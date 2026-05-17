class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? document;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.document,
    required this.isActive,
  });
}
