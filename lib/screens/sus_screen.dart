import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/study_session.dart';
import '../services/session_logger.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/therapist_session_banner.dart';
import 'nasa_tlx_screen.dart';

/// Screen 13 of the design — the standard 10-item System Usability Scale,
/// auto-scored with Brooke's original formula: odd items contribute
/// `response - 1`, even items contribute `5 - response`, and the sum (out of
/// 40) is scaled by 2.5. See [StudySession.susScore].
class SusScreen extends StatefulWidget {
  const SusScreen({super.key, required this.session});

  final StudySession session;

  @override
  State<SusScreen> createState() => _SusScreenState();
}

class _SusScreenState extends State<SusScreen> {
  static const _items = [
    'I think that I would like to use this app frequently.',
    'I found the app unnecessarily complex.',
    'I thought the app was easy to use.',
    'I think that I would need the support of a technical person to be able '
        'to use this app.',
    'I found the various functions in this app were well integrated.',
    'I thought there was too much inconsistency in this app.',
    'I would imagine that most people would learn to use this app very '
        'quickly.',
    'I found the app very cumbersome to use.',
    'I felt very confident using the app.',
    'I needed to learn a lot of things before I could get going with this '
        'app.',
  ];

  void _answer(int index, int rating) {
    setState(() => widget.session.susAnswers[index] = rating);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final score = session.susScore;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TherapistSessionBanner(),
            AppHeader(
              title: 'System Usability Scale',
              subtitle: '10 statements · 1 = strongly disagree',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    for (var i = 0; i < _items.length; i++) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (i + 1).toString().padLeft(2, '0'),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.tealDeep),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(_items[i], style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 11),
                            _ScaleButtonRow(
                              itemIndex: i,
                              answers: session.susAnswers,
                              onTap: _answer,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 11),
                    ],
                    Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LIVE SUS SCORE',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.onNavyMuted),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  session.susComplete
                                      ? (score >= 68 ? 'Above the 68 benchmark' : 'Below the 68 benchmark')
                                      : 'Answer all 10 to see the score',
                                  style: const TextStyle(fontSize: 15, color: AppColors.onNavyMuted),
                                ),
                              ],
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              session.susComplete ? score.toStringAsFixed(1) : '—',
                              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Continue to NASA-TLX',
                      backgroundColor: AppColors.tealText,
                      onPressed: session.susComplete
                          ? () {
                              context
                                  .read<SessionLogger>()
                                  .logSus(session.sessionId, session.susAnswers, score);
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => NasaTlxScreen(session: session)),
                              );
                            }
                          : null,
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

/// The five 1–5 Likert buttons for one SUS statement. Wraps to two rows
/// (3 + 2) instead of forcing five across whenever that would leave each
/// button narrower than the app's 44px minimum tap target — tying the
/// wrap decision directly to that rule rather than guessing a breakpoint.
class _ScaleButtonRow extends StatelessWidget {
  const _ScaleButtonRow({
    required this.itemIndex,
    required this.answers,
    required this.onTap,
  });

  final int itemIndex;
  final List<int> answers;
  final void Function(int itemIndex, int rating) onTap;

  static const _spacing = 6.0;
  static const _minTapWidth = 44.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fiveAcross = (constraints.maxWidth - _spacing * 4) / 5;
        final perRow = fiveAcross >= _minTapWidth ? 5 : 3;
        final tileWidth = (constraints.maxWidth - _spacing * (perRow - 1)) / perRow;
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (var n = 1; n <= 5; n++)
              SizedBox(
                width: tileWidth,
                child: _ScaleButton(
                  label: '$n',
                  selected: answers[itemIndex] == n,
                  onTap: () => onTap(itemIndex, n),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ScaleButton extends StatelessWidget {
  const _ScaleButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : AppColors.canvas,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: selected ? null : Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
