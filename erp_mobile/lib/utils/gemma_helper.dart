import 'dart:convert';

import 'package:erp_mobile/constants/env.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CreateCustomerTool {
  static const Map<String, dynamic> spec = {
    "type": "function",
    "function": {
      "name": "createCustomer",
      "description":
          "Crea solo un cliente. Usar cuando el usuario pide registrar un cliente y NO pide venta, compra, producto ni inventario.",
      "parameters": {
        "type": "object",
        "properties": {
          "name": {
            "type": "string",
            "description":
                "Nombre completo del cliente. Nunca debe ir vacio; si no hay nombre usa Cliente General.",
          },
          "email": {
            "type": "string",
            "description":
                "Correo del cliente si el usuario lo dijo. Omitir si no existe.",
          },
          "phone": {
            "type": "string",
            "description":
                "Telefono como texto, conservando ceros y prefijos. Omitir si no existe.",
          },
          "address": {
            "type": "string",
            "description": "Direccion fisica. Omitir si no existe.",
          },
          "document": {
            "type": "string",
            "description": "CI, NIT o documento fiscal. Omitir si no existe.",
          },
        },
        "required": ["name"],
        "additionalProperties": false,
      },
    },
  };
}

class CreateProductTool {
  static const Map<String, dynamic> spec = {
    "type": "function",
    "function": {
      "name": "createProduct",
      "description":
          "Crea solo un producto. Usar cuando el usuario pide registrar producto y NO pide venta, compra ni ajuste de inventario.",
      "parameters": {
        "type": "object",
        "properties": {
          "name": {
            "type": "string",
            "description":
                "Nombre del producto. Nunca debe ir vacio; extraer el articulo principal del prompt.",
          },
          "sku": {
            "type": "string",
            "description":
                "SKU en mayusculas. Si el usuario no lo da, generarlo con 3 letras del producto + -001. Ej: Arroz -> ARR-001.",
          },
          "price": {
            "type": "number",
            "description":
                "Precio de venta en Bs. Si solo hay costo, usar costo * 1.30 redondeado a 2 decimales.",
          },
          "cost": {
            "type": "number",
            "description":
                "Costo en Bs. Si no se indica, usar price * 0.70 redondeado a 2 decimales.",
          },
          "description": {
            "type": "string",
            "description": "Descripcion breve. Omitir si no existe.",
          },
          "category": {
            "type": "string",
            "description":
                "Categoria del producto. Si no se indica, usar General.",
          },
          "unit": {
            "type": "string",
            "description":
                "Unidad de medida. Usar unidad si no se indica otra: caja, kg, litro, paquete, etc.",
          },
        },
        "required": ["name", "sku", "price", "cost", "category", "unit"],
        "additionalProperties": false,
      },
    },
  };
}

class CreateSaleTool {
  static const Map<String, dynamic> spec = {
    "type": "function",
    "function": {
      "name": "createSale",
      "description":
          "Crea una venta usando product_id existentes. NO usar si el usuario solo da nombre del producto; en ese caso usar quickSale.",
      "parameters": {
        "type": "object",
        "properties": {
          "customer_id": {
            "type": "string",
            "description":
                "ID real del cliente existente. Omitir si no existe.",
          },
          "items": {
            "type": "array",
            "description":
                "Productos vendidos. Usar solo cuando cada item tenga product_id real.",
            "items": {
              "type": "object",
              "properties": {
                "product_id": {
                  "type": "string",
                  "description": "ID real del producto existente.",
                },
                "quantity": {
                  "type": "number",
                  "description": "Cantidad vendida. Si falta, usar 1.",
                },
                "unit_price": {
                  "type": "number",
                  "description": "Precio unitario de venta.",
                },
              },
              "required": ["product_id", "quantity", "unit_price"],
              "additionalProperties": false,
            },
          },
        },
        "required": ["items"],
        "additionalProperties": false,
      },
    },
  };
}

class CreatePurchaseTool {
  static const Map<String, dynamic> spec = {
    "type": "function",
    "function": {
      "name": "createPurchase",
      "description":
          "Crea una compra usando product_id existentes. NO usar si el usuario solo da nombre del producto; en ese caso usar quickPurchase.",
      "parameters": {
        "type": "object",
        "properties": {
          "supplier_name": {
            "type": "string",
            "description": "Nombre del proveedor.",
          },
          "items": {
            "type": "array",
            "description":
                "Productos comprados. Usar solo cuando cada item tenga product_id real.",
            "items": {
              "type": "object",
              "properties": {
                "product_id": {
                  "type": "string",
                  "description": "ID real del producto existente.",
                },
                "quantity": {
                  "type": "number",
                  "description": "Cantidad comprada. Si falta, usar 1.",
                },
                "unit_cost": {
                  "type": "number",
                  "description": "Costo unitario de compra.",
                },
              },
              "required": ["product_id", "quantity", "unit_cost"],
              "additionalProperties": false,
            },
          },
        },
        "required": ["supplier_name", "items"],
        "additionalProperties": false,
      },
    },
  };
}

