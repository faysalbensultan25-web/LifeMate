import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../events/events_page.dart';
import '../finance/finance_page.dart';
import '../notes/notes_page.dart';
import '../profile/profile_page.dart';
import '../reports/pdf_reports_page.dart';
import '../statistics/budget_page.dart';
import '../statistics/statistics_page.dart';
import '../todo/todo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  List<Map<String, dynamic>> activities = [];

  String? profilePhotoPath;
  String? profileName;

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    await Future.wait([
      loadActivities(),
      loadProfile(),
    ]);
  }

  Future<void> loadProfile() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'profiles',
      orderBy: 'id ASC',
      limit: 1,
    );

    String? newPhotoPath;
    String? newProfileName;

    if (result.isNotEmpty) {
      final profile = result.first;

      final savedPhoto = profile['photo_path']?.toString();
      final savedName = profile['name']?.toString();

      if (savedPhoto != null &&
          savedPhoto.isNotEmpty &&
          File(savedPhoto).existsSync()) {
        newPhotoPath = savedPhoto;
      }

      if (savedName != null && savedName.isNotEmpty) {
        newProfileName = savedName;
      }
    }

    if (!mounted) return;

    setState(() {
      profilePhotoPath = newPhotoPath;
      profileName = newProfileName;
    });
  }

  Future<void> loadActivities() async {
    final db = await AppDatabase.database;

    final todos = await db.query(
      'todos',
      orderBy: 'id DESC',
      limit: 3,
    );

    final notes = await db.query(
      'notes',
      orderBy: 'id DESC',
      limit: 3,
    );

    final incomes = await db.query(
      'incomes',
      orderBy: 'id DESC',
      limit: 3,
    );

    final expenses = await db.query(
      'expenses',
      orderBy: 'id DESC',
      limit: 3,
    );

    final result = <Map<String, dynamic>>[];

    for (final todo in todos) {
      result.add({
        'type': 'todo',
        'title': todo['title'],
        'subtitle': 'To-Do',
        'date': todo['created_at'],
      });
    }

    for (final note in notes) {
      result.add({
        'type': 'note',
        'title': note['title'],
        'subtitle': 'Note',
        'date': note['created_at'],
      });
    }

    for (final income in incomes) {
      result.add({
        'type': 'income',
        'title': 'Income: ৳${income['amount']}',
        'subtitle': income['description'] ?? 'Income',
        'date': income['created_at'],
      });
    }

    for (final expense in expenses) {
      result.add({
        'type': 'expense',
        'title': 'Expense: ৳${expense['amount']}',
        'subtitle': expense['description'] ?? 'Expense',
        'date': expense['created_at'],
      });
    }

    result.sort((a, b) {
      final aDate = DateTime.tryParse(a['date'] as String);
      final bDate = DateTime.tryParse(b['date'] as String);

      if (aDate == null || bDate == null) {
        return 0;
      }

      return bDate.compareTo(aDate);
    });

    if (!mounted) return;

    setState(() {
      activities = result.take(8).toList();
    });
  }

  Future<void> openTodo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TodoPage(),
      ),
    );

    await loadActivities();
  }

  Future<void> openNotes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotesPage(),
      ),
    );

    await loadActivities();
  }

  Future<void> openFinance() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FinancePage(),
      ),
    );

    await loadActivities();
  }

  Future<void> openEvents() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EventsPage(),
      ),
    );

    await loadActivities();
  }

  Future<void> openStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StatisticsPage(),
      ),
    );

    await loadActivities();
  }

  Future<void> openBudget() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BudgetPage(),
      ),
    );

    await loadActivities();
  }

  Future<void> openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfilePage(),
      ),
    );

    // Reload profile photo and name after returning.
    await loadProfile();
    await loadActivities();
  }

  Future<void> openPdfReports() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PdfReportsPage(),
      ),
    );

    await loadActivities();
  }

  Widget _profileHomeIcon() {
    final hasPhoto =
        profilePhotoPath != null &&
        profilePhotoPath!.isNotEmpty &&
        File(profilePhotoPath!).existsSync();

    if (hasPhoto) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: FileImage(
          File(profilePhotoPath!),
        ),
      );
    }

    return const Icon(
      Icons.account_circle_outlined,
    );
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
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),
          IconButton(
            onPressed: openProfile,
            icon: _profileHomeIcon(),
            tooltip: profileName ?? 'Profile',
          ),
        ],
      ),

      body: ListView(
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
                'To-Do',
                Icons.task_alt,
                true,
                openTodo,
              ),
              _featureCard(
                'Finance',
                Icons.account_balance_wallet,
                true,
                openFinance,
              ),
              _featureCard(
                'Notes',
                Icons.note_alt,
                true,
                openNotes,
              ),
              _featureCard(
                'Events',
                Icons.event,
                true,
                openEvents,
              ),
              _featureCard(
                'Statistics',
                Icons.bar_chart,
                true,
                openStatistics,
              ),
              _featureCard(
                'Budget',
                Icons.savings,
                true,
                openBudget,
              ),
              _featureCard(
                'Profile',
                Icons.person,
                true,
                openProfile,
              ),
              _featureCard(
                'PDF Reports',
                Icons.picture_as_pdf,
                true,
                openPdfReports,
              ),
              _featureCard(
                'Backup',
                Icons.backup,
                false,
                null,
              ),
              _featureCard(
                'Settings',
                Icons.settings,
                false,
                null,
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

          if (activities.isEmpty)
            _emptyActivity()
          else
            ...activities.map(_activityCard),

          const SizedBox(height: 8),

          _financeCard(),
        ],
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

  Widget _featureCard(
    String title,
    IconData icon,
    bool active,
    VoidCallback? onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 38,
              color: active
                  ? const Color(0xFF1877F2)
                  : Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              active ? 'Open' : 'Coming soon',
              style: TextStyle(
                fontSize: 11,
                color: active
                    ? const Color(0xFF1877F2)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityCard(
    Map<String, dynamic> activity,
  ) {
    final type = activity['type'] as String;

    final isTodo = type == 'todo';
    final isNote = type == 'note';
    final isIncome = type == 'income';

    final icon = isTodo
        ? Icons.task_alt
        : isNote
            ? Icons.note_alt
            : isIncome
                ? Icons.trending_up
                : Icons.trending_down;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: isTodo
            ? openTodo
            : isNote
                ? openNotes
                : openFinance,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE7F0FF),
          child: Icon(
            icon,
            color: const Color(0xFF1877F2),
          ),
        ),
        title: Text(
          activity['title'] as String,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          activity['subtitle'] as String,
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }

  Widget _emptyActivity() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No recent activity',
          ),
        ),
      ),
    );
  }

  Widget _financeCard() {
    return Card(
      child: ListTile(
        onTap: openFinance,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE7F0FF),
          child: Icon(
            Icons.account_balance_wallet,
            color: Color(0xFF1877F2),
          ),
        ),
        title: const Text(
          'Finance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          'Manage your income and expenses',
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }
}
