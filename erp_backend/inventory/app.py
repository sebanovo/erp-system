from boto3.dynamodb.conditions import Attr

from shared.dynamo import table, scan_all
from shared.ids import new_id, now_iso
from shared.response import error, handle_exception, parse_body, success
from shared.validators import require_fields, to_positive_int, to_non_negative_int

INVENTORY_TABLE_ENV = "INVENTORY_TABLE"
MOVEMENTS_TABLE_ENV = "INVENTORY_MOVEMENTS_TABLE"

ALLOWED_ADJUSTMENT_TYPES = ["ADJUSTMENT_IN", "ADJUSTMENT_OUT"]


def lambda_handler(event, context):
    try:
        method = event.get("httpMethod")
        resource = event.get("resource") or event.get("path")

        if method == "GET" and resource == "/inventory":
            return list_inventory()
        if method == "GET" and resource == "/inventory/{productId}":
            return get_inventory(event)
        if method == "GET" and resource == "/inventory/low-stock":
            return get_low_stock()
        if method == "POST" and resource == "/inventory/adjustments":
            return create_adjustment(event)
        if method == "GET" and resource == "/inventory/{productId}/movements":
            return get_inventory_movements(event)

        return error("Route not found", 404)
    except Exception as exc:
        return handle_exception(exc)


def list_inventory():
    items = scan_all(table(INVENTORY_TABLE_ENV))
    return success(items, "Inventory retrieved")


def get_inventory(event):
    product_id = (event.get("pathParameters") or {}).get("productId")
    if not product_id:
        raise ValueError("productId is required")

    result = table(INVENTORY_TABLE_ENV).get_item(Key={"productId": product_id})
    item = result.get("Item")
    if not item:
        return error("Inventory not found", 404)
    return success(item, "Inventory retrieved")


def get_low_stock():
    items = scan_all(table(INVENTORY_TABLE_ENV))
    low_stock = [item for item in items if int(item.get("stock", 0)) <= int(item.get("minStock", 0))]
    return success(low_stock, "Low stock products retrieved")


def create_adjustment(event):
    body = parse_body(event)
    require_fields(body, ["productId", "quantity", "type", "reason"])

    product_id = body["productId"]
    quantity = to_positive_int(body["quantity"], "quantity")
    movement_type = str(body["type"]).strip().upper()
    reason = str(body["reason"]).strip()
    min_stock = to_non_negative_int(body.get("minStock", 0), "minStock")

    if movement_type not in ALLOWED_ADJUSTMENT_TYPES:
        raise ValueError(f"type must be one of: {', '.join(ALLOWED_ADJUSTMENT_TYPES)}")

    signed_quantity = quantity if movement_type == "ADJUSTMENT_IN" else -quantity
    now = now_iso()

    inventory_table = table(INVENTORY_TABLE_ENV)
    movements_table = table(MOVEMENTS_TABLE_ENV)

    existing = inventory_table.get_item(Key={"productId": product_id}).get("Item")
    current_stock = int(existing.get("stock", 0)) if existing else 0
    new_stock = current_stock + signed_quantity
    if new_stock < 0:
        raise ValueError("Adjustment would leave negative stock")

    inventory_item = {
        "productId": product_id,
        "stock": new_stock,
        "minStock": int(existing.get("minStock", min_stock)) if existing else min_stock,
        "updatedAt": now,
    }
    inventory_table.put_item(Item=inventory_item)

    movement = {
        "movementId": new_id("MOV"),
        "productId": product_id,
        "type": movement_type,
        "quantity": signed_quantity,
        "reason": reason,
        "createdAt": now,
    }
    movements_table.put_item(Item=movement)

    return success({"inventory": inventory_item, "movement": movement}, "Inventory adjusted", 201)


def get_inventory_movements(event):
    product_id = (event.get("pathParameters") or {}).get("productId")
    if not product_id:
        raise ValueError("productId is required")

    response = table(MOVEMENTS_TABLE_ENV).scan(
        FilterExpression=Attr("productId").eq(product_id)
    )
    items = response.get("Items", [])
    items.sort(key=lambda x: x.get("createdAt", ""), reverse=True)
    return success(items, "Inventory movements retrieved")
