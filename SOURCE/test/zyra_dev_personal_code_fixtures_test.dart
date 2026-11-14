import 'package:qr_flutter/qr_flutter.dart';
// LOCK 14 V5: APP_COLOURS/RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V5.md;
// masters APP_COLOURS/MASTERS/c11_app_icon_1024.png and c12_splash.png.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_personal_code_fixtures.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_qr_assertions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platformCalls = <MethodCall>[];
  final shareCalls = <MethodCall>[];
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

  setUp(() {
    platformCalls.clear();
    shareCalls.clear();
    ZyraText.useTestFontStubs = true;
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (call) async {
          shareCalls.add(call);
          return '';
        });
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    AppState.instance.resetForAccountChange();
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
  });

  test('Founder preview codes are deterministic for all four personas', () {
    expect(
      ZyraDevPersonalCodeFixtures.forPersona(
        asGuardian: false,
        gender: 'male',
      ).code,
      'ZYRA-DEMO-SEEKER-ADAM',
    );
    expect(
      ZyraDevPersonalCodeFixtures.forPersona(
        asGuardian: false,
        gender: 'female',
      ).code,
      'ZYRA-DEMO-SEEKER-MARYAM',
    );
    expect(
      ZyraDevPersonalCodeFixtures.forPersona(
        asGuardian: true,
        gender: 'male',
      ).code,
      'ZYRA-DEMO-GUARDIAN-IBRAHIM',
    );
    expect(
      ZyraDevPersonalCodeFixtures.forPersona(
        asGuardian: true,
        gender: 'female',
      ).code,
      'ZYRA-DEMO-GUARDIAN-KHADIJA',
    );
  });

  test('Founder preview codes can never parse as live ZYRA Codes', () {
    for (final asGuardian in [false, true]) {
      for (final gender in ['male', 'female']) {
        final fixture = ZyraDevPersonalCodeFixtures.forPersona(
          asGuardian: asGuardian,
          gender: gender,
        );
        expect(
          ZyraPersonalCode.fromRow({
            'code': fixture.code,
            'role_context': fixture.roleContext,
          }),
          isNull,
        );
      }
    }
  });

  test('Founder code-entry fixtures resolve only the opposite role', () {
    expect(
      ZyraDevPersonalCodeFixtures.previewEntryCode(
        ZyraDevPersonalCodeFixtures.validGuardianEntryCode,
        asGuardian: false,
      )?.firstName,
      'Ibrahim',
    );
    expect(
      ZyraDevPersonalCodeFixtures.previewEntryCode(
        ZyraDevPersonalCodeFixtures.validSeekerEntryCode,
        asGuardian: true,
      )?.firstName,
      'Adam',
    );
    expect(
      ZyraDevPersonalCodeFixtures.previewEntryCode(
        ZyraDevPersonalCodeFixtures.invalidEntryCode,
        asGuardian: false,
      ),
      isNull,
    );
  });

  Future<void> open(WidgetTester t, {bool guardian = false}) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(430, 932);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(name: 'Adam', gender: 'male');
    await t.pumpWidget(MaterialApp(home: ZyraCodeScreen(asGuardian: guardian)));
    await t.pumpAndSettle();
  }

  Future<void> press(WidgetTester t, String text) async {
    final target = find.text(text);
    if (text == 'Check code') {
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
    }
    await t.ensureVisible(target);
    await t.tap(target);
    await t.pumpAndSettle();
  }

  testWidgets('Founder preview shows the fictional QR and no refresh error', (
    t,
  ) async {
    await open(t);
    await expectZyraQrPayload(t, 'ZYRA-DEMO-SEEKER-ADAM');
    expect(find.textContaining("couldn't be refreshed"), findsNothing);
    expect(find.text('Get a new code'), findsOneWidget);
  });

  testWidgets('copy remains confirmed and repeat taps copy again', (t) async {
    await open(t);
    await press(t, 'Copy code');
    await press(t, 'Copied');
    expect(
      platformCalls.where((call) => call.method == 'Clipboard.setData'),
      hasLength(2),
    );
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('Founder preview shares the existing sample wording', (t) async {
    await open(t);
    await press(t, 'Share my code');
    final shared = shareCalls.single.arguments as Map;
    expect(
      shared['text'],
      'ZYRA Developer Preview code:\nZYRA-DEMO-SEEKER-ADAM\n\n'
      'This sample code cannot connect real accounts.',
    );
    expect(shared['subject'], 'My ZYRA Code');
  });

  testWidgets('Their code preserves invalid and found/sent states', (t) async {
    await open(t);
    await press(t, 'Their code');
    expect(find.byType(QrImageView), findsNothing);
    final field = find.byKey(const ValueKey('local-code-field'));
    await t.enterText(field, ZyraDevPersonalCodeFixtures.invalidEntryCode);
    await press(t, 'Check code');
    expect(find.text('Invalid code. Please try again.'), findsOneWidget);
    await t.enterText(
      field,
      ZyraDevPersonalCodeFixtures.validGuardianEntryCode,
    );
    await press(t, 'Check code');
    expect(find.text('Ibrahim'), findsOneWidget);
    expect(find.text('Guardian · first name and role only'), findsOneWidget);
    await press(t, 'Send request');
    expect(find.text('Request sent'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets(
    'Guardian must select a relationship before simulating a request',
    (t) async {
      final telemetry = ZyraProductTelemetry.instance;
      final originalEvents = telemetry.snapshot.sessionEventCount;
      await open(t, guardian: true);
      final invitationRevision = ZyraWaliLinkService.invitationRevision.value;
      await press(t, 'Their code');
      await t.enterText(
        find.byKey(const ValueKey('local-code-field')),
        ZyraDevPersonalCodeFixtures.validSeekerEntryCode,
      );
      await press(t, 'Check code');
      expect(find.text('Adam'), findsOneWidget);
      expect(find.text('Seeker · first name and role only'), findsOneWidget);
      expect(find.text('How are you related?'), findsOneWidget);
      await press(t, 'Send request');
      expect(find.text('Choose how you are related first.'), findsOneWidget);
      expect(find.text('Request sent'), findsNothing);
      ScaffoldMessenger.of(
        t.element(find.byType(ZyraCodeScreen)),
      ).clearSnackBars();
      await t.pumpAndSettle();

      await press(t, 'Father');
      expect(
        t
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Father'))
            .selected,
        isTrue,
      );
      await press(t, 'Send request');
      expect(find.text('Request sent'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(ZyraWaliLinkService.invitationRevision.value, invitationRevision);
      expect(telemetry.snapshot.sessionEventCount, originalEvents);
    },
  );
}
