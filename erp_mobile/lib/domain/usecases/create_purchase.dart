import '../entities/purchase.dart';
import '../repositories/purchase_repository.dart';

class CreatePurchase {
  final PurchaseRepository repository;
  CreatePurchase(this.repository);

  Future<void> call(Purchase purchase) async {
    await repository.create(purchase);
  }
}
