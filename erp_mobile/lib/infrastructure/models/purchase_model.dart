import 'package:json_annotation/json_annotation.dart';
import '../../../domain/entities/purchase.dart';

part 'purchase_model.g.dart';

@JsonSerializable()
class PurchaseItemModel {
  @JsonKey(name: 'productId')
  final String productId;
  final int quantity;
  @JsonKey(name: 'unitCost')
  final double unitCost;
  final double subtotal;
  @JsonKey(name: 'locationId')
  final String? locationId;

  PurchaseItemModel({
    required this.productId,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    this.locationId,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$PurchaseItemModelToJson(this);

  PurchaseItem toDomain() => PurchaseItem(
    productId: productId,
    quantity: quantity,
    unitCost: unitCost,
    subtotal: subtotal,
    locationId: locationId,
  );
}

@JsonSerializable()
class PurchaseModel {
  @JsonKey(name: 'purchaseId')
  final String purchaseId;
  @JsonKey(name: 'supplierName')
  final String supplierName;
  final List<PurchaseItemModel> items;
  final double total;
  @JsonKey(defaultValue: 'COMPLETED')
  final String status;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  PurchaseModel({
    required this.purchaseId,
    required this.supplierName,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseModelFromJson(json);
  Map<String, dynamic> toJson() => _$PurchaseModelToJson(this);

  Purchase toDomain() => Purchase(
    purchaseId: purchaseId,
    supplierName: supplierName,
    items: items.map((i) => i.toDomain()).toList(),
    total: total,
    status: status,
    createdAt: createdAt,
  );
}
