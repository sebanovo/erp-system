import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  final Widget child;
  const HomePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people), label: "Clientes"),
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: "Productos",
          ),
        ],
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/customers');
          } else if (index == 1) {
            context.go('/products');
          }
        },
      ),
    );
  }
}
