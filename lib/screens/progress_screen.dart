import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/settings_controls.dart';
import 'statistics_screen.dart';

/// Screen 07 of the design — the Progress tab of [HomeShell].
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const List<double> _weekHeights = [0.38, 0.62, 0.45, 0.80, 0.55, 0.92, 0.30];
  static const List<String> _weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(title: 'My Progress'),
        Expanded(
          child: Container(
            color: AppColors.canvas,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: WhiteCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.schedule_rounded, color: AppColors.tealText, size: 26),
                              const SizedBox(height: 5),
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy),
                                  children: [
                                    TextSpan(text: '18'),
                                    TextSpan(text: ' min', style: TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w400)),
                                  ],
                                ),
                              ),
                              const Text('Time today', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: WhiteCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.description_rounded, color: AppColors.tealText, size: 26),
                              const SizedBox(height: 5),
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy),
                                  children: [
                                    TextSpan(text: '7'),
                                    TextSpan(text: ' pages', style: TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w400)),
                                  ],
                                ),
                              ),
                              const Text('Pages read', style: TextStyle(fontSize: 14, color: AppColors.muted)),
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
                            child: Text('Current passage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          ),
                          SizedBox(width: 8),
                          Text('64%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.tealText)),
                        ],
                      ),
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: const LinearProgressIndicator(
                          value: 0.64,
                          minHeight: 10,
                          backgroundColor: AppColors.trackAlt,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'বৃষ্টির দিনে মিতু',
                        style: TextStyle(fontFamily: 'NotoSansBengali', fontSize: 16, color: AppColors.body),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('This week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 12),
                      // Only the bars themselves live inside the fixed-height
                      // plot area — a bar chart needs a bounded drawing
                      // height for the relative bars to mean anything, but
                      // nothing that renders text may share that box, since
                      // text is exactly what can't be capped to a fixed size.
                      SizedBox(
                        height: 90,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < 7; i++) ...[
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: _weekHeights[i],
                                    widthFactor: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: i == 6 ? AppColors.tealSoft : AppColors.teal,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(3)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (i != 6) const SizedBox(width: 7),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (var i = 0; i < 7; i++) ...[
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(_weekLabels[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.body)),
                              ),
                            ),
                            if (i != 6) const SizedBox(width: 7),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListRowButton(
                  leading: const Icon(Icons.analytics_rounded, color: AppColors.navy, size: 24),
                  title: 'Detailed reading statistics',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatisticsScreen()),
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
