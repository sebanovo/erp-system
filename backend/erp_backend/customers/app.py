from boto3.dynamodb.conditions import Attr

from shared.dynamo import table, scan_active
from shared.ids import new_id, now_iso
from shared.response import error, handle_exception, parse_body, success
from shared.validators import require_fields

CUSTOMERS_TABLE_ENV = "CUSTOMERS_TABLE"


def lambda_handler(event, context):
    try:
        method = event.get("httpMethod")
        resource = event.get("resource") or event.get("path")

        if method == "POST" and resource == "/customers":
            return create_customer(event)
        if method == "GET" and resource == "/customers":
            return list_customers()
        if method == "GET" and resource == "/customers/search":
            return search_customers(event)
        if method == "PATCH" and resource == "/customers/{customerId}":
            return update_customer(event)
        if method == "DELETE" and resource == "/customers/{customerId}":
            return delete_customer(event)

        return error("Route not found", 404)
    except Exception as exc:
        return handle_exception(exc)


def create_customer(event):
    body = parse_body(event)
    require_fields(body, ["name"])

    now = now_iso()
    item = {
        "customerId": new_id("CUS"),
        "name": str(body["name"]).strip(),
        "document": str(body.get("document", "")).strip(),
        "phone": str(body.get("phone", "")).strip(),
        "email": str(body.get("email", "")).strip(),
        "address": str(body.get("address", "")).strip(),
        "metadata": body.get("metadata", {}),
        "isActive": True,
        "createdAt": now,
        "updatedAt": now,
    }

    table(CUSTOMERS_TABLE_ENV).put_item(Item=item)
    return success(item, "Customer created", 201)


def list_customers():
    items = scan_active(table(CUSTOMERS_TABLE_ENV))
    items.sort(key=lambda x: x.get("createdAt", ""), reverse=True)
    return success(items, "Customers retrieved")


def search_customers(event):
    params = event.get("queryStringParameters") or {}
    name = (params.get("name") or "").strip().lower()
    if not name:
        raise ValueError("Query parameter 'name' is required")

    response = table(CUSTOMERS_TABLE_ENV).scan(FilterExpression=Attr("isActive").eq(True))
    items = response.get("Items", [])
    filtered = [
        customer for customer in items
        if name in customer.get('name', '').lower()
    ]
    return success(filtered, "Customers found")


def update_customer(event):
    customer_id = (event.get("pathParameters") or {}).get("customerId")
    if not customer_id:
        raise ValueError("customerId is required")

    body = parse_body(event)
    allowed_fields = ["name", "document", "phone", "email", "address", "metadata"]
    updates = {}
    for field in allowed_fields:
        if field in body:
            if field == "metadata":
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

    result = table(CUSTOMERS_TABLE_ENV).update_item(
        Key={"customerId": customer_id},
        UpdateExpression=update_expression,
        ExpressionAttributeNames=expression_names,
        ExpressionAttributeValues=expression_values,
        ReturnValues="ALL_NEW",
    )
    return success(result.get("Attributes"), "Customer updated")


def delete_customer(event):
    customer_id = (event.get("pathParameters") or {}).get("customerId")
    if not customer_id:
        raise ValueError("customerId is required")

    result = table(CUSTOMERS_TABLE_ENV).update_item(
        Key={"customerId": customer_id},
        UpdateExpression="SET isActive = :isActive, updatedAt = :updatedAt",
        ExpressionAttributeValues={":isActive": False, ":updatedAt": now_iso()},
        ReturnValues="ALL_NEW",
    )
    return success(result.get("Attributes"), "Customer deactivated")
