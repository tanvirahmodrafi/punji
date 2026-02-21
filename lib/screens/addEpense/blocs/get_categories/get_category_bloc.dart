import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';

part 'get_category_event.dart';
part 'get_category_state.dart';

class GetCategoryBloc extends Bloc<GetCategoryEvent, GetCategoryState> {
  final ExpenseRepository expenseRepository;

  GetCategoryBloc(this.expenseRepository) : super(GetCategoryInitial()) {
    on<GetCategories>((event, emit) async {
      emit(GetCategoryLoading());
      try {
        List<Category> categories = await expenseRepository.getCategory();
        emit(GetCategorySuccess(categories));
      } catch (e) {
        emit(GetCategoryFailure());
      }
    });
  }
}
