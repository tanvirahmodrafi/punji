import '../entities/expense_connection_entity.dart';

class ExpenseConnection {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseConnection({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  String partnerIdFor(String myUserId) {
    return requesterId == myUserId ? receiverId : requesterId;
  }

  ExpenseConnectionEntity toEntity() {
    return ExpenseConnectionEntity(
      id: id,
      requesterId: requesterId,
      receiverId: receiverId,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static ExpenseConnection fromEntity(ExpenseConnectionEntity entity) {
    return ExpenseConnection(
      id: entity.id,
      requesterId: entity.requesterId,
      receiverId: entity.receiverId,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
