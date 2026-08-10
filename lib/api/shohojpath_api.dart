import 'api_client.dart';

/// Typed wrappers over the Django endpoints.
///
/// One place that knows the URL strings and the response shapes, so a change on
/// the server surfaces as a compile-time or single-file change rather than a
/// string edit hunted across a dozen screens.
class ShohojpathApi {
  ShohojpathApi(this.client);

  final ApiClient client;

  // ---- Auth --------------------------------------------------------------

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String role,
    String? fullName,
    int? age,
    String? classGrade,
    String? school,
  }) async {
    final data = await client.post(
      '/api/auth/signup/',
      authenticated: false,
      body: {
        'email': email.trim(),
        'password': password,
        'role': role,
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
        'age': ?age,
        if (classGrade != null && classGrade.isNotEmpty) 'class_grade': classGrade,
        if (school != null && school.isNotEmpty) 'school': school,
      },
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> logIn({
    required String email,
    required String password,
  }) async {
    final data = await client.post(
      '/api/auth/login/',
      authenticated: false,
      body: {'email': email.trim(), 'password': password},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> me() async =>
      Map<String, dynamic>.from(await client.get('/api/auth/me/') as Map);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      client.post('/api/auth/password/', body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });

  // ---- Readers (therapist side) -----------------------------------------

  /// Readers no therapist has added yet — the Add Reader list.
  Future<List<Map<String, dynamic>>> availableReaders({String? search}) =>
      _list('/api/readers/available/', query: {'search': search});

  Future<List<Map<String, dynamic>>> myReaders() =>
      _list('/api/readers/mine/');

  Future<Map<String, dynamic>> registerReader({
    required String displayName,
    int? age,
    String? classGrade,
    String? school,
    String? startingProfile,
  }) async {
    final data = await client.post('/api/readers/mine/', body: {
      'display_name': displayName,
      'age': ?age,
      'class_grade': ?classGrade,
      'school': ?school,
      'starting_profile': ?startingProfile,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  /// Asks a reader for permission to supervise them. Nothing changes until
  /// they accept — [ApiException.isConflict] means they already have a
  /// therapist, or have no account to answer with.
  Future<Map<String, dynamic>> requestSupervision(String participantId) async {
    final data = await client.post('/api/readers/$participantId/request/');
    return Map<String, dynamic>.from(data as Map);
  }

  /// Supervision requests waiting on the signed-in reader.
  Future<List<Map<String, dynamic>>> mySupervisionRequests() =>
      _list('/api/me/supervision-requests/');

  /// Answers one. [ApiException.isConflict] means it was already answered,
  /// or someone else was accepted first.
  Future<Map<String, dynamic>> respondToSupervision(int id,
      {required bool accept}) async {
    final data = await client.post(
      '/api/supervision-requests/$id/respond/',
      body: {'accept': accept},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> releaseReader(String participantId) =>
      client.post('/api/readers/$participantId/release/');

  Future<List<Map<String, dynamic>>> readerNotes(String participantId) =>
      _list('/api/readers/$participantId/notes/');

  Future<void> addReaderNote(String participantId, String text) =>
      client.post('/api/readers/$participantId/notes/', body: {'text': text});

  // ---- Notifications -----------------------------------------------------

  Future<List<Map<String, dynamic>>> notifications({bool unreadOnly = false}) =>
      _list('/api/notifications/',
          query: {if (unreadOnly) 'unread': 'true'});

  Future<void> markNotificationRead(int id) =>
      client.post('/api/notifications/$id/read/');

  Future<void> markAllNotificationsRead() =>
      client.post('/api/notifications/read-all/');

  // ---- Passages ----------------------------------------------------------

  Future<List<Map<String, dynamic>>> passages({
    String? search,
    String? category,
    String? difficulty,
  }) =>
      _list('/api/passages/', query: {
        'search': search,
        'category': category,
        'difficulty': difficulty,
      });

  Future<Map<String, dynamic>> passage(String slug) async =>
      Map<String, dynamic>.from(await client.get('/api/passages/$slug/') as Map);

  Future<List<String>> passageCategories() async {
    final data = await client.get('/api/passages/categories/') as Map;
    return List<String>.from(data['categories'] as List);
  }

  // ---- Bookmarks ---------------------------------------------------------

  Future<List<Map<String, dynamic>>> bookmarks() => _list('/api/bookmarks/');

  Future<Map<String, dynamic>> addBookmark({
    required String passageId,
    required int pageIndex,
    String excerpt = '',
  }) async {
    final data = await client.post('/api/bookmarks/', body: {
      'passage_id': passageId,
      'page_index': pageIndex,
      'excerpt': excerpt,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> deleteBookmark(int id) => client.delete('/api/bookmarks/$id/');

  // ---- Assignments -------------------------------------------------------

  Future<List<Map<String, dynamic>>> myAssignments() =>
      _list('/api/assignments/mine/');

  Future<List<Map<String, dynamic>>> readerAssignments(String participantId) =>
      _list('/api/readers/$participantId/assignments/');

  Future<void> assignPassage({
    required String participantId,
    required String passageId,
    String? profile,
  }) =>
      client.post('/api/readers/$participantId/assignments/', body: {
        'passage_id': passageId,
        'profile': ?profile,
      });

  Future<void> unassignPassage(String participantId, String passageId) =>
      client.delete('/api/readers/$participantId/assignments/$passageId/');

  // ---- Progress & statistics --------------------------------------------

  Future<Map<String, dynamic>> myProgress() async =>
      Map<String, dynamic>.from(await client.get('/api/me/progress/') as Map);

  Future<Map<String, dynamic>> myStatistics() async =>
      Map<String, dynamic>.from(await client.get('/api/me/statistics/') as Map);

  Future<List<Map<String, dynamic>>> mySessions() =>
      _list('/api/sessions/mine/');

  /// The same figures the reader sees, for their therapist.
  Future<Map<String, dynamic>> readerProgress(String participantId) async =>
      Map<String, dynamic>.from(
        await client.get('/api/readers/$participantId/progress/') as Map,
      );

  Future<Map<String, dynamic>> readerStatistics(String participantId) async =>
      Map<String, dynamic>.from(
        await client.get('/api/readers/$participantId/statistics/') as Map,
      );

  Future<List<Map<String, dynamic>>> readerSessions(String participantId) =>
      _list('/api/readers/$participantId/sessions/');

  Future<Map<String, dynamic>> therapistOverview() async =>
      Map<String, dynamic>.from(
        await client.get('/api/therapist/overview/') as Map,
      );

  Future<List<Map<String, dynamic>>> therapistReaderSummary() async {
    final data = await client.get('/api/therapist/readers-summary/') as Map;
    return List<Map<String, dynamic>>.from(
      (data['readers'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---- My profile & settings --------------------------------------------

  Future<Map<String, dynamic>> myProfile() async =>
      Map<String, dynamic>.from(await client.get('/api/me/profile/') as Map);

  Future<Map<String, dynamic>> updateMyProfile({
    String? displayName,
    int? age,
    String? classGrade,
    String? school,
    String? startingProfile,
  }) async {
    final data = await client.patch('/api/me/profile/', body: {
      'display_name': ?displayName,
      'age': ?age,
      'class_grade': ?classGrade,
      'school': ?school,
      'starting_profile': ?startingProfile,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  /// The reader's configuration, mirrored so it survives a reinstall and so
  /// their therapist can see the condition they actually read under.
  Future<Map<String, dynamic>> mySettings() async =>
      Map<String, dynamic>.from(await client.get('/api/me/settings/') as Map);

  Future<void> saveMySettings(Map<String, Object?> values) =>
      client.put('/api/me/settings/', body: {'values': values});

  Future<Map<String, dynamic>> readerSettings(String participantId) async =>
      Map<String, dynamic>.from(
        await client.get('/api/readers/$participantId/settings/') as Map,
      );

  // ---- Editable app copy -------------------------------------------------

  /// Help features, FAQs, About rows and notices — one request, because these
  /// are a few dozen short strings and two screens should not each wait on a
  /// host that may be waking from sleep.
  Future<Map<String, dynamic>> appContent() async =>
      Map<String, dynamic>.from(await client.get('/api/content/') as Map);

  // ---- Sync --------------------------------------------------------------

  Future<Map<String, dynamic>> uploadSessions(
    List<Map<String, dynamic>> sessions,
  ) async {
    final data = await client.post(
      '/api/sync/sessions/',
      body: {'sessions': sessions},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  // ---- Helpers -----------------------------------------------------------

  /// Unwraps DRF pagination, following `next` so a caller never silently sees
  /// only the first 50 of a longer list.
  Future<List<Map<String, dynamic>>> _list(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final results = <Map<String, dynamic>>[];
    dynamic response = await client.get(path, query: query);

    while (true) {
      if (response is List) {
        results.addAll(response.map((e) => Map<String, dynamic>.from(e as Map)));
        return results;
      }

      final map = Map<String, dynamic>.from(response as Map);
      final page = map['results'] as List? ?? const [];
      results.addAll(page.map((e) => Map<String, dynamic>.from(e as Map)));

      final next = map['next'] as String?;
      if (next == null || next.isEmpty) return results;

      // DRF returns `next` as an absolute URL; the client builds its own from
      // the configured base, so only the path and query travel onward.
      final nextUri = Uri.parse(next);
      response = await client.get(
        nextUri.path,
        query: nextUri.queryParameters,
      );
    }
  }
}
