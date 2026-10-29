// Actual developer panels and shared controls, using offline synthetic state.
// Description cleanup must not change options, authority or account actions.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/data/zyra_release_gates.dart';
import 'package:zyra/dev/dev_onboarding_directions.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/dev_onboarding_transition.dart';
import 'package:zyra/dev/dev_onboarding_welcome_motion.dart';
import 'package:zyra/dev/dev_scenario_panel_v2.dart';
import 'package:zyra/dev/dev_settings_design.dart';
import 'package:zyra/dev/dev_settings_design_state.dart';
import 'package:zyra/dev/dev_splash_directions.dart';
import 'package:zyra/dev/wali_dev_scenario_panel.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';

const _capture = bool.fromEnvironment('ZYRA_TOGGLE_SUBTEXT_CAPTURE');
const _boundary = ValueKey('toggle-subtext-candidate');
const _font = 'PoppinsToggleSubtext';
const _wordmark = 'SyneToggleSubtext';
const _candidates =
    'visual/candidates/toggle_subtext_cleanup_2026_10_09/font_corrected';
const _homeActions = [
  ('dev_home_navigation', 'Home'),
  ('dev_home_login', 'Restart at login'),
  ('dev_reset_state', 'Reset account'),
  ('dev_switch_accounts', 'Switch test account'),
];
const _retiredCopy = [
  'Non-swipe preview · sample data only.',
  'Quiet Horizon is main. All twelve ideas remain here',
  'Choose a style to start onboarding from the beginning.',
  'Try one consistent way to move through the four introduction cards.',
  'Choose the control used after the opening story.',
  'Compare the current screen with a rounded, motion-led layout.',
  'Visual choice only. Existing account actions still work',
  'A read-only inventory of every section, state and interruption',
  'Nothing is written and your current scenario stays intact',
  'Open the real full-screen recovery states.',
  'Protected developer access · internal testing only.',
  'Never present in a release build',
];

class _OfflineOnly extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Toggle cleanup tests must remain offline.');
  }
}

Finder _key(String id) => find.byKey(ValueKey(id));

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark().copyWith(
    textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      disableAnimations: true,
    ),
    child: RepaintBoundary(key: _boundary, child: child!),
  ),
  home: Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: child,
    ),
  ),
);

Widget _scrolling(Widget child) => SafeArea(
  child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child),
);

