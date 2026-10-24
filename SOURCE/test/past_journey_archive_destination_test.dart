// OA151/299/304/305/307: a pair-only archive row must never resolve a
// different/current attempt. Lists and approved mock previews remain usable.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/matches/journey_timeline_screen.dart';
import 'package:zyra/screens/profile/past_journeys_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_text.dart';

const _a = '00000000-0000-4000-8000-000000006301';
const _b = '00000000-0000-4000-8000-000000006302';
const _person = SeekerProfile(
  id: 'local-archived-person',
  firstName: 'Maryam',
  age: 29,
  city: 'Leeds',
  gender: 'female',
  photos: [],
);
const _paused = JourneyMatch(
  matchId: 'selected-archive-pair',
  profile: _person,
  status: 'active',
  journeyStage: 'phase_1',
  pause: ZyraJourneyPauseState(phase: ZyraPausePhase.paused),
);
final _ended = JourneyMatch(
  matchId: 'selected-ended-pair',
  profile: _person,
  status: 'ended',
  endedAt: DateTime(2026, 10, 1),
);

Map<String, dynamic> _sessionJson(String id) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': id, 'session_id': 'archive-local-session', 'exp': 4102444800})}.synthetic',
    'token_type': 'bearer',
    'refresh_token': 'synthetic-refresh',
    'user': {
      'id': id,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-18T00:00:00Z',
    },
  };
}

