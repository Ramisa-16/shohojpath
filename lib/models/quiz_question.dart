import 'package:flutter/foundation.dart';

enum QuestionType { multipleChoice, trueFalse }

/// One comprehension question. True/False questions are just multiple
/// choice with a fixed two-option shape — [type] only changes how the
/// options render (a 2-up row instead of a stacked list).
@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final QuestionType type;
  final String prompt;
  final List<String> options;
  final int correctIndex;
}
