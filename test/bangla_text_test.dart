import 'package:flutter_test/flutter_test.dart';

import 'package:shohojpath/utils/bangla_text.dart';

void main() {
  group('findConjuncts', () {
    test('finds a simple two-consonant stack', () {
      final found = BanglaText.findConjuncts('ক্ষ');
      expect(found, hasLength(1));
      expect(found.single.text, 'ক্ষ');
      expect(found.single.start, 0);
      expect(found.single.end, 3);
    });

    test('finds every conjunct in a sentence, in order', () {
      final found = BanglaText.findConjuncts('বৃষ্টির দিনে ছোট্ট মিতু');
      expect(found.map((c) => c.text).toList(), ['ষ্ট', 'ট্ট']);
    });

    test('returns a stacked cluster once, not as overlapping pairs', () {
      // ন ্ ত ্ র — two hasants, one stack.
      final found = BanglaText.findConjuncts('মন্ত্র');
      expect(found, hasLength(1));
      expect(found.single.text, 'ন্ত্র');
    });

    test('ignores a hasant that is not between two consonants', () {
      // Word-final hasant (khanda-ta style) has no following consonant.
      expect(BanglaText.findConjuncts('উৎ'), isEmpty);
      expect(BanglaText.findConjuncts('আমার'), isEmpty);
    });

    test('treats ya-phala and ra-phala as conjuncts', () {
      expect(BanglaText.findConjuncts('বিদ্যুৎ').single.text, 'দ্য');
      expect(BanglaText.findConjuncts('দ্রুত').single.text, 'দ্র');
    });

    test('styleEnd extends over trailing vowel signs', () {
      // বারান্দার — the ন্দ stack is followed by া, which belongs to the same
      // syllable and must be underlined with it.
      final cluster = BanglaText.findConjuncts('বারান্দার').single;
      expect(cluster.text, 'ন্দ');
      expect(cluster.styleEnd, cluster.end + 1);
    });

    test('recognises the nukta letters as consonants', () {
      expect(BanglaText.isConsonant('ড়'.codeUnitAt(0)), isTrue);
      expect(BanglaText.isConsonant('য়'.codeUnitAt(0)), isTrue);
      expect(BanglaText.isConsonant('ৎ'.codeUnitAt(0)), isTrue);
    });
  });

  group('ConjunctCluster', () {
    test('splitForm inserts a ZWNJ', () {
      expect(BanglaText.findConjuncts('ক্ষ').single.splitForm, 'ক্‌ষ');
    });

    test('decomposition reads as the teaching label', () {
      expect(BanglaText.findConjuncts('ক্ষ').single.decomposition, 'ক্‌ + ষ');
      expect(BanglaText.findConjuncts('মন্ত্র').single.decomposition,
          'ন্‌ + ত্‌ + র');
    });

    test('letters lists the constituents', () {
      expect(BanglaText.findConjuncts('ষ্ট').single.letters, ['ষ', 'ট']);
    });
  });

  group('split', () {
    test('inserts ZWNJ after the hasant in a conjunct', () {
      expect(BanglaText.split('ক্ষ'), 'ক্‌ষ');
      expect(BanglaText.split('বৃষ্টি'), 'বৃষ্‌টি');
    });

    test('is idempotent', () {
      final once = BanglaText.split('লক্ষ্য');
      expect(BanglaText.split(once), once);
    });

    test('leaves text without conjuncts alone', () {
      expect(BanglaText.split('আমার'), 'আমার');
    });

    test('join undoes split', () {
      expect(BanglaText.join(BanglaText.split('বারান্দার')), 'বারান্দার');
    });

    test('never changes the length of the stored text it was given', () {
      const source = 'সন্ধ্যায় মা জিজ্ঞেস করলেন';
      final split = BanglaText.split(source);
      expect(split, isNot(source));
      expect(BanglaText.join(split), source);
    });
  });

  group('words', () {
    test('splits on spaces and punctuation', () {
      final found = BanglaText.words('মিতু হাত নাড়ল।');
      expect(found, hasLength(3));
      expect('মিতু হাত নাড়ল।'.substring(found[0].start, found[0].end), 'মিতু');
      expect('মিতু হাত নাড়ল।'.substring(found[2].start, found[2].end), 'নাড়ল');
    });
  });

  group('syllableBreaks', () {
    List<String> segment(String word) {
      final range = BanglaText.words(word).single;
      final breaks = BanglaText.syllableBreaks(word, range);
      final parts = <String>[];
      var cursor = range.start;
      for (final b in breaks) {
        parts.add(word.substring(cursor, b));
        cursor = b;
      }
      parts.add(word.substring(cursor, range.end));
      return parts;
    }

    test('segments a long word at consonant cluster starts', () {
      expect(segment('বারান্দার'), ['বা', 'রা', 'ন্দা', 'র']);
    });

    test('keeps a conjunct stack together', () {
      // The ন্দ stack must not be cut between ন and দ.
      expect(segment('বারান্দার').any((p) => p.contains('ন্দ')), isTrue);
    });

    test('leaves short words alone', () {
      final range = BanglaText.words('মিতু').single;
      expect(BanglaText.syllableBreaks('মিতু', range), isEmpty);
    });
  });
}
