import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_scenario_panel_v2.dart';
import 'package:zyra/dev/wali_dev_scenario_panel.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/dev/zyra_dev_local_preview.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

const _actions = [
  ('dev_home_navigation', 'Home'),
  ('dev_home_login', 'Restart at login'),
  ('dev_reset_state', 'Reset account'),
  ('dev_switch_accounts', 'Switch test account'),
];

Widget _tools({
  bool busy = false,
  double textScale = 1,
  VoidCallback? home,
  VoidCallback? restart,
  VoidCallback? reset,
  VoidCallback? accounts,
  VoidCallback? signup,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: SafeArea(
      child: Center(
        child: SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: ZyraDevHomeTools(
              busy: busy,
              onHome: home ?? () {},
              onRestart: restart ?? () {},
              onReset: reset ?? () {},
              onAccounts: accounts ?? () {},
              onSeekerSignUp: signup ?? () {},
              onGuardianSignUp: signup ?? () {},
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder _action(String key) => find.byKey(ValueKey(key));

void _expectCleanHome() {
  for (final section in const [
    'gender',
    'app_gold',
    'mobile_menu',
    'onboarding_transitions',
    'icons',
  ]) {
    expect(_action('dev_home_section_$section'), findsNothing);
  }
  for (final section in const [
    'navigation',
    'discovery_direction',
    'splash',
    'onboarding',
    'settings',
    'account',
  ]) {
    expect(_action('dev_home_section_$section'), findsOneWidget);
  }
  expect(find.text('Preview gender'), findsNothing);
  expect(_action('dev_preview_gender_male'), findsNothing);
  expect(_action('dev_preview_gender_female'), findsNothing);
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevLocalPreview.genderSelection.value = 'male';
  });

  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevLocalPreview.genderSelection.value = 'male';
  });

  for (final (label, panel)
      in <(String, Widget Function(ValueListenable<int>))>[
        (
          'entry',
          (requests) => ZyraEntryDevPanel(
            pageLabel: 'Auth fixture',
            openRequests: requests,
          ),
        ),
        (
          'Seeker',
          (requests) =>
              DevScenarioPanelV2(onOpenPage: (_) {}, openRequests: requests),
        ),
        (
          'Guardian',
          (requests) =>
              WaliDevScenarioPanel(onOpenPage: (_) {}, openRequests: requests),
        ),
      ]) {
    testWidgets(
      '$label Home keeps one Developer Access heading and other headers stay contextual',
      (tester) async {
        final requests = ValueNotifier<int>(0);
        addTearDown(requests.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(fit: StackFit.expand, children: [panel(requests)]),
            ),
          ),
        );
        requests.value++;
        await tester.pumpAndSettle();
        await tester.tap(_action('dev_controls_tab_home').hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('Developer controls'), findsOneWidget);
        expect(find.text('ZYRA DEV · HOME'), findsNothing);
        expect(find.text('Home & accounts'), findsNothing);
        _expectCleanHome();
        for (final (key, title) in _actions) {
          expect(_action(key), findsOneWidget);
          expect(
            find.descendant(of: _action(key), matching: find.text(title)),
            findsOneWidget,
          );
        }
        expect(_action('dev_signup_seeker'), findsNothing);
        expect(_action('dev_signup_guardian'), findsNothing);
        await tester.tap(_action('dev_controls_tab_actions').hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('Developer controls'), findsOneWidget);
        expect(find.text('ZYRA DEV · ACTIONS'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(ZyraDevPageOptions),
            matching: find.text('Page options'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'Home leads with a separate Home action and preserves account actions',
    (tester) async {
      await tester.pumpWidget(_tools());
      _expectCleanHome();
      expect(
        tester.getTopLeft(_action('dev_home_navigation')).dy,
        lessThan(
          tester.getTopLeft(_action('dev_home_section_discovery_direction')).dy,
        ),
      );
      expect(
        find.descendant(
          of: _action('dev_home_section_navigation'),
          matching: _action('dev_home_navigation'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _action('dev_home_navigation'),
          matching: find.byIcon(Icons.home_outlined),
        ),
        findsOneWidget,
      );
      var previousBottom = double.negativeInfinity;
      for (final (key, title) in _actions) {
        final action = _action(key);
        expect(action, findsOneWidget);
        expect(
          find.descendant(of: action, matching: find.byType(Text)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: action, matching: find.text(title)),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(action).dy,
          greaterThanOrEqualTo(previousBottom),
        );
        expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
        expect(tester.getSize(action).height, lessThan(62));
        previousBottom = tester.getBottomLeft(action).dy;
      }
      for (final label in [
        'Home & accounts',
        'READY-MADE ACCOUNTS',
        'START SIGN-UP',
        'Restart at Welcome',
        'Reset developer state',
        'Sign Up — Seeker',
        'Sign Up — Guardian',
      ]) {
        expect(find.text(label), findsNothing);
      }
      expect(find.textContaining('Restart the app, reset'), findsNothing);
      expect(find.textContaining('Signs out and replays'), findsNothing);
      expect(find.textContaining('Clears supported scenarios'), findsNothing);
      expect(
        find.textContaining('Founder verification is required'),
        findsNothing,
      );
      expect(_action('dev_signup_seeker'), findsNothing);
      expect(_action('dev_signup_guardian'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the four Home actions each invoke only their supplied callback once',
    (tester) async {
      var restarts = 0;
      var resets = 0;
      var switches = 0;
      var signups = 0;
      var homes = 0;
      await tester.pumpWidget(
        _tools(
          home: () => homes++,
          restart: () => restarts++,
          reset: () => resets++,
          accounts: () => switches++,
          signup: () => signups++,
        ),
      );
      await tester.tap(_action('dev_home_navigation'));
      expect([homes, restarts, resets, switches, signups], [1, 0, 0, 0, 0]);
      await tester.ensureVisible(_action('dev_home_login'));
      await tester.pumpAndSettle();
      await tester.tap(_action('dev_home_login'));
      expect([restarts, resets, switches, signups], [1, 0, 0, 0]);
      await tester.ensureVisible(_action('dev_reset_state'));
      await tester.pumpAndSettle();
      await tester.tap(_action('dev_reset_state'));
      expect([restarts, resets, switches, signups], [1, 1, 0, 0]);
      await tester.ensureVisible(_action('dev_switch_accounts'));
      await tester.pumpAndSettle();
      await tester.tap(_action('dev_switch_accounts'));
      expect([restarts, resets, switches, signups], [1, 1, 1, 0]);
      expect(homes, 1);
    },
  );

  testWidgets(
    'busy reset disables Home and reset without changing account callbacks',
    (tester) async {
      var resets = 0;
      var restarts = 0;
      var switches = 0;
      var homes = 0;
      await tester.pumpWidget(
        _tools(
          busy: true,
          home: () => homes++,
          reset: () => resets++,
          restart: () => restarts++,
          accounts: () => switches++,
        ),
      );
      expect(find.text('Resetting…'), findsOneWidget);
      expect(
        tester
            .widget<InkWell>(
              find.descendant(
                of: _action('dev_home_navigation'),
                matching: find.byType(InkWell),
              ),
            )
            .onTap,
        isNull,
      );
      await tester.tap(_action('dev_home_navigation'));
      expect(homes, 0);
      final resetInk = tester.widget<InkWell>(
        find.descendant(
          of: _action('dev_reset_state'),
          matching: find.byType(InkWell),
        ),
      );
      expect(resetInk.onTap, isNull);
      await tester.ensureVisible(_action('dev_reset_state'));
      await tester.pumpAndSettle();
      await tester.tap(_action('dev_reset_state'));
      _expectCleanHome();
      expect(resets, 0);
      expect(ZyraDevLocalPreview.genderSelection.value, 'male');
      await tester.ensureVisible(_action('dev_home_login'));
      await tester.pumpAndSettle();
      await tester.tap(_action('dev_home_login'));
      await tester.ensureVisible(_action('dev_switch_accounts'));
      await tester.pumpAndSettle();
      await tester.tap(_action('dev_switch_accounts'));
      expect([restarts, switches], [1, 1]);
    },
  );

  testWidgets(
    'the simplified Home panel fits narrow large text and remains actionable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var taps = 0;
      await tester.pumpWidget(
        _tools(
          textScale: 2,
          home: () => taps++,
          restart: () => taps++,
          reset: () => taps++,
          accounts: () => taps++,
        ),
      );
      _expectCleanHome();
      for (final (key, title) in _actions) {
        final action = _action(key);
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
        await tester.tap(action);
        expect(tester.takeException(), isNull);
      }
      expect(taps, 4);
    },
  );
}
