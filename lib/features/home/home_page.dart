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

  // ------------------------------------------------------------
  // QUICK ADD
  // ------------------------------------------------------------

  void showQuickAdd() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quick Add',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _quickAddTile(
                  sheetContext,
                  'To-Do',
                  Icons.check_circle_outline,
                  () {
                    Navigator.pop(sheetContext);
                    openTodo();
                  },
                ),

                _quickAddTile(
                  sheetContext,
                  'Income',
                  Icons.trending_up,
                  () {
                    Navigator.pop(sheetContext);
                    openFinance();
                  },
                ),

                _quickAddTile(
                  sheetContext,
                  'Expense',
                  Icons.trending_down,
                  () {
                    Navigator.pop(sheetContext);
                    openFinance();
                  },
                ),

                _quickAddTile(
                  sheetContext,
                  'Note',
                  Icons.note_alt_outlined,
                  () {
                    Navigator.pop(sheetContext);
                    openNotes();
                  },
                ),

                _quickAddTile(
                  sheetContext,
                  'Event',
                  Icons.event_outlined,
                  () {
                    Navigator.pop(sheetContext);
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

  Widget _quickAddTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE7F0FF),
        child: Icon(
          icon,
          color: const Color(0xFF1877F2),
        ),
      ),
      title: Text(title),
      trailing: const Icon(
        Icons.chevron_right,
      ),
      onTap: onTap,
    );
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> searchAll(
    String query,
  ) async {
    final text = query.trim();

    if (text.isEmpty) return [];

    final db = await AppDatabase.database;
    final pattern = '%$text%';

    final result = <Map<String, dynamic>>[];

    final todos = await db.query(
      'todos',
      where: 'title LIKE ?',
      whereArgs: [pattern],
      orderBy: 'id DESC',
      limit: 20,
    );

    for (final item in todos) {
      result.add({
        'type': 'To-Do',
        'title': item['title'],
        'subtitle': 'To-Do',
        'action': 'todo',
      });
    }

    final notes = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: 'id DESC',
      limit: 20,
    );

    for (final item in notes) {
      result.add({
        'type': 'Note',
        'title': item['title'],
        'subtitle': item['content'],
        'action': 'note',
      });
    }

    final incomes = await db.query(
      'incomes',
      where: 'description LIKE ?',
      whereArgs: [pattern],
      orderBy: 'id DESC',
      limit: 20,
    );

    for (final item in incomes) {
      result.add({
        'type': 'Income',
        'title': 'Income: ৳${item['amount']}',
        'subtitle': item['description'] ?? 'Income',
        'action': 'finance',
      });
    }

    final expenses = await db.query(
      'expenses',
      where: 'description LIKE ?',
      whereArgs: [pattern],
      orderBy: 'id DESC',
      limit: 20,
    );

    for (final item in expenses) {
      result.add({
        'type': 'Expense',
        'title': 'Expense: ৳${item['amount']}',
        'subtitle': item['description'] ?? 'Expense',
        'action': 'finance',
      });
    }

    final events = await db.query(
      'events',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: 'id DESC',
      limit: 20,
    );

    for (final item in events) {
      result.add({
        'type': 'Event',
        'title': item['title'],
        'subtitle': item['description'] ?? 'Event',
        'action': 'events',
      });
    }

    return result;
  }

  void openSearch() {
    final searchController = TextEditingController();

    showSearchResults(searchController);
  }

  void showSearchResults(
    TextEditingController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                          16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.78,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Search LifeMate',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: controller,
                        autofocus: true,
                        onChanged: (_) {
                          setSheetState(() {});
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Search To-Do, Notes, Finance, Events...',
                          prefixIcon:
                              const Icon(Icons.search),
                          suffixIcon: controller.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    controller.clear();
                                    setSheetState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.clear,
                                  ),
                                ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: FutureBuilder<
                            List<Map<String, dynamic>>>(
                          future: searchAll(
                            controller.text,
                          ),
                          builder: (
                            context,
                            snapshot,
                          ) {
                            if (controller.text.trim().isEmpty) {
                              return const Center(
                                child: Text(
                                  'Type something to search.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child:
                                    CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Search failed: ${snapshot.error}',
                                ),
                              );
                            }

                            final results =
                                snapshot.data ?? [];

                            if (results.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No results found.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                final item =
                                    results[index];

                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor:
                                          Color(0xFFE7F0FF),
                                      child: Icon(
                                        Icons.search,
                                        color:
                                            Color(0xFF1877F2),
                                      ),
                                    ),
                                    title: Text(
                                      item['title']
                                          .toString(),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${item['type']} • '
                                      '${item['subtitle']}',
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                    ),
                                    onTap: () {
                                      Navigator.pop(
                                        sheetContext,
                                      );

                                      _openSearchResult(
                                        item['action']
                                            .toString(),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _openSearchResult(String action) {
    if (action == 'todo') {
      openTodo();
    } else if (action == 'note') {
      openNotes();
    } else if (action == 'finance') {
      openFinance();
    } else if (action == 'events') {
      openEvents();
    }
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
            onPressed: openSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Notifications will be available here.',
                  ),
                ),
              );
            },
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
          } else if (index == 2) {
            showQuickAdd();
          } else if (index == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Notifications will be available here.',
                ),
              ),
            );
          } else if (index == 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'More options will be available here.',
                ),
              ),
            );
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
