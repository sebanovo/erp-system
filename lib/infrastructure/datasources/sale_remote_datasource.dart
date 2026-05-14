import '../../../core/network/api_client.dart';
import '../../../constants/api_constants.dart';
import '../../../domain/entities/sale.dart';
import '../models/sale_model.dart';

abstract class SaleRemoteDataSource {
  Future<List<SaleModel>> getSales();
  Future<void> createSale(Sale sale);
}

class SaleRemoteDataSourceImpl implements SaleRemoteDataSource {
  final ApiClient apiClient;
  SaleRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<SaleModel>> getSales() async {
    final response = await apiClient.get(ApiConstants.sales);
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = response.data;
      final List<dynamic> data = json['data'];
      return data.map((e) => SaleModel.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener ventas: ${response.statusCode}");
    }
  }

  @override
  Future<void> createSale(Sale sale) async {
    final body = {
      "customer_id": sale.customerId ?? "",
      "items": sale.items
          .map(
            (item) => {
              "product_id": item.productId,
              "quantity": item.quantity,
              "unit_price": item.unitPrice,
            },
          )
          .toList(),
    };
    final response = await apiClient.post(ApiConstants.sales, body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al crear venta: ${response.statusCode}");
    }
  }
}
