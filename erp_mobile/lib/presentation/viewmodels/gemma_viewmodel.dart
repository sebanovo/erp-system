// import 'package:erp_mobile/domain/entities/product.dart';
// import 'package:erp_mobile/domain/entities/purchase.dart';
// import 'package:erp_mobile/domain/entities/sale.dart';
// import 'package:erp_mobile/domain/usecases/adjust_inventory.dart';
// import 'package:erp_mobile/domain/usecases/create_product.dart';
// import 'package:erp_mobile/domain/usecases/create_purchase.dart';
// import 'package:erp_mobile/domain/usecases/create_sale.dart';
// import 'package:erp_mobile/utils/gemma_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_gemma/flutter_gemma.dart';
// import 'package:get_it/get_it.dart';
// import '../../domain/entities/customer.dart';
// import '../../domain/usecases/create_customer.dart';

// class GemmaViewModel extends ChangeNotifier {
//   final CreateCustomer _createCustomer = GetIt.instance<CreateCustomer>();
//   final CreateProduct _createProduct = GetIt.instance<CreateProduct>();
//   final CreateSale _createSale = GetIt.instance<CreateSale>();
//   final CreatePurchase _createPurchase = GetIt.instance<CreatePurchase>();
//   final AdjustInventory _adjustInventory = GetIt.instance<AdjustInventory>();

//   bool _isModelReady = false;
//   String _conversationHistory = ""; // ← CAMBIO 1: renombrar
//   bool _isProcessing = false;
//   InferenceChat? _chat;

//   bool get isModelReady => _isModelReady;
//   String get lastResponse =>
//       _conversationHistory; // ← CAMBIO 2: retornar historial
//   bool get isProcessing => _isProcessing;

//   Future<void> loadModel() async {
//     try {
//       await GemmaHelper.loadModelFromFile();
//       _chat = await GemmaHelper.createChatWithTools();
//       _isModelReady = true;
//       _conversationHistory = "✅ Modelo cargado correctamente\n\n";
//       notifyListeners();
//     } catch (e) {
//       _conversationHistory = "❌ Error: $e";
//       notifyListeners();
//     }
//   }

//   Future<void> processCommand(
//     String userInput, {
//     Function(Customer)? onCustomerCreated,
//     Function(Product)? onProductCreated,
//     Function(Sale)? onSaleCreated,
//     Function(Purchase)? onPurchaseCreated,
//     VoidCallback? onInventoryAdjusted,
//   }) async {
//     if (!_isModelReady || _chat == null) {
//       _conversationHistory += "⚠️ Primero carga un modelo\n\n";
//       notifyListeners();
//       return;
//     }

//     _isProcessing = true;

//     // ✅ CAMBIO 3: Agregar mensaje del usuario al historial
//     _conversationHistory += "👤 **Tú:** $userInput\n\n";
//     _conversationHistory += "🤖 **Asistente:** ";
//     notifyListeners();

//     try {
//       await _chat!.clearHistory();
//       await _chat!.addQueryChunk(Message.text(text: userInput, isUser: true));

//       await _chat!.generateChatResponseAsync().listen((response) async {
//         if (response is FunctionCallResponse) {
//           if (response.name == 'createSale') {
//             final args = response.args;
//             final items = (args['items'] as List)
//                 .map(
//                   (item) => SaleItem(
//                     productId: item['product_id'],
//                     quantity: (item['quantity'] as num).toInt(),
//                     unitPrice: (item['unit_price'] as num).toDouble(),
//                     subtotal:
//                         (item['quantity'] as num).toInt() *
//                         (item['unit_price'] as num).toDouble(),
//                     locationId: 'MAIN',
//                   ),
//                 )
//                 .toList();

//             final total = items.fold(0.0, (sum, item) => sum + item.subtotal);

