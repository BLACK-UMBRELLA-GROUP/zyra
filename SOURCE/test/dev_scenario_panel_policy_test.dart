import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_entitlements.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/dev/dev_scenario_panel_v2.dart';
import 'package:zyra/dev/wali_dev_scenario_panel.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_loading.dart';

const _realProfile = SeekerProfile(
  id: 'real-profile',
  firstName: 'Arif',
  age: 36,
  city: 'Derby',
  photos: ['https://example.invalid/arif.jpg'],
  gender: 'male',
);

const _realActive = JourneyMatch(
  matchId: 'real-match',
  profile: _realProfile,
  status: 'active',
  journeyStage: 'salam_exchange',
);

List<ZyraDevPageOption> _pageOptions(WidgetTester tester) =>
    tester.widget<ZyraDevPageOptions>(find.byType(ZyraDevPageOptions)).options;

Future<void> _selectOption(WidgetTester tester, String id) async {
  await _pageOptions(
    tester,
  ).singleWhere((option) => option.id == id).onSelected!();
  await tester.pumpAndSettle();
}

final _categoryDropdowns = find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'dev_page_options_dropdown_',
      ),
);

final _panelRequests = ValueNotifier<int>(0);

Future<void> _openPanel(WidgetTester tester) async {
  _panelRequests.value++;
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => ZyraDeveloperAccess.setAuthorizedForTesting(true));
  tearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));
  final scenario = ZyraDevScenario.instance;

  setUp(() {
    scenario.reset();
    scenario.setCurrentPage(DevPage.browse);
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraColors.selectDevLightAccent(ZyraDevLightAccent.purple);
    ZyraText.useTestFontStubs = true;
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
    ZyraInteractionStyle.restoreDefaults();
  });
  tearDown(() {
    scenario.reset();
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraColors.selectDevLightAccent(ZyraDevLightAccent.purple);
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.useTestFontStubs = false;
  });

  test('zero preview counts never hide a real Journey', () {
    final rows = ZyraDevScenario.composeJourneys(
      viewerGender: 'female',
      currentUserId: 'me',
      viewerPlan: ZyraPlan.one,
      realActive: const [_realActive],
    );

    expect(rows, contains(same(_realActive)));
    expect(rows.where((row) => row.isMock), isEmpty);
  });

  test('developer reset enters an isolated zero-card Connections state', () {
    expect(scenario.connectionsPreviewIsolated, isTrue);
    expect(scenario.connectionsRealRows(const [_realActive]), isEmpty);

    final rows = ZyraDevScenario.composeJourneys(
      viewerGender: 'female',
      currentUserId: 'me',
      viewerPlan: ZyraPlan.basic,
    );

    expect(rows, isEmpty);
    scenario.setQueuedJourneys(1);
    expect(scenario.connectionsPreviewIsolated, isTrue);
  });

  test('preview counts add cards without replacing real account truth', () {
    scenario.setQueuedJourneys(1);

    final rows = ZyraDevScenario.composeJourneys(
      viewerGender: 'female',
      currentUserId: 'me',
      viewerPlan: ZyraPlan.one,
      realActive: const [_realActive],
      realPotential: const [
        JourneyMatch(
          matchId: 'real-potential',
          profile: _realProfile,
          status: 'potential',
        ),
      ],
    );

    expect(rows.where((row) => !row.isMock), hasLength(2));
    expect(rows.where((row) => row.isMock), hasLength(1));
  });

  test('clean panel migration removes only retired invisible counters', () {
    scenario.setActiveJourneys(1);
    scenario.setBusyPotential(2);
    scenario.setBusyPaused(2);
    scenario.setBusyEnded(2);

    scenario.migrateToCleanSeekerPanel();

    expect(scenario.activeJourneys, 1);
    expect(scenario.busyPotential, 0);
    expect(scenario.busyPaused, 0);
    expect(scenario.busyEnded, 0);
  });

  test('developer popups retain limits but no sponsored-card state', () {
    expect(DevPopup.values, const [
      DevPopup.saveLimit,
      DevPopup.considerLimit,
      DevPopup.dailyLimit,
    ]);
  });

  test('Active Journey preview options follow the current plan limits', () {
    expect(ZyraEntitlements.devOptions(ZyraEntitlements.basic.active), const [
      '0',
      '1',
    ]);
    expect(ZyraEntitlements.devOptions(ZyraEntitlements.one.active), const [
      '0',
      '1',
      '2',
      '3',
    ]);

    scenario.setActiveJourneys(3);
    final basicRows = ZyraDevScenario.composeJourneys(
      viewerGender: 'female',
      currentUserId: 'me',
      viewerPlan: ZyraPlan.basic,
    );
    final oneRows = ZyraDevScenario.composeJourneys(
      viewerGender: 'female',
      currentUserId: 'me',
      viewerPlan: ZyraPlan.one,
    );

    expect(basicRows.where((row) => row.status == 'active'), hasLength(1));
    expect(oneRows.where((row) => row.status == 'active'), hasLength(3));
  });

  test('retired Connections comparisons remain archived as enum studies', () {
    expect(ZyraConnectionsCardStyle.values, hasLength(6));
    expect(ZyraConnectionsHeadingStyle.values, hasLength(5));
  });

  test('Introduction lab clamps 0–5 and reset clears local previews', () {
    scenario.setIntroductionPreviewCount(9);
    expect(scenario.introductionPreviewCount, 5);
    scenario.reset();
    expect(scenario.introductionPreviewCount, 0);
  });

  test('Activity labs clamp 0–5 and reset clears all local previews', () {
    scenario
      ..setConsideredPreviewCount(9)
      ..setSavedPreviewCount(3)
      ..setPassedPreviewCount(-2);
    expect(scenario.consideredPreviewCount, 5);
    expect(scenario.savedPreviewCount, 3);
    expect(scenario.passedPreviewCount, 0);

    scenario
      ..setPassedPreviewCount(4)
      ..reset();
    expect(scenario.consideredPreviewCount, 0);
    expect(scenario.savedPreviewCount, 0);
    expect(scenario.passedPreviewCount, 0);
  });

  test(
    'local Activity actions move one fixture without account-state writes',
    () {
      scenario.setConsideredPreviewCount(1);
      final id = zyraActivityTestProfileId(ZyraActivityTestState.considered, 0);

      expect(scenario.localProfileDestination(id), isNull);
      expect(scenario.isLocalProfileHidden(id), isFalse);

      scenario.moveLocalProfile(id, ZyraActivityTestState.saved);
      expect(scenario.localProfileDestination(id), ZyraActivityTestState.saved);

      scenario.moveLocalProfile(id, ZyraActivityTestState.passed);
      expect(
        scenario.localProfileDestination(id),
        ZyraActivityTestState.passed,
      );

      scenario.hideLocalProfile(id);
      expect(scenario.localProfileDestination(id), isNull);
      expect(scenario.isLocalProfileHidden(id), isTrue);

      scenario.setConsideredPreviewCount(0);
      expect(scenario.isLocalProfileHidden(id), isFalse);

      scenario
        ..setConsideredPreviewCount(1)
        ..moveLocalProfile(id, ZyraActivityTestState.saved)
        ..reset();
      expect(scenario.localProfileDestination(id), isNull);
      expect(scenario.isLocalProfileHidden(id), isFalse);
    },
  );

  test('Introduction fixtures use the same local destination boundary', () {
    scenario.setIntroductionPreviewCount(1);
    final id = zyraIntroductionTestProfileId(0);

    scenario.moveLocalProfile(id, ZyraActivityTestState.considered);
    expect(
      scenario.localProfileDestination(id),
      ZyraActivityTestState.considered,
    );

    scenario.setIntroductionPreviewCount(0);
    expect(scenario.localProfileDestination(id), isNull);
    expect(scenario.isLocalProfileHidden(id), isFalse);
  });

  test('Comet line is the locked shared loading motion', () {
    expect(ZyraLoadingStyle.values, hasLength(10));
    expect(kZyraLoadingStyle, ZyraLoadingStyle.cometLoop);
  });

  test('Browse swipe lab keeps Full aura plus ten 3D options and resets', () {
    expect(ZyraBrowseSwipeFeedbackStyle.values, hasLength(11));
    expect(
      ZyraBrowseSwipeFeedbackStyle.values.where(
        (style) => style.groupLabel == 'Current default',
      ),
      hasLength(1),
    );
    expect(
      ZyraBrowseSwipeFeedbackStyle.values.where(
        (style) => style.groupLabel == '3D photo movement',
      ),
      hasLength(10),
    );
    expect(
      ZyraBrowseSwipeFeedbackStyle.values.where((style) => style.movesPhoto),
      hasLength(10),
    );
    expect(
      ZyraBrowseSwipeFeedbackStyle.values.where(
        (style) => style.previewsNextProfile,
      ),
      hasLength(10),
    );
    expect(
      scenario.browseSwipeFeedbackStyle,
      ZyraBrowseSwipeFeedbackStyle.fullAura,
    );

    scenario.setBrowseSwipeFeedbackStyle(
      ZyraBrowseSwipeFeedbackStyle.horizonLift,
    );
    expect(
      scenario.browseSwipeFeedbackStyle,
      ZyraBrowseSwipeFeedbackStyle.horizonLift,
    );

    scenario.reset();
    expect(
      scenario.browseSwipeFeedbackStyle,
      ZyraBrowseSwipeFeedbackStyle.fullAura,
    );
  });

  testWidgets('Home tools omit the retired compatibility breakdown toggle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZyraDevHomeTools(
              busy: false,
              onHome: () {},
              onRestart: () {},
              onReset: () {},
              onAccounts: () {},
              onSeekerSignUp: () {},
              onGuardianSignUp: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('COMPATIBILITY BREAKDOWN'), findsNothing);
    expect(
      find.byKey(const ValueKey('dev_compatibility_breakdown_threePartRail')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dev_compatibility_breakdown_exactTrio')),
      findsNothing,
    );
  });

  test('Browse motion lab appends five distinct local profiles', () {
    const live = SeekerProfile(
      id: 'real-browse-profile',
      firstName: 'Existing',
      age: 34,
      city: 'Derby',
      photos: ['https://example.invalid/shared.jpg'],
      gender: 'female',
    );

    final deck = ZyraDevScenario.composeBrowsePreviewProfiles(
      real: const [live],
      viewerGender: 'male',
    );
    final previews = deck.skip(1).toList();

    expect(deck, hasLength(6));
    expect(deck.first, same(live));
    expect(previews, hasLength(5));
    expect(previews.map((profile) => profile.id).toSet(), hasLength(5));
    expect(previews.map((profile) => profile.firstName).toSet(), hasLength(5));
    expect(previews.map((profile) => profile.age).toSet(), hasLength(5));
    expect(previews.map((profile) => profile.city).toSet(), hasLength(5));
    expect(previews.every((profile) => profile.gender == 'female'), isTrue);
    expect(
      previews.every((profile) => identical(profile.photos, live.photos)),
      isTrue,
    );
    expect(
      previews.every((profile) => profile.id.startsWith('dev-browse-preview-')),
      isTrue,
    );
  });

  test('Browse preview pool follows the opposite-gender rule', () {
    final deck = ZyraDevScenario.composeBrowsePreviewProfiles(
      real: const [],
      viewerGender: 'female',
    );

    expect(deck, hasLength(5));
    expect(deck.every((profile) => profile.gender == 'male'), isTrue);
  });

  test('shared Pause preview exposes every approved state and resets', () {
    for (final pauseScenario in ZyraPauseDevScenario.values) {
      scenario.setPauseScenario(pauseScenario);
      expect(scenario.pausedJourneys, 1);
      expect(scenario.pauseScenario, pauseScenario);
    }

    scenario.reset();
    expect(scenario.pausedJourneys, 0);
    expect(scenario.pauseScenario, ZyraPauseDevScenario.active);
  });

  test('style lab has 18 reading faces and never changes the wordmark', () {
    expect(ZyraAppFont.values, hasLength(18));
    expect(ZyraText.currentDefaultFont, ZyraAppFont.poppins);
    final lockedWordmark = ZyraText.wordmark().fontFamily;

    for (final font in ZyraAppFont.values) {
      ZyraText.selectAppFont(font);
      expect(ZyraText.body().fontFamily, ZyraText.preview(font).fontFamily);
      expect(ZyraText.wordmark().fontFamily, lockedWordmark);
    }
  });

  test('Crystal UI keeps background, accent, font and nav independent', () {
    ZyraColors.selectDevPalette(ZyraDevPalette.crystalMist);
    final purpleGlass = ZyraColors.glassFill;
    ZyraColors.selectDevLightAccent(ZyraDevLightAccent.emerald);
    ZyraText.selectAppFont(ZyraAppFont.manrope);
    ZyraInteractionStyle.selectNavStyle(ZyraNavStyle.quietDot);

    expect(ZyraColors.devPalette, ZyraDevPalette.crystalMist);
    expect(ZyraColors.devLightAccent, ZyraDevLightAccent.emerald);
    expect(ZyraText.appFont, ZyraAppFont.manrope);
    expect(ZyraInteractionStyle.navStyle, ZyraNavStyle.quietDot);
    expect(ZyraColors.glassFill, purpleGlass);
    expect(ZyraColors.glassFill.a, greaterThan(0.70));
    expect(ZyraColors.actionFill, ZyraDevLightAccent.emerald.color);
  });

  testWidgets('the Poppins default is bundled for offline first launch', (
    _,
  ) async {
    for (final weight in const [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      final bytes = await rootBundle.load('assets/fonts/Poppins-$weight.ttf');
      expect(bytes.lengthInBytes, greaterThan(1000));
    }
  });

  testWidgets('the separate Syne wordmark is bundled for offline first paint', (
    _,
  ) async {
    final bytes = await rootBundle.load('assets/fonts/Syne-SemiBold.ttf');
    expect(bytes.lengthInBytes, greaterThan(1000));
    expect(ZyraText.wordmark().fontFamily, 'Syne');
    expect(ZyraText.heading().fontFamily, 'Poppins');
  });

  test('palette lab is live and restores the current default background', () {
    final defaultColors = ZyraColors.brandGradient.colors;

    ZyraColors.selectDevPalette(ZyraDevPalette.deepEmerald);
    expect(ZyraColors.devPalette, ZyraDevPalette.deepEmerald);
    expect(ZyraColors.brandGradient.colors, isNot(defaultColors));

    ZyraColors.selectDevPalette(ZyraDevPalette.paperWhite);
    expect(ZyraColors.isLightPalette, isTrue);
    expect(ZyraColors.brandGradient.colors.first, const Color(0xFFFFFFFF));
    expect(ZyraText.heading().color, ZyraColors.luxuryDarkPurple);
    expect(ZyraColors.iconButtonBorder, const Color(0x303D2A4A));
    expect(ZyraDevLightAccent.values, hasLength(7));
    ZyraColors.selectDevLightAccent(ZyraDevLightAccent.emerald);
    expect(ZyraColors.actionFill, ZyraDevLightAccent.emerald.color);
    expect(ZyraColors.onAction, Colors.white);
    expect(
      ZyraColors.accentBg,
      ZyraDevLightAccent.emerald.color.withValues(alpha: 0.14),
    );
    expect(
      ZyraColors.accentBorder,
      ZyraDevLightAccent.emerald.color.withValues(alpha: 0.40),
    );
    expect(ZyraColors.glassFill, const Color(0x143D2A4A));
    expect(ZyraColors.frostBorder, const Color(0x293D2A4A));

    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    expect(ZyraColors.isLightPalette, isFalse);
    expect(ZyraText.heading().color, Colors.white);
    expect(ZyraColors.brandGradient.colors, defaultColors);
  });

  testWidgets('three developer doors omit retired visual comparisons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DevScenarioPanelV2(
                onOpenPage: (_) {},
                openRequests: _panelRequests,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);
    await _openPanel(tester);
    for (final section in ['preview', 'actions', 'home']) {
      expect(find.byKey(ValueKey('dev_controls_tab_$section')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('dev_rail_style')), findsNothing);
    final homeY = tester
        .getCenter(find.byKey(const ValueKey('dev_controls_tab_home')))
        .dx;
    final previewY = tester
        .getCenter(find.byKey(const ValueKey('dev_controls_tab_preview')))
        .dx;
    final actionsY = tester
        .getCenter(find.byKey(const ValueKey('dev_controls_tab_actions')))
        .dx;
    expect(actionsY, lessThan(previewY));
    expect(previewY, lessThan(homeY));

    await tester.tap(
      find.byKey(const ValueKey('dev_controls_tab_preview')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Browse preview'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_open_page_preview')), findsOneWidget);
    expect(find.text('Page error'), findsOneWidget);
    expect(find.text('Session expired'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('dev_open_page_preview')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Everything this page can contain.'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Decisions'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openPanel(tester);

    await tester.tap(
      find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev_home_login')), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_reset_state')), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_switch_accounts')), findsOneWidget);
    expect(find.text('Restart at login'), findsOneWidget);
    expect(find.text('Reset account'), findsOneWidget);
    expect(find.text('Switch test account'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_signup_seeker')), findsNothing);
    expect(find.byKey(const ValueKey('dev_signup_guardian')), findsNothing);
    expect(find.text('APP SURFACE'), findsNothing);
    expect(find.text('HOME SCREEN ICON'), findsNothing);
    expect(find.text('Sign Up — Seeker'), findsNothing);
    expect(find.text('Sign Up — Guardian'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('dev_controls_tab_actions')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('OPEN PAGE'), findsNothing);
    expect(find.text('BROWSE SCENARIOS'), findsNothing);
    expect(find.text('Sponsored card'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ZyraDevPageOptions),
        matching: find.text('Page options'),
      ),
      findsOneWidget,
    );
    final options = _pageOptions(tester);
    expect(
      options.where((option) => option.id.startsWith('browse-motion-')),
      hasLength(11),
    );
    expect(
      options.map((option) => option.label),
      containsAll(['Full aura', '10 · Horizon lift']),
    );
    expect(
      options.map((option) => option.group),
      containsAll(['Swipe feedback', 'Limit previews']),
    );
    expect(
      _categoryDropdowns,
      findsNWidgets(options.map((option) => option.group).toSet().length),
    );
    for (final group in options.map((option) => option.group).toSet()) {
      expect(
        find.byKey(ValueKey('dev_page_options_dropdown_$group')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('dev_page_options_dropdown')),
      findsNothing,
    );
  });

  testWidgets('Developer controls do not expose loading or style selectors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DevScenarioPanelV2(
                onOpenPage: (_) {},
                openRequests: _panelRequests,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('dev_rail_style')), findsNothing);
    expect(find.byKey(const ValueKey('dev_loading_animation')), findsNothing);
    expect(kZyraLoadingStyle, ZyraLoadingStyle.cometLoop);
  });

  testWidgets(
    'main-app Founder panel exposes local scenarios but omits server tools',
    (tester) async {
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      addTearDown(
        () => ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null),
      );
      scenario
        ..setCurrentPage(DevPage.connections)
        ..setConnectionsSection(0)
        ..setUseLiveGuardianData(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DevScenarioPanelV2(
                  onOpenPage: (_) {},
                  openRequests: _panelRequests,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(scenario.useLiveGuardianData, isFalse);
      await _openPanel(tester);

      expect(
        find.byKey(const ValueKey('main_app_founder_preview_panel_banner')),
        findsNothing,
      );
      final journey = _pageOptions(tester);
      expect(
        journey.any((option) => option.label == 'Open live Journey'),
        isFalse,
      );
      expect(
        journey.any((option) => option.group == 'Active Journeys'),
        isTrue,
      );
      expect(find.textContaining('Local preview cards only'), findsNothing);

      scenario.setConnectionsSection(1);
      await tester.pumpAndSettle();
      final activity = _pageOptions(tester);
      expect(
        activity.any((option) => option.id == 'considered-profiles-1'),
        isTrue,
      );
      expect(
        activity.any((option) => option.id.startsWith('credits-')),
        isFalse,
      );
      expect(
        activity.any((option) => option.id.startsWith('guardians-on-decided-')),
        isFalse,
      );
    },
  );

  testWidgets(
    'main-app Founder membership is local and live Guardian source is absent',
    (tester) async {
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      addTearDown(
        () => ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null),
      );
      AppState.instance.setPlan(ZyraPlan.basic);
      scenario.setCurrentPage(DevPage.guardian);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DevScenarioPanelV2(
                  onOpenPage: (_) {},
                  openRequests: _panelRequests,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await _openPanel(tester);

      final guardian = _pageOptions(tester);
      expect(guardian.any((option) => option.group == 'Data source'), isFalse);
      expect(guardian.any((option) => option.group == 'Main Guardian'), isTrue);
      expect(
        guardian.any((option) => option.group == 'Additional Guardians'),
        isTrue,
      );
      expect(
        guardian.any((option) => option.group == 'Active Journeys'),
        isTrue,
      );
      expect(guardian.any((option) => option.group == 'Membership'), isFalse);

      scenario.setCurrentPage(DevPage.profile);
      await tester.pumpAndSettle();
      final profile = _pageOptions(tester);
      expect(
        profile.map((option) => option.label),
        containsAll([
          'No access',
          'Seeker One',
          'Notification permission banner',
        ]),
      );
      expect(profile.any((option) => option.label == 'Basic'), isFalse);
      expect(
        profile.any((option) => option.label == 'ZYRA One invitation banner'),
        isFalse,
      );
      expect(
        profile.any((option) => option.label == 'Seeker One invitation banner'),
        isFalse,
      );
      await _selectOption(tester, 'profile-membership-one');
      expect(AppState.instance.plan, ZyraPlan.one);
      expect(
        find.textContaining('Account membership was unchanged'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Connections actions follow the actual segment without another selector',
    (tester) async {
      AppState.instance.setPlan(ZyraPlan.one);
      scenario
        ..setCurrentPage(DevPage.connections)
        ..setConnectionsSection(0);
      final openedSections = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DevScenarioPanelV2(
                  onOpenPage: (_) {},
                  openRequests: _panelRequests,
                  onOpenConnectionsSection: openedSections.add,
                ),
              ],
            ),
          ),
        ),
      );
      await _openPanel(tester);

      expect(
        find.byKey(const ValueKey('dev_connections_section_picker')),
        findsNothing,
      );
      expect(
        _pageOptions(tester).any((option) => option.id == 'paused-journeys-1'),
        isTrue,
      );
      expect(
        _pageOptions(
          tester,
        ).any((option) => option.id == 'considered-profiles-1'),
        isFalse,
      );

      scenario.setConnectionsSection(1);
      await tester.pumpAndSettle();
      expect(
        _pageOptions(tester).any((option) => option.id == 'paused-journeys-1'),
        isFalse,
      );
      for (final group in ['considered', 'saved', 'passed']) {
        expect(
          _pageOptions(
            tester,
          ).any((option) => option.id == '$group-profiles-1'),
          isTrue,
        );
      }
      expect(
        _pageOptions(
          tester,
        ).any((option) => option.id == 'test-introductions-1'),
        isFalse,
      );

      scenario.setConnectionsSection(2);
      await tester.pumpAndSettle();
      expect(_pageOptions(tester).map((option) => option.id), [
        for (var count = 0; count <= 5; count++) 'test-introductions-$count',
      ]);
      expect(
        scenario.introductionPreviewCount,
        0,
        reason: 'Observing a page must not stage rows automatically.',
      );
      expect(openedSections, isEmpty);

      scenario.setConnectionsSection(0);
      await tester.pumpAndSettle();
      expect(
        _pageOptions(tester).any((option) => option.id == 'paused-journeys-1'),
        isTrue,
      );
    },
  );

  testWidgets(
    'Pause decision state belongs only to page-aware Active Journey actions',
    (tester) async {
      scenario
        ..setPausedJourneys(1)
        ..setCurrentPage(DevPage.connections)
        ..setConnectionsSection(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DevScenarioPanelV2(
                  onOpenPage: (_) {},
                  openRequests: _panelRequests,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await _openPanel(tester);
      expect(
        find.byKey(const ValueKey('dev_controls_tab_actions')),
        findsOneWidget,
      );

      expect(
        _pageOptions(
          tester,
        ).any((option) => option.group == 'Pause decision state'),
        isFalse,
      );
      scenario.setCurrentPage(DevPage.activeJourney);
      await tester.pumpAndSettle();
      expect(
        _pageOptions(
          tester,
        ).where((option) => option.group == 'Pause decision state'),
        hasLength(ZyraPauseDevScenario.values.length),
      );
      await _selectOption(tester, 'pause-mutuallyPaused');
      expect(scenario.pauseScenario, ZyraPauseDevScenario.mutuallyPaused);
    },
  );

  testWidgets(
    'Introduction control stages locally and opens the real segment',
    (tester) async {
      scenario
        ..setCurrentPage(DevPage.connections)
        ..setConnectionsSection(2);
      var openedIntroductions = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DevScenarioPanelV2(
                  onOpenPage: (_) {},
                  openRequests: _panelRequests,
                  onOpenIntroductions: () => openedIntroductions++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await _openPanel(tester);
      await _selectOption(tester, 'test-introductions-1');
      expect(scenario.introductionPreviewCount, 1);
      expect(openedIntroductions, 1);
    },
  );

  testWidgets('Guardian uses the same page-aware three-door control', (
    tester,
  ) async {
    scenario.setCurrentWaliPage(WaliPage.network);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              WaliDevScenarioPanel(
                onOpenPage: (_) {},
                openRequests: _panelRequests,
              ),
            ],
          ),
        ),
      ),
    );

    await _openPanel(tester);
    for (final section in ['preview', 'actions', 'home']) {
      expect(find.byKey(ValueKey('dev_controls_tab_$section')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('dev_rail_style')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('dev_controls_tab_preview')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Network preview'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('dev_open_page_preview')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Guardian · Network'), findsOneWidget);
    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('Connection stages'), findsOneWidget);
  });
}
