
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  bool loading = true;

  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> categories = [];

  double plannedIncome = 0;
  double plannedExpense = 0;
  double actualIncome = 0;
  double actualExpense = 0;

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

  String formatMoney(double value) {
    return '$currencySymbol ${value.toStringAsFixed(0)}';
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await loadCurrency();
    await loadData();
  }

  Future<void> loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('currency');

      if (!mounted) return;

      setState(() {
        currency = savedCurrency != null &&
                supportedCurrencies.contains(savedCurrency)
            ? savedCurrency
            : 'BDT (৳)';
      });
    } catch (e) {
      debugPrint('Currency loading error: $e');
    }
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final db = await AppDatabase.database;

      final b = await db.query(
        'budgets',
        orderBy: 'start_date DESC, id DESC',
      );

      final c = await db.query(
        'categories',
        orderBy: 'name ASC',
      );

      if (!mounted) return;

      setState(() {
        budgets = b;
        categories = c;
      });

      await calculateSummary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> calculateSummary() async {
    double pi = 0;
    double pe = 0;
    double ai = 0;
    double ae = 0;

    for (final budget in budgets) {
      final type = budget['type']?.toString() ?? 'expense';
      final amount = toDouble(budget['amount']);
      final actual = await calculateActual(budget);

      if (type == 'income') {
        pi += amount;
        ai += actual;
      } else {
        pe += amount;
        ae += actual;
      }
    }

    if (!mounted) return;

    setState(() {
      plannedIncome = pi;
      plannedExpense = pe;
      actualIncome = ai;
      actualExpense = ae;
    });
  }

  Future<double> calculateActual(
    Map<String, dynamic> budget,
  ) async {
    final db = await AppDatabase.database;

    final type = budget['type']?.toString() ?? 'expense';
    final categoryId = budget['category_id'];

    final startDate = parseDate(budget['start_date']);
    if (startDate == null) return 0;

    DateTime endDate;

    if ((budget['period'] ?? 'monthly') == 'monthly') {
      endDate = DateTime(
        startDate.year,
        startDate.month + 1,
        0,
        23,
        59,
        59,
      );
    } else {
      endDate = parseDate(budget['end_date']) ?? startDate;
      endDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
    }

    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final table = type == 'income' ? 'incomes' : 'expenses';

    final rows = await db.query(table);

    double total = 0;

    for (final row in rows) {
      final date = DateTime.tryParse(
        row['date']?.toString() ?? '',
      );

      if (date == null) continue;

      if (date.isBefore(start) || date.isAfter(endDate)) {
        continue;
      }

      if (categoryId != null &&
          row['category_id'].toString() != categoryId.toString()) {
        continue;
      }

      total += toDouble(row['amount']);
    }

    return total;
  }

  List<Map<String, dynamic>> categoriesFor(String type) {
    return categories
        .where((x) => x['type']?.toString() == type)
        .toList();
  }

  String categoryName(dynamic id) {
    if (id == null) return 'All Categories';

    for (final c in categories) {
      if (c['id'].toString() == id.toString()) {
        return c['name']?.toString() ?? 'All Categories';
      }
    }

    return 'All Categories';
  }

  Future<void> showBudgetDialog({
    Map<String, dynamic>? existing,
  }) async {
    final editing = existing != null;

    String type = existing?['type']?.toString() ?? 'expense';
    String period = existing?['period']?.toString() ?? 'monthly';

    final title = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );

    final amount = TextEditingController(
      text: existing == null
          ? ''
          : toDouble(existing['amount']).toStringAsFixed(2),
    );

    DateTime start = parseDate(existing?['start_date']) ??
        DateTime(
          DateTime.now().year,
          DateTime.now().month,
          1,
        );

    DateTime? end = parseDate(existing?['end_date']);

    int? categoryId = existing?['category_id'] == null
        ? null
        : int.tryParse(existing!['category_id'].toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            final available = categoriesFor(type);

            if (categoryId != null &&
                !available.any(
                  (x) => x['id'].toString() == categoryId.toString(),
                )) {
              categoryId = null;
            }

            return AlertDialog(
              title: Text(
                editing ? 'Edit Budget' : 'Add Budget',
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Income'),
                        ),
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Expense'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setDialog(() {
                          type = v;
                          categoryId = null;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Budget Title',
                        hintText: 'Example: Monthly Food',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '$currencySymbol ',
                        border: const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<int?>(
                      value: categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...available.map(
                          (x) => DropdownMenuItem<int?>(
                            value: x['id'] as int,
                            child: Text(x['name'].toString()),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setDialog(() {
                          categoryId = v;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: period,
                      decoration: const InputDecoration(
                        labelText: 'Period',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Monthly'),
                        ),
                        DropdownMenuItem(
                          value: 'custom',
                          child: Text('Custom'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;

                        setDialog(() {
                          period = v;

                          if (v == 'monthly') {
                            start = DateTime(
                              start.year,
                              start.month,
                              1,
                            );
                            end = null;
                          } else {
                            end ??= start;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month),
                      title: Text(
                        period == 'monthly' ? 'Month' : 'Start Date',
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy').format(start),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: start,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (picked == null) return;

                        setDialog(() {
                          start = period == 'monthly'
                              ? DateTime(picked.year, picked.month, 1)
                              : picked;

                          if (end != null && end!.isBefore(start)) {
                            end = start;
                          }
                        });
                      },
                    ),

                    if (period == 'custom')
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_available),
                        title: const Text('End Date'),
                        subtitle: Text(
                          end == null
                              ? 'Select end date'
                              : DateFormat('dd MMM yyyy').format(end!),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: end ?? start,
                            firstDate: start,
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setDialog(() {
                              end = picked;
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = title.text.trim();

                    final value = double.tryParse(
                      amount.text.trim().replaceAll(',', ''),
                    );

                    if (name.isEmpty || value == null || value <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter title and valid amount.'),
                        ),
                      );
                      return;
                    }

                    if (period == 'custom' && end == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select end date.'),
                        ),
                      );
                      return;
                    }

                    if (period == 'custom' && end!.isBefore(start)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'End date cannot be before start date.',
                          ),
                        ),
                      );
                      return;
                    }

                    final db = await AppDatabase.database;

                    final data = {
                      'title': name,
                      'amount': value,
                      'type': type,
                      'category_id': categoryId,
                      'period': period,
                      'start_date': DateFormat('yyyy-MM-dd').format(start),
                      'end_date': period == 'custom'
                          ? DateFormat('yyyy-MM-dd').format(end!)
                          : null,
                    };

                    if (editing) {
                      await db.update(
                        'budgets',
                        data,
                        where: 'id = ?',
                        whereArgs: [existing['id']],
                      );
                    } else {
                      await db.insert('budgets', data);
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: Text(editing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    title.dispose();
    amount.dispose();

    if (saved == true) {
      await loadData();
    }
  }

  Future<void> deleteBudget(Map<String, dynamic> budget) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final db = await AppDatabase.database;

    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [budget['id']],
    );

    await loadData();
  }

  String periodText(Map<String, dynamic> b) {
    final start = parseDate(b['start_date']);
    if (start == null) return '';

    if (b['period'] == 'monthly') {
      return DateFormat('MMMM yyyy').format(start);
    }

    final end = parseDate(b['end_date']);

    if (end == null) {
      return DateFormat('dd MMM yyyy').format(start);
    }

    return '${DateFormat('dd MMM yyyy').format(start)}'
        ' - '
        '${DateFormat('dd MMM yyyy').format(end)}';
  }

  Widget summary(
    String title,
    double value,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(value),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget budgetCard(Map<String, dynamic> budget) {
    final type = budget['type']?.toString() ?? 'expense';

    final planned = toDouble(budget['amount']);
    final income = type == 'income';

    return FutureBuilder<double>(
      future: calculateActual(budget),
      builder: (context, snapshot) {
        final actual = snapshot.data ?? 0;

        final progress = planned <= 0
            ? 0.0
            : (actual / planned).clamp(0.0, 1.0);

        final exceeded = income ? actual < planned : actual > planned;
        final remaining = (planned - actual).abs();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Icon(
                        income ? Icons.trending_up : Icons.trending_down,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget['title']?.toString() ?? 'Budget',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${income ? 'Income' : 'Expense'} • '
                            '${categoryName(budget['category_id'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            periodText(budget),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          showBudgetDialog(existing: budget);
                        } else {
                          deleteBudget(budget);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    amountText('Planned', planned),
                    amountText('Actual', actual),
                    amountText(
                      income ? 'Shortfall' : 'Remaining',
                      remaining,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                  ),
                ),

                const SizedBox(height: 7),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    income
                        ? (exceeded
                            ? 'Income target not reached'
                            : 'Income target reached')
                        : (exceeded ? 'Budget exceeded' : 'Within budget'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: exceeded ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget amountText(String title, double amount) {
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
        const SizedBox(height: 3),
        Text(
          formatMoney(amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final plannedSavings = plannedIncome - plannedExpense;
    final actualSavings = actualIncome - actualExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budget Planning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBudgetDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Budget'),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: [
                  Row(
                    children: [
                      summary(
                        'Planned Income',
                        plannedIncome,
                        Icons.trending_up,
                      ),
                      const SizedBox(width: 8),
                      summary(
                        'Actual Income',
                        actualIncome,
                        Icons.payments,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      summary(
                        'Planned Expense',
                        plannedExpense,
                        Icons.trending_down,
                      ),
                      const SizedBox(width: 8),
                      summary(
                        'Actual Expense',
                        actualExpense,
                        Icons.shopping_cart,
                      ),
                    ],
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.savings_outlined),
                      title: const Text(
                        'Savings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Planned: ${formatMoney(plannedSavings)}'
                        '  •  '
                        'Actual: ${formatMoney(actualSavings)}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Your Budgets',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (budgets.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 55,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No budgets yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Create your first budget.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  ...budgets.map(budgetCard),
                ],
              ),
            ),
    );
  }
}
