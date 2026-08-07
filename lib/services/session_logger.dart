import 'package:sqflite/sqflite.dart';

import '../models/reading_settings.dart';
import '../models/study_session.dart';
import 'app_database.dart';

/// Writes the research data the study is collecting to the local database,
/// one stage at a time.
///
/// Each stage is a separate write against the same session row rather than
/// one bulk write at the very end: NASA-TLX is explicitly optional and the
/// participant can back out at any point after finishing the passage, so a
/// session that never reaches "Submit session" still has its reading, quiz
/// and feedback data safely on disk instead of losing everything for want of
/// the last step.
class SessionLogger {
  Future<Database> get _db async => AppDatabase.instance.database;

  /// Whichever reading session is currently open, so [logSettingsChange] —
  /// registered once, globally, as a [SettingsChangeListener] — knows which
  /// session row a change belongs to without every call site having to pass
  /// it through. Null outside of an active reading session (settings
  /// changed from the Library or the Settings screen's reset button still
  /// get logged, just with no session to attribute them to).
  String? _activeSessionId;

  /// A fresh id for a session that is about to start. Split out from
  /// [startSession] (which does I/O) so a caller — [ReadingScreen] — can
  /// have the id synchronously, before the insert lands, and use it right
  /// away for page-time logging.
  String newSessionId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> startSession({
    required String sessionId,
    required String participantId,
    required String passageId,
    required ReadingProfile profile,
  }) async {
    _activeSessionId = sessionId;
    final db = await _db;
    await db.insert(AppDatabase.sessionsTable, {
      'id': sessionId,
      'participant_id': participantId,
      'passage_id': passageId,
      'started_at': DateTime.now().toUtc().toIso8601String(),
      'profile': profile.id,
    });
  }

  /// Clears the active-session marker if [sessionId] is still the current
  /// one — a safety net for [ReadingScreen.dispose] when a participant backs
  /// out of a passage without tapping Finish, so a later settings change
  /// elsewhere in the app doesn't get attributed to an abandoned session.
  void endActiveSession(String sessionId) {
    if (_activeSessionId == sessionId) _activeSessionId = null;
  }

  /// Logs one settings change with its timestamp, tied to whichever session
  /// is currently open. Registered directly as a [SettingsChangeListener] —
  /// see [ReadingSettings.addChangeObserver] in `main.dart`.
  Future<void> logSettingsChange(SettingsChange change) async {
    final db = await _db;
    await db.insert(AppDatabase.settingsChangesTable, {
      'session_id': _activeSessionId,
      'at': change.at.toUtc().toIso8601String(),
      'key': change.key,
      'old_value': change.from?.toString(),
      'new_value': change.to?.toString(),
      'profile': change.profile.id,
    });
  }

  Future<void> logPageTime(String sessionId, int pageIndex, Duration time) async {
    final db = await _db;
    await db.insert(
      AppDatabase.pageTimesTable,
      {
        'session_id': sessionId,
        'page_index': pageIndex,
        'seconds': time.inMilliseconds / 1000,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> finishReading({
    required String sessionId,
    required Duration totalReadingTime,
    required int wordsRead,
    required bool readAloudOn,
    required Duration audioDuration,
  }) async {
    endActiveSession(sessionId);
    final db = await _db;
    await db.update(
      AppDatabase.sessionsTable,
      {
        'ended_at': DateTime.now().toUtc().toIso8601String(),
        'total_reading_seconds': totalReadingTime.inMilliseconds / 1000,
        'words_read': wordsRead,
        'read_aloud_on': readAloudOn ? 1 : 0,
        'audio_duration_seconds': audioDuration.inMilliseconds / 1000,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> logQuizAnswers(String sessionId, List<QuizAnswer> answers) async {
    final db = await _db;
    final batch = db.batch();
    for (var i = 0; i < answers.length; i++) {
      final a = answers[i];
      batch.insert(
        AppDatabase.quizAnswersTable,
        {
          'session_id': sessionId,
          'question_index': i,
          'selected_index': a.selectedIndex,
          'correct': a.correct ? 1 : 0,
          'time_seconds': a.timeTaken.inMilliseconds / 1000,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    batch.update(
      AppDatabase.sessionsTable,
      {
        'quiz_score': answers.where((a) => a.correct).length,
        'quiz_total': answers.length,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    await batch.commit(noResult: true);
  }

  Future<void> logFeedback(
    String sessionId, {
    required int? easeStars,
    required int? audioHelpStars,
    required Set<String> helpfulSettings,
    required String suggestion,
  }) async {
    final db = await _db;
    await db.update(
      AppDatabase.sessionsTable,
      {
        'ease_stars': easeStars,
        'audio_help_stars': audioHelpStars,
        'helpful_settings': helpfulSettings.join('; '),
        'suggestion': suggestion,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> logSus(String sessionId, List<int> responses, double score) async {
    final db = await _db;
    final batch = db.batch();
    for (var i = 0; i < responses.length; i++) {
      batch.insert(
        AppDatabase.susResponsesTable,
        {'session_id': sessionId, 'item_index': i, 'response': responses[i]},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    batch.update(
      AppDatabase.sessionsTable,
      {'sus_score': score},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    await batch.commit(noResult: true);
  }

  Future<void> logTlx(String sessionId, Map<String, int> values) async {
    final db = await _db;
    final batch = db.batch();
    values.forEach((subscale, value) {
      batch.insert(
        AppDatabase.tlxResponsesTable,
        {'session_id': sessionId, 'subscale': subscale, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }

  Future<int> sessionCount() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM ${AppDatabase.sessionsTable}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> sessionCountFor(String participantId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${AppDatabase.sessionsTable} WHERE participant_id = ?',
      [participantId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// All session rows for one participant, most recent first — what a
  /// therapist's Reader Detail screen renders its Sessions tab from.
  Future<List<Map<String, Object?>>> sessionsFor(String participantId) async {
    final db = await _db;
    return db.query(
      AppDatabase.sessionsTable,
      where: 'participant_id = ?',
      whereArgs: [participantId],
      orderBy: 'started_at DESC',
    );
  }

  /// How many sessions (across every reader) started on or after [since] —
  /// the therapist dashboard's "sessions this week" tile.
  Future<int> sessionsSince(DateTime since) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${AppDatabase.sessionsTable} WHERE started_at >= ?',
      [since.toUtc().toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Mean SUS score across every session that has one — the therapist
  /// dashboard's "SUS average" tile. Null when nobody has completed SUS yet,
  /// so the caller can show "—" instead of a misleading 0.
  Future<double?> averageSusScore() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT AVG(sus_score) AS a FROM ${AppDatabase.sessionsTable} WHERE sus_score IS NOT NULL',
    );
    final value = result.first['a'];
    return value == null ? null : (value as num).toDouble();
  }

  /// Wipes every table this logger writes to — used only from the hidden
  /// researcher screen, between participants.
  Future<void> clearAllData() async {
    final db = await _db;
    final batch = db.batch();
    for (final table in [
      AppDatabase.settingsChangesTable,
      AppDatabase.pageTimesTable,
      AppDatabase.quizAnswersTable,
      AppDatabase.susResponsesTable,
      AppDatabase.tlxResponsesTable,
      AppDatabase.sessionsTable,
    ]) {
      batch.delete(table);
    }
    await batch.commit(noResult: true);
  }
}
