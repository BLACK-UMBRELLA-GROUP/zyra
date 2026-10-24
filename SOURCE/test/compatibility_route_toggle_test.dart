import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/dev/dev_scenario_panel_v2.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/subscription/profile_unlock_screen.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/services/zyra_unlock_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_gold_action_pill.dart';

const _profile = SeekerProfile(
  id: 'dev-compatibility-route-noor',
  firstName: 'Noor',
  surnameLine: 'Mahmood',
  age: 30,
  city: 'Glasgow',
  photos: <String>[],
  gender: 'female',
);
const _otherProfile = SeekerProfile(
  id: 'dev-compatibility-route-layla',
  firstName: 'Layla',
  surnameLine: 'Hussain',
  age: 29,
  city: 'Manchester',
  photos: <String>[],
  gender: 'female',
);
const _realProfile = SeekerProfile(
  id: '22222222-2222-4222-8222-222222222222',
  firstName: 'Real route sentinel',
  surnameLine: 'Member',
  age: 31,
  city: 'London',
  photos: <String>[],
  gender: 'female',
);
const _browserKey = ValueKey('compatibility-browser-host');
const _openKey = ValueKey('compatibility-browser-open');
const _coverKey = ValueKey('compatibility-covered-route');
const _standard = 'Compatibility Unlock';
const _plus = 'Compatibility Unlock';
const _plusActionKey = ValueKey('compatibility-unlock-Unlock Compatibility');
const _categories = [
  'Lifestyle',
  'Work & Education',
  'Family Values',
  'Marriage Goals',
  'Personality',
  'Deen',
];

ZyraDevSurfaceCoordinator get _coordinator =>
    ZyraDevSurfaceCoordinator.instance;

class _Harness {
  _Harness(this.navigator, this.openedPages);
  final GlobalKey<NavigatorState> navigator;
  final List<DevPage> openedPages;
}

