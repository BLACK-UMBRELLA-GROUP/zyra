import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/wali/wali_journey_detail_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_journey_service.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_match_service.dart';
import 'package:zyra/services/zyra_wali_journey_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = '11111111-1111-4111-8111-111111111111';
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
  });
  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = true;
    await ZyraAccountState.synchronize(owner);
  });
  tearDown(() {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  WaliJourneyView journey(
    String id, {
    String attempt = 'attempt-1',
    String status = 'active',
    bool isMock = false,
  }) => WaliJourneyView(
    matchId: id,
    attemptId: attempt,
    linkedSeekerId: 'linked-seeker',
    linkedSeekerName: 'Maryam',
    partner: const SeekerProfile(
      id: 'partner',
      firstName: 'Adam',
      age: 31,
      city: '—',
      photos: [],
      gender: 'male',
    ),
    counterpartGuardianName: null,
    counterpartGuardianSurname: null,
    status: status,
    isMock: isMock,
    journeyStage: 'family_stage',
  );
  Future<Map<String, String>> emptyAnswers(String _, String _) async =>
      <String, String>{};
  Future<ZyraSourceResult<List<ZyraMilestone>>> timeline(String _) async =>
      const ZyraSourceResult.available(<ZyraMilestone>[]);
  Future<ZyraSourceResult<List<ZyraChatMessage>>> messages(String _) async =>
      ZyraSourceResult.available([
        ZyraChatMessage(
          id: 'private',
          text: 'Private confirmed conversation',
          fromMe: false,
          createdAt: DateTime.utc(2026, 10, 11),
        ),
      ]);
  Future<ZyraSourceResult<ZyraFamilyReview?>> noReview(String _) async =>
      const ZyraSourceResult<ZyraFamilyReview?>.available(null);
  Future<ZyraSourceResult<String?>> noDecision(String _) async =>
      const ZyraSourceResult<String?>.available(null);

  WaliJourneyDetailScreen screen({
    String id = 'match-1',
    String attempt = 'attempt-1',
    String status = 'active',
    bool isMock = false,
    bool paid = true,
    bool polling = false,
    WaliFamilyAnswerWriter? writer,
    WaliReviewDecisionWriter? reviewWriter,
    Future<bool> Function(String)? reopen,
    WaliFamilyReviewSourceLoader? reviewLoader,
    WaliReviewDecisionSourceLoader? decisionLoader,
  }) => WaliJourneyDetailScreen(
    key: const ValueKey('same-detail'),
    journey: journey(id, attempt: attempt, status: status, isMock: isMock),
    hasGuardianOne: paid,
    enablePolling: polling,
    loadTimeline: timeline,
    loadMessages: messages,
    loadFamilyAnswers: emptyAnswers,
    loadFamilyReview: reviewLoader ?? noReview,
    loadReviewDecision: decisionLoader ?? noDecision,
    writeFamilyAnswer: writer,
    writeReviewDecision: reviewWriter,
    reopenReview: reopen,
  );
  Future<void> mount(
    WidgetTester tester,
    WaliJourneyDetailScreen detail,
  ) async {
    await tester.pumpWidget(MaterialApp(home: detail));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    final fields = find.byType(TextField);
    for (var step = 0; step < 20 && fields.evaluate().isEmpty; step++) {
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
    }
    expect(fields, findsWidgets);
    await tester.ensureVisible(fields.at(0));
    await tester.enterText(fields.at(0), 'First frozen answer');
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), 'Second frozen answer');
    await tester.ensureVisible(find.text('Submit'));
    await tester.pumpAndSettle();
  }

  ButtonStyleButton button(WidgetTester tester, String label) =>
      tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate(
            (widget) => widget is ButtonStyleButton,
          ),
        ),
      );

  void lifetimeTest(String label, Future<void> Function(WidgetTester) body) {
    testWidgets(label, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => ZyraLocalPrefs.bindAccount(null));
      }
    });
  }

  for (final change in ['Journey', 'attempt', 'membership', 'sign-out']) {
    lifetimeTest('pending family save stops after $change replacement', (
      tester,
    ) async {
      final pending = Completer<bool>();
      final calls = <(String, String, String)>[];
      Future<bool> writer(
        String match,
        String _,
        String question,
        String answer,
      ) async {
        calls.add((match, question, answer));
        return calls.length == 1 ? pending.future : true;
      }

      await mount(tester, screen(writer: writer));
      await fill(tester);
      final submit = button(tester, 'Submit').onPressed!;
      submit();
      submit();
      await tester.pump();
      expect(calls, hasLength(1), reason: 'single-flight write');
      if (change == 'sign-out') {
        await tester.runAsync(ZyraAccountState.beginSignOut);
        await tester.pump();
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Private confirmed conversation'), findsNothing);
        expect(find.text('Maryam & Adam'), findsNothing);
      } else {
        await mount(
          tester,
          screen(
            id: change == 'Journey' ? 'match-2' : 'match-1',
            attempt: change == 'attempt' ? 'attempt-2' : 'attempt-1',
            paid: change != 'membership',
            writer: writer,
          ),
        );
      }
      pending.complete(true);
      await tester.pumpAndSettle();
      submit(); // Captured control from the old page remains denied.
      await tester.pump();
      expect(calls, hasLength(1));
      expect(calls.single.$1, 'match-1');
      expect(calls.single.$3, 'First frozen answer');
      expect(tester.takeException(), isNull);
    });
  }

  lifetimeTest('family save freezes typed answers while user edits', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final answers = <String>[];
    Future<bool> writer(String _, String _, String _, String answer) async {
      answers.add(answer);
      return answers.length == 1 ? pending.future : true;
    }

    await mount(tester, screen(writer: writer));
    await fill(tester);
    button(tester, 'Submit').onPressed!();
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'Edited during save');
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(answers, ['First frozen answer', 'Second frozen answer']);
  });

  for (final action in ['Continue', 'Reopen Review']) {
    lifetimeTest('$action failure is visible and retryable', (tester) async {
      final review = (
        id: 'review-1',
        status: action == 'Continue' ? 'pending' : 'paused',
        toStage: 'phase_2',
        deadlineAt: DateTime.now().add(const Duration(hours: 24)),
      );
      Future<ZyraSourceResult<ZyraFamilyReview?>> reviewLoader(
        String _,
      ) async => ZyraSourceResult.available(review);
      var calls = 0;
      await mount(
        tester,
        screen(
          reviewLoader: reviewLoader,
          reviewWriter: (_, _) async {
            calls++;
            return false;
          },
          reopen: (_) async {
            calls++;
            throw StateError('fake transport failure');
          },
        ),
      );
      await tester.ensureVisible(find.text(action));
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(
        find.text("Your review didn't save — please try again."),
        findsOneWidget,
      );
      expect(button(tester, action).onPressed, isNotNull);
    });
  }

  lifetimeTest('review completion cannot change a replaced Journey', (
    tester,
  ) async {
    final pending = Completer<bool>();
    var writes = 0;
    Future<bool> writer(String _, String _) async {
      writes++;
      return pending.future;
    }

    Future<ZyraSourceResult<ZyraFamilyReview?>> reviewLoader(String _) async =>
        ZyraSourceResult.available((
          id: 'review-1',
          status: 'pending',
          toStage: 'phase_2',
          deadlineAt: DateTime.now().add(const Duration(hours: 24)),
        ));
    await mount(
      tester,
      screen(reviewWriter: writer, reviewLoader: reviewLoader),
    );
    await tester.ensureVisible(find.text('Continue'));
    final oldAction = button(tester, 'Continue').onPressed!;
    oldAction();
    oldAction();
    await tester.pump();
    expect(writes, 1);
    await mount(
      tester,
      screen(id: 'match-2', reviewWriter: writer, reviewLoader: reviewLoader),
    );
    pending.complete(false);
    await tester.pumpAndSettle();
    oldAction();
    await tester.pump();
    expect(writes, 1);
    expect(
      find.text("Your review didn't save — please try again."),
      findsNothing,
    );
    expect(button(tester, 'Continue').onPressed, isNotNull);
  });

  for (final action in ['Submit', 'Continue', 'Reopen Review']) {
    lifetimeTest('$action completion while covered does not strand the page', (
      tester,
    ) async {
      final pending = Completer<bool>();
      var calls = 0;
      final review = (
        id: 'review-1',
        status: action == 'Reopen Review' ? 'paused' : 'pending',
        toStage: 'phase_2',
        deadlineAt: DateTime.utc(2030),
      );
      await mount(
        tester,
        screen(
          reviewLoader: action == 'Submit'
              ? noReview
              : (_) async => ZyraSourceResult.available(review),
          writer: (_, _, _, _) async {
            calls++;
            return pending.future;
          },
          reviewWriter: (_, _) async {
            calls++;
            return pending.future;
          },
          reopen: (_) async {
            calls++;
            return pending.future;
          },
        ),
      );
      if (action == 'Submit') await fill(tester);
      await tester.ensureVisible(find.text(action));
      button(tester, action).onPressed!();
      await tester.pump();
      final navigator = Navigator.of(
        tester.element(find.byType(WaliJourneyDetailScreen)),
      );
      unawaited(
        navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Other')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(calls, 1, reason: 'no later family writes while covered');
      navigator.pop();
      await tester.pumpAndSettle();
      expect(button(tester, action).onPressed, isNotNull);
      expect(
        find.text("Your review didn't save — please try again."),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final change in ['paused', 'confirmed decision', 'reopened window']) {
    lifetimeTest('same-ID $change poll denies a retained Continue callback', (
      tester,
    ) async {
      var review = (
        id: 'review-1',
        status: 'pending',
        toStage: 'phase_2',
        deadlineAt: DateTime.utc(2030),
      );
      String? decision;
      var writes = 0;
      await mount(
        tester,
        screen(
          polling: true,
          reviewLoader: (_) async => ZyraSourceResult.available(review),
          decisionLoader: (_) async => ZyraSourceResult.available(decision),
          reviewWriter: (_, _) async {
            writes++;
            return true;
          },
        ),
      );
      final oldAction = button(tester, 'Continue').onPressed!;
      if (change == 'confirmed decision') {
        decision = 'continue';
      } else {
        review = (
          id: review.id,
          status: 'paused',
          toStage: review.toStage,
          deadlineAt: review.deadlineAt,
        );
      }
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      if (change == 'reopened window') {
        review = (
          id: review.id,
          status: 'pending',
          toStage: review.toStage,
          deadlineAt: DateTime.utc(2030, 1, 2),
        );
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(button(tester, 'Continue').onPressed, isNotNull);
      }
      oldAction();
      await tester.pumpAndSettle();
      expect(writes, 0);
    });
  }

  lifetimeTest('old review completion cannot clear a new review busy token', (
    tester,
  ) async {
    final oldWrite = Completer<bool>();
    final newWrite = Completer<bool>();
    var review = (
      id: 'review-1',
      status: 'pending',
      toStage: 'phase_2',
      deadlineAt: DateTime.utc(2030),
    );
    var calls = 0;
    await mount(
      tester,
      screen(
        polling: true,
        reviewLoader: (_) async => ZyraSourceResult.available(review),
        reviewWriter: (_, _) async {
          calls++;
          return calls == 1 ? oldWrite.future : newWrite.future;
        },
      ),
    );
    button(tester, 'Continue').onPressed!();
    await tester.pump();
    review = (
      id: 'review-2',
      status: 'pending',
      toStage: 'phase_2',
      deadlineAt: DateTime.utc(2030, 1, 2),
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    button(tester, 'Continue').onPressed!();
    await tester.pump();
    oldWrite.complete(false);
    await tester.pump();
    expect(button(tester, 'Continue').onPressed, isNull);
    expect(calls, 2);
    newWrite.complete(false);
    await tester.pumpAndSettle();
    expect(button(tester, 'Continue').onPressed, isNotNull);
  });

  lifetimeTest('ended archive retains reads without family or review writers', (
    tester,
  ) async {
    var writes = 0;
    Future<bool> reviewWriter(String _, String _) async {
      writes++;
      return true;
    }

    Future<bool> familyWriter(String _, String _, String _, String _) async {
      writes++;
      return true;
    }

    Future<ZyraSourceResult<ZyraFamilyReview?>> reviewLoader(String _) async =>
        ZyraSourceResult.available((
          id: 'review-1',
          status: 'pending',
          toStage: 'phase_2',
          deadlineAt: DateTime.utc(2030),
        ));
    await mount(
      tester,
      screen(
        writer: familyWriter,
        reviewWriter: reviewWriter,
        reviewLoader: reviewLoader,
      ),
    );
    final continueReview = button(tester, 'Continue').onPressed!;
    await fill(tester);
    final submit = button(tester, 'Submit').onPressed!;
    await mount(
      tester,
      screen(
        status: 'ended',
        writer: familyWriter,
        reviewWriter: reviewWriter,
        reviewLoader: reviewLoader,
      ),
    );
    expect(find.text('Submit'), findsNothing);
    expect(find.text('Continue'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Private confirmed conversation'),
      180,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Private confirmed conversation'), findsOneWidget);
    submit();
    continueReview();
    await tester.pumpAndSettle();
    expect(writes, 0);
  });

  lifetimeTest(
    'withdrawn mock authority never falls into ordinary writes or reads',
    (tester) async {
      var reads = 0;
      var writes = 0;
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await mount(
        tester,
        WaliJourneyDetailScreen(
          journey: journey('dev-wj0', isMock: true),
          hasGuardianOne: true,
          enablePolling: true,
          loadTimeline: (_) async {
            reads++;
            return const ZyraSourceResult.available(<ZyraMilestone>[]);
          },
          loadMessages: messages,
          loadFamilyReview: noReview,
          loadFamilyAnswers: emptyAnswers,
          writeFamilyAnswer: (_, _, _, _) async {
            writes++;
            return true;
          },
        ),
      );
      await fill(tester);
      final oldSubmit = button(tester, 'Submit').onPressed!;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Maryam & Adam'), findsNothing);
      oldSubmit();
      await tester.pump(const Duration(seconds: 6));
      expect(reads, 0);
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
