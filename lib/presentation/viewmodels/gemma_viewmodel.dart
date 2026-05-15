import 'package:app_ia_llm/domain/entities/customer.dart';
import 'package:app_ia_llm/domain/usecases/create_customer.dart';
import 'package:app_ia_llm/domain/entities/product.dart';
import 'package:app_ia_llm/domain/entities/purchase.dart';
import 'package:app_ia_llm/domain/entities/sale.dart';
import 'package:app_ia_llm/domain/usecases/adjust_inventory.dart';
import 'package:app_ia_llm/domain/usecases/create_product.dart';
import 'package:app_ia_llm/domain/usecases/create_purchase.dart';
import 'package:app_ia_llm/domain/usecases/create_sale.dart';
import 'package:app_ia_llm/utils/gemma_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:get_it/get_it.dart';

class GemmaViewModel extends ChangeNotifier {
  final CreateCustomer _createCustomer = GetIt.instance<CreateCustomer>();
  final CreateProduct _createProduct = GetIt.instance<CreateProduct>();
  final CreateSale _createSale = GetIt.instance<CreateSale>();
  final CreatePurchase _createPurchase = GetIt.instance<CreatePurchase>();
  final AdjustInventory _adjustInventory = GetIt.instance<AdjustInventory>();

  bool _isModelReady = false;
  String _lastResponse = "";
  bool _isProcessing = false;
  InferenceChat? _chat;

  bool get isModelReady => _isModelReady;
  String get lastResponse => _lastResponse;
  bool get isProcessing => _isProcessing;

  Future<void> loadModel() async {
    try {
      await GemmaHelper.loadModelFromFile();
      _chat = await GemmaHelper.createChatWithTools();
      _isModelReady = true;
      _lastResponse = "✅ Modelo cargado correctamente";
      notifyListeners();
    } catch (e) {
      _lastResponse = "❌ Error: $e";
      notifyListeners();
    }
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
      _lastResponse = "⚠️ Primero carga un modelo";
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _lastResponse = "";
    notifyListeners();

    try {
      await _chat!.clearHistory();
      await _chat!.addQueryChunk(Message.text(text: userInput, isUser: true));

      await _chat!.generateChatResponseAsync().listen((response) async {
        if (response is FunctionCallResponse) {
          if (response.name == 'createSale') {
            final args = response.args;
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
            _lastResponse =
                "✅ Venta creada por ${items.length} producto(s) - Total: $total Bs";
            notifyListeners();
            if (onSaleCreated != null) onSaleCreated(sale);
          } else if (response.name == 'adjustInventory') {
            final args = response.args;
            await _adjustInventory.call(
              productId: args['product_id'],
              type: args['type'],
              quantity: (args['quantity'] as num).toInt(),
              reason: args['reason'],
              note: args['note'],
            );
            _lastResponse =
                "✅ Stock ajustado: ${args['type'] == 'IN' ? '+' : '-'}${args['quantity']} unidades del producto ${args['product_id']}";
            notifyListeners();
            if (onInventoryAdjusted != null) onInventoryAdjusted();
          } else if (response.name == 'createPurchase') {
            final args = response.args;
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
            _lastResponse =
                "✅ Compra creada: ${purchase.supplierName} - ${items.length} producto(s) - Total: $total Bs";
            notifyListeners();
            if (onPurchaseCreated != null) onPurchaseCreated(purchase);
          } else if (response.name == 'createProduct') {
            final args = response.args;
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
            // ✅ Usar _lastResponse en lugar de _conversationHistory
            _lastResponse = "✅ Producto creado: ${product.name}";
            notifyListeners();
            if (onProductCreated != null) onProductCreated(product);
          } else if (response.name == 'createCustomer') {
            final args = response.args;
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
            _lastResponse = "✅ Cliente creado: ${customer.name}";
            notifyListeners();
            if (onCustomerCreated != null) onCustomerCreated(customer);
          } else {
            _lastResponse = "⚠️ Función desconocida: ${response.name}";
            notifyListeners();
          }
        } else if (response is TextResponse) {
          _lastResponse = response.token;
          notifyListeners();
        }
      }).asFuture();
    } catch (e) {
      _lastResponse = "Error: $e";
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
    _lastResponse = "";
    _isProcessing = false;
    notifyListeners();
  }

  void clearResponse() {
    _lastResponse = "";
    notifyListeners();
  }
}
