import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quiz_bank.dart';
import '../models/quiz_question.dart';
import '../models/study_session.dart';
import '../services/session_logger.dart';
import '../theme/app_colors.dart';
import '../utils/duration_format.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/therapist_session_banner.dart';
import 'feedback_screen.dart';

/// Screen 11 of the design — MCQ and True/False comprehension questions
/// only, with per-question timing and the audio-state strip the task asked
/// for ("Reading condition": whether read-aloud was on for this passage).
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.session});

  final StudySession session;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QuizQuestion> _questions = QuizBank.forPassage(widget.session.passage.id);
  int _index = 0;
  int? _selected;
  final Stopwatch _questionTimer = Stopwatch()..start();

  QuizQuestion get _question => _questions[_index];

  void _select(int optionIndex) {
    setState(() => _selected = optionIndex);
  }

  void _next() {
    final selected = _selected;
    if (selected == null) return;

    widget.session.quizAnswers.add(
      QuizAnswer(
        selectedIndex: selected,
        correct: selected == _question.correctIndex,
        timeTaken: _questionTimer.elapsed,
      ),
    );

    if (_index == _questions.length - 1) {
      context
          .read<SessionLogger>()
          .logQuizAnswers(widget.session.sessionId, widget.session.quizAnswers);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FeedbackScreen(session: widget.session)),
      );
      return;
    }

    setState(() {
      _index++;
      _selected = null;
      _questionTimer
        ..reset()
        ..start();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const TherapistSessionBanner(),
              AppHeader(title: 'Comprehension', onBack: () => Navigator.of(context).maybePop()),
              const Expanded(
                child: Center(
                  child: Text(
                    'No comprehension questions are wired up for this passage yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TherapistSessionBanner(),
            AppHeader(
              title: 'Comprehension',
              onBack: () => Navigator.of(context).maybePop(),
              trailing: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${_index + 1} / ${_questions.length}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onNavyMuted),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < _questions.length; i++) ...[
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: i <= _index ? AppColors.teal : AppColors.track,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          if (i != _questions.length - 1) const SizedBox(width: 5),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.chipNeutral,
                        border: Border.all(color: AppColors.borderStrong, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // A Row with a trailing fixed-width label ("Reading
                      // condition") after an Expanded description overflows
                      // once the description needs more than one line at
                      // large font sizes — stacking the tag below instead
                      // guarantees both always have the full width to wrap
                      // into.
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.headphones_rounded, color: AppColors.muted, size: 22),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Audio support: ${widget.session.readAloudWasOn ? "ON" : "OFF"} during this passage',
                                  style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Reading condition',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _question.type == QuestionType.multipleChoice
                                ? 'MULTIPLE CHOICE'
                                : 'TRUE / FALSE',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.tealDeep,
                            ),
                          ),
                          const SizedBox(height: 13),
                          Text(
                            _question.prompt,
                            style: const TextStyle(
                              fontFamily: 'NotoSansBengali',
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              height: 1.7,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 13),
                          if (_question.type == QuestionType.trueFalse)
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var i = 0; i < _question.options.length; i++) ...[
                                    Expanded(
                                      child: _OptionButton(
                                        label: _question.options[i],
                                        selected: _selected == i,
                                        onTap: () => _select(i),
                                      ),
                                    ),
                                    if (i != _question.options.length - 1) const SizedBox(width: 9),
                                  ],
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (var i = 0; i < _question.options.length; i++) ...[
                                  _OptionButton(
                                    label: _question.options[i],
                                    selected: _selected == i,
                                    onTap: () => _select(i),
                                  ),
                                  if (i != _question.options.length - 1) const SizedBox(height: 9),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_rounded, color: AppColors.body, size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Reading time recorded', style: TextStyle(fontSize: 15, color: AppColors.body)),
                          ),
                          Text(
                            formatDuration(widget.session.readingDuration),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: _index == _questions.length - 1 ? 'Finish quiz' : 'Next question',
                      onPressed: _selected == null ? null : _next,
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

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navyTint : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.borderStrong,
              width: selected ? 2.5 : 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSansBengali',
              fontSize: 17,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.navy : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
