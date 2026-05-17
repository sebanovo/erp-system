import 'package:flutter/material.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/usecases/adjust_inventory.dart';
import '../../domain/repositories/inventory_repository.dart';

class InventoryViewModel extends ChangeNotifier {
  final InventoryRepository repository;
  final AdjustInventory adjustInventory;

  List<InventoryItem> _items = [];
  bool _isLoading = false;
  String? _error;
  final Map<String, List<InventoryMovement>> _movementsCache = {};

  InventoryViewModel(this.repository, this.adjustInventory);

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await repository.getInventory();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<InventoryMovement>> getMovements(String productId) async {
    if (_movementsCache.containsKey(productId)) {
      return _movementsCache[productId]!;
    }
    final movements = await repository.getMovements(productId);
    _movementsCache[productId] = movements;
    return movements;
  }

  Future<void> addAdjustment({
    required String productId,
    required String type,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    await adjustInventory.call(
      productId: productId,
      type: type,
      quantity: quantity,
      reason: reason,
      note: note,
    );
    // Limpiar caché de movimientos para este producto
    _movementsCache.remove(productId);
    await load(); // Recargar inventario
  }
}
