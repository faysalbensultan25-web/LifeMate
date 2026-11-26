import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/services/language_service.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  List<Map<String, dynamic>> incomes = [];
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> moneyRecords = [];
  List<Map<String, dynamic>> payments = [];

  double totalIncome = 0;
  double totalExpense = 0;
  double totalReceivable = 0;
  double totalPayable = 0;

  double get balance => totalIncome - totalExpense;

  String currency = 'BDT (৳)';

  static const List<String> supportedCurrencies = [
    'BDT (৳)',
    'USD (\$)',
    'INR (₹)',
    'SAR (﷼)',
    'AED (د.إ)',
  ];

  String get currencySymbol {
    switch (currency) {
      case 'USD (\$)':
        return '\$';
      case 'INR (₹)':
        return '₹';
      case 'SAR (﷼)':
        return '﷼';
      case 'AED (د.إ)':
        return 'د.إ';
      default:
        return '৳';
    }
  }

  String formatMoney(double amount) {
    return '$currencySymbol ${amount.toStringAsFixed(2)}';
  }

  String tr(String en, String bn, String hi, String ar) {
    return LanguageService.text(
      english: en,
      bangla: bn,
      hindi: hi,
      arabic: ar,
    );
  }

  bool get isArabic => LanguageService.isArabic;

  @override
  void initState() {
    super.initState();
    initializeFinance();
  }

  Future<void> initializeFinance() async {
    await loadCurrency();
    await insertDefaultCategories();
    await loadFinanceData();
  }

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCurrency =
        prefs.getString('currency') ?? 'BDT (৳)';

    final selectedCurrency = supportedCurrencies.contains(savedCurrency)
        ? savedCurrency
        : 'BDT (৳)';

    if (!mounted) return;

    setState(() {
      currency = selectedCurrency;
    });
  }

  Future<void> insertDefaultCategories() async {
    final db = await AppDatabase.database;

    final defaults = {
      'income': [
        'Salary',
        'Business',
        'House Rent',
        'Investment',
        'Gift',
        'Other',
      ],
      'expense': [
        'Food',
        'Transport',
        'Shopping',
        'House Rent',
        'Electricity',
        'Medical',
        'Education',
        'Family',
        'Entertainment',
        'Other',
      ],
    };

    for (final entry in defaults.entries) {
      for (final name in entry.value) {
        final exists = await db.query(
          'categories',
          where: 'name = ? AND type = ?',
          whereArgs: [name, entry.key],
          limit: 1,
        );

        if (exists.isEmpty) {
          await db.insert('categories', {
            'name': name,
            'type': entry.key,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    }
  }

  Future<void> loadFinanceData() async {
    final db = await AppDatabase.database;

    final incomeData = await db.query(
      'incomes',
      orderBy: 'id DESC',
    );

    final expenseData = await db.query(
      'expenses',
      orderBy: 'id DESC',
    );

    final categoryData = await db.query(
      'categories',
      orderBy: 'name ASC',
    );

    final records = await db.query(
      'money_records',
      orderBy: 'id DESC',
    );

    final paymentData = await db.query(
      'money_payments',
      orderBy: 'id DESC',
    );

    double income = 0;
    double expense = 0;

    for (final x in incomeData) {
      income += (x['amount'] as num).toDouble();
    }

    for (final x in expenseData) {
      expense += (x['amount'] as num).toDouble();
    }

    final paidMap = <int, double>{};

    for (final payment in paymentData) {
      final id = payment['record_id'] as int;

      paidMap[id] = (paidMap[id] ?? 0) +
          (payment['amount'] as num).toDouble();
    }

    double receivable = 0;
    double payable = 0;

    for (final record in records) {
      final id = record['id'] as int;
      final amount = (record['amount'] as num).toDouble();
      final paid = paidMap[id] ?? 0;

      final remaining = (amount - paid).clamp(0.0, amount);

      if (record['type'] == 'receivable') {
        receivable += remaining;
      } else {
        payable += remaining;
      }
    }

    if (!mounted) return;

    setState(() {
      incomes = incomeData;
      expenses = expenseData;
      categories = categoryData;
      moneyRecords = records;
      payments = paymentData;

      totalIncome = income;
      totalExpense = expense;
      totalReceivable = receivable;
      totalPayable = payable;
    });
  }

  double paidAmount(int recordId) {
    double total = 0;

    for (final payment in payments) {
      if (payment['record_id'] == recordId) {
        total += (payment['amount'] as num).toDouble();
      }
    }

    return total;
  }

  double remainingAmount(Map<String, dynamic> record) {
    final amount = (record['amount'] as num).toDouble();

    return (amount - paidAmount(record['id'] as int))
        .clamp(0.0, amount);
  }

  String categoryName(dynamic id) {
    final item = categories.where((x) => x['id'] == id);

    if (item.isEmpty) return 'Other';

    return item.first['name'].toString();
  }

  String formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) return '';

    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> addCategory(String type) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          type == 'income'
              ? tr(
                  'Add Income Category',
                  'আয়ের খাত যোগ',
                  'आय श्रेणी जोड़ें',
                  'إضافة فئة دخل',
                )
              : tr(
                  'Add Expense Category',
                  'ব্যয়ের খাত যোগ',
                  'व्यय श्रेणी जोड़ें',
                  'إضافة فئة مصروف',
                ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: tr(
              'Category Name',
              'খাতের নাম',
              'श्रेणी का नाम',
              'اسم الفئة',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              tr(
                'Cancel',
                'বাতিল',
                'रद्द करें',
                'إلغاء',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();

              if (name.isEmpty) return;

              final db = await AppDatabase.database;

              final exists = await db.query(
                'categories',
                where: 'name = ? AND type = ?',
                whereArgs: [name, type],
                limit: 1,
              );

              if (exists.isNotEmpty) return;

              await db.insert('categories', {
                'name': name,
                'type': type,
                'created_at': DateTime.now().toIso8601String(),
              });

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              tr(
                'Save',
                'সংরক্ষণ',
                'सहेजें',
                'حفظ',
              ),
            ),
          ),
        ],
      ),
    );

    controller.dispose();

    await loadFinanceData();
  }

  Future<void> addTransaction(bool isIncome) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController();

    final type = isIncome ? 'income' : 'expense';

    DateTime selectedDate = DateTime.now();

    var availableCategories =
        categories.where((x) => x['type'] == type).toList();

    int? selectedCategoryId;

    dateController.text =
        DateFormat('dd MMM yyyy').format(selectedDate);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, update) {
            return AlertDialog(
              title: Text(
                isIncome
                    ? tr(
                        'Add Income',
                        'আয় যোগ করুন',
                        'आय जोड़ें',
                        'إضافة دخل',
                      )
                    : tr(
                        'Add Expense',
                        'ব্যয় যোগ করুন',
                        'व्यय जोड़ें',
                        'إضافة مصروف',
                      ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: tr(
                          'Amount',
                          'পরিমাণ',
                          'राशि',
                          'المبلغ',
                        ),
                        prefixText: '$currencySymbol ',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: tr(
                          'Category',
                          'খাত',
                          'श्रेणी',
                          'الفئة',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: availableCategories.map((x) {
                        return DropdownMenuItem<int>(
                          value: x['id'] as int,
                          child: Text(x['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        update(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          await addCategory(type);
                          await loadFinanceData();

                          availableCategories = categories
                              .where((x) => x['type'] == type)
                              .toList();

                          update(() {
                            if (availableCategories.isNotEmpty) {
                              selectedCategoryId =
                                  availableCategories.last['id'] as int;
                            }
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: Text(
                          tr(
                            'Add Category',
                            'খাত যোগ করুন',
                            'श्रेणी जोड़ें',
                            'إضافة فئة',
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: tr(
                          'Date',
                          'তারিখ',
                          'तारीख',
                          'التاريخ',
                        ),
                        prefixIcon:
                            const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (date != null) {
                          update(() {
                            selectedDate = date;
                            dateController.text =
                                DateFormat('dd MMM yyyy').format(date);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: tr(
                          'Description',
                          'বিবরণ',
                          'विवरण',
                          'الوصف',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    tr(
                      'Cancel',
                      'বাতিল',
                      'रद्द करें',
                      'إلغاء',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim());

                    if (amount == null ||
                        amount <= 0 ||
                        selectedCategoryId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr(
                              'Enter amount and select category',
                              'পরিমাণ লিখুন এবং খাত নির্বাচন করুন',
                              'राशि दर्ज करें और श्रेणी चुनें',
                              'أدخل المبلغ واختر الفئة',
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    final db = await AppDatabase.database;

                    await db.insert(
                      isIncome ? 'incomes' : 'expenses',
                      {
                        'amount': amount,
                        'category_id': selectedCategoryId,
                        'description':
                            descriptionController.text.trim(),
                        'date': selectedDate.toIso8601String(),
                        'created_at':
                            DateTime.now().toIso8601String(),
                      },
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(
                    tr(
                      'Save',
                      'সংরক্ষণ',
                      'सहेजें',
                      'حفظ',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    descriptionController.dispose();
    dateController.dispose();

    await loadFinanceData();
  }

  Future<void> addMoneyRecord(String type) async {
    final personController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    DateTime recordDate = DateTime.now();
    DateTime? expectedDate;

    final isReceivable = type == 'receivable';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          return AlertDialog(
            title: Text(
              isReceivable
                  ? tr(
                      'Add Receivable',
                      'পাওনা যোগ করুন',
                      'प्राप्य जोड़ें',
                      'إضافة مستحق',
                    )
                  : tr(
                      'Add Payable',
                      'দেনা যোগ করুন',
                      'देय जोड़ें',
                      'إضافة مستحق عليه',
                    ),
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: personController,
                    decoration: InputDecoration(
                      labelText: tr(
                        'Person Name',
                        'ব্যক্তির নাম',
                        'व्यक्ति का नाम',
                        'اسم الشخص',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: tr(
                        'Mobile Number',
                        'মোবাইল নম্বর',
                        'मोबाइल नंबर',
                        'رقم الهاتف',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: tr(
                        'Amount',
                        'পরিমাণ',
                        'राशि',
                        'المبلغ',
                      ),
                      prefixText: '$currencySymbol ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tr(
                        'Record Date',
                        'হিসাবের তারিখ',
                        'रिकॉर्ड तारीख',
                        'تاريخ التسجيل',
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy')
                          .format(recordDate),
                    ),
                    trailing:
                        const Icon(Icons.calendar_month),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: recordDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (date != null) {
                        update(() => recordDate = date);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tr(
                        'Expected Date (Optional)',
                        'সম্ভাব্য পরিশোধের তারিখ (ঐচ্ছিক)',
                        'अपेक्षित तारीख (वैकल्पिक)',
                        'التاريخ المتوقع (اختياري)',
                      ),
                    ),
                    subtitle: Text(
                      expectedDate == null
                          ? tr(
                              'Not set',
                              'নির্ধারণ করা হয়নি',
                              'निर्धारित नहीं',
                              'غير محدد',
                            )
                          : DateFormat('dd MMM yyyy')
                              .format(expectedDate!),
                    ),
                    trailing: const Icon(Icons.event),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            expectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (date != null) {
                        update(() => expectedDate = date);
                      }
                    },
                  ),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: tr(
                        'Note / Description',
                        'বিবরণ',
                        'विवरण',
                        'ملاحظات',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  tr(
                    'Cancel',
                    'বাতিল',
                    'रद्द करें',
                    'إلغاء',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = personController.text.trim();
                  final amount =
                      double.tryParse(amountController.text.trim());

                  if (name.isEmpty ||
                      amount == null ||
                      amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr(
                            'Enter name and a valid amount',
                            'নাম ও সঠিক পরিমাণ লিখুন',
                            'नाम और सही राशि दर्ज करें',
                            'أدخل الاسم والمبلغ الصحيح',
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  final db = await AppDatabase.database;

                  await db.insert('money_records', {
                    'type': type,
                    'person_name': name,
                    'phone': phoneController.text.trim(),
                    'amount': amount,
                    'record_date':
                        recordDate.toIso8601String(),
                    'expected_date':
                        expectedDate?.toIso8601String(),
                    'description':
                        descriptionController.text.trim(),
                    'created_at':
                        DateTime.now().toIso8601String(),
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(
                  tr(
                    'Save',
                    'সংরক্ষণ',
                    'सहेजें',
                    'حفظ',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    personController.dispose();
    phoneController.dispose();
    amountController.dispose();
    descriptionController.dispose();

    await loadFinanceData();
  }

  Future<void> addPayment(Map<String, dynamic> record) async {
    final controller = TextEditingController();
    final noteController = TextEditingController();

    DateTime paymentDate = DateTime.now();
    final remaining = remainingAmount(record);

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            tr(
              'Add Payment',
              'পরিশোধ যোগ করুন',
              'भुगतान जोड़ें',
              'إضافة دفعة',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${tr('Remaining', 'বাকি', 'शेष', 'المتبقي')}: ${formatMoney(remaining)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: tr(
                    'Payment Amount',
                    'পরিশোধের পরিমাণ',
                    'भुगतान राशि',
                    'مبلغ الدفعة',
                  ),
                  prefixText: '$currencySymbol ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  tr(
                    'Payment Date',
                    'পরিশোধের তারিখ',
                    'भुगतान की तारीख',
                    'تاريخ الدفع',
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd MMM yyyy')
                      .format(paymentDate),
                ),
                trailing:
                    const Icon(Icons.calendar_month),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: paymentDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (date != null) {
                    update(() => paymentDate = date);
                  }
                },
              ),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: tr(
                    'Note',
                    'মন্তব্য',
                    'टिप्पणी',
                    'ملاحظة',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                tr(
                  'Cancel',
                  'বাতিল',
                  'रद्द करें',
                  'إلغاء',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    double.tryParse(controller.text.trim());

                if (amount == null ||
                    amount <= 0 ||
                    amount > remaining) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr(
                          'Enter a valid amount within the remaining balance',
                          'বাকি টাকার মধ্যে সঠিক পরিমাণ লিখুন',
                          'शेष राशि के भीतर सही राशि दर्ज करें',
                          'أدخل مبلغاً صحيحاً ضمن الرصيد المتبقي',
                        ),
                      ),
                    ),
                  );
                  return;
                }

                final db = await AppDatabase.database;

                await db.insert('money_payments', {
                  'record_id': record['id'],
                  'amount': amount,
                  'payment_date':
                      paymentDate.toIso8601String(),
                  'note': noteController.text.trim(),
                  'created_at':
                      DateTime.now().toIso8601String(),
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(
                tr(
                  'Save',
                  'সংরক্ষণ',
                  'सहेजें',
                  'حفظ',
                ),
              ),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    noteController.dispose();

    await loadFinanceData();
  }

  Future<void> deleteMoneyRecord(int id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'money_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    await loadFinanceData();
  }

  Future<void> deleteTransaction(
    bool isIncome,
    int id,
  ) async {
    final db = await AppDatabase.database;

    await db.delete(
      isIncome ? 'incomes' : 'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    await loadFinanceData();
  }

  Widget summaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(.12),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatMoney(amount),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget transactionCard(
    Map<String, dynamic> item,
    bool isIncome,
  ) {
    final amount =
        (item['amount'] as num).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? Colors.green.shade50
              : Colors.red.shade50,
          child: Icon(
            isIncome
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isIncome
                ? Colors.green
                : Colors.red,
          ),
        ),
        title: Text(
          '${isIncome ? '+' : '-'} ${formatMoney(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                isIncome ? Colors.green : Colors.red,
          ),
        ),
        subtitle: Text(
          '${categoryName(item['category_id'])}'
          '${item['description'].toString().isNotEmpty ? ' • ${item['description']}' : ''}'
          '\n${formatDate(item['date'])}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
          onPressed: () => deleteTransaction(
            isIncome,
            item['id'] as int,
          ),
        ),
      ),
    );
  }

  Widget history(
    String title,
    List<Map<String, dynamic>> items,
    bool isIncome,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Card(
            child: ListTile(
              leading: Icon(
                isIncome
                    ? Icons.account_balance_wallet_outlined
                    : Icons.receipt_long_outlined,
              ),
              title: Text(
                isIncome
                    ? tr(
                        'No income recorded',
                        'কোনো আয় নেই',
                        'कोई आय दर्ज नहीं',
                        'لا يوجد دخل مسجل',
                      )
                    : tr(
                        'No expense recorded',
                        'কোনো ব্যয় নেই',
                        'कोई व्यय दर्ज नहीं',
                        'لا توجد مصروفات مسجلة',
                      ),
              ),
            ),
          )
        else
          ...items.map(
            (x) => transactionCard(x, isIncome),
          ),
      ],
    );
  }

  Widget paymentHistory(int recordId) {
    final recordPayments = payments
        .where((p) => p['record_id'] == recordId)
        .toList();

    if (recordPayments.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          tr(
            'No payments recorded',
            'কোনো পরিশোধের তথ্য নেই',
            'कोई भुगतान दर्ज नहीं',
            'لا توجد دفعات مسجلة',
          ),
          style:
              const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text(
          tr(
            'Payment History',
            'পরিশোধের ইতিহাস',
            'भुगतान इतिहास',
            'سجل الدفعات',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        ...recordPayments.map((payment) {
          final amount =
              (payment['amount'] as num).toDouble();
          final note =
              (payment['note'] ?? '').toString();

          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
            title: Text(
              formatMoney(amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            subtitle: Text(
              '${formatDate(payment['payment_date'])}'
              '${note.isNotEmpty ? ' • $note' : ''}',
            ),
          );
        }),
      ],
    );
  }

  Widget moneySection(String type) {
    final isReceivable =
        type == 'receivable';

    final records = moneyRecords
        .where((x) => x['type'] == type)
        .toList();

    final title = isReceivable
        ? tr(
            'Receivable - My Money',
            'আমার পাওনা',
            'मेरा प्राप्य',
            'مستحقاتي',
          )
        : tr(
            'Payable - My Debt',
            'আমার দেনা',
            'मेरे ऋण',
            'ديوني',
          );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => addMoneyRecord(type),
              icon: const Icon(
                Icons.add_circle,
                color: Colors.blue,
              ),
              tooltip: tr(
                'Add',
                'যোগ করুন',
                'जोड़ें',
                'إضافة',
              ),
            ),
          ],
        ),
        if (records.isEmpty)
          Card(
            child: ListTile(
              leading: Icon(
                isReceivable
                    ? Icons.call_received
                    : Icons.call_made,
              ),
              title: Text(
                tr(
                  'No records yet',
                  'এখনো কোনো হিসাব নেই',
                  'अभी कोई रिकॉर्ड नहीं',
                  'لا توجد سجلات بعد',
                ),
              ),
            ),
          )
        else
          ...records.map((record) {
            final id = record['id'] as int;
            final amount =
                (record['amount'] as num).toDouble();
            final paid = paidAmount(id);
            final remaining =
                remainingAmount(record);
            final isPaid = remaining <= 0;

            return Card(
              margin:
                  const EdgeInsets.only(bottom: 9),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: isReceivable
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  child: Icon(
                    isReceivable
                        ? Icons.call_received
                        : Icons.call_made,
                    color: isReceivable
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                title: Text(
                  record['person_name'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${tr('Total', 'মোট', 'कुल', 'الإجمالي')}: ${formatMoney(amount)}'
                  '\n${tr('Remaining', 'বাকি', 'शेष', 'المتبقي')}: ${formatMoney(remaining)}',
                ),
                trailing: Text(
                  isPaid
                      ? tr(
                          'Paid',
                          'পরিশোধিত',
                          'भुगतान',
                          'مدفوع',
                        )
                      : paid > 0
                          ? tr(
                              'Partial',
                              'আংশিক',
                              'आंशिक',
                              'جزئي',
                            )
                          : tr(
                              'Due',
                              'বাকি',
                              'बकाया',
                              'مستحق',
                            ),
                  style: TextStyle(
                    color: isPaid
                        ? Colors.green
                        : Colors.orange,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if ((record['phone'] ?? '')
                            .toString()
                            .isNotEmpty)
                          Text(
                            '${tr('Mobile', 'মোবাইল', 'मोबाइल', 'الهاتف')}: ${record['phone']}',
                          ),
                        Text(
                          '${tr('Date', 'তারিখ', 'तारीख', 'التاريخ')}: ${formatDate(record['record_date'])}',
                        ),
                        if (record['expected_date'] !=
                            null)
                          Text(
                            '${tr('Expected Date', 'সম্ভাব্য তারিখ', 'अपेक्षित तारीख', 'التاريخ المتوقع')}: ${formatDate(record['expected_date'])}',
                          ),
                        if ((record['description'] ??
                                '')
                            .toString()
                            .isNotEmpty)
                          Text(
                            '${tr('Note', 'বিবরণ', 'विवरण', 'ملاحظة')}: ${record['description']}',
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${tr('Paid', 'পরিশোধ হয়েছে', 'भुगतान हुआ', 'المدفوع')}: ${formatMoney(paid)}',
                        ),
                        Text(
                          '${tr('Remaining', 'বাকি', 'शेष', 'المتبقي')}: ${formatMoney(remaining)}',
                        ),
                        paymentHistory(id),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (!isPaid)
                              ElevatedButton.icon(
                                onPressed: () =>
                                    addPayment(record),
                                icon: const Icon(
                                  Icons.payments,
                                  size: 18,
                                ),
                                label: Text(
                                  tr(
                                    'Add Payment',
                                    'পরিশোধ যোগ',
                                    'भुगतान जोड़ें',
                                    'إضافة دفعة',
                                  ),
                                ),
                              ),
                            IconButton(
                              onPressed: () =>
                                  deleteMoneyRecord(id),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: tr(
                                'Delete',
                                'মুছুন',
                                'हटाएं',
                                'حذف',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic
          ? ui.TextDirection.rtl
          : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            tr(
              'Finance',
              'আর্থিক হিসাব',
              'वित्त',
              'المالية',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: addCategory,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'income',
                  child: Text(
                    tr(
                      'Add Income Category',
                      'আয়ের খাত যোগ',
                      'आय श्रेणी जोड़ें',
                      'إضافة فئة دخل',
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'expense',
                  child: Text(
                    tr(
                      'Add Expense Category',
                      'ব্যয়ের খাত যোগ',
                      'व्यय श्रेणी जोड़ें',
                      'إضافة فئة مصروف',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: loadFinanceData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              14,
              10,
              14,
              30,
            ),
            children: [
              summaryCard(
                tr(
                  'Total Income',
                  'মোট আয়',
                  'कुल आय',
                  'إجمالي الدخل',
                ),
                totalIncome,
                Icons.trending_up,
                Colors.green,
              ),
              summaryCard(
                tr(
                  'Total Expense',
                  'মোট ব্যয়',
                  'कुल व्यय',
                  'إجمالي المصروفات',
                ),
                totalExpense,
                Icons.trending_down,
                Colors.red,
              ),
              summaryCard(
                tr(
                  'Current Balance',
                  'বর্তমান জমা',
                  'वर्तमान शेष',
                  'الرصيد الحالي',
                ),
                balance,
                Icons.account_balance_wallet,
                balance >= 0
                    ? Colors.blue
                    : Colors.red,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: summaryCard(
                      tr(
                        'Receivable',
                        'আমার পাওনা',
                        'मेरा प्राप्य',
                        'مستحقاتي',
                      ),
                      totalReceivable,
                      Icons.call_received,
                      Colors.teal,
                    ),
                  ),
                  Expanded(
                    child: summaryCard(
                      tr(
                        'Payable',
                        'আমার দেনা',
                        'मेरे ऋण',
                        'ديوني',
                      ),
                      totalPayable,
                      Icons.call_made,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              Card(
                color: Colors.blue.withOpacity(.07),
                child: ListTile(
                  title: Text(
                    tr(
                      'Net Receivable',
                      'নিট পাওনা',
                      'शुद्ध प्राप्य',
                      'صافي المستحقات',
                    ),
                  ),
                  trailing: Text(
                    formatMoney(
                      totalReceivable -
                          totalPayable,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          addTransaction(true),
                      icon: const Icon(Icons.add),
                      label: Text(
                        tr(
                          'Income',
                          'আয়',
                          'आय',
                          'دخل',
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          addTransaction(false),
                      icon: const Icon(Icons.remove),
                      label: Text(
                        tr(
                          'Expense',
                          'ব্যয়',
                          'व्यय',
                          'مصروف',
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              moneySection('receivable'),
              moneySection('payable'),
              history(
                tr(
                  'Income History',
                  'আয়ের ইতিহাস',
                  'आय का इतिहास',
                  'سجل الدخل',
                ),
                incomes,
                true,
              ),
              history(
                tr(
                  'Expense History',
                  'ব্যয়ের ইতিহাস',
                  'व्यय का इतिहास',
                  'سجل المصروفات',
                ),
                expenses,
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
