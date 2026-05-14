import '../../../domain/entities/purchase.dart';
import '../../../domain/repositories/purchase_repository.dart';
import '../datasources/purchase_remote_datasource.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseRemoteDataSource dataSource;
  PurchaseRepositoryImpl(this.dataSource);

  @override
  Future<List<Purchase>> getPurchases() async {
    final models = await dataSource.getPurchases();
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<void> create(Purchase purchase) async {
    await dataSource.createPurchase(purchase);
  }
}
