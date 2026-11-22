import 'package:flutter/material.dart';

import '../todo/todo_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            context,
            title: 'To-Do',
            icon: Icons.task_alt,
            active: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TodoPage(),
                ),
              );
            },
          ),
          _featureCard(
            context,
            title: 'Finance',
            icon: Icons.account_balance_wallet,
          ),
          _featureCard(
            context,
            title: 'Notes',
            icon: Icons.note_alt,
          ),
          _featureCard(
            context,
            title: 'Events',
            icon: Icons.event,
          ),
          _featureCard(
            context,
            title: 'Statistics',
            icon: Icons.bar_chart,
          ),
          _featureCard(
            context,
            title: 'Budget',
            icon: Icons.savings,
          ),
          _featureCard(
            context,
            title: 'Profile',
            icon: Icons.person,
          ),
          _featureCard(
            context,
            title: 'PDF Reports',
            icon: Icons.picture_as_pdf,
          ),
          _featureCard(
            context,
            title: 'Backup',
            icon: Icons.backup,
          ),
          _featureCard(
            context,
            title: 'Settings',
            icon: Icons.settings,
          ),
        ],
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
            icon: const Icon(Icons.check_circle_outline),
            selectedIcon: const Icon(Icons.check_circle),
            label: 'To-Do',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TodoPage(),
                ),
              );
            },
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu_open),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: active ? onTap : () {},
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
