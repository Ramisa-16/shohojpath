import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The one password behind every therapist-gated action in this prototype
/// (therapist login, unlocking a locked session's settings, ending a
/// supervised session). There is no accounts backend here — this is a fixed
/// research-prototype credential, not a per-therapist secret.
const kTherapistPassword = 'password123';

/// Shows a password prompt and returns true only once [kTherapistPassword]
/// is entered correctly; false if the reader cancels. Wrong entries show an
/// inline error and leave the dialog open rather than silently closing it,
/// so a mistyped password never reads as a successful unlock.
Future<bool> showTherapistPasswordDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _TherapistPasswordDialog(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
    ),
  );
  return result ?? false;
}

class _TherapistPasswordDialog extends StatefulWidget {
  const _TherapistPasswordDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
  });

  final String title;
  final String description;
  final String confirmLabel;

  @override
  State<_TherapistPasswordDialog> createState() => _TherapistPasswordDialogState();
}

class _TherapistPasswordDialogState extends State<_TherapistPasswordDialog> {
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.trim() == kTherapistPassword) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _error = 'Incorrect password.');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: const TextStyle(fontSize: 15, color: AppColors.body, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(hintText: 'Password', errorText: _error),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
