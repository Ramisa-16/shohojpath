import 'package:flutter/material.dart';

import '../data/mock_content.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/settings_controls.dart';
import 'reading_screen.dart';

/// Screen 08 of the design.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Reading History', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: MockContent.history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 11),
                  itemBuilder: (context, i) {
                    final entry = MockContent.history[i];
                    return WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.title,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansBengali',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Text(entry.date, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 18, color: AppColors.body),
                                  const SizedBox(width: 5),
                                  Text(entry.time, style: const TextStyle(fontSize: 14, color: AppColors.body)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.done_all_rounded, size: 18, color: AppColors.body),
                                  const SizedBox(width: 5),
                                  Text(entry.percent, style: const TextStyle(fontSize: 14, color: AppColors.body)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          PrimaryButton(
                            label: 'Continue',
                            onPressed: () {
                              final e = MockContent.library.firstWhere(
                                (e) => e.title == entry.title,
                                orElse: () => MockContent.library.first,
                              );
                              final passage = e.passage;
                              if (passage == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No full passage wired up for this entry yet.')),
                                );
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ReadingScreen(passage: passage)),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
