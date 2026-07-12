class SaleItem {
  final String productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? locationId;

  SaleItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.locationId,
  });
}

class Sale {
  final String saleId;
  final String? customerId;
  final List<SaleItem> items;
  final double total;
  final String status;
  final DateTime createdAt;

  Sale({
    required this.saleId,
    this.customerId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });
}
