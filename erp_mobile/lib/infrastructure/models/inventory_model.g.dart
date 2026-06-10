// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryItemModel _$InventoryItemModelFromJson(Map<String, dynamic> json) =>
    InventoryItemModel(
      productId: json['productId'] as String,
      onHand: (json['stock'] as num?)?.toInt() ?? 0,
      reserved: (json['reserved'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
      minStock: (json['minStock'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'AVAILABLE',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$InventoryItemModelToJson(InventoryItemModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'stock': instance.onHand,
      'reserved': instance.reserved,
      'available': instance.available,
      'minStock': instance.minStock,
      'status': instance.status,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

InventoryMovementModel _$InventoryMovementModelFromJson(
  Map<String, dynamic> json,
) => InventoryMovementModel(
  movementId: json['movementId'] as String,
  productId: json['productId'] as String,
  type: json['type'] as String,
  reason: json['reason'] as String,
  quantity: (json['quantity'] as num).toInt(),
  previousOnHand: (json['previous_on_hand'] as num?)?.toInt() ?? 0,
  newOnHand: (json['new_on_hand'] as num?)?.toInt() ?? 0,
  note: json['note'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$InventoryMovementModelToJson(
  InventoryMovementModel instance,
) => <String, dynamic>{
  'movementId': instance.movementId,
  'productId': instance.productId,
  'type': instance.type,
  'reason': instance.reason,
  'quantity': instance.quantity,
  'previous_on_hand': instance.previousOnHand,
  'new_on_hand': instance.newOnHand,
  'note': instance.note,
  'createdAt': instance.createdAt.toIso8601String(),
};
