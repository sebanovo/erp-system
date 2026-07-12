// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseItemModel _$PurchaseItemModelFromJson(Map<String, dynamic> json) =>
    PurchaseItemModel(
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitCost: (json['unitCost'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      locationId: json['locationId'] as String?,
    );

Map<String, dynamic> _$PurchaseItemModelToJson(PurchaseItemModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'subtotal': instance.subtotal,
      'locationId': instance.locationId,
    };

PurchaseModel _$PurchaseModelFromJson(Map<String, dynamic> json) =>
    PurchaseModel(
      purchaseId: json['purchaseId'] as String,
      supplierName: json['supplierName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => PurchaseItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String? ?? 'COMPLETED',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PurchaseModelToJson(PurchaseModel instance) =>
    <String, dynamic>{
      'purchaseId': instance.purchaseId,
      'supplierName': instance.supplierName,
      'items': instance.items,
      'total': instance.total,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
    };
