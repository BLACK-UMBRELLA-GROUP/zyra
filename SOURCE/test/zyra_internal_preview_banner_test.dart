import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/screens/dev/developer_access_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  const bannerKey = ValueKey('main_app_founder_preview_safety_banner');

  setUp(() {
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('local preview banner remains absent across preview routes', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => ZyraGlobalDevOverlayHost(
          navigatorKey: navigatorKey,
          authStateChangesOverride: const Stream.empty(),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const DeveloperAccessScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(DeveloperAccessScreen),
        matching: find.text('Developer Access'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(bannerKey), findsNothing);
    expect(ZyraInternalPreviewClient.isActive, isTrue);

    unawaited(
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Pushed preview page')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pushed preview page'), findsOneWidget);
    expect(find.byKey(bannerKey), findsNothing);
    expect(ZyraInternalPreviewClient.isActive, isTrue);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(DeveloperAccessScreen),
        matching: find.text('Developer Access'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(bannerKey), findsNothing);
    expect(ZyraInternalPreviewClient.isActive, isTrue);

    unawaited(
      navigatorKey.currentState!.pushAndRemoveUntil<void>(
        MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Text('Replacement preview page')),
        ),
        (_) => false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DeveloperAccessScreen), findsNothing);
    expect(find.text('Replacement preview page'), findsOneWidget);
    expect(find.byKey(bannerKey), findsNothing);
    expect(ZyraInternalPreviewClient.isActive, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'removed banner stays absent through authority and latch changes',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final authority = ValueNotifier(true);
      addTearDown(authority.dispose);
      ZyraInternalPreviewClient.beginPreview();

      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: authority,
          builder: (context, allowed, _) => MaterialApp(
            navigatorKey: navigatorKey,
            builder: (context, child) => ZyraGlobalDevOverlayHost(
              navigatorKey: navigatorKey,
              authorizationReaderOverride: () => allowed,
              authStateChangesOverride: const Stream.empty(),
              child: child ?? const SizedBox.shrink(),
            ),
            home: const Scaffold(body: Text('Preview shell')),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(bannerKey), findsNothing);
      expect(find.text('Preview shell'), findsOneWidget);

      // Models a failed exit: privileged authority is gone, but the network
      // deny latch remains active because sign-out did not fully complete.
      authority.value = false;
      await tester.pump();
      await tester.pump();

      expect(find.byKey(bannerKey), findsNothing);
      expect(find.text('Preview shell'), findsOneWidget);

      ZyraInternalPreviewClient.finishSignOut();
      await tester.pump();

      expect(find.byKey(bannerKey), findsNothing);
      expect(find.text('Preview shell'), findsOneWidget);
    },
  );
}
