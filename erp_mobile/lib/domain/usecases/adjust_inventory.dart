import '../repositories/inventory_repository.dart';

class AdjustInventory {
  final InventoryRepository repository;
  AdjustInventory(this.repository);

  Future<void> call({
    required String productId,
    required String type,
    required int quantity,
    required String reason,
    String? locationId,
    int? minStock,
    String? note,
  }) async {
    await repository.adjustStock(
      productId: productId,
      type: type,
      quantity: quantity,
      reason: reason,
      locationId: locationId,
      minStock: minStock,
      note: note,
    );
  }
}
