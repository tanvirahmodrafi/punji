import 'dart:typed_data';

import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
              pw.Text('Total Income: +\$${totalIncome.toString()}'),
              pw.Text('Total Expense: -\$${totalExpense.toString()}'),
              pw.Text(
                'Net: \$${(totalIncome - totalExpense).toString()}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: const ['Date', 'Type', 'Category', 'Amount'],
                data:
                    transactions
                        .map(
                          (tx) => [
                            dateFormat.format(tx.date),
                            tx.isIncome ? 'Income' : 'Expense',
                            tx.category,
                            tx.isIncome ? '+\$${tx.amount}' : '-\$${tx.amount}',
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

    return Scaffold(
      appBar: AppBar(title: const Text('Dawnload PDF')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select date window',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFromDate,
              icon: const Icon(Icons.date_range),
              label: Text(
                _fromDate == null
                    ? 'From date'
                    : 'From: ${displayFormat.format(_fromDate!)}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickToDate,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                _toDate == null
                    ? 'To date'
                    : 'To: ${displayFormat.format(_toDate!)}',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isGenerating ? null : _downloadPdf,
              child:
                  _isGenerating
                      ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Download'),
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
