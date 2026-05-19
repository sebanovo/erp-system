class InventoryItem {
  final String productId;
  final int onHand;
  final int reserved;
  final int available;
  final int minStock;
  final String status;
  final DateTime updatedAt;

  InventoryItem({
    required this.productId,
    required this.onHand,
    required this.reserved,
    required this.available,
    required this.minStock,
    required this.status,
    required this.updatedAt,
  });
}

class InventoryMovement {
  final String movementId;
  final String productId;
  final String type; // ADJUSTMENT_IN | ADJUSTMENT_OUT
  final String reason;
  final int quantity;
  final int previousOnHand;
  final int newOnHand;
  final String? note;
  final DateTime createdAt;

  InventoryMovement({
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
}
