import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_nav_state.dart';
import '../models/study_session.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/duration_format.dart';
import '../widgets/app_buttons.dart';
import 'home_shell.dart';

/// Screen 19 of the design — the end of the study flow. "Back to Home"
/// clears the whole session stack back to the tabbed shell.
class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key, required this.session});

  final StudySession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.tealTint],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 34),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.teal.withValues(alpha: 0.32), blurRadius: 26, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.t.thankYou,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your session has been recorded. Your responses help us design '
                        'better Bangla reading tools.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: AppColors.body, height: 1.7),
                      ),
                      const SizedBox(height: 20),
                      Container(
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
                            _Row(context.t.readingTime, formatDurationLong(session.readingDuration)),
                            const SizedBox(height: 8),
                            _Row(context.t.comprehension, '${session.quizScore} / ${session.quizAnswers.length}'),
                            const SizedBox(height: 8),
                            _Row(context.t.susScore, session.susComplete ? session.susScore.toStringAsFixed(1) : '—'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: context.t.backToHome,
                        expand: false,
                        onPressed: () {
                          context.read<AppNavState>().select(AppTab.home);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeShell()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Stacked and left-aligned rather than a right-aligned value beside the
    // label — a long value wraps to a ragged left edge when right-aligned
    // instead.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: AppColors.body)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy)),
      ],
    );
  }
}
