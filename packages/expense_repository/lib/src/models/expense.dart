import '../entities/expense_entity.dart';
import 'category.dart';

class Expense {
  String expenseId;
  Category category;
  DateTime date;
  int amount;
  bool isSplit;
  String? splitGroupId;
  String? splitCreatedBy;
  String? splitPartnerId;
  int? splitTotalAmount;
  int? splitShareAmount;
  String? userId;

  Expense({
    required this.expenseId,
    required this.category,
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

  static final empty = Expense(
    expenseId: '',
    category: Category.empty,
    date: DateTime.now(),
    amount: 0,
    isSplit: false,
  );

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      expenseId: expenseId,
      categoryId: category.categoryId,
      date: date,
      amount: amount,
      isSplit: isSplit,
      splitGroupId: splitGroupId,
      splitCreatedBy: splitCreatedBy,
      splitPartnerId: splitPartnerId,
      splitTotalAmount: splitTotalAmount,
      splitShareAmount: splitShareAmount,
      userId: userId,
    );
  }

  static Expense fromEntity(ExpenseEntity entity, Category category) {
    return Expense(
      expenseId: entity.expenseId,
      category: category,
      date: entity.date,
      amount: entity.amount,
      isSplit: entity.isSplit,
      splitGroupId: entity.splitGroupId,
      splitCreatedBy: entity.splitCreatedBy,
      splitPartnerId: entity.splitPartnerId,
      splitTotalAmount: entity.splitTotalAmount,
      splitShareAmount: entity.splitShareAmount,
      userId: entity.userId,
    );
  }
}