class AdjustInventoryTool {
  static const Map<String, dynamic> spec = {
    "type": "function",
    "function": {
      "name": "adjustInventory",
      "description":
          "Ajusta stock/inventario de un producto existente. Usar para aumentar, disminuir, corregir, sumar, restar o inicializar stock.",
      "parameters": {
        "type": "object",
        "properties": {
          "productId": {
            "type": "string",
            "description":
                "ID real del producto existente. No usar nombre de producto aqui.",
          },
          "type": {
            "type": "string",
            "enum": ["ADJUSTMENT_IN", "ADJUSTMENT_OUT"],
            "description":
                "ADJUSTMENT_IN para sumar stock, ADJUSTMENT_OUT para restar stock.",
          },
          "quantity": {
            "type": "number",
            "description": "Cantidad positiva a ajustar. Nunca usar negativos.",
          },
          "reason": {
            "type": "string",
            "description":
                "Motivo del ajuste. Ej: MANUAL_ADJUSTMENT, INITIAL_STOCK, DAMAGE, LOSS.",
          },
          "note": {
            "type": "string",
            "description": "Nota opcional del ajuste.",
          },
        },
        "required": ["productId", "type", "quantity", "reason"],
        "additionalProperties": false,
      },
    },
  };
}

class QuickSaleTool {
  static const Map<String, dynamic> spec = {
    "type": "function",
    "function": {
      "name": "quickSale",
      "description":
          "Registra una venta rapida en una sola operacion. Usar para vender, registrar venta, facturar, cobrar o vender a un cliente cuando el prompt trae nombres/datos y no IDs.",
      "parameters": {
        "type": "object",
        "properties": {
          "customer_name": {
            "type": "string",
            "description":
                "Nombre del cliente. Si no se indica cliente, usar Cliente General.",
          },
          "customer_phone": {
            "type": "string",
            "description":
                "Telefono del cliente si aparece. Omitir si no existe.",
          },
          "customer_email": {
            "type": "string",
            "description": "Email del cliente si aparece. Omitir si no existe.",
          },
          "product_name": {
            "type": "string",
            "description":
                "Producto vendido, sin cantidad ni precio. Ej: 2 cajas de leche -> leche.",
          },
          "product_sku": {
            "type": "string",
            "description":
                "SKU en mayusculas. Si no se indica, generar con 3 letras del producto + -001. Ej: laptop -> LAP-001.",
          },
          "product_price": {
            "type": "number",
            "description":
                "Precio de venta del producto. Debe ser igual a sale_unit_price salvo que el usuario diferencie precio catalogo y precio de venta.",
          },
          "product_cost": {
            "type": "number",
            "description":
                "Costo estimado del producto. Si no se indica, usar product_price * 0.70 redondeado a 2 decimales.",
          },
          "sale_quantity": {
            "type": "number",
            "description": "Cantidad vendida. Si no se indica, usar 1.",
          },
          "sale_unit_price": {
            "type": "number",
            "description":
                "Precio unitario cobrado en la venta, sin moneda ni texto.",
          },
        },
        "required": [
          "customer_name",
          "product_name",
          "product_sku",
          "product_price",
          "product_cost",
          "sale_quantity",
          "sale_unit_price",
        ],
        "additionalProperties": false,
      },
    },
  };
}

