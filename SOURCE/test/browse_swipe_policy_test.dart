import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/browse/browse_swipe_policy.dart';

void main() {
  group('Browse physical swipe policy', () {
    test('physical swipe right is Pass and grows red from the left edge', () {
      const drag = Offset(121, 0);

      expect(
        ZyraBrowseSwipePolicy.previewDecision(drag),
        ZyraBrowseSwipeDecision.pass,
      );
      expect(
        ZyraBrowseSwipePolicy.committedDecision(drag),
        ZyraBrowseSwipeDecision.pass,
      );
      expect(
        ZyraBrowseSwipePolicy.cueEdge(ZyraBrowseSwipeDecision.pass),
        ZyraBrowseSwipeCueEdge.left,
      );
      expect(
        ZyraBrowseSwipePolicy.flingTarget(ZyraBrowseSwipeDecision.pass).dx,
        isPositive,
      );
    });

    test(
      'physical swipe left is Consider and grows green from the right edge',
      () {
        const drag = Offset(-121, 0);

        expect(
          ZyraBrowseSwipePolicy.previewDecision(drag),
          ZyraBrowseSwipeDecision.consider,
        );
        expect(
          ZyraBrowseSwipePolicy.committedDecision(drag),
          ZyraBrowseSwipeDecision.consider,
        );
        expect(
          ZyraBrowseSwipePolicy.cueEdge(ZyraBrowseSwipeDecision.consider),
          ZyraBrowseSwipeCueEdge.right,
        );
        expect(
          ZyraBrowseSwipePolicy.flingTarget(
            ZyraBrowseSwipeDecision.consider,
          ).dx,
          isNegative,
        );
      },
    );

    test('down is Save and reveals the cue from the top edge', () {
      const drag = Offset(0, 121);

      expect(
        ZyraBrowseSwipePolicy.previewDecision(drag),
        ZyraBrowseSwipeDecision.save,
      );
      expect(
        ZyraBrowseSwipePolicy.committedDecision(drag),
        ZyraBrowseSwipeDecision.save,
      );
      expect(
        ZyraBrowseSwipePolicy.cueEdge(ZyraBrowseSwipeDecision.save),
        ZyraBrowseSwipeCueEdge.top,
      );
      expect(
        ZyraBrowseSwipePolicy.flingTarget(ZyraBrowseSwipeDecision.save).dy,
        isPositive,
      );
    });

    test('threshold and dominant axis prevent accidental decisions', () {
      expect(
        ZyraBrowseSwipePolicy.previewDecision(const Offset(20, 0)),
        isNull,
      );
      expect(
        ZyraBrowseSwipePolicy.committedDecision(const Offset(120, 0)),
        isNull,
      );
      expect(
        ZyraBrowseSwipePolicy.committedDecision(const Offset(140, -150)),
        isNull,
      );
      expect(
        ZyraBrowseSwipePolicy.committedDecision(const Offset(130, 121)),
        ZyraBrowseSwipeDecision.pass,
      );
      expect(
        ZyraBrowseSwipePolicy.committedDecision(const Offset(-130, 121)),
        ZyraBrowseSwipeDecision.consider,
      );
    });

    test('a horizontal drag cannot turn into Save while returning', () {
      const outward = Offset(64, 3);
      final lockedAxis = ZyraBrowseSwipePolicy.previewAxis(outward);

      expect(lockedAxis, ZyraBrowseSwipeAxis.horizontal);
      expect(
        ZyraBrowseSwipePolicy.previewDecision(outward, lockedAxis: lockedAxis),
        ZyraBrowseSwipeDecision.pass,
      );

      // The finger has returned almost to its starting x-position with some
      // natural downward drift. The cue should clear, not flash Save/orange.
      const returnedWithDrift = Offset(4, 42);
      expect(
        ZyraBrowseSwipePolicy.previewDecision(
          returnedWithDrift,
          lockedAxis: lockedAxis,
        ),
        isNull,
      );
      expect(
        ZyraBrowseSwipePolicy.committedDecision(
          const Offset(4, 130),
          lockedAxis: lockedAxis,
        ),
        isNull,
      );
    });

    test('Full aura and ten 3D treatments share the corrected policy', () {
      final source = File(
        'lib/screens/browse/browse_screen.dart',
      ).readAsStringSync();
      final feedbackStart = source.indexOf('class _SwipeFeedbackLayer');
      final feedbackEnd = source.indexOf('class _BorderFlash', feedbackStart);
      final feedback = source.substring(feedbackStart, feedbackEnd);

      for (final style in [
        'fullAura',
        'layeredParallax',
        'edgePeek',
        'floatingDeck',
        'carousel3d',
        'doorHinge',
        'pageCurl',
        'depthTunnel',
        'subjectSplit',
        'magneticTilt',
        'horizonLift',
      ]) {
        expect(
          feedback,
          contains('ZyraBrowseSwipeFeedbackStyle.$style'),
          reason: '$style must remain wired into the shared feedback layer',
        );
      }
      expect(feedback, contains('ZyraBrowseSwipePolicy.cueEdge'));
      expect(source, contains('ZyraBrowseSwipePolicy.previewDecision'));
      expect(source, contains('ZyraBrowseSwipePolicy.committedDecision'));
      expect(source, contains('ZyraBrowseSwipePolicy.flingTarget'));
    });
  });
}
