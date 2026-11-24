// LOCK 40 replaces the old Hidden Profiles inspection page with one
// first-name/date list. These are the retained safety invariants on its real
// Founder Settings route; no member store or network is used.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/received_request_fixture.dart';
import 'visual/baseline_capture_support.dart';

const _sara = 'draft-sara';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE/build/line134/hidden_blocked';

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);

  BaselineHarness harness(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return BaselineHarness(
      tester,
      group: 'line134_hidden_blocked',
      evidenceRoot: _evidence,
    );
  }

  test('unhide and unblock change only their own sample flags', () {
    final model = ReceivedRequestFixture(capacity: 3);
    final request = model.stateFor(_sara);
    expect(model.hide(_sara), isTrue);
    expect(model.block(_sara), isTrue);
    expect(model.unhide(_sara), isTrue);
    expect(model.isHidden(_sara), isFalse);
    expect(model.blockedPeers.contains(_sara), isTrue);
    expect(model.stateFor(_sara), request);
    expect(model.unblock(_sara), isTrue);
    expect(model.blockedPeers.contains(_sara), isFalse);
    expect(model.stateFor(_sara), request);
  });

  testWidgets(
    'Show again removes only hide; it cannot restore a past request',
    (tester) async {
      final model = ReceivedRequestFixture(capacity: 3)..hide(_sara);
      final before = model.stateFor(_sara);
      final h = harness(tester);
      await h.mount(tab: 4, pages: const ['settings'], model: model);
      final current = h.shellFixture.model;
      await h.tap('concept_settings_hiddenProfiles');
      expect(find.text('Hidden and blocked'), findsOneWidget);
      expect(find.text('Sara'), findsOneWidget);
      expect(find.byKey(const ValueKey('privacy_show_$_sara')), findsOneWidget);
      expect(find.text('View profile'), findsNothing);
      await h.tap('privacy_show_$_sara');
      expect(current.isHidden(_sara), isFalse);
      expect(current.stateFor(_sara), before);
      expect(find.text('No one is hidden.'), findsOneWidget);
    },
  );

  testWidgets('Unblock confirms first and leaves the request untouched', (
    tester,
  ) async {
    final model = ReceivedRequestFixture(capacity: 3)..block(_sara);
    final before = model.stateFor(_sara);
    final h = harness(tester);
    await h.mount(tab: 4, pages: const ['settings'], model: model);
    final current = h.shellFixture.model;
    await h.tap('concept_settings_hiddenProfiles');
    await h.tap('privacy_unblock_$_sara');
    expect(current.blockedPeers.contains(_sara), isTrue);
    await h.tap('privacy_keep_blocked');
    expect(current.blockedPeers.contains(_sara), isTrue);
    await h.tap('privacy_unblock_$_sara');
    await h.tap('privacy_confirm_unblock');
    expect(current.blockedPeers.contains(_sara), isFalse);
    expect(current.stateFor(_sara), before);
    expect(find.text('No one is blocked.'), findsOneWidget);
  });

  testWidgets('a retained Show again callback loses ownership after Back', (
    tester,
  ) async {
    final model = ReceivedRequestFixture(capacity: 3)..hide(_sara);
    final h = harness(tester);
    await h.mount(tab: 4, pages: const ['settings'], model: model);
    final current = h.shellFixture.model;
    await h.tap('concept_settings_hiddenProfiles');
    final retained = tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('privacy_show_$_sara')),
        )
        .onPressed!;
    await tester.binding.handlePopRoute();
    await h.flush();
    retained();
    await h.flush();
    expect(current.isHidden(_sara), isTrue);
  });
}
