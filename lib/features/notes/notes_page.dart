
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
        final importanceA = getImportance(
          a['color'] as String? ?? 'yellow',
        );

        final importanceB = getImportance(
          b['color'] as String? ?? 'yellow',
        );

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
  // COLOR SELECTOR - ALL 8 COLORS VISIBLE
  // ============================================================

  Widget colorSelector({
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: noteColors.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 8,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final item = noteColors[index];
        final name = item['name'] as String;
        final label = item['label'] as String;
        final color = item['color'] as Color;
        final isSelected = selected == name;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelected(name),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.35),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle,
                  color: color,
                  size: 19,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: color,
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

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isEditing
                        ? Icons.edit_note_rounded
                        : Icons.note_add_rounded,
                    color: noteColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Note' : 'New Note',
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Note title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      maxLines: 7,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        hintText: 'Write your note...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 100),
                          child: Icon(Icons.notes_rounded),
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Importance / Color',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),

                    colorSelector(
                      selected: selectedNoteColor,
                      onSelected: (name) {
                        setDialogState(() {
                          selectedNoteColor = name;
                        });
                      },
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Selected: ${getColorLabel(selectedNoteColor)}',
                      style: TextStyle(
                        color: noteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();

                    if (title.isEmpty && content.isEmpty) {
                      return;
                    }

                    final db = await AppDatabase.database;
                    final now = DateTime.now().toIso8601String();

                    if (isEditing) {
                      await db.update(
                        'notes',
                        {
                          'title': title.isEmpty ? 'Untitled' : title,
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
                          'title': title.isEmpty ? 'Untitled' : title,
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
                    isEditing ? Icons.save_outlined : Icons.add,
                  ),
                  label: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
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

  Future<void> showNoteDetails(Map<String, dynamic> note) async {
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
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: SelectableText(
                note['content'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
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
                      final colorName = template['color'] ?? 'yellow';
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
  // COLOR FILTER - ALL OPTIONS VISIBLE
  // ============================================================

  Widget buildColorFilter() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: noteColors.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 7,
        mainAxisSpacing: 5,
        childAspectRatio: 2.8,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          final selected = selectedColor == 'all';

          return FilterChip(
            visualDensity: VisualDensity.compact,
            selected: selected,
            label: const Text('All'),
            avatar: const Icon(
              Icons.grid_view_rounded,
              size: 17,
            ),
            onSelected: (_) {
              setState(() {
                selectedColor = 'all';
              });
            },
          );
        }

        final item = noteColors[index - 1];
        final name = item['name'] as String;
        final color = item['color'] as Color;
        final label = item['label'] as String;

        return FilterChip(
          visualDensity: VisualDensity.compact,
          selected: selectedColor == name,
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          avatar: CircleAvatar(
            radius: 7,
            backgroundColor: color,
          ),
          onSelected: (_) {
            setState(() {
              selectedColor = name;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // NOTE CARD - DYNAMIC HEIGHT, MAXIMUM 4:3
  // ============================================================

  Widget buildNoteCard(Map<String, dynamic> note) {
    final colorName = note['color'] as String? ?? 'yellow';
    final noteColor = getNoteColor(colorName);

    final title = note['title'] as String? ?? 'Untitled';
    final content = note['content'] as String? ?? '';
    final pinned = note['pinned'] == 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final titleLines = (title.length / 32).ceil().clamp(1, 2);
        final contentLines = (
          content.split('\n').length +
          (content.length / 48).floor()
        ).clamp(1, 5);

        final maximumHeight = width * 0.75;

        final desiredHeight = (
          88 + titleLines * 20 + contentLines * 18
        ).toDouble();

        final cardHeight = desiredHeight.clamp(
          112.0,
          maximumHeight,
        );

        final availableContentLines = (
          ((cardHeight - 90) / 18).floor()
        ).clamp(1, 5);

        return SizedBox(
          height: cardHeight,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showNoteDetails(note),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    color: noteColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        7,
                        8,
                        7,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (pinned)
                                Icon(
                                  Icons.push_pin_rounded,
                                  size: 17,
                                  color: noteColor,
                                ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                iconSize: 20,
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
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('Edit'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        pinned
                                            ? Icons.push_pin_outlined
                                            : Icons.push_pin_rounded,
                                      ),
                                      title: Text(
                                        pinned ? 'Unpin' : 'Pin',
                                      ),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.delete_outline),
                                      title: Text('Delete'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                content.isEmpty ? 'No content' : content,
                                maxLines: availableContentLines,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.75),
                                ),
                              ),
                            ),
                          ),

                          Row(
                            children: [
                              Icon(
                                getColorIcon(colorName),
                                size: 15,
                                color: noteColor,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  getColorLabel(colorName),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: noteColor,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.open_in_full_rounded,
                                size: 14,
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
      },
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            searchText = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ALL COLORS SHOWN TOGETHER

          buildColorFilter(),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 5, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.notes_rounded, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${visibleNotes.length} note${visibleNotes.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.65),
                  ),
                ),
                const Spacer(),
                if (sortByImportance)
                  const Row(
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Importance',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          Expanded(
            child: visibleNotes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            searchText.isNotEmpty ||
                                    selectedColor != 'all'
                                ? Icons.search_off_rounded
                                : Icons.sticky_note_2_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.55),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            searchText.isNotEmpty ||
                                    selectedColor != 'all'
                                ? 'No matching notes'
                                : 'No notes yet',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchText.isNotEmpty ||
                                    selectedColor != 'all'
                                ? 'Try another search or color.'
                                : 'Create your first note or use a template.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.65),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: showTemplateDialog,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Use Template'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                    itemCount: visibleNotes.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      return buildNoteCard(visibleNotes[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showTemplateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }
}
