import 'package:flutter_test/flutter_test.dart';

import 'package:shohojpath/data/passages.dart';
import 'package:shohojpath/utils/bangla_text.dart';
import 'package:shohojpath/utils/passage_transform.dart';

/// The offset map is the load-bearing part of the display transform: TTS
/// reports progress in offsets over the string it was handed (the *original*),
/// while what the reader sees may have ZWNJ and syllable dots inserted. If the
/// map drifts, word highlighting lands on the wrong word and the session log
/// records positions that never existed.
void main() {
  const sample = 'ছোট্ট পাখি বারান্দার কোণে বসে আছে';

  group('identity transform', () {
    test('display equals original when both toggles are off', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: false,
        syllableBreaks: false,
      );
      expect(p.display, sample);
      expect(p.mapping.isIdentity, isTrue);
      expect(p.mapping.insertions, isEmpty);
    });

    test('conjuncts are still found', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: false,
        syllableBreaks: false,
      );
      expect(p.conjuncts.map((c) => c.text), containsAll(['ট্ট', 'ন্দ']));
    });
  });

  group('split conjuncts', () {
    test('never modifies the stored text', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: true,
        syllableBreaks: false,
      );
      expect(p.original, sample);
      expect(p.display, isNot(sample));
      expect(BanglaText.join(p.display), sample);
    });

    test('display is longer by exactly one ZWNJ per conjunct hasant', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: true,
        syllableBreaks: false,
      );
      final expected = BanglaText.split(sample).length;
      expect(p.display.length, expected);
    });

    test('every original offset round-trips', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: true,
        syllableBreaks: false,
      );
      for (var i = 0; i <= sample.length; i++) {
        expect(
          p.mapping.toOriginal(p.mapping.toDisplay(i)),
          i,
          reason: 'original offset $i did not survive the round trip',
        );
      }
    });

    test('a mapped range still selects the same source text', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: true,
        syllableBreaks: false,
      );
      for (final word in p.words) {
        final displayRange = p.mapping.toDisplayRange(word);
        final displayed =
            p.display.substring(displayRange.start, displayRange.end);
        expect(BanglaText.join(displayed),
            sample.substring(word.start, word.end));
      }
    });

    test('a display offset inside a conjunct resolves to that conjunct', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: true,
        syllableBreaks: false,
      );
      final cluster = p.conjuncts.firstWhere((c) => c.text == 'ন্দ');
      final displayStart = p.mapping.toDisplay(cluster.start);
      expect(p.conjunctAtDisplay(displayStart), cluster);
      expect(p.conjunctAtDisplay(displayStart + 1), cluster);
    });
  });

  group('syllable breaks', () {
    test('inserted dots are marked presentational', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: false,
        syllableBreaks: true,
      );
      expect(p.mapping.insertions, isNotEmpty);
      for (final r in p.mapping.insertions) {
        expect(p.display.substring(r.start, r.end),
            PassageTransform.syllableDot);
        expect(p.mapping.isInserted(r.start), isTrue);
      }
    });

    test('stripping the dots gives back the original', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: false,
        syllableBreaks: true,
      );
      expect(p.display.replaceAll(PassageTransform.syllableDot, ''), sample);
    });

    test('original offsets round-trip', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: false,
        syllableBreaks: true,
      );
      for (var i = 0; i <= sample.length; i++) {
        expect(p.mapping.toOriginal(p.mapping.toDisplay(i)), i);
      }
    });
  });

  group('both transforms together', () {
    test('round-trips across the whole sample story', () {
      for (final page in Passages.bristirDineMitu.pages) {
        for (final paragraph in page.paragraphs) {
          final p = PassageTransform.prepare(
            paragraph,
            splitConjuncts: true,
            syllableBreaks: true,
          );

          expect(p.original, paragraph);

          final stripped = BanglaText.join(p.display)
              .replaceAll(PassageTransform.syllableDot, '');
          expect(stripped, paragraph,
              reason: 'display text no longer reduces to the source');

          for (var i = 0; i <= paragraph.length; i++) {
            expect(p.mapping.toOriginal(p.mapping.toDisplay(i)), i);
          }
        }
      }
    });

    test('display offsets always map back inside the source', () {
      final p = PassageTransform.prepare(
        sample,
        splitConjuncts: true,
        syllableBreaks: true,
      );
      for (var i = 0; i <= p.display.length; i++) {
        final original = p.mapping.toOriginal(i);
        expect(original, inInclusiveRange(0, sample.length));
      }
    });
  });

  group('sample passage', () {
    test('has enough conjunct variety to be worth testing on', () {
      final conjuncts = Passages.bristirDineMitu.distinctConjuncts;
      expect(conjuncts.length, greaterThanOrEqualTo(10));
      expect(Passages.bristirDineMitu.pageCount, 6);
      expect(Passages.bristirDineMitu.wordCount, greaterThan(100));
    });
  });
}
