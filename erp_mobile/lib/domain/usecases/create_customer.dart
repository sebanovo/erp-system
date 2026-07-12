import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class CreateCustomer {
  final CustomerRepository repository;
  CreateCustomer(this.repository);

  Future<void> call(Customer customer) async {
    await repository.create(customer);
  }
}
