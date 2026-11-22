
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> notes = [];

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

  Future<void> addNote() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Note'),
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
                  maxLines: 5,
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

                await db.insert('notes', {
                  'title': title.isEmpty ? 'Untitled' : title,
                  'content': content,
                  'pinned': 0,
                  'created_at': now,
                  'updated_at': now,
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: notes.isEmpty
          ? const Center(
              child: Text(
                'No notes yet',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
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
                    leading: Icon(
                      note['pinned'] == 1
                          ? Icons.push_pin
                          : Icons.note_alt_outlined,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'pin') {
                          togglePin(note);
                        } else if (value == 'delete') {
                          deleteNote(note['id'] as int);
                        }
                      },
                      itemBuilder: (context) => [
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
      floatingActionButton: FloatingActionButton(
        onPressed: addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
