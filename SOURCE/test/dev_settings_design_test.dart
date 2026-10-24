import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_settings_design.dart';
import 'package:zyra/dev/dev_settings_design_state.dart';
import 'package:zyra/screens/settings/settings_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDevSettingsDesign.select(ZyraSettingsDesign.current);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
  });

  tearDown(() {
    ZyraDevSettingsDesign.select(ZyraSettingsDesign.current);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('Founder can select and open the same Guardian Settings routes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DevSettingsDesignPicker(guardian: true)),
      ),
    );

    expect(ZyraDevSettingsDesign.current, ZyraSettingsDesign.current);
    await tester.tap(
      find.byKey(const ValueKey('dev_settings_design_smoothCards')),
    );
    await tester.pump();
    expect(ZyraDevSettingsDesign.current, ZyraSettingsDesign.smoothCards);

    await tester.tap(find.byKey(const ValueKey('dev_settings_open')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings_smooth_header')),
      findsOneWidget,
    );
    expect(find.text('Linked Seekers'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Guardian privacy'), 200);
    expect(find.text('Guardian privacy'), findsOneWidget);
    expect(find.text('Pause My Profile'), findsOneWidget);
    expect(find.text('Discovery & visibility'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('comparison is absent without Founder preview authority', (
    tester,
  ) async {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DevSettingsDesignPicker(guardian: false)),
      ),
    );
    expect(find.text('Settings design'), findsNothing);
    expect(find.byKey(const ValueKey('dev_settings_open')), findsNothing);

    ZyraDevSettingsDesign.select(ZyraSettingsDesign.smoothCards);
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen(guardian: true)),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('settings_smooth_header')), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('smooth cards fits a compact phone with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ZyraDevSettingsDesign.select(ZyraSettingsDesign.smoothCards);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const SettingsScreen(guardian: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings_smooth_header')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Privacy & data'), 200);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seeker candidate retains seeker privacy destinations', (
    tester,
  ) async {
    ZyraDevSettingsDesign.select(ZyraSettingsDesign.smoothCards);
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
