
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

  String formatDate(dynamic value) {
    if (value == null) return '';

    try {
      final date = DateTime.parse(value.toString());
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> generateFinancialStatement() async {
    setState(() {
      isGenerating = true;
    });

    try {
      final db = await AppDatabase.database;

      final incomes = await db.query(
        'incomes',
        orderBy: 'date DESC',
      );

      final expenses = await db.query(
        'expenses',
        orderBy: 'date DESC',
      );

      double totalIncome = 0;
      double totalExpense = 0;

      for (final item in incomes) {
        totalIncome +=
            (item['amount'] as num?)?.toDouble() ?? 0;
      }

      for (final item in expenses) {
        totalExpense +=
            (item['amount'] as num?)?.toDouble() ?? 0;
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

              pw.SizedBox(height: 8),

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
                style: const pw.TextStyle(fontSize: 10),
              ),

              pw.SizedBox(height: 24),

              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
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
                  headers: [
                    'Date',
                    'Amount',
                    'Description',
                  ],
                  data: incomes.map((item) {
                    return [
                      formatDate(item['date']),
                      ((item['amount'] as num?)?.toDouble() ?? 0)
                          .toStringAsFixed(2),
                      item['description']?.toString() ?? '',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(
                    fontSize: 9,
                  ),
                ),

              pw.SizedBox(height: 24),

              pw.Text(
                'Expense Transactions',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 10),

              if (expenses.isEmpty)
                pw.Text('No expense transactions found.')
              else
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Date',
                    'Amount',
                    'Description',
                  ],
                  data: expenses.map((item) {
                    return [
                      formatDate(item['date']),
                      ((item['amount'] as num?)?.toDouble() ?? 0)
                          .toStringAsFixed(2),
                      item['description']?.toString() ?? '',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(
                    fontSize: 9,
                  ),
                ),

              pw.SizedBox(height: 30),

              pw.Divider(),

              pw.SizedBox(height: 8),

              pw.Text(
                'Generated by LifeMate',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generation failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 48,
                    color: Color(0xFF1877F2),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Financial Statement',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Generate a PDF report containing your '
                    'income, expenses and current balance.',
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isGenerating
                          ? null
                          : generateFinancialStatement,
                      icon: isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(
                        isGenerating
                            ? 'Generating...'
                            : 'Generate Financial Statement',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
