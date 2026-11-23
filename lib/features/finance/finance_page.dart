
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  List<Map<String, dynamic>> incomes = [];
  List<Map<String, dynamic>> expenses = [];

  double totalIncome = 0;
  double totalExpense = 0;

  double get balance => totalIncome - totalExpense;

  @override
  void initState() {
    super.initState();
    loadFinanceData();
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

    final incomeTotal = incomeData.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    final expenseTotal = expenseData.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    if (!mounted) return;

    setState(() {
      incomes = incomeData;
      expenses = expenseData;
      totalIncome = incomeTotal;
      totalExpense = expenseTotal;
    });
  }

  Future<void> addTransaction(bool isIncome) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isIncome ? 'Add Income' : 'Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(
                  amountController.text.trim(),
                );

                if (amount == null || amount <= 0) return;

                final db = await AppDatabase.database;
                final now = DateTime.now().toIso8601String();

                await db.insert(
                  isIncome ? 'incomes' : 'expenses',
                  {
                    'amount': amount,
                    'description': descriptionController.text.trim(),
                    'date': now,
                    'created_at': now,
                  },
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    amountController.dispose();
    descriptionController.dispose();

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              '৳ ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget transactionList(
    String title,
    List<Map<String, dynamic>> items,
    bool isIncome,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (items.isEmpty)
          const Card(
            child: ListTile(
              title: Text('No transactions yet'),
            ),
          )
        else
          ...items.map((item) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isIncome
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  '৳ ${(item['amount'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  (item['description'] as String?)?.isNotEmpty == true
                      ? item['description'] as String
                      : 'No description',
                ),
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
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
      ),
      body: RefreshIndicator(
        onRefresh: loadFinanceData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
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
              ],
            ),
            summaryCard(
              'Current Balance',
              balance,
              Icons.account_balance_wallet,
              const Color(0xFF1877F2),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => addTransaction(true),
                    icon: const Icon(Icons.add),
                    label: const Text('Income'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => addTransaction(false),
                    icon: const Icon(Icons.remove),
                    label: const Text('Expense'),
                  ),
                ),
              ],
            ),
            transactionList('Income History', incomes, true),
            transactionList('Expense History', expenses, false),
          ],
        ),
      ),
    );
  }
}
