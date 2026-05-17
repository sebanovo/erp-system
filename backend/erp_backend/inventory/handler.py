from decimal import Decimal

from boto3.dynamodb.conditions import Key

from shared.dates import utc_now_iso
from shared.dynamodb import get_table
from shared.ids import generate_inventory_id, generate_movement_id
from shared.response import success_response, error_response
from shared.tenant import get_tenant_id
from shared.validation import (
    parse_json_body,
    require_fields,
    require_non_negative_decimal,
)


PRODUCTS_TABLE_ENV = "PRODUCTS_TABLE_NAME"
INVENTORY_TABLE_ENV = "INVENTORY_TABLE_NAME"
INVENTORY_MOVEMENTS_TABLE_ENV = "INVENTORY_MOVEMENTS_TABLE_NAME"

DEFAULT_LOCATION_ID = "MAIN"

VALID_MOVEMENT_TYPES = ["IN", "OUT", "ADJUSTMENT"]
VALID_REASONS = [
    "PURCHASE",
    "SALE",
    "MANUAL_ADJUSTMENT",
    "INITIAL_STOCK",
]


def lambda_handler(event, context):
    try:
        http_method = event.get("httpMethod")
        resource = event.get("resource") or ""
        path_parameters = event.get("pathParameters") or {}
        product_id = path_parameters.get("product_id")

        if http_method == "GET" and resource == "/inventory":
            return list_inventory(event)

        if http_method == "GET" and resource == "/inventory/low-stock":
            return list_low_stock(event)

        if http_method == "GET" and resource == "/inventory/{product_id}":
            return get_inventory_by_product(event, product_id)

        if http_method == "GET" and resource == "/inventory/{product_id}/movements":
            return list_inventory_movements(event, product_id)

        if http_method == "POST" and resource == "/inventory/adjustments":
            return create_inventory_adjustment(event)

        return error_response(
            message="Route not found",
            status_code=404
        )

    except ValueError as exc:
        return error_response(
            message=str(exc),
            status_code=400
        )

    except Exception as exc:
        return error_response(
            message="Internal server error",
            errors=[str(exc)],
            status_code=500
        )


def get_products_table():
    return get_table(PRODUCTS_TABLE_ENV)


def get_inventory_table():
    return get_table(INVENTORY_TABLE_ENV)


def get_inventory_movements_table():
    return get_table(INVENTORY_MOVEMENTS_TABLE_ENV)


def list_inventory(event):
    tenant_id = get_tenant_id(event)
    table = get_inventory_table()

    result = table.query(
        KeyConditionExpression=Key("tenant_id").eq(tenant_id)
    )

    return success_response(
        message="Inventory retrieved successfully",
        data=result.get("Items", [])
    )


def list_low_stock(event):
    tenant_id = get_tenant_id(event)
    table = get_inventory_table()

    result = table.query(
        KeyConditionExpression=Key("tenant_id").eq(tenant_id)
    )

    items = result.get("Items", [])

    low_stock_items = [
        item for item in items
        if item.get("status") in ["LOW_STOCK", "OUT_OF_STOCK"]
    ]

    return success_response(
        message="Low stock inventory retrieved successfully",
        data=low_stock_items
    )


def get_inventory_by_product(event, product_id):
    if not product_id:
        return error_response(
            message="product_id is required",
            status_code=400
        )

    tenant_id = get_tenant_id(event)
    location_id = DEFAULT_LOCATION_ID
    inventory_id = generate_inventory_id(product_id, location_id)

    table = get_inventory_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "inventory_id": inventory_id
        }
    )

    inventory = result.get("Item")

    if not inventory:
        return error_response(
            message="Inventory not found",
            status_code=404
        )

    return success_response(
        message="Inventory retrieved successfully",
        data=inventory
    )


def list_inventory_movements(event, product_id):
    if not product_id:
        return error_response(
            message="product_id is required",
            status_code=400
        )

    tenant_id = get_tenant_id(event)
    tenant_product_id = build_tenant_product_id(tenant_id, product_id)

    table = get_inventory_movements_table()

    result = table.query(
        KeyConditionExpression=Key("tenant_product_id").eq(tenant_product_id)
    )

    movements = result.get("Items", [])

    return success_response(
        message="Inventory movements retrieved successfully",
        data=movements
    )


