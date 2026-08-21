import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/data/zyra_journey_scroll.dart';

void main() {
  group('Journey section settling', () {
    const page = 600.0;

    test('a slight movement settles back to the current section', () {
      expect(
        ZyraJourneyScroll.nearestBoundary(
          offset: 42,
          pageExtent: page,
          headerPageCount: 1,
        ),
        0,
      );
      expect(
        ZyraJourneyScroll.nearestBoundary(
          offset: 650,
          pageExtent: page,
          headerPageCount: 2,
        ),
        page,
      );
    });

    test('a deliberate movement settles onto the next section', () {
      expect(
        ZyraJourneyScroll.nearestBoundary(
          offset: 340,
          pageExtent: page,
          headerPageCount: 1,
        ),
        page,
      );
      expect(
        ZyraJourneyScroll.nearestBoundary(
          offset: 950,
          pageExtent: page,
          headerPageCount: 2,
        ),
        page * 2,
      );
    });

    test('overscroll is clamped to the first and last resting points', () {
      expect(
        ZyraJourneyScroll.nearestBoundary(
          offset: -80,
          pageExtent: page,
          headerPageCount: 2,
        ),
        0,
      );
      expect(
        ZyraJourneyScroll.nearestBoundary(
          offset: 1800,
          pageExtent: page,
          headerPageCount: 2,
        ),
        page * 2,
      );
    });

    test('a deliberate short drag moves exactly one chapter', () {
      expect(
        ZyraJourneyScroll.boundaryAfterDrag(
          offset: 85,
          dragStartOffset: 0,
          pageExtent: page,
          headerPageCount: 2,
        ),
        page,
      );
      expect(
        ZyraJourneyScroll.boundaryAfterDrag(
          offset: 1120,
          dragStartOffset: 1200,
          pageExtent: page,
          headerPageCount: 2,
        ),
        page,
      );
    });

    test('a tiny drag returns to the nearest chapter', () {
      expect(
        ZyraJourneyScroll.boundaryAfterDrag(
          offset: 18,
          dragStartOffset: 0,
          pageExtent: page,
          headerPageCount: 2,
        ),
        0,
      );
      expect(
        ZyraJourneyScroll.boundaryAfterDrag(
          offset: 618,
          dragStartOffset: page,
          pageExtent: page,
          headerPageCount: 2,
        ),
        page,
      );
    });

    test('one drag cannot skip multiple chapters', () {
      expect(
        ZyraJourneyScroll.boundaryAfterDrag(
          offset: 1500,
          dragStartOffset: 0,
          pageExtent: page,
          headerPageCount: 3,
        ),
        page,
      );
    });

    test('completion intent accepts touch and wheel or trackpad input', () {
      final touch = ZyraJourneyScroll.completionDistanceAfterInput(
        currentDistance: 0,
        // An upward finger movement arrives at the caller as -delta.dy.
        forwardDelta: 12,
      );
      expect(touch, 12);
      expect(
        ZyraJourneyScroll.completionDistanceAfterInput(
          currentDistance: touch,
          // A forward wheel/trackpad scroll uses positive scrollDelta.dy.
          forwardDelta: 14,
        ),
        22,
      );
    });

    test('reverse completion movement cannot build forward intent', () {
      expect(
        ZyraJourneyScroll.completionDistanceAfterInput(
          currentDistance: 8,
          forwardDelta: -20,
        ),
        0,
      );
    });

    test('a missed forward swipe from Stage 2 returns to Stage 3', () {
      expect(
        ZyraJourneyScroll.missedHistoryForwardTarget(
          startPage: 1,
          currentPage: 1.08,
          arrivalPage: 2,
          forwardDistance: 36,
        ),
        2,
      );
    });

    test('history recovery applies once and never skips a stage', () {
      expect(
        ZyraJourneyScroll.missedHistoryForwardTarget(
          startPage: 0,
          currentPage: 0,
          arrivalPage: 5,
          forwardDistance: 50,
        ),
        1,
      );
      expect(
        ZyraJourneyScroll.missedHistoryForwardTarget(
          startPage: 1,
          currentPage: 2,
          arrivalPage: 5,
          forwardDistance: 50,
        ),
        isNull,
      );
    });

    test('small, reverse and non-history gestures never force a move', () {
      expect(
        ZyraJourneyScroll.missedHistoryForwardTarget(
          startPage: 1,
          currentPage: 1,
          arrivalPage: 2,
          forwardDistance: 20,
        ),
        isNull,
      );
      expect(
        ZyraJourneyScroll.missedHistoryForwardTarget(
          startPage: 2,
          currentPage: 2,
          arrivalPage: 2,
          forwardDistance: 50,
        ),
        isNull,
      );
    });

    test(
      'arrival, action and decision pages have fixed adjacent addresses',
      () {
        expect(ZyraJourneyScroll.arrivalPage(0), 0);
        expect(ZyraJourneyScroll.actionPage(0), 1);
        expect(ZyraJourneyScroll.decisionPage(0), 2);

        expect(ZyraJourneyScroll.arrivalPage(3), 3);
        expect(ZyraJourneyScroll.actionPage(3), 4);
        expect(ZyraJourneyScroll.decisionPage(3), 5);
        expect(
          ZyraJourneyScroll.isActionPage(page: 4, completedStageCount: 3),
          isTrue,
        );
        expect(
          ZyraJourneyScroll.isActionPage(page: 3, completedStageCount: 3),
          isFalse,
        );
      },
    );

    test('the ribbon follows history and returns to the current stage', () {
      expect(
        ZyraJourneyScroll.viewedStageIndex(page: 3, completedStageCount: 4),
        3,
      );
      expect(
        ZyraJourneyScroll.viewedStageIndex(page: 4, completedStageCount: 4),
        4,
      );
      expect(
        ZyraJourneyScroll.viewedStageIndex(page: 6, completedStageCount: 4),
        4,
      );
    });
  });

  group('Compatibility reveal animation', () {
    test(
      'preloading a ready result off-screen does not consume the moment',
      () {
        expect(
          ZyraCompatibilityRevealPolicy.shouldAnimate(
            isActionVisible: false,
            mineRevealed: true,
            theirsRevealed: true,
            hasScore: true,
            alreadyCelebrated: false,
          ),
          isFalse,
        );
      },
    );

    test('a ready result animates when its action page becomes visible', () {
      expect(
        ZyraCompatibilityRevealPolicy.shouldAnimate(
          isActionVisible: true,
          mineRevealed: true,
          theirsRevealed: true,
          hasScore: true,
          alreadyCelebrated: false,
        ),
        isTrue,
      );
    });

    test('an incomplete or already celebrated result never replays', () {
      expect(
        ZyraCompatibilityRevealPolicy.shouldAnimate(
          isActionVisible: true,
          mineRevealed: true,
          theirsRevealed: false,
          hasScore: true,
          alreadyCelebrated: false,
        ),
        isFalse,
      );
      expect(
        ZyraCompatibilityRevealPolicy.shouldAnimate(
          isActionVisible: true,
          mineRevealed: true,
          theirsRevealed: true,
          hasScore: true,
          alreadyCelebrated: true,
        ),
        isFalse,
      );
    });
  });

  group('Salam Gold Wake connection', () {
    test('motion follows the one outstanding side', () {
      expect(
        ZyraSalamConnectionPolicy.resolve(mine: true, theirs: false),
        ZyraSalamConnectionMotion.outbound,
      );
      expect(
        ZyraSalamConnectionPolicy.resolve(mine: false, theirs: true),
        ZyraSalamConnectionMotion.inbound,
      );
    });

    test('the completed exchange settles and stops travelling', () {
      expect(
        ZyraSalamConnectionPolicy.resolve(mine: true, theirs: true),
        ZyraSalamConnectionMotion.settled,
      );
      expect(
        ZyraSalamConnectionPolicy.resolve(mine: false, theirs: false),
        ZyraSalamConnectionMotion.idle,
      );
    });
  });
}
