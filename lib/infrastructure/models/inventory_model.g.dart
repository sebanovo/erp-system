// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryItemModel _$InventoryItemModelFromJson(Map<String, dynamic> json) =>
    InventoryItemModel(
      productId: json['product_id'] as String,
      onHand: (json['on_hand'] as num).toInt(),
      reserved: (json['reserved'] as num).toInt(),
      available: (json['available'] as num).toInt(),
      minStock: (json['min_stock'] as num).toInt(),
      status: json['status'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$InventoryItemModelToJson(InventoryItemModel instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'on_hand': instance.onHand,
      'reserved': instance.reserved,
      'available': instance.available,
      'min_stock': instance.minStock,
      'status': instance.status,
      'updated_at': instance.updatedAt.toIso8601String(),
    };

InventoryMovementModel _$InventoryMovementModelFromJson(
  Map<String, dynamic> json,
) => InventoryMovementModel(
  movementId: json['movement_id'] as String,
  productId: json['product_id'] as String,
  type: json['type'] as String,
  reason: json['reason'] as String,
  quantity: (json['quantity'] as num).toInt(),
  previousOnHand: (json['previous_on_hand'] as num).toInt(),
  newOnHand: (json['new_on_hand'] as num).toInt(),
  note: json['note'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$InventoryMovementModelToJson(
  InventoryMovementModel instance,
) => <String, dynamic>{
  'movement_id': instance.movementId,
  'product_id': instance.productId,
  'type': instance.type,
  'reason': instance.reason,
  'quantity': instance.quantity,
  'previous_on_hand': instance.previousOnHand,
  'new_on_hand': instance.newOnHand,
  'note': instance.note,
  'created_at': instance.createdAt.toIso8601String(),
};
