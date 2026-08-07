import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_buttons.dart';

/// The navy header repeated at the top of nearly every screen in the design:
/// an optional back button, a title (with optional subtitle), optional
/// trailing icon actions, and an optional widget slot below the title row
/// (Home and Library hang a search field there).
///
/// A plain widget rather than a Scaffold `appBar`, matching how
/// [ReadingScreen]'s own header is built — every screen wraps its body in
/// its own `SafeArea`, so this only needs to draw the bar itself.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing = const [],
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: EdgeInsets.fromLTRB(6, 8, 10, bottom == null ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconOnlyButton(
                  onPressed: onBack,
                  tooltip: 'Back',
                  icon: Icons.arrow_back_rounded,
                  color: Colors.white,
                )
              else
                const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onNavyMuted,
                        ),
                      ),
                  ],
                ),
              ),
              ...trailing,
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: 10),
            bottom!,
          ],
        ],
      ),
    );
  }
}

/// A pill search field used under [AppHeader] on Home and Library — visual
/// only unless [onTap] is given, matching the design where only Library's
/// actually filters.
class HeaderSearchField extends StatelessWidget {
  const HeaderSearchField({super.key, required this.hint, this.onTap});

  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.onNavyFaint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.onNavyFaint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
