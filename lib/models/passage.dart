import 'package:flutter/foundation.dart';

import '../utils/bangla_text.dart';

enum PassageDifficulty {
  easy(id: 'easy', label: 'Easy', labelBn: 'সহজ'),
  medium(id: 'medium', label: 'Medium', labelBn: 'মাঝারি'),
  hard(id: 'hard', label: 'Hard', labelBn: 'কঠিন');

  const PassageDifficulty({
    required this.id,
    required this.label,
    required this.labelBn,
  });

  final String id;
  final String label;
  final String labelBn;
}

/// One screenful of a passage. The design paginates rather than scrolling a
/// whole story, so reading time per page is a usable measure.
@immutable
class PassagePage {
  const PassagePage(this.paragraphs);

  final List<String> paragraphs;

  int get wordCount =>
      paragraphs.fold(0, (n, p) => n + BanglaText.words(p).length);

  List<ConjunctCluster> get conjuncts =>
      paragraphs.expand(BanglaText.findConjuncts).toList();
}

/// A reading text plus the metadata the study needs about it.
@immutable
class Passage {
  const Passage({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.pages,
  });

  final String id;
  final String title;
  final String category;
  final PassageDifficulty difficulty;
  final int estimatedMinutes;
  final List<PassagePage> pages;

  int get pageCount => pages.length;

  int get wordCount => pages.fold(0, (n, p) => n + p.wordCount);

  /// Distinct conjuncts across the whole passage — reported so passages can be
  /// matched for conjunct density when swapping in real study material.
  List<String> get distinctConjuncts {
    final seen = <String>{};
    for (final page in pages) {
      for (final c in page.conjuncts) {
        seen.add(c.text);
      }
    }
    return seen.toList()..sort();
  }

  String get subtitle => '$category · ${difficulty.label}';
}
