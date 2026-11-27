
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    'money_records',
    'money_payments',
  ];

  // =========================
  // BACKUP
  // =========================

  static Future<String?> backup() async {
    final db = await AppDatabase.database;

    final data = <String, dynamic>{};

    for (final table in tables) {
      try {
        data[table] = await db.query(table);
      } catch (_) {
        // Skip a table if it does not exist in this database version.
        data[table] = [];
      }
    }

    final json = const JsonEncoder.withIndent('  ').convert(data);

    final bytes = Uint8List.fromList(
      utf8.encode(json),
    );

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save LifeMate Backup',
      fileName: 'lifemate_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    if (path == null) {
      return null;
    }

    // FilePicker saves the supplied bytes itself.
    return path;
  }

  // =========================
  // RESTORE
  // =========================

  static Future<bool> restore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return false;
    }

    final selectedFile = result.files.single;

    String jsonString;

    if (selectedFile.bytes != null) {
      // Android and iOS
      jsonString = utf8.decode(selectedFile.bytes!);
    } else if (selectedFile.path != null) {
      // Desktop fallback
      final file = File(selectedFile.path!);
      jsonString = await file.readAsString();
    } else {
      throw Exception('Unable to read the selected backup file.');
    }

    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid backup file.');
    }

    final db = await AppDatabase.database;

    await db.transaction((txn) async {
      for (final table in tables) {
        final rows = decoded[table];

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
