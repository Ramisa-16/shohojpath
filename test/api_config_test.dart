import 'package:flutter_test/flutter_test.dart';

import 'package:shohojpath/api/api_config.dart';

/// An APK built for a study device must reach the deployed server. Leaving
/// that to a --dart-define on every release means one forgotten flag produces
/// an app that starts, looks correct, and records nothing.
void main() {
  test('the production host is https with no trailing slash', () {
    // A trailing slash here yields '//api/passages/' once a path is appended,
    // which Django answers with a redirect the client will not follow.
    expect(ApiConfig.production, startsWith('https://'));
    expect(ApiConfig.production, isNot(endsWith('/')));
    expect(ApiConfig.production, 'https://shohojpath.pythonanywhere.com');
  });

  test('tests and debug builds stay on the loopback address', () {
    // kReleaseMode is false under the test runner, so this is the debug path.
    // A test suite that quietly talked to the live study server would be both
    // slow and capable of writing to real participant data.
    expect(ApiConfig.baseUrl, contains('127.0.0.1'));
    expect(ApiConfig.baseUrl, isNot(contains('pythonanywhere')));
  });

  test('url() joins paths without doubling the separator', () {
    expect(
      ApiConfig.url('/api/passages/').toString(),
      '${ApiConfig.baseUrl}/api/passages/',
    );
    // Callers are inconsistent about the leading slash; both must work.
    expect(
      ApiConfig.url('api/passages/').toString(),
      '${ApiConfig.baseUrl}/api/passages/',
    );
  });

  test('url() drops null query values rather than sending "null"', () {
    final uri = ApiConfig.url('/api/passages/', {
      'search': 'শিয়াল',
      'category': null,
      'difficulty': 'easy',
    });

    expect(uri.queryParameters['search'], 'শিয়াল');
    expect(uri.queryParameters.containsKey('category'), isFalse);
    expect(uri.queryParameters['difficulty'], 'easy');
  });

  test('the timeout allows for a host waking up', () {
    // PythonAnywhere does not sleep on idle, but it does reboot for
    // maintenance, and the first request after that pays the startup cost.
    expect(ApiConfig.timeout.inSeconds, greaterThanOrEqualTo(30));
    expect(ApiConfig.healthTimeout, lessThan(ApiConfig.timeout));
  });
}
