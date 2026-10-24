import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/zyra_external_tester_policy.dart';
import 'package:zyra/screens/auth/tester_access_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';

void main() {
  const username = 'apple-review';
  const password = 'review-password';

  setUp(() {
    ZyraDeveloperAccess.clearExternalTesterAuthorization();
    ZyraExternalTesterPolicy.setForTesting(
      enabled: true,
      username: username,
      password: password,
    );
  });

  tearDown(() {
    ZyraDeveloperAccess.clearExternalTesterAuthorization();
    ZyraExternalTesterPolicy.setForTesting();
  });

  test('review access requires both exact demo fields', () {
    expect(
      ZyraDeveloperAccess.authorizeExternalTester(
        username: username,
        password: 'wrong',
      ),
      isFalse,
    );
    expect(
      ZyraDeveloperAccess.authorizeExternalTester(
        username: 'wrong',
        password: password,
      ),
      isFalse,
    );
    expect(
      ZyraDeveloperAccess.authorizeExternalTester(
        username: ' $username ',
        password: password,
      ),
      isTrue,
    );
  });

  test('review access remains closed when the build gate is off', () {
    ZyraExternalTesterPolicy.setForTesting(
      enabled: false,
      username: username,
      password: password,
    );

    expect(
      ZyraDeveloperAccess.authorizeExternalTester(
        username: username,
        password: password,
      ),
      isFalse,
    );
  });

  testWidgets('valid review details reveal both complete app experiences', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TesterAccessScreen()));

    expect(find.text('Review access'), findsOneWidget);
    expect(find.text('Seeker'), findsNothing);
    expect(find.text('Guardian'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('tester_username_field')),
      username,
    );
    await tester.enterText(
      find.byKey(const ValueKey('tester_password_field')),
      password,
    );
    await tester.tap(find.byKey(const ValueKey('tester_verify_button')));
    await tester.pump();

    expect(find.text('Choose an experience'), findsOneWidget);
    expect(find.text('Seeker'), findsOneWidget);
    expect(find.text('Guardian'), findsOneWidget);
    expect(ZyraDeveloperAccess.isAuthorizedTester, isTrue);
  });

  testWidgets('invalid review details show a clear error', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TesterAccessScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('tester_username_field')),
      username,
    );
    await tester.enterText(
      find.byKey(const ValueKey('tester_password_field')),
      'wrong',
    );
    await tester.tap(find.byKey(const ValueKey('tester_verify_button')));
    await tester.pump();

    expect(
      find.text('Those review details are not recognised.'),
      findsOneWidget,
    );
    expect(find.text('Choose an experience'), findsNothing);
    expect(ZyraDeveloperAccess.isAuthorizedTester, isFalse);
  });
}
