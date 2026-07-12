import '../../../domain/entities/inventory.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource dataSource;
  InventoryRepositoryImpl(this.dataSource);

  @override
  Future<List<InventoryItem>> getInventory() async {
    final models = await dataSource.getInventory();
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<List<InventoryMovement>> getMovements(String productId) async {
    final models = await dataSource.getMovements(productId);
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<void> adjustStock({
    required String productId,
    required String type,
    required int quantity,
    required String reason,
    String? locationId,
    int? minStock,
    String? note,
  }) async {
    await dataSource.adjustStock(
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
