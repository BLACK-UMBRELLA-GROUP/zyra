import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/settings/privacy_settings_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';

import 'support/zyra_profile_pause_fixture.dart';

Finder get _action => find.byKey(const ValueKey('profile-pause-action'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = ProfilePauseFixture();
  setUpAll(fixture.initialize);
  tearDownAll(fixture.dispose);
  setUp(fixture.reset);
  tearDown(fixture.afterEach);

  Future<void> flushFrames(WidgetTester tester, {int frames = 24}) async {
    // Do not pumpAndSettle a route that contains app background decoration.
    // Advance a bounded transition window and separately allow intercepted
    // HTTP body futures to drain in the real async zone.
    for (var frame = 0; frame < frames; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(
          Duration.zero,
        ).timeout(const Duration(seconds: 2)),
      );
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    bool Function() ready, {
    required String reason,
  }) async {
    for (var frame = 0; frame < 40 && !ready(); frame++) {
      await flushFrames(tester, frames: 1);
    }
    expect(ready(), isTrue, reason: reason);
  }

  Completer<void> heldReply() {
    final release = Completer<void>();
    addTearDown(() {
      // A failed assertion must not leave the intercepted client hanging.
      if (!release.isCompleted) release.complete();
    });
    return release;
  }

  Future<GlobalKey<NavigatorState>> mount(
    WidgetTester tester, {
    bool settle = true,
    Size size = const Size(393, 852),
    double scale = 1,
  }) async {
    final navigator = GlobalKey<NavigatorState>();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const PrivacySettingsScreen(),
      ),
    );
    if (settle) await fixture.settle(tester);
    return navigator;
  }

  testWidgets(
    'confirmed pause and unpause remain signed in without changing Journey records',
    (tester) async {
      final generation = ZyraAccountState.generation;
      await mount(tester);
      expect(find.text('Profile active'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      await tester.tap(_action);
      await fixture.settle(tester);
      expect(find.text('Profile paused'), findsOneWidget);
      expect(find.text('Unpause My Profile'), findsOneWidget);
      await tester.tap(_action);
      await fixture.settle(tester);
      expect(find.text('Profile active'), findsOneWidget);
      expect(ZyraAccountState.generation, generation);
      expect(fixture.calls('zyra_set_my_profile_pause'), 2);
      expect(
        fixture.requests.every(
          (request) => request.url.path.contains('profile_pause'),
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'missing server contract is unknown and cannot enable a local pause',
    (tester) async {
      fixture.missing = true;
      await mount(tester);
      expect(find.text('Pause status unavailable'), findsOneWidget);
      expect(tester.widget<FilledButton>(_action).onPressed, isNull);
      expect(find.text('Profile active'), findsNothing);
      expect(find.text('Profile paused'), findsNothing);
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      await tester.tap(find.byKey(const ValueKey('profile-pause-retry')));
      await fixture.settle(tester);
      expect(fixture.calls('zyra_my_profile_pause_state'), 2);
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'unconfirmed write shows unknown instead of an optimistic paused state',
    (tester) async {
      await mount(tester);
      final release = heldReply();
      fixture.intercept = (request) async {
        if (!request.url.path.endsWith('/zyra_my_profile_pause_state')) {
          return null;
        }
        await release.future;
        return ProfilePauseFixture.response({'message': 'Unavailable'}, 503);
      };
      await tester.tap(_action);
      await tester.pump();
      expect(find.text('Profile paused'), findsNothing);
      expect(find.text('Confirming…'), findsOneWidget);
      expect(tester.widget<FilledButton>(_action).onPressed, isNull);
      release.complete();
      await fixture.settle(tester);
      expect(find.text('Pause status unavailable'), findsOneWidget);
      expect(find.text('Profile paused'), findsNothing);
      expect(find.textContaining("couldn't confirm"), findsOneWidget);
      expect(fixture.paused, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a retained action cannot stack writes before a repaint', (
    tester,
  ) async {
    await mount(tester);
    final action = tester.widget<FilledButton>(_action).onPressed!;
    action();
    action();
    await fixture.settle(tester);
    expect(fixture.calls('zyra_set_my_profile_pause'), 1);
    expect(find.text('Profile paused'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opening owner replacement and A-B-A retire old controls', (
    tester,
  ) async {
    await mount(tester);
    final action = tester.widget<FilledButton>(_action).onPressed!;
    await fixture.transition(tester, pauseOwnerB);
    action();
    await fixture.transition(tester, pauseOwnerA);
    action();
    await fixture.settle(tester);
    expect(fixture.calls('zyra_set_my_profile_pause'), 0);
    expect(find.text('Pause status unavailable'), findsOneWidget);
    expect(tester.widget<FilledButton>(_action).onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'cover-uncover ABA retires prior action but permits a fresh confirmed one',
    (tester) async {
      final navigator = await mount(tester);
      final stale = tester.widget<FilledButton>(_action).onPressed!;
      navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover')),
        ),
      );
      await flushFrames(tester);
      expect(find.text('Cover').hitTestable(), findsOneWidget);
      stale();
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      navigator.currentState!.pop();
      await flushFrames(tester);
      await waitFor(
        tester,
        () =>
            find.text('Profile active').evaluate().isNotEmpty &&
            _action.hitTestable().evaluate().isNotEmpty &&
            tester.widget<FilledButton>(_action).onPressed != null,
        reason: 'Uncovered opening route receives a fresh confirmed read',
      );
      expect(fixture.calls('zyra_my_profile_pause_state'), 2);
      stale();
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      expect(find.text('Profile active'), findsOneWidget);
      await tester.tap(_action);
      await fixture.settle(tester);
      expect(fixture.calls('zyra_set_my_profile_pause'), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  for (final change in ['SDK-only A-B-A', 'preview A-off']) {
    testWidgets(
      '$change clears visible confirmation and denies retained actions',
      (tester) async {
        await mount(tester);
        final stale = tester.widget<FilledButton>(_action).onPressed!;
        final generation = ZyraAccountState.generation;
        if (change == 'SDK-only A-B-A') {
          // No aggregate AccountState transition or intermediate rendered frame.
          await tester.runAsync(() async {
            await fixture.session(pauseOwnerB, synchronize: false);
            await fixture.session(pauseOwnerA, synchronize: false);
            await Future<void>.delayed(Duration.zero);
          });
        } else {
          ZyraInternalPreviewClient.beginPreview();
          ZyraInternalPreviewClient.finishSignOut();
        }
        stale();
        await fixture.settle(tester);
        expect(ZyraAccountState.generation, generation);
        expect(find.text('Profile active'), findsNothing);
        expect(find.text('Profile paused'), findsNothing);
        expect(find.text('Pause status unavailable'), findsOneWidget);
        expect(tester.widget<FilledButton>(_action).onPressed, isNull);
        expect(
          tester
              .widget<TextButton>(
                find.byKey(const ValueKey('profile-pause-retry')),
              )
              .onPressed,
          isNull,
        );
        expect(fixture.calls('zyra_set_my_profile_pause'), 0);
        expect(fixture.calls('zyra_my_profile_pause_state'), 1);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'healthy refresh clears old action then fresh retry remains usable',
    (tester) async {
      await mount(tester);
      final stale = tester.widget<FilledButton>(_action).onPressed!;
      final generation = ZyraAccountState.generation;
      await tester.runAsync(() => fixture.refresh());
      await fixture.settle(tester);
      expect(find.text('Profile active'), findsNothing);
      expect(find.text('Pause status unavailable'), findsOneWidget);
      stale();
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      final retry = find.byKey(const ValueKey('profile-pause-retry'));
      expect(tester.widget<TextButton>(retry).onPressed, isNotNull);
      await tester.tap(retry);
      await fixture.settle(tester);
      expect(find.text('Profile active'), findsOneWidget);
      stale();
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      await tester.tap(_action);
      await fixture.settle(tester);
      expect(find.text('Profile paused'), findsOneWidget);
      expect(ZyraAccountState.generation, generation);
      expect(fixture.calls('zyra_set_my_profile_pause'), 1);
      expect(fixture.calls('zyra_my_profile_pause_state'), 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'a held read cannot disclose the previous owner after replacement',
    (tester) async {
      final release = heldReply();
      fixture.intercept = (_) async {
        await release.future;
        return ProfilePauseFixture.response(fixture.payload());
      };
      await mount(tester, settle: false);
      await tester.pump();
      await fixture.transition(tester, pauseOwnerB);
      release.complete();
      await fixture.settle(tester);
      expect(find.text('Pause status unavailable'), findsOneWidget);
      expect(find.text('Profile active'), findsNothing);
      expect(fixture.calls('zyra_my_profile_pause_state'), 1);
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('disposal denies retained action and held reply', (tester) async {
    await mount(tester);
    final stale = tester.widget<FilledButton>(_action).onPressed!;
    final release = heldReply();
    fixture.intercept = (_) async {
      await release.future;
      return ProfilePauseFixture.response({
        ...fixture.payload(),
        'paused': true,
        'revision': 2,
      });
    };
    stale();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    stale();
    release.complete();
    await fixture.settle(tester);
    expect(fixture.calls('zyra_set_my_profile_pause'), 1);
    expect(fixture.calls('zyra_my_profile_pause_state'), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small double-text pause content and action remain reachable', (
    tester,
  ) async {
    await mount(tester, size: const Size(320, 568), scale: 2);
    await tester.scrollUntilVisible(
      _action,
      180,
      scrollable: find.byType(Scrollable),
      maxScrolls: 20,
    );
    await tester.ensureVisible(_action);
    await flushFrames(tester);
    expect(_action.hitTestable(), findsOneWidget);
    expect(tester.getSize(_action).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'account notification without a replacement result cannot invent a paused state',
    (tester) async {
      await mount(tester);
      ZyraAccountState.resetForTesting();
      AppState.instance.resetForAccountChange();
      await fixture.settle(tester);
      expect(find.text('Pause status unavailable'), findsOneWidget);
      expect(tester.widget<FilledButton>(_action).onPressed, isNull);
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
