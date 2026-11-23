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

  List<Map<String, dynamic>> get filteredNotes {
    if (searchText.trim().isEmpty) {
      return notes;
    }

    final query = searchText.toLowerCase();

    return notes.where((note) {
      final title = (note['title'] as String).toLowerCase();
      final content = (note['content'] as String).toLowerCase();

      return title.contains(query) || content.contains(query);
    }).toList();
  }

  Future<void> showNoteDialog({
    Map<String, dynamic>? note,
  }) async {
    final titleController = TextEditingController(
      text: note?['title'] as String? ?? '',
    );

    final contentController = TextEditingController(
      text: note?['content'] as String? ?? '',
    );

    final isEditing = note != null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Note' : 'New Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final content = contentController.text.trim();

                if (title.isEmpty && content.isEmpty) return;

                final db = await AppDatabase.database;
                final now = DateTime.now().toIso8601String();

                if (isEditing) {
                  await db.update(
                    'notes',
                    {
                      'title': title.isEmpty ? 'Untitled' : title,
                      'content': content,
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
                      'created_at': now,
                      'updated_at': now,
                    },
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    contentController.dispose();

    await loadNotes();
  }

  Future<void> deleteNote(int id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    await loadNotes();
  }

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

  @override
  Widget build(BuildContext context) {
    final visibleNotes = filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: visibleNotes.isEmpty
                ? Center(
                    child: Text(
                      searchText.isEmpty
                          ? 'No notes yet'
                          : 'No matching notes',
                      style: const TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visibleNotes.length,
                    itemBuilder: (context, index) {
                      final note = visibleNotes[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            note['pinned'] == 1
                                ? Icons.push_pin
                                : Icons.note_alt_outlined,
                          ),
                          title: Text(
                            note['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            note['content'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            showNoteDialog(note: note);
                          },
                          trailing: PopupMenuButton<String>(
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
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'pin',
                                child: Text(
                                  note['pinned'] == 1 ? 'Unpin' : 'Pin',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
