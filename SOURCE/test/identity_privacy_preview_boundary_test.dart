// OA303/304/305: rehearsal privacy must never become ordinary contact/identity.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_one_journey_settings_details.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/screens/settings/legal_document_screen.dart';
import 'package:zyra/screens/settings/privacy_and_data_screen.dart';
import 'package:zyra/screens/settings/safety_case_status_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _captureDir = String.fromEnvironment('ZYRA_HEALTH_CAPTURE_DIR');
const _captureKey = ValueKey('identity-privacy-health-capture');
Finder _key(String id) => find.byKey(ValueKey(id));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Privacy preview is offline.');
  }
}

Widget _app(
  Widget child, {
  GlobalKey<NavigatorState>? navigator,
  bool compact = false,
}) => MaterialApp(
  navigatorKey: navigator,
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      textScaler: TextScaler.linear(compact ? 2 : 1),
    ),
    child: RepaintBoundary(key: _captureKey, child: child!),
  ),
  home: child,
);

Future<void> _tap(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 60,
    );
  }
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _noOrdinary() {
  expect(find.byType(PrivacyAndDataScreen), findsNothing);
  expect(find.byType(LegalDocumentScreen), findsNothing);
  expect(find.byType(SafetyCaseStatusScreen), findsNothing);
  expect(_key('help-support-email-action'), findsNothing);
  expect(_key('support-safety-case-status'), findsNothing);
  expect(ZyraProductTelemetry.instance.snapshot.sessionEventCount, 0);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captureDir/$name.png');
    await file.create(exclusive: true);
    final frame = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await frame.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    } finally {
      frame.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalHttp = HttpOverrides.current;
  final oldFont = ZyraText.useTestFontStubs;
  final oldReading = ZyraText.testReadingFontFamily;
  final oldWordmark = ZyraText.testWordmarkFontFamily;
  late _NoNetwork network;
  var nativeCalls = 0;
  const nativeChannels = [
    'plugins.flutter.io/url_launcher',
    'plugins.flutter.io/local_auth',
  ];

  setUpAll(() async {
    if (_captureDir.isNotEmpty) {
      if (!_captureDir.startsWith('/')) {
        throw StateError('Absolute capture path required.');
      }
      var current = '';
      for (final part
          in _captureDir.split('/').where((part) => part.isNotEmpty)) {
        if (part == '.' || part == '..') {
          throw StateError('No aliases.');
        }
        current += '/$part';
        if (FileSystemEntity.typeSync(current, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw StateError('Existing nonlinked output directory required.');
        }
      }
    }
    final fonts = FontLoader('PoppinsIdentityPrivacyHealth');
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      fonts.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    final wordmark = FontLoader('SyneIdentityPrivacyHealth')
      ..addFont(rootBundle.load('assets/fonts/Syne-SemiBold.ttf'));
    await Future.wait([fonts.load(), icons.load(), wordmark.load()]);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({'health-sentinel': 'keep'});
    await ZyraLocalPrefs.init();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraProductTelemetry.instance.resetForTest();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsIdentityPrivacyHealth';
    ZyraText.testWordmarkFontFamily = 'SyneIdentityPrivacyHealth';
    nativeCalls = 0;
    network = _NoNetwork();
    HttpOverrides.global = network;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in nativeChannels) {
      messenger.setMockMessageHandler(channel, (_) async {
        nativeCalls++;
        return null;
      });
    }
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
  });
  tearDown(() {
    try {
      expect(network.attempts, 0);
      expect(nativeCalls, 0);
    } finally {
      HttpOverrides.global = originalHttp;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraDeveloperAccess.resetAuthorizationForTesting();
      ZyraAccountState.clearImagesForTesting = null;
      ZyraText.useTestFontStubs = oldFont;
      ZyraText.testReadingFontFamily = oldReading;
      ZyraText.testWordmarkFontFamily = oldWordmark;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final channel in nativeChannels) {
        messenger.setMockMessageHandler(channel, null);
      }
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    }
  });

  for (final compact in [false, true]) {
    testWidgets(
      'protected identity privacy policy FAQ and Back stay local ${compact ? '320px200%' : '393px'}',
      (tester) async {
        tester.view.physicalSize = compact
            ? const Size(320, 568)
            : const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(
            const InitialIdentityCheckScreen(devPreview: true),
            compact: compact,
          ),
        );
        await _tap(tester, _key('identity-privacy-policy'));
        _noOrdinary();
        await _tap(tester, _key('identity_privacy_summary'));
        expect(
          find.byType(ZyraConceptSettingsDetailPresentation),
          findsOneWidget,
        );
        expect(
          _key('founder_launch_note_detail_privacyPolicy'),
          findsOneWidget,
        );
        _noOrdinary();
        // A healthy same-owner publication must not replace the route's
        // captured caller merely because its builder runs again.
        AppState.instance.setNotificationPreference();
        await tester.pumpAndSettle();
        expect(
          find.byType(ZyraConceptSettingsDetailPresentation),
          findsOneWidget,
        );
        if (!compact) await _capture(tester, 'identity-preview-policy');
        await _tap(tester, _key('concept_settings_help_detail_privacyPolicy'));
        expect(_key('help-support-preview-title'), findsOneWidget);
        _noOrdinary();
        AppState.instance.setNotificationPreference();
        await tester.pumpAndSettle();
        expect(_key('help-support-preview-title'), findsOneWidget);
        if (!compact) await _capture(tester, 'identity-preview-help');
        await _tap(
          tester,
          _key(
            'help-support-faq:Privacy guidance:Is this the formal Privacy Policy?',
          ),
        );
        _noOrdinary();
        // FAQ answers expand inline; there is no dialog route to pop.
        expect(
          find.text(
            'No. This is an explanation of current availability, '
            'not a published policy or a record of acceptance.',
          ),
          findsOneWidget,
        );
        await _tap(tester, _key('identity_preview_privacy_back'));
        expect(
          find.byType(ZyraConceptSettingsDetailPresentation),
          findsOneWidget,
        );
        await _tap(tester, _key('identity_preview_privacy_back'));
        await _tap(tester, _key('identity_privacy_back'));
        expect(_key('identity-privacy-policy'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'ordinary identity privacy summary remains a real ordinary destination',
    (tester) async {
      await tester.pumpWidget(_app(const IdentityVerificationPrivacyScreen()));
      await _tap(tester, _key('identity_privacy_summary'));
      expect(find.byType(PrivacyAndDataScreen), findsOneWidget);
      expect(find.byType(ZyraConceptSettingsDetailPresentation), findsNothing);
      expect(find.text('Founder input needed before launch'), findsNothing);
    },
  );

  testWidgets(
    'preview privacy mode and callback replacements deny rather than fall through',
    (tester) async {
      final page = GlobalKey();
      bool admitted() => true;
      await tester.pumpWidget(
        _app(
          IdentityVerificationPrivacyScreen(
            key: page,
            devPreview: true,
            canAct: admitted,
          ),
        ),
      );
      final saved = tester
          .widget<OutlinedButton>(_key('identity_privacy_summary'))
          .onPressed!;
      await tester.pumpWidget(
        _app(IdentityVerificationPrivacyScreen(key: page, canAct: admitted)),
      );
      saved();
      await tester.pumpAndSettle();
      expect(_key('identity_privacy_unavailable'), findsOneWidget);
      _noOrdinary();
      await tester.pumpWidget(
        _app(
          IdentityVerificationPrivacyScreen(
            key: page,
            devPreview: true,
            canAct: admitted,
          ),
        ),
      );
      saved();
      await tester.pumpAndSettle();
      expect(_key('identity_privacy_unavailable'), findsOneWidget);
      _noOrdinary();
    },
  );

  testWidgets(
    'saved privacy push and Back cannot affect a covering route or disposed owner',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _app(
          const IdentityVerificationPrivacyScreen(devPreview: true),
          navigator: navigator,
        ),
      );
      final open = tester
          .widget<OutlinedButton>(_key('identity_privacy_summary'))
          .onPressed!;
      final back = tester
          .widget<IconButton>(_key('identity_privacy_back'))
          .onPressed!;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover')),
        ),
      );
      await tester.pumpAndSettle();
      open();
      back();
      await tester.pumpAndSettle();
      expect(find.text('Cover'), findsOneWidget);
      expect(find.byType(ZyraConceptSettingsDetailPresentation), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      open();
      back();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'same-mode replacement owner cannot revive a mounted privacy page',
    (tester) async {
      final page = GlobalKey();
      bool original() => true;
      bool replacement() => true;
      await tester.pumpWidget(
        _app(
          IdentityVerificationPrivacyScreen(
            key: page,
            devPreview: true,
            canAct: original,
          ),
        ),
      );
      final saved = tester
          .widget<OutlinedButton>(_key('identity_privacy_summary'))
          .onPressed!;
      await tester.pumpWidget(
        _app(
          IdentityVerificationPrivacyScreen(
            key: page,
            devPreview: true,
            canAct: replacement,
          ),
        ),
      );
      saved();
      await tester.pumpAndSettle();
      expect(_key('identity_privacy_unavailable'), findsOneWidget);
      _noOrdinary();
    },
  );

  testWidgets(
    'developer revocation ABA permanently withdraws the nested privacy route',
    (tester) async {
      await tester.pumpWidget(
        _app(const IdentityVerificationPrivacyScreen(devPreview: true)),
      );
      await _tap(tester, _key('identity_privacy_summary'));
      await _tap(tester, _key('concept_settings_help_detail_privacyPolicy'));
      final back = tester
          .widget<IconButton>(_key('identity_preview_privacy_back'))
          .onPressed!;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      back();
      await tester.pumpAndSettle();
      expect(_key('identity_preview_privacy_unavailable'), findsOneWidget);
      expect(find.byType(HelpSupportScreen), findsNothing);
      _noOrdinary();
    },
  );

  testWidgets(
    'parent preview mode cannot become ordinary consent or borrow a replacement skip',
    (tester) async {
      final page = GlobalKey();
      var opening = 0, replacement = 0;
      await tester.pumpWidget(
        _app(InitialIdentityCheckScreen(key: page, devPreview: true)),
      );
      final privacy = tester
          .widget<TextButton>(_key('identity-privacy-policy'))
          .onPressed!;
      await tester.pumpWidget(_app(InitialIdentityCheckScreen(key: page)));
      privacy();
      await tester.pumpAndSettle();
      expect(_key('identity-session-changed'), findsOneWidget);
      expect(find.byType(IdentityVerificationPrivacyScreen), findsNothing);
      expect(opening, 0);
      expect(replacement, 0);
      _noOrdinary();
    },
  );
}
