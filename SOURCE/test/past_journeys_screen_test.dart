import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/profile/past_journeys_screen.dart';
import 'package:zyra/screens/matches/journey_timeline_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _pausedProfile = SeekerProfile(
  id: 'paused-person',
  firstName: 'Maryam',
  age: 29,
  city: 'Birmingham',
  photos: [],
  gender: 'female',
);

const _endedProfile = SeekerProfile(
  id: 'ended-person',
  firstName: 'Hassan',
  age: 31,
  city: 'London',
  photos: [],
  gender: 'male',
);

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    AppState.instance.resetForAccountChange();
  });

  tearDown(() {
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAccountState.resetForTesting();
  });

  test(
    'Connections keeps live Journey sections separate from Profile history',
    () {
      final connections = File(
        'lib/screens/connections/connections_screen.dart',
      ).readAsStringSync();
      expect(connections, contains("title: 'Active Journey'"));
      expect(connections, contains("title: 'Potential Journeys'"));
      expect(connections, contains("title: 'Paused Journeys'"));
      expect(connections, contains("title: 'Ended Journeys'"));
      expect(
        connections,
        contains("_ConnectionsSubsectionLabel('REQUESTS FOR YOU')"),
      );
      expect(connections, isNot(contains("title: 'Journey History'")));
    },
  );

  testWidgets('Profile archive separates Paused and Ended Journeys', (
    tester,
  ) async {
    const paused = JourneyMatch(
      matchId: 'paused-match',
      profile: _pausedProfile,
      status: 'active',
      pause: ZyraJourneyPauseState(phase: ZyraPausePhase.paused),
    );
    final ended = JourneyMatch(
      matchId: 'ended-match',
      profile: _endedProfile,
      status: 'ended',
      endedAt: DateTime(2026, 7, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PastJourneysScreen(
          previewPaused: const [paused],
          previewEnded: [ended],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('past-journeys-toggle')), findsOneWidget);
    expect(find.text('Maryam, 29').hitTestable(), findsOneWidget);
    expect(find.text('Hassan, 31').hitTestable(), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('past-journeys-toggle'))).dy,
      lessThan(tester.getTopLeft(find.text('Maryam, 29')).dy),
      reason:
          'The shared page selector belongs beneath the title, not at the bottom.',
    );

    await tester.drag(
      find.byKey(const ValueKey('past-journeys-pages')),
      const Offset(-650, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maryam, 29').hitTestable(), findsNothing);
    expect(find.text('Hassan, 31').hitTestable(), findsOneWidget);
    expect(find.text('Ended Journey').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty archive uses calm section-specific copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PastJourneysScreen(previewPaused: [], previewEnded: []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Paused Journeys yet'), findsOneWidget);
    expect(
      find.text(
        'Journeys placed on hold will appear here until they continue or end.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('could not be refreshed'), findsNothing);

    await tester.tap(find.text('Ended'));
    await tester.pumpAndSettle();
    expect(find.text('No Ended Journeys yet'), findsOneWidget);
    expect(
      find.text(
        'Journeys brought to a close will appear here, with their history kept.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'ordinary archive withdraws already loaded owner history',
    (tester) async {
      await _bindHistoryOwner(tester, 'history-owner-a');
      await tester.pumpWidget(
        MaterialApp(
          home: PastJourneysScreen(
            loader: ({required statuses}) async => statuses.single == 'active'
                ? [_pausedJourney]
                : [_endedJourney],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Maryam, 29').hitTestable(), findsOneWidget);
      final open = tester
          .widget<InkWell>(find.widgetWithText(InkWell, 'Maryam, 29'))
          .onTap!;

      await _bindHistoryOwner(tester, 'history-owner-b');
      open();
      await tester.pumpAndSettle();
      expect(find.byType(JourneyTimelineScreen), findsNothing);
      expect(find.text('Maryam, 29', skipOffstage: false), findsNothing);
      expect(find.text('Hassan, 31', skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'account replacement stops the second archive request',
    (tester) async {
      await _bindHistoryOwner(tester, 'history-owner-a');
      final first = Completer<List<JourneyMatch>?>();
      final calls = <List<String>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: PastJourneysScreen(
            loader: ({required statuses}) {
              calls.add(List.of(statuses));
              return statuses.single == 'active'
                  ? first.future
                  : Future.value([_endedJourney]);
            },
          ),
        ),
      );
      await tester.pump();
      expect(calls, [
        <String>['active'],
      ]);

      await _bindHistoryOwner(tester, 'history-owner-b');
      first.complete([_pausedJourney]);
      await tester.pumpAndSettle();
      expect(calls, [
        <String>['active'],
      ]);
      expect(find.text('Maryam, 29', skipOffstage: false), findsNothing);
      expect(find.text('Hassan, 31', skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'owner A B A cannot revive a pending archive load',
    (tester) async {
      await _bindHistoryOwner(tester, 'history-owner-a');
      final first = Completer<List<JourneyMatch>?>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PastJourneysScreen(
            loader: ({required statuses}) {
              calls++;
              return statuses.single == 'active'
                  ? first.future
                  : Future.value([_endedJourney]);
            },
          ),
        ),
      );
      await tester.pump();
      await _bindHistoryOwner(tester, 'history-owner-b');
      await _bindHistoryOwner(tester, 'history-owner-a');
      first.complete([_pausedJourney]);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Maryam, 29', skipOffstage: false), findsNothing);
      expect(find.text('Hassan, 31', skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'replacement during second archive read cannot publish mixed rows',
    (tester) async {
      await _bindHistoryOwner(tester, 'history-owner-a');
      final second = Completer<List<JourneyMatch>?>();
      final calls = <List<String>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: PastJourneysScreen(
            loader: ({required statuses}) {
              calls.add(List.of(statuses));
              return statuses.single == 'active'
                  ? Future.value([_pausedJourney])
                  : second.future;
            },
          ),
        ),
      );
      await tester.pump();
      expect(calls, [
        <String>['active'],
        <String>['ended'],
      ]);
      await _bindHistoryOwner(tester, 'history-owner-b');
      second.complete([_endedJourney]);
      await tester.pumpAndSettle();
      expect(find.text('Maryam, 29', skipOffstage: false), findsNothing);
      expect(find.text('Hassan, 31', skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'same-owner archive loader failure remains retryable',
    (tester) async {
      await _bindHistoryOwner(tester, 'history-owner-a');
      var fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: PastJourneysScreen(
            loader: ({required statuses}) async {
              if (fail) throw StateError('Synthetic history read failed');
              return statuses.single == 'active'
                  ? [_pausedJourney]
                  : [_endedJourney];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text("We couldn't load this just now").hitTestable(),
        findsOneWidget,
      );
      fail = false;
      await tester.tap(find.text('Try again').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Maryam, 29').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );
}

Future<void> _bindHistoryOwner(WidgetTester tester, String owner) async {
  await tester.runAsync(() => ZyraAccountState.synchronize(owner));
}

const _pausedJourney = JourneyMatch(
  matchId: 'paused-match',
  profile: _pausedProfile,
  status: 'active',
  pause: ZyraJourneyPauseState(phase: ZyraPausePhase.paused),
);

final _endedJourney = JourneyMatch(
  matchId: 'ended-match',
  profile: _endedProfile,
  status: 'ended',
  endedAt: DateTime(2026, 7, 1),
);
