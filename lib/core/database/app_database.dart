import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'lifemate.db');

    return openDatabase(
      path,
      version: 5,

      onCreate: (db, version) async {
        // To-Do
        await db.execute('''
          CREATE TABLE todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // Notes
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            pinned INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Income
        await db.execute('''
          CREATE TABLE incomes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            category_id INTEGER,
            description TEXT,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Expense
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            category_id INTEGER,
            description TEXT,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Categories
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Events
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            event_date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Budgets
        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL DEFAULT 'expense',
            category_id INTEGER,
            period TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT
          )
        ''');

        // Profile
        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            email TEXT,
            address TEXT,
            photo_path TEXT,
            birth_date TEXT,
            gender TEXT,
            permanent_address TEXT,
            education TEXT,
            occupation TEXT,
            workplace TEXT,
            designation TEXT,
            blood_group TEXT,
            emergency_contact TEXT,
            about TEXT,
            skills TEXT,
            languages TEXT,
            training TEXT,
            experience TEXT,
            achievements TEXT,
            career_objective TEXT
          )
        ''');

        // Education - Multiple records
        await db.execute('''
          CREATE TABLE profile_education (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL DEFAULT 1,
            qualification TEXT NOT NULL,
            institution TEXT,
            subject TEXT,
            result TEXT,
            passing_year TEXT,
            start_year TEXT,
            end_year TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Training and Certifications - Multiple records
        await db.execute('''
          CREATE TABLE profile_training (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL DEFAULT 1,
            title TEXT NOT NULL,
            institution TEXT,
            duration TEXT,
            completion_year TEXT,
            certificate_details TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Work Experience - Multiple records
        await db.execute('''
          CREATE TABLE profile_experience (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL DEFAULT 1,
            designation TEXT NOT NULL,
            workplace TEXT,
            location TEXT,
            employment_type TEXT,
            start_date TEXT,
            end_date TEXT,
            is_current INTEGER NOT NULL DEFAULT 0,
            responsibilities TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Skills - Multiple records
        await db.execute('''
          CREATE TABLE profile_skills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL DEFAULT 1,
            skill_name TEXT NOT NULL,
            proficiency TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Languages - Multiple records
        await db.execute('''
          CREATE TABLE profile_languages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL DEFAULT 1,
            language_name TEXT NOT NULL,
            proficiency TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Achievements - Multiple records
        await db.execute('''
          CREATE TABLE profile_achievements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL DEFAULT 1,
            title TEXT NOT NULL,
            description TEXT,
            achievement_date TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Notifications
        await db.execute('''
          CREATE TABLE notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Backups
        await db.execute('''
          CREATE TABLE backups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        // Version 1 -> Version 2
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE profiles ADD COLUMN birth_date TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN gender TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN permanent_address TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN education TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN occupation TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN workplace TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN designation TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN blood_group TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN emergency_contact TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN about TEXT',
          );
        }

        // Version 2 -> Version 3
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE budgets ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'",
          );

          await db.execute(
            'ALTER TABLE budgets ADD COLUMN category_id INTEGER',
          );
        }

        // Version 3 -> Version 4
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE profiles ADD COLUMN skills TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN languages TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN training TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN experience TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN achievements TEXT',
          );

          await db.execute(
            'ALTER TABLE profiles ADD COLUMN career_objective TEXT',
          );
        }

        // Version 4 -> Version 5
        if (oldVersion < 5) {
          // Education
          await db.execute('''
            CREATE TABLE profile_education (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL DEFAULT 1,
              qualification TEXT NOT NULL,
              institution TEXT,
              subject TEXT,
              result TEXT,
              passing_year TEXT,
              start_year TEXT,
              end_year TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          // Training
          await db.execute('''
            CREATE TABLE profile_training (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL DEFAULT 1,
              title TEXT NOT NULL,
              institution TEXT,
              duration TEXT,
              completion_year TEXT,
              certificate_details TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          // Work Experience
          await db.execute('''
            CREATE TABLE profile_experience (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL DEFAULT 1,
              designation TEXT NOT NULL,
              workplace TEXT,
              location TEXT,
              employment_type TEXT,
              start_date TEXT,
              end_date TEXT,
              is_current INTEGER NOT NULL DEFAULT 0,
              responsibilities TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          // Skills
          await db.execute('''
            CREATE TABLE profile_skills (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL DEFAULT 1,
              skill_name TEXT NOT NULL,
              proficiency TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          // Languages
          await db.execute('''
            CREATE TABLE profile_languages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL DEFAULT 1,
              language_name TEXT NOT NULL,
              proficiency TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          // Achievements
          await db.execute('''
            CREATE TABLE profile_achievements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL DEFAULT 1,
              title TEXT NOT NULL,
              description TEXT,
              achievement_date TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  // Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
