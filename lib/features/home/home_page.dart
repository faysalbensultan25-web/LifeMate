
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
  String name = 'LifeMate';
  String occupation = '';
  String workplace = '';
  String? photo;

  double income = 0;
  double expense = 0;

  int todos = 0;
  int notes = 0;

  List<Map<String, dynamic>> recent = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final db = await AppDatabase.database;

    final p = await db.query('profiles', limit: 1);

    String newName = 'LifeMate';
    String newOccupation = '';
    String newWorkplace = '';
    String? newPhoto;

    if (p.isNotEmpty) {
      newName = (p.first['name'] ?? 'LifeMate').toString();
      newOccupation = (p.first['occupation'] ?? '').toString();
      newWorkplace = (p.first['workplace'] ?? '').toString();
      newPhoto = p.first['photo_path']?.toString();
    }

    final ts = await db.query(
      'todos',
      where: 'completed = ?',
      whereArgs: [0],
    );

    final ns = await db.query('notes');
    final ins = await db.query('incomes');
    final exs = await db.query('expenses');

    final newIncome = ins.fold<double>(
      0,
      (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0),
    );

    final newExpense = exs.fold<double>(
      0,
      (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0),
    );

    final activities = <Map<String, dynamic>>[];

    for (final x in ts.take(3)) {
      activities.add({
        'i': Icons.check_circle,
        't': x['title'],
        's': 'To-Do',
      });
    }

    for (final x in ns.take(3)) {
      activities.add({
        'i': Icons.note_alt,
        't': x['title'],
        's': 'Note',
      });
    }

    for (final x in ins.take(3)) {
      activities.add({
        'i': Icons.arrow_downward,
        't': x['description'] ?? 'Income',
        's': '+ ৳${x['amount']}',
      });
    }

    for (final x in exs.take(3)) {
      activities.add({
        'i': Icons.arrow_upward,
        't': x['description'] ?? 'Expense',
        's': '- ৳${x['amount']}',
      });
    }

    if (!mounted) return;

    setState(() {
      name = newName;
      occupation = newOccupation;
      workplace = newWorkplace;
      photo = newPhoto;

      income = newIncome;
      expense = newExpense;

      todos = ts.length;
      notes = ns.length;

      recent = activities.take(5).toList();
    });
  }

  Future<void> go(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (mounted) load();
  }

  // SEARCH

  void search() {
    final c = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search LifeMate'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: c,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'To-Do, Notes, Income, Expense...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (v) {
              Navigator.pop(ctx);
              showResults(v);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              showResults(c.text);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> searchTable(
    dynamic db,
    String table,
    String query,
  ) async {
    final allowedTables = [
      'todos',
      'notes',
      'incomes',
      'expenses',
    ];

    if (!allowedTables.contains(table)) return [];

    final columns = await db.rawQuery(
      'PRAGMA table_info($table)',
    );

    if (columns.isEmpty) return [];

    final conditions = <String>[];
    final args = <dynamic>[];

    for (final column in columns) {
      final columnName = column['name'].toString();

      if (columnName == 'id') continue;

      conditions.add('CAST("$columnName" AS TEXT) LIKE ?');
      args.add('%$query%');
    }

    if (conditions.isEmpty) return [];

    return await db.query(
      table,
      where: conditions.join(' OR '),
      whereArgs: args,
      limit: 100,
    );
  }

  Future<void> showResults(String q) async {
    if (q.trim().isEmpty) return;

    final db = await AppDatabase.database;
    final key = q.trim();

    final results = <Map<String, dynamic>>[];

    final tables = [
      {'table': 'todos', 'type': 'To-Do'},
      {'table': 'notes', 'type': 'Note'},
      {'table': 'incomes', 'type': 'Income'},
      {'table': 'expenses', 'type': 'Expense'},
    ];

    for (final item in tables) {
      final data = await searchTable(
        db,
        item['table']!,
        key,
      );

      for (final row in data) {
        final title = row['title'] ??
            row['description'] ??
            row['content'] ??
            row['amount'] ??
            item['type'];

        final details = <String>[];

        if (row['description'] != null &&
            row['description'].toString().isNotEmpty &&
            row['description'].toString() != title.toString()) {
          details.add(row['description'].toString());
        }

        if (row['content'] != null &&
            row['content'].toString().isNotEmpty) {
          details.add(row['content'].toString());
        }

        if (row['amount'] != null) {
          details.add('৳ ${row['amount']}');
        }

        if (row['date'] != null) {
          details.add(row['date'].toString());
        }

        results.add({
          'type': item['type'],
          'title': title.toString(),
          'details': details.join(' • '),
        });
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Search Results (${results.length})'),
        content: SizedBox(
          width: 400,
          child: results.isEmpty
              ? const Text('No result found.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];

                    IconData icon = Icons.search;

                    switch (item['type']) {
                      case 'To-Do':
                        icon = Icons.check_circle;
                        break;
                      case 'Note':
                        icon = Icons.note_alt;
                        break;
                      case 'Income':
                        icon = Icons.arrow_downward;
                        break;
                      case 'Expense':
                        icon = Icons.arrow_upward;
                        break;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(icon),
                      ),
                      title: Text(item['title']),
                      subtitle: Text(
                        '${item['type']}'
                        '${item['details'].toString().isNotEmpty ? ' • ${item['details']}' : ''}',
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // MORE MENU

  void more() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            item(Icons.event, 'Events', () => go(const EventsPage())),
            item(Icons.bar_chart, 'Statistics', () => go(const StatisticsPage())),
            item(Icons.savings, 'Budget', () => go(const BudgetPage())),
            item(Icons.picture_as_pdf, 'PDF Reports', () => go(const PdfReportsPage())),
            item(Icons.person, 'Profile', () => go(const ProfilePage())),
            item(Icons.settings, 'Settings', () => go(const SettingsPage())),
          ],
        ),
      ),
    );
  }

  Widget item(IconData i, String t, VoidCallback f) {
    return ListTile(
      leading: Icon(i),
      title: Text(t),
      onTap: () {
        Navigator.pop(context);
        f();
      },
    );
  }

  Widget avatar() {
    if (photo != null &&
        photo!.isNotEmpty &&
        File(photo!).existsSync()) {
      return CircleAvatar(
        radius: 35,
        backgroundImage: FileImage(File(photo!)),
      );
    }

    return const CircleAvatar(
      radius: 35,
      child: Icon(Icons.person, size: 38),
    );
  }

  Widget badge(Widget child, int n) {
    return Badge(
      isLabelVisible: n > 0,
      label: Text('$n'),
      child: child,
    );
  }

  Widget quick(
    String t,
    IconData i,
    Color c,
    VoidCallback f, {
    int count = 0,
  }) {
    return Expanded(
      child: InkWell(
        onTap: f,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 105,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.withOpacity(.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              badge(Icon(i, size: 34, color: c), count),
              const SizedBox(height: 7),
              Text(
                t,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget card({
    required Widget child,
    Color? color,
  }) {
    return Card(
      color: color,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }

  Widget money(String title, double value, Color c) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.withOpacity(.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                '৳ ${value.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.eco, color: Colors.green),
            const SizedBox(width: 7),
            const Text(
              'LifeMate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: search,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: more,
            icon: const Icon(Icons.settings_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => go(const ProfilePage()),
              child: avatar(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
          children: [
            card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  avatar(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (occupation.isNotEmpty) Text(occupation),
                        if (workplace.isNotEmpty) Text(workplace),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => go(const ProfilePage()),
                    child: const Text('Profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            card(
              child: Row(
                children: [
                  const Icon(Icons.search, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Search anything...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  IconButton(
                    onPressed: search,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                quick(
                  'To-Do',
                  Icons.check_circle,
                  Colors.blue,
                  () => go(const TodoPage()),
                  count: todos,
                ),
                quick(
                  'Notes',
                  Icons.note_alt,
                  Colors.green,
                  () => go(const NotesPage()),
                  count: notes,
                ),
                quick(
                  'Income',
                  Icons.account_balance_wallet,
                  Colors.green,
                  () => go(const FinancePage()),
                ),
              ],
            ),
            Row(
              children: [
                quick(
                  'Expense',
                  Icons.wallet,
                  Colors.red,
                  () => go(const FinancePage()),
                ),
                quick(
                  'Events',
                  Icons.event,
                  Colors.purple,
                  () => go(const EventsPage()),
                ),
                quick(
                  'More',
                  Icons.apps,
                  Colors.indigo,
                  more,
                ),
              ],
            ),
            const SizedBox(height: 8),
            card(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: load,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                  if (recent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(15),
                      child: Text('No recent activity'),
                    ),
                  ...recent.map(
                    (x) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        child: Icon(x['i'], size: 18),
                      ),
                      title: Text('${x['t']}'),
                      subtitle: Text('${x['s']}'),
                    ),
                  ),
                ],
              ),
            ),
            card(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Finance Summary',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text('All'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      money('Income', income, Colors.green),
                      money('Expense', expense, Colors.red),
                      money('Balance', balance, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            card(
              color: Colors.amber.shade50,
              child: Row(
                children: [
                  const Icon(
                    Icons.track_changes,
                    color: Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Open Budget for details'),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => go(const BudgetPage()),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
            if (todos > 0)
              card(
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Badge(
                      label: Text('$todos'),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$todos pending To-Do task${todos == 1 ? '' : 's'}',
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: badge(const Icon(Icons.check_circle_outline), todos),
            selectedIcon: badge(const Icon(Icons.check_circle), todos),
            label: 'To-Do',
          ),
          const NavigationDestination(
            icon: Icon(Icons.arrow_downward),
            selectedIcon: Icon(Icons.arrow_downward),
            label: 'Income',
          ),
          const NavigationDestination(
            icon: Icon(Icons.arrow_upward),
            selectedIcon: Icon(Icons.arrow_upward),
            label: 'Expense',
          ),
          NavigationDestination(
            icon: badge(const Icon(Icons.note_alt_outlined), notes),
            selectedIcon: badge(const Icon(Icons.note_alt), notes),
            label: 'Notes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
        onDestinationSelected: (i) {
          if (i == 1) go(const TodoPage());
          if (i == 2) go(const FinancePage());
          if (i == 3) go(const FinancePage());
          if (i == 4) go(const NotesPage());
          if (i == 5) more();
        },
      ),
    );
  }
}
