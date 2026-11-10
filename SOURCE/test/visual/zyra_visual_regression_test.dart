import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/screens/wali/wali_gn_shared.dart';
import 'package:zyra/screens/wali/wali_network_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_seeker.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_subscription_wallet_draft.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';
import 'package:zyra/widgets/zyra_loading.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';
import 'lock15_focus_capture_test.dart' show circleToken, fillPreferences, one;

/// Candidate screenshots are deliberately separate from approved baselines.
///
/// Normal invocation performs render/overflow checks and compares only entries
/// explicitly present in `approved/manifest.json`. The capture command adds
/// `--update-goldens --dart-define=ZYRA_CAPTURE_CANDIDATES=true`, which writes
/// to `candidates/`; it can never replace `approved/` by accident.
const _captureCandidates = bool.fromEnvironment('ZYRA_CAPTURE_CANDIDATES');
// Health checks must not overwrite sealed historical candidate copies which
// the promotion ledger still byte-verifies. The normal candidate path remains
// unchanged for the governed visual workflow.
const _healthCapture = bool.fromEnvironment('ZYRA_HEALTH_CAPTURE');
// Theme explorations must preserve sealed earlier candidate copies.
const _candidateDirectory = String.fromEnvironment(
  'ZYRA_VISUAL_CANDIDATE_DIRECTORY',
  defaultValue: 'candidates',
);

/// Founder-approved OA-ZYRA-281 files remain byte-preserved after Phase 3
/// supersedes their Today presentation. Each archived fixture is explicitly
/// paired with its promoted replacement rather than silently disappearing.
const _presentationSupersededFixtures = <String, String>{
  'seeker-dashboard-unread': 'seeker-dashboard-thinned-no-guardian',
  'seeker-dashboard-resolved-actions': 'seeker-dashboard-thinned-connected',
  'seeker-dashboard-home-lower-levels':
      'seeker-dashboard-thinned-pending-invitation',
};

/// Phase 1 rows superseded by the post-067 Founder-directed Guardian delta.
/// The accepted v2 replacements are active; every v1 pixel remains preserved
/// in the archive ledger at its original path.
const _phase1SupersededFixtures = <String, String>{
  'guardianship-manager-empty': 'guardian-manager-empty',
  'guardianship-manager-main-consent-off': 'guardian-manager-main',
  'guardianship-manager-loaded-consent-on': 'guardian-manager-loaded-pending',
  'guardianship-manager-unavailable': 'guardian-manager-unavailable',
  'guardian-detail-main': 'guardian-detail-main-consent-off',
  'guardian-detail-history-unavailable':
      'guardian-detail-main-history-unavailable-consent-off',
};

// OA-ZYRA-316 Tier 1 removes these unused screens. Historical approval
// manifests stay sealed; the active manifests retain their retirement metadata.
const _tier1RetiredFixtures = <String>{
  'guardian-detail-main-consent-off',
  'guardian-detail-additional',
  'guardian-detail-main-history-unavailable-consent-off',
  'notifications-empty',
  'notifications-error',
};

const _visualRoot = ValueKey('zyra-visual-audit-root');

Future<ByteData> _fontBytes(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

class _Device {
  final String id;
  final Size size;

  const _Device(this.id, this.size);
}

const _devices = <_Device>[
  _Device('small', Size(320, 568)),
  _Device('standard', Size(390, 844)),
  _Device('large', Size(430, 932)),
];

class _Fixture {
  final String id;
  final String role;
  final String plan;
  final String state;
  final bool largeText;
  final Widget Function() build;

  const _Fixture({
    required this.id,
    required this.role,
    required this.plan,
    required this.state,
    required this.build,
    this.largeText = false,
  });
}

Widget _gradientBody(Widget child, {String? title}) => Scaffold(
  body: DecoratedBox(
    decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
              child: Text(title, style: ZyraText.heading(size: 25)),
            ),
          Expanded(child: child),
        ],
      ),
    ),
  ),
);

Widget _guardianAccess({required bool entitled, required bool linked}) =>
    _gradientBody(
      GuardianNetworkAccessView(
        hasEntitlement: entitled,
        hasLinkedSeeker: linked,
        onLinkSeeker: () {},
        onMembership: () {},
      ),
      title: 'Network',
    );

Widget _guardianSlider() {
  const wards = [
    WaliLinkedPerson(id: '1', firstName: 'Maryam', isMain: true),
    WaliLinkedPerson(id: '2', firstName: 'Muhammad'),
    WaliLinkedPerson(id: '3', firstName: 'Abdul-Rahman'),
    WaliLinkedPerson(id: '4', firstName: 'Nur'),
    WaliLinkedPerson(id: '5', firstName: 'Ibrahim'),
    WaliLinkedPerson(id: '6', firstName: 'Khadijah'),
  ];
  GNContext.instance.reset();
  return _gradientBody(
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          const GNSeekerSlider(wards: wards),
          const Spacer(),
          ZyraEmptyState(
            icon: Icons.family_restroom_outlined,
            title: 'Six linked Seekers',
            message:
                'The four-name window remains usable while every other Seeker stays available from the overflow control.',
          ),
          const Spacer(),
        ],
      ),
    ),
    title: 'Dashboard',
  );
}

Widget _emptyGuardianManager() => _gradientBody(
  GuardianshipManagerView(
    people: const [],
    linksAvailable: true,
    onRetryLinks: () {},
    onOpenGuardian: (_) {},
    onAdd: () {},
    pendingInvitesLoader: () async => const ZyraSourceResult.available([]),
  ),
);

