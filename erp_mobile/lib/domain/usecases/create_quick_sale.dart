import '../repositories/sale_repository.dart';

class CreateQuickSale {
  final SaleRepository repository;
  CreateQuickSale(this.repository);

  Future<void> call(Map<String, dynamic> payload) async {
    return await repository.createQuickSale(payload);
  }
}
