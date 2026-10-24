import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/wali/wali_seeker_workspace_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_guardian_seeker_roster_resolver.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_wali_journey_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';

void main() {
  testWidgets('Additional workspace receives authorised Journey context', (
    tester,
  ) async {
    var reads = 0;
    await tester.pumpWidget(
      _app(
        WaliSeekerWorkspaceScreen(
          entry: _entry(isMain: false),
          loadSummaries: (_) async {
            reads++;
            return ZyraSourceResult.available([_summary('forbidden')]);
          },
          onOpenNetwork: () {},
        ),
      ),
    );
    await tester.pump();

    expect(reads, 1);
    expect(find.textContaining('Additional Guardian'), findsWidgets);
    expect(find.text('JOURNEY SUMMARY'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('guardian-attempt-summary-forbidden')),
      findsOneWidget,
    );
    expect(find.text('CURRENT CONTEXT'), findsOneWidget);
    expect(find.text('No current Journey'), findsOneWidget);
    expect(find.textContaining('Open current Journey'), findsNothing);
  });

  testWidgets('Main summary preserves server row order and nullable end date', (
    tester,
  ) async {
    final entry = _entry(isMain: true);
    final ended = GuardianAttemptSummary(
      attemptId: 'attempt-ended',
      startedAt: DateTime(2026, 2, 3),
      endedAt: null,
      ended: true,
    );
    final current = GuardianAttemptSummary(
      attemptId: 'attempt-current',
      startedAt: DateTime(2026, 8, 4),
      endedAt: null,
      ended: false,
    );
    var opened = 0;
    await tester.pumpWidget(
      _app(
        GuardianSeekerWorkspaceView(
          entry: entry,
          summaries: [ended, current],
          onRetrySummary: () {},
          onOpenJourney: (_) => opened++,
        ),
      ),
    );

    expect(find.text('End date not recorded'), findsOneWidget);
    expect(find.text('Not ended'), findsOneWidget);
    expect(find.text('attempt-ended'), findsNothing);
    expect(find.text('attempt-current'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Ended Journey')).dy,
      lessThan(tester.getTopLeft(find.text('Current Journey').last).dy),
    );

    final endedCard = find.byKey(
      const ValueKey('guardian-attempt-summary-attempt-ended'),
    );
    final currentCard = find.byKey(
      const ValueKey('guardian-attempt-summary-attempt-current'),
    );
    await tester.ensureVisible(endedCard);
    await tester.tap(endedCard);
    expect(opened, 0);
    await tester.ensureVisible(currentCard);
    await tester.drag(
      find.byKey(const PageStorageKey('guardian-seeker-workspace')),
      const Offset(0, -80),
    );
    await tester.pump();
    await tester.tap(currentCard);
    expect(opened, 1);
  });

  testWidgets('successful empty differs from unavailable', (tester) async {
    final entry = _entry(isMain: true);
    await tester.pumpWidget(
      _app(
        WaliSeekerWorkspaceScreen(
          entry: entry,
          loadSummaries: (_) async =>
              const ZyraSourceResult.available(<GuardianAttemptSummary>[]),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No Journey summaries are available.'), findsOneWidget);
    expect(
      find.text('Journey summaries are unavailable right now.'),
      findsNothing,
    );

    await tester.pumpWidget(
      _app(
        WaliSeekerWorkspaceScreen(
          key: const ValueKey('unavailable'),
          entry: entry,
          loadSummaries: (_) async => const ZyraSourceResult.unavailable(
            ZyraSourceFailure.requestFailed,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text('Journey summaries are unavailable right now.'),
      findsOneWidget,
    );
    expect(find.text('No Journey summaries are available.'), findsNothing);
  });

  testWidgets('last-known rows stay visible and are labelled', (tester) async {
    await tester.pumpWidget(
      _app(
        GuardianSeekerWorkspaceView(
          entry: _entry(isMain: true),
          summaries: [_summary('last-known')],
          summaryUnavailable: true,
          summaryLastKnown: true,
          onRetrySummary: () {},
        ),
      ),
    );

    expect(
      find.text(
        'Journey summaries could not refresh. Showing last confirmed rows.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-attempt-summary-last-known')),
      findsOneWidget,
    );
  });

  testWidgets('embedded Seeker workspace uses the quiet full-page sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        GuardianSeekerWorkspaceView(
          entry: _entry(isMain: true),
          embedded: true,
          summaries: [_summary('embedded-current')],
          onRetrySummary: () {},
          onOpenJourney: (_) {},
          onOpenFamilyChat: () {},
          onOpenNetwork: () {},
          hasGuardianOne: true,
        ),
      ),
    );

    expect(find.text('DETAILS'), findsOneWidget);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    expect(find.text('JOURNEY SUMMARY'), findsOneWidget);
    expect(find.text('GUARDIAN CIRCLE'), findsOneWidget);
    expect(find.text('GUARDIAN NETWORK'), findsOneWidget);
    expect(find.text('ROLE & ACCESS'), findsNothing);
    expect(find.text('CURRENT CONTEXT'), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  group('synthetic workspace read and rendered-action lifetime', () {
    const owner = '00000000-0000-4000-8000-000000000971';
    const replacement = '00000000-0000-4000-8000-000000000972';

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await ZyraLocalPrefs.init();
    });
    setUp(() async {
      ZyraAccountState.resetForTesting();
      ZyraAccountState.clearImagesForTesting = () async {};
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await ZyraAccountState.synchronize(owner);
    });
    tearDown(() {
      ZyraAccountState.resetForTesting();
      ZyraAccountState.clearImagesForTesting = null;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
    });

    void workspaceTest(
      String description,
      Future<void> Function(WidgetTester) body,
    ) {
      testWidgets(description, (tester) async {
        try {
          await body(tester);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          // Move the preference queue tail out of this test's FakeAsync zone
          // before it is discarded, including when an assertion fails.
          await tester.runAsync(() async {
            unawaited(ZyraLocalPrefs.bindAccount(null));
          });
          var drained = false;
          ZyraLocalPrefs.bindAccount(null).then((_) => drained = true);
          for (var frame = 0; frame < 20 && !drained; frame++) {
            await tester.pump();
            await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          }
          expect(
            drained,
            isTrue,
            reason: 'Synthetic preference cleanup leaves its test zone',
          );
        }
      });
    }

    GuardianSeekerWorkspaceView view(WidgetTester tester) =>
        tester.widget<GuardianSeekerWorkspaceView>(
          find.byType(GuardianSeekerWorkspaceView),
        );

    Widget subject({
      required GuardianAttemptSummaryLoader loader,
      bool isMain = true,
      bool paid = true,
      DateTime? linkedAt,
      ValueChanged<WaliJourneyView>? onJourney,
      VoidCallback? onNetwork,
      VoidCallback? onFamily,
    }) => _app(
      WaliSeekerWorkspaceScreen(
        key: const ValueKey('same-workspace-state'),
        entry: _stableEntry(isMain: isMain, linkedAt: linkedAt),
        hasGuardianOne: paid,
        loadSummaries: loader,
        onOpenJourney: onJourney,
        onOpenNetwork: onNetwork,
        onOpenFamilyChat: onFamily,
      ),
    );

    Future<VoidCallback> renderedButton(
      WidgetTester tester,
      String label,
    ) async {
      final text = find.text(label);
      await tester.ensureVisible(text);
      await tester.pumpAndSettle();
      final button = find.ancestor(
        of: text,
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        ),
      );
      final callback = tester.widget<ButtonStyleButton>(button).onPressed;
      expect(callback, isNotNull);
      return callback!;
    }

    Future<void> press(WidgetTester tester, String label) async {
      await renderedButton(tester, label);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    workspaceTest('same-person Main change ignores an older summary read', (
      tester,
    ) async {
      final older = Completer<ZyraSourceResult<List<GuardianAttemptSummary>>>();
      final newer = Completer<ZyraSourceResult<List<GuardianAttemptSummary>>>();
      var reads = 0;
      Future<ZyraSourceResult<List<GuardianAttemptSummary>>> loader(String id) {
        expect(id, 'same-seeker');
        return ++reads == 1 ? older.future : newer.future;
      }

      await tester.pumpWidget(subject(loader: loader));
      await tester.pumpWidget(subject(loader: loader, isMain: false));
      expect(reads, 2);
      newer.complete(ZyraSourceResult.available([_summary('new-summary')]));
      await tester.pump();
      expect(view(tester).entry.person.isMain, isFalse);
      expect(view(tester).summaries.single.attemptId, 'new-summary');

      older.complete(ZyraSourceResult.available([_summary('old-summary')]));
      await tester.pump();
      expect(view(tester).summaries.map((row) => row.attemptId), [
        'new-summary',
      ]);
      expect(
        find.byKey(const ValueKey('guardian-attempt-summary-old-summary')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    workspaceTest(
      'same-person source replacement reloads and rejects old rows',
      (tester) async {
        final older =
            Completer<ZyraSourceResult<List<GuardianAttemptSummary>>>();
        var oldReads = 0;
        var newReads = 0;
        Future<ZyraSourceResult<List<GuardianAttemptSummary>>> oldLoader(
          String _,
        ) {
          oldReads++;
          return older.future;
        }

        Future<ZyraSourceResult<List<GuardianAttemptSummary>>> newLoader(
          String _,
        ) async {
          newReads++;
          return ZyraSourceResult.available([_summary('replacement-summary')]);
        }

        await tester.pumpWidget(subject(loader: oldLoader));
        await tester.pumpWidget(subject(loader: newLoader));
        await tester.pump();
        expect(oldReads, 1);
        expect(newReads, 1);
        expect(view(tester).summaries.single.attemptId, 'replacement-summary');
        older.complete(ZyraSourceResult.available([_summary('old-source')]));
        await tester.pump();
        expect(view(tester).summaries.single.attemptId, 'replacement-summary');
        expect(tester.takeException(), isNull);
      },
    );

    workspaceTest('thrown first read ends loading and actual Retry recovers', (
      tester,
    ) async {
      var reads = 0;
      Future<ZyraSourceResult<List<GuardianAttemptSummary>>> loader(
        String _,
      ) async {
        if (++reads == 1) throw StateError('synthetic read failure');
        return const ZyraSourceResult.available(<GuardianAttemptSummary>[]);
      }

      await tester.pumpWidget(subject(loader: loader));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(view(tester).summaryLoading, isFalse);
      expect(view(tester).summaryUnavailable, isTrue);
      expect(
        find.text('Journey summaries are unavailable right now.'),
        findsOneWidget,
      );
      await press(tester, 'Try again');
      expect(reads, 2);
      expect(view(tester).summaryUnavailable, isFalse);
      expect(view(tester).summaries, isEmpty);
      expect(find.text('No Journey summaries are available.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    workspaceTest(
      'current-source thrown refresh retains labelled rows and Retry',
      (tester) async {
        var reads = 0;
        Future<ZyraSourceResult<List<GuardianAttemptSummary>>> loader(
          String _,
        ) async {
          if (++reads == 2) throw StateError('synthetic retry failure');
          return ZyraSourceResult.available([_summary('confirmed-row')]);
        }

        await tester.pumpWidget(subject(loader: loader));
        await tester.pump();
        // Synthetic read control through the public presentation delegate:
        // a successful page has no user-facing Refresh button to tap.
        view(tester).onRetrySummary();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(view(tester).summaryLoading, isFalse);
        expect(view(tester).summaryUnavailable, isTrue);
        expect(view(tester).summaryLastKnown, isTrue);
        expect(view(tester).summaries.single.attemptId, 'confirmed-row');
        expect(
          find.text(
            'Journey summaries could not refresh. Showing last confirmed rows.',
          ),
          findsOneWidget,
        );
        await press(tester, 'Try again');
        expect(reads, 3);
        expect(view(tester).summaryUnavailable, isFalse);
        expect(view(tester).summaryLastKnown, isFalse);
        expect(view(tester).summaries.single.attemptId, 'confirmed-row');
      },
    );

    workspaceTest(
      'replacement source failure does not inherit old confirmed rows',
      (tester) async {
        Future<ZyraSourceResult<List<GuardianAttemptSummary>>> oldLoader(
          String _,
        ) async => ZyraSourceResult.available([_summary('old-confirmed')]);
        Future<ZyraSourceResult<List<GuardianAttemptSummary>>> newLoader(
          String _,
        ) async =>
            const ZyraSourceResult.unavailable(ZyraSourceFailure.requestFailed);

        await tester.pumpWidget(subject(loader: oldLoader));
        await tester.pump();
        expect(view(tester).summaries.single.attemptId, 'old-confirmed');
        await tester.pumpWidget(subject(loader: newLoader));
        await tester.pump();
        expect(view(tester).summaryUnavailable, isTrue);
        expect(view(tester).summaryLastKnown, isFalse);
        expect(view(tester).summaries, isEmpty);
        expect(
          find.byKey(const ValueKey('guardian-attempt-summary-old-confirmed')),
          findsNothing,
        );
      },
    );

    workspaceTest('link-epoch replacement reloads the same person', (
      tester,
    ) async {
      var reads = 0;
      Future<ZyraSourceResult<List<GuardianAttemptSummary>>> loader(
        String _,
      ) async => ZyraSourceResult.available([_summary('link-read-${++reads}')]);

      await tester.pumpWidget(
        subject(loader: loader, linkedAt: DateTime(2026, 1, 2)),
      );
      await tester.pump();
      await tester.pumpWidget(
        subject(loader: loader, linkedAt: DateTime(2026, 2, 3)),
      );
      await tester.pump();
      expect(reads, 2);
      expect(view(tester).summaries.single.attemptId, 'link-read-2');
    });

    workspaceTest(
      'retained buttons cannot act for a replacement person binding',
      (tester) async {
        var reads = 0;
        var journeyOpens = 0;
        var networkOpens = 0;
        var familyOpens = 0;
        Future<ZyraSourceResult<List<GuardianAttemptSummary>>> loader(
          String _,
        ) async {
          reads++;
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.requestFailed,
          );
        }

        void journey(WaliJourneyView _) => journeyOpens++;
        void network() => networkOpens++;
        void family() => familyOpens++;

        await tester.pumpWidget(
          subject(
            loader: loader,
            onJourney: journey,
            onNetwork: network,
            onFamily: family,
          ),
        );
        await tester.pump();
        final retry = await renderedButton(tester, 'Try again');
        final openJourney = await renderedButton(
          tester,
          'Open current Journey',
        );
        final openNetwork = await renderedButton(tester, 'Open for Maryam');
        final openFamily = await renderedButton(
          tester,
          'Enter Maryam’s Guardian Circle',
        );
        await press(tester, 'Open current Journey');
        await press(tester, 'Open for Maryam');
        await press(tester, 'Enter Maryam’s Guardian Circle');
        expect([journeyOpens, networkOpens, familyOpens], [1, 1, 1]);

        await tester.pumpWidget(
          subject(
            loader: loader,
            isMain: false,
            onJourney: journey,
            onNetwork: network,
            onFamily: family,
          ),
        );
        await tester.pump();
        expect(reads, 2);
        retry();
        openJourney();
        openNetwork();
        openFamily();
        await tester.pump();
        expect(reads, 2);
        expect([journeyOpens, networkOpens, familyOpens], [1, 1, 1]);
        expect(tester.takeException(), isNull);
      },
    );

    for (final change in ['replacement', 'same-owner epoch', 'sign-out']) {
      workspaceTest(
        '$change withdraws rows and denies retained rendered actions',
        (tester) async {
          var reads = 0;
          var opened = 0;
          final pending =
              Completer<ZyraSourceResult<List<GuardianAttemptSummary>>>();
          Future<ZyraSourceResult<List<GuardianAttemptSummary>>> loader(
            String _,
          ) {
            reads++;
            return reads == 1
                ? Future.value(
                    ZyraSourceResult.available([_summary('private-row')]),
                  )
                : pending.future;
          }

          await tester.pumpWidget(
            subject(
              loader: loader,
              onJourney: (_) => opened++,
              onNetwork: () => opened++,
              onFamily: () => opened++,
            ),
          );
          await tester.pump();
          expect(view(tester).summaries.single.attemptId, 'private-row');
          final openJourney = await renderedButton(
            tester,
            'Open current Journey',
          );
          final openNetwork = await renderedButton(tester, 'Open for Maryam');
          final openFamily = await renderedButton(
            tester,
            'Enter Maryam’s Guardian Circle',
          );
          final retry = view(tester).onRetrySummary;
          retry();
          await tester.pump();
          expect(reads, 2);

          if (change == 'replacement') {
            await tester.runAsync(
              () => ZyraAccountState.synchronize(replacement),
            );
          } else if (change == 'same-owner epoch') {
            await tester.runAsync(() async {
              await ZyraAccountState.synchronize(null);
              await ZyraAccountState.synchronize(owner);
            });
          } else {
            await tester.runAsync(ZyraAccountState.beginSignOut);
          }
          await tester.pump();
          expect(
            find.byKey(const ValueKey('guardian-attempt-summary-private-row')),
            findsNothing,
          );
          retry();
          openJourney();
          openNetwork();
          openFamily();
          pending.complete(
            ZyraSourceResult.available([_summary('late-private-row')]),
          );
          await tester.pump();
          expect(reads, 2);
          expect(opened, 0);
          expect(find.byType(GuardianSeekerWorkspaceView), findsNothing);
          expect(find.text('Open current Journey'), findsNothing);
          expect(
            find.byKey(
              const ValueKey('guardian-attempt-summary-late-private-row'),
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    workspaceTest(
      'disposed workspace ignores late rows and retained controls',
      (tester) async {
        var reads = 0;
        var opens = 0;
        final pending =
            Completer<ZyraSourceResult<List<GuardianAttemptSummary>>>();
        Future<ZyraSourceResult<List<GuardianAttemptSummary>>> loader(
          String _,
        ) {
          reads++;
          return pending.future;
        }

        await tester.pumpWidget(
          subject(
            loader: loader,
            onJourney: (_) => opens++,
            onNetwork: () => opens++,
            onFamily: () => opens++,
          ),
        );
        // Do not pumpAndSettle with the intentional loading spinner pending.
        final oldView = view(tester);
        final retry = oldView.onRetrySummary;
        final openJourney = oldView.onOpenJourney!;
        final openNetwork = oldView.onOpenNetwork!;
        final openFamily = oldView.onOpenFamilyChat!;
        final journey = oldView.entry.currentJourney!;
        await tester.pumpWidget(
          _app(const Text('Unaffected replacement route')),
        );
        retry();
        openJourney(journey);
        openNetwork();
        openFamily();
        pending.complete(
          ZyraSourceResult.available([_summary('disposed-private')]),
        );
        await tester.pump();
        expect(reads, 1);
        expect(opens, 0);
        expect(find.text('Unaffected replacement route'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  test('summary parser keeps three-state dates and rejects malformed rows', () {
    final parsed = GuardianAttemptSummary.fromRow({
      'attempt_id': 'a-1',
      'started_at': null,
      'ended_at': null,
      'ended': true,
    });
    expect(parsed, isNotNull);
    expect(parsed!.startedAt, isNull);
    expect(parsed.endedAt, isNull);
    expect(parsed.ended, isTrue);

    expect(
      GuardianAttemptSummary.fromRow({
        'attempt_id': 'a-2',
        'started_at': 'not-a-date',
        'ended_at': null,
        'ended': false,
      }),
      isNull,
    );
    expect(
      GuardianAttemptSummary.fromRow({
        'attempt_id': 'a-3',
        'started_at': null,
        'ended_at': null,
        'ended': 'false',
      }),
      isNull,
    );
  });
}

Widget _app(Widget child) => MaterialApp(home: child);

GuardianSeekerRosterEntry _entry({required bool isMain}) {
  final person = WaliLinkedPerson(
    id: isMain ? 'main-seeker' : 'additional-seeker',
    firstName: isMain ? 'Maryam' : 'Aaliyah',
    isMain: isMain,
    relationship: 'father',
    linkedAt: DateTime(2026, 1, 2),
  );
  final journey = isMain
      ? WaliJourneyView(
          attemptId: 'attempt-current',
          matchId: 'match-current',
          linkedSeekerId: person.id,
          linkedSeekerName: person.firstName,
          partner: const SeekerProfile(
            id: 'partner',
            firstName: 'Idris',
            age: 30,
            city: '—',
            photos: [],
            gender: '',
          ),
          counterpartGuardianName: null,
          counterpartGuardianSurname: null,
          status: 'active',
          journeyStage: 'phase_1',
        )
      : null;
  return GuardianSeekerRosterEntry(
    person: person,
    currentJourney: journey,
    group: isMain ? GuardianSeekerRosterGroup.inAJourney : null,
    needsAttention: false,
    waitingSince: null,
    contextLine: isMain
        ? 'Journey with Idris · Faith & Values'
        : 'Additional Guardian',
  );
}

GuardianAttemptSummary _summary(String id) => GuardianAttemptSummary(
  attemptId: id,
  startedAt: DateTime(2026, 8, 1),
  endedAt: null,
  ended: false,
);

GuardianSeekerRosterEntry _stableEntry({
  required bool isMain,
  DateTime? linkedAt,
}) {
  final person = WaliLinkedPerson(
    id: 'same-seeker',
    firstName: 'Maryam',
    isMain: isMain,
    relationship: 'father',
    linkedAt: linkedAt ?? DateTime(2026, 1, 2),
  );
  return GuardianSeekerRosterEntry(
    person: person,
    currentJourney: isMain
        ? WaliJourneyView(
            attemptId: 'same-attempt',
            matchId: 'same-match',
            linkedSeekerId: person.id,
            linkedSeekerName: person.firstName,
            partner: const SeekerProfile(
              id: 'same-partner',
              firstName: 'Idris',
              age: 30,
              city: '—',
              photos: [],
              gender: '',
            ),
            counterpartGuardianName: null,
            counterpartGuardianSurname: null,
            status: 'active',
            journeyStage: 'phase_1',
          )
        : null,
    group: isMain ? GuardianSeekerRosterGroup.inAJourney : null,
    needsAttention: false,
    waitingSince: null,
    contextLine: isMain
        ? 'Journey with Idris · Faith & Values'
        : 'Additional Guardian',
  );
}
