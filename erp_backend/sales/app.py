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
        if method == "POST" and resource == "/sales/quick":
            return quick_sale(event)
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

def quick_sale(event):
    body = parse_body(event)
    require_fields(body, ["customer", "product", "sale"])

    customer_data = body["customer"]
    product_data = body["product"]
    sale_data = body["sale"]

    require_fields(customer_data, ["name"])
    require_fields(product_data, ["name", "sku", "price", "cost"])
    require_fields(sale_data, ["quantity", "unit_price"])

    now = now_iso()

    # Create Customer
    customer_id = new_id("CUS")
    customer_item = {
        "customerId": customer_id,
        "name": str(customer_data["name"]).strip(),
        "document": str(customer_data.get("document", "")).strip(),
        "phone": str(customer_data.get("phone", "")).strip(),
        "email": str(customer_data.get("email", "")).strip(),
        "address": str(customer_data.get("address", "")).strip(),
        "isActive": True,
        "createdAt": now,
        "updatedAt": now,
    }
    table(CUSTOMERS_TABLE_ENV).put_item(Item=customer_item)

    # Create Product
    product_id = new_id("PROD")
    product_item = {
        "productId": product_id,
        "sku": str(product_data["sku"]).strip(),
        "name": str(product_data["name"]).strip(),
        "description": str(product_data.get("description", "")).strip(),
        "category": str(product_data.get("category", "")).strip(),
        "unit": str(product_data.get("unit", "unit")).strip(),
        "price": to_decimal(product_data["price"], "price"),
        "cost": to_decimal(product_data["cost"], "cost"),
        "isActive": True,
        "createdAt": now,
        "updatedAt": now,
    }
    table(PRODUCTS_TABLE_ENV).put_item(Item=product_item)

    # Calculate Sale
    quantity = to_positive_int(sale_data["quantity"], "quantity")
    unit_price = to_decimal(sale_data["unit_price"], "unit_price")
    subtotal = unit_price * Decimal(quantity)

    sale_item = {
        "saleId": new_id("SALE"),
        "customerId": customer_id,
        "customerName": customer_item["name"],
        "items": [
            {
                "productId": product_id,
                "productName": product_item["name"],
                "quantity": quantity,
                "unitPrice": unit_price,
                "subtotal": subtotal,
            }
        ],
        "total": subtotal,
        "createdAt": now,
    }
    table(SALES_TABLE_ENV).put_item(Item=sale_item)

    # Inventory Update
    new_stock = -quantity
    inventory_item = {
        "productId": product_id,
        "stock": new_stock,
        "minStock": 0,
        "updatedAt": now,
    }
    table(INVENTORY_TABLE_ENV).put_item(Item=inventory_item)

    movement = {
        "movementId": new_id("MOV"),
        "productId": product_id,
        "type": "SALE",
        "quantity": -quantity,
        "reason": f"Quick Sale {sale_item['saleId']}",
        "createdAt": now,
    }
    table(MOVEMENTS_TABLE_ENV).put_item(Item=movement)

    return success({
        "customer": customer_item,
        "product": product_item,
        "sale": sale_item,
        "inventory": inventory_item
    }, "Quick sale created", 201)