Future<_Harness> _mountBrowser(
  WidgetTester tester, {
  Size viewport = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = GlobalKey<NavigatorState>();
  final controlsRouteObserver = ZyraDevControlsRouteObserver();
  final owner = Object();
  final openedPages = <DevPage>[];
  _coordinator.attachSeeker(owner, (page) {
    openedPages.add(page);
    ZyraDevScenario.instance.setCurrentPage(page);
  });
  addTearDown(() async {
    final state = navigator.currentState;
    if (state != null && state.mounted) {
      while (state.canPop()) {
        state.pop();
      }
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    _coordinator.detachSeeker(owner);
  });
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [controlsRouteObserver],
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: ZyraGlobalDevOverlayHost(
          navigatorKey: navigator,
          routeObserver: controlsRouteObserver,
          authStateChangesOverride: const Stream<AuthState>.empty(),
          authorityLossDestinationBuilder: (_) =>
              const Scaffold(body: Text('Denied operator route')),
          child: child!,
        ),
      ),
      home: Scaffold(
        key: _browserKey,
        body: Builder(
          builder: (context) => Column(
            children: [
              const Text('Browse root'),
              TextButton(
                key: _openKey,
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProfileUnlockScreen(profile: _profile),
                  ),
                ),
                child: const Text('Open this profile’s Compatibility'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(navigator, openedPages);
}

Future<ZyraCompatibilityDevControls> _openCompatibility(
  WidgetTester tester,
) async {
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  final controls = _coordinator.activeCompatibilityControls;
  expect(controls, isNotNull);
  expect(controls!.profileId, _profile.id);
  expect(controls.isCurrent(), isTrue);
  expect(controls.balance(false), 0);
  expect(controls.balance(true), 1);
  expect(find.text('1 left'), findsOneWidget);
  return controls;
}

Future<void> _showControls(WidgetTester tester) async {
  final hold = await tester.startGesture(
    Offset(
      tester.view.physicalSize.width - 8,
      tester.view.physicalSize.height / 2,
    ),
  );
  await tester.pump(const Duration(seconds: 3));
  await hold.up();
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('dev_controls_close')), findsOneWidget);
}

Future<void> _openActions(WidgetTester tester) async {
  await _showControls(tester);
  expect(
    find
        .descendant(
          of: find.byType(DevScenarioPanelV2),
          matching: find.text('Compatibility'),
        )
        .hitTestable(),
    findsOneWidget,
  );
}

ZyraDevPageOptions _pageOptions(WidgetTester tester) =>
    tester.widget<ZyraDevPageOptions>(
      find.byKey(const ValueKey('seeker_page_options')),
    );

Future<void> _chooseBalance(
  WidgetTester tester, {
  required bool plus,
  required int count,
}) async {
  final group = plus ? _plus : _standard;
  final dropdown = find.byKey(ValueKey('dev_page_options_dropdown_$group'));
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  expect(dropdown.hitTestable(), findsOneWidget);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final option = find.byKey(
    ValueKey('compatibility-${plus ? 'plus' : 'standard'}-$count'),
  );
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  expect(option.hitTestable(), findsOneWidget);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> _closeActions(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey('dev_controls_close')).hitTestable(),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectDemoResult(WidgetTester tester) async {
  final notice = find.byKey(const ValueKey('compatibility-demo-notice'));
  await tester.ensureVisible(notice);
  await tester.pumpAndSettle();
  expect(notice.hitTestable(), findsOneWidget);
  expect(
    find.descendant(of: notice, matching: find.text('Developer demo')),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: notice,
      matching: find.textContaining('not calculated from answers'),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: notice,
      matching: find.textContaining('No real unlocks are used.'),
    ),
    findsOneWidget,
  );
  expect(
    find.byKey(const ValueKey('compatibility-demo-result')),
    findsOneWidget,
  );
  expect(find.text('Sample category percentages'), findsOneWidget);
  expect(find.text('__%'), findsNothing);
  expect(find.textContaining(RegExp(r'^\d+%$')), findsNWidgets(19));
  for (final category in _categories) {
    final row = find.byKey(ValueKey('compatibility-exact-row-$category'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    expect(row.hitTestable(), findsOneWidget);
    final percentages = tester
        .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
        .map((text) => text.data ?? '')
        .where((text) => RegExp(r'^\d+%$').hasMatch(text))
        .map((text) => int.parse(text.substring(0, text.length - 1)))
        .toList();
    expect(percentages, hasLength(3), reason: category);
    expect(percentages.every((value) => value >= 0 && value <= 100), isTrue);
    expect(
      percentages.reduce((sum, value) => sum + value),
      100,
      reason: category,
    );
    expect(find.descendant(of: row, matching: find.text('—')), findsNothing);
  }
  final guardian = find.byKey(const ValueKey('compatibility-demo-guardian'));
  await tester.ensureVisible(guardian);
  await tester.pumpAndSettle();
  expect(guardian.hitTestable(), findsOneWidget);
  expect(
    find.descendant(
      of: guardian,
      matching: find.text('Main Guardian · Fictional example'),
    ),
    findsOneWidget,
  );
}

void _expectNoBackend() {
  // Deliberately never initialise Supabase in this suite. A local sample
  // cannot hide an attempted live transport behind a successful mock server.
  expect(() => Supabase.instance.client, throwsAssertionError);
  expect(ZyraProductTelemetry.instance.snapshot.remoteAcceptedCount, 0);
  expect(ZyraProductTelemetry.instance.snapshot.remoteFailureCount, 0);
}

void main() {
  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.finishSignOut();
    _coordinator.resetForTesting();
    ZyraUnlockService.clearForSignOut();
    ZyraDevScenario.instance.reset();
    ZyraDevScenario.instance.setCurrentPage(DevPage.browse);
    ZyraProductTelemetry.instance.resetForTest();
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    _coordinator.resetForTesting();
    ZyraUnlockService.clearForSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraProductTelemetry.instance.resetForTest();
    ZyraText.useTestFontStubs = false;
  });

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0),
    (size: Size(320, 568), scale: 1.3),
  ]) {
    testWidgets(
      'real route toggle has one reachable credit group at ${viewport.size.width}/${viewport.scale}',
      (tester) async {
        await _mountBrowser(
          tester,
          viewport: viewport.size,
          textScale: viewport.scale,
        );
        await _openCompatibility(tester);
        await _openActions(tester);
        final options = _pageOptions(tester).options;
        expect(options.map((option) => option.id).toSet(), {
          'compatibility-plus-0',
          'compatibility-plus-1',
          'compatibility-plus-5',
        });
        expect(options.map((option) => option.group).toSet(), {_plus});
        expect(
          options
              .singleWhere((option) => option.id == 'compatibility-plus-5')
              .label,
          '5 Compatibility Unlocks',
        );
        for (final plus in const [true]) {
          final dropdown = find.byKey(
            ValueKey('dev_page_options_dropdown_${plus ? _plus : _standard}'),
          );
          await tester.ensureVisible(dropdown);
          await tester.pumpAndSettle();
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          for (final count in const [0, 1, 5]) {
            final choice = find.byKey(
              ValueKey('compatibility-${plus ? 'plus' : 'standard'}-$count'),
            );
            await tester.ensureVisible(choice);
            await tester.pumpAndSettle();
            expect(choice.hitTestable(), findsOneWidget);
            expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
          }
          await tester.ensureVisible(dropdown);
          await tester.pumpAndSettle();
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
        }
        _expectNoBackend();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'five unified credits are exact and idempotent without a legacy balance',
    (tester) async {
      final initialPlan = AppState.instance.plan;
      final initialGender = AppState.instance.gender;
      await _mountBrowser(tester);
      final controls = await _openCompatibility(tester);
      await _openActions(tester);
      expect(controls.balance(false), 0);
      await _chooseBalance(tester, plus: true, count: 5);
      expect(controls.balance(false), 0);
      expect(controls.balance(true), 5);
      for (final plus in const [true]) {
        await _chooseBalance(tester, plus: plus, count: 5);
      }
      expect(controls.balance(false), 0);
      expect(controls.balance(true), 5);
      expect(
        _pageOptions(tester).options
            .where((option) => option.selected)
            .map((option) => option.id)
            .toSet(),
        {'compatibility-plus-5'},
      );
      expect(AppState.instance.plan, initialPlan);
      expect(AppState.instance.gender, initialGender);
      expect(find.byType(UpgradeScreen), findsNothing);
      _expectNoBackend();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('zero, one, and five assign only the unified route balance', (
    tester,
  ) async {
    await _mountBrowser(tester);
    final controls = await _openCompatibility(tester);
    await _openActions(tester);
    for (final plus in const [true]) {
      final other = controls.balance(!plus);
      for (final count in const [0, 1, 5]) {
        await _chooseBalance(tester, plus: plus, count: count);
        expect(controls.balance(plus), count);
        expect(controls.balance(!plus), other);
      }
    }
    controls.setBalance(false, 5);
    expect(controls.balance(false), 0);
    expect(controls.balance(true), 5);
    await _chooseBalance(tester, plus: true, count: 0);
    final unlock = tester.widget<ZyraGoldActionPill>(
      find.byKey(const ValueKey('compatibility-unlock-Unlock Compatibility')),
    );
    expect(unlock.onPressed, isNull);
    expect(find.text('none left'), findsOneWidget);
    _expectNoBackend();
    expect(tester.takeException(), isNull);
  });

  testWidgets('one successful sample unlock reveals every section only once', (
    tester,
  ) async {
    await _mountBrowser(tester);
    final controls = await _openCompatibility(tester);
    await _openActions(tester);
    await _chooseBalance(tester, plus: true, count: 5);
    await _closeActions(tester);
    final action = find.byKey(
      const ValueKey('compatibility-unlock-Unlock Compatibility'),
    );
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    final repeated = tester.widget<ZyraGoldActionPill>(action).onPressed!;
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(controls.balance(false), 0);
    expect(controls.balance(true), 4);
    expect(
      ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.standard),
      isFalse,
    );
    expect(ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.plus), isFalse);
    expect(find.text('Use an Unlock+ instead?'), findsNothing);
    repeated();
    await tester.pumpAndSettle();
    expect(controls.balance(false), 0);
    expect(controls.balance(true), 4);
    await _expectDemoResult(tester);
    _expectNoBackend();
    expect(tester.takeException(), isNull);
  });

  testWidgets('unified demo stock does not open the live category-spend fuse', (
    tester,
  ) async {
    await _mountBrowser(tester);
    final controls = await _openCompatibility(tester);
    await _openActions(tester);
    await _chooseBalance(tester, plus: true, count: 5);
    expect(controls.balance(false), 0);
    expect(controls.balance(true), 5);
    await _closeActions(tester);
    expect(ZyraUnlockService.categoryBreakdownAvailable, isFalse);
    expect(ZyraUnlockService.isTierAvailable(UnlockTier.plus), isFalse);
    expect(
      await ZyraUnlockService.unlock(_profile.id, UnlockTier.plus),
      UnlockOutcome.unavailable,
    );
    expect(controls.balance(true), 5);
    expect(ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.plus), isFalse);
    expect(find.text('Unlock Compatibility'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('compatibility-detail-unavailable')),
      findsOneWidget,
    );
    // Choosing demo stock is not revealing demo results. Only the explicit
    // local full-reveal action may replace these locked placeholders.
    expect(find.text('__%'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+\s*%')), findsNothing);
    for (final category in _categories) {
      final row = find.byKey(ValueKey('compatibility-exact-row-$category'));
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text('—')),
        findsNWidgets(3),
      );
      expect(
        find.descendant(of: row, matching: find.textContaining(RegExp(r'\d'))),
        findsNothing,
      );
    }
    _expectNoBackend();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'default unified demo reveals clearly labelled coherent local results',
    (tester) async {
      final initialPlan = AppState.instance.plan;
      await _mountBrowser(tester);
      final controls = await _openCompatibility(tester);
      final action = find.byKey(_plusActionKey);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.widget<ZyraGoldActionPill>(action).onPressed, isNotNull);
      expect(
        find.byKey(const ValueKey('compatibility-demo-notice')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('compatibility-demo-result')),
        findsNothing,
      );
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(controls.balance(false), 0);
      expect(controls.balance(true), 0);
      expect(find.byKey(_plusActionKey), findsNothing);
      await _expectDemoResult(tester);
      expect(ZyraUnlockService.categoryBreakdownAvailable, isFalse);
      expect(
        ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.standard),
        isFalse,
      );
      expect(
        ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.plus),
        isFalse,
      );
      expect(AppState.instance.plan, initialPlan);
      expect(find.byType(CompatibilityUnlockStoreScreen), findsNothing);
      _expectNoBackend();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'five-credit demo double tap and saved callback spend one unified credit',
    (tester) async {
      await _mountBrowser(tester);
      final controls = await _openCompatibility(tester);
      await _openActions(tester);
      await _chooseBalance(tester, plus: true, count: 5);
      await _closeActions(tester);
      final action = find.byKey(_plusActionKey);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      final repeated = tester.widget<ZyraGoldActionPill>(action).onPressed!;
      await tester.tap(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(controls.balance(false), 0);
      expect(controls.balance(true), 4);
      repeated();
      repeated();
      await tester.pumpAndSettle();
      expect(controls.balance(false), 0);
      expect(controls.balance(true), 4);
      await _expectDemoResult(tester);
      expect(
        ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.standard),
        isFalse,
      );
      expect(
        ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.plus),
        isFalse,
      );
      _expectNoBackend();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'zero unified credits disables demo and rejects its enabled callback',
    (tester) async {
      await _mountBrowser(tester);
      final controls = await _openCompatibility(tester);
      final stalePlus = tester
          .widget<ZyraGoldActionPill>(find.byKey(_plusActionKey))
          .onPressed!;
      await _openActions(tester);
      await _chooseBalance(tester, plus: true, count: 0);
      await _closeActions(tester);
      expect(
        tester.widget<ZyraGoldActionPill>(find.byKey(_plusActionKey)).onPressed,
        isNull,
      );
      stalePlus();
      await tester.pumpAndSettle();
      expect(controls.balance(false), 0);
      expect(controls.balance(true), 0);
      expect(
        find.byKey(const ValueKey('compatibility-demo-result')),
        findsNothing,
      );
      expect(find.text('__%'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\d+%$')), findsNothing);
      expect(
        ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.plus),
        isFalse,
      );
      _expectNoBackend();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reopening a unified demo route resets its result and local balance',
    (tester) async {
      final harness = await _mountBrowser(tester);
      final first = await _openCompatibility(tester);
      final action = find.byKey(_plusActionKey);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      final stalePlus = tester.widget<ZyraGoldActionPill>(action).onPressed!;
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(first.balance(true), 0);
      expect(
        find.byKey(const ValueKey('compatibility-demo-result')),
        findsOneWidget,
      );
      harness.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      final second = await _openCompatibility(tester);
      stalePlus();
      await tester.pumpAndSettle();
      expect(second, isNot(same(first)));
      expect(second.balance(false), 0);
      expect(second.balance(true), 1);
      expect(first.balance(true), 0);
      expect(
        find.byKey(const ValueKey('compatibility-demo-result')),
        findsNothing,
      );
      expect(find.text('__%'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\d+%$')), findsNothing);
      expect(
        ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.standard),
        isFalse,
      );
      expect(
        ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.plus),
        isFalse,
      );
      _expectNoBackend();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('authority revocation clears an already revealed full demo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
    );
    await tester.pumpAndSettle();
    final controls = _coordinator.activeCompatibilityControls!;
    final action = find.byKey(_plusActionKey);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    final stalePlus = tester.widget<ZyraGoldActionPill>(action).onPressed!;
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('compatibility-demo-result')),
      findsOneWidget,
    );
    expect(controls.balance(true), 0);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    stalePlus();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('compatibility-preview-denied')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compatibility-demo-result')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('compatibility-demo-notice')),
      findsNothing,
    );
    expect(find.textContaining(RegExp(r'^\d+%$')), findsNothing);
    expect(controls.balance(true), 0);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('compatibility-demo-result')),
      findsNothing,
    );
    expect(find.text('__%'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d+%$')), findsNothing);
    expect(controls.balance(false), 0);
    expect(controls.balance(true), 0);
    expect(ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.plus), isFalse);
    _expectNoBackend();
    expect(tester.takeException(), isNull);
  });

  testWidgets('covered route rejects its old option and direct setter', (
    tester,
  ) async {
    final harness = await _mountBrowser(tester);
    final first = await _openCompatibility(tester);
    await _openActions(tester);
    final oldOption = _pageOptions(tester).options
        .singleWhere((option) => option.id == 'compatibility-plus-5')
        .onSelected!;
    final stalePlus = tester
        .widget<ZyraGoldActionPill>(find.byKey(_plusActionKey))
        .onPressed!;
    harness.navigator.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) =>
            const Scaffold(key: _coverKey, body: Text('Cover route')),
      ),
    );
    await tester.pumpAndSettle();
    expect(_coordinator.activeCompatibilityControls, isNull);
    expect(first.isCurrent(), isFalse);
    first.setBalance(false, 5);
    first.setBalance(true, 5);
    await oldOption();
    stalePlus();
    await tester.pumpAndSettle();
    expect(first.balance(false), 0);
    expect(first.balance(true), 1);
    harness.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_coordinator.activeCompatibilityControls, same(first));
    expect(first.isCurrent(), isTrue);
    expect(find.text('__%'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+\s*%')), findsNothing);
    expect(ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.plus), isFalse);
    _expectNoBackend();
    expect(tester.takeException(), isNull);
  });

  testWidgets('another sample starts independently and rejects the old owner', (
    tester,
  ) async {
    final harness = await _mountBrowser(tester);
    final first = await _openCompatibility(tester);
    await _openActions(tester);
    final oldOption = _pageOptions(tester).options
        .singleWhere((option) => option.id == 'compatibility-plus-5')
        .onSelected!;
    final stalePlus = tester
        .widget<ZyraGoldActionPill>(find.byKey(_plusActionKey))
        .onPressed!;
    harness.navigator.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => const ProfileUnlockScreen(profile: _otherProfile),
      ),
    );
    await tester.pumpAndSettle();
    final second = _coordinator.activeCompatibilityControls!;
    expect(second.profileId, _otherProfile.id);
    expect(second.balance(false), 0);
    expect(second.balance(true), 1);
    expect(first.isCurrent(), isFalse);
    first.setBalance(false, 5);
    first.setBalance(true, 5);
    await oldOption();
    stalePlus();
    await tester.pumpAndSettle();
    expect(first.balance(false), 0);
    expect(first.balance(true), 1);
    expect(second.balance(false), 0);
    expect(second.balance(true), 1);
    expect(find.text('__%'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+\s*%')), findsNothing);
    harness.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_coordinator.activeCompatibilityControls, same(first));
    _expectNoBackend();
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing returns Browse and rejects disposed callbacks', (
    tester,
  ) async {
    final harness = await _mountBrowser(tester);
    final controls = await _openCompatibility(tester);
    await _openActions(tester);
    await _chooseBalance(tester, plus: true, count: 5);
    final oldOption = _pageOptions(tester).options
        .singleWhere((option) => option.id == 'compatibility-plus-5')
        .onSelected!;
    final stalePlus = tester
        .widget<ZyraGoldActionPill>(find.byKey(_plusActionKey))
        .onPressed!;
    await _closeActions(tester);
    await tester.tap(find.byTooltip('Back').hitTestable());
    await tester.pumpAndSettle();
    expect(find.byKey(_browserKey), findsOneWidget);
    expect(harness.navigator.currentState!.canPop(), isFalse);
    expect(_coordinator.activeCompatibilityControls, isNull);
    controls.setBalance(false, 0);
    controls.setBalance(true, 5);
    await oldOption();
    stalePlus();
    await tester.pumpAndSettle();
    expect(controls.balance(false), 0);
    expect(controls.balance(true), 5);
    await _showControls(tester);
    expect(find.text('Profiles').hitTestable(), findsOneWidget);
    expect(
      _pageOptions(
        tester,
      ).options.any((option) => option.id.startsWith('compatibility-')),
      isFalse,
    );
    _coordinator.openSeeker(DevPage.profile);
    expect(harness.openedPages, [DevPage.profile]);
    _expectNoBackend();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reopening the same sample resets route-only balance overrides', (
    tester,
  ) async {
    final harness = await _mountBrowser(tester);
    final first = await _openCompatibility(tester);
    first.setBalance(false, 5);
    first.setBalance(true, 5);
    await tester.pumpAndSettle();
    harness.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    final second = await _openCompatibility(tester);
    expect(second, isNot(same(first)));
    expect(second.balance(false), 0);
    expect(second.balance(true), 1);
    expect(first.balance(false), 0);
    expect(first.balance(true), 5);
    _expectNoBackend();
    expect(tester.takeException(), isNull);
  });

  testWidgets('revoked raw sample denies without a live balance fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
    );
    await tester.pumpAndSettle();
    final controls = _coordinator.activeCompatibilityControls!;
    final staleUnlock = tester
        .widget<ZyraGoldActionPill>(
          find.byKey(
            const ValueKey('compatibility-unlock-Unlock Compatibility'),
          ),
        )
        .onPressed!;
    final stalePlus = tester
        .widget<ZyraGoldActionPill>(find.byKey(_plusActionKey))
        .onPressed!;
    expect(ZyraInternalPreviewClient.isActive, isFalse);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('compatibility-preview-denied')),
      findsOneWidget,
    );
    expect(_coordinator.activeCompatibilityControls, isNull);
    controls.setBalance(false, 5);
    controls.setBalance(true, 5);
    staleUnlock();
    stalePlus();
    await tester.pumpAndSettle();
    expect(controls.balance(false), 0);
    expect(controls.balance(true), 1);
    expect(
      ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.standard),
      isFalse,
    );
    expect(find.text('Unlock Compatibility'), findsNothing);
    expect(find.byKey(_plusActionKey), findsNothing);
    expect(find.textContaining(RegExp(r'\d+\s*%')), findsNothing);
    expect(ZyraUnlockService.isUnlocked(_profile.id, UnlockTier.plus), isFalse);
    _expectNoBackend();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unauthorized sample cannot gain preview mode after construction',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpWidget(
        const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('compatibility-preview-denied')),
        findsOneWidget,
      );
      expect(_coordinator.activeCompatibilityControls, isNull);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('compatibility-preview-denied')),
        findsOneWidget,
      );
      expect(_coordinator.activeCompatibilityControls, isNull);
      expect(find.text('1 left'), findsNothing);
      _expectNoBackend();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('real UUID route never attaches local sample credit controls', (
    tester,
  ) async {
    final harness = await _mountBrowser(tester);
    final first = await _openCompatibility(tester);
    harness.navigator.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => const ProfileUnlockScreen(profile: _realProfile),
      ),
    );
    await tester.pumpAndSettle();
    expect(ZyraUnlockService.isSampleProfile(_realProfile.id), isFalse);
    expect(ZyraUnlockService.developerPreviewScore(_realProfile.id), isNull);
    expect(_coordinator.activeCompatibilityControls, isNull);
    first.setBalance(false, 5);
    expect(first.balance(false), 0);
    expect(find.text('1 left'), findsNothing);
    expect(find.byKey(_plusActionKey), findsNothing);
    expect(find.text('Developer demo'), findsNothing);
    await _showControls(tester);
    expect(
      _pageOptions(
        tester,
      ).options.any((option) => option.id.startsWith('compatibility-')),
      isFalse,
    );
    _expectNoBackend();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'route balance choices never purchase or change catalogue selection',
    (tester) async {
      final initialPlan = AppState.instance.plan;
      final harness = await _mountBrowser(tester);
      harness.navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const CompatibilityUnlockStoreScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('draft_compatibility_store_use_unlocks')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('draft_compatibility_store_use_guidance')),
        findsNothing,
      );
      for (final offer in const ['unlock_single', 'unlock_three']) {
        final add = find.byKey(ValueKey('draft_compatibility_store_$offer'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        await tester.tap(add);
        await tester.pumpAndSettle();
      }
      final selected = find.byKey(
        const ValueKey('draft_compatibility_store_unlock_three_selection'),
      );
      expect(tester.widget<Semantics>(selected).properties.selected, isTrue);
      harness.navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const ProfileUnlockScreen(profile: _profile),
        ),
      );
      await tester.pumpAndSettle();
      final controls = _coordinator.activeCompatibilityControls!;
      await _openActions(tester);
      await _chooseBalance(tester, plus: true, count: 5);
      expect(controls.balance(false), 0);
      expect(controls.balance(true), 5);
      await _closeActions(tester);
      await tester.tap(find.byTooltip('Back').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(CompatibilityUnlockStoreScreen), findsOneWidget);
      expect(tester.widget<Semantics>(selected).properties.selected, isTrue);
      expect(find.byKey(const ValueKey('compatibility-basket')), findsNothing);
      final continueButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('draft_compatibility_store_continue')),
      );
      expect(continueButton.onPressed, isNull);
      expect(find.textContaining('£6.99'), findsWidgets);
      expect(find.textContaining('22%'), findsWidgets);
      expect(find.text('Purchase terms'), findsOneWidget);
      expect(find.text('Purchasing isn’t available yet.'), findsOneWidget);
      expect(AppState.instance.plan, initialPlan);
      _expectNoBackend();
      expect(tester.takeException(), isNull);
    },
  );
}
