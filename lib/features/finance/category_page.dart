
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Map<String, dynamic>> incomeCategories = [];
  List<Map<String, dynamic>> expenseCategories = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final db = await AppDatabase.database;

    final income = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: ['income'],
      orderBy: 'name ASC',
    );

    final expense = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: ['expense'],
      orderBy: 'name ASC',
    );

    if (!mounted) return;

    setState(() {
      incomeCategories = income;
      expenseCategories = expense;
      isLoading = false;
    });
  }

  Future<void> addCategory(String type) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Category'),
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
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || !mounted) return;

    final db = await AppDatabase.database;

    final existing = await db.query(
      'categories',
      where: 'name = ? AND type = ?',
      whereArgs: [name, type],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category already exists'),
        ),
      );
      return;
    }

    await db.insert('categories', {
      'name': name,
      'type': type,
      'created_at': DateTime.now().toIso8601String(),
    });

    await loadCategories();
  }

  Future<void> editCategory(
    Map<String, dynamic> category,
  ) async {
    final controller = TextEditingController(
      text: category['name'] as String,
    );

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Category'),
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
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || !mounted) return;

    final db = await AppDatabase.database;

    final existing = await db.query(
      'categories',
      where: 'name = ? AND type = ? AND id != ?',
      whereArgs: [
        name,
        category['type'],
        category['id'],
      ],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category already exists'),
        ),
      );
      return;
    }

    await db.update(
      'categories',
      {'name': name},
      where: 'id = ?',
      whereArgs: [category['id']],
    );

    await loadCategories();
  }

  Future<void> deleteCategory(
    Map<String, dynamic> category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Category?'),
          content: Text(
            'Are you sure you want to delete '
            '"${category['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final db = await AppDatabase.database;
    final categoryId = category['id'];

    final incomeUsage = await db.query(
      'incomes',
      columns: ['id'],
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );

    final expenseUsage = await db.query(
      'expenses',
      columns: ['id'],
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );

    if (incomeUsage.isNotEmpty ||
        expenseUsage.isNotEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This category is already in use. '
            'It cannot be deleted.',
          ),
        ),
      );
      return;
    }

    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    await loadCategories();
  }

  Widget categoryList(
    List<Map<String, dynamic>> categories,
  ) {
    if (categories.isEmpty) {
      return const Center(
        child: Text('No categories found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.category_outlined),
            ),
            title: Text(category['name'] as String),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => editCategory(category),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => deleteCategory(category),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Category Management'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.trending_up),
                text: 'Income',
              ),
              Tab(
                icon: Icon(Icons.trending_down),
                text: 'Expense',
              ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                children: [
                  categoryList(incomeCategories),
                  categoryList(expenseCategories),
                ],
              ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                final index =
                    DefaultTabController.of(context).index;

                addCategory(
                  index == 0 ? 'income' : 'expense',
                );
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}
