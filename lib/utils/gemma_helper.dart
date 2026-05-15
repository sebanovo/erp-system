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
        "product_id": {"type": "string", "description": "Product ID."},
        "type": {
          "type": "string",
          "enum": ["IN", "OUT"],
          "description":
              "Type of adjustment: IN (add stock) or OUT (remove stock).",
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
      "required": ["product_id", "type", "quantity", "reason"],
    },
  );
}

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
      maxTokens: 2048,
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
        AdjustInventoryTool.spec,
      ],
      toolChoice: ToolChoice.auto,
      supportsFunctionCalls: true,
      systemInstruction: """
      Eres un asistente de ERP. Trabajas sobre 5 módulos:
      - Cliente
      - Producto
      - Ventas
      - Compras
      - Inventario
      """,
    );
  }
}
