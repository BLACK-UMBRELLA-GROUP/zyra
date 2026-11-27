import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FlutterAuthClientOptions, Supabase;
import 'package:zyra/main.dart' show ZyraStartupGate;
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';

final _primary = find.byKey(const ValueKey('zyra_error_primary'));
final _support = find.byKey(const ValueKey('zyra_error_secondary'));

Future<void> _mount(
  WidgetTester tester,
  ZyraErrorKind kind,
  Future<void> Function() action, {
  Size size = const Size(430, 932),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ZyraFullScreenError(
        kind: kind,
        referenceCode: 'ZY-TEST',
        onPrimary: action,
      ),
    ),
  );
}

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  for (final kind in [
    ZyraErrorKind.offline,
    ZyraErrorKind.serviceUnavailable,
  ]) {
    testWidgets('$kind retains the locked tan retry surface while connecting', (
      tester,
    ) async {
      final pending = Completer<void>();
      await _mount(tester, kind, () => pending.future);
      final button = tester.widget<OutlinedButton>(_primary);
      const tan = Color(0xFFF1EADE);
      expect(
        button.style!.backgroundColor!.resolve({})!.toARGB32(),
        tan.toARGB32(),
      );
      expect(button.style!.foregroundColor!.resolve({}), ZyraColors.goldText);
      await tester.tap(_primary);
      await tester.pump();
      expect(find.text('Connecting…'), findsOneWidget);
      final connecting = tester.widget<OutlinedButton>(_primary);
      expect(connecting.onPressed, isNull);
      expect(
        connecting.style!.backgroundColor!.resolve({
          WidgetState.disabled,
        })!.toARGB32(),
        tan.toARGB32(),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete();
      await tester.pump();
    });
  }

  test(
    'full-page classification distinguishes device, service and session',
    () {
      for (final error in [
        const SocketException('Network is unreachable'),
        const SocketException('The Internet connection appears to be offline.'),
      ]) {
        expect(zyraErrorKindFor(error), ZyraErrorKind.offline);
      }
      for (final error in [
        TimeoutException('private timeout detail'),
        http.ClientException('SocketException: Failed host lookup'),
        http.ClientException('SocketException: connection refused'),
        http.ClientException('SocketException: connection reset'),
        http.ClientException('statusCode: 503 connection closed'),
        http.ClientException('statusCode: 500'),
      ]) {
        expect(zyraErrorKindFor(error), ZyraErrorKind.serviceUnavailable);
      }
      for (final error in [
        Exception('Invalid refresh token: token not found'),
        Exception('refresh token has expired'),
      ]) {
        expect(zyraErrorKindFor(error), ZyraErrorKind.sessionExpired);
      }
      expect(
        zyraErrorKindFor(const ZyraPreviewAuthorizationException()),
        ZyraErrorKind.previewAccess,
      );
      expect(
        zyraErrorKindFor(http.ClientException('Unexpected response format')),
        ZyraErrorKind.page,
      );
      expect(
        zyraInlineErrorMessageFor(const SocketException('Failed host lookup')),
        'Check your connection, or try again shortly.',
      );
      expect(
        zyraErrorReference(Exception('private backend detail')),
        matches(RegExp(r'^ZY-[0-9A-Z]{4}$')),
      );
    },
  );

  final copy = {
    ZyraErrorKind.offline: (
      'You’re offline.',
      'ZYRA needs an internet connection to open.',
      ['Check Wi-Fi or mobile data', 'We keep trying', 'Still stuck?'],
    ),
    ZyraErrorKind.serviceUnavailable: (
      'ZYRA is taking a moment.',
      'This is on our side, not yours. Your account is safe.',
      ['We keep trying', 'Nothing changes while we’re away', 'Still stuck?'],
    ),
    ZyraErrorKind.page: (
      'We couldn’t open this page.',
      'Something didn’t load correctly.',
      ['We keep trying', 'Still stuck?'],
    ),
    for (final kind in [
      ZyraErrorKind.sessionExpired,
      ZyraErrorKind.previewAccess,
    ])
      kind: (
        'Please sign in again.',
        'For your security, your session has ended.',
        ['Why this happens', 'Can’t sign in?'],
      ),
  };
  for (final entry in copy.entries) {
    testWidgets('${entry.key.name} shows its locked help on one page', (
      tester,
    ) async {
      var calls = 0;
      await _mount(tester, entry.key, () async => calls++);
      final (title, message, rows) = entry.value;
      expect(find.byType(ZyraFullScreenError), findsOneWidget);
      for (final text in [
        'ZYRA',
        title,
        message,
        'WHAT YOU CAN TRY',
        ...rows,
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('zyra_error_connection_mark')),
        findsOneWidget,
      );
      expect(find.text('Contact support'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.semanticsLabel == 'REFERENCE: ZY-TEST',
        ),
        findsOneWidget,
      );
      if (entry.key.needsSignIn) {
        await tester.pump(const Duration(seconds: 30));
        expect(calls, 0);
        expect(find.textContaining('Trying again'), findsNothing);
        expect(find.text('Sign in again'), findsOneWidget);
        await tester.tap(_primary);
        expect(calls, 1);
      } else {
        expect(find.text('Trying again in 15 s'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        if (entry.key == ZyraErrorKind.page) {
          // Q59 preserves the timer on ordinary, route-owned page errors.
          await tester.pump(const Duration(seconds: 15));
          expect(calls, 1);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  // Q59 / LOCK 23: the release fallback uses page copy and manual restart.
  testWidgets('framework fallback never restarts without Try again', (
    tester,
  ) async {
    var restarts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraFullScreenError.frameworkFallback(
          referenceCode: 'ZY-TEST',
          onRestart: () async => restarts++,
        ),
      ),
    );

    expect(find.text('We couldn’t open this page.'), findsOneWidget);
    expect(find.text('Something didn’t load correctly.'), findsOneWidget);
    expect(find.text('Still stuck?'), findsOneWidget);
    expect(find.text('Contact support'), findsOneWidget);
    expect(find.text('We keep trying'), findsNothing);
    expect(find.textContaining('Trying again'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);

    await tester.pump(const Duration(minutes: 1));
    expect(restarts, 0);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(_primary);
    await tester.pump();
    expect(restarts, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(restarts, 1);
    expect(find.textContaining('Trying again'), findsNothing);
  });

  testWidgets(
    'retry starts at 15 s, disables overlap, and restarts on failure',
    (tester) async {
      var calls = 0;
      var pending = Completer<void>();
      await _mount(tester, ZyraErrorKind.offline, () {
        calls++;
        return pending.future;
      });
      final state = tester.state(find.byType(ZyraFullScreenError));
      await tester.pump(const Duration(seconds: 14));
      expect(find.text('Trying again in 1 s'), findsOneWidget);
      expect(calls, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(calls, 1);
      expect(find.text('Trying again…'), findsOneWidget);
      expect(find.text('Connecting…'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(_primary).onPressed, isNull);
      await tester.pump(const Duration(seconds: 20));
      expect(calls, 1);
      pending.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('Trying again in 15 s'), findsOneWidget);
      expect(tester.state(find.byType(ZyraFullScreenError)), same(state));
      pending = Completer<void>();
      await tester.tap(_primary);
      await tester.pump();
      expect(calls, 2);
      expect(find.text('Connecting…'), findsOneWidget);
      pending.complete();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 20));
      expect(calls, 2);
    },
  );

  testWidgets('Contact support opens Help & Support with the same reference', (
    tester,
  ) async {
    var calls = 0;
    await _mount(tester, ZyraErrorKind.offline, () async => calls++);
    await tester.tap(_support);
    await tester.pumpAndSettle();
    expect(find.byType(HelpSupportScreen), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.semanticsLabel == 'REFERENCE: ZY-TEST',
      ),
      findsOneWidget,
    );
    expect(find.text('Your safety reports'), findsNothing);
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 0);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(ZyraFullScreenError), findsOneWidget);
    expect(find.text('Trying again in 15 s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('startup session error prepares the SDK before opening sign-in', (
    tester,
  ) async {
    expect(() => Supabase.instance, throwsAssertionError);
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const methods = MethodChannel('com.llfbandit.app_links/messages');
    const events = MethodChannel('com.llfbandit.app_links/events');
    messenger.setMockMethodCallHandler(methods, (_) async => null);
    messenger.setMockMethodCallHandler(events, (_) async => null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(methods, null);
      messenger.setMockMethodCallHandler(events, null);
    });
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var initializes = 0;
    final allowed = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraStartupGate(
          startupError: StateError('session expired'),
          backendConfigured: true,
          initializeClient: () {
            initializes++;
            return allowed.future;
          },
        ),
      ),
    );
    expect(find.text('Please sign in again.'), findsOneWidget);
    await tester.tap(_primary);
    await tester.pump();
    expect(initializes, 1);
    expect(find.byType(WelcomeScreen), findsNothing);
    await tester.runAsync(
      () => Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'synthetic-startup-test-only',
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      ),
    );
    allowed.complete();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(ZyraFullScreenError), findsNothing);
    expect(Supabase.instance.isInitialized, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => Supabase.instance.dispose());
  });

  for (final kind in ZyraErrorKind.values) {
    testWidgets('${kind.name} actions remain reachable at Larger Text', (
      tester,
    ) async {
      await _mount(
        tester,
        kind,
        () async {},
        size: const Size(320, 480),
        textScale: 2,
      );
      for (final target in [
        _primary,
        _support,
        find.byWidgetPredicate(
          (w) => w is Text && w.semanticsLabel == 'REFERENCE: ZY-TEST',
        ),
      ]) {
        await tester.ensureVisible(target);
        await tester.pump();
        expect(target.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
