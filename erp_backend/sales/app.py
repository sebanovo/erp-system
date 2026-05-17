from decimal import Decimal

from shared.dynamo import table, scan_all
from shared.ids import new_id, now_iso
from shared.response import error, handle_exception, parse_body, success
from shared.validators import require_fields, to_positive_int, to_decimal

CUSTOMERS_TABLE_ENV = "CUSTOMERS_TABLE"
PRODUCTS_TABLE_ENV = "PRODUCTS_TABLE"
INVENTORY_TABLE_ENV = "INVENTORY_TABLE"
SALES_TABLE_ENV = "SALES_TABLE"
MOVEMENTS_TABLE_ENV = "INVENTORY_MOVEMENTS_TABLE"


def lambda_handler(event, context):
    try:
        method = event.get("httpMethod")
        resource = event.get("resource") or event.get("path")

        if method == "POST" and resource == "/sales":
            return create_sale(event)
        if method == "GET" and resource == "/sales":
            return list_sales()
        if method == "GET" and resource == "/sales/by-customer/{customerId}":
            return list_sales_by_customer(event)

        return error("Route not found", 404)
    except Exception as exc:
        return handle_exception(exc)


def create_sale(event):
    body = parse_body(event)
    require_fields(body, ["customer_id", "items"])

    customer_id = body["customer_id"]
    raw_items = body.get("items") or []
    if not isinstance(raw_items, list) or not raw_items:
        raise ValueError("items must be a non-empty list")

    customers_table = table(CUSTOMERS_TABLE_ENV)
    products_table = table(PRODUCTS_TABLE_ENV)
    inventory_table = table(INVENTORY_TABLE_ENV)
    sales_table = table(SALES_TABLE_ENV)
    movements_table = table(MOVEMENTS_TABLE_ENV)

    customer = customers_table.get_item(Key={"customerId": customer_id}).get("Item")
    if not customer or customer.get("isActive") is False:
        return error("Customer not found or inactive", 404)

    sale_items = []
    total = Decimal("0")

    for raw_item in raw_items:
        require_fields(raw_item, ["product_id", "quantity", "unit_price"])
        product_id = raw_item["product_id"]
        quantity = to_positive_int(raw_item["quantity"], "quantity")
        unit_price = to_decimal(raw_item["unit_price"], "unit_price")

        product = products_table.get_item(Key={"productId": product_id}).get("Item")
        if not product or product.get("isActive") is False:
            return error(f"Product not found or inactive: {product_id}", 404)

        inventory = inventory_table.get_item(Key={"productId": product_id}).get("Item")
        stock = int(inventory.get("stock", 0)) if inventory else 0
        if stock < quantity:
            return error(f"Not enough stock for product {product.get('name')}. Available: {stock}", 409)

        subtotal = Decimal(quantity) * unit_price
        total += subtotal

        sale_items.append({
            "productId": product_id,
            "productName": product.get("name"),
            "quantity": quantity,
            "unitPrice": unit_price,
            "subtotal": subtotal,
            "previousStock": stock,
            "newStock": stock - quantity,
        })

    now = now_iso()
    sale = {
        "saleId": new_id("SALE"),
        "customerId": customer_id,
        "customerName": f"{customer.get('firstName', '')} {customer.get('lastName', '')}".strip(),
        "items": [
            {
                "productId": item["productId"],
                "productName": item["productName"],
                "quantity": item["quantity"],
                "unitPrice": item["unitPrice"],
                "subtotal": item["subtotal"],
            }
            for item in sale_items
        ],
        "total": total,
        "createdAt": now,
    }

    sales_table.put_item(Item=sale)

    movements = []
    updated_inventory = []

    for item in sale_items:
        inventory_item = {
            "productId": item["productId"],
            "stock": item["newStock"],
            "minStock": int(inventory_table.get_item(Key={"productId": item["productId"]}).get("Item", {}).get("minStock", 0)),
            "updatedAt": now,
        }
        inventory_table.put_item(Item=inventory_item)
        updated_inventory.append(inventory_item)

        movement = {
            "movementId": new_id("MOV"),
            "productId": item["productId"],
            "type": "SALE",
            "quantity": -item["quantity"],
            "reason": f"Sale {sale['saleId']}",
            "createdAt": now,
        }
        movements_table.put_item(Item=movement)
        movements.append(movement)

    return success({"sale": sale, "inventory": updated_inventory, "movements": movements}, "Sale created", 201)


def list_sales():
    items = scan_all(table(SALES_TABLE_ENV))
    items.sort(key=lambda x: x.get("createdAt", ""), reverse=True)
    return success(items, "Sales retrieved")


def list_sales_by_customer(event):
    customer_id = (event.get("pathParameters") or {}).get("customerId")
    if not customer_id:
        raise ValueError("customerId is required")

    items = scan_all(table(SALES_TABLE_ENV))
    filtered = [sale for sale in items if sale.get("customerId") == customer_id]
    filtered.sort(key=lambda x: x.get("createdAt", ""), reverse=True)
    return success(filtered, "Customer sales retrieved")
