from boto3.dynamodb.conditions import Attr

from shared.dynamo import table, scan_active
from shared.ids import new_id, now_iso
from shared.response import error, handle_exception, parse_body, success
from shared.validators import require_fields, to_decimal

PRODUCTS_TABLE_ENV = "PRODUCTS_TABLE"


def lambda_handler(event, context):
    try:
        method = event.get("httpMethod")
        resource = event.get("resource") or event.get("path")

        if method == "POST" and resource == "/products":
            return create_product(event)
        if method == "GET" and resource == "/products":
            return list_products()
        if method == "GET" and resource == "/products/search":
            return search_products(event)
        if method == "PATCH" and resource == "/products/{productId}":
            return update_product(event)
        if method == "DELETE" and resource == "/products/{productId}":
            return delete_product(event)

        return error("Route not found", 404)
    except Exception as exc:
        return handle_exception(exc)


def create_product(event):
    body = parse_body(event)
    require_fields(body, ["sku", "name", "price", "cost"])

    now = now_iso()
    item = {
        "productId": new_id("PROD"),
        "sku": str(body["sku"]).strip(),
        "name": str(body["name"]).strip(),
        "description": str(body.get("description", "")).strip(),
        "category": str(body.get("category", "")).strip(),
        "unit": str(body.get("unit", "unit")).strip(),
        "price": to_decimal(body["price"], "price"),
        "cost": to_decimal(body["cost"], "cost"),
        "metadata": body.get("metadata", {}),
        "isActive": True,
        "createdAt": now,
        "updatedAt": now,
    }

    table(PRODUCTS_TABLE_ENV).put_item(Item=item)
    return success(item, "Product created", 201)


def list_products():
    items = scan_active(table(PRODUCTS_TABLE_ENV))
    items.sort(key=lambda x: x.get("createdAt", ""), reverse=True)
    return success(items, "Products retrieved")


def search_products(event):
    params = event.get("queryStringParameters") or {}
    name = (params.get("name") or "").strip().lower()
    if not name:
        raise ValueError("Query parameter 'name' is required")

    response = table(PRODUCTS_TABLE_ENV).scan(FilterExpression=Attr("isActive").eq(True))
    items = response.get("Items", [])
    filtered = [product for product in items if name in product.get("name", "").lower()]
    return success(filtered, "Products found")


def update_product(event):
    product_id = (event.get("pathParameters") or {}).get("productId")
    if not product_id:
        raise ValueError("productId is required")

    body = parse_body(event)
    allowed_fields = ["sku", "name", "description", "category", "unit", "price", "cost", "metadata"]
    updates = {}
    for field in allowed_fields:
        if field in body:
            if field in ["price", "cost"]:
                updates[field] = to_decimal(body[field], field)
            elif field == "metadata":
                updates[field] = body[field]
            else:
                updates[field] = str(body[field]).strip()

    if not updates:
        raise ValueError("No valid fields to update")

    expression_names = {f"#{field}": field for field in updates.keys()}
    expression_values = {f":{field}": value for field, value in updates.items()}
    expression_names["#updatedAt"] = "updatedAt"
    expression_values[":updatedAt"] = now_iso()

    update_expression = "SET " + ", ".join([f"#{field} = :{field}" for field in updates.keys()])
    update_expression += ", #updatedAt = :updatedAt"

    result = table(PRODUCTS_TABLE_ENV).update_item(
        Key={"productId": product_id},
        UpdateExpression=update_expression,
        ExpressionAttributeNames=expression_names,
        ExpressionAttributeValues=expression_values,
        ReturnValues="ALL_NEW",
    )
    return success(result.get("Attributes"), "Product updated")


def delete_product(event):
    product_id = (event.get("pathParameters") or {}).get("productId")
    if not product_id:
        raise ValueError("productId is required")

    result = table(PRODUCTS_TABLE_ENV).update_item(
        Key={"productId": product_id},
        UpdateExpression="SET isActive = :isActive, updatedAt = :updatedAt",
        ExpressionAttributeValues={":isActive": False, ":updatedAt": now_iso()},
        ReturnValues="ALL_NEW",
    )
    return success(result.get("Attributes"), "Product deactivated")
