import '../../../domain/entities/customer.dart';
import '../../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource dataSource;
  CustomerRepositoryImpl(this.dataSource);

  @override
  Future<List<Customer>> getCustomers() async {
    final models = await dataSource.getCustomers();
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<void> create(Customer customer) async {
    await dataSource.createCustomer(customer);
  }
}
