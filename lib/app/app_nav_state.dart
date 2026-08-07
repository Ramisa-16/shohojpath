import 'package:flutter/foundation.dart';

/// The four destinations on the persistent bottom tab bar (screen map's
/// `showTabs` set, minus Statistics — Stats is reached by pushing from
/// Progress and shares the bar only so a tap on it can jump straight back).
enum AppTab { home, library, progress, profile }

/// Which bottom tab is selected, shared across the tabbed shell and any
/// pushed screen (like Statistics) that still shows the bar.
///
/// A tap on the bar from a pushed screen has to both pop back to the shell
/// and select a tab — a plain constructor argument can't do that because the
/// shell already exists further down the navigation stack, so this is a
/// small piece of app-wide state instead.
class AppNavState extends ChangeNotifier {
  AppTab _tab = AppTab.home;
  AppTab get tab => _tab;

  void select(AppTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }
}
