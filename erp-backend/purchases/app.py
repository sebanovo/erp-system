from decimal import Decimal

from shared.dynamo import table, scan_all
from shared.ids import new_id, now_iso
from shared.response import error, handle_exception, parse_body, success
from shared.validators import require_fields, to_decimal, to_positive_int

PRODUCTS_TABLE_ENV = "PRODUCTS_TABLE"
INVENTORY_TABLE_ENV = "INVENTORY_TABLE"
PURCHASES_TABLE_ENV = "PURCHASES_TABLE"
MOVEMENTS_TABLE_ENV = "INVENTORY_MOVEMENTS_TABLE"


def lambda_handler(event, context):
    try:
        method = event.get("httpMethod")
        resource = event.get("resource") or event.get("path")

        if method == "POST" and resource == "/purchases":
            return create_purchase(event)
        if method == "POST" and resource == "/purchases/quick":
            return quick_purchase(event)
        if method == "GET" and resource == "/purchases":
            return list_purchases()

        return error("Route not found", 404)
    except Exception as exc:
        return handle_exception(exc)


def create_purchase(event):
    body = parse_body(event)
    require_fields(body, ["supplier_name", "items"])
    supplier_name = body["supplier_name"]
    raw_items = body.get("items") or []
    if not isinstance(raw_items, list) or not raw_items:
        raise ValueError("items must be a non-empty list")

    purchases_table = table(PURCHASES_TABLE_ENV)
    inventory_table = table(INVENTORY_TABLE_ENV)
    movements_table = table(MOVEMENTS_TABLE_ENV)
    products_table = table(PRODUCTS_TABLE_ENV)

    purchase_items = []
    total = Decimal("0")

    for raw_item in raw_items:
        require_fields(raw_item, ["product_id", "quantity", "unit_cost"])
        product_id = raw_item["product_id"]
        quantity = to_positive_int(raw_item["quantity"], "quantity")
        unit_cost = to_decimal(raw_item["unit_cost"], "unit_cost")

        product = products_table.get_item(Key={"productId": product_id}).get("Item")
        if not product or product.get("isActive") is False:
            return error(f"Product not found or inactive: {product_id}", 404)

        subtotal = Decimal(quantity) * unit_cost
        total += subtotal

        purchase_items.append({
            "productId": product_id,
            "productName": product.get("name"),
            "quantity": quantity,
            "unitCost": unit_cost,
            "subtotal": subtotal,
        })

    now = now_iso()
    purchase = {
        "purchaseId": new_id("PUR"),
        "supplierName": supplier_name,
        "items": [
            {
                "productId": item["productId"],
                "productName": item["productName"],
                "quantity": item["quantity"],
                "unitCost": item["unitCost"],
                "subtotal": item["subtotal"],
            }
            for item in purchase_items
        ],
        "total": total,
        "createdAt": now,
    }

    purchases_table.put_item(Item=purchase)

    movements = []
    updated_inventory = []

    for item in purchase_items:
        existing_inventory = inventory_table.get_item(Key={"productId": item["productId"]}).get("Item")
        current_stock = int(existing_inventory.get("stock", 0)) if existing_inventory else 0
        min_stock = int(existing_inventory.get("minStock", 0)) if existing_inventory else 0
        new_stock = current_stock + item["quantity"]

        inventory_item = {
            "productId": item["productId"],
            "stock": new_stock,
            "minStock": min_stock,
            "updatedAt": now,
        }
        inventory_table.put_item(Item=inventory_item)
        updated_inventory.append(inventory_item)

        movement = {
            "movementId": new_id("MOV"),
            "productId": item["productId"],
            "type": "PURCHASE",
            "quantity": item["quantity"],
            "reason": f"Purchase {purchase['purchaseId']}",
            "createdAt": now,
        }
        movements_table.put_item(Item=movement)
        movements.append(movement)

    return success({"purchase": purchase, "inventory": updated_inventory, "movements": movements}, "Purchase created", 201)


def list_purchases():
    items = scan_all(table(PURCHASES_TABLE_ENV))
    items.sort(key=lambda x: x.get("createdAt", ""), reverse=True)
    return success(items, "Purchases retrieved")


def quick_purchase(event):
    body = parse_body(event)
    require_fields(body, ["supplier_name", "product", "purchase"])
    supplier_name = str(body["supplier_name"]).strip()
    product_data = body["product"]
    purchase_data = body["purchase"]

    require_fields(product_data, ["name", "sku", "price", "cost"])
    require_fields(purchase_data, ["quantity", "unit_cost"])

    now = now_iso()

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

    # Calculate Purchase
    quantity = to_positive_int(purchase_data["quantity"], "quantity")
    unit_cost = to_decimal(purchase_data["unit_cost"], "unit_cost")
    subtotal = unit_cost * Decimal(quantity)

    purchase_item = {
        "purchaseId": new_id("PUR"),
        "supplierName": supplier_name,
        "items": [
            {
                "productId": product_id,
                "productName": product_item["name"],
                "quantity": quantity,
                "unitCost": unit_cost,
                "subtotal": subtotal,
            }
        ],
        "total": subtotal,
        "createdAt": now,
    }
    table(PURCHASES_TABLE_ENV).put_item(Item=purchase_item)

    # Inventory Update
    inventory_item = {
        "productId": product_id,
        "stock": quantity,
        "minStock": 0,
        "updatedAt": now,
    }
    table(INVENTORY_TABLE_ENV).put_item(Item=inventory_item)

    movement = {
        "movementId": new_id("MOV"),
        "productId": product_id,
        "type": "PURCHASE",
        "quantity": quantity,
        "reason": f"Quick Purchase {purchase_item['purchaseId']}",
        "createdAt": now,
    }
    table(MOVEMENTS_TABLE_ENV).put_item(Item=movement)

    return success({
        "product": product_item,
        "purchase": purchase_item,
        "inventory": inventory_item
    }, "Quick purchase created", 201)
