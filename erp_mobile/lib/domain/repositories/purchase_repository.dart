import '../entities/purchase.dart';

abstract class PurchaseRepository {
  Future<List<Purchase>> getPurchases();
  Future<void> create(Purchase purchase);
  Future<void> createQuickPurchase(Map<String, dynamic> payload);
}
