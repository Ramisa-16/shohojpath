import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The five button shapes used everywhere in this app. Every screen picks
/// one of these instead of styling a `FilledButton`/`OutlinedButton`/
/// `IconButton` by hand — that hand-styling is exactly how the app ended up
/// with a dozen different paddings and one swatch with text touching its
/// edges. When a button doesn't fit any of these five, that's a sign to
/// reconsider the design, not to invent a sixth one-off style.

/// PRIMARY — filled, the main call to action on a screen (Log in, Apply
/// settings, Add Reader, Start Reading). Full width by default; pass
/// `expand: false` only when a parent (e.g. `Expanded` in a Row) already
/// controls the width.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.navy,
    this.disabledBackgroundColor,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color? disabledBackgroundColor;
  final bool expand;

  static const double verticalPadding = 18;
  static const double horizontalPadding = 28;
  static const double minHeight = 56;
  static const double fontSize = 18;
  static const double radius = 12;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor ?? AppColors.borderStrong,
      padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
      minimumSize: const Size(0, minHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: const TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
    );
    final labelText = Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis);
    final button = icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: labelText)
        : FilledButton.icon(onPressed: onPressed, style: style, icon: Icon(icon), label: labelText);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// SECONDARY — outlined, a lesser action alongside or below a primary one
/// (Continue as Guest, Cancel).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.navy,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Foreground and border share one colour — every secondary button in
  /// the design is a single-colour outline, never a mixed border/text pair.
  final Color color;
  final bool expand;

  static const double verticalPadding = 16;
  static const double horizontalPadding = 24;
  static const double minHeight = 52;
  static const double fontSize = 16;
  static const double radius = 12;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
      minimumSize: const Size(0, minHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: const TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
    );
    final labelText = Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis);
    final button = icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: labelText)
        : OutlinedButton.icon(onPressed: onPressed, style: style, icon: Icon(icon), label: labelText);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// CHOICE TILE — one option in a set of mutually-exclusive picks: theme
/// swatches, font names, difficulty/category filters. Always a single
/// line — a label too long to fit is a label to shorten, not a tile to
/// resize, so callers must pick short enough text rather than expect this
/// widget to wrap or shrink its font.
///
/// Every tile in one group must render at the same size: give each an
/// identical explicit `width` (typically computed once via `LayoutBuilder`
/// and applied to every tile including the last row of a wrap) rather than
/// letting each tile size to its own content.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.width,
    this.selectedColor = AppColors.navy,
    this.selectedTextColor = Colors.white,
    this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? width;
  final Color selectedColor;
  final Color selectedTextColor;

  /// Swaps in custom content (e.g. a theme-colour preview) above the label
  /// instead of just the label alone — the label is still rendered below,
  /// one line, to the same rules.
  final Widget? child;

  static const double verticalPadding = 16;
  static const double horizontalPadding = 20;
  static const double minHeight = 64;
  static const double fontSize = 16;
  static const double radius = 12;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: selected ? selectedColor : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          constraints: const BoxConstraints(minHeight: minHeight),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: selected ? selectedColor : AppColors.borderStrong,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: child == null
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: selected ? selectedTextColor : AppColors.body,
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    child!,
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: selected ? selectedTextColor : AppColors.body,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
    return width == null ? tile : SizedBox(width: width, child: tile);
  }
}

/// LIST ROW BUTTON — a full-width navigation/selection row: reader cards,
/// library cards, settings rows. Content sits left-aligned with an optional
/// leading icon, a trailing chevron by default.
class ListRowButton extends StatelessWidget {
  const ListRowButton({
    super.key,
    required this.title,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.trailing = const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  static const double verticalPadding = 18;
  static const double horizontalPadding = 20;
  static const double minHeight = 72;
  static const double radius = 16;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: const TextStyle(fontSize: 14, color: AppColors.body)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// ICON-ONLY BUTTON — back, close, bookmark, play/pause and similar chrome
/// controls: 48x48 minimum tap target, icon centred, 12px of breathing room
/// around it.
class IconOnlyButton extends StatelessWidget {
  const IconOnlyButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
    this.size = 24,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;
  final double size;

  static const double minSize = 48;
  static const double internalPadding = 12;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: size, color: color),
      padding: const EdgeInsets.all(internalPadding),
      constraints: const BoxConstraints(minWidth: minSize, minHeight: minSize),
    );
  }
}
