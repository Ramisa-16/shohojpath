import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/auth_state.dart';
import '../app/participant_state.dart';
import '../services/reader_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/auth_form_field.dart';
import 'home_shell.dart';
import 'signup_screen.dart';
import 'therapist/therapist_dashboard_screen.dart';

/// Screen 02 of the design — sign in with email and password.
///
/// Backed by the Django API rather than the fixed password the prototype used
/// to check against: readers and therapists are real accounts now, and which
/// screens someone sees is decided by the role on their token, not by a
/// toggle in the UI.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError =
          _email.text.trim().isEmpty ? 'Please enter your email.' : null;
      _passwordError =
          _password.text.isEmpty ? 'Please enter your password.' : null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _logIn() async {
    if (!_validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthState>();
    final ok = await auth.logIn(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted || !ok) return;
    _goToApp(auth.isTherapist);
  }

  /// Reading without an account, entirely on-device.
  ///
  /// Kept because the study runs in places with no reliable connection, and a
  /// participant who cannot sign in must still be able to read. Their sessions
  /// are logged locally against a guest id and simply never sync.
  Future<void> _continueAsGuest() async {
    final navigator = Navigator.of(context);
    final participant = context.read<ParticipantState>();
    final id = await context.read<ReaderRepository>().createGuestReader();
    participant.signInAsReader(id, displayName: 'Guest');
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  void _goToApp(bool isTherapist) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            isTherapist ? const TherapistDashboardScreen() : const HomeShell(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Sign in to save your reading settings and progress across '
              'sessions.',
              style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.body),
            ),
            const SizedBox(height: 20),

            if (auth.error != null) AuthErrorBanner(message: auth.error!),

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
              onChanged: (_) => _clearServerError(),
            ),
            const SizedBox(height: 14),
            AuthFormField(
              label: 'Password',
              controller: _password,
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              errorText: _passwordError,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              enabled: !auth.isBusy,
              onChanged: (_) => _clearServerError(),
              onSubmitted: (_) => _logIn(),
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

            const SizedBox(height: 20),
            PrimaryButton(
              label: auth.isBusy ? 'Signing in…' : 'Log in',
              onPressed: auth.isBusy ? null : _logIn,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.track)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.track)),
              ],
            ),
            const SizedBox(height: 16),

            SecondaryButton(
              label: 'Continue as Guest',
              onPressed: auth.isBusy ? null : _continueAsGuest,
            ),
            const SizedBox(height: 8),
            const Text(
              'Guest reading stays on this device only — nothing is uploaded '
              'and a therapist cannot see it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
            ),

            const SizedBox(height: 22),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'New here? ',
                    style: TextStyle(fontSize: 15, color: AppColors.body),
                  ),
                  TextButton(
                    onPressed: auth.isBusy ? null : _openSignUp,
                    child: const Text(
                      'Create an account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearServerError() {
    final auth = context.read<AuthState>();
    if (auth.error != null) auth.clearError();
  }

  /// Clears the banner on the way out and again on the way back: a failed
  /// sign-in must not greet someone on the Sign up form, and a failed sign-up
  /// must not still be showing when they return here.
  Future<void> _openSignUp() async {
    context.read<AuthState>().clearError();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
    if (!mounted) return;
    context.read<AuthState>().clearError();
  }
}
