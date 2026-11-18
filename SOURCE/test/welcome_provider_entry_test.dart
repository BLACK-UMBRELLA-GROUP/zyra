import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_auth.dart';

void main() {
  testWidgets(
    'Google leads on a small Android phone with only provider entry',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

      expect(
        find.textContaining(RegExp('recovery', caseSensitive: false)),
        findsNothing,
      );
      expect(find.byType(TextButton), findsNothing);
      expect(find.text('Developer Access'), findsNothing);
      final googleLogo = tester.widget<Image>(
        find.byKey(const ValueKey('welcome_google_brand_logo')),
      );
      expect(
        (googleLogo.image as AssetImage).assetName,
        'assets/auth/google_g_logo.png',
      );
      final googleSurface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('welcome_google_white_surface')),
      );
      final appleSurface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('welcome_apple_white_surface')),
      );
      expect((googleSurface.decoration as BoxDecoration).color, Colors.white);
      expect((appleSurface.decoration as BoxDecoration).color, Colors.white);
      expect(
        tester.getSize(find.byKey(const ValueKey('welcome_google'))).height,
        54,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('welcome_apple'))).height,
        46,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('welcome_google'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('welcome_apple'))).dy,
        ),
      );
      expect(find.byIcon(Icons.g_mobiledata), findsNothing);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('Apple leads and is larger on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(
      find.textContaining(RegExp('recovery', caseSensitive: false)),
      findsNothing,
    );
    expect(find.byType(TextButton), findsNothing);
    final apple = find.byKey(const ValueKey('welcome_apple'));
    final google = find.byKey(const ValueKey('welcome_google'));
    expect(tester.getSize(apple).height, 54);
    expect(tester.getSize(google).height, 46);
    expect(tester.getTopLeft(apple).dy, lessThan(tester.getTopLeft(google).dy));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('only the selected OAuth provider shows progress', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final googleResult = Completer<ZyraAuthResult>();
    await tester.pumpWidget(
      MaterialApp(home: WelcomeScreen(googleSignIn: () => googleResult.future)),
    );

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Connecting with Google…'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);

    googleResult.complete(const ZyraAuthResult.cancelled());
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
