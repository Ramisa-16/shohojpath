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

  bool _searchFocusRequested = false;

  /// Home's search field is a shortcut into Library's real one, so switching
  /// tabs is only half the job: arriving at a search screen with the keyboard
  /// down leaves the reader to tap a second time for the thing they already
  /// asked for.
  void openLibrarySearch() {
    _searchFocusRequested = true;
    _tab = AppTab.library;
    notifyListeners();
  }

  /// Reads the request and clears it. One-shot on purpose — a later rebuild
  /// of Library (a filter tap, a rotation) must not pop the keyboard back up.
  bool takeSearchFocusRequest() {
    if (!_searchFocusRequested) return false;
    _searchFocusRequested = false;
    return true;
  }
}
