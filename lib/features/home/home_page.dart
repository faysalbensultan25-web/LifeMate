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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
          'id': todo['id'],
        });
      }

      for (final note in notes) {
        activities.add({
          'type': 'note',
          'title': note['title'] as String,
          'subtitle': 'Note created',
          'date': note['created_at'] as String,
          'id': note['id'],
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

  void openTodo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TodoPage(),
      ),
    );

    await loadRecentActivities();
  }

  void openNotes() async {
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
                  title: 'Settings',
                  icon: Icons.settings,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentActivity(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });

          if (index == 1) {
            openTodo();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'To-Do',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu_open),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (loadingActivities) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (recentActivities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 40,
                color: AppThemeColor.primary,
              ),
              const SizedBox(height: 10),
              const Text(
                'No recent activity',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your recent To-Do and Notes will appear here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...recentActivities.map(
          (activity) => _activityCard(activity),
        ),
        const SizedBox(height: 4),
        _financeActivityCard(),
      ],
    );
  }

  Widget _activityCard(Map<String, dynamic> activity) {
    final isTodo = activity['type'] == 'todo';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: isTodo ? openTodo : openNotes,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE7F0FF),
          child: Icon(
            isTodo ? Icons.task_alt : Icons.note_alt,
            color: AppThemeColor.primary,
          ),
        ),
        title: Text(
          activity['title'] as String,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${isTodo ? 'To-Do' : 'Notes'} • '
          '${activity['subtitle']}',
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }

  Widget _financeActivityCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE7F0FF),
          child: Icon(
            Icons.account_balance_wallet,
            color: AppThemeColor.primary,
          ),
        ),
        title: const Text(
          'Finance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          'Finance activity will appear here',
        ),
        trailing: const Icon(
          Icons.lock_outline,
          size: 20,
        ),
      ),
    );
  }

  Widget _featureCard({
    required String title,
    required IconData icon,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16
