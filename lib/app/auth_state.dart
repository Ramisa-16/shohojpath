import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../api/shohojpath_api.dart';
import 'participant_state.dart';
import '../l10n/app_strings.dart';
import '../l10n/app_language.dart';

/// Who is signed in, backed by the server.
///
/// Sits alongside [ParticipantState] rather than replacing it: that class is
/// what every existing screen already reads for "whose data is this", so
/// signing in here pushes the identity into it and the rest of the app keeps
/// working unchanged.
class AuthState extends ChangeNotifier {
  AuthState({
    required ShohojpathApi api,
    required ParticipantState participant,
    LanguageState? language,
  })  : _api = api,
        _participant = participant,
        _language = language {
    _api.client.onSessionExpired = _handleSessionExpired;
  }

  final ShohojpathApi _api;

  /// This class has no BuildContext, but the one message it writes itself is
  /// read by whoever was signed in — so it has to follow their language
  /// rather than assume one. Optional so tests can build an AuthState
  /// without the whole provider tree; Bangla is the default either way.
  final LanguageState? _language;

  AppStrings get _strings =>
      AppStrings(_language?.language ?? AppLanguage.bangla);
  final ParticipantState _participant;

  bool _restoring = true;
  bool _busy = false;
  String? _error;

  /// Clears the error automatically. Without this the banner outlives the
  /// screen that produced it — a failed sign-in was still showing on the Sign
  /// up page, where it makes no sense and looks like the new form failed
  /// before it was even filled in.
  Timer? _errorTimer;
  static const Duration errorLifetime = Duration(seconds: 5);

  String? _email;
  String? _fullName;
  String? _role;
  String? _participantId;

  /// True while the stored token is being read at startup — the splash screen
  /// must wait for this rather than flashing Login at a signed-in user.
  bool get isRestoring => _restoring;
  bool get isBusy => _busy;
  String? get error => _error;

  bool get isSignedIn => _role != null;
  bool get isTherapist => _role == 'therapist';
  bool get isReader => _role == 'reader';

  String? get email => _email;
  String? get fullName => _fullName;
  String? get participantId => _participantId;

  /// Restores a previous session from the keystore.
  ///
  /// Deliberately does not call the server: a reader opening the app on a bus
  /// with no signal must still get into their passages. The token is verified
  /// lazily by the first real request instead.
  Future<void> restore() async {
    _restoring = true;
    notifyListeners();

    await _api.client.tokens.load();
    if (_api.client.tokens.hasSession) {
      final profile = await _api.client.tokens.readProfile();
      _role = profile['role'];
      _email = profile['email'];
      _fullName = profile['full_name'];
      _participantId = profile['participant_id'];
      _pushToParticipantState();
    }

    _restoring = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String role,
    String? fullName,
    int? age,
    String? classGrade,
    String? school,
  }) =>
      _run(() => _api.signUp(
            email: email,
            password: password,
            role: role,
            fullName: fullName,
            age: age,
            classGrade: classGrade,
            school: school,
          ));

  Future<bool> logIn({required String email, required String password}) =>
      _run(() => _api.logIn(email: email, password: password));

  Future<bool> _run(Future<Map<String, dynamic>> Function() call) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final data = await call();
      await _adopt(data);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _adopt(Map<String, dynamic> data) async {
    final user = Map<String, dynamic>.from(data['user'] as Map);
    _role = user['role'] as String?;
    _email = user['email'] as String?;
    _fullName = user['full_name'] as String?;
    _participantId = data['participant_id'] as String?;

    await _api.client.tokens.save(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
      role: _role,
      participantId: _participantId,
      email: _email,
      fullName: _fullName,
    );

    _pushToParticipantState();
  }

  void _pushToParticipantState() {
    if (isTherapist) {
      _participant.signInAsTherapist();
    } else if (isReader && _participantId != null) {
      _participant.signInAsReader(
        _participantId!,
        displayName: _fullName?.isNotEmpty == true ? _fullName : null,
      );
    }
  }

  Future<void> signOut() async {
    await _api.client.tokens.clear();
    _errorTimer?.cancel();
    _role = null;
    _email = null;
    _fullName = null;
    _participantId = null;
    _error = null;
    _participant.signOut();
    notifyListeners();
  }

  /// The refresh token was rejected — the session is genuinely over, as
  /// opposed to merely being offline, which never lands here.
  void _handleSessionExpired() {
    if (!isSignedIn) return;
    _setError(_strings.sessionExpired);
    signOut();
  }

  void _setError(String message) {
    _error = message;
    _errorTimer?.cancel();
    _errorTimer = Timer(errorLifetime, clearError);
  }

  void clearError() {
    _errorTimer?.cancel();
    _errorTimer = null;
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    super.dispose();
  }
}
