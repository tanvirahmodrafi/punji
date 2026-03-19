part of 'create_expense_bloc.dart';

sealed class CreateExpenseEvent extends Equatable {
  const CreateExpenseEvent();

  @override
  List<Object> get props => [];
}

class CreateExpense extends CreateExpenseEvent {
  final Expense expense;
  const CreateExpense(this.expense);

  @override
  List<Object> get props => [expense];
}

class UpdateExpense extends CreateExpenseEvent {
  final Expense expense;
  const UpdateExpense(this.expense);

  @override
  List<Object> get props => [expense];
}

class CreateSplitExpense extends CreateExpenseEvent {
  final Expense expense;
  final String partnerUserId;
  final int totalAmount;
  final int partnerShareAmount;

  const CreateSplitExpense({
    required this.expense,
    required this.partnerUserId,
    required this.totalAmount,
    required this.partnerShareAmount,
  });

  @override
  List<Object> get props => [
    expense,
    partnerUserId,
    totalAmount,
    partnerShareAmount,
  ];
}

class UpdateSplitExpense extends CreateExpenseEvent {
  final Expense expense;
  final int totalAmount;
  final int partnerShareAmount;

  const UpdateSplitExpense({
    required this.expense,
    required this.totalAmount,
    required this.partnerShareAmount,
  });

  @override
  List<Object> get props => [expense, totalAmount, partnerShareAmount];
}
