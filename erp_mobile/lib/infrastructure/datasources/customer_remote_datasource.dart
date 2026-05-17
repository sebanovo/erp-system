import 'package:app_ia_llm/domain/entities/customer.dart';

import '../../../core/network/api_client.dart';
import '../../../constants/api_constants.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers();
  Future<void> createCustomer(Customer customer);
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

  @override
  Future<void> createCustomer(Customer customer) async {
    final body = {
      "name": customer.name,
      "email": customer.email,
      "phone": customer.phone,
      "address": customer.address,
      "document": customer.document,
      "metadata": {"source": "ai-assistant"},
    };
    final response = await apiClient.post(ApiConstants.customers, body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al crear cliente: ${response.statusCode}");
    }
  }
}
