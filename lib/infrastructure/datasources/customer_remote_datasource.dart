import '../../../core/network/api_client.dart';
import '../../../constants/api_constants.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers();
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final ApiClient apiClient;
  CustomerRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<CustomerModel>> getCustomers() async {
    final response = await apiClient.get(ApiConstants.customers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = response.data;
      final List<dynamic> data = json['data'];
      return data.map((e) => CustomerModel.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener clientes");
    }
  }
}
