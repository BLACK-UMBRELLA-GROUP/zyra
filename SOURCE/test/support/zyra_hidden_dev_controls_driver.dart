// Positive integration tests enter the protected controls through the real
// screen hold and leave through the actual X/Home actions. This is a test
// driver, not a production shortcut or a direct shell-state callback.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_hold_to_open.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

const _page = ValueKey('dev_controls_page');
const _close = ValueKey('dev_controls_close');

/// Physical root-tab navigation is two deliberate taps when LOCK 6 is idle.
/// Expand through the real bar before callers measure their destination; the
/// moving small icons are not destination-sized touch targets. Legacy/action
/// bars have no compact surface and are deliberately left alone.
Future<void> expandZyraPreviewTabBarIfIdle(WidgetTester tester) async {
  final surface = find.byKey(const ValueKey('compact-nav-surface'));
  if (surface.evaluate().isEmpty) return;
  expect(surface, findsOneWidget);
  final root = find.byType(ZyraShellNavigation);
  expect(root, findsOneWidget);
  final navigation = tester.widget<ZyraShellNavigation>(root);
  final context = tester.element(surface);
  if (!navigation.interactionEnabled ||
      ModalRoute.of(context)?.isCurrent == false ||
      surface.hitTestable().evaluate().isEmpty) {
    return;
  }
  final viewport = MediaQuery.sizeOf(context).width;
  final fullWidth =
      viewport -
      2 * (navigation.contentEdgeInset ?? ZyraNavBarMetrics.sideInset);
  if (tester.getSize(surface).width >
          fullWidth * (navigation.compactV2 ? .6 : .4) + .01 &&
      tester.getSize(surface).width < fullWidth - .01) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  if (tester.getSize(surface).width >= fullWidth - .01) return;
  final selected = navigation.currentIndex;
  await tester.tapAt(tester.getCenter(surface));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(tester.takeException(), isNull);
  expect(tester.getSize(surface).width, closeTo(fullWidth, .01));
  expect(tester.widget<ZyraShellNavigation>(root).currentIndex, selected);
}

Future<void> openZyraDevControls(WidgetTester tester) async {
  expect(find.byKey(_page), findsNothing);
  // The app-wide host remains inert around a concept-owned child. Select the
  // one admitted holder, never an arbitrary ancestor sharing the surface key.
  final surface = find.byWidgetPredicate(
    (widget) => widget is ZyraDevHoldToOpen && widget.enabled,
  );
  expect(surface, findsOneWidget);
  final rect = tester.getRect(surface);
  final media = MediaQuery.of(tester.element(surface));
  final point = Offset(
    rect.center.dx,
    (rect.top + media.padding.top + 8)
        .clamp(rect.top + 1, rect.bottom - 1)
        .toDouble(),
  );
  final finger = await tester.startGesture(point);
  try {
    await tester.pump(const Duration(seconds: 3));
  } finally {
    await finger.up();
  }
  // This overlay changes in place. The retained page may intentionally keep
  // a loading spinner or gold animation alive, so do not wait for its timers.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byKey(_page), findsOneWidget);
  expect(find.byKey(_close).hitTestable(), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> closeZyraDevControls(WidgetTester tester) async {
  expect(find.byKey(_page), findsOneWidget);
  final close = find.byKey(_close);
  expect(close.hitTestable(), findsOneWidget);
  await tester.tap(close);
  // X returns to the same page, including its deliberate loading state.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byKey(_page), findsNothing);
  expect(tester.takeException(), isNull);
}

Future<void> toggleZyraDevControls(WidgetTester tester) async {
  if (find.byKey(_page).evaluate().isEmpty) {
    await openZyraDevControls(tester);
  } else {
    await closeZyraDevControls(tester);
  }
}

/// Exercise the same left-edge gesture as a sighted user, including the
/// committed closing animation. Never invoke a shell-state callback instead.
Future<void> swipeZyraBack(WidgetTester tester) async {
  final edge = find
      .byKey(const ValueKey('zyra_back_swipe_edge'))
      .hitTestable()
      .last;
  expect(edge, findsOneWidget);
  final rect = tester.getRect(edge);
  final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.timedDragFrom(
    Offset(rect.left + 8, rect.top + rect.height * .4),
    Offset(viewport.width * .72, 0),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// Capture the real accessibility action for stale-owner rejection tests.
/// This is not the physical navigation driver and creates no hidden button.
VoidCallback captureZyraAccessibleBack(WidgetTester tester) {
  final semantics = find
      .byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.key == const ValueKey('zyra_pull_down_back_semantics') &&
            widget.properties.onDismiss != null,
      )
      .last;
  expect(semantics, findsOneWidget);
  final action = tester.widget<Semantics>(semantics).properties.onDismiss;
  expect(action, isNotNull);
  return action!;
}

/// Ordinary page navigation stays a real edge swipe, never a controls toggle.
Future<void> returnZyraPreviewPage(WidgetTester tester) async {
  if (find.byKey(_page).evaluate().isNotEmpty) {
    await closeZyraDevControls(tester);
    return;
  }
  await swipeZyraBack(tester);
}

Future<void> leaveZyraDeveloperPreview(WidgetTester tester) async {
  if (find.byKey(_page).evaluate().isEmpty) {
    await openZyraDevControls(tester);
  }
  final home = find.byKey(const ValueKey('draft_close'));
  if (home.evaluate().isEmpty) {
    final scroll = find.descendant(
      of: find.byKey(const ValueKey('dev_controls_scroll')),
      matching: find.byType(Scrollable),
    );
    expect(scroll, findsOneWidget);
    await tester.scrollUntilVisible(home, 160, scrollable: scroll);
  } else {
    await Scrollable.ensureVisible(tester.element(home), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(home.hitTestable(), findsOneWidget);
  await tester.tap(home);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// Bridges old test-driver command names to the new physical UI. Tests whose
/// old draft_back meant page navigation must use their real edge gesture
/// instead of this controls-only toggle.
Future<bool> pressZyraDevControlKey(WidgetTester tester, String key) async {
  switch (key) {
    case 'draft_rules':
      if (find.byKey(_page).evaluate().isEmpty) {
        await openZyraDevControls(tester);
      }
      return true;
    case 'draft_back':
      await toggleZyraDevControls(tester);
      return true;
    case 'draft_close':
      await leaveZyraDeveloperPreview(tester);
      return true;
    case 'draft_role_guardian':
    case 'draft_role_seeker':
      // Profile Switch now reviews already-confirmed local coverage first.
      // Preserve old test commands through both real taps, never a direct
      // role-state callback or a skipped coverage/admission step.
      if (find.byKey(_page).evaluate().isNotEmpty ||
          find
              .byKey(const ValueKey('concept_profile_title'))
              .evaluate()
              .isEmpty) {
        return false;
      }
      final switchButton = find.byKey(ValueKey(key));
      if (switchButton.evaluate().isEmpty) return false;
      await Scrollable.ensureVisible(
        tester.element(switchButton),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      expect(switchButton.hitTestable(), findsOneWidget);
      await tester.tap(switchButton);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('wallet_switch_scroll')),
        findsOneWidget,
      );
      final role = key == 'draft_role_guardian' ? 'guardian' : 'seeker';
      final confirm = find.byKey(ValueKey('wallet_primary_$role'));
      await Scrollable.ensureVisible(tester.element(confirm), alignment: .5);
      await tester.pumpAndSettle();
      expect(confirm.hitTestable(), findsOneWidget);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('wallet_switch_scroll')), findsNothing);
      expect(tester.takeException(), isNull);
      return true;
    default:
      return false;
  }
}
