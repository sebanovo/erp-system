import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:file_picker/file_picker.dart';

class CreateCustomerTool {
  static const Tool spec = Tool(
    name: 'createCustomer',
    description: 'Creates a new customer in the ERP system.',
    parameters: {
      "type": "object",
      "properties": {
        "name": {"type": "string", "description": "Full name of the customer."},
        "email": {"type": "string", "description": "Email address."},
        "phone": {"type": "string", "description": "Phone number."},
        "address": {"type": "string", "description": "Physical address."},
        "document": {"type": "string", "description": "Tax ID or document."},
      },
      "required": ["name"],
    },
  );
}

class CreateProductTool {
  static const Tool spec = Tool(
    name: 'createProduct',
    description: 'Creates a new product in the ERP system.',
    parameters: {
      "type": "object",
      "properties": {
        "name": {"type": "string", "description": "Product name."},
        "sku": {"type": "string", "description": "Unique SKU identifier."},
        "price": {"type": "number", "description": "Selling price."},
        "cost": {"type": "number", "description": "Cost price."},
        "description": {
          "type": "string",
          "description": "Product description.",
        },
        "category": {"type": "string", "description": "Product category."},
        "unit": {"type": "string", "description": "Unit of measurement."},
      },
      "required": ["name", "sku", "price"],
    },
  );
}

class CreateSaleTool {
  static const Tool spec = Tool(
    name: 'createSale',
    description: 'Creates a new sale in the ERP system.',
    parameters: {
      "type": "object",
      "properties": {
        "customer_id": {
          "type": "string",
          "description": "Customer ID (optional).",
        },
        "items": {
          "type": "array",
          "description": "List of products sold.",
          "items": {
            "type": "object",
            "properties": {
              "product_id": {"type": "string", "description": "Product ID."},
              "quantity": {"type": "number", "description": "Quantity sold."},
              "unit_price": {
                "type": "number",
                "description": "Price per unit.",
              },
            },
            "required": ["product_id", "quantity", "unit_price"],
          },
        },
      },
      "required": ["items"],
    },
  );
}

class CreatePurchaseTool {
  static const Tool spec = Tool(
    name: 'createPurchase',
    description: 'Creates a new purchase order in the ERP system.',
    parameters: {
      "type": "object",
      "properties": {
        "supplier_name": {
          "type": "string",
          "description": "Name of the supplier.",
        },
        "items": {
          "type": "array",
          "description": "List of products purchased.",
          "items": {
            "type": "object",
            "properties": {
              "product_id": {"type": "string", "description": "Product ID."},
              "quantity": {
                "type": "number",
                "description": "Quantity purchased.",
              },
              "unit_cost": {"type": "number", "description": "Cost per unit."},
            },
            "required": ["product_id", "quantity", "unit_cost"],
          },
        },
      },
      "required": ["supplier_name", "items"],
    },
  );
}

class AdjustInventoryTool {
  static const Tool spec = Tool(
    name: 'adjustInventory',
    description: 'Adjusts stock of a product (increase or decrease).',
    parameters: {
      "type": "object",
      "properties": {
        "productId": {"type": "string", "description": "Product ID."},
        "type": {
          "type": "string",
          "enum": ["ADJUSTMENT_IN", "ADJUSTMENT_OUT"],
          "description":
              "Type of adjustment: ADJUSTMENT_IN (add stock) or ADJUSTMENT_OUT (remove stock).",
        },
        "quantity": {"type": "number", "description": "Quantity to adjust."},
        "reason": {
          "type": "string",
          "description":
              "Reason for adjustment (e.g., MANUAL_ADJUSTMENT, INITIAL_STOCK, etc.).",
        },
        "note": {
          "type": "string",
          "description": "Optional note about the adjustment.",
        },
      },
      "required": ["productId", "type", "quantity", "reason"],
    },
  );
}

