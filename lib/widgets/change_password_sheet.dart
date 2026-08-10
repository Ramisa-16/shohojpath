import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../api/shohojpath_api.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'app_buttons.dart';
import 'auth_form_field.dart';

/// Changes the signed-in user's password through `/api/auth/password/`.
///
/// Shared by the reader and therapist profiles rather than written twice: a
/// second copy is how one of them ends up without the current-password check,
/// or with a weaker minimum length than the server enforces.
///
/// Presented as a bottom sheet: three stacked fields plus the keyboard is more
/// than a centred dialog can hold on a phone, and a sheet rises above the
/// keyboard instead of being squeezed by it.
Future<bool> showChangePasswordSheet(BuildContext context) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    // Half-typed passwords should not be thrown away by a stray tap on the
    // scrim; Cancel is right there.
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ChangePasswordSheet(),
  );
  if (changed == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tOnce.passwordChanged)),
    );
  }
  return changed ?? false;
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
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
      setState(() => _error = context.tOnce.enterCurrentPassword);
      return;
    }
    // Mirrors the server's MinimumLengthValidator so the obvious case does not
    // cost a round trip. The server stays the authority.
    if (_next.text.length < 8) {
      setState(() => _error = context.tOnce.useAtLeast8);
      return;
    }
    // A mistyped new password would otherwise lock someone out of an account
    // they can no longer sign in to in order to fix.
    if (_next.text != _confirm.text) {
      setState(() => _error = context.tOnce.passwordsDoNotMatch);
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
        _error = e.messageFor(context.tOnce);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Padding(
      // Lifts the sheet clear of the keyboard, so the field being typed into
      // is never the one hidden behind it.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.changePassword,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) AuthErrorBanner(message: _error!),
              AuthFormField(
                label: t.currentPassword,
                controller: _current,
                icon: Icons.lock_outline_rounded,
                obscure: true,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AuthFormField(
                label: t.newPassword,
                controller: _next,
                icon: Icons.lock_reset_rounded,
                hint: t.atLeast8Characters,
                obscure: true,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AuthFormField(
                label: t.confirmNewPassword,
                controller: _confirm,
                icon: Icons.check_circle_outline_rounded,
                obscure: true,
                enabled: !_saving,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _saving ? t.saving : t.changePassword,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(false),
                  child: Text(t.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
