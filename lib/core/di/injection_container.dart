import 'package:app_ia_llm/domain/usecases/create_customer.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../infrastructure/datasources/customer_remote_datasource.dart';
import '../../infrastructure/repositories/customer_repository_impl.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/get_customers.dart';
import '../../presentation/viewmodels/customers_viewmodel.dart';
import '../../presentation/viewmodels/gemma_viewmodel.dart';

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
}
