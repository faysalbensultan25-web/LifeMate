
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/services/language_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool isLoading = true;

  double totalIncome = 0;
  double totalExpense = 0;
  double highestIncome = 0;
  double highestExpense = 0;
  double savingsRate = 0;

  double totalReceivable = 0;
  double totalPayable = 0;
  double netReceivable = 0;

  String highestIncomeDescription = '';
  String highestExpenseDescription = '';

  List<Map<String, dynamic>> incomes = [];
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> moneyRecords = [];
  List<Map<String, dynamic>> moneyPayments = [];

  List<Map<String, dynamic>> monthlyData = [];
  List<Map<String, dynamic>> weeklyData = [];
  List<Map<String, dynamic>> yearlyData = [];
  List<Map<String, dynamic>> categoryData = [];

  bool get isArabic => LanguageService.isArabic;

  String tr(String en, String bn, String hi, String ar) {
    return LanguageService.text(
      english: en,
      bangla: bn,
      hindi: hi,
      arabic: ar,
    );
  }

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  double toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool isDateInRange(
    DateTime date,
    DateTime start,
    DateTime end,
  ) {
    final d = dateOnly(date);
    return !d.isBefore(dateOnly(start)) &&
        !d.isAfter(dateOnly(end));
  }

  Future<void> loadStatistics() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final db = await AppDatabase.database;

      final loadedIncomes = await db.query(
        'incomes',
        orderBy: 'date DESC',
      );

      final loadedExpenses = await db.query(
        'expenses',
        orderBy: 'date DESC',
      );

      final loadedCategories = await db.query(
        'categories',
        orderBy: 'name ASC',
      );

      final loadedBudgets = await db.query(
        'budgets',
        orderBy: 'start_date DESC',
      );

      final loadedMoneyRecords =
          await db.query('money_records');

      final loadedMoneyPayments =
          await db.query('money_payments');

      double incomeTotal = 0;
      double expenseTotal = 0;
      double maxIncome = 0;
      double maxExpense = 0;

      String maxIncomeDesc = '';
      String maxExpenseDesc = '';

      for (final item in loadedIncomes) {
        final amount = toDouble(item['amount']);
        incomeTotal += amount;

        if (amount > maxIncome) {
          maxIncome = amount;
          maxIncomeDesc =
              item['description']?.toString() ?? '';
        }
      }

      for (final item in loadedExpenses) {
        final amount = toDouble(item['amount']);
        expenseTotal += amount;

        if (amount > maxExpense) {
          maxExpense = amount;
          maxExpenseDesc =
              item['description']?.toString() ?? '';
        }
      }

      double receivable = 0;
      double payable = 0;

      for (final record in loadedMoneyRecords) {
        final id = record['id'];

        final paid = loadedMoneyPayments
            .where(
              (p) =>
                  p['record_id'].toString() == id.toString(),
            )
            .fold<double>(
              0,
              (sum, p) => sum + toDouble(p['amount']),
            );

        final remaining =
            toDouble(record['amount']) - paid;

        if (remaining <= 0) continue;

        if (record['type'] == 'receivable') {
          receivable += remaining;
        } else if (record['type'] == 'payable') {
          payable += remaining;
        }
      }

      final rate = incomeTotal > 0
          ? ((incomeTotal - expenseTotal) / incomeTotal) * 100
          : 0.0;

      if (!mounted) return;

      setState(() {
        incomes = loadedIncomes;
        expenses = loadedExpenses;
        categories = loadedCategories;
        budgets = loadedBudgets;
        moneyRecords = loadedMoneyRecords;
        moneyPayments = loadedMoneyPayments;

        totalIncome = incomeTotal;
        totalExpense = expenseTotal;

        highestIncome = maxIncome;
        highestExpense = maxExpense;

        highestIncomeDescription = maxIncomeDesc;
        highestExpenseDescription = maxExpenseDesc;

        totalReceivable = receivable;
        totalPayable = payable;
        netReceivable = receivable - payable;

        savingsRate = rate;

        monthlyData = buildMonthlyData();
        weeklyData = buildWeeklyData();
        yearlyData = buildYearlyData();
        categoryData = buildCategoryData();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${tr('Statistics loading failed', 'পরিসংখ্যান লোড হয়নি', 'आंकड़े लोड नहीं हुए', 'فشل تحميل الإحصائيات')}: $e',
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> buildMonthlyData() {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    for (int month = 1; month <= 12; month++) {
      double income = 0;
      double expense = 0;

      for (final item in incomes) {
        final date = parseDate(item['date']);
        if (date != null &&
            date.year == now.year &&
            date.month == month) {
          income += toDouble(item['amount']);
        }
      }

      for (final item in expenses) {
        final date = parseDate(item['date']);
        if (date != null &&
            date.year == now.year &&
            date.month == month) {
          expense += toDouble(item['amount']);
        }
      }

      result.add({
        'month': month,
        'income': income,
        'expense': expense,
      });
    }

    return result;
  }

  List<Map<String, dynamic>> buildWeeklyData() {
    final today = dateOnly(DateTime.now());
    final result = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));

      double income = 0;
      double expense = 0;

      for (final item in incomes) {
        final date = parseDate(item['date']);
        if (date != null && isDateInRange(date, day, day)) {
          income += toDouble(item['amount']);
        }
      }

      for (final item in expenses) {
        final date = parseDate(item['date']);
        if (date != null && isDateInRange(date, day, day)) {
          expense += toDouble(item['amount']);
        }
      }

      result.add({
        'date': day,
        'income': income,
        'expense': expense,
      });
    }

    return result;
  }

  List<Map<String, dynamic>> buildYearlyData() {
    final currentYear = DateTime.now().year;
    final result = <Map<String, dynamic>>[];

    for (int year = currentYear - 4;
        year <= currentYear;
        year++) {
      double income = 0;
      double expense = 0;

      for (final item in incomes) {
        final date = parseDate(item['date']);
        if (date != null && date.year == year) {
          income += toDouble(item['amount']);
        }
      }

      for (final item in expenses) {
        final date = parseDate(item['date']);
        if (date != null && date.year == year) {
          expense += toDouble(item['amount']);
        }
      }

      result.add({
        'year': year,
        'income': income,
        'expense': expense,
      });
    }

    return result;
  }

  List<Map<String, dynamic>> buildCategoryData() {
    final totals = <String, double>{};

    for (final item in expenses) {
      final id = item['category_id']?.toString();
      if (id == null) continue;

      totals[id] =
          (totals[id] ?? 0) + toDouble(item['amount']);
    }

    final result = <Map<String, dynamic>>[];

    for (final category in categories) {
      if (category['type']?.toString() != 'expense') {
        continue;
      }

      final id = category['id'].toString();
      final amount = totals[id] ?? 0;

      if (amount > 0) {
        result.add({
          'name': category['name']?.toString() ?? 'Other',
          'amount': amount,
        });
      }
    }

    result.sort(
      (a, b) => (b['amount'] as double)
          .compareTo(a['amount'] as double),
    );

    return result;
  }

  String money(double amount) =>
      '৳${amount.toStringAsFixed(2)}';

  String monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return months[month - 1];
  }

  Widget summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget amountItem(
    String title,
    double amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            money(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget periodSummary(
    String title,
    String subtitle,
    double income,
    double expense,
  ) {
    final balance = income - expense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: amountItem(
                    tr('Income', 'আয়', 'आय', 'الدخل'),
                    income,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: amountItem(
                    tr('Expense', 'ব্যয়', 'व्यय', 'المصروفات'),
                    expense,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: amountItem(
                    tr('Balance', 'ব্যালেন্স', 'शेष', 'الرصيد'),
                    balance,
                    balance >= 0 ? Colors.blue : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget legend(Color color, String title) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(title),
      ],
    );
  }

  Widget _chartBar(
    double amount,
    double maxAmount,
    Color color,
    double width,
    double maxHeight,
  ) {
    final height = amount <= 0
        ? 2.0
        : (amount / maxAmount) * maxHeight;

    return Container(
      width: width,
      height: height.clamp(2.0, maxHeight),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget monthlyChart() {
    final currentMonth = DateTime.now().month;

    final data = monthlyData
        .where((item) => (item['month'] as int) <= currentMonth)
        .toList();

    double maxAmount = 1;

    for (final item in data) {
      maxAmount = [
        maxAmount,
        toDouble(item['income']),
        toDouble(item['expense']),
      ].reduce((a, b) => a > b ? a : b);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                'Monthly Income vs Expense',
                'মাসিক আয় ও ব্যয়',
                'मासिक आय और व्यय',
                'الدخل والمصروفات الشهرية',
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('Current year', 'চলতি বছর', 'वर्तमान वर्ष', 'السنة الحالية'),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                legend(
                  Colors.green,
                  tr('Income', 'আয়', 'आय', 'الدخل'),
                ),
                const SizedBox(width: 20),
                legend(
                  Colors.red,
                  tr('Expense', 'ব্যয়', 'व्यय', 'المصروفات'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];

                  return SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 135,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              _chartBar(
                                toDouble(item['income']),
                                maxAmount,
                                Colors.green,
                                13,
                                125,
                              ),
                              const SizedBox(width: 5),
                              _chartBar(
                                toDouble(item['expense']),
                                maxAmount,
                                Colors.red,
                                13,
                                125,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          monthName(item['month'] as int),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget weeklyChart() {
    double maxAmount = 1;

    for (final item in weeklyData) {
      maxAmount = [
        maxAmount,
        toDouble(item['income']),
        toDouble(item['expense']),
      ].reduce((a, b) => a > b ? a : b);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Last 7 Days', 'গত ৭ দিন', 'पिछले 7 दिन', 'آخر 7 أيام'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weeklyData.map((item) {
                  final date = item['date'] as DateTime;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 110,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              _chartBar(
                                toDouble(item['income']),
                                maxAmount,
                                Colors.green,
                                8,
                                105,
                              ),
                              const SizedBox(width: 3),
                              _chartBar(
                                toDouble(item['expense']),
                                maxAmount,
                                Colors.red,
                                8,
                                105,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('E').format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(
    String title,
    double amount,
    double maxAmount,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            title,
            style: const TextStyle(fontSize: 10),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: maxAmount > 0
                  ? (amount / maxAmount).clamp(0.0, 1.0)
                  : 0,
              minHeight: 9,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(
            money(amount),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget yearlyChart() {
    double maxAmount = 1;

    for (final item in yearlyData) {
      maxAmount = [
        maxAmount,
        toDouble(item['income']),
        toDouble(item['expense']),
      ].reduce((a, b) => a > b ? a : b);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                'Yearly Income vs Expense',
                'বার্ষিক আয় ও ব্যয়',
                'वार्षिक आय और व्यय',
                'الدخل والمصروفات السنوية',
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            ...yearlyData.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['year'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _bar(
                      tr('Income', 'আয়', 'आय', 'الدخل'),
                      toDouble(item['income']),
                      maxAmount,
                      Colors.green,
                    ),
                    const SizedBox(height: 6),
                    _bar(
                      tr('Expense', 'ব্যয়', 'व्यय', 'المصروفات'),
                      toDouble(item['expense']),
                      maxAmount,
                      Colors.red,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget categoryBreakdown() {
    if (categoryData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              tr(
                'No expense category data',
                'ব্যয়ের কোনো ক্যাটাগরির তথ্য নেই',
                'व्यय श्रेणी का कोई डेटा नहीं',
                'لا توجد بيانات لفئات المصروفات',
              ),
            ),
          ),
        ),
      );
    }

    final maxAmount = toDouble(categoryData.first['amount']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                'Expense by Category',
                'ক্যাটাগরি অনুযায়ী ব্যয়',
                'श्रेणी के अनुसार व्यय',
                'المصروفات حسب الفئة',
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryData.map((item) {
              final amount = toDouble(item['amount']);

              final percentage = totalExpense > 0
                  ? (amount / totalExpense) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item['name'].toString()),
                        ),
                        Text('${percentage.toStringAsFixed(1)}%'),
                        const SizedBox(width: 8),
                        Text(
                          money(amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: maxAmount > 0
                            ? amount / maxAmount
                            : 0,
                        minHeight: 9,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF1877F2),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget highestTransactionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                'Highest Transactions',
                'সর্বোচ্চ লেনদেন',
                'सबसे बड़े लेनदेन',
                'أعلى المعاملات',
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _highestItem(
                    tr('Highest Income', 'সর্বোচ্চ আয়',
                        'सबसे अधिक आय', 'أعلى دخل'),
                    highestIncome,
                    highestIncomeDescription,
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _highestItem(
                    tr('Highest Expense', 'সর্বোচ্চ ব্যয়',
                        'सबसे अधिक व्यय', 'أعلى مصروف'),
                    highestExpense,
                    highestExpenseDescription,
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _highestItem(
    String title,
    double amount,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              money(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget savingsAnalysis() {
    final balance = totalIncome - totalExpense;
    final progress = (savingsRate / 100).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Savings Analysis', 'সঞ্চয় বিশ্লেষণ',
                  'बचत विश्लेषण', 'تحليل المدخرات'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 95,
                        height: 95,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 9,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.teal,
                            ),
                            Text(
                              '${savingsRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('Savings Rate', 'সঞ্চয়ের হার',
                            'बचत दर', 'معدل الادخار'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Net Savings', 'নিট সঞ্চয়',
                            'शुद्ध बचत', 'صافي المدخرات'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        money(balance),
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.teal : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        tr('Total Income', 'মোট আয়',
                            'कुल आय', 'إجمالي الدخل'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        money(totalIncome),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Receivable and Payable summary
  Widget moneyRecordsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                'Receivable & Payable',
                'পাওনা ও দেনা',
                'प्राप्य और देय',
                'المبالغ المستحقة',
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: amountItem(
                    tr('Receivable', 'পাওনা', 'प्राप्य', 'مستحق لك'),
                    totalReceivable,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: amountItem(
                    tr('Payable', 'দেনা', 'देय', 'مستحق عليك'),
                    totalPayable,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: amountItem(
                    tr('Net Receivable', 'নিট পাওনা',
                        'शुद्ध प्राप्य', 'صافي المستحق لك'),
                    netReceivable,
                    netReceivable >= 0 ? Colors.blue : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Text(
              tr(
                'These amounts are separate from income and expense.',
                'এই হিসাব আয় ও ব্যয়ের হিসাব থেকে আলাদা রাখা হয়েছে।',
                'ये राशियां आय और व्यय से अलग रखी गई हैं।',
                'هذه المبالغ منفصلة عن الدخل والمصروفات.',
              ),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, DateTime>? getBudgetRange(
    Map<String, dynamic> budget,
  ) {
    final start = parseDate(budget['start_date']);
    if (start == null) return null;

    final period =
        budget['period']?.toString().toLowerCase() ?? 'monthly';

    if (period == 'custom') {
      final end = parseDate(budget['end_date']);
      if (end == null) return null;

      return {
        'start': dateOnly(start),
        'end': dateOnly(end),
      };
    }

    return {
      'start': DateTime(start.year, start.month, 1),
      'end': DateTime(start.year, start.month + 1, 0),
    };
  }

  double calculateBudgetActual(
    Map<String, dynamic> budget,
  ) {
    final range = getBudgetRange(budget);
    if (range == null) return 0;

    final type =
        budget['type']?.toString().toLowerCase() ?? 'expense';

    final categoryId = budget['category_id'];
    final source = type == 'income' ? incomes : expenses;

    double actual = 0;

    for (final item in source) {
      final date = parseDate(item['date']);
      if (date == null) continue;

      if (!isDateInRange(
        date,
        range['start']!,
        range['end']!,
      )) {
        continue;
      }

      if (categoryId != null &&
          item['category_id']?.toString() !=
              categoryId.toString()) {
        continue;
      }

      actual += toDouble(item['amount']);
    }

    return actual;
  }

  bool isCurrentBudget(Map<String, dynamic> budget) {
    final range = getBudgetRange(budget);
    if (range == null) return false;

    final currentDate = dateOnly(DateTime.now());

    return !currentDate.isBefore(range['start']!) &&
        !currentDate.isAfter(range['end']!);
  }

  String budgetCategoryName(Map<String, dynamic> budget) {
    final id = budget['category_id'];
    if (id == null) {
      return tr('All Categories', 'সব ক্যাটাগরি',
          'सभी श्रेणियां', 'جميع الفئات');
    }

    for (final category in categories) {
      if (category['id'].toString() == id.toString()) {
        return category['name'].toString();
      }
    }

    return tr('All Categories', 'সব ক্যাটাগরি',
        'सभी श्रेणियां', 'جميع الفئات');
  }

  Widget budgetVsActual() {
    if (budgets.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              tr('No budget plans found.',
                  'কোনো বাজেট পরিকল্পনা নেই।',
                  'कोई बजट योजना नहीं मिली।',
                  'لم يتم العثور على خطط ميزانية.'),
            ),
          ),
        ),
      );
    }

    final currentBudgets =
        budgets.where(isCurrentBudget).toList();

    if (currentBudgets.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              tr('No active budget plans.',
                  'কোনো সক্রিয় বাজেট নেই।',
                  'कोई सक्रिय बजट योजना नहीं है।',
                  'لا توجد خطط ميزانية نشطة.'),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Budget vs Actual', 'বাজেট বনাম প্রকৃত ব্যয়',
                  'बजट बनाम वास्तविक', 'الميزانية مقابل الفعلي'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              tr('Current active budgets', 'বর্তমান সক্রিয় বাজেট',
                  'वर्तमान सक्रिय बजट', 'الميزانيات النشطة الحالية'),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ...currentBudgets.map((budget) {
              final planned = toDouble(budget['amount']);
              final actual = calculateBudgetActual(budget);
              final percentage =
                  planned > 0 ? actual / planned : 0.0;

              final exceeded = actual > planned;
              final isIncome = budget['type'] == 'income';
              final color = isIncome ? Colors.green : Colors.red;
              final difference = planned - actual;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isIncome
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 19,
                          color: color,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            budget['title']?.toString() ?? 'Budget',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          isIncome ? 'INCOME' : 'EXPENSE',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${budget['period']?.toString().toUpperCase()} • '
                      '${budgetCategoryName(budget)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: amountItem(
                            tr('Planned', 'পরিকল্পিত',
                                'नियोजित', 'المخطط'),
                            planned,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: amountItem(
                            tr('Actual', 'প্রকৃত',
                                'वास्तविक', 'الفعلي'),
                            actual,
                            color,
                          ),
                        ),
                        Expanded(
                          child: amountItem(
                            exceeded
                                ? tr('Exceeded', 'অতিরিক্ত',
                                    'अधिक', 'تجاوز')
                                : tr('Remaining', 'অবশিষ্ট',
                                    'शेष', 'المتبقي'),
                            exceeded ? actual - planned : difference,
                            exceeded ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        minHeight: 9,
                        backgroundColor: Colors.grey.shade200,
                        color: exceeded ? Colors.red : color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      exceeded
                          ? '${tr('Exceeded by', 'অতিরিক্ত হয়েছে',
                              'से अधिक', 'تجاوز بمقدار')} ${money(actual - planned)}'
                          : '${(percentage * 100).toStringAsFixed(1)}% • '
                              '${tr('Remaining', 'অবশিষ্ট',
                                  'शेष', 'المتبقي')} ${money(difference)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: exceeded ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildPeriodSummaries() {
    final now = DateTime.now();

    double dailyIncome = 0;
    double dailyExpense = 0;

    for (final item in incomes) {
      final date = parseDate(item['date']);
      if (date != null && isDateInRange(date, now, now)) {
        dailyIncome += toDouble(item['amount']);
      }
    }

    for (final item in expenses) {
      final date = parseDate(item['date']);
      if (date != null && isDateInRange(date, now, now)) {
        dailyExpense += toDouble(item['amount']);
      }
    }

    double weeklyIncome = 0;
    double weeklyExpense = 0;

    for (final item in weeklyData) {
      weeklyIncome += toDouble(item['income']);
      weeklyExpense += toDouble(item['expense']);
    }

    double monthlyIncome = 0;
    double monthlyExpense = 0;

    for (final item in monthlyData) {
      if (item['month'] == now.month) {
        monthlyIncome = toDouble(item['income']);
        monthlyExpense = toDouble(item['expense']);
      }
    }

    double yearlyIncome = 0;
    double yearlyExpense = 0;

    for (final item in yearlyData) {
      if (item['year'] == now.year) {
        yearlyIncome = toDouble(item['income']);
        yearlyExpense = toDouble(item['expense']);
      }
    }

    return Column(
      children: [
        periodSummary(
          tr('Daily Statistics', 'দৈনিক পরিসংখ্যান',
              'दैनिक आंकड़े', 'الإحصائيات اليومية'),
          DateFormat('dd MMM yyyy').format(now),
          dailyIncome,
          dailyExpense,
        ),
        const SizedBox(height: 14),
        periodSummary(
          tr('Weekly Statistics', 'সাপ্তাহিক পরিসংখ্যান',
              'साप्ताहिक आंकड़े', 'الإحصائيات الأسبوعية'),
          tr('Last 7 days', 'গত ৭ দিন',
              'पिछले 7 दिन', 'آخر 7 أيام'),
          weeklyIncome,
          weeklyExpense,
        ),
        const SizedBox(height: 14),
        periodSummary(
          tr('Monthly Statistics', 'মাসিক পরিসংখ্যান',
              'मासिक आंकड़े', 'الإحصائيات الشهرية'),
          DateFormat('MMMM yyyy').format(now),
          monthlyIncome,
          monthlyExpense,
        ),
        const SizedBox(height: 14),
        periodSummary(
          tr('Yearly Statistics', 'বার্ষিক পরিসংখ্যান',
              'वार्षिक आंकड़े', 'الإحصائيات السنوية'),
          now.year.toString(),
          yearlyIncome,
          yearlyExpense,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = totalIncome - totalExpense;

    return Directionality(
      textDirection:
          isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            tr('Statistics', 'পরিসংখ্যান',
                'आंकड़े', 'الإحصائيات'),
          ),
          actions: [
            IconButton(
              onPressed: isLoading ? null : loadStatistics,
              icon: const Icon(Icons.refresh),
              tooltip: tr('Refresh', 'রিফ্রেশ',
                  'रीफ्रेश', 'تحديث'),
            ),
          ],
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: loadStatistics,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        summaryCard(
                          tr('Total Income', 'মোট আয়',
                              'कुल आय', 'إجمالي الدخل'),
                          money(totalIncome),
                          Icons.trending_up,
                          Colors.green,
                        ),
                        summaryCard(
                          tr('Total Expense', 'মোট ব্যয়',
                              'कुल व्यय', 'إجمالي المصروفات'),
                          money(totalExpense),
                          Icons.trending_down,
                          Colors.red,
                        ),
                        summaryCard(
                          tr('Balance', 'বর্তমান ব্যালেন্স',
                              'शेष राशि', 'الرصيد'),
                          money(balance),
                          Icons.account_balance_wallet,
                          balance >= 0 ? Colors.blue : Colors.red,
                        ),
                        summaryCard(
                          tr('Savings Rate', 'সঞ্চয়ের হার',
                              'बचत दर', 'معدل الادخار'),
                          '${savingsRate.toStringAsFixed(1)}%',
                          Icons.savings,
                          Colors.teal,
                        ),
                        summaryCard(
                          tr('Receivable', 'মোট পাওনা',
                              'कुल प्राप्य', 'إجمالي المستحق لك'),
                          money(totalReceivable),
                          Icons.call_received,
                          Colors.green,
                        ),
                        summaryCard(
                          tr('Payable', 'মোট দেনা',
                              'कुल देय', 'إجمالي المستحق عليك'),
                          money(totalPayable),
                          Icons.call_made,
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    moneyRecordsSummary(),
                    const SizedBox(height: 20),
                    buildPeriodSummaries(),
                    const SizedBox(height: 20),
                    monthlyChart(),
                    const SizedBox(height: 20),
                    weeklyChart(),
                    const SizedBox(height: 20),
                    yearlyChart(),
                    const SizedBox(height: 20),
                    categoryBreakdown(),
                    const SizedBox(height: 20),
                    highestTransactionCard(),
                    const SizedBox(height: 20),
                    savingsAnalysis(),
                    const SizedBox(height: 20),
                    budgetVsActual(),
                    const SizedBox(height: 25),
                    Center(
                      child: Text(
                        'LifeMate Statistics',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
      ),
    );
  }
}
