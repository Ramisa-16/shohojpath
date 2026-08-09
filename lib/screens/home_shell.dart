import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_nav_state.dart';
import '../widgets/bottom_tab_bar.dart';
import '../widgets/therapist_session_banner.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';

/// The tabbed shell around Home, Library, Progress and Profile.
///
/// This is the app's single root route — every other screen is pushed on
/// top of it, so [BottomTabBar] can always get back here with a plain
/// `popUntil((r) => r.isFirst)`.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<AppNavState>().tab;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TherapistSessionBanner(),
            Expanded(
              child: IndexedStack(
                index: AppTab.values.indexOf(tab),
                // showBack: false — these are tabs, not pushed routes, so
                // there is nothing beneath them to go back to.
                children: const [
                  HomeScreen(),
                  LibraryScreen(showBack: false),
                  ProgressScreen(showBack: false),
                  ProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomTabBar(current: tab),
    );
  }
}
