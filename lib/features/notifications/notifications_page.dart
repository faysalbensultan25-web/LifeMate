
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/services/language_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;

  String tr(String en, String bn, String hi, String ar) {
    return LanguageService.text(
      english: en,
      bangla: bn,
      hindi: hi,
      arabic: ar,
    );
  }

  bool get isArabic => LanguageService.isArabic;

  int get unreadCount =>
      notifications.where((item) => item['is_read'] != 1).length;

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
          content: Text(
            tr(
              'Could not load notifications',
              'বিজ্ঞপ্তি লোড করা যায়নি',
              'सूचनाएं लोड नहीं हो सकीं',
              'تعذر تحميل الإشعارات',
            ),
          ),
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
          title: Text(
            tr(
              'Clear Notifications?',
              'সব বিজ্ঞপ্তি মুছবেন?',
              'सूचनाएं हटाएं?',
              'مسح الإشعارات؟',
            ),
          ),
          content: Text(
            tr(
              'All notifications will be deleted.',
              'সব বিজ্ঞপ্তি মুছে যাবে।',
              'सभी सूचनाएं हटा दी जाएंगी।',
              'سيتم حذف جميع الإشعارات.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: Text(
                tr('Cancel', 'বাতিল', 'रद्द करें', 'إلغاء'),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(
                tr('Clear All', 'সব মুছুন', 'सभी हटाएं', 'مسح الكل'),
              ),
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

    if (text.contains('todo') || text.contains('task')) {
      return Icons.checklist;
    }
    if (text.contains('event')) return Icons.event;
    if (text.contains('budget')) {
      return Icons.account_balance_wallet;
    }
    if (text.contains('receivable')) {
      return Icons.call_received;
    }
    if (text.contains('payable')) {
      return Icons.call_made;
    }
    if (text.contains('expense')) return Icons.money_off;
    if (text.contains('income')) return Icons.attach_money;

    return Icons.notifications;
  }

  String translateTitle(String title) {
    switch (title.toLowerCase()) {
      case 'pending to-do':
        return tr('Pending To-Do', 'অসমাপ্ত কাজ', 'अधूरे कार्य', 'مهام معلقة');
      case 'upcoming events':
        return tr('Upcoming Events', 'আসন্ন অনুষ্ঠান', 'आगामी कार्यक्रम', 'الأحداث القادمة');
      case 'budget alert':
        return tr('Budget Alert', 'বাজেট সতর্কতা', 'बजट चेतावनी', 'تنبيه الميزانية');
      case 'receivable reminder':
        return tr('Receivable Reminder', 'পাওনা আদায়ের স্মারক', 'प्राप्य राशि अनुस्मारक', 'تذكير بالمبالغ المستحقة لك');
      case 'payable reminder':
        return tr('Payable Reminder', 'দেনা পরিশোধের স্মারক', 'देय राशि अनुस्मारक', 'تذكير بالمبالغ المستحقة عليك');
      default:
        return title;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                tr(
                  'Notifications',
                  'বিজ্ঞপ্তি',
                  'सूचनाएं',
                  'الإشعارات',
                ),
              ),
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
                tooltip: tr(
                  'Mark all as read',
                  'সব পড়া হয়েছে চিহ্নিত করুন',
                  'सभी को पढ़ा हुआ चिह्नित करें',
                  'تحديد الكل كمقروء',
                ),
                onPressed: markAllAsRead,
                icon: const Icon(Icons.done_all),
              ),
            if (notifications.isNotEmpty)
              IconButton(
                tooltip: tr(
                  'Clear all',
                  'সব মুছুন',
                  'सभी हटाएं',
                  'مسح الكل',
                ),
                onPressed: clearAll,
                icon: const Icon(Icons.delete_sweep),
              ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadNotifications,
                child: notifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 180),
                          const Icon(
                            Icons.notifications_none,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              tr(
                                'No notifications',
                                'কোনো বিজ্ঞপ্তি নেই',
                                'कोई सूचना नहीं',
                                'لا توجد إشعارات',
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              tr(
                                'You are all caught up.',
                                'আপনি সব বিজ্ঞপ্তি দেখে ফেলেছেন।',
                                'आपने सभी सूचनाएं देख ली हैं।',
                                'لقد اطلعت على جميع الإشعارات.',
                              ),
                              style: const TextStyle(color: Colors.grey),
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
      ),
    );
  }

  Widget buildNotification(
    Map<String, dynamic> notification,
  ) {
    final id = int.tryParse(
          notification['id']?.toString() ?? '',
        ) ??
        0;

    final title = notification['title']?.toString() ?? '';
    final message = notification['message']?.toString() ?? '';
    final createdAt =
        notification['created_at']?.toString() ?? '';

    final isRead = notification['is_read'] == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isRead
          ? Theme.of(context).cardColor
          : Theme.of(context).colorScheme.primaryContainer.withValues(
                alpha: 0.35,
              ),
      child: ListTile(
        onTap: () {
          if (!isRead) markAsRead(id);
        },
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            getIcon(title),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                translateTitle(title),
                style: TextStyle(
                  fontWeight:
                      isRead ? FontWeight.w500 : FontWeight.bold,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
            if (value == 'read') markAsRead(id);
            if (value == 'delete') deleteNotification(id);
          },
          itemBuilder: (context) => [
            if (!isRead)
              PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    const Icon(Icons.done),
                    const SizedBox(width: 8),
                    Text(
                      tr(
                        'Mark as read',
                        'পড়া হয়েছে চিহ্নিত করুন',
                        'पढ़ा हुआ चिह्नित करें',
                        'تحديد كمقروء',
                      ),
                    ),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline),
                  const SizedBox(width: 8),
                  Text(
                    tr('Delete', 'মুছুন', 'हटाएं', 'حذف'),
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
