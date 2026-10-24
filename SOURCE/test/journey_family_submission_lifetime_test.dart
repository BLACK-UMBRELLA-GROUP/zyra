// OA-ZYRA-305: public Family submission lifetime controls.
// Derived from the frozen PUBLIC_V3 ordinary-auth fixture. Synthetic .invalid
// transport only; default developer access locked; telemetry disabled.
// The inherited public Guardian-ready loader is disclosed, not a private
// widget/state/readiness injection. No native/provider/backend observation.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase, supabaseReady;
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/journey/journey_flow_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_identity_verification_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_text.dart';

const _actor = '00000000-0000-4000-8000-000000003071';
const _actorB = '00000000-0000-4000-8000-000000003074';
const _other = '00000000-0000-4000-8000-000000003072';
const _match = '00000000-0000-4000-8000-000000003073';
const _host = 'family-submission-lifetime-evidence.invalid';

http.Response _json(Object? body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

Future<void> _session([String id = _actor]) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-in-memory-only',
      'user': {
        'id': id,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-06T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  final denied = <String>[];
  var name = 'Synthetic counterpart';
  var serverStage = 'compatibility_reveal';
  late Future<http.Response> Function(http.Request) familyWriteReply;
  final confirmedFamilyAnswers = <Map<String, Object?>>[];
  int count(String path, [String? method]) => requests
      .where((r) => r.url.path == path && (method == null || r.method == method)).length;
  String requestActor(http.Request r) {
    final token = r.headers['authorization']!.split(' ').last;
    return (jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(
      token.split('.')[1],
    )))) as Map)['sub'] as String;
  }

  final vertical = find.byWidgetPredicate(
    (widget) => widget is PageView && widget.scrollDirection == Axis.vertical,
  );
  double page(Finder finder, WidgetTester tester) =>
      tester.widget<PageView>(finder).controller!.page!;

  setUp(() async {
    requests.clear();
    denied.clear();
    name = 'Synthetic counterpart';
    serverStage = 'compatibility_reveal';
    confirmedFamilyAnswers.clear();
    familyWriteReply = (_) async => _json(<Object>[]);
    for (final channel in ['events', 'methods']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel('com.llfbandit.app_links/$channel'),
            (_) async => null,
          );
    }
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraProductTelemetry.instance.resetForTest();
    ZyraText.useTestFontStubs = true;
    await Supabase.initialize(
      url: 'https://$_host',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        final posts = {
          '/rest/v1/rpc/guardians_for_unlocked',
          '/rest/v1/rpc/resolve_family_review_if_due',
          '/rest/v1/rpc/zyra_my_pause_states',
          '/rest/v1/rpc/ages_for',
          '/rest/v1/rpc/zyra_journey_busy_flags',
          '/rest/v1/rpc/zyra_journey_compatibility_state',
          '/rest/v1/journey_family_answers',
        };
        final gets = {
          '/rest/v1/matches',
          '/rest/v1/profiles',
          '/rest/v1/journey_family_reviews',
          '/rest/v1/journey_salams',
          '/rest/v1/journey_phase_answers',
          '/rest/v1/journey_phase_checkpoints',
          '/rest/v1/journey_phase_ratings',
          '/rest/v1/journey_family_answers',
        };
        if (request.url.scheme != 'https' ||
            request.url.host != _host ||
            request.url.port != 443 ||
            request.url.userInfo.isNotEmpty ||
            request.url.fragment.isNotEmpty ||
            !((request.method == 'POST' &&
                    posts.contains(path) &&
                    request.url.query.isEmpty) ||
                (request.method == 'GET' && gets.contains(path)))) {
          denied.add('${request.method} ${request.url}');
          throw StateError('Wali evidence denied unexpected transport');
        }
        requests.add(request);
        http.Response response;
        if (path == '/rest/v1/journey_family_answers' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final actor = requestActor(request);
          // Permit a genuinely wrong next-account write so the lifetime oracle
          // detects it; do not mask a product bug as a mock assertion failure.
          expect(actor, isIn([_actor, _actorB]));
          final qid = body['question_id'];
          expect(qid, matches(r'^fam_wts_q[1-4]$'));
          expect(body, {
            'match_id': _match, 'direction': 'wali_to_seeker',
            'question_id': qid, 'answerer_id': actor,
            'answer_text': 'Synthetic family answer ${qid.toString().substring(9)}',
          });
          response = await familyWriteReply(request);
          confirmedFamilyAnswers.add({
            'answerer_id': actor, 'question_id': qid,
            'answer_text': body['answer_text'],
            'created_at': '2026-10-07T11:00:00Z',
          });
        } else if (path == '/rest/v1/matches') {
          expect(request.url.queryParameters['id'], 'eq.$_match');
          response = _json({
            'id': _match,
            'status': 'active',
            'journey_stage': serverStage,
            'suspended_by': null,
            'suspended_at': null,
            'ended_at': null,
          });
        } else if (path == '/rest/v1/profiles') {
          expect(request.url.queryParameters['id'], 'eq.$_other');
          response = _json({
            'id': _other,
            'first_name': name,
            'location_text': 'Generated city',
            'gender': 'female',
            'profile_photos': <Object>[],
          });
        } else if (path == '/rest/v1/rpc/guardians_for_unlocked') {
          expect(jsonDecode(request.body), {'p_target': _other});
          response = _json([
            {
              'first_name': 'Generated Main Guardian',
              'gender': 'male',
              'location_text': 'Generated city',
              'is_main': true,
              'relationship': 'father',
            },
            {
              'first_name': 'Generated Additional Guardian',
              'gender': 'male',
              'location_text': 'Generated city',
              'is_main': false,
              'relationship': 'uncle',
            },
          ]);
        } else if (path == '/rest/v1/rpc/zyra_my_pause_states') {
          expect(jsonDecode(request.body), {
            'p_match_ids': [_match],
          });
          response = _json([
            {
              'match_id': _match,
              'pause_state': 'none',
              'pause_initiated_by': _actor,
              'pause_version': 0,
            },
          ]);
        } else if (path == '/rest/v1/rpc/zyra_journey_busy_flags') {
          expect(jsonDecode(request.body), {
            'p_match_ids': [_match],
          });
          response = _json([
            {'match_id': _match, 'in_another_journey': false},
          ]);
        } else if (path == '/rest/v1/rpc/ages_for') {
          expect(jsonDecode(request.body), {
            'p_ids': [_other],
          });
          response = _json([
            {'id': _other, 'age': 30},
          ]);
        } else if (path == '/rest/v1/rpc/resolve_family_review_if_due') {
          expect(jsonDecode(request.body), {'p_match_id': _match});
          response = _json(null);
        } else if (path == '/rest/v1/rpc/zyra_journey_compatibility_state') {
          expect(jsonDecode(request.body), {'p_match_id': _match});
          response = _json(<Object>[]);
        } else if (path == '/rest/v1/journey_salams') {
          expect(request.url.queryParameters, {
            'select': 'seeker_id',
            'match_id': 'eq.$_match',
          });
          response = _json(<Object>[]);
        } else if (path == '/rest/v1/journey_phase_answers' ||
            path == '/rest/v1/journey_phase_checkpoints' ||
            path == '/rest/v1/journey_phase_ratings') {
          final query = request.url.queryParameters;
          expect(query['phase'], isIn(['eq.1', 'eq.2', 'eq.3']));
          expect(query, {
            'select': switch (path) {
              '/rest/v1/journey_phase_answers' =>
                'seeker_id,question_id,answer_text',
              '/rest/v1/journey_phase_checkpoints' => 'seeker_id,decision',
              _ => 'question_id,rating',
            },
            'match_id': 'eq.$_match',
            'phase': query['phase'],
            if (path == '/rest/v1/journey_phase_ratings')
              'rater_id': 'eq.${supabase.auth.currentUser!.id}',
          });
          response = _json(<Object>[]);
        } else if (path == '/rest/v1/journey_family_answers') {
          final query = request.url.queryParameters;
          expect(
            query['direction'],
            isIn(['eq.wali_to_seeker', 'eq.seeker_to_wali']),
          );
          expect(query, {
            'select': 'question_id,answer_text,created_at',
            'match_id': 'eq.$_match',
            'direction': query['direction'],
            'order': 'created_at.asc.nullslast',
          });
          response = _json(query['direction'] == 'eq.wali_to_seeker'
              ? confirmedFamilyAnswers
                  .where((row) => row['answerer_id'] == requestActor(request))
                  .map((row) => {
                    'question_id': row['question_id'],
                    'answer_text': row['answer_text'],
                    'created_at': row['created_at'],
                  }).toList()
              : <Object>[]);
        } else {
          response = _json(<Object>[]);
        }
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    await _session();
    expect(supabaseReady, isFalse);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    expect(ZyraDeveloperAccess.isMainAppPreview, isFalse);
    expect(ZyraInternalPreviewClient.isActive, isFalse);
    expect(ZyraIdentityVerificationService.enforceExistingAccountGate, isFalse);
    expect(ZyraProductTelemetry.productionCollectionEnabled, isFalse);
  });

  tearDown(() async {
    await ZyraAccountState.synchronize(null);
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraProductTelemetry.instance.resetForTest();
    ZyraText.useTestFontStubs = false;
    await Supabase.instance.dispose();
    for (final channel in ['events', 'methods']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel('com.llfbandit.app_links/$channel'),
            null,
          );
    }
    expect(denied, isEmpty);
  });

  Future<void> flush(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (var index = 0; index < 16; index++) {
        await Future<void>.delayed(Duration.zero);
      }
    });
    await tester.pump();
  }

  Future<void> settlePage(WidgetTester tester, Finder finder) async {
    // Bounded page-physics frames; continuous atmosphere animations prevent
    // pumpAndSettle. Keep the original exact destination assertion unchanged.
    await tester.pump();
    for (var frame = 0; frame < 120; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final controller = tester.widget<PageView>(finder).controller!;
      if (!controller.position.isScrollingNotifier.value) break;
    }
    await flush(tester);
  }

  Future<double> mount(
    WidgetTester tester, {
    required Size size,
    bool reduced = false,
    double textScale = 1,
    EdgeInsets insets = EdgeInsets.zero,
    bool longName = false,
    bool openAction = false,
  }) async {
    if (longName) name = 'Generated Counterpart With A Long Name';
    await tester.binding.setSurfaceSize(size);
    // Teardown errors are deliberately not caught or suppressed.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    });
    final profile = SeekerProfile(
      id: _other,
      firstName: name,
      age: 30,
      city: 'Generated city',
      photos: const [],
      gender: 'female',
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduced,
            textScaler: TextScaler.linear(textScale),
            padding: insets,
            viewPadding: insets,
          ),
          child: child!,
        ),
        home: JourneyFlowScreen(
          matchId: _match,
          profile: profile,
          guardianGateLoader: (_) async => ZyraJourneyGuardianGate.ready,
        ),
      ),
    );
    await flush(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await flush(tester);
    expect(vertical, findsOneWidget);
    final arrival = page(vertical, tester);
    if (openAction) {
      await tester.drag(vertical, Offset(0, -size.height * 0.75));
      await settlePage(tester, vertical);
      expect(page(vertical, tester), closeTo(arrival + 1, 0.02));
    }
    return arrival;
  }


  Future<void> fillFamily(WidgetTester tester) async {
    serverStage = 'family_stage';
    await mount(tester, size: const Size(800, 1000), openAction: true);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));
    for (var index = 0; index < 4; index++) {
      await tester.ensureVisible(fields.at(index));
      await tester.enterText(fields.at(index), 'Synthetic family answer ${index + 1}');
    }
    final share = find.byWidgetPredicate((widget) => widget is Semantics &&
        widget.properties.label == 'Share my answers');
    expect(share, findsOneWidget);
    await tester.ensureVisible(share);
    await tester.tap(share);
    await flush(tester);
  }

  for (final mode in ['same owner', 'A-B', 'A-B-A', 'disposed']) {
    testWidgets('Family submission retains its starting lifetime: $mode', (tester) async {
      final mountClock = tester.binding.clock.now();
      final pending = Completer<http.Response>();
      var dispatched = 0;
      familyWriteReply = (_) => ++dispatched == 1
          ? pending.future : Future.value(_json(<Object>[]));
      await fillFamily(tester);
      expect(count('/rest/v1/journey_family_answers', 'POST'), 1);
      expect(confirmedFamilyAnswers, isEmpty);
      final originalGeneration = ZyraAccountState.generation;
      expect(ZyraAccountState.isCurrent(_actor, originalGeneration), isTrue);

      if (mode == 'A-B' || mode == 'A-B-A') {
        await tester.runAsync(() async =>
            await _session(_actorB).timeout(const Duration(seconds: 3)));
        await flush(tester);
        expect(ZyraAccountState.isCurrent(_actor, originalGeneration), isFalse);
        expect(supabase.auth.currentUser?.id, _actorB);
        final bGeneration = ZyraAccountState.generation;
        expect(bGeneration, greaterThan(originalGeneration));
        if (mode == 'A-B-A') {
          await tester.runAsync(() async =>
              await _session(_actor).timeout(const Duration(seconds: 3)));
          await flush(tester);
          expect(ZyraAccountState.generation, greaterThan(bGeneration));
          expect(ZyraAccountState.isCurrent(_actorB, bGeneration), isFalse);
        }
      } else if (mode == 'disposed') {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(find.byType(JourneyFlowScreen), findsNothing);
      }
      final expectedActor = mode == 'A-B' ? _actorB : _actor;
      final currentGeneration = ZyraAccountState.generation;
      expect(supabase.auth.currentUser?.id, expectedActor);
      expect(ZyraAccountState.isCurrent(expectedActor, currentGeneration), isTrue);
      expect(tester.takeException(), isNull);

      // Account-transition reads are baseline work, not late-ACK side effects.
      final afterTransitionRequests = requests.length;
      final afterTransitionReads = count('/rest/v1/journey_family_answers', 'GET');
      final windowStart = tester.binding.clock.now();
      const observationWindow = Duration(milliseconds: 500);
      final firstPollDeadline = mountClock.add(const Duration(seconds: 8));
      expect(windowStart.add(observationWindow).isBefore(firstPollDeadline), isTrue);
      pending.complete(_json(<Object>[]));
      await flush(tester);
      await tester.pump(observationWindow);
      await flush(tester);
      final windowEnd = tester.binding.clock.now();
      expect(windowEnd.isBefore(firstPollDeadline), isTrue);
      expect(windowEnd.difference(windowStart), observationWindow);
      final writes = requests.where((request) =>
          request.method == 'POST' &&
          request.url.path == '/rest/v1/journey_family_answers').toList();
      debugPrint('OA305_FAMILY_LIFETIME ${jsonEncode({
        'case': mode, 'original_generation': originalGeneration,
        'current_generation': currentGeneration,
        'actor_after_ack': supabase.auth.currentUser?.id,
        'write_actors': writes.map(requestActor).toList(),
        'write_qids': writes.map((r) => (jsonDecode(r.body) as Map)['question_id']).toList(),
        'committed_synthetic_rows': confirmedFamilyAnswers.length,
        'after_transition_requests': afterTransitionRequests,
        'after_ack_requests': requests.length,
        'after_transition_family_reads': afterTransitionReads,
        'after_ack_family_reads': count('/rest/v1/journey_family_answers', 'GET'),
        'observation_ms': observationWindow.inMilliseconds,
        'elapsed_from_mount_ms': windowEnd.difference(mountClock).inMilliseconds,
      })}');

      if (mode == 'same owner') {
        expect(writes, hasLength(4));
        expect(writes.map(requestActor), everyElement(_actor));
        expect(writes.map((r) => (jsonDecode(r.body) as Map)['question_id']),
            List.generate(4, (i) => 'fam_wts_q${i + 1}'));
        expect(confirmedFamilyAnswers, hasLength(4));
        expect(count('/rest/v1/journey_family_answers', 'GET'), afterTransitionReads + 2);
        expect(find.text('Your Guardian is answering'), findsOneWidget);
      } else {
        expect(writes, hasLength(1),
            reason: 'Only the already-dispatched q1 may settle after its lifetime ends.');
        expect(requestActor(writes.single), _actor);
        expect((jsonDecode(writes.single.body) as Map)['question_id'], 'fam_wts_q1');
        expect(confirmedFamilyAnswers, hasLength(1),
            reason: 'The already-dispatched first ACK remains unrevokable locally.');
        expect(count('/rest/v1/journey_family_answers', 'GET'), afterTransitionReads);
        expect(requests, hasLength(afterTransitionRequests),
            reason: 'Retired submission must not dispatch drafts or reload.');
        expect(find.text('Your Guardian is answering'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
      }
      expect(supabase.auth.currentUser?.id, expectedActor);
      expect(ZyraAccountState.generation, currentGeneration);
      expect(ZyraAccountState.isCurrent(expectedActor, currentGeneration), isTrue);
      if (mode == 'A-B' || mode == 'A-B-A') {
        expect(ZyraAccountState.isCurrent(_actor, originalGeneration), isFalse);
      }
      expect(tester.takeException(), isNull);
      expect(denied, isEmpty);
    });
  }
}
