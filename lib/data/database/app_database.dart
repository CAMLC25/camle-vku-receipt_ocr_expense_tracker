import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database helper managing the SQLite database lifecycle, schema versioning,
/// table definitions, and indexes for offline receipt expense tracking.
class AppDatabase {
  static const String databaseName = 'expense_tracker.db';
  static const int databaseVersion = 1;

  static const String tableTransactions = 'transactions';

  // Singleton instance
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();
  factory AppDatabase() => instance;

  Database? _db;

  /// Visible for testing: inject an already-opened Database (e.g. sqflite_common_ffi in-memory).
  void setDatabaseForTesting(Database testDb) {
    _db = testDb;
  }

  /// Returns the singleton database handle, opening it if not already opened.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id TEXT PRIMARY KEY,
        merchant TEXT NOT NULL,
        description TEXT,
        amount INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'VND',
        transaction_date TEXT NOT NULL,
        transaction_time TEXT,
        transaction_type TEXT NOT NULL,
        category TEXT NOT NULL,
        payment_method TEXT,
        reference_number TEXT,
        notes TEXT,
        receipt_image_path TEXT,
        raw_ocr_text TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for accelerated queries and range aggregations
    await db.execute('''
      CREATE INDEX idx_transactions_date ON $tableTransactions(transaction_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_category ON $tableTransactions(category)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_type ON $tableTransactions(transaction_type)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration hooks for future schema versions
  }

  /// Closes the database if open.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