Widget _styleShowcase(ZyraNavStyle nav) {
  ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
  ZyraInteractionStyle.selectNavStyle(nav);
  return Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: ZyraText.heading(size: 26)),
                    const SizedBox(height: 4),
                    Text(
                      'Assalamu alaikum, Maryam.',
                      style: ZyraText.subtext(size: 13.5),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: ZyraColors.glassFill,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: ZyraColors.glassBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your ZYRA', style: ZyraText.heading(size: 20)),
                          const SizedBox(height: 8),
                          Text(
                            'Midnight Plum · ${nav.label}',
                            style: ZyraText.subtext(size: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        FloatingNavBar(
          currentIndex: 2,
          onTap: (_) {},
          items: const [
            FloatingNavItem(icon: Icons.search, label: 'Browse'),
            FloatingNavItem(icon: Icons.bookmark_border, label: 'Connections'),
            FloatingNavItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              badge: 8,
            ),
            FloatingNavItem(
              icon: Icons.gpp_good_outlined,
              label: 'Guardian',
              dot: true,
            ),
            FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
          ],
        ),
      ],
    ),
  );
}

List<_Fixture> _fixtures() => [
  _Fixture(
    id: 'auth-normal',
    role: 'female-seeker',
    plan: 'basic',
    state: 'normal',
    largeText: true,
    build: () => const WelcomeScreen(),
  ),
  _Fixture(
    id: 'onboarding-intro',
    role: 'male-seeker',
    plan: 'basic',
    state: 'normal',
    largeText: true,
    build: () => OnboardingStageIntroScreen(
      stage: SeekerOnboardingStage.buildProfile,
      welcomeName: 'Shakeel Ahmad',
      onContinue: () {},
    ),
  ),
  // Q17. Keep all four member sizes exercising the real empty manager.
  _Fixture(
    id: 'guardian-manager-empty',
    role: 'female-seeker',
    plan: 'basic',
    state: 'honest-empty',
    largeText: true,
    build: _emptyGuardianManager,
  ),
  _Fixture(
    id: 'subscription-upgrade',
    role: 'male-seeker',
    plan: 'basic',
    state: 'upgrade',
    largeText: true,
    build: () => const UpgradeScreen(),
  ),
  _Fixture(
    id: 'guardian-network-locked',
    role: 'guardian',
    plan: 'basic',
    state: 'locked',
    largeText: true,
    build: () => _guardianAccess(entitled: false, linked: true),
  ),
  _Fixture(
    id: 'guardian-network-unlinked',
    role: 'guardian',
    plan: 'zyra-one',
    state: 'empty',
    build: () => _guardianAccess(entitled: true, linked: false),
  ),
  _Fixture(
    id: 'guardian-network-unavailable',
    role: 'guardian',
    plan: 'zyra-one',
    state: 'disabled',
    build: () => _guardianAccess(entitled: true, linked: true),
  ),
  _Fixture(
    id: 'shared-loading',
    role: 'female-seeker',
    plan: 'basic',
    state: 'loading',
    build: () => const ZyraLoading.fullScreen(label: 'Preparing your Journey…'),
  ),
  _Fixture(
    id: 'shared-error',
    role: 'female-seeker',
    plan: 'basic',
    state: 'error',
    largeText: true,
    build: () => ZyraFullScreenError(
      kind: ZyraErrorKind.offline,
      onPrimary: null,
      referenceCode: 'ZY-AUDIT',
    ),
  ),
  _Fixture(
    id: 'shared-empty-long-copy',
    role: 'guardian',
    plan: 'basic',
    state: 'empty',
    largeText: true,
    build: () => _gradientBody(
      ZyraEmptyState(
        icon: Icons.people_outline,
        title: 'Nothing is waiting for Muhammad Abdullah Al-Rahman',
        message:
            'Updates for this Seeker in Greater London and the surrounding counties will appear here when there is something useful to review.',
        ctaLabel: 'Return to Dashboard',
        onCta: () {},
      ),
    ),
  ),
  _Fixture(
    id: 'guardian-slider-six-seekers',
    role: 'guardian',
    plan: 'zyra-one',
    state: 'expanded',
    largeText: true,
    build: _guardianSlider,
  ),
  for (final nav in ZyraNavStyle.values)
    _Fixture(
      id: 'style-${nav.name}',
      role: 'female-seeker',
      plan: 'basic',
      state: 'selected',
      build: () => _styleShowcase(nav),
    ),
];

Map<String, Map<String, dynamic>> _baselines(String field) {
  final decoded = _readManifest('test/visual/approved/manifest.json');
  final rows = (decoded[field] as List<dynamic>? ?? const []);
  return {
    for (final raw in rows)
      if (raw is Map<String, dynamic> && raw['id'] is String)
        raw['id'] as String: raw,
  };
}

Map<String, dynamic> _readManifest(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Map<String, Map<String, dynamic>> _retiredBaselines() {
  final manifest = _readManifest('test/visual/approved/manifest.json');
  return {
    for (final row
        in (manifest['retired_baselines'] as List).cast<Map<String, dynamic>>())
      row['id'] as String: row,
  };
}

// Removed screenshots no longer participate in rendering or portable byte
// audits. Preserve their original metadata against the sealed approval record;
// the task's move audit verifies the bytes at the recorded _to_delete paths.
void _expectTier1Retirement(Map screenshot) {
  final id = screenshot['id'] as String;
  final retired = _retiredBaselines()[id];
  expect(retired, isNotNull, reason: '$id needs an explicit retirement record');
  final sourcePath =
      (screenshot['path'] ?? screenshot['source_path']) as String;
  final approvedPath = screenshot['approved_path'] as String;
  expect(retired?['source_path'], sourcePath);
  expect('test/visual/${retired?['path']}', approvedPath);
  for (final field in ['sha256', 'bytes', 'version']) {
    expect(retired?[field], screenshot[field], reason: '$id $field drift');
  }
  expect(retired?['retirement_reference'], contains('OA-ZYRA-316 Tier 1'));
  expect(retired?['retired_date'], '2026-10-29');
  expect(retired?['retired_by'], 'Founder (Shakeel)');
  expect(retired?['retired_to'], endsWith('/SOURCE/$approvedPath'));
  expect(retired?['retired_source_to'], endsWith('/SOURCE/$sourcePath'));
  expect(File(sourcePath).existsSync(), isFalse);
  expect(File(approvedPath).existsSync(), isFalse);
}

void _applyRoleAndPlan(_Fixture fixture) {
  final state = AppState.instance;
  state.gender = switch (fixture.role) {
    'male-seeker' => 'male',
    'female-seeker' => 'female',
    _ => 'female',
  };
  state.plan = fixture.plan == 'zyra-one' ? ZyraPlan.one : ZyraPlan.basic;
  state.name = fixture.role == 'guardian' ? 'Amina' : 'Maryam';
  state.surnameLine = 'Fatima Abdullah Al-Rahman';
  state.location = 'Greater London and the surrounding counties';
  state.age = 29;
}

Widget _testApp(Widget child, {required double textScale}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    useMaterial3: true,
    brightness: ZyraColors.isLightPalette ? Brightness.light : Brightness.dark,
    textTheme: ZyraText.textTheme(
      ZyraColors.isLightPalette
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: ZyraColors.actionFill,
      brightness: ZyraColors.isLightPalette
          ? Brightness.light
          : Brightness.dark,
    ),
  ),
  builder: (context, appChild) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: true,
    ),
    child: RepaintBoundary(key: _visualRoot, child: appChild!),
  ),
  home: child,
);

