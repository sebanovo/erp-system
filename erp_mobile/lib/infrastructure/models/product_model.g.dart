// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  productId: json['product_id'] as String,
  sku: json['sku'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  category: json['category'] as String?,
  unit: json['unit'] as String?,
  price: (json['price'] as num).toDouble(),
  cost: (json['cost'] as num).toDouble(),
  isActive: json['is_active'] as bool,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'sku': instance.sku,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'unit': instance.unit,
      'price': instance.price,
      'cost': instance.cost,
      'is_active': instance.isActive,
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
