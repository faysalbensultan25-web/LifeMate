import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> incomeCategories = [];
  List<Map<String, dynamic>> expenseCategories = [];

  bool isLoading = true;
  bool isActionRunning = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final db = await AppDatabase.database;

    final budgetResult = await db.query(
      'budgets',
      orderBy: 'start_date DESC',
    );

    final categoryResult = await db.query(
      'categories',
      orderBy: 'name ASC',
    );

    if (!mounted) return;

    setState(() {
      budgets = budgetResult;

      incomeCategories = categoryResult
          .where((item) => item['type'] == 'income')
          .toList();

      expenseCategories = categoryResult
          .where((item) => item['type'] == 'expense')
          .toList();

      isLoading = false;
    });
  }

  Future<double> calculateActual(
    Map<String, dynamic> budget,
  ) async {
    final db = await AppDatabase.database;

    final type = budget['type']?.toString() ?? 'expense';

    final table = type == 'income' ? 'incomes' : 'expenses';

    final startDate = DateTime.parse(
      budget['start_date'].toString(),
    );

    DateTime start;
    DateTime end;

    if (budget['period'] == 'Monthly') {
      start = DateTime(
        startDate.year,
        startDate.month,
        1,
      );

      end = DateTime(
        startDate.year,
        startDate.month + 1,
        0,
        23,
        59,
        59,
      );
    } else {
      start = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      final storedEnd = budget['end_date'];

      if (storedEnd != null) {
        final parsedEnd = DateTime.parse(
          storedEnd.toString(),
        );

        end = DateTime(
          parsedEnd.year,
          parsedEnd.month,
          parsedEnd.day,
          23,
          59,
          59,
        );
      } else {
        end = start;
      }
    }

    final categoryId = budget['category_id'];

    String where = 'date >= ? AND date <= ?';
    final List<dynamic> whereArgs = [
      start.toIso8601String(),
      end.toIso8601String(),
    ];

    if (categoryId != null) {
      where += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM $table
      WHERE $where
      ''',
      whereArgs,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0;
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

    String type = budget?['type']?.toString() ?? 'expense';

    String period = budget?['period']?.toString() ?? 'Monthly';

    int? categoryId = budget?['category_id'] as int?;

    DateTime startDate = budget != null
        ? DateTime.parse(
            budget['start_date'].toString(),
          )
        : DateTime.now();

    DateTime? endDate = budget?['end_date'] != null
        ? DateTime.parse(
            budget!['end_date'].toString(),
          )
        : null;

    final dialogResult = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final categories = type == 'income'
                ? incomeCategories
                : expenseCategories;

            final categoryExists = categories.any(
              (item) => item['id'] == categoryId,
            );

            if (!categoryExists) {
              categoryId = null;
            }

            return AlertDialog(
              title: Text(
                budget == null
                    ? 'Add Budget'
                    : 'Edit Budget',
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Budget Type',
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
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value == null) return;

                              setDialogState(() {
                                type = value;
                                categoryId = null;
                              });
                            },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: titleController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Budget Title',
                        hintText: type == 'income'
                            ? 'Example: Monthly Income'
                            : 'Example: Monthly Expenses',
                        border: const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Planned Amount',
                        prefixText: '৳ ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<int?>(
                      value: categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...categories.map(
                          (category) => DropdownMenuItem<int?>(
                            value: category['id'] as int,
                            child: Text(
                              category['name'].toString(),
                            ),
                          ),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              setDialogState(() {
                                categoryId = value;
                              });
                            },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: period,
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
                                period = value;

                                if (value == 'Monthly') {
                                  endDate = null;
                                }
                              });
                            },
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month,
                      ),
                      title: const Text('Start Date'),
                      subtitle: Text(
                        formatDate(startDate),
                      ),
                      onTap: saving
                          ? null
                          : () async {
                              final selected =
                                  await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );

                              if (selected == null) return;

                              setDialogState(() {
                                startDate = selected;

                                if (endDate != null &&
                                    endDate!.isBefore(
                                      startDate,
                                    )) {
                                  endDate = null;
                                }
                              });
                            },
                    ),

                    if (period == 'Custom')
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.event,
                        ),
                        title: const Text('End Date'),
                        subtitle: Text(
                          endDate == null
                              ? 'Select end date'
                              : formatDate(endDate!),
                        ),
                        onTap: saving
                            ? null
                            : () async {
                                final selected =
                                    await showDatePicker(
                                  context: context,
                                  initialDate:
                                      endDate ?? startDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2100),
                                );

                                if (selected == null) {
                                  return;
                                }

                                setDialogState(() {
                                  endDate = selected;
                                });
                              },
                      ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(
                            dialogContext,
                            false,
                          ),
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (saving) return;

                          final title =
                              titleController.text.trim();

                          final amount =
                              double.tryParse(
                            amountController.text.trim(),
                          );

                          if (title.isEmpty ||
                              amount == null ||
                              amount <= 0) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a valid title and amount',
                                ),
                              ),
                            );
                            return;
                          }

                          if (period == 'Custom' &&
                              endDate == null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
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
                            final db =
                                await AppDatabase.database;

                            final data = {
                              'title': title,
                              'amount': amount,
                              'type': type,
                              'category_id': categoryId,
                              'period': period,
                              'start_date':
                                  startDate.toIso8601String(),
                              'end_date': period == 'Custom'
                                  ? endDate
                                      ?.toIso8601String()
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
                                whereArgs: [
                                  budget['id'],
                                ],
                              );
                            }

                            if (!mounted) return;

                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
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
                          child:
                              CircularProgressIndicator(
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

    if (dialogResult == true) {
      await loadData();
    }
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
              onPressed: () => Navigator.pop(
                context,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                true,
              ),
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

      await loadData();
    } finally {
      if (mounted) {
        setState(() {
          isActionRunning = false;
        });
      }
    }
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatAmount(dynamic value) {
    final amount =
        double.tryParse(value.toString()) ?? 0;

    return amount.toStringAsFixed(2);
  }

  String getCategoryName(
    Map<String, dynamic> budget,
  ) {
    final categoryId = budget['category_id'];

    if (categoryId == null) {
      return 'All Categories';
    }

    final categories =
        budget['type'] == 'income'
            ? incomeCategories
            : expenseCategories;

    for (final category in categories) {
      if (category['id'] == categoryId) {
        return category['name'].toString();
      }
    }

    return 'All Categories';
  }

  Future<Widget> buildBudgetStatus(
    Map<String, dynamic> budget,
  ) async {
    final planned =
        double.tryParse(
              budget['amount'].toString(),
            ) ??
            0;

    final actual =
        await calculateActual(budget);

    final difference = planned - actual;

    final exceeded = actual > planned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planned: ৳ ${formatAmount(planned)}',
        ),
        const SizedBox(height: 3),
        Text(
          'Actual: ৳ ${formatAmount(actual)}',
        ),
        const SizedBox(height: 3),
        Text(
          exceeded
              ? 'Exceeded: ৳ ${formatAmount(actual - planned)}'
              : 'Remaining: ৳ ${formatAmount(difference)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: exceeded
                ? Colors.red
                : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget buildBudgetCard(
    Map<String, dynamic> budget,
  ) {
    final type =
        budget['type']?.toString() ?? 'expense';

    final isIncome = type == 'income';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isIncome
                  ? Colors.green.withOpacity(0.12)
                  : Colors.red.withOpacity(0.12),
              child: Icon(
                isIncome
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: isIncome
                    ? Colors.green
                    : Colors.red,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    budget['title']?.toString() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    isIncome
                        ? 'Income Budget'
                        : 'Expense Budget',
                    style: TextStyle(
                      color: isIncome
                          ? Colors.green
                          : Colors.red,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Category: ${getCategoryName(budget)}',
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Time Frame: ${budget['period']}',
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Start: ${formatDate(
                      DateTime.parse(
                        budget['start_date']
                            .toString(),
                      ),
                    )}',
                  ),

                  if (budget['end_date'] != null)
                    Text(
                      'End: ${formatDate(
                        DateTime.parse(
                          budget['end_date']
                              .toString(),
                        ),
                      )}',
                    ),

                  const SizedBox(height: 8),

                  FutureBuilder<Widget>(
                    future: buildBudgetStatus(
                      budget,
                    ),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Text(
                          'Unable to calculate actual',
                        );
                      }

                      return snapshot.data ??
                          const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
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
          ],
        ),
      ),
    );
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
                    mainAxisAlignment:
                        MainAxisAlignment.center,
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
                  onRefresh: loadData,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(12),
                    itemCount: budgets.length,
                    itemBuilder:
                        (context, index) {
                      return buildBudgetCard(
                        budgets[index],
                      );
                    },
                  ),
                ),
    );
  }
}
