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
        padding: const EdgeInsets
