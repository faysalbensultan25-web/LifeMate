
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<Map<String, dynamic>> budgets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'budgets',
      orderBy: 'start_date DESC',
    );

    if (!mounted) return;

    setState(() {
      budgets = result;
      isLoading = false;
    });
  }

  Future<void> showBudgetDialog({
    Map<String, dynamic>? budget,
  }) async {
    final titleController = TextEditingController(
      text: budget?['title'] ?? '',
    );

    final amountController = TextEditingController(
      text: budget?['amount']?.toString() ?? '',
    );

    String period = budget?['period'] ?? 'Monthly';

    DateTime startDate = budget != null
        ? DateTime.parse(budget['start_date'])
        : DateTime.now();

    DateTime? endDate = budget?['end_date'] != null
        ? DateTime.parse(budget!['end_date'])
        : null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                budget == null ? 'Add Budget' : 'Edit Budget',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Budget Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Budget Amount',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: period,
                      decoration: const InputDecoration(
                        labelText: 'Budget Period',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Weekly',
                          child: Text('Weekly'),
                        ),
                        DropdownMenuItem(
                          value: 'Monthly',
                          child: Text('Monthly'),
                        ),
                        DropdownMenuItem(
                          value: 'Yearly',
                          child: Text('Yearly'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            period = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start Date'),
                      subtitle: Text(
                        '${startDate.day}/${startDate.month}/${startDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (selected != null) {
                          setDialogState(() {
                            startDate = selected;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End Date (Optional)'),
                      subtitle: Text(
                        endDate == null
                            ? 'Not selected'
                            : '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? startDate,
                          firstDate: startDate,
                          lastDate: DateTime(2100),
                        );

                        if (selected != null) {
                          setDialogState(() {
                            endDate = selected;
                          });
                        }
                      },
                    ),
                    if (endDate != null)
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            endDate = null;
                          });
                        },
                        child: const Text('Remove End Date'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );

                    if (title.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a valid title and amount'),
                        ),
                      );
                      return;
                    }

                    final db = await AppDatabase.database;

                    final data = {
                      'title': title,
                      'amount': amount,
                      'period': period,
                      'start_date': startDate.toIso8601String(),
                      'end_date': endDate?.toIso8601String(),
                    };

                    if (budget == null) {
                      await db.insert('budgets', data);
                    } else {
                      await db.update(
                        'budgets',
                        data,
                        where: 'id = ?',
                        whereArgs: [budget['id']],
                      );
                    }

                    if (!mounted) return;

                    Navigator.pop(dialogContext);
                    await loadBudgets();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    amountController.dispose();
  }

  Future<void> deleteBudget(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text(
          'Are you sure you want to delete this budget?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await AppDatabase.database;

      await db.delete(
        'budgets',
        where: 'id = ?',
        whereArgs: [id],
      );

      await loadBudgets();
    }
  }

  String formatDate(String value) {
    final date = DateTime.parse(value);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planning'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBudgetDialog(),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : budgets.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 65,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No budgets yet',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.grey,
                        ),
                      ),
                      Text('Tap + to create your first budget'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadBudgets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE7F0FF),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF1877F2),
                            ),
                          ),
                          title: Text(
                            budget['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '৳ ${budget['amount']} • ${budget['period']}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Start: ${formatDate(budget['start_date'])}',
                                ),
                                if (budget['end_date'] != null)
                                  Text(
                                    'End: ${formatDate(budget['end_date'])}',
                                  ),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                showBudgetDialog(budget: budget);
                              } else if (value == 'delete') {
                                deleteBudget(budget['id'] as int);
                              }
                            },
                            itemBuilder: (context) => const [
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
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
