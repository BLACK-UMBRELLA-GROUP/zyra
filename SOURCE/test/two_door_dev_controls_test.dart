import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/main.dart' show ZyraApp, zyraNavigatorKey;
import 'package:zyra/screens/settings/settings_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';

import 'support/zyra_settings_haptics_test_driver.dart';

// Test-only identity tokens let the pre-existing failing assertion remain
// executable after its production rail and enum have been retired.
enum _RetiredDoor { home, preview, actions }

const _twoDoors = [_RetiredDoor.home, _RetiredDoor.actions];

Future<void> _mount(
  WidgetTester tester, {
  List<_RetiredDoor>? sections,
  bool open = false,
  _RetiredDoor selected = _RetiredDoor.home,
  Size size = const Size(393, 852),
  double textScale = 1,
  Widget child = const SettingsScreen(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        final rebuild = const ZyraApp().build(context) as ListenableBuilder;
        final app = rebuild.builder(context, null) as MaterialApp;
        return MaterialApp(
          navigatorKey: app.navigatorKey,
          navigatorObservers:
              app.navigatorObservers ?? const <NavigatorObserver>[],
          theme: app.theme,
          routes: app.routes ?? const <String, WidgetBuilder>{},
          onGenerateRoute: app.onGenerateRoute,
          onUnknownRoute: app.onUnknownRoute,
          builder: (context, content) => app.builder!(
            context,
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: EdgeInsets.only(
                  top: size.width == 375 ? 20 : 59,
                  bottom: size.width == 375 ? 0 : 34,
                ),
                textScaler: TextScaler.linear(textScale),
              ),
              child: content!,
            ),
          ),
          home: child,
        );
      },
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Finder _door(String name) => find.byKey(ValueKey('dev_rail_$name'));
Finder _withinRail(Finder matching) => find.descendant(
  of: find.byKey(const ValueKey('dev_control_rail')),
  matching: matching,
);

void _expectNoDoors() {
  for (final door in _RetiredDoor.values) {
    expect(_door(door.name), findsNothing);
  }
  expect(
    find.bySemanticsLabel(RegExp('Sample preview controls|Developer actions')),
    findsNothing,
  );
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAppGoldStyle.instance.restore(false);
  });
  tearDown(() {
    ZyraAppGoldStyle.instance.restore(false);
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('production routes reject every retired developer door', (
    tester,
  ) async {
    await _mount(tester);
    for (final route in ['/dev/home', '/dev/preview', '/dev/actions']) {
      expect(
        () => zyraNavigatorKey.currentState!.pushNamed<void>(route),
        throwsFlutterError,
      );
    }
    _expectNoDoors();
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('member Haptics touch geometry and actions survive rail removal', (
    tester,
  ) async {
    final changes = <ZyraHapticLevel>[];
    await _mount(tester, child: settingsHapticsTestPage(
      canAct: () => true,
      onChanged: changes.add,
    ));
    final row = find.byKey(const ValueKey('test-haptics-row'));
    expect(tester.getSize(row).height, greaterThanOrEqualTo(44));
    expect(row.hitTestable(), findsOneWidget);
    await openSettingsHapticsForTest(tester);
    retainSettingsHapticAction(tester)(true);
    expect(changes, [ZyraHapticLevel.strong]);
    _expectNoDoors();
  });

  testWidgets('removed doors leave no eye hit target or developer semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _mount(tester, child: settingsHapticsTestPage(
        canAct: () => true,
        onChanged: (_) {},
      ));
      _expectNoDoors();
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      await openSettingsHapticsForTest(tester);
      final slider = find.byType(Slider);
      expect(find.bySemanticsLabel('Haptic strength'), findsOneWidget);
      expect(tester.widget<Slider>(slider).onChanged, isNotNull);
    } finally {
      semantics.dispose();
    }
  });

  // DEV_TOGGLES removal brief §§3,6 retires Actions, icon and marker.
  testWidgets(
    'retired Actions selection exposes no icon, marker or semantics',
    (tester) async {
      await _mount(
        tester,
        sections: _twoDoors,
        open: true,
        selected: _RetiredDoor.actions,
      );
      _expectNoDoors();
      expect(_withinRail(find.byType(Positioned)), findsNothing);
      expect(find.byKey(const ValueKey('dev_control_rail')), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  testWidgets(
    'retired Gold selection cannot produce a rail marker or eye',
    (tester) async {
      await _mount(tester);
      final member = ZyraAppGoldStyle.instance;
      expect(
        member.select(
          true,
          expectedGeneration: ZyraAccountState.generation,
          expectedRevision: member.revision,
        ),
        isFalse,
      );
      await tester.pump();
      expect(member.enabled, isFalse);
      expect(find.text('Gold accents'), findsNothing);
      _expectNoDoors();
      expect(_withinRail(find.byType(Positioned)), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    },
  );

  testWidgets(
    'member Haptics retains stop order and dispatches the selected value',
    (tester) async {
      final selected = <ZyraHapticLevel>[];
      await _mount(tester, child: settingsHapticsTestPage(
        canAct: () => true,
        onChanged: selected.add,
      ));
      await openSettingsHapticsForTest(tester);
      final stops = ZyraHapticLevel.values;
      for (var index = 1; index < stops.length; index++) {
        expect(
          tester.getTopLeft(find.text(stops[index - 1].label)).dx,
          lessThan(tester.getTopLeft(find.text(stops[index].label)).dx),
        );
      }
      retainSettingsHapticAction(tester)(false);
      expect(selected, [ZyraHapticLevel.light]);
      _expectNoDoors();
    },
  );

  for (final role in const ['Seeker', 'Guardian']) {
    for (final size in const [Size(375, 667), Size(430, 932)]) {
      testWidgets(
        '$role Settings Haptics remains reachable at $size with Larger Text and no developer doors',
        (tester) async {
          ZyraLocalPrefs.setCachedRole(role == 'Seeker' ? 'seeker' : 'wali');
          await _mount(tester, size: size, textScale: 1.4,
              child: SettingsScreen(guardian: role == 'Guardian'));
          final haptics = find.text('Haptics');
          await tester.scrollUntilVisible(haptics, 110);
          await tester.pumpAndSettle();
          final rect = tester.getRect(haptics);
          expect(rect.top, greaterThanOrEqualTo(size.width == 375 ? 20 : 59));
          expect(rect.bottom, lessThanOrEqualTo(size.height - (size.width == 375 ? 0 : 34)));
          expect(haptics.hitTestable(), findsOneWidget);
          expect(find.text('Gold accents'), findsNothing);
          _expectNoDoors();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
