import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:provider/provider.dart';

import '../models/reading_settings.dart';
import '../theme/app_colors.dart';
import '../theme/reading_surface.dart';
import '../utils/bangla_text.dart';
import '../utils/passage_transform.dart';
import 'reading_aids_painter.dart';

/// Where a conjunct tap happened, so the card can be anchored near it.
typedef ConjunctTapCallback = void Function(
  ConjunctCluster cluster,
  Offset globalPosition,
);

/// Renders Bangla passage text with every typography setting applied live.
///
/// This is the core of the prototype: the independent variables of the study
/// are the settings, and this widget is the only place they turn into pixels.
/// Nothing here hard-codes a size, spacing or colour — it all comes from
/// [ReadingSettings] and the selected [ReadingSurface], so switching research
/// condition re-renders the passage immediately and honestly.
///
/// The stored text is never modified. Split conjuncts and syllable breaks are
/// display transforms; see [PassageTransform].
class BanglaPassage extends StatefulWidget {
  const BanglaPassage({
    super.key,
    required this.paragraphs,
    this.onConjunctTap,
    this.selectedConjunct,
    this.onFocusChanged,
    this.spokenParagraphIndex,
    this.spokenRange,
    this.scrollController,
  });

  /// Stored paragraph text, exactly as it appears in the study material.
  final List<String> paragraphs;

  /// Called when the reader taps a যুক্তাক্ষর.
  final ConjunctTapCallback? onConjunctTap;

  /// The conjunct currently shown on the card, drawn with a stronger fill so
  /// the reader can see which one the card is talking about.
  final ConjunctCluster? selectedConjunct;

  /// Reports the paragraph the reader last touched, for session logging.
  final ValueChanged<int>? onFocusChanged;

  /// Which paragraph read-aloud is currently speaking, or null when nothing
  /// is playing or word highlighting is off.
  final int? spokenParagraphIndex;

  /// Offsets of the word currently being spoken, in **original** offsets over
  /// [spokenParagraphIndex]'s paragraph text.
  final TextUnitRange? spokenRange;

  /// The scroll view this passage is laid out in, so the spoken word can be
  /// scrolled into view as read-aloud progresses.
  final ScrollController? scrollController;

  @override
  State<BanglaPassage> createState() => _BanglaPassageState();
}

class _BanglaPassageState extends State<BanglaPassage> {
  /// Which paragraph holds the reading focus, and where in it.
  int? _focusParagraph;
  int? _focusDisplayOffset;

  List<PreparedParagraph>? _prepared;
  Object? _preparedKey;

  /// Re-analysing every paragraph on every rebuild would run the conjunct
  /// scanner on each frame while a slider is being dragged, so the result is
  /// cached against the only inputs that can change it.
  List<PreparedParagraph> _prepare(ReadingSettings settings) {
    final key = Object.hash(
      Object.hashAll(widget.paragraphs),
      settings.splitConjuncts,
      settings.syllableBreaks,
    );
    if (_preparedKey == key && _prepared != null) return _prepared!;

    _prepared = [
      for (final text in widget.paragraphs)
        PassageTransform.prepare(
          text,
          splitConjuncts: settings.splitConjuncts,
          syllableBreaks: settings.syllableBreaks,
        ),
    ];
    _preparedKey = key;
    return _prepared!;
  }

  void _handleTap({
    required int paragraphIndex,
    required PreparedParagraph prepared,
    required TextSpan span,
    required double width,
    required Offset localPosition,
    required Offset globalPosition,
    required bool conjunctsTappable,
  }) {
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: width);

    final position = painter.getPositionForOffset(localPosition);
    painter.dispose();

    setState(() {
      _focusParagraph = paragraphIndex;
      _focusDisplayOffset = position.offset;
    });
    widget.onFocusChanged?.call(paragraphIndex);

