import 'dart:typed_data';

import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:punji/theme/app_ui_style.dart';

class DownloadPdfScreen extends StatefulWidget {
  final List<Expense> expenses;
  final List<Income> incomes;

  const DownloadPdfScreen({
    super.key,
    required this.expenses,
    required this.incomes,
  });

  @override
  State<DownloadPdfScreen> createState() => _DownloadPdfScreenState();
}

class _DownloadPdfScreenState extends State<DownloadPdfScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startOfWindow = endOfToday.subtract(const Duration(days: 29));

    _toDate = endOfToday;
    _fromDate = DateTime(
      startOfWindow.year,
      startOfWindow.month,
      startOfWindow.day,
    );
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? _toDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _fromDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both from and to dates.')),
      );
      return;
    }

    final transactions = _buildTransactions();
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions found to export.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final effectiveRange = _resolveEffectiveRange(
        _fromDate!,
        _toDate!,
        transactions,
      );

      final filtered =
          transactions
              .where(
                (tx) =>
                    !tx.date.isBefore(effectiveRange.$1) &&
                    !tx.date.isAfter(effectiveRange.$2),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      final bytes = await _buildPdf(
        fromDate: effectiveRange.$1,
        toDate: effectiveRange.$2,
        transactions: filtered,
      );

      final formatter = DateFormat('yyyyMMdd');
      final fileName =
          'transactions_${formatter.format(effectiveRange.$1)}_${formatter.format(effectiveRange.$2)}.pdf';

      await Printing.sharePdf(bytes: bytes, filename: fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF ready: $fileName')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to generate PDF.')));
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  List<_TransactionRow> _buildTransactions() {
    return [
      ...widget.expenses.map(
        (e) => _TransactionRow(
          date: e.date,
          category: e.category.name,
          amount: e.amount,
          isIncome: false,
        ),
      ),
      ...widget.incomes.map(
        (i) => _TransactionRow(
          date: i.date,
          category: i.category,
          amount: i.amount,
          isIncome: true,
        ),
      ),
    ];
  }

  (DateTime, DateTime) _resolveEffectiveRange(
    DateTime selectedFrom,
    DateTime selectedTo,
    List<_TransactionRow> transactions,
  ) {
    final sortedDates =
        transactions.map((e) => e.date).toList()
          ..sort((a, b) => a.compareTo(b));
    final dataMin = DateTime(
      sortedDates.first.year,
      sortedDates.first.month,
      sortedDates.first.day,
    );
    final dataMax = DateTime(
      sortedDates.last.year,
      sortedDates.last.month,
      sortedDates.last.day,
      23,
      59,
      59,
    );

    DateTime from = selectedFrom;
    DateTime to = selectedTo;
    if (from.isAfter(to)) {
      final temp = from;
      from = to;
      to = temp;
    }

    // If selected window is fully out of data range, fall back to full available range.
    if (to.isBefore(dataMin) || from.isAfter(dataMax)) {
      return (dataMin, dataMax);
    }

    final effectiveFrom = from.isBefore(dataMin) ? dataMin : from;
    final effectiveTo = to.isAfter(dataMax) ? dataMax : to;
    return (effectiveFrom, effectiveTo);
  }

  Future<Uint8List> _buildPdf({
    required DateTime fromDate,
    required DateTime toDate,
    required List<_TransactionRow> transactions,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    final totalIncome = transactions
        .where((tx) => tx.isIncome)
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final totalExpense = transactions
        .where((tx) => !tx.isIncome)
        .fold<int>(0, (sum, tx) => sum + tx.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              pw.Text(
                'Transactions Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('From: ${dateFormat.format(fromDate)}'),
              pw.Text('To: ${dateFormat.format(toDate)}'),
              pw.SizedBox(height: 8),
              pw.Text('Total Income: +${totalIncome.toString()}'),
              pw.Text('Total Expense: -${totalExpense.toString()}'),
              pw.Text(
                'Net: ${(totalIncome - totalExpense).toString()}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: const ['Date', 'Type', 'Category', 'Amount'],
                data:
                    transactions
                        .map(
                          (tx) => [
                            dateFormat.format(tx.date),
                            tx.isIncome ? 'Income' : 'Expense',
                            tx.category,
                            tx.isIncome ? '+${tx.amount}' : '-${tx.amount}',
                          ],
                        )
                        .toList(),
              ),
            ],
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final displayFormat = DateFormat('dd MMM yyyy');
    final isDark = AppUiStyle.isDark(context);
    final cardColor = AppUiStyle.card(context);
    final secondaryCardColor = AppUiStyle.cardMuted(context);
    final hintColor = Theme.of(context).colorScheme.outline.withValues(alpha: 0.9);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Download PDF'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isDark
                          ? const [Color(0xFF1E293B), Color(0xFF111827)]
                          : const [Color(0xFFEAF4FF), Color(0xFFF3ECFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a date range and generate a shareable report',
                    style: TextStyle(fontSize: 13, color: hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  ...AppUiStyle.cardShadow(context),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 2),
                  _dateSelectorTile(
                    context: context,
                    title: _fromDate == null
                        ? 'From date'
                        : 'From: ${displayFormat.format(_fromDate!)}',
                    icon: Icons.date_range,
                    onTap: _pickFromDate,
                    bgColor: secondaryCardColor,
                  ),
                  const SizedBox(height: 12),
                  _dateSelectorTile(
                    context: context,
                    title: _toDate == null
                        ? 'To date'
                        : 'To: ${displayFormat.format(_toDate!)}',
                    icon: Icons.date_range_outlined,
                    onTap: _pickToDate,
                    bgColor: secondaryCardColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _downloadPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppUiStyle.primaryButton(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_isGenerating ? 'Generating...' : 'Generate PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateSelectorTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color bgColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow {
  final DateTime date;
  final String category;
  final int amount;
  final bool isIncome;

  const _TransactionRow({
    required this.date,
    required this.category,
    required this.amount,
    required this.isIncome,
  });
}
