
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'lifemate_bottom_nav.dart';
import '../todo/todo_page.dart';
import '../finance/finance_page.dart';
import '../notes/notes_page.dart';
import '../events/events_page.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import '../reports/pdf_reports_page.dart';
import '../settings/settings_page.dart';
import '../statistics/budget_page.dart';
import '../statistics/statistics_page.dart';

class LifeMateShell extends StatefulWidget {
  final String language;
  final ValueChanged<String>? onLanguageChanged;

  const LifeMateShell({
    super.key,
    required this.language,
    this.onLanguageChanged,
  });

  @override
  State<LifeMateShell> createState() => _LifeMateShellState();
}

class _LifeMateShellState extends State<LifeMateShell> {
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  int selectedIndex = 0;

  void navigate(int index) {
    if (index == 5) {
      showMore();
      return;
    }

    final pages = <Widget>[
      HomePage(
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      const TodoPage(),
      const FinancePage(),
      const FinancePage(),
      const NotesPage(),
    ];

    setState(() => selectedIndex = index);

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => pages[index]),
      (route) => false,
    );
  }

  void showMore() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            moreItem(Icons.event, 'Events', const EventsPage()),
            moreItem(Icons.bar_chart, 'Statistics', const StatisticsPage()),
            moreItem(Icons.savings, 'Budget', const BudgetPage()),
            moreItem(Icons.picture_as_pdf, 'PDF Reports', const PdfReportsPage()),
            moreItem(Icons.person, 'Profile', const ProfilePage()),
            moreItem(Icons.settings, 'Settings', const SettingsPage()),
            moreItem(Icons.notifications, 'Notifications', const NotificationsPage()),
          ],
        ),
      ),
    );
  }

  Widget moreItem(IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => HomePage(
            language: widget.language,
            onLanguageChanged: widget.onLanguageChanged,
          ),
        ),
      ),
      bottomNavigationBar: LifeMateBottomNav(
        selectedIndex: selectedIndex,
        onTap: navigate,
      ),
    );
  }
}