    if (!conjunctsTappable) return;
    final cluster = prepared.conjunctAtDisplay(position.offset);
    if (cluster != null) {
      widget.onConjunctTap?.call(cluster, globalPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReadingSettings>();
    final surface = settings.surface;
    final prepared = _prepare(settings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < prepared.length; i++) ...[
          if (i > 0) SizedBox(height: settings.paragraphSpacingPx),
          _Paragraph(
            index: i,
            prepared: prepared[i],
            settings: settings,
            surface: surface,
            selectedConjunct: widget.selectedConjunct,
            isFocused: _focusParagraph == i,
            focusDisplayOffset: _focusParagraph == i ? _focusDisplayOffset : null,
            anyParagraphFocused: _focusParagraph != null,
            spokenRange:
                widget.spokenParagraphIndex == i ? widget.spokenRange : null,
            scrollController: widget.scrollController,
            onTap: (span, width, local, global) => _handleTap(
              paragraphIndex: i,
              prepared: prepared[i],
              span: span,
              width: width,
              localPosition: local,
              globalPosition: global,
              conjunctsTappable: widget.onConjunctTap != null,
            ),
          ),
        ],
      ],
    );
  }
}

typedef _ParagraphTap = void Function(
  TextSpan span,
  double width,
  Offset localPosition,
  Offset globalPosition,
);

class _Paragraph extends StatefulWidget {
  const _Paragraph({
    required this.index,
    required this.prepared,
    required this.settings,
    required this.surface,
    required this.selectedConjunct,
    required this.isFocused,
    required this.focusDisplayOffset,
    required this.anyParagraphFocused,
    required this.spokenRange,
    required this.scrollController,
    required this.onTap,
  });

  final int index;
  final PreparedParagraph prepared;
  final ReadingSettings settings;
  final ReadingSurface surface;
  final ConjunctCluster? selectedConjunct;
  final bool isFocused;
  final int? focusDisplayOffset;
  final bool anyParagraphFocused;

  /// Offsets of the word read-aloud is speaking, in original offsets, or null
  /// when this paragraph does not hold read-aloud's focus.
  final TextUnitRange? spokenRange;
  final ScrollController? scrollController;
  final _ParagraphTap onTap;

  @override
  State<_Paragraph> createState() => _ParagraphState();
}

class _ParagraphState extends State<_Paragraph> {
  /// Anchored to the widget that shares its coordinate space with the
  /// `TextPainter` layouts below (nothing between this key and the RichText
  /// adds its own offset), so a rect computed from glyph boxes is valid to
  /// reveal directly against this render object.
  final GlobalKey _textKey = GlobalKey();

  TextSpan? _lastSpan;
  double _lastWidth = 0;

  /// Focus mode dims everything except the paragraph being read. It only
  /// engages once the reader has actually settled somewhere — dimming the whole
  /// page before the first tap would just look broken.
  static const double _dimmedOpacity = 0.35;

