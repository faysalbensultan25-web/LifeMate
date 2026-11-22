import 'package:flutter/material.dart';

import '../notes/notes_page.dart';
import '../todo/todo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  void openTodo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TodoPage(),
      ),
    );
  }

  void openNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LifeMate'),
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
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
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

  Widget _featureCard({
    required String title,
    required IconData icon,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: active ? onTap : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 38,
              color: active ? Colors.teal : Colors.grey,
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
                color: active ? Colors.teal : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
