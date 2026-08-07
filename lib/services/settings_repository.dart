import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Persists [ReadingSettings.toMap] per reader, so each participant's own
/// tuned configuration survives an app restart and a therapist's "Start
/// session" instead of everyone sharing one device-wide row.
///
/// A single JSON blob per row rather than a typed column per setting: the
/// settings map already has one stable shape ([ReadingSettings.toMap] /
/// [ReadingSettings.restoreFromMap]), so there is nothing a relational schema
/// would buy here that isn't extra migration work every time a setting is
/// added.
class SettingsRepository {
  static const _table = AppDatabase.settingsTable;

  Future<Map<String, Object?>?> load(String participantId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      _table,
      where: 'participant_id = ?',
      whereArgs: [participantId],
    );
    if (rows.isEmpty) return null;
    return (jsonDecode(rows.first['json'] as String) as Map<String, dynamic>)
        .cast<String, Object?>();
  }

  Future<void> save(String participantId, Map<String, Object?> settings) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      _table,
      {'participant_id': participantId, 'json': jsonEncode(settings)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
