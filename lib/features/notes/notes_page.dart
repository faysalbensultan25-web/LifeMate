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

  // ============================================================
  // 8 NOTE COLORS
  // ============================================================

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

  // ============================================================
  // NOTE TEMPLATES
  // ============================================================

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

  // ============================================================
  // LOAD NOTES
  // ============================================================

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

  // ============================================================
  // COLOR HELPERS
  // ============================================================

  Color getNoteColor(String? colorName) {
    final item = noteColors.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['name'] == colorName,
          orElse: () => null,
        );

    return item?['color'] as Color? ?? Colors.amber;
  }

  String getColorLabel(String? colorName) {
    final item = noteColors.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['name'] == colorName,
          orElse: () => null,
        );

    return item?['label'] as String? ?? 'Important';
  }

  IconData getColorIcon(String? colorName) {
    final item = noteColors.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['name'] == colorName,
          orElse: () => null,
        );

    return item?['icon'] as IconData? ?? Icons.note;
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

  // ============================================================
  // FILTERED NOTES
  // ============================================================

  List<Map<String, dynamic>> get filteredNotes {
    List<Map<String, dynamic>> result = List.from(notes);

    if (selectedColor != 'all') {
      result = result.where((note) {
        return (note['color'] as String? ?? 'yellow') == selectedColor;
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
        final colorA = a['color'] as String? ?? 'yellow';
        final colorB = b['color'] as String? ?? 'yellow';

        final importanceA = getImportance(colorA);
        final importanceB = getImportance(colorB);

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
  // NEW / EDIT NOTE
  // ============================================================

  Future<void> showNoteDialog({
    Map<String, dynamic>? note,
    String? templateTitle,
    String? templateContent,
    String? templateColor,
  }) async {
    final titleController = TextEditingController(
      text: templateTitle ??
          (note?['title'] as String? ?? ''),
    );

    final contentController = TextEditingController(
      text: templateContent ??
          (note?['content'] as String? ?? ''),
    );

    final isEditing = note != null;

    String selectedNoteColor =
        templateColor ??
        (note?['color'] as String? ?? 'yellow');

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
                      textCapitalization:
                          TextCapitalization.sentences,
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
                      textCapitalization:
                          TextCapitalization.sentences,
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

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: noteColors.map((item) {
                        final name = item['name'] as String;
                        final color = item['color'] as Color;
                        final label = item['label'] as String;

                        final selected =
                            selectedNoteColor == name;

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedNoteColor = name;
                            });
                          },
                          child: Tooltip(
                            message: label,
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 180),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? color
                                      : color.withOpacity(0.35),
                                  width: selected ? 3 : 1.5,
                                ),
                              ),
                              child: Icon(
                                selected
                                    ? Icons.check
                                    : Icons.circle,
                                size: selected ? 22 : 18,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      getColorLabel(selectedNoteColor),
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
                    final title =
                        titleController.text.trim();

                    final content =
                        contentController.text.trim();

                    if (title.isEmpty && content.isEmpty) {
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
                        : Icons.add,
                  ),
                  label: Text(
                    isEditing ? 'Update' : 'Save',
                  ),
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
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24,
            ),
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
                      final template =
                          noteTemplates[index];

                      final colorName =
                          template['color'] ?? 'yellow';

                      final color =
                          getNoteColor(colorName);

                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                color.withOpacity(0.18),
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
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap: () {
                            Navigator.pop(sheetContext);

                            showNoteDialog(
                              templateTitle:
                                  template['title'],
                              templateContent:
                                  template['content'],
                              templateColor:
                                  template['color'],
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
                    label: const Text(
                      'Blank Note',
                    ),
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

  Future<void> togglePin(
    Map<String, dynamic> note,
  ) async {
    final db = await AppDatabase.database;

    await db.update(
      'notes',
      {
        'pinned': note['pinned'] == 1 ? 0 : 1,
        'updated_at':
            DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [note['id']],
    );

    await loadNotes();
  }

  // ============================================================
  // COLOR FILTER
  // ============================================================

  Widget colorFilterButton({
    required String name,
    required Color color,
    required String label,
  }) {
    final selected = selectedColor == name;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        avatar: CircleAvatar(
          radius: 8,
          backgroundColor: color,
        ),
        onSelected: (_) {
          setState(() {
            selectedColor = name;
          });
        },
      ),
    );
  }

  // ============================================================
  // NOTE CARD
  // ============================================================

  Widget buildNoteCard(
    Map<String, dynamic> note,
  ) {
    final colorName =
        note['color'] as String? ?? 'yellow';

    final noteColor =
        getNoteColor(colorName);

    final title =
        note['title'] as String? ?? 'Untitled';

    final content =
        note['content'] as String? ?? '';

    final pinned =
        note['pinned'] == 1;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showNoteDialog(note: note);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: noteColor,
                width: 5,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            12,
            10,
            8,
            10,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  if (pinned)
                    Icon(
                      Icons.push_pin_rounded,
                      size: 18,
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
                        deleteNote(
                          note['id'] as int,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          leading:
                              Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pin',
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          leading: Icon(
                            pinned
                                ? Icons
                                    .push_pin_outlined
                                : Icons
                                    .push_pin_rounded,
                          ),
                          title: Text(
                            pinned ? 'Unpin' : 'Pin',
                          ),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_outline,
                          ),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (content.isNotEmpty)
                Text(
                  content,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.78),
                  ),
                ),

              const Spacer(),

              const SizedBox(height: 10),

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
                    Icons.arrow_forward_ios,
                    size: 12,
                  ),
                ],
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
                sortByImportance =
                    !sortByImportance;
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
            icon: const Icon(
              Icons.auto_awesome_rounded,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ======================================================
          // SEARCH
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon:
                    const Icon(Icons.search),
                suffixIcon:
                    searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                searchText = '';
                              });
                            },
                            icon: const Icon(
                              Icons.clear,
                            ),
                          )
                        : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ======================================================
          // COLOR FILTER
          // ======================================================

          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected:
                        selectedColor == 'all',
                    label: const Text('All'),
                    avatar: const Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedColor = 'all';
                      });
                    },
                  ),
                ),
                ...noteColors.map(
                  (item) => colorFilterButton(
                    name: item['name'] as String,
                    color: item['color'] as Color,
                    label: item['label'] as String,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // NOTE COUNT
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(14, 2, 14, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.notes_rounded,
                  size: 18,
                ),
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

          // ======================================================
          // NOTES GRID
          // ======================================================

          Expanded(
            child: visibleNotes.isEmpty
                ? Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            searchText.isNotEmpty ||
                                    selectedColor !=
                                        'all'
                                ? Icons.search_off_rounded
                                : Icons
                                    .sticky_note_2_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.55),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            searchText.isNotEmpty ||
                                    selectedColor !=
                                        'all'
                                ? 'No matching notes'
                                : 'No notes yet',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchText.isNotEmpty ||
                                    selectedColor !=
                                        'all'
                                ? 'Try another search or color.'
                                : 'Create your first note or use a template.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.65),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed:
                                showTemplateDialog,
                            icon: const Icon(
                              Icons.auto_awesome,
                            ),
                            label: const Text(
                              'Use Template',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      12,
                      4,
                      12,
                      90,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: visibleNotes.length,
                    itemBuilder: (context, index) {
                      return buildNoteCard(
                        visibleNotes[index],
                      );
                    },
                  ),
          ),
        ],
      ),

      // ==========================================================
      // ADD NOTE
      // ==========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: showTemplateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }
}
