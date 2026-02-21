part of 'get_category_bloc.dart';

sealed class GetCategoryEvent extends Equatable {
  const GetCategoryEvent();

  @override
  List<Object> get props => [];
}

class GetCategories extends GetCategoryEvent {}
