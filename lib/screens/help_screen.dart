import 'package:flutter/material.dart';

import '../data/mock_content.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/settings_controls.dart';

/// Screen 17 of the design.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const Map<IconDataId, IconData> _icons = {
    IconDataId.volumeUp: Icons.volume_up_rounded,
    IconDataId.spellcheck: Icons.spellcheck_rounded,
    IconDataId.formatSize: Icons.format_size_rounded,
    IconDataId.formatLineSpacing: Icons.format_line_spacing_rounded,
    IconDataId.ruler: Icons.straighten_rounded,
    IconDataId.bookmark: Icons.bookmark_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Help', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: AppColors.navyTint, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('How to use Shohojpath', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
                          SizedBox(height: 8),
                          Text(
                            'Pick a passage from the Library, then tap the settings button while '
                            'reading. Start with Read Aloud — it helps most. Adjust spacing and '
                            'theme until the text feels comfortable. Your choices are saved '
                            'automatically.',
                            style: TextStyle(fontSize: 15, color: AppColors.ink, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Accessibility features', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
                          const SizedBox(height: 13),
                          for (final f in MockContent.helpFeatures) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(_icons[f.icon], color: AppColors.tealText, size: 22),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(f.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                        Text(f.description, style: const TextStyle(fontSize: 14, color: AppColors.body, height: 1.4)),
                                      ],
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
                    WhiteCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final faq in MockContent.faqs)
                            ExpansionTile(
                              title: Text(
                                faq.question,
                                style: const TextStyle(fontSize: 15, color: AppColors.ink, height: 1.4),
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              expandedAlignment: Alignment.centerLeft,
                              children: [
                                Text(
                                  faq.answer,
                                  style: const TextStyle(fontSize: 14, color: AppColors.body, height: 1.55),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListRowButton(
                      leading: const Icon(Icons.mail_rounded, color: AppColors.navy, size: 24),
                      title: 'Contact the research team',
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Contact the research team'),
                          content: const Text('research-team@example.edu (placeholder contact address).'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                          ],
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
