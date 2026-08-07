import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/participant_state.dart';
import '../models/reader_sign_in_display.dart';
import '../services/app_config_repository.dart';
import '../services/reader_profile_loader.dart';
import '../services/reader_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/reader_tile.dart';
import '../widgets/therapist_password_dialog.dart';
import 'all_readers_screen.dart';
import 'home_shell.dart';
import 'therapist/therapist_dashboard_screen.dart';

/// The most readers the Login screen shows before folding the rest behind
/// "Show all readers" — a therapist with dozens of readers must not turn
/// the sign-in screen into an endless scroll before "Continue as Guest".
const maxVisibleReadersOnLogin = 4;

/// Screen 02 of the design (v2: 2 roles, v3: tap-to-choose reader sign-in).
/// There is no accounts backend behind this prototype — "Email" is cosmetic
/// — but "Log in" does check the password field against the one fixed
/// research-prototype credential in [kTherapistPassword].
///
/// Readers never type anything to sign in: they tap their own name (or
/// participant ID, or nothing at all if sign-in display is switched off in
/// App Settings — see [ReaderSignInDisplay]) from a list, or tap Continue as
/// Guest. A typed ID field is exactly the wrong first experience for a
/// dyslexic reader, and every reader listed here was already registered by a
/// therapist, so there is nothing only a keyboard could supply anyway.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _password = TextEditingController(text: 'password123');
  bool _obscure = true;
  String? _passwordError;
  UserRole _role = UserRole.reader;
  bool _loading = true;
  ReaderSignInDisplay _display = ReaderSignInDisplay.names;
  List<Map<String, Object?>> _readers = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final configRepo = context.read<AppConfigRepository>();
    final readerRepo = context.read<ReaderRepository>();

    final displayId = await configRepo.get('reader_sign_in_display');
    final display = ReaderSignInDisplay.fromId(displayId);
    final readers = display == ReaderSignInDisplay.off
        ? const <Map<String, Object?>>[]
        : await readerRepo.readersByRecentActivity();

    if (!mounted) return;
    setState(() {
      _display = display;
      _readers = readers;
      _role = display == ReaderSignInDisplay.off ? UserRole.therapist : UserRole.reader;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  String get _email => _role == UserRole.reader
      ? 'mitu.rahman@mail.com'
      : 'r.chowdhury@clinic.org';

  Future<void> _enterAsReader(String participantId, {String? displayName}) async {
    context.read<ParticipantState>().signInAsReader(participantId, displayName: displayName);
    await loadReaderProfile(context, participantId);
    if (!mounted) return;
    // pushAndRemoveUntil rather than pushReplacement: this can be called
    // from the Login screen directly or from All Readers pushed on top of
    // it, and either way sign-in should clear the whole stack down to
    // HomeShell, not just swap out whichever screen is on top.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  Future<void> _enterAsGuest() async {
    final id = await context.read<ReaderRepository>().createGuestReader();
    if (!mounted) return;
    await _enterAsReader(id);
  }

  void _enterAsTherapist() {
    if (_password.text.trim() != kTherapistPassword) {
      setState(() => _passwordError = 'Incorrect password.');
      return;
    }
    setState(() => _passwordError = null);
    context.read<ParticipantState>().signInAsTherapist();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TherapistDashboardScreen()),
    );
  }

  void _notImplemented(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is not available in this prototype.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final showRolePicker = _display != ReaderSignInDisplay.off;
    final isReader = showRolePicker && _role == UserRole.reader;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome back',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              isReader
                  ? 'Sign in to save your reading settings across sessions.'
                  : 'Sign in to manage your readers, assignments and reports.',
              style: const TextStyle(fontSize: 15, color: AppColors.body, height: 1.5),
            ),
            const SizedBox(height: 12),
            if (showRolePicker) ...[
              const Text(
                'I AM A…',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.body),
              ),
              const SizedBox(height: 8),
              _RoleCard(
                icon: Icons.menu_book_rounded,
                title: 'Reader',
                subtitle: 'Read and track my progress',
                selected: isReader,
                onTap: () => setState(() => _role = UserRole.reader),
              ),
              const SizedBox(height: 8),
              _RoleCard(
                icon: Icons.assignment_rounded,
                title: 'Therapist',
                subtitle: 'Manage readers and assignments',
                selected: !isReader,
                onTap: () => setState(() => _role = UserRole.therapist),
              ),
            ],
            if (isReader) ...[
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),
              const Text(
                'WHO IS READING?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.body),
              ),
              const SizedBox(height: 4),
              Text(
                _display == ReaderSignInDisplay.participantIdsOnly
                    ? 'Tap your ID to start reading.'
                    : 'Tap your name to start reading.',
                style: const TextStyle(fontSize: 15, color: AppColors.body, height: 1.5),
              ),
              const SizedBox(height: 10),
              _ReaderPicker(
                readers: _readers.take(maxVisibleReadersOnLogin).toList(),
                display: _display,
                onSelect: (reader) => _enterAsReader(
                  reader['participant_id'] as String,
                  displayName: reader['name'] as String,
                ),
              ),
              if (_readers.length > maxVisibleReadersOnLogin) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AllReadersScreen(
                          readers: _readers,
                          display: _display,
                          onSelect: (reader) => _enterAsReader(
                            reader['participant_id'] as String,
                            displayName: reader['name'] as String,
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      'Show all readers (${_readers.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _GuestDivider(onGuest: _enterAsGuest),
            ] else ...[
              if (showRolePicker) const SizedBox(height: 12),
              const Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.body)),
              const SizedBox(height: 6),
              _InputBox(
                icon: Icons.mail_outline_rounded,
                child: Text(_email, style: const TextStyle(fontSize: 15, color: AppColors.ink)),
              ),
              const SizedBox(height: 10),
              const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.body)),
              const SizedBox(height: 6),
              _InputBox(
                icon: Icons.lock_outline_rounded,
                borderColor: _passwordError == null ? null : AppColors.danger,
                trailing: IconOnlyButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.muted,
                ),
                child: TextField(
                  controller: _password,
                  obscureText: _obscure,
                  onChanged: (_) {
                    if (_passwordError != null) setState(() => _passwordError = null);
                  },
                  onSubmitted: (_) => _enterAsTherapist(),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  style: const TextStyle(fontSize: 15, color: AppColors.ink),
                ),
              ),
              if (_passwordError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _passwordError!,
                  style: const TextStyle(fontSize: 14, color: AppColors.danger),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _notImplemented('Password reset'),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 4),
              PrimaryButton(label: 'Log in', onPressed: _enterAsTherapist),
              if (!showRolePicker) ...[
                const SizedBox(height: 10),
                _GuestDivider(onGuest: _enterAsGuest),
              ],
            ],
            // Readers never create accounts — a therapist adds them — so
            // this only makes sense in the therapist path.
            if (!isReader) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _notImplemented('Account creation'),
                  child: const Text(
                    "New here? Create an account",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The OR-divider plus "Continue as Guest" button shared by both the reader
/// picker and the sign-in-display-off layout.
class _GuestDivider extends StatelessWidget {
  const _GuestDivider({required this.onGuest});

  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Continue as Guest', onPressed: onGuest),
      ],
    );
  }
}

/// The tap-to-choose list of registered readers — labelled by name or by
/// participant ID depending on [display], never both, so a shared study
/// device never leaks a name the setting was switched off to hide.
class _ReaderPicker extends StatelessWidget {
  const _ReaderPicker({
    required this.readers,
    required this.display,
    required this.onSelect,
  });

  final List<Map<String, Object?>> readers;
  final ReaderSignInDisplay display;
  final ValueChanged<Map<String, Object?>> onSelect;

  @override
  Widget build(BuildContext context) {
    if (readers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No readers set up on this device yet. Ask your therapist, or '
          'continue as guest below.',
          style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
        ),
      );
    }

    return Column(
      children: [
        for (final reader in readers) ...[
          ReaderTile(
            name: reader['name'] as String,
            participantId: reader['participant_id'] as String,
            showNameAsPrimary: display != ReaderSignInDisplay.participantIdsOnly,
            onTap: () => onSelect(reader),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navyTint : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.borderStrong,
              width: selected ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: selected ? AppColors.navy : AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.icon, required this.child, this.trailing, this.borderColor});

  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? AppColors.borderStrong, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.canvas,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 22),
          const SizedBox(width: 10),
          Expanded(child: child),
          ?trailing,
        ],
      ),
    );
  }
}