class QuickPurchaseTool {
  static const Map<String, dynamic> spec = {
    "type": "function",
    "function": {
      "name": "quickPurchase",
      "description":
          "Registra una compra rapida en una sola operacion. Usar para comprar mercaderia, abastecer, adquirir productos de proveedor o registrar ingreso por compra.",
      "parameters": {
        "type": "object",
        "properties": {
          "supplier_name": {
            "type": "string",
            "description":
                "Nombre del proveedor. Si no se indica, usar Proveedor General.",
          },
          "product_name": {
            "type": "string",
            "description":
                "Producto comprado, sin cantidad ni costo. Ej: compra 10 celulares -> celulares.",
          },
          "product_sku": {
            "type": "string",
            "description":
                "SKU en mayusculas. Si no se indica, generar con 3 letras del producto + -001. Ej: celular -> CEL-001.",
          },
          "product_price": {
            "type": "number",
            "description":
                "Precio de venta sugerido. Si no se indica, usar product_cost * 1.30 redondeado a 2 decimales.",
          },
          "product_cost": {
            "type": "number",
            "description":
                "Costo unitario del producto comprado. Igual a purchase_unit_cost si no hay otro costo.",
          },
          "purchase_quantity": {
            "type": "number",
            "description": "Cantidad comprada. Si no se indica, usar 1.",
          },
          "purchase_unit_cost": {
            "type": "number",
            "description":
                "Costo unitario pagado en la compra, sin moneda ni texto.",
          },
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
        "additionalProperties": false,
      },
    },
  };
}

String initialPrompt = """
Eres el asistente de un sistema ERP. Convierte el mensaje del usuario en llamadas a tools con argumentos JSON correctos. Responde con function calls, no con explicaciones.

Reglas principales:
- Para ventas naturales usa quickSale.
- Para compras naturales usa quickPurchase.
- Para crear solo un cliente usa createCustomer.
- Para crear solo un producto usa createProduct.
- Usa createSale/createPurchase solo si el usuario proporciona product_id reales.
- Usa adjustInventory para sumar/restar/corregir stock con un productId real.
- Nunca dejes vacios los campos requeridos.
- No uses objetos anidados en quickSale ni quickPurchase; sus argumentos son planos.

Valores por defecto:
- customer_name: "Cliente General" si no hay cliente.
- supplier_name: "Proveedor General" si no hay proveedor.
- quantity: 1 si no hay cantidad.
- category: "General" si no hay categoria.
- unit: "unit" si no hay unidad.
- sku: primeras 3 letras significativas del producto en mayusculas + "-001".
- product_cost en ventas: product_price * 0.70.
- product_price en compras: product_cost * 1.30.
- Telefonos y documentos siempre como string.
- Montos como "Bs", "bolivianos" o "\$" deben convertirse a number sin moneda.

Ejemplos:
Usuario: "Vende 2 laptops a 1200 Bs a Juan Perez telefono 70000000"
Tool: quickSale
Args: {"customer_name":"Juan Perez","customer_phone":"70000000","product_name":"laptop","product_sku":"LAP-001","product_price":1200,"product_cost":840,"sale_quantity":2,"sale_unit_price":1200}

Usuario: "Compra 10 celulares a 500 Bs de Proveedor X"
Tool: quickPurchase
Args: {"supplier_name":"Proveedor X","product_name":"celulares","product_sku":"CEL-001","product_price":650,"product_cost":500,"purchase_quantity":10,"purchase_unit_cost":500}

Usuario: "Crea cliente Ana Lopez telefono 76543210 nit 123"
Tool: createCustomer
Args: {"name":"Ana Lopez","phone":"76543210","document":"123"}

Usuario: "Crea producto Cafe molido precio 45 costo 30 categoria Abarrotes"
Tool: createProduct
Args: {"name":"Cafe molido","sku":"CAF-001","price":45,"cost":30,"category":"Abarrotes","unit":"unit"}
""";

class AiFunctionCall {
  const AiFunctionCall({required this.name, required this.args});

  final String name;
  final Map<String, dynamic> args;
}

class GemmaHelper {
  static const String _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static bool _isReady = false;

  static bool get isReady => _isReady;

  static String get _apiKey => Env.openRouterApiKey;

  static String get modelName => Env.aiModel;

  static List<Map<String, dynamic>> get tools => const [
    CreateCustomerTool.spec,
    CreateProductTool.spec,
    CreateSaleTool.spec,
    CreatePurchaseTool.spec,
    QuickSaleTool.spec,
    QuickPurchaseTool.spec,
    AdjustInventoryTool.spec,
  ];

  static Future<void> loadModelFromFile() async {
    if (_apiKey.trim().isEmpty) {
      throw Exception(
        'Falta configurar la API key del servicio de IA en el archivo .env',
      );
    }

    _isReady = true;
    debugPrint('[AI] Servicio listo para usar modelo: $modelName');
  }

  static Future<void> createChatWithTools() async {
    if (!_isReady) {
      await loadModelFromFile();
    }
  }

  static Future<List<AiFunctionCall>> generateToolCalls(
    String userInput,
  ) async {
    if (!_isReady) {
      await loadModelFromFile();
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://erp-mobile.local',
        'X-Title': 'ERP Mobile IA',
      },
      body: jsonEncode({
        'model': modelName,
        'messages': [
          {'role': 'system', 'content': initialPrompt},
          {'role': 'user', 'content': userInput},
        ],
        'tools': tools,
        'tool_choice': 'required',
        'parallel_tool_calls': true,
        'temperature': 0.1,
        'max_tokens': 1200,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error del servicio de IA ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('El servicio de IA no devolvio respuestas');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final toolCalls = message?['tool_calls'] as List<dynamic>?;
    if (toolCalls == null || toolCalls.isEmpty) {
      throw Exception('El servicio de IA no devolvio acciones para ejecutar');
    }

    return toolCalls.map((rawCall) {
      final call = rawCall as Map<String, dynamic>;
      final function = call['function'] as Map<String, dynamic>;
      final argsRaw = function['arguments'];
      final args = argsRaw is String
          ? jsonDecode(argsRaw) as Map<String, dynamic>
          : Map<String, dynamic>.from(argsRaw as Map);

      return AiFunctionCall(name: function['name'] as String, args: args);
    }).toList();
  }

  static Future<void> unloadModel() async {
    _isReady = false;
  }
}
