import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../api/shohojpath_api.dart';
import '../data/passages.dart';
import '../models/passage.dart';
import '../models/quiz_question.dart';

/// Study material, fetched from the backend and cached in memory.
///
/// Passages live on the server so a researcher can change them without
/// shipping a new APK. But a reading session must never depend on the network:
/// if the server cannot be reached, whatever was fetched earlier is reused,
/// and failing that the bundled sample story — a participant sitting down to
/// read must always have something to read.
class PassageRepository {
  PassageRepository(this._api);

  final ShohojpathApi _api;

  final Map<String, Passage> _passages = {};
  final Map<String, List<QuizQuestion>> _questions = {};
  List<Passage>? _library;

  /// True when the last fetch fell back to bundled content, so the Library can
  /// say so rather than silently showing a one-passage corpus.
  bool usingBundledFallback = false;

  /// The Library list. Summaries only — page bodies arrive with [passage].
  Future<List<Passage>> library({
    String? search,
    String? category,
    String? difficulty,
  }) async {
    try {
      final rows = await _api.passages(
        search: search,
        category: category,
        difficulty: difficulty,
      );
      final parsed = rows.map(_passageFromSummary).toList();
      usingBundledFallback = false;
      // Only an unfiltered fetch is a complete picture worth caching as "the
      // library"; a filtered one would poison the offline fallback.
      if ((search ?? '').isEmpty &&
          (category ?? '').isEmpty &&
          (difficulty ?? '').isEmpty) {
        _library = parsed;
      }
      return parsed;
    } on ApiException {
      usingBundledFallback = _library == null;
      return _library ?? Passages.all;
    }
  }

  Future<List<String>> categories() async {
    try {
      return await _api.passageCategories();
    } on ApiException {
      final seen = <String>{
        for (final p in _library ?? Passages.all) p.category,
      };
      return ['All', ...seen];
    }
  }

  /// Full text for one passage, with its comprehension questions.
  Future<Passage> passage(String id) async {
    try {
      final data = await _api.passage(id);
      final parsed = _passageFromDetail(data);
      _passages[parsed.id] = parsed;
      _questions[parsed.id] = _questionsFrom(data);
      return parsed;
    } on ApiException {
      final cached = _passages[id];
      if (cached != null) return cached;
      // Bundled fallback keeps a session possible with no connection at all.
      return Passages.all.firstWhere(
        (p) => p.id == id,
        orElse: () => Passages.bristirDineMitu,
      );
    }
  }

  /// Questions for a passage. Empty means the researcher has not authored any
  /// yet — the quiz screen must handle that rather than assume five.
  List<QuizQuestion> questionsFor(String passageId) =>
      _questions[passageId] ?? const [];

  Future<List<QuizQuestion>> loadQuestions(String passageId) async {
    if (_questions.containsKey(passageId)) return _questions[passageId]!;
    await passage(passageId);
    return _questions[passageId] ?? const [];
  }

  // ---- Parsing -----------------------------------------------------------

  Passage _passageFromSummary(Map<String, dynamic> row) => Passage(
        id: row['id'] as String,
        title: row['title'] as String? ?? '',
        category: row['category'] as String? ?? '',
        difficulty: _difficulty(row['difficulty'] as String?),
        estimatedMinutes: (row['estimated_minutes'] as num?)?.toInt() ?? 3,
        // A summary carries no page bodies; the Library only needs the count,
        // and the reader screen fetches the detail before it opens.
        pages: const [],
      );

  Passage _passageFromDetail(Map<String, dynamic> data) {
    final pages = <PassagePage>[];
    for (final page in (data['pages'] as List? ?? const [])) {
      final map = Map<String, dynamic>.from(page as Map);
      final paragraphs = List<String>.from(
        (map['paragraphs'] as List? ?? const []).map((p) => '$p'),
      );
      if (paragraphs.isNotEmpty) pages.add(PassagePage(paragraphs));
    }

    return Passage(
      id: data['id'] as String,
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? '',
      difficulty: _difficulty(data['difficulty'] as String?),
      estimatedMinutes: (data['estimated_minutes'] as num?)?.toInt() ?? 3,
      pages: pages,
    );
  }

  List<QuizQuestion> _questionsFrom(Map<String, dynamic> data) {
    final result = <QuizQuestion>[];
    for (final raw in (data['questions'] as List? ?? const [])) {
      final map = Map<String, dynamic>.from(raw as Map);
      final options = List<String>.from(
        (map['options'] as List? ?? const []).map((o) => '$o'),
      );
      if (options.length < 2) continue;

      final correct = (map['correct_index'] as num?)?.toInt() ?? 0;
      result.add(
        QuizQuestion(
          type: map['kind'] == 'true_false'
              ? QuestionType.trueFalse
              : QuestionType.multipleChoice,
          prompt: map['prompt'] as String? ?? '',
          options: options,
          // Clamped rather than trusted: a bad index would throw deep inside
          // the quiz, mid-session, in front of a participant.
          correctIndex: correct.clamp(0, options.length - 1),
        ),
      );
    }
    return result;
  }

  PassageDifficulty _difficulty(String? value) => switch (value) {
        'medium' => PassageDifficulty.medium,
        'hard' => PassageDifficulty.hard,
        _ => PassageDifficulty.easy,
      };

  @visibleForTesting
  void seed(Passage passage, List<QuizQuestion> questions) {
    _passages[passage.id] = passage;
    _questions[passage.id] = questions;
  }
}
