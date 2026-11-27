
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> notes = [];

  String searchText = '';
  String selectedColor = 'all';
  bool sortByImportance = false;

  static const List<Map<String, dynamic>> noteColors = [
    {
      'name': 'red',
      'label': 'Urgent',
      'color': Colors.red,
      'icon': Icons.priority_high,
    },
    {
      'name': 'orange',
      'label': 'High',
      'color': Colors.orange,
      'icon': Icons.warning_amber_rounded,
    },
    {
      'name': 'yellow',
      'label': 'Important',
      'color': Colors.amber,
      'icon': Icons.star_rounded,
    },
    {
      'name': 'green',
      'label': 'Normal',
      'color': Colors.green,
      'icon': Icons.check_circle_outline,
    },
    {
      'name': 'blue',
      'label': 'Info',
      'color': Colors.blue,
      'icon': Icons.info_outline,
    },
    {
      'name': 'purple',
      'label': 'Personal',
      'color': Colors.purple,
      'icon': Icons.person_outline,
    },
    {
      'name': 'pink',
      'label': 'Idea',
      'color': Colors.pink,
      'icon': Icons.lightbulb_outline,
    },
    {
      'name': 'grey',
      'label': 'Other',
      'color': Colors.grey,
      'icon': Icons.more_horiz,
    },
  ];

  static const List<Map<String, String>> noteTemplates = [
    {
      'title': 'Personal Note',
      'content': 'Write your personal thoughts here...',
      'color': 'purple',
    },
    {
      'title': 'Daily Reminder',
      'content': 'Today I need to remember...',
      'color': 'yellow',
    },
    {
      'title': 'Important Task',
      'content': 'Important task:\n\n1. \n2. \n3. ',
      'color': 'red',
    },
    {
      'title': 'Meeting Note',
      'content': 'Meeting date:\nPeople:\nMain points:\n\nAction items:',
      'color': 'blue',
    },
    {
      'title': 'Idea & Plan',
      'content': 'My idea:\n\nPlan:\n1. \n2. \n3. ',
      'color': 'pink',
    },
    {
      'title': 'Shopping List',
      'content': 'Shopping list:\n\n• \n• \n• ',
      'color': 'green',
    },
    {
      'title': 'Expense Note',
      'content': 'Date:\nItem:\nAmount:\nNote:',
      'color': 'orange',
    },
    {
      'title': 'Quick Note',
      'content': 'Write something quickly here...',
      'color': 'grey',
    },
  ];

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'notes',
      orderBy: 'pinned DESC, id DESC',
    );

    if (!mounted) return;

    setState(() {
      notes = result;
    });
  }

  Color getNoteColor(String? colorName) {
    for (final item in noteColors) {
      if (item['name'] == colorName) {
        return item['color'] as Color;
      }
    }
    return Colors.amber;
  }

  String getColorLabel(String? colorName) {
    for (final item in noteColors) {
      if (item['name'] == colorName) {
        return item['label'] as String;
      }
    }
    return 'Important';
  }

  IconData getColorIcon(String? colorName) {
    for (final item in noteColors) {
      if (item['name'] == colorName) {
        return item['icon'] as IconData;
      }
    }
    return Icons.note;
  }

  int getImportance(String? colorName) {
    const importance = {
      'red': 1,
      'orange': 2,
      'yellow': 3,
      'green': 4,
      'blue': 5,
      'purple': 6,
      'pink': 7,
      'grey': 8,
    };

    return importance[colorName] ?? 8;
  }

  List<Map<String, dynamic>> get filteredNotes {
    List<Map<String, dynamic>> result = List.from(notes);

    if (selectedColor != 'all') {
      result = result.where((note) {
        return (note['color'] as String? ?? 'yellow') ==
            selectedColor;
      }).toList();
    }

    if (searchText.trim().isNotEmpty) {
      final query = searchText.trim().toLowerCase();

      result = result.where((note) {
        final title =
            (note['title'] as String? ?? '').toLowerCase();

        final content =
            (note['content'] as String? ?? '').toLowerCase();

        return title.contains(query) || content.contains(query);
      }).toList();
    }

    if (sortByImportance) {
      result.sort((a, b) {
        final importanceA =
            getImportance(a['color'] as String? ?? 'yellow');

        final importanceB =
            getImportance(b['color'] as String? ?? 'yellow');

        if (importanceA != importanceB) {
          return importanceA.compareTo(importanceB);
        }

        return (b['id'] as int).compareTo(a['id'] as int);
      });
    } else {
      result.sort((a, b) {
        final pinnedA = a['pinned'] as int? ?? 0;
        final pinnedB = b['pinned'] as int? ?? 0;

        if (pinnedA != pinnedB) {
          return pinnedB.compareTo(pinnedA);
        }

        return (b['id'] as int).compareTo(a['id'] as int);
      });
    }

    return result;
  }

  // ============================================================
  // COMPACT COLOR SELECTOR
  // ============================================================

  Widget colorSelector({
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 9,
      runSpacing: 8,
      children: noteColors.map((item) {
        final name = item['name'] as String;
        final color = item['color'] as Color;
        final isSelected = selected == name;

        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => onSelected(name),
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(
                color: isSelected
                    ? color
                    : color.withOpacity(0.35),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              isSelected ? Icons.check : Icons.circle,
              size: isSelected ? 17 : 12,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // NEW / EDIT NOTE
  // ============================================================

  Future<void> showNoteDialog({
    Map<String, dynamic>? note,
    String? templateTitle,
    String? templateContent,
    String? templateColor,
  }) async {
    final titleController = TextEditingController(
      text: templateTitle ?? (note?['title'] as String? ?? ''),
    );

    final contentController = TextEditingController(
      text: templateContent ?? (note?['content'] as String? ?? ''),
    );

    final isEditing = note != null;

    String selectedNoteColor =
        templateColor ?? (note?['color'] as String? ?? 'yellow');

    if (!noteColors.any(
      (item) => item['name'] == selectedNoteColor,
    )) {
      selectedNoteColor = 'yellow';
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final noteColor = getNoteColor(selectedNoteColor);

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 720,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 39,
                              height: 39,
                              decoration: BoxDecoration(
                                color: noteColor.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEditing
                                    ? Icons.edit_note_rounded
                                    : Icons.note_add_rounded,
                                color: noteColor,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                isEditing ? 'Edit Note' : 'New Note',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Title',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 7),

                        TextField(
                          controller: titleController,
                          textCapitalization:
                              TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Enter note title',
                            filled: true,
                            prefixIcon: const Icon(Icons.title),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'Your Note',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 7),

                        // Larger and clearer writing area.
                        TextField(
                          controller: contentController,
                          minLines: 8,
                          maxLines: 14,
                          keyboardType: TextInputType.multiline,
                          textCapitalization:
                              TextCapitalization.sentences,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.55,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Start writing your note here...',
                            hintMaxLines: 2,
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.35),
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.45),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.7,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Importance / Color',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              getColorLabel(selectedNoteColor),
                              style: TextStyle(
                                color: noteColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        colorSelector(
                          selected: selectedNoteColor,
                          onSelected: (name) {
                            setDialogState(() {
                              selectedNoteColor = name;
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final title =
                                      titleController.text.trim();

                                  final content =
                                      contentController.text.trim();

                                  if (title.isEmpty &&
                                      content.isEmpty) {
                                    return;
                                  }

                                  final db =
                                      await AppDatabase.database;

                                  final now =
                                      DateTime.now().toIso8601String();

                                  if (isEditing) {
                                    await db.update(
                                      'notes',
                                      {
                                        'title': title.isEmpty
                                            ? 'Untitled'
                                            : title,
                                        'content': content,
                                        'color': selectedNoteColor,
                                        'updated_at': now,
                                      },
                                      where: 'id = ?',
                                      whereArgs: [note['id']],
                                    );
                                  } else {
                                    await db.insert(
                                      'notes',
                                      {
                                        'title': title.isEmpty
                                            ? 'Untitled'
                                            : title,
                                        'content': content,
                                        'pinned': 0,
                                        'color': selectedNoteColor,
                                        'created_at': now,
                                        'updated_at': now,
                                      },
                                    );
                                  }

                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                },
                                icon: Icon(
                                  isEditing
                                      ? Icons.save_outlined
                                      : Icons.check,
                                  size: 18,
                                ),
                                label: Text(
                                  isEditing ? 'Update' : 'Save',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    contentController.dispose();

    await loadNotes();
  }

  // ============================================================
  // FULL NOTE DETAILS
  // ============================================================

  Future<void> showNoteDetails(
    Map<String, dynamic> note,
  ) async {
    final colorName = note['color'] as String? ?? 'yellow';
    final noteColor = getNoteColor(colorName);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                getColorIcon(colorName),
                color: noteColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note['title'] as String? ?? 'Untitled',
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 450),
            child: SingleChildScrollView(
              child: SelectableText(
                note['content'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                showNoteDialog(note: note);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TEMPLATE SELECTOR
  // ============================================================

  Future<void> showTemplateDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded),
                    SizedBox(width: 8),
                    Text(
                      'Note Templates',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: noteTemplates.length,
                    itemBuilder: (context, index) {
                      final template = noteTemplates[index];
                      final colorName =
                          template['color'] ?? 'yellow';

                      final color = getNoteColor(colorName);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.18),
                            child: Icon(
                              getColorIcon(colorName),
                              color: color,
                            ),
                          ),
                          title: Text(
                            template['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            template['content'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(sheetContext);

                            showNoteDialog(
                              templateTitle: template['title'],
                              templateContent: template['content'],
                              templateColor: template['color'],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      showNoteDialog();
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Blank Note'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteNote(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: const Text(
            'This note will be permanently deleted.',
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final db = await AppDatabase.database;

    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    await loadNotes();
  }

  // ============================================================
  // PIN
  // ============================================================

  Future<void> togglePin(Map<String, dynamic> note) async {
    final db = await AppDatabase.database;

    await db.update(
      'notes',
      {
        'pinned': note['pinned'] == 1 ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [note['id']],
    );

    await loadNotes();
  }

  // ============================================================
  // COMPACT HORIZONTAL COLOR FILTER
  // ============================================================

  Widget buildColorFilter() {
    return SizedBox(
      height: 39,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildFilterItem(
            name: 'all',
            label: 'All',
            color: Theme.of(context).colorScheme.primary,
            icon: Icons.grid_view_rounded,
          ),
          ...noteColors.map((item) {
            return _buildFilterItem(
              name: item['name'] as String,
              label: item['label'] as String,
              color: item['color'] as Color,
              icon: item['icon'] as IconData,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterItem({
    required String name,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = selectedColor == name;

    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            selectedColor = name;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.17)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected ? color : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMPACT FULL-WIDTH NOTE CARD
  // ============================================================

  Widget buildNoteCard(Map<String, dynamic> note) {
    final colorName = note['color'] as String? ?? 'yellow';
    final noteColor = getNoteColor(colorName);

    final title = note['title'] as String? ?? 'Untitled';
    final content = note['content'] as String? ?? '';
    final pinned = note['pinned'] == 1;

    return SizedBox(
      height: 104,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1.5,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(
            color: noteColor.withOpacity(0.22),
            width: 0.8,
          ),
        ),
        child: InkWell(
          onTap: () => showNoteDetails(note),
          child: Row(
            children: [
              Container(
                width: 5,
                color: noteColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    9,
                    7,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (pinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Icon(
                                Icons.push_pin_rounded,
                                size: 15,
                                color: noteColor,
                              ),
                            ),
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconSize: 19,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  showNoteDialog(note: note);
                                } else if (value == 'pin') {
                                  togglePin(note);
                                } else if (value == 'delete') {
                                  deleteNote(note['id'] as int);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 10),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'pin',
                                  child: Row(
                                    children: [
                                      Icon(
                                        pinned
                                            ? Icons.push_pin_outlined
                                            : Icons.push_pin_rounded,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        pinned ? 'Unpin' : 'Pin',
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline),
                                      SizedBox(width: 10),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            content.isEmpty
                                ? 'No content'
                                : content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.82),
                            ),
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: noteColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            getColorLabel(colorName),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: noteColor,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.open_in_full_rounded,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.45),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final visibleNotes = filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            tooltip: 'Sort by importance',
            onPressed: () {
              setState(() {
                sortByImportance = !sortByImportance;
              });
            },
            icon: Icon(
              sortByImportance
                  ? Icons.sort_by_alpha_rounded
                  : Icons.priority_high_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Templates',
            onPressed: showTemplateDialog,
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
        ],
      ),

      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
            child: SizedBox(
              height: 45,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search, size: 21),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              searchText = '';
                            });
                          },
                          icon: const Icon(Icons.clear, size: 19),
                        )
                      : null,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // ONE ROW COLOR FILTER
          buildColorFilter(),

          // NOTE COUNT
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
            child: Row(
              children: [
                const Icon(Icons.notes_rounded, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${visibleNotes.length} note${visibleNotes.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                if (sortByImportance)
                  const Row(
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        size: 14,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Importance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // NOTES LIST
          Expanded(
            child: visibleNotes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            searchText.isNotEmpty ||
                                    selectedColor != 'all'
                                ? Icons.search_off_rounded
                                : Icons.sticky_note_2_outlined,
                            size: 58,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.55),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            searchText.isNotEmpty ||
                                    selectedColor != 'all'
                                ? 'No matching notes'
                                : 'No notes yet',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            searchText.isNotEmpty ||
                                    selectedColor != 'all'
                                ? 'Try another search or color.'
                                : 'Create your first note or use a template.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.65),
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton.icon(
                            onPressed: showTemplateDialog,
                            icon: const Icon(
                              Icons.auto_awesome,
                              size: 18,
                            ),
                            label: const Text('Use Template'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      2,
                      12,
                      85,
                    ),
                    itemCount: visibleNotes.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 7);
                    },
                    itemBuilder: (context, index) {
                      return buildNoteCard(visibleNotes[index]);
                    },
                  ),
          ),
        ],
      ),

      // ONLY PLUS BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: showNoteDialog,
        tooltip: 'New Note',
        child: const Icon(
          Icons.add_rounded,
          size: 29,
        ),
      ),
    );
  }
}
