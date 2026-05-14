import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/customers_viewmodel.dart';
import '../widgets/ai_chat_dialog.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clientes")),
      body: Consumer<CustomersViewModel>(
        builder: (ctx, vm, _) {
          if (vm.isLoading)
            return const Center(child: CircularProgressIndicator());
          if (vm.error != null)
            return Center(child: Text("Error: ${vm.error}"));
          if (vm.customers.isEmpty)
            return const Center(child: Text("No hay clientes"));
          return ListView.builder(
            itemCount: vm.customers.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(vm.customers[i].name),
              subtitle: Text(vm.customers[i].id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.chat),
        onPressed: () =>
            showDialog(context: context, builder: (_) => const AiChatDialog()),
      ),
    );
  }
}
