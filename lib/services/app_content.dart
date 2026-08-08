import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../api/shohojpath_api.dart';
import '../data/mock_content.dart';

/// The editable copy behind Help and About.
///
/// Fetched so a researcher can reword it in the admin — an ethics board may
/// require exact wording on the disclaimer — and cached, with the strings that
/// used to be compiled into the app as the offline fallback. Help and About
/// must never be blank: they are the two screens someone opens when they are
/// already confused.
class AppContent extends ChangeNotifier {
  AppContent(this._api);

  final ShohojpathApi _api;

  List<HelpFeature> _features = MockContent.helpFeatures;
  List<Faq> _faqs = MockContent.faqs;
  List<KeyValue> _about = MockContent.about;
  List<String> _accessibility = MockContent.accessibilitySummary;
  Map<String, String> _notices = const {};

  bool _loaded = false;

  List<HelpFeature> get helpFeatures => _features;
  List<Faq> get faqs => _faqs;
  List<KeyValue> get about => _about;
  List<String> get accessibilitySummary => _accessibility;

  /// True once the server's copy has replaced the bundled fallback.
  bool get isLive => _loaded;

  String notice(String key, String fallback) => _notices[key] ?? fallback;

  Future<void> load() async {
    try {
      final data = await _api.appContent();

      final features = <HelpFeature>[];
      for (final raw in (data['help_features'] as List? ?? const [])) {
        final row = Map<String, dynamic>.from(raw as Map);
        features.add(
          HelpFeature(
            icon: _iconFor('${row['icon']}'),
            name: '${row['name']}',
            description: '${row['description']}',
          ),
        );
      }

      final faqs = <Faq>[];
      for (final raw in (data['faqs'] as List? ?? const [])) {
        final row = Map<String, dynamic>.from(raw as Map);
        faqs.add(
          Faq(question: '${row['question']}', answer: '${row['answer']}'),
        );
      }

      final about = <KeyValue>[];
      for (final raw in (data['about'] as List? ?? const [])) {
        final row = Map<String, dynamic>.from(raw as Map);
        about.add(KeyValue('${row['key']}', '${row['value']}'));
      }

      final accessibility = [
        for (final row in (data['accessibility'] as List? ?? const [])) '$row',
      ];

      // Only replace a section the server actually populated. A
      // half-configured backend must not blank out copy the app already had.
      if (features.isNotEmpty) _features = features;
      if (faqs.isNotEmpty) _faqs = faqs;
      if (about.isNotEmpty) _about = about;
      if (accessibility.isNotEmpty) _accessibility = accessibility;

      final notices = <String, String>{};
      for (final entry in (data['notices'] as Map? ?? const {}).entries) {
        final value = Map<String, dynamic>.from(entry.value as Map);
        notices['${entry.key}'] = '${value['body']}';
      }
      _notices = notices;

      _loaded = true;
      notifyListeners();
    } on ApiException {
      // Offline: the bundled copy stands, which is the whole point of keeping
      // it around rather than shipping empty screens.
    }
  }

  /// Maps the admin's Material icon names onto the small icon set the app
  /// knows about. An unrecognised name falls back rather than crashing on
  /// something a researcher mistyped.
  static IconDataId _iconFor(String name) => switch (name) {
        'volume_up' => IconDataId.volumeUp,
        'spellcheck' => IconDataId.spellcheck,
        'format_size' => IconDataId.formatSize,
        'format_line_spacing' => IconDataId.formatLineSpacing,
        'straighten' || 'ruler' => IconDataId.ruler,
        'bookmark' => IconDataId.bookmark,
        _ => IconDataId.bookmark,
      };
}
