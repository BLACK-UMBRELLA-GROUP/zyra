import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/main.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/journey/journey_flow_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_loading.dart';

const _owner = '00000000-0000-4000-8000-000000000901';
const _other = '00000000-0000-4000-8000-000000000902';
const _match = '00000000-0000-4000-8000-000000000903';
const _profile = SeekerProfile(
  id: _other,
  firstName: 'Synthetic counterpart',
  age: 30,
  city: 'Synthetic city',
  photos: [],
  gender: 'female',
);

Future<void> _session() async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': _owner, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': _owner,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-05T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(_owner);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final scenario = ZyraDevScenario.instance;
  final unexpectedRequests = <String>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    // Every SDK request is intercepted; no server or member data is used.
    await Supabase.initialize(
      url: 'https://synthetic-journey.invalid',
      publishableKey: 'synthetic-test-only',
      // This fixture injects sessions; native deep-link delivery is not under test.
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        Object? result;
        if (path == '/rest/v1/rpc/resolve_family_review_if_due') {
          result = null;
        } else if (path == '/rest/v1/matches') {
          result = {
            'id': _match,
            'status': 'active',
            'journey_stage': 'salam_exchange',
            'suspended_by': null,
            'suspended_at': null,
            'ended_at': null,
          };
        } else if (path == '/rest/v1/profiles') {
          result = {
            'id': _other,
            'first_name': _profile.firstName,
            'location_text': _profile.city,
            'gender': _profile.gender,
            'profile_photos': <Object>[],
          };
        } else if (const {
          '/rest/v1/rpc/zyra_my_pause_states',
          '/rest/v1/rpc/ages_for',
          '/rest/v1/rpc/zyra_journey_busy_flags',
          '/rest/v1/journey_family_reviews',
        }.contains(path)) {
          result = <Object>[];
        } else {
          unexpectedRequests.add('${request.method} $path');
          return http.Response('synthetic route denied', 503);
        }
        return http.Response(
          jsonEncode(result),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    scenario.reset();
    unexpectedRequests.clear();
    ZyraText.useTestFontStubs = true;
    await _session();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.resetForTesting();
    expect(unexpectedRequests, isEmpty);
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<void> mount(
    WidgetTester tester,
    Future<ZyraJourneyGuardianGate> Function(String) loader,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyFlowScreen(
          matchId: _match,
          profile: _profile,
          guardianGateLoader: loader,
        ),
      ),
    );
    // SDK futures run outside FakeAsync; animated loading is intentionally
    // not settled indefinitely. The unrelated Journey reads are in memory.
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Choose a Main Guardian'), findsOneWidget);
  }

  testWidgets('preview-to-live withdraws the gate until its answer arrives', (
    tester,
  ) async {
    final pending = Completer<ZyraJourneyGuardianGate>();
    var calls = 0;
    await mount(tester, (_) {
      calls++;
      return pending.future;
    });
    expect(calls, 0);

    scenario.setUseLiveGuardianData(true);
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Choose a Main Guardian'), findsNothing);
    expect(find.byType(ZyraLoading), findsOneWidget);

    pending.complete(ZyraJourneyGuardianGate.otherMissing);
    await tester.pump();
    expect(find.text('This Journey is waiting'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('revocation and refreshed gate reject the earlier late result', (
    tester,
  ) async {
    final older = Completer<ZyraJourneyGuardianGate>();
    final current = Completer<ZyraJourneyGuardianGate>();
    var calls = 0;
    await mount(tester, (_) => ++calls == 1 ? older.future : current.future);

    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Choose a Main Guardian'), findsNothing);
    expect(find.byType(ZyraLoading), findsOneWidget);

    ZyraWaliLinkService.linkRevision.value++;
    await tester.pump();
    expect(calls, 2);
    current.complete(ZyraJourneyGuardianGate.unavailable);
    await tester.pump();
    expect(find.text("Couldn't check your Main Guardian"), findsOneWidget);
    older.complete(ZyraJourneyGuardianGate.ready);
    await tester.pump();
    expect(find.text("Couldn't check your Main Guardian"), findsOneWidget);
    expect(find.text('Choose a Main Guardian'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('account generation rejects an in-flight gate answer', (
    tester,
  ) async {
    final pending = Completer<ZyraJourneyGuardianGate>();
    await mount(tester, (_) => pending.future);
    scenario.setUseLiveGuardianData(true);
    await tester.pump();
    ZyraAccountState.resetForTesting();
    pending.complete(ZyraJourneyGuardianGate.selfMissing);
    await tester.pump();
    expect(find.text('Choose a Main Guardian'), findsNothing);
    expect(find.byType(ZyraLoading), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
