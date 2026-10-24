// OA151/299/304/305/307: ordinary Timeline actions never cross their opening
// actor, SDK lifetime, route visit or selected-person intent. All replies and
// SDK notifications are synthetic; no backend, paid authority or device API.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/matches/journey_timeline_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_match_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_moment.dart';

const _a = '00000000-0000-4000-8000-000000006201';
const _b = '00000000-0000-4000-8000-000000006202';
const _person = SeekerProfile(
  id: 'timeline-local-person',
  firstName: 'Aaliyah',
  age: 27,
  city: 'London',
  gender: 'female',
  photos: [],
);
const _replacement = SeekerProfile(
  id: 'timeline-local-replacement',
  firstName: 'Maryam',
  age: 29,
  city: 'Leeds',
  gender: 'female',
  photos: [],
);
final _pending = ZyraMilestoneAttestation(
  id: 'local-attestation',
  type: 'meeting',
  occurredOn: _recordedDate,
  proposedBy: _b,
);
final _recordedDate = DateTime(2026, 10, 1);

Map<String, dynamic> _sessionJson(String owner, {String token = 'opening'}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': owner, 'session_id': 'timeline-session', 'jti': token, 'exp': 4102444800})}.synthetic',
    'token_type': 'bearer',
    'refresh_token': 'synthetic-refresh',
    'user': {
      'id': owner,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-18T00:00:00Z',
    },
  };
}

void _emit(AuthChangeEvent event, String owner, {String token = 'opening'}) {
  // Queue a payload without changing the getter or AppState generation.
  // ignore: invalid_use_of_internal_member
  Supabase.instance.client.auth.notifyAllSubscribers(
    event,
    session: Session.fromJson(_sessionJson(owner, token: token))!,
    broadcast: false,
  );
}

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

VoidCallback _recordAction(WidgetTester tester) => tester
    .widget<InkWell>(
      find
          .ancestor(
            of: find.text('Record a milestone'),
            matching: find.byType(InkWell),
          )
          .first,
    )
    .onTap!;

VoidCallback _confirmAction(WidgetTester tester) => tester
    .widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm'))
    .onPressed!;

