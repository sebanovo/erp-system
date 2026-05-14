// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleItemModel _$SaleItemModelFromJson(Map<String, dynamic> json) =>
    SaleItemModel(
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      locationId: json['location_id'] as String?,
    );

Map<String, dynamic> _$SaleItemModelToJson(SaleItemModel instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'subtotal': instance.subtotal,
      'location_id': instance.locationId,
    };

SaleModel _$SaleModelFromJson(Map<String, dynamic> json) => SaleModel(
  saleId: json['sale_id'] as String,
  customerId: json['customer_id'] as String?,
  items: (json['items'] as List<dynamic>)
      .map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toDouble(),
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SaleModelToJson(SaleModel instance) => <String, dynamic>{
  'sale_id': instance.saleId,
  'customer_id': instance.customerId,
  'items': instance.items,
  'total': instance.total,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
};
