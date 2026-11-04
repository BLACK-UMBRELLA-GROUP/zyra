import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
// The former tools have no replacement UI; ordinary member entry remains.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/screens/auth/email_recovery_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_loading.dart';
import 'support/queue44_removed_controls_fixture.dart';
import 'visual/baseline_capture_support.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: ZyraInternalFounderPolicy.approvedSupabaseUrl,
      publishableKey: 'queue44-local-widget-test',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((_) async => http.Response('offline', 403)),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });
  testWidgets('member sign-in remains available with every Home tool removed', (
    t,
  ) async {
    await t.pumpWidget(const Queue44MemberFrame(child: WelcomeScreen()));
    await t.pumpAndSettle();
    expectQueue44ControlsAbsent();
    await t.tap(find.byKey(const ValueKey('welcome_recovery_email')));
    await t.pumpAndSettle();
    expect(find.byType(EmailRecoveryScreen), findsOneWidget);
    expectQueue44ControlsAbsent();
  });
  testWidgets(
    'member signup remains available without developer signup shortcuts',
    (t) async {
      await t.pumpWidget(const Queue44MemberFrame(child: WelcomeScreen()));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('welcome_google')), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome_apple')), findsOneWidget);
      expectQueue44ControlsAbsent();
    },
  );
  testWidgets('a waiting member page has no Home or reset actions', (t) async {
    await t.pumpWidget(const Queue44MemberFrame(child: ZyraQuietLoading()));
    await t.pump();
    final before = ZyraAccountState.generation;
    expectQueue44ControlsAbsent();
    await t.pump(const Duration(seconds: 4));
    expect(ZyraAccountState.generation, before);
    expectQueue44ControlsAbsent();
  });
  testWidgets(
    'member entry stays usable at narrow enlarged text without a tools panel',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      const evidence =
          '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE/.buildlog/queue44_20261103/home-tools-compact';
      await t.runAsync(() => baselineSetUp(evidenceRoot: evidence));
      addTearDown(baselineTearDown);
      final h = BaselineHarness(
        t,
        group: 'compact',
        outputRoot: evidence,
        evidenceRoot: evidence,
        textScale: 2,
      );
      await h.mount(tab: 4);
      t.view.physicalSize = const Size(960, 1704);
      await h.flush();
      expectQueue44ControlsAbsent();
      expect(t.takeException(), isNull);
    },
  );
  for (final role in ['entry', 'Seeker', 'Guardian']) {
    testWidgets(
      '$role page has no Developer Access heading or contextual tools',
      (t) async {
        if (role == 'entry') {
          await t.pumpWidget(const Queue44MemberFrame(child: WelcomeScreen()));
          await t.pumpAndSettle();
        } else {
          const evidence =
              '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE/.buildlog/queue44_20261103/home-tools';
          await t.runAsync(() => baselineSetUp(evidenceRoot: evidence));
          addTearDown(baselineTearDown);
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final h = BaselineHarness(
            t,
            group: role,
            outputRoot: evidence,
            evidenceRoot: evidence,
          );
          await h.mount(
            guardian: role == 'Guardian',
            tab: role == 'Guardian' ? 3 : 4,
          );
        }
        expect(find.text('Developer Access'), findsNothing);
        expectQueue44ControlsAbsent();
      },
    );
  }
}
