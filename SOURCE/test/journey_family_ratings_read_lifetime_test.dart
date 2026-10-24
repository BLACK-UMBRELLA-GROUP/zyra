// OA-ZYRA-305: Family aggregate ratings ownership, first phase-rating fetch.
// Public widget/SDK/services only, strict .invalid HTTP; disclosed inherited
// synthetic Guardian-ready loader and font stubs. Existing public setPlan(One)
// is mock-only UI entitlement, NOT receipt authority, verification or admission.
// No private state injection, duplicate service call, or widget disposal case.
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
import 'package:zyra/state/app_state.dart';

const _actor = '00000000-0000-4000-8000-000000003071';
const _actorB = '00000000-0000-4000-8000-000000003074';
const _other = '00000000-0000-4000-8000-000000003072';
const _match = '00000000-0000-4000-8000-000000003073';
const _host = 'family-ratings-lifetime-evidence.invalid';

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
  late Future<http.Response> Function(http.Request) ratingReadReply;
  final ratingReadObservations = <Map<String, Object?>>[];
  int count(String path, [String? method]) => requests
      .where(
        (r) => r.url.path == path && (method == null || r.method == method),
      )
      .length;
  String requestActor(http.Request r) {
    final token = r.headers['authorization']!.split(' ').last;
    return (jsonDecode(
              utf8.decode(
                base64Url.decode(base64Url.normalize(token.split('.')[1])),
              ),
            )
            as Map)['sub']
        as String;
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
    ratingReadObservations.clear();
    ratingReadReply = (_) async => _json(<Object>[]);
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
        if (path == '/rest/v1/matches') {
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
          if (path == '/rest/v1/journey_phase_ratings') {
            ratingReadObservations.add({
              'actor': requestActor(request),
              'phase': query['phase'],
              'rater_id': query['rater_id'],
            });
            response = await ratingReadReply(request);
          } else {
            response = _json(<Object>[]);
          }
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
          response = _json(
            query['direction'] == 'eq.wali_to_seeker'
                ? List.generate(
                    4,
                    (i) => {
                      'question_id': 'fam_wts_q${i + 1}',
                      'answer_text':
                          'Synthetic completed family answer ${i + 1}',
                      'created_at': '2026-10-07T12:00:00Z',
                    },
                  )
                : <Object>[],
          );
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
    expect(AppState.instance.plan, ZyraPlan.basic);
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

  const expectedSummary =
      'This is the summary your Guardian would be given: '
      'you and Synthetic counterpart appear well aligned on faith in daily life. '
      'children and handling disagreement may benefit from an early conversation.';
  // Pure generator trace: p1_q1→faith in daily life/reassured,
  // p2_q1→children/concerns, p3_q1→handling disagreement/discuss_further.
  // Every topic in this exact public summary depends on a returned phase row.

  for (final mode in ['same owner', 'A-B', 'A-B-A']) {
    testWidgets('Family aggregate ratings retain their starting lifetime: $mode', (
      tester,
    ) async {
      final mountClock = tester.binding.clock.now();
      if (mode == 'same owner') {
        // Existing public mock plan setter; not real payment/admission proof.
        AppState.instance.setPlan(ZyraPlan.one);
      }
      final pending = Completer<http.Response>();
      var dispatched = 0;
      String? firstDispatchedActor;
      String? firstDispatchedRater;
      List<Map<String, Object?>>? firstRows;
      ratingReadReply = (request) {
        final actor = requestActor(request);
        final query = request.url.queryParameters;
        if (++dispatched == 1) {
          expect(actor, _actor);
          expect(query['phase'], 'eq.1');
          expect(query['rater_id'], 'eq.$_actor');
          firstDispatchedActor = actor;
          firstDispatchedRater = query['rater_id'];
          firstRows = [
            {'question_id': 'p1_q1', 'rating': 'reassured'},
          ];
          return pending.future;
        }
        // Potential wrong-account reads are allowed, observed, not mock-denied.
        return Future.value(
          _json([
            if (query['phase'] == 'eq.2')
              {'question_id': 'p2_q1', 'rating': 'concerns'}
            else
              {'question_id': 'p3_q1', 'rating': 'discuss_further'},
          ]),
        );
      };
      serverStage = 'family_stage';
      await mount(tester, size: const Size(800, 1000), openAction: true);
      expect(count('/rest/v1/journey_family_answers', 'GET'), 2);
      expect(count('/rest/v1/journey_phase_ratings', 'GET'), 1);
      expect(dispatched, 1);
      expect(firstDispatchedActor, _actor);
      expect(firstDispatchedRater, 'eq.$_actor');
      expect(
        AppState.instance.plan,
        mode == 'same owner' ? ZyraPlan.one : ZyraPlan.basic,
      );
      expect(find.text('Your Guardian is answering'), findsNothing);
      final originalGeneration = ZyraAccountState.generation;
      expect(ZyraAccountState.isCurrent(_actor, originalGeneration), isTrue);
      if (mode != 'same owner') {
        await tester.runAsync(
          () async =>
              await _session(_actorB).timeout(const Duration(seconds: 3)),
        );
        await flush(tester);
        final bGeneration = ZyraAccountState.generation;
        expect(ZyraAccountState.isCurrent(_actor, originalGeneration), isFalse);
        expect(AppState.instance.plan, ZyraPlan.basic);
        if (mode == 'A-B-A') {
          await tester.runAsync(
            () async =>
                await _session(_actor).timeout(const Duration(seconds: 3)),
          );
          await flush(tester);
          expect(ZyraAccountState.generation, greaterThan(bGeneration));
        }
      }
      final expectedActor = mode == 'A-B' ? _actorB : _actor;
      final currentGeneration = ZyraAccountState.generation;
      expect(supabase.auth.currentUser?.id, expectedActor);
      expect(
        ZyraAccountState.isCurrent(expectedActor, currentGeneration),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      final afterTransitionRequests = requests.length;
      final afterTransitionFamilyReads = count(
        '/rest/v1/journey_family_answers',
        'GET',
      );
      final afterTransitionRatingReads = count(
        '/rest/v1/journey_phase_ratings',
        'GET',
      );
      final windowStart = tester.binding.clock.now();
      const observationWindow = Duration(milliseconds: 500);
      final firstPollDeadline = mountClock.add(const Duration(seconds: 8));
      pending.complete(_json(firstRows!));
      await flush(tester);
      await tester.pump(observationWindow);
      await flush(tester);
      final windowEnd = tester.binding.clock.now();
      final frameworkError = tester.takeException();
      final afterAckRatingReads = count(
        '/rest/v1/journey_phase_ratings',
        'GET',
      );
      final completionVisible = find
          .text('Your Guardian is answering')
          .evaluate()
          .isNotEmpty;
      final summaryVisible = find.text(expectedSummary).evaluate().isNotEmpty;
      final postRequests = requests.skip(afterTransitionRequests).toList();
      debugPrint(
        'OA305_FAMILY_RATINGS_LIFETIME ${jsonEncode({'case': mode, 'original_generation': originalGeneration, 'current_generation': currentGeneration, 'generation_after_ack': ZyraAccountState.generation, 'actor_after_ack': supabase.auth.currentUser?.id, 'first_dispatched_actor': firstDispatchedActor, 'first_dispatched_rater': firstDispatchedRater, 'frozen_first_rows': firstRows, 'rating_reads_at_dispatch': ratingReadObservations, 'after_transition_requests': afterTransitionRequests, 'after_ack_requests': requests.length, 'post_ack_request_actors': postRequests.map(requestActor).toList(), 'after_transition_family_reads': afterTransitionFamilyReads, 'after_ack_family_reads': count('/rest/v1/journey_family_answers', 'GET'), 'after_transition_rating_reads': afterTransitionRatingReads, 'after_ack_rating_reads': afterAckRatingReads, 'completion_visible': completionVisible, 'expected_summary_visible': summaryVisible, 'mock_plan_after_ack': AppState.instance.plan.name, 'framework_error': frameworkError?.toString(), 'observation_ms': observationWindow.inMilliseconds, 'elapsed_from_mount_ms': windowEnd.difference(mountClock).inMilliseconds, 'within_initial_poll_window': windowEnd.isBefore(firstPollDeadline)})}',
      );
      expect(
        windowStart.add(observationWindow).isBefore(firstPollDeadline),
        isTrue,
      );
      expect(windowEnd.isBefore(firstPollDeadline), isTrue);
      expect(windowEnd.difference(windowStart), observationWindow);
      expect(frameworkError, isNull);
      if (mode == 'same owner') {
        expect(afterAckRatingReads, afterTransitionRatingReads + 2);
        expect(postRequests, hasLength(2));
        expect(ratingReadObservations.map((r) => r['phase']), [
          'eq.1',
          'eq.2',
          'eq.3',
        ]);
        expect(
          ratingReadObservations.map((r) => r['actor']),
          everyElement(_actor),
        );
        expect(
          ratingReadObservations.map((r) => r['rater_id']),
          everyElement('eq.$_actor'),
        );
        expect(
          find.text(expectedSummary),
          findsOneWidget,
          reason:
              'All three returned ratings must contribute their exact topics.',
        );
        expect(completionVisible, isTrue);
      } else {
        expect(
          afterAckRatingReads,
          afterTransitionRatingReads,
          reason:
              'Retired aggregate must not dispatch phase2 or phase3 under the next lifetime.',
        );
        expect(postRequests, isEmpty);
        expect(ratingReadObservations, hasLength(1));
        expect(completionVisible, isFalse);
        expect(summaryVisible, isFalse);
      }
      expect(
        count('/rest/v1/journey_family_answers', 'GET'),
        afterTransitionFamilyReads,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(supabase.auth.currentUser?.id, expectedActor);
      expect(ZyraAccountState.generation, currentGeneration);
      expect(
        ZyraAccountState.isCurrent(expectedActor, currentGeneration),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      expect(denied, isEmpty);
    });
  }
}
