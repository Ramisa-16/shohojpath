import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reading_settings.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/reading_surface.dart';
import '../utils/bangla_text.dart';

/// Shows one যুক্তাক্ষর broken into its letters, with a speaker button.
///
/// This is the teaching moment the whole conjunct feature exists for: the
/// reader taps a glyph they cannot decode and is shown what is hiding inside
/// it (ক্ষ → ক্‌ + ষ) with the sound to match.
class ConjunctCard extends StatelessWidget {
  const ConjunctCard({
    super.key,
    required this.cluster,
    this.onClose,
    this.compact = false,
  });

  final ConjunctCluster cluster;

  /// Shown as a dismiss button when the card is floating over the passage.
  final VoidCallback? onClose;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReadingSettings>();
    final tts = context.watch<TtsService>();
    final surface = settings.surface;
    final onDark = surface.isDark;

    return Container(
      padding: EdgeInsets.all(compact ? 11 : 13),
      decoration: BoxDecoration(
        color: onDark ? const Color(0xFF16222C) : Colors.white,
        border: Border.all(color: surface.accent, width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: compact
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: cluster.text),
                  const TextSpan(text: '   →   '),
                  TextSpan(text: cluster.decomposition),
                ],
              ),
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: settings.fontFamily.family,
                // Tied to the reader's own size so the card stays legible for
                // whoever needed 48 px in the passage, but capped: this is a
                // single cluster, not running text.
                fontSize: (settings.fontSize * 0.95).clamp(18.0, 34.0),
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: onDark ? surface.text : AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SpeakerButton(
            enabled: tts.hasBanglaVoice,
            surface: surface,
            onPressed: () => context.read<TtsService>().speak(
                  cluster.text,
                  rate: settings.speechRate,
                ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onClose,
              tooltip: 'Close',
              iconSize: 22,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: Icon(
                Icons.close_rounded,
                color: onDark ? surface.secondaryText : AppColors.body,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({
    required this.enabled,
    required this.surface,
    required this.onPressed,
  });

  final bool enabled;
  final ReadingSurface surface;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: enabled
          ? 'Hear this conjunct read aloud'
          : 'No Bangla voice installed on this device',
      child: Material(
        color: enabled ? surface.accent : AppColors.borderStrong,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: surface.isDark ? const Color(0xFF10222B) : Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
