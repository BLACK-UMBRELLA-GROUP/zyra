import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_first_tour_overlay.dart';
import 'package:zyra/dev/zyra_first_tour_steps.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/widgets/zyra_developer_title.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/main.dart' show supabase, ZyraApp;
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_app_lock.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/services/zyra_session_router.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/widgets/zyra_focus_dashboard.dart';
import 'package:zyra/dev/zyra_developer_inactivity_email.dart';
import 'package:zyra/widgets/zyra_account_session_host.dart';
import 'package:zyra/widgets/zyra_app_lock_gate.dart';

const _owner = ZyraInternalFounderPolicy.approvedFounderUserId;
const _project = ZyraInternalFounderPolicy.approvedSupabaseUrl;
const _member = 'ordinary-seeker-fixture';
const _captureRoot = ValueKey('line96-capture');
const _captures = String.fromEnvironment('ZYRA_LINE96_CAPTURE_DIR');
const _signupCaptures = String.fromEnvironment('ZYRA_LINE121_SHELL_OUTPUT');

Finder _key(String key) => find.byKey(ValueKey(key));

Map<String, Object?> _session({
  String user = _owner,
  String issuer = _project,
  String lifetime = 'synthetic-session-one',
  String? claim = 'founder',
  String? jwtClaim,
  int version = 0,
  int expiry = 4102444800,
}) {
  String part(Object data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  final metadata = {'zyra_role': ?claim};
  final claims = {
    'iss': '$issuer/auth/v1',
    'sub': user,
    'exp': expiry,
    'session_id': lifetime,
    'app_metadata': jwtClaim == null ? metadata : {'zyra_role': jwtClaim},
    'jti': 'fixture-$version',
  };
  return {
    'access_token': '${part({'alg': 'HS256'})}.${part(claims)}.${part([1])}',
    'refresh_token': 'synthetic-refresh-$version',
    'token_type': 'bearer',
    'user': {
      'id': user,
      'aud': 'authenticated',
      'email': 'sample-admin@example.org',
      'created_at': '2026-11-12T00:00:00Z',
      'app_metadata': metadata,
      'user_metadata': {'zyra_role': 'founder'},
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var refreshCalls = 0;
  var profileRole = 'seeker';
  var plan = 'seeker_basic';
  var currentIdentity = _owner;
  var readsAndWrites = <({String method, String path})>[];
  var respondToRefresh = (int version) async => _session(version: version);

  Future<void> initialize({String endpoint = _project}) => Supabase.initialize(
    url: endpoint,
    publishableKey: 'synthetic-test-only',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: false,
      detectSessionInUri: false,
      localStorage: EmptyLocalStorage(),
    ),
    httpClient: MockClient((request) async {
      final path = request.url.path;
      readsAndWrites.add((method: request.method, path: path));
      Object? response = const [];
      if (path == '/auth/v1/token') {
        response = await respondToRefresh(++refreshCalls);
      } else if (path == '/rest/v1/profiles' &&
          request.url.queryParameters['select'] ==
              'role,first_name,surname_line,gender,location_text') {
        response = [
          {
            'role': profileRole,
            'first_name': 'Sample Admin',
            'gender': 'male',
            'location_text': 'Leeds',
          },
        ];
      } else if (path == '/rest/v1/subscriptions') {
        response = [
          {'plan_type': plan, 'expires_at': null},
        ];
      } else if (path.endsWith('/ages_for_one')) {
        response = 29;
      }
      return http.Response(
        jsonEncode(response),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }),
  );

  Future<void> installSession(Map<String, Object?> session) async {
    await supabase.auth.setInitialSession(jsonEncode(session));
    await ZyraAccountState.synchronize(currentIdentity);
  }

  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/messages'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/events'),
      (_) async => null,
    );
    final font = FontLoader('PoppinsLine96');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await initialize();
  });

  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsLine96';
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.finishSignOut();
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    currentIdentity = _owner;
    await installSession(_session());
    refreshCalls = 0;
    profileRole = 'seeker';
    plan = 'seeker_basic';
    currentIdentity = _owner;
    readsAndWrites = [];
    respondToRefresh = (version) async =>
        _session(user: currentIdentity, version: version);
  });

  tearDown(() {
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraDeveloperSamples.instance.resetForAccountChange();
    ZyraAppLock.instance.clearForSignOut();
  });

  tearDownAll(() => Supabase.instance.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 8; frame++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  Future<GlobalKey<NavigatorState>> mount(
    WidgetTester tester, {
    Widget? homeOverride,
  }) async {
    final home = (await tester.runAsync(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        return await ZyraSessionRouter.resolveHome();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }))!;
    final navigator = GlobalKey<NavigatorState>();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          final source = _signupCaptures.isEmpty
              ? null
              : const ZyraApp().build(context) as ListenableBuilder;
          final app = source?.builder(context, null) as MaterialApp?;
          return MaterialApp(
            theme: app?.theme?.copyWith(platform: TargetPlatform.iOS),
            scrollBehavior: app?.scrollBehavior,
            debugShowCheckedModeBanner: false,
            navigatorKey: navigator,
            builder: (_, child) => ZyraDeveloperPanelSession(
              child: ZyraAppLockGate(
                child: ZyraAccountSessionHost(
                  navigatorKey: navigator,
                  child: MediaQuery(
                    data: MediaQueryData.fromView(tester.view).copyWith(
                      padding: const EdgeInsets.only(top: 59, bottom: 34),
                      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
                      disableAnimations: true,
                    ),
                    child: RepaintBoundary(key: _captureRoot, child: child!),
                  ),
                ),
              ),
            ),
            home: homeOverride ?? home,
          );
        },
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
    });
    return navigator;
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);
    expect(tester.takeException(), isNull);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (_captures.isEmpty && _signupCaptures.isEmpty) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_captureRoot),
      );
      final image = await boundary.toImage(
        pixelRatio: _signupCaptures.isEmpty ? 1 : 3,
      );
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${_signupCaptures.isEmpty ? _captures : _signupCaptures}/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settle(tester);
  }

  // LOCK 34 cases still check their own setup behavior after the mandatory
  // first-entry walkthrough has explicitly completed.
  Future<void> finishFirstTour(WidgetTester tester) async {
    expect(_key('first_tour_overlay'), findsOneWidget);
    for (var move = 0; move < 21; move++) {
      if (_key('first_tour_overlay').evaluate().isEmpty) break;
      await tap(tester, _key('first_tour_next'));
    }
    expect(_key('first_tour_overlay'), findsNothing);
  }

  Future<ZyraSignupPreviewController> signupReady(
    WidgetTester tester, {
    required bool guardian,
  }) async {
    await tap(tester, _key('dev_page_title'));
    await tap(tester, _key('dev_start_signup'));
    await tap(tester, _key('signup_apple'));
    final controller = tester
        .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
        .controller;
    controller.setGuardian(guardian);
    while (controller.step != ZyraSignupStep.verify) {
      await tap(tester, _key('signup_skip'));
    }
    await tap(tester, _key('signup_verify_later'));
    return controller;
  }

  Widget previewHome({
    ViewRequestDraftModel? model,
    int tab = 2,
    ZyraPreviewNavigationCheckpoint? checkpoint,
    ValueChanged<ZyraPreviewNavigationCheckpoint>? onCheckpoint,
  }) => ZyraDeveloperSeekerScope(
    preview: true,
    child: Builder(
      builder: (context) => ZyraOneJourneyConceptShell(
        canAct: () => ModalRoute.of(context)?.isCurrent == true,
        onExit: () {},
        initialTab: tab,
        initialCheckpoint: checkpoint,
        onCheckpoint: onCheckpoint,
        fixture: ZyraOneJourneyShellFixture(model: model),
      ),
    ),
  );

  Future<void> previewTab(WidgetTester tester, int index) async {
    tester
        .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
        .onTap(index);
    await settle(tester);
  }

  Future<void> openSampleConversation(WidgetTester tester) async {
    await tap(tester, _key('dev_active_1'));
    await tap(tester, _key('dev_journey_0'));
    final stage = ZyraJourneyStages.previewAll.indexWhere(
      (stage) => stage.value == 'conversation',
    );
    await tap(tester, _key('dev_stage_$stage'));
    await tap(tester, _key('dev_done'));
    final arrival = _key('concept_journey_arrival_continue');
    if (arrival.evaluate().isNotEmpty) await tap(tester, arrival);
    expect(_key('concept_message'), findsOneWidget);
  }

  testWidgets(
    'every inactivity email returns to My ZYRA with the correct kept or removed history',
    (tester) async {
      plan = 'seeker_premium';
      await mount(tester, homeOverride: previewHome());
      for (var number = 1; number <= 5; number++) {
        await tap(tester, _key('dev_page_title'));
        await tap(tester, _key('dev_notice_$number'));
        await tap(tester, _key('dev_done'));
        final email = tester.widget<ZyraDeveloperInactivityEmail>(
          find.byType(ZyraDeveloperInactivityEmail),
        );
        expect(email.number, number);
        await tap(tester, _key('dev_page_title'));
        email.onOpen!();
        await settle(tester);
        expect(ZyraDeveloperSamples.instance.notice, number);
        expect(find.byType(ZyraDeveloperInactivityEmail), findsOneWidget);
        await tap(tester, _key('dev_done'));
        tester
            .widget<ZyraDeveloperInactivityEmail>(
              find.byType(ZyraDeveloperInactivityEmail),
            )
            .onOpen!();
        await settle(tester);
        expect(find.byType(ZyraDeveloperInactivityEmail), findsNothing);
        expect(find.byType(ZyraFocusDashboard), findsOneWidget);
        expect(ZyraDeveloperSamples.instance.notice, number < 5 ? 6 : 0);
        expect(ZyraDeveloperSamples.instance.ended, number < 5 ? 2 : 0);
        expect(
          find.text('Welcome back, Adam'),
          number < 5 ? findsOneWidget : findsNothing,
        );
      }
      await dispose(tester);
    },
  );

  testWidgets(
    'all My ZYRA presets include LOCK 34 setup continuation where required',
    (tester) async {
      plan = 'seeker_premium';
      await mount(tester, homeOverride: previewHome());
      for (final example in [
        (index: 1, needs: 2, chips: 3),
        (index: 3, needs: 15, chips: 5),
        (index: 2, needs: 1, chips: 3),
        (index: 0, needs: 0, chips: 1),
      ]) {
        await tap(tester, _key('dev_page_title'));
        await tap(tester, _key('dev_preset_${example.index}'));
        await tap(tester, _key('dev_done'));
        final dashboard = tester.widget<ZyraFocusDashboard>(
          find.byType(ZyraFocusDashboard),
        );
        expect(dashboard.items.length, example.needs);
        expect(dashboard.chips.length, example.chips);
        expect(
          dashboard.items.any((item) => item.title == 'Finish setting up'),
          example.index == 2 || example.index == 3,
        );
      }
      await dispose(tester);
    },
  );

  testWidgets(
    'missing membership uses local Seeker One and Clear returns to it',
    (tester) async {
      plan = 'unavailable';
      await mount(tester);
      await tap(tester, _key('dev_page_title'));
      expect(
        find.textContaining('Viewing as Seeker One · real plan: none'),
        findsOneWidget,
      );
      expect(ZyraDeveloperSamples.instance.viewAs?.name, 'seekerOne');
      await tap(tester, _key('dev_view_as_3'));
      await tap(tester, _key('dev_clear'));
      expect(ZyraDeveloperSamples.instance.viewAs?.name, 'seekerOne');
      expect(ZyraDeveloperSamples.instance.setupUnfinished, isFalse);
      expect(
        find.textContaining('Viewing as Seeker One · real plan: none'),
        findsOneWidget,
      );
      await tap(tester, _key('dev_done'));
      expect(AppState.instance.verifiedSeekerPlan, isNull);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      await dispose(tester);
    },
  );

  testWidgets(
    'panel proof and View as preserve unselected native request state',
    (tester) async {
      plan = 'seeker_premium';
      final native = ViewRequestDraftModel(capacity: 3);
      expect(native.seedReceived('draft-amira'), isTrue);
      await mount(tester, homeOverride: previewHome(model: native));
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(ZyraDeveloperSamples.instance.hasSamples, isFalse);
      expect(find.text('Journey request from Amira'), findsOneWidget);
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_done'));
      expect(find.text('Journey request from Amira'), findsOneWidget);
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_view_as_0'));
      await tap(tester, _key('dev_done'));
      expect(ZyraDeveloperSamples.instance.received, isNull);
      expect(find.text('Journey request from Amira'), findsOneWidget);
      expect(native.stateFor('draft-amira'), DraftJourneyState.received);
      await dispose(tester);
    },
  );

  testWidgets(
    'owned nested title admits current editor and rejects covered callbacks',
    (tester) async {
      plan = 'seeker_premium';
      final navigator = await mount(tester, homeOverride: previewHome(tab: 4));
      await tap(tester, _key('concept_edit_profile'));
      final owned = tester.widget<ZyraDeveloperOwnedNavigatorScope>(
        find.byType(ZyraDeveloperOwnedNavigatorScope),
      );
      expect(_key('dev_page_title'), findsOneWidget);
      await tap(tester, _key('dev_page_title'));
      expect(_key('dev_panel'), findsOneWidget);
      await tap(tester, _key('dev_done'));
      final stale = tester
          .widget<GestureDetector>(_key('dev_page_title'))
          .onTap!;
      final before = refreshCalls;
      unawaited(
        owned.navigatorKey.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Nested cover')),
          ),
        ),
      );
      await settle(tester);
      stale();
      await settle(tester);
      expect(refreshCalls, before);
      expect(_key('dev_panel'), findsNothing);
      owned.navigatorKey.currentState!.pop();
      await settle(tester);
      final rootCovered = tester
          .widget<GestureDetector>(_key('dev_page_title'))
          .onTap!;
      unawaited(
        navigator.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Root cover')),
          ),
        ),
      );
      await settle(tester);
      rootCovered();
      await settle(tester);
      expect(refreshCalls, before);
      expect(_key('dev_panel'), findsNothing);
      navigator.currentState!.pop();
      await settle(tester);
      await tap(tester, _key('dev_page_title'));
      expect(_key('dev_panel'), findsOneWidget);
      await tap(tester, _key('dev_done'));
      await dispose(tester);
    },
  );

  testWidgets(
    'Clear discards conversation samples and restores colliding native history',
    (tester) async {
      plan = 'seeker_premium';
      final native = ViewRequestDraftModel(capacity: 3);
      expect(
        native.replacePreviewJourneys([
          (profileId: 'draft-sara', stage: 'phase_1'),
        ]),
        isTrue,
      );
      expect(native.end('draft-sara'), isTrue);
      final original = native.snapshot();
      await mount(tester, homeOverride: previewHome(model: native));
      await tap(tester, _key('dev_page_title'));
      await openSampleConversation(tester);
      // A fixed Sara sample replaces a colliding ended state only in its own
      // working model; the native fixture and archive remain untouched.
      expect(native.stateFor('draft-sara'), DraftJourneyState.ended);
      expect(native.snapshot().endedAttempts, original.endedAttempts);
      await tester.ensureVisible(_key('concept_message'));
      await tester.enterText(_key('concept_message'), 'line123 sample marker');
      await tap(tester, _key('concept_send_message'));
      expect(find.text('You · line123 sample marker'), findsOneWidget);
      await tester.enterText(_key('concept_message'), 'line123 unsent marker');
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_clear'));
      await tap(tester, _key('dev_done'));
      expect(ZyraDeveloperSamples.instance.hasSamples, isFalse);
      await previewTab(tester, 1);
      expect(find.text('No Journey yet'), findsOneWidget);
      await tap(tester, _key('dev_page_title'));
      await openSampleConversation(tester);
      expect(find.text('You · line123 sample marker'), findsNothing);
      expect(
        tester.widget<TextField>(_key('concept_message')).controller!.text,
        isEmpty,
      );
      await dispose(tester);
    },
  );

  testWidgets(
    'ordinary Seeker title opens the Basic panel after explicit refresh',
    (tester) async {
      await mount(tester);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(ZyraInternalPreviewClient.isActive, isFalse);
      expect(find.text('My ZYRA'), findsOneWidget);
      expect(_key('dev_page_title'), findsOneWidget);
      final before = refreshCalls;
      await tap(tester, find.text('My ZYRA'));
      expect(refreshCalls, before + 1);
      expect(_key('dev_panel'), findsOneWidget);
      expect(find.textContaining('Seeker Basic'), findsWidgets);
      expect(find.text('Seeker Basic has 1 place'), findsOneWidget);
      readsAndWrites.clear();
      final telemetry =
          ZyraProductTelemetry.instance.snapshot.sessionEventCount;
      await tap(tester, _key('dev_active_2'));
      expect(ZyraDeveloperSamples.instance.active, isNull);
      await tap(tester, _key('dev_active_1'));
      await tap(tester, _key('dev_ended_2'));
      await tap(tester, _key('dev_received_3'));
      await tap(tester, _key('dev_sent_2'));
      await tap(tester, _key('dev_past_2'));
      await tap(tester, _key('dev_introductions_2'));
      expect(ZyraDeveloperSamples.instance.active, 1);
      expect(ZyraDeveloperSamples.instance.ended, 2);
      expect(ZyraDeveloperSamples.instance.received, 3);
      expect(ZyraDeveloperSamples.instance.sent, 2);
      expect(ZyraDeveloperSamples.instance.introductions, 2);
      await capture(tester, 'line96_ordinary_basic_panel');
      await tap(tester, _key('dev_done'));
      expect(find.text('1 of 1 place in use'), findsOneWidget);
      expect(find.byKey(const ValueKey('dev_founder_preview')), findsOneWidget);
      final requests = find.text('Journey\nrequests');
      expect(requests, findsOneWidget);
      await tap(tester, requests);
      expect(find.text('Received'), findsOneWidget);
      expect(_key('dev_page_title'), findsOneWidget);
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_clear'));
      expect(ZyraDeveloperSamples.instance.hasSamples, isFalse);
      await tap(tester, _key('dev_done'));
      expect(_key('dev_panel'), findsNothing);
      expect(
        readsAndWrites.where(
          (call) => call.method != 'GET' && call.path != '/auth/v1/token',
        ),
        isEmpty,
      );
      expect(
        ZyraProductTelemetry.instance.snapshot.sessionEventCount,
        telemetry,
      );
      await dispose(tester);
    },
  );

  testWidgets('offstage and covered title callbacks cannot open the panel', (
    tester,
  ) async {
    final navigator = await mount(tester);
    final titleTap = tester
        .widget<GestureDetector>(_key('dev_page_title'))
        .onTap!;
    final before = refreshCalls;
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover')),
        ),
      ),
    );
    await settle(tester);
    titleTap();
    await settle(tester);
    expect(refreshCalls, before);
    expect(_key('dev_panel'), findsNothing);
    navigator.currentState!.pop();
    await settle(tester);

    final delayed = Completer<void>();
    respondToRefresh = (version) async {
      await delayed.future;
      return _session(version: version);
    };
    await tester.tap(find.text('My ZYRA'));
    await settle(tester);
    await tester.tapAt(tester.getCenter(_key('floating-nav-item-4')));
    await settle(tester);
    expect(find.text('My ZYRA').hitTestable(), findsNothing);
    expect(_key('dev_panel'), findsNothing);
    await tester.tapAt(tester.getCenter(_key('floating-nav-item-2')));
    await settle(tester);
    expect(find.text('My ZYRA'), findsOneWidget);
    delayed.complete();
    await settle(tester);
    expect(_key('dev_panel'), findsNothing);
    expect(_key('dev_page_title'), findsOneWidget);
    await tap(tester, find.text('My ZYRA'));
    expect(_key('dev_panel'), findsOneWidget);
    await tap(tester, _key('dev_done'));
    await dispose(tester);
  });

  testWidgets(
    'Guardian role has no title affordance even with the pinned claim',
    (tester) async {
      profileRole = 'wali';
      await mount(tester);
      expect(find.byType(WaliHomeShell), findsOneWidget);
      expect(_key('dev_page_title'), findsNothing);
      expect(ZyraDeveloperSamples.instance.isAuthorized, isFalse);
      await dispose(tester);
    },
  );

  testWidgets('sign-out intent clears the overlay and removes only its sheet', (
    tester,
  ) async {
    final navigator = await mount(tester);
    await tap(tester, find.text('My ZYRA'));
    await tap(tester, _key('dev_received_3'));
    expect(ZyraDeveloperSamples.instance.received, 3);
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Independent route')),
        ),
      ),
    );
    await settle(tester);
    await tester.runAsync(ZyraAccountState.beginSignOut);
    await settle(tester);
    expect(_key('dev_panel'), findsNothing);
    expect(find.text('Independent route'), findsOneWidget);
    navigator.currentState!.pop();
    await settle(tester);
    expect(_key('dev_panel'), findsNothing);
    expect(ZyraDeveloperSamples.instance.hasSamples, isFalse);
    expect(_key('dev_page_title'), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
    await dispose(tester);
  });

  final samples = ZyraDeveloperSamples.instance;

  testWidgets(
    'LOCK 2 V4 sample archive keeps shell navigation and revokes on Clear',
    (tester) async {
      plan = 'seeker_premium';
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await mount(
        tester,
        homeOverride: previewHome(
          model: ViewRequestDraftModel(capacity: 3),
          onCheckpoint: (value) => checkpoint = value,
        ),
      );
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_ended_3'));
      await tap(tester, _key('dev_done'));
      expect(samples.endedRows, hasLength(3));
      final row = samples.endedRows!.first;
      expect(row.person.firstName, 'Zainab');
      await tap(tester, _key('concept-my-ended'));
      await tap(tester, _key('sample-ended-${row.id}-header'));
      await tap(tester, find.text('View Timeline'));
      expect(checkpoint!.pages.last, 'ended_archive');
      expect(find.text('Journey with Zainab'), findsOneWidget);
      expect(_key('compact-nav-surface'), findsOneWidget);
      expect(find.byType(ZyraEndedJourneyArchivePresentation), findsOneWidget);
      for (final label in ['Timeline', 'Journey Bio', 'Guardians']) {
        expect(find.text(label), findsOneWidget);
      }
      final retained = tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text('Timeline'),
              matching: find.byType(ListTile),
            ),
          )
          .onTap!;
      samples.clear();
      await settle(tester);
      expect(find.byType(ZyraEndedJourneyArchivePresentation), findsNothing);
      expect(find.text('Journey with Zainab'), findsNothing);
      final afterClear = List<String>.of(checkpoint!.pages);
      retained();
      await settle(tester);
      expect(checkpoint!.pages, afterClear);
      expect(find.byType(ZyraEndedJourneyArchivePresentation), findsNothing);
      await dispose(tester);
    },
  );

  Future<void> openSampleRequests(WidgetTester tester) async {
    final dashboardLink = find.text('Journey\nrequests');
    await tap(tester, dashboardLink);
  }

  for (final requests in [true, false]) {
    testWidgets(
      'sample ${requests ? 'Journey requests' : 'Journey'} title opens after a delayed refresh',
      (tester) async {
        await mount(tester);
        await tap(tester, find.text('My ZYRA'));
        await tap(tester, _key('dev_active_1'));
        await tap(tester, _key('dev_received_1'));
        if (!requests) await tap(tester, _key('dev_journey_0'));
        await tap(tester, _key('dev_done'));

        if (requests) {
          await openSampleRequests(tester);
        }

        final title = find.text(
          requests
              ? 'Journey requests'
              : 'Journey with ${samples.activeRows!.single.person.firstName}',
        );
        final sampleContent = requests
            ? _key('sample-request-true-draft-amira-header')
            : _key('concept_journey_${samples.activeRows!.single.person.id}');
        expect(title, findsOneWidget);
        expect(sampleContent, findsOneWidget);

        final delayed = Completer<void>();
        respondToRefresh = (version) async {
          await delayed.future;
          return _session(version: version);
        };
        final before = refreshCalls;
        // tap() pumps frames while the mock response is still outstanding.
        await tap(tester, title);
        expect(refreshCalls, before + 1);
        expect(_key('dev_panel'), findsNothing);
        expect(title, findsOneWidget);
        expect(sampleContent, findsOneWidget);

        delayed.complete();
        await settle(tester);
        expect(_key('dev_panel'), findsOneWidget);
        await tap(tester, _key('dev_done'));
        expect(title, findsOneWidget);
        expect(sampleContent, findsOneWidget);
        expect(samples.received, 1);
        expect(samples.active, 1);
        await dispose(tester);
      },
    );
  }

  void resume(WidgetTester tester) {
    final binding = tester.binding;
    if (binding.lifecycleState == AppLifecycleState.paused) {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    }
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  void suspend(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  }

  for (final expires in [false, true]) {
    testWidgets(
      expires
          ? 'sample requests lose access when the old proof expires during refresh'
          : 'sample requests lose access on title refresh timeout until explicit reproof',
      (tester) async {
        await mount(tester);
        await tap(tester, find.text('My ZYRA'));
        await tap(tester, _key('dev_received_1'));
        await tap(tester, _key('dev_done'));
        await openSampleRequests(tester);

        final title = find.text('Journey requests');
        final row = _key('sample-request-true-draft-amira-header');
        if (expires) {
          respondToRefresh = (version) async {
            // The SDK counts a token as expired 30 seconds before its exp.
            final deadline = DateTime.now().add(const Duration(seconds: 37));
            return _session(
              version: version,
              expiry: deadline.millisecondsSinceEpoch ~/ 1000,
            );
          };
          await tap(tester, title);
          await tap(tester, _key('dev_done'));
        }

        final delayed = Completer<void>();
        respondToRefresh = (version) async {
          await delayed.future;
          return _session(version: version);
        };
        final before = refreshCalls;
        await tap(tester, title);
        expect(refreshCalls, before + 1);
        expect(row, findsOneWidget);

        // The expiry case reaches the old proof's timer before the timeout.
        await tester.pump(Duration(seconds: expires ? 8 : 10));
        expect(row, findsNothing);
        expect(samples.isAuthorized, isFalse);
        expect(_key('dev_panel'), findsNothing);

        delayed.complete();
        await settle(tester);
        expect(row, findsNothing);
        expect(_key('dev_panel'), findsNothing);
        expect(samples.isAuthorized, isFalse);

        suspend(tester);
        resume(tester);
        await settle(tester);
        expect(refreshCalls, before + 2);
        expect(row, findsOneWidget);
        expect(_key('dev_panel'), findsNothing);
        await dispose(tester);
      },
    );
  }

  Future<void> lock(WidgetTester tester) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      (_) async => true,
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/local_auth'),
        null,
      ),
    );
    final enabled = await tester.runAsync(
      () => ZyraAppLock.instance.setEnabled(true),
    );
    expect(enabled, isTrue);
    suspend(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(samples.isAuthorized, isFalse);
    await settle(tester);
    expect(find.byType(ZyraAccountSessionHost), findsNothing);
    expect(find.text('Locked'), findsOneWidget);
  }

  testWidgets(
    'App Lock teardown restores choices only after same-session proof',
    (tester) async {
      await mount(tester);
      await tap(tester, find.text('My ZYRA'));
      await tap(tester, _key('dev_received_3'));
      final heldAction = tester
          .widget<TextButton>(_key('dev_received_2'))
          .onPressed!;
      final lease = samples.generation;
      final before = refreshCalls;
      await lock(tester);
      expect(samples.isCurrentLease(lease), isFalse);
      expect(samples.receivedRows, isNull);
      expect(_key('dev_panel'), findsNothing);
      final delayed = Completer<void>();
      respondToRefresh = (version) async {
        await delayed.future;
        return _session(version: version);
      };
      resume(tester);
      await settle(tester);
      expect(samples.isAuthorized, isFalse);
      expect(refreshCalls, before + 1);
      delayed.complete();
      await settle(tester);
      expect(samples.received, 3);
      heldAction();
      expect(samples.received, 3);
      expect(samples.isCurrentLease(lease), isFalse);
      await dispose(tester);
    },
  );

  testWidgets('unlock waits for a retired refresh then reproofs once', (
    tester,
  ) async {
    await mount(tester);
    await tap(tester, find.text('My ZYRA'));
    await tap(tester, _key('dev_received_3'));
    await tap(tester, _key('dev_done'));
    final before = refreshCalls;
    final retired = Completer<void>();
    final fresh = Completer<void>();
    respondToRefresh = (version) async {
      await (version == before + 1 ? retired : fresh).future;
      return _session(version: version);
    };
    await tap(tester, find.text('My ZYRA'));
    expect(refreshCalls, before + 1);
    await lock(tester);
    resume(tester);
    await settle(tester);
    expect(refreshCalls, before + 1);
    retired.complete();
    await settle(tester);
    expect(refreshCalls, before + 2);
    expect(_key('dev_page_title'), findsNothing);
    expect(samples.receivedRows, isNull);
    fresh.complete();
    await settle(tester);
    expect(samples.received, 3);
    expect(refreshCalls, before + 2);
    expect(_key('dev_panel'), findsNothing);
    await dispose(tester);
  });

  testWidgets(
    'temporary refresh error suspends choices until explicit reproof',
    (tester) async {
      await mount(tester);
      await tap(tester, find.text('My ZYRA'));
      await tap(tester, _key('dev_received_3'));
      final lease = samples.generation;
      final before = refreshCalls;
      suspend(tester);
      expect(samples.isCurrentLease(lease), isFalse);
      // A response the SDK cannot decode produces a non-terminal auth error
      // without exercising its separate network retry/backoff policy.
      respondToRefresh = (_) async => {'access_token': 'malformed-fixture'};
      resume(tester);
      await settle(tester);
      expect(refreshCalls, before + 1);
      expect(_key('dev_panel'), findsNothing);
      expect(_key('dev_page_title'), findsNothing);
      expect(samples.receivedRows, isNull);

      respondToRefresh = (version) async => _session(version: version);
      await tester.runAsync(() => supabase.auth.refreshSession());
      await settle(tester);
      expect(refreshCalls, before + 2);
      expect(_key('dev_page_title'), findsNothing);
      expect(samples.receivedRows, isNull);
      suspend(tester);
      resume(tester);
      await settle(tester);
      expect(refreshCalls, before + 3);
      expect(samples.received, 3);
      expect(samples.isCurrentLease(lease), isFalse);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      await dispose(tester);
    },
  );

  testWidgets('claim denial empties choices even after same-session reproof', (
    tester,
  ) async {
    await mount(tester);
    await tap(tester, find.text('My ZYRA'));
    await tap(tester, _key('dev_received_3'));
    await tap(tester, _key('dev_done'));
    respondToRefresh = (version) async =>
        _session(claim: null, version: version);
    await tap(tester, find.text('My ZYRA'));
    expect(_key('dev_panel'), findsNothing);
    expect(_key('dev_page_title'), findsNothing);
    expect(samples.hasSamples, isFalse);
    respondToRefresh = (version) async => _session(version: version);
    suspend(tester);
    resume(tester);
    await settle(tester);
    expect(_key('dev_page_title'), findsOneWidget);
    expect(samples.receivedRows, isNull);
    expect(samples.hasSamples, isFalse);
    await dispose(tester);
  });

  for (final signOut in [true, false]) {
    testWidgets(
      signOut
          ? 'sign-out from App Lock wipes choices even after same-session proof'
          : 'same-account SDK session replacement while locked wipes choices',
      (tester) async {
        await mount(tester);
        await tap(tester, find.text('My ZYRA'));
        await tap(tester, _key('dev_received_3'));
        await lock(tester);
        if (signOut) {
          final nextGeneration = ZyraAccountState.generation + 1;
          // Account reset is immediate even though remote cleanup is async.
          await tester.runAsync(() async {
            debugDefaultTargetPlatformOverride = TargetPlatform.linux;
            try {
              final signingOut = ZyraAuth.signOut();
              expect(ZyraAccountState.generation, nextGeneration);
              await signingOut;
            } finally {
              debugDefaultTargetPlatformOverride = null;
            }
          });
          await tester.runAsync(() => installSession(_session(version: 90)));
        } else {
          await tester.runAsync(() async {
            await supabase.auth.setInitialSession(
              jsonEncode(
                _session(lifetime: 'replacement-session', version: 90),
              ),
            );
            await Future<void>.delayed(Duration.zero);
            await supabase.auth.setInitialSession(
              jsonEncode(_session(version: 91)),
            );
          });
        }
        resume(tester);
        await settle(tester);
        expect(_key('dev_page_title'), findsOneWidget);
        expect(samples.receivedRows, isNull);
        expect(samples.activeRows, isNull);
        expect(samples.unverified, isFalse);
        expect(samples.setupUnfinished, isFalse);
        expect(samples.preset, isNull);
        expect(samples.notice, 0);
        if (AppState.instance.verifiedSeekerPlan == null) {
          // Q173: a new session with no hydrated real plan starts afresh in
          // local Seeker One; none of the retired session's choices survive.
          expect(samples.viewAs?.name, 'seekerOne');
        } else {
          expect(samples.hasSamples, isFalse);
        }
        await dispose(tester);
      },
    );
  }

  for (final pinned in [true, false]) {
    testWidgets(
      pinned
          ? 'pinned Seeker without claim has no Developer UI'
          : 'other Seeker with claim has no Developer UI',
      (tester) async {
        currentIdentity = pinned ? _owner : _member;
        respondToRefresh = (version) async => _session(
          user: currentIdentity,
          claim: pinned ? null : 'founder',
          version: version,
        );
        await tester.runAsync(
          () => installSession(
            _session(user: currentIdentity, claim: pinned ? null : 'founder'),
          ),
        );
        await mount(tester);
        expect(find.byType(HomeShell), findsOneWidget);
        final title = find.text('My ZYRA');
        final semantics = tester.ensureSemantics();
        expect(tester.getSemantics(title).getSemanticsData().actions, 0);
        semantics.dispose();
        await tap(tester, title);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith('dev_'),
          ),
          findsNothing,
        );
        await dispose(tester);
      },
    );
  }

  test('a token event alone never publishes panel authority', () async {
    final access = ZyraDeveloperPanelAccess();
    addTearDown(access.dispose);
    access.observe(
      AuthState(AuthChangeEvent.tokenRefreshed, supabase.auth.currentSession),
    );
    expect(access.email, isNull);
    expect(refreshCalls, 0);
  });

  for (final (name, response) in <(String, Map<String, Object?> Function(int))>[
    ('replayed session', (_) => _session()),
    ('wrong principal', (version) => _session(user: _member, version: version)),
    (
      'wrong issuer',
      (version) => _session(issuer: 'https://wrong.invalid', version: version),
    ),
    (
      'wrong session',
      (version) => _session(lifetime: 'different-session', version: version),
    ),
    ('stale session', (version) => _session(expiry: 1, version: version)),
    ('missing claim', (version) => _session(claim: null, version: version)),
    ('wrong claim', (version) => _session(claim: 'admin', version: version)),
    (
      'wrong JWT claim',
      (version) => _session(jwtClaim: 'admin', version: version),
    ),
  ]) {
    test('explicit refresh denies $name', () async {
      respondToRefresh = (version) async => response(version);
      final access = ZyraDeveloperPanelAccess();
      addTearDown(access.dispose);
      expect(await access.verify(), isFalse);
      expect(access.email, isNull);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(ZyraInternalPreviewClient.isActive, isFalse);
    });
  }

  test('wrong actual project is rejected with no refresh', () async {
    await Supabase.instance.dispose();
    await initialize(endpoint: 'https://wrong.invalid');
    try {
      await installSession(_session());
      final access = ZyraDeveloperPanelAccess();
      addTearDown(access.dispose);
      expect(await access.verify(), isFalse);
      expect(refreshCalls, 0);
    } finally {
      await Supabase.instance.dispose();
      await initialize();
    }
  });

  test(
    'account change before refresh starts retires the captured session',
    () async {
      final access = ZyraDeveloperPanelAccess();
      addTearDown(access.dispose);
      final verification = access.verify();
      await ZyraAccountState.synchronize(_member);
      expect(await verification, isFalse);
      expect(refreshCalls, 0);
      expect(access.email, isNull);
    },
  );

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    testWidgets(
      'LOCK 36 $role first entry visits every page once and Replay returns to Settings',
      (tester) async {
        plan = 'seeker_premium';
        await mount(tester);
        final signup = await signupReady(tester, guardian: guardian);
        final callsBeforeEntry = readsAndWrites.length;
        await tap(tester, _key('signup_look_around'));
        expect(_key('first_tour_overlay'), findsOneWidget);
        expect(find.text('Hi ${signup.firstName}, welcome'), findsOneWidget);
        expect(find.text('Skip'), findsNothing);
        final steps = guardian ? zyraGuardianTourSteps : zyraSeekerTourSteps;
        final welcomeNext = tester
            .widget<ZyraFirstTourOverlay>(find.byType(ZyraFirstTourOverlay))
            .onNext;
        await tap(tester, _key('first_tour_next'));
        welcomeNext();
        await settle(tester);
        expect(
          tester
              .widget<ZyraFirstTourOverlay>(find.byType(ZyraFirstTourOverlay))
              .index,
          1,
        );

        for (var index = 0; index < steps.length; index++) {
          final step = steps[index];
          final overlay = tester.widget<ZyraFirstTourOverlay>(
            find.byType(ZyraFirstTourOverlay),
          );
          expect(overlay.guardian, guardian);
          expect(overlay.index, index + 1);
          expect(
            find.descendant(
              of: _key('first_tour_overlay'),
              matching: find.text(step.title),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: _key('first_tour_overlay'),
              matching: find.text(step.body),
            ),
            findsOneWidget,
          );
          expect(
            tester
                .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
                .currentIndex,
            step.tab,
          );
          if (!guardian && index == 5) {
            expect(_key('journey_tab_empty_title'), findsOneWidget);
            expect(overlay.targetRect('journey_tab_browse'), isNotNull);
          }
          if (guardian && index == 4) {
            expect(overlay.targetRect('guardian_journey'), isNull);
            expect(_key('first_tour_target'), findsOneWidget);
          }
          await tap(tester, _key('first_tour_next'));
        }
        expect(
          find.text('That’s everything, ${signup.firstName}'),
          findsOneWidget,
        );
        await tap(tester, _key('first_tour_next'));
        expect(_key('first_tour_overlay'), findsNothing);
        expect(_key('signup_continue_setup'), findsOneWidget);
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .currentIndex,
          2,
        );
        expect(
          readsAndWrites
              .skip(callsBeforeEntry)
              .where((call) => call.method != 'GET'),
          isEmpty,
        );

        await previewTab(tester, 4);
        await tap(tester, _key('concept_settings'));
        final settings = tester.widget<ZyraConceptSettingsPresentation>(
          find.byType(ZyraConceptSettingsPresentation),
        );
        await tester.drag(
          _key('concept-current-settings-scroll'),
          const Offset(0, -480),
        );
        await settle(tester);
        await tap(tester, _key('concept_settings_replayWalkthrough'));
        expect(find.text('Hi ${signup.firstName}, welcome'), findsOneWidget);
        settings.onAction(ZyraConceptAccountAction.membership);
        await settle(tester);
        expect(
          tester
              .widget<ZyraFirstTourOverlay>(find.byType(ZyraFirstTourOverlay))
              .index,
          0,
        );
        await tap(tester, _key('first_tour_next'));
        final viewport = tester.getRect(_key('first_tour_overlay'));
        await tester.tapAt(Offset(viewport.left + 20, viewport.center.dy));
        await settle(tester);
        expect(find.text('Hi ${signup.firstName}, welcome'), findsOneWidget);
        await finishFirstTour(tester);
        expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
        tester
            .widget<ZyraPullDownBackScope>(_key('concept_pull_down_back_scope'))
            .onBack();
        await settle(tester);
        expect(_key('concept_profile_title'), findsOneWidget);
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .currentIndex,
          4,
        );

        // Rebuilding the protected host and repeating detached signup must not
        // forget this bound account's already claimed first-entry receipt.
        await dispose(tester);
        await mount(tester);
        await signupReady(tester, guardian: guardian);
        await tap(tester, _key('signup_look_around'));
        expect(_key('first_tour_overlay'), findsNothing);
        expect(_key('signup_continue_setup'), findsOneWidget);
        await dispose(tester);
      },
    );
  }

  testWidgets(
    'LOCK 36 completed first signup clears old sample Journeys before its mandatory tour',
    (tester) async {
      plan = 'seeker_premium';
      final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
      expect(model.occupiedCount, 1);
      await mount(tester, homeOverride: previewHome(model: model));
      final signup = await signupReady(tester, guardian: false);
      signup.setPreviewVerified(true);
      await tap(tester, _key('signup_finish_setup'));
      await tap(tester, _key('signup_preferences_next'));
      await tap(tester, _key('signup_continue'));
      await tap(tester, _key('signup_continue'));
      expect(signup.step, ZyraSignupStep.allSet);
      await tap(tester, _key('signup_enter'));
      expect(signup.setupComplete, isTrue);
      expect(model.occupiedCount, 0);
      expect(_key('first_tour_overlay'), findsOneWidget);
      for (var move = 0; move < 4; move++) {
        await tap(tester, _key('first_tour_next'));
      }
      final overlay = tester.widget<ZyraFirstTourOverlay>(
        find.byType(ZyraFirstTourOverlay),
      );
      expect(overlay.index, 4);
      final request = overlay.targetRect('tour_profiles_request');
      expect(request, isNotNull);
      final states = model.snapshot().states;
      await tester.tapAt(
        tester.getTopLeft(_key('first_tour_overlay')) + request!.center,
      );
      await settle(tester);
      expect(
        tester
            .widget<ZyraFirstTourOverlay>(find.byType(ZyraFirstTourOverlay))
            .index,
        5,
      );
      expect(model.snapshot().states, states);
      await finishFirstTour(tester);
      expect(_key('signup_continue_setup'), findsNothing);
      await previewTab(tester, 1);
      expect(_key('journey_tab_empty_title'), findsOneWidget);
      await dispose(tester);
    },
  );

  testWidgets(
    'LOCK 36 a completed tour callback cannot advance the same index in Replay',
    (tester) async {
      plan = 'seeker_premium';
      await mount(tester);
      final signup = await signupReady(tester, guardian: false);
      await tap(tester, _key('signup_look_around'));
      final retiredNext = tester
          .widget<ZyraFirstTourOverlay>(find.byType(ZyraFirstTourOverlay))
          .onNext;
      await finishFirstTour(tester);
      await previewTab(tester, 4);
      await tap(tester, _key('concept_settings'));
      await tester.drag(
        _key('concept-current-settings-scroll'),
        const Offset(0, -480),
      );
      await settle(tester);
      await tap(tester, _key('concept_settings_replayWalkthrough'));
      final currentNext = tester
          .widget<ZyraFirstTourOverlay>(find.byType(ZyraFirstTourOverlay))
          .onNext;
      retiredNext();
      await settle(tester);
      expect(
        tester
            .widget<ZyraFirstTourOverlay>(find.byType(ZyraFirstTourOverlay))
            .index,
        0,
      );
      expect(find.text('Hi ${signup.firstName}, welcome'), findsOneWidget);
      currentNext();
      await settle(tester);
      expect(
        tester
            .widget<ZyraFirstTourOverlay>(find.byType(ZyraFirstTourOverlay))
            .index,
        1,
      );
      expect(find.text('This is Profiles'), findsOneWidget);
      await dispose(tester);
    },
  );

  testWidgets('LOCK 36 retired owner cannot advance a captured tour callback', (
    tester,
  ) async {
    plan = 'seeker_premium';
    await mount(tester);
    await signupReady(tester, guardian: false);
    await tap(tester, _key('signup_look_around'));
    final next = tester
        .widget<ZyraFirstTourOverlay>(find.byType(ZyraFirstTourOverlay))
        .onNext;
    await tester.runAsync(() => ZyraAccountState.synchronize(_member));
    await settle(tester);
    final callsBefore = readsAndWrites.length;
    next();
    await settle(tester);
    expect(_key('first_tour_note'), findsNothing);
    expect(readsAndWrites.length, callsBefore);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('LOCK 34 Start sign-up is local and paused accounts are gated', (
    tester,
  ) async {
    plan = 'seeker_premium';
    await mount(tester, homeOverride: previewHome());
    await tap(tester, _key('dev_page_title'));
    await tap(tester, _key('dev_start_signup'));
    expect(_key('signup_welcome'), findsOneWidget);
    final callsBefore = readsAndWrites.length;
    await tap(tester, _key('signup_apple'));
    final c = tester
        .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
        .controller;
    while (c.step != ZyraSignupStep.verify) {
      await tap(tester, _key('signup_skip'));
    }
    await tap(tester, _key('signup_verify_later'));
    expect(c.verified, isFalse);
    await tap(tester, _key('signup_look_around'));
    await finishFirstTour(tester);
    expect(_key('signup_continue_setup'), findsOneWidget);
    await capture(tester, 's30_paused__my_zyra_needs_you');
    await previewTab(tester, 0);
    expect(find.text('Every person on ZYRA is verified'), findsOneWidget);
    await capture(tester, 's31_gate__unverified_profiles');
    expect(readsAndWrites.length, callsBefore);
    expect(ZyraDeveloperSamples.instance.setupUnfinished, isTrue);
    await dispose(tester);
  });

  testWidgets('LOCK 34 progress long press freshly admits Developer', (
    tester,
  ) async {
    await mount(tester, homeOverride: previewHome());
    await tap(tester, _key('dev_page_title'));
    await tap(tester, _key('dev_start_signup'));
    await tap(tester, _key('signup_apple'));
    final c = tester
        .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
        .controller;
    final coveredContinue = tester
        .widget<FilledButton>(_key('signup_continue'))
        .onPressed!;
    final before = refreshCalls;
    await tester.longPress(_key('signup_progress'));
    await settle(tester);
    expect(_key('dev_panel'), findsOneWidget);
    expect(refreshCalls, before + 1);
    coveredContinue();
    await settle(tester);
    expect(c.step, ZyraSignupStep.role);
    await tap(tester, _key('dev_done'));
    expect(find.byType(ZyraSignupPreview), findsOneWidget);
    await tap(tester, _key('signup_continue'));
    expect(c.step, ZyraSignupStep.name);
    await dispose(tester);
  });

  testWidgets(
    'LOCK 34 setup resumes the saved step and completion clears the gate',
    (tester) async {
      plan = 'seeker_premium';
      await mount(tester, homeOverride: previewHome());
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_setup_unfinished'));
      await tap(tester, _key('dev_done'));
      await tap(tester, _key('signup_continue_setup'));
      expect(find.textContaining('0/320 answered'), findsOneWidget);
      await tap(tester, _key('signup_preferences_next'));
      final c = tester
          .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
          .controller;
      expect(c.step, ZyraSignupStep.aboutYou);
      c.setAboutYou('A local draft, kept when setup is paused.');
      await settle(tester);
      await tap(tester, _key('signup_finish_later'));
      await previewTab(tester, 4);
      await tap(tester, _key('concept_edit_profile'));
      final edit = tester.widget<EditProfileScreen>(
        find.byType(EditProfileScreen),
      );
      final saved = await edit.repository!.load('draft-self');
      expect(
        saved!.journeyBio.toOnboardingAnswers()['bio_about_me'],
        'A local draft, kept when setup is paused.',
      );
      tester
          .widget<ZyraPullDownBackScope>(_key('concept_pull_down_back_scope'))
          .onBack();
      await settle(tester);
      await previewTab(tester, 2);
      await tap(tester, _key('signup_continue_setup'));
      expect(c.step, ZyraSignupStep.aboutYou);
      expect(c.aboutYou, 'A local draft, kept when setup is paused.');
      await tap(tester, _key('signup_continue'));
      expect(c.step, ZyraSignupStep.addGuardian);
      await tap(tester, _key('signup_continue'));
      expect(c.step, ZyraSignupStep.allSet);
      await tap(tester, _key('signup_enter'));
      expect(find.byType(ZyraSignupPreview), findsNothing);
      expect(c.setupComplete, isTrue);
      expect(ZyraDeveloperSamples.instance.setupUnfinished, isFalse);
      expect(_key('signup_continue_setup'), findsNothing);
      await dispose(tester);
    },
  );

  testWidgets(
    'LOCK 34 female setup uses applicable 325 and preserves the choice on resume',
    (tester) async {
      plan = 'seeker_premium';
      await mount(tester, homeOverride: previewHome());
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_start_signup'));
      await tap(tester, _key('signup_apple'));
      final c = tester
          .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
          .controller;
      c.setGender('female');
      while (c.step != ZyraSignupStep.verify) {
        await tap(tester, _key('signup_skip'));
      }
      await tap(tester, _key('signup_verify_later'));
      await tap(tester, _key('signup_finish_setup'));
      expect(find.textContaining('0/325 answered'), findsOneWidget);
      await tap(tester, _key('signup_preferences_later'));
      await finishFirstTour(tester);
      await tap(tester, _key('signup_continue_setup'));
      expect(find.textContaining('0/325 answered'), findsOneWidget);
      await dispose(tester);
    },
  );

  testWidgets('LOCK 34 unfinished setup blocks an ordinary Journey request', (
    tester,
  ) async {
    plan = 'seeker_premium';
    await mount(tester, homeOverride: previewHome());
    await tap(tester, _key('dev_page_title'));
    await tap(tester, _key('dev_setup_unfinished'));
    await tap(tester, _key('dev_done'));
    await previewTab(tester, 0);
    final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    final person = browse.profiles[browse.selectedIndex];
    final before = ZyraDeveloperSamples.instance.sent;
    browse.onRequest!(person);
    await settle(tester);
    expect(
      find.text('Finish setting up your profile to start a Journey.'),
      findsOneWidget,
    );
    expect(ZyraDeveloperSamples.instance.sent, before);
    await dispose(tester);
  });

  testWidgets(
    'LOCK 34 unfinished setup also blocks an eligible Journey restart',
    (tester) async {
      plan = 'seeker_premium';
      var clock = DateTime(2026, 11, 17);
      final model = ViewRequestDraftModel(capacity: 3, clock: () => clock)
        ..seedJourneys(1);
      expect(model.end('draft-sara'), isTrue);
      clock = clock.add(const Duration(hours: 25));
      expect(model.canRequestEndedJourney('draft-sara'), isTrue);
      final checkpoint = ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: model.snapshot(),
        tab: 2,
        pages: const ['ended'],
        personId: 'draft-sara',
      );
      final changes = ChangeNotifier();
      addTearDown(changes.dispose);
      ZyraOneJourneyShellFixtureState? state;
      final fixture = ZyraOneJourneyShellFixture(
        model: model,
        changes: changes,
        readState: () => state,
      );
      await mount(
        tester,
        homeOverride: ZyraDeveloperSeekerScope(
          preview: true,
          child: Builder(
            builder: (context) => ZyraOneJourneyConceptShell(
              canAct: () => ModalRoute.of(context)?.isCurrent == true,
              onExit: () {},
              initialTab: 2,
              previewClock: () => clock,
              fixture: fixture,
            ),
          ),
        ),
      );
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_setup_unfinished'));
      await tap(tester, _key('dev_done'));
      state = ZyraOneJourneyShellFixtureState(checkpoint: checkpoint, tab: 2);
      changes.notifyListeners();
      await settle(tester);
      await tap(tester, _key('draft_journey_draft-sara_header'));
      await tap(tester, _key('draft_ended_restart_draft-sara'));
      await tap(tester, _key('draft_restart_send_draft-sara'));
      expect(
        find.text('Finish setting up your profile to start a Journey.'),
        findsOneWidget,
      );
      expect(model.restartExpiresAt('draft-sara'), isNull);
      await dispose(tester);
    },
  );

  testWidgets(
    'LOCK 34 Unverified withdraws an open Guardian profile and denies direct Seeker entry',
    (tester) async {
      plan = 'seeker_premium';
      await mount(tester, homeOverride: previewHome());
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_view_as_2'));
      await tap(tester, _key('dev_done'));
      await previewTab(tester, 3);
      tester
          .widget<ZyraGuardianTabsPresentation>(
            find.byType(ZyraGuardianTabsPresentation),
          )
          .onAction('seeker_0');
      await settle(tester);
      expect(
        tester
            .widget<ZyraGuardianTabsPresentation>(
              find.byType(ZyraGuardianTabsPresentation),
            )
            .page,
        'seeker',
      );
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_unverified'));
      if (_key('dev_done').evaluate().isNotEmpty) {
        await tap(tester, _key('dev_done'));
      }
      await settle(tester);
      expect(find.text('Every person on ZYRA is verified'), findsOneWidget);
      expect(find.byType(ZyraGuardianTabsPresentation), findsNothing);
      await previewTab(tester, 3);
      tester
          .widget<ZyraGuardianTabsPresentation>(
            find.byType(ZyraGuardianTabsPresentation),
          )
          .onAction('seeker_0');
      await settle(tester);
      expect(find.text('Every person on ZYRA is verified'), findsOneWidget);
      expect(find.byType(ZyraGuardianTabsPresentation), findsNothing);
      await dispose(tester);
    },
  );

  testWidgets(
    'LOCK 34 resumed setup preserves the selected identity and biography',
    (tester) async {
      plan = 'seeker_premium';
      await mount(tester, homeOverride: previewHome());
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_start_signup'));
      await tap(tester, _key('signup_apple'));
      final c = tester
          .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
          .controller;
      c.setGender('female');
      c.setDay('1');
      c.setMonth('1');
      c.setYear('1997');
      c.setLocation('Leeds');
      c.setNationality('Canadian');
      c.toggleEthnicity('British');
      while (c.step != ZyraSignupStep.verify) {
        await tap(tester, _key('signup_skip'));
      }
      await tap(tester, _key('signup_verify_now'));
      await tap(tester, _key('signup_skip'));
      await tap(tester, _key('signup_finish_setup'));
      await tap(tester, _key('signup_preferences_next'));
      c.setAboutYou('One local biography.');
      await settle(tester);
      await tap(tester, _key('signup_continue'));
      await tap(tester, _key('signup_continue'));
      await tap(tester, _key('signup_enter'));
      await finishFirstTour(tester);
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_setup_unfinished'));
      await tap(tester, _key('dev_done'));
      await tap(tester, _key('signup_continue_setup'));
      final resumed = tester
          .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
          .controller;
      expect(resumed.gender, 'female');
      expect(resumed.age, 29);
      expect(resumed.location, 'Leeds');
      expect(resumed.nationality, 'Canadian');
      expect(resumed.ethnicities, {'British'});
      expect(resumed.aboutYou, 'One local biography.');
      await dispose(tester);
    },
  );

  testWidgets('LOCK 34 Guardian verification keeps the selected role', (
    tester,
  ) async {
    plan = 'seeker_premium';
    await mount(tester, homeOverride: previewHome());
    await tap(tester, _key('dev_page_title'));
    await tap(tester, _key('dev_start_signup'));
    await tap(tester, _key('signup_apple'));
    final seeker = tester
        .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
        .controller;
    while (seeker.step != ZyraSignupStep.verify) {
      await tap(tester, _key('signup_skip'));
    }
    await tap(tester, _key('signup_verify_later'));
    await tap(tester, _key('signup_look_around'));
    await finishFirstTour(tester);
    await tap(tester, _key('dev_page_title'));
    await tap(tester, _key('dev_view_as_2'));
    await tap(tester, _key('dev_done'));
    await previewTab(tester, 0);
    expect(find.text('Network'), findsWidgets);
    await tap(tester, find.text('Verify now'));
    expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
    expect(find.byType(ZyraSignupPreview), findsNothing);
    expect(seeker.guardian, isFalse);
    expect(seeker.step, ZyraSignupStep.accountReady);
    await dispose(tester);
  });

  testWidgets('LOCK 34 Guardian pause keeps its own About text on resume', (
    tester,
  ) async {
    plan = 'seeker_premium';
    await mount(tester, homeOverride: previewHome());
    await tap(tester, _key('dev_page_title'));
    await tap(tester, _key('dev_start_signup'));
    await tap(tester, _key('signup_apple'));
    final c = tester
        .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
        .controller;
    c.setGuardian(true);
    while (c.step != ZyraSignupStep.verify) {
      await tap(tester, _key('signup_skip'));
    }
    await tap(tester, _key('signup_verify_later'));
    await tap(tester, _key('signup_finish_setup'));
    expect(c.step, ZyraSignupStep.aboutYou);
    c.setAboutYou('Guardian words stay with this role.');
    await settle(tester);
    await tap(tester, _key('signup_finish_later'));
    await finishFirstTour(tester);
    await tap(tester, _key('signup_continue_setup'));
    expect(c.aboutYou, 'Guardian words stay with this role.');
    expect(c.step, ZyraSignupStep.aboutYou);
    await dispose(tester);
  });

  testWidgets(
    'LOCK 34 preset unfinished state can be switched off explicitly',
    (tester) async {
      plan = 'seeker_premium';
      await mount(tester, homeOverride: previewHome());
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_preset_2'));
      await tap(tester, _key('dev_done'));
      expect(ZyraDeveloperSamples.instance.setupUnfinished, isTrue);
      expect(_key('signup_continue_setup'), findsOneWidget);
      await tap(tester, _key('dev_page_title'));
      await tap(tester, _key('dev_setup_unfinished'));
      await tap(tester, _key('dev_done'));
      expect(ZyraDeveloperSamples.instance.setupUnfinished, isFalse);
      expect(_key('signup_continue_setup'), findsNothing);
      await dispose(tester);
    },
  );
}
