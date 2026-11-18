import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

Future<void> mount(
  WidgetTester tester, {
  required List<String> names,
  required List<String> actions,
  Size size = const Size(402, 874),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: ZyraGuardianTabsPresentation(
          state: ZyraGuardianTabsState(),
          page: 'network',
          paid: false,
          linked: names.isNotEmpty,
          linkedSeekerNames: names,
          seekerGender: 'male',
          photoFor: (_) => null,
          onAction: actions.add,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Poppins');
    for (final weight in ['Light', 'Regular', 'Medium']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
  });
  for (final names in <List<String>>[
    [],
    ['Adam'],
    ['Adam', 'Yusuf'],
  ]) {
    testWidgets('Network gate uses linked Seeker count ${names.length}', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final actions = <String>[];
      await mount(tester, names: names, actions: actions);
      final who = names.length == 1 ? 'Adam' : 'your Seekers';
      final suggestion = names.length == 1 ? 'Adam' : 'one of your Seekers';
      expect(find.text('Introduce someone to $who'), findsOneWidget);
      expect(
        find.text('Suggest a profile for $suggestion to look at'),
        findsOneWidget,
      );
      expect(
        find.text('Everything else you do for $who stays the same.'),
        findsOneWidget,
      );
      expect(find.text('Network is part\nof Guardian One'), findsOneWidget);
      expect(find.text('Find other families'), findsOneWidget);
      expect(find.text('Connect with their Guardians'), findsOneWidget);
      expect(
        tester.getSize(
          find.byKey(const ValueKey('guardian_network_lock_circle')),
        ),
        const Size(102, 102),
      );
      final button = find.byKey(const ValueKey('guardian_network_membership'));
      expect(tester.getSize(button).width, 362);
      expect(
        tester.getRect(button).bottom,
        874 - 34 - ZyraNavBarMetrics.height - ZyraNavBarMetrics.contentGap,
      );
      await tester.tap(button);
      expect(actions, ['membership']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Small phone with larger text keeps all gate content reachable', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final actions = <String>[];
    await mount(
      tester,
      names: ['Adam', 'Yusuf'],
      actions: actions,
      size: const Size(320, 568),
      scale: 1.3,
    );
    expect(tester.takeException(), isNull);
    final button = find.byKey(const ValueKey('guardian_network_membership'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    expect(actions, ['membership']);
    expect(tester.takeException(), isNull);
  });
}
