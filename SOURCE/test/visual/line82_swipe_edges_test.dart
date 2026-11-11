// LOCK 26 V2: the actual preview routes paint past the card's resting box.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/widgets/zyra_swipe_track.dart';

import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE82_CAPTURE_DIR');

class _CaptureBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get disableShadows => false;
}

enum _Route {
  profiles,
  guardian,
  journey,
  filters,
  seekerMyZyra,
  guardianMyZyra,
}

Future<void> _open(BaselineHarness harness, _Route route) async {
  switch (route) {
    case _Route.profiles:
      await harness.mount();
    case _Route.guardian:
    case _Route.journey:
      await harness.mount(
        tab: route == _Route.guardian ? 3 : 1,
        model: ViewRequestDraftModel(capacity: 3)..seedJourneys(2),
      );
    case _Route.filters:
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      addTearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
      ZyraInternalPreviewClient.beginPreview();
      await harness.mount(navigatorObservers: [ZyraPreviewRouteObserver()]);
      await harness.tap('concept_browse_menu');
      await harness.tester.tapAt(
        harness.tester.getCenter(
          find.descendant(
            of: harness.key('concept_browse_options_navigation'),
            matching: harness.key('floating-nav-item-3'),
          ),
        ),
      );
      await harness.flush();
      harness.assertPage('filters');
    case _Route.seekerMyZyra:
    case _Route.guardianMyZyra:
      final guardian = route == _Route.guardianMyZyra;
      final model = ViewRequestDraftModel(capacity: 3)
        ..seedReceived('draft-amira');
      await harness.mount(
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
  }
}

void main() {
  if (_captures.isNotEmpty) _CaptureBinding();
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final (size, safePadding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.round()}x${size.height.round()}';
    for (final route in _Route.values) {
      final name = '${route.name}_$dimensions';
      testWidgets('$name full-width swipe and full shadow paint bounds', (
        tester,
      ) async {
        final harness = BaselineHarness(
          tester,
          group: name,
          logicalSize: size,
          safePadding: safePadding,
          outputRoot: _captures,
          evidenceRoot: _captures,
          flatOutput: true,
          circleArrivalsFor: (seeker, viewer) =>
              seeker == 'draft-self' && viewer == 'draft-self'
              ? [
                  ZyraFamilyMessage(
                    id: 'line82-arrival',
                    senderId: 'draft-guardian-hassan',
                    senderFirstName: 'Hassan',
                    body: 'A preview arrival.',
                    createdAt: DateTime.utc(2026, 10, 12),
                    unreadForMe: true,
                  ),
                ]
              : [],
        );
        await _open(harness, route);
        final track = find.byType(ZyraSwipeTrack);
        expect(track, findsOneWidget);
        final clip = find
            .descendant(of: track, matching: find.byType(ClipRect))
            .first;
        final nav = harness.key('compact-nav-surface');
        final navBefore = nav.evaluate().isEmpty ? null : tester.getRect(nav);
        final header = find.text(switch (route) {
          _Route.profiles => 'Profiles',
          _Route.guardian => 'Guardian',
          _Route.journey => 'Journey',
          _Route.filters => 'Filters',
          _ => 'My ZYRA',
        }).first;
        final headerBefore = tester.getRect(header);
        final card = tester.getRect(clip);
        final selected = tester.widget<ZyraSwipeTrack>(track).index;
        final inset = route == _Route.filters ? 21.0 : 20.0;
        expect(card.left, closeTo(inset, .01));
        expect(card.right, closeTo(size.width - inset, .01));
        final last = switch (route) {
          _Route.profiles || _Route.guardian => clip,
          _Route.journey => harness.key('concept_request_row_surface'),
          _Route.seekerMyZyra => harness.key('focus-notifications'),
          _Route.guardianMyZyra => harness.key('guardian_notifications'),
          _Route.filters => null,
        };
        if (last != null) {
          final scroll = Scrollable.maybeOf(tester.element(last))?.position;
          final start = scroll?.pixels;
          if (scroll != null) {
            scroll.jumpTo(scroll.maxScrollExtent);
            await tester.pump();
          }
          expect(navBefore!.top - tester.getRect(last).bottom, closeTo(16, 1));
          if (scroll != null) {
            scroll.jumpTo(start!);
            await tester.pump();
          }
        }
        if (_captures.isNotEmpty) {
          await harness.capture('swipe', name, 'rest', 'Actual preview route');
        }

        final start = route == _Route.filters
            ? Offset(card.center.dx, card.bottom - 30)
            : route == _Route.seekerMyZyra || route == _Route.guardianMyZyra
            ? headerBefore.center
            : card.center;
        final gesture = await tester.startGesture(start);
        await gesture.moveBy(const Offset(-124, 0));
        await tester.pump();

        final viewport = tester.widget<ClipRect>(clip);
        expect(viewport.clipBehavior, Clip.hardEdge);
        final paintClip = viewport.clipper!
            .getClip(card.size)
            .shift(card.topLeft);
        expect(paintClip.left, closeTo(0, .01));
        expect(paintClip.right, closeTo(size.width, .01));
        expect(paintClip.top, lessThan(0));
        expect(paintClip.bottom, greaterThan(size.height));
        expect(tester.getRect(clip), card);
        expect(tester.widget<ZyraSwipeTrack>(track).index, selected);
        expect(tester.getRect(header), headerBefore);
        if (navBefore != null) expect(tester.getRect(nav), navBefore);

        final stack = viewport.child! as Stack;
        expect(stack.children, hasLength(2));
        final current = (stack.children[0] as KeyedSubtree).child as Transform;
        final neighbour = (stack.children[1] as Positioned).child as Transform;
        Rect movingBounds(Transform slide) {
          final child = slide.child! as IgnorePointer;
          expect(child.ignoring, isTrue);
          return tester.getRect(find.byWidget(child));
        }

        final moving = movingBounds(current);
        final incoming = movingBounds(neighbour);
        expect(moving.left, lessThan(paintClip.left));
        expect(incoming.left, lessThan(paintClip.right));
        expect(incoming.left - moving.right, closeTo(24, .01));
        expect(moving.bottom, closeTo(card.bottom, .01));
        if (_captures.isNotEmpty) {
          await harness.capture(
            'swipe',
            name,
            'drag',
            'Pointer held mid-swipe',
          );
        }
        await gesture.up();
        await harness.flush();
        expect(tester.widget<ClipRect>(clip).clipBehavior, Clip.none);
        expect(tester.getRect(clip).left, closeTo(inset, .01));
        expect(tester.getRect(clip).right, closeTo(size.width - inset, .01));
      });
    }
  }
}
