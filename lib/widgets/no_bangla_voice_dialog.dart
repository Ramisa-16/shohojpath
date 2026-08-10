import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../l10n/app_strings.dart';

/// Ensures a Bangla voice is ready before speaking, surfacing the failure
/// instead of letting a play button silently do nothing.
///
/// Always call this before [TtsService.speak] from a UI event handler. It
/// runs [TtsService.init] (a no-op if already done), and if no Bengali voice
/// turned up, shows [showNoBanglaVoiceDialog] and returns false so the caller
/// knows not to proceed.
Future<bool> ensureBanglaVoice(BuildContext context, TtsService tts) async {
  await tts.init();
  if (tts.hasBanglaVoice) return true;
  if (context.mounted) await showNoBanglaVoiceDialog(context);
  return false;
}

/// Explains why read-aloud is unavailable and what to do about it.
///
/// flutter_tts has no Bengali voice to fall back to on a device where none is
/// installed — it just never speaks. A participant tapping play with no
/// feedback would read as a broken app, so this has to be explicit rather
/// than a disabled button they have to guess the reason for.
Future<void> showNoBanglaVoiceDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t.noBanglaVoiceShort),
      content: Text(
        '${context.t.noBanglaVoiceBody}\n\n${context.t.noBanglaVoiceHow}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.done),
        ),
      ],
    ),
  );
}
