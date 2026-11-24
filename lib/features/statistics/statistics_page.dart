
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
  double savingsRate = 0;

  String highestIncomeDescription = '';
  String highestExpenseDescription = '';

  List<Map<String, dynamic>> incomes = [];
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> budgets = [];

  List<Map<String, dynamic>> monthlyData = [];
  List<Map<String, dynamic>> weeklyData = [];
  List<Map<String, dynamic>> yearlyData = [];
  List<Map<String, dynamic>> categoryData = [];

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    setState(() => isLoading = true);

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

      String maxIncomeDesc = '';
      String maxExpenseDesc = '';

      for (final item in loadedIncomes) {
        final amount = toDouble(item['amount']);
        incomeTotal += amount;

        if (amount > maxIncome) {
          maxIncome = amount;
          maxIncomeDesc = item['description']?.toString() ?? '';
        }
      }

      for (final item in loadedExpenses) {
        final amount = toDouble(item['amount']);
        expenseTotal += amount;

        if (amount > maxExpense) {
          maxExpense = amount;
          maxExpenseDesc = item['description']?.toString() ?? '';
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

        totalIncome = incomeTotal;
        totalExpense = expenseTotal;

        highestIncome = maxIncome;
        highestExpense = maxExpense;

        highestIncomeDescription = maxIncomeDesc;
        highestExpenseDescription = maxExpenseDesc;

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
        SnackBar(content: Text('Statistics loading failed: $e')),
      );
    }
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

    for (int year = currentYear - 4; year <= currentYear; year++) {
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

      totals[id] = (totals[id] ?? 0) + toDouble(item['amount']);
    }

    final result = <Map<String, dynamic>>[];

    for (final category in categories) {
      if (category['type']?.toString() != 'expense') continue;

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
      (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
    );

    return result;
  }

  String money(double amount) => '৳${amount.toStringAsFixed(2)}';

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
              style: const TextStyle(color: Colors.grey, fontSize: 12),
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

  Widget amountItem(String title, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: amountItem('Income', income, Colors.green)),
                Expanded(child: amountItem('Expense', expense, Colors.red)),
                Expanded(
                  child: amountItem(
                    'Balance',
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(title),
      ],
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
            const Text(
              'Monthly Income vs Expense',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Current year', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 14),
            Row(
              children: [
                legend(Colors.green, 'Income'),
                const SizedBox(width: 20),
                legend(Colors.red, 'Expense'),
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
                  final income = toDouble(item['income']);
                  final expense = toDouble(item['expense']);

                  return SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 135,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _chartBar(income, maxAmount, Colors.green, 13, 125),
                              const SizedBox(width: 5),
                              _chartBar(expense, maxAmount, Colors.red, 13, 125),
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
            const Text(
              'Last 7 Days',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
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

  Widget _chartBar(
    double amount,
    double maxAmount,
    Color color,
    double width,
    double maxHeight,
  ) {
    final height = amount <= 0 ? 2.0 : (amount / maxAmount) * maxHeight;

    return Container(
      width: width,
      height: height.clamp(2.0, maxHeight),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
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
            const Text(
              'Yearly Income vs Expense',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _bar('Income', toDouble(item['income']), maxAmount, Colors.green),
                    const SizedBox(height: 6),
                    _bar('Expense', toDouble(item['expense']), maxAmount, Colors.red),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _bar(String title, double amount, double maxAmount, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(title, style: const TextStyle(fontSize: 10)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0,
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

  Widget categoryBreakdown() {
    if (categoryData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No expense category data')),
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
            const Text(
              'Expense by Category',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                        Expanded(child: Text(item['name'].toString())),
                        Text('${percentage.toStringAsFixed(1)}%'),
                        const SizedBox(width: 8),
                        Text(
                          money(amount),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: maxAmount > 0 ? amount / maxAmount : 0,
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
            const Text(
              'Highest Transactions',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
            const Text(
              'Savings Analysis',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                      const Text(
                        'Savings Rate',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Savings',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
                      const Text(
                        'Total Income',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        money(totalIncome),
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  Map<String, DateTime>? getBudgetRange(
    Map<String, dynamic> budget,
  ) {
    final start = parseDate(budget['start_date']);
    if (start == null) return null;

    final period = budget['period']?.toString().toLowerCase() ?? 'monthly';

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

  double calculateBudgetActual(Map<String, dynamic> budget) {
    final range = getBudgetRange(budget);
    if (range == null) return 0;

    final type = budget['type']?.toString().toLowerCase() ?? 'expense';
    final categoryId = budget['category_id'];

    final source = type == 'income' ? incomes : expenses;

    double actual = 0;

    for (final item in source) {
      final date = parseDate(item['date']);
      if (date == null) continue;

      if (!isDateInRange(date, range['start']!, range['end']!)) {
        continue;
      }

      if (categoryId != null &&
          item['category_id']?.toString() != categoryId.toString()) {
        continue;
      }

      actual += toDouble(item['amount']);
    }

    return actual;
  }

  bool isCurrentBudget(Map<String, dynamic> budget) {
    final range = getBudgetRange(budget);
    if (range == null) return false;

    final today = dateOnly(DateTime.now());

    return !today.isBefore(range['start']!) &&
        !today.isAfter(range['end']!);
  }

  String budgetCategoryName(Map<String, dynamic> budget) {
    final id = budget['category_id'];
    if (id == null) return 'All Categories';

    for (final category in categories) {
      if (category['id'].toString() == id.toString()) {
        return category['name'].toString();
      }
    }

    return 'All Categories';
  }

  Widget budgetVsActual() {
    if (budgets.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No budget plans found.')),
        ),
      );
    }

    final currentBudgets = budgets.where(isCurrentBudget).toList();

    if (currentBudgets.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No active budget plans.')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget vs Actual',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Current active budgets',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...currentBudgets.map((budget) {
              final planned = toDouble(budget['amount']);
              final actual = calculateBudgetActual(budget);
              final percentage = planned > 0 ? actual / planned : 0.0;
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
                          isIncome ? Icons.trending_up : Icons.trending_down,
                          size: 19,
                          color: color,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            budget['title']?.toString() ?? 'Budget',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: amountItem('Planned', planned, Colors.blue)),
                        Expanded(child: amountItem('Actual', actual, color)),
                        Expanded(
                          child: amountItem(
                            exceeded ? 'Exceeded' : 'Remaining',
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
                          ? 'Exceeded by ${money(actual - planned)}'
                          : '${(percentage * 100).toStringAsFixed(1)}% used • '
                              'Remaining ${money(difference)}',
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
          'Daily Statistics',
          DateFormat('dd MMM yyyy').format(now),
          dailyIncome,
          dailyExpense,
        ),
        const SizedBox(height: 14),
        periodSummary(
          'Weekly Statistics',
          'Last 7 days',
          weeklyIncome,
          weeklyExpense,
        ),
        const SizedBox(height: 14),
        periodSummary(
          'Monthly Statistics',
          DateFormat('MMMM yyyy').format(now),
          monthlyIncome,
          monthlyExpense,
        ),
        const SizedBox(height: 14),
        periodSummary(
          'Yearly Statistics',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadStatistics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        balance >= 0 ? Colors.blue : Colors.red,
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
                  const Center(
                    child: Text(
                      'LifeMate Statistics',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }
}
