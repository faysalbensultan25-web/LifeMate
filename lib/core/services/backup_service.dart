import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../database/app_database.dart';

class BackupService {
  BackupService._();

  static const tables = [
    'todos',
    'notes',
    'incomes',
    'expenses',
    'categories',
    'events',
    'budgets',
    'profiles',
    'profile_education',
    'profile_training',
    'profile_experience',
    'profile_skills',
    'profile_languages',
    'profile_achievements',
    'notifications',
  ];

  static Future<String?> backup() async {
    final db = await AppDatabase.database;
    final data = <String, dynamic>{};

    for (final table in tables) {
      data[table] = await db.query(table);
    }

    final json = const JsonEncoder.withIndent('  ').convert(data);

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save LifeMate Backup',
      fileName: 'lifemate_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (path == null) return null;

    await File(path).writeAsString(json);
    return path;
  }

  static Future<bool> restore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return false;
    }

    final file = File(result.files.single.path!);
    final json = jsonDecode(await file.readAsString());

    if (json is! Map<String, dynamic>) {
      throw Exception('Invalid backup file');
    }

    final db = await AppDatabase.database;

    await db.transaction((txn) async {
      for (final table in tables) {
        final rows = json[table];

        if (rows is! List) continue;

        await txn.delete(table);

        for (final row in rows) {
          if (row is Map) {
            await txn.insert(
              table,
              Map<String, dynamic>.from(row),
            );
          }
        }
      }
    });

    return true;
  }
}
