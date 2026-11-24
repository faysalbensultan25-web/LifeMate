import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  List<Map<String, dynamic>> incomes = [];
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categories = [];

  double totalIncome = 0;
  double totalExpense = 0;

  double get balance => totalIncome - totalExpense;

  @override
  void initState() {
    super.initState();
    initializeFinance();
  }

  Future<void> initializeFinance() async {
    await insertDefaultCategories();
    await loadFinanceData();
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

    final incomeData =
        await db.query('incomes', orderBy: 'id DESC');

    final expenseData =
        await db.query('expenses', orderBy: 'id DESC');

    final categoryData =
        await db.query('categories', orderBy: 'name ASC');

    double income = 0;
    double expense = 0;

    for (final x in incomeData) {
      income += (x['amount'] as num).toDouble();
    }

    for (final x in expenseData) {
      expense += (x['amount'] as num).toDouble();
    }

    if (!mounted) return;

    setState(() {
      incomes = incomeData;
      expenses = expenseData;
      categories = categoryData;
      totalIncome = income;
      totalExpense = expense;
    });
  }

  Future<void> addCategory(String type) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          type == 'income'
              ? 'Add Income Category'
              : 'Add Expense Category',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
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
            child: const Text('Save'),
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
              title: Row(
                children: [
                  Icon(
                    isIncome
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(isIncome ? 'Add Income' : 'Add Expense'),
                ],
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
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '৳ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
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
                        label: const Text('Add Category'),
                      ),
                    ),

                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim());

                    if (amount == null ||
                        amount <= 0 ||
                        selectedCategoryId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter amount and select category',
                          ),
                        ),
                      );
                      return;
                    }

                    final db = await AppDatabase.database;
                    final date =
                        selectedDate.toIso8601String();

                    await db.insert(
                      isIncome ? 'incomes' : 'expenses',
                      {
                        'amount': amount,
                        'category_id': selectedCategoryId,
                        'description':
                            descriptionController.text.trim(),
                        'date': date,
                        'created_at':
                            DateTime.now().toIso8601String(),
                      },
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
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

  Widget summaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '৳ ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
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
    final amount = (item['amount'] as num).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isIncome
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          '${isIncome ? '+' : '-'} ৳ ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    ? 'No income recorded'
                    : 'No expense recorded',
              ),
            ),
          )
        else
          ...items.map((x) => transactionCard(x, isIncome)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: addCategory,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'income',
                child: Text('Add Income Category'),
              ),
              PopupMenuItem(
                value: 'expense',
                child: Text('Add Expense Category'),
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
              'Current Balance',
              balance,
              Icons.account_balance_wallet,
              balance >= 0
                  ? Colors.blue
                  : Colors.red,
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => addTransaction(true),
                    icon: const Icon(Icons.add),
                    label: const Text('Income'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => addTransaction(false),
                    icon: const Icon(Icons.remove),
                    label: const Text('Expense'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            history(
              'Income History',
              incomes,
              true,
            ),

            history(
              'Expense History',
              expenses,
              false,
            ),
          ],
        ),
      ),
    );
  }
}
