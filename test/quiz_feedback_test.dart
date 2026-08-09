import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shohojpath/api/api_client.dart';
import 'package:shohojpath/api/shohojpath_api.dart';
import 'package:shohojpath/api/token_store.dart';
import 'package:shohojpath/models/passage.dart';
import 'package:shohojpath/models/quiz_question.dart';
import 'package:shohojpath/models/reading_settings.dart';
import 'package:shohojpath/models/study_session.dart';
import 'package:shohojpath/screens/quiz_screen.dart';
import 'package:shohojpath/services/passage_repository.dart';
import 'package:shohojpath/services/session_logger.dart';
import 'package:shohojpath/app/participant_state.dart';

/// The quiz marks an answer the moment it is tapped. The rules that matter
/// are not the colours: the tap must be final, the correct option must be
/// revealed either way, and the recorded time must be the deciding time
/// rather than the time spent reading the feedback afterwards.
class _NoDbLogger extends SessionLogger {
  @override
  Future<void> logQuizAnswers(String sessionId, List<QuizAnswer> answers) async {}
}

/// Serves the questions the screen asks for, without a network or a database.
class _FixedRepository extends PassageRepository {
  _FixedRepository(super.api, this._questions);

  final List<QuizQuestion> _questions;

  @override
  List<QuizQuestion> questionsFor(String passageId) => _questions;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final passage = Passage(
    id: 'aesop_kak',
    title: 'কাক ও শিয়াল',
    category: 'ইশপের গল্প',
    difficulty: PassageDifficulty.easy,
    estimatedMinutes: 2,
    pages: const [
      PassagePage(['এক কাক একটুকরো মাংস নিয়ে গাছে বসেছিল।']),
    ],
  );

  // correctIndex 0 on the first question, 2 on the second.
  final questions = <QuizQuestion>[
    const QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'কাকের মুখে কী ছিল?',
      options: ['একটুকরো মাংস', 'একটি ফল', 'একটি বাদাম', 'একটি মাছ'],
      correctIndex: 0,
    ),
    const QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'শিয়াল কী করেছিল?',
      options: ['ঘুমিয়ে ছিল', 'পালিয়ে গেল', 'প্রশংসা করল', 'কেঁদেছিল'],
      correctIndex: 2,
    ),
  ];

  late StudySession session;

  Future<void> pumpQuiz(WidgetTester tester) async {
    tester.view.physicalSize = const Size(700, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    session = StudySession(
      sessionId: 's1',
      passage: passage,
      readAloudWasOn: false,
      readingDuration: const Duration(minutes: 2),
    );

    final api = ShohojpathApi(ApiClient(tokens: TokenStore()));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ReadingSettings()),
          ChangeNotifierProvider(create: (_) => ParticipantState()),
          Provider<SessionLogger>.value(value: _NoDbLogger()),
          Provider<PassageRepository>.value(
            value: _FixedRepository(api, questions),
          ),
          Provider<ShohojpathApi>.value(value: api),
        ],
        child: MaterialApp(home: QuizScreen(session: session)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder option(String label) => find.text(label);

  bool hasIcon(WidgetTester tester, IconData icon) =>
      find.byIcon(icon).evaluate().isNotEmpty;

  testWidgets('a correct tap is marked correct immediately', (tester) async {
    await pumpQuiz(tester);

    expect(hasIcon(tester, Icons.check_circle_rounded), isFalse);

    await tester.tap(option('একটুকরো মাংস'));
    await tester.pumpAndSettle();

    expect(hasIcon(tester, Icons.check_circle_rounded), isTrue);
    expect(hasIcon(tester, Icons.cancel_rounded), isFalse);
    expect(find.text('ঠিক হয়েছে!'), findsOneWidget);
  });

  testWidgets('a wrong tap reveals the right answer too', (tester) async {
    await pumpQuiz(tester);

    await tester.tap(option('একটি বাদাম'));
    await tester.pumpAndSettle();

    // Their choice is marked wrong AND the correct one is marked, which is
    // the whole point — a child who guessed still learns the answer.
    expect(hasIcon(tester, Icons.cancel_rounded), isTrue);
    expect(hasIcon(tester, Icons.check_circle_rounded), isTrue);
    expect(find.text('সঠিক উত্তরটি চিহ্নিত করা হয়েছে।'), findsOneWidget);
  });

  testWidgets('feedback never depends on colour alone', (tester) async {
    await pumpQuiz(tester);
    await tester.tap(option('একটি বাদাম'));
    await tester.pumpAndSettle();

    // Roughly one boy in twelve cannot separate red from green. Both states
    // must carry an icon and words as well.
    expect(hasIcon(tester, Icons.cancel_rounded), isTrue);
    expect(hasIcon(tester, Icons.check_circle_rounded), isTrue);
    expect(find.textContaining('সঠিক উত্তর'), findsOneWidget);
  });

  testWidgets('the first tap is final', (tester) async {
    await pumpQuiz(tester);

    await tester.tap(option('একটি বাদাম'));
    await tester.pumpAndSettle();
    // Changing to the right answer after seeing it revealed would make the
    // score a measure of who spotted the marking.
    await tester.tap(option('একটুকরো মাংস'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next question'));
    await tester.pumpAndSettle();

    expect(session.quizAnswers.single.selectedIndex, 2);
    expect(session.quizAnswers.single.correct, isFalse);
  });

  testWidgets('the recorded time is the deciding time, not the reading-the-'
      'feedback time', (tester) async {
    await pumpQuiz(tester);

    await tester.pump(const Duration(seconds: 4));
    await tester.tap(option('একটুকরো মাংস'));
    await tester.pumpAndSettle();

    // They then sit looking at the feedback for a while before moving on.
    await tester.pump(const Duration(seconds: 30));
    await tester.tap(find.text('Next question'));
    await tester.pumpAndSettle();

    final recorded = session.quizAnswers.single.timeTaken;
    expect(recorded.inSeconds, lessThan(20),
        reason: 'the 30s spent reading the feedback must not be counted');
  });

  testWidgets('the next question starts clean', (tester) async {
    await pumpQuiz(tester);

    await tester.tap(option('একটুকরো মাংস'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next question'));
    await tester.pumpAndSettle();

    expect(find.text('শিয়াল কী করেছিল?'), findsOneWidget);
    expect(hasIcon(tester, Icons.check_circle_rounded), isFalse);
    expect(find.text('ঠিক হয়েছে!'), findsNothing);
  });

  testWidgets('Next does nothing until something is answered', (tester) async {
    await pumpQuiz(tester);

    await tester.tap(find.text('Next question'));
    await tester.pumpAndSettle();

    // Still on question one, and nothing recorded — skipping forward would
    // leave a hole in the per-question data the study exports.
    expect(find.text('কাকের মুখে কী ছিল?'), findsOneWidget);
    expect(session.quizAnswers, isEmpty);
  });
}
