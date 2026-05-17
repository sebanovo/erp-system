from decimal import Decimal

from boto3.dynamodb.conditions import Key

from shared.dates import utc_now_iso
from shared.dynamodb import get_table
from shared.ids import generate_inventory_id, generate_movement_id, generate_purchase_id
from shared.response import success_response, error_response
from shared.tenant import get_tenant_id
from shared.validation import (
    parse_json_body,
    require_fields,
    require_positive_decimal,
    require_non_negative_decimal,
)


PRODUCTS_TABLE_ENV = "PRODUCTS_TABLE_NAME"
INVENTORY_TABLE_ENV = "INVENTORY_TABLE_NAME"
INVENTORY_MOVEMENTS_TABLE_ENV = "INVENTORY_MOVEMENTS_TABLE_NAME"
PURCHASES_TABLE_ENV = "PURCHASES_TABLE_NAME"

DEFAULT_LOCATION_ID = "MAIN"


def lambda_handler(event, context):
    try:
        http_method = event.get("httpMethod")
        path_parameters = event.get("pathParameters") or {}
        purchase_id = path_parameters.get("purchase_id")

        if http_method == "GET" and purchase_id:
            return get_purchase(event, purchase_id)

        if http_method == "GET":
            return list_purchases(event)

        if http_method == "POST":
            return create_purchase(event)

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


def get_purchases_table():
    return get_table(PURCHASES_TABLE_ENV)


def list_purchases(event):
    tenant_id = get_tenant_id(event)
    table = get_purchases_table()

    result = table.query(
        KeyConditionExpression=Key("tenant_id").eq(tenant_id)
    )

    return success_response(
        message="Purchases retrieved successfully",
        data=result.get("Items", [])
    )


def get_purchase(event, purchase_id):
    tenant_id = get_tenant_id(event)
    table = get_purchases_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "purchase_id": purchase_id
        }
    )

    purchase = result.get("Item")

    if not purchase:
        return error_response(
            message="Purchase not found",
            status_code=404
        )

    return success_response(
        message="Purchase retrieved successfully",
        data=purchase
    )


def create_purchase(event):
    tenant_id = get_tenant_id(event)
    data = parse_json_body(event)

    require_fields(
        data,
        [
            "supplier_name",
            "items"
        ]
    )

    supplier_name = normalize_text(data.get("supplier_name"))
    items = data.get("items")

    if not isinstance(items, list) or len(items) == 0:
        raise ValueError("items must be a non-empty list")

    purchase_id = generate_purchase_id()
    now = utc_now_iso()

    processed_items = []
    total = Decimal("0")

    for item in items:
        processed_item = process_purchase_item(tenant_id, item)
        processed_items.append(processed_item)
        total += processed_item["subtotal"]

    purchase = {
        "tenant_id": tenant_id,
        "purchase_id": purchase_id,
        "supplier_name": supplier_name,
        "items": processed_items,
        "total": total,
        "status": "CONFIRMED",
        "created_at": now
    }

    purchases_table = get_purchases_table()
    purchases_table.put_item(Item=purchase)

    for item in processed_items:
        increase_inventory_from_purchase(
            tenant_id=tenant_id,
            item=item,
            purchase_id=purchase_id,
            created_at=now
        )

    return success_response(
        message="Purchase created successfully",
        data=purchase,
        status_code=201
    )


def process_purchase_item(tenant_id, item):
    if not isinstance(item, dict):
        raise ValueError("Each purchase item must be an object")

    require_fields(
        item,
        [
            "product_id",
            "quantity",
            "unit_cost"
        ]
    )

    product_id = normalize_text(item.get("product_id"))
    location_id = normalize_text(item.get("location_id")) or DEFAULT_LOCATION_ID

    quantity = require_positive_decimal(item.get("quantity"), "quantity")
    unit_cost = require_non_negative_decimal(item.get("unit_cost"), "unit_cost")

    validate_product_exists(tenant_id, product_id)

    subtotal = quantity * unit_cost

    return {
        "product_id": product_id,
        "location_id": location_id,
        "quantity": quantity,
        "unit_cost": unit_cost,
        "subtotal": subtotal
    }


def validate_product_exists(tenant_id, product_id):
    products_table = get_products_table()

    result = products_table.get_item(
        Key={
            "tenant_id": tenant_id,
            "product_id": product_id
        }
    )

    product = result.get("Item")

    if not product or product.get("is_active") is False:
        raise ValueError(f"Product not found: {product_id}")


def increase_inventory_from_purchase(tenant_id, item, purchase_id, created_at):
    inventory_table = get_inventory_table()
    movements_table = get_inventory_movements_table()

    product_id = item["product_id"]
    location_id = item.get("location_id") or DEFAULT_LOCATION_ID
    quantity = item["quantity"]

    inventory_id = generate_inventory_id(product_id, location_id)

    current_inventory = get_current_inventory(
        table=inventory_table,
        tenant_id=tenant_id,
        inventory_id=inventory_id,
        product_id=product_id,
        location_id=location_id
    )

    previous_on_hand = Decimal(str(current_inventory.get("on_hand", 0)))
    previous_reserved = Decimal(str(current_inventory.get("reserved", 0)))
    min_stock = Decimal(str(current_inventory.get("min_stock", 0)))

    new_on_hand = previous_on_hand + quantity
    available = new_on_hand - previous_reserved
    status = calculate_inventory_status(available, min_stock)

    inventory = {
        "tenant_id": tenant_id,
        "inventory_id": inventory_id,
        "product_id": product_id,
        "location_id": location_id,
        "on_hand": new_on_hand,
        "reserved": previous_reserved,
        "available": available,
        "min_stock": min_stock,
        "status": status,
        "created_at": current_inventory.get("created_at", created_at),
        "updated_at": created_at
    }

    inventory_table.put_item(Item=inventory)

    movement = {
        "tenant_product_id": build_tenant_product_id(tenant_id, product_id),
        "movement_id": generate_movement_id(),
        "tenant_id": tenant_id,
        "product_id": product_id,
        "location_id": location_id,
        "type": "IN",
        "reason": "PURCHASE",
        "quantity": quantity,
        "previous_on_hand": previous_on_hand,
        "new_on_hand": new_on_hand,
        "reference_id": purchase_id,
        "note": "Purchase registered",
        "created_at": created_at
    }

    movements_table.put_item(Item=movement)


def get_current_inventory(table, tenant_id, inventory_id, product_id, location_id):
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
        "min_stock": Decimal("0"),
        "status": "OUT_OF_STOCK",
        "created_at": now,
        "updated_at": now
    }


def calculate_inventory_status(available, min_stock):
    if available == 0:
        return "OUT_OF_STOCK"

    if available <= min_stock:
        return "LOW_STOCK"

    return "AVAILABLE"


def build_tenant_product_id(tenant_id, product_id):
    return f"{tenant_id}#{product_id}"


def normalize_text(value):
    if value is None:
        return ""

    return str(value).strip()