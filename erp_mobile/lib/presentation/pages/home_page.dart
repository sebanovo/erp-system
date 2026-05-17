// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class HomePage extends StatelessWidget {
//   final Widget child;
//   const HomePage({super.key, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: child,
//       bottomNavigationBar: NavigationBar(
//         destinations: const [
//           NavigationDestination(icon: Icon(Icons.people), label: "Clientes"),
//           NavigationDestination(
//             icon: Icon(Icons.inventory),
//             label: "Productos",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.shopping_cart),
//             label: "Ventas",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.add_shopping_cart),
//             label: "Compras",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.warehouse),
//             label: "Inventario",
//           ),
//         ],
//         onDestinationSelected: (index) {
//           switch (index) {
//             case 0:
//               context.go('/customers');
//               break;
//             case 1:
//               context.go('/products');
//               break;
//             case 2:
//               context.go('/sales');
//               break;
//             case 3:
//               context.go('/purchases');
//               break;
//             case 4:
//               context.go('/inventory');
//               break;
//           }
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  final Widget child;
  const HomePage({super.key, required this.child});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Mapeo de rutas a índices
  int _getIndexFromRoute(String route) {
    switch (route) {
      case '/customers':
        return 0;
      case '/products':
        return 1;
      case '/sales':
        return 2;
      case '/purchases':
        return 3;
      case '/inventory':
        return 4;
      default:
        return 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Escuchar cambios en la ruta
    final route = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.last.matchedLocation;
    final newIndex = _getIndexFromRoute(route);
    if (_selectedIndex != newIndex) {
      _selectedIndex = newIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              context.go('/customers');
              break;
            case 1:
              context.go('/products');
              break;
            case 2:
              context.go('/sales');
              break;
            case 3:
              context.go('/purchases');
              break;
            case 4:
              context.go('/inventory');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people), label: "Clientes"),
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: "Productos",
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: "Ventas",
          ),
          NavigationDestination(
            icon: Icon(Icons.add_shopping_cart),
            label: "Compras",
          ),
          NavigationDestination(
            icon: Icon(Icons.warehouse),
            label: "Inventario",
          ),
        ],
      ),
    );
  }
}
