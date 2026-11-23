import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../notes/notes_page.dart';
import '../todo/todo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  List<Map<String, dynamic>> recentActivities = [];
  bool loadingActivities = true;

  @override
  void initState() {
    super.initState();
    loadRecentActivities();
  }

  Future<void> loadRecentActivities() async {
    try {
      final db = await AppDatabase.database;

      final todos = await db.query(
        'todos',
        orderBy: 'id DESC',
        limit: 5,
      );

      final notes = await db.query(
        'notes',
        orderBy: 'id DESC',
        limit: 5,
      );

      final activities = <Map<String, dynamic>>[];

      for (final todo in todos) {
        activities.add({
          'type': 'todo',
          'title': todo['title'] as String,
          'subtitle': todo['completed'] == 1
              ? 'Task completed'
              : 'Task added',
          'date': todo['created_at'] as String,
        });
      }

      for (final note in notes) {
        activities.add({
          'type': 'note',
          'title': note['title'] as String,
          'subtitle': 'Note created',
          'date': note['created_at'] as String,
        });
      }

      activities.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] as String);
        final dateB = DateTime.tryParse(b['date'] as String);

        if (dateA == null || dateB == null) {
          return 0;
        }

        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        recentActivities = activities.take(6).toList();
        loadingActivities = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loadingActivities = false;
      });
    }
  }

  Future<void> openTodo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TodoPage(),
      ),
    );

    await loadRecentActivities();
  }

  Future<void> openNotes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotesPage(),
      ),
    );

    await loadRecentActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LifeMate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadRecentActivities,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _featureCard(
                  title: 'To-Do',
                  icon: Icons.task_alt,
                  active: true,
                  onTap: openTodo,
                ),
                _featureCard(
                  title: 'Finance',
                  icon: Icons.account_balance_wallet,
                ),
                _featureCard(
                  title: 'Notes',
                  icon: Icons.note_alt,
                  active: true,
                  onTap: openNotes,
                ),
                _featureCard(
                  title: 'Events',
                  icon: Icons.event,
                ),
                _featureCard(
                  title: 'Statistics',
                  icon: Icons.bar_chart,
                ),
                _featureCard(
                  title: 'Budget',
                  icon: Icons.savings,
                ),
                _featureCard(
                  title: 'Profile',
                  icon: Icons.person,
                ),
                _featureCard(
                  title: 'PDF Reports',
                  icon: Icons.picture_as_pdf,
                ),
                _featureCard(
                  title: 'Backup',
                  icon: Icons.backup,
                ),
                _featureCard(
                  title: 'Settings
