"""
Customers module for the Serverless ERP application.

This module handles CRUD operations for customers in the ERP system.
It provides endpoints for listing, creating, retrieving, updating, and deleting customers.
All operations are tenant-aware and use DynamoDB for data storage.
"""

from boto3.dynamodb.conditions import Key

from shared.dates import utc_now_iso
from shared.dynamodb import get_table
from shared.ids import generate_customer_id
from shared.response import success_response, error_response
from shared.tenant import get_tenant_id
from shared.validation import parse_json_body, require_fields


CUSTOMERS_TABLE_ENV = "CUSTOMERS_TABLE_NAME"


def lambda_handler(event, context):
    """
    Main Lambda handler for customer operations.

    Routes HTTP requests to appropriate handler functions based on method and path.
    Supports GET, POST, PUT, DELETE methods for customers.

    Args:
        event (dict): API Gateway event containing request details
        context: Lambda context object

    Returns:
        dict: API response with appropriate status code and data
    """
    try:
        http_method = event.get("httpMethod")
        path_parameters = event.get("pathParameters") or {}
        customer_id = path_parameters.get("customer_id")

        if http_method == "GET" and customer_id:
            return get_customer(event, customer_id)

        if http_method == "GET":
            return list_customers(event)

        if http_method == "POST":
            return create_customer(event)

        if http_method == "PUT" and customer_id:
            return update_customer(event, customer_id)

        if http_method == "DELETE" and customer_id:
            return delete_customer(event, customer_id)

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
    try:
        http_method = event.get("httpMethod")
        path_parameters = event.get("pathParameters") or {}
        customer_id = path_parameters.get("customer_id")

        if http_method == "GET" and customer_id:
            return get_customer(event, customer_id)

        if http_method == "GET":
            return list_customers(event)

        if http_method == "POST":
            return create_customer(event)

        if http_method == "PUT" and customer_id:
            return update_customer(event, customer_id)

        if http_method == "DELETE" and customer_id:
            return delete_customer(event, customer_id)

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
    """
    Get the DynamoDB table resource for customers.

    Returns:
        boto3.dynamodb.Table: Customers table instance
    """
    return get_table(CUSTOMERS_TABLE_ENV)


def list_customers(event):
    """
    List all active customers for the current tenant.

    Args:
        event (dict): API Gateway event

    Returns:
        dict: API response with list of customers
    """
    tenant_id = get_tenant_id(event)
    table = get_customers_table()

    result = table.query(
        KeyConditionExpression=Key("tenant_id").eq(tenant_id)
    )

    customers = result.get("Items", [])

    active_customers = [
        customer for customer in customers
        if customer.get("is_active", True) is True
    ]

    return success_response(
        message="Customers retrieved successfully",
        data=active_customers
    )


def get_customer(event, customer_id):
    """
    Retrieve a specific customer by ID for the current tenant.

    Args:
        event (dict): API Gateway event
        customer_id (str): Customer identifier

    Returns:
        dict: API response with customer data or 404 if not found
    """
    tenant_id = get_tenant_id(event)
    table = get_customers_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "customer_id": customer_id
        }
    )

    customer = result.get("Item")

    if not customer or customer.get("is_active") is False:
        return error_response(
            message="Customer not found",
            status_code=404
        )

    return success_response(
        message="Customer retrieved successfully",
        data=customer
    )


def create_customer(event):
    """
    Create a new customer for the current tenant.

    Validates required fields and creates a customer with generated ID.

    Args:
        event (dict): API Gateway event with customer data in body

    Returns:
        dict: API response with created customer data
    """
    tenant_id = get_tenant_id(event)
    data = parse_json_body(event)

    require_fields(
        data,
        [
            "name"
        ]
    )

    customer_id = generate_customer_id()
    now = utc_now_iso()

    customer = {
        "tenant_id": tenant_id,
        "customer_id": customer_id,
        "name": normalize_text(data.get("name")),
        "document": normalize_text(data.get("document")),
        "phone": normalize_text(data.get("phone")),
        "email": normalize_text(data.get("email")),
        "address": normalize_text(data.get("address")),
        "metadata": data.get("metadata") or {},
        "is_active": True,
        "created_at": now,
        "updated_at": now
    }

    table = get_customers_table()
    table.put_item(Item=customer)

    return success_response(
        message="Customer created successfully",
        data=customer,
        status_code=201
    )


def update_customer(event, customer_id):
    """
    Update an existing customer for the current tenant.

    Only allows updating specific editable fields.

    Args:
        event (dict): API Gateway event with update data in body
        customer_id (str): Customer identifier

    Returns:
        dict: API response with updated customer data or 404 if not found
    """
    tenant_id = get_tenant_id(event)
    data = parse_json_body(event)
    table = get_customers_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "customer_id": customer_id
        }
    )

    customer = result.get("Item")

    if not customer or customer.get("is_active") is False:
        return error_response(
            message="Customer not found",
            status_code=404
        )

    text_fields = [
        "name",
        "document",
        "phone",
        "email",
        "address"
    ]

    for field in text_fields:
        if field in data:
            customer[field] = normalize_text(data.get(field))

    if "metadata" in data:
        customer["metadata"] = data.get("metadata") or {}

    if "is_active" in data:
        customer["is_active"] = bool(data.get("is_active"))

    customer["updated_at"] = utc_now_iso()

    table.put_item(Item=customer)

    return success_response(
        message="Customer updated successfully",
        data=customer
    )


def delete_customer(event, customer_id):
    """
    Soft delete a customer for the current tenant.

    Sets is_active to False instead of removing the record.

    Args:
        event (dict): API Gateway event
        customer_id (str): Customer identifier

    Returns:
        dict: API response confirming deletion or 404 if not found
    """
    tenant_id = get_tenant_id(event)
    table = get_customers_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "customer_id": customer_id
        }
    )

    customer = result.get("Item")

    if not customer or customer.get("is_active") is False:
        return error_response(
            message="Customer not found",
            status_code=404
        )

    customer["is_active"] = False
    customer["updated_at"] = utc_now_iso()

    table.put_item(Item=customer)

    return success_response(
        message="Customer deleted successfully",
        data={
            "customer_id": customer_id
        }
    )


def normalize_text(value):
    """
    Normalize text value by converting to string and stripping whitespace.

    Args:
        value: Value to normalize

    Returns:
        str: Normalized text or empty string if None
    """
    if value is None:
        return ""

    return str(value).strip()