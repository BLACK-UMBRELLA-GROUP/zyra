// Drives the LOCK 19 Guardian card through its public gestures.
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/widgets/zyra_swipe_track.dart';

Finder get visibleGuardianCard => find.descendant(
  of: find.byType(ZyraOneJourneyGuardianCards),
  matching: find.byType(ZyraSwipeTrack),
);

Future<void> swipeGuardianCard(WidgetTester tester, {bool next = true}) async {
  final card = tester.getRect(visibleGuardianCard);
  await tester.dragFrom(
    Offset(next ? card.right - 30 : card.left + 30, card.top + 25),
    Offset(card.width * (next ? -.6 : .6), 0),
  );
  await tester.pumpAndSettle();
}
