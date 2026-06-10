import '../../../core/network/api_client.dart';
import '../../../constants/api_constants.dart';
import '../../../domain/entities/product.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<void> createProduct(Product product);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient apiClient;
  ProductRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await apiClient.get(ApiConstants.products);
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = response.data;
      final List<dynamic> data = json['data'];
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener productos: ${response.statusCode}");
    }
  }

  @override
  Future<void> createProduct(Product product) async {
    final body = {
      "sku": product.sku,
      "name": product.name,
      "description": product.description,
      "category": product.category,
      "unit": product.unit,
      "price": product.price,
      "cost": product.cost,
      "metadata": product.metadata ?? {"source": "ai-assistant"},
    };
    final response = await apiClient.post(ApiConstants.products, body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al crear producto: ${response.statusCode}");
    }
  }
}
