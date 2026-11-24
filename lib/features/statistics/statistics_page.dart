import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';

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

  String highestIncomeDescription = '';
  String highestExpenseDescription = '';

  double savingsRate = 0;

  List<Map<String, dynamic>> incomes = [];
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> budgets = [];

  List<Map<String, dynamic>> monthlyData = [];
  List<Map<String, dynamic>> weeklyData = [];
  List<Map<String, dynamic>> dailyData = [];
  List<Map<String, dynamic>> yearlyData = [];
  List<Map<String, dynamic>> categoryData = [];

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> loadStatistics() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

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

      double incomeTotal = 0;
      double expenseTotal = 0;

      double maxIncome = 0;
      double maxExpense = 0;

      String maxIncomeDescription = '';
      String maxExpenseDescription = '';

      for (final item in loadedIncomes) {
        final amount =
            (item['amount'] as num?)?.toDouble() ?? 0;

        incomeTotal += amount;

        if (amount > maxIncome) {
          maxIncome = amount;
          maxIncomeDescription =
              item['description']?.toString() ?? '';
        }
      }

      for (final item in loadedExpenses) {
        final amount =
            (item['amount'] as num?)?.toDouble() ?? 0;

        expenseTotal += amount;

        if (amount > maxExpense) {
          maxExpense = amount;
          maxExpenseDescription =
              item['description']?.toString() ?? '';
        }
      }

      final rate = incomeTotal > 0
          ? ((incomeTotal - expenseTotal) / incomeTotal) * 100
          : 0.0;

      final monthly = buildMonthlyData(
        loadedIncomes,
        loadedExpenses,
      );

      final weekly = buildWeeklyData(
        loadedIncomes,
        loadedExpenses,
      );

      final daily = buildDailyData(
        loadedIncomes,
        loadedExpenses,
      );

      final yearly = buildYearlyData(
        loadedIncomes,
        loadedExpenses,
      );

      final category = buildCategoryData(
        loadedExpenses,
        loadedCategories,
      );

      if (!mounted) return;

      setState(() {
        incomes = loadedIncomes;
        expenses = loadedExpenses;
        categories = loadedCategories;
        budgets = loadedBudgets;

        totalIncome = incomeTotal;
        totalExpense = expenseTotal;

        highestIncome = maxIncome;
        highestExpense = maxExpense;

        highestIncomeDescription = maxIncomeDescription;
        highestExpenseDescription = maxExpenseDescription;

        savingsRate = rate;

        monthlyData = monthly;
        weeklyData = weekly;
        dailyData = daily;
        yearlyData = yearly;
        categoryData = category;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Statistics loading failed: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(
      value.toString(),
    );
  }

  DateTime dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool isDateInRange(
    DateTime date,
    DateTime start,
    DateTime end,
  ) {
    final d = dateOnly(date);
    final s = dateOnly(start);
    final e = dateOnly(end);

    return !d.isBefore(s) && !d.isAfter(e);
  }

  // ============================================================
  // MONTHLY DATA
  // ============================================================

  List<Map<String, dynamic>> buildMonthlyData(
    List<Map<String, dynamic>> incomeList,
    List<Map<String, dynamic>> expenseList,
  ) {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    for (int month = 1; month <= 12; month++) {
      double income = 0;
      double expense = 0;

      for (final item in incomeList) {
        final date = parseDate(item['date']);

        if (date != null &&
            date.year == now.year &&
            date.month == month) {
          income +=
              (item['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      for (final item in expenseList) {
        final date = parseDate(item['date']);

        if (date != null &&
            date.year == now.year &&
            date.month == month) {
          expense +=
              (item['amount'] as num?)?.toDouble() ?? 0;
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

  // ============================================================
  // WEEKLY DATA
  // ============================================================

  List<Map<String, dynamic>> buildWeeklyData(
    List<Map<String, dynamic>> incomeList,
    List<Map<String, dynamic>> expenseList,
  ) {
    final today = dateOnly(DateTime.now());

    final result = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(
        Duration(days: i),
      );

      double income = 0;
      double expense = 0;

      for (final item in incomeList) {
        final date = parseDate(item['date']);

        if (date != null &&
            isDateInRange(date, day, day)) {
          income +=
              (item['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      for (final item in expenseList) {
        final date = parseDate(item['date']);

        if (date != null &&
            isDateInRange(date, day, day)) {
          expense +=
              (item['amount'] as num?)?.toDouble() ?? 0;
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

  // ============================================================
  // DAILY DATA
  // ============================================================

  List<Map<String, dynamic>> buildDailyData(
    List<Map<String, dynamic>> incomeList,
    List<Map<String, dynamic>> expenseList,
  ) {
    final today = dateOnly(DateTime.now());

    double income = 0;
    double expense = 0;

    for (final item in incomeList) {
      final date = parseDate(item['date']);

      if (date != null &&
          isDateInRange(date, today, today)) {
        income +=
            (item['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    for (final item in expenseList) {
      final date = parseDate(item['date']);

      if (date != null &&
          isDateInRange(date, today, today)) {
        expense +=
            (item['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    final result = <Map<String, dynamic>>[];

    for (int hour = 0; hour < 24; hour++) {
      result.add({
        'hour': hour,
        'income': 0.0,
        'expense': 0.0,
      });
    }

    // Keep daily total information in hour 0 when
    // transaction date does not contain a useful time.
    result[0]['income'] = income;
    result[0]['expense'] = expense;

    return result;
  }

  // ============================================================
  // YEARLY DATA
  // ============================================================

  List<Map<String, dynamic>> buildYearlyData(
    List<Map<String, dynamic>> incomeList,
    List<Map<String, dynamic>> expenseList,
  ) {
    final currentYear = DateTime.now().year;

    final result = <Map<String, dynamic>>[];

    for (int year = currentYear - 4;
        year <= currentYear;
        year++) {
      double income = 0;
      double expense = 0;

      for (final item in incomeList) {
        final date = parseDate(item['date']);

        if (date != null && date.year == year) {
          income +=
              (item['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      for (final item in expenseList) {
        final date = parseDate(item['date']);

        if (date != null && date.year == year) {
          expense +=
              (item['amount'] as num?)?.toDouble() ?? 0;
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

  // ============================================================
  // CATEGORY DATA
  // ============================================================

  List<Map<String, dynamic>> buildCategoryData(
    List<Map<String, dynamic>> expenseList,
    List<Map<String, dynamic>> categoryList,
  ) {
    final categoryTotals = <int, double>{};

    for (final item in expenseList) {
      final categoryId = item['category_id'];

      if (categoryId != null) {
        final id = categoryId is int
            ? categoryId
            : int.tryParse(
                categoryId.toString(),
              );

        if (id != null) {
          categoryTotals[id] =
              (categoryTotals[id] ?? 0) +
                  ((item['amount'] as num?)?.toDouble() ?? 0);
        }
      }
    }

    final result = <Map<String, dynamic>>[];

    for (final category in categoryList) {
      if (category['type'] != 'expense') {
        continue;
      }

      final id = category['id'] as int;
      final amount = categoryTotals[id] ?? 0;

      if (amount > 0) {
        result.add({
          'name':
              category['name']?.toString() ?? 'Other',
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

  // ============================================================
  // MONEY
  // ============================================================

  String money(double amount) {
    return '৳${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
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
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
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

  // ============================================================
  // PERIOD SUMMARY
  // ============================================================

  Widget periodSummaryCard({
    required String title,
    required double income,
    required double expense,
    required String subtitle,
  }) {
    final balance = income - expense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
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
                  child: _smallAmount(
                    'Income',
                    income,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _smallAmount(
                    'Expense',
                    expense,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _smallAmount(
                    'Balance',
                    balance,
                    balance >= 0
                        ? Colors.blue
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallAmount(
    String title,
    double amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
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
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
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

  // ============================================================
  // MONTHLY CHART
  // ============================================================

  Widget monthlyChart() {
    final currentMonth = DateTime.now().month;

    final visibleData = monthlyData
        .where(
          (item) =>
              (item['month'] as int) <= currentMonth,
        )
        .toList();

    double maxAmount = 0;

    for (final item in visibleData) {
      final income = item['income'] as double;
      final expense = item['expense'] as double;

      if (income > maxAmount) {
        maxAmount = income;
      }

      if (expense > maxAmount) {
        maxAmount = expense;
      }
    }

    if (maxAmount == 0) {
      maxAmount = 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Income vs Expense',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Current year',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _legend(
                  Colors.green,
                  'Income',
                ),
                const SizedBox(width: 20),
                _legend(
                  Colors.red,
                  'Expense',
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection:
                    Axis.horizontal,
                itemCount: visibleData.length,
                itemBuilder: (context, index) {
                  final item =
                      visibleData[index];

                  final income =
                      item['income'] as double;

                  final expense =
                      item['expense'] as double;

                  final incomeHeight =
                      (income / maxAmount) * 125;

                  final expenseHeight =
                      (expense / maxAmount) * 125;

                  return SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 135,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 13,
                                height:
                                    incomeHeight < 2
                                        ? 2
                                        : incomeHeight,
                                decoration:
                                    BoxDecoration(
                                  color: Colors.green,
                                  borderRadius:
                                      BorderRadius
                                          .circular(4),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 13,
                                height:
                                    expenseHeight < 2
                                        ? 2
                                        : expenseHeight,
                                decoration:
                                    BoxDecoration(
                                  color: Colors.red,
                                  borderRadius:
                                      BorderRadius
                                          .circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          monthName(
                            item['month'] as int,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 11,
                          ),
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

  String monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  Widget _legend(
    Color color,
    String title,
  ) {
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

  // ============================================================
  // WEEKLY CHART
  // ============================================================

  Widget weeklyChart() {
    double maxAmount = 0;

    for (final item in weeklyData) {
      final income = item['income'] as double;
      final expense = item['expense'] as double;

      if (income > maxAmount) {
        maxAmount = income;
      }

      if (expense > maxAmount) {
        maxAmount = expense;
      }
    }

    if (maxAmount == 0) {
      maxAmount = 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 7 Days',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: weeklyData.map((item) {
                  final date =
                      item['date'] as DateTime;

                  final income =
                      item['income'] as double;

                  final expense =
                      item['expense'] as double;

                  final incomeHeight =
                      (income / maxAmount) * 105;

                  final expenseHeight =
                      (expense / maxAmount) * 105;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 110,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 8,
                                height:
                                    incomeHeight < 2
                                        ? 2
                                        : incomeHeight,
                                decoration:
                                    BoxDecoration(
                                  color: Colors.green,
                                  borderRadius:
                                      BorderRadius
                                          .circular(3),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Container(
                                width: 8,
                                height:
                                    expenseHeight < 2
                                        ? 2
                                        : expenseHeight,
                                decoration:
                                    BoxDecoration(
                                  color: Colors.red,
                                  borderRadius:
                                      BorderRadius
                                          .circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('E')
                              .format(date),
                          style:
                              const TextStyle(
                            fontSize: 10,
                          ),
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

  // ============================================================
  // YEARLY CHART
  // ============================================================

  Widget yearlyChart() {
    double maxAmount = 0;

    for (final item in yearlyData) {
      final income = item['income'] as double;
      final expense = item['expense'] as double;

      if (income > maxAmount) {
        maxAmount = income;
      }

      if (expense > maxAmount) {
        maxAmount = expense;
      }
    }

    if (maxAmount == 0) {
      maxAmount = 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Yearly Income vs Expense',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            ...yearlyData.map((item) {
              final year = item['year'] as int;
              final income =
                  item['income'] as double;
              final expense =
                  item['expense'] as double;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 18,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      year.toString(),
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _bar(
                      'Income',
                      income,
                      maxAmount,
                      Colors.green,
                    ),
                    const SizedBox(height: 6),
                    _bar(
                      'Expense',
                      expense,
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

  Widget _bar(
    String title,
    double amount,
    double maxAmount,
    Color color,
  ) {
    final value =
        maxAmount == 0 ? 0.0 : amount / maxAmount;

    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 9,
              backgroundColor:
                  Colors.grey.shade200,
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

  // ============================================================
  // CATEGORY BREAKDOWN
  // ============================================================

  Widget categoryBreakdown() {
    if (categoryData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No expense category data',
            ),
          ),
        ),
      );
    }

    final maxAmount =
        categoryData.first['amount'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense by Category',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryData.map((item) {
              final amount =
                  item['amount'] as double;

              final percentage =
                  totalExpense > 0
                      ? (amount / totalExpense) * 100
                      : 0.0;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] as String,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style:
                              const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          money(amount),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10),
                      child:
                          LinearProgressIndicator(
                        value:
                            maxAmount > 0
                                ? amount / maxAmount
                                : 0,
                        minHeight: 9,
                        backgroundColor:
                            Colors.grey.shade200,
                        color:
                            const Color(0xFF1877F2),
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

  // ============================================================
  // HIGHEST TRANSACTIONS
  // ============================================================

  Widget highestTransactionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Highest Transactions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _highestItem(
                    'Highest Income',
                    highestIncome,
                    highestIncomeDescription,
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _highestItem(
                    'Highest Expense',
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
        borderRadius:
            BorderRadius.circular(12),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
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
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
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
              style: const TextStyle(
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SAVINGS ANALYSIS
  // ============================================================

  Widget savingsAnalysis() {
    final balance =
        totalIncome - totalExpense;

    final rateText =
        '${savingsRate.toStringAsFixed(1)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Savings Analysis',
              style: TextStyle(
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
                          alignment:
                              Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value:
                                  (savingsRate.clamp(
                                    0,
                                    100,
                                  )) /
                                  100,
                              strokeWidth: 9,
                              backgroundColor:
                                  Colors.grey.shade200,
                              color: Colors.teal,
                            ),
                            Text(
                              rateText,
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Savings Rate',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Savings',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        money(
                          balance > 0
                              ? balance
                              : 0,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Total Income',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        money(totalIncome),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
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

  // ============================================================
  // BUDGET DATE RANGE
  // ============================================================

  Map<String, DateTime>? getBudgetRange(
    Map<String, dynamic> budget,
  ) {
    final start = parseDate(
      budget['start_date'],
    );

    if (start == null) return null;

    final period =
        budget['period']?.toString() ?? 'Monthly';

    final startDay = dateOnly(start);

    if (period == 'Custom') {
      final end = parseDate(
        budget['end_date'],
      );

      if (end == null) return null;

      return {
        'start': startDay,
        'end': dateOnly(end),
      };
    }

    // Monthly budget = the complete month
    final monthStart = DateTime(
      start.year,
      start.month,
      1,
    );

    final monthEnd = DateTime(
      start.year,
      start.month + 1,
      0,
    );

    return {
      'start': monthStart,
      'end': monthEnd,
    };
  }

  // ============================================================
  // BUDGET ACTUAL
  // ============================================================

  double calculateBudgetActual(
    Map<String, dynamic> budget,
  ) {
    final range = getBudgetRange(budget);

    if (range == null) return 0;

    final start = range['start']!;
    final end = range['end']!;

    final type =
        budget['type']?.toString() ?? 'expense';

    final categoryId = budget['category_id'];

    final source =
        type == 'income' ? incomes : expenses;

    double actual = 0;

    for (final item in source) {
      final date = parseDate(item['date']);

      if (date == null) continue;

      if (!isDateInRange(
        date,
        start,
        end,
      )) {
        continue;
      }

      if (categoryId != null) {
        final transactionCategoryId =
            item['category_id'];

        if (transactionCategoryId == null ||
            transactionCategoryId.toString() !=
                categoryId.toString()) {
          continue;
        }
      }

      actual +=
          (item['amount'] as num?)?.toDouble() ?? 0;
    }

    return actual;
  }

  // ============================================================
  // ACTIVE / CURRENT BUDGETS
  // ============================================================

  bool isCurrentBudget(
    Map<String, dynamic> budget,
  ) {
    final range = getBudgetRange(budget);

    if (range == null) return false;

    final today = dateOnly(DateTime.now());

    final start = range['start']!;
    final end = range['end']!;

    return !today.isBefore(start) &&
        !today.isAfter(end);
  }

  String budgetTypeName(
    Map<String, dynamic> budget,
  ) {
    return budget['type'] == 'income'
        ? 'Income'
        : 'Expense';
  }

  String budgetCategoryName(
    Map<String, dynamic> budget,
  ) {
    final categoryId = budget['category_id'];

    if (categoryId == null) {
      return 'All Categories';
    }

    for (final category in categories) {
      if (category['id'].toString() ==
          categoryId.toString()) {
        return category['name'].toString();
      }
    }

    return 'All Categories';
  }

  // ============================================================
  // BUDGET VS ACTUAL
  // ============================================================

  Widget budgetVsActual() {
    if (budgets.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: Colors.grey,
              ),
              const SizedBox(height: 10),
              const Text(
                'No budget plans found.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Create an income or expense budget '
                'to compare planned and actual amounts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentBudgets = budgets
        .where(isCurrentBudget)
        .toList();

    if (currentBudgets.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 40,
                color: Colors.grey,
              ),
              const SizedBox(height: 10),
              const Text(
                'No active budget plans.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'There are no budgets active today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget vs Actual',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Current active budgets',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            ...currentBudgets.map(
              (budget) {
                final planned =
                    (budget['amount'] as num?)
                            ?.toDouble() ??
                        0;

                final actual =
                    calculateBudgetActual(
                  budget,
                );

                final percentage =
                    planned > 0
                        ? actual / planned
                        : 0.0;

                final exceeded =
                    actual > planned;

                final isIncome =
                    budget['type'] == 'income';

                final difference =
                    planned - actual;

                final accentColor = isIncome
                    ? Colors.green
                    : Colors.red;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isIncome
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 19,
                            color: accentColor,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              budget['title']
                                      ?.toString() ??
                                  'Budget',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius
                                      .circular(10),
                              color: accentColor
                                  .withOpacity(0.10),
                            ),
                            child: Text(
                              budgetTypeName(
                                budget,
                              ),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      Text(
                        '${budget['period']} • '
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
                            child: _budgetAmount(
                              'Planned',
                              planned,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _budgetAmount(
                              'Actual',
                              actual,
                              accentColor,
                            ),
                          ),
                          Expanded(
                            child: _budgetAmount(
                              exceeded
                                  ? 'Exceeded'
                                  : 'Remaining',
                              exceeded
                                  ? actual - planned
                                  : difference,
                              exceeded
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 9),

                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                        child:
                            LinearProgressIndicator(
                          value: percentage > 1
                              ? 1
                              : percentage,
                          minHeight: 9,
                          backgroundColor:
                              Colors.grey.shade200,
                          color: exceeded
                              ? Colors.red
                              : accentColor,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        exceeded
                            ? 'Budget exceeded by '
                                '${money(actual - planned)}'
                            : '${(percentage * 100).toStringAsFixed(1)}% used • '
                                'Remaining ${money(difference)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: exceeded
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetAmount(
    String title,
    double amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            money(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DAILY SUMMARY
  // ============================================================

  Widget dailySummary() {
    final today = DateTime.now();

    double income = 0;
    double expense = 0;

    for (final item in dailyData) {
      income += item['income'] as double;
      expense += item['expense'] as double;
    }

    return periodSummaryCard(
      title: 'Daily Statistics',
      subtitle:
          DateFormat('dd MMM yyyy').format(today),
      income: income,
      expense: expense,
    );
  }

  // ============================================================
  // WEEKLY SUMMARY
  // ============================================================

  Widget weeklySummary() {
    double income = 0;
    double expense = 0;

    for (final item in weeklyData) {
      income += item['income'] as double;
      expense += item['expense'] as double;
    }

    return periodSummaryCard(
      title: 'Weekly Statistics',
      subtitle: 'Last 7 days',
      income: income,
      expense: expense,
    );
  }

  // ============================================================
  // MONTHLY SUMMARY
  // ============================================================

  Widget monthlySummary() {
    final now = DateTime.now();

    double income = 0;
    double expense = 0;

    for (final item in monthlyData) {
      if (item['month'] == now.month) {
        income = item['income'] as double;
        expense = item['expense'] as double;
        break;
      }
    }

    return periodSummaryCard(
      title: 'Monthly Statistics',
      subtitle:
          DateFormat('MMMM yyyy').format(now),
      income: income,
      expense: expense,
    );
  }

  // ============================================================
  // YEARLY SUMMARY
  // ============================================================

  Widget yearlySummary() {
    final currentYear = DateTime.now().year;

    double income = 0;
    double expense = 0;

    for (final item in yearlyData) {
      if (item['year'] == currentYear) {
        income = item['income'] as double;
        expense = item['expense'] as double;
        break;
      }
    }

    return periodSummaryCard(
      title: 'Yearly Statistics',
      subtitle: currentYear.toString(),
      income: income,
      expense: expense,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final balance =
        totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            onPressed: isLoading
                ? null
                : loadStatistics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
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
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      summaryCard(
                        'Total Income',
                        money(totalIncome),
                        Icons.trending_up,
                        Colors.green,
                      ),
                      summaryCard(
                        'Total Expense',
                        money(totalExpense),
                        Icons.trending_down,
                        Colors.red,
                      ),
                      summaryCard(
                        'Balance',
                        money(balance),
                        Icons.account_balance_wallet,
                        balance >= 0
                            ? Colors.blue
                            : Colors.red,
                      ),
                      summaryCard(
                        'Savings Rate',
                        '${savingsRate.toStringAsFixed(1)}%',
                        Icons.savings,
                        Colors.teal,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  dailySummary(),

                  const SizedBox(height: 14),

                  weeklySummary(),

                  const SizedBox(height: 14),

                  monthlySummary(),

                  const SizedBox(height: 14),

                  yearlySummary(),

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

                  const Center(
                    child: Text(
                      'LifeMate Statistics',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }
}
