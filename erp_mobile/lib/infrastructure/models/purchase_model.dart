import 'package:json_annotation/json_annotation.dart';
import '../../../domain/entities/purchase.dart';

part 'purchase_model.g.dart';

@JsonSerializable()
class PurchaseItemModel {
  @JsonKey(name: 'product_id')
  final String productId;
  final int quantity;
  @JsonKey(name: 'unit_cost')
  final double unitCost;
  final double subtotal;
  @JsonKey(name: 'location_id')
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
  @JsonKey(name: 'purchase_id')
  final String purchaseId;
  @JsonKey(name: 'supplier_name')
  final String supplierName;
  final List<PurchaseItemModel> items;
  final double total;
  final String status;
  @JsonKey(name: 'created_at')
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
