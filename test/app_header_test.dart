import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shohojpath/widgets/app_header.dart';

/// A back arrow that cannot pop is a dead control, and a reader has no way to
/// tell it apart from a broken app. Library and Progress live inside
/// HomeShell's IndexedStack with no route beneath them, so they were showing
/// exactly that.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  Finder backArrow() => find.byIcon(Icons.arrow_back_rounded);

  testWidgets('hides the arrow at the root of a navigator', (tester) async {
    await tester.pumpWidget(
      wrap(AppHeader(title: 'Reading Library', onBack: () {})),
    );
    expect(
      backArrow(),
      findsNothing,
      reason: 'nothing to pop, so the arrow would do nothing',
    );
  });

  testWidgets('shows the arrow on a pushed route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: AppHeader(title: 'History', onBack: () {}),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(backArrow(), findsOneWidget);
  });

  testWidgets('tapping it runs the callback', (tester) async {
    var popped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: AppHeader(
                      title: 'History',
                      onBack: () => popped = true,
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(backArrow());
    await tester.pump();

    expect(popped, isTrue);
  });

  testWidgets('no arrow at all when onBack is omitted', (tester) async {
    await tester.pumpWidget(wrap(const AppHeader(title: 'Home')));
    expect(backArrow(), findsNothing);
  });

  testWidgets('alwaysShowBack forces it on for a non-pop action',
      (tester) async {
    await tester.pumpWidget(
      wrap(AppHeader(title: 'Custom', onBack: () {}, alwaysShowBack: true)),
    );
    expect(backArrow(), findsOneWidget);
  });
}
