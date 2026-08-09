import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../api/shohojpath_api.dart';
import '../theme/app_colors.dart';
import 'auth_form_field.dart';

/// Changes the signed-in user's password through `/api/auth/password/`.
///
/// Shared by the reader and therapist profiles rather than written twice: a
/// second copy is how one of them ends up without the current-password check,
/// or with a weaker minimum length than the server enforces.
Future<bool> showChangePasswordDialog(BuildContext context) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => const _ChangePasswordDialog(),
  );
  if (changed == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed.')),
    );
  }
  return changed ?? false;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_current.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    // Mirrors the server's MinimumLengthValidator so the obvious case does not
    // cost a round trip. The server stays the authority.
    if (_next.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    // A mistyped new password would otherwise lock someone out of an account
    // they can no longer sign in to in order to fix.
    if (_next.text != _confirm.text) {
      setState(() => _error = 'The two new passwords do not match.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    try {
      await context.read<ShohojpathApi>().changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      navigator.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Change password',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            AuthFormField(
              label: 'Current password',
              controller: _current,
              icon: Icons.lock_outline_rounded,
              obscure: true,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthFormField(
              label: 'New password',
              controller: _next,
              icon: Icons.lock_reset_rounded,
              hint: 'At least 8 characters',
              obscure: true,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthFormField(
              label: 'Confirm new password',
              controller: _confirm,
              icon: Icons.check_circle_outline_rounded,
              obscure: true,
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Change'),
        ),
      ],
    );
  }
}