class _Host {
  final navigator = GlobalKey<NavigatorState>();
  final timelineKey = GlobalKey();
  late StateSetter update;
  SeekerProfile person = _person;
  int reads = 0;
  int proposed = 0;
  int confirmed = 0;
  Future<String?> Function(String, String, DateTime)? propose;
  Future<String?> Function(String)? confirm;
  ZyraTimelineContext context = const ZyraTimelineContext(
    matchId: 'local-match',
    active: true,
  );

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return JourneyTimelineScreen(
              key: timelineKey,
              withProfile: person,
              loadTimeline: (_) async {
                reads++;
                return const ZyraSourceResult.available(<ZyraMilestone>[]);
              },
              loadContext: (_) async => this.context,
              proposeMilestone: (match, type, date) {
                proposed++;
                return propose?.call(match, type, date) ?? Future.value(null);
              },
              confirmMilestone: (id) {
                confirmed++;
                return confirm?.call(id) ?? Future.value(null);
              },
            );
          },
        ),
      ),
    );
    await _flush(tester);
    await tester.pumpAndSettle();
    expect(find.text('Timeline with Aaliyah'), findsOneWidget);
  }

  Future<void> cover(WidgetTester tester, {bool returnToPage = true}) async {
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Unrelated route')),
      ),
    );
    await tester.pumpAndSettle();
    if (returnToPage) {
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var unexpectedTransport = 0;
  var phaseReads = 0;

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
        if (request.method == 'GET' &&
            request.url.path == '/rest/v1/journey_phase_answers') {
          phaseReads++;
          return http.Response(
            '[]',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        unexpectedTransport++;
        throw StateError(
          'Unexpected Timeline transport; mutations must use the detached test seam.',
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
    unexpectedTransport = 0;
    phaseReads = 0;
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.clearImagesForTesting = null;
  });

  void actionTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
        expect(unexpectedTransport, 0);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush(tester);
        await tester.runAsync(() => ZyraAccountState.synchronize(null));
        await _flush(tester);
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  }

  Future<void> boundary(WidgetTester tester, _Host host, String kind) async {
    switch (kind) {
      case 'account replacement':
        await tester.runAsync(() => ZyraAccountState.synchronize(_b));
      case 'queued SDK ABA':
        _emit(AuthChangeEvent.tokenRefreshed, _b);
        _emit(AuthChangeEvent.tokenRefreshed, _a);
      case 'same-owner session boundary':
        _emit(AuthChangeEvent.signedIn, _a);
      case 'cover and return':
        await host.cover(tester);
      case 'disposed':
        await tester.pumpWidget(const SizedBox.shrink());
      case 'replaced person':
        host.update(() => host.person = _replacement);
    }
    await _flush(tester);
  }

  for (final kind in [
    'account replacement',
    'queued SDK ABA',
    'same-owner session boundary',
    'cover and return',
    'disposed',
    'replaced person',
  ]) {
    actionTest('saved Timeline record entry denies $kind', (tester) async {
      final host = _Host();
      await host.mount(tester);
      final saved = _recordAction(tester);
      await boundary(tester, host, kind);
      saved();
      await _flush(tester);
      expect(find.widgetWithText(FilledButton, 'Meeting'), findsNothing);
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(host.proposed, 0);
      expect(host.confirmed, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final kind in [
    'account replacement',
    'queued SDK ABA',
    'cover and return',
    'disposed',
    'replaced person',
  ]) {
    actionTest('Timeline type dialog withdraws safely on $kind', (
      tester,
    ) async {
      final host = _Host();
      await host.mount(tester);
      await tester.tap(find.text('Record a milestone'));
      await tester.pumpAndSettle();
      final saved = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Meeting'))
          .onPressed!;
      await boundary(tester, host, kind);
      saved();
      await _flush(tester);
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(host.proposed, 0);
      expect(tester.takeException(), isNull);
    });
  }

  actionTest(
    'Timeline date dialog withdraws on SDK replacement without null-match crash',
    (tester) async {
      final host = _Host();
      await host.mount(tester);
      await tester.tap(find.text('Record a milestone'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Meeting'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      _emit(AuthChangeEvent.signedIn, _b);
      await _flush(tester);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(host.proposed, 0);
      expect(tester.takeException(), isNull);
    },
  );

  actionTest(
    'same-owner SDK refresh preserves the complete Timeline proposal flow',
    (tester) async {
      final host = _Host();
      final sent = <(String, String, DateTime)>[];
      host.propose = (match, type, date) async {
        sent.add((match, type, date));
        return null;
      };
      await host.mount(tester);
      await tester.tap(find.text('Record a milestone'));
      await tester.pumpAndSettle();
      // Matching bootstrap notification and refresh are not account changes.
      _emit(AuthChangeEvent.initialSession, _a);
      _emit(AuthChangeEvent.tokenRefreshed, _a, token: 'refreshed');
      await _flush(tester);
      final savedType = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Meeting'))
          .onPressed!;
      await tester.tap(find.widgetWithText(FilledButton, 'Meeting'));
      await tester.pumpAndSettle();
      savedType();
      await tester.pump();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('OK'));
      await _flush(tester);
      expect(host.proposed, 1);
      expect(sent.single.$1, 'local-match');
      expect(sent.single.$2, 'meeting');
      expect(find.textContaining('Asked Aaliyah to confirm'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(host.reads, 2);
      expect(phaseReads, 6);
      expect(tester.takeException(), isNull);
    },
  );

  actionTest('a refused Timeline proposal remains visible and reloads', (
    tester,
  ) async {
    final host = _Host()
      ..propose = (_, _, _) async => 'This milestone could not be saved.';
    await host.mount(tester);
    await tester.tap(find.text('Record a milestone'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Meeting'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await _flush(tester);
    expect(host.proposed, 1);
    expect(find.text('This milestone could not be saved.'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Asked Aaliyah to confirm'), findsNothing);
    expect(host.reads, 2);
    expect(phaseReads, 6);
    expect(tester.takeException(), isNull);
  });

  for (final kind in [
    'queued SDK ABA',
    'cover and return',
    'disposed',
    'replaced person',
  ]) {
    actionTest('saved Timeline confirmation denies $kind before dispatch', (
      tester,
    ) async {
      final host = _Host()
        ..context = ZyraTimelineContext(
          matchId: 'local-match',
          active: true,
          pending: _pending,
        );
      await host.mount(tester);
      final saved = _confirmAction(tester);
      await boundary(tester, host, kind);
      saved();
      await _flush(tester);
      expect(host.confirmed, 0);
      expect(find.byType(ZyraMomentScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    actionTest('Timeline confirmation ACK is not published after $kind', (
      tester,
    ) async {
      final reply = Completer<String?>();
      final host = _Host()
        ..context = ZyraTimelineContext(
          matchId: 'local-match',
          active: true,
          pending: _pending,
        )
        ..confirm = (_) => reply.future;
      await host.mount(tester);
      final saved = _confirmAction(tester);
      saved();
      await tester.pump();
      expect(host.confirmed, 1);
      saved();
      expect(
        host.confirmed,
        1,
        reason: 'One in-flight confirmation owns the intent.',
      );
      await boundary(tester, host, kind);
      final reads = host.reads;
      reply.complete(null);
      await _flush(tester);
      expect(find.byType(ZyraMomentScreen), findsNothing);
      expect(find.text('You met.'), findsNothing);
      expect(host.reads, reads);
      expect(host.confirmed, 1);
      expect(tester.takeException(), isNull);
    });
  }

  actionTest(
    'healthy Timeline confirmation retains its existing moment and reload',
    (tester) async {
      final host = _Host()
        ..context = ZyraTimelineContext(
          matchId: 'local-match',
          active: true,
          pending: _pending,
        );
      await host.mount(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();
      expect(host.confirmed, 1);
      expect(find.byType(ZyraMomentScreen), findsOneWidget);
      expect(find.text('You met.'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await _flush(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ZyraMomentScreen), findsNothing);
      expect(host.reads, 2);
      expect(tester.takeException(), isNull);
    },
  );

  actionTest(
    'Timeline confirmation moment withdraws with its opening SDK session',
    (tester) async {
      final host = _Host()
        ..context = ZyraTimelineContext(
          matchId: 'local-match',
          active: true,
          pending: _pending,
        );
      await host.mount(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();
      final saved = tester
          .widget<ZyraMomentScreen>(find.byType(ZyraMomentScreen))
          .onPrimary!;
      _emit(AuthChangeEvent.signedIn, _b);
      await _flush(tester);
      saved();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraMomentScreen), findsNothing);
      expect(host.reads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  actionTest(
    'inactive or paused Timeline never exposes milestone mutation actions',
    (tester) async {
      for (final context in [
        ZyraTimelineContext(matchId: 'local-match', pending: _pending),
        ZyraTimelineContext(
          matchId: 'local-match',
          active: true,
          paused: true,
          pending: _pending,
        ),
      ]) {
        final host = _Host()..context = context;
        await host.mount(tester);
        expect(find.text('Record a milestone'), findsNothing);
        expect(find.widgetWithText(FilledButton, 'Confirm'), findsNothing);
        expect(host.confirmed, 0);
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush(tester);
      }
      expect(AppState.instance.plan, ZyraPlan.basic);
    },
  );
}
