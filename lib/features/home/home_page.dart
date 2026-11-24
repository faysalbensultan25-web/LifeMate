import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../events/events_page.dart';
import '../finance/finance_page.dart';
import '../notes/notes_page.dart';
import '../profile/profile_page.dart';
import '../reports/pdf_reports_page.dart';
import '../settings/settings_page.dart';
import '../statistics/budget_page.dart';
import '../statistics/statistics_page.dart';
import '../todo/todo_page.dart';

class HomePage extends StatefulWidget {
  final String language;
  final ValueChanged<String>? onLanguageChanged;

  const HomePage({
    super.key,
    this.language = 'English',
    this.onLanguageChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String profileName = 'LifeMate';
  String? profilePhoto;

  List<Map<String, dynamic>> recentActivities = [];

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    final db = await AppDatabase.database;

    final profiles = await db.query(
      'profiles',
      orderBy: 'id ASC',
      limit: 1,
    );

    if (profiles.isNotEmpty) {
      final profile = profiles.first;

      final name = profile['name']?.toString().trim();
      final photo = profile['photo_path']?.toString();

      if (mounted) {
        setState(() {
          profileName =
              name != null && name.isNotEmpty ? name : 'LifeMate';

          profilePhoto =
              photo != null && photo.isNotEmpty ? photo : null;
        });
      }
    }

    await loadRecentActivities();
  }

  Future<void> loadRecentActivities() async {
    final db = await AppDatabase.database;

    final List<Map<String, dynamic>> activities = [];

    final todos = await db.query(
      'todos',
      orderBy: 'id DESC',
      limit: 5,
    );

    for (final todo in todos) {
      activities.add({
        'type': 'todo',
        'title': todo['title']?.toString() ?? 'To-Do',
        'subtitle':
            todo['is_completed'] == 1 ? 'Completed' : 'Pending',
        'date': todo['created_at']?.toString() ?? '',
        'icon': Icons.task_alt,
      });
    }

    final notes = await db.query(
      'notes',
      orderBy: 'id DESC',
      limit: 5,
    );

    for (final note in notes) {
      activities.add({
        'type': 'note',
        'title': note['title']?.toString() ?? 'Note',
        'subtitle': 'Note',
        'date': note['created_at']?.toString() ?? '',
        'icon': Icons.note_alt,
      });
    }

    final incomes = await db.query(
      'incomes',
      orderBy: 'id DESC',
      limit: 5,
    );

    for (final income in incomes) {
      activities.add({
        'type': 'income',
        'title': income['description']?.toString() ??
            income['category']?.toString() ??
            'Income',
        'subtitle': 'Income: ${income['amount'] ?? 0}',
        'date': income['date']?.toString() ?? '',
        'icon': Icons.arrow_downward,
      });
    }

    final expenses = await db.query(
      'expenses',
      orderBy: 'id DESC',
      limit: 5,
    );

    for (final expense in expenses) {
      activities.add({
        'type': 'expense',
        'title': expense['description']?.toString() ??
            expense['category']?.toString() ??
            'Expense',
        'subtitle': 'Expense: ${expense['amount'] ?? 0}',
        'date': expense['date']?.toString() ?? '',
        'icon': Icons.arrow_upward,
      });
    }

    activities.sort((a, b) {
      final aDate = DateTime.tryParse(
        a['date']?.toString() ?? '',
      );
      final bDate = DateTime.tryParse(
        b['date']?.toString() ?? '',
      );

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    if (mounted) {
      setState(() {
        recentActivities = activities.take(10).toList();
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
    await loadHomeData();
  }

  Future<void> openNotes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotesPage(),
      ),
    );
    await loadHomeData();
  }

  Future<void> openFinance() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FinancePage(),
      ),
    );
    await loadHomeData();
  }

  Future<void> openEvents() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EventsPage(),
      ),
    );
    await loadHomeData();
  }

  Future<void> openStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StatisticsPage(),
      ),
    );
    await loadHomeData();
  }

  Future<void> openBudget() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BudgetPage(),
      ),
    );
    await loadHomeData();
  }

  Future<void> openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfilePage(),
      ),
    );
    await loadHomeData();
  }

  Future<void> openPdfReports() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PdfReportsPage(),
      ),
    );
  }

  Future<void> openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
    await loadHomeData();
  }

  void showQuickAdd() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quick Add',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.task_alt),
                  title: const Text('Add To-Do'),
                  onTap: () {
                    Navigator.pop(context);
                    openTodo();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.account_balance_wallet),
                  title: const Text('Add Finance'),
                  onTap: () {
                    Navigator.pop(context);
                    openFinance();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.note_alt),
                  title: const Text('Add Note'),
                  onTap: () {
                    Navigator.pop(context);
                    openNotes();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Add Event'),
                  onTap: () {
                    Navigator.pop(context);
                    openEvents();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showSearchPanel() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Search LifeMate',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText:
                      'Search To-Do, Notes, Finance, Events',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Search results will appear here.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  void showAlerts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Notifications will be available here.'),
      ),
    );
  }

  void showMore() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  openProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  openSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF Reports'),
                onTap: () {
                  Navigator.pop(context);
                  openPdfReports();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildProfileAvatar() {
    if (profilePhoto != null &&
        profilePhoto!.isNotEmpty &&
        File(profilePhoto!).existsSync()) {
      return CircleAvatar(
        radius: 21,
        backgroundImage: FileImage(
          File(profilePhoto!),
        ),
      );
    }

    return const CircleAvatar(
      radius: 21,
      child: Icon(Icons.person),
    );
  }

  Widget featureCard(
    String title,
    IconData icon,
    bool active,
    VoidCallback? onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: active ? onTap : null,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                active ? 'Open' : 'Coming soon',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      active ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRecentActivity() {
    if (recentActivities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 42,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              const Text(
                'No recent activity',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: recentActivities.map((activity) {
          return ListTile(
            leading: CircleAvatar(
              child: Icon(
                activity['icon'] as IconData,
                size: 20,
              ),
            ),
            title: Text(
              activity['title']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              activity['subtitle']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LifeMate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: showSearchPanel,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: showAlerts,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: openProfile,
              child: buildProfileAvatar(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadHomeData,
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    buildProfileAvatar(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profileName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                featureCard(
                  'To-Do',
                  Icons.task_alt,
                  true,
                  openTodo,
                ),
                featureCard(
                  'Finance',
                  Icons.account_balance_wallet,
                  true,
                  openFinance,
                ),
                featureCard(
                  'Notes',
                  Icons.note_alt,
                  true,
                  openNotes,
                ),
                featureCard(
                  'Events',
                  Icons.event,
                  true,
                  openEvents,
                ),
                featureCard(
                  'Statistics',
                  Icons.bar_chart,
                  true,
                  openStatistics,
                ),
                featureCard(
                  'Budget',
                  Icons.savings,
                  true,
                  openBudget,
                ),
                featureCard(
                  'Profile',
                  Icons.person,
                  true,
                  openProfile,
                ),
                featureCard(
                  'PDF Reports',
                  Icons.picture_as_pdf,
                  true,
                  openPdfReports,
                ),
                featureCard(
                  'Backup',
                  Icons.backup,
                  false,
                  null,
                ),
                featureCard(
                  'Settings',
                  Icons.settings,
                  true,
                  openSettings,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: loadRecentActivities,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            buildRecentActivity(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              openTodo();
              break;
            case 2:
              showQuickAdd();
              break;
            case 3:
              showAlerts();
              break;
            case 4:
              showMore();
              break;
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
}
