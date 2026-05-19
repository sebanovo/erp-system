import 'package:json_annotation/json_annotation.dart';
import '../../../domain/entities/product.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  @JsonKey(name: 'productId')
  final String productId;
  final String sku;
  final String name;
  final String? description;
  final String? category;
  final String? unit;
  final double price;
  final double cost;
  @JsonKey(name: 'isActive', defaultValue: true)
  final bool isActive;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  ProductModel({
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

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  Product toDomain() => Product(
    productId: productId,
    sku: sku,
    name: name,
    description: description,
    category: category,
    unit: unit,
    price: price,
    cost: cost,
    isActive: isActive,
    metadata: metadata,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
