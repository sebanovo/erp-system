import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/inventory_viewmodel.dart';
import '../viewmodels/gemma_viewmodel.dart';
import '../widgets/ai_chat_dialog.dart';
import '../../domain/entities/inventory.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<InventoryViewModel>().load(),
            tooltip: "Recargar",
          ),
        ],
      ),
      body: Consumer<InventoryViewModel>(
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
          if (vm.items.isEmpty) {
            return const Center(child: Text("No hay productos en inventario"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.items.length,
            itemBuilder: (_, i) {
              final item = vm.items[i];
              final lowStock = item.available <= item.minStock;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showProductDetail(context, item),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Producto ${item.productId.substring(0, 8)}...",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (lowStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Stock mínimo",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.inventory,
                          "Disponible: ${item.available}",
                          context,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.handyman,
                          "Físico: ${item.onHand}",
                          context,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.low_priority,
                          "Mínimo: ${item.minStock}",
                          context,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.update,
                          "Actualizado: ${item.updatedAt.toString().substring(0, 16)}",
                          context,
                          isSmall: true,
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
                onSaleCreated: (_) {},
                onPurchaseCreated: (_) {},
                onInventoryAdjusted: () {
                  context.read<InventoryViewModel>().load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Inventario ajustado"),
                      duration: Duration(seconds: 2),
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
    bool isSmall = false,
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
                fontSize: isSmall ? 11 : 13,
                color: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(BuildContext context, InventoryItem item) async {
    final vm = Provider.of<InventoryViewModel>(context, listen: false);
    final movements = await vm.getMovements(item.productId);

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
              "Producto ${item.productId.substring(0, 8)}...",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow("Disponible", "${item.available}"),
            _buildDetailRow("Físico", "${item.onHand}"),
            _buildDetailRow("Reservado", "${item.reserved}"),
            _buildDetailRow("Stock mínimo", "${item.minStock}"),
            _buildDetailRow("Estado", item.status),
            const Divider(height: 24),
            const Text(
              "Últimos movimientos",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (movements.isEmpty)
              const Text(
                "No hay movimientos registrados",
                style: TextStyle(fontSize: 12),
              )
            else
              ...movements
                  .take(5)
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "${m.type == 'IN' ? '➕' : '➖'} ${m.quantity} unidades - ${m.reason} (${m.createdAt.toString().substring(0, 16)})",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(": $value"),
        ],
      ),
    );
  }
}
