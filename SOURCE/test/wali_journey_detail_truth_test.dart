import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/wali/wali_journey_detail_screen.dart';
import 'package:zyra/services/zyra_journey_service.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_match_service.dart';
import 'package:zyra/services/zyra_wali_journey_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  const journey = WaliJourneyView(
    matchId: 'match-1',
    linkedSeekerId: 'seeker-1',
    linkedSeekerName: 'Maryam',
    partner: SeekerProfile(
      id: 'partner-1',
      firstName: 'Adam',
      age: 31,
      city: '—',
      photos: [],
      gender: 'male',
    ),
    counterpartGuardianName: null,
    counterpartGuardianSurname: null,
    status: 'active',
    journeyStage: 'phase_1',
  );

  Future<ZyraSourceResult<ZyraFamilyReview?>> noReview(String _) async =>
      const ZyraSourceResult<ZyraFamilyReview?>.available(null);
  Future<ZyraSourceResult<String?>> noDecision(String _) async =>
      const ZyraSourceResult<String?>.available(null);

  Widget app(WaliJourneyDetailScreen screen) => MaterialApp(home: screen);

  // Race fixtures use only injected, fake read sources, with developer access
  // OFF and explicit paid capability. The stable key deliberately preserves
  // the public widget's State across plan/Journey/source replacements.
  WaliJourneyDetailScreen raceScreen(
    WaliMessagesSourceLoader messages, {
    bool paid = true,
    WaliJourneyView currentJourney = journey,
  }) => WaliJourneyDetailScreen(
    key: const ValueKey('guardian-message-race-detail'),
    journey: currentJourney,
    hasGuardianOne: paid,
    loadTimeline: (_) async =>
        const ZyraSourceResult.available(<ZyraMilestone>[]),
    loadMessages: messages,
    loadFamilyReview: noReview,
    loadReviewDecision: noDecision,
  );

  Future<void> raceMount(
    WidgetTester tester,
    WaliJourneyDetailScreen screen,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = true;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraText.useTestFontStubs = false;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app(screen));
    await tester.pump();
    await tester.pump();
  }

  Future<void> racePoll(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
  }

  ZyraChatMessage oldMessage() => ZyraChatMessage(
    id: 'synthetic-old-refresh-message',
    text: 'Old read must not resurrect this message',
    fromMe: false,
    createdAt: DateTime.utc(2026, 10, 10),
  );

  testWidgets('successful empty reads keep the existing empty copy', (
    tester,
  ) async {
    var decisionCalls = 0;
    await tester.pumpWidget(
      app(
        WaliJourneyDetailScreen(
          journey: journey,
          hasGuardianOne: true,
          enablePolling: false,
          loadTimeline: (_) async =>
              const ZyraSourceResult.available(<ZyraMilestone>[]),
          loadMessages: (_) async =>
              const ZyraSourceResult.available(<ZyraChatMessage>[]),
          loadFamilyReview: noReview,
          loadReviewDecision: (_) async {
            decisionCalls++;
            return const ZyraSourceResult<String?>.available(null);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Nothing recorded here yet.'),
      300,
    );
    expect(find.text('Nothing recorded here yet.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('No messages yet.'), 300);
    expect(find.text('No messages yet.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('wali-timeline-unavailable')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('wali-conversation-unavailable')),
      findsNothing,
    );
    expect(decisionCalls, 0, reason: 'no review means no decision lookup');
  });

  testWidgets('Guardian Basic can view Journey without conversation access', (
    tester,
  ) async {
    var messageCalls = 0;
    await tester.pumpWidget(
      app(
        WaliJourneyDetailScreen(
          journey: journey,
          hasGuardianOne: false,
          enablePolling: false,
          loadTimeline: (_) async =>
              const ZyraSourceResult.available(<ZyraMilestone>[]),
          loadMessages: (_) async {
            messageCalls++;
            return const ZyraSourceResult.available(<ZyraChatMessage>[]);
          },
          loadFamilyReview: noReview,
          loadReviewDecision: noDecision,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maryam\'s Journey with Adam'), findsOneWidget);
    expect(find.text('CONVERSATION'), findsNothing);
    expect(find.text('No messages yet.'), findsNothing);
    expect(messageCalls, 0);
  });

  testWidgets(
    'each failed source stays unavailable and Timeline retries locally',
    (tester) async {
      var timelineCalls = 0;
      var messageCalls = 0;
      var reviewCalls = 0;
      await tester.pumpWidget(
        app(
          WaliJourneyDetailScreen(
            journey: journey,
            hasGuardianOne: true,
            enablePolling: false,
            loadTimeline: (_) async => timelineCalls++ == 0
                ? const ZyraSourceResult.unavailable(
                    ZyraSourceFailure.requestFailed,
                  )
                : const ZyraSourceResult.available(<ZyraMilestone>[]),
            loadMessages: (_) async {
              messageCalls++;
              return const ZyraSourceResult.unavailable(
                ZyraSourceFailure.requestFailed,
              );
            },
            loadFamilyReview: (_) async {
              reviewCalls++;
              return const ZyraSourceResult.unavailable(
                ZyraSourceFailure.requestFailed,
              );
            },
            loadReviewDecision: noDecision,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('wali-review-unavailable')),
        250,
      );
      expect(find.text('Family Review could not refresh.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('wali-timeline-unavailable')),
        300,
      );
      expect(find.text('Nothing recorded here yet.'), findsNothing);
      final timelineError = find.byKey(
        const ValueKey('wali-timeline-unavailable'),
      );
      await tester.tap(
        find.descendant(of: timelineError, matching: find.text('Try again')),
      );
      await tester.pumpAndSettle();
      expect(timelineCalls, 2);
      expect(
        messageCalls,
        1,
        reason: 'Timeline retry must not reload Conversation',
      );
      expect(
        reviewCalls,
        1,
        reason: 'Timeline retry must not reload review truth',
      );
      expect(
        find.byKey(const ValueKey('wali-timeline-unavailable')),
        findsNothing,
      );
      expect(find.text('Nothing recorded here yet.'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('wali-conversation-unavailable')),
        300,
      );
      expect(find.text('No messages yet.'), findsNothing);
    },
  );

  testWidgets('failed poll retains rows only with last-confirmed labels', (
    tester,
  ) async {
    var timelineCalls = 0;
    var messageCalls = 0;
    final milestone = ZyraMilestone(
      type: 'meeting',
      occurredAt: DateTime.utc(2026, 8, 20),
    );
    final message = ZyraChatMessage(
      id: 'message-1',
      text: 'Last confirmed message',
      fromMe: false,
      createdAt: DateTime.utc(2026, 8, 20),
    );
    await tester.pumpWidget(
      app(
        WaliJourneyDetailScreen(
          journey: journey,
          hasGuardianOne: true,
          loadTimeline: (_) async => timelineCalls++ == 0
              ? ZyraSourceResult.available([milestone])
              : const ZyraSourceResult.unavailable(
                  ZyraSourceFailure.requestFailed,
                ),
          loadMessages: (_) async => messageCalls++ == 0
              ? ZyraSourceResult.available([message])
              : const ZyraSourceResult.unavailable(
                  ZyraSourceFailure.requestFailed,
                ),
          loadFamilyReview: noReview,
          loadReviewDecision: noDecision,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('wali-timeline-unavailable')),
      300,
    );
    expect(
      find.text('Timeline could not refresh. Showing last confirmed Timeline.'),
      findsOneWidget,
    );
    expect(find.text('Meeting'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('wali-conversation-unavailable')),
      300,
    );
    expect(
      find.text(
        'Conversation could not refresh. Showing last confirmed messages.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Last confirmed message'), 200);
    expect(find.text('Last confirmed message'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'decision failure hides review actions and retries only decision truth',
    (tester) async {
      var reviewCalls = 0;
      var decisionCalls = 0;
      final review = (
        id: 'review-1',
        status: 'pending',
        toStage: 'phase_2',
        deadlineAt: DateTime.now().add(const Duration(hours: 12)),
      );
      await tester.pumpWidget(
        app(
          WaliJourneyDetailScreen(
            journey: journey,
            hasGuardianOne: true,
            enablePolling: false,
            loadTimeline: (_) async =>
                const ZyraSourceResult.available(<ZyraMilestone>[]),
            loadMessages: (_) async =>
                const ZyraSourceResult.available(<ZyraChatMessage>[]),
            loadFamilyReview: (_) async {
              reviewCalls++;
              return ZyraSourceResult<ZyraFamilyReview?>.available(review);
            },
            loadReviewDecision: (_) async => decisionCalls++ == 0
                ? const ZyraSourceResult.unavailable(
                    ZyraSourceFailure.requestFailed,
                  )
                : const ZyraSourceResult<String?>.available(null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('wali-review-decision-unavailable')),
        250,
      );
      expect(find.widgetWithText(FilledButton, 'Continue'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Pause'), findsNothing);
      final error = find.byKey(
        const ValueKey('wali-review-decision-unavailable'),
      );
      await tester.tap(
        find.descendant(of: error, matching: find.text('Try again')),
      );
      await tester.pumpAndSettle();
      expect(reviewCalls, 1);
      expect(decisionCalls, 2);
      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Pause'), findsOneWidget);
    },
  );

  testWidgets('older message read cannot replace newer successful empty poll', (
    tester,
  ) async {
    final older = Completer<ZyraSourceResult<List<ZyraChatMessage>>>();
    var calls = 0;
    Future<ZyraSourceResult<List<ZyraChatMessage>>> messages(String _) =>
        calls++ == 0
        ? older.future
        : Future.value(const ZyraSourceResult.available(<ZyraChatMessage>[]));
    await raceMount(tester, raceScreen(messages));
    await racePoll(tester);
    expect(calls, 2);
    await tester.scrollUntilVisible(find.text('No messages yet.'), 300);
    older.complete(ZyraSourceResult.available([oldMessage()]));
    await tester.pump();
    await tester.pump();
    expect(find.text('No messages yet.'), findsOneWidget);
    expect(find.text(oldMessage().text), findsNothing);
    expect(
      find.byKey(const ValueKey('wali-conversation-unavailable')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('older message read cannot clear newer unavailable poll truth', (
    tester,
  ) async {
    final older = Completer<ZyraSourceResult<List<ZyraChatMessage>>>();
    var calls = 0;
    Future<ZyraSourceResult<List<ZyraChatMessage>>> messages(String _) =>
        calls++ == 0
        ? older.future
        : Future.value(
            const ZyraSourceResult.unavailable(ZyraSourceFailure.requestFailed),
          );
    await raceMount(tester, raceScreen(messages));
    await racePoll(tester);
    expect(calls, 2);
    final unavailable = find.byKey(
      const ValueKey('wali-conversation-unavailable'),
    );
    await tester.scrollUntilVisible(unavailable, 300);
    older.complete(ZyraSourceResult.available([oldMessage()]));
    await tester.pump();
    await tester.pump();
    expect(unavailable, findsOneWidget);
    expect(find.text('Conversation could not refresh.'), findsOneWidget);
    expect(find.text('No messages yet.'), findsNothing);
    expect(find.text(oldMessage().text), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('same-State paid to Basic invalidates pending message contents', (
    tester,
  ) async {
    final older = Completer<ZyraSourceResult<List<ZyraChatMessage>>>();
    var calls = 0;
    Future<ZyraSourceResult<List<ZyraChatMessage>>> messages(String _) =>
        calls++ == 0
        ? older.future
        : Future.value(const ZyraSourceResult.available(<ZyraChatMessage>[]));
    await raceMount(tester, raceScreen(messages));
    await tester.pumpWidget(app(raceScreen(messages, paid: false)));
    await racePoll(tester);
    expect(calls, 1, reason: 'Basic never starts a Conversation source read');
    older.complete(ZyraSourceResult.available([oldMessage()]));
    await tester.pump();
    await tester.pump();
    expect(find.text('CONVERSATION'), findsNothing);
    expect(find.text(oldMessage().text), findsNothing);
    // Restore paid capability in the same State to expose any stale retained
    // list. Regrant is not permission to resurrect the invalidated old read.
    await tester.pumpWidget(app(raceScreen(messages)));
    await tester.pump();
    await tester.pump();
    expect(find.text(oldMessage().text), findsNothing);
    await tester.scrollUntilVisible(find.text('No messages yet.'), 300);
    expect(find.text('No messages yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final replaceJourney in [true, false]) {
    final boundary = replaceJourney ? 'Journey' : 'message source';
    testWidgets('same-State $boundary replacement rejects old message read', (
      tester,
    ) async {
      final older = Completer<ZyraSourceResult<List<ZyraChatMessage>>>();
      final oldIds = <String>[];
      final newIds = <String>[];
      Future<ZyraSourceResult<List<ZyraChatMessage>>> oldSource(String id) {
        oldIds.add(id);
        return older.future;
      }

      Future<ZyraSourceResult<List<ZyraChatMessage>>> newSource(
        String id,
      ) async {
        newIds.add(id);
        return const ZyraSourceResult.available(<ZyraChatMessage>[]);
      }

      const replacement = WaliJourneyView(
        matchId: 'match-2',
        linkedSeekerId: 'seeker-2',
        linkedSeekerName: 'Sara',
        partner: SeekerProfile(
          id: 'partner-2',
          firstName: 'Yusuf',
          age: 32,
          city: '—',
          photos: [],
          gender: 'male',
        ),
        counterpartGuardianName: null,
        counterpartGuardianSurname: null,
        status: 'active',
        journeyStage: 'phase_1',
      );
      await raceMount(tester, raceScreen(oldSource));
      final nextJourney = replaceJourney ? replacement : journey;
      await tester.pumpWidget(
        app(raceScreen(newSource, currentJourney: nextJourney)),
      );
      await racePoll(tester);
      expect(oldIds, ['match-1']);
      expect(newIds, isNotEmpty);
      expect(newIds.every((id) => id == nextJourney.matchId), isTrue);
      await tester.scrollUntilVisible(find.text('No messages yet.'), 300);
      older.complete(ZyraSourceResult.available([oldMessage()]));
      await tester.pump();
      await tester.pump();
      expect(find.text('No messages yet.'), findsOneWidget);
      expect(find.text(oldMessage().text), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('disposed Guardian detail rejects late message completion', (
    tester,
  ) async {
    final older = Completer<ZyraSourceResult<List<ZyraChatMessage>>>();
    var calls = 0;
    Future<ZyraSourceResult<List<ZyraChatMessage>>> messages(String _) {
      calls++;
      return older.future;
    }

    await raceMount(tester, raceScreen(messages));
    await tester.pumpWidget(const SizedBox.shrink());
    older.complete(ZyraSourceResult.available([oldMessage()]));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(calls, 1, reason: 'Disposed detail cancels its polling timer');
    expect(find.byType(WaliJourneyDetailScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('older Timeline read cannot replace newer confirmed empty poll', (
    tester,
  ) async {
    final older = Completer<ZyraSourceResult<List<ZyraMilestone>>>();
    final disposed = Completer<ZyraSourceResult<List<ZyraMilestone>>>();
    var timelineCalls = 0;
    await raceMount(
      tester,
      WaliJourneyDetailScreen(
        journey: journey,
        hasGuardianOne: true,
        loadTimeline: (_) {
          timelineCalls++;
          if (timelineCalls == 1) return older.future;
          if (timelineCalls == 2) {
            return Future.value(
              const ZyraSourceResult.available(<ZyraMilestone>[]),
            );
          }
          return disposed.future;
        },
        loadMessages: (_) async =>
            const ZyraSourceResult.available(<ZyraChatMessage>[]),
        loadFamilyReview: noReview,
        loadReviewDecision: noDecision,
      ),
    );
    await racePoll(tester);
    expect(timelineCalls, 2);
    await tester.scrollUntilVisible(
      find.text('Nothing recorded here yet.'),
      300,
    );
    final oldRow = ZyraMilestone(
      type: 'meeting',
      occurredAt: DateTime.utc(2026, 10, 10),
    );
    older.complete(ZyraSourceResult.available([oldRow]));
    await tester.pump();
    await tester.pump();
    expect(find.text('Nothing recorded here yet.'), findsOneWidget);
    expect(find.text('Meeting'), findsNothing);
    expect(
      find.byKey(const ValueKey('wali-timeline-unavailable')),
      findsNothing,
    );
    await racePoll(tester);
    expect(timelineCalls, 3);
    await tester.pumpWidget(const SizedBox.shrink());
    disposed.complete(ZyraSourceResult.available([oldRow]));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(timelineCalls, 3, reason: 'Disposed detail must stop polling');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'older Family Review cannot resurrect newer confirmed no review',
    (tester) async {
      final older = Completer<ZyraSourceResult<ZyraFamilyReview?>>();
      final disposed = Completer<ZyraSourceResult<ZyraFamilyReview?>>();
      var reviewCalls = 0;
      final decisionIds = <String>[];
      final oldReview = (
        id: 'synthetic-old-review',
        status: 'pending',
        toStage: 'phase_2',
        deadlineAt: DateTime.now().add(const Duration(hours: 12)),
      );
      await raceMount(
        tester,
        WaliJourneyDetailScreen(
          journey: journey,
          hasGuardianOne: true,
          loadTimeline: (_) async =>
              const ZyraSourceResult.available(<ZyraMilestone>[]),
          loadMessages: (_) async =>
              const ZyraSourceResult.available(<ZyraChatMessage>[]),
          loadFamilyReview: (_) {
            reviewCalls++;
            if (reviewCalls == 1) return older.future;
            if (reviewCalls == 2) {
              return Future.value(
                const ZyraSourceResult<ZyraFamilyReview?>.available(null),
              );
            }
            return disposed.future;
          },
          loadReviewDecision: (id) async {
            decisionIds.add(id);
            return const ZyraSourceResult<String?>.available(null);
          },
        ),
      );
      await racePoll(tester);
      expect(reviewCalls, 2);
      expect(decisionIds, isEmpty);
      older.complete(ZyraSourceResult<ZyraFamilyReview?>.available(oldReview));
      await tester.pump();
      await tester.pump();
      expect(find.text('Family Review Period'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Continue'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Pause'), findsNothing);
      expect(
        decisionIds,
        isEmpty,
        reason: 'Stale review must not start a read',
      );
      expect(
        find.byKey(const ValueKey('wali-review-unavailable')),
        findsNothing,
      );
      await racePoll(tester);
      expect(reviewCalls, 3);
      await tester.pumpWidget(const SizedBox.shrink());
      disposed.complete(
        ZyraSourceResult<ZyraFamilyReview?>.available(oldReview),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(reviewCalls, 3);
      expect(
        decisionIds,
        isEmpty,
        reason: 'Disposed review must not start a read',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('old review decision cannot become the newer review decision', (
    tester,
  ) async {
    final older = Completer<ZyraSourceResult<String?>>();
    final disposed = Completer<ZyraSourceResult<String?>>();
    var reviewCalls = 0;
    final decisionIds = <String>[];
    final deadline = DateTime.now().add(const Duration(hours: 12));
    final reviewA = (
      id: 'synthetic-review-a',
      status: 'pending',
      toStage: 'phase_2',
      deadlineAt: deadline,
    );
    final reviewB = (
      id: 'synthetic-review-b',
      status: 'pending',
      toStage: 'phase_2',
      deadlineAt: deadline,
    );
    const currentChoice = 'You chose Continue — waiting on the review window.';
    await raceMount(
      tester,
      WaliJourneyDetailScreen(
        journey: journey,
        hasGuardianOne: true,
        loadTimeline: (_) async =>
            const ZyraSourceResult.available(<ZyraMilestone>[]),
        loadMessages: (_) async =>
            const ZyraSourceResult.available(<ZyraChatMessage>[]),
        loadFamilyReview: (_) async =>
            ZyraSourceResult<ZyraFamilyReview?>.available(
              reviewCalls++ == 0 ? reviewA : reviewB,
            ),
        loadReviewDecision: (id) {
          decisionIds.add(id);
          if (id == reviewA.id) return older.future;
          if (decisionIds.length == 2) {
            return Future.value(
              const ZyraSourceResult<String?>.available('continue'),
            );
          }
          return disposed.future;
        },
      ),
    );
    expect(decisionIds, [reviewA.id]);
    await racePoll(tester);
    expect(decisionIds, [reviewA.id, reviewB.id]);
    await tester.scrollUntilVisible(find.text(currentChoice), 250);
    older.complete(const ZyraSourceResult<String?>.available('pause'));
    await tester.pump();
    await tester.pump();
    expect(find.text(currentChoice), findsOneWidget);
    expect(find.text('You chose Pause.'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Pause'), findsNothing);
    await racePoll(tester);
    expect(decisionIds, [reviewA.id, reviewB.id, reviewB.id]);
    await tester.pumpWidget(const SizedBox.shrink());
    disposed.complete(const ZyraSourceResult<String?>.available('pause'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(reviewCalls, 3);
    expect(decisionIds, [reviewA.id, reviewB.id, reviewB.id]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('omitted Guardian One capability defaults to no conversation', (
    tester,
  ) async {
    var messageCalls = 0;
    await raceMount(
      tester,
      WaliJourneyDetailScreen(
        journey: journey,
        enablePolling: false,
        loadTimeline: (_) async =>
            const ZyraSourceResult.available(<ZyraMilestone>[]),
        loadMessages: (_) async {
          messageCalls++;
          return const ZyraSourceResult.available(<ZyraChatMessage>[]);
        },
        loadFamilyReview: noReview,
        loadReviewDecision: noDecision,
      ),
    );
    expect(find.text('Maryam\'s Journey with Adam'), findsOneWidget);
    expect(find.text('CONVERSATION'), findsNothing);
    expect(find.text('No messages yet.'), findsNothing);
    expect(messageCalls, 0, reason: 'No resolved paid capability was supplied');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mock branch invokes none of the injected source loaders', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    addTearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));
    var calls = 0;
    const mockJourney = WaliJourneyView(
      matchId: 'dev-wj0',
      linkedSeekerId: 'dev-seeker',
      linkedSeekerName: 'Maryam',
      partner: SeekerProfile(
        id: 'dev-partner',
        firstName: 'Adam',
        age: 31,
        city: '—',
        photos: [],
        gender: 'male',
      ),
      counterpartGuardianName: null,
      counterpartGuardianSurname: null,
      status: 'active',
      journeyStage: 'phase_1',
      isMock: true,
    );
    Future<ZyraSourceResult<List<ZyraMilestone>>> timeline(String _) async {
      calls++;
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }

    Future<ZyraSourceResult<List<ZyraChatMessage>>> messages(String _) async {
      calls++;
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }

    Future<ZyraSourceResult<ZyraFamilyReview?>> review(String _) async {
      calls++;
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }

    Future<ZyraSourceResult<String?>> decision(String _) async {
      calls++;
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }

    await tester.pumpWidget(
      app(
        WaliJourneyDetailScreen(
          journey: mockJourney,
          hasGuardianOne: true,
          enablePolling: false,
          loadTimeline: timeline,
          loadMessages: messages,
          loadFamilyReview: review,
          loadReviewDecision: decision,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.scrollUntilVisible(find.text('Match'), 300);
    expect(find.text('Match'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('No messages yet.'), 300);
    expect(find.text('No messages yet.'), findsOneWidget);
  });
}
