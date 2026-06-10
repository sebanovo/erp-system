// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleItemModel _$SaleItemModelFromJson(Map<String, dynamic> json) =>
    SaleItemModel(
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      locationId: json['locationId'] as String?,
    );

Map<String, dynamic> _$SaleItemModelToJson(SaleItemModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'subtotal': instance.subtotal,
      'locationId': instance.locationId,
    };

SaleModel _$SaleModelFromJson(Map<String, dynamic> json) => SaleModel(
  saleId: json['saleId'] as String,
  customerId: json['customerId'] as String?,
  items: (json['items'] as List<dynamic>)
      .map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toDouble(),
  status: json['status'] as String? ?? 'COMPLETED',
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SaleModelToJson(SaleModel instance) => <String, dynamic>{
  'saleId': instance.saleId,
  'customerId': instance.customerId,
  'items': instance.items,
  'total': instance.total,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
};
