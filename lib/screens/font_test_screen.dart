import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bangla_font.dart';
import '../models/reading_settings.dart';
import '../theme/app_colors.dart';
import '../theme/reading_surface.dart';
import '../utils/bangla_text.dart';

/// THROWAWAY DIAGNOSTIC SCREEN — delete before the study build.
///
/// It exists to answer one question with your own eyes on a real Android
/// device: do the four bundled Bangla faces render যুক্তাক্ষর correctly, and
/// does inserting U+200C after the hasant actually produce the split form?
/// Emulators and desktop hosts use different text shapers, so this has to be
/// checked on the handset the participants will hold.
///
/// What to look for on each pair:
///   * top row  — the fused conjunct (ক্ষ as one glyph)
///   * bottom row — the split form (ক্‌ + ষ, with a visible hasant)
/// If the two rows look identical, that face's shaper is ignoring the ZWNJ and
/// "Split conjuncts" cannot be offered as a condition with that font.
class FontTestScreen extends StatelessWidget {
  const FontTestScreen({super.key});

  static const List<String> _conjuncts = [
    'ক্ষ',
    'ষ্ট',
    'ঞ্চ',
    'ন্ড',
    'ট্ট',
    'ন্দ',
    'ক্ত',
    'স্থ',
    'হ্ম',
  ];

  static const List<String> _words = [
    'বৃষ্টি',
    'ছোট্ট',
    'বারান্দার',
    'বিদ্যুৎ',
    'লক্ষ্য',
  ];

  static const List<double> _sizes = [16, 24, 48];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReadingSettings>();
    final surface = settings.surface;

    return Scaffold(
      backgroundColor: surface.background,
      appBar: AppBar(
        title: const Text('Conjunct / ZWNJ render test'),
        actions: [
          PopupMenuButton<ReadingSurface>(
            tooltip: 'Reading surface',
            icon: const Icon(Icons.palette_outlined),
            initialValue: surface,
            onSelected: (s) => context.read<ReadingSettings>().surface = s,
            itemBuilder: (context) => [
              for (final s in ReadingSurface.values)
                PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: s.background,
                          border: Border.all(color: AppColors.borderStrong),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(s.label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
        children: [
          _Legend(surface: surface),
          for (final font in BanglaFont.values) ...[
            _FontHeading(font: font, surface: surface),
            for (final size in _sizes) ...[
              _SizeHeading(size: size, surface: surface),
              _SampleGrid(
                samples: _conjuncts,
                font: font,
                size: size,
                surface: surface,
              ),
              const SizedBox(height: 10),
              _SampleGrid(
                samples: _words,
                font: font,
                size: size,
                surface: surface,
              ),
              const SizedBox(height: 18),
            ],
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.surface});

  final ReadingSurface surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface.accent.withValues(alpha: 0.12),
        border: Border(left: BorderSide(color: surface.accent, width: 4)),
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Each cell shows the same text twice',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: surface.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Top = joined (as authored). Bottom = ZWNJ inserted after every '
            'hasant, i.e. the split form the "যুক্তাক্ষর ভেঙে দেখাও" setting '
            'will produce. If both lines look the same, that font is not '
            'honouring U+200C.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: surface.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _FontHeading extends StatelessWidget {
  const _FontHeading({required this.font, required this.surface});

  final BanglaFont font;
  final ReadingSurface surface;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              font.label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: surface.isDark ? surface.text : AppColors.navy,
              ),
            ),
          ),
          if (!font.hasRealBold)
            Text(
              'single weight',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: surface.secondaryText,
              ),
            ),
        ],
      ),
    );
  }
}

class _SizeHeading extends StatelessWidget {
  const _SizeHeading({required this.size, required this.surface});

  final double size;
  final ReadingSurface surface;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Text(
            '${size.toInt()} px',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.84,
              color: surface.secondaryText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: surface.line)),
        ],
      ),
    );
  }
}

class _SampleGrid extends StatelessWidget {
  const _SampleGrid({
    required this.samples,
    required this.font,
    required this.size,
    required this.surface,
  });

  final List<String> samples;
  final BanglaFont font;
  final double size;
  final ReadingSurface surface;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final sample in samples)
          _SampleCell(
            joined: sample,
            font: font,
            size: size,
            surface: surface,
          ),
      ],
    );
  }
}

class _SampleCell extends StatelessWidget {
  const _SampleCell({
    required this.joined,
    required this.font,
    required this.size,
    required this.surface,
  });

  final String joined;
  final BanglaFont font;
  final double size;
  final ReadingSurface surface;

  @override
  Widget build(BuildContext context) {
    final split = BanglaText.split(joined);
    // No hasant found at all — the sample itself is wrong, not the font.
    final nothingToSplit = split == joined;

    TextStyle style(Color color) => TextStyle(
          fontFamily: font.family,
          fontSize: size,
          height: 1.6,
          color: color,
        );

    // A 48 px word can be wider than the screen; let it wrap inside its cell
    // instead of overflowing the row.
    final maxWidth = MediaQuery.sizeOf(context).width - 56;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size >= 48 ? 12 : 9,
        vertical: 8,
      ),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: surface.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        border: Border.all(
          color: nothingToSplit ? AppColors.danger : surface.line,
          width: nothingToSplit ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(joined, style: style(surface.text)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(height: 1, color: surface.line),
          ),
          Text(split, style: style(AppColors.tealText)),
        ],
      ),
    );
  }
}
