import '../../../core/network/api_client.dart';
import '../../../constants/api_constants.dart';
import '../../../domain/entities/purchase.dart';
import '../models/purchase_model.dart';

abstract class PurchaseRemoteDataSource {
  Future<List<PurchaseModel>> getPurchases();
  Future<void> createPurchase(Purchase purchase);
}

class PurchaseRemoteDataSourceImpl implements PurchaseRemoteDataSource {
  final ApiClient apiClient;
  PurchaseRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<PurchaseModel>> getPurchases() async {
    final response = await apiClient.get(ApiConstants.purchases);
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = response.data;
      final List<dynamic> data = json['data'];
      return data.map((e) => PurchaseModel.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener compras: ${response.statusCode}");
    }
  }

  @override
  Future<void> createPurchase(Purchase purchase) async {
    final body = {
      "supplier_name": purchase.supplierName,
      "items": purchase.items
          .map(
            (item) => {
              "product_id": item.productId,
              "quantity": item.quantity,
              "unit_cost": item.unitCost,
            },
          )
          .toList(),
    };
    final response = await apiClient.post(ApiConstants.purchases, body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al crear compra: ${response.statusCode}");
    }
  }
}
