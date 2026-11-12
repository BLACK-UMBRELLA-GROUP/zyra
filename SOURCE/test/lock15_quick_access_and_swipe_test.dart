// LOCK 15 V5: quick-access origin and page-owned swipe in the actual shell.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/widgets/zyra_floating_surface.dart';
import 'package:zyra/widgets/zyra_focus_dashboard.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';
import 'visual/baseline_capture_support.dart';

Finder _key(String id) => find.byKey(ValueKey(id));

Future<void> _physicalTab(WidgetTester tester, int index) async {
  await tester.tap(_key('floating-nav-item-$index'));
  await tester.pump(const Duration(milliseconds: 400));
}

BaselineHarness _h(
  WidgetTester tester, {
  bool arrival = false,
  double textScale = 1,
}) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'lock15-quick',
    textScale: textScale,
    circleArrivalsFor: !arrival
        ? null
        : (seeker, viewer) => seeker == 'draft-self' && viewer == 'draft-self'
              ? [
                  ZyraFamilyMessage(
                    id: 'lock15-arrived',
                    senderId: 'draft-guardian-hassan',
                    senderFirstName: 'Hassan',
                    body: 'A test arrival for the swipe.',
                    createdAt: DateTime.utc(2026, 10, 12),
                    unreadForMe: true,
                  ),
                ]
              : [],
  );
}

