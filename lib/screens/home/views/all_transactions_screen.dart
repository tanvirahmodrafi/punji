import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:punji/screens/home/views/main_screen.dart';
import 'package:punji/theme/app_ui_style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final userId = Supabase.instance.client.auth.currentUser?.id;

    // Merge and sort by date (newest first)
    final List<dynamic> transactions = [...expenses, ...incomes];
    transactions.sort((a, b) {
      final dateA = a is Expense ? a.date : (a as Income).date;
      final dateB = b is Expense ? b.date : (b as Income).date;
      return dateB.compareTo(dateA);
    });

    final Map<String, List<dynamic>> monthBuckets = {};
    for (final tx in transactions) {
      final date = tx is Expense ? tx.date : (tx as Income).date;
      final key = DateFormat('yyyy-MM').format(date);
      monthBuckets.putIfAbsent(key, () => []).add(tx);
    }
    final sortedMonthKeys =
        monthBuckets.keys.toList()..sort((a, b) => b.compareTo(a));

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
              : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 10,
                ),
                children: [
                  for (final monthKey in sortedMonthKeys) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Text(
                        DateFormat(
                          'MMMM yyyy',
                        ).format(DateTime.parse('$monthKey-01')),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    for (final item in monthBuckets[monthKey]!)
                      _buildTransactionCard(context, item, userId),
                  ],
                ],
              ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    dynamic item,
    String? userId,
  ) {
    final bool isExpense = item is Expense;

    final String name;
    final int amount;
    final DateTime date;
    final Color circleColor;
    final Widget circleChild;
    final String amountPrefix;
    final Color amountColor;
    bool isSplit = false;
    bool isPartnerTxn = false;

    if (isExpense) {
      final expense = item;
      name = expense.category.name;
      amount = expense.amount;
      date = expense.date;
      circleColor = Color(int.tryParse(expense.category.color) ?? 0xFF9E9E9E);
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
      isSplit = expense.isSplit;
      isPartnerTxn =
          expense.isSplit &&
          userId != null &&
          expense.splitCreatedBy != null &&
          expense.splitCreatedBy != userId;
    } else {
      final income = item as Income;
      name = income.category;
      amount = income.amount;
      date = income.date;
      circleColor = incomeCategoryColors[income.category] ?? Colors.teal;
      circleChild = const Icon(
        FontAwesomeIcons.wallet,
        color: Colors.white,
        size: 18,
      );
      amountPrefix = '+';
      amountColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppUiStyle.card(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppUiStyle.cardShadow(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        circleChild,
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSplit)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isPartnerTxn
                                            ? Colors.deepPurple.withValues(
                                              alpha: 0.16,
                                            )
                                            : Colors.blue.withValues(
                                              alpha: 0.14,
                                            ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPartnerTxn
                                            ? Icons.people_alt_rounded
                                            : Icons.swap_horiz_rounded,
                                        size: 12,
                                        color:
                                            isPartnerTxn
                                                ? Colors.deepPurple
                                                : Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPartnerTxn ? 'Partner' : 'Split',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              isPartnerTxn
                                                  ? Colors.deepPurple
                                                  : Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM, yyyy').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$amountPrefix $amount',
                style: TextStyle(
                  fontSize: 14,
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
