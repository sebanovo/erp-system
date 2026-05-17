"""
Products module for the Serverless ERP application.

This module handles CRUD operations for products in the ERP system.
It provides endpoints for listing, creating, retrieving, updating, and deleting products.
All operations are tenant-aware and use DynamoDB for data storage.
"""

from boto3.dynamodb.conditions import Key

from shared.dates import utc_now_iso
from shared.dynamodb import get_table
from shared.ids import generate_product_id
from shared.response import success_response, error_response
from shared.tenant import get_tenant_id
from shared.validation import (
    parse_json_body,
    require_fields,
    require_non_negative_decimal,
)


PRODUCTS_TABLE_ENV = "PRODUCTS_TABLE_NAME"


def lambda_handler(event, context):
    """
    Main Lambda handler for product operations.

    Routes HTTP requests to appropriate handler functions based on method and path.
    Supports GET, POST, PUT, DELETE methods for products.

    Args:
        event (dict): API Gateway event containing request details
        context: Lambda context object

    Returns:
        dict: API response with appropriate status code and data
    """
    try:
        http_method = event.get("httpMethod")
        path_parameters = event.get("pathParameters") or {}
        product_id = path_parameters.get("product_id")

        if http_method == "GET" and product_id:
            return get_product(event, product_id)

        if http_method == "GET":
            return list_products(event)

        if http_method == "POST":
            return create_product(event)

        if http_method == "PUT" and product_id:
            return update_product(event, product_id)

        if http_method == "DELETE" and product_id:
            return delete_product(event, product_id)

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
        product_id = path_parameters.get("product_id")

        if http_method == "GET" and product_id:
            return get_product(event, product_id)

        if http_method == "GET":
            return list_products(event)

        if http_method == "POST":
            return create_product(event)

        if http_method == "PUT" and product_id:
            return update_product(event, product_id)

        if http_method == "DELETE" and product_id:
            return delete_product(event, product_id)

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
    """
    Get the DynamoDB table resource for products.

    Returns:
        boto3.dynamodb.Table: Products table instance
    """
    return get_table(PRODUCTS_TABLE_ENV)


def list_products(event):
    """
    List all active products for the current tenant.

    Args:
        event (dict): API Gateway event

    Returns:
        dict: API response with list of products
    """
    tenant_id = get_tenant_id(event)
    table = get_products_table()

    result = table.query(
        KeyConditionExpression=Key("tenant_id").eq(tenant_id)
    )

    products = result.get("Items", [])

    active_products = [
        product for product in products
        if product.get("is_active", True) is True
    ]

    return success_response(
        message="Products retrieved successfully",
        data=active_products
    )


def get_product(event, product_id):
    """
    Retrieve a specific product by ID for the current tenant.

    Args:
        event (dict): API Gateway event
        product_id (str): Product identifier

    Returns:
        dict: API response with product data or 404 if not found
    """
    tenant_id = get_tenant_id(event)
    table = get_products_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "product_id": product_id
        }
    )

    product = result.get("Item")

    if not product or product.get("is_active") is False:
        return error_response(
            message="Product not found",
            status_code=404
        )

    return success_response(
        message="Product retrieved successfully",
        data=product
    )


def create_product(event):
    """
    Create a new product for the current tenant.

    Validates required fields and creates a product with generated ID.

    Args:
        event (dict): API Gateway event with product data in body

    Returns:
        dict: API response with created product data
    """
    tenant_id = get_tenant_id(event)
    data = parse_json_body(event)

    require_fields(
        data,
        [
            "sku",
            "name",
            "unit",
            "price",
            "cost"
        ]
    )

    price = require_non_negative_decimal(data.get("price"), "price")
    cost = require_non_negative_decimal(data.get("cost"), "cost")

    product_id = generate_product_id()
    now = utc_now_iso()

    product = {
        "tenant_id": tenant_id,
        "product_id": product_id,
        "sku": str(data.get("sku")).strip(),
        "name": str(data.get("name")).strip(),
        "description": str(data.get("description", "")).strip(),
        "category": str(data.get("category", "")).strip(),
        "unit": str(data.get("unit")).strip(),
        "price": price,
        "cost": cost,
        "metadata": data.get("metadata") or {},
        "is_active": True,
        "created_at": now,
        "updated_at": now
    }

    table = get_products_table()
    table.put_item(Item=product)

    return success_response(
        message="Product created successfully",
        data=product,
        status_code=201
    )


def update_product(event, product_id):
    """
    Update an existing product for the current tenant.

    Only allows updating specific editable fields. Validates price/cost if provided.

    Args:
        event (dict): API Gateway event with update data in body
        product_id (str): Product identifier

    Returns:
        dict: API response with updated product data or 404 if not found
    """
    tenant_id = get_tenant_id(event)
    data = parse_json_body(event)
    table = get_products_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "product_id": product_id
        }
    )

    product = result.get("Item")

    if not product or product.get("is_active") is False:
        return error_response(
            message="Product not found",
            status_code=404
        )

    editable_fields = [
        "sku",
        "name",
        "description",
        "category",
        "unit",
        "metadata",
        "is_active"
    ]

    for field in editable_fields:
        if field in data:
            product[field] = data[field]

    if "price" in data:
        product["price"] = require_non_negative_decimal(data.get("price"), "price")

    if "cost" in data:
        product["cost"] = require_non_negative_decimal(data.get("cost"), "cost")

    product["updated_at"] = utc_now_iso()

    table.put_item(Item=product)

    return success_response(
        message="Product updated successfully",
        data=product
    )


def delete_product(event, product_id):
    """
    Soft delete a product for the current tenant.

    Sets is_active to False instead of removing the record.

    Args:
        event (dict): API Gateway event
        product_id (str): Product identifier

    Returns:
        dict: API response confirming deletion or 404 if not found
    """
    tenant_id = get_tenant_id(event)
    table = get_products_table()

    result = table.get_item(
        Key={
            "tenant_id": tenant_id,
            "product_id": product_id
        }
    )

    product = result.get("Item")

    if not product or product.get("is_active") is False:
        return error_response(
            message="Product not found",
            status_code=404
        )

    product["is_active"] = False
    product["updated_at"] = utc_now_iso()

    table.put_item(Item=product)

    return success_response(
        message="Product deleted successfully",
        data={
            "product_id": product_id
        }
    )