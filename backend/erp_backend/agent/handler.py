import json
import os
from uuid import uuid4
from decimal import Decimal
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key


AGENT_TABLE_ENV = "AGENT_TABLE_NAME"


# =========================
# Lambda principal
# =========================

def lambda_handler(event, context):
    try:
        body = parse_body(event)

        action = body.get("action")
        payload = body.get("payload") or {}

        if not action:
            return error_response("Missing action", status_code=400)

        if action == "create_customer":
            return create_customer(payload)

        if action == "create_product":
            return create_product(payload)

        if action == "list_products":
            return list_products()

        if action == "get_inventory":
            return get_inventory()

        if action == "register_purchase":
            return register_purchase(payload)

        if action == "register_sale":
            return register_sale(payload)

        if action == "get_summary":
            return get_summary()

        return error_response(f"Unknown action: {action}", status_code=400)

    except ValueError as exc:
        return error_response(str(exc), status_code=400)

    except Exception as exc:
        return error_response(
            "Internal server error",
            error=str(exc),
            status_code=500
        )


# =========================
# Acciones del agente
# =========================

def create_customer(payload):
    name = normalize_text(payload.get("name"))
    phone = normalize_text(payload.get("phone"))

    if not name:
        raise ValueError("name is required")

    existing_customer = find_customer_by_name(name)

    if existing_customer:
        return success_response(
            "Customer already exists",
            data=existing_customer
        )

    now = utc_now()
    customer = {
        "entity_type": "CUSTOMER",
        "entity_id": generate_id("CUS"),
        "name": name,
        "name_key": normalize_key(name),
        "phone": phone,
        "created_at": now
    }

    table().put_item(Item=customer)

    return success_response(
        "Customer created",
        data=customer,
        status_code=201
    )


def create_product(payload):
    name = normalize_text(payload.get("name"))

    if not name:
        raise ValueError("name is required")

    price = to_decimal(payload.get("price"), "price", required=True)
    cost = to_decimal(payload.get("cost", 0), "cost", required=False)
    stock = to_decimal(payload.get("stock", 0), "stock", required=False)

    if stock < 0:
        raise ValueError("stock must be greater than or equal to zero")

    existing_product = find_product_by_name(name)

    if existing_product:
        return success_response(
            "Product already exists",
            data=existing_product
        )

    now = utc_now()
    product = {
        "entity_type": "PRODUCT",
        "entity_id": generate_id("PROD"),
        "name": name,
        "name_key": normalize_key(name),
        "price": price,
        "cost": cost,
        "stock": stock,
        "created_at": now,
        "updated_at": now
    }

    table().put_item(Item=product)

    return success_response(
        "Product created",
        data=product,
        status_code=201
    )


def list_products():
    products = query_by_type("PRODUCT")

    return success_response(
        "Products retrieved",
        data=products
    )


def get_inventory():
    products = query_by_type("PRODUCT")

    inventory = []

    for product in products:
        inventory.append({
            "product_id": product.get("entity_id"),
            "product_name": product.get("name"),
            "price": product.get("price", 0),
            "cost": product.get("cost", 0),
            "stock": product.get("stock", 0)
        })

    return success_response(
        "Inventory retrieved",
        data=inventory
    )


def register_purchase(payload):
    product_name = normalize_text(payload.get("product_name"))
    product_id = normalize_text(payload.get("product_id"))
    supplier_name = normalize_text(payload.get("supplier_name")) or "General Supplier"

    quantity = to_decimal(payload.get("quantity"), "quantity", required=True)
    unit_cost = to_decimal(payload.get("unit_cost"), "unit_cost", required=True)

    if quantity <= 0:
        raise ValueError("quantity must be greater than zero")

    product = find_product(product_id=product_id, product_name=product_name)

    if not product:
        raise ValueError("Product not found")

    previous_stock = to_decimal(product.get("stock", 0), "stock")
    new_stock = previous_stock + quantity
    total = quantity * unit_cost
    now = utc_now()

    product["stock"] = new_stock
    product["cost"] = unit_cost
    product["updated_at"] = now

    purchase = {
        "entity_type": "PURCHASE",
        "entity_id": generate_id("PUR"),
        "supplier_name": supplier_name,
        "product_id": product.get("entity_id"),
        "product_name": product.get("name"),
        "quantity": quantity,
        "unit_cost": unit_cost,
        "total": total,
        "previous_stock": previous_stock,
        "new_stock": new_stock,
        "created_at": now
    }

    table().put_item(Item=product)
    table().put_item(Item=purchase)

    return success_response(
        "Purchase registered",
        data={
            "purchase": purchase,
            "product": product
        },
        status_code=201
    )


