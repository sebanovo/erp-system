import '../../../domain/entities/sale.dart';
import '../../../domain/repositories/sale_repository.dart';
import '../datasources/sale_remote_datasource.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDataSource dataSource;
  SaleRepositoryImpl(this.dataSource);

  @override
  Future<List<Sale>> getSales() async {
    final models = await dataSource.getSales();
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<void> create(Sale sale) async {
    await dataSource.createSale(sale);
  }

  @override
  Future<void> createQuickSale(Map<String, dynamic> payload) async {
    await dataSource.createQuickSale(payload);
  }
}
