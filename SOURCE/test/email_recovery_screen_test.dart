import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/auth/email_recovery_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_auth.dart';

void main() {
  testWidgets(
    'recovery uses a verified email code and never asks for a password',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? sentTo;
      String? verifiedEmail;
      String? verifiedCode;
      var recovered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: EmailRecoveryScreen(
            sendCode: (email) async {
              sentTo = email;
              return const ZyraAuthResult.success();
            },
            verifyCode: ({required email, required code}) async {
              verifiedEmail = email;
              verifiedCode = code;
              return const ZyraAuthResult.success();
            },
            onRecovered: () async => recovered = true,
          ),
        ),
      );

      expect(
        find.textContaining('password', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Password'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('recovery_signin_email')),
        '  Founder@Yahoo.com ',
      );
      await tester.tap(find.byKey(const ValueKey('recovery_signin_send')));
      await tester.pump();

      expect(sentTo, 'founder@yahoo.com');
      expect(find.text('Check your email.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('recovery_signin_code')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('recovery_signin_verify')));
      await tester.pump();

      expect(verifiedEmail, 'founder@yahoo.com');
      expect(verifiedCode, '123456');
      expect(recovered, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  test('email validation rejects malformed recovery addresses', () {
    expect(ZyraAuth.isValidEmail('founder@yahoo.com'), isTrue);
    expect(ZyraAuth.isValidEmail('founder@yahoo'), isFalse);
    expect(ZyraAuth.isValidEmail('founder @yahoo.com'), isFalse);
  });

  testWidgets('welcome exposes recovery without overflowing a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('Use recovery email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
