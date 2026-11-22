
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Map<String, dynamic>> tasks = [];
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'todos',
      orderBy: 'id DESC',
    );

    if (!mounted) return;

    setState(() {
      tasks = result;
    });
  }

  Future<void> addTask() async {
    final title = controller.text.trim();

    if (title.isEmpty) return;

    final db = await AppDatabase.database;

    await db.insert('todos', {
      'title': title,
      'completed': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    controller.clear();

    if (mounted) {
      Navigator.pop(context);
    }

    await loadTasks();
  }

  Future<void> toggleTask(Map<String, dynamic> task) async {
    final db = await AppDatabase.database;

    await db.update(
      'todos',
      {
        'completed': task['completed'] == 1 ? 0 : 1,
      },
      where: 'id = ?',
      whereArgs: [task['id']],
    );

    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter task name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => addTask(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: addTask,
              child: const Text('Add'),
            ),
          ],
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
    final pendingTasks =
        tasks.where((task) => task['completed'] == 0).toList();

    final completedTasks =
        tasks.where((task) => task['completed'] == 1).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),
      body: tasks.isEmpty
          ? const Center(
              child: Text('No tasks yet. Add your first task!'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Pending (${pendingTasks.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...pendingTasks.map(buildTaskTile),
                const SizedBox(height: 20),
                Text(
                  'Completed (${completedTasks.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...completedTasks.map(buildTaskTile),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildTaskTile(Map<String, dynamic> task) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: task['completed'] == 1,
          onChanged: (_) => toggleTask(task),
        ),
        title: Text(
          task['title'] as String,
          style: TextStyle(
            decoration: task['completed'] == 1
                ? TextDecoration.lineThrough
                : TextDecoration.none,
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
