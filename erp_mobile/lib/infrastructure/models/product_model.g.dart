// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  productId: json['productId'] as String,
  sku: json['sku'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  category: json['category'] as String?,
  unit: json['unit'] as String?,
  price: (json['price'] as num).toDouble(),
  cost: (json['cost'] as num).toDouble(),
  isActive: json['isActive'] as bool? ?? true,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'sku': instance.sku,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'unit': instance.unit,
      'price': instance.price,
      'cost': instance.cost,
      'isActive': instance.isActive,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
