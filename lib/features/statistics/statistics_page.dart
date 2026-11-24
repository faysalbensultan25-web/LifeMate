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
          ? ((incomeTotal - expenseTotal) / incomeTotal) *
              100
          : 0;

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

        highestIncomeDescription =
            maxIncomeDescription;

        highestExpenseDescription =
            maxExpenseDescription;

        savingsRate = rate.toDouble();

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
        final date = DateTime.tryParse(
          item['date']?.toString() ?? '',
        );

        if (date != null &&
            date.year == now.year &&
            date.month == month) {
          income +=
              (item['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      for (final item in expenseList) {
        final date = DateTime.tryParse(
          item['date']?.toString() ?? '',
        );

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
  // WEEKLY DATA - CURRENT 7 DAYS
  // ============================================================

  List<Map<String, dynamic>> buildWeeklyData(
    List<Map<String, dynamic>> incomeList,
    List<Map<String, dynamic>> expenseList,
  ) {
    final today = DateTime.now();

    final result = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));

      double income = 0;
      double expense = 0;

      for (final item in incomeList) {
        final date = DateTime.tryParse(
          item['date']?.toString() ?? '',
        );

        if (date != null &&
            date.year == day.year &&
            date.month == day.month &&
            date.day == day.day) {
          income +=
              (item['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      for (final item in expenseList) {
        final date = DateTime.tryParse(
          item['date']?.toString() ?? '',
        );

        if (date != null &&
            date.year == day.year &&
            date.month == day.month &&
            date.day == day.day) {
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
  // DAILY DATA - TODAY
  // ============================================================

  List<Map<String, dynamic>> buildDailyData(
    List<Map<String, dynamic>> incomeList,
    List<Map<String, dynamic>> expenseList,
  ) {
    final today = DateTime.now();

    final result = <Map<String, dynamic>>[];

    for (int hour = 0; hour < 24; hour++) {
      double income = 0;
      double expense = 0;

      for (final item in incomeList) {
        final date = DateTime.tryParse(
          item['date']?.toString() ?? '',
        );

        if (date != null &&
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day &&
            date.hour == hour) {
          income +=
              (item['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      for (final item in expenseList) {
        final date = DateTime.tryParse(
          item['date']?.toString() ?? '',
        );

        if (date != null &&
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day &&
            date.hour == hour) {
          expense +=
              (item['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      result.add({
        'hour': hour,
        'income': income,
        'expense': expense,
      });
    }

    return result;
  }

  // ============================================================
  // YEARLY DATA - LAST 5 YEARS
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
        final date = DateTime.tryParse(
          item['date']?.toString() ?? '',
        );

        if (date != null && date.year == year) {
          income +=
              (item['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      for (final item in expenseList) {
        final date = DateTime.tryParse(
          item['date']?.toString() ?? '',
        );

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
            : int.tryParse(categoryId.toString());

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
  // PERIOD CARD
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
                      ? (amount / totalExpense) *
                          100
                      : 0;

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
                            item['name']
                                as String,
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
                          BorderRadius.circular(
                        10,
                      ),
                      child:
                          LinearProgressIndicator(
                        value:
                            amount / maxAmount,
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
  // HIGHEST INCOME / EXPENSE
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
        color: color.withValues(alpha: 0.08),
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
    final balance = totalIncome - totalExpense;

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
              ),
              const SizedBox(height: 4),
              Text(
                'Create a budget to compare planned '
                'and actual expenses.',
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

    final now = DateTime.now();

    final currentBudgets = budgets.where((budget) {
      final start = DateTime.tryParse(
        budget['start_date']?.toString() ?? '',
      );

      final endText =
          budget['end_date']?.toString();

      final end = endText != null &&
              endText.isNotEmpty
          ? DateTime.tryParse(endText)
          : null;

      if (start == null) {
        return false;
      }

      if (start.isAfter(now)) {
        return false;
      }

      if (end != null && end.isBefore(now)) {
        return false;
      }

      return true;
    }).toList();

    if (currentBudgets.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'No active budget plans.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'There are no budgets active today.',
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
            const SizedBox(height: 16),
            ...currentBudgets.map(
              (budget) {
                final planned =
                    (budget['amount'] as num?)
                            ?.toDouble() ??
                        0;

                final period =
                    budget['period']
                        ?.toString() ??
                    'Monthly';

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

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 18,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                          Text(
                            period,
                            style:
                                const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Text(
                            'Actual: ${money(actual)}',
                            style: TextStyle(
                              color: exceeded
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight:
                                  FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Budget: ${money(planned)}',
                            style:
                                const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                        child:
                            LinearProgressIndicator(
                          value:
                              percentage > 1
                                  ? 1
                                  : percentage,
                          minHeight: 9,
                          backgroundColor:
                              Colors.grey.shade200,
                          color: exceeded
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        exceeded
                            ? 'Budget exceeded by ${money(actual - planned)}'
                            : 'Remaining: ${money(planned - actual)}',
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

  // ============================================================
  // CALCULATE BUDGET ACTUAL
  // ============================================================

  double calculateBudgetActual(
    Map<String, dynamic> budget,
  ) {
    final now = DateTime.now();

    final amount =
        (budget['amount'] as num?)?.toDouble() ?? 0;

    final period =
        budget['period']?.toString() ?? 'Monthly';

    final startText =
        budget['start_date']?.toString();

    final start = startText != null
        ? DateTime.tryParse(startText)
        : null;

    if (start == null) {
      return 0;
    }

    DateTime rangeStart;
    DateTime rangeEnd;

    if (period == 'Weekly') {
      final difference =
          now.difference(start).inDays;

      final weeks = difference >= 0
          ? difference ~/ 7
          : 0;

      rangeStart =
          start.add(Duration(days: weeks * 7));

      rangeEnd =
          rangeStart.add(const Duration(days: 7));
    } else if (period == 'Yearly') {
      rangeStart = DateTime(
        now.year,
        start.month,
        start.day,
      );

      if (rangeStart.isAfter(now)) {
        rangeStart = DateTime(
          now.year - 1,
          start.month,
          start.day,
        );
      }

      rangeEnd = DateTime(
        rangeStart.year + 1,
        rangeStart.month,
        rangeStart.day,
      );
    } else {
      rangeStart = DateTime(
        now.year,
        now.month,
        start.day,
      );

      if (rangeStart.isAfter(now)) {
        rangeStart = DateTime(
          now.year,
          now.month - 1,
          start.day,
        );
      }

      rangeEnd = DateTime(
        rangeStart.year,
        rangeStart.month + 1,
        rangeStart.day,
      );
    }

    final customEnd =
        budget['end_date']?.toString();

    final parsedCustomEnd =
        customEnd != null &&
                customEnd.isNotEmpty
            ? DateTime.tryParse(customEnd)
            : null;

    if (parsedCustomEnd != null &&
        parsedCustomEnd.isBefore(rangeEnd)) {
      rangeEnd = parsedCustomEnd
          .add(const Duration(days: 1));
    }

    double actual = 0;

    for (final expense in expenses) {
      final date = DateTime.tryParse(
        expense['date']?.toString() ?? '',
      );

      if (date == null) {
        continue;
      }

      if (!date.isBefore(rangeStart) &&
          date.isBefore(rangeEnd)) {
        actual +=
            (expense['amount'] as num?)
                    ?.toDouble() ??
                0;
      }
    }

    return actual;
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
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadStatistics,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(16),
                children: [
                  // ------------------------------------------------
                  // OVERALL SUMMARY
                  // ------------------------------------------------

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

                  // ------------------------------------------------
                  // DAILY / WEEKLY / MONTHLY / YEARLY
                  // ------------------------------------------------

                  dailySummary(),

                  const SizedBox(height: 14),

                  weeklySummary(),

                  const SizedBox(height: 14),

                  monthlySummary(),

                  const SizedBox(height: 14),

                  yearlySummary(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // MONTHLY CHART
                  // ------------------------------------------------

                  monthlyChart(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // WEEKLY CHART
                  // ------------------------------------------------

                  weeklyChart(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // YEARLY CHART
                  // ------------------------------------------------

                  yearlyChart(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // CATEGORY
                  // ------------------------------------------------

                  categoryBreakdown(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // HIGHEST TRANSACTIONS
                  // ------------------------------------------------

                  highestTransactionCard(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // SAVINGS ANALYSIS
                  // ------------------------------------------------

                  savingsAnalysis(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // BUDGET VS ACTUAL
                  // ------------------------------------------------

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
