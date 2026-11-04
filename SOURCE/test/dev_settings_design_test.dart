import 'visual/baseline_capture_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/settings/settings_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
  });

  tearDown(() {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  testWidgets(
    'Founder opens the current Guardian Settings without a design picker',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(guardian: true)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dev_settings_open')), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings_smooth_header')),
        findsNothing,
      );
      expect(find.text('Linked Seekers'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Guardian privacy'), 200);
      expect(find.text('Guardian privacy'), findsOneWidget);
      expect(find.text('Pause My Profile'), findsOneWidget);
      expect(find.text('Discovery & visibility'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('comparison is absent without Founder preview authority', (
    tester,
  ) async {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen(guardian: false)),
    );
    expect(find.text('Settings design'), findsNothing);
    expect(find.byKey(const ValueKey('dev_settings_open')), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen(guardian: true)),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('settings_smooth_header')), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('current Settings fits a compact phone with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const evidence =
        '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE/.buildlog/queue44_20261103/settings';
    await tester.runAsync(() => baselineSetUp(evidenceRoot: evidence));
    addTearDown(baselineTearDown);
    final h = BaselineHarness(
      tester,
      group: 'settings-removal',
      outputRoot: evidence,
      evidenceRoot: evidence,
      textScale: 1.3,
    );
    await h.mount(guardian: true, tab: 3, pages: ['settings']);
    tester.view.physicalSize = const Size(960, 1704);
    await h.flush();
    expect(find.byKey(const ValueKey('settings_smooth_header')), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_settings_open')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seeker current Settings retains seeker privacy destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen(guardian: false)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pause My Profile'), 200);
    expect(find.text('Pause My Profile'), findsOneWidget);
    expect(find.text('Discovery & visibility'), findsNothing);
    expect(find.text('Guardian privacy'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
