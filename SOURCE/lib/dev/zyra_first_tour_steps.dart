/// LOCK 36 copy and page order. Targets name existing page widgets; a missing
/// target falls back to the corresponding tab icon in the walkthrough host.
class ZyraFirstTourStep {
  const ZyraFirstTourStep({
    required this.tab,
    required this.title,
    required this.body,
    required this.targetKey,
    this.swipe = false,
    this.photo = false,
  });

  final int tab;
  final String title;
  final String body;
  final String? targetKey;
  final bool swipe;
  final bool photo;
}

const zyraSeekerTourSteps = <ZyraFirstTourStep>[
  ZyraFirstTourStep(
    tab: 0,
    title: 'This is Profiles',
    body:
        'This is where you meet people. Everyone here is verified, and you see one person at a time.',
    targetKey: null,
  ),
  ZyraFirstTourStep(
    tab: 0,
    title: 'Each card is one person',
    body: 'Swipe left or right to move to the next person.',
    targetKey: 'tour_profiles_card',
    swipe: true,
  ),
  ZyraFirstTourStep(
    tab: 0,
    title: 'See their photos',
    body: 'Tap the card to move through their photos, one after another.',
    targetKey: 'tour_profiles_card',
    photo: true,
  ),
  ZyraFirstTourStep(
    tab: 0,
    title: 'Ready to begin?',
    body:
        'When it feels right, tap here to ask for a Journey. They’ll receive your request.',
    targetKey: 'tour_profiles_request',
  ),
  ZyraFirstTourStep(
    tab: 1,
    title: 'This is Journey',
    body:
        'When someone accepts, your Journey happens here. It moves in stages, with your families beside you.',
    targetKey: null,
  ),
  ZyraFirstTourStep(
    tab: 1,
    title: 'Nothing here yet',
    body:
        'That’s normal. Your first Journey starts from a profile you like, so this takes you back to Profiles.',
    targetKey: 'journey_tab_browse',
  ),
  ZyraFirstTourStep(
    tab: 2,
    title: 'This is My ZYRA',
    body:
        'Your home page. Whenever something needs you, you’ll find it here first.',
    targetKey: null,
  ),
  ZyraFirstTourStep(
    tab: 2,
    title: 'Needs you',
    body:
        'Requests, replies and next steps show here, newest first. Swipe if there’s more than one.',
    targetKey: 'focus-area',
    swipe: true,
  ),
  ZyraFirstTourStep(
    tab: 2,
    title: 'At a glance',
    body:
        'The Journey places you’re using, your notifications and your partner preferences.',
    targetKey: 'tour_status_pills',
  ),
  ZyraFirstTourStep(
    tab: 2,
    title: 'Quick access',
    body:
        'Your Journey requests, introductions from your Guardians, ended Journeys and notifications.',
    targetKey: 'tour_quick_access',
  ),
  ZyraFirstTourStep(
    tab: 3,
    title: 'This is Guardian',
    body:
        'On ZYRA you never do this alone. Your Guardians, a parent or relative, walk every Journey with you.',
    targetKey: null,
  ),
  ZyraFirstTourStep(
    tab: 3,
    title: 'Your Guardians',
    body:
        'Each card is one Guardian. Swipe to see the next, and tap ••• for options.',
    targetKey: 'tour_guardian_name',
    swipe: true,
  ),
  ZyraFirstTourStep(
    tab: 3,
    title: 'What they can see',
    body:
        'For each Journey, choose whether this Guardian can view it and chat in it.',
    targetKey: 'tour_guardian_access',
  ),
  ZyraFirstTourStep(
    tab: 3,
    title: 'Talk and add',
    body: 'Chat with all your Guardians in one place, or tap + to add another.',
    targetKey: 'tour_guardian_actions',
  ),
  ZyraFirstTourStep(
    tab: 4,
    title: 'This is Profile',
    body: 'Everything about you: your photos, your plan and your settings.',
    targetKey: null,
  ),
  ZyraFirstTourStep(
    tab: 4,
    title: 'Your profile',
    body: 'Preview it the way others see it, or tap Edit to change it.',
    targetKey: 'concept_profile_avatar',
  ),
  ZyraFirstTourStep(
    tab: 4,
    title: 'Your membership',
    body: 'Your plan and how many Journey places you have.',
    targetKey: 'concept_membership',
  ),
  ZyraFirstTourStep(
    tab: 4,
    title: 'Settings',
    body: 'Everything else you might need lives here.',
    targetKey: 'concept_settings',
  ),
];

const zyraGuardianTourSteps = <ZyraFirstTourStep>[
  ZyraFirstTourStep(
    tab: 0,
    title: 'This is Network',
    body:
        'Families on ZYRA. Here you look for a match for the Seeker you support.',
    targetKey: null,
  ),
  ZyraFirstTourStep(
    tab: 0,
    title: 'Choose your Seeker',
    body: 'If you support more than one Seeker, switch between them here.',
    targetKey: 'tour_network_seeker',
  ),
  ZyraFirstTourStep(
    tab: 0,
    title: 'Introduce or connect',
    body:
        'Introduce someone to your Seeker, or speak with their Guardian first.',
    targetKey: 'tour_network_actions',
  ),
  ZyraFirstTourStep(
    tab: 1,
    title: 'This is Journeys',
    body: 'Every Journey your Seeker begins shows here, stage by stage.',
    targetKey: null,
  ),
  ZyraFirstTourStep(
    tab: 1,
    title: 'Open a Journey',
    body: 'See where it is and take part when it’s your turn.',
    targetKey: 'guardian_journey',
  ),
  ZyraFirstTourStep(
    tab: 2,
    title: 'This is My ZYRA',
    body:
        'Your home page. Whenever something needs you, you’ll find it here first.',
    targetKey: null,
  ),
  ZyraFirstTourStep(
    tab: 2,
    title: 'Needs you',
    body:
        'Family Review and anything else waiting for you shows here, newest first.',
    targetKey: 'focus-area',
    swipe: true,
  ),
  ZyraFirstTourStep(
    tab: 2,
    title: 'Quick access',
    body: 'Journey requests, introductions and notifications.',
    targetKey: 'tour_quick_access',
  ),
  ZyraFirstTourStep(
    tab: 3,
    title: 'This is Seekers',
    body: 'The people you support. Each one has their own card.',
    targetKey: null,
  ),
  ZyraFirstTourStep(
    tab: 3,
    title: 'Swipe through',
    body:
        'Each card shows their current Journey. Swipe to the end to invite another Seeker.',
    targetKey: 'guardian_seekers_track',
    swipe: true,
  ),
  ZyraFirstTourStep(
    tab: 3,
    title: 'Talk and invite',
    body: 'Chat in the Guardian Circle, or tap + to invite a Seeker.',
    targetKey: 'tour_seekers_actions',
  ),
  ZyraFirstTourStep(
    tab: 4,
    title: 'This is Profile',
    body: 'Your details, your plan and your settings.',
    targetKey: null,
  ),
  ZyraFirstTourStep(
    tab: 4,
    title: 'Your membership',
    body: 'Your plan and what it lets you do.',
    targetKey: 'concept_membership',
  ),
  ZyraFirstTourStep(
    tab: 4,
    title: 'Settings',
    body: 'Everything else you might need lives here.',
    targetKey: 'concept_settings',
  ),
];
