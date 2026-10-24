import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_app_icon_directions.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/services/zyra_dev_app_icon.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('zyra.test/icon-preview');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var readCalls = 0;
  var writeCalls = 0;
  String? activeIcon;

  ZyraDevAppIconController controller() =>
      ZyraDevAppIconController(channel: channel, isIOSOverride: true);

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    readCalls = 0;
    writeCalls = 0;
    activeIcon = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAppIconState') {
        readCalls++;
      } else {
        expect(call.method, 'setAppIcon');
        writeCalls++;
        activeIcon = (call.arguments as Map)['iconName'] as String?;
      }
      return {'supported': true, 'iconName': activeIcon};
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('Home keeps splash directions without icon previews or writes', (
    tester,
  ) async {
    var restarts = 0;
    var closes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZyraDevHomeTools(
              busy: false,
              onHome: () {},
              onRestart: () => restarts++,
              onReset: null,
              onAccounts: () {},
              onSeekerSignUp: () {},
              onGuardianSignUp: () {},
              onOpenSplashPreview: () => closes++,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Splash directions'), findsOneWidget);
    expect(find.text('App icon directions'), findsNothing);
    expect(find.byType(DevAppIconDirectionPicker), findsNothing);
    expect(find.byKey(const ValueKey('dev_home_section_icons')), findsNothing);
    for (final icon in ZyraDevAppIcon.values) {
      expect(find.byKey(ValueKey('dev_app_icon_${icon.name}')), findsNothing);
    }
    expect(find.byType(DevAppIconDirectionsScreen), findsNothing);
    expect(closes, 0);
    expect(readCalls, 0);
    expect(writeCalls, 0);
    expect(find.byType(ZyraDevHomeTools), findsOneWidget);
    expect(restarts, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all eleven comparisons are visual until explicit native apply', (
    tester,
  ) async {
    final icons = controller();
    await tester.pumpWidget(
      MaterialApp(home: DevAppIconDirectionsScreen(controller: icons)),
    );
    await tester.pumpAndSettle();
    expect(readCalls, 1);
    expect(writeCalls, 0);
    for (final icon in ZyraDevAppIcon.values) {
      expect(
        find.byKey(ValueKey('dev_app_icon_art_${icon.name}')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Next icon'));
      await tester.pumpAndSettle();
      expect(writeCalls, 0);
    }
    // Previous wraps back from Current to the final study.
    await tester.tap(find.byTooltip('Previous icon'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dev_app_icon_art_royalSeal')),
      findsOneWidget,
    );
    final apply = find.byKey(const ValueKey('dev_app_icon_apply'));
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(writeCalls, 1);
    expect(activeIcon, 'ZyraRoyalSeal');
    expect(find.text('On your Home Screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'denied picker and direct route expose no artwork or native calls',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpWidget(
        MaterialApp(home: DevAppIconDirectionsScreen(controller: controller())),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dev_app_icon_directions_denied')),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNothing);
      expect(readCalls, 0);
      expect(writeCalls, 0);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DevAppIconDirectionPicker())),
      );
      expect(find.byType(ActionChip), findsNothing);
    },
  );

  testWidgets('authorization revocation hides gallery and apply control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DevAppIconDirectionsScreen(controller: controller())),
    );
    await tester.pumpAndSettle();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const ValueKey('dev_app_icon_apply')), findsNothing);
    expect(writeCalls, 0);
  });

  testWidgets('disabled icon picker refuses the eleven preview choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DevAppIconDirectionPicker(enabled: false)),
      ),
    );
    for (final icon in ZyraDevAppIcon.values) {
      final chip = tester.widget<ActionChip>(
        find.byKey(ValueKey('dev_app_icon_${icon.name}')),
      );
      expect(chip.onPressed, isNull);
    }
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('all eleven icons fit a narrow screen at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final icon in ZyraDevAppIcon.values) {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: DevAppIconDirectionsScreen(
              key: ValueKey(icon),
              initialIcon: icon,
              controller: controller(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final apply = find.byKey(const ValueKey('dev_app_icon_apply'));
        await tester.ensureVisible(apply);
        await tester.pumpAndSettle();
        expect(apply.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
