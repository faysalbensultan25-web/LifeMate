import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/database/app_database.dart';

class PdfReportsPage extends StatefulWidget {
  const PdfReportsPage({super.key});

  @override
  State<PdfReportsPage> createState() => _PdfReportsPageState();
}

class _PdfReportsPageState extends State<PdfReportsPage> {
  bool isGenerating = false;

  Future<void> generateFinancialStatement() async {
    setState(() {
      isGenerating = true;
    });

    try {
      final db = await AppDatabase.database;

      final incomes = await db.query(
        'incomes',
        orderBy: 'date DESC, id DESC',
      );

      final expenses = await db.query(
        'expenses',
        orderBy: 'date DESC, id DESC',
      );

      double totalIncome = 0;
      double totalExpense = 0;

      for (final income in incomes) {
        totalIncome += (income['amount'] as num?)?.toDouble() ?? 0;
      }

      for (final expense in expenses) {
        totalExpense += (expense['amount'] as num?)?.toDouble() ?? 0;
      }

      final balance = totalIncome - totalExpense;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return [
              pw.Text(
                'LifeMate',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Financial Statement',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 24),

              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Financial Summary',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Total Income: ${totalIncome.toStringAsFixed(2)}',
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Total Expense: ${totalExpense.toStringAsFixed(2)}',
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Balance: ${balance.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              pw.Text(
                'Income Transactions',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              if (incomes.isEmpty)
                pw.Text('No income transactions found.')
              else
                pw.TableHelper.fromTextArray(
                  headers: const [
                    'Date',
                    'Amount',
                    'Description',
                  ],
                  data: incomes.map((income) {
                    return [
                      formatDate(income['date']),
                      (income['amount'] as num?)
                              ?.toDouble()
                              .toStringAsFixed(2) ??
                          '0.00',
                      income['description']?.toString() ?? '',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.Font
