import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:punji/screens/home/blocs/get_expenses/get_expenses_bloc.dart';
import 'package:punji/screens/home/blocs/get_incomes/get_incomes_bloc.dart';
import 'package:punji/screens/stats/chart.dart';
import 'package:punji/screens/stats/download_pdf_screen.dart';
import 'package:punji/theme/app_ui_style.dart';

class StatScreen extends StatelessWidget {
  const StatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<GetExpensesBloc, GetExpensesState>(
        builder: (context, expenseState) {
          return BlocBuilder<GetIncomesBloc, GetIncomesState>(
            builder: (context, incomeState) {
              final List<Expense> expenses =
                  expenseState is GetExpensesSuccess
                      ? expenseState.expenses
                      : const <Expense>[];
              final List<Income> incomes =
                  incomeState is GetIncomesSuccess
                      ? incomeState.incomes
                      : const <Income>[];
              final canOpen =
                  expenseState is GetExpensesSuccess &&
                  incomeState is GetIncomesSuccess;
              final totalExpense = expenses.fold<double>(
                0,
                (sum, e) => sum + e.amount.toDouble(),
              );
              final totalIncome = incomes.fold<double>(
                0,
                (sum, i) => sum + i.amount.toDouble(),
              );
              final net = totalIncome - totalExpense;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1F2937),
                            const Color(0xFF111827),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistics',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Track your spending rhythm and income flow',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _summaryPill(
                                label: 'Income',
                                value: totalIncome.toStringAsFixed(2),
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 10),
                              _summaryPill(
                                label: 'Expense',
                                value: totalExpense.toStringAsFixed(2),
                                color: const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 10),
                              _summaryPill(
                                label: 'Net',
                                value: net.toStringAsFixed(2),
                                color:
                                    net >= 0
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width * 0.92,
                      decoration: BoxDecoration(
                        color: AppUiStyle.card(context),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppUiStyle.cardShadow(context),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                        child:
                            expenseState is GetExpensesSuccess
                                ? MyChart(expenses: expenseState.expenses)
                                : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppUiStyle.primaryButton(context),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text(
                          'Export Statistics PDF',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _summaryPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