class QuickSaleTool {
  static const Tool spec = Tool(
    name: 'quickSale',
    description: 'Creates a sale with customer and product in one operation.',
    parameters: {
      "type": "object",
      "properties": {
        // Cliente (plano)
        "customer_name": {"type": "string"},
        "customer_phone": {"type": "string"},
        "customer_email": {"type": "string"},
        // Producto (plano)
        "product_name": {"type": "string"},
        "product_sku": {"type": "string"},
        "product_price": {"type": "number"},
        "product_cost": {"type": "number"},
        // Venta (plano)
        "sale_quantity": {"type": "number"},
        "sale_unit_price": {"type": "number"},
      },
      "required": [
        "customer_name",
        "product_name",
        "product_sku",
        "product_price",
        "sale_quantity",
        "sale_unit_price",
      ],
    },
  );
}

class QuickPurchaseTool {
  static const Tool spec = Tool(
    name: 'quickPurchase',
    description: 'Creates a purchase with product in one operation.',
    parameters: {
      "type": "object",
      "properties": {
        "supplier_name": {"type": "string"},
        // Producto (plano)
        "product_name": {"type": "string"},
        "product_sku": {"type": "string"},
        "product_price": {"type": "number"},
        "product_cost": {"type": "number"},
        // Compra (plano)
        "purchase_quantity": {"type": "number"},
        "purchase_unit_cost": {"type": "number"},
      },
      "required": [
        "supplier_name",
        "product_name",
        "product_sku",
        "product_price",
        "product_cost",
        "purchase_quantity",
        "purchase_unit_cost",
      ],
    },
  );
}

// String initialPrompt = """
// Eres un asistente de ERP con acceso a herramientas para gestionar:
// - Clientes (createCustomer)
// - Productos (createProduct)
// - Ventas (createSale, quickSale)
// - Compras (createPurchase, quickPurchase)
// - Inventario (adjustInventory)

// REGLAS OBLIGATORIAS:
// 1. Cuando el usuario pida MÚLTIPLES acciones en un solo mensaje, DEBES responder con ParallelFunctionCallResponse que contenga TODAS las llamadas a herramientas.
// 2. Mantén el orden exacto que el usuario solicitó.
// 3. NUNCA generes las herramientas una tras otra como texto separado.
// 4. SIEMPRE completa todas las herramientas antes de finalizar la respuesta.

// Eres un agente de ERP. Cuando el usuario pida "crear un cliente, luego un producto, luego una venta",
// DEBES traducirlo a una sola llamada a quickSale con todos los datos.

// Ejemplo:
// Usuario: "Crea un cliente Juan. Luego crea un producto Laptop. Luego véndele 2 laptops"
// Tú: quickSale(customer:{name:"Juan"}, product:{name:"Laptop", sku:"LP-001", price:1000}, sale:{quantity:2, unit_price:1000})

// NUNCA intentes ejecutar createCustomer, createProduct y createSale por separado.
// SIEMPRE usa quickSale para ventas que requieren crear cliente y/o producto.

// Ejemplo correcto:
// Usuario: "Crea un cliente Juan y un producto Manzana"
// Respuesta: ParallelFunctionCallResponse con 2 tool calls (createCustomer, createProduct)

// Ejemplo INCORRECTO:
// Usuario: "Crea un cliente Juan y un producto Manzana"
// Respuesta: createCustomer {...} createProduct {...} (texto separado)

// AHORA PROCESA LA SOLICITUD DEL USUARIO.
// """;

// String initialPrompt = """
// Eres un asistente de ERP especializado en procesar solicitudes de ventas y compras rápidas.

// HERRAMIENTAS DISPONIBLES:
// 1. quickSale - Para ventas que requieren crear cliente Y producto (o usar existentes)
// 2. quickPurchase - Para compras que requieren crear producto

// REGLAS OBLIGATORIAS:
// 1. SIEMPRE usa quickSale cuando el usuario mencione "venta", "vender", "comprar cliente", "registrar venta"
// 2. SIEMPRE usa quickPurchase cuando el usuario mencione "compra", "adquirir", "comprar producto"
// 3. NUNCA uses createCustomer, createProduct, createSale, createPurchase por separado
// 4. Extrae TODOS los datos necesarios del mensaje del usuario

