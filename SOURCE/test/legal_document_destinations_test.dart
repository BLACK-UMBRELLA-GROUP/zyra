// OA304: a missing formal document is explicit, navigable and never accepted.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/screens/settings/legal_document_screen.dart';
import 'package:zyra/screens/settings/privacy_and_data_screen.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/theme/zyra_text.dart';

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Legal destination checks must remain offline.');
  }
}

Widget _app(
  Widget child, {
  bool compact = false,
  GlobalKey<NavigatorState>? navigator,
}) => MaterialApp(
  navigatorKey: navigator,
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(compact ? 2 : 1)),
    child: child!,
  ),
  home: child,
);

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).last;
  final position = tester.state<ScrollableState>(scrollable).position;
  if (target.evaluate().isEmpty) {
    position.jumpTo(0);
    await tester.pumpAndSettle();
    for (var step = 0; step < 100 && target.evaluate().isEmpty; step++) {
      position.jumpTo(
        (position.pixels + 180).clamp(0, position.maxScrollExtent),
      );
      await tester.pumpAndSettle();
    }
  }
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldHttp = HttpOverrides.current;
  late _NoNetwork network;
  final requests = <http.Request>[];
  const native = MethodChannel('plugins.flutter.io/url_launcher');
  var nativeCalls = 0;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'legal-sentinel': 'keep'});
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        throw StateError('No server calls belong to these document pages.');
      }),
    );
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraProductTelemetry.instance.resetForTest();
    network = _NoNetwork();
    HttpOverrides.global = network;
    requests.clear();
    nativeCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(native, (_) async {
          nativeCalls++;
          return false;
        });
  });
  tearDown(() async {
    try {
      expect(network.attempts, 0);
      expect(requests, isEmpty);
      expect(nativeCalls, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'legal-sentinel'});
      expect(prefs.getString('legal-sentinel'), 'keep');
    } finally {
      HttpOverrides.global = oldHttp;
      ZyraText.useTestFontStubs = false;
      ZyraProductTelemetry.instance.resetForTest();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(native, null);
    }
  });
  tearDownAll(() => Supabase.instance.dispose());

  for (final guardian in [false, true]) {
    for (final document in ZyraLegalDocument.values) {
      for (final compact in [false, true]) {
        testWidgets(
          '${guardian ? 'Guardian' : 'Seeker'} ${document.name} '
          '${compact ? 'compact 200%' : 'normal'} summary/document/Help/back',
          (tester) async {
            tester.view.physicalSize = compact
                ? const Size(320, 568)
                : const Size(393, 852);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              _app(PrivacyAndDataScreen(guardian: guardian), compact: compact),
            );
            await tester.pumpAndSettle();
            final destination = find.byKey(
              ValueKey('privacy_document_${document.name}'),
            );
            await _reveal(tester, destination);
            expect(
              tester.getSize(destination).height,
              greaterThanOrEqualTo(48),
            );
            await tester.tap(destination);
            await tester.pumpAndSettle();
            expect(find.byType(LegalDocumentScreen), findsOneWidget);
            expect(find.text('Not available yet'), findsOneWidget);
            await _reveal(
              tester,
              find.textContaining('No document acceptance is recorded'),
            );
            expect(
              find.textContaining('No document acceptance is recorded'),
              findsOneWidget,
            );
            expect(find.byType(Checkbox), findsNothing);
            expect(find.byType(Switch), findsNothing);
            final help = find.byKey(const ValueKey('legal_document_help'));
            await _reveal(tester, help);
            await tester.tap(help);
            await tester.pumpAndSettle();
            expect(find.byType(HelpSupportScreen), findsOneWidget);
            await tester.pageBack();
            await tester.pumpAndSettle();
            expect(find.byType(LegalDocumentScreen), findsOneWidget);
            await tester.pageBack();
            await tester.pumpAndSettle();
            expect(find.byType(PrivacyAndDataScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'privacy summary states real recovery and build telemetry boundary',
    (tester) async {
      await tester.pumpWidget(_app(const PrivacyAndDataScreen()));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This is not the full Privacy Policy'),
        findsOneWidget,
      );
      await _reveal(tester, find.textContaining('recovery email can help'));
      expect(find.textContaining('one-time code'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('Feature usage'), findsOneWidget);
      expect(
        find.textContaining(
          ZyraProductTelemetry.productionCollectionEnabled
              ? 'can send limited feature-usage events'
              : 'transmission is off',
        ),
        findsOneWidget,
      );
      expect(find.text('No tracking or advertising'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saved document Help callback cannot navigate under a covering route',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _app(
          const LegalDocumentScreen(document: ZyraLegalDocument.privacyPolicy),
          navigator: navigator,
        ),
      );
      await tester.pumpAndSettle();
      final help = find.byKey(const ValueKey('legal_document_help'));
      await _reveal(tester, help);
      final saved = tester.widget<OutlinedButton>(help).onPressed!;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('covered')),
        ),
      );
      await tester.pumpAndSettle();
      saved();
      await tester.pumpAndSettle();
      expect(find.text('covered'), findsOneWidget);
      expect(find.byType(HelpSupportScreen), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      saved();
      await tester.pumpAndSettle();
      expect(find.byType(HelpSupportScreen), findsOneWidget);
    },
  );

  for (final compact in [false, true]) {
    testWidgets(
      'identity privacy summary scrolls at ${compact ? '200%' : '100%'}',
      (tester) async {
        tester.view.physicalSize = compact
            ? const Size(320, 568)
            : const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(const IdentityVerificationPrivacyScreen(), compact: compact),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('identity_privacy_scroll')),
          findsOneWidget,
        );
        final read = find.text('Read current privacy & data summary');
        await _reveal(tester, read);
        await tester.tap(read);
        await tester.pumpAndSettle();
        expect(find.byType(PrivacyAndDataScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(IdentityVerificationPrivacyScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('disposed legal and summary callbacks cannot reopen a route', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const PrivacyAndDataScreen()));
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('privacy_document_privacyPolicy'));
    await _reveal(tester, row);
    final savedRow = tester.widget<OutlinedButton>(row).onPressed!;
    await tester.tap(row);
    await tester.pumpAndSettle();
    final help = find.byKey(const ValueKey('legal_document_help'));
    await _reveal(tester, help);
    final savedHelp = tester.widget<OutlinedButton>(help).onPressed!;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    savedRow();
    savedHelp();
    await tester.pumpAndSettle();
    expect(find.byType(HelpSupportScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
