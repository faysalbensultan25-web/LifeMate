
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
      version: 9,

      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

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

        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            event_date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

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

        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            email TEXT,
            address TEXT,
            location TEXT,
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
            career_objective TEXT,
            facebook TEXT,
            linkedin TEXT,
            github TEXT,
            website TEXT
          )
        ''');

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

        await db.execute('''
          CREATE TABLE profile_skills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL DEFAULT 1,
            skill_name TEXT NOT NULL,
            proficiency TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE profile_languages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL DEFAULT 1,
            language_name TEXT NOT NULL,
            proficiency TEXT,
            created_at TEXT NOT NULL
          )
        ''');

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

        await db.execute('''
          CREATE TABLE notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE backups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Receivable and Payable
        await _createMoneyTables(db);
      },

      onUpgrade: (db, oldVersion, newVersion) async {
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

        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE budgets ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'",
          );
          await db.execute(
            'ALTER TABLE budgets ADD COLUMN category_id INTEGER',
          );
        }

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

        if (oldVersion < 5) {
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

          await db.execute('''
            CREATE TABLE profile_skills (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL DEFAULT 1,
              skill_name TEXT NOT NULL,
              proficiency TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE profile_languages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL DEFAULT 1,
              language_name TEXT NOT NULL,
              proficiency TEXT,
              created_at TEXT NOT NULL
            )
          ''');

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

        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notifications (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              message TEXT NOT NULL,
              created_at TEXT NOT NULL,
              is_read INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }

        if (oldVersion < 7) {
          await db.execute(
            'ALTER TABLE profiles ADD COLUMN location TEXT',
          );
        }

        if (oldVersion < 8) {
          await db.execute(
            'ALTER TABLE profiles ADD COLUMN facebook TEXT',
          );
          await db.execute(
            'ALTER TABLE profiles ADD COLUMN linkedin TEXT',
          );
          await db.execute(
            'ALTER TABLE profiles ADD COLUMN github TEXT',
          );
          await db.execute(
            'ALTER TABLE profiles ADD COLUMN website TEXT',
          );
        }

        if (oldVersion < 9) {
          await _createMoneyTables(db);
        }
      },
    );
  }

  static Future<void> _createMoneyTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE money_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        person_name TEXT NOT NULL,
        phone TEXT,
        amount REAL NOT NULL,
        record_date TEXT NOT NULL,
        expected_date TEXT,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE money_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (record_id)
          REFERENCES money_records(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
