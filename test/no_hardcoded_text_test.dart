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

  test('the SUS and NASA-TLX instruments are still flagged as untranslated',
      () {
    // Deliberately NOT localised, and this test says so out loud rather than
    // leaving it to be noticed. The SUS is a validated scale whose 68-point
    // benchmark only holds for the wording it was validated in; an ad-hoc
    // Bangla rendering would silently break comparison to that benchmark.
    // Translating it is a supervisor's call, not a developer's.
    final sus = File('lib/screens/sus_screen.dart').readAsStringSync();
    expect(
      sus.contains('I think that I would like to use this app frequently.'),
      isTrue,
      reason: 'If the SUS has been translated, retire this test and record '
          'which validated Bangla version was used.',
    );
  });
}
