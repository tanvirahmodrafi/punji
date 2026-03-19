class ExpenseEntity {
  String expenseId;
  String categoryId;
  DateTime date;
  int amount;
  bool isSplit;
  String? splitGroupId;
  String? splitCreatedBy;
  String? splitPartnerId;
  int? splitTotalAmount;
  int? splitShareAmount;
  String? userId;

  ExpenseEntity({
    required this.expenseId,
    required this.categoryId,
    required this.date,
    required this.amount,
    this.isSplit = false,
    this.splitGroupId,
    this.splitCreatedBy,
    this.splitPartnerId,
    this.splitTotalAmount,
    this.splitShareAmount,
    this.userId,
  });

  Map<String, Object?> toDocument() {
    return {
      'expenseId': expenseId,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'amount': amount,
      'is_split': isSplit,
      'split_group_id': splitGroupId,
      'split_created_by': splitCreatedBy,
      'split_partner_id': splitPartnerId,
      'split_total_amount': splitTotalAmount,
      'split_share_amount': splitShareAmount,
      'userid': userId,
    };
  }

  static ExpenseEntity fromDocument(Map<String, dynamic> doc) {
    final expenseId = doc['expenseId'] ?? doc['expenseid'] ?? '';
    final categoryId = doc['categoryId'] ?? doc['categoryid'] ?? '';
    final dateRaw = doc['date'];
    final amountRaw = doc['amount'] ?? 0;
    final splitRaw = doc['is_split'] ?? doc['isSplit'] ?? false;

    int? parseNullableInt(dynamic raw) {
      if (raw == null) {
        return null;
      }
      if (raw is int) {
        return raw;
      }
      return int.tryParse(raw.toString());
    }

    bool parseBool(dynamic raw) {
      if (raw is bool) {
        return raw;
      }
      final asString = raw?.toString().toLowerCase();
      return asString == 'true' || asString == '1';
    }

    return ExpenseEntity(
      expenseId: expenseId.toString(),
      categoryId: categoryId.toString(),
      date: dateRaw is DateTime
          ? dateRaw
          : DateTime.tryParse(dateRaw?.toString() ?? '') ?? DateTime.now(),
      amount: amountRaw is int
          ? amountRaw
          : int.tryParse(amountRaw.toString()) ?? 0,
      isSplit: parseBool(splitRaw),
      splitGroupId: (doc['split_group_id'] ?? doc['splitGroupId'])?.toString(),
      splitCreatedBy:
          (doc['split_created_by'] ?? doc['splitCreatedBy'])?.toString(),
      splitPartnerId:
          (doc['split_partner_id'] ?? doc['splitPartnerId'])?.toString(),
      splitTotalAmount: parseNullableInt(
        doc['split_total_amount'] ?? doc['splitTotalAmount'],
      ),
      splitShareAmount: parseNullableInt(
        doc['split_share_amount'] ?? doc['splitShareAmount'],
      ),
      userId: (doc['userid'] ?? doc['userId'])?.toString(),
    );
  }
}
