import '../entities/sale.dart';
import '../repositories/sale_repository.dart';

class CreateSale {
  final SaleRepository repository;
  CreateSale(this.repository);

  Future<void> call(Sale sale) async {
    await repository.create(sale);
  }
}
