import 'dart:ui' show LineMetrics, BoxHeightStyle;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../utils/bangla_text.dart';

/// Shared layout for the aid painters.
///
/// Both painters re-lay-out the *same* span at the *same* width as the visible
/// `Text.rich`, so the bands they draw sit exactly on the lines the reader
/// sees. Any divergence in span, style, width or text scaling would show up as
/// a ruler floating half a line off, so the width is passed in explicitly
/// rather than taken from the paint size.
TextPainter _layout(InlineSpan span, double width) {
  final painter = TextPainter(
    text: span,
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.start,
    textScaler: TextScaler.noScaling,
  )..layout(maxWidth: width);
  return painter;
}

LineMetrics? _lineAt(
  TextPainter painter,
  List<LineMetrics> lines,
  int displayOffset,
) {
  if (lines.isEmpty) return null;
  final caretTop = painter
      .getOffsetForCaret(TextPosition(offset: displayOffset), Rect.zero)
      .dy;

  var best = lines.first;
  var bestDistance = double.infinity;
  for (final line in lines) {
    final distance = ((line.baseline - line.ascent) - caretTop).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      best = line;
    }
  }
  return best;
}

/// Draws the reading ruler and current-line band *behind* the text.
class ReadingLineBandPainter extends CustomPainter {
  const ReadingLineBandPainter({
    required this.span,
    required this.width,
    required this.focusOffset,
    required this.showRuler,
    required this.highlightLine,
    required this.accent,
  });

  final InlineSpan span;
  final double width;

  /// Display offset of the character the reader is on, or null when the
  /// paragraph does not hold the focus.
  final int? focusOffset;

  final bool showRuler;
  final bool highlightLine;
  final Color accent;

  /// The design bleeds the ruler slightly past the text column so it reads as
  /// a band across the page rather than a highlight on the words.
  static const double bleed = 6;

  @override
  void paint(Canvas canvas, Size size) {
    if (focusOffset == null) return;
    if (!showRuler && !highlightLine) return;

    final painter = _layout(span, width);
    final lines = painter.computeLineMetrics();
    final line = _lineAt(painter, lines, focusOffset!);
    if (line == null) return;

    final top = line.baseline - line.ascent;
    final bottom = line.baseline + line.descent;
    final rect = Rect.fromLTRB(-bleed, top, size.width + bleed, bottom);

    // Both aids tint the same band; drawing two fills would double the alpha
    // and make the ruler read as a much darker block than specified.
    final fillAlpha = showRuler ? 0.14 : 0.10;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = accent.withValues(alpha: fillAlpha),
    );

    if (showRuler) {
      canvas.drawRect(
        Rect.fromLTRB(rect.left, rect.bottom - 2, rect.right, rect.bottom),
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(ReadingLineBandPainter old) =>
      old.span != span ||
      old.width != width ||
      old.focusOffset != focusOffset ||
      old.showRuler != showRuler ||
      old.highlightLine != highlightLine ||
      old.accent != accent;
}

/// Draws the মাত্রা emphasis *over* the text.
///
/// The matra is the horizontal headline that ties the letters of a word
/// together; emphasising it strengthens the visual anchor that tells a reader
/// where one word starts and ends. It is drawn per word rather than across the
/// whole line, because a rule running through the spaces would read as a
/// strikethrough joining separate words.
class MatraEmphasisPainter extends CustomPainter {
  const MatraEmphasisPainter({
    required this.span,
    required this.width,
    required this.wordRanges,
    required this.fontSize,
    required this.colour,
  });

  final InlineSpan span;
  final double width;

  /// Word ranges in **display** offsets.
  final List<TextUnitRange> wordRanges;

  final double fontSize;
  final Color colour;

  /// Height of the matra above the baseline, as a fraction of font size.
  ///
  /// Bangla base consonants sit roughly 0.70 em above the baseline in the faces
  /// bundled here, but this is font-dependent — CHECK IT ON A DEVICE against
  /// each of the four typefaces before running a session with this toggle on.
  /// The band is drawn 3 px tall so a small error still lands on the headline
  /// rather than through the middle of the letters.
  static const double matraHeightRatio = 0.70;
  static const double bandThickness = 3;

  @override
  void paint(Canvas canvas, Size size) {
    if (wordRanges.isEmpty) return;

    final painter = _layout(span, width);
    final lines = painter.computeLineMetrics();
    if (lines.isEmpty) return;

    final paint = Paint()..color = colour;

    for (final range in wordRanges) {
      if (range.length <= 0) continue;

      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
        boxHeightStyle: BoxHeightStyle.tight,
      );

      for (final box in boxes) {
        final baseline = _baselineFor(lines, box.top + box.toRect().height / 2);
        if (baseline == null) continue;
        final y = baseline - fontSize * matraHeightRatio;
        canvas.drawRect(
          Rect.fromLTRB(box.left, y, box.right, y + bandThickness),
          paint,
        );
      }
    }
  }

  double? _baselineFor(List<LineMetrics> lines, double y) {
    for (final line in lines) {
      final top = line.baseline - line.ascent;
      final bottom = line.baseline + line.descent;
      if (y >= top - 0.5 && y <= bottom + 0.5) return line.baseline;
    }
    return null;
  }

  @override
  bool shouldRepaint(MatraEmphasisPainter old) =>
      old.span != span ||
      old.width != width ||
      old.fontSize != fontSize ||
      old.colour != colour ||
      !listEquals(old.wordRanges, wordRanges);
}
