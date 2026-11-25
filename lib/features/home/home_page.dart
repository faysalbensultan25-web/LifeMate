
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/services/notification_service.dart';
import '../events/events_page.dart';
import '../finance/finance_page.dart';
import '../notes/notes_page.dart';
import '../notifications/notifications_page.dart';
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
  int unreadNotifications = 0;

  List<Map<String, dynamic>> recent = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final db = await AppDatabase.database;

    await NotificationService.generateAlerts();

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
      orderBy: 'id DESC',
    );

    final ns = await db.query('notes', orderBy: 'id DESC');
    final ins = await db.query('incomes', orderBy: 'id DESC');
    final exs = await db.query('expenses', orderBy: 'id DESC');

    final newIncome = ins.fold<double>(
      0,
      (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0),
    );

    final newExpense = exs.fold<double>(
      0,
      (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0),
    );

    final unread = await NotificationService.unreadCount();

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
      unreadNotifications = unread;
      recent = activities.take(5).toList();
    });
  }

  Future<void> go(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (mounted) await load();
  }

  void openNotifications() => go(const NotificationsPage());

  void search() {
    final c = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search LifeMate'),
        content: TextField(
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
    const allowedTables = ['todos', 'notes', 'incomes', 'expenses'];

    if (!allowedTables.contains(table)) return [];

    final columns = await db.rawQuery('PRAGMA table_info($table)');
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
    final results = <Map<String, dynamic>>[];

    final tables = [
      {'table': 'todos', 'type': 'To-Do'},
      {'table': 'notes', 'type': 'Note'},
      {'table': 'incomes', 'type': 'Income'},
      {'table': 'expenses', 'type': 'Expense'},
    ];

    for (final item in tables) {
      final data = await searchTable(db, item['table']!, q.trim());

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

  void more() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            item(Icons.event, 'Events', () => go(const EventsPage())),
            item(Icons.bar_chart, 'Statistics',
                () => go(const StatisticsPage())),
            item(Icons.savings, 'Budget', () => go(const BudgetPage())),
            item(Icons.picture_as_pdf, 'PDF Reports',
                () => go(const PdfReportsPage())),
            item(Icons.person, 'Profile', () => go(const ProfilePage())),
            item(Icons.settings, 'Settings',
                () => go(const SettingsPage())),
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

  Widget avatar({double radius = 25}) {
    if (photo != null &&
        photo!.isNotEmpty &&
        File(photo!).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(photo!)),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withOpacity(.25),
      child: Icon(Icons.person, size: radius * 1.2, color: Colors.white),
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
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int count = 0,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                badge(
                  Icon(icon, size: 23, color: color),
                  count,
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget sectionCard({
    required Widget child,
    Color? color,
  }) {
    return Card(
      color: color,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: child,
      ),
    );
  }

  Widget money(String title, double value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                '৳ ${value.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
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
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              height: 39,
              width: 39,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6655D9), Color(0xFF29B6A6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LifeMate',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your Personal Life Manager',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: search,
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: openNotifications,
            icon: badge(
              const Icon(Icons.notifications_outlined),
              unreadNotifications,
            ),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: more,
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'More',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 9),
            child: GestureDetector(
              onTap: () => go(const ProfilePage()),
              child: avatar(radius: 17),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 15),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6655D9),
                    Color(0xFF3988D9),
                    Color(0xFF20B9A6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(.20),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  avatar(radius: 27),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (occupation.isNotEmpty)
                          Text(
                            occupation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        if (workplace.isNotEmpty)
                          Text(
                            workplace,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => go(const ProfilePage()),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: search,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search anything in LifeMate...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 13, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                quick(
                  'To-Do',
                  Icons.task_alt,
                  const Color(0xFF3988E8),
                  () => go(const TodoPage()),
                  count: todos,
                ),
                quick(
                  'Notes',
                  Icons.note_alt_outlined,
                  const Color(0xFF19A77A),
                  () => go(const NotesPage()),
                  count: notes,
                ),
                quick(
                  'Income',
                  Icons.trending_up,
                  const Color(0xFF159D70),
                  () => go(const FinancePage()),
                ),
              ],
            ),
            Row(
              children: [
                quick(
                  'Expense',
                  Icons.trending_down,
                  const Color(0xFFE65363),
                  () => go(const FinancePage()),
                ),
                quick(
                  'Events',
                  Icons.event_available,
                  const Color(0xFF9562D5),
                  () => go(const EventsPage()),
                ),
                quick(
                  'Alerts',
                  Icons.notifications_active_outlined,
                  const Color(0xFFEA9635),
                  openNotifications,
                  count: unreadNotifications,
                ),
              ],
            ),
            const SizedBox(height: 10),
            sectionCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          color: Color(0xFF6655D9)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Finance Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => go(const FinancePage()),
                        child: const Text('Details'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      money('Income', income, const Color(0xFF159D70),
                          Icons.arrow_downward),
                      money('Expense', expense, const Color(0xFFE65363),
                          Icons.arrow_upward),
                      money('Balance', balance, const Color(0xFF3988E8),
                          Icons.account_balance),
                    ],
                  ),
                ],
              ),
            ),
            sectionCard(
              color: Theme.of(context).cardColor,
              child: InkWell(
                onTap: () => go(const BudgetPage()),
                child: Row(
                  children: [
                    Container(
                      height: 43,
                      width: 43,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726).withOpacity(.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.track_changes,
                        color: Color(0xFFEF9225),
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget Summary',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'View your budget and spending plan',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 15),
                  ],
                ),
              ),
            ),
            sectionCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: Color(0xFF3988E8)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 16,
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
                      child: Text(
                        'No recent activity',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ...recent.map(
                    (x) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 17,
                        backgroundColor: primary.withOpacity(.10),
                        child: Icon(
                          x['i'] as IconData,
                          size: 17,
                          color: primary,
                        ),
                      ),
                      title: Text(
                        '${x['t']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${x['s']}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (todos > 0 || unreadNotifications > 0)
              sectionCard(
                color: const Color(0xFFFFA726).withOpacity(.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active,
                            color: Color(0xFFEA9635)),
                        SizedBox(width: 8),
                        Text(
                          'Alerts & Reminders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (todos > 0)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.task_alt,
                            color: Colors.blue),
                        title: Text('$todos pending To-Do tasks'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => go(const TodoPage()),
                      ),
                    if (unreadNotifications > 0)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications,
                            color: Colors.orange),
                        title: Text(
                          '$unreadNotifications unread notifications',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: openNotifications,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
