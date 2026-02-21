part of 'get_expenses_bloc.dart';

sealed class GetExpensesEvent extends Equatable {
  const GetExpensesEvent();

  @override
  List<Object> get props => [];
}

class GetExpenses extends GetExpensesEvent {}

class DeleteExpense extends GetExpensesEvent {
  final String expenseId;
  const DeleteExpense(this.expenseId);

  @override
  List<Object> get props => [expenseId];
}
