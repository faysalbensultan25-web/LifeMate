class TodoRepository {
  final List<Map<String, dynamic>> _tasks = [];

  List<Map<String, dynamic>> getTasks() {
    return List.unmodifiable(_tasks);
  }

  void addTask(String title) {
    if (title.trim().isEmpty) return;

    _tasks.add({
      'id': DateTime.now().microsecondsSinceEpoch,
      'title': title.trim(),
      'completed': false,
    });
  }

  void updateTask(int id, String title) {
    final index = _tasks.indexWhere((task) => task['id'] == id);

    if (index == -1 || title.trim().isEmpty) return;

    _tasks[index]['title'] = title.trim();
  }

  void toggleTask(int id) {
    final index = _tasks.indexWhere((task) => task['id'] == id);

    if (index == -1) return;

    _tasks[index]['completed'] =
        !(_tasks[index]['completed'] as bool);
  }

  void deleteTask(int id) {
    _tasks.removeWhere((task) => task['id'] == id);
  }
}
