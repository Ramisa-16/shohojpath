import 'package:flutter/foundation.dart';

import 'bangla_text.dart';
import 'display_mapping.dart';

/// The result of analysing one paragraph under a given set of reading
/// settings: what to lay out, where the conjuncts are, and how to get back to
/// the stored text.
@immutable
class PreparedParagraph {
  const PreparedParagraph({
    required this.mapping,
    required this.conjuncts,
    required this.words,
  });

  final DisplayMapping mapping;

  /// Conjuncts in **original** offsets. Convert with [DisplayMapping.toDisplay]
  /// before styling.
  final List<ConjunctCluster> conjuncts;

  /// Word ranges in **original** offsets.
  final List<TextUnitRange> words;

  String get original => mapping.original;
  String get display => mapping.display;

  /// The conjunct whose styled range covers [originalOffset], if any.
  ConjunctCluster? conjunctAt(int originalOffset) {
    for (final c in conjuncts) {
      if (originalOffset >= c.start && originalOffset < c.styleEnd) return c;
    }
    return null;
  }

  /// The conjunct at a **display** offset — what a tap gives us.
  ConjunctCluster? conjunctAtDisplay(int displayOffset) =>
      conjunctAt(mapping.toOriginal(displayOffset));
}

/// Turns stored passage text into displayable text.
///
/// Both transforms are pure insertions, which is what makes the offset map in
/// [DisplayMapping] possible — nothing is ever deleted or reordered, so the
/// source text a participant reads is byte-for-byte the text recorded in the
/// study material regardless of which aids they had switched on.
abstract final class PassageTransform {
  /// U+00B7 MIDDLE DOT, the syllable separator.
  ///
  /// A visible mark is the point: a zero-width break would satisfy the code but
  /// show the reader nothing. It is emitted as its own styled span so it can be
  /// drawn lighter than the text it segments.
  static const String syllableDot = '·';

  static PreparedParagraph prepare(
    String text, {
    required bool splitConjuncts,
    required bool syllableBreaks,
  }) {
    final conjuncts = BanglaText.findConjuncts(text);
    final words = BanglaText.words(text);

    if (!splitConjuncts && !syllableBreaks) {
      return PreparedParagraph(
        mapping: DisplayMapping.identity(text),
        conjuncts: conjuncts,
        words: words,
      );
    }

    // Collect the offsets that need a syllable dot in front of them, so the
    // single pass below can check membership cheaply.
    final breakOffsets = <int>{};
    if (syllableBreaks) {
      for (final word in words) {
        breakOffsets.addAll(BanglaText.syllableBreaks(text, word));
      }
    }

    final builder = DisplayMappingBuilder(text);
    final units = text.codeUnits;

    for (var i = 0; i < units.length; i++) {
      if (breakOffsets.contains(i)) {
        builder.insert(syllableDot, i, presentational: true);
      }

      builder.copy(i);

      if (!splitConjuncts) continue;
      if (units[i] != BanglaText.hasantCode) continue;

      final next = i + 1 < units.length ? units[i + 1] : -1;
      if (next == -1 ||
          next == BanglaText.zwnjCode ||
          next == BanglaText.zwjCode) {
        continue;
      }
      if (!BanglaText.isConsonant(next)) continue;

      // Anchored to i + 1: the ZWNJ belongs in front of the following letter,
      // so a caret landing on it resolves to that letter rather than the hasant
      // it trails.
      builder.insert(BanglaText.zwnj, i + 1);
    }

    return PreparedParagraph(
      mapping: builder.build(),
      conjuncts: conjuncts,
      words: words,
    );
  }
}