//             final sale = Sale(
//               saleId: '',
//               customerId: args['customer_id'],
//               items: items,
//               total: total,
//               status: 'CONFIRMED',
//               createdAt: DateTime.now(),
//             );
//             await _createSale.call(sale);
//             final responseText =
//                 "✅ Venta creada por ${items.length} producto(s) - Total: $total Bs";
//             _conversationHistory += responseText;
//             notifyListeners();
//             if (onSaleCreated != null) onSaleCreated(sale);
//           } else if (response.name == 'adjustInventory') {
//             final args = response.args;
//             await _adjustInventory.call(
//               productId: args['product_id'],
//               type: args['type'],
//               quantity: (args['quantity'] as num).toInt(),
//               reason: args['reason'],
//               note: args['note'],
//             );
//             final responseText =
//                 "✅ Stock ajustado: ${args['type'] == 'IN' ? '+' : '-'}${args['quantity']} unidades del producto ${args['product_id']}";
//             _conversationHistory += responseText;
//             notifyListeners();
//             if (onInventoryAdjusted != null) onInventoryAdjusted();
//           } else if (response.name == 'createPurchase') {
//             final args = response.args;
//             final items = (args['items'] as List)
//                 .map(
//                   (item) => PurchaseItem(
//                     productId: item['product_id'],
//                     quantity: (item['quantity'] as num).toInt(),
//                     unitCost: (item['unit_cost'] as num).toDouble(),
//                     subtotal:
//                         (item['quantity'] as num).toInt() *
//                         (item['unit_cost'] as num).toDouble(),
//                     locationId: 'MAIN',
//                   ),
//                 )
//                 .toList();

//             final total = items.fold(0.0, (sum, item) => sum + item.subtotal);

//             final purchase = Purchase(
//               purchaseId: '',
//               supplierName: args['supplier_name'] ?? 'Proveedor General',
//               items: items,
//               total: total,
//               status: 'CONFIRMED',
//               createdAt: DateTime.now(),
//             );
//             await _createPurchase.call(purchase);
//             final responseText =
//                 "✅ Compra creada: ${purchase.supplierName} - ${items.length} producto(s) - Total: $total Bs";
//             _conversationHistory += responseText;
//             notifyListeners();
//             if (onPurchaseCreated != null) onPurchaseCreated(purchase);
//           } else if (response.name == 'createProduct') {
//             final args = response.args;
//             final product = Product(
//               productId: '',
//               sku: args['sku'] ?? '',
//               name: args['name'] ?? '',
//               description: args['description'],
//               category: args['category'] ?? 'General',
//               unit: args['unit'] ?? 'unit',
//               price: (args['price'] ?? 0).toDouble(),
//               cost: (args['cost'] ?? 0).toDouble(),
//               isActive: true,
//               metadata: {},
//               createdAt: DateTime.now(),
//               updatedAt: DateTime.now(),
//             );
//             await _createProduct.call(product);
//             final responseText = "✅ Producto creado: ${product.name}";
//             _conversationHistory += responseText;
//             notifyListeners();
//             if (onProductCreated != null) onProductCreated(product);
//           } else if (response.name == 'createCustomer') {
//             final args = response.args;
//             final customer = Customer(
//               id: '',
//               name: args['name'] ?? '',
//               email: args['email'],
//               phone: args['phone'],
//               address: args['address'],
//               document: args['document'],
//               isActive: true,
//             );
//             await _createCustomer.call(customer);
//             final responseText = "✅ Cliente creado: ${customer.name}";
//             _conversationHistory += responseText;
//             notifyListeners();
//             if (onCustomerCreated != null) onCustomerCreated(customer);
//           } else {
//             final responseText = "⚠️ Función desconocida: ${response.name}";
//             _conversationHistory += responseText;
//             notifyListeners();
//           }
//           _conversationHistory += "\n\n";
//         } else if (response is TextResponse) {
//           _conversationHistory += response.token;
//           notifyListeners();
//         }
//       }).asFuture();

//       // Asegurar salto de línea al final
//       if (!_conversationHistory.endsWith('\n\n')) {
//         _conversationHistory += "\n\n";
//       }
//     } catch (e) {
//       _conversationHistory += "❌ Error: $e\n\n";
//       notifyListeners();
//     } finally {
//       _isProcessing = false;
//       notifyListeners();
//     }
//   }

//   Future<void> unloadModel() async {
//     _chat?.close();
//     _chat = null;
//     _isModelReady = false;
//     _conversationHistory = "";
//     _isProcessing = false;
//     notifyListeners();
//   }

//   void clearResponse() {
//     _conversationHistory = "";
//     notifyListeners();
//   }
// }

