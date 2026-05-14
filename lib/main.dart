import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_router.dart';
import 'presentation/viewmodels/gemma_viewmodel.dart';
import 'presentation/viewmodels/customers_viewmodel.dart';
import 'presentation/viewmodels/products_viewmodel.dart'; // ← Agregar
import 'presentation/viewmodels/sales_viewmodel.dart'; // ← Agregar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();
  await dotenv.load(fileName: ".env");
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => di.sl<CustomersViewModel>()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<ProductsViewModel>()..load(), // ← Agregar
        ),
        ChangeNotifierProvider(create: (_) => di.sl<SalesViewModel>()..load()),
        ChangeNotifierProvider(create: (_) => di.sl<GemmaViewModel>()),
      ],
      child: MaterialApp.router(
        title: "ERP IA",
        routerConfig: appRouter,
        theme: ThemeData.dark(useMaterial3: true),
      ),
    );
  }
}
