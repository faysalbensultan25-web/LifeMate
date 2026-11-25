import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState
    extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;

  int get unreadCount => notifications
      .where((item) => item['is_read'] != 1)
      .length;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final db = await AppDatabase.database;

      final result = await db.query(
        'notifications',
        orderBy: 'id DESC',
      );

      if (!mounted) return;

      setState(() {
        notifications = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load notifications: $e'),
        ),
      );
    }
  }

  Future<void> markAsRead(int id) async {
    final db = await AppDatabase.database;

    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;

    final db = await AppDatabase.database;

    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'is_read = ?',
      whereArgs: [0],
    );

    await loadNotifications();
  }

  Future<void> deleteNotification(int id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );

    await loadNotifications();
  }

  Future<void> clearAll() async {
    if (notifications.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Notifications?'),
          content: const Text(
            'All notifications will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final db = await AppDatabase.database;

    await db.delete('notifications');

    await loadNotifications();
  }

  String formatDate(String value) {
    try {
      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  IconData getIcon(String title) {
    final text = title.toLowerCase();

    if (text.contains('todo') ||
        text.contains('task')) {
      return Icons.checklist;
    }

    if (text.contains('event')) {
      return Icons.event;
    }

    if (text.contains('budget')) {
      return Icons.account_balance_wallet;
    }

    if (text.contains('expense')) {
      return Icons.money_off;
    }

    if (text.contains('income')) {
      return Icons.attach_money;
    }

    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 12,
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            IconButton(
              tooltip: 'Mark all as read',
              onPressed: markAllAsRead,
              icon: const Icon(Icons.done_all),
            ),
          if (notifications.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              onPressed: clearAll,
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadNotifications,
              child: notifications.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 180),
                        Icon(
                          Icons.notifications_none,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Center(
                          child: Text(
                            'You are all caught up.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return buildNotification(
                          notifications[index],
                        );
                      },
                    ),
            ),
    );
  }

  Widget buildNotification(
    Map<String, dynamic> notification,
  ) {
    final id = notification['id'] as int;
    final title =
        notification['title']?.toString() ?? '';
    final message =
        notification['message']?.toString() ?? '';
    final createdAt =
        notification['created_at']?.toString() ?? '';
    final isRead = notification['is_read'] == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => markAsRead(id),
        leading: CircleAvatar(
          child: Icon(getIcon(title)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isRead
                      ? FontWeight.w500
                      : FontWeight.bold,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .error,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 5),
              Text(
                formatDate(createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'read') {
              markAsRead(id);
            }

            if (value == 'delete') {
              deleteNotification(id);
            }
          },
          itemBuilder: (context) => [
            if (!isRead)
              const PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    Icon(Icons.done),
                    SizedBox(width: 8),
                    Text('Mark as read'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