def create_inventory_adjustment(event):
    tenant_id = get_tenant_id(event)
    data = parse_json_body(event)

    require_fields(
        data,
        [
            "product_id",
            "type",
            "quantity"
        ]
    )

    product_id = str(data.get("product_id")).strip()
    location_id = str(data.get("location_id") or DEFAULT_LOCATION_ID).strip()
    movement_type = str(data.get("type")).strip().upper()
    reason = str(data.get("reason") or "MANUAL_ADJUSTMENT").strip().upper()
    note = str(data.get("note") or "").strip()

    if movement_type not in VALID_MOVEMENT_TYPES:
        raise ValueError(f"type must be one of: {', '.join(VALID_MOVEMENT_TYPES)}")

    if reason not in VALID_REASONS:
        raise ValueError(f"reason must be one of: {', '.join(VALID_REASONS)}")

    quantity = require_non_negative_decimal(data.get("quantity"), "quantity")
    min_stock = require_non_negative_decimal(data.get("min_stock", 0), "min_stock")

    validate_product_exists(tenant_id, product_id)

    inventory_table = get_inventory_table()
    movements_table = get_inventory_movements_table()

    inventory_id = generate_inventory_id(product_id, location_id)

    current_inventory = get_current_inventory(
        inventory_table,
        tenant_id,
        inventory_id,
        product_id,
        location_id,
        min_stock
    )

    previous_on_hand = Decimal(str(current_inventory.get("on_hand", 0)))
    previous_reserved = Decimal(str(current_inventory.get("reserved", 0)))
    current_min_stock = Decimal(str(current_inventory.get("min_stock", min_stock)))

    if "min_stock" in data:
        current_min_stock = min_stock

    new_on_hand = calculate_new_on_hand(
        previous_on_hand=previous_on_hand,
        quantity=quantity,
        movement_type=movement_type
    )

    if new_on_hand < 0:
        raise ValueError("on_hand cannot be negative")

    available = new_on_hand - previous_reserved

    if available < 0:
        raise ValueError("available stock cannot be negative")

    status = calculate_inventory_status(
        available=available,
        min_stock=current_min_stock
    )

    now = utc_now_iso()

    inventory = {
        "tenant_id": tenant_id,
        "inventory_id": inventory_id,
        "product_id": product_id,
        "location_id": location_id,
        "on_hand": new_on_hand,
        "reserved": previous_reserved,
        "available": available,
        "min_stock": current_min_stock,
        "status": status,
        "created_at": current_inventory.get("created_at", now),
        "updated_at": now
    }

    inventory_table.put_item(Item=inventory)

    movement = {
        "tenant_product_id": build_tenant_product_id(tenant_id, product_id),
        "movement_id": generate_movement_id(),
        "tenant_id": tenant_id,
        "product_id": product_id,
        "location_id": location_id,
        "type": movement_type,
        "reason": reason,
        "quantity": quantity,
        "previous_on_hand": previous_on_hand,
        "new_on_hand": new_on_hand,
        "reference_id": str(data.get("reference_id") or ""),
        "note": note,
        "created_at": now
    }

    movements_table.put_item(Item=movement)

    return success_response(
        message="Inventory adjustment created successfully",
        data={
            "inventory": inventory,
            "movement": movement
        },
        status_code=201
    )


def validate_product_exists(tenant_id, product_id):
    table = get_products_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "product_id": product_id
        }
    )

    product = result.get("Item")

    if not product or product.get("is_active") is False:
        raise ValueError("Product not found")


def get_current_inventory(table, tenant_id, inventory_id, product_id, location_id, min_stock):
    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "inventory_id": inventory_id
        }
    )

    item = result.get("Item")

    if item:
        return item

    now = utc_now_iso()

    return {
        "tenant_id": tenant_id,
        "inventory_id": inventory_id,
        "product_id": product_id,
        "location_id": location_id,
        "on_hand": Decimal("0"),
        "reserved": Decimal("0"),
        "available": Decimal("0"),
        "min_stock": min_stock,
        "status": "OUT_OF_STOCK",
        "created_at": now,
        "updated_at": now
    }


def calculate_new_on_hand(previous_on_hand, quantity, movement_type):
    if movement_type == "IN":
        return previous_on_hand + quantity

    if movement_type == "OUT":
        return previous_on_hand - quantity

    if movement_type == "ADJUSTMENT":
        return quantity

    raise ValueError("Invalid movement type")


def calculate_inventory_status(available, min_stock):
    if available == 0:
        return "OUT_OF_STOCK"

    if available <= min_stock:
        return "LOW_STOCK"

    return "AVAILABLE"


def build_tenant_product_id(tenant_id, product_id):
    return f"{tenant_id}#{product_id}"