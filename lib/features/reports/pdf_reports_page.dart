
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/database/app_database.dart';
import '../../core/services/language_service.dart';

class PdfReportsPage extends StatefulWidget {
  const PdfReportsPage({super.key});

  @override
  State<PdfReportsPage> createState() => _PdfReportsPageState();
}

class _PdfReportsPageState extends State<PdfReportsPage> {
  bool isGeneratingFinancial = false;
  bool isGeneratingProfile = false;
  bool isGeneratingBudget = false;

  // ============================================================
  // LOAD PDF FONT ACCORDING TO SELECTED APP LANGUAGE
  // ============================================================

  Future<pw.ThemeData> _loadPdfTheme() async {
    final language = LanguageService.language.value;

    String fontPath;

    switch (language) {
      case 'Bangla':
        fontPath = 'assets/fonts/NotoSansBengali-Regular.ttf';
        break;

      case 'Hindi':
        fontPath = 'assets/fonts/NotoSansDevanagari-Regular.ttf';
        break;

      case 'Arabic':
        fontPath = 'assets/fonts/NotoSansArabic-Regular.ttf';
        break;

      case 'English':
      default:
        fontPath = 'assets/fonts/NotoSans-Regular.ttf';
        break;
    }

    final fontData = await rootBundle.load(fontPath);
    final pdfFont = pw.Font.ttf(fontData);

    return pw.ThemeData.withFont(
      base: pdfFont,
      bold: pdfFont,
    );
  }

  String t({
    required String en,
    required String bn,
    required String hi,
    required String ar,
  }) {
    return LanguageService.text(
      english: en,
      bangla: bn,
      hindi: hi,
      arabic: ar,
    );
  }

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';

