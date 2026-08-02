import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// App chrome theme (headers, cards, buttons). The *passage* is deliberately
/// not styled from here — it is driven entirely by `ReadingSettings` so that
/// the independent variables of the study live in exactly one place.
abstract final class AppTheme {
  /// Minimum touch target used throughout the mockup.
  static const double minTouchTarget = 48;

  /// The mockup never uses a UI label below 14 px (accessibility claim).
  static const double minLabelSize = 14;

  static const _fontFamily = 'NotoSansBengali';

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.navy,
      onPrimary: Colors.white,
      primaryContainer: AppColors.navyTint,
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.teal,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.tealTint,
      onSecondaryContainer: AppColors.tealDeep,
      tertiary: AppColors.focus,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: AppColors.dangerTint,
      onErrorContainer: AppColors.danger,
      surface: Colors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.body,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: _fontFamily,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(style: _primaryButton),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          foregroundColor: const WidgetStatePropertyAll(AppColors.navy),
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.navy, width: 2),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: _fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.teal
              : AppColors.borderStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.teal,
        inactiveTrackColor: AppColors.track,
        thumbColor: Colors.white,
        overlayColor: Color(0x3326A69A),
        trackHeight: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipNeutral,
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.body,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      // The design puts a 3 px #B07A00 ring on every focusable control.
      focusColor: AppColors.focus,
    );
  }

  static final ButtonStyle _primaryButton = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
    backgroundColor: const WidgetStatePropertyAll(AppColors.navy),
    foregroundColor: const WidgetStatePropertyAll(Colors.white),
    elevation: const WidgetStatePropertyAll(0),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static const TextTheme _textTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: AppColors.navy,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.navy,
    ),
    titleLarge: TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.body,
    ),
    bodyLarge: TextStyle(fontSize: 17, height: 1.5, color: AppColors.ink),
    bodyMedium: TextStyle(fontSize: 15, height: 1.55, color: AppColors.body),
    bodySmall: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.muted,
    ),
  );

  /// The uppercase section eyebrow used on nearly every card in the mockup.
  static const TextStyle eyebrow = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.84, // .06em at 14px
    color: AppColors.muted,
  );
}
