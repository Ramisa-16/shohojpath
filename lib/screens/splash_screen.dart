import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/auth_state.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import 'home_shell.dart';
import 'login_screen.dart';
import 'therapist/therapist_dashboard_screen.dart';

/// Screen 01 of the design. Loads for a moment (settings are already read
/// from disk by the time `main` calls `runApp`, so this is UX pacing rather
/// than real waiting) then moves on to sign-in — automatically, or sooner if
/// the participant taps through.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), _continue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Waits for the stored token to be read before deciding where to go.
  ///
  /// Without this a returning reader is shown the Login screen for a frame and
  /// then bounced into the app, which reads as the app having forgotten them.
  Future<void> _continue() async {
    _timer?.cancel();
    if (!mounted) return;

    final auth = context.read<AuthState>();
    while (auth.isRestoring) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
    }
    if (!mounted) return;

    final Widget destination;
    if (!auth.isSignedIn) {
      destination = const LoginScreen();
    } else if (auth.isTherapist) {
      destination = const TherapistDashboardScreen();
    } else {
      destination = const HomeShell();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFEAF1F7)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(34),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: 0.28),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'সহজপাঠ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoSansBengali',
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // A single unbroken word with wide letter-spacing has no
                      // wrap point of its own — FittedBox scales the whole
                      // wordmark down as one unit at extreme font-size
                      // settings instead of letting Flutter force a mid-word
                      // break or overflow the screen width.
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'SHOHOJPATH',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.96,
                            color: AppColors.tealText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.t.appTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.body,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 132,
                        height: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: const LinearProgressIndicator(
                            backgroundColor: AppColors.track,
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.t.loadingPreferences,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.muted),
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: context.t.getStarted,
                        onPressed: () => _continue(),
                        expand: false,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        context.t.versionLine,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.muted),
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
