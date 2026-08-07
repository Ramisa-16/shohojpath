import 'package:flutter/material.dart';

import '../data/mock_content.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import 'researcher_screen.dart';

/// Screen 18 of the design. University, researcher and supervisor are left
/// as explicit placeholders — see [MockContent.about] — pending the real
/// research team's details.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'About', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(22)),
                            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 38),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'সহজপাঠ',
                            style: TextStyle(fontFamily: 'NotoSansBengali', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RESEARCH TITLE',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.body),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Design and Evaluation of a Dyslexia-Friendly Bangla Reading '
                            'Interface Using Human-Centered Design Principles',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.55, color: AppColors.ink),
                          ),
                          for (final a in MockContent.about)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: AppColors.divider)),
                                ),
                                padding: const EdgeInsets.only(top: 10),
                                // Stacked and left-aligned rather than a
                                // right-aligned value beside the label — a
                                // long value wraps to a ragged left edge
                                // when right-aligned, which fights the
                                // left-to-right tracking this app's type is
                                // meant to support.
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.key, style: const TextStyle(fontSize: 14, color: AppColors.body)),
                                    const SizedBox(height: 3),
                                    Text(
                                      a.value,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.teal, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Accessibility summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
                          const SizedBox(height: 10),
                          for (final line in MockContent.accessibilitySummary)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.tealText, size: 20),
                                  const SizedBox(width: 9),
                                  Expanded(child: Text(line, style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.5))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFAF4),
                        border: Border.all(color: AppColors.focus, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Disclaimer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.focusText)),
                          SizedBox(height: 8),
                          Text(
                            'This application is a reading support tool. It is not a diagnostic '
                            'or therapeutic instrument and does not replace assessment or '
                            'instruction by qualified professionals.',
                            style: TextStyle(fontSize: 14, color: AppColors.ink, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: GestureDetector(
                        onLongPress: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ResearcherScreen()),
                        ),
                        child: const Text(
                          'Version 1.0 · Research Prototype',
                          style: TextStyle(fontSize: 14, color: AppColors.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
