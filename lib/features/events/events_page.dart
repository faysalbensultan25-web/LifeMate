
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    final db = await AppDatabase.database;

    final data = await db.query(
      'events',
      orderBy: 'event_date ASC',
    );

    if (!mounted) return;

    setState(() {
      events = data;
      isLoading = false;
    });
  }

  Future<void> addEvent() async {
    await showEventDialog();
  }

  Future<void> editEvent(
    Map<String, dynamic> event,
  ) async {
    await showEventDialog(event: event);
  }

  Future<void> showEventDialog({
    Map<String, dynamic>? event,
  }) async {
    final titleController = TextEditingController(
      text: event?['title'] as String? ?? '',
    );

    final descriptionController = TextEditingController(
      text: event?['description'] as String? ?? '',
    );

    DateTime selectedDate = event == null
        ? DateTime.now()
        : DateTime.tryParse(
              event['event_date'] as String,
            ) ??
            DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                event == null ? 'Add Event' : 'Edit Event',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month,
                      ),
                      title: const Text('Event Date'),
                      subtitle: Text(
                        '${selectedDate.day}/'
                        '${selectedDate.month}/'
                        '${selectedDate.year}',
                      ),
                      trailing: const Icon(
                        Icons.edit_calendar,
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (date != null) {
                          setDialogState(() {
                            selectedDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(
                    event == null ? 'Save' : 'Update',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    titleController.dispose();
    descriptionController.dispose();

    if (result != true || !mounted) return;

    final db = await AppDatabase.database;

    if (event == null) {
      await db.insert('events', {
        'title': title,
        'description': description,
        'event_date': selectedDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'events',
        {
          'title': title,
          'description': description,
          'event_date': selectedDate.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [event['id']],
      );
    }

    await loadEvents();
  }

  Future<void> deleteEvent(
    Map<String, dynamic> event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Event?'),
          content: Text(
            'Delete "${event['title']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final db = await AppDatabase.database;

    await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [event['id']],
    );

    await loadEvents();
  }

  String formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget eventCard(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE7F0FF),
          child: Icon(
            Icons.event,
            color: Color(0xFF1877F2),
          ),
        ),
        title: Text(
          event['title'] as String,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDate(event['event_date'] as String),
              ),
              if ((event['description'] as String? ?? '')
                  .isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(event['description'] as String),
              ],
            ],
          ),
        ),
        isThreeLine:
            (event['description'] as String? ?? '').isNotEmpty,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              editEvent(event);
            } else if (value == 'delete') {
              deleteEvent(event);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : events.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 70,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text('No events yet'),
                      Text('Tap + to add your first event'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return eventCard(events[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
