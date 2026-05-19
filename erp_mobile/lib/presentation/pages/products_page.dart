import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/products_viewmodel.dart';
import '../viewmodels/gemma_viewmodel.dart';
import '../widgets/ai_chat_dialog.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Productos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductsViewModel>().load(),
            tooltip: "Recargar",
          ),
        ],
      ),
      body: Consumer<ProductsViewModel>(
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
          if (vm.products.isEmpty) {
            return const Center(child: Text("No hay productos registrados"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.products.length,
            itemBuilder: (_, i) {
              final p = vm.products[i];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showProductDetail(context, p),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
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
                                color: p.isActive
                                    ? Colors.green.shade100
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.isActive ? "Activo" : "Inactivo",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: p.isActive
                                      ? Colors.green.shade900
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // ✅ Usar _buildInfoRow correctamente
                        _buildInfoRow(Icons.tag, "SKU: ${p.sku}", context),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.attach_money,
                          "Precio: ${p.price} Bs",
                          context,
                          isPrice: true,
                        ),
                        if (p.description != null && p.description!.isNotEmpty)
                          _buildInfoRow(
                            Icons.description,
                            p.description!,
                            context,
                            maxLines: 2,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          "ID: ${p.productId}",
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
                onCustomerCreated: (_) {}, // Callback vacío si no se usa
                onProductCreated: (newProduct) {
                  context.read<ProductsViewModel>().load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✅ Producto ${newProduct.name} creado"),
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
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isPrice ? FontWeight.w500 : FontWeight.normal,
                color: isPrice ? Colors.deepPurple : Colors.grey.shade300,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(BuildContext context, product) {
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
              product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "SKU: ${product.sku}",
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            if (product.description != null && product.description!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text("Descripción"),
                subtitle: Text(product.description!),
              ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text("Categoría"),
              subtitle: Text(product.category ?? "General"),
            ),
            ListTile(
              leading: const Icon(Icons.sell),
              title: const Text("Precio / Costo"),
              subtitle: Text("${product.price} Bs / ${product.cost} Bs"),
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text("ID Producto"),
              subtitle: Text(product.productId),
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
