import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Small device-level key/value settings — currently just "Reader sign-in
/// display" (see [ReaderSignInDisplay]) — that belong to the device/study
/// setup rather than to any one reader's [SettingsRepository] row.
class AppConfigRepository {
  static const _table = AppDatabase.appConfigTable;

  Future<String?> get(String key) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(_table, where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> set(String key, String value) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      _table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
