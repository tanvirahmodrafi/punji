import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punji/screens/home/blocs/get_expenses/get_expenses_bloc.dart';
import 'package:punji/screens/home/blocs/get_incomes/get_incomes_bloc.dart';
import 'package:punji/screens/stats/chart.dart';
import 'package:punji/screens/stats/download_pdf_screen.dart';

class StatScreen extends StatelessWidget {
  const StatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                child: BlocBuilder<GetExpensesBloc, GetExpensesState>(
                  builder: (context, state) {
                    if (state is GetExpensesSuccess) {
                      return MyChart(expenses: state.expenses);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<GetExpensesBloc, GetExpensesState>(
              builder: (context, expenseState) {
                return BlocBuilder<GetIncomesBloc, GetIncomesState>(
                  builder: (context, incomeState) {
                    final canOpen =
                        expenseState is GetExpensesSuccess &&
                        incomeState is GetIncomesSuccess;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            canOpen
                                ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => DownloadPdfScreen(
                                            expenses: expenseState.expenses,
                                            incomes: incomeState.incomes,
                                          ),
                                    ),
                                  );
                                }
                                : null,
                        child: const Text('Dawnload PDF'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
