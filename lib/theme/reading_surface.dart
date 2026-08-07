import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The background/foreground pairs a participant can choose for the passage.
///
/// The mockup exposes four (White / Cream / Yellow / Dark). High contrast is
/// added on top as a fifth, because the accessibility claim in the About screen
/// ("WCAG AA contrast on all text") is worth being able to demonstrate at the
/// maximum end during the study.
enum ReadingSurface {
  white(
    id: 'white',
    label: 'White',
    labelBn: 'সাদা',
    background: AppColors.surfaceWhite,
    text: AppColors.ink,
    secondaryText: AppColors.body,
    accent: AppColors.teal,
    highlight: AppColors.spokenWord,
  ),
  cream(
    id: 'cream',
    label: 'Cream',
    labelBn: 'ক্রিম',
    background: AppColors.surfaceCream,
    text: AppColors.ink,
    secondaryText: AppColors.body,
    accent: AppColors.teal,
    highlight: AppColors.spokenWord,
  ),
  lightYellow(
    id: 'light_yellow',
    label: 'Yellow',
    labelBn: 'হলুদ',
    background: AppColors.surfaceLightYellow,
    text: AppColors.ink,
    secondaryText: AppColors.body,
    accent: AppColors.teal,
    highlight: AppColors.spokenWord,
  ),
  dark(
    id: 'dark',
    label: 'Dark',
    labelBn: 'কালো',
    background: AppColors.surfaceDark,
    text: Color(0xFFF2F6FA),
    secondaryText: Color(0xFFB9C7D4),
    accent: Color(0xFF5FD3C8),
    highlight: Color(0xFF14615A),
  ),
  highContrast(
    id: 'high_contrast',
    // Shortened from "High contrast": the theme swatch is a one-line,
    // fixed-width choice tile alongside White/Cream/Yellow/Dark, and the
    // full name didn't fit without the text touching the tile's edges.
    label: 'Contrast',
    labelBn: 'উচ্চ কনট্রাস্ট',
    background: AppColors.surfaceHighContrast,
    text: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFE6E6E6),
    accent: Color(0xFFFFD400),
    highlight: Color(0xFF3A3000),
  );

  const ReadingSurface({
    required this.id,
    required this.label,
    required this.labelBn,
    required this.background,
    required this.text,
    required this.secondaryText,
    required this.accent,
    required this.highlight,
  });

  /// Stable key for the settings log and CSV export. Never renumber these.
  final String id;
  final String label;
  final String labelBn;

  /// Passage background.
  final Color background;

  /// Passage text.
  final Color text;

  /// Captions and chrome drawn on top of [background].
  final Color secondaryText;

  /// Conjunct underline, ruler, progress on this surface.
  final Color accent;

  /// Fill behind the word currently being spoken.
  final Color highlight;

  bool get isDark => this == dark || this == highContrast;

  /// Hairline suitable for drawing dividers on this surface.
  Color get line => isDark
      ? text.withValues(alpha: 0.24)
      : AppColors.border;

  static ReadingSurface fromId(String? id) => values.firstWhere(
        (s) => s.id == id,
        orElse: () => ReadingSurface.white,
      );
}
