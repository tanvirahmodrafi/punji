import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:punji/screens/home/views/main_screen.dart';

class AllTransactionsScreen extends StatelessWidget {
  final List<Expense> expenses;
  final List<Income> incomes;

  const AllTransactionsScreen({
    super.key,
    required this.expenses,
    required this.incomes,
  });

  @override
  Widget build(BuildContext context) {
    // Merge and sort by date (newest first)
    final List<dynamic> transactions = [...expenses, ...incomes];
    transactions.sort((a, b) {
      final dateA = a is Expense ? a.date : (a as Income).date;
      final dateB = b is Expense ? b.date : (b as Income).date;
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(
          'All Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body:
          transactions.isEmpty
              ? const Center(
                child: Text(
                  "No transactions yet.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 10,
                ),
                itemCount: transactions.length,
                itemBuilder: (context, i) {
                  final item = transactions[i];
                  final bool isExpense = item is Expense;

                  final String name;
                  final int amount;
                  final DateTime date;
                  final Color circleColor;
                  final Widget circleChild;
                  final String amountPrefix;
                  final Color amountColor;

                  if (isExpense) {
                    final expense = item;
                    name = expense.category.name;
                    amount = expense.amount;
                    date = expense.date;
                    circleColor = Color(
                      int.tryParse(expense.category.color) ?? 0xFF9E9E9E,
                    );
                    circleChild = Image.asset(
                      'assets/${expense.category.icon}.png',
                      width: 28,
                      height: 28,
                      color: Colors.white,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.category, color: Colors.white);
                      },
                    );
                    amountPrefix = '-';
                    amountColor = Colors.red;
                  } else {
                    final income = item as Income;
                    name = income.category;
                    amount = income.amount;
                    date = income.date;
                    circleColor =
                        incomeCategoryColors[income.category] ?? Colors.teal;
                    circleChild = const Icon(
                      FontAwesomeIcons.dollarSign,
                      color: Colors.white,
                      size: 20,
                    );
                    amountPrefix = '+';
                    amountColor = Colors.green;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        color: circleColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    circleChild,
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$amountPrefix\$ $amount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: amountColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(date),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
