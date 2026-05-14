import 'package:app_ia_llm/presentation/pages/sales_page.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/customers_page.dart';
import '../../presentation/pages/products_page.dart';
import '../../presentation/pages/purchases_page.dart';

final appRouter = GoRouter(
  initialLocation: '/customers',
  routes: [
    ShellRoute(
      builder: (context, state, child) => HomePage(child: child),
      routes: [
        GoRoute(path: '/customers', builder: (_, _) => const CustomersPage()),
        GoRoute(path: '/products', builder: (_, _) => const ProductsPage()),
        GoRoute(path: '/sales', builder: (_, _) => const SalesPage()),
        GoRoute(path: '/purchases', builder: (_, _) => const PurchasesPage()),
      ],
    ),
  ],
);
