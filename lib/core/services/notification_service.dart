
import '../database/app_database.dart';

class NotificationService {
  NotificationService._();

  static Future<void> generateAlerts() async {
    final db = await AppDatabase.database;

    await _todoAlerts(db);
    await _eventAlerts(db);
    await _budgetAlerts(db);
    await _moneyRecordAlerts(db);
  }

  static Future<void> _todoAlerts(dynamic db) async {
    final todos = await db.query(
      'todos',
      where: 'completed = ?',
      whereArgs: [0],
      orderBy: 'id DESC',
    );

    if (todos.isEmpty) return;

    await _addIfMissing(
      db,
      'Pending To-Do',
      'You have ${todos.length} pending task(s).',
      'todo_${todos.length}',
    );
  }

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
      if (value == null) continue;

      try {
        final date = DateTime.parse(value);
        if (!date.isBefore(today)) upcoming++;
      } catch (_) {}
    }

    if (upcoming == 0) return;

    await _addIfMissing(
      db,
      'Upcoming Events',
      'You have $upcoming upcoming event(s).',
      'events_$upcoming',
    );
  }

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
        if (startDate != null) {
          start = DateTime.parse(startDate);
        }

        if (endDate != null && endDate.isNotEmpty) {
          end = DateTime.parse(endDate);
        }
      } catch (_) {
        continue;
      }

      final now = DateTime.now();

      if (start != null && now.isBefore(start)) continue;
      if (end != null && now.isAfter(end)) continue;

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
        final title = budget['title']?.toString() ?? 'Budget';

        await _addIfMissing(
          db,
          'Budget Alert',
          '$title budget limit has been reached.',
          'budget_${budget['id']}_$amount',
        );
      }
    }
  }

  // Receivable and Payable reminders
  static Future<void> _moneyRecordAlerts(dynamic db) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderLimit = today.add(const Duration(days: 3));

    final records = await db.query('money_records');

    for (final record in records) {
      final expectedDate = record['expected_date']?.toString();

      if (expectedDate == null || expectedDate.isEmpty) {
        continue;
      }

      DateTime dueDate;

      try {
        final parsed = DateTime.parse(expectedDate);
        dueDate = DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        continue;
      }

      // Remind 3 days before and continue after due date.
      if (dueDate.isAfter(reminderLimit)) continue;

      final recordId = record['id'];
      final totalAmount = double.tryParse(
            record['amount']?.toString() ?? '',
          ) ??
          0;

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

      if (remaining <= 0) continue;

      final type = record['type']?.toString() ?? 'receivable';
      final person = record['person_name']?.toString() ?? 'Unknown';

      final isReceivable = type == 'receivable';

      final title = isReceivable
          ? 'Receivable Reminder'
          : 'Payable Reminder';

      final formattedDate =
          '${dueDate.day}/${dueDate.month}/${dueDate.year}';

      final status = dueDate.isBefore(today)
          ? 'Overdue'
          : dueDate.isAtSameMomentAs(today)
              ? 'Due today'
              : 'Due soon';

      final message =
          '$status: ${isReceivable ? 'Collect' : 'Pay'} '
          'Tk ${remaining.toStringAsFixed(2)} '
          '${isReceivable ? 'from' : 'to'} $person. '
          'Due date: $formattedDate.';

      await _addIfMissing(
        db,
        title,
        message,
        'money_${recordId}_${remaining}_$formattedDate',
      );
    }
  }

  static Future<void> _addIfMissing(
    dynamic db,
    String title,
    String message,
    String key,
  ) async {
    final existing = await db.query(
      'notifications',
      where: 'message = ?',
      whereArgs: [message],
      limit: 1,
    );

    if (existing.isNotEmpty) return;

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

  static Future<int> unreadCount() async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM notifications
      WHERE is_read = 0
      ''',
    );

    return (result.first['count'] as int?) ?? 0;
  }
}
