import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.zyraconnect.zyra/app_icon');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var readCalls = 0;
  var writeCalls = 0;
  String? activeIcon;

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    readCalls = 0;
    writeCalls = 0;
    activeIcon = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAppIconState') {
        readCalls++;
      } else {
        expect(call.method, 'setAppIcon');
        writeCalls++;
        activeIcon = (call.arguments as Map)['iconName'] as String?;
      }
      return {'supported': true, 'iconName': activeIcon};
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('Home keeps splash directions without icon previews or writes', (
    tester,
  ) async {
    const restarts = 0;
    const closes = 0;
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('Splash directions'), findsNothing);
    expect(find.text('App icon directions'), findsNothing);
    expect(find.byKey(const ValueKey('dev_home_section_icons')), findsNothing);
    expect(closes, 0);
    expect(readCalls, 0);
    expect(writeCalls, 0);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(restarts, 0);
    expect(tester.takeException(), isNull);
  });
}