// FORMATO DE RESPUESTA:
// - Para ventas: quickSale(customer:{name, phone?}, product:{name, sku, price, cost?}, sale:{quantity, unit_price})
// - Para compras: quickPurchase(supplier_name, product:{name, sku, price, cost}, purchase:{quantity, unit_cost})

// EJEMPLOS:

// Usuario: "Vende 2 laptops de 1200 Bs a Juan Pérez con teléfono 70000000"
// Tú: quickSale(
//   customer: {name: "Juan Pérez", phone: "70000000"},
//   product: {name: "laptop", sku: "LP-001", price: 1200, cost: 900},
//   sale: {quantity: 2, unit_price: 1200}
// )

// Usuario: "Compra 10 celulares a 500 Bs cada uno de Proveedor X"
// Tú: quickPurchase(
//   supplier_name: "Proveedor X",
//   product: {name: "celular", sku: "CEL-001", price: 800, cost: 500},
//   purchase: {quantity: 10, unit_cost: 500}
// )

// Usuario: "Registra venta de 3 monitores de 300 Bs para María López"
// Tú: quickSale(
//   customer: {name: "María López"},
//   product: {name: "monitor", sku: "MON-001", price: 300, cost: 200},
//   sale: {quantity: 3, unit_price: 300}
// )

// AHORA PROCESA LA SOLICITUD DEL USUARIO.
// """;

String initialPrompt = """
Eres un asistente de ERP. Usa quickSale para ventas y quickPurchase para compras.

quickSale(customer_name, customer_phone?, product_name, product_sku, product_price, sale_quantity, sale_unit_price)
quickPurchase(supplier_name, product_name, product_sku, product_price, product_cost, purchase_quantity, purchase_unit_cost)

Ejemplo:
Usuario: "Vende 2 laptops a 1200 Bs a Juan Pérez teléfono 70000000"
Tú: quickSale(customer_name:"Juan Pérez", customer_phone:"70000000", product_name:"laptop", product_sku:"LP-001", product_price:1200, sale_quantity:2, sale_unit_price:1200)

Usuario: "Compra 10 celulares a 500 Bs de Proveedor X"
Tú: quickPurchase(supplier_name:"Proveedor X", product_name:"celular", product_sku:"CEL-001", product_price:800, product_cost:500, purchase_quantity:10, purchase_unit_cost:500)

AHORA PROCESA LA SOLICITUD DEL USUARIO.
""";

class GemmaHelper {
  static InferenceModel? _model;
  static bool _isReady = false;

  static bool get isReady => _isReady;
  static InferenceModel? get model => _model;

  static Future<void> loadModelFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['task'],
    );
    if (result == null) throw Exception("No se seleccionó ningún archivo");

    final path = result.files.single.path!;
    final name = result.files.single.name;

    // 1. PRIMERO: Instalar el modelo
    await FlutterGemma.installModel(
      modelType: ModelType.qwen, // Qwen2.5
    ).fromFile(path).install();

    // 2. SEGUNDO: Verificar que se instaló
    final isInstalled = await FlutterGemma.isModelInstalled(name);
    debugPrint("#################################");
    debugPrint("Modelo instalado en caché? $isInstalled");
    debugPrint("#################################");

    debugPrint("🔄 Obteniendo modelo activo...");
    // 3. TERCERO: Obtener el modelo activo
    _model = await FlutterGemma.getActiveModel(
      maxTokens: 4096,
      preferredBackend: PreferredBackend.cpu,
    );

    _isReady = true;
    debugPrint("✅ Modelo listo para usar");
  }

  static Future<InferenceChat> createChatWithTools() async {
    if (!_isReady || _model == null) {
      throw Exception(
        "Modelo no cargado. Asegúrate de haber seleccionado un archivo .task",
      );
    }
    return await _model!.createChat(
      tools: [
        CreateCustomerTool.spec,
        CreateProductTool.spec,
        CreateSaleTool.spec,
        CreatePurchaseTool.spec,
        QuickSaleTool.spec,
        QuickPurchaseTool.spec,
        AdjustInventoryTool.spec,
      ],
      modelType: ModelType.qwen,
      toolChoice: ToolChoice.required,
      supportsFunctionCalls: true,
      systemInstruction: initialPrompt,
    );
  }
}
