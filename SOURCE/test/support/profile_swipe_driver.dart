import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_invitation_feedback.dart';

Future<bool> swipeProfileForControlKey(WidgetTester tester, String key) async {
  final dx = switch (key) {
    'concept_next_profile' => -160.0,
    'concept_previous_profile' => 160.0,
    _ => null,
  };
  if (dx == null) return false;
  final track = find.byKey(const ValueKey('concept_profile_swipe_track'));
  if (track.evaluate().isEmpty) return false;
  await tester.drag(track, Offset(dx, 0));
  await pumpInvitationFeedback(tester);
  return true;
}
