import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../api/api_exception.dart';
import '../api/shohojpath_api.dart';
import 'app_database.dart';

enum SyncStatus { idle, syncing, offline, failed }

/// Pushes locally recorded sessions up to the backend.
///
/// The device stays the source of truth: a session is written to sqflite as it
/// happens and uploaded afterwards, so the study runs whether or not the server
/// is awake — which matters because free hosts sleep and take the better part
/// of a minute to wake, and a participant cannot be made to wait for that.
///
/// Upload is idempotent server-side (keyed on `session_id`), so a retry after a
/// dropped response is safe and no local "already uploaded" flag has to be kept
/// perfectly in step with the server.
class SyncService extends ChangeNotifier {
  SyncService({required ShohojpathApi api}) : _api = api;

  final ShohojpathApi _api;

  /// Sessions per request. Small enough that a flaky connection has a chance
  /// of completing one, large enough not to make 40 requests after a long
  /// offline stretch.
  static const int batchSize = 20;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncedAt;
  String? _lastError;
  int _pendingCount = 0;

  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  bool _running = false;

  SyncStatus get status => _status;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;
  int get pendingCount => _pendingCount;
  bool get isSyncing => _status == SyncStatus.syncing;

  Future<Database> get _db async => AppDatabase.instance.database;

  /// Starts watching the connection and syncs whenever it returns.
  void start() {
    _connectivity ??= Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        // Fire and forget: coming back online should not block whatever the
        // reader is doing.
        unawaited(syncNow());
      } else {
        _status = SyncStatus.offline;
        notifyListeners();
      }
    });
    unawaited(refreshPendingCount());
    unawaited(syncNow());
  }

  @override
  void dispose() {
    _connectivity?.cancel();
    super.dispose();
  }

  Future<void> refreshPendingCount() async {
    _pendingCount = (await _pendingSessionIds()).length;
    notifyListeners();
  }

  /// Uploads everything not yet acknowledged by the server.
  ///
  /// Safe to call at any time; overlapping calls collapse into the first.
  Future<bool> syncNow() async {
    if (_running) return false;
    _running = true;

    try {
      final pending = await _pendingSessionIds();
      _pendingCount = pending.length;
      if (pending.isEmpty) {
        _status = SyncStatus.idle;
        notifyListeners();
        return true;
      }

      _status = SyncStatus.syncing;
      _lastError = null;
      notifyListeners();

      for (var i = 0; i < pending.length; i += batchSize) {
        final slice = pending.sublist(
          i,
          (i + batchSize).clamp(0, pending.length),
        );
        final payload = <Map<String, dynamic>>[];
        for (final id in slice) {
          final row = await _buildSessionPayload(id);
          if (row != null) payload.add(row);
        }
        if (payload.isEmpty) continue;

        final result = await _api.uploadSessions(payload);
        final synced = List<String>.from(
          (result['session_ids'] as List?) ?? const [],
        );
        await _markSynced(synced);
      }

      _lastSyncedAt = DateTime.now();
      _status = SyncStatus.idle;
      await refreshPendingCount();
      return true;
    } on ApiException catch (e) {
      // Offline is the expected state, not a failure worth alarming about.
      _status = e.statusCode == null ? SyncStatus.offline : SyncStatus.failed;
      _lastError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = SyncStatus.failed;
      _lastError = '$e';
      notifyListeners();
      return false;
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  /// Sessions that have not been acknowledged by the server yet.
  ///
  /// Only finished sessions are sent: one still in progress would upload with
  /// a null reading time and have to be corrected on the next pass.
  Future<List<String>> _pendingSessionIds() async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.sessionsTable,
      columns: ['id'],
      where: 'synced_at IS NULL AND ended_at IS NOT NULL',
      orderBy: 'started_at ASC',
    );
    return rows.map((r) => r['id'] as String).toList();
  }

  Future<void> _markSynced(List<String> sessionIds) async {
    if (sessionIds.isEmpty) return;
    final db = await _db;
    final stamp = DateTime.now().toUtc().toIso8601String();
    final placeholders = List.filled(sessionIds.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE ${AppDatabase.sessionsTable} SET synced_at = ? '
      'WHERE id IN ($placeholders)',
      [stamp, ...sessionIds],
    );
  }

  /// Assembles one session and all its child rows into the shape
  /// `/api/sync/sessions/` expects.
  Future<Map<String, dynamic>?> _buildSessionPayload(String sessionId) async {
    final db = await _db;

    final sessions = await db.query(
      AppDatabase.sessionsTable,
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (sessions.isEmpty) return null;
    final s = sessions.first;

    Future<List<Map<String, Object?>>> children(String table) => db.query(
          table,
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );

    final settingsChanges = await children(AppDatabase.settingsChangesTable);
    final pageTimes = await children(AppDatabase.pageTimesTable);
    final quizAnswers = await children(AppDatabase.quizAnswersTable);
    final susResponses = await children(AppDatabase.susResponsesTable);
    final tlxResponses = await children(AppDatabase.tlxResponsesTable);

    return {
      'session_id': s['id'],
      'participant_id': s['participant_id'],
      'passage_id': s['passage_id'],
      'started_at': s['started_at'],
      'ended_at': s['ended_at'],
      'profile': s['profile'] ?? '',
      'total_reading_seconds': s['total_reading_seconds'],
      'words_read': s['words_read'],
      // sqflite has no boolean column type, so this is stored as 0/1.
      'read_aloud_on': (s['read_aloud_on'] as int? ?? 0) == 1,
      'audio_duration_seconds': s['audio_duration_seconds'],
      'quiz_score': s['quiz_score'],
      'quiz_total': s['quiz_total'],
      'ease_stars': s['ease_stars'],
      'audio_help_stars': s['audio_help_stars'],
      'helpful_settings': s['helpful_settings'] ?? '',
      'suggestion': s['suggestion'] ?? '',
      'sus_score': s['sus_score'],
      'settings_changes': [
        for (final r in settingsChanges)
          {
            'at': r['at'],
            'key': r['key'],
            'old_value': r['old_value'] ?? '',
            'new_value': r['new_value'] ?? '',
            'profile': r['profile'],
          },
      ],
      'page_times': [
        for (final r in pageTimes)
          {'page_index': r['page_index'], 'seconds': r['seconds']},
      ],
      'quiz_answers': [
        for (final r in quizAnswers)
          {
            'question_index': r['question_index'],
            'selected_index': r['selected_index'],
            'correct': (r['correct'] as int? ?? 0) == 1,
            'time_seconds': r['time_seconds'],
          },
      ],
      'sus_responses': [
        for (final r in susResponses)
          {'item_index': r['item_index'], 'response': r['response']},
      ],
      'tlx_responses': [
        for (final r in tlxResponses)
          {'subscale': r['subscale'], 'value': r['value']},
      ],
    };
  }
}
