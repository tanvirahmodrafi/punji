import 'dart:math';

import 'package:expense_repository/expense_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyChart extends StatefulWidget {
  final List<Expense> expenses;
  const MyChart({super.key, required this.expenses});

  @override
  State<MyChart> createState() => _MyChartState();
}

class _MyChartState extends State<MyChart> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final axisTextColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.9);
    final barBackgroundColor =
        isDark ? const Color(0xFF2A3240) : Colors.grey.shade300;

    // Aggregate expenses by category
    final Map<String, int> categoryTotals = {};
    for (var expense in widget.expenses) {
      categoryTotals[expense.category.name] =
          (categoryTotals[expense.category.name] ?? 0) + expense.amount;
    }

    final categoryNames = categoryTotals.keys.toList();
    final categoryAmounts = categoryTotals.values.toList();

    if (categoryNames.isEmpty) {
      return const Center(child: Text("No data to display"));
    }

    final maxY =
        categoryAmounts.isNotEmpty
            ? (categoryAmounts.reduce((a, b) => a > b ? a : b).toDouble() * 1.2)
            : 5.0;

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < categoryNames.length) {
                  return SideTitleWidget(
                    space: 16,
                    axisSide: meta.axisSide,
                    child: Text(
                      categoryNames[idx].length > 5
                          ? '${categoryNames[idx].substring(0, 5)}..'
                          : categoryNames[idx],
                      style: TextStyle(
                        color: axisTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  space: 0,
                  axisSide: meta.axisSide,
                  child: Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      color: axisTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(categoryNames.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: categoryAmounts[i].toDouble(),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                  transform: const GradientRotation(pi / 40),
                ),
                width: 20,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: barBackgroundColor,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
