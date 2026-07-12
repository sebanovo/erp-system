import '../repositories/purchase_repository.dart';

class CreateQuickPurchase {
  final PurchaseRepository repository;
  CreateQuickPurchase(this.repository);

  Future<void> call(Map<String, dynamic> payload) async {
    return await repository.createQuickPurchase(payload);
  }
}
