import 'package:flutter/widgets.dart';

import '../services/app_config_repository.dart';

/// The two languages the interface is written in.
///
/// Bangla is the default and the one the study runs in: the participants are
/// Bangladeshi children of about eleven, and an English interface would add a
/// second reading task on top of the one being measured. English exists for
/// supervisors and examiners.
enum AppLanguage {
  bangla('bn', 'বাংলা'),
  english('en', 'English');

  const AppLanguage(this.code, this.label);

  final String code;

  /// Always written in its own language — a reader looking for Bangla should
  /// not have to read English to find it.
  final String label;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => bangla);
}

/// Which language the interface is in, device-wide.
///
/// Device-level rather than per-reader: a therapist and a child share one
/// phone, and the language has to be right before anyone signs in — including
/// on the sign-in screen itself, where there is no reader yet.
class LanguageState extends ChangeNotifier {
  LanguageState({AppConfigRepository? config})
      : _config = config ?? AppConfigRepository();

  static const storageKey = 'ui_language';

  final AppConfigRepository _config;

  AppLanguage _language = AppLanguage.bangla;
  AppLanguage get language => _language;

  bool get isBangla => _language == AppLanguage.bangla;

  Locale get locale => _language.locale;

  /// Read once at startup. Failure keeps the Bangla default rather than
  /// throwing: an unreadable preference is not a reason to refuse to start.
  Future<void> restore() async {
    try {
      final stored = await _config.get(storageKey);
      final restored = AppLanguage.fromCode(stored);
      if (restored != _language) {
        _language = restored;
        notifyListeners();
      }
    } catch (_) {
      // Keep the default.
    }
  }

  Future<void> select(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    // The switch has already happened on screen; persisting is bookkeeping
    // for next launch and must not make the tap feel slow or fail visibly.
    try {
      await _config.set(storageKey, language.code);
    } catch (_) {
      // Next launch falls back to Bangla, which is the study default anyway.
    }
  }
}
