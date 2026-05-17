from decimal import Decimal

from boto3.dynamodb.conditions import Key

from shared.dates import utc_now_iso
from shared.dynamodb import get_table
from shared.ids import generate_inventory_id, generate_movement_id, generate_sale_id
from shared.response import success_response, error_response
from shared.tenant import get_tenant_id
from shared.validation import (
    parse_json_body,
    require_fields,
    require_positive_decimal,
    require_non_negative_decimal,
)


CUSTOMERS_TABLE_ENV = "CUSTOMERS_TABLE_NAME"
PRODUCTS_TABLE_ENV = "PRODUCTS_TABLE_NAME"
INVENTORY_TABLE_ENV = "INVENTORY_TABLE_NAME"
INVENTORY_MOVEMENTS_TABLE_ENV = "INVENTORY_MOVEMENTS_TABLE_NAME"
SALES_TABLE_ENV = "SALES_TABLE_NAME"

DEFAULT_LOCATION_ID = "MAIN"


def lambda_handler(event, context):
    try:
        http_method = event.get("httpMethod")
        path_parameters = event.get("pathParameters") or {}
        sale_id = path_parameters.get("sale_id")

        if http_method == "GET" and sale_id:
            return get_sale(event, sale_id)

        if http_method == "GET":
            return list_sales(event)

        if http_method == "POST":
            return create_sale(event)

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


def get_customers_table():
    return get_table(CUSTOMERS_TABLE_ENV)


def get_products_table():
    return get_table(PRODUCTS_TABLE_ENV)


def get_inventory_table():
    return get_table(INVENTORY_TABLE_ENV)


def get_inventory_movements_table():
    return get_table(INVENTORY_MOVEMENTS_TABLE_ENV)


def get_sales_table():
    return get_table(SALES_TABLE_ENV)


def list_sales(event):
    tenant_id = get_tenant_id(event)
    table = get_sales_table()

    result = table.query(
        KeyConditionExpression=Key("tenant_id").eq(tenant_id)
    )

    return success_response(
        message="Sales retrieved successfully",
        data=result.get("Items", [])
    )


def get_sale(event, sale_id):
    tenant_id = get_tenant_id(event)
    table = get_sales_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "sale_id": sale_id
        }
    )

    sale = result.get("Item")

    if not sale:
        return error_response(
            message="Sale not found",
            status_code=404
        )

    return success_response(
        message="Sale retrieved successfully",
        data=sale
    )


def create_sale(event):
    tenant_id = get_tenant_id(event)
    data = parse_json_body(event)

    require_fields(
        data,
        [
            "items"
        ]
    )

    customer_id = normalize_text(data.get("customer_id"))

    if customer_id:
        validate_customer_exists(tenant_id, customer_id)

    items = data.get("items")

    if not isinstance(items, list) or len(items) == 0:
        raise ValueError("items must be a non-empty list")

    sale_id = generate_sale_id()
    now = utc_now_iso()

    processed_items = []
    total = Decimal("0")

    for item in items:
        processed_item = process_sale_item(tenant_id, item)
        processed_items.append(processed_item)
        total += processed_item["subtotal"]

    insufficient_stock_errors = validate_available_stock(
        tenant_id=tenant_id,
        items=processed_items
    )

    if insufficient_stock_errors:
        return error_response(
            message="Insufficient stock",
            errors=insufficient_stock_errors,
            status_code=400
        )

    sale = {
        "tenant_id": tenant_id,
        "sale_id": sale_id,
        "customer_id": customer_id,
        "items": processed_items,
        "total": total,
        "status": "CONFIRMED",
        "created_at": now
    }

    sales_table = get_sales_table()
    sales_table.put_item(Item=sale)

    for item in processed_items:
        decrease_inventory_from_sale(
            tenant_id=tenant_id,
            item=item,
            sale_id=sale_id,
            created_at=now
        )

    return success_response(
        message="Sale created successfully",
        data=sale,
        status_code=201
    )


