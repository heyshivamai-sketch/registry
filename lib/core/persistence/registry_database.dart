import 'package:sqflite/sqflite.dart';

/// On-device SQLite database for documents and subscriptions.
///
/// Version 1 stores document and subscription rows. Version 2 adds attachment
/// metadata plus ordered dynamic fields and renewal history.
abstract final class RegistryDatabase {
  static const int schemaVersion = 2;

  static Future<Database> open(String path) {
    return openDatabase(
      path,
      version: schemaVersion,
      singleInstance: true,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await applyMigrations(db, 0, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await applyMigrations(db, oldVersion, newVersion);
      },
    );
  }

  static Future<void> applyMigrations(
    DatabaseExecutor db,
    int from,
    int to,
  ) async {
    if (from < 1 && to >= 1) {
      await _createVersion1(db);
    }
    if (from < 2 && to >= 2) {
      await _upgradeToVersion2(db);
    }
  }

  static Future<void> _createVersion1(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        owner_name TEXT,
        issuing_authority TEXT,
        document_number TEXT,
        issue_date TEXT,
        expiry_date TEXT NOT NULL,
        action_date TEXT,
        impact TEXT NOT NULL,
        renewal_effort TEXT,
        cost_of_lapsing TEXT,
        dependency TEXT,
        expected_changes TEXT,
        notes TEXT,
        reminders TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        schema_id TEXT NOT NULL,
        country_code TEXT,
        sort_rank INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE subscriptions (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        service_name TEXT NOT NULL,
        plan_name TEXT,
        category TEXT NOT NULL,
        minor_units INTEGER NOT NULL,
        currency_code TEXT NOT NULL,
        billing_cycle TEXT NOT NULL,
        next_payment_date TEXT NOT NULL,
        decide_by_date TEXT,
        auto_renew INTEGER NOT NULL,
        lifecycle TEXT NOT NULL,
        impact TEXT NOT NULL,
        reminders TEXT NOT NULL,
        notes TEXT,
        sort_rank INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _upgradeToVersion2(DatabaseExecutor db) async {
    await db.execute(
      'ALTER TABLE documents ADD COLUMN attachment_file_name TEXT',
    );
    await db.execute(
      'ALTER TABLE documents ADD COLUMN attachment_byte_length INTEGER',
    );
    await db.execute('''
      CREATE TABLE document_fields (
        document_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        field_id TEXT NOT NULL,
        field_key TEXT NOT NULL,
        custom_label TEXT,
        value TEXT NOT NULL,
        sensitive INTEGER NOT NULL,
        is_date INTEGER NOT NULL,
        is_custom INTEGER NOT NULL,
        PRIMARY KEY (document_id, position),
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE renewal_history (
        document_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        entry_id TEXT NOT NULL,
        renewed_on TEXT NOT NULL,
        previous_expiry_date TEXT NOT NULL,
        new_expiry_date TEXT NOT NULL,
        note TEXT,
        PRIMARY KEY (document_id, position),
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
  }
}
