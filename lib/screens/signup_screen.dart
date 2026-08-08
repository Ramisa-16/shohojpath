import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/auth_state.dart';
import '../app/participant_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/auth_form_field.dart';
import 'home_shell.dart';
import 'therapist/therapist_dashboard_screen.dart';

/// Create an account — reader or therapist, email and password.
///
/// A reader signing up here is what makes them visible to therapists in the
/// Add Reader list, so the fields a therapist searches by (name, school) are
/// offered at signup rather than left for later.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.initialRole = UserRole.reader});

  final UserRole initialRole;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late UserRole _role = widget.initialRole;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _age = TextEditingController();
  final _school = TextEditingController();

  bool _obscure = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _age.dispose();
    _school.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Please enter a name.' : null;
      final email = _email.text.trim();
      _emailError = email.isEmpty
          ? 'Please enter an email address.'
          : (!email.contains('@') || !email.contains('.'))
              ? 'That does not look like an email address.'
              : null;
      // Mirrors the server's MinimumLengthValidator, so the obvious case is
      // caught without a round trip. The server remains the authority.
      _passwordError = _password.text.length < 8
          ? 'Use at least 8 characters.'
          : null;
    });
    return _nameError == null && _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthState>();
    final ok = await auth.signUp(
      email: _email.text,
      password: _password.text,
      role: _role == UserRole.therapist ? 'therapist' : 'reader',
      fullName: _name.text,
      age: int.tryParse(_age.text.trim()),
      school: _school.text.trim(),
    );
    if (!mounted || !ok) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => auth.isTherapist
            ? const TherapistDashboardScreen()
            : const HomeShell(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isReader = _role == UserRole.reader;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        title: const Text(
          'Create an account',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (auth.error != null) AuthErrorBanner(message: auth.error!),

            const Text(
              'I am a…',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.84,
                color: AppColors.body,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RoleChip(
                    label: 'Reader',
                    selected: isReader,
                    onTap: () => setState(() => _role = UserRole.reader),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _RoleChip(
                    label: 'Therapist',
                    selected: !isReader,
                    onTap: () => setState(() => _role = UserRole.therapist),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            AuthFormField(
              label: 'Full name',
              controller: _name,
              icon: Icons.person_outline_rounded,
              hint: isReader ? 'e.g. Mitu Rahman' : 'e.g. Dr A. Karim',
              errorText: _nameError,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              enabled: !auth.isBusy,
              onChanged: (_) => _clear(),
            ),
            const SizedBox(height: 14),

            AuthFormField(
              label: 'Email',
              controller: _email,
              icon: Icons.mail_outline_rounded,
              hint: 'you@example.com',
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !auth.isBusy,
              onChanged: (_) => _clear(),
            ),
            const SizedBox(height: 14),

            AuthFormField(
              label: 'Password',
              controller: _password,
              icon: Icons.lock_outline_rounded,
              hint: 'At least 8 characters',
              obscure: _obscure,
              errorText: _passwordError,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              enabled: !auth.isBusy,
              onChanged: (_) => _clear(),
              trailing: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.muted,
                  size: 22,
                ),
              ),
            ),

            if (isReader) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: AuthFormField(
                      label: 'Age',
                      controller: _age,
                      hint: '11',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      enabled: !auth.isBusy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthFormField(
                      label: 'School (optional)',
                      controller: _school,
                      hint: 'Shimultoli High',
                      textInputAction: TextInputAction.done,
                      enabled: !auth.isBusy,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Your name and school help your therapist find you when they '
                'add you as their reader.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            ],

            const SizedBox(height: 22),
            PrimaryButton(
              label: auth.isBusy ? 'Creating account…' : 'Create account',
              onPressed: auth.isBusy ? null : _submit,
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: auth.isBusy
                    ? null
                    : () {
                        context.read<AuthState>().clearError();
                        Navigator.of(context).maybePop();
                      },
                child: const Text(
                  'I already have an account',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clear() {
    if (context.read<AuthState>().error != null) {
      context.read<AuthState>().clearError();
    }
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.tealTint : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.teal : AppColors.borderStrong,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.navy : AppColors.body,
            ),
          ),
        ),
      ),
    );
  }
}