def register_sale(payload):
    product_name = normalize_text(payload.get("product_name"))
    product_id = normalize_text(payload.get("product_id"))
    customer_name = normalize_text(payload.get("customer_name")) or "Final Customer"

    quantity = to_decimal(payload.get("quantity"), "quantity", required=True)

    if quantity <= 0:
        raise ValueError("quantity must be greater than zero")

    product = find_product(product_id=product_id, product_name=product_name)

    if not product:
        raise ValueError("Product not found")

    previous_stock = to_decimal(product.get("stock", 0), "stock")

    if previous_stock < quantity:
        return error_response(
            "Insufficient stock",
            error={
                "product_name": product.get("name"),
                "available": previous_stock,
                "requested": quantity
            },
            status_code=400
        )

    unit_price = payload.get("unit_price")

    if unit_price is None:
        unit_price = product.get("price", 0)

    unit_price = to_decimal(unit_price, "unit_price", required=True)

    customer = find_customer_by_name(customer_name)

    if not customer:
        customer = {
            "entity_type": "CUSTOMER",
            "entity_id": generate_id("CUS"),
            "name": customer_name,
            "name_key": normalize_key(customer_name),
            "phone": "",
            "created_at": utc_now()
        }
        table().put_item(Item=customer)

    new_stock = previous_stock - quantity
    total = quantity * unit_price
    now = utc_now()

    product["stock"] = new_stock
    product["updated_at"] = now

    sale = {
        "entity_type": "SALE",
        "entity_id": generate_id("SALE"),
        "customer_id": customer.get("entity_id"),
        "customer_name": customer.get("name"),
        "product_id": product.get("entity_id"),
        "product_name": product.get("name"),
        "quantity": quantity,
        "unit_price": unit_price,
        "total": total,
        "previous_stock": previous_stock,
        "new_stock": new_stock,
        "created_at": now
    }

    table().put_item(Item=product)
    table().put_item(Item=sale)

    return success_response(
        "Sale registered",
        data={
            "sale": sale,
            "product": product
        },
        status_code=201
    )


def get_summary():
    products = query_by_type("PRODUCT")
    customers = query_by_type("CUSTOMER")
    purchases = query_by_type("PURCHASE")
    sales = query_by_type("SALE")

    total_stock = sum_decimal(products, "stock")
    total_sales = sum_decimal(sales, "total")
    total_purchases = sum_decimal(purchases, "total")

    return success_response(
        "Summary retrieved",
        data={
            "products_count": len(products),
            "customers_count": len(customers),
            "purchases_count": len(purchases),
            "sales_count": len(sales),
            "total_stock": total_stock,
            "total_purchases": total_purchases,
            "total_sales": total_sales
        }
    )


# =========================
# DynamoDB helpers
# =========================

def table():
    table_name = os.environ.get(AGENT_TABLE_ENV)

    if not table_name:
        raise RuntimeError("Missing AGENT_TABLE_NAME environment variable")

    dynamodb = boto3.resource("dynamodb")
    return dynamodb.Table(table_name)


def query_by_type(entity_type):
    result = table().query(
        KeyConditionExpression=Key("entity_type").eq(entity_type)
    )

    return result.get("Items", [])


def find_product(product_id=None, product_name=None):
    if product_id:
        result = table().get_item(
            Key={
                "entity_type": "PRODUCT",
                "entity_id": product_id
            }
        )

        product = result.get("Item")

        if product:
            return product

    if product_name:
        return find_product_by_name(product_name)

    return None


def find_product_by_name(name):
    name_key = normalize_key(name)
    products = query_by_type("PRODUCT")

    for product in products:
        if product.get("name_key") == name_key:
            return product

    return None


def find_customer_by_name(name):
    name_key = normalize_key(name)
    customers = query_by_type("CUSTOMER")

    for customer in customers:
        if customer.get("name_key") == name_key:
            return customer

    return None


# =========================
# Utilidades
# =========================

def parse_body(event):
    raw_body = event.get("body")

    if not raw_body:
        return {}

    if isinstance(raw_body, dict):
        return raw_body

    try:
        return json.loads(raw_body, parse_float=Decimal, parse_int=Decimal)
    except json.JSONDecodeError:
        raise ValueError("Invalid JSON body")


def normalize_text(value):
    if value is None:
        return ""

    return str(value).strip()


def normalize_key(value):
    return normalize_text(value).lower()


def to_decimal(value, field_name, required=False):
    if value is None or value == "":
        if required:
            raise ValueError(f"{field_name} is required")

        return Decimal("0")

    try:
        number = Decimal(str(value))
    except Exception:
        raise ValueError(f"{field_name} must be a valid number")

    if number < 0:
        raise ValueError(f"{field_name} must be greater than or equal to zero")

    return number


def generate_id(prefix):
    return f"{prefix}-{uuid4().hex[:10].upper()}"


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def sum_decimal(items, field):
    total = Decimal("0")

    for item in items:
        total += to_decimal(item.get(field, 0), field)

    return total


# =========================
# Respuestas HTTP
# =========================

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            if obj % 1 == 0:
                return int(obj)

            return float(obj)

        return super().default(obj)


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,x-tenant-id",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS"
        },
        "body": json.dumps(body, cls=DecimalEncoder)
    }


def success_response(message, data=None, status_code=200):
    return response(
        status_code,
        {
            "ok": True,
            "message": message,
            "data": data
        }
    )


def error_response(message, error=None, status_code=400):
    return response(
        status_code,
        {
            "ok": False,
            "message": message,
            "error": error
        }
    )