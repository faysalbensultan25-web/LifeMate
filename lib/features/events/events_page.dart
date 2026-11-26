
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/services/language_service.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;
  String selectedFilter = 'upcoming';

  bool get isArabic => LanguageService.isArabic;

  String tr(String en, String bn, String hi, String ar) {
    return LanguageService.text(
      english: en,
      bangla: bn,
      hindi: hi,
      arabic: ar,
    );
  }

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
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
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Could not load events',
              'অনুষ্ঠান লোড করা যায়নি',
              'कार्यक्रम लोड नहीं हो सके',
              'تعذر تحميل الأحداث',
            ),
          ),
        ),
      );
    }
  }

  bool isUpcoming(Map<String, dynamic> event) {
    final date = DateTime.tryParse(
      event['event_date']?.toString() ?? '',
    );

    if (date == null) return true;

    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(today);
  }

  List<Map<String, dynamic>> get filteredEvents {
    return events.where((event) {
      return selectedFilter == 'upcoming'
          ? isUpcoming(event)
          : !isUpcoming(event);
    }).toList();
  }

  int get upcomingCount =>
      events.where(isUpcoming).length;

  int get pastCount =>
      events.length - upcomingCount;

  Future<void> addEvent() async {
    await showEventDialog();
  }

  Future<void> editEvent(Map<String, dynamic> event) async {
    await showEventDialog(event: event);
  }

  Future<void> showEventDialog({
    Map<String, dynamic>? event,
  }) async {
    final titleController = TextEditingController(
      text: event?['title']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: event?['description']?.toString() ?? '',
    );

    DateTime selectedDate = event == null
        ? DateTime.now()
        : DateTime.tryParse(
              event['event_date']?.toString() ?? '',
            ) ??
            DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: isArabic
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  event == null
                      ? tr('Add Event', 'অনুষ্ঠান যোগ করুন',
                          'कार्यक्रम जोड़ें', 'إضافة حدث')
                      : tr('Edit Event', 'অনুষ্ঠান সম্পাদনা',
                          'कार्यक्रम संपादित करें', 'تعديل الحدث'),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: tr(
                            'Event Title',
                            'অনুষ্ঠানের নাম',
                            'कार्यक्रम का नाम',
                            'عنوان الحدث',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: tr(
                            'Description',
                            'বিবরণ',
                            'विवरण',
                            'الوصف',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month),
                        title: Text(
                          tr('Event Date', 'অনুষ্ঠানের তারিখ',
                              'कार्यक्रम की तारीख', 'تاريخ الحدث'),
                        ),
                        subtitle: Text(
                          formatDate(
                            selectedDate.toIso8601String(),
                          ),
                        ),
                        trailing: const Icon(Icons.edit_calendar),
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
                    onPressed: () =>
                        Navigator.pop(dialogContext, false),
                    child: Text(
                      tr('Cancel', 'বাতিল', 'रद्द करें', 'إلغاء'),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) {
                        return;
                      }
                      Navigator.pop(dialogContext, true);
                    },
                    child: Text(
                      event == null
                          ? tr('Save', 'সংরক্ষণ', 'सहेजें', 'حفظ')
                          : tr('Update', 'আপডেট', 'अपडेट', 'تحديث'),
                    ),
                  ),
                ],
              );
            },
          ),
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
          title: Text(
            tr('Delete Event?', 'অনুষ্ঠান মুছবেন?',
                'कार्यक्रम हटाएं?', 'حذف الحدث؟'),
          ),
          content: Text(
            tr(
              'Delete "${event['title']}"?',
              '"${event['title']}" মুছে ফেলবেন?',
              '"${event['title']}" हटाएं?',
              'هل تريد حذف "${event['title']}"؟',
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
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(
                tr('Delete', 'মুছুন', 'हटाएं', 'حذف'),
              ),
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

  Widget summaryCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 27),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget eventCard(Map<String, dynamic> event) {
    final title = event['title']?.toString() ?? '';
    final description =
        event['description']?.toString() ?? '';
    final upcoming = isUpcoming(event);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: upcoming
              ? const Color(0xFFE7F0FF)
              : Colors.grey.withValues(alpha: 0.15),
          child: Icon(
            Icons.event,
            color: upcoming ? const Color(0xFF1877F2) : Colors.grey,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    formatDate(
                      event['event_date']?.toString() ?? '',
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(description),
              ],
              const SizedBox(height: 7),
              Text(
                upcoming
                    ? tr('Upcoming', 'আসন্ন', 'आगामी', 'قادم')
                    : tr('Past Event', 'অতীত অনুষ্ঠান',
                        'पिछला कार्यक्रम', 'حدث سابق'),
                style: TextStyle(
                  color: upcoming ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') editEvent(event);
            if (value == 'delete') deleteEvent(event);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Text(
                tr('Edit', 'সম্পাদনা', 'संपादित करें', 'تعديل'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                tr('Delete', 'মুছুন', 'हटाएं', 'حذف'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            tr('Events', 'অনুষ্ঠান', 'कार्यक्रम', 'الأحداث'),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadEvents,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        summaryCard(
                          tr('Upcoming', 'আসন্ন', 'आगामी', 'قادمة'),
                          upcomingCount,
                          Icons.event_available,
                          Colors.green,
                        ),
                        summaryCard(
                          tr('Past', 'অতীত', 'पिछले', 'سابقة'),
                          pastCount,
                          Icons.event_busy,
                          Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'upcoming',
                          label: Text(
                            tr('Upcoming', 'আসন্ন', 'आगामी', 'قادمة'),
                          ),
                          icon: const Icon(Icons.event_available),
                        ),
                        ButtonSegment(
                          value: 'past',
                          label: Text(
                            tr('Past', 'অতীত', 'पिछले', 'سابقة'),
                          ),
                          icon: const Icon(Icons.history),
                        ),
                      ],
                      selected: {selectedFilter},
                      onSelectionChanged: (value) {
                        setState(() {
                          selectedFilter = value.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (filteredEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 70),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.event_note,
                              size: 65,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tr(
                                'No events found',
                                'কোনো অনুষ্ঠান পাওয়া যায়নি',
                                'कोई कार्यक्रम नहीं मिला',
                                'لم يتم العثور على أحداث',
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              tr(
                                'Tap + to add an event',
                                '+ চিহ্নে চাপ দিয়ে অনুষ্ঠান যোগ করুন',
                                '+ दबाकर कार्यक्रम जोड़ें',
                                'اضغط + لإضافة حدث',
                              ),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filteredEvents.map(eventCard),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: addEvent,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
