// The account pause UI requires the versioned owner-only RPC contract.
// All HTTP is intercepted; old discovery booleans are not a pause authority.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/settings/privacy_settings_screen.dart';

import 'support/zyra_profile_pause_fixture.dart';

Finder get _action => find.byKey(const ValueKey('profile-pause-action'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = ProfilePauseFixture();
  setUpAll(fixture.initialize);
  tearDownAll(fixture.dispose);
  setUp(fixture.reset);
  tearDown(fixture.afterEach);

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacySettingsScreen()));
    await fixture.settle(tester);
  }

  testWidgets(
    'unknown pause status cannot enable an action, but a confirmed retry can',
    (tester) async {
      fixture.missing = true;
      await mount(tester);
      expect(find.text('Pause status unavailable'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(tester.widget<FilledButton>(_action).onPressed, isNull);
      fixture.missing = false;
      await tester.tap(find.byKey(const ValueKey('profile-pause-retry')));
      await fixture.settle(tester);
      expect(find.text('Profile active'), findsOneWidget);
      expect(tester.widget<FilledButton>(_action).onPressed, isNotNull);
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'pause display changes only after a fresh authoritative readback',
    (tester) async {
      await mount(tester);
      final release = Completer<void>();
      fixture.intercept = (request) async {
        if (!request.url.path.endsWith('/zyra_my_profile_pause_state')) {
          return null;
        }
        await release.future;
        return ProfilePauseFixture.response(fixture.payload());
      };
      await tester.tap(_action);
      await tester.pump();
      expect(find.text('Profile paused'), findsNothing);
      expect(find.text('Profile active'), findsOneWidget);
      expect(tester.widget<FilledButton>(_action).onPressed, isNull);
      release.complete();
      await fixture.settle(tester);
      expect(find.text('Profile paused'), findsOneWidget);
      expect(fixture.calls('zyra_my_profile_pause_state'), 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('malformed or other-owner status is unavailable, never active', (
    tester,
  ) async {
    fixture.intercept = (_) async => ProfilePauseFixture.response({
      ...fixture.payload(),
      'owner_id': pauseOwnerB,
    });
    await mount(tester);
    expect(find.text('Pause status unavailable'), findsOneWidget);
    expect(find.text('Profile active'), findsNothing);
    expect(tester.widget<FilledButton>(_action).onPressed, isNull);
    expect(fixture.calls('zyra_set_my_profile_pause'), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('old-owner write never reads back a replacement account', (
    tester,
  ) async {
    await mount(tester);
    final release = Completer<void>();
    fixture.intercept = (request) async {
      if (!request.url.path.endsWith('/zyra_set_my_profile_pause')) return null;
      await release.future;
      return ProfilePauseFixture.response({
        ...fixture.payload(),
        'paused': true,
        'revision': 2,
      });
    };
    await tester.tap(_action);
    await tester.pump();
    await fixture.transition(tester, pauseOwnerB);
    release.complete();
    await fixture.settle(tester);
    expect(find.text('Pause status unavailable'), findsOneWidget);
    expect(find.text('Profile paused'), findsNothing);
    expect(fixture.calls('zyra_my_profile_pause_state'), 1);
    expect(fixture.calls('zyra_set_my_profile_pause'), 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
