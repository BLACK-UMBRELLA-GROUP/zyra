import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/main.dart' show ZyraApp, zyraNavigatorKey;
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';

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
  Widget child = const PersonalisationScreen(),
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
                padding: const EdgeInsets.only(top: 59, bottom: 34),
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
    expect(find.text('Personalisation'), findsOneWidget);
  });

  testWidgets('member Gold touch geometry and actions survive rail removal', (
    tester,
  ) async {
    await _mount(tester);
    final toggle = find.byKey(const ValueKey('personalisation_gold_toggle'));
    await tester.scrollUntilVisible(toggle, 160);
    await tester.pumpAndSettle();
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(44));
    expect(toggle.hitTestable(), findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    expect(ZyraAppGoldStyle.instance.enabled, isTrue);
    await tester.tap(toggle);
    await tester.pump();
    expect(ZyraAppGoldStyle.instance.enabled, isFalse);
    _expectNoDoors();
  });

  testWidgets('removed doors leave no eye hit target or developer semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _mount(tester);
      _expectNoDoors();
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      final toggle = find.byKey(const ValueKey('personalisation_gold_toggle'));
      await tester.scrollUntilVisible(toggle, 160);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(toggle).label, contains('Gold accents'));
      expect(tester.widget<Switch>(toggle).onChanged, isNotNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'member content retains caller scroll keys without custom developer doors',
    (tester) async {
      var gold = false;
      const scroll = ValueKey('member-custom-scroll');
      await _mount(
        tester,
        child: Scaffold(
          body: ZyraPersonalisationContent(
            scrollKey: scroll,
            snapshot: const ZyraPersonalisationSnapshot(
              palette: ZyraDevPalette.ivory,
              hapticLevel: ZyraHapticLevel.subtle,
              goldEnabled: false,
            ),
            onChooseHaptic: null,
            onGoldChanged: (value) => gold = value,
          ),
        ),
      );
      expect(find.byKey(scroll), findsOneWidget);
      final toggle = find.byKey(const ValueKey('personalisation_gold_toggle'));
      await tester.scrollUntilVisible(toggle, 160);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pump();
      expect(gold, isTrue);
      expect(find.byKey(const ValueKey('draft_rules')), findsNothing);
      expect(find.byKey(const ValueKey('draft_close')), findsNothing);
      _expectNoDoors();
    },
  );

  testWidgets('Actions selection keeps the existing gold icon and marker', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _mount(
        tester,
        sections: _twoDoors,
        open: true,
        selected: _RetiredDoor.actions,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.tune)).color,
        ZyraColors.unlockText,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.home_outlined)).color,
        Colors.white54,
      );
      expect(
        tester.getSemantics(_door('actions')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(_door('home')).flagsCollection.isSelected,
        Tristate.isFalse,
      );
      expect(_withinRail(find.byType(Positioned)), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'member Gold selection cannot produce a retired rail marker or eye',
    (tester) async {
      await _mount(tester);
      final member = ZyraAppGoldStyle.instance;
      expect(
        member.select(
          true,
          expectedGeneration: ZyraAccountState.generation,
          expectedRevision: member.revision,
        ),
        isTrue,
      );
      await tester.pump();
      final toggle = find.byKey(const ValueKey('personalisation_gold_toggle'));
      await tester.scrollUntilVisible(toggle, 160);
      await tester.pump();
      expect(tester.widget<Switch>(toggle).value, isTrue);
      _expectNoDoors();
      expect(_withinRail(find.byType(Positioned)), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    },
  );

  testWidgets(
    'member choice sheets retain caller order and dispatch their own values',
    (tester) async {
      final selected = <String>[];
      await _mount(
        tester,
        child: Scaffold(
          body: ZyraPersonalisationChoiceSheet<String>(
            title: 'Member choices',
            options: const ['Second choice', 'First choice'],
            selected: 'First choice',
            labelFor: (value) => value,
            onSelected: selected.add,
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('Second choice')).dy,
        lessThan(tester.getTopLeft(find.text('First choice')).dy),
      );
      await tester.tap(find.text('Second choice'));
      await tester.pump();
      expect(selected, ['Second choice']);
      _expectNoDoors();
    },
  );

  for (final role in const ['Seeker', 'Guardian']) {
    for (final size in const [Size(320, 568), Size(393, 852)]) {
      testWidgets(
        '$role member Gold remains reachable at $size and 200% text without developer doors',
        (tester) async {
          ZyraLocalPrefs.setCachedRole(role == 'Seeker' ? 'seeker' : 'wali');
          await _mount(tester, size: size, textScale: 2);
          final toggle = find.byKey(
            const ValueKey('personalisation_gold_toggle'),
          );
          await tester.scrollUntilVisible(toggle, 160);
          await tester.pumpAndSettle();
          final rect = tester.getRect(toggle);
          expect(rect.top, greaterThanOrEqualTo(59));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 34));
          expect(toggle.hitTestable(), findsOneWidget);
          await tester.tap(toggle);
          await tester.pump();
          expect(ZyraAppGoldStyle.instance.enabled, isTrue);
          _expectNoDoors();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
