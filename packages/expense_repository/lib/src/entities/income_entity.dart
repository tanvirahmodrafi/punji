class IncomeEntity {
  String incomeId;
  String category;
  DateTime date;
  int amount;

  IncomeEntity({
    required this.incomeId,
    required this.category,
    required this.date,
    required this.amount,
  });

  Map<String, Object?> toDocument() {
    return {
      'incomeId': incomeId,
      'category': category,
      'date': date.toIso8601String(),
      'amount': amount,
    };
  }

  static IncomeEntity fromDocument(Map<String, dynamic> doc) {
    final incomeId = doc['incomeId'] ?? doc['incomeid'] ?? '';
    final category = doc['category'] ?? '';
    final dateRaw = doc['date'];
    final amountRaw = doc['amount'] ?? 0;

    return IncomeEntity(
      incomeId: incomeId.toString(),
      category: category.toString(),
      date: dateRaw is DateTime
          ? dateRaw
          : DateTime.tryParse(dateRaw?.toString() ?? '') ?? DateTime.now(),
      amount: amountRaw is int
          ? amountRaw
          : int.tryParse(amountRaw.toString()) ?? 0,
    );
  }
}
