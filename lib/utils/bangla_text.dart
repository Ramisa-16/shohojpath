import 'package:flutter/foundation.dart';

/// Bangla script analysis.
///
/// The research feature the whole prototype hangs on is conjunct handling:
/// বাংলা যুক্তাক্ষর fuse their constituent letters into a single unrecognisable
/// glyph (ক + ্ + ষ renders as ক্ষ), which is precisely the decoding step
/// readers with dyslexia struggle with. Inserting U+200C ZERO WIDTH NON-JOINER
/// after the hasant suppresses the ligature and forces the explicit-halant form
/// (ক্‌ষ), making the spelling visible.
abstract final class BanglaText {
  /// U+09CD BENGALI SIGN VIRAMA — locally called হসন্ত / hasant.
  static const String hasant = '্';
  static const int hasantCode = 0x09CD;

  /// U+200C ZERO WIDTH NON-JOINER. Breaks the conjunct ligature.
  static const String zwnj = '‌';
  static const int zwnjCode = 0x200C;

  /// U+200D ZERO WIDTH JOINER. Requests the *half* form; leave it alone.
  static const String zwj = '‍';
  static const int zwjCode = 0x200D;

  /// Consonants that can take part in a conjunct.
  ///
  /// The contiguous block ক (U+0995) … হ (U+09B9), plus ৎ khanda ta and the
  /// three nukta letters ড় ঢ় য় which are separate code points rather than
  /// base+nukta sequences.
  static bool isConsonant(int c) =>
      (c >= 0x0995 && c <= 0x09B9) ||
      c == 0x09CE ||
      (c >= 0x09DC && c <= 0x09DF && c != 0x09DE);

  /// Dependent signs that hang off the preceding consonant cluster: vowel
  /// signs (া ি ী ু ূ ৃ ে ৈ ো ৌ), the ৗ length mark, nukta, and the
  /// chandrabindu / anusvara / visarga trio.
  static bool isCombiningMark(int c) =>
      (c >= 0x09BE && c <= 0x09CC) ||
      c == 0x09D7 ||
      c == 0x09BC ||
      (c >= 0x0981 && c <= 0x0983);

  /// Independent vowels অ … ঔ.
  static bool isIndependentVowel(int c) => c >= 0x0985 && c <= 0x0994;

  /// Anything in the Bengali block, plus the two joiners.
  static bool isBanglaCodeUnit(int c) =>
      (c >= 0x0980 && c <= 0x09FF) || c == zwnjCode || c == zwjCode;

  /// True for characters that belong to a word rather than separating one.
  static bool isWordCharacter(int c) =>
      isBanglaCodeUnit(c) ||
      (c >= 0x0030 && c <= 0x0039) ||
      (c >= 0x0041 && c <= 0x005A) ||
      (c >= 0x0061 && c <= 0x007A);

  /// Every যুক্তাক্ষর in [text], in order of appearance.
  ///
  /// A conjunct is a hasant sitting between two consonants. Stacked clusters
  /// (ন্ত্র = ন ্ ত ্ র) come back as one cluster, not two overlapping ones.
  static List<ConjunctCluster> findConjuncts(String text) {
    final units = text.codeUnits;
    final clusters = <ConjunctCluster>[];

    for (var i = 1; i < units.length - 1; i++) {
      if (units[i] != hasantCode) continue;
      if (!isConsonant(units[i - 1]) || !isConsonant(units[i + 1])) continue;

      // Walk left over any earlier links of the same stack.
      var start = i - 1;
      while (start - 2 >= 0 &&
          units[start - 1] == hasantCode &&
          isConsonant(units[start - 2])) {
        start -= 2;
      }

      // Walk right over any later links.
      var end = i + 1;
      while (end + 2 < units.length &&
          units[end + 1] == hasantCode &&
          isConsonant(units[end + 2])) {
        end += 2;
      }

      // Trailing marks are not part of the cluster, but they do belong to the
      // same syllable — an underline that stops short of the া in ন্দা looks
      // broken, and a pre-base ি renders to the *left* of the cluster it
      // attaches to, so styling has to cover it as well.
      var styleEnd = end + 1;
      while (styleEnd < units.length && isCombiningMark(units[styleEnd])) {
        styleEnd++;
      }

      clusters.add(
        ConjunctCluster(
          start: start,
          end: end + 1,
          styleEnd: styleEnd,
          text: text.substring(start, end + 1),
        ),
      );

      // Continue past the stack we just consumed.
      i = end;
    }

    return clusters;
  }

