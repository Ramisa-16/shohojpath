import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the localisation against slow erosion.
///
/// Every English literal in the app was replaced with a string-table lookup.
/// Nothing stops the next screen from typing `Text('Save')` again, and a
/// single English word on an otherwise Bangla screen is exactly the mixture
/// this work removed. This walks the source and fails if one comes back.
void main() {
  /// Text that reaches a reader's eyes, as opposed to code identifiers.
  final userFacing = RegExp(
    r"""(?:Text\(|label:\s*|title:\s*|subtitle:\s*|hint:\s*|hintText:\s*|tooltip:\s*|emptyTitle:\s*|emptyBody:\s*|caption:\s*|badge:\s*|description:\s*|confirmLabel:\s*)'([A-Z][A-Za-z][^']{3,})'""",
  );

  /// Names, not prose: font families, proper nouns and validated instrument
  /// titles that would stop being findable if translated.
  const allowed = {
    'Noto Sans', 'SolaimanLipi', 'Kalpurush', 'AdorshoLipi',
    'NotoSansBengali', 'AtkinsonHyperlegible', 'OpenDyslexic', 'BalooDa2',
    'Hind Siliguri',
    'NASA-TLX', 'System Usability Scale', 'Shohojpath',
    'Default', 'Recommended', 'Custom', // enum data, localised at display
    'White', 'Cream', 'Yellow', 'Dark', 'Contrast',
    'Easy', 'Medium', 'Hard',
    'Names', 'Participant IDs only', 'Off — therapist starts all sessions',
    'English',
  };

  /// Files that legitimately hold English: fallback copy the server replaces,
  /// the throwaway font probe, and the string table itself.
  const skipFiles = {
    'lib/l10n/app_strings.dart',
    'lib/data/mock_content.dart',
    'lib/screens/font_test_screen.dart',
  };

  test('no user-facing English literals outside the string table', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (skipFiles.contains(path)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;

        for (final match in userFacing.allMatches(line)) {
          final text = match.group(1)!;
          if (allowed.contains(text)) continue;
          // A string carrying only a proper noun or a unit is not prose.
          if (!text.contains(' ') && text.length < 6) continue;
          offenders.add('$path:${i + 1}  "$text"');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These should read from AppStrings so they follow the language '
          'setting:\n${offenders.join('\n')}',
    );
  });

  test('the English SUS wording is Brooke\'s original, unedited', () {
    // The 68-point benchmark this study compares against was established on
    // this exact wording. An item reworded "for clarity" is a different
    // instrument, and the comparison quietly stops meaning anything.
    final strings = File('lib/l10n/app_strings.dart').readAsStringSync();

    const original = [
      'I think that I would like to use this app frequently.',
      'I found the app unnecessarily complex.',
      'I thought the app was easy to use.',
      'I found the various functions in this app were well integrated.',
      'I thought there was too much inconsistency in this app.',
      'I found the app very cumbersome to use.',
      'I felt very confident using the app.',
    ];

    for (final item in original) {
      expect(strings.contains(item), isTrue, reason: 'SUS item reworded: $item');
    }
  });

  test('the Bangla SUS is present and scored the same way', () {
    // A working translation supplied by the research team, NOT a validated
    // one — it has had no forward/back translation or pilot. Scores from it
    // must be reported as coming from a non-validated translation rather than
    // held against 68 as though nothing changed. This test exists so that
    // caveat stays attached to the code.
    final strings = File('lib/l10n/app_strings.dart').readAsStringSync();

    expect(
      strings.contains('আমার মনে হয় আমি এই অ্যাপটি ঘনঘন ব্যবহার করতে চাইবো।'),
      isTrue,
    );
    expect(
      strings.contains('non-validated'),
      isTrue,
      reason: 'the caveat must stay next to the translation',
    );
  });
}
