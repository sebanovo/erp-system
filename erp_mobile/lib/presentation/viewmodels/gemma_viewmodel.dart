import 'package:erp_mobile/domain/entities/product.dart';
import 'package:erp_mobile/domain/entities/purchase.dart';
import 'package:erp_mobile/domain/entities/sale.dart';
import 'package:erp_mobile/domain/usecases/adjust_inventory.dart';
import 'package:erp_mobile/domain/usecases/create_product.dart';
import 'package:erp_mobile/domain/usecases/create_purchase.dart';
import 'package:erp_mobile/domain/usecases/create_quick_purchase.dart';
import 'package:erp_mobile/domain/usecases/create_quick_sale.dart';
import 'package:erp_mobile/domain/usecases/create_sale.dart';
import 'package:erp_mobile/utils/gemma_helper.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/create_customer.dart';

class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  ChatMessage copyWith({String? text}) {
    return ChatMessage(text: text ?? this.text, isUser: isUser);
  }
}

class GemmaViewModel extends ChangeNotifier {
  static const Duration _minimumSendLoadingDuration = Duration(minutes: 1);

  final CreateCustomer _createCustomer = GetIt.instance<CreateCustomer>();
  final CreateProduct _createProduct = GetIt.instance<CreateProduct>();
  final CreateSale _createSale = GetIt.instance<CreateSale>();
  final CreatePurchase _createPurchase = GetIt.instance<CreatePurchase>();
  final AdjustInventory _adjustInventory = GetIt.instance<AdjustInventory>();
  final CreateQuickSale _createQuickSale = GetIt.instance<CreateQuickSale>();
  final CreateQuickPurchase _createQuickPurchase =
      GetIt.instance<CreateQuickPurchase>();

  bool _isModelReady = false;
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;

  bool get isModelReady => _isModelReady;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String get lastResponse => _messages
      .map(
        (message) => "${message.isUser ? 'Tu' : 'Asistente'}: ${message.text}",
      )
      .join("\n\n");
  bool get isProcessing => _isProcessing;

  void _addAssistantMessage(String text) {
    _messages.add(ChatMessage(text: text, isUser: false));
  }

  void _appendToAssistantMessage(String text) {
    if (_messages.isEmpty || _messages.last.isUser) {
      _addAssistantMessage(text);
      return;
    }

    final lastIndex = _messages.length - 1;
    _messages[lastIndex] = _messages[lastIndex].copyWith(
      text: "${_messages[lastIndex].text}$text",
    );
  }

  Future<void> loadModel() async {
    try {
      await GemmaHelper.loadModelFromFile();
      await GemmaHelper.createChatWithTools();
      _isModelReady = true;
      _messages
        ..clear()
        ..add(ChatMessage(text: "Modelo cargado correctamente", isUser: false));
      notifyListeners();
    } catch (e) {
      _messages
        ..clear()
        ..add(ChatMessage(text: "Error: $e", isUser: false));
      notifyListeners();
    }
  }

  Future<void> _executeFunctionCall(
    AiFunctionCall call, {
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
        _appendToAssistantMessage("Cliente creado: ${customer.name}\n");
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
        _appendToAssistantMessage(
          "Producto creado: ${product.name} (SKU: ${product.sku})\n",
        );
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
        _appendToAssistantMessage(
          "Venta creada - Total: $total Bs (${items.length} productos)\n",
        );
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
        _appendToAssistantMessage(
          "Compra creada: ${purchase.supplierName} - Total: $total Bs\n",
        );
        if (onPurchaseCreated != null) onPurchaseCreated(purchase);
        break;

      case 'adjustInventory':
        await _adjustInventory.call(
          productId: args['productId'],
          locationId: args['locationId'] ?? "MAIN",
          type: args['type'],
          quantity: (args['quantity'] as num).toInt(),
          reason: args['reason'],
          note: args['note'],
        );
        _appendToAssistantMessage(
          "Stock ajustado: ${args['type'] == 'ADJUSTMENT_IN' ? '+' : '-'}${args['quantity']} unidades\n",
        );
        if (onInventoryAdjusted != null) onInventoryAdjusted();
        break;

      case 'quickSale':
        final payload = {
          "customer": {
            "name": args['customer_name'],
            "phone": args['customer_phone'],
            "email": args['customer_email'],
          },
          "product": {
            "name": args['product_name'],
            "sku": args['product_sku'],
            "price": args['product_price'],
            "cost": args['product_cost'] ?? 0,
          },
          "sale": {
            "quantity": args['sale_quantity'],
            "unit_price": args['sale_unit_price'],
          },
        };

        await _createQuickSale.call(payload);
        _appendToAssistantMessage("Venta rápida registrada exitosamente\n");
        break;

      case 'quickPurchase':
        final payload = {
          "supplier_name": args['supplier_name'],
          "product": {
            "name": args['product_name'],
            "sku": args['product_sku'],
            "price": args['product_price'],
            "cost": args['product_cost'],
          },
          "purchase": {
            "quantity": args['purchase_quantity'],
            "unit_cost": args['purchase_unit_cost'],
          },
        };

        await _createQuickPurchase.call(payload);
        _appendToAssistantMessage("Compra rápida registrada exitosamente\n");
        break;

      default:
        _appendToAssistantMessage("Funcion desconocida: ${call.name}\n");
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
    if (!_isModelReady) {
      _addAssistantMessage("Primero carga el modelo");
      notifyListeners();
      return;
    }

    _isProcessing = true;

    _messages.add(ChatMessage(text: userInput, isUser: true));
    _addAssistantMessage("");
    notifyListeners();

    try {
      await Future.delayed(_minimumSendLoadingDuration);

      final calls = await GemmaHelper.generateToolCalls(userInput);
      debugPrint("AI tool calls: ${calls.length}");

      for (final call in calls) {
        debugPrint("  - Ejecutando: ${call.name}");
        await _executeFunctionCall(
          call,
          onCustomerCreated: onCustomerCreated,
          onProductCreated: onProductCreated,
          onSaleCreated: onSaleCreated,
          onPurchaseCreated: onPurchaseCreated,
          onInventoryAdjusted: onInventoryAdjusted,
        );
      }

      if (calls.length > 1) {
        _appendToAssistantMessage("\nTodas las tareas completadas");
        notifyListeners();
      }
    } catch (e) {
      _appendToAssistantMessage("Error: $e");
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> unloadModel() async {
    await GemmaHelper.unloadModel();
    _isModelReady = false;
    _messages.clear();
    _isProcessing = false;
    notifyListeners();
  }

  void clearResponse() {
    _messages.clear();
    notifyListeners();
  }
}
