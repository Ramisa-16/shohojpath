import 'package:flutter/material.dart';

import '../data/mock_content.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import 'app_settings_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';

/// Screen 15 of the design — the Profile tab of [HomeShell].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.navy,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'MR',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Expanded: the name/ID line must never be squeezed off
                    // by the fixed-width avatar without anywhere to wrap.
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mitu Rahman',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Age 11 · Reader · P-04',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.onNavyMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.canvas,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final pref in MockContent.profilePrefs) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: pref == MockContent.profilePrefs.last
                              ? null
                              : const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                ),
                          // Stacked and left-aligned, not a Row with a
                          // right-aligned value: a value like "Noto Sans
                          // Bengali" wraps to two lines at large font sizes,
                          // and right-aligned wrapped text gives a ragged
                          // left edge that's harder to track — exactly what
                          // this app's typography is meant to avoid.
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pref.key,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.body,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pref.value,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListRowButton(
                  leading: const Icon(Icons.history_rounded, color: AppColors.navy, size: 24),
                  title: 'Reading history',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                const SizedBox(height: 11),
                ListRowButton(
                  leading: const Icon(Icons.analytics_rounded, color: AppColors.navy, size: 24),
                  title: 'My statistics',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                  ),
                ),
                const SizedBox(height: 11),
                ListRowButton(
                  leading: const Icon(Icons.settings_rounded, color: AppColors.navy, size: 24),
                  title: 'App settings',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
