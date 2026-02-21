import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';

part 'get_incomes_event.dart';
part 'get_incomes_state.dart';

class GetIncomesBloc extends Bloc<GetIncomesEvent, GetIncomesState> {
  final ExpenseRepository expenseRepository;

  GetIncomesBloc(this.expenseRepository) : super(GetIncomesInitial()) {
    on<GetIncomes>((event, emit) async {
      emit(GetIncomesLoading());
      try {
        List<Income> incomes = await expenseRepository.getIncomes();
        emit(GetIncomesSuccess(incomes));
      } catch (e) {
        emit(GetIncomesFailure());
      }
    });

    on<DeleteIncome>((event, emit) async {
      try {
        await expenseRepository.deleteIncome(event.incomeId);
        List<Income> incomes = await expenseRepository.getIncomes();
        emit(GetIncomesSuccess(incomes));
      } catch (e) {
        emit(GetIncomesFailure());
      }
    });
  }
}
