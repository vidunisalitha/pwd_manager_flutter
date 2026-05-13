import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DBHelper {
    static final DBHelper instance = DBHelper._internal();
    static Database? _database;

    DBHelper._internal();

    Future<Database> getDatabase(String masterKey) async {
        if(_database != null) return _database!;

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
        await db.execute(
            '''
            CREATE TABLE accounts(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                service_name TEXT NOT NULL,
                username TEXT NOT NULL,
                encrypted_password TEXT NOT NULL
            )
            '''
        );
    }

    Future<int> insertAccount(Map<String, dynamic> row) async {
        if(_database == null) throw Exception("Database not initialized");
        return await _database!.insert('accounts', row);
    }

    Future<List<Map<String, dynamic>>> getAllAccounts() async {
        if(_database == null) throw Exception("Database not initialized");
        return await _database!.query('accounts', orderBy: 'service_name ASC');
    }

    Future<int> updateAccount(Map<String, dynamic> row) async {
        if(_database == null) throw Exception("Database not initialized");
        int id = row['id'];
        return await _database!.update(
            'accounts',
            row,
            where: 'id = ?',
            whereArgs: [id]
        );
    }

    Future<int> deleteAccount(int id) async {
        if(_database == null) throw Exception("Database not initialized");
        return await _database!.delete(
            'accounts',
            where: 'id = ?',
            whereArgs: [id]
        );
    }

    Future<void> closeDatabase() async {
        if(_database != null){
            await _database!.close();
            _database = null;
        }
    }
}