import 'package:erp_mobile/domain/entities/product.dart';
import 'package:erp_mobile/domain/entities/purchase.dart';
import 'package:erp_mobile/domain/entities/sale.dart';
import 'package:erp_mobile/domain/usecases/adjust_inventory.dart';
import 'package:erp_mobile/domain/usecases/create_product.dart';
import 'package:erp_mobile/domain/usecases/create_purchase.dart';
import 'package:erp_mobile/domain/usecases/create_sale.dart';
import 'package:erp_mobile/utils/gemma_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/create_customer.dart';

class GemmaViewModel extends ChangeNotifier {
  final CreateCustomer _createCustomer = GetIt.instance<CreateCustomer>();
  final CreateProduct _createProduct = GetIt.instance<CreateProduct>();
  final CreateSale _createSale = GetIt.instance<CreateSale>();
  final CreatePurchase _createPurchase = GetIt.instance<CreatePurchase>();
  final AdjustInventory _adjustInventory = GetIt.instance<AdjustInventory>();

  bool _isModelReady = false;
  String _conversationHistory = "";
  bool _isProcessing = false;
  InferenceChat? _chat;

  bool get isModelReady => _isModelReady;
  String get lastResponse => _conversationHistory;
  bool get isProcessing => _isProcessing;

  Future<void> loadModel() async {
    try {
      await GemmaHelper.loadModelFromFile();
      _chat = await GemmaHelper.createChatWithTools();
      _isModelReady = true;
      _conversationHistory = "✅ Modelo cargado correctamente\n\n";
      notifyListeners();
    } catch (e) {
      _conversationHistory = "❌ Error: $e";
      notifyListeners();
    }
  }

