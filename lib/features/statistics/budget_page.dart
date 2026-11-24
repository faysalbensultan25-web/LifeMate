import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  bool isLoading = true;
  bool isSaving = false;

  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> categories = [];

  double plannedIncome = 0;
  double plannedExpense = 0;
  double actualIncome = 0;
  double actualExpense = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final db = await AppDatabase.database;

      final budgetData = await db.query(
        'budgets',
        orderBy: 'start_date DESC, id DESC',
      );

      final categoryData = await db.query(
        'categories',
        orderBy: 'name ASC',
      );

      if (!mounted) return;

      setState(() {
        budgets = budgetData;
        categories = categoryData;
      });

      await calculateSummary();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load budget data: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> calculateSummary() async {
    double pIncome = 0;
    double pExpense = 0;
    double aIncome = 0;
    double aExpense = 0;

    final db = await AppDatabase.database;

    for (final budget in budgets) {
      final type = (budget['type'] ?? 'expense').toString();
      final amount = _toDouble(budget['amount']);

      if (type == 'income') {
        pIncome += amount;
      } else {
        pExpense += amount;
      }

      final actual = await calculateActual(budget);

      if (type == 'income') {
        aIncome += actual;
      } else {
        aExpense += actual;
      }
    }

    if (!mounted) return;

    setState(() {
      plannedIncome = pIncome;
      plannedExpense = pExpense;
      actualIncome = aIncome;
      actualExpense = aExpense;
    });

    // Keep database connection referenced so analyzer does not
    // consider this flow incomplete.
    db;
  }

  Future<double> calculateActual(
    Map<String, dynamic> budget,
  ) async {
    final db = await AppDatabase.database;

    final type = (budget['type'] ?? 'expense').toString();
    final categoryId = budget['category_id'];

    final startDate = _parseDate(budget['start_date']);

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
      final parsedEnd = _parseDate(budget['end_date']);

      if (parsedEnd == null) return 0;

      endDate = DateTime(
        parsedEnd.year,
        parsedEnd.month,
        parsedEnd.day,
        23,
        59,
        59,
      );
    }

    final start = DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ),
    );

    final end = DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate);

    final table = type == 'income' ? 'incomes' : 'expenses';

    final whereParts = <String>[
      'date >= ?',
      'date <= ?',
    ];

    final whereArgs = <dynamic>[
      start,
      end,
    ];

    if (categoryId != null) {
      whereParts.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM $table
      WHERE ${whereParts.join(' AND ')}
      ''',
      whereArgs,
    );

    return _toDouble(result.first['total']);
  }

  String categoryName(dynamic categoryId) {
    if (categoryId == null) {
      return 'All Categories';
    }

    for (final category in categories) {
      if (category['id'].toString() == categoryId.toString()) {
        return category['name']?.toString() ?? 'All Categories';
      }
    }

    return 'All Categories';
  }

  List<Map<String, dynamic>> categoriesForType(String type) {
    return categories.where((category) {
      return (category['type'] ?? '').toString() == type;
    }).toList();
  }

  Future<void> showBudgetDialog({
    Map<String, dynamic>? existing,
  }) async {
    final isEditing = existing != null;

    String type =
        (existing?['type'] ?? 'expense').toString();

    String period =
        (existing?['period'] ?? 'monthly').toString();

    final titleController = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );

    final amountController = TextEditingController(
      text: existing != null
          ? _toDouble(existing['amount']).toStringAsFixed(2)
          : '',
    );

    DateTime startDate =
        _parseDate(existing?['start_date']) ??
            DateTime(
              DateTime.now().year,
              DateTime.now().month,
              1,
            );

    DateTime? endDate =
        _parseDate(existing?['end_date']);

    int? categoryId;

    if (existing?['category_id'] != null) {
      categoryId = int.tryParse(
        existing!['category_id'].toString(),
      );
    }

    if (period == 'custom' && endDate == null) {
      endDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
    }

    isSaving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableCategories =
                categoriesForType(type);

            final categoryExists = categoryId == null ||
                availableCategories.any(
                  (category) =>
                      category['id'].toString() ==
                      categoryId.toString(),
                );

            if (!categoryExists) {
              categoryId = null;
            }

            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Budget' : 'Add Budget',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      onChanged: isSaving
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
                      enabled: !isSaving,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Example: Monthly food',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: amountController,
                      enabled: !isSaving,
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
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...availableCategories.map(
                          (category) {
                            return DropdownMenuItem<int?>(
                              value: int.tryParse(
                                category['id'].toString(),
                              ),
                              child: Text(
                                category['name'].toString(),
                              ),
                            );
                          },
                        ),
                      ],
                      onChanged: isSaving
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
                          value: 'monthly',
                          child: Text('Monthly'),
                        ),
                        DropdownMenuItem(
                          value: 'custom',
                          child: Text('Custom'),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) return;

                              setDialogState(() {
                                period = value;

                                if (period == 'monthly') {
                                  endDate = null;
                                  startDate = DateTime(
                                    startDate.year,
                                    startDate.month,
                                    1,
                                  );
                                } else {
                                  endDate ??= DateTime(
                                    startDate.year,
                                    startDate.month,
                                    startDate.day,
                                  );
                                }
                              });
                            },
                    ),

                    const SizedBox(height: 12),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month_outlined,
                      ),
                      title: Text(
                        period == 'monthly'
                            ? 'Month'
                            : 'Start Date',
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy')
                            .format(startDate),
                      ),
                      onTap: isSaving
                          ? null
                          : () async {
                              if (period == 'monthly') {
                                final picked =
                                    await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    startDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      1,
                                    );
                                  });
                                }
                              } else {
                                final picked =
                                    await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    startDate = picked;

                                    if (endDate != null &&
                                        endDate!.isBefore(
                                          startDate,
                                        )) {
                                      endDate = startDate;
                                    }
                                  });
                                }
                              }
                            },
                    ),

                    if (period == 'custom')
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.event_available_outlined,
                        ),
                        title: const Text('End Date'),
                        subtitle: Text(
                          endDate == null
                              ? 'Select end date'
                              : DateFormat('dd MMM yyyy')
                                  .format(endDate!),
                        ),
                        onTap: isSaving
                            ? null
                            : () async {
                                final picked =
                                    await showDatePicker(
                                  context: context,
                                  initialDate:
                                      endDate ?? startDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2100),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    endDate = picked;
                                  });
                                }
                              },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (isSaving) return;

                          final title =
                              titleController.text.trim();

                          final amount = double.tryParse(
                            amountController.text
                                .trim()
                                .replaceAll(',', ''),
                          );

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Enter a budget title.'),
                              ),
                            );
                            return;
                          }

                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a valid amount.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (period == 'custom' &&
                              endDate == null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Select an end date.'),
                              ),
                            );
                            return;
                          }

                          if (period == 'custom' &&
                              endDate!.isBefore(startDate)) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'End date cannot be before start date.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final db =
                                await AppDatabase.database;

                            final data = <String, dynamic>{
                              'title': title,
                              'amount': amount,
                              'type': type,
                              'category_id': categoryId,
                              'period': period,
                              'start_date': DateFormat(
                                'yyyy-MM-dd',
                              ).format(startDate),
                              'end_date': period == 'custom'
                                  ? DateFormat('yyyy-MM-dd')
                                      .format(endDate!)
                                  : null,
                            };

                            if (isEditing) {
                              await db.update(
                                'budgets',
                                data,
                                where: 'id = ?',
                                whereArgs: [
                                  existing['id'],
                                ],
                              );
                            } else {
                              await db.insert(
                                'budgets',
                                data,
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(
                                dialogContext,
                                true,
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                isSaving = false;
                              });

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not save budget: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update' : 'Save',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    amountController.dispose();

    if (result == true && mounted) {
      await loadData();
    }
  }

  Future<void> deleteBudget(
    Map<String, dynamic> budget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: const Text(
            'Are you sure you want to delete this budget?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final db = await AppDatabase.database;

      await db.delete(
        'budgets',
        where: 'id = ?',
        whereArgs: [budget['id']],
      );

      await loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete budget: $e'),
        ),
      );
    }
  }

  String periodText(Map<String, dynamic> budget) {
    final period =
        (budget['period'] ?? 'monthly').toString();

    final start = _parseDate(budget['start_date']);

    if (start == null) return '';

    if (period == 'monthly') {
      return DateFormat('MMMM yyyy').format(start);
    }

    final end = _parseDate(budget['end_date']);

    if (end == null) {
      return DateFormat('dd MMM yyyy').format(start);
    }

    return '${DateFormat('dd MMM yyyy').format(start)}'
        ' – '
        '${DateFormat('dd MMM yyyy').format(end)}';
  }

  Widget summaryCard(
    String title,
    double amount,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '৳${amount.toStringAsFixed(0)}',
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

  Widget budgetCard(
    Map<String, dynamic> budget,
  ) {
    final type =
        (budget['type'] ?? 'expense').toString();

    final amount = _toDouble(budget['amount']);

    return FutureBuilder<double>(
      future: calculateActual(budget),
      builder: (context, snapshot) {
        final actual = snapshot.data ?? 0;
        final isIncome = type == 'income';

        final difference = isIncome
            ? amount - actual
            : amount - actual;

        final exceeded = isIncome
            ? actual < amount
            : actual > amount;

        final progress = amount <= 0
            ? 0.0
            : (actual / amount).clamp(0.0, 1.0);

        final progressColor = exceeded
            ? Colors.orange
            : Colors.green;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: isIncome
                          ? Colors.green.withValues(
                              alpha: 0.12,
                            )
                          : Colors.red.withValues(
                              alpha: 0.12,
                            ),
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
                            budget['title']?.toString() ??
                                'Budget',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${isIncome ? 'Income' : 'Expense'}'
                            ' • ${categoryName(budget['category_id'])}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            periodText(budget),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showBudgetDialog(
                            existing: budget,
                          );
                        } else if (value == 'delete') {
                          deleteBudget(budget);
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ];
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    _amountColumn(
                      'Planned',
                      amount,
                    ),
                    _amountColumn(
                      'Actual',
                      actual,
                    ),
                    _amountColumn(
                      isIncome
                          ? 'Shortfall'
                          : 'Remaining',
                      difference.abs(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      progressColor,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isIncome
                      ? (exceeded
                          ? 'Income target not reached'
                          : 'Income target reached')
                      : (exceeded
                          ? 'Budget exceeded'
                          : 'Within budget'),
                  style: TextStyle(
                    fontSize: 12,
                    color: exceeded
                        ? Colors.orange.shade800
                        : Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _amountColumn(
    String title,
    double amount,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '৳${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    final actualSavings =
        actualIncome - actualExpense;

    final plannedSavings =
        plannedIncome - plannedExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planning'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading
            ? null
            : () => showBudgetDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Budget'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              child: budgets.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 160),
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No budgets yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Create a monthly or custom budget.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        90,
                      ),
                      children: [
                        Row(
                          children: [
                            summaryCard(
                              'Planned Income',
                              plannedIncome,
                              Icons.trending_up,
                            ),
                            const SizedBox(width: 8),
                            summaryCard(
                              'Actual Income',
                              actualIncome,
                              Icons.payments_outlined,
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            summaryCard(
                              'Planned Expense',
                              plannedExpense,
                              Icons.trending_down,
                            ),
                            const SizedBox(width: 8),
                            summaryCard(
                              'Actual Expense',
                              actualExpense,
                              Icons.shopping_cart_outlined,
                            ),
                          ],
                        ),

                        Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.savings_outlined,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Savings',
                                        style: TextStyle(
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Planned: ৳${plannedSavings.toStringAsFixed(0)}'
                                        '   •   '
                                        'Actual: ৳${actualSavings.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Your Budgets',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        ...budgets.map(
                          budgetCard,
                        ),
                      ],
                    ),
            ),
    );
  }
}
