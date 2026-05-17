class Product {
  final String productId;
  final String sku;
  final String name;
  final String? description;
  final String? category;
  final String? unit;
  final double price;
  final double cost;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.productId,
    required this.sku,
    required this.name,
    this.description,
    this.category,
    this.unit,
    required this.price,
    required this.cost,
    required this.isActive,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });
}