const _founderFrame = ValueKey('zyra-founder-baseline-boundary');

Finder _key(String value) => find.byKey(ValueKey(value));

BaselineHarness _round2Harness(WidgetTester tester, {double textScale = 1}) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(tester, group: 'queue75', textScale: textScale);
}

Future<void> _resizeRound2(BaselineHarness h, Size size) async {
  h.tester.view.devicePixelRatio = 1;
  h.tester.view.physicalSize = size;
  await h.flush();
}

void _round2MasterTests(Map<String, Map<String, dynamic>> approved) {
  final cases =
      <
        ({
          String id,
          String lock,
          String master,
          List<int> questions,
          Future<void> Function(BaselineHarness) drive,
        })
      >[
        (
          // Q46/Q47: current Family Review replaces the old Guardian priority card.
          id: 'gm01_family_review',
          lock: 'LOCK 15 V3 / LOCK 18 V2',
          master: 'MY_ZYRA/MASTERS/gm01_family_review.png',
          questions: [46, 47],
          drive: (h) async {
            await h.mount(guardian: true, tab: 2);
            expect(
              find.text('Family Review for\nAdam and Sara'),
              findsOneWidget,
            );
            expect(find.text('Continue'), findsOneWidget);
            expect(find.text('Pause'), findsOneWidget);
          },
        ),
        (
          // Q46/Q47: the no-priority case uses the approved gm04 Focus state.
          id: 'gm04_all_caught_up',
          lock: 'LOCK 15 V3 / LOCK 18 V2',
          master: 'MY_ZYRA/MASTERS/gm04_all_caught_up.png',
          questions: [46, 47],
          drive: (h) async {
            await h.mount(
              guardian: true,
              checkpoint: ZyraPreviewNavigationCheckpoint(
                guardian: true,
                model: (ViewRequestDraftModel(
                  capacity: 3,
                )..seedJourneys(1)).snapshot(),
                tab: 2,
                pages: const [],
                guardianTabs: const ZyraGuardianTabsSnapshot(
                  review: ZyraGuardianReview.continued,
                  connection: ZyraGuardianConnection.dismissed,
                ),
              ),
            );
            expect(find.text('Nothing needs you right now.'), findsOneWidget);
            expect(find.text('Continue'), findsNothing);
            expect(find.text('Pause'), findsNothing);
          },
        ),
        (
          // Q48/Q49: the Main Seeker page carries the current disclosure contract.
          id: 'g11_seeker__adam_main',
          lock: 'LOCK 8 V6',
          master: 'GUARDIAN_TABS/MASTERS/g11_seeker__adam_main.png',
          questions: [49],
          drive: (h) async {
            final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
            await h.mount(guardian: true, tab: 3, model: model);
            await h.tap('guardian_seeker_0');
            h.assertPage('guardian_seeker');
            expect(find.text('Current Journey'), findsOneWidget);
            expect(find.text('View and Chat'), findsOneWidget);
            expect(find.text('You see them'), findsOneWidget);
            expect(find.text('Not shared'), findsOneWidget);
          },
        ),
        (
          // Q48/Q49: Additional access stays distinct after selecting the other Seeker.
          id: 'g12_seeker__yusuf_additional',
          lock: 'LOCK 8 V6',
          master: 'GUARDIAN_TABS/MASTERS/g12_seeker__yusuf_additional.png',
          questions: [48, 49],
          drive: (h) async {
            final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
            await h.mount(guardian: true, tab: 3, model: model);
            await h.tap('guardian_seeker_0');
            final staleJourney = h.tester
                .widget<ZyraGuardianSeekerPage>(
                  find.byType(ZyraGuardianSeekerPage),
                )
                .onJourney;
            expect(staleJourney, isNotNull);
            await returnZyraPreviewPage(h.tester);
            await h.flush();
            await h.tap('guardian_seeker_1');
            staleJourney!();
            await h.flush();
            h.assertPage('guardian_seeker');
            expect(find.text('Main Guardian only'), findsOneWidget);
            expect(find.text('View and Chat'), findsNothing);
            expect(find.text('You see them'), findsNothing);
            expect(find.text('Current Journey'), findsNothing);
            expect(find.text('Continue'), findsNothing);
            expect(find.text('Pause'), findsNothing);
          },
        ),
        (
          // Q17: no linked Guardians, so k08 is the only card.
          id: 'k08_card__add_a_guardian',
          lock: 'LOCK 19 V3',
          master: 'GUARDIAN_CARD/MASTERS/k08_card__add_a_guardian.png',
          questions: [17],
          drive: (h) async {
            await h.mount(
              checkpoint: ZyraPreviewNavigationCheckpoint(
                guardian: false,
                model: ViewRequestDraftModel(capacity: 3).snapshot(),
                tab: 3,
                pages: const [],
                removedGuardians: draftGuardians.map((person) => person.id),
              ),
            );
            expect(_key('guardian-card-add'), findsOneWidget);
            expect(find.text('Omar'), findsNothing);
            final next = _key('guardian-card-next');
            if (next.evaluate().isNotEmpty) {
              await h.tester.tap(next, warnIfMissed: false);
              await h.flush();
              expect(_key('guardian-card-add'), findsOneWidget);
            }
          },
        ),
        (
          // Q52: Basic's Main Guardian card uses the exact k17 role and capacity.
          id: 'k17_basic__card_front_hassan',
          lock: 'LOCK 19 V3',
          master: 'GUARDIAN_CARD/MASTERS/k17_basic__card_front_hassan.png',
          questions: [52],
          drive: (h) async {
            await h.mount(
              tab: 3,
              initialSeekerBasic: true,
              seekerMembership: 'Seeker Basic',
            );
            expect(_key('guardian-card-draft-guardian-hassan'), findsOneWidget);
          },
        ),
        (
          // Q52/Q53: physically select the invited card, which replaced the old
          // simultaneously displayed pending invitation.
          id: 'k07_card__omar_invited',
          lock: 'LOCK 19 V3',
          master: 'GUARDIAN_CARD/MASTERS/k07_card__omar_invited.png',
          questions: [52, 53],
          drive: (h) async {
            await h.mount(tab: 3);
            await h.tap('guardian-card-next');
            await h.tap('guardian-card-next');
            expect(_key('guardian-card-preview-invited-omar'), findsOneWidget);
            expect(find.text('Waiting for Omar'), findsOneWidget);
            expect(find.text('Send invitation again'), findsOneWidget);
          },
        ),
        (
          // Q54/Q55: preserve the no-Guardian status in the approved new-member
          // Focus fixture, including the unfinished setup and phone permissions.
          id: 'm05_new_member',
          lock: 'LOCK 15 V3 / LOCK 18 V2',
          master: 'MY_ZYRA/MASTERS/m05_new_member.png',
          questions: [54, 55],
          drive: (h) async {
            final model = one();
            model.acknowledgeReceivedRequests(['draft-amira']);
            expect(model.request('draft-noor'), isTrue);
            final messenger = TestDefaultBinaryMessengerBinding
                .instance
                .defaultBinaryMessenger;
            messenger.setMockMethodCallHandler(zyraPhoneAccessChannel, (
              call,
            ) async {
              if (call.method != 'status') return null;
              return {
                'notifications': 'denied',
                'location': 'allowed',
                'photos': 'limited',
                'camera': 'notDetermined',
                'faceID': 'notDetermined',
              };
            });
            addTearDown(
              () => messenger.setMockMethodCallHandler(
                zyraPhoneAccessChannel,
                null,
              ),
            );
            await h.mount(
              checkpoint: ZyraPreviewNavigationCheckpoint(
                guardian: false,
                model: model.snapshot(),
                tab: 2,
                pages: const [],
                seekerReadiness: ZyraWalletReadiness.unfinished,
                removedGuardians: draftGuardians.map((person) => person.id),
                myZyraConsumedFocusTokens: const [circleToken],
              ),
            );
            await fillPreferences(h);
            expect(find.text('Finish setup'), findsOneWidget);
            expect(find.text('No Guardian yet'), findsOneWidget);
            expect(find.text('Notifications off'), findsOneWidget);
          },
        ),
        (
          // Q54/Q55: the connected Basic member's selected Journey capacity on Focus.
          id: 'm06_seeker_basic',
          lock: 'LOCK 15 V3 / LOCK 18 V2',
          master: 'MY_ZYRA/MASTERS/m06_seeker_basic.png',
          questions: [54, 55],
          drive: (h) async {
            final model = ViewRequestDraftModel(capacity: 1)..seedJourneys(1);
            await h.mount(
              tab: 2,
              model: model,
              seekerMembership: 'Seeker Basic',
            );
            expect(find.text('1 of 1 place in use'), findsOneWidget);
            expect(find.textContaining('Insights'), findsNothing);
          },
        ),
      ];

  // Q50/Q51: LOCK 8 g10 has historical Espresso pixels. Preserve the
  // current Ivory roster and its role isolation while the golden is held.
  for (final device in _devices) {
    for (final scale in device.id == 'standard' ? [1.0, 1.3] : [1.0]) {
      testWidgets(
        'LOCK 8 g10 Seekers role isolation ${device.id} text scale $scale',
        (tester) async {
          final h = _round2Harness(tester, textScale: scale);
          final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
          await h.mount(guardian: true, tab: 3, model: model);
          await _resizeRound2(h, device.size);
          expect(_key('guardian_seeker_0'), findsOneWidget);
          final additional = _key('guardian_seeker_1');
          expect(additional, findsOneWidget);
          expect(
            find.descendant(
              of: additional,
              matching: find.textContaining('Additional Guardian'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: additional,
              matching: find.textContaining('Journey with Sara'),
            ),
            findsNothing,
          );
          await h.tap('guardian_seeker_1');
          h.assertPage('guardian_seeker');
          expect(find.text('Main Guardian only'), findsOneWidget);
          expect(find.text('You see them'), findsNothing);
          expect(find.text('View and Chat'), findsNothing);
          expect(_key('guardian_journey'), findsNothing);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }
  }

  // Brief step 6 / LOCK 8 V9 g06: Larger Text at 390 pt may wrap between
  // words. A word must remain on a single painted line.
  testWidgets(
    'Guardian Network Larger Text keeps words whole at 390 pt',
    (tester) async {
      final h = _round2Harness(tester, textScale: 1.3);
      await h.mount(guardian: true, tab: 0);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      await h.flush();
      for (final text in [
        'Network',
        'Introduce to\nAdam',
        'Connect with\nGuardian',
      ]) {
        final finder = find.text(text);
        expect(finder, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        for (final word in RegExp(r'\S+').allMatches(text)) {
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: word.start, extentOffset: word.end),
          );
          expect(
            boxes,
            hasLength(1),
            reason: 'Keep ${word.group(0)} on one line',
          );
        }
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  group('Round 2 LOCK master', () {
    test('all active comparisons have an exact current master', () {
      expect(approved.keys.toSet(), cases.map((entry) => entry.id).toSet());
      for (final entry in cases) {
        expect(
          approved[entry.id]?['governing_reference'],
          '${entry.lock} ${entry.master}',
        );
        expect(approved[entry.id]?['questions_rows'], entry.questions);
        expect(
          File('../PRODUCT/APPROVED/${entry.master}').existsSync(),
          isTrue,
        );
      }
    });
    for (final entry in cases) {
      for (final (device, scale) in [
        (_devices[0], 1.0),
        (_devices[1], 1.0),
        (_devices[1], 1.3),
      ]) {
        testWidgets(
          '${entry.id} layout ${device.id} text scale $scale',
          (tester) async {
            final h = _round2Harness(tester, textScale: scale);
            await entry.drive(h);
            await _resizeRound2(h, device.size);
            expect(find.byKey(_founderFrame), findsOneWidget);
          },
          variant: TargetPlatformVariant.only(TargetPlatform.iOS),
        );
      }
      testWidgets(entry.id, (tester) async {
        final h = _round2Harness(tester);
        await entry.drive(h);
        expect(tester.takeException(), isNull);
        final path = _captureCandidates
            ? '${_healthCapture ? 'health_candidates' : _candidateDirectory}/${entry.id}.png'
            : approved[entry.id]!['path'] as String;
        final priorShadows = debugDisableShadows;
        debugDisableShadows = false;
        try {
          void repaint(RenderObject object) {
            object.markNeedsPaint();
            object.visitChildren(repaint);
          }

          repaint(tester.renderObject(find.byKey(_founderFrame)));
          await tester.pump();
          await expectLater(find.byKey(_founderFrame), matchesGoldenFile(path));
        } finally {
          debugDisableShadows = priorShadows;
        }
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
    }
  });
}

void main() {
  final approved = _baselines('baselines');
  final historical = _baselines('round2_superseded_baselines');
  final historicalFixtures = historical.keys
      .map((id) => id.split('__').first)
      .toSet();
  _round2MasterTests(approved);
  final retired = _retiredBaselines();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'visual-test-key',
    );
    final readingFont = FontLoader('PoppinsAudit')
      ..addFont(_fontBytes('assets/fonts/Poppins-ExtraLight.ttf'))
      ..addFont(_fontBytes('assets/fonts/Poppins-Light.ttf'))
      ..addFont(_fontBytes('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(_fontBytes('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(_fontBytes('assets/fonts/Poppins-SemiBold.ttf'))
      ..addFont(_fontBytes('assets/fonts/Poppins-Bold.ttf'));
    final wordmarkFont = FontLoader('SyneAudit')
      ..addFont(_fontBytes('assets/fonts/Syne-SemiBold.ttf'));
    await Future.wait([readingFont.load(), wordmarkFont.load()]);
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    final fonts = [materialIcons.load()];
    if (Platform.isMacOS) {
      final symbols = FontLoader('ZYRABaselineSystemSymbols')
        ..addFont(_fontBytes('/System/Library/Fonts/SFNS.ttf'));
      fonts.add(symbols.load());
    }
    await Future.wait(fonts);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
    ZyraText.testWordmarkFontFamily = 'SyneAudit';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    GNContext.instance.reset();
  });

  test('active approved manifests are identical and fully byte-audited', () {
    final runtime = _readManifest('test/visual/approved/manifest.json');
    final governed = _readManifest(
      '../SYSTEM/tools/ui_gate/BASELINES/manifest.json',
    );
    expect(runtime['automatic_updates_allowed'], isFalse);
    expect(governed['automatic_updates_allowed'], isFalse);
    expect(runtime['active_baseline_count'], approved.length);
    expect(runtime['archived_baseline_count'], 36);
    expect(runtime['active_version'], 'ZYRA-QUEUE75-R2');
    expect(runtime['historical_active_versions'], [
      'OA-ZYRA-281-v1',
      'OA-ZYRA-282-phase2-v1',
      'OA-ZYRA-282-phase3-v1',
      'OA-ZYRA-282-phase1-v2',
    ]);
    expect(jsonEncode(runtime['baselines']), jsonEncode(governed['baselines']));
    expect(
      jsonEncode(runtime['archived_baselines']),
      jsonEncode(governed['archived_baselines']),
    );
    expect(runtime['retired_baseline_count'], 12);
    expect(
      jsonEncode(runtime['retired_baselines']),
      jsonEncode(governed['retired_baselines']),
    );
    expect(
      jsonEncode(runtime['retired_unapproved_captures']),
      jsonEncode(governed['retired_unapproved_captures']),
    );
    expect(
      jsonEncode(runtime['round2_superseded_baselines']),
      jsonEncode(governed['round2_superseded_baselines']),
    );
    expect(historical, hasLength(112));
    expect(
      historical.values.map((entry) => entry['path']).toSet(),
      hasLength(112),
    );
    expect(
      historical.keys.toSet().intersection(approved.keys.toSet()),
      isEmpty,
    );
    for (final entry in historical.values) {
      expect(entry['questions_row'], inInclusiveRange(17, 55));
      expect(entry['line_73_case_id'], matches(RegExp(r'^Q73-C[0-9]{4}$')));
      final replacement = entry['round2_replacement'];
      switch (entry['round2_disposition']) {
        case 'superseded':
          expect(approved, contains(replacement));
        case 'retired':
          expect(replacement, isNull);
        case 'finding':
          expect(replacement, isNull);
          expect(entry['round2_reason'], isNotEmpty);
        default:
          fail('Missing Round 2 disposition for ${entry['id']}');
      }
    }
    final versions = <String, int>{};
    for (final entry in {...historical, ...approved}.values) {
      for (final key in const [
        'id',
        'path',
        'screen',
        'state',
        'role',
        'plan',
        'device',
        'approved_date',
        'approved_by',
        'governing_reference',
        'version',
      ]) {
        expect(entry[key], isNotNull, reason: 'approved baseline missing $key');
      }
      versions.update(
        entry['version'] as String,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final path = entry['path'] as String;
      final file = File('test/visual/$path');
      expect(file.existsSync(), isTrue, reason: 'missing approved file $path');
      final bytes = file.readAsBytesSync();
      expect(bytes.length, entry['bytes'], reason: '$path byte drift');
      expect(
        sha256.convert(bytes).toString(),
        entry['sha256'],
        reason: '$path hash drift',
      );
    }
    expect(versions, {
      'OA-ZYRA-281-v1': 28,
      'OA-ZYRA-282-phase2-v1': 36,
      'OA-ZYRA-282-phase3-v1': 32,
      'OA-ZYRA-282-phase1-v2': 16,
      if (approved.isNotEmpty) 'ZYRA-QUEUE75-R2': approved.length,
    });
  });

  test('Tier 1 retired screens have no active fixtures or baselines', () {
    final fixtureIds = {
      ..._fixtures().map((fixture) => fixture.id),
      ...historicalFixtures,
    };
    expect(fixtureIds.intersection(_tier1RetiredFixtures), isEmpty);
    expect(retired, hasLength(12));
    expect(retired.keys.toSet().intersection(historical.keys.toSet()), isEmpty);
    for (final entry in retired.values) {
      final fixture = (entry['id'] as String).split('__').first;
      expect(_tier1RetiredFixtures, contains(fixture));
      expect(
        entry['retirement_reason'],
        contains('Unused GuardianDetailScreen'),
      );
      expect(entry['retired_to'], contains('/_to_delete/OA-ZYRA-316_TIER1_'));
      expect(File('test/visual/${entry['path']}').existsSync(), isFalse);
      expect(File(entry['source_path'] as String).existsSync(), isFalse);
    }
    final runtime = _readManifest('test/visual/approved/manifest.json');
    final captures = (runtime['retired_unapproved_captures'] as List)
        .cast<Map<String, dynamic>>();
    expect(captures, hasLength(7));
    for (final capture in captures) {
      final path = capture['path'] as String;
      expect(path, startsWith('SOURCE/test/visual/candidates/notifications-'));
      expect(File('../$path').existsSync(), isFalse);
      expect(capture['retirement_reference'], 'OA-ZYRA-316 Tier 1');
      expect(capture['retired_to'], endsWith('/$path'));
      expect(capture['sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(capture['bytes'], greaterThan(0));
    }
  });

  test('superseded pixels are archived without byte deletion', () {
    final runtime = _readManifest('test/visual/approved/manifest.json');
    final archived = (runtime['archived_baselines'] as List)
        .cast<Map<String, dynamic>>();
    expect(archived, hasLength(36));
    expect(
      archived
          .map((entry) => entry['id'])
          .toSet()
          .intersection(historical.keys.toSet()),
      isEmpty,
    );
    final currentFixtureIds = {
      ..._fixtures().map((fixture) => fixture.id),
      ...historicalFixtures,
    };
    const variants = ['small', 'standard', 'large', 'standard__text-130'];

    for (final replacement in _presentationSupersededFixtures.entries) {
      expect(
        currentFixtureIds,
        contains(replacement.value),
        reason: '${replacement.key} has no registered Phase 3 replacement',
      );
      expect(
        currentFixtureIds,
        isNot(contains(replacement.key)),
        reason: '${replacement.key} must not compare new UI to old pixels',
      );
      for (final variant in variants) {
        final id = '${replacement.key}__$variant';
        expect(historical[id], isNull, reason: '$id must not remain active');
        final baseline = archived.singleWhere((entry) => entry['id'] == id);
        expect(baseline['archive_status'], 'superseded_byte_preserved');
        expect(baseline['archived_date'], '2026-08-31');
        expect(baseline['archived_by'], 'Founder (Shakeel)');
        expect(
          baseline['archive_reference'],
          contains('066_FABLE-CODEX_2026-08-31'),
        );
        expect(baseline['superseded_by'], '${replacement.value}__$variant');
        expect(historical, contains('${replacement.value}__$variant'));
        final path = baseline['path'] as String;
        expect(baseline['byte_preserved_at'], path);
        final file = File('test/visual/$path');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'missing approved file $path',
        );
        final bytes = file.readAsBytesSync();
        expect(bytes.length, baseline['bytes'], reason: '$id byte drift');
        expect(
          sha256.convert(bytes).toString(),
          baseline['sha256'],
          reason: '$id hash drift',
        );
      }
    }
  });

  test('all OA-ZYRA-282 candidate manifests record governed promotion', () {
    final registeredFixtures = {
      ..._fixtures().map((fixture) => fixture.id),
      ...historicalFixtures,
    };
    final runtime = _readManifest('test/visual/approved/manifest.json');
    final archived = (runtime['archived_baselines'] as List)
        .cast<Map<String, dynamic>>();
    const phases = <({String file, int count, int fixtures, String version})>[
      (
        file: 'OA-ZYRA-282_PHASE_1_manifest.json',
        count: 28,
        fixtures: 7,
        version: 'OA-ZYRA-282-phase1-v1',
      ),
      (
        file: 'OA-ZYRA-282_PHASE_2_manifest.json',
        count: 36,
        fixtures: 9,
        version: 'OA-ZYRA-282-phase2-v1',
      ),
      (
        file: 'OA-ZYRA-282_PHASE_3_manifest.json',
        count: 32,
        fixtures: 8,
        version: 'OA-ZYRA-282-phase3-v1',
      ),
    ];
    for (final phase in phases) {
      final manifest = _readManifest(
        '../SYSTEM/tools/ui_gate/CANDIDATES/${phase.file}',
      );
      expect(manifest['comparison_clock'], '2026-08-30T18:00:00Z');
      expect(manifest['automatic_promotion_allowed'], isFalse);
      expect(manifest['approved_baselines_modified'], isFalse);
      expect(manifest['device_acceptance_pending'], isFalse);
      expect(manifest['fixture_count'], phase.fixtures);
      expect(manifest['variant_count'], phase.count);
      expect(manifest['promoted_variant_count'], phase.count);
      expect(manifest['promoted_baseline_version'], phase.version);
      expect(manifest['founder_approved_date'], '2026-08-31');
      expect(manifest['approved_by'], 'Founder (Shakeel)');
      expect(manifest['approval_reference'], contains('066_FABLE-CODEX'));

      final declaredFixtures = (manifest['fixtures'] as List)
          .map((raw) => (raw as Map)['id'] as String)
          .toSet();
      expect(declaredFixtures, hasLength(phase.fixtures));
      if (phase.version == 'OA-ZYRA-282-phase1-v1') {
        expect(
          declaredFixtures.intersection(_phase1SupersededFixtures.keys.toSet()),
          _phase1SupersededFixtures.keys.toSet(),
        );
        expect(
          registeredFixtures,
          containsAll(
            declaredFixtures
                .difference(_phase1SupersededFixtures.keys.toSet())
                .difference(_tier1RetiredFixtures),
          ),
        );
        for (final replacement in _phase1SupersededFixtures.entries) {
          expect(registeredFixtures, isNot(contains(replacement.key)));
          expect(
            registeredFixtures.contains(replacement.value),
            !_tier1RetiredFixtures.contains(replacement.value),
          );
        }
      } else {
        expect(registeredFixtures, containsAll(declaredFixtures));
      }

      final screenshots = manifest['screenshots'] as List;
      expect(screenshots, hasLength(phase.count));
      for (final raw in screenshots) {
        final screenshot = raw as Map;
        final id = screenshot['id'] as String;
        expect(screenshot['approved'], isTrue);
        expect(screenshot['approved_date'], '2026-08-31');
        expect(screenshot['approved_by'], 'Founder (Shakeel)');
        expect(screenshot['version'], phase.version);
        if (retired.containsKey(id)) {
          _expectTier1Retirement(screenshot);
          expect(historical[id], isNull);
          continue;
        }
        final sourcePath =
            (screenshot['path'] ?? screenshot['source_path']) as String;
        final approvedPath = screenshot['approved_path'] as String;
        final sourceFile = File(sourcePath);
        final approvedFile = File(approvedPath);
        expect(sourceFile.existsSync(), isTrue, reason: 'missing $sourcePath');
        expect(
          approvedFile.existsSync(),
          isTrue,
          reason: 'missing $approvedPath',
        );
        final sourceBytes = sourceFile.readAsBytesSync();
        final approvedBytes = approvedFile.readAsBytesSync();
        expect(sourceBytes, approvedBytes, reason: '$id copy drift');
        expect(
          sourceBytes.length,
          screenshot['bytes'],
          reason: '$id byte drift',
        );
        expect(
          sha256.convert(sourceBytes).toString(),
          screenshot['sha256'],
          reason: '$id hash drift',
        );
        final wasPhase1Superseded =
            phase.version == 'OA-ZYRA-282-phase1-v1' &&
            _phase1SupersededFixtures.keys.any(
              (fixture) => id.startsWith('${fixture}__'),
            );
        if (wasPhase1Superseded) {
          final archivedRow = archived.singleWhere(
            (entry) => entry['id'] == id,
          );
          expect(archivedRow['version'], phase.version);
          expect(archivedRow['sha256'], screenshot['sha256']);
          expect(historical[id], isNull);
        } else {
          expect(historical[id]?['version'], phase.version);
          expect(historical[id]?['sha256'], screenshot['sha256']);
        }
      }
    }
  });

  test('Phase 1 v2 successors are promoted and supersessions finalized', () {
    final manifest = _readManifest(
      '../SYSTEM/tools/ui_gate/CANDIDATES/'
      'OA-ZYRA-282_PHASE_1_V2_manifest.json',
    );
    expect(manifest['programme'], 'OA-ZYRA-282');
    expect(manifest['comparison_clock'], '2026-08-30T18:00:00Z');
    expect(manifest['automatic_promotion_allowed'], isFalse);
    expect(manifest['approved_baselines_modified'], isFalse);
    expect(manifest['device_acceptance_pending'], isFalse);
    expect(manifest['fixture_count'], 6);
    expect(manifest['variant_count'], 24);
    expect(manifest['variants_per_fixture'], 4);
    expect(manifest['proposed_baseline_version'], isNull);
    expect(manifest['promoted_baseline_version'], 'OA-ZYRA-282-phase1-v2');
    expect(manifest['promoted_variant_count'], 24);
    expect(manifest['supersession_status'], 'finalized_founder_accepted');
    expect(manifest['staged_date'], '2026-08-31');
    expect(manifest['staged_by'], 'Codex / Lead Architect');
    expect(manifest['staging_reference'], contains('068_FABLE-CODEX'));
    expect(manifest['founder_approved_date'], '2026-09-01');
    expect(manifest['approved_by'], 'Founder (Shakeel)');
    expect(manifest['approval_reference'], contains('072_FABLE-CODEX'));

    final registeredFixtures = {
      ..._fixtures().map((fixture) => fixture.id),
      ...historicalFixtures,
    };
    final replacementRows = (manifest['superseded_approved_fixtures'] as List)
        .cast<Map<String, dynamic>>();
    expect(replacementRows, hasLength(6));
    for (final replacement in _phase1SupersededFixtures.entries) {
      final row = replacementRows.singleWhere(
        (candidate) => candidate['approved_fixture'] == replacement.key,
      );
      expect(row['candidate_fixture'], replacement.value);
      expect(row['variant_count'], 4);
      expect(registeredFixtures, isNot(contains(replacement.key)));
      expect(
        registeredFixtures.contains(replacement.value),
        !_tier1RetiredFixtures.contains(replacement.value),
      );
    }

    final screenshots = (manifest['screenshots'] as List)
        .cast<Map<String, dynamic>>();
    expect(screenshots, hasLength(24));
    for (final screenshot in screenshots) {
      expect(screenshot['approved'], isTrue);
      expect(screenshot['proposed_version'], isNull);
      expect(screenshot['approved_date'], '2026-09-01');
      expect(screenshot['approved_by'], 'Founder (Shakeel)');
      expect(screenshot['version'], 'OA-ZYRA-282-phase1-v2');
      expect(screenshot['governing_reference'], contains('072_FABLE-CODEX'));
      if (retired.containsKey(screenshot['id'])) {
        _expectTier1Retirement(screenshot);
        expect(historical[screenshot['id']], isNull);
        continue;
      }
      final path = screenshot['path'] as String;
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'missing candidate $path');
      final bytes = file.readAsBytesSync();
      expect(bytes.length, screenshot['bytes'], reason: '$path byte drift');
      expect(
        sha256.convert(bytes).toString(),
        screenshot['sha256'],
        reason: '$path hash drift',
      );
      final approvedPath = screenshot['approved_path'] as String;
      final approvedFile = File(approvedPath);
      expect(
        approvedFile.existsSync(),
        isTrue,
        reason: 'missing promoted copy $approvedPath',
      );
      expect(approvedFile.readAsBytesSync(), bytes);
      final active = historical[screenshot['id']];
      expect(active, isNotNull);
      expect(active?['path'], approvedPath.replaceFirst('test/visual/', ''));
      expect(active?['version'], 'OA-ZYRA-282-phase1-v2');
      expect(active?['sha256'], screenshot['sha256']);
    }

    final runtime = _readManifest('test/visual/approved/manifest.json');
    final archived = (runtime['archived_baselines'] as List)
        .cast<Map<String, dynamic>>();
    expect(runtime['active_baseline_count'], approved.length);
    expect(runtime['archived_baseline_count'], 36);
    final staged = (manifest['staged_supersession_rows'] as List)
        .cast<Map<String, dynamic>>();
    expect(staged, hasLength(24));
    for (final row in staged) {
      final id = row['id'] as String;
      expect(historical[id], isNull, reason: '$id must not remain active');
      expect(row['archive_status'], 'superseded_byte_preserved');
      expect(row['archived_date'], '2026-09-01');
      expect(row['archived_by'], 'Founder (Shakeel)');
      expect(row['archive_reference'], contains('072_FABLE-CODEX'));
      expect(row['archive_reason'], contains('Founder-accepted'));
      expect(row['byte_preserved_at'], row['path']);
      expect(
        historical[row['superseded_by']] ?? retired[row['superseded_by']],
        isNotNull,
      );
      final ledgerRow = archived.singleWhere((entry) => entry['id'] == id);
      expect(jsonEncode(ledgerRow), jsonEncode(row));
      final oldFile = File('test/visual/${row['path']}');
      expect(oldFile.existsSync(), isTrue, reason: 'missing archive $id');
      final oldBytes = oldFile.readAsBytesSync();
      expect(oldBytes.length, row['bytes'], reason: '$id archive byte drift');
      expect(
        sha256.convert(oldBytes).toString(),
        row['sha256'],
        reason: '$id archive hash drift',
      );
    }

    final continuing = historical.values
        .where((row) => row['version'] == 'OA-ZYRA-282-phase1-v1')
        .map((row) => row['id'] as String)
        .toList();
    expect(continuing, isEmpty);
    expect(
      retired.values.where((row) => row['version'] == 'OA-ZYRA-282-phase1-v1'),
      hasLength(4),
    );
  });

  for (final fixture in _fixtures()) {
    final variants = <({String id, _Device device, double scale})>[
      for (final device in _devices)
        (id: '${fixture.id}__${device.id}', device: device, scale: 1.0),
      if (fixture.largeText)
        (
          id: '${fixture.id}__standard__text-130',
          device: _devices[1],
          scale: 1.3,
        ),
    ];

    for (final variant in variants) {
      testWidgets('${variant.id} renders without overflow or exceptions', (
        tester,
      ) async {
        tester.view.physicalSize = variant.device.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
        ZyraInteractionStyle.restoreDefaults();
        _applyRoleAndPlan(fixture);

        await tester.pumpWidget(
          _testApp(fixture.build(), textScale: variant.scale),
        );
        await tester.pump(const Duration(milliseconds: 80));
        if (fixture.id == 'guardian-manager-empty') {
          // Q17, LOCK 19 k08: the only member card is Add a Guardian.
          final card = _key('guardianship-manager-empty');
          expect(card, findsOneWidget);
          expect(
            find.descendant(of: card, matching: find.text('Add a Guardian')),
            findsOneWidget,
          );
        }
        expect(find.byKey(_visualRoot), findsOneWidget);

        if (_captureCandidates) {
          await expectLater(
            find.byKey(_visualRoot),
            matchesGoldenFile(
              '${_healthCapture ? 'health_candidates' : _candidateDirectory}/${variant.id}.png',
            ),
          );
        } else {
          final baseline = approved[variant.id];
          if (baseline != null) {
            await expectLater(
              find.byKey(_visualRoot),
              matchesGoldenFile(baseline['path'] as String),
            );
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
