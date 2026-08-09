import 'package:flutter/material.dart';

import '../screens/therapist/therapist_profile_screen.dart';
import '../theme/app_colors.dart';
import '../l10n/app_strings.dart';

/// The therapist side's two destinations — Dashboard is the root route
/// (reached via `pushReplacement` from Login), Profile is always exactly one
/// push above it, so unlike the reader's four-way [BottomTabBar] this needs
/// no shared nav state: tapping Dashboard just pops back to the root, and
/// tapping Profile pushes it.
enum TherapistTab { dashboard, profile }

class TherapistBottomTabBar extends StatelessWidget {
  const TherapistBottomTabBar({super.key, required this.current});

  final TherapistTab current;

  static const _icons = {
    TherapistTab.dashboard: Icons.dashboard_rounded,
    TherapistTab.profile: Icons.person_rounded,
  };

  static String _label(AppStrings t, TherapistTab tab) => switch (tab) {
        TherapistTab.dashboard => t.dashboard,
        TherapistTab.profile => t.tabProfile,
      };

  void _goTo(BuildContext context, TherapistTab tab) {
    if (tab == current) return;
    if (tab == TherapistTab.dashboard) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TherapistProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final tab in TherapistTab.values)
              Expanded(
                child: _TabButton(
                  icon: _icons[tab]!,
                  label: _label(context.t, tab),
                  selected: tab == current,
                  onTap: () => _goTo(context, tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.muted;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
