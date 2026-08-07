import 'package:sqflite/sqflite.dart';

import '../models/reading_settings.dart';
import 'app_database.dart';

/// CRUD for the therapist side of the study: the readers (participants) a
/// therapist manages, the passages assigned to each, and the dated notes on
/// their progress. Everything here keys off the same `participant_id` used
/// in [AppDatabase.sessionsTable], so a reader's dashboard numbers are
/// computed from the sessions they actually logged, not a separate mock feed.
class ReaderRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  /// "Continue as Guest" on Login: a reader who never types an ID still
  /// needs one to attribute their session data to, so this mints the next
  /// available `P-##` (same numbering [AddReaderScreen] uses) and writes a
  /// minimal stub row — no age/class, no `starting_profile`, so
  /// [loadReaderProfile] falls back to the plain constructor default rather
  /// than a therapist-chosen condition nobody actually picked for this
  /// anonymous reader. Name is literally "Guest", never the participant id —
  /// a name that just repeats the ID back is indistinguishable from a
  /// missing name and reads as a bug on the reader picker.
  Future<String> createGuestReader() async {
    final existing = await readerCount();
    final participantId = 'P-${(existing + 1).toString().padLeft(2, '0')}';
    final db = await _db;
    await db.insert(AppDatabase.readersTable, {
      'participant_id': participantId,
      'name': 'Guest',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return participantId;
  }

  Future<void> addReader({
    required String participantId,
    required String name,
    int? age,
    String? classGrade,
    String? school,
    String? notes,
    required ReadingProfile startingProfile,
  }) async {
    final db = await _db;
    await db.insert(
      AppDatabase.readersTable,
      {
        'participant_id': participantId,
        'name': name,
        'age': age,
        'class_grade': classGrade,
        'school': school,
        'notes': notes,
        'starting_profile': startingProfile.id,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> allReaders() async {
    final db = await _db;
    return db.query(AppDatabase.readersTable, orderBy: 'created_at DESC');
  }

  /// Readers ordered by their most recent session's start time, falling
  /// back to registration time for a reader who has never had one — what
  /// the Login screen's tap-to-choose list and "Show all readers" screen
  /// use, so whoever read most recently surfaces first.
  Future<List<Map<String, Object?>>> readersByRecentActivity() async {
    final db = await _db;
    return db.rawQuery('''
      SELECT r.*, COALESCE(MAX(s.started_at), r.created_at) AS last_active
      FROM ${AppDatabase.readersTable} r
      LEFT JOIN ${AppDatabase.sessionsTable} s ON s.participant_id = r.participant_id
      GROUP BY r.participant_id
      ORDER BY last_active DESC
    ''');
  }

  Future<Map<String, Object?>?> reader(String participantId) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.readersTable,
      where: 'participant_id = ?',
      whereArgs: [participantId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> readerCount() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM ${AppDatabase.readersTable}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> assignPassage(
    String participantId,
    String passageId, {
    ReadingProfile? profile,
  }) async {
    final db = await _db;
    await db.insert(
      AppDatabase.assignmentsTable,
      {
        'participant_id': participantId,
        'passage_id': passageId,
        'assigned_at': DateTime.now().toUtc().toIso8601String(),
        'profile': profile?.id,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> unassignPassage(String participantId, String passageId) async {
    final db = await _db;
    await db.delete(
      AppDatabase.assignmentsTable,
      where: 'participant_id = ? AND passage_id = ?',
      whereArgs: [participantId, passageId],
    );
  }

  Future<List<String>> assignedPassageIds(String participantId) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.assignmentsTable,
      where: 'participant_id = ?',
      whereArgs: [participantId],
    );
    return rows.map((r) => r['passage_id'] as String).toList();
  }

  Future<void> addNote(String participantId, String text) async {
    final db = await _db;
    await db.insert(AppDatabase.readerNotesTable, {
      'participant_id': participantId,
      'at': DateTime.now().toUtc().toIso8601String(),
      'text': text,
    });
  }

  Future<List<Map<String, Object?>>> notesFor(String participantId) async {
    final db = await _db;
    return db.query(
      AppDatabase.readerNotesTable,
      where: 'participant_id = ?',
      whereArgs: [participantId],
      orderBy: 'at DESC',
    );
  }
}
