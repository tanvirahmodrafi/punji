class ExpenseEntity {
  String expenseId;
  String categoryId;
  DateTime date;
  int amount;

  ExpenseEntity({
    required this.expenseId,
    required this.categoryId,
    required this.date,
    required this.amount,
  });

  Map<String, Object?> toDocument() {
    return {
      'expenseId': expenseId,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'amount': amount,
    };
  }

  static ExpenseEntity fromDocument(Map<String, dynamic> doc) {
    final expenseId = doc['expenseId'] ?? doc['expenseid'] ?? '';
    final categoryId = doc['categoryId'] ?? doc['categoryid'] ?? '';
    final dateRaw = doc['date'];
    final amountRaw = doc['amount'] ?? 0;

    return ExpenseEntity(
      expenseId: expenseId.toString(),
      categoryId: categoryId.toString(),
      date: dateRaw is DateTime
          ? dateRaw
          : DateTime.tryParse(dateRaw?.toString() ?? '') ?? DateTime.now(),
      amount: amountRaw is int
          ? amountRaw
          : int.tryParse(amountRaw.toString()) ?? 0,
    );
  }
}
