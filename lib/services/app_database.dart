import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// The single sqflite connection behind both [SettingsRepository] (the
/// participant's own settings, one JSON row) and [SessionLogger] (the
/// research data the study is actually collecting). One file, one schema,
/// one place that knows the version history — a setting-store migration and
/// a session-table migration would otherwise fight over the same
/// `shohojpath.db` if each service opened it independently.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const settingsTable = 'settings';
  static const sessionsTable = 'sessions';
  static const settingsChangesTable = 'settings_changes';
  static const pageTimesTable = 'page_times';
  static const quizAnswersTable = 'quiz_answers';
  static const susResponsesTable = 'sus_responses';
  static const tlxResponsesTable = 'tlx_responses';
  static const readersTable = 'readers';
  static const assignmentsTable = 'assignments';
  static const readerNotesTable = 'reader_notes';
  static const appConfigTable = 'app_config';

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'shohojpath.db');
    final db = await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await _createSettingsTable(db);
        await _createSessionTables(db);
        await _createTherapistTables(db);
        await _createAppConfigTable(db);
        await _ensureSampleReaders(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createSessionTables(db);
          await _createTherapistTables(db);
        }
        if (oldVersion < 3) {
          // Settings moved from a single device-wide row (id=0) to one row
          // per participant, so each reader keeps their own tuned settings
          // instead of sharing whoever used the device last. A prototype
          // research build with no participants mid-study yet — dropping
          // the old single row is simpler than migrating it to a made-up id.
          await db.execute('DROP TABLE IF EXISTS $settingsTable');
          await _createSettingsTable(db);
          await _createAppConfigTable(db);
        }
        if (oldVersion < 4) {
          await _ensureSampleReaders(db);
        }
        if (oldVersion < 5) {
          // createGuestReader used to write the participant id back as the
          // "name", so a guest reader showed the same string twice on the
          // picker and looked like a missing name. Fix any row still
          // carrying that bug before this fix landed.
          await db.rawUpdate(
            'UPDATE $readersTable SET name = ? WHERE name = participant_id',
            ['Guest'],
          );
        }
      },
    );
    _db = db;
    return db;
  }

  Future<void> _createSettingsTable(Database db) => db.execute(
        'CREATE TABLE IF NOT EXISTS $settingsTable (participant_id TEXT PRIMARY KEY, json TEXT NOT NULL)',
      );

  /// Small device-level key/value store — currently just the "Reader
  /// sign-in display" preference, but general enough for future app-wide
  /// toggles that aren't part of any one reader's [settingsTable] row.
  Future<void> _createAppConfigTable(Database db) => db.execute(
        'CREATE TABLE IF NOT EXISTS $appConfigTable (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );

  /// One row per reading session, filled in as the participant progresses —
  /// [SessionLogger.startSession] inserts it, and every later stage
  /// (finishing the passage, the quiz, feedback, SUS, submitting NASA-TLX)
  /// updates it in place, so a session abandoned partway through the study
  /// still leaves whatever was actually completed on disk.
  Future<void> _createSessionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $sessionsTable (
        id TEXT PRIMARY KEY,
        participant_id TEXT NOT NULL,
        passage_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        profile TEXT,
        total_reading_seconds REAL,
        words_read INTEGER,
        read_aloud_on INTEGER,
        audio_duration_seconds REAL,
        quiz_score INTEGER,
        quiz_total INTEGER,
        ease_stars INTEGER,
        audio_help_stars INTEGER,
        helpful_settings TEXT,
        suggestion TEXT,
        sus_score REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $settingsChangesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        at TEXT NOT NULL,
        key TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT,
        profile TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $pageTimesTable (
        session_id TEXT NOT NULL,
        page_index INTEGER NOT NULL,
        seconds REAL NOT NULL,
        PRIMARY KEY (session_id, page_index)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $quizAnswersTable (
        session_id TEXT NOT NULL,
        question_index INTEGER NOT NULL,
        selected_index INTEGER NOT NULL,
        correct INTEGER NOT NULL,
        time_seconds REAL NOT NULL,
        PRIMARY KEY (session_id, question_index)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $susResponsesTable (
        session_id TEXT NOT NULL,
        item_index INTEGER NOT NULL,
        response INTEGER NOT NULL,
        PRIMARY KEY (session_id, item_index)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tlxResponsesTable (
        session_id TEXT NOT NULL,
        subscale TEXT NOT NULL,
        value INTEGER NOT NULL,
        PRIMARY KEY (session_id, subscale)
      )
    ''');
  }

  /// A reader is a study participant registered by a therapist — the same
  /// `participant_id` that shows up on every row of [sessionsTable], just
  /// with the name/age/class a bare ID can't carry.
  Future<void> _createTherapistTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $readersTable (
        participant_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER,
        class_grade TEXT,
        school TEXT,
        notes TEXT,
        starting_profile TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $assignmentsTable (
        participant_id TEXT NOT NULL,
        passage_id TEXT NOT NULL,
        assigned_at TEXT NOT NULL,
        profile TEXT,
        PRIMARY KEY (participant_id, passage_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $readerNotesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participant_id TEXT NOT NULL,
        at TEXT NOT NULL,
        text TEXT NOT NULL
      )
    ''');
  }

  /// Tops the readers table up to at least 3 sample entries, so a fresh
  /// device's tap-to-choose picker reads as an actual list rather than one
  /// lonely guest entry named after its own participant id — and so an
  /// already-running test device (with, say, one guest "P-01" from earlier
  /// testing) gains company on upgrade too, without colliding with whatever
  /// ids already exist. Real study use replaces these via the therapist's
  /// own "Add Reader" screen.
  Future<void> _ensureSampleReaders(Database db) async {
    final existing = await db.query(readersTable);
    var missing = 3 - existing.length;
    if (missing <= 0) return;

    final existingIds = existing.map((r) => r['participant_id'] as String).toSet();
    final now = DateTime.now().toUtc().toIso8601String();
    var nextNumber = 1;

    for (final (name, age, classGrade) in [
      ('মিতু রহমান', 11, 'Class 5'),
      ('রাফি ইসলাম', 9, 'Class 3'),
      ('সাদিয়া আক্তার', 10, 'Class 4'),
    ]) {
      if (missing <= 0) break;
      String id;
      do {
        id = 'P-${nextNumber.toString().padLeft(2, '0')}';
        nextNumber++;
      } while (existingIds.contains(id));
      existingIds.add(id);

      await db.insert(readersTable, {
        'participant_id': id,
        'name': name,
        'age': age,
        'class_grade': classGrade,
        'starting_profile': 'recommended',
        'created_at': now,
      });
      missing--;
    }
  }
}
