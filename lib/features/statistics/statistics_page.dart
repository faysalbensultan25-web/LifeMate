
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  double totalIncome = 0;
  double totalExpense = 0;

  List<Map<String, dynamic>> monthlyData = [];
  List<Map<String, dynamic>> categoryData = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    final db = await AppDatabase.database;

    final incomes = await db.query('incomes');
    final expenses = await db.query('expenses');
    final categories = await db.query('categories');

    double incomeTotal = 0;
    double expenseTotal = 0;

    for (final item in incomes) {
      incomeTotal +=
          (item['amount'] as num).toDouble();
    }

    for (final item in expenses) {
      expenseTotal +=
          (item['amount'] as num).toDouble();
    }

    final now = DateTime.now();
    final monthly = <Map<String, dynamic>>[];

    for (int month = 1; month <= 12; month++) {
      double monthIncome = 0;
      double monthExpense = 0;

      for (final item in incomes) {
        final date = DateTime.tryParse(
          item['date'] as String,
        );

        if (date != null &&
            date.year == now.year &&
            date.month == month) {
          monthIncome +=
              (item['amount'] as num).toDouble();
        }
      }

      for (final item in expenses) {
        final date = DateTime.tryParse(
          item['date'] as String,
        );

        if (date != null &&
            date.year == now.year &&
            date.month == month) {
          monthExpense +=
              (item['amount'] as num).toDouble();
        }
      }

      monthly.add({
        'month': month,
        'income': monthIncome,
        'expense': monthExpense,
      });
    }

    final categoryTotals = <int, double>{};

    for (final item in expenses) {
      final categoryId = item['category_id'];

      if (categoryId != null) {
        final id = categoryId as int;

        categoryTotals[id] =
            (categoryTotals[id] ?? 0) +
            (item['amount'] as num).toDouble();
      }
    }

    final categoryList = <Map<String, dynamic>>[];

    for (final category in categories) {
      if (category['type'] != 'expense') continue;

      final id = category['id'] as int;
      final amount = categoryTotals[id] ?? 0;

      if (amount > 0) {
        categoryList.add({
          'name': category['name'],
          'amount': amount,
        });
      }
    }

    categoryList.sort(
      (a, b) => (b['amount'] as double)
          .compareTo(a['amount'] as double),
    );

    if (!mounted) return;

    setState(() {
      totalIncome = incomeTotal;
      totalExpense = expenseTotal;
      monthlyData = monthly;
      categoryData = categoryList;
      isLoading = false;
    });
  }

  String money(double amount) {
    return '৳${amount.toStringAsFixed(2)}';
  }

  String monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return months[month - 1];
  }

  Widget summaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                money(amount),
                style: TextStyle(
                  fontSize: 19,
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

  Widget monthlyChart() {
    final currentMonth = DateTime.now().month;

    final visibleData = monthlyData
        .where(
          (item) => (item['month'] as int) <= currentMonth,
        )
        .toList();

    double maxAmount = 0;

    for (final item in visibleData) {
      final income = item['income'] as double;
      final expense = item['expense'] as double;

      if (income > maxAmount) maxAmount = income;
      if (expense > maxAmount) maxAmount = expense;
    }

    if (maxAmount == 0) maxAmount = 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Income & Expense',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _legend(Colors.green, 'Income'),
                const SizedBox(width: 20),
                _legend(Colors.red, 'Expense'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: visibleData.length,
                itemBuilder: (context, index) {
                  final item = visibleData[index];

                  final income = item['income'] as double;
                  final expense = item['expense'] as double;

                  final incomeHeight =
                      (income / maxAmount) * 125;

                  final expenseHeight =
                      (expense / maxAmount) * 125;

                  return SizedBox(
                    width: 58,
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
                                height: incomeHeight < 2
                                    ? 2
                                    : incomeHeight,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 13,
                                height: expenseHeight < 2
                                    ? 2
                                    : expenseHeight,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          monthName(item['month'] as int),
                          style: const TextStyle(
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

  Widget _legend(Color color, String title) {
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

  Widget categoryBreakdown() {
    if (categoryData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('No expense category data'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              final amount = item['amount'] as double;

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] as String,
                          ),
                        ),
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
                      borderRadius:
                          BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: amount / maxAmount,
                        minHeight: 9,
                        backgroundColor:
                            Colors.grey.shade200,
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

  @override
  Widget build(BuildContext context) {
    final balance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            onPressed: loadStatistics,
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
                padding: const EdgeInsets.all(16),
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
                        totalIncome,
                        Icons.trending_up,
                        Colors.green,
                      ),
                      summaryCard(
                        'Total Expense',
                        totalExpense,
                        Icons.trending_down,
                        Colors.red,
                      ),
                      summaryCard(
                        'Balance',
                        balance,
                        Icons.account_balance_wallet,
                        balance >= 0
                            ? Colors.blue
                            : Colors.red,
                      ),
                      summaryCard(
                        'Savings',
                        balance > 0 ? balance : 0,
                        Icons.savings,
                        Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  monthlyChart(),
                  const SizedBox(height: 20),
                  categoryBreakdown(),
                ],
              ),
            ),
    );
  }
}
