// Account controls are informative only; every synthetic HTTP request is denied.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/screens/settings/account_advanced_screen.dart';
import 'package:zyra/screens/subscription/membership_required_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_profile_service.dart';

import 'support/zyra_profile_pause_fixture.dart';

VoidCallback _rowAction(WidgetTester tester, String label) => tester
    .widget<InkWell>(
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
    )
    .onTap!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = ProfilePauseFixture();
  setUpAll(fixture.initialize);
  tearDownAll(fixture.dispose);
  setUp(fixture.reset);
  tearDown(fixture.afterEach);

  Future<GlobalKey<NavigatorState>> mount(
    WidgetTester tester, {
    bool guardian = false,
  }) async {
    final key = GlobalKey<NavigatorState>();
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        home: AccountAdvancedScreen(guardian: guardian),
      ),
    );
    await fixture.settle(tester);
    return key;
  }

  for (final guardian in [false, true]) {
    for (final action in ['Reset profile', 'Delete account']) {
      final reset = action == 'Reset profile';
      final title = reset ? 'Reset Profile' : 'Delete Account';
      testWidgets('guardian=$guardian $action opens only an explanation', (
        tester,
      ) async {
        await mount(tester, guardian: guardian);
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(find.textContaining('not available'), findsWidgets);
        expect(find.byType(FilledButton), findsNothing);
        expect(find.text('Start fresh'), findsNothing);
        expect(
          find
              .byKey(const ValueKey('account-control-info-support'))
              .hitTestable(),
          findsOneWidget,
        );
        expect(fixture.requests, isEmpty);
        expect(supabase.auth.currentUser!.id, pauseOwnerA);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  for (final action in ['Reset profile', 'Delete account']) {
    testWidgets('$action retained callback denies replacement and A-B-A', (
      tester,
    ) async {
      await mount(tester);
      final callback = _rowAction(tester, action);
      await fixture.transition(tester, pauseOwnerB);
      callback();
      await tester.pumpAndSettle();
      expect(find.text('Reset Profile'), findsNothing);
      expect(find.text('Delete Account'), findsNothing);
      await fixture.transition(tester, pauseOwnerA);
      callback();
      await tester.pumpAndSettle();
      expect(find.text('Reset Profile'), findsNothing);
      expect(find.text('Delete Account'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(fixture.requests, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('$action duplicate tap opens one informational route only', (
      tester,
    ) async {
      final navigator = await mount(tester);
      final callback = _rowAction(tester, action);
      callback();
      callback();
      await tester.pumpAndSettle();
      expect(
        find.text(
          action == 'Reset profile' ? 'Reset Profile' : 'Delete Account',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(find.byType(FilledButton, skipOffstage: false), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Advanced'), findsOneWidget);
      expect(fixture.requests, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'old informational actions cannot pop a cover or open Help for a replacement',
    (tester) async {
      final navigator = await mount(tester);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      final back = tester
          .widget<IconButton>(
            find.byKey(const ValueKey('account-control-info-back')),
          )
          .onPressed!;
      final support = tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('account-control-info-support')),
          )
          .onPressed!;
      navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Unrelated cover')),
        ),
      );
      await tester.pumpAndSettle();
      back();
      support();
      await tester.pumpAndSettle();
      expect(find.text('Unrelated cover'), findsOneWidget);
      await fixture.transition(tester, pauseOwnerB);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      back();
      support();
      await tester.pumpAndSettle();
      expect(find.text('Account controls unavailable'), findsOneWidget);
      expect(find.text('Help & support'), findsNothing);
      expect(fixture.requests, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final change in ['SDK-only A-B-A', 'preview A-off']) {
    testWidgets('$change cannot revive either retained Advanced destination', (
      tester,
    ) async {
      await mount(tester);
      final reset = _rowAction(tester, 'Reset profile');
      final deletion = _rowAction(tester, 'Delete account');
      final generation = ZyraAccountState.generation;
      if (change == 'SDK-only A-B-A') {
        await tester.runAsync(() async {
          await fixture.session(pauseOwnerB, synchronize: false);
          await fixture.session(pauseOwnerA, synchronize: false);
          await Future<void>.delayed(Duration.zero);
        });
      } else {
        ZyraInternalPreviewClient.beginPreview();
        ZyraInternalPreviewClient.finishSignOut();
      }
      reset();
      deletion();
      await fixture.settle(tester);
      expect(ZyraAccountState.generation, generation);
      expect(find.text('Reset Profile'), findsNothing);
      expect(find.text('Delete Account'), findsNothing);
      expect(
        find.textContaining('Account controls unavailable'),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsNothing);
      expect(fixture.requests, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('same-owner healthy refresh preserves informative navigation', (
    tester,
  ) async {
    await mount(tester);
    final reset = _rowAction(tester, 'Reset profile');
    final generation = ZyraAccountState.generation;
    await tester.runAsync(() => fixture.refresh());
    await fixture.settle(tester);
    reset();
    await fixture.settle(tester);
    expect(find.text('Reset Profile'), findsOneWidget);
    expect(ZyraAccountState.generation, generation);
    expect(find.byType(FilledButton), findsNothing);
    expect(fixture.requests, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'membership-required Guardian route preserves Guardian identity',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: MembershipRequiredScreen(guardian: true)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download or delete account data'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AccountAdvancedScreen>(find.byType(AccountAdvancedScreen))
            .guardian,
        isTrue,
      );
      await tester.tap(find.text('Reset profile'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Guardian profile reset is not available'),
        findsOneWidget,
      );
      expect(fixture.requests, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'held service methods do not perform cleanup, RPC, logout or account changes',
    () async {
      final generation = ZyraAccountState.generation;
      expect(
        (await ZyraProfileService.resetProfile()).outcome,
        ZyraResetOutcome.refused,
      );
      expect(await ZyraAuth.deleteAccount(), isFalse);
      expect(fixture.requests, isEmpty);
      expect(supabase.auth.currentUser!.id, pauseOwnerA);
      expect(ZyraAccountState.generation, generation);
    },
  );
}