Widget _home({
  bool busy = false,
  VoidCallback? home,
  VoidCallback? restart,
  VoidCallback? reset,
  VoidCallback? accounts,
  VoidCallback? signup,
}) => ZyraDevHomeTools(
  busy: busy,
  onHome: home ?? () {},
  onRestart: restart ?? () {},
  onReset: reset ?? () {},
  onAccounts: accounts ?? () {},
  onSeekerSignUp: signup ?? () {},
  onGuardianSignUp: signup ?? () {},
);

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(child, scale: scale));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _press(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  final ancestors = find.ancestor(
    of: target,
    matching: find.byType(Scrollable),
  );
  if (ancestors.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  var visible = tester
      .getRect(target)
      .intersect(Offset.zero & tester.view.physicalSize);
  if (ancestors.evaluate().isNotEmpty) {
    visible = visible.intersect(tester.getRect(ancestors.first));
  }
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final local = box.globalToLocal(visible.center);
  final alignment = Alignment(
    local.dx * 2 / box.size.width - 1,
    local.dy * 2 / box.size.height - 1,
  );
  expect(target.hitTestable(at: alignment), findsOneWidget);
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

InkWell _actionInk(WidgetTester tester, String id) {
  final widget = tester.widget<Widget>(_key(id));
  if (widget is InkWell) return widget;
  return tester.widget<InkWell>(
    find.descendant(of: _key(id), matching: find.byType(InkWell)),
  );
}

void _expectRemovedDescriptions() {
  for (final fragment in _retiredCopy) {
    expect(find.textContaining(fragment), findsNothing);
  }
  expect(find.textContaining('ZYRA DEV ·'), findsNothing);
}

void _expectOneLabel(WidgetTester tester, String id, String label) {
  final option = _key(id);
  expect(option, findsOneWidget);
  final texts = tester.widgetList<Text>(
    find.descendant(of: option, matching: find.byType(Text)),
  );
  expect(texts.map((text) => text.data), [label]);
}

void _expectHomeInventory(WidgetTester tester, {bool large = false}) {
  for (final section in [
    'navigation',
    'discovery_direction',
    'splash',
    'onboarding',
    'settings',
    'account',
  ]) {
    expect(_key('dev_home_section_$section'), findsOneWidget);
  }
  for (final retired in [
    'gender',
    'app_gold',
    'mobile_menu',
    'onboarding_transitions',
    'icons',
  ]) {
    expect(_key('dev_home_section_$retired'), findsNothing);
  }
  for (final (id, label) in _homeActions) {
    _expectOneLabel(tester, id, label);
    final target = _key(id);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
    if (!large) expect(tester.getSize(target).height, lessThanOrEqualTo(48));
    final text = tester.widget<Text>(
      find.descendant(of: target, matching: find.byType(Text)),
    );
    expect(text.style!.fontSize, 12.5);
    expect(text.style!.fontFamily, _font);
    for (final icon in tester.widgetList<Icon>(
      find.descendant(of: target, matching: find.byType(Icon)),
    )) {
      expect(icon.size, 17);
    }
    expect(_actionInk(tester, id).borderRadius, BorderRadius.circular(9));
  }
  _expectOneLabel(tester, 'dev_discovery_view_request', 'Open app preview');
  expect(find.text('App preview'), findsOneWidget);
  expect(find.text('Account controls'), findsOneWidget);
  for (final direction in ZyraSplashDirection.values) {
    _expectOneLabel(tester, 'dev_splash_${direction.name}', direction.label);
  }
  for (final direction in ZyraOnboardingDirection.values) {
    _expectOneLabel(
      tester,
      'dev_onboarding_${direction.name}',
      direction.label,
    );
  }
  for (final mode in ZyraOnboardingStoryNavigation.values) {
    _expectOneLabel(
      tester,
      'dev_onboarding_story_${mode.name}',
      mode == ZyraOnboardingStoryNavigation.tapThrough
          ? 'Tap through'
          : 'Scroll down',
    );
  }
  for (final mode in ZyraOnboardingAdvanceMode.values) {
    _expectOneLabel(
      tester,
      'dev_onboarding_advance_${mode.name}',
      mode == ZyraOnboardingAdvanceMode.continueButton
          ? 'Continue'
          : 'Animated down arrow',
    );
  }
  _expectOneLabel(tester, 'dev_settings_design_current', 'Current');
  _expectOneLabel(tester, 'dev_settings_design_smoothCards', 'Smooth cards');
  _expectOneLabel(tester, 'dev_settings_open', 'Open Settings');
  _expectRemovedDescriptions();
}

Future<void> _snapshot(WidgetTester tester, String filename) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await expectLater(
        bytes!.buffer.asUint8List(),
        matchesGoldenFile('$_candidates/$filename.png'),
      );
    } finally {
      image.dispose();
    }
  });
}

