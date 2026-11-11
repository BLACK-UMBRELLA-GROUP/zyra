// Drives the LOCK 19 Guardian card through its public gestures.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';

Finder get visibleGuardianCard => find.descendant(
  of: find.byType(ZyraOneJourneyGuardianCards),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is GestureDetector && widget.onHorizontalDragUpdate != null,
  ),
);

Future<void> swipeGuardianCard(WidgetTester tester, {bool next = true}) async {
  final card = tester.getRect(visibleGuardianCard);
  await tester.dragFrom(
    Offset(next ? card.right - 30 : card.left + 30, card.top + 25),
    Offset(card.width * (next ? -.6 : .6), 0),
  );
  await tester.pumpAndSettle();
}
