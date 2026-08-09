import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quiz_bank.dart';
import '../services/passage_repository.dart';
import '../models/quiz_question.dart';
import '../models/study_session.dart';
import '../services/session_logger.dart';
import '../l10n/app_strings.dart';
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
  /// Authored in the admin and fetched with the passage, so the researcher can
  /// change the questions without shipping a new APK. Falls back to the
  /// bundled bank when the server has none for this passage yet — a
  /// participant who has just finished reading must not hit a dead end.
  late final List<QuizQuestion> _questions = _resolveQuestions();
  int _index = 0;
  int? _selected;

  /// Captured the moment they tap, not when they press Next: the seconds spent
  /// reading the feedback afterwards are not deciding time, and folding them
  /// in would inflate every answer a child paused over.
  Duration? _answerTime;

  final Stopwatch _questionTimer = Stopwatch()..start();

  QuizQuestion get _question => _questions[_index];

  /// Answering is a one-way door. Showing the right answer *and* allowing a
  /// change would turn quiz_score into a measure of who noticed the colour.
  bool get _answered => _selected != null;

  bool get _isCorrect => _selected == _question.correctIndex;

  List<QuizQuestion> _resolveQuestions() {
    final fromServer = context
        .read<PassageRepository>()
        .questionsFor(widget.session.passage.id);
    if (fromServer.isNotEmpty) return fromServer;
    return QuizBank.forPassage(widget.session.passage.id);
  }

  void _select(int optionIndex) {
    if (_answered) return;
    _questionTimer.stop();
    setState(() {
      _selected = optionIndex;
      _answerTime = _questionTimer.elapsed;
    });
  }

  void _next() {
    final selected = _selected;
    if (selected == null) return;

    widget.session.quizAnswers.add(
      QuizAnswer(
        selectedIndex: selected,
        correct: selected == _question.correctIndex,
        timeTaken: _answerTime ?? _questionTimer.elapsed,
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
      _answerTime = null;
      _questionTimer
        ..reset()
        ..start();
    });
  }

  /// How one option should read once the answer is in. The correct option is
  /// marked whether or not they picked it — that is the teaching moment.
  _OptionState _stateFor(int optionIndex) {
    if (!_answered) return _OptionState.idle;
    if (optionIndex == _question.correctIndex) return _OptionState.correct;
    if (optionIndex == _selected) return _OptionState.wrong;
    return _OptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    if (_questions.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const TherapistSessionBanner(),
              AppHeader(title: t.comprehension, onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: Center(
                  child: Text(
                    t.noQuestionsForPassage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppColors.muted),
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
              title: t.comprehension,
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
                                  widget.session.readAloudWasOn ? t.audioOn : t.audioOff,
                                  style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.readingCondition,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted),
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
                                ? t.multipleChoice
                                : t.trueFalse,
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
                                        state: _stateFor(i),
                                        onTap: _answered ? null : () => _select(i),
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
                                    state: _stateFor(i),
                                    onTap: _answered ? null : () => _select(i),
                                  ),
                                  if (i != _question.options.length - 1) const SizedBox(height: 9),
                                ],
                              ],
                            ),
                          if (_answered) ...[
                            const SizedBox(height: 13),
                            _AnswerFeedback(correct: _isCorrect),
                          ],
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
                          Expanded(
                            child: Text(t.readingTimeRecorded, style: const TextStyle(fontSize: 15, color: AppColors.body)),
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
                      label: _index == _questions.length - 1 ? t.finishQuiz : t.nextQuestion,
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

/// How an option reads once the answer is in.
enum _OptionState { idle, correct, wrong }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.state = _OptionState.idle,
  });

  final String label;
  final bool selected;

  /// Null once the question is answered — the options stop being controls.
  final VoidCallback? onTap;

  final _OptionState state;

  @override
  Widget build(BuildContext context) {
    // Every state carries an icon and a word as well as a colour. Around one
    // boy in twelve cannot separate red from green, and this app exists for
    // children who already find reading hard — a cue only some of them can
    // see is not a cue.
    final (background, border, foreground, icon) = switch (state) {
      _OptionState.correct => (
          AppColors.tealTint,
          AppColors.teal,
          AppColors.tealDeep,
          Icons.check_circle_rounded,
        ),
      _OptionState.wrong => (
          AppColors.dangerTint,
          AppColors.danger,
          AppColors.danger,
          Icons.cancel_rounded,
        ),
      _OptionState.idle when selected => (
          AppColors.navyTint,
          AppColors.navy,
          AppColors.navy,
          null,
        ),
      _OptionState.idle => (
          Colors.white,
          AppColors.borderStrong,
          AppColors.ink,
          null,
        ),
    };

    final emphasised = selected || state != _OptionState.idle;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          // Short and plain: a colour settling in, no shake and no bounce. A
          // wrong answer should not feel like a punishment.
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: border,
              width: emphasised ? 2.5 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'NotoSansBengali',
                    fontSize: 17,
                    fontWeight: emphasised ? FontWeight.w600 : FontWeight.w400,
                    color: foreground,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 10),
                Icon(icon, size: 24, color: border),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The line under the options once an answer is in.
class _AnswerFeedback extends StatelessWidget {
  const _AnswerFeedback({required this.correct});

  final bool correct;

  @override
  Widget build(BuildContext context) {
    // Worded without naming a colour: "the green one" is useless to a child
    // who cannot see the difference, and the marked option carries an icon.
    final message =
        correct ? context.t.answerCorrect : context.t.answerRevealed;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: correct ? AppColors.tealTint : AppColors.dangerTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: correct ? AppColors.tealLine : AppColors.dangerBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
              size: 22,
              color: correct ? AppColors.teal : AppColors.danger,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'NotoSansBengali',
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: correct ? AppColors.tealDeep : AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
