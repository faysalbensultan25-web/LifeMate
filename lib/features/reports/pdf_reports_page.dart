import 'dart:io';

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
  bool isGeneratingFinancial = false;
  bool isGeneratingProfile = false;

  String formatDate(dynamic value) {
    if (value == null) return '';

    try {
      final date = DateTime.parse(value.toString());
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // FINANCIAL STATEMENT PDF
  // ============================================================

  Future<void> generateFinancialStatement() async {
    setState(() {
      isGeneratingFinancial = true;
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
          content: Text(
            'Financial PDF generation failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingFinancial = false;
        });
      }
    }
  }

  // ============================================================
  // PROFILE PDF
  // ============================================================

  Future<void> generateProfilePdf() async {
    setState(() {
      isGeneratingProfile = true;
    });

    try {
      final db = await AppDatabase.database;

      final profiles = await db.query(
        'profiles',
        orderBy: 'id DESC',
        limit: 1,
      );

      if (profiles.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No profile information found. Please save your profile first.',
            ),
          ),
        );

        return;
      }

      final profile = profiles.first;

      pw.MemoryImage? profileImage;

      final photoPath = profile['photo_path']?.toString();

      if (photoPath != null &&
          photoPath.isNotEmpty &&
          File(photoPath).existsSync()) {
        try {
          final imageBytes = await File(photoPath).readAsBytes();
          profileImage = pw.MemoryImage(imageBytes);
        } catch (_) {
          profileImage = null;
        }
      }

      String value(String key) {
        final data = profile[key];

        if (data == null) {
          return 'Not provided';
        }

        final text = data.toString().trim();

        if (text.isEmpty) {
          return 'Not provided';
        }

        return text;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return [
              // Header
              pw.Row(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [
                  if (profileImage != null)
                    pw.Container(
                      width: 90,
                      height: 90,
                      margin: const pw.EdgeInsets.only(
                        right: 20,
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 8,
                        verticalRadius: 8,
                        child: pw.Image(
                          profileImage!,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),

                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LifeMate',
                          style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 6),

                        pw.Text(
                          'Personal Profile',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 8),

                        pw.Text(
                          value('name'),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 25),

              pw.Divider(),

              pw.SizedBox(height: 15),

              // Personal Information
              pw.Text(
                'Personal Information',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 12),

              _profileTable([
                ['Full Name', value('name')],
                ['Birth Date', formatDate(profile['birth_date'])],
                ['Gender', value('gender')],
                ['Blood Group', value('blood_group')],
              ]),

              pw.SizedBox(height: 20),

              // Contact Information
              pw.Text(
                'Contact Information',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 12),

              _profileTable([
                ['Phone', value('phone')],
                ['Email', value('email')],
                ['Current Address', value('address')],
                [
                  'Permanent Address',
                  value('permanent_address'),
                ],
                [
                  'Emergency Contact',
                  value('emergency_contact'),
                ],
              ]),

              pw.SizedBox(height: 20),

              // Professional Information
              pw.Text(
                'Education & Professional Information',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 12),

              _profileTable([
                ['Education', value('education')],
                ['Occupation', value('occupation')],
                ['Workplace', value('workplace')],
                ['Designation', value('designation')],
              ]),

              pw.SizedBox(height: 20),

              // About
              pw.Text(
                'About',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                  ),
                  borderRadius:
                      pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  value('about'),
                  style: const pw.TextStyle(
                    fontSize: 10,
                  ),
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

              pw.SizedBox(height: 4),

              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
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
          content: Text(
            'Profile PDF generation failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingProfile = false;
        });
      }
    }
  }

  // ============================================================
  // PROFILE TABLE
  // ============================================================

  pw.Widget _profileTable(
    List<List<String>> rows,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey400,
        width: 0.5,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                row[1],
                style: const pw.TextStyle(
                  fontSize: 9,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------------------------------------------
          // Financial Statement
          // ------------------------------------------------------

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
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
                      onPressed: isGeneratingFinancial ||
                              isGeneratingProfile
                          ? null
                          : generateFinancialStatement,
                      icon: isGeneratingFinancial
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.picture_as_pdf,
                            ),
                      label: Text(
                        isGeneratingFinancial
                            ? 'Generating...'
                            : 'Generate Financial Statement',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ------------------------------------------------------
          // Profile PDF
          // ------------------------------------------------------

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 48,
                    color: Color(0xFF1877F2),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Profile PDF',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Generate a professional PDF containing '
                    'your profile information and profile photo.',
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isGeneratingFinancial ||
                              isGeneratingProfile
                          ? null
                          : generateProfilePdf,
                      icon: isGeneratingProfile
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.picture_as_pdf,
                            ),
                      label: Text(
                        isGeneratingProfile
                            ? 'Generating...'
                            : 'Generate Profile PDF',
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
