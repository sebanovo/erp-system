import '../../../core/network/api_client.dart';
import '../../../constants/api_constants.dart';
import '../models/inventory_model.dart';

abstract class InventoryRemoteDataSource {
  Future<List<InventoryItemModel>> getInventory();
  Future<List<InventoryMovementModel>> getMovements(String productId);
  Future<void> adjustStock({
    required String productId,
    required String type,
    required int quantity,
    required String reason,
    String? locationId,
    int? minStock,
    String? note,
  });
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final ApiClient apiClient;
  InventoryRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<InventoryItemModel>> getInventory() async {
    final response = await apiClient.get(ApiConstants.inventory);
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = response.data;
      final List<dynamic> data = json['data'];
      return data.map((e) => InventoryItemModel.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener inventario: ${response.statusCode}");
    }
  }

  @override
  Future<List<InventoryMovementModel>> getMovements(String productId) async {
    final response = await apiClient.get(
      '${ApiConstants.inventory}/$productId/movements',
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = response.data;
      final List<dynamic> data = json['data'];
      return data.map((e) => InventoryMovementModel.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener movimientos: ${response.statusCode}");
    }
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
    final body = {
      "productId": productId,
      "locationId": locationId ?? "MAIN",
      "type": type,
      "quantity": quantity,
      "reason": reason,
      "minStock": ?minStock,
      "note": ?note,
    };
    final response = await apiClient.post(
      ApiConstants.inventoryAdjustments,
      body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al ajustar inventario: ${response.statusCode}");
    }
  }
}