def process_sale_item(tenant_id, item):
    if not isinstance(item, dict):
        raise ValueError("Each sale item must be an object")

    require_fields(
        item,
        [
            "product_id",
            "quantity",
            "unit_price"
        ]
    )

    product_id = normalize_text(item.get("product_id"))
    location_id = normalize_text(item.get("location_id")) or DEFAULT_LOCATION_ID

    quantity = require_positive_decimal(item.get("quantity"), "quantity")
    unit_price = require_non_negative_decimal(item.get("unit_price"), "unit_price")

    validate_product_exists(tenant_id, product_id)

    subtotal = quantity * unit_price

    return {
        "product_id": product_id,
        "location_id": location_id,
        "quantity": quantity,
        "unit_price": unit_price,
        "subtotal": subtotal
    }


def validate_customer_exists(tenant_id, customer_id):
    table = get_customers_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "customer_id": customer_id
        }
    )

    customer = result.get("Item")

    if not customer or customer.get("is_active") is False:
        raise ValueError(f"Customer not found: {customer_id}")


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
        raise ValueError(f"Product not found: {product_id}")


def validate_available_stock(tenant_id, items):
    inventory_table = get_inventory_table()
    requested_by_inventory = {}
    inventory_cache = {}
    errors = []

    for item in items:
        product_id = item["product_id"]
        location_id = item.get("location_id") or DEFAULT_LOCATION_ID
        inventory_id = generate_inventory_id(product_id, location_id)

        requested_by_inventory[inventory_id] = requested_by_inventory.get(
            inventory_id,
            Decimal("0")
        ) + item["quantity"]

        if inventory_id not in inventory_cache:
            result = inventory_table.get_item(
                Key={
                    "tenant_id": tenant_id,
                    "inventory_id": inventory_id
                }
            )

            inventory = result.get("Item")

            if not inventory:
                inventory_cache[inventory_id] = None
            else:
                inventory_cache[inventory_id] = inventory

    for inventory_id, requested_quantity in requested_by_inventory.items():
        inventory = inventory_cache.get(inventory_id)

        if not inventory:
            product_id = extract_product_id_from_inventory_id(inventory_id)

            errors.append({
                "product_id": product_id,
                "available": 0,
                "requested": requested_quantity
            })

            continue

        available = Decimal(str(inventory.get("available", 0)))
        product_id = inventory.get("product_id")

        if available < requested_quantity:
            errors.append({
                "product_id": product_id,
                "available": available,
                "requested": requested_quantity
            })

    return errors


def decrease_inventory_from_sale(tenant_id, item, sale_id, created_at):
    inventory_table = get_inventory_table()
    movements_table = get_inventory_movements_table()

    product_id = item["product_id"]
    location_id = item.get("location_id") or DEFAULT_LOCATION_ID
    quantity = item["quantity"]

    inventory_id = generate_inventory_id(product_id, location_id)

    result = inventory_table.get_item(
        Key={
            "tenant_id": tenant_id,
            "inventory_id": inventory_id
        }
    )

    current_inventory = result.get("Item")

    if not current_inventory:
        raise ValueError(f"Inventory not found for product: {product_id}")

    previous_on_hand = Decimal(str(current_inventory.get("on_hand", 0)))
    previous_reserved = Decimal(str(current_inventory.get("reserved", 0)))
    previous_available = Decimal(str(current_inventory.get("available", 0)))
    min_stock = Decimal(str(current_inventory.get("min_stock", 0)))

    if previous_available < quantity:
        raise ValueError(f"Insufficient stock for product: {product_id}")

    new_on_hand = previous_on_hand - quantity

    if new_on_hand < 0:
        raise ValueError(f"on_hand cannot be negative for product: {product_id}")

    available = new_on_hand - previous_reserved

    if available < 0:
        raise ValueError(f"available stock cannot be negative for product: {product_id}")

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
        "type": "OUT",
        "reason": "SALE",
        "quantity": quantity,
        "previous_on_hand": previous_on_hand,
        "new_on_hand": new_on_hand,
        "reference_id": sale_id,
        "note": "Sale registered",
        "created_at": created_at
    }

    movements_table.put_item(Item=movement)


def calculate_inventory_status(available, min_stock):
    if available == 0:
        return "OUT_OF_STOCK"

    if available <= min_stock:
        return "LOW_STOCK"

    return "AVAILABLE"


def build_tenant_product_id(tenant_id, product_id):
    return f"{tenant_id}#{product_id}"


def extract_product_id_from_inventory_id(inventory_id):
    parts = inventory_id.split("#")

    if len(parts) >= 2:
        return parts[1]

    return inventory_id


def normalize_text(value):
    if value is None:
        return ""

    return str(value).strip()