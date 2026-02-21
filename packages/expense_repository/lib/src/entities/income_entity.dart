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
    return IncomeEntity(
      incomeId: doc['incomeId'],
      category: doc['category'],
      date: DateTime.parse(doc['date']),
      amount: doc['amount'],
    );
  }
}
