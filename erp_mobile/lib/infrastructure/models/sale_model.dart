import 'package:json_annotation/json_annotation.dart';
import '../../../domain/entities/sale.dart';

part 'sale_model.g.dart';

@JsonSerializable()
class SaleItemModel {
  @JsonKey(name: 'productId')
  final String productId;
  final int quantity;
  @JsonKey(name: 'unitPrice')
  final double unitPrice;
  final double subtotal;
  @JsonKey(name: 'locationId')
  final String? locationId;

  SaleItemModel({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.locationId,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) =>
      _$SaleItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$SaleItemModelToJson(this);

  SaleItem toDomain() => SaleItem(
    productId: productId,
    quantity: quantity,
    unitPrice: unitPrice,
    subtotal: subtotal,
    locationId: locationId,
  );
}

@JsonSerializable()
class SaleModel {
  @JsonKey(name: 'saleId')
  final String saleId;
  @JsonKey(name: 'customerId')
  final String? customerId;
  final List<SaleItemModel> items;
  final double total;
  @JsonKey(defaultValue: 'COMPLETED')
  final String status;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  SaleModel({
    required this.saleId,
    this.customerId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) =>
      _$SaleModelFromJson(json);
  Map<String, dynamic> toJson() => _$SaleModelToJson(this);

  Sale toDomain() => Sale(
    saleId: saleId,
    customerId: customerId,
    items: items.map((i) => i.toDomain()).toList(),
    total: total,
    status: status,
    createdAt: createdAt,
  );
}
