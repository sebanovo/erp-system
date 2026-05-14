// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseItemModel _$PurchaseItemModelFromJson(Map<String, dynamic> json) =>
    PurchaseItemModel(
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitCost: (json['unit_cost'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      locationId: json['location_id'] as String?,
    );

Map<String, dynamic> _$PurchaseItemModelToJson(PurchaseItemModel instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'quantity': instance.quantity,
      'unit_cost': instance.unitCost,
      'subtotal': instance.subtotal,
      'location_id': instance.locationId,
    };

PurchaseModel _$PurchaseModelFromJson(Map<String, dynamic> json) =>
    PurchaseModel(
      purchaseId: json['purchase_id'] as String,
      supplierName: json['supplier_name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => PurchaseItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PurchaseModelToJson(PurchaseModel instance) =>
    <String, dynamic>{
      'purchase_id': instance.purchaseId,
      'supplier_name': instance.supplierName,
      'items': instance.items,
      'total': instance.total,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
    };
