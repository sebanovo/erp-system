import 'package:app_ia_llm/presentation/viewmodels/gemma_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/customers_viewmodel.dart';
import '../widgets/ai_chat_dialog.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clientes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CustomersViewModel>().load(),
            tooltip: "Recargar",
          ),
        ],
      ),
      body: Consumer<CustomersViewModel>(
        builder: (ctx, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error: ${vm.error}"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => vm.load(),
                    child: const Text("Reintentar"),
                  ),
                ],
              ),
            );
          }
          if (vm.customers.isEmpty) {
            return const Center(child: Text("No hay clientes registrados"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.customers.length,
            itemBuilder: (_, i) {
              final c = vm.customers[i];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showCustomerDetail(context, c),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: c.isActive
                                    ? Colors.green.shade100
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                c.isActive ? "Activo" : "Inactivo",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.isActive
                                      ? Colors.green.shade900
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (c.email != null && c.email!.isNotEmpty)
                          _buildInfoRow(Icons.email, c.email!, context),
                        if (c.phone != null && c.phone!.isNotEmpty)
                          _buildInfoRow(Icons.phone, c.phone!, context),
                        if (c.address != null && c.address!.isNotEmpty)
                          _buildInfoRow(Icons.location_on, c.address!, context),
                        const SizedBox(height: 8),
                        Text(
                          "ID: ${c.id}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.chat),
      //   onPressed: () =>
      //       showDialog(context: context, builder: (_) => const AiChatDialog()),
      // ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.chat),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => ChangeNotifierProvider.value(
              // ✅ Proveer el GemmaViewModel existente
              value: Provider.of<GemmaViewModel>(context, listen: false),
              child: AiChatDialog(
                // ✅ Callback para refrescar la lista cuando se cree un cliente
                onCustomerCreated: (newCustomer) {
                  print("Cliente creado: ${newCustomer.name}");
                  // Refrescar la lista de clientes
                  context.read<CustomersViewModel>().load();
                  // Mostrar confirmación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✅ Cliente ${newCustomer.name} creado"),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetail(BuildContext context, customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              customer.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (customer.email != null && customer.email!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text("Correo"),
                subtitle: Text(customer.email!),
              ),
            if (customer.phone != null && customer.phone!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text("Teléfono"),
                subtitle: Text(customer.phone!),
              ),
            if (customer.address != null && customer.address!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text("Dirección"),
                subtitle: Text(customer.address!),
              ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text("ID Cliente"),
              subtitle: Text(customer.id),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cerrar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
