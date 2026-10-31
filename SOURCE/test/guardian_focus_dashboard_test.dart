import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/widgets/zyra_focus_dashboard.dart';

Future<ZyraFocusDashboard> _mount(
  WidgetTester tester, {
  ZyraGuardianTabsState? state,
  bool paid = true,
  bool linked = true,
  bool main = true,
  int notifications = 0,
  required List<String> actions,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ZyraGuardianTabsPresentation(
          state: state ?? ZyraGuardianTabsState(),
          page: 'my_zyra',
          paid: paid,
          linked: linked,
          adamMain: main,
          notificationCount: notifications,
          photoFor: (_) => null,
          onAction: actions.add,
        ),
      ),
    ),
  );
  return tester.widget<ZyraFocusDashboard>(find.byType(ZyraFocusDashboard));
}

void main() {
  testWidgets('Guardian Focus keeps review and Connect actions distinct', (
    tester,
  ) async {
    final actions = <String>[];
    final dashboard = await _mount(tester, actions: actions, notifications: 2);
    expect(
      dashboard.greeting,
      'Assalamu alaikum, Hassan. You support Adam and Yusuf.',
    );
    expect(dashboard.items.map((item) => item.id), [
      'review-open-0',
      'connect-pending',
    ]);
    final review = dashboard.items.first;
    expect(review.actionLabel, 'Continue');
    expect(review.actionKey, 'guardian_continue');
    expect(review.secondaryLabel, 'Pause');
    expect(review.secondaryKey, 'guardian_pause');
    review.onAction();
    review.onSecondaryAction!();
    dashboard.items.last.onAction();
    for (final chip in dashboard.chips) {
      chip.onTap();
    }
    for (final tile in dashboard.tiles) {
      tile.onTap();
    }
    expect(actions, [
      'continue',
      'pause',
      'received',
      'focus_adam',
      'focus_yusuf',
      'requests',
      'connect',
      'introductions',
      'notifications',
    ]);
    expect(dashboard.tiles.map((tile) => tile.id), [
      'guardian_requests',
      'guardian_connect',
      'guardian_introductions',
      'guardian_notifications',
    ]);
    expect(dashboard.tiles.last.status, '2 new');
    expect(dashboard.tiles.last.isNew, isTrue);
  });

  testWidgets(
    'Guardian Focus paused review preserves Reopen and actual counts',
    (tester) async {
      final actions = <String>[];
      final state = ZyraGuardianTabsState(
        const ZyraGuardianTabsSnapshot(
          review: ZyraGuardianReview.paused,
          connection: ZyraGuardianConnection.dismissed,
          introduced: {'adam:aisha', 'yusuf:noor'},
          sent: {'aisha'},
        ),
      );
      final dashboard = await _mount(tester, state: state, actions: actions);
      expect(dashboard.items.single.id, 'review-paused-0');
      expect(dashboard.items.single.actionLabel, 'Reopen review');
      expect(dashboard.items.single.secondaryLabel, isNull);
      dashboard.items.single.onAction();
      expect(actions, ['reopen']);
      expect(dashboard.chips.first.label, 'Adam · Paused by family');
      expect(dashboard.tiles[1].status, '1 sent');
      expect(dashboard.tiles[1].isNew, isFalse);
      expect(dashboard.tiles[2].status, '2 made');
      expect(dashboard.tiles.last.status, 'Nothing new');
    },
  );

  testWidgets('Guardian Basic hides paid Focus and keeps both locked tiles', (
    tester,
  ) async {
    final actions = <String>[];
    final dashboard = await _mount(tester, paid: false, actions: actions);
    expect(dashboard.items.map((item) => item.id), ['review-open-0']);
    expect(dashboard.tiles[1].locked, isTrue);
    expect(dashboard.tiles[2].locked, isTrue);
    expect(dashboard.tiles[1].status, 'Guardian One');
    expect(dashboard.tiles[2].status, 'Guardian One');
    dashboard.tiles[1].onTap();
    dashboard.tiles[2].onTap();
    expect(actions, ['membership', 'membership']);
  });

  testWidgets('Additional Guardian sees review status without decisions', (
    tester,
  ) async {
    final actions = <String>[];
    final dashboard = await _mount(tester, main: false, actions: actions);
    expect(dashboard.items.single.id, 'review-open-0');
    expect(dashboard.items.single.actionLabel, isEmpty);
    expect(dashboard.items.single.secondaryLabel, isNull);
    dashboard.items.single.onAction();
    expect(actions, isEmpty);
    expect(dashboard.tiles.first.status, 'None');
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Pause'), findsNothing);
  });

  testWidgets(
    'Focus consumption preserves review, Connect, and attention state',
    (tester) async {
      final actions = <String>[];
      final state = ZyraGuardianTabsState(
        const ZyraGuardianTabsSnapshot(
          focusIndex: 1,
          consumedFocus: {'connect-pending'},
        ),
      );
      final dashboard = await _mount(tester, state: state, actions: actions);
      expect(dashboard.items.map((item) => item.id), ['review-open-0']);
      expect(state.connection, ZyraGuardianConnection.pending);
      expect(state.review, ZyraGuardianReview.open);
      expect(state.attentionSeen, isFalse);
      dashboard.onIndexChanged!(0);
      expect(actions, ['focus_index_0']);
      final saved = state.snapshot;
      state.consumedFocus.add('review-open-0');
      expect(saved.consumedFocus, {'connect-pending'});
      expect(() => saved.consumedFocus.add('anything'), throwsUnsupportedError);
      final restored = ZyraGuardianTabsState(saved);
      expect(restored.focusIndex, 1);
      expect(restored.consumedFocus, {'connect-pending'});
    },
  );

  testWidgets(
    'Review consumption follows event revision through countdown and restore',
    (tester) async {
      final actions = <String>[];
      final original = ZyraGuardianTabsState(
        const ZyraGuardianTabsSnapshot(
          connection: ZyraGuardianConnection.dismissed,
        ),
      );
      original.consumedFocus.add(original.reviewFocusId);
      original.hours = 40;
      final restored = ZyraGuardianTabsState(original.snapshot);
      expect(restored.hours, 40);
      expect(restored.reviewRevision, 0);
      expect(restored.reviewFocusId, 'review-open-0');
      var dashboard = await _mount(tester, state: restored, actions: actions);
      expect(dashboard.items, isEmpty);

      // A genuine new event is separate even if its display hours are equal.
      restored.reviewRevision++;
      dashboard = await _mount(tester, state: restored, actions: actions);
      expect(dashboard.items.single.id, 'review-open-1');
      expect(dashboard.items.single.detail, contains('40 hours left'));
      expect(restored.consumedFocus, {'review-open-0'});
      final newEvent = ZyraGuardianTabsState(restored.snapshot);
      expect(newEvent.reviewRevision, 1);
      expect(newEvent.reviewFocusId, 'review-open-1');
    },
  );

  test('Negative review revision restores to the initial event', () {
    final state = ZyraGuardianTabsState(
      const ZyraGuardianTabsSnapshot(reviewRevision: -1),
    );
    expect(state.reviewRevision, 0);
    expect(state.reviewFocusId, 'review-open-0');
  });

  testWidgets('Unlinked Guardian has no family Focus or private status chips', (
    tester,
  ) async {
    final actions = <String>[];
    final dashboard = await _mount(tester, linked: false, actions: actions);
    expect(dashboard.items, isEmpty);
    expect(dashboard.chips, isEmpty);
    expect(dashboard.greeting, 'Assalamu alaikum, Hassan.');
    expect(dashboard.tiles.first.status, 'None');
    expect(dashboard.tiles[1].isNew, isFalse);
  });
}
