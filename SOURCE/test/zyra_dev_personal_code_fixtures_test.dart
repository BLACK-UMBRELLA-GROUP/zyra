// LOCK 14 V5: APP_COLOURS/RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V5.md;
// masters APP_COLOURS/MASTERS/c11_app_icon_1024.png and c12_splash.png.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_personal_code_fixtures.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platformCalls = <MethodCall>[];
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

  setUp(() {
    platformCalls.clear();
    ZyraText.useTestFontStubs = true;
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (_) async => '');
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

  testWidgets(
    'Founder preview renders its local code without a refresh error',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      ZyraInternalPreviewClient.beginPreview();
      AppState.instance.applyDevPreset(name: 'Adam', gender: 'male');

      await tester.pumpWidget(
        const MaterialApp(home: ZyraCodeScreen(asGuardian: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('ZYRA-DEMO-SEEKER-ADAM'), findsOneWidget);
      expect(find.textContaining("couldn't be refreshed"), findsNothing);
      expect(find.textContaining('not stored or accepted'), findsOneWidget);
      expect(find.text('Change code'), findsNothing);
    },
  );

  testWidgets('QR morphs inside the expanded card without changing page mode', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(name: 'Adam', gender: 'male');

    await tester.pumpWidget(
      const MaterialApp(home: ZyraCodeScreen(asGuardian: false)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('zyra_code_details')), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.tap(find.text('QR'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('zyra_code_qr_preview')), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Tap QR again to return'), findsOneWidget);

    await tester.tap(find.text('QR'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('zyra_code_details')), findsOneWidget);
    expect(find.text('Tap QR again to return'), findsNothing);
  });

  testWidgets('Copy stays confirmed and repeat taps replay feedback', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(name: 'Adam', gender: 'male');

    await tester.pumpWidget(
      const MaterialApp(home: ZyraCodeScreen(asGuardian: false)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(find.text('Copied'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Copied')).style?.color,
      const Color(0xFF845F24),
    );
    expect(find.text('ZYRA Code copied.'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byKey(const ValueKey('small-action-Copied-1')), findsOneWidget);

    await tester.tap(find.text('Copied'));
    await tester.pump();
    expect(find.byKey(const ValueKey('small-action-Copied-2')), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.text('Share')).style?.color,
      const Color(0xFF845F24),
    );

    expect(
      platformCalls.where(
        (call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.selectionClick',
      ),
      hasLength(3),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Copied'), findsOneWidget);
    expect(find.text('Copy'), findsNothing);
    expect(
      tester.widget<Text>(find.text('Copied')).style?.color,
      const Color(0xFF845F24),
    );
  });

  testWidgets(
    'Enter code closes QR and previews valid and wrong codes inline',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      ZyraInternalPreviewClient.beginPreview();
      AppState.instance.applyDevPreset(name: 'Adam', gender: 'male');

      await tester.pumpWidget(
        const MaterialApp(home: ZyraCodeScreen(asGuardian: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('QR'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('zyra_code_qr_preview')),
        findsOneWidget,
      );

      await tester.tap(find.text('Enter code'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('zyra_code_qr_preview')), findsNothing);
      expect(
        find.byKey(const ValueKey('inline-zyra-code-field')),
        findsOneWidget,
      );
      final composerRect = tester.getRect(
        find.byKey(const ValueKey('inline-code-composer')),
      );
      final checkRect = tester.getRect(
        find.byKey(const ValueKey('inline-code-primary-action')),
      );
      // The composer's 1px border wraps the integrated action.
      expect(checkRect.top, closeTo(composerRect.top, 1.1));
      expect(checkRect.right, closeTo(composerRect.right, 1.1));
      expect(checkRect.bottom, closeTo(composerRect.bottom, 1.1));

      await tester.enterText(
        find.byKey(const ValueKey('inline-zyra-code-field')),
        ZyraDevPersonalCodeFixtures.invalidEntryCode,
      );
      await tester.tap(find.text('Check'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Invalid code. Please try again.'), findsOneWidget);
      final clearedField = tester.widget<TextField>(
        find.byKey(const ValueKey('inline-zyra-code-field')),
      );
      expect(clearedField.controller!.text, isEmpty);
      expect(clearedField.focusNode!.hasFocus, isTrue);

      await tester.enterText(
        find.byKey(const ValueKey('inline-zyra-code-field')),
        ZyraDevPersonalCodeFixtures.validGuardianEntryCode,
      );
      await tester.tap(find.text('Check'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('zyra-code-person-confirmation')),
        findsOneWidget,
      );
      expect(find.text('Ibrahim'), findsOneWidget);
      expect(find.text('Guardian'), findsOneWidget);
      expect(find.text('Change code'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      final differentCodeRect = tester.getRect(
        find.byKey(const ValueKey('inline-code-different-action')),
      );
      final confirmRect = tester.getRect(
        find.byKey(const ValueKey('inline-code-primary-action')),
      );
      expect(differentCodeRect.top, confirmRect.top);
      expect(differentCodeRect.height, confirmRect.height);
      expect(
        (differentCodeRect.width - confirmRect.width).abs(),
        lessThan(0.01),
      );
      expect(
        find.byKey(const ValueKey('inline-zyra-code-field')),
        findsNothing,
      );
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      expect(find.text('Request sent'), findsOneWidget);
    },
  );

  testWidgets('Guardian receives the same Seeker confirmation flow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(name: 'Ibrahim', gender: 'male');

    await tester.pumpWidget(
      const MaterialApp(home: ZyraCodeScreen(asGuardian: true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter code'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const ValueKey('inline-zyra-code-field')),
      ZyraDevPersonalCodeFixtures.validSeekerEntryCode,
    );
    await tester.tap(find.text('Check'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Adam'), findsOneWidget);
    expect(find.text('Seeker'), findsOneWidget);
    expect(find.text('How are you related?'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
  });
}
