import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/dev/dev_splash_directions.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/dev/zyra_developer_route_gate.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_splash_artwork.dart';

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraColors.restoreAppPalette(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });

  for (final direction in ZyraSplashDirection.values) {
    testWidgets('${direction.name} uses the app-wide dark purple gradient', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ZyraSplashStudy(direction: direction)),
      );
      final decorations = tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      );
      expect(
        decorations.any(
          (box) =>
              box.decoration is BoxDecoration &&
              (box.decoration as BoxDecoration).gradient ==
                  ZyraColors.brandGradient,
        ),
        isTrue,
      );
      expect(ZyraColors.brandGradient.colors, const [
        Color(0xFF30203F),
        Color(0xFF160E20),
      ]);
      await tester.pump(const Duration(milliseconds: 3051));
      expect(tester.takeException(), isNull);
    });
  }
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  testWidgets('Quiet Horizon preview ends its timer after the shared hold', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ZyraSplashStudy(direction: ZyraSplashDirection.dawnHorizon),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2401));
    expect(
      tester
          .widget<ZyraSplashArtworkFrame>(find.byType(ZyraSplashArtworkFrame))
          .progress,
      1,
    );
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 648));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 2));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('shared Home keeps Quiet Horizon and opens its preview', (
    tester,
  ) async {
    var panelClosed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZyraDevHomeTools(
              busy: false,
              onHome: () {},
              onRestart: () {},
              onReset: null,
              onOpenSplashPreview: () => panelClosed = true,
              onAccounts: () {},
              onSeekerSignUp: () {},
              onGuardianSignUp: () {},
            ),
          ),
        ),
      ),
    );
    for (final direction in ZyraSplashDirection.values) {
      expect(
        find.byKey(ValueKey('dev_splash_${direction.name}')),
        findsOneWidget,
      );
    }
    expect(ZyraSplashDirection.values, [ZyraSplashDirection.dawnHorizon]);
    expect(ZyraSplashDirection.dawnHorizon.label, '6 · Quiet Horizon · Main');
    expect(find.text('6 · Quiet Horizon · Main'), findsOneWidget);
    for (final removed in ['disney', 'moonly', 'luma', 'headspace', 'tinder']) {
      expect(find.byKey(ValueKey('dev_splash_$removed')), findsNothing);
    }
    await tester.tap(find.byKey(const ValueKey('dev_splash_dawnHorizon')));
    expect(panelClosed, isTrue);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('splash_study_dawnHorizon')),
      findsOneWidget,
    );
  });

  testWidgets('direct unauthorized preview and Home picker are denied', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpWidget(
      const MaterialApp(home: DevSplashDirectionsScreen()),
    );
    expect(
      find.byKey(const ValueKey('dev_splash_directions_denied')),
      findsOneWidget,
    );
    expect(find.byType(SplashScreen), findsNothing);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DevSplashDirectionPicker())),
    );
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('the selected visual preview preserves the underlying route', (
    tester,
  ) async {
    var restartCalls = 0;
    var refreshCalls = 0;
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => null,
      refreshSession: () async {
        refreshCalls++;
        return null;
      },
      founderIdentityMatches: (_) => false,
    );
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Existing profile stays here'),
                ZyraDevHomeTools(
                  busy: false,
                  onHome: () {},
                  onRestart: () => restartCalls++,
                  onReset: null,
                  onAccounts: () {},
                  onSeekerSignUp: () {},
                  onGuardianSignUp: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('dev_splash_dawnHorizon')));
    await tester.pumpAndSettle();
    for (final direction in ZyraSplashDirection.values) {
      expect(find.text(direction.label), findsOneWidget);
      expect(find.byType(ZyraDeveloperRouteGate), findsNothing);
      expect(navigator.currentState!.canPop(), isTrue);
      await tester.tap(find.text('Replay'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next direction'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip('Close splash preview'));
    await tester.pumpAndSettle();
    expect(find.text('Existing profile stays here'), findsOneWidget);
    expect(restartCalls, 0);
    expect(refreshCalls, 0);
  });

  testWidgets(
    'revoked artwork permission hides preview without resetting stack',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('Original page')),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute(builder: (_) => const DevSplashDirectionsScreen()),
      );
      await tester.pumpAndSettle();
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dev_splash_directions_denied')),
        findsOneWidget,
      );
      expect(navigator.currentState!.canPop(), isTrue);
      await tester.tap(find.byTooltip('Close splash preview'));
      await tester.pumpAndSettle();
      expect(find.text('Original page'), findsOneWidget);
    },
  );

  for (final size in const [
    Size(320, 568),
    Size(390, 844),
    Size(430, 932),
    Size(844, 390),
  ]) {
    for (final direction in ZyraSplashDirection.values) {
      testWidgets('${direction.name} fits $size with enlarged text', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.3),
              ),
              child: ZyraSplashStudy(direction: direction),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 3051));
        expect(find.text('ZYRA'), findsOneWidget);
        expect(find.text('Connecting with trust'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('reduced motion shows a settled study immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: ZyraSplashStudy(direction: ZyraSplashDirection.dawnHorizon),
        ),
      ),
    );
    for (final opacity in tester.widgetList<Opacity>(find.byType(Opacity))) {
      expect(opacity.opacity, 1);
    }
  });
}
