class PurchaseItem {
  final String productId;
  final int quantity;
  final double unitCost;
  final double subtotal;
  final String? locationId;

  PurchaseItem({
    required this.productId,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    this.locationId,
  });
}

class Purchase {
  final String purchaseId;
  final String supplierName;
  final List<PurchaseItem> items;
  final double total;
  final String status;
  final DateTime createdAt;

  Purchase({
    required this.purchaseId,
    required this.supplierName,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });
}
