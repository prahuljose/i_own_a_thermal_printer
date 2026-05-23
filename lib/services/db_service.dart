import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbService {
  DbService._();

  static Database? _db;

  static Future<void> init() async {
    _db = await openDatabase(
      join(await getDatabasesPath(), 'thermal_printer.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE print_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            preview TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            data_json TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> addHistory({
    required String type,
    required String preview,
  }) async {
    await _db!.insert('print_history', {
      'type': type,
      'preview': preview,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _db!.rawDelete('''
      DELETE FROM print_history WHERE id NOT IN (
        SELECT id FROM print_history ORDER BY id DESC LIMIT 100
      )
    ''');
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    return _db!.query('print_history', orderBy: 'id DESC');
  }

  static Future<void> clearHistory() async {
    await _db!.delete('print_history');
  }

  static Future<void> saveTemplate({
    required String type,
    required String name,
    required String dataJson,
  }) async {
    await _db!.insert('templates', {
      'type': type,
      'name': name,
      'data_json': dataJson,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getTemplates(String type) async {
    return _db!.query(
      'templates',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'id DESC',
    );
  }

  static Future<void> deleteTemplate(int id) async {
    await _db!.delete('templates', where: 'id = ?', whereArgs: [id]);
  }
}
