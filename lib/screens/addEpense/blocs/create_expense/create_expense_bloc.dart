import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';

part 'create_expense_event.dart';
part 'create_expense_state.dart';

class CreateExpenseBloc extends Bloc<CreateExpenseEvent, CreateExpenseState> {
  final ExpenseRepository expenseRepository;

  CreateExpenseBloc(this.expenseRepository) : super(CreateExpenseInitial()) {
    on<CreateExpense>((event, emit) async {
      emit(CreateExpenseLoading());
      try {
        await expenseRepository.createExpense(event.expense);
        emit(CreateExpenseSuccess());
      } catch (e) {
        emit(CreateExpenseFailure(e.toString()));
      }
    });

    on<UpdateExpense>((event, emit) async {
      emit(CreateExpenseLoading());
      try {
        await expenseRepository.updateExpense(event.expense);
        emit(CreateExpenseSuccess());
      } catch (e) {
        emit(CreateExpenseFailure(e.toString()));
      }
    });

    on<CreateSplitExpense>((event, emit) async {
      emit(CreateExpenseLoading());
      try {
        await expenseRepository.createSplitExpensePair(
          myExpense: event.expense,
          partnerUserId: event.partnerUserId,
          totalAmount: event.totalAmount,
          partnerShareAmount: event.partnerShareAmount,
        );
        emit(CreateExpenseSuccess());
      } catch (e) {
        emit(CreateExpenseFailure(e.toString()));
      }
    });

    on<UpdateSplitExpense>((event, emit) async {
      emit(CreateExpenseLoading());
      try {
        await expenseRepository.updateSplitExpensePair(
          myExpense: event.expense,
          totalAmount: event.totalAmount,
          partnerShareAmount: event.partnerShareAmount,
        );
        emit(CreateExpenseSuccess());
      } catch (e) {
        emit(CreateExpenseFailure(e.toString()));
      }
    });
  }
}
