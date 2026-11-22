import 'package:flutter/material.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController controller = TextEditingController();

  void addTask() {
    final title = controller.text.trim();

    if (title.isEmpty) return;

    setState(() {
      tasks.add({
        'title': title,
        'completed': false,
      });
    });

    controller.clear();
    Navigator.pop(context);
  }

  void showAddTaskDialog() {
    controller.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter task name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
        tasks.where((task) => !task['completed']).toList();

    final completedTasks =
        tasks.where((task) => task['completed']).toList();

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
                ...pendingTasks.map((task) => buildTaskTile(task)),
                const SizedBox(height: 20),
                Text(
                  'Completed (${completedTasks.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...completedTasks.map((task) => buildTaskTile(task)),
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
          value: task['completed'] as bool,
          onChanged: (value) {
            setState(() {
              task['completed'] = value ?? false;
            });
          },
        ),
        title: Text(
          task['title'] as String,
          style: TextStyle(
            decoration: task['completed']
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            setState(() {
              tasks.remove(task);
            });
          },
        ),
      ),
    );
  }
}
