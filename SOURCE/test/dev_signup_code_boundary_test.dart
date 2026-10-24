import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zyra/screens/wali/wali_invite_seeker_screen.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

class _Routes extends NavigatorObserver {
  int pushes = 0;
  int replacements = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacements++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final platformCalls = <String>[];
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<void> mount(
    WidgetTester tester, {
    NavigatorObserver? observer,
    Size size = const Size(430, 932),
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: observer == null ? const [] : [observer],
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const WaliInviteSeekerScreen(signupPreview: true),
      ),
    );
    await tester.pumpAndSettle();
  }

  InkWell action(WidgetTester tester, String name) => tester.widget<InkWell>(
    find.descendant(
      of: find.byKey(ValueKey('signup_code_$name')),
      matching: find.byType(InkWell),
    ),
  );

  setUp(() {
    platformCalls.clear();
    ZyraText.useTestFontStubs = true;
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    // Deliberately no Founder-main flag and no preview network latch. The raw
    // requested mode must isolate this surface even when directly constructed.
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    AppState.instance.resetForAccountChange();
    ZyraProductTelemetry.instance.resetForTest();
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      // Scaffold updates OS descriptions and overlay styles as normal chrome.
      // Keep every other platform method observable: clipboard, haptics and
      // any unexpected feature operation must still fail the boundary tests.
      if (!call.method.startsWith('SystemChrome.')) {
        platformCalls.add('platform:${call.method}');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      platformCalls.add('share:${call.method}');
      return '';
    });
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    AppState.instance.resetForAccountChange();
    ZyraProductTelemetry.instance.resetForTest();
    ZyraText.useTestFontStubs = false;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(shareChannel, null);
  });

  test('live code and invite constructors remain default OFF', () {
    expect(const WaliInviteSeekerScreen().signupPreview, isFalse);
    expect(const ZyraCodeScreen(asGuardian: true).signupPreview, isFalse);
    expect(const ZyraCodeScreen(asGuardian: false).signupPreview, isFalse);
  });

  testWidgets('requested signup uses fictional code without Founder latch', (
    tester,
  ) async {
    await mount(tester);

    expect(ZyraInternalPreviewClient.isActive, isFalse);
    expect(ZyraDeveloperAccess.isMainAppFounderPreview, isFalse);
    expect(find.byKey(const ValueKey('signup_code_preview')), findsOneWidget);
    expect(find.text('ZYRA-DEMO-GUARDIAN-IBRAHIM'), findsOneWidget);
    expect(find.textContaining('fictional code'), findsOneWidget);
    expect(find.textContaining("couldn't be refreshed"), findsNothing);
    expect(find.text('Change code'), findsNothing);
    expect(find.text('REQUESTS'), findsNothing);
    expect(platformCalls, isEmpty);
    expect(ZyraProductTelemetry.instance.snapshot.sessionEventCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('denied direct requested preview exposes no code or actions', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await mount(tester);

    expect(
      find.byKey(const ValueKey('signup_code_preview_denied')),
      findsOneWidget,
    );
    expect(find.textContaining('ZYRA-DEMO-'), findsNothing);
    expect(find.byKey(const ValueKey('signup_code_copy')), findsNothing);
    expect(find.byType(MobileScanner), findsNothing);
    expect(platformCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authorization grant loads only the local orientation', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await mount(tester);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('signup_code_preview')), findsOneWidget);
    expect(find.text('ZYRA-DEMO-GUARDIAN-IBRAHIM'), findsOneWidget);
    expect(ZyraInternalPreviewClient.isActive, isFalse);
    expect(platformCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external actions explain locally without device or link calls', (
    tester,
  ) async {
    final routes = _Routes();
    await mount(tester, observer: routes);
    final originalPushes = routes.pushes;

    for (final name in ['copy', 'share', 'scan', 'enter']) {
      await tester.ensureVisible(find.byKey(ValueKey('signup_code_$name')));
      await tester.tap(find.byKey(ValueKey('signup_code_$name')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('signup_code_action_info')),
        findsOneWidget,
      );
      expect(find.byType(MobileScanner), findsNothing);
      expect(
        find.byKey(const ValueKey('inline-zyra-code-field')),
        findsNothing,
      );
      expect(find.text('Request sent'), findsNothing);
      expect(find.text('Copied'), findsNothing);
      expect(routes.pushes, originalPushes);
      expect(routes.replacements, 0);
      expect(platformCalls, isEmpty);
      expect(ZyraProductTelemetry.instance.snapshot.sessionEventCount, 0);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('QR changes presentation only without platform feedback', (
    tester,
  ) async {
    await mount(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('signup_code_qr')));
    await tester.tap(find.byKey(const ValueKey('signup_code_qr')));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Hide QR'), findsOneWidget);
    expect(find.byType(MobileScanner), findsNothing);
    expect(platformCalls, isEmpty);

    await tester.ensureVisible(find.byKey(const ValueKey('signup_code_qr')));
    await tester.tap(find.byKey(const ValueKey('signup_code_qr')));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(platformCalls, isEmpty);
  });

  testWidgets('revocation denies presentation and stale external callbacks', (
    tester,
  ) async {
    final routes = _Routes();
    await mount(tester, observer: routes);
    final callbacks = [
      for (final name in ['copy', 'share', 'scan', 'enter', 'qr'])
        action(tester, name).onTap!,
    ];
    final originalPushes = routes.pushes;

    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    for (final callback in callbacks) {
      callback();
    }
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('signup_code_preview_denied')),
      findsOneWidget,
    );
    expect(find.textContaining('ZYRA-DEMO-'), findsNothing);
    expect(find.byType(MobileScanner), findsNothing);
    expect(routes.pushes, originalPushes);
    expect(platformCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invitation refresh does not mix live rows into signup preview', (
    tester,
  ) async {
    await mount(tester);
    ZyraWaliLinkService.invitationRevision.value++;
    await tester.pumpAndSettle();
    expect(find.text('ZYRA-DEMO-GUARDIAN-IBRAHIM'), findsOneWidget);
    expect(find.text('REQUESTS'), findsNothing);
    expect(find.textContaining("couldn't be refreshed"), findsNothing);
    expect(platformCalls, isEmpty);
  });

  testWidgets('preview remains reachable on compact large-text viewport', (
    tester,
  ) async {
    await mount(tester, size: const Size(320, 568), scale: 2);
    for (final name in ['copy', 'qr', 'share', 'scan', 'enter']) {
      final option = find.byKey(ValueKey('signup_code_$name'));
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      expect(option.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
