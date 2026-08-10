import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/study_session.dart';
import '../services/session_logger.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/duration_format.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/therapist_session_banner.dart';
import 'sus_screen.dart';

/// Screen 12 of the design.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, required this.session});

  final StudySession session;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  /// Names the controls the reader has just been using, so the wording must
  /// match the settings panel exactly — a different phrase here would read as
  /// a different feature.
  static List<String> _candidateSettings(AppStrings t) => [
        t.settingReadAloud,
        t.settingConjunctHighlight,
        t.settingLineSpacing,
        t.settingCreamTheme,
        t.settingReadingRuler,
      ];

  final _suggestion = TextEditingController();

  @override
  void initState() {
    super.initState();
    _suggestion.text = widget.session.suggestion;
  }

  @override
  void dispose() {
    _suggestion.dispose();
    super.dispose();
  }

  int get _wpm {
    final minutes = widget.session.readingDuration.inSeconds / 60;
    if (minutes <= 0) return 0;
    return (widget.session.passage.wordCount / minutes).round();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TherapistSessionBanner(),
            AppHeader(title: context.t.yourFeedback, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: AppColors.tealTint, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          const Icon(Icons.task_alt_rounded, color: AppColors.tealDeep, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quiz score: ${session.quizScore} / ${session.quizAnswers.length}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.tealDeep),
                                ),
                                Text(
                                  'Reading time ${formatDuration(session.readingDuration)} · $_wpm wpm',
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF2F6B65)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CardBlock(
                      title: context.t.wasReadingEasy,
                      child: _StarRow(
                        value: session.easeStars,
                        onChanged: (v) => setState(() => session.easeStars = v),
                      ),
                    ),
                    const SizedBox(height: 11),
                    _CardBlock(
                      title: context.t.didReadAloudHelp,
                      child: _StarRow(
                        value: session.audioHelpStars,
                        onChanged: (v) => setState(() => session.audioHelpStars = v),
                      ),
                    ),
                    const SizedBox(height: 11),
                    _CardBlock(
                      title: context.t.whichSettingsHelped,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final label in _candidateSettings(context.t))
                            ChoiceTile(
                              label: label,
                              selected: session.helpfulSettings.contains(label),
                              onTap: () => setState(() {
                                if (!session.helpfulSettings.remove(label)) {
                                  session.helpfulSettings.add(label);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    _CardBlock(
                      title: context.t.anySuggestions,
                      child: TextField(
                        controller: _suggestion,
                        onChanged: (v) => session.suggestion = v,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: context.t.suggestionsHint,
                          filled: true,
                          fillColor: AppColors.canvas,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: context.t.continueToSus,
                      onPressed: () {
                        context.read<SessionLogger>().logFeedback(
                              session.sessionId,
                              easeStars: session.easeStars,
                              audioHelpStars: session.audioHelpStars,
                              helpfulSettings: session.helpfulSettings,
                              suggestion: session.suggestion,
                            );
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SusScreen(session: session)),
                        );
                      },
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

class _CardBlock extends StatelessWidget {
  const _CardBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            onPressed: () => onChanged(i),
            tooltip: '$i star${i == 1 ? '' : 's'}',
            icon: Icon(
              (value ?? 0) >= i ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppColors.focus,
              size: 32,
            ),
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          ),
      ],
    );
  }
}