    try {
      return DateFormat('dd/MM/yyyy').format(
        DateTime.parse(value.toString()),
      );
    } catch (_) {
      return value.toString();
    }
  }

  String cleanValue(dynamic value) {
    if (value == null) return '';

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ============================================================
  // FINANCIAL STATEMENT PDF
  // ============================================================

  Future<void> generateFinancialStatement() async {
    if (isGeneratingFinancial ||
        isGeneratingProfile ||
        isGeneratingBudget) {
      return;
    }

    setState(() => isGeneratingFinancial = true);

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

      final categoryMap = <dynamic, String>{};

      try {
        final categories = await db.query('categories');

        for (final category in categories) {
          categoryMap[category['id']] =
              cleanValue(category['name']);
        }
      } catch (_) {}

      final transactions = <Map<String, dynamic>>[];

      for (final item in incomes) {
        transactions.add({
          'date': item['date'],
          'type': 'Income',
          'category': categoryMap[item['category_id']] ??
              cleanValue(item['category_id']),
          'description': cleanValue(item['description']),
          'amount': (item['amount'] as num?)?.toDouble() ?? 0,
        });
      }

      for (final item in expenses) {
        transactions.add({
          'date': item['date'],
          'type': 'Expense',
          'category': categoryMap[item['category_id']] ??
              cleanValue(item['category_id']),
          'description': cleanValue(item['description']),
          'amount': (item['amount'] as num?)?.toDouble() ?? 0,
        });
      }

      transactions.sort((a, b) {
        final aDate = DateTime.tryParse(
              a['date']?.toString() ?? '',
            ) ??
            DateTime(1900);

        final bDate = DateTime.tryParse(
              b['date']?.toString() ?? '',
            ) ??
            DateTime(1900);

        return bDate.compareTo(aDate);
      });

      final pdfTheme = await _loadPdfTheme();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          theme: pdfTheme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(18, 18, 18, 20),
          footer: (context) {
            return pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'LifeMate | Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey600,
                ),
              ),
            );
          },
          build: (context) {
            return [
              pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'LifeMate',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Financial Statement',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 8,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text(
                      'Income: ${totalIncome.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Expense: ${totalExpense.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Balance: ${balance.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              if (transactions.isEmpty)
                pw.Text(
                  'No transactions found.',
                  style: const pw.TextStyle(fontSize: 9),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Date',
                    'Type',
                    'Category',
                    'Description',
                    'Amount',
                  ],
                  data: transactions.map((item) {
                    return [
                      formatDate(item['date']),
                      item['type'],
                      item['category'],
                      item['description'],
                      item['amount'].toStringAsFixed(2),
                    ];
                  }).toList(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.0),
                    1: const pw.FlexColumnWidth(0.8),
                    2: const pw.FlexColumnWidth(1.1),
                    3: const pw.FlexColumnWidth(2.2),
                    4: const pw.FlexColumnWidth(1.0),
                  },
                  headerStyle: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 3,
                  ),
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.4,
                  ),
                ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated by LifeMate',
                style: const pw.TextStyle(
                  fontSize: 7,
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

      showMessage('Financial PDF generation failed: $e');
    } finally {
      if (mounted) {
        setState(() => isGeneratingFinancial = false);
      }
    }
  }

  // ============================================================
  // BUDGET PDF
  // ============================================================

  Future<void> generateBudgetPdf() async {
    if (isGeneratingFinancial ||
        isGeneratingProfile ||
        isGeneratingBudget) {
      return;
    }

    setState(() => isGeneratingBudget = true);

    try {
      final db = await AppDatabase.database;

      final budgets = await db.query(
        'budgets',
        orderBy: 'start_date DESC',
      );

      final categories = await db.query('categories');

      final categoryMap = <dynamic, String>{};

      for (final category in categories) {
        categoryMap[category['id']] =
            cleanValue(category['name']);
      }

      double totalIncomeBudget = 0;
      double totalExpenseBudget = 0;

      final incomeBudgets = <Map<String, dynamic>>[];
      final expenseBudgets = <Map<String, dynamic>>[];

      for (final budget in budgets) {
        final amount =
            (budget['amount'] as num?)?.toDouble() ?? 0;

        final type =
            cleanValue(budget['type']).toLowerCase();

        final category =
            categoryMap[budget['category_id']] ??
                cleanValue(budget['category_id']);

        final item = {
          'title': cleanValue(budget['title']),
          'category': category.isEmpty ? 'General' : category,
          'amount': amount,
          'period': cleanValue(budget['period']),
          'start_date': budget['start_date'],
          'end_date': budget['end_date'],
        };

        if (type == 'income') {
          totalIncomeBudget += amount;
          incomeBudgets.add(item);
        } else {
          totalExpenseBudget += amount;
          expenseBudgets.add(item);
        }
      }

      final plannedBalance =
          totalIncomeBudget - totalExpenseBudget;

      final pdfTheme = await _loadPdfTheme();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          theme: pdfTheme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(18, 18, 18, 20),
          footer: (context) {
            return pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'LifeMate | Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey600,
                ),
              ),
            );
          },
          build: (context) {
            return [
              pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'LifeMate',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Budget Report',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 7,
                  horizontal: 8,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text(
                      'Income Budget: ${totalIncomeBudget.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Expense Budget: ${totalExpenseBudget.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Planned Balance: ${plannedBalance.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Income Budget',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              if (incomeBudgets.isEmpty)
                pw.Text(
                  'No income budget found.',
                  style: const pw.TextStyle(fontSize: 8),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Title',
                    'Category',
                    'Period',
                    'Start',
                    'End',
                    'Amount',
                  ],
                  data: incomeBudgets.map((item) {
                    return [
                      item['title'],
                      item['category'],
                      item['period'],
                      formatDate(item['start_date']),
                      formatDate(item['end_date']),
                      item['amount'].toStringAsFixed(2),
                    ];
                  }).toList(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(1.2),
                    2: const pw.FlexColumnWidth(0.9),
                    3: const pw.FlexColumnWidth(0.9),
                    4: const pw.FlexColumnWidth(0.9),
                    5: const pw.FlexColumnWidth(1.0),
                  },
                  headerStyle: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 3,
                  ),
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.4,
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Expense Budget',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              if (expenseBudgets.isEmpty)
                pw.Text(
                  'No expense budget found.',
                  style: const pw.TextStyle(fontSize: 8),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Title',
                    'Category',
                    'Period',
                    'Start',
                    'End',
                    'Amount',
                  ],
                  data: expenseBudgets.map((item) {
                    return [
                      item['title'],
                      item['category'],
                      item['period'],
                      formatDate(item['start_date']),
                      formatDate(item['end_date']),
                      item['amount'].toStringAsFixed(2),
                    ];
                  }).toList(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(1.2),
                    2: const pw.FlexColumnWidth(0.9),
                    3: const pw.FlexColumnWidth(0.9),
                    4: const pw.FlexColumnWidth(0.9),
                    5: const pw.FlexColumnWidth(1.0),
                  },
                  headerStyle: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 3,
                  ),
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.4,
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated by LifeMate',
                style: const pw.TextStyle(
                  fontSize: 7,
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

      showMessage('Budget PDF generation failed: $e');
    } finally {
      if (mounted) {
        setState(() => isGeneratingBudget = false);
      }
    }
  }

  // ============================================================
  // PROFILE PDF / PROFESSIONAL CV
  // ============================================================

  Future<void> generateProfilePdf() async {
    if (isGeneratingFinancial ||
        isGeneratingProfile ||
        isGeneratingBudget) {
      return;
    }

    setState(() => isGeneratingProfile = true);

    try {
      final db = await AppDatabase.database;

      final profiles = await db.query(
        'profiles',
        orderBy: 'id DESC',
        limit: 1,
      );

      if (profiles.isEmpty) {
        showMessage(
          'No profile information found. Please save your profile first.',
        );
        return;
      }

      final profile = profiles.first;
      final profileId = profile['id'];

      final education = await db.query(
        'profile_education',
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'id DESC',
      );

      final training = await db.query(
        'profile_training',
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'id DESC',
      );

      final experience = await db.query(
        'profile_experience',
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'id DESC',
      );

      final skills = await db.query(
        'profile_skills',
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'id DESC',
      );

      final languages = await db.query(
        'profile_languages',
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'id DESC',
      );

      final achievements = await db.query(
        'profile_achievements',
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'id DESC',
      );

      pw.MemoryImage? profileImage;

      final photoPath = cleanValue(profile['photo_path']);

      if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
        try {
          profileImage = pw.MemoryImage(
            await File(photoPath).readAsBytes(),
          );
        } catch (_) {
          profileImage = null;
        }
      }

      String value(String key) {
        return cleanValue(profile[key]);
      }

      String dateValue(String key) {
        return formatDate(profile[key]);
      }

      final pdfTheme = await _loadPdfTheme();
      final pdf = pw.Document();
      final profileSections = <pw.Widget>[];

      profileSections.add(
        _infoSection(
          'Personal Information',
          [
            ['Full Name', value('name')],
            ['Birth Date', dateValue('birth_date')],
            ['Gender', value('gender')],
            ['Blood Group', value('blood_group')],
            ['Phone', value('phone')],
            ['Email', value('email')],
            ['Current Address', value('address')],
            ['Permanent Address', value('permanent_address')],
            ['Emergency Contact', value('emergency_contact')],
          ],
        ),
      );

      if (value('career_objective').isNotEmpty) {
        profileSections.add(
          _textSection(
            'Career Objective',
            value('career_objective'),
          ),
        );
      }

      // EDUCATION

      if (education.isNotEmpty) {
        profileSections.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('Education'),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Qualification',
                  'Institution',
                  'Subject',
                  'Result',
                  'Year',
                  'Period',
                ],
                data: education.map((record) {
                  final start = cleanValue(record['start_year']);
                  final end = cleanValue(record['end_year']);

                  String period = '';

                  if (start.isNotEmpty || end.isNotEmpty) {
                    if (start.isEmpty) {
                      period = end;
                    } else if (end.isEmpty) {
                      period = start;
                    } else {
                      period = '$start - $end';
                    }
                  }

                  return [
                    cleanValue(record['qualification']),
                    cleanValue(record['institution']),
                    cleanValue(record['subject']),
                    cleanValue(record['result']),
                    cleanValue(record['passing_year']),
                    period,
                  ];
                }).toList(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2),
                  1: const pw.FlexColumnWidth(1.8),
                  2: const pw.FlexColumnWidth(1.3),
                  3: const pw.FlexColumnWidth(0.8),
                  4: const pw.FlexColumnWidth(0.7),
                  5: const pw.FlexColumnWidth(1.0),
                },
                headerStyle: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 4,
                ),
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.4,
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          ),
        );
      }

      // TRAINING

      profileSections.add(
        _recordSection(
          'Training & Certifications',
          training,
          [
            ['Training Title', 'title'],
            ['Institution', 'institution'],
            ['Duration', 'duration'],
            ['Completion Year', 'completion_year'],
            ['Certificate Details', 'certificate_details'],
          ],
        ),
      );

      // EXPERIENCE

      profileSections.add(
        _recordSection(
          'Work Experience',
          experience,
          [
            ['Designation', 'designation'],
            ['Workplace', 'workplace'],
            ['Location', 'location'],
            ['Employment Type', 'employment_type'],
            ['Period', 'period'],
            ['Responsibilities', 'responsibilities'],
          ],
          specialFields: {
            'period': (record) {
              final start = formatDate(record['start_date']);

              final end = record['is_current'] == 1
                  ? 'Present'
                  : formatDate(record['end_date']);

              if (start.isEmpty) return end;
              if (end.isEmpty) return start;

              return '$start - $end';
            },
          },
        ),
      );

      // SKILLS

      profileSections.add(
        _recordSection(
          'Skills',
          skills,
          [
            ['Skill', 'skill_name'],
            ['Proficiency', 'proficiency'],
          ],
        ),
      );

      // LANGUAGES

      profileSections.add(
        _recordSection(
          'Languages',
          languages,
          [
            ['Language', 'language_name'],
            ['Proficiency', 'proficiency'],
          ],
        ),
      );

      // ACHIEVEMENTS

      profileSections.add(
        _recordSection(
          'Achievements',
          achievements,
          [
            ['Title', 'title'],
            ['Description', 'description'],
            ['Date', 'achievement_date'],
          ],
          dateFields: const ['achievement_date'],
        ),
      );

      // ADDITIONAL INFORMATION

      profileSections.add(
        _infoSection(
          'Additional Information',
          [
            ['Occupation', value('occupation')],
            ['Workplace', value('workplace')],
            ['Designation', value('designation')],
          ],
        ),
      );

      // SOCIAL LINKS

      profileSections.add(
        _infoSection(
          'Social Links',
          [
            ['Facebook', value('facebook')],
            ['LinkedIn', value('linkedin')],
            ['GitHub', value('github')],
            ['Website', value('website')],
          ],
        ),
      );

      if (value('about').isNotEmpty) {
        profileSections.add(
          _textSection(
            'About Me',
            value('about'),
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          theme: pdfTheme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          footer: (context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(top: 12),
              child: pw.Text(
                'LifeMate | Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            );
          },
          build: (context) {
            return [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (profileImage != null)
                    pw.Container(
                      width: 78,
                      height: 88,
                      margin: const pw.EdgeInsets.only(right: 16),
                      child: pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(
                          profileImage,
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
                          value('name').isEmpty
                              ? 'Personal CV'
                              : value('name'),
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        if (value('designation').isNotEmpty)
                          pw.Text(
                            value('designation'),
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        if (value('phone').isNotEmpty)
                          pw.Text(
                            value('phone'),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        if (value('email').isNotEmpty)
                          pw.Text(
                            value('email'),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        if (value('address').isNotEmpty)
                          pw.Text(
                            value('address'),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(
                color: PdfColors.grey500,
                thickness: 1,
              ),
              pw.SizedBox(height: 8),
              ...profileSections,
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Text(
                'Generated by LifeMate | '
                '${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 8,
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

      showMessage('Profile PDF generation failed: $e');
    } finally {
      if (mounted) {
        setState(() => isGeneratingProfile = false);
      }
    }
  }

  // ============================================================
  // PDF SECTION HELPERS
  // ============================================================

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 7),
      padding: const pw.EdgeInsets.only(
        bottom: 5,
        top: 5,
      ),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey400,
            width: 0.7,
          ),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  pw.Widget _infoSection(
    String title,
    List<List<String>> rows,
  ) {
    final validRows = rows
        .where(
          (row) =>
              row.length >= 2 && row[1].trim().isNotEmpty,
        )
        .toList();

    if (validRows.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(1.1),
            1: const pw.FlexColumnWidth(2),
          },
          children: validRows.map((row) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 4,
                  ),
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 4,
                  ),
                  child: pw.Text(
                    row[1],
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _textSection(
    String title,
    String content,
  ) {
    if (content.trim().isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        pw.Text(
          content,
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _recordSection(
    String title,
    List<Map<String, Object?>> records,
    List<List<String>> fields, {
    List<String> dateFields = const [],
    Map<String, String Function(Map<String, Object?>)>
        specialFields = const {},
  }) {
    if (records.isEmpty) {
      return pw.SizedBox();
    }

    final recordWidgets = <pw.Widget>[];

    for (final record in records) {
      final rows = <List<String>>[];

      for (final field in fields) {
        final label = field[0];
        final key = field[1];

        String text;

        if (specialFields.containsKey(key)) {
          text = specialFields[key]!(record);
        } else if (dateFields.contains(key)) {
          text = formatDate(record[key]);
        } else {
          text = cleanValue(record[key]);
        }

        if (text.isNotEmpty) {
          rows.add([label, text]);
        }
      }

      if (rows.isEmpty) continue;

      recordWidgets.add(
        pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 7),
          padding: const pw.EdgeInsets.all(7),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
            },
            children: rows.map((row) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 3,
                    ),
                    child: pw.Text(
                      row[0],
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 3,
                    ),
                    child: pw.Text(
                      row[1],
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }

    if (recordWidgets.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        ...recordWidgets,
        pw.SizedBox(height: 8),
      ],
    );
  }

  // ============================================================
  // BUILD - FOUR LANGUAGE SUPPORT
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.language,
      builder: (context, language, child) {
        final isArabic = language == 'Arabic';

        final isBusy = isGeneratingFinancial ||
            isGeneratingProfile ||
            isGeneratingBudget;

        return Directionality(
          textDirection: isArabic
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                t(
                  en: 'PDF Reports',
                  bn: 'পিডিএফ রিপোর্ট',
                  hi: 'पीडीएफ रिपोर्ट',
                  ar: 'تقارير PDF',
                ),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildReportCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: t(
                    en: 'Financial Statement',
                    bn: 'আর্থিক বিবরণী',
                    hi: 'वित्तीय विवरण',
                    ar: 'كشف الحساب المالي',
                  ),
                  description: t(
                    en: 'Generate a PDF report containing your income, expenses and current balance.',
                    bn: 'আপনার আয়, ব্যয় ও বর্তমান ব্যালেন্সসহ PDF রিপোর্ট তৈরি করুন।',
                    hi: 'अपनी आय, खर्च और वर्तमान शेष राशि की PDF रिपोर्ट बनाएं।',
                    ar: 'أنشئ تقرير PDF يتضمن دخلك ومصروفاتك ورصيدك الحالي.',
                  ),
                  buttonText: t(
                    en: 'Generate Financial Statement',
                    bn: 'আর্থিক বিবরণী তৈরি করুন',
                    hi: 'वित्तीय विवरण बनाएं',
                    ar: 'إنشاء كشف الحساب المالي',
                  ),
                  generatingText: t(
                    en: 'Generating...',
                    bn: 'তৈরি হচ্ছে...',
                    hi: 'बनाया जा रहा है...',
                    ar: 'جارٍ الإنشاء...',
                  ),
                  iconColor: const Color(0xFF1877F2),
                  isGenerating: isGeneratingFinancial,
                  isBusy: isBusy,
                  onPressed: generateFinancialStatement,
                ),

                const SizedBox(height: 16),

                _buildReportCard(
                  icon: Icons.account_balance_outlined,
                  title: t(
                    en: 'Budget PDF',
                    bn: 'বাজেট PDF',
                    hi: 'बजट PDF',
                    ar: 'تقرير الميزانية',
                  ),
                  description: t(
                    en: 'Generate a PDF report with income budget, expense budget, categories and planned balance.',
                    bn: 'আয়ের বাজেট, ব্যয়ের বাজেট, বিভাগ ও পরিকল্পিত ব্যালেন্সসহ PDF তৈরি করুন।',
                    hi: 'आय बजट, खर्च बजट, श्रेणियों और नियोजित शेष राशि की PDF रिपोर्ट बनाएं।',
                    ar: 'أنشئ تقرير PDF لميزانية الدخل والمصروفات والتصنيفات والرصيد المخطط.',
                  ),
                  buttonText: t(
                    en: 'Generate Budget PDF',
                    bn: 'বাজেট PDF তৈরি করুন',
                    hi: 'बजट PDF बनाएं',
                    ar: 'إنشاء تقرير الميزانية',
                  ),
                  generatingText: t(
                    en: 'Generating...',
                    bn: 'তৈরি হচ্ছে...',
                    hi: 'बनाया जा रहा है...',
                    ar: 'جارٍ الإنشاء...',
                  ),
                  iconColor: const Color(0xFF16A085),
                  isGenerating: isGeneratingBudget,
                  isBusy: isBusy,
                  onPressed: generateBudgetPdf,
                ),

                const SizedBox(height: 16),

                _buildReportCard(
                  icon: Icons.person_outline,
                  title: t(
                    en: 'Professional CV / Profile PDF',
                    bn: 'পেশাদার জীবনবৃত্তান্ত / প্রোফাইল PDF',
                    hi: 'प्रोफेशनल CV / प्रोफाइल PDF',
                    ar: 'السيرة الذاتية / الملف الشخصي',
                  ),
                  description: t(
                    en: 'Generate a compact professional CV with personal details, education, training, experience, skills, languages and achievements.',
                    bn: 'ব্যক্তিগত তথ্য, শিক্ষা, প্রশিক্ষণ, অভিজ্ঞতা, দক্ষতা, ভাষা ও অর্জনসহ পেশাদার জীবনবৃত্তান্ত তৈরি করুন।',
                    hi: 'व्यक्तिगत जानकारी, शिक्षा, प्रशिक्षण, अनुभव, कौशल, भाषाओं और उपलब्धियों के साथ CV बनाएं।',
                    ar: 'أنشئ سيرة ذاتية احترافية تتضمن البيانات الشخصية والتعليم والتدريب والخبرة والمهارات والإنجازات.',
                  ),
                  buttonText: t(
                    en: 'Generate Professional CV',
                    bn: 'পেশাদার CV তৈরি করুন',
                    hi: 'प्रोफेशनल CV बनाएं',
                    ar: 'إنشاء السيرة الذاتية',
                  ),
                  generatingText: t(
                    en: 'Generating...',
                    bn: 'তৈরি হচ্ছে...',
                    hi: 'बनाया जा रहा है...',
                    ar: 'جارٍ الإنشاء...',
                  ),
                  iconColor: const Color(0xFF8E44AD),
                  isGenerating: isGeneratingProfile,
                  isBusy: isBusy,
                  onPressed: generateProfilePdf,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required String generatingText,
    required Color iconColor,
    required bool isGenerating,
    required bool isBusy,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : onPressed,
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
                  isGenerating ? generatingText : buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
