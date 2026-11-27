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

  Widget getPage(int index) {
    switch (index) {
      case 0:
        return HomePage(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        );

      case 1:
        return const TodoPage();

      case 2:
      case 3:
        return const FinancePage();

      case 4:
        return const NotesPage();

      default:
        return HomePage(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        );
    }
  }

  void navigate(int index) {
    if (index == 5) {
      showMore();
      return;
    }

    if (index < 0 || index > 4) return;

    // Home button
    if (index == 0) {
      navigatorKey.currentState?.popUntil(
        (route) => route.isFirst,
      );

      if (mounted) {
        setState(() {
          selectedIndex = 0;
        });
      }

      return;
    }

    if (mounted) {
      setState(() {
        selectedIndex = index;
      });
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => getPage(index),
      ),
      (route) => route.isFirst,
    );
  }

  void showMore() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            moreItem(
              Icons.event,
              'Events',
              const EventsPage(),
            ),
            moreItem(
              Icons.bar_chart,
              'Statistics',
              const StatisticsPage(),
            ),
            moreItem(
              Icons.savings,
              'Budget',
              const BudgetPage(),
            ),
            moreItem(
              Icons.picture_as_pdf,
              'PDF Reports',
              const PdfReportsPage(),
            ),
            moreItem(
              Icons.person,
              'Profile',
              const ProfilePage(),
            ),
            moreItem(
              Icons.settings,
              'Settings',
              const SettingsPage(),
            ),
            moreItem(
              Icons.notifications,
              'Notifications',
              const NotificationsPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget moreItem(
    IconData icon,
    String title,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },
    );
  }

  // ============================================================
  // ANDROID BACK / EDGE SWIPE CONTROL
  // ============================================================
  //
  // Important:
  // The outer LifeMateShell must NOT allow Android to close
  // the entire application directly.
  //
  // If there is a page inside the LifeMate Navigator, Back/Swipe
  // will first return to the previous page.
  //
  // If already on Home/root, the Back/Swipe is consumed instead
  // of closing LifeMate.
  //
  Future<void> _handleBack() async {
    final navigator = navigatorKey.currentState;

    if (navigator == null) return;

    if (navigator.canPop()) {
      navigator.pop();

      if (mounted) {
        setState(() {
          selectedIndex = 0;
        });
      }

      return;
    }

    // Already at Home/root.
    // Do NOT close the application.
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        _handleBack();
      },
      child: Scaffold(
        body: Navigator(
          key: navigatorKey,
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => getPage(0),
          ),
        ),
        bottomNavigationBar: LifeMateBottomNav(
          selectedIndex: selectedIndex,
          onTap: navigate,
        ),
      ),
    );
  }
}
