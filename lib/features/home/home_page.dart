vimport 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/services/language_service.dart';
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
  double receivable = 0;
  double payable = 0;

  int todos = 0;
  int notes = 0;
  int unreadNotifications = 0;

  List<Map<String, dynamic>> recent = [];

  // ============================================================
  // CURRENCY
  // ============================================================

  String currency = 'BDT (৳)';

  String get currencySymbol {
    switch (currency) {
      case 'USD (\$)':
        return '\$';

      case 'INR (₹)':
        return '₹';

      case 'SAR (﷼)':
        return '﷼';

      case 'AED (د.إ)':
        return 'د.إ';

      default:
        return '৳';
    }
  }

  String formatMoney(double value) {
    return '$currencySymbol ${value.toStringAsFixed(0)}';
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  String tr(String en, String bn, String hi, String ar) {
    return LanguageService.text(
      english: en,
      bangla: bn,
      hindi: hi,
      arabic: ar,
    );
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> load() async {
    final db = await AppDatabase.database;

    // Load selected currency from Settings.
    final prefs = await SharedPreferences.getInstance();

    final savedCurrency =
        prefs.getString('currency') ?? 'BDT (৳)';

    const supportedCurrencies = [
      'BDT (৳)',
      'USD (\$)',
      'INR (₹)',
      'SAR (﷼)',
      'AED (د.إ)',
    ];

    final selectedCurrency =
        supportedCurrencies.contains(savedCurrency)
            ? savedCurrency
            : 'BDT (৳)';

    await NotificationService.generateAlerts();

    final profiles = await db.query(
      'profiles',
      limit: 1,
    );

    String newName = 'LifeMate';
    String newOccupation = '';
    String newWorkplace = '';
    String? newPhoto;

    if (profiles.isNotEmpty) {
      newName =
          (profiles.first['name'] ?? 'LifeMate').toString();

      newOccupation =
          (profiles.first['occupation'] ?? '').toString();

      newWorkplace =
          (profiles.first['workplace'] ?? '').toString();

      newPhoto =
          profiles.first['photo_path']?.toString();
    }

    final ts = await db.query(
      'todos',
      where: 'completed = ?',
      whereArgs: [0],
      orderBy: 'id DESC',
    );

    final ns = await db.query(
      'notes',
      orderBy: 'id DESC',
    );

    final ins = await db.query(
      'incomes',
      orderBy: 'id DESC',
    );

    final exs = await db.query(
      'expenses',
      orderBy: 'id DESC',
    );

    final records = await db.query('money_records');

    final payments = await db.query('money_payments');

    final newIncome = ins.fold<double>(
      0,
      (sum, row) =>
          sum + ((row['amount'] as num?)?.toDouble() ?? 0),
    );

    final newExpense = exs.fold<double>(
      0,
      (sum, row) =>
          sum + ((row['amount'] as num?)?.toDouble() ?? 0),
    );

    final paidMap = <int, double>{};

    for (final payment in payments) {
      final id =
          (payment['record_id'] as num?)?.toInt();

      final amount =
          (payment['amount'] as num?)?.toDouble() ?? 0;

      if (id != null) {
        paidMap[id] = (paidMap[id] ?? 0) + amount;
      }
    }

    double newReceivable = 0;
    double newPayable = 0;

    for (final record in records) {
      final id =
          (record['id'] as num?)?.toInt();

      final amount =
          (record['amount'] as num?)?.toDouble() ?? 0;

      final paid =
          id == null ? 0 : (paidMap[id] ?? 0);

      final remaining =
          amount - paid > 0 ? amount - paid : 0;

      if (record['type'] == 'receivable') {
        newReceivable += remaining;
      } else if (record['type'] == 'payable') {
        newPayable += remaining;
      }
    }

    final unread =
        await NotificationService.unreadCount();

    // ==========================================================
    // RECENT ACTIVITIES
    // ==========================================================

    final activities = <Map<String, dynamic>>[];

    for (final x in ts.take(3)) {
      activities.add({
        'i': Icons.task_alt,
        't': x['title'] ?? 'To-Do',
        's': 'To-Do',
        'date': x['created_at'] ?? '',
      });
    }

    for (final x in ns.take(3)) {
      activities.add({
        'i': Icons.note_alt,
        't': x['title'] ?? 'Note',
        's': 'Note',
        'date': x['created_at'] ?? '',
      });
    }

    for (final x in ins.take(3)) {
      activities.add({
        'i': Icons.arrow_downward,
        't': x['description'] ?? 'Income',
        's': '+ $currencySymbol${x['amount']}',
        'date': x['created_at'] ?? '',
      });
    }

    for (final x in exs.take(3)) {
      activities.add({
        'i': Icons.arrow_upward,
        't': x['description'] ?? 'Expense',
        's': '- $currencySymbol${x['amount']}',
        'date': x['created_at'] ?? '',
      });
    }

    activities.sort((a, b) {
      final da = DateTime.tryParse(a['date'].toString());
      final db = DateTime.tryParse(b['date'].toString());

      if (da == null) return 1;
      if (db == null) return -1;

      return db.compareTo(da);
    });

    if (!mounted) return;

    setState(() {
      name = newName;
      occupation = newOccupation;
      workplace = newWorkplace;
      photo = newPhoto;

      income = newIncome;
      expense = newExpense;
      receivable = newReceivable;
      payable = newPayable;

      todos = ts.length;
      notes = ns.length;
      unreadNotifications = unread;

      currency = selectedCurrency;

      recent = activities.take(5).toList();
    });
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> go(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (mounted) await load();
  }

  void openNotifications() {
    go(const NotificationsPage());
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void search() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tr(
            'Search LifeMate',
            'LifeMate অনুসন্ধান',
            'LifeMate खोजें',
            'البحث في LifeMate',
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: tr(
              'To-Do, Notes, Income, Expense...',
              'কাজ, নোট, আয়, ব্যয়...',
              'कार्य, नोट्स, आय, खर्च...',
              'المهام والملاحظات والدخل والمصروفات...',
            ),
            prefixIcon: const Icon(Icons.search),
          ),
          onSubmitted: (value) {
            Navigator.pop(ctx);
            showResults(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              tr('Cancel', 'বাতিল', 'रद्द करें', 'إلغاء'),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              showResults(controller.text);
            },
            child: Text(
              tr('Search', 'খুঁজুন', 'खोजें', 'بحث'),
            ),
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
    const allowedTables = [
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

      conditions.add(
        'CAST("$columnName" AS TEXT) LIKE ?',
      );

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

  Future<void> showResults(String query) async {
    if (query.trim().isEmpty) return;

    final db = await AppDatabase.database;

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
        query.trim(),
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
          details.add(
            '$currencySymbol ${row['amount']}',
          );
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
        title: Text(
          '${tr('Search Results', 'অনুসন্ধানের ফলাফল', 'खोज परिणाम', 'نتائج البحث')} (${results.length})',
        ),
        content: SizedBox(
          width: 400,
          child: results.isEmpty
              ? Text(
                  tr(
                    'No result found.',
                    'কোনো ফলাফল পাওয়া যায়নি।',
                    'कोई परिणाम नहीं मिला।',
                    'لم يتم العثور على نتائج.',
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];

                    IconData icon = Icons.search;

                    switch (item['type']) {
                      case 'To-Do':
                        icon = Icons.task_alt;
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
            child: Text(
              tr('Close', 'বন্ধ করুন', 'बंद करें', 'إغلاق'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MORE MENU
  // ============================================================

  void more() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            item(
              Icons.event,
              'Events',
              tr('Events', 'অনুষ্ঠান', 'कार्यक्रम', 'الأحداث'),
              () => go(const EventsPage()),
            ),
            item(
              Icons.bar_chart,
              'Statistics',
              tr(
                'Statistics',
                'পরিসংখ্যান',
                'आंकड़े',
                'الإحصائيات',
              ),
              () => go(const StatisticsPage()),
            ),
            item(
              Icons.savings,
              'Budget',
              tr('Budget', 'বাজেট', 'बजट', 'الميزانية'),
              () => go(const BudgetPage()),
            ),
            item(
              Icons.picture_as_pdf,
              'PDF Reports',
              tr(
                'PDF Reports',
                'PDF প্রতিবেদন',
                'PDF रिपोर्ट',
                'تقارير PDF',
              ),
              () => go(const PdfReportsPage()),
            ),
            item(
              Icons.person,
              'Profile',
              tr(
                'Profile',
                'প্রোফাইল',
                'प्रोफ़ाइल',
                'الملف الشخصي',
              ),
              () => go(const ProfilePage()),
            ),
            item(
              Icons.settings,
              'Settings',
              tr(
                'Settings',
                'সেটিংস',
                'सेटिंग्स',
                'الإعدادات',
              ),
              () => go(const SettingsPage()),
            ),
          ],
        ),
      ),
    );
  }

  Widget item(
    IconData icon,
    String id,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

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
      child: Icon(
        Icons.person,
        size: radius * 1.2,
        color: Colors.white,
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget badge(Widget child, int count) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: child,
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

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

  // ============================================================
  // QUICK ACCESS
  // ============================================================

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
            height: 82,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(.15),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                badge(
                  Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                  count,
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  // ============================================================
  // MONEY WIDGET
  // ============================================================

  Widget money(
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                formatMoney(value),
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

  // ============================================================
  // RECEIVABLE / PAYABLE SUMMARY
  // ============================================================

  Widget moneySummary(
    String title,
    double value,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(.18),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 23,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                child: Text(
                  formatMoney(value),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;

    final netReceivable = receivable - payable;

    final primary =
        Theme.of(context).colorScheme.primary;

    final isArabic = LanguageService.isArabic;

    return Directionality(
      textDirection:
          isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
                    colors: [
                      Color(0xFF6655D9),
                      Color(0xFF29B6A6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'LifeMate',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tr(
                        'Your Personal Life Manager',
                        'আপনার ব্যক্তিগত জীবন ব্যবস্থাপক',
                        'आपका व्यक्तिगत जीवन प्रबंधक',
                        'مدير حياتك الشخصي',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
              tooltip: tr(
                'Search',
                'খুঁজুন',
                'खोजें',
                'بحث',
              ),
            ),
            IconButton(
              onPressed: openNotifications,
              icon: badge(
                const Icon(Icons.notifications_outlined),
                unreadNotifications,
              ),
              tooltip: tr(
                'Notifications',
                'বিজ্ঞপ্তি',
                'सूचनाएं',
                'الإشعارات',
              ),
            ),
            IconButton(
              onPressed: more,
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: tr(
                'More',
                'আরও',
                'अधिक',
                'المزيد',
              ),
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

        // ======================================================
        // BODY
        // ======================================================

        body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              12,
              10,
              12,
              15,
            ),
            children: [
              // ==================================================
              // WELCOME CARD
              // ==================================================

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
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(
                              'Welcome back!',
                              'স্বাগতম!',
                              'वापसी पर स्वागत है!',
                              'مرحباً بعودتك!',
                            ),
                            style: const TextStyle(
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
                      onPressed: () =>
                          go(const ProfilePage()),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // SEARCH
              // ==================================================

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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr(
                            'Search anything in LifeMate...',
                            'LifeMate-এ যেকোনো কিছু খুঁজুন...',
                            'LifeMate में कुछ भी खोजें...',
                            'ابحث عن أي شيء في LifeMate...',
                          ),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // QUICK ACCESS
              // ==================================================

              Text(
                tr(
                  'Quick Access',
                  'দ্রুত প্রবেশ',
                  'त्वरित पहुंच',
                  'الوصول السريع',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              Row(
                children: [
                  quick(
                    tr(
                      'To-Do',
                      'করণীয়',
                      'कार्य',
                      'المهام',
                    ),
                    Icons.task_alt,
                    const Color(0xFF3988E8),
                    () => go(const TodoPage()),
                    count: todos,
                  ),
                  quick(
                    tr(
                      'Income',
                      'আয়',
                      'आय',
                      'الدخل',
                    ),
                    Icons.trending_up,
                    const Color(0xFF159D70),
                    () => go(const FinancePage()),
                  ),
                  quick(
                    tr(
                      'Expense',
                      'ব্যয়',
                      'खर्च',
                      'المصروفات',
                    ),
                    Icons.trending_down,
                    const Color(0xFFE65363),
                    () => go(const FinancePage()),
                  ),
                ],
              ),

              Row(
                children: [
                  quick(
                    tr(
                      'Notes',
                      'নোট',
                      'नोट्स',
                      'الملاحظات',
                    ),
                    Icons.note_alt_outlined,
                    const Color(0xFF19A77A),
                    () => go(const NotesPage()),
                    count: notes,
                  ),
                  quick(
                    tr(
                      'Events',
                      'অনুষ্ঠান',
                      'कार्यक्रम',
                      'الأحداث',
                    ),
                    Icons.event_available,
                    const Color(0xFF9562D5),
                    () => go(const EventsPage()),
                  ),
                  quick(
                    tr(
                      'Alerts',
                      'সতর্কতা',
                      'अलर्ट',
                      'التنبيهات',
                    ),
                    Icons.notifications_active_outlined,
                    const Color(0xFFEA9635),
                    openNotifications,
                    count: unreadNotifications,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==================================================
              // FINANCIAL OVERVIEW
              // ==================================================

              sectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF6655D9),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr(
                              'Financial Overview',
                              'আর্থিক হিসাব',
                              'वित्तीय सारांश',
                              'الملخص المالي',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              go(const FinancePage()),
                          child: Text(
                            tr(
                              'Details',
                              'বিস্তারিত',
                              'विवरण',
                              'التفاصيل',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        money(
                          tr(
                            'Income',
                            'আয়',
                            'आय',
                            'الدخل',
                          ),
                          income,
                          const Color(0xFF159D70),
                          Icons.arrow_downward,
                        ),
                        money(
                          tr(
                            'Expense',
                            'ব্যয়',
                            'खर्च',
                            'المصروفات',
                          ),
                          expense,
                          const Color(0xFFE65363),
                          Icons.arrow_upward,
                        ),
                        money(
                          tr(
                            'Balance',
                            'বর্তমান স্থিতি',
                            'शेष राशि',
                            'الرصيد',
                          ),
                          balance,
                          const Color(0xFF3988E8),
                          Icons.account_balance,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ==================================================
              // RECEIVABLE AND PAYABLE
              // ==================================================

              sectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.swap_horiz,
                          color: Color(0xFF6655D9),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr(
                              'Receivable & Payable',
                              'পাওনা ও দেনা',
                              'लेना और देना',
                              'المستحقات والديون',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        moneySummary(
                          tr(
                            'Receivable',
                            'আমার পাওনা',
                            'मुझे लेना है',
                            'لي',
                          ),
                          receivable,
                          const Color(0xFF159D70),
                          Icons.call_received,
                          () => go(const FinancePage()),
                        ),
                        moneySummary(
                          tr(
                            'Payable',
                            'আমার দেনা',
                            'मुझे देना है',
                            'عليّ',
                          ),
                          payable,
                          const Color(0xFFE65363),
                          Icons.call_made,
                          () => go(const FinancePage()),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 7),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3988E8)
                            .withOpacity(.09),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance,
                            color: Color(0xFF3988E8),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              tr(
                                'Net Receivable',
                                'নিট পাওনা',
                                'शुद्ध प्राप्ति',
                                'صافي المستحقات',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            formatMoney(netReceivable),
                            style: const TextStyle(
                              color: Color(0xFF3988E8),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // BUDGET
              // ==================================================

              sectionCard(
                child: InkWell(
                  onTap: () => go(const BudgetPage()),
                  child: Row(
                    children: [
                      Container(
                        height: 43,
                        width: 43,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA726)
                              .withOpacity(.15),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.track_changes,
                          color: Color(0xFFEF9225),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(
                                'Budget Summary',
                                'বাজেটের সারাংশ',
                                'बजट सारांश',
                                'ملخص الميزانية',
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              tr(
                                'View your budget and spending plan',
                                'আপনার বাজেট ও ব্যয় পরিকল্পনা দেখুন',
                                'अपना बजट और खर्च योजना देखें',
                                'عرض ميزانيتك وخطة الإنفاق',
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // RECENT ACTIVITY
              // ==================================================

              sectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.history,
                          color: Color(0xFF3988E8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr(
                              'Recent Activity',
                              'সাম্প্রতিক কার্যক্রম',
                              'हाल की गतिविधियां',
                              'النشاط الأخير',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: load,
                          child: Text(
                            tr(
                              'Refresh',
                              'রিফ্রেশ',
                              'रिफ्रेश',
                              'تحديث',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (recent.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          tr(
                            'No recent activity',
                            'সাম্প্রতিক কোনো কার্যক্রম নেই',
                            'कोई हाल की गतिविधि नहीं',
                            'لا يوجد نشاط حديث',
                          ),
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ...recent.map(
                      (x) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 17,
                          backgroundColor:
                              primary.withOpacity(.10),
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
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${x['s']}',
                          style: const TextStyle(
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ALERTS AND REMINDERS
              // ==================================================

              if (todos > 0 || unreadNotifications > 0)
                sectionCard(
                  color: const Color(0xFFFFA726)
                      .withOpacity(.08),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: Color(0xFFEA9635),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr(
                              'Alerts & Reminders',
                              'সতর্কতা ও অনুস্মারক',
                              'अलर्ट और रिमाइंडर',
                              'التنبيهات والتذكيرات',
                            ),
                            style: const TextStyle(
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
                          leading: const Icon(
                            Icons.task_alt,
                            color: Colors.blue,
                          ),
                          title: Text(
                            tr(
                              '$todos pending To-Do tasks',
                              '$todosটি অসম্পূর্ণ কাজ',
                              '$todos अधूरे कार्य',
                              '$todos مهام معلقة',
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap: () => go(const TodoPage()),
                        ),
                      if (unreadNotifications > 0)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.notifications,
                            color: Colors.orange,
                          ),
                          title: Text(
                            tr(
                              '$unreadNotifications unread notifications',
                              '$unreadNotificationsটি অপঠিত বিজ্ঞপ্তি',
                              '$unreadNotifications अपठित सूचनाएं',
                              '$unreadNotifications إشعارات غير مقروءة',
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap: openNotifications,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
