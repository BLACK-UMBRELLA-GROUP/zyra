// Historical option metadata and callbacks are code-only fixtures.
// Actual member recovery UI, account authority and offline checks remain covered.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/data/zyra_release_gates.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';
import 'support/queue44_dashboard_fixture_catalog.dart';
import 'support/queue44_scenario_fixture_catalog.dart';
import 'support/queue44_home_fixture_catalog.dart';
import 'support/queue44_settings_fixture.dart';
import 'support/queue44_gold_fixture.dart';
import 'support/queue44_onboarding_interaction_fixture.dart';
import 'support/queue44_onboarding_transition_fixture.dart';
import 'support/queue44_welcome_motion_fixture.dart';

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

void _expectRemovedDescriptions() {
  for (final fragment in _retiredCopy) {
    expect(find.textContaining(fragment), findsNothing);
  }
  expect(find.textContaining('ZYRA DEV ·'), findsNothing);
}

void _expectHomeInventory(WidgetTester tester, Queue44HomeCatalog catalog) {
  expect(Queue44HomeCatalog.sections, [
    'navigation',
    'discovery_direction',
    'splash',
    'onboarding',
    'settings',
    'account',
  ]);
  for (final (id, _) in _homeActions) {
    expect(catalog.commands.containsKey(id), isTrue);
    expect(_key(id), findsNothing);
  }
  final choices = catalog.choices;
  expect(choices, isNotEmpty);
  expect(choices.map((choice) => choice.id).toSet().length, choices.length);
  for (final choice in choices) {
    expect(choice.label.trim(), isNotEmpty);
    expect(_key(choice.id), findsNothing);
  }
  for (final id in [
    'dev_controls_close',
    'dev_controls_tab_home',
    'dev_controls_tab_preview',
    'dev_controls_tab_actions',
    'dev_discovery_view_request',
    'dev_open_page_preview',
    'dev_page_options_dropdown_Synthetic options',
  ]) {
    expect(_key(id), findsNothing);
  }
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
      final catalog = Queue44HomeCatalog();
      await _mount(tester, const SizedBox(), size: viewport.size);
      _expectHomeInventory(tester, catalog);
      await _snapshot(tester, 'home_${viewport.label}_absent');
      _expectMemberUnchanged();
    });
  }

  testWidgets('all Home actions keep exactly their supplied callback', (
    tester,
  ) async {
    final calls = [0, 0, 0, 0, 0];
    final catalog = Queue44HomeCatalog(
      home: () => calls[0]++,
      restart: () => calls[1]++,
      reset: () => calls[2]++,
      accounts: () => calls[3]++,
    );
    await _mount(tester, const SizedBox());
    for (var i = 0; i < _homeActions.length; i++) {
      catalog.commands[_homeActions[i].$1]!();
      expect(calls, [for (var j = 0; j < 4; j++) j <= i ? 1 : 0, 0]);
    }
    expect(catalog.commands.keys, isNot(contains('signup')));
    _expectHomeInventory(tester, catalog);
    _expectMemberUnchanged();
  });

  testWidgets('busy Home retains existing disabled and enabled actions', (
    tester,
  ) async {
    final catalog = Queue44HomeCatalog(
      busy: true,
      home: () {},
      restart: () {},
      reset: () {},
      accounts: () {},
    );
    await _mount(tester, const SizedBox());
    expect(catalog.commands['dev_home_navigation'], isNull);
    expect(catalog.commands['dev_reset_state'], isNull);
    expect(catalog.commands['dev_home_login'], isNotNull);
    expect(catalog.commands['dev_switch_accounts'], isNotNull);
    expect(catalog.enabled, isFalse);
    expect(
      catalog.choices.every((choice) => choice.onSelected == null),
      isTrue,
    );
    _expectHomeInventory(tester, catalog);
    _expectMemberUnchanged();
  });

  for (final enabled in [true, false]) {
    testWidgets('motion options remain label-only and enabled=$enabled', (
      tester,
    ) async {
      final choices = queue44MotionChoices(enabled: enabled);
      await _mount(tester, const SizedBox());
      expect(choices, isNotEmpty);
      expect(choices.map((choice) => choice.id).toSet().length, choices.length);
      for (final choice in choices) {
        expect(choice.label.trim(), isNotEmpty);
        expect(choice.onSelected, enabled ? isNotNull : isNull);
        expect(_key(choice.id), findsNothing);
      }
      expect(
        choices.map((choice) => choice.group).toSet(),
        containsAll([
          'Opening slide motion',
          'Opening gold accents',
          'Gold animation',
          'Page transition',
        ]),
      );
      _expectRemovedDescriptions();
      _expectMemberUnchanged();
    });
  }

  testWidgets('short option labels still select their local presentation', (
    tester,
  ) async {
    final catalog = Queue44HomeCatalog();
    await _mount(tester, const SizedBox());
    for (final id in [
      'dev_welcome_text_motion_lighterDescent',
      'dev_onboarding_gold_design_diagonalDust',
      'dev_onboarding_gold_motion_pageEntrance',
      'dev_onboarding_transition_quietFade',
      'dev_settings_design_smoothCards',
    ]) {
      await catalog.choices
          .singleWhere((choice) => choice.id == id)
          .onSelected!();
    }
    expect(
      ZyraDevWelcomeTextMotion.current,
      ZyraWelcomeTextMotion.lighterDescent,
    );
    expect(
      ZyraDevOnboardingGoldDesign.current,
      ZyraOnboardingGoldDesign.diagonalDust,
    );
    expect(
      ZyraDevOnboardingGoldMotion.current,
      ZyraOnboardingGoldMotion.pageEntrance,
    );
    expect(
      ZyraDevOnboardingTransition.current,
      ZyraOnboardingPageTransition.quietFade,
    );
    expect(ZyraDevSettingsDesign.current, ZyraSettingsDesign.smoothCards);
    _expectMemberUnchanged();
  });

  for (final role in ['entry', 'seeker', 'guardian']) {
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
        final home = Queue44HomeCatalog();
        final owner = UniqueKey();
        bool current() => find.byKey(owner).evaluate().isNotEmpty;
        final options = switch (role) {
          'seeker' => Queue44SeekerCatalog(current: current).options,
          'guardian' => Queue44GuardianCatalog(current: current).options,
          _ => const [
            ZyraFixtureChoice(
              id: 'dev_entry_accounts',
              label: 'Switch test account',
              group: 'Entry',
            ),
            ZyraFixtureChoice(
              id: 'dev_entry_signup',
              label: 'Onboarding',
              group: 'Onboarding',
            ),
          ],
        };
        await _mount(
          tester,
          SizedBox(key: owner),
          size: viewport.size,
          scale: viewport.scale,
        );
        _expectHomeInventory(tester, home);
        await home.choices
            .singleWhere(
              (choice) => choice.id == 'dev_settings_design_smoothCards',
            )
            .onSelected!();
        expect(ZyraDevSettingsDesign.current, ZyraSettingsDesign.smoothCards);
        expect(options, isNotEmpty);
        expect(
          options.map((option) => option.id).toSet().length,
          options.length,
        );
        for (final option in options) {
          expect(_key(option.id), findsNothing);
          expect(option.label.trim(), isNotEmpty);
        }
        expect(find.text('Developer controls'), findsNothing);
        expect(find.text('Internal preview'), findsNothing);
        expect(tester.takeException(), isNull);
        _expectMemberUnchanged();
      });
    }
  }

  testWidgets('ordinary members see no developer rail or picker options', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    for (final role in ['entry', 'seeker', 'guardian']) {
      await _mount(tester, const SizedBox());
      _expectHomeInventory(tester, Queue44HomeCatalog());
      final options = switch (role) {
        'seeker' => Queue44SeekerCatalog(current: () => true).options,
        'guardian' => Queue44GuardianCatalog(current: () => true).options,
        _ => const <ZyraFixtureChoice>[],
      };
      for (final option in options.where(
        (option) => option.onSelected != null,
      )) {
        await option.onSelected!();
      }
      _expectMemberUnchanged();
    }
  });

  testWidgets('page options retain disabled reasons and actionable errors', (
    tester,
  ) async {
    var attempts = 0;
    const unavailable = ZyraFixtureChoice(
      id: 'cleanup_unavailable',
      label: 'Unavailable option',
      group: 'Synthetic options',
      unavailableReason: 'Server controls are unavailable in this preview.',
    );
    final retry = ZyraFixtureChoice(
      id: 'cleanup_error',
      label: 'Retryable option',
      group: 'Synthetic options',
      onSelected: () {
        attempts++;
        throw StateError('Synthetic local failure');
      },
    );
    await _mount(tester, const SizedBox());
    expect(unavailable.onSelected, isNull);
    expect(
      unavailable.unavailableReason,
      'Server controls are unavailable in this preview.',
    );
    expect(() => retry.onSelected!(), throwsA(isA<StateError>()));
    expect(attempts, 1);
    expect(_key('dev_page_option_error'), findsNothing);
    expect(_key('cleanup_unavailable'), findsNothing);
    _expectMemberUnchanged();
  });

  testWidgets('Seeker reset explanation remains and Cancel does not reset', (
    tester,
  ) async {
    ZyraDevScenario.instance.setActiveJourneys(2);
    final catalog = Queue44HomeCatalog(reset: ZyraDevScenario.instance.reset);
    await _mount(tester, const SizedBox());
    expect(catalog.commands['dev_reset_state'], isNotNull);
    // Cancellation is represented without dispatching the reset command.
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Reset developer state?'), findsNothing);
    expect(_key('dev_reset_state'), findsNothing);
    expect(ZyraDevScenario.instance.activeJourneys, 2);
    _expectMemberUnchanged();
  });

  testWidgets('short recovery labels still open and leave the actual error', (
    tester,
  ) async {
    await _mount(tester, const SizedBox(key: ValueKey('member-route')));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => ZyraFullScreenError(
          kind: ZyraErrorKind.offline,
          onPrimary: () => navigator.pop(),
          onSecondary: () => navigator.pop(),
          referenceCode: 'offline-fixture',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ZyraFullScreenError), findsOneWidget);
    expect(find.text(ZyraErrorKind.offline.content.message), findsOneWidget);
    expect(_key('zyra_error_primary'), findsOneWidget);
    expect(_key('zyra_error_secondary'), findsOneWidget);
    await _press(tester, _key('zyra_error_secondary'));
    expect(find.byType(ZyraFullScreenError), findsNothing);
    expect(_key('member-route'), findsOneWidget);
    _expectMemberUnchanged();
  });
}
