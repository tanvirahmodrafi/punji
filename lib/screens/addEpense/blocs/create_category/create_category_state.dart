part of 'create_category_bloc.dart';

sealed class CreateCategoryState extends Equatable {
  const CreateCategoryState();

  @override
  List<Object> get props => [];
}

final class CreateCategoryInitial extends CreateCategoryState {}

final class CreateCategoryFailure extends CreateCategoryState {
  final String error;
  const CreateCategoryFailure({this.error = 'Unknown error'});

  @override
  List<Object> get props => [error];
}

final class CreateCategoryLoading extends CreateCategoryState {}

final class CreateCategorySuccess extends CreateCategoryState {}
