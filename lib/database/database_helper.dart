import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, fileName);

    return await openDatabase(
      path,
      version: 2, // Increment the version for migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add migration logic
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;'); // Enable foreign keys
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        default_category TEXT,
        custom_category_id INTEGER,
        amount REAL NOT NULL,
        description TEXT,
        timestamp TEXT NOT NULL,
        original_currency TEXT,
        original_amount REAL,
        FOREIGN KEY (custom_category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense'))
      )
    ''');

    // User financial summary
    await db.execute('''
      CREATE TABLE user_finances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        balance REAL NOT NULL DEFAULT 0,
        income REAL NOT NULL DEFAULT 0,
        expense REAL NOT NULL DEFAULT 0,
        preferred_currency TEXT NOT NULL DEFAULT 'KGS'
      )
    ''');

    // Insert default user_finances record
    await db.insert('user_finances', {
      'balance': 0.0,
      'income': 0.0,
      'expense': 0.0,
      'preferred_currency': 'KGS',
    });

    // Insert default categories
    const List<Map<String, dynamic>> defaultCategories = [
      {'name': 'food', 'type': 'expense'},
      {'name': 'transport', 'type': 'expense'},
      {'name': 'housing', 'type': 'expense'},
      {'name': 'utilities', 'type': 'expense'},
      {'name': 'entertainment', 'type': 'expense'},
      {'name': 'healthcare', 'type': 'expense'},
      {'name': 'education', 'type': 'expense'},
      {'name': 'shopping', 'type': 'expense'},
      {'name': 'other_expense', 'type': 'expense'},
      {'name': 'salary', 'type': 'income'},
      {'name': 'gift', 'type': 'income'},
      {'name': 'interest', 'type': 'income'},
      {'name': 'other_income', 'type': 'income'},
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Step 1: Create a new transactions table with the updated foreign key
      await db.execute('''
        CREATE TABLE transactions_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
          default_category TEXT,
          custom_category_id INTEGER,
          amount REAL NOT NULL,
          description TEXT,
          timestamp TEXT NOT NULL,
          original_currency TEXT,
          original_amount REAL,
          FOREIGN KEY (custom_category_id) REFERENCES categories(id) ON DELETE SET NULL
        )
      ''');

      // Step 2: Copy data from the old transactions table to the new one
      await db.execute('''
        INSERT INTO transactions_new (
          id, type, default_category, custom_category_id, amount, description, 
          timestamp, original_currency, original_amount
        )
        SELECT 
          id, type, default_category, custom_category_id, amount, description, 
          timestamp, original_currency, original_amount
        FROM transactions
      ''');

      // Step 3: Drop the old transactions table
      await db.execute('DROP TABLE transactions');

      // Step 4: Rename the new table to the original name
      await db.execute('ALTER TABLE transactions_new RENAME TO transactions');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}