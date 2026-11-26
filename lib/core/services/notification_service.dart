import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import 'language_service.dart';

class NotificationService {
  NotificationService._();

  static Future<void> generateAlerts() async {
    // Notification disabled হলে নতুন alert তৈরি হবে না।
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications') ?? true;

    if (!enabled) return;

    final db = await AppDatabase.database;

    await _todoAlerts(db);
    await _eventAlerts(db);
    await _budgetAlerts(db);
    await _moneyRecordAlerts(db);
  }

  // ============================================================
  // LANGUAGE HELPER
  // ============================================================

  static String _t({
    required String english,
    required String bangla,
    required String hindi,
    required String arabic,
  }) {
    return LanguageService.text(
      english: english,
      bangla: bangla,
      hindi: hindi,
      arabic: arabic,
    );
  }

  // ============================================================
  // TODO ALERTS
  // ============================================================

  static Future<void> _todoAlerts(dynamic db) async {
    final todos = await db.query(
      'todos',
      where: 'completed = ?',
      whereArgs: [0],
      orderBy: 'id DESC',
    );

    if (todos.isEmpty) return;

    final count = todos.length;

    final title = _t(
      english: 'Pending To-Do',
      bangla: 'অসম্পূর্ণ কাজ',
      hindi: 'लंबित कार्य',
      arabic: 'مهام معلقة',
    );

    final message = _t(
      english: 'You have $count pending task(s).',
      bangla: 'আপনার $countটি অসম্পূর্ণ কাজ আছে।',
      hindi: 'आपके $count लंबित कार्य हैं।',
      arabic: 'لديك $count من المهام المعلقة.',
    );

    await _addIfMissing(
      db,
      title,
      message,
      'todo_$count',
    );
  }

  // ============================================================
  // EVENT ALERTS
  // ============================================================

  static Future<void> _eventAlerts(dynamic db) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final events = await db.query(
      'events',
      orderBy: 'event_date ASC',
    );

    int upcoming = 0;

    for (final event in events) {
      final value = event['event_date']?.toString();

      if (value == null || value.isEmpty) continue;

      try {
        final date = DateTime.parse(value);

        if (!date.isBefore(today)) {
          upcoming++;
        }
      } catch (_) {}
    }

    if (upcoming == 0) return;

    final title = _t(
      english: 'Upcoming Events',
      bangla: 'আসন্ন অনুষ্ঠান',
      hindi: 'आगामी कार्यक्रम',
      arabic: 'الأحداث القادمة',
    );

    final message = _t(
      english: 'You have $upcoming upcoming event(s).',
      bangla: 'আপনার $upcomingটি আসন্ন অনুষ্ঠান আছে।',
      hindi: 'आपके $upcoming आगामी कार्यक्रम हैं।',
      arabic: 'لديك $upcoming من الأحداث القادمة.',
    );

