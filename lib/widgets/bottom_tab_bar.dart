import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_nav_state.dart';
import '../theme/app_colors.dart';

/// The four-tab bar shown on Home, Library, Progress, Profile — and on
/// Statistics, which is reached by pushing from Progress but still shows the
/// bar so a tap on it can jump straight back to another tab.
///
/// Tapping a tab always pops back to the tabbed shell first: the shell is
/// the app's single root route, so any screen pushed on top of it (Stats,
/// Reading, Quiz, …) can still use this bar to return to it.
class BottomTabBar extends StatelessWidget {
  const BottomTabBar({super.key, required this.current});

  final AppTab current;

  static const _icons = {
    AppTab.home: Icons.home_rounded,
    AppTab.library: Icons.local_library_rounded,
    AppTab.progress: Icons.insights_rounded,
    AppTab.profile: Icons.person_rounded,
  };

  static const _labels = {
    AppTab.home: 'Home',
    AppTab.library: 'Library',
    AppTab.progress: 'Progress',
    AppTab.profile: 'Profile',
  };

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
            for (final tab in AppTab.values)
              Expanded(
                child: _TabButton(
                  icon: _icons[tab]!,
                  label: _labels[tab]!,
                  selected: tab == current,
                  onTap: () {
                    context.read<AppNavState>().select(tab);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
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
            // Four columns share the bar's width and each label is a single
            // word with no wrap point — scale the word down as a unit at
            // extreme font settings rather than force a mid-word break.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
