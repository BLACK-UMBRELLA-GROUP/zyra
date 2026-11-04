import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/zyra_external_tester_policy.dart';
import 'package:zyra/main.dart' show ZyraApp, zyraNavigatorKey;
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/theme/zyra_text.dart';
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

  testWidgets(
    'valid review fixture cannot restore a retired review entry route',
    (tester) async {
      ZyraText.useTestFontStubs = true;
      addTearDown(() => ZyraText.useTestFontStubs = false);
      expect(
        ZyraDeveloperAccess.authorizeExternalTester(
          username: username,
          password: password,
        ),
        isTrue,
      );
      await tester.pumpWidget(_ordinaryFrame());
      await tester.pumpAndSettle();
      expect(
        () => zyraNavigatorKey.currentState!.pushNamed<void>('/tester-access'),
        throwsFlutterError,
      );
      expect(find.byType(ViewRequestDraftScreen), findsNothing);
      expect(find.text('Choose an experience'), findsNothing);
      expect(find.text('Ordinary entry'), findsOneWidget);
      expect(ZyraDeveloperAccess.isAuthorizedTester, isTrue);
    },
  );

  testWidgets(
    'invalid review fixture cannot authorize or reveal sample entry',
    (tester) async {
      ZyraText.useTestFontStubs = true;
      addTearDown(() => ZyraText.useTestFontStubs = false);
      expect(
        ZyraDeveloperAccess.authorizeExternalTester(
          username: username,
          password: 'wrong',
        ),
        isFalse,
      );
      await tester.pumpWidget(_ordinaryFrame());
      await tester.pumpAndSettle();
      expect(find.byType(ViewRequestDraftScreen), findsNothing);
      expect(find.text('Choose an experience'), findsNothing);
      expect(find.byKey(const ValueKey('tester_username_field')), findsNothing);
      expect(find.byKey(const ValueKey('tester_password_field')), findsNothing);
      expect(ZyraDeveloperAccess.isAuthorizedTester, isFalse);
      expect(find.text('Ordinary entry'), findsOneWidget);
    },
  );
}

Widget _ordinaryFrame() => Builder(
  builder: (context) {
    final rebuild = const ZyraApp().build(context) as ListenableBuilder;
    final app = rebuild.builder(context, null) as MaterialApp;
    return MaterialApp(
      navigatorKey: app.navigatorKey,
      navigatorObservers: app.navigatorObservers ?? const <NavigatorObserver>[],
      theme: app.theme,
      builder: app.builder,
      routes: app.routes ?? const <String, WidgetBuilder>{},
      onGenerateRoute: app.onGenerateRoute,
      onUnknownRoute: app.onUnknownRoute,
      home: const Scaffold(body: Text('Ordinary entry')),
    );
  },
);
