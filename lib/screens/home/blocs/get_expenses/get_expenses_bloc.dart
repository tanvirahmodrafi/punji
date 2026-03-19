import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'get_expenses_event.dart';
part 'get_expenses_state.dart';

class GetExpensesBloc extends Bloc<GetExpensesEvent, GetExpensesState> {
  final ExpenseRepository expenseRepository;

  GetExpensesBloc(this.expenseRepository) : super(GetExpensesInitial()) {
    on<GetExpenses>((event, emit) async {
      emit(GetExpensesLoading());
      try {
        List<Expense> expenses = await expenseRepository.getExpenses();
        emit(GetExpensesSuccess(expenses));
      } catch (e) {
        emit(GetExpensesFailure());
      }
    });

    on<DeleteExpense>((event, emit) async {
      try {
        if (event.expense.isSplit) {
          final splitGroupId = event.expense.splitGroupId;
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          if (splitGroupId == null || splitGroupId.isEmpty) {
            throw StateError(
              'Missing split group id for split expense delete.',
            );
          }
          if (event.expense.splitCreatedBy != null &&
              event.expense.splitCreatedBy != currentUserId) {
            throw StateError(
              'Only the creator can delete this split expense pair.',
            );
          }
          await expenseRepository.deleteSplitExpensePair(splitGroupId);
        } else {
          await expenseRepository.deleteExpense(event.expense.expenseId);
        }
        List<Expense> expenses = await expenseRepository.getExpenses();
        emit(GetExpensesSuccess(expenses));
      } catch (e) {
        emit(GetExpensesFailure());
      }
    });
  }
}
