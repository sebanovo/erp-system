import 'package:erp_mobile/domain/repositories/inventory_repository.dart';
import 'package:erp_mobile/domain/repositories/product_repository.dart';
import 'package:erp_mobile/domain/repositories/purchase_repository.dart';
import 'package:erp_mobile/domain/repositories/sale_repository.dart';
import 'package:erp_mobile/domain/usecases/adjust_inventory.dart';
import 'package:erp_mobile/domain/usecases/create_customer.dart';
import 'package:erp_mobile/domain/usecases/create_product.dart';
import 'package:erp_mobile/domain/usecases/create_purchase.dart';
import 'package:erp_mobile/domain/usecases/create_sale.dart';
import 'package:erp_mobile/infrastructure/datasources/inventory_remote_datasource.dart';
import 'package:erp_mobile/infrastructure/datasources/product_remote_datasource.dart';
import 'package:erp_mobile/infrastructure/datasources/purchase_remote_datasource.dart';
import 'package:erp_mobile/infrastructure/datasources/sale_remote_datasource.dart';
import 'package:erp_mobile/infrastructure/repositories/inventory_repository_impl.dart';
import 'package:erp_mobile/infrastructure/repositories/product_repository_impl.dart';
import 'package:erp_mobile/infrastructure/repositories/purchase_repository_impl.dart';
import 'package:erp_mobile/infrastructure/repositories/sale_repository_impl.dart';
import 'package:erp_mobile/presentation/viewmodels/inventory_viewmodel.dart';
import 'package:erp_mobile/presentation/viewmodels/products_viewmodel.dart';
import 'package:erp_mobile/presentation/viewmodels/purchases_viewmodel.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../infrastructure/datasources/customer_remote_datasource.dart';
import '../../infrastructure/repositories/customer_repository_impl.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/get_customers.dart';
import '../../presentation/viewmodels/customers_viewmodel.dart';
import '../../presentation/viewmodels/gemma_viewmodel.dart';
import '../../presentation/viewmodels/sales_viewmodel.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => Dio());

  // Data sources
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCustomers(sl()));

  // ViewModels
  sl.registerFactory(() => CustomersViewModel(sl()));
  sl.registerLazySingleton(
    () => GemmaViewModel(),
  ); // Singleton para mantener el modelo cargado
  // Agregar al final de init()
  sl.registerLazySingleton(() => CreateCustomer(sl<CustomerRepository>()));
  // PRODUCTOS
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateProduct(sl<ProductRepository>()));

  // ViewModels
  sl.registerFactory(
    () => ProductsViewModel(sl<ProductRepository>(), sl<CreateProduct>()),
  );

  // SALES
  // Dentro de init(), agregar:
  // Data sources
  sl.registerLazySingleton<SaleRemoteDataSource>(
    () => SaleRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<SaleRepository>(() => SaleRepositoryImpl(sl()));

  // Use cases
  sl.registerLazySingleton(() => CreateSale(sl<SaleRepository>()));

  // ViewModels
  sl.registerFactory(
    () => SalesViewModel(sl<SaleRepository>(), sl<CreateSale>()),
  );

  // PURCHASE
  // Dentro de init(), agregar:
  // Data sources
  sl.registerLazySingleton<PurchaseRemoteDataSource>(
    () => PurchaseRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<PurchaseRepository>(
    () => PurchaseRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => CreatePurchase(sl<PurchaseRepository>()));

  // ViewModels
  sl.registerFactory(
    () => PurchasesViewModel(sl<PurchaseRepository>(), sl<CreatePurchase>()),
  );

  // INVENTORY
  sl.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => AdjustInventory(sl<InventoryRepository>()));

  // ViewModels
  sl.registerFactory(
    () => InventoryViewModel(sl<InventoryRepository>(), sl<AdjustInventory>()),
  );
}
