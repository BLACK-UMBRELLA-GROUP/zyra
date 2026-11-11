import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_invitation_outline.dart';

/// Lets finite label, card and route transitions finish while the visible
/// sent glow continues to repeat. The glow itself has separate timing tests.
Future<void> pumpInvitationFeedback(WidgetTester tester) async {
  await tester.pump();
  final sent = find.byWidgetPredicate(
    (widget) => widget is ZyraInvitationOutline && widget.sent,
  );
  final glow = find.descendant(
    of: sent,
    matching: find.byKey(const ValueKey('invitation-inner-glow')),
  );
  if (glow.evaluate().isEmpty) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(seconds: 1));
  }
}
