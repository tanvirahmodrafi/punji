part of 'get_expenses_bloc.dart';

sealed class GetExpensesEvent extends Equatable {
  const GetExpensesEvent();

  @override
  List<Object> get props => [];
}

class GetExpenses extends GetExpensesEvent {}

class DeleteExpense extends GetExpensesEvent {
  final Expense expense;
  const DeleteExpense(this.expense);

  @override
  List<Object> get props => [expense];
}
