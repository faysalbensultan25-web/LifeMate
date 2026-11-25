
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Map<String, dynamic>> tasks = [];

  final TextEditingController controller =
      TextEditingController();

  bool isSaving = false;
  bool isLoading = true;

  int get pendingCount => tasks
      .where((task) => task['completed'] != 1)
      .length;

  int get completedCount => tasks
      .where((task) => task['completed'] == 1)
      .length;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final db = await AppDatabase.database;

      final result = await db.query(
        'todos',
        orderBy: 'id DESC',
      );

      if (!mounted) return;

      setState(() {
        tasks = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loading failed: $e')),
      );
    }
  }

  Future<void> addTask(BuildContext dialogContext) async {
    if (isSaving) return;

    final title = controller.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a task name.'),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final db = await AppDatabase.database;

      await db.insert('todos', {
        'title': title,
        'completed': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      controller.clear();

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      await loadTasks();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add task: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> toggleTask(
    Map<String, dynamic> task,
  ) async {
    final db = await AppDatabase.database;

    final completed = task['completed'] == 1 ? 0 : 1;

    await db.update(
      'todos',
      {'completed': completed},
      where: 'id = ?',
      whereArgs: [task['id']],
    );

    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
          'Are you sure you want to delete this task?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final db = await AppDatabase.database;

    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );

    await loadTasks();
  }

  void showAddTaskDialog() {
    controller.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Task'),
              content: TextField(
                controller: controller,
                autofocus: true,
                enabled: !isSaving,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Enter task name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  addTask(dialogContext);
                  setDialogState(() {});
                },
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          addTask(dialogContext);
                          setDialogState(() {});
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = tasks
        .where((task) => task['completed'] != 1)
        .toList();

    final completedTasks = tasks
        .where((task) => task['completed'] == 1)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(
                avatar: const Icon(
                  Icons.pending_actions,
                  size: 18,
                ),
                label: Text('$pendingCount Pending'),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadTasks,
              child: tasks.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 180),
                        Icon(
                          Icons.checklist_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No tasks yet.',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Add your first task.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        16, 16, 16, 100,
                      ),
                      children: [
                        Text(
                          'Pending ($pendingCount)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...pendingTasks.map(buildTaskTile),
                        const SizedBox(height: 20),
                        Text(
                          'Completed ($completedCount)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...completedTasks.map(buildTaskTile),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildTaskTile(Map<String, dynamic> task) {
    final completed = task['completed'] == 1;

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: completed,
          onChanged: (_) => toggleTask(task),
        ),
        title: Text(
          task['title']?.toString() ?? '',
          style: TextStyle(
            decoration: completed
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: completed ? Colors.grey : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => deleteTask(task['id'] as int),
        ),
      ),
    );
  }
}
