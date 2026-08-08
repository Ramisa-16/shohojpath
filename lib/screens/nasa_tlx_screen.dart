import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/study_session.dart';
import '../services/session_logger.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/therapist_session_banner.dart';
import 'thank_you_screen.dart';

/// Screen 14 of the design — the six NASA-TLX subscales, 0–100 each.
class NasaTlxScreen extends StatefulWidget {
  const NasaTlxScreen({super.key, required this.session});

  final StudySession session;

  @override
  State<NasaTlxScreen> createState() => _NasaTlxScreenState();
}

class _NasaTlxScreenState extends State<NasaTlxScreen> {
  static const _subscales = [
    ('Mental demand', 'How much thinking was required?'),
    ('Physical demand', 'How physically demanding was the task?'),
    ('Temporal demand', 'How hurried was the pace?'),
    ('Performance', 'How successful were you?'),
    ('Effort', 'How hard did you have to work?'),
    ('Frustration', 'How irritated or stressed did you feel?'),
  ];

  int _valueFor(String name) => widget.session.tlx[name] ?? 50;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TherapistSessionBanner(),
            AppHeader(
              title: 'NASA-TLX',
              subtitle: 'Optional · workload rating',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    for (final (name, desc) in _subscales) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                ),
                                Text(
                                  '${_valueFor(name)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.body, height: 1.45)),
                            Slider(
                              value: _valueFor(name).toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 20,
                              onChanged: (v) => setState(() => session.tlx[name] = v.round()),
                            ),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text('Very low', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted)),
                                ),
                                Expanded(
                                  child: Text(
                                    'Very high',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                    ],
                    PrimaryButton(
                      label: 'Submit session',
                      onPressed: () async {
                        await context
                            .read<SessionLogger>()
                            .logTlx(session.sessionId, session.tlx);
                        if (!context.mounted) return;

                        // The session is complete on disk; push it now rather
                        // than waiting for the next connectivity change, so a
                        // therapist can see it while the participant is still
                        // in the room. Not awaited — a sleeping server must
                        // never hold up the Thank You screen.
                        unawaited(context.read<SyncService>().syncNow());

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ThankYouScreen(session: session),
                          ),
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
