import 'package:flutter/material.dart';

import '../app/app_nav_state.dart';
import '../data/mock_content.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_tab_bar.dart';
import '../widgets/settings_controls.dart';

/// Screen 10 of the design. Reached by pushing from Progress, but still
/// shows the bottom tab bar — [BottomTabBar] pops back to the shell first.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: 'Reading Statistics',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'WORDS READ THIS WEEK',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.onNavyMuted,
                            ),
                          ),
                          Text(
                            '4,280',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '▲ 620 words vs last week',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.tealSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        Expanded(
                          child: WhiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Reading speed',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.body,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                    ),
                                    children: [
                                      TextSpan(text: '96 '),
                                      TextSpan(
                                        text: 'wpm',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Speed is read alongside accuracy.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.body,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: WhiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Reading accuracy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.body,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                    ),
                                    children: [
                                      TextSpan(text: '94'),
                                      TextSpan(
                                        text: '%',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '6 errors this session',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.body,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Expanded(
                                child: Text(
                                  'Read aloud used',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '73%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.tealText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: const LinearProgressIndicator(
                              value: 0.73,
                              minHeight: 10,
                              backgroundColor: AppColors.trackAlt,
                              color: AppColors.teal,
                            ),
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            'Percentage of sessions where audio support was switched on.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.body,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (
                      var row = 0;
                      row < MockContent.statTiles.length;
                      row += 2
                    ) ...[
                      if (row > 0) const SizedBox(height: 11),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (
                              var col = row;
                              col < row + 2 &&
                                  col < MockContent.statTiles.length;
                              col++
                            ) ...[
                              if (col > row) const SizedBox(width: 11),
                              Expanded(
                                child: WhiteCard(
                                  padding: const EdgeInsets.all(13),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        MockContent.statTiles[col].key,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.body,
                                        ),
                                      ),
                                      Text(
                                        MockContent.statTiles[col].value,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Most-used settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 11),
                          for (final s in MockContent.mostUsedSettings) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.key,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.body,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    s.value,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value:
                                    double.parse(s.value.replaceAll('%', '')) /
                                    100,
                                minHeight: 7,
                                backgroundColor: AppColors.trackAlt,
                                color: AppColors.teal,
                              ),
                            ),
                            if (s != MockContent.mostUsedSettings.last)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomTabBar(current: AppTab.progress),
    );
  }
}