  /// Inserts a ZWNJ after every hasant so conjuncts render split.
  ///
  /// Idempotent: a hasant already followed by ZWNJ (or by an explicit ZWJ,
  /// which the author used on purpose) is left untouched. A trailing hasant is
  /// left untouched too — it is already showing its explicit form.
  static String split(String input) {
    if (!input.contains(hasant)) return input;

    final out = StringBuffer();
    final units = input.codeUnits;
    for (var i = 0; i < units.length; i++) {
      final c = units[i];
      out.writeCharCode(c);
      if (c != hasantCode) continue;

      final next = i + 1 < units.length ? units[i + 1] : -1;
      if (next == -1 || next == zwnjCode || next == zwjCode) continue;
      if (!isConsonant(next)) continue;
      out.write(zwnj);
    }
    return out.toString();
  }

  /// Removes every ZWNJ, restoring the fused conjunct forms.
  static String join(String input) =>
      input.contains(zwnj) ? input.replaceAll(zwnj, '') : input;

  /// True when [text] contains at least one conjunct.
  static bool hasConjunct(String text) => findConjuncts(text).isNotEmpty;

  /// Word boundaries in [text], as ranges over its code units.
  static List<TextUnitRange> words(String text) {
    final units = text.codeUnits;
    final result = <TextUnitRange>[];
    var start = -1;
    for (var i = 0; i < units.length; i++) {
      final isWord = isWordCharacter(units[i]);
      if (isWord && start < 0) {
        start = i;
      } else if (!isWord && start >= 0) {
        result.add(TextUnitRange(start, i));
        start = -1;
      }
    }
    if (start >= 0) result.add(TextUnitRange(start, units.length));
    return result;
  }

  /// Offsets inside [range] of [text] where a syllable break may be shown.
  ///
  /// Bangla syllables are consonant-initial: each new consonant cluster starts
  /// one. So the break points are the cluster starts after the first, where a
  /// "cluster start" is a consonant not immediately preceded by a hasant (that
  /// would make it the tail of the previous stack instead).
  ///
  /// This is a display aid, not a linguistic claim — it segments বারান্দার as
  /// বা·রা·ন্দা·র, which is what a teacher would write on a board.
  static List<int> syllableBreaks(
    String text,
    TextUnitRange range, {
    int minLength = 6,
    int minSyllables = 3,
  }) {
    final units = text.codeUnits;
    final starts = <int>[];
    for (var i = range.start; i < range.end; i++) {
      if (!isConsonant(units[i]) && !isIndependentVowel(units[i])) continue;
      if (i > range.start && units[i - 1] == hasantCode) continue;
      starts.add(i);
    }

    // Only long words get broken up — chopping short ones adds noise.
    if (starts.length < minSyllables) return const [];
    if (range.length < minLength) return const [];

    return starts.sublist(1);
  }
}

/// A যুক্তাক্ষর found in a passage, in offsets over the *original* text.
@immutable
class ConjunctCluster {
  const ConjunctCluster({
    required this.start,
    required this.end,
    required this.styleEnd,
    required this.text,
  });

  /// First code unit of the consonant stack.
  final int start;

  /// One past the last consonant of the stack.
  final int end;

  /// One past the last trailing combining mark — the range worth styling, so
  /// vowel signs belonging to the same syllable are underlined too.
  final int styleEnd;

  /// The stack itself, e.g. `ক্ষ`.
  final String text;

  /// The same cluster with ZWNJ inserted, e.g. `ক্‌ষ`.
  String get splitForm => BanglaText.split(text);

  /// The constituent letters, e.g. `['ক', 'ষ']`.
  List<String> get letters =>
      text.split(BanglaText.hasant).where((s) => s.isNotEmpty).toList();

  /// Read aloud as separate letters, e.g. `ক, ষ` — lets the reader hear the
  /// decomposition instead of the TTS engine resynthesising the fused
  /// conjunct sound.
  String get spokenForm => letters.join(', ');

  /// The teaching label used on the conjunct card: `ক্‌ + ষ`.
  String get decomposition {
    final parts = letters;
    if (parts.length < 2) return text;
    final head = parts
        .sublist(0, parts.length - 1)
        .map((l) => '$l${BanglaText.hasant}${BanglaText.zwnj}')
        .join(' + ');
    return '$head + ${parts.last}';
  }

  @override
  bool operator ==(Object other) =>
      other is ConjunctCluster && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ConjunctCluster($text @ $start..$end)';
}

/// A half-open range over the code units of a string.
@immutable
class TextUnitRange {
  const TextUnitRange(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start;
  bool contains(int offset) => offset >= start && offset < end;

  @override
  bool operator ==(Object other) =>
      other is TextUnitRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end)';
}
