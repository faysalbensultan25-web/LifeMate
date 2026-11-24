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
  bool isActionRunning = false;

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
    if (isActionRunning) return;

    final titleController = TextEditingController(
      text: budget?['title']?.toString() ?? '',
    );

    final amountController = TextEditingController(
      text: budget?['amount']?.toString() ?? '',
    );

    String timeFrame = budget?['period']?.toString() ?? 'Monthly';

    DateTime startDate = budget != null
        ? DateTime.parse(budget['start_date'].toString())
        : DateTime.now();

    DateTime? endDate = budget?['end_date'] != null
        ? DateTime.parse(budget!['end_date'].toString())
        : null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

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
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Budget Title',
                        hintText: 'Example: Monthly Family Budget',
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
                        prefixText: '৳ ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: timeFrame,
                      decoration: const InputDecoration(
                        labelText: 'Time Frame',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Monthly',
                          child: Text('Monthly'),
                        ),
                        DropdownMenuItem(
                          value: 'Custom',
                          child: Text('Custom'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value == null) return;

                              setDialogState(() {
                                timeFrame = value;

                                if (value == 'Monthly') {
                                  endDate = null;
                                }
                              });
                            },
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Start Date'),
                      subtitle: Text(formatDateTime(startDate)),
                      onTap: saving
                          ? null
                          : () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );

                              if (selected == null) return;

                              setDialogState(() {
                                startDate = selected;

                                if (endDate != null &&
                                    endDate!.isBefore(startDate)) {
                                  endDate = null;
                                }
                              });
                            },
                    ),

                    if (timeFrame == 'Custom') ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: const Text('End Date'),
                        subtitle: Text(
                          endDate == null
                              ? 'Select end date'
                              : formatDateTime(endDate!),
                        ),
                        onTap: saving
                            ? null
                            : () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? startDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2100),
                                );

                                if (selected == null) return;

                                setDialogState(() {
                                  endDate = selected;
                                });
                              },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          // Prevent double tap / double action.
                          if (saving) return;

                          final title = titleController.text.trim();
                          final amount = double.tryParse(
                            amountController.text.trim(),
                          );

                          if (title.isEmpty ||
                              amount == null ||
                              amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a valid title and amount',
                                ),
                              ),
                            );
                            return;
                          }

                          if (timeFrame == 'Custom' && endDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select an end date',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final db = await AppDatabase.database;

                            final data = <String, dynamic>{
                              'title': title,
                              'amount': amount,
                              'period': timeFrame,
                              'start_date':
                                  startDate.toIso8601String(),
                              'end_date': timeFrame == 'Custom'
                                  ? endDate?.toIso8601String()
                                  : null,
                            };

                            if (budget == null) {
                              await db.insert(
                                'budgets',
                                data,
                              );
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
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not save budget: $e',
                                ),
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save'),
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
    if (isActionRunning) return;

    setState(() {
      isActionRunning = true;
    });

    try {
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final db = await AppDatabase.database;

      await db.delete(
        'budgets',
        where: 'id = ?',
        whereArgs: [id],
      );

      await loadBudgets();
    } finally {
      if (mounted) {
        setState(() {
          isActionRunning = false;
        });
      }
    }
  }

  String formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatAmount(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planning'),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: isActionRunning
            ? null
            : () => showBudgetDialog(),
        child: const Icon(Icons.add),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
                      SizedBox(height: 4),
                      Text(
                        'Tap + to create your first budget',
                      ),
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
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE7F0FF),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF1877F2),
                            ),
                          ),

                          title: Text(
                            budget['title']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '৳ ${formatAmount(budget['amount'])}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Time Frame: ${budget['period']}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Start: ${formatDateTime(
                                    DateTime.parse(
                                      budget['start_date'].toString(),
                                    ),
                                  )}',
                                ),
                                if (budget['end_date'] != null)
                                  Text(
                                    'End: ${formatDateTime(
                                      DateTime.parse(
                                        budget['end_date'].toString(),
                                      ),
                                    )}',
                                  ),
                              ],
                            ),
                          ),

                          isThreeLine: true,

                          trailing: PopupMenuButton<String>(
                            enabled: !isActionRunning,
                            onSelected: (value) {
                              if (isActionRunning) return;

                              if (value == 'edit') {
                                showBudgetDialog(
                                  budget: budget,
                                );
                              } else if (value == 'delete') {
                                deleteBudget(
                                  budget['id'] as int,
                                );
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
