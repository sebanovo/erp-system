import 'package:json_annotation/json_annotation.dart';
import '../../../domain/entities/customer.dart';

part 'customer_model.g.dart'; // el error es acá: Target of URI hasn't been generated: 'package:erp_mobile/infrastructure/models/customer_model.g.dart'.
// Try running the generator that will generate the file referenced by the URI.darturi_has_not_been_generated

@JsonSerializable()
class CustomerModel {
  @JsonKey(name: 'customer_id')
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  @JsonKey(name: 'is_active')
  final bool isActive;

  CustomerModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    required this.isActive,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerModelToJson(this);

  Customer toDomain() => Customer(
    id: id,
    name: name,
    email: email,
    phone: phone,
    address: address,
    isActive: isActive,
  );
}
