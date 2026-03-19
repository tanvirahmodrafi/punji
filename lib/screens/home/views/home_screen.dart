import 'dart:math';
import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punji/screens/addEpense/blocs/create_category/create_category_bloc.dart';
import 'package:punji/screens/addEpense/blocs/create_expense/create_expense_bloc.dart';
import 'package:punji/screens/addEpense/blocs/get_categories/get_category_bloc.dart';
import 'package:punji/screens/addEpense/views/addExpense.dart';
import 'package:punji/screens/home/blocs/get_expenses/get_expenses_bloc.dart';
import 'package:punji/screens/home/views/main_screen.dart';
import 'package:punji/theme/app_ui_style.dart';

import '../../stats/stats.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = AppUiStyle.isDark(context);
    final selectedItem = Theme.of(context).colorScheme.primary;
    final unselectedItem = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.75);

    return Scaffold(
      // Bottom Navigation Bar with `onTap` to switch between the screens
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (value) {
            setState(() {
              index = value;
            });
          },
          backgroundColor:
              AppUiStyle.card(context),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: isDark ? 0 : 3,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.home,
                color: index == 0 ? selectedItem : unselectedItem,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.chart_bar_alt_fill,
                color: index == 1 ? selectedItem : unselectedItem,
              ),
              label: 'Stats',
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () async {
          final expenseRepository = context.read<ExpenseRepository>();
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder:
                  (BuildContext context) => MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create:
                            (context) => CreateCategoryBloc(expenseRepository),
                      ),
                      BlocProvider(
                        create:
                            (context) =>
                                GetCategoryBloc(expenseRepository)
                                  ..add(GetCategories()),
                      ),
                      BlocProvider(
                        create:
                            (context) => CreateExpenseBloc(expenseRepository),
                      ),
                    ],
                    child: const AddExpense(),
                  ),
            ),
          );
          // Refresh expenses when returning from AddExpense
          if (mounted) {
            context.read<GetExpensesBloc>().add(GetExpenses());
          }
        },
        shape: const CircleBorder(),
        child: Container(
          width: 100, // Custom width
          height: 100, // Custom height
          decoration: BoxDecoration(
            shape: BoxShape.circle, // Ensures the shape is round
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.tertiary,
              ],
              transform: const GradientRotation(pi / 4),
            ),
          ),
          child: const Icon(
            CupertinoIcons.add,
            color: Colors.white, // Icon color
          ),
        ),
      ),

      // Switch between screens based on selected index
      //body: widgetList[index],
      body: index == 0 ? MainScreen() : StatScreen(),
    );
  }
}
