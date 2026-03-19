import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punji/app_view.dart';
import 'package:punji/screens/home/blocs/get_expenses/get_expenses_bloc.dart';
import 'package:punji/screens/home/blocs/get_incomes/get_incomes_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ExpenseRepository>(
      create: (context) => SupabaseExpenseRepo(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) => GetExpensesBloc(context.read<ExpenseRepository>()),
          ),
          BlocProvider(
            create:
                (context) => GetIncomesBloc(context.read<ExpenseRepository>()),
          ),
        ],
        child: const MyAppView(),
      ),
    );
  }
}