    await _addIfMissing(
      db,
      title,
      message,
      'events_$upcoming',
    );
  }

  // ============================================================
  // BUDGET ALERTS
  // ============================================================

  static Future<void> _budgetAlerts(dynamic db) async {
    final budgets = await db.query('budgets');

    for (final budget in budgets) {
      final type =
          budget['type']?.toString().toLowerCase() ?? 'expense';

      if (type != 'expense') continue;

      final amount = double.tryParse(
            budget['amount']?.toString() ?? '',
          ) ??
          0;

      if (amount <= 0) continue;

      final startDate = budget['start_date']?.toString();
      final endDate = budget['end_date']?.toString();

      DateTime? start;
      DateTime? end;

      try {
        if (startDate != null && startDate.isNotEmpty) {
          final parsed = DateTime.parse(startDate);
          start = DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
          );
        }

        if (endDate != null && endDate.isNotEmpty) {
          final parsed = DateTime.parse(endDate);
          end = DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
          );
        }
      } catch (_) {
        continue;
      }

      final now = DateTime.now();
      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      if (start != null && today.isBefore(start)) {
        continue;
      }

      if (end != null && today.isAfter(end)) {
        continue;
      }

      final expenses = await db.query(
        'expenses',
        columns: ['amount'],
      );

      double totalExpense = 0;

      for (final expense in expenses) {
        totalExpense += double.tryParse(
              expense['amount']?.toString() ?? '',
            ) ??
            0;
      }

      if (totalExpense >= amount) {
        final titleValue =
            budget['title']?.toString() ?? 'Budget';

        final title = _t(
          english: 'Budget Alert',
          bangla: 'বাজেট সতর্কতা',
          hindi: 'बजट चेतावनी',
          arabic: 'تنبيه الميزانية',
        );

        final message = _t(
          english:
              '$titleValue budget limit has been reached.',
          bangla:
              '$titleValue বাজেটের সীমা পূর্ণ হয়েছে।',
          hindi:
              '$titleValue बजट की सीमा पूरी हो गई है।',
          arabic:
              'تم الوصول إلى حد ميزانية $titleValue.',
        );

        await _addIfMissing(
          db,
          title,
          message,
          'budget_${budget['id']}_$amount',
        );
      }
    }
  }

  // ============================================================
  // RECEIVABLE / PAYABLE ALERTS
  // ============================================================

  static Future<void> _moneyRecordAlerts(dynamic db) async {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // 3 days আগে থেকে reminder
    final reminderLimit = today.add(
      const Duration(days: 3),
    );

    final records = await db.query(
      'money_records',
      orderBy: 'expected_date ASC',
    );

    for (final record in records) {
      final expectedDate =
          record['expected_date']?.toString();

      if (expectedDate == null || expectedDate.isEmpty) {
        continue;
      }

      DateTime dueDate;

      try {
        final parsed = DateTime.parse(expectedDate);

        dueDate = DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
        );
      } catch (_) {
        continue;
      }

      // 3 দিনের বেশি পরে হলে এখনো reminder নয়।
      if (dueDate.isAfter(reminderLimit)) {
        continue;
      }

      final recordId = record['id'];

      final totalAmount = double.tryParse(
            record['amount']?.toString() ?? '',
          ) ??
          0;

      if (totalAmount <= 0) continue;

      // Payment হিসাব
      final payments = await db.query(
        'money_payments',
        columns: ['amount'],
        where: 'record_id = ?',
        whereArgs: [recordId],
      );

      double paidAmount = 0;

      for (final payment in payments) {
        paidAmount += double.tryParse(
              payment['amount']?.toString() ?? '',
            ) ??
            0;
      }

      final remaining = totalAmount - paidAmount;

      // সম্পূর্ণ পরিশোধ হয়ে গেলে reminder নয়।
      if (remaining <= 0) continue;

      final type =
          record['type']?.toString() ?? 'receivable';

      final person =
          record['person_name']?.toString() ?? 'Unknown';

      final isReceivable = type == 'receivable';

      final title = isReceivable
          ? _t(
              english: 'Receivable Reminder',
              bangla: 'পাওনা টাকার স্মরণ করানো',
              hindi: 'प्राप्य राशि अनुस्मारक',
              arabic: 'تذكير بالمبلغ المستحق لك',
            )
          : _t(
              english: 'Payable Reminder',
              bangla: 'দেনা টাকার স্মরণ করানো',
              hindi: 'देय राशि अनुस्मारक',
              arabic: 'تذكير بالمبلغ المستحق عليك',
            );

      final formattedDate =
          '${dueDate.day}/${dueDate.month}/${dueDate.year}';

      String status;

      if (dueDate.isBefore(today)) {
        status = _t(
          english: 'Overdue',
          bangla: 'সময় পার হয়েছে',
          hindi: 'समय सीमा पार',
          arabic: 'متأخر',
        );
      } else if (dueDate.isAtSameMomentAs(today)) {
        status = _t(
          english: 'Due today',
          bangla: 'আজ পরিশোধের তারিখ',
          hindi: 'आज देय है',
          arabic: 'مستحق اليوم',
        );
      } else {
        status = _t(
          english: 'Due soon',
          bangla: 'শিগগিরই পরিশোধের তারিখ',
          hindi: 'जल्द देय',
          arabic: 'مستحق قريبًا',
        );
      }

      final amountText =
          remaining.toStringAsFixed(2);

      final message = isReceivable
          ? _t(
              english:
                  '$status: Collect Tk $amountText from $person. Due date: $formattedDate.',
              bangla:
                  '$status: $person-এর কাছ থেকে ৳$amountText পাওনা। তারিখ: $formattedDate।',
              hindi:
                  '$status: $person से ₹$amountText प्राप्त करें। देय तिथि: $formattedDate।',
              arabic:
                  '$status: استلم مبلغ $amountText من $person. تاريخ الاستحقاق: $formattedDate.',
            )
          : _t(
              english:
                  '$status: Pay Tk $amountText to $person. Due date: $formattedDate.',
              bangla:
                  '$status: $person-কে ৳$amountText দিতে হবে। তারিখ: $formattedDate।',
              hindi:
                  '$status: $person को ₹$amountText भुगतान करें। देय तिथि: $formattedDate।',
              arabic:
                  '$status: ادفع مبلغ $amountText إلى $person. تاريخ الاستحقاق: $formattedDate.',
            );

      await _addIfMissing(
        db,
        title,
        message,
        'money_${recordId}_${remaining}_$formattedDate',
      );
    }
  }

  // ============================================================
  // ADD NOTIFICATION ONLY IF IT DOES NOT ALREADY EXIST
  // ============================================================

  static Future<void> _addIfMissing(
    dynamic db,
    String title,
    String message,
    String key,
  ) async {
    // key ব্যবহার করে একই alert বারবার তৈরি হওয়া বন্ধ করা।
    //
    // বর্তমান notifications table-এ key column না থাকায়
    // message দিয়েও duplicate check করা হচ্ছে।

    final existing = await db.query(
      'notifications',
      where: 'message = ?',
      whereArgs: [message],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return;
    }

    await db.insert(
      'notifications',
      {
        'title': title,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': 0,
      },
    );
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  static Future<int> unreadCount() async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM notifications
      WHERE is_read = 0
      ''',
    );

    if (result.isEmpty) {
      return 0;
    }

    final value = result.first['count'];

    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
