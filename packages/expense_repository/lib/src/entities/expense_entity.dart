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
    return ExpenseEntity(
      expenseId: doc['expenseId'],
      categoryId: doc['categoryId'],
      date: DateTime.parse(doc['date']),
      amount: doc['amount'],
    );
  }
}
