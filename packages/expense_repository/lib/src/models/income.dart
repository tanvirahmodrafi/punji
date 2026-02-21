import '../entities/income_entity.dart';

class Income {
  String incomeId;
  String category; // e.g. "Salary", "Business", "Bank"
  DateTime date;
  int amount;

  Income({
    required this.incomeId,
    required this.category,
    required this.date,
    required this.amount,
  });

  static final empty = Income(
    incomeId: '',
    category: '',
    date: DateTime.now(),
    amount: 0,
  );

  IncomeEntity toEntity() {
    return IncomeEntity(
      incomeId: incomeId,
      category: category,
      date: date,
      amount: amount,
    );
  }

  static Income fromEntity(IncomeEntity entity) {
    return Income(
      incomeId: entity.incomeId,
      category: entity.category,
      date: entity.date,
      amount: entity.amount,
    );
  }
}
