import '../models/passage.dart';

/// One participant's answer to one [QuizQuestion].
class QuizAnswer {
  const QuizAnswer({
    required this.selectedIndex,
    required this.correct,
    required this.timeTaken,
  });

  final int selectedIndex;
  final bool correct;

  /// How long the participant spent on this question — the study needs
  /// per-question timing, not just a total.
  final Duration timeTaken;
}

/// Everything gathered while a participant works through one passage: the
/// reading itself, the comprehension quiz, the feedback form, SUS, and
/// NASA-TLX. Built once when reading finishes and threaded forward through
/// Quiz → Feedback → SUS → NASA-TLX → Thank You, each screen filling in its
/// own section before pushing the next.
class StudySession {
  StudySession({
    required this.sessionId,
    required this.passage,
    required this.readAloudWasOn,
    required this.readingDuration,
  });

  /// Primary key of this session's row in [AppDatabase.sessionsTable] —
  /// generated and the row inserted the moment reading starts, so every
  /// later stage (quiz, feedback, SUS, NASA-TLX) has somewhere to log
  /// against.
  final String sessionId;

  final Passage passage;

  /// Whether read-aloud was switched on at the moment the participant
  /// finished reading — the "reading condition" the quiz screen reports.
  final bool readAloudWasOn;

  final Duration readingDuration;

  final List<QuizAnswer> quizAnswers = [];

  int get quizScore => quizAnswers.where((a) => a.correct).length;

  Duration get quizDuration => quizAnswers.fold(
        Duration.zero,
        (total, a) => total + a.timeTaken,
      );

  /// "Was the reading easy?" 1–5 stars, null until answered.
  int? easeStars;

  /// "Did read aloud help?" 1–5 stars, null until answered.
  int? audioHelpStars;

  final Set<String> helpfulSettings = {};

  String suggestion = '';

  /// Ten 1–5 Likert responses, in SUS item order. Zero means unanswered.
  final List<int> susAnswers = List.filled(10, 0);

  bool get susComplete => susAnswers.every((r) => r >= 1 && r <= 5);

  /// Standard SUS scoring: odd items contribute `(response - 1)`, even items
  /// contribute `(5 - response)`; the sum of contributions, out of a possible
  /// 40, is scaled by 2.5 to a 0–100 score.
  double get susScore {
    if (!susComplete) return 0;
    var total = 0;
    for (var i = 0; i < susAnswers.length; i++) {
      final r = susAnswers[i];
      total += i.isEven ? (r - 1) : (5 - r);
    }
    return total * 2.5;
  }

  /// NASA-TLX subscale ratings, 0–100, keyed by subscale name.
  final Map<String, int> tlx = {};
}
