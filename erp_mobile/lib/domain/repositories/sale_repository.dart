import '../entities/sale.dart';

abstract class SaleRepository {
  Future<List<Sale>> getSales();
  Future<void> create(Sale sale);
}
