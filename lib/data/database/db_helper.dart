import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  Future<Database> getDatabase(String masterKey) async {
    if (_database != null) return _database!;

    _database = await _initDatabase(masterKey);
    return _database!;
  }

  Future<Database> _initDatabase(String masterKey) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'peek_a_key.db');

    return await openDatabase(
      path,
      password: masterKey,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
            CREATE TABLE accounts(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                service_name TEXT NOT NULL,
                username TEXT NOT NULL,
                encrypted_password TEXT NOT NULL
            )
            ''');
  }

  Future<int> insertAccount(Map<String, dynamic> row) async {
    if (_database == null) throw Exception("Database not initialized");
    return await _database!.insert('accounts', row);
  }

  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    if (_database == null) throw Exception("Database not initialized");
    return await _database!.query('accounts', orderBy: 'service_name ASC');
  }

  Future<int> updateAccount(Map<String, dynamic> row) async {
    if (_database == null) throw Exception("Database not initialized");
    int id = row['id'];
    return await _database!.update(
      'accounts',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAccount(int id) async {
    if (_database == null) throw Exception("Database not initialized");
    return await _database!.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> rekeyDatabase(String newPassword) async {
    if (_database == null) throw Exception("Database not initialized");

    final escapedPassword = newPassword.replaceAll("'", "''");
    await _database!.execute("PRAGMA rekey = '$escapedPassword';");
  }

  /// Recreate the database using [newPassword] and insert [rows].
  ///
  /// This is a safer alternative to PRAGMA rekey which can fail on some
  /// platform/sqlcipher configurations. The [rows] should contain map entries
  /// matching the `accounts` table columns (service_name, username,
  /// encrypted_password). The existing database file will be replaced.
  Future<void> recreateDatabaseWithRows(
    String newPassword,
    List<Map<String, dynamic>> rows,
  ) async {
    // Close existing DB first
    await closeDatabase();

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'peek_a_key.db');

    // Delete existing file (keep it simple; caller should ensure backup if needed)
    try {
      await deleteDatabase(path);
    } catch (_) {}

    // Open a fresh database encrypted with the new password
    _database = await openDatabase(
      path,
      password: newPassword,
      version: 1,
      onCreate: _createDB,
    );

    // Insert provided rows
    final batch = _database!.batch();
    for (final row in rows) {
      batch.insert('accounts', row);
    }
    await batch.commit(noResult: true);
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
