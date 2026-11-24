import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../home/home_page.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Map<String, dynamic>> tasks = [];

  final TextEditingController controller = TextEditingController();

  int currentIndex = 1;
  bool isSaving = false;

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

  Future<void> addTask(
    BuildContext dialogContext,
  ) async {
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

    setState(() {
      isSaving = true;
    });

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
        SnackBar(
          content: Text('Could not add task: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> toggleTask(
    Map<String, dynamic> task,
  ) async {
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
                },
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
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
                          width: 18,
                          height: 18,
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

  void handleNavigation(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
      return;
    }

    if (index == 1) {
      return;
    }

    if (index == 2) {
      showAddTaskDialog();
      return;
    }

    if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerts will be available here.'),
        ),
      );
      return;
    }

    if (index == 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('More options will be available here.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = tasks
        .where(
          (task) => task['completed'] == 0,
        )
        .toList();

    final completedTasks = tasks
        .where(
          (task) => task['completed'] == 1,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),

      body: tasks.isEmpty
          ? RefreshIndicator(
              onRefresh: loadTasks,
              child: ListView(
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
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: loadTasks,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  100,
                ),
                children: [
                  Text(
                    'Pending (${pendingTasks.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...pendingTasks.map(
                    buildTaskTile,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Completed (${completedTasks.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...completedTasks.map(
                    buildTaskTile,
                  ),
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: handleNavigation,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'To-Do',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget buildTaskTile(
    Map<String, dynamic> task,
  ) {
    final completed = task['completed'] == 1;

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: completed,
          onChanged: (_) => toggleTask(task),
        ),
        title: Text(
          task['title'] as String,
          style: TextStyle(
            decoration: completed
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: completed
                ? Colors.grey
                : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
          ),
          onPressed: () {
            deleteTask(
              task['id'] as int,
            );
          },
        ),
      ),
    );
  }
}
