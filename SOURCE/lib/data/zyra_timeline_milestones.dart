// Shared presentation vocabulary for the existing Timeline contract. This
// allow-list does not create an event or confer access to relationship data.
import 'package:flutter/material.dart';

class ZyraTimelineMilestones {
  ZyraTimelineMilestones._();

  static const List<String> supportedTypes = [
    'liked',
    'match_created',
    'journey_started',
    'salam_exchanged',
    'compatibility_revealed',
    'guardian_linked',
    'phase_1_complete',
    'journey_paused',
    'journey_continued',
    'phase_2_complete',
    'phase_3_complete',
    'family_stage',
    'conversation_started',
    'meeting',
    'journey_ended',
    'journey_restarted',
    'nikah',
  ];

  static bool isSupported(String type) => supportedTypes.contains(type);

  // Exact existing captions, shared rather than copied by the new presenter.
  static String labelFor(String type) => switch (type) {
    'liked' => 'You liked each other',
    'match_created' => 'Match',
    'journey_started' => 'Journey began',
    'compatibility_revealed' => 'Compatibility revealed',
    'salam_exchanged' => 'Salam exchanged',
    'guardian_linked' => 'Guardians linked',
    'phase_1_complete' => 'Finished Faith & Values',
    'phase_2_complete' => 'Finished Building a Life',
    'phase_3_complete' => 'Finished Navigating Life',
    'family_stage' => 'Families introduced',
    'conversation_started' => 'Open Conversation began',
    'meeting' => 'Meeting',
    'nikah' => 'Nikah',
    'journey_ended' => 'Journey ended',
    'journey_restarted' => 'Journey began again',
    'journey_paused' => 'Journey paused',
    'journey_continued' => 'Journey continued',
    _ => type,
  };

  static bool isQuiet(String type) =>
      type == 'journey_paused' || type == 'journey_continued';

  static IconData iconFor(String type) => switch (type) {
    'liked' => Icons.handshake_outlined,
    'match_created' => Icons.check_circle_outline,
    'journey_started' => Icons.flag_outlined,
    'compatibility_revealed' => Icons.insights_outlined,
    'salam_exchanged' => Icons.waving_hand_outlined,
    'guardian_linked' => Icons.shield_outlined,
    'phase_1_complete' => Icons.menu_book_outlined,
    'phase_2_complete' => Icons.home_outlined,
    'phase_3_complete' => Icons.route_outlined,
    'family_stage' => Icons.family_restroom_outlined,
    'conversation_started' => Icons.forum_outlined,
    'meeting' => Icons.people_outline,
    'nikah' => Icons.auto_awesome_outlined,
    'journey_ended' => Icons.do_not_disturb_alt_outlined,
    'journey_restarted' => Icons.restart_alt_outlined,
    'journey_paused' => Icons.pause_circle_outline,
    'journey_continued' => Icons.play_circle_outline,
    _ => Icons.circle_outlined,
  };
}
