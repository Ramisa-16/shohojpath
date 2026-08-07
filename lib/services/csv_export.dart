import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// Exports every table [SessionLogger] writes to as its own CSV — one row
/// per session in `sessions.csv`, one row per settings change, page, quiz
/// answer, SUS item and NASA-TLX subscale in the rest. Kept as separate
/// files rather than one merged sheet: the child tables are one-to-many
/// against a session, so flattening them into `sessions.csv` would mean
/// either repeating every session's summary columns on every quiz-answer row
/// or losing the per-item detail — a spreadsheet tool can join these back on
/// `session_id` far more cleanly than this app could guess the right shape.
class CsvExport {
  static const Map<String, List<String>> _tables = {
    AppDatabase.sessionsTable: [
      'id',
      'participant_id',
      'passage_id',
      'started_at',
      'ended_at',
      'profile',
      'total_reading_seconds',
      'words_read',
      'read_aloud_on',
      'audio_duration_seconds',
      'quiz_score',
      'quiz_total',
      'ease_stars',
      'audio_help_stars',
      'helpful_settings',
      'suggestion',
      'sus_score',
    ],
    AppDatabase.settingsChangesTable: [
      'session_id',
      'at',
      'key',
      'old_value',
      'new_value',
      'profile',
    ],
    AppDatabase.pageTimesTable: ['session_id', 'page_index', 'seconds'],
    AppDatabase.quizAnswersTable: [
      'session_id',
      'question_index',
      'selected_index',
      'correct',
      'time_seconds',
    ],
    AppDatabase.susResponsesTable: ['session_id', 'item_index', 'response'],
    AppDatabase.tlxResponsesTable: ['session_id', 'subscale', 'value'],
  };

  /// Writes every table to a CSV file in the temp directory and returns the
  /// files — ready to hand to the share sheet. Temp rather than documents:
  /// these are throwaway copies of what's already durably in the database,
  /// regenerated fresh on every export.
  static Future<List<File>> exportAll() async {
    final db = await AppDatabase.instance.database;
    final dir = await getTemporaryDirectory();
    final files = <File>[];

    for (final entry in _tables.entries) {
      final rows = await db.query(entry.key);
      final buffer = StringBuffer()..writeln(entry.value.map(_field).join(','));
      for (final row in rows) {
        buffer.writeln(entry.value.map((c) => _field(row[c])).join(','));
      }
      final file = File(p.join(dir.path, '${entry.key}.csv'));
      await file.writeAsString(buffer.toString());
      files.add(file);
    }

    return files;
  }

  static String _field(Object? value) {
    if (value == null) return '';
    final s = value.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
