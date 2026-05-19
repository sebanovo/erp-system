import '../entities/inventory.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getInventory();
  Future<List<InventoryMovement>> getMovements(String productId);
  Future<void> adjustStock({
    required String productId,
    required String type, // ADJUSTMENT_IN | ADJUSTMENT_OUT
    required int quantity,
    required String reason,
    String? locationId,
    int? minStock,
    String? note,
  });
}
