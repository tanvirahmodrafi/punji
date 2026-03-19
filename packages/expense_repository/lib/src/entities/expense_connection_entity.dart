class ExpenseConnectionEntity {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseConnectionEntity({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  static ExpenseConnectionEntity fromDocument(Map<String, dynamic> doc) {
    DateTime? parseDate(dynamic raw) {
      final asString = raw?.toString();
      if (asString == null || asString.isEmpty) {
        return null;
      }
      return DateTime.tryParse(asString);
    }

    return ExpenseConnectionEntity(
      id: (doc['id'] ?? '').toString(),
      requesterId: (doc['requester_id'] ?? doc['requesterId'] ?? '').toString(),
      receiverId: (doc['receiver_id'] ?? doc['receiverId'] ?? '').toString(),
      status: (doc['status'] ?? '').toString(),
      createdAt: parseDate(doc['created_at'] ?? doc['createdAt']),
      updatedAt: parseDate(doc['updated_at'] ?? doc['updatedAt']),
    );
  }

  Map<String, Object?> toDocument() {
    return {
      'id': id,
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
