import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shohojpath/models/bangla_font.dart';
import 'package:shohojpath/models/reading_settings.dart';
import 'package:shohojpath/theme/reading_surface.dart';
import 'package:shohojpath/utils/bangla_text.dart';
import 'package:shohojpath/widgets/bangla_passage.dart';

/// These assert the claim the whole prototype rests on: the settings are not
/// decorative, they reach the glyphs. A passage that ignored one of them would
/// silently invalidate every session recorded under that condition.
void main() {
  const paragraph = 'ছোট্ট পাখি বারান্দার কোণে বসে আছে';

  late ReadingSettings settings;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ReadingSettings>.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(
            body: MediaQuery.withNoTextScaling(
              child: const SingleChildScrollView(
                child: BanglaPassage(paragraphs: [paragraph]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The span actually handed to the text engine.
  InlineSpan renderedSpan(WidgetTester tester) =>
      tester.widget<RichText>(find.byType(RichText).first).text;

  String renderedText(WidgetTester tester) =>
      renderedSpan(tester).toPlainText();

  setUp(() {
    settings = ReadingSettings(initialProfile: ReadingProfile.standard);
  });

  testWidgets('renders the stored text unchanged when no transform is on',
      (tester) async {
    await pump(tester);
    expect(renderedText(tester), paragraph);
  });

  testWidgets('typography settings reach the text style', (tester) async {
    settings
      ..fontSize = 30
      ..letterSpacingEm = 0.05
      ..wordSpacingEm = 0.2
      ..lineHeight = 2.0
      ..fontFamily = BanglaFont.kalpurush
      ..boldText = true;

    await pump(tester);

    final style = renderedSpan(tester).style!;
    expect(style.fontSize, 30);
    expect(style.fontFamily, 'Kalpurush');
    expect(style.fontWeight, FontWeight.w700);
    expect(style.height, 2.0);
    // em values are resolved against the live font size.
    expect(style.letterSpacing, closeTo(30 * 0.05, 0.001));
    expect(style.wordSpacing, closeTo(30 * 0.2, 0.001));
  });

  testWidgets('changing font size live re-resolves the spacing',
      (tester) async {
    settings
      ..fontSize = 20
      ..wordSpacingEm = 0.16;
    await pump(tester);
    expect(renderedSpan(tester).style!.wordSpacing, closeTo(20 * 0.16, 0.001));

    settings.fontSize = 40;
    await tester.pump();
    expect(renderedSpan(tester).style!.wordSpacing, closeTo(40 * 0.16, 0.001));
  });

  testWidgets('the reading surface supplies background and text colour',
      (tester) async {
    settings.surface = ReadingSurface.dark;
    await pump(tester);
    expect(renderedSpan(tester).style!.color, ReadingSurface.dark.text);
  });

  testWidgets('split conjuncts is a display transform only', (tester) async {
    await pump(tester);
    expect(renderedText(tester).contains(BanglaText.zwnj), isFalse);

    settings.splitConjuncts = true;
    await tester.pump();

    final displayed = renderedText(tester);
    expect(displayed.contains(BanglaText.zwnj), isTrue);
    // The source is recoverable, so nothing was actually rewritten.
    expect(BanglaText.join(displayed), paragraph);
  });

  testWidgets('highlight conjuncts underlines the clusters and nothing else',
      (tester) async {
    settings.highlightConjuncts = true;
    await pump(tester);

    final underlined = <String>[];
    renderedSpan(tester).visitChildren((span) {
      if (span is TextSpan &&
          span.style?.decoration == TextDecoration.underline) {
        underlined.add(span.text ?? '');
      }
      return true;
    });

    expect(underlined, isNotEmpty);
    // Every underlined run must contain a hasant — i.e. be a real conjunct.
    for (final run in underlined) {
      expect(run.contains(BanglaText.hasant), isTrue,
          reason: '"$run" was underlined but is not a conjunct');
    }
  });

  testWidgets('no underline when the toggle is off', (tester) async {
    settings.highlightConjuncts = false;
    await pump(tester);

    var found = false;
    renderedSpan(tester).visitChildren((span) {
      if (span is TextSpan &&
          span.style?.decoration == TextDecoration.underline) {
        found = true;
      }
      return true;
    });
    expect(found, isFalse);
  });

  testWidgets('syllable breaks insert visible separators', (tester) async {
    settings.syllableBreaks = true;
    await pump(tester);

    final displayed = renderedText(tester);
    expect(displayed.contains('·'), isTrue);
    expect(displayed.replaceAll('·', ''), paragraph);
  });

  testWidgets('tapping a conjunct reports the cluster', (tester) async {
    ConjunctCluster? tapped;
    settings
      ..fontSize = 40
      ..highlightConjuncts = true;

    await tester.pumpWidget(
      ChangeNotifierProvider<ReadingSettings>.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(
            body: MediaQuery.withNoTextScaling(
              child: SingleChildScrollView(
                child: BanglaPassage(
                  paragraphs: const [paragraph],
                  onConjunctTap: (cluster, _) => tapped = cluster,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Find where ট্ট actually landed rather than guessing a pixel: lay the
    // rendered span out again and ask for the caret at the cluster's start.
    final finder = find.byType(RichText).first;
    final rich = tester.widget<RichText>(finder);
    final painter = TextPainter(
      text: rich.text,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: tester.getSize(finder).width);

    final cluster = BanglaText.findConjuncts(paragraph).first;
    expect(cluster.text, 'ট্ট');
    final caret = painter.getOffsetForCaret(
      TextPosition(offset: cluster.start),
      Rect.zero,
    );
    painter.dispose();

    await tester.tapAt(
      tester.getTopLeft(finder) + caret + const Offset(4, 12),
    );
    await tester.pump();

    expect(tapped, isNotNull);
    expect(tapped!.text, 'ট্ট');
  });
}
