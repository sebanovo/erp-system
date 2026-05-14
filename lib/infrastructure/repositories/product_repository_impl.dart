import '../../../domain/entities/product.dart';
import '../../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource dataSource;
  ProductRepositoryImpl(this.dataSource);

  @override
  Future<List<Product>> getProducts() async {
    final models = await dataSource.getProducts();
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<void> create(Product product) async {
    await dataSource.createProduct(product);
  }
}