void main() {
  for (final guardian in [false, true]) {
    for (final basic in [false, true]) {
      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} ${basic ? 'Basic' : 'One'} quick tiles keep the full current tab and original access gates',
        (tester) async {
          final h = _h(tester);
          await h.mount(
            guardian: guardian,
            tab: 2,
            seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
            guardianMembership: basic ? 'Guardian Basic' : 'Guardian One',
            model: ViewRequestDraftModel(capacity: basic && !guardian ? 1 : 3),
          );
          final routes = guardian
              ? {
                  'guardian_requests': 'guardian_requests',
                  'guardian_connect': basic
                      ? 'one_upgrade'
                      : 'guardian_connect',
                  'guardian_introductions': basic
                      ? 'one_upgrade'
                      : 'guardian_introductions',
                  'guardian_notifications': 'notifications',
                }
              : {
                  'concept-my-requests': 'requests',
                  'concept-my-introductions': 'introductions',
                  'concept-my-ended': 'ended',
                  'focus-notifications': 'notifications',
                };
          for (final route in routes.entries) {
            await h.tap(route.key);
            h.assertPage(route.value);
            final nav = find.byType(ZyraShellNavigation);
            if (route.value == 'one_upgrade') {
              expect(nav, findsNothing);
              expect(find.text('Guardian One'), findsOneWidget);
              expect(find.text('Chat in a Journey'), findsOneWidget);
              await h.tapText('Not now');
            } else {
              expect(tester.widget<ZyraShellNavigation>(nav).currentIndex, 2);
              expect(tester.getSize(_key('compact-nav-surface')).height, 58);
              await _physicalTab(tester, 2);
            }
            expect(h.latest.pages, isEmpty);
            expect(h.latest.tab, 2);
          }
          await h.tap(routes.keys.first);
          await _physicalTab(tester, 0);
          expect(h.latest.pages, isEmpty);
          expect(h.latest.tab, 0);
        },
      );
    }
  }

  for (final membership in ['Guardian One', 'Guardian Basic']) {
    testWidgets('$membership Notifications opens read-only Guardian requests', (
      tester,
    ) async {
      final h = _h(tester);
      final model = ViewRequestDraftModel(capacity: 3)
        ..seedReceived('draft-amira');
      await h.mount(
        guardian: true,
        tab: 2,
        guardianMembership: membership,
        model: model,
      );

      await h.tap('guardian_requests');
      h.assertPage('guardian_requests');
      final directRequestPage = tester.widget<ZyraGuardianTabsPresentation>(
        find.byType(ZyraGuardianTabsPresentation),
      );
      expect(
        directRequestPage.receivedJourneyRequests.map((p) => p.id),
        contains('draft-amira'),
      );
      await _physicalTab(tester, 2);

      await h.tap('guardian_notifications');
      h.assertPage('notifications');
      await h.tap('concept_updates_connections');
      expect(h.latest.pages, ['notifications', 'guardian_requests']);
      final childRequestPage = tester.widget<ZyraGuardianTabsPresentation>(
        find.byType(ZyraGuardianTabsPresentation),
      );
      expect(
        childRequestPage.receivedJourneyRequests.map((p) => p.id),
        directRequestPage.receivedJourneyRequests.map((p) => p.id),
      );
      expect(_key('concept_request_draft-amira_header'), findsNothing);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Decline'), findsNothing);
      final nav = find.byType(ZyraShellNavigation);
      expect(tester.widget<ZyraShellNavigation>(nav).currentIndex, 2);

      await h.mount(guardian: true, checkpoint: h.latest);
      expect(h.latest.pages, ['notifications', 'guardian_requests']);
      expect(tester.widget<ZyraShellNavigation>(nav).currentIndex, 2);
      await returnZyraPreviewPage(tester);
      await h.flush();
      h.assertPage('notifications');
      expect(tester.widget<ZyraShellNavigation>(nav).currentIndex, 2);
      await returnZyraPreviewPage(tester);
      await h.flush();
      expect(h.latest.pages, isEmpty);

      await h.tap('guardian_notifications');
      await h.tap('concept_updates_connections');
      await _physicalTab(tester, 2);
      expect(h.latest.pages, isEmpty);
      expect(h.latest.tab, 2);
    });
  }

  testWidgets(
    'My ZYRA Preferences and Edit Profile open the same Partner preferences hub',
    (tester) async {
      final h = _h(tester);
      await h.mount(tab: 2);

      CompatibilityEditorScreen editor() =>
          tester.widget<CompatibilityEditorScreen>(
            find.byType(CompatibilityEditorScreen),
          );

      void assertPartnerPreferences() {
        Finder editorText(String text) => find.descendant(
          of: find.byType(CompatibilityEditorScreen),
          matching: find.text(text),
        );
        expect(editor().kind, CompatibilityEditorKind.trafficLights);
        expect(editorText('Partner preferences'), findsOneWidget);
        expect(editorText('Green / Yellow / Red'), findsNothing);
        expect(editorText('Marriage preferences'), findsNothing);
        expect(
          editorText('How every possible partner answer feels to you.'),
          findsOneWidget,
        );
        for (final meaning in ['Prefer', 'Open to this', 'Not for me']) {
          expect(editorText(meaning), findsOneWidget);
        }
        expect(
          _key('edit-preferences-deen_practice').hitTestable(),
          findsOneWidget,
        );
        expect(
          _key('edit-preferences-marriage_intentions').hitTestable(),
          findsOneWidget,
        );
        expect(
          find.textContaining(RegExp(r'^0 of \d+ preferences set$')),
          findsWidgets,
        );
        Rect card(String id) => tester.getRect(
          find.descendant(
            of: _key('edit-preferences-$id'),
            matching: find.byType(ZyraFloatingSurface),
          ),
        );
        final legend = tester.getRect(
          find
              .ancestor(
                of: editorText('Prefer'),
                matching: find.byType(ZyraFloatingSurface),
              )
              .first,
        );
        final first = card('deen_practice');
        final second = card('marriage_intentions');
        expect(first.top - legend.bottom, closeTo(12, .01));
        expect(second.top - first.bottom, closeTo(12, .01));
        expect(_key('compatibility-save').hitTestable(), findsOneWidget);
        expect(editorText('Save changes'), findsOneWidget);
      }

      final retainedChip = tester
          .widget<ZyraFocusDashboard>(find.byType(ZyraFocusDashboard))
          .chips
          .singleWhere((chip) => chip.id == 'focus-preferences')
          .onTap;
      final counterpartTotal = ZyraCompatibilityDraft.fromSnapshot(
        gender: 'male',
      ).preferenceOptionCount;
      expect(find.text('Preferences 0/$counterpartTotal'), findsOneWidget);
      await h.tap('focus-preferences');
      h.assertPage('filter_preferences');
      assertPartnerPreferences();
      final retainedSave = editor().onPersist;
      final initialDraft = editor().initialDraft.copy();
      await returnZyraPreviewPage(tester);
      await h.flush();
      expect(h.latest.pages, isEmpty);
      expect(h.latest.tab, 2);
      retainedChip();
      expect(await retainedSave(initialDraft), isFalse);
      await h.flush();
      expect(h.latest.pages, isEmpty);
      expect(find.text('Preferences 0/$counterpartTotal'), findsOneWidget);

      await _physicalTab(tester, 4);
      await h.tap('concept_edit_profile');
      h.assertPage('edit_profile');
      final preferenceRow = _key('compatibility-editor-trafficLights');
      expect(
        find.descendant(
          of: preferenceRow,
          matching: find.text('Partner preferences'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: preferenceRow,
          matching: find.text('0 of $counterpartTotal set'),
        ),
        findsOneWidget,
      );
      await h.tap('compatibility-editor-trafficLights');
      assertPartnerPreferences();
      expect(
        editor().initialDraft.preferenceOptionCount,
        initialDraft.preferenceOptionCount,
      );
      await returnZyraPreviewPage(tester);
      await h.flush();
      h.assertPage('edit_profile');
      expect(preferenceRow, findsOneWidget);

      await h.tap('compatibility-editor-hardRequirements');
      expect(
        find.textContaining(
          'First mark an answer Not for me in Partner preferences.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'quick access survives deep Back and an owned restore, but not entry from elsewhere',
    (tester) async {
      final h = _h(tester);
      final model = ViewRequestDraftModel(capacity: 3)
        ..seedReceived('draft-amira');
      await h.mount(tab: 2, model: model);
      await h.tap('concept-my-requests');
      h.assertPage('requests');
      final checkpoint = h.latest;
      await h.mount(checkpoint: checkpoint);
      expect(find.byType(ZyraShellNavigation), findsOneWidget);
      await h.tap('concept_request_draft-amira_header');
      await h.tap('concept_request_profile_draft-amira');
      h.assertPage('profile');
      expect(find.byType(ZyraShellNavigation), findsNothing);
      await returnZyraPreviewPage(tester);
      await h.flush();
      h.assertPage('requests');
      expect(find.byType(ZyraShellNavigation), findsOneWidget);
      await returnZyraPreviewPage(tester);
      await h.flush();
      expect(h.latest.pages, isEmpty);
      await h.mount(tab: 1, pages: ['ended'], model: model);
      h.assertPage('ended');
      expect(find.byType(ZyraShellNavigation), findsNothing);
    },
  );

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} can swipe across a tile without opening it',
      (tester) async {
        final h = _h(tester, arrival: !guardian);
        final model = ViewRequestDraftModel(capacity: 3)
          ..seedReceived('draft-amira');
        await h.mount(
          guardian: guardian,
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: guardian,
            model: model.snapshot(),
            tab: 2,
            pages: const [],
            guardianTabs: const ZyraGuardianTabsSnapshot(
              review: ZyraGuardianReview.open,
              connection: ZyraGuardianConnection.pending,
            ),
          ),
        );
        final tile = _key(
          guardian ? 'guardian_requests' : 'concept-my-requests',
        );
        final before = tester.widget<ZyraFocusDashboard>(
          find.byType(ZyraFocusDashboard),
        );
        expect(before.items.length, greaterThanOrEqualTo(2));
        final focusArea = _key('focus-area');
        final neighbour = _key('focus-item-${before.items[1].id}');
        expect(neighbour, findsNothing);
        final start = tester.getCenter(tile);
        final pointer = await tester.startGesture(start);
        for (var dx = 10.0; dx <= 150; dx += 10) {
          await pointer.moveTo(start.translate(-dx, 0));
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(
          tester.getRect(neighbour).overlaps(tester.getRect(focusArea)),
          isTrue,
        );
        expect(
          guardian
              ? h.latest.guardianTabs.focusIndex
              : h.latest.myZyraFocusIndex,
          0,
        );
        expect(h.latest.pages, isEmpty);
        await pointer.up();
        await h.flush();
        await tester.pump();
        expect(h.latest.pages, isEmpty);
        expect(
          guardian
              ? h.latest.guardianTabs.focusIndex
              : h.latest.myZyraFocusIndex,
          1,
        );
        // Neither a boundary swipe nor a drag on the bar can open the tile
        // or change Needs you selection.
        for (final target in [tile, _key('compact-nav-surface')]) {
          await tester.drag(target, const Offset(-78, 0));
          await h.flush();
          expect(h.latest.pages, isEmpty);
          expect(
            guardian
                ? h.latest.guardianTabs.focusIndex
                : h.latest.myZyraFocusIndex,
            1,
          );
        }
        // The bar retains its own tab scrubbing. Return through it before
        // checking the page's ordinary tile tap.
        if (h.latest.tab != 2) await _physicalTab(tester, 2);
        await tester.tap(tile);
        await h.flush();
        h.assertPage(guardian ? 'guardian_requests' : 'requests');
      },
    );
  }

  testWidgets('Larger Text My ZYRA still scrolls vertically', (tester) async {
    final h = _h(tester, arrival: true, textScale: 2);
    final model = ViewRequestDraftModel(capacity: 3)
      ..seedReceived('draft-amira');
    await h.mount(tab: 2, model: model);
    final area = find.byKey(const PageStorageKey('my-zyra-focus-scroll'));
    final outer = find.descendant(of: area, matching: find.byType(Scrollable));
    final position = tester.state<ScrollableState>(outer.first).position;
    expect(position.maxScrollExtent, greaterThan(0));
    await tester.dragFrom(
      tester.getTopLeft(area) + const Offset(100, 120),
      const Offset(0, -100),
    );
    await h.flush();
    expect(position.pixels, greaterThan(0));
    expect(h.latest.myZyraFocusIndex, 0);
    expect(h.latest.pages, isEmpty);
  });
}
