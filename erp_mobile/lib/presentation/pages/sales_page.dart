import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/sales_viewmodel.dart';
import '../viewmodels/gemma_viewmodel.dart';
import '../widgets/ai_chat_dialog.dart';
import '../../domain/entities/sale.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ventas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SalesViewModel>().load(),
            tooltip: "Recargar",
          ),
        ],
      ),
      body: Consumer<SalesViewModel>(
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
          if (vm.sales.isEmpty) {
            return const Center(child: Text("No hay ventas registradas"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.sales.length,
            itemBuilder: (_, i) {
              final s = vm.sales[i];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showSaleDetail(context, s),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Venta #${s.saleId.substring(0, 8)}...",
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
                                color: s.status == 'CONFIRMED'
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: s.status == 'CONFIRMED'
                                      ? Colors.green.shade900
                                      : Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.person,
                          s.customerId?.isNotEmpty == true
                              ? "Cliente: ${s.customerId!.substring(0, 8)}..."
                              : "Cliente: No especificado",
                          context,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.shopping_cart,
                          "${s.items.length} producto(s)",
                          context,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.attach_money,
                          "Total: ${s.total} Bs",
                          context,
                          isPrice: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.createdAt.toString().substring(0, 16),
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.chat),
        onPressed: () {
          final gemmaVM = Provider.of<GemmaViewModel>(context, listen: false);
          showDialog(
            context: context,
            builder: (_) => ChangeNotifierProvider.value(
              value: gemmaVM,
              child: AiChatDialog(
                onCustomerCreated: (_) {},
                onProductCreated: (_) {},
                onSaleCreated: (newSale) {
                  context.read<SalesViewModel>().load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "✅ Venta #${newSale.saleId.substring(0, 8)} creada",
                      ),
                      duration: const Duration(seconds: 2),
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

  Widget _buildInfoRow(
    IconData icon,
    String text,
    BuildContext context, {
    bool isPrice = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isPrice ? FontWeight.w500 : FontWeight.normal,
                color: isPrice ? Colors.deepPurple : Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSaleDetail(BuildContext context, Sale sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              "Venta ${sale.saleId}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Estado: ${sale.status}",
              style: TextStyle(
                color: sale.status == 'CONFIRMED'
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Cliente"),
              subtitle: Text(sale.customerId ?? "No especificado"),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text("Items"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sale.items.map((item) {
                  return Text(
                    "• Producto: ${item.productId.substring(0, 8)}... "
                    "x${item.quantity} @ ${item.unitPrice} Bs = ${item.subtotal} Bs",
                    style: const TextStyle(fontSize: 12),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text("Total"),
              subtitle: Text(
                "${sale.total} Bs",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Fecha"),
              subtitle: Text(sale.createdAt.toString()),
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
