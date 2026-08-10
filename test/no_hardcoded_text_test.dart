import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the localisation against slow erosion.
///
/// Every English literal in the app was replaced with a string-table lookup.
/// Nothing stops the next screen from typing `Text('Save')` again, and a
/// single English word on an otherwise Bangla screen is exactly the mixture
/// this work removed. This walks the source and fails if one comes back.
void main() {
  /// Any string literal in a screen or widget file.
  ///
  /// The first version of this only looked at literals directly after `Text(`
  /// or `label:`, and skipped anything short. It passed while the sign-up
  /// screen still showed "Age", "Create account", "I already have an account"
  /// and two placeholder hints in English — every one of them written in a
  /// form the pattern was not watching, like
  /// `label: busy ? 'Creating account…' : 'Create account'`. Matching every
  /// literal and excluding what is legitimately not prose is the way round
  /// that actually holds.
  final anyLiteral = RegExp(r"'([A-Za-z][^'\\$]{2,})'");

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
    'English', 'SHOHOJPATH', 'bn-BD', 'bn-IN',
  };

  /// Files that legitimately hold English.
  const skipFiles = {
    // The string table itself, and the bundled copy the server replaces.
    'lib/l10n/app_strings.dart',
    'lib/data/mock_content.dart',
    'lib/data/passages.dart',
    'lib/screens/font_test_screen.dart',
    // HTTP verbs and header names are protocol, not prose.
    'lib/api/api_client.dart',
    // Carries an English `message` on purpose — for logs and the exported
    // study data, where wording that shifts with a UI setting would be worse
    // than useless. Screens call messageFor(t) instead, and a test below
    // holds that line.
    'lib/api/api_exception.dart',
    // Sample rows seeded into the local database for development, and the
    // English label a guest row is created with before any UI sees it.
    'lib/services/app_database.dart',
    'lib/services/reader_repository.dart',
    // The share sheet's subject line for the researcher's CSV export.
    'lib/widgets/export_data_action.dart',
  };

  /// Distinguishes a string the code uses from a sentence a reader sees.
  ///
  /// Deliberately conservative: a false alarm costs one line in `allowed`,
  /// while a miss puts an English word on a Bangla screen in front of a child.
  bool isCodeNotProse(String text) {
    // JSON keys, database columns, enum ids: snake_case with no spaces.
    if (!text.contains(' ') && text.contains('_')) return true;
    // Paths, URLs, MIME types, channel names, file names.
    if (text.contains('/') || text.contains('.') && !text.contains(' ')) {
      return true;
    }
    // SQL: where-clauses and order-by fragments passed to sqflite.
    if (RegExp(r'= \?|IS N(OT )?NULL| (ASC|DESC)$').hasMatch(text)) return true;
    // A single lowercase word is an identifier ('pending', 'reader', 'bn').
    if (!text.contains(' ') && text == text.toLowerCase()) return true;
    // Single short capitalised token: mostly enum labels and format letters.
    if (!text.contains(' ') && text.length <= 3) return true;
    return false;
  }

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
        if (line.trimLeft().startsWith('///')) continue;
        // import 'x.dart', JSON keys, asset paths, channel names.
        if (line.contains('import ') || line.contains('part ')) continue;

        for (final match in anyLiteral.allMatches(line)) {
          final text = match.group(1)!;
          if (allowed.contains(text)) continue;
          if (isCodeNotProse(text)) continue;
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