void _emit(String id) {
  // A queued payload must deny even while the SDK getter is already A.
  // ignore: invalid_use_of_internal_member
  Supabase.instance.client.auth.notifyAllSubscribers(
    AuthChangeEvent.tokenRefreshed,
    session: Session.fromJson(_sessionJson(id))!,
    broadcast: false,
  );
}

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var transport = 0;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        transport++;
        throw StateError(
          'The archive status must not resolve any Timeline, context, answer or write.',
        );
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await Supabase.instance.client.auth.setInitialSession(
      jsonEncode(_sessionJson(_a)),
    );
    await ZyraAccountState.synchronize(_a);
    transport = 0;
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.clearImagesForTesting = null;
  });

  void archiveTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
        expect(transport, 0);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush(tester);
        await tester.runAsync(() => ZyraAccountState.synchronize(null));
        await _flush(tester);
      }
    }, timeout: const Timeout(Duration(seconds: 25)));
  }

  Future<GlobalKey<NavigatorState>> mount(
    WidgetTester tester, {
    bool mock = false,
    bool compact = false,
  }) async {
    final navigator = GlobalKey<NavigatorState>();
    if (compact) {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(compact ? 2 : 1)),
          child: child!,
        ),
        home: PastJourneysScreen(
          loader: ({required statuses}) async => statuses.single == 'active'
              ? [
                  mock
                      ? const JourneyMatch(
                          matchId: 'approved-mock-archive',
                          profile: _person,
                          status: 'active',
                          isMock: true,
                          pause: ZyraJourneyPauseState(
                            phase: ZyraPausePhase.paused,
                          ),
                        )
                      : _paused,
                ]
              : [_ended],
        ),
      ),
    );
    await _flush(tester);
    await tester.pumpAndSettle();
    return navigator;
  }

  Finder card(String id) => find.byKey(ValueKey('past-journey-card-$id'));
  VoidCallback back(WidgetTester tester) => tester
      .widget<OutlinedButton>(
        find.byKey(const ValueKey('past-journey-archive-back')),
      )
      .onPressed!;

  for (final ended in [false, true]) {
    archiveTest(
      '${ended ? 'Ended' : 'Paused'} real archive opens truthful status and Back, never counterpart Timeline',
      (tester) async {
        await mount(tester);
        if (ended) {
          await tester.tap(find.text('Ended'));
          await tester.pumpAndSettle();
        }
        await tester.tap(card(ended ? _ended.matchId : _paused.matchId));
        await tester.pumpAndSettle();
        expect(
          find.byType(PastJourneyArchiveUnavailableScreen),
          findsOneWidget,
        );
        expect(find.text('History with Maryam'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('History with Maryam')).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AppBar)).dy),
          reason: 'The body heading must start below the transparent toolbar.',
        );
        expect(
          find.textContaining(
            'A different or current Journey has not been opened instead.',
          ),
          findsOneWidget,
        );
        expect(find.byType(JourneyTimelineScreen), findsNothing);
        expect(find.text('Try again'), findsNothing);
        expect(find.text('Record a milestone'), findsNothing);
        expect(find.text('End Journey'), findsNothing);
        expect(find.textContaining('OA-'), findsNothing);
        expect(find.textContaining('Founder'), findsNothing);
        await tester.tap(
          find.byKey(const ValueKey('past-journey-archive-back')),
        );
        await tester.pumpAndSettle();
        expect(
          card(ended ? _ended.matchId : _paused.matchId).hitTestable(),
          findsOneWidget,
        );
      },
    );
  }

  archiveTest(
    'approved mock archive keeps its explicit no-network mock Timeline',
    (tester) async {
      await mount(tester, mock: true);
      await tester.tap(card('approved-mock-archive'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<JourneyTimelineScreen>(find.byType(JourneyTimelineScreen))
            .isMock,
        isTrue,
      );
      expect(find.byType(PastJourneyArchiveUnavailableScreen), findsNothing);
      expect(find.text('Record a milestone'), findsNothing);
    },
  );

  archiveTest('retained archive card cannot open after route cover-return', (
    tester,
  ) async {
    final navigator = await mount(tester);
    final saved = tester.widget<InkWell>(card(_paused.matchId)).onTap!;
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Cover')),
      ),
    );
    await tester.pumpAndSettle();
    saved();
    await tester.pump();
    expect(find.byType(PastJourneyArchiveUnavailableScreen), findsNothing);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    saved();
    await tester.pump();
    expect(find.byType(PastJourneyArchiveUnavailableScreen), findsNothing);
    await tester.tap(card(_paused.matchId));
    await tester.pumpAndSettle();
    expect(find.byType(PastJourneyArchiveUnavailableScreen), findsOneWidget);
  });

  archiveTest(
    'queued SDK ABA invalidates retained archive card without account-generation publication',
    (tester) async {
      await mount(tester);
      final saved = tester.widget<InkWell>(card(_paused.matchId)).onTap!;
      final generation = ZyraAccountState.generation;
      _emit(_b);
      _emit(_a);
      await _flush(tester);
      expect(ZyraAccountState.generation, generation);
      expect(Supabase.instance.client.auth.currentUser?.id, _a);
      saved();
      await _flush(tester);
      expect(find.byType(PastJourneyArchiveUnavailableScreen), findsNothing);
      expect(find.text('Maryam, 29', skipOffstage: false), findsNothing);
    },
  );

  archiveTest(
    'archive status retained Back cannot pop a cover or a later route visit',
    (tester) async {
      final navigator = await mount(tester);
      await tester.tap(card(_paused.matchId));
      await tester.pumpAndSettle();
      final saved = back(tester);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover')),
        ),
      );
      await tester.pumpAndSettle();
      saved();
      await tester.pump();
      expect(find.text('Cover'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      saved();
      await tester.pump();
      expect(find.byType(PastJourneyArchiveUnavailableScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('past-journey-archive-back')));
      await tester.pumpAndSettle();
      expect(card(_paused.matchId).hitTestable(), findsOneWidget);
    },
  );

  archiveTest(
    'covered archive status withdraws its owner without popping unrelated cover',
    (tester) async {
      final navigator = await mount(tester);
      await tester.tap(card(_paused.matchId));
      await tester.pumpAndSettle();
      final saved = back(tester);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover')),
        ),
      );
      await tester.pumpAndSettle();
      _emit(_b);
      _emit(_a);
      await _flush(tester);
      saved();
      await tester.pumpAndSettle();
      expect(find.text('Cover'), findsOneWidget);
      expect(
        find.text('History with Maryam', skipOffstage: false),
        findsNothing,
      );
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(JourneyTimelineScreen), findsNothing);
      expect(find.byType(PastJourneyArchiveUnavailableScreen), findsNothing);
    },
  );

  archiveTest('disposed archive status and card callbacks stay inert', (
    tester,
  ) async {
    await mount(tester);
    final savedCard = tester.widget<InkWell>(card(_paused.matchId)).onTap!;
    await tester.tap(card(_paused.matchId));
    await tester.pumpAndSettle();
    final savedBack = back(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    savedBack();
    savedCard();
    await _flush(tester);
    expect(find.byType(PastJourneyArchiveUnavailableScreen), findsNothing);
  });

  archiveTest(
    'archive explanation remains scrollable at 320px and 200 percent text',
    (tester) async {
      await mount(tester, compact: true);
      await tester.tap(card(_paused.matchId));
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('past-journey-archive-back'));
      if (action.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          action,
          180,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 20,
        );
      }
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(PastJourneyArchiveUnavailableScreen), findsNothing);
    },
  );

  for (final replacement in ['person', 'caller guard']) {
    archiveTest(
      'same-State archive status refuses $replacement rebind permanently',
      (tester) async {
        const statusKey = ValueKey('same-archive-status-state');
        bool opening() => true;
        bool replacementGuard() => true;
        var name = 'Maryam';
        var guard = opening;
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return PastJourneyArchiveUnavailableScreen(
                  key: statusKey,
                  firstName: name,
                  canAct: guard,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final state = tester.state(
          find.byType(PastJourneyArchiveUnavailableScreen),
        );
        final saved = back(tester);
        update(() {
          if (replacement == 'person') {
            name = 'Aaliyah';
          } else {
            guard = replacementGuard;
          }
        });
        await tester.pumpAndSettle();
        expect(
          tester.state(find.byType(PastJourneyArchiveUnavailableScreen)),
          same(state),
        );
        saved();
        expect(find.text('History with Maryam'), findsNothing);
        expect(find.text('History with Aaliyah'), findsNothing);
        update(() {
          name = 'Maryam';
          guard = opening;
        });
        await tester.pumpAndSettle();
        saved();
        expect(find.text('History with Maryam'), findsNothing);
        expect(
          find.byKey(const ValueKey('past-journey-archive-back')),
          findsNothing,
        );
      },
    );
  }

  archiveTest(
    'throwing opening archive guard is terminal denial, not an uncaught action',
    (tester) async {
      var throws = false;
      bool guard() {
        if (throws) throw StateError('Synthetic caller failure');
        return true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: PastJourneyArchiveUnavailableScreen(
            firstName: 'Maryam',
            canAct: guard,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final saved = back(tester);
      throws = true;
      saved();
      await tester.pumpAndSettle();
      expect(find.text('History with Maryam'), findsNothing);
      expect(tester.takeException(), isNull);
      throws = false;
      saved();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('past-journey-archive-back')),
        findsNothing,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PastJourneyArchiveUnavailableScreen(
            key: const ValueKey('new-archive-lifetime'),
            firstName: 'Maryam',
            canAct: guard,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('History with Maryam'), findsOneWidget);
    },
  );
}