  // ✅ Método auxiliar para ejecutar una función individual
  Future<void> _executeFunctionCall(
    FunctionCallResponse call, {
    Function(Customer)? onCustomerCreated,
    Function(Product)? onProductCreated,
    Function(Sale)? onSaleCreated,
    Function(Purchase)? onPurchaseCreated,
    VoidCallback? onInventoryAdjusted,
  }) async {
    final args = call.args;

    switch (call.name) {
      case 'createCustomer':
        final customer = Customer(
          id: '',
          name: args['name'] ?? '',
          email: args['email'],
          phone: args['phone'],
          address: args['address'],
          document: args['document'],
          isActive: true,
        );
        await _createCustomer.call(customer);
        _conversationHistory += "✅ Cliente creado: ${customer.name}\n";
        if (onCustomerCreated != null) onCustomerCreated(customer);
        break;

      case 'createProduct':
        final product = Product(
          productId: '',
          sku: args['sku'] ?? '',
          name: args['name'] ?? '',
          description: args['description'],
          category: args['category'] ?? 'General',
          unit: args['unit'] ?? 'unit',
          price: (args['price'] ?? 0).toDouble(),
          cost: (args['cost'] ?? 0).toDouble(),
          isActive: true,
          metadata: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _createProduct.call(product);
        _conversationHistory +=
            "✅ Producto creado: ${product.name} (SKU: ${product.sku})\n";
        if (onProductCreated != null) onProductCreated(product);
        break;

      case 'createSale':
        final items = (args['items'] as List)
            .map(
              (item) => SaleItem(
                productId: item['product_id'],
                quantity: (item['quantity'] as num).toInt(),
                unitPrice: (item['unit_price'] as num).toDouble(),
                subtotal:
                    (item['quantity'] as num).toInt() *
                    (item['unit_price'] as num).toDouble(),
                locationId: 'MAIN',
              ),
            )
            .toList();
        final total = items.fold(0.0, (sum, item) => sum + item.subtotal);
        final sale = Sale(
          saleId: '',
          customerId: args['customer_id'],
          items: items,
          total: total,
          status: 'CONFIRMED',
          createdAt: DateTime.now(),
        );
        await _createSale.call(sale);
        _conversationHistory +=
            "✅ Venta creada - Total: $total Bs (${items.length} productos)\n";
        if (onSaleCreated != null) onSaleCreated(sale);
        break;

      case 'createPurchase':
        final items = (args['items'] as List)
            .map(
              (item) => PurchaseItem(
                productId: item['product_id'],
                quantity: (item['quantity'] as num).toInt(),
                unitCost: (item['unit_cost'] as num).toDouble(),
                subtotal:
                    (item['quantity'] as num).toInt() *
                    (item['unit_cost'] as num).toDouble(),
                locationId: 'MAIN',
              ),
            )
            .toList();
        final total = items.fold(0.0, (sum, item) => sum + item.subtotal);
        final purchase = Purchase(
          purchaseId: '',
          supplierName: args['supplier_name'] ?? 'Proveedor General',
          items: items,
          total: total,
          status: 'CONFIRMED',
          createdAt: DateTime.now(),
        );
        await _createPurchase.call(purchase);
        _conversationHistory +=
            "✅ Compra creada: ${purchase.supplierName} - Total: $total Bs\n";
        if (onPurchaseCreated != null) onPurchaseCreated(purchase);
        break;

      case 'adjustInventory':
        await _adjustInventory.call(
          productId: args['product_id'],
          type: args['type'],
          quantity: (args['quantity'] as num).toInt(),
          reason: args['reason'],
          note: args['note'],
        );
        _conversationHistory +=
            "✅ Stock ajustado: ${args['type'] == 'IN' ? '+' : '-'}${args['quantity']} unidades\n";
        if (onInventoryAdjusted != null) onInventoryAdjusted();
        break;

      default:
        _conversationHistory += "⚠️ Función desconocida: ${call.name}\n";
    }
    notifyListeners();
  }

  Future<void> processCommand(
    String userInput, {
    Function(Customer)? onCustomerCreated,
    Function(Product)? onProductCreated,
    Function(Sale)? onSaleCreated,
    Function(Purchase)? onPurchaseCreated,
    VoidCallback? onInventoryAdjusted,
  }) async {
    if (!_isModelReady || _chat == null) {
      _conversationHistory += "⚠️ Primero carga un modelo\n\n";
      notifyListeners();
      return;
    }

    _isProcessing = true;

    // Agregar mensaje del usuario al historial
    _conversationHistory += "👤 **Tú:** $userInput\n\n";
    _conversationHistory += "🤖 **Asistente:** ";
    notifyListeners();

    try {
      await _chat!.clearHistory();
      await _chat!.addQueryChunk(Message.text(text: userInput, isUser: true));

      await _chat!.generateChatResponseAsync().listen((response) async {
        // 🔥 TASK CHAINING: Manejar múltiples llamadas en paralelo/secuencial
        if (response is ParallelFunctionCallResponse) {
          print("📞 Tareas encadenadas: ${response.calls.length}");

          // Ejecutar cada función en orden secuencial
          for (final call in response.calls) {
            print("  - Ejecutando: ${call.name}");
            await _executeFunctionCall(
              call,
              onCustomerCreated: onCustomerCreated,
              onProductCreated: onProductCreated,
              onSaleCreated: onSaleCreated,
              onPurchaseCreated: onPurchaseCreated,
              onInventoryAdjusted: onInventoryAdjusted,
            );
          }
          _conversationHistory += "\n✅ Todas las tareas completadas\n\n";
          notifyListeners();
        }
        // Manejar llamada única
        else if (response is FunctionCallResponse) {
          await _executeFunctionCall(
            response,
            onCustomerCreated: onCustomerCreated,
            onProductCreated: onProductCreated,
            onSaleCreated: onSaleCreated,
            onPurchaseCreated: onPurchaseCreated,
            onInventoryAdjusted: onInventoryAdjusted,
          );
          _conversationHistory += "\n\n";
        }
        // Manejar respuesta de texto
        else if (response is TextResponse) {
          _conversationHistory += response.token;
          notifyListeners();
        }
      }).asFuture();

      // Asegurar salto de línea al final
      if (!_conversationHistory.endsWith('\n\n')) {
        _conversationHistory += "\n\n";
      }
    } catch (e) {
      _conversationHistory += "❌ Error: $e\n\n";
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> unloadModel() async {
    _chat?.close();
    _chat = null;
    _isModelReady = false;
    _conversationHistory = "";
    _isProcessing = false;
    notifyListeners();
  }

  void clearResponse() {
    _conversationHistory = "";
    notifyListeners();
  }
}
