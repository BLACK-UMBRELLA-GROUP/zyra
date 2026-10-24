// The existing public Browse menu hook must not outlive its originating owner.
// SDK sessions, candidate records, local preferences and HTTP replies are fake.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/screens/browse/browse_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_hidden_profile_store.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_seeker_basic_usage_store.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _a = '00000000-0000-4000-8000-000000001326';
const _b = '00000000-0000-4000-8000-000000001327';
const _peer = SeekerProfile(
  id: 'retained-browse-local-peer',
  firstName: 'Aaliyah',
  age: 27,
  city: 'London',
  gender: 'female',
  photos: [],
);
const _nextPeer = SeekerProfile(
  id: 'next-browse-local-peer',
  firstName: 'Maryam',
  age: 29,
  city: 'Leeds',
  gender: 'female',
  photos: [],
);
const _realPeer = SeekerProfile(
  id: '00000000-0000-4000-8000-000000001328',
  firstName: 'Aaliyah',
  age: 27,
  city: 'London',
  gender: 'female',
  photos: [],
);
typedef _Actions = ({
  VoidCallback report,
  VoidCallback hide,
  String hideWarning,
  VoidCallback compatibility,
});

class _PushObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var revision = 0;
  var forbiddenRequests = 0;
  Future<http.Response> Function(http.Request)? decisionReply;
  final decisionRequests = <http.Request>[];
  bool? personalHideAck;
  final personalHideRequests = <http.Request>[];
  Map<String, Object?> sessionJson(String owner) {
    String part(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    return {
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': owner, 'session_id': ++revision, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': owner,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-13T00:00:00Z',
      },
    };
  }

  void emit(AuthChangeEvent event, String owner) {
    // Synthetic queued notification: the current SDK getter may still be A.
    // ignore: invalid_use_of_internal_member
    Supabase.instance.client.auth.notifyAllSubscribers(
      event,
      session: Session.fromJson(sessionJson(owner))!,
      broadcast: false,
    );
  }

  Future<void> sdkSession(String owner) {
    String part(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    return Supabase.instance.client.auth.setInitialSession(
      jsonEncode({
        'access_token':
            '${part({'alg': 'none'})}.${part({'sub': owner, 'session_id': ++revision, 'exp': 4102444800})}.synthetic',
        'token_type': 'bearer',
        'refresh_token': 'synthetic-refresh',
        'user': {
          'id': owner,
          'app_metadata': <String, Object?>{},
          'user_metadata': <String, Object?>{},
          'aud': 'authenticated',
          'created_at': '2026-10-13T00:00:00Z',
        },
      }),
    );
  }

  Future<void> flush(WidgetTester tester) async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
  }

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
        if (personalHideAck != null &&
            request.url.path == '/rest/v1/rpc/zyra_set_profile_hidden') {
          personalHideRequests.add(request);
          return http.Response(
            jsonEncode({
              'schema_version': 1,
              'viewer_id': _a,
              'profile_id': _realPeer.id,
              'hidden': personalHideAck,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (decisionReply != null &&
            request.method == 'POST' &&
            const [
              '/rest/v1/saves',
              '/rest/v1/passes',
              '/rest/v1/likes',
            ].contains(request.url.path)) {
          decisionRequests.add(request);
          return decisionReply!(request);
        }
        // These are the ordinary screen's two read-only startup calls.
        if ((request.method == 'POST' &&
                request.url.path ==
                    '/rest/v1/rpc/zyra_my_onboarding_progress') ||
            (request.method == 'GET' &&
                request.url.path == '/rest/v1/wali_suggestions')) {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        forbiddenRequests++;
        throw StateError('Unexpected transport in the local Browse fixture.');
      }),
    );
    // Initialise the read-only usage queue outside any individual widget
    // test's FakeAsync lifetime. Later Basic fixtures must not await a
    // static Future first created in an already-finished fake zone.
    await ZyraSeekerBasicUsageStore.load();
  });
  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await (await SharedPreferences.getInstance()).clear();
    await sdkSession(_a);
    await ZyraAccountState.synchronize(_a);
    AppState.instance.plan = ZyraPlan.one;
    forbiddenRequests = 0;
    decisionReply = null;
    decisionRequests.clear();
    personalHideAck = null;
    personalHideRequests.clear();
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.clearImagesForTesting = null;
  });
  tearDownAll(() => Supabase.instance.dispose());

  void actionTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
        expect(forbiddenRequests, 0);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await flush(tester);
        await tester.runAsync(() => ZyraAccountState.synchronize(null));
        await flush(tester);
      }
    }, timeout: const Timeout(Duration(seconds: 25)));
  }

  Future<_Actions> menu(
    WidgetTester tester,
    _PushObserver observer, {
    SeekerProfile profile = _peer,
  }) async {
    _Actions? actions;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Scaffold(
          body: BrowseScreen(
            loadHiddenIds: () async => const [],
            loadCandidates: () async => ZyraSourceResult.available([profile]),
            onOpenActions: (value) => actions = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ZyraBrowseMoreActionsButton));
    await tester.pump();
    expect(actions, isNotNull);
    return actions!;
  }

  Future<GlobalKey<NavigatorState>> decisionDeck(
    WidgetTester tester, {
    Future<ZyraSeekerBasicUsage?> Function()? claim,
    Future<ZyraSeekerBasicUsage> Function()? swipe,
    SeekerProfile first = _peer,
  }) async {
    AppState.instance.plan = ZyraPlan.basic;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(
          body: BrowseScreen(
            loadHiddenIds: () async => const [],
            loadCandidates: () async =>
                ZyraSourceResult.available([first, _nextPeer]),
            claimConsider: claim,
            recordSwipe: swipe,
          ),
        ),
      ),
    );
    await flush(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ZyraBrowseMoreActionsButton), findsOneWidget);
    return navigator;
  }

  GestureDetector swipeWidget(WidgetTester tester) =>
      tester.widget<GestureDetector>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is GestureDetector &&
                  widget.onPanStart != null &&
                  widget.onPanEnd != null,
            )
            .first,
      );

  void swipe(GestureDetector gesture, Offset delta) {
    // Invoke the public gesture callbacks saved from the real mounted card,
    // not private screen state or a substitute action implementation.
    gesture.onPanStart!(
      DragStartDetails(globalPosition: const Offset(100, 200)),
    );
    gesture.onPanUpdate!(
      DragUpdateDetails(delta: delta, globalPosition: Offset(100, 200) + delta),
    );
    gesture.onPanEnd!(DragEndDetails());
  }

  for (final boundary in [
    'Account B',
    'queued SDK B A',
    'same-owner sign-in',
    'covered and returned',
    'disposed',
    'replaced decision',
  ]) {
    actionTest('pending Browse Consider denies $boundary', (tester) async {
      final claim = Completer<ZyraSeekerBasicUsage?>();
      var claimed = 0;
      var advanced = 0;
      final navigator = await decisionDeck(
        tester,
        claim: () {
          claimed++;
          return claim.future;
        },
        swipe: () async {
          advanced++;
          return ZyraSeekerBasicUsage.fresh(DateTime(2026));
        },
      );
      swipe(swipeWidget(tester), const Offset(-220, 0));
      await tester.pump();
      expect(claimed, 1);
      switch (boundary) {
        case 'Account B':
          await tester.runAsync(() => ZyraAccountState.synchronize(_b));
        case 'queued SDK B A':
          emit(AuthChangeEvent.tokenRefreshed, _b);
          emit(AuthChangeEvent.tokenRefreshed, _a);
        case 'same-owner sign-in':
          emit(AuthChangeEvent.signedIn, _a);
        case 'covered and returned':
          navigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Other route')),
            ),
          );
          await tester.pumpAndSettle();
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
        case 'disposed':
          await tester.pumpWidget(const SizedBox.shrink());
        case 'replaced decision':
          swipe(swipeWidget(tester), const Offset(220, 0));
      }
      await flush(tester);
      claim.complete(ZyraSeekerBasicUsage.fresh(DateTime(2026)));
      await flush(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(AppState.instance.outgoingLikes, isEmpty);
      expect(advanced, boundary == 'replaced decision' ? 1 : 0);
      expect(decisionRequests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  actionTest(
    'same-owner SDK refresh preserves pending Consider and one advance',
    (tester) async {
      final claim = Completer<ZyraSeekerBasicUsage?>();
      var advanced = 0;
      await decisionDeck(
        tester,
        claim: () => claim.future,
        swipe: () async {
          advanced++;
          return ZyraSeekerBasicUsage.fresh(DateTime(2026));
        },
      );
      swipe(swipeWidget(tester), const Offset(-220, 0));
      await tester.pump();
      // Matching initial snapshot and refresh events are not new sign-ins.
      // ignore: invalid_use_of_internal_member
      Supabase.instance.client.auth.notifyAllSubscribers(
        AuthChangeEvent.initialSession,
        session: Supabase.instance.client.auth.currentSession,
        broadcast: false,
      );
      emit(AuthChangeEvent.tokenRefreshed, _a);
      await flush(tester);
      claim.complete(ZyraSeekerBasicUsage.fresh(DateTime(2026)));
      await flush(tester);
      expect(AppState.instance.outgoingLikes.map((p) => p.id), [_peer.id]);
      await tester.pump(const Duration(milliseconds: 400));
      await flush(tester);
      expect(advanced, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final direction in [const Offset(220, 0), const Offset(0, 220)]) {
    actionTest(
      'Browse ${direction.dx == 0 ? 'Save' : 'Pass'} timer cannot charge replacement account',
      (tester) async {
        var advanced = 0;
        await decisionDeck(
          tester,
          swipe: () async {
            advanced++;
            return ZyraSeekerBasicUsage.fresh(DateTime(2026));
          },
        );
        swipe(swipeWidget(tester), direction);
        await tester.pump();
        await tester.runAsync(() => ZyraAccountState.synchronize(_b));
        await flush(tester);
        await tester.pump(const Duration(milliseconds: 500));
        expect(advanced, 0);
        expect(AppState.instance.saved, isEmpty);
        expect(AppState.instance.outgoingLikes, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  actionTest(
    'retained Browse gesture denies cover-return while fresh gesture remains usable',
    (tester) async {
      var advanced = 0;
      final navigator = await decisionDeck(
        tester,
        swipe: () async {
          advanced++;
          return ZyraSeekerBasicUsage.fresh(DateTime(2026));
        },
      );
      final saved = swipeWidget(tester);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Other route')),
        ),
      );
      await tester.pumpAndSettle();
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      swipe(saved, const Offset(0, 220));
      await tester.pump(const Duration(milliseconds: 500));
      expect(AppState.instance.saved, isEmpty);
      expect(advanced, 0);
      swipe(swipeWidget(tester), const Offset(0, 220));
      await tester.pump(const Duration(milliseconds: 500));
      await flush(tester);
      expect(AppState.instance.saved.map((p) => p.id), [_peer.id]);
      expect(advanced, 1);
    },
  );

  actionTest(
    'saved Browse retry denies queued owner withdrawal before dispatch',
    (tester) async {
      decisionReply = (request) async =>
          http.Response('{}', 500, request: request);
      await decisionDeck(
        tester,
        first: _realPeer,
        swipe: () async => ZyraSeekerBasicUsage.fresh(DateTime(2026)),
      );
      swipe(swipeWidget(tester), const Offset(0, 220));
      await flush(tester);
      await tester.pumpAndSettle();
      expect(decisionRequests, hasLength(1));
      final retry = tester
          .widget<SnackBarAction>(find.byType(SnackBarAction))
          .onPressed;
      emit(AuthChangeEvent.tokenRefreshed, _b);
      emit(AuthChangeEvent.tokenRefreshed, _a);
      await flush(tester);
      retry();
      await flush(tester);
      expect(decisionRequests, hasLength(1));
      expect(find.text('Save saved.'), findsNothing);
    },
  );

  actionTest('pending Browse retry never publishes success after withdrawal', (
    tester,
  ) async {
    final reply = Completer<http.Response>();
    decisionReply = (request) => decisionRequests.length == 1
        ? Future.value(http.Response('{}', 500, request: request))
        : reply.future;
    await decisionDeck(
      tester,
      first: _realPeer,
      swipe: () async => ZyraSeekerBasicUsage.fresh(DateTime(2026)),
    );
    swipe(swipeWidget(tester), const Offset(0, 220));
    await flush(tester);
    await tester.pumpAndSettle();
    final retry = tester
        .widget<SnackBarAction>(find.byType(SnackBarAction))
        .onPressed;
    retry();
    await flush(tester);
    expect(decisionRequests, hasLength(2));
    emit(AuthChangeEvent.signedIn, _a);
    await flush(tester);
    reply.complete(http.Response('{}', 201, request: decisionRequests.last));
    await flush(tester);
    expect(find.text('Save saved.'), findsNothing);
    expect(decisionRequests, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  for (final replacement in ['AccountState B', 'SDK B', 'SDK A B A']) {
    actionTest('retained Browse actions deny $replacement', (tester) async {
      final observer = _PushObserver();
      final actions = await menu(tester, observer);
      final generation = ZyraAccountState.generation;
      await tester.runAsync(() async {
        if (replacement == 'AccountState B') {
          await ZyraAccountState.synchronize(_b);
        } else {
          await sdkSession(_b);
          if (replacement == 'SDK A B A') await sdkSession(_a);
        }
      });
      if (replacement != 'AccountState B') {
        expect(ZyraAccountState.userId, _a);
        expect(ZyraAccountState.generation, generation);
      }
      await flush(tester);
      // A stale hide must not remove the new owner's account-local record.
      AppState.instance.saved.add(_peer);
      final pushes = observer.pushes;
      actions.hide();
      actions.report();
      actions.compatibility();
      await flush(tester);
      expect(observer.pushes, pushes);
      expect(AppState.instance.saved.map((p) => p.id), contains(_peer.id));
      final hidden = await tester.runAsync(ZyraHiddenProfileStore.records);
      expect(hidden, isEmpty);
      expect(find.byType(ZyraBrowseMoreActionsButton), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  actionTest('current owner can still hide a synthetic Browse profile', (
    tester,
  ) async {
    final actions = await menu(tester, _PushObserver());
    AppState.instance.saved.add(_peer);
    actions.hide();
    await flush(tester);
    final hidden = await tester.runAsync(ZyraHiddenProfileStore.records);
    expect(hidden?.map((p) => p.id), contains(_peer.id));
    expect(AppState.instance.saved, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final acknowledged in [true, false]) {
    actionTest('real personal Hide ACK $acknowledged never ends a Journey', (
      tester,
    ) async {
      personalHideAck = acknowledged;
      final actions = await menu(tester, _PushObserver(), profile: _realPeer);
      const journey = JourneyMatch(
        matchId: 'synthetic-retained-journey',
        profile: _realPeer,
        status: 'active',
      );
      AppState.instance.activeJourneys.add(journey);
      expect(actions.hideWarning, contains('does not block'));
      expect(actions.hideWarning, isNot(contains('will end')));
      actions.hide();
      await flush(tester);
      expect(personalHideRequests, hasLength(1));
      expect(jsonDecode(personalHideRequests.single.body), {
        'p_other': _realPeer.id,
        'p_hidden': true,
      });
      expect(AppState.instance.activeJourneys, contains(same(journey)));
      final records = await tester.runAsync(ZyraHiddenProfileStore.records);
      expect(records, isEmpty);
      if (acknowledged) {
        expect(find.byType(SnackBar), findsNothing);
        expect(find.text('Aaliyah'), findsNothing);
      } else {
        expect(
          find.text("That didn't go through — try again."),
          findsOneWidget,
        );
        expect(find.text('Aaliyah'), findsOneWidget);
      }
    });
  }
}
