import 'package:flutter/material.dart';

/// Design tokens lifted verbatim from the Claude Design mockup
/// (`design/Screen.dc.html`). Do not invent new colours here — if a screen
/// needs one, add it to this file with a comment naming where it came from,
/// so the thesis appendix can document the palette from a single source.
abstract final class AppColors {
  // ---- Brand ------------------------------------------------------------
  /// Primary. App bars, primary buttons, headings.
  static const navy = Color(0xFF1F4E79);

  /// Accent. Progress, toggles-on, conjunct underline, "evidence-based" chips.
  static const teal = Color(0xFF26A69A);

  /// Darker teal used for text on light teal tints (passes AA on #E8F5F3).
  static const tealText = Color(0xFF1F7A70);
  static const tealDeep = Color(0xFF155F58);
  static const tealSoft = Color(0xFF7FC8C1);

  /// Focus ring. Every interactive element in the mockup carries a 3 px
  /// #B07A00 outline — keep it, it is part of the accessibility claim.
  static const focus = Color(0xFFB07A00);
  static const focusText = Color(0xFF8A6000);

  // ---- Text -------------------------------------------------------------
  /// Body copy on light surfaces.
  static const body = Color(0xFF3B4B5A);

  /// Secondary / caption text.
  static const muted = Color(0xFF5B6B7B);

  /// Highest-emphasis ink. Also the dark reading surface.
  static const ink = Color(0xFF22303C);

  /// Muted text on the navy header.
  static const onNavyMuted = Color(0xFFC9DCEA);
  static const onNavyFaint = Color(0xFFDCEAF5);

  // ---- Surfaces & lines -------------------------------------------------
  /// App background behind cards.
  static const canvas = Color(0xFFF7F9FC);

  /// Navy tint: secondary buttons, icon wells.
  static const navyTint = Color(0xFFEAF1F7);

  /// Teal tints: "recommended" cards and chips.
  static const tealTint = Color(0xFFE8F5F3);
  static const tealTintSoft = Color(0xFFF2FAF9);
  static const tealLine = Color(0xFFCBE7E3);

  /// Word-highlight fill used while read-aloud speaks.
  static const spokenWord = Color(0xFF9BDDD6);

  static const border = Color(0xFFC9D4DF);
  static const borderStrong = Color(0xFF9FB0C0);
  static const divider = Color(0xFFEDF1F5);
  static const track = Color(0xFFDCE5EE);
  static const trackAlt = Color(0xFFEDF2F7);
  static const chipNeutral = Color(0xFFF2F6FA);

  // ---- Destructive ------------------------------------------------------
  static const danger = Color(0xFF8E4141);
  static const dangerBorder = Color(0xFFC99A9A);
  static const dangerTint = Color(0xFFFCF6F6);

  // ---- Reading surfaces -------------------------------------------------
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const surfaceCream = Color(0xFFFFF8E7);
  static const surfaceLightYellow = Color(0xFFFFFDE7);
  static const surfaceDark = Color(0xFF22303C);
  static const surfaceHighContrast = Color(0xFF000000);
}