  @override
  void initState() {
    super.initState();
    if (widget.spokenRange != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSpokenWord());
    }
  }

  @override
  void didUpdateWidget(covariant _Paragraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spokenRange != oldWidget.spokenRange) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSpokenWord());
    }
  }

  void _revealSpokenWord() {
    if (!mounted) return;
    final range = widget.spokenRange;
    final span = _lastSpan;
    final controller = widget.scrollController;
    if (range == null || span == null || controller == null) return;
    if (!controller.hasClients) return;
    if (Scrollable.maybeOf(context) == null) return;

    final renderObject = _textKey.currentContext?.findRenderObject();
    if (renderObject == null) return;

    final displayRange = widget.prepared.mapping.toDisplayRange(range);
    final rect = SpokenWordPainter.rectFor(span, _lastWidth, displayRange);
    if (rect == null) return;

    final viewport = RenderAbstractViewport.of(renderObject);
    final reveal = viewport.getOffsetToReveal(renderObject, 0.5, rect: rect);
    final target = reveal.offset.clamp(
      controller.position.minScrollExtent,
      controller.position.maxScrollExtent,
    );
    if ((target - controller.offset).abs() > 4) {
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final span = _buildSpan();
    final dim = widget.settings.focusMode &&
        widget.anyParagraphFocused &&
        !widget.isFocused;

    final showParagraphBand =
        widget.settings.highlightCurrentParagraph && widget.isFocused;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        _lastSpan = span;
        _lastWidth = width;

        Widget text = CustomPaint(
          key: _textKey,
          painter: ReadingLineBandPainter(
            span: span,
            width: width,
            focusOffset: widget.focusDisplayOffset,
            showRuler: widget.settings.readingRuler,
            highlightLine: widget.settings.highlightCurrentLine,
            accent: widget.surface.accent,
          ),
          child: CustomPaint(
            painter: widget.spokenRange != null
                ? SpokenWordPainter(
                    span: span,
                    width: width,
                    range: widget.prepared.mapping
                        .toDisplayRange(widget.spokenRange!),
                    fillColor: AppColors.spokenWord,
                    outlineColor: AppColors.teal,
                  )
                : null,
            foregroundPainter: widget.settings.emphasiseMatra
                ? MatraEmphasisPainter(
                    span: span,
                    width: width,
                    wordRanges: _displayWordRanges(),
                    fontSize: widget.settings.fontSize,
                    colour: widget.surface.accent.withValues(alpha: 0.5),
                  )
                : null,
            // RichText rather than Text.rich: Text merges the ambient
            // DefaultTextStyle in as the root span and nests the given span
            // underneath, so the widget and the aid painters would be laying
            // out two different span trees. They must be identical or the
            // ruler drifts off the line.
            child: RichText(
              text: span,
              textAlign: TextAlign.start,
              textDirection: TextDirection.ltr,
              textScaler: TextScaler.noScaling,
            ),
          ),
        );

        text = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => widget.onTap(
            span,
            width,
            details.localPosition,
            details.globalPosition,
          ),
          child: text,
        );

        if (showParagraphBand) {
          text = Container(
            decoration: BoxDecoration(
              color: widget.surface.accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: text,
          );
        }

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: dim ? _dimmedOpacity : 1,
          child: text,
        );
      },
    );
  }

  List<TextUnitRange> _displayWordRanges() => [
        for (final w in widget.prepared.words)
          widget.prepared.mapping.toDisplayRange(w),
      ];

  /// Splits the display text into styled runs.
  ///
  /// Boundaries come from the conjunct ranges (mapped into display space) and
  /// the presentational insertions, so every run has one unambiguous style.
  TextSpan _buildSpan() {
    final base = widget.settings.passageStyle(color: widget.surface.text);
    final display = widget.prepared.display;
    final mapping = widget.prepared.mapping;

    final highlightRanges = <TextUnitRange, ConjunctCluster>{};
    if (widget.settings.highlightConjuncts) {
      for (final c in widget.prepared.conjuncts) {
        highlightRanges[
            mapping.toDisplayRange(TextUnitRange(c.start, c.styleEnd))] = c;
      }
    }

    if (highlightRanges.isEmpty && mapping.insertions.isEmpty) {
      return TextSpan(text: display, style: base);
    }

    final boundaries = <int>{0, display.length};
    for (final r in highlightRanges.keys) {
      boundaries.add(r.start);
      boundaries.add(r.end);
    }
    for (final r in mapping.insertions) {
      boundaries.add(r.start);
      boundaries.add(r.end);
    }

    final points = boundaries.where((b) => b >= 0 && b <= display.length).toList()
      ..sort();

    final children = <TextSpan>[];
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      if (end <= start) continue;

      final isInsertion = mapping.insertions.any((r) => r.contains(start));

      ConjunctCluster? cluster;
      for (final entry in highlightRanges.entries) {
        if (entry.key.contains(start)) {
          cluster = entry.value;
          break;
        }
      }

      children.add(
        TextSpan(
          text: display.substring(start, end),
          style: _styleFor(base, cluster: cluster, isInsertion: isInsertion),
        ),
      );
    }

    return TextSpan(style: base, children: children);
  }

  TextStyle _styleFor(
    TextStyle base, {
    required ConjunctCluster? cluster,
    required bool isInsertion,
  }) {
    if (isInsertion) {
      // The syllable dot is scaffolding, not content: it stays legible but
      // must never compete with the letters it separates.
      return base.copyWith(
        color: widget.surface.secondaryText.withValues(alpha: 0.55),
        fontWeight: FontWeight.w400,
      );
    }

    if (cluster == null) return base;

    final selected = widget.selectedConjunct;
    final isSelected =
        selected != null && selected.start == cluster.start && selected.end == cluster.end;

    return base.copyWith(
      decoration: TextDecoration.underline,
      decorationColor:
          widget.surface.accent.withValues(alpha: isSelected ? 1 : 0.75),
      decorationThickness: isSelected ? 3 : 2.2,
      backgroundColor:
          isSelected ? widget.surface.accent.withValues(alpha: 0.22) : null,
    );
  }
}
