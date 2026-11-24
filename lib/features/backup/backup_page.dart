import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool isLoading = true;
  bool isProcessing = false;

  List<Map<String, Object?>> backups = [];

  @override
  void initState() {
    super.initState();
    loadBackups();
  }

  Future<String> getDatabasePath() async {
    final directory = await getDatabasesPath();
    return join(directory, 'lifemate.db');
  }

  Future<void> loadBackups() async {
    try {
      final db = await AppDatabase.database;

      final result = await db.query(
        'backups',
        orderBy: 'id DESC',
      );

      if (!mounted) return;

      setState(() {
        backups = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage('Could not load backup history: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> createBackup() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final db = await AppDatabase.database;

      // Complete pending SQLite write operations.
      await db.rawQuery('PRAGMA wal_checkpoint(FULL)');

      final databasePath = await getDatabasePath();
      final originalFile = File(databasePath);

      if (!await originalFile.exists()) {
        throw Exception('Database file not found.');
      }

      final now = DateTime.now();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);

      final backupPath = join(
        dirname(databasePath),
        'lifemate_backup_$timestamp.db',
      );

      // Close database before copying.
      await AppDatabase.close();

      await originalFile.copy(backupPath);

      // Reopen database.
      final reopenedDb = await AppDatabase.database;

      await reopenedDb.insert('backups', {
        'file_path': backupPath,
        'created_at': now.toIso8601String(),
      });

      await loadBackups();

      showMessage('Backup created successfully.');
    } catch (e) {
      // Try reopening the database if necessary.
      try {
        await AppDatabase.database;
      } catch (_) {}

      showMessage('Backup failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<bool> validateBackup(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      return false;
    }

    if (await file.length() == 0) {
      return false;
    }

    Database? testDb;

    try {
      testDb = await openDatabase(
        path,
        readOnly: true,
      );

      final result = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );

      final tables = result
          .map((row) => row['name'].toString())
          .toSet();

      const requiredTables = {
        'todos',
        'notes',
        'incomes',
        'expenses',
        'categories',
        'events',
        'budgets',
        'profiles',
        'backups',
        'profile_education',
        'profile_training',
        'profile_experience',
        'profile_skills',
        'profile_languages',
        'profile_achievements',
      };

      return tables.containsAll(requiredTables);
    } catch (_) {
      return false;
    } finally {
      await testDb?.close();
    }
  }

  Future<void> restoreBackup(String backupPath) async {
    if (isProcessing) return;

    final valid = await validateBackup(backupPath);

    if (!valid) {
      showMessage('Invalid or incompatible backup file.');
      return;
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'Restoring this backup will replace your current '
          'LifeMate database. Any changes made after this backup '
          'will be lost. Continue?',
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
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final databasePath = await getDatabasePath();

      final originalFile = File(databasePath);

      final tempPath = '$databasePath.restore_temp';
      final tempFile = File(tempPath);

      // Copy backup to temporary location first.
      await File(backupPath).copy(tempPath);

      await AppDatabase.close();

      // Remove existing database and sidecar files.
      final walFile = File('$databasePath-wal');
      final shmFile = File('$databasePath-shm');

      if (await walFile.exists()) {
        await walFile.delete();
      }

      if (await shmFile.exists()) {
        await shmFile.delete();
      }

      if (await originalFile.exists()) {
        await originalFile.delete();
      }

      // Replace database.
      await tempFile.copy(databasePath);
      await tempFile.delete();

      // Open restored database.
      await AppDatabase.database;

      await loadBackups();

      showMessage('Backup restored successfully. Please reopen the app.');
    } catch (e) {
      showMessage('Restore failed: $e');
    } finally {
      try {
        await AppDatabase.database;
      } catch (_) {}

      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> importBackup() async {
    if (isProcessing) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final path = result.files.single.path!;

      await restoreBackup(path);
    } catch (e) {
      showMessage('Could not select backup: $e');
    }
  }

  Future<void> deleteBackup(Map<String, Object?> backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: const Text(
          'This will permanently delete this backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final path = backup['file_path'].toString();
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }

      final db = await AppDatabase.database;

      await db.delete(
        'backups',
        where: 'id = ?',
        whereArgs: [backup['id']],
      );

      await loadBackups();

      showMessage('Backup deleted.');
    } catch (e) {
      showMessage('Delete failed: $e');
    }
  }

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: isProcessing ? null : onTap,
      ),
    );
  }

  Widget backupHistoryItem(Map<String, Object?> backup) {
    final path = backup['file_path'].toString();

    final date = DateTime.tryParse(
      backup['created_at'].toString(),
    );

    final formattedDate = date == null
        ? 'Unknown date'
        : DateFormat('dd MMM yyyy, hh:mm a').format(date);

    final exists = File(path).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          Icons.insert_drive_file,
          color: exists ? Colors.green : Colors.grey,
        ),
        title: Text(
          formattedDate,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          exists ? 'Backup available' : 'Backup file missing',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'restore') {
              restoreBackup(path);
            } else if (value == 'delete') {
              deleteBackup(backup);
            }
          },
          itemBuilder: (context) => [
            if (exists)
              const PopupMenuItem(
                value: 'restore',
                child: Text('Restore'),
              ),
            const PopupMenuItem(
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
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            onPressed: loadBackups,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: Colors.blue.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.shield,
                              size: 35,
                              color: Colors.blue,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Protect Your LifeMate Data',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Create a local backup of your To-Do, '
                              'Notes, Finance, Events, Profile and '
                              'other app data.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    actionCard(
                      icon: Icons.backup,
                      title: 'Create Backup',
                      subtitle: 'Save all LifeMate database information',
                      onTap: createBackup,
                      color: Colors.green,
                    ),

                    actionCard(
                      icon: Icons.restore,
                      title: 'Import Backup',
                      subtitle: 'Select a LifeMate .db backup from your phone',
                      onTap: importBackup,
                      color: Colors.orange,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Backup History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text('${backups.length} backups'),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (backups.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No backup available yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      ...backups.map(backupHistoryItem),

                    const SizedBox(height: 20),

                    const Text(
                      'Important: Backups created here are stored '
                      'inside the app private storage. Export a copy '
                      'to another safe location before uninstalling '
                      'LifeMate or clearing app data.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                if (isProcessing)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 15),
                              Text('Please wait...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