void _expectMemberUnchanged() {
  expect(AppState.instance.name, 'Unchanged ordinary fixture');
  expect(AppState.instance.gender, 'female');
  expect(AppState.instance.plan, ZyraPlan.one);
  expect(AppState.instance.activeJourneys, isEmpty);
  expect(AppState.instance.potentialJourneys, isEmpty);
  expect(ZyraReleaseGates.requestNewJourneyEnabled, isFalse);
  expect(ZyraReleaseGates.paidOnlyMembershipEnforced, isFalse);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldHttp = HttpOverrides.current;
  final oldFatal = WidgetController.hitTestWarningShouldBeFatal;
  late _OfflineOnly network;
  setUpAll(() async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    final reading = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader(_wordmark)
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
  });
  tearDownAll(() {
    WidgetController.hitTestWarningShouldBeFatal = oldFatal;
    HttpOverrides.global = oldHttp;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({'ordinary-setting': 'unchanged'});
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraText.testWordmarkFontFamily = _wordmark;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevScenario.instance.reset();
    ZyraDevScenario.instance.setCurrentPage(DevPage.browse);
    ZyraDevScenario.instance.setCurrentWaliPage(WaliPage.network);
    ZyraDevSettingsDesign.select(ZyraSettingsDesign.current);
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDevOnboardingTransition.resetForTesting();
    ZyraDevWelcomeTextMotion.resetForTesting();
    ZyraDevOnboardingGoldDesign.resetForTesting();
    ZyraDevOnboardingGoldMotion.resetForTesting();
    ZyraColors.restoreAppPalette(null);
    AppState.instance.resetForAccountChange();
    AppState.instance.name = 'Unchanged ordinary fixture';
    AppState.instance.gender = 'female';
    AppState.instance.plan = ZyraPlan.one;
    network = _OfflineOnly();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() async {
    expect(network.attempts, 0);
    expect(
      (await SharedPreferences.getInstance()).getString('ordinary-setting'),
      'unchanged',
    );
    HttpOverrides.global = oldHttp;
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevSettingsDesign.select(ZyraSettingsDesign.current);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final viewport in [
    (size: const Size(393, 852), label: '393'),
    (size: const Size(430, 932), label: '430'),
  ]) {
    testWidgets('${viewport.label} Home is compact without losing options', (
      tester,
    ) async {
      await _mount(tester, _scrolling(_home()), size: viewport.size);
      _expectHomeInventory(tester);
      await _snapshot(tester, 'home_${viewport.label}_top');
      await Scrollable.ensureVisible(
        tester.element(_key('dev_switch_accounts')),
        alignment: 1,
      );
      await tester.pumpAndSettle();
      await _snapshot(tester, 'home_${viewport.label}_lower');
      _expectMemberUnchanged();
    });
  }

  testWidgets('all Home actions keep exactly their supplied callback', (
    tester,
  ) async {
    final calls = [0, 0, 0, 0, 0];
    await _mount(
      tester,
      _scrolling(
        _home(
          home: () => calls[0]++,
          restart: () => calls[1]++,
          reset: () => calls[2]++,
          accounts: () => calls[3]++,
          signup: () => calls[4]++,
        ),
      ),
    );
    for (var i = 0; i < _homeActions.length; i++) {
      await _press(tester, _key(_homeActions[i].$1));
      expect(calls, [for (var j = 0; j < 4; j++) j <= i ? 1 : 0, 0]);
    }
    _expectMemberUnchanged();
  });

  testWidgets('busy Home retains existing disabled and enabled actions', (
    tester,
  ) async {
    await _mount(tester, _scrolling(_home(busy: true)));
    expect(find.text('Resetting…'), findsOneWidget);
    expect(_actionInk(tester, 'dev_home_navigation').onTap, isNull);
    expect(_actionInk(tester, 'dev_reset_state').onTap, isNull);
    expect(_actionInk(tester, 'dev_home_login').onTap, isNotNull);
    expect(_actionInk(tester, 'dev_switch_accounts').onTap, isNotNull);
    for (final direction in ZyraSplashDirection.values) {
      expect(
        tester
            .widget<ActionChip>(_key('dev_splash_${direction.name}'))
            .onPressed,
        isNull,
      );
    }
    for (final direction in ZyraOnboardingDirection.values) {
      expect(
        tester
            .widget<ActionChip>(_key('dev_onboarding_${direction.name}'))
            .onPressed,
        isNull,
      );
    }
    expect(
      tester
          .widget<OutlinedButton>(_key('dev_discovery_view_request'))
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<ChoiceChip>(_key('dev_settings_design_current')).onSelected,
      isNull,
    );
    _expectRemovedDescriptions();
    _expectMemberUnchanged();
  });

  for (final enabled in [true, false]) {
    testWidgets('motion options remain label-only and enabled=$enabled', (
      tester,
    ) async {
      await _mount(
        tester,
        _scrolling(DevOnboardingTransitionPicker(enabled: enabled)),
      );
      final inkKeys = <(String, String)>[
        for (final motion in ZyraWelcomeTextMotion.values.where(
          (value) => value.family == ZyraWelcomeTextMotionFamily.descent,
        ))
          ('dev_welcome_text_motion_${motion.name}', motion.label),
        for (final design in ZyraOnboardingGoldDesign.values)
          ('dev_onboarding_gold_design_${design.name}', design.label),
        for (final transition in ZyraOnboardingPageTransition.values)
          ('dev_onboarding_transition_${transition.name}', transition.label),
      ];
      for (final (id, label) in inkKeys) {
        _expectOneLabel(tester, id, label);
        expect(_actionInk(tester, id).onTap, enabled ? isNotNull : isNull);
      }
      for (final motion in ZyraOnboardingGoldMotion.values) {
        final id = 'dev_onboarding_gold_motion_${motion.name}';
        _expectOneLabel(tester, id, motion.label);
        expect(
          tester.widget<ActionChip>(_key(id)).onPressed,
          enabled ? isNotNull : isNull,
        );
      }
      expect(find.text('Opening slide motion'), findsOneWidget);
      expect(find.text('Descent only'), findsNothing);
      expect(find.text('Opening gold accents'), findsOneWidget);
      expect(find.text('Gold animation'), findsOneWidget);
      expect(find.textContaining('Choose how the'), findsNothing);
      expect(find.textContaining('This changes only'), findsNothing);
      _expectMemberUnchanged();
    });
  }

  testWidgets('short option labels still select their local presentation', (
    tester,
  ) async {
    await _mount(
      tester,
      _scrolling(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DevOnboardingTransitionPicker(),
            DevSettingsDesignPicker(guardian: false),
          ],
        ),
      ),
    );
    await _press(tester, _key('dev_welcome_text_motion_lighterDescent'));
    expect(
      ZyraDevWelcomeTextMotion.current,
      ZyraWelcomeTextMotion.lighterDescent,
    );
    await _press(tester, _key('dev_onboarding_gold_design_diagonalDust'));
    expect(
      ZyraDevOnboardingGoldDesign.current,
      ZyraOnboardingGoldDesign.diagonalDust,
    );
    await _press(tester, _key('dev_onboarding_gold_motion_pageEntrance'));
    expect(
      ZyraDevOnboardingGoldMotion.current,
      ZyraOnboardingGoldMotion.pageEntrance,
    );
    await _press(tester, _key('dev_onboarding_transition_quietFade'));
    expect(
      ZyraDevOnboardingTransition.current,
      ZyraOnboardingPageTransition.quietFade,
    );
    await _press(tester, _key('dev_settings_design_smoothCards'));
    expect(ZyraDevSettingsDesign.current, ZyraSettingsDesign.smoothCards);
    _expectMemberUnchanged();
  });

  for (final (role, panel) in <(String, Widget Function(ValueListenable<int>))>[
    (
      'entry',
      (requests) =>
          ZyraEntryDevPanel(pageLabel: 'Entry fixture', openRequests: requests),
    ),
    (
      'seeker',
      (requests) =>
          DevScenarioPanelV2(onOpenPage: (_) {}, openRequests: requests),
    ),
    (
      'guardian',
      (requests) =>
          WaliDevScenarioPanel(onOpenPage: (_) {}, openRequests: requests),
    ),
  ]) {
    for (final viewport in [
      (size: const Size(393, 852), scale: 1.0, label: '393'),
      (size: const Size(430, 932), scale: 1.0, label: '430'),
      (size: const Size(320, 568), scale: 2.0, label: '320_200'),
      (size: const Size(393, 852), scale: 2.0, label: '393_200'),
      (size: const Size(430, 932), scale: 2.0, label: '430_200'),
    ]) {
      testWidgets('$role ${viewport.label} panel keeps concise usable doors', (
        tester,
      ) async {
        final requests = ValueNotifier<int>(0);
        addTearDown(requests.dispose);
        await _mount(
          tester,
          Stack(fit: StackFit.expand, children: [panel(requests)]),
          size: viewport.size,
          scale: viewport.scale,
        );
        requests.value++;
        await tester.pumpAndSettle();
        await _press(tester, _key('dev_controls_tab_home'));
        expect(find.text('Developer controls'), findsOneWidget);
        _expectHomeInventory(tester, large: viewport.scale > 1);
        await _press(tester, _key('dev_settings_design_smoothCards'));
        expect(ZyraDevSettingsDesign.current, ZyraSettingsDesign.smoothCards);
        await _press(tester, _key('dev_controls_tab_actions'));
        expect(find.byType(ZyraDevPageOptions), findsOneWidget);
        final options = tester
            .widget<ZyraDevPageOptions>(find.byType(ZyraDevPageOptions))
            .options;
        expect(options, isNotEmpty);
        expect(
          options.map((option) => option.id).toSet().length,
          options.length,
        );
        await _press(tester, _key('dev_controls_tab_preview'));
        expect(_key('dev_open_page_preview'), findsOneWidget);
        _expectOneLabel(
          tester,
          'dev_open_page_preview',
          'Open complete page preview',
        );
        expect(
          tester.getSize(_key('dev_open_page_preview')).height,
          greaterThanOrEqualTo(44),
        );
        _expectRemovedDescriptions();
        if (role == 'seeker') {
          final seekerScroll = find
              .descendant(
                of: find.byType(DevScenarioPanelV2),
                matching: find.byType(Scrollable),
              )
              .first;
          tester.state<ScrollableState>(seekerScroll).position.jumpTo(0);
          await tester.pumpAndSettle();
          expect(
            find.text('Local preview · server controls unavailable'),
            findsOneWidget,
          );
          for (final label in [
            'Page error',
            'Offline',
            'ZYRA unavailable',
            'Session expired',
          ]) {
            await tester.scrollUntilVisible(
              find.text(label),
              200,
              scrollable: seekerScroll,
            );
            await tester.pumpAndSettle();
            expect(find.text(label), findsOneWidget);
          }
          tester.state<ScrollableState>(seekerScroll).position.jumpTo(0);
          await tester.pumpAndSettle();
        }
        if ((role == 'entry' && viewport.label == '393') ||
            (role == 'seeker' && viewport.label == '393') ||
            (role == 'guardian' && viewport.label == '430') ||
            (role == 'seeker' && viewport.label == '320_200')) {
          await _snapshot(tester, '${role}_${viewport.label}_preview');
        }
        // The small, enlarged-text Seeker preview builds its footer lazily.
        // Prove that it is reachable instead of requiring off-screen rows
        // to have been eagerly mounted; preserve the top-content proof above.
        final host = switch (role) {
          'entry' => find.byType(ZyraEntryDevPanel),
          'seeker' => find.byType(DevScenarioPanelV2),
          _ => find.byType(WaliDevScenarioPanel),
        };
        await tester.scrollUntilVisible(
          find.text('Internal preview'),
          200,
          scrollable: find
              .descendant(of: host, matching: find.byType(Scrollable))
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Internal preview'), findsOneWidget);
        expect(find.text('Internal preview').hitTestable(), findsOneWidget);
        _expectRemovedDescriptions();
        expect(tester.takeException(), isNull);
        _expectMemberUnchanged();
      });
    }
  }

  testWidgets('ordinary members see no developer rail or picker options', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    for (final panel in <Widget>[
      const ZyraEntryDevPanel(pageLabel: 'Entry fixture'),
      DevScenarioPanelV2(onOpenPage: (_) {}),
      WaliDevScenarioPanel(onOpenPage: (_) {}),
    ]) {
      await _mount(tester, Stack(fit: StackFit.expand, children: [panel]));
      expect(_key('dev_controls_close'), findsNothing);
      expect(_key('dev_controls_tab_home'), findsNothing);
      expect(_key('dev_controls_tab_preview'), findsNothing);
      expect(_key('dev_controls_tab_actions'), findsNothing);
      expect(_key('dev_discovery_view_request'), findsNothing);
      expect(find.byType(ZyraDevPageOptions), findsNothing);
      _expectMemberUnchanged();
    }
  });

  testWidgets('page options retain disabled reasons and actionable errors', (
    tester,
  ) async {
    var attempts = 0;
    await _mount(
      tester,
      _scrolling(
        ZyraDevPageOptions(
          contextKey: 'synthetic-cleanup',
          options: [
            const ZyraDevPageOption(
              id: 'cleanup_unavailable',
              label: 'Unavailable option',
              group: 'Synthetic options',
              unavailableReason:
                  'Server controls are unavailable in this preview.',
            ),
            ZyraDevPageOption(
              id: 'cleanup_error',
              label: 'Retryable option',
              group: 'Synthetic options',
              onSelected: () {
                attempts++;
                throw StateError('Synthetic local failure');
              },
            ),
          ],
        ),
      ),
    );
    await _press(tester, _key('dev_page_options_dropdown_Synthetic options'));
    expect(
      find.text('Server controls are unavailable in this preview.'),
      findsOneWidget,
    );
    expect(tester.widget<InkWell>(_key('cleanup_unavailable')).onTap, isNull);
    await _press(tester, _key('cleanup_error'));
    expect(attempts, 1);
    expect(_key('dev_page_option_error'), findsOneWidget);
    expect(
      find.text('This option could not be applied. Try again.'),
      findsOneWidget,
    );
    _expectMemberUnchanged();
  });

  testWidgets('Seeker reset explanation remains and Cancel does not reset', (
    tester,
  ) async {
    ZyraDevScenario.instance.setActiveJourneys(2);
    final requests = ValueNotifier<int>(0);
    addTearDown(requests.dispose);
    await _mount(
      tester,
      Stack(
        fit: StackFit.expand,
        children: [
          DevScenarioPanelV2(onOpenPage: (_) {}, openRequests: requests),
        ],
      ),
    );
    requests.value++;
    await tester.pumpAndSettle();
    await _press(tester, _key('dev_controls_tab_home'));
    await _press(tester, _key('dev_reset_state'));
    expect(find.text('Reset developer state?'), findsOneWidget);
    expect(
      find.textContaining('Account and server rows are unchanged.'),
      findsOneWidget,
    );
    expect(find.text('Reset'), findsOneWidget);
    await _press(tester, find.text('Cancel'));
    expect(find.text('Reset developer state?'), findsNothing);
    expect(ZyraDevScenario.instance.activeJourneys, 2);
    _expectMemberUnchanged();
  });

  testWidgets('short recovery labels still open and leave the actual error', (
    tester,
  ) async {
    final requests = ValueNotifier<int>(0);
    addTearDown(requests.dispose);
    await _mount(
      tester,
      Stack(
        fit: StackFit.expand,
        children: [
          DevScenarioPanelV2(onOpenPage: (_) {}, openRequests: requests),
        ],
      ),
    );
    requests.value++;
    await tester.pumpAndSettle();
    await _press(tester, _key('dev_controls_tab_preview'));
    await _press(tester, find.text('Offline'));
    expect(find.byType(ZyraFullScreenError), findsOneWidget);
    expect(find.text(ZyraErrorKind.offline.content.message), findsOneWidget);
    expect(_key('zyra_error_primary'), findsOneWidget);
    expect(_key('zyra_error_secondary'), findsOneWidget);
    await _press(tester, _key('zyra_error_secondary'));
    expect(find.byType(ZyraFullScreenError), findsNothing);
    expect(find.byType(DevScenarioPanelV2), findsOneWidget);
    _expectMemberUnchanged();
  });
}
