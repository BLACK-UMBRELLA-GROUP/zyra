import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/theme/zyra_colors.dart';

const _twoDoors = [ZyraDevControlSection.home, ZyraDevControlSection.actions];

Future<void> _mount(
  WidgetTester tester, {
  List<ZyraDevControlSection>? sections,
  bool open = false,
  ZyraDevControlSection selected = ZyraDevControlSection.home,
  ValueChanged<ZyraDevControlSection>? onSelected,
  Map<ZyraDevControlSection, Key> buttonKeys = const {},
  Map<ZyraDevControlSection, String> labels = const {},
  Size size = const Size(393, 852),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: ZyraDevControlRail.width,
            child: ZyraDevControlRail(
              open: open,
              selected: selected,
              onSelected: onSelected ?? (_) {},
              buttonKeys: buttonKeys,
              labels: labels,
              visibleSections: sections ?? ZyraDevControlSection.values,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Finder _door(String name) => find.byKey(ValueKey('dev_rail_$name'));
Finder _withinRail(Finder matching) =>
    find.descendant(of: find.byType(ZyraDevControlRail), matching: matching);

void main() {
  test('legacy constructor retains the three-door default', () {
    final rail = ZyraDevControlRail(
      open: false,
      selected: ZyraDevControlSection.home,
      onSelected: (_) {},
    );
    expect(rail.visibleSections, ZyraDevControlSection.values);
  });

  testWidgets('legacy default keeps icons, order and touch geometry', (
    tester,
  ) async {
    final selections = <ZyraDevControlSection>[];
    await _mount(tester, onSelected: selections.add);
    for (final section in ZyraDevControlSection.values) {
      final target = _door(section.name);
      expect(target, findsOneWidget);
      expect(target.hitTestable(), findsOneWidget);
      expect(tester.getSize(target), const Size(36, 48));
      expect(find.byIcon(section.icon), findsOneWidget);
      await tester.tap(target);
    }
    expect(selections, ZyraDevControlSection.values);
    expect(
      tester.getRect(_door('home')).bottom,
      tester.getRect(_door('preview')).top,
    );
    expect(
      tester.getRect(_door('preview')).bottom,
      tester.getRect(_door('actions')).top,
    );
  });

  testWidgets('two doors omit the eye, its hit target and semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final selections = <ZyraDevControlSection>[];
      await _mount(tester, sections: _twoDoors, onSelected: selections.add);
      expect(_door('home'), findsOneWidget);
      expect(_door('actions'), findsOneWidget);
      expect(_door('preview'), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(_withinRail(find.byType(InkWell)), findsNWidgets(2));
      expect(_withinRail(find.byType(Tooltip)), findsNWidgets(2));
      expect(
        find.bySemanticsLabel(RegExp('Preview|Sample preview controls')),
        findsNothing,
      );
      for (final section in _twoDoors) {
        final target = _door(section.name);
        expect(tester.getSize(target), const Size(36, 48));
        expect(tester.getSemantics(target).flagsCollection.isButton, isTrue);
        await tester.tap(target);
      }
      expect(selections, _twoDoors);
      expect(
        tester.getRect(_door('home')).bottom,
        tester.getRect(_door('actions')).top,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('custom keys and labels survive without the hidden custom eye', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final selections = <ZyraDevControlSection>[];
      await _mount(
        tester,
        sections: _twoDoors,
        onSelected: selections.add,
        buttonKeys: const {
          ZyraDevControlSection.home: ValueKey('draft_close'),
          ZyraDevControlSection.preview: ValueKey('draft_rules'),
          ZyraDevControlSection.actions: ValueKey('draft_back'),
        },
        labels: const {
          ZyraDevControlSection.home: 'Home',
          ZyraDevControlSection.preview: 'Sample preview controls',
          ZyraDevControlSection.actions: 'Actions',
        },
      );
      expect(find.byKey(const ValueKey('draft_rules')), findsNothing);
      expect(_door('home'), findsNothing);
      expect(_door('actions'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Sample preview')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('draft_close')));
      await tester.tap(find.byKey(const ValueKey('draft_back')));
      expect(selections, _twoDoors);
      expect(find.byTooltip('Home'), findsOneWidget);
      expect(find.byTooltip('Actions'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Actions selection keeps the existing gold icon and marker', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _mount(
        tester,
        sections: _twoDoors,
        open: true,
        selected: ZyraDevControlSection.actions,
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

  testWidgets('an omitted selected door never produces a marker or eye', (
    tester,
  ) async {
    await _mount(
      tester,
      sections: _twoDoors,
      open: true,
      selected: ZyraDevControlSection.preview,
    );
    expect(_withinRail(find.byType(Positioned)), findsNothing);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    expect(
      tester.widgetList<Icon>(find.byType(Icon)).map((icon) => icon.color),
      everyElement(Colors.white54),
    );
  });

  testWidgets('caller order is honoured rather than restored to enum order', (
    tester,
  ) async {
    await _mount(
      tester,
      sections: const [
        ZyraDevControlSection.actions,
        ZyraDevControlSection.home,
      ],
    );
    expect(
      tester.getRect(_door('actions')).bottom,
      tester.getRect(_door('home')).top,
    );
  });

  for (final role in const ['Seeker', 'Guardian']) {
    for (final size in const [Size(320, 568), Size(393, 852)]) {
      testWidgets('$role two doors stay compact at $size and 200% text', (
        tester,
      ) async {
        final selections = <ZyraDevControlSection>[];
        await _mount(
          tester,
          sections: _twoDoors,
          size: size,
          textScale: 2,
          labels: {
            ZyraDevControlSection.home: '$role Home',
            ZyraDevControlSection.actions: '$role Actions',
          },
          onSelected: selections.add,
        );
        expect(find.byIcon(Icons.visibility_outlined), findsNothing);
        for (final section in _twoDoors) {
          final target = _door(section.name);
          final rect = tester.getRect(target);
          expect(rect.width, 36);
          expect(rect.height, 48);
          expect(rect.right, size.width);
          expect(rect.top, greaterThanOrEqualTo(59));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 34));
          expect(target.hitTestable(), findsOneWidget);
          await tester.tap(target);
        }
        expect(selections, _twoDoors);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
