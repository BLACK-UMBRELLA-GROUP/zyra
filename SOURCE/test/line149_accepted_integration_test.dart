import 'dart:convert';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_app_lock.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_session_router.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_account_session_host.dart';
import 'package:zyra/widgets/zyra_app_lock_gate.dart';
import 'package:zyra/widgets/zyra_developer_title.dart';

import 'package:zyra/dev/zyra_legal_reader_preview.dart';
import 'package:zyra/dev/zyra_help_safety_preview.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_family_sheet.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_guardian_preview_lifetime.dart';
import 'package:zyra/widgets/zyra_purchase_fine_print.dart';

import 'visual/baseline_capture_support.dart';

const _owner = ZyraInternalFounderPolicy.approvedFounderUserId;
const _project = ZyraInternalFounderPolicy.approvedSupabaseUrl;
final _samples = ZyraDeveloperSamples.instance;
Finder _key(String value) => find.byKey(ValueKey(value));

Map<String, Object?> _session({String user = _owner, int version = 0}) {
  String part(Object data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  const metadata = {'zyra_role': 'founder'};
  return {
    'access_token':
        '${part({'alg': 'HS256'})}.${part({'iss': '$_project/auth/v1', 'sub': user, 'exp': 4102444800, 'session_id': 'line149-admission-session', 'app_metadata': metadata, 'jti': 'fixture-$version'})}.${part([1])}',
    'refresh_token': 'synthetic-line149-refresh-$version',
    'token_type': 'bearer',
    'user': {
      'id': user,
      'aud': 'authenticated',
      'email': 'sample-admin@example.org',
      'created_at': '2026-11-12T00:00:00Z',
      'app_metadata': metadata,
    },
  };
}

void _expectInk(WidgetTester tester, Color ink) {
  final finePrint = find.byType(ZyraPurchaseFinePrint);
  expect(finePrint, findsOneWidget);
  final purchase = tester.widget<ZyraPurchaseFinePrint>(finePrint);
  final paragraph = tester.widget<Text>(
    find.descendant(
      of: finePrint,
      matching: find.text(
        ZyraPurchaseFinePrint.copyFor(
          purchase.offer,
          familyMonthlyPence: purchase.familyMonthlyPence,
        ),
      ),
    ),
  );
  expect(paragraph.style?.color, ink);
  expect(paragraph.style?.fontSize, 11.5);
  for (final label in [
    'Terms of use',
    'Privacy policy',
    if (purchase.offer != ZyraPurchaseOffer.compatibilityUnlocks)
      'Restore purchases',
  ]) {
    final button = find.descendant(
      of: finePrint,
      matching: find.widgetWithText(TextButton, label),
    );
    final text = tester.widget<Text>(
      find.descendant(of: button, matching: find.text(label)),
    );
    expect(text.style?.color, const Color(0xFF845F24));
    expect(text.style?.fontSize, 12);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
  }
}

Future<void> _endOfReader(WidgetTester tester) async {
  final scroll = tester.state<ScrollableState>(
    find.descendant(
      of: _key('legal_reading_scroll'),
      matching: find.byType(Scrollable),
    ),
  );
  scroll.position.jumpTo(scroll.position.maxScrollExtent);
  await tester.pumpAndSettle();
}

Future<void> _pop(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var identity = _owner;
  var refresh = 0;
  final requests = <({String method, String path})>[];

  setUpAll(() async {
    await baselineSetUp(evidenceRoot: null);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      'com.llfbandit.app_links/messages',
      'com.llfbandit.app_links/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: _project,
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) async {
        requests.add((method: request.method, path: request.url.path));
        Object response = const [];
        if (request.url.path == '/auth/v1/token') {
          response = _session(user: identity, version: ++refresh);
        } else if (request.url.path == '/rest/v1/profiles' &&
            request.url.queryParameters['select'] ==
                'role,first_name,surname_line,gender,location_text') {
          response = [
            {
              'role': 'seeker',
              'first_name': 'Sample Admin',
              'gender': 'male',
              'location_text': 'Leeds',
            },
          ];
        } else if (request.url.path == '/rest/v1/subscriptions') {
          response = [
            {'plan_type': 'seeker_premium', 'expires_at': null},
          ];
        } else if (request.url.path.endsWith('/ages_for_one')) {
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
  });

  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    identity = _owner;
    await supabase.auth.setInitialSession(jsonEncode(_session()));
    await ZyraAccountState.synchronize(identity);
    requests.clear();
  });

  tearDown(() {
    _samples.resetForAccountChange();
    ZyraAppLock.instance.clearForSignOut();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() async {
    await Supabase.instance.dispose();
    await baselineTearDown();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 8; frame++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    expect(target, findsOneWidget);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settle(tester);
  }

  Future<GlobalKey<NavigatorState>> mount(
    WidgetTester tester, {
    required ViewRequestDraftModel model,
    int waiting = 0,
    int viewAs = 0,
  }) async {
    await tester.runAsync(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await ZyraSessionRouter.resolveHome();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
    final navigator = GlobalKey<NavigatorState>();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
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
                child: child!,
              ),
            ),
          ),
        ),
        home: ZyraDeveloperSeekerScope(
          preview: true,
          child: Builder(
            builder: (context) {
              bool currentPreview() {
                final bridge = ZyraDeveloperSeekerScope.bridgeOf(context);
                return context.mounted &&
                    bridge?.canPresent == true &&
                    bridge?.viewAs != null &&
                    _samples.hasSamples;
              }

              return ZyraOneJourneyConceptShell(
                canAct: () =>
                    currentPreview() && ModalRoute.isCurrentOf(context) == true,
                // Match both admission predicates in the real Founder wrapper.
                canActInOwnedDialog: currentPreview,
                onExit: () {},
                initialTab: 2,
                fixture: ZyraOneJourneyShellFixture(
                  model: model,
                  seededWaitingRequests: waiting,
                ),
              );
            },
          ),
        ),
      ),
    );
    await settle(tester);
    await tap(tester, _key('dev_page_title'));
    await tap(tester, _key('dev_view_as_$viewAs'));
    await tap(tester, _key('dev_active_0'));
    await tap(tester, _key('dev_introductions_1'));
    await tap(tester, _key('dev_done'));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
    });
    return navigator;
  }

  for (final guardian in [false, true]) {
    testWidgets('LOCK51 actual ${guardian ? 'Guardian' : 'Seeker'} Basic '
        'comparison retains Q241 ink through legal return', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = BaselineHarness(tester, group: 'line149_accepted');
      await harness.mount(
        guardian: guardian,
        tab: 4,
        initialSeekerBasic: !guardian,
        initialGuardianBasic: guardian,
        seekerMembership: guardian ? 'Seeker One' : 'Seeker Basic',
        guardianMembership: guardian ? 'Guardian Basic' : 'Guardian One',
      );
      await harness.tap('concept_membership');
      harness.assertPage('one_upgrade');
      expect(
        tester
            .widget<ZyraOneUpgradePage>(find.byType(ZyraOneUpgradePage))
            .strongBasicComparisonDisclosure,
        isTrue,
      );
      _expectInk(tester, ZyraColors.strongSecondaryText);
      await harness.tap('purchase-terms-of-use');
      await tester.pumpAndSettle();
      expect(_key('legal_reader_terms'), findsOneWidget);
      await _endOfReader(tester);
      await harness.tap('legal_next_privacy');
      expect(_key('legal_reader_privacy'), findsOneWidget);
      await _pop(tester);
      expect(find.byType(ZyraLegalReaderPreview), findsNothing);
      harness.assertPage('one_upgrade');
      _expectInk(tester, ZyraColors.strongSecondaryText);
      await harness.tap('purchase-privacy-policy');
      await tester.pumpAndSettle();
      expect(_key('legal_reader_privacy'), findsOneWidget);
      await _pop(tester);
      _expectInk(tester, ZyraColors.strongSecondaryText);
      await harness.tap('purchase-restore-purchases');
      expect(find.text(ZyraPurchaseFinePrint.restoreNotice), findsOneWidget);
      final oldTerms = tester
          .widget<TextButton>(_key('purchase-terms-of-use'))
          .onPressed!;
      // The existing three-second notice overlays the bottom action.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await harness.tapFinder(find.text('Not now'));
      expect(find.byType(ZyraOneUpgradePage), findsNothing);
      oldTerms();
      await tester.pumpAndSettle();
      expect(find.byType(ZyraLegalReaderPreview), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('LOCK51 actual Guardian Before you pay retains the checkbox '
      'and default disclosure while covered legal callbacks deny', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = BaselineHarness(tester, group: 'line149_accepted');
    await harness.mount(
      guardian: true,
      tab: 4,
      initialGuardianBasic: true,
      guardianMembership: 'Guardian Basic',
    );
    await harness.tap('concept_membership');
    await harness.tap('one-upgrade-continue');
    await tester.pumpAndSettle();
    expect(find.text('Before you pay'), findsOneWidget);
    _expectInk(tester, const Color(0xFF6E6257));
    expect(
      tester
          .widget<ZyraPurchaseFinePrint>(find.byType(ZyraPurchaseFinePrint))
          .disclosureColor,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(_key('guardian-before-pay-continue'))
          .onPressed,
      isNull,
    );
    await harness.tap('guardian-before-pay-understand');
    final continueWhileFresh = tester
        .widget<FilledButton>(_key('guardian-before-pay-continue'))
        .onPressed!;
    final checkboxWhileFresh = tester
        .widget<InkWell>(_key('guardian-before-pay-understand'))
        .onTap!;
    await harness.tap('purchase-terms-of-use');
    await tester.pumpAndSettle();
    expect(_key('legal_reader_terms'), findsOneWidget);
    continueWhileFresh();
    checkboxWhileFresh();
    await tester.pumpAndSettle();
    expect(find.text(ZyraPurchaseFinePrint.appleNotice), findsNothing);
    await _endOfReader(tester);
    await harness.tap('legal_next_privacy');
    await _pop(tester);
    expect(find.text('Before you pay'), findsOneWidget);
    _expectInk(tester, const Color(0xFF6E6257));
    expect(
      tester
          .widget<FilledButton>(_key('guardian-before-pay-continue'))
          .onPressed,
      isNotNull,
    );
    await harness.tap('guardian-before-pay-continue');
    expect(find.text(ZyraPurchaseFinePrint.appleNotice), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LOCK51 distinct Guardian Compatibility keeps its default '
      'disclosure through legal navigation', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final model = ViewRequestDraftModel(capacity: 3);
    expect(model.seedJourneys(1), isTrue);
    const subject = 'draft-sara';
    expect(model.sendSalam(subject), isTrue);
    expect(model.simulatePeerSalam(subject), isTrue);
    expect(model.chooseStageContinue(subject), isTrue);
    expect(model.simulatePeerStageContinue(subject), isTrue);
    expect(model.advanceStage(subject), isTrue);
    expect(model.chooseCompatibilityReveal(subject), isTrue);
    expect(model.simulatePeerCompatibilityReveal(subject), isTrue);
    final harness = BaselineHarness(tester, group: 'line149_accepted');
    await harness.mount(
      guardian: true,
      checkpoint: ZyraPreviewNavigationCheckpoint(
        guardian: true,
        model: model.snapshot(),
        tab: 1,
        pages: const [],
        guardianMembership: 'Guardian Basic',
      ),
    );
    expect(harness.shellFixture.compatibilityAccess!.unlock(subject), isTrue);
    expect(harness.shellFixture.refresh(), isTrue);
    await harness.flush();
    await harness.tap('guardian_journey');
    await harness.tap('draft_guardian_compatibility_$subject');
    await harness.tap('draft_compatibility_score_next');
    await harness.tap('draft_compatibility_area_action');
    harness.assertPage('guardian_compatibility_upgrade');
    expect(
      tester
          .widget<ZyraOneUpgradePage>(find.byType(ZyraOneUpgradePage))
          .strongBasicComparisonDisclosure,
      isFalse,
    );
    _expectInk(tester, const Color(0xFF6E6257));
    await harness.tap('purchase-terms-of-use');
    await tester.pumpAndSettle();
    expect(_key('legal_reader_terms'), findsOneWidget);
    await _endOfReader(tester);
    await harness.tap('legal_next_privacy');
    await _pop(tester);
    harness.assertPage('guardian_compatibility_upgrade');
    _expectInk(tester, const Color(0xFF6E6257));
    expect(tester.takeException(), isNull);
  });
  Future<
    ({
      ZyraGuardianPreviewLifetime authority,
      GlobalKey<NavigatorState> navigator,
      ZyraGuardianCircleScreen circle,
      Object share,
      VoidCallback view,
    })
  >
  openOwnedCirclePrice(WidgetTester tester) async {
    final model = ViewRequestDraftModel(capacity: 3);
    expect(
      model.setSampleGuardianMembership(
        'draft-guardian-yusuf',
        DraftGuardianMembership.basic,
      ),
      isTrue,
    );
    await mount(tester, model: model);
    await tap(tester, _key('concept-my-introductions'));
    await tap(tester, _key('family-introduction-sample-aisha-header'));
    await tap(tester, find.text('Ask my Guardians'));
    final circle = tester.widget<ZyraGuardianCircleScreen>(
      find.byType(ZyraGuardianCircleScreen),
    );
    final scope = tester.widget<ZyraDeveloperOwnedNavigatorScope>(
      find.byType(ZyraDeveloperOwnedNavigatorScope),
    );
    expect(scope.bridge, isNotNull);
    expect(scope.admitsNavigator(scope.navigatorKey.currentState), isTrue);
    final boundary = tester.widget<ZyraGuardianPreviewRouteBoundary>(
      find
          .descendant(
            of: find.byType(ZyraGuardianCircleScreen),
            matching: find.byType(ZyraGuardianPreviewRouteBoundary),
          )
          .first,
    );
    expect(boundary.authority.canPreview, isTrue);
    expect(circle.previewTopics!.introductionAttachment, isNotNull);
    expect(find.text('Family introduction'), findsOneWidget);
    final share = _samples.introductionShares.single;
    expect(
      circle.previewData!.messages.where((m) => m.id == share.id),
      hasLength(1),
    );
    final view = tester
        .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'View'))
        .onPressed!;
    await tap(tester, _key('circle_topics_menu'));
    expect(
      circle.previewTopics!.readOnlyParticipantIds,
      contains('draft-guardian-yusuf'),
    );
    final basic = circle.previewTopics!.readOnlyParticipantIds.first;
    await tap(tester, _key('circle_topics_member_$basic'));
    expect(find.byType(ZyraGuardianFamilySheet), findsOneWidget);
    await tap(tester, _key('guardian-family-introduction-primary'));
    expect(_key('guardian-family-price-primary'), findsOneWidget);
    expect(
      tester
          .widget<ZyraPurchaseFinePrint>(find.byType(ZyraPurchaseFinePrint))
          .offer,
      ZyraPurchaseOffer.zyraFamily,
    );
    return (
      authority: boundary.authority,
      navigator: scope.navigatorKey,
      circle: circle,
      share: share,
      view: view,
    );
  }

  testWidgets('LOCK51 actual owned Circle Family price legal return retains '
      'the existing family attachment and local state', (tester) async {
    final owned = await openOwnedCirclePrice(tester);
    final originalMessages = List.of(owned.circle.previewData!.messages);
    final family = _samples.familyIntroduction('sample-aisha')!;
    final originalPhase = family.phase;
    final sentBefore = List.of(_samples.waitingSentProfileIds);
    final before = requests.length;
    final sheetState = tester.state(find.byType(ZyraGuardianFamilySheet));
    await tap(tester, _key('purchase-terms-of-use'));
    expect(_key('legal_reader_terms'), findsOneWidget);
    await _endOfReader(tester);
    await tap(tester, _key('legal_next_privacy'));
    await _pop(tester);
    expect(_key('guardian-family-price-primary'), findsOneWidget);
    expect(
      tester.state(find.byType(ZyraGuardianFamilySheet)),
      same(sheetState),
    );
    expect(owned.authority.canPreview, isTrue);
    expect(_samples.introductionShares.single, same(owned.share));
    expect(_samples.familyIntroduction('sample-aisha'), same(family));
    expect(family.phase, originalPhase);
    expect(_samples.waitingSentProfileIds, sentBefore);
    await _pop(tester);
    expect(find.byType(ZyraGuardianFamilySheet), findsNothing);
    expect(find.text('Family introduction'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'View'), findsOneWidget);
    final retainedCircle = tester.widget<ZyraGuardianCircleScreen>(
      find.byType(ZyraGuardianCircleScreen),
    );
    expect(retainedCircle, same(owned.circle));
    expect(
      retainedCircle.previewData!.messages,
      orderedEquals(originalMessages),
    );
    expect(_samples.introductionShares, hasLength(1));
    expect(requests, hasLength(before));
    expect(tester.takeException(), isNull);
  });

  for (final unrelatedAbove in [false, true]) {
    testWidgets(
      'LOCK51 actual owned Circle revoke while legal open '
      '${unrelatedAbove ? 'preserves unrelated route' : 'removes exact owned children'}',
      (tester) async {
        final owned = await openOwnedCirclePrice(tester);
        final family = _samples.familyIntroduction('sample-aisha')!;
        final originalPhase = family.phase;
        final before = requests.length;
        final staleTerms = tester
            .widget<TextButton>(_key('purchase-terms-of-use'))
            .onPressed!;
        final stalePurchase = tester
            .widget<FilledButton>(_key('guardian-family-price-primary'))
            .onPressed!;
        await tap(tester, _key('purchase-terms-of-use'));
        expect(_key('legal_reader_terms'), findsOneWidget);
        final reader = tester.widget<ZyraLegalReaderPreview>(
          find.byType(ZyraLegalReaderPreview),
        );
        Route<void>? cover;
        if (unrelatedAbove) {
          cover = MaterialPageRoute<void>(
            builder: (_) => const Scaffold(
              body: Text('Unrelated owned navigator destination'),
            ),
          );
          owned.navigator.currentState!.push(cover);
          await tester.pumpAndSettle();
          expect(cover.isCurrent, isTrue);
        }
        owned.authority.revoke();
        reader.onContact();
        staleTerms();
        stalePurchase();
        owned.view();
        await settle(tester);
        await tester.pumpAndSettle();
        expect(owned.authority.isCurrent, isFalse);
        expect(
          find.byType(ZyraLegalReaderPreview, skipOffstage: false),
          findsNothing,
        );
        expect(
          find.byType(ZyraGuardianFamilySheet, skipOffstage: false),
          findsNothing,
        );
        expect(_key('help_safety_contact'), findsNothing);
        expect(_samples.familyIntroduction('sample-aisha'), same(family));
        expect(family.phase, originalPhase);
        expect(_samples.introductionShares.single, same(owned.share));
        expect(_samples.waitingSentProfileIds, isEmpty);
        expect(requests, hasLength(before));
        if (unrelatedAbove) {
          expect(cover!.isCurrent, isTrue);
          expect(
            find.text('Unrelated owned navigator destination'),
            findsOneWidget,
          );
          owned.navigator.currentState!.pop();
          await tester.pumpAndSettle();
        }
        expect(owned.navigator.currentState!.canPop(), isFalse);
        staleTerms();
        owned.view();
        await settle(tester);
        expect(
          find.byType(ZyraLegalReaderPreview, skipOffstage: false),
          findsNothing,
        );
        expect(
          find.byType(ZyraGuardianFamilySheet, skipOffstage: false),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final child in ['all sections', 'signed-in support']) {
    testWidgets('LOCK51 actual owned Circle revokes reader with $child open', (
      tester,
    ) async {
      final owned = await openOwnedCirclePrice(tester);
      final family = _samples.familyIntroduction('sample-aisha')!;
      final originalPhase = family.phase;
      final before = requests.length;
      final staleTerms = tester
          .widget<TextButton>(_key('purchase-terms-of-use'))
          .onPressed!;
      await tap(tester, _key('purchase-terms-of-use'));
      expect(_key('legal_reader_terms'), findsOneWidget);
      late VoidCallback staleChild;
      if (child == 'all sections') {
        await tap(tester, _key('legal_all_sections'));
        expect(_key('legal_sections_sheet'), findsOneWidget);
        staleChild = tester
            .widget<InkWell>(_key('legal_sheet_section_2'))
            .onTap!;
      } else {
        await _endOfReader(tester);
        await tap(tester, _key('legal_contact'));
        final contact = tester.widget<ZyraHelpSafetyPreview>(
          find.byType(ZyraHelpSafetyPreview),
        );
        expect(contact.screen, ZyraHelpSafetyScreen.contact);
        expect(_key('help_contact_message'), findsOneWidget);
        staleChild = contact.onContactSent;
      }
      owned.authority.revoke();
      staleChild();
      staleTerms();
      owned.view();
      await settle(tester);
      await tester.pumpAndSettle();
      expect(owned.authority.isCurrent, isFalse);
      expect(
        find.byType(ZyraLegalReaderPreview, skipOffstage: false),
        findsNothing,
      );
      expect(
        find.byType(ZyraGuardianFamilySheet, skipOffstage: false),
        findsNothing,
      );
      expect(
        find.byType(ZyraHelpSafetyPreview, skipOffstage: false),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('legal_sections_sheet'), skipOffstage: false),
        findsNothing,
      );
      expect(owned.navigator.currentState!.canPop(), isFalse);
      expect(_samples.familyIntroduction('sample-aisha'), same(family));
      expect(family.phase, originalPhase);
      expect(_samples.introductionShares.single, same(owned.share));
      expect(_samples.waitingSentProfileIds, isEmpty);
      expect(requests, hasLength(before));
      staleChild();
      await settle(tester);
      expect(owned.navigator.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
