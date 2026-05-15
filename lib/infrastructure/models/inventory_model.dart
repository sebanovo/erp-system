import 'package:json_annotation/json_annotation.dart';
import '../../../domain/entities/inventory.dart';

part 'inventory_model.g.dart';

@JsonSerializable()
class InventoryItemModel {
  @JsonKey(name: 'product_id')
  final String productId;
  @JsonKey(name: 'on_hand')
  final int onHand;
  final int reserved;
  final int available;
  @JsonKey(name: 'min_stock')
  final int minStock;
  final String status;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  InventoryItemModel({
    required this.productId,
    required this.onHand,
    required this.reserved,
    required this.available,
    required this.minStock,
    required this.status,
    required this.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryItemModelToJson(this);

  InventoryItem toDomain() => InventoryItem(
    productId: productId,
    onHand: onHand,
    reserved: reserved,
    available: available,
    minStock: minStock,
    status: status,
    updatedAt: updatedAt,
  );
}

@JsonSerializable()
class InventoryMovementModel {
  @JsonKey(name: 'movement_id')
  final String movementId;
  @JsonKey(name: 'product_id')
  final String productId;
  final String type;
  final String reason;
  final int quantity;
  @JsonKey(name: 'previous_on_hand')
  final int previousOnHand;
  @JsonKey(name: 'new_on_hand')
  final int newOnHand;
  final String? note;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  InventoryMovementModel({
    required this.movementId,
    required this.productId,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.previousOnHand,
    required this.newOnHand,
    this.note,
    required this.createdAt,
  });

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryMovementModelFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryMovementModelToJson(this);

  InventoryMovement toDomain() => InventoryMovement(
    movementId: movementId,
    productId: productId,
    type: type,
    reason: reason,
    quantity: quantity,
    previousOnHand: previousOnHand,
    newOnHand: newOnHand,
    note: note,
    createdAt: createdAt,
  );
}
