// LOCK 14 V5: APP_COLOURS/RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V5.md;
// masters APP_COLOURS/MASTERS/c11_app_icon_1024.png and c12_splash.png.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/screens/splash_screen.dart';
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
    testWidgets('${direction.name} uses the locked Ivory gradient', (
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
        Color(0xFFFBF7F0),
        Color(0xFFEEE6D8),
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

  testWidgets(
    'selected Quiet Horizon artwork is code-selected with no Home picker',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ZyraSplashStudy(direction: ZyraSplashDirection.dawnHorizon),
        ),
      );
      expect(ZyraSplashDirection.values, [ZyraSplashDirection.dawnHorizon]);
      expect(ZyraSplashDirection.dawnHorizon.label, '6 · Quiet Horizon · Main');
      for (final name in [
        'dawnHorizon',
        'disney',
        'moonly',
        'luma',
        'headspace',
        'tinder',
      ]) {
        expect(find.byKey(ValueKey('dev_splash_$name')), findsNothing);
      }
      expect(find.byType(ZyraSplashArtworkFrame), findsOneWidget);
      await tester.pump(
        zyraSplashTotalDuration + const Duration(milliseconds: 2),
      );
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets(
    'ordinary splash retains its completion without a developer route',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen(onFinished: () => completed++)),
      );
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);
      expect(
        find.byKey(const ValueKey('dev_splash_directions_denied')),
        findsNothing,
      );
      await tester.pump(
        zyraSplashTotalDuration + const Duration(milliseconds: 2),
      );
      expect(completed, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'code-selected artwork preserves the underlying route and authority',
    (tester) async {
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
          home: const Scaffold(body: Text('Existing profile stays here')),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const ZyraSplashStudy(direction: ZyraSplashDirection.dawnHorizon),
        ),
      );
      await tester.pumpAndSettle();
      expect(navigator.currentState!.canPop(), isTrue);
      expect(find.byType(ZyraSplashArtworkFrame), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Existing profile stays here'), findsOneWidget);
      expect(refreshCalls, 0);
    },
  );

  testWidgets(
    'revoked developer authority cannot add splash controls or reset the stack',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('Original page')),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const ZyraSplashStudy(direction: ZyraSplashDirection.dawnHorizon),
        ),
      );
      await tester.pumpAndSettle();
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNothing);
      expect(
        find.byKey(const ValueKey('dev_splash_dawnHorizon')),
        findsNothing,
      );
      expect(navigator.currentState!.canPop(), isTrue);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Original page'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
