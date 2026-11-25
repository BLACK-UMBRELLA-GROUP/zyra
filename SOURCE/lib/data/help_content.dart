// LOCK 43 / Q224: canonical FAQ source for Founder and retained Help.
// Spec questions lead each of the six topics. Bundled content; no server reads.
import 'zyra_membership_catalog.dart';

class ZyraHelpEntry {
  final String question;
  final String answer;
  const ZyraHelpEntry(this.question, this.answer);

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    return q.isEmpty ||
        question.toLowerCase().contains(q) ||
        answer.toLowerCase().contains(q);
  }
}

class ZyraHelpCategory {
  final String title;
  final List<ZyraHelpEntry> entries;
  const ZyraHelpCategory(this.title, this.entries);
}

const zyraPastJourneySummariesQuestion = 'What are Past Journey summaries?';

const List<ZyraHelpCategory> zyraHelpCategories = [
  ZyraHelpCategory("Getting started", [
    ZyraHelpEntry(
      "How does ZYRA work?",
      "You build a profile, browse other verified Seekers and send a Journey request. If it is accepted, you walk a Journey of 8 stages together, with your Guardians beside you, until you decide together.",
    ),
    ZyraHelpEntry(
      "How do I sign in?",
      "With Sign in with Apple or Google, the same one you used to join. ZYRA has no password of its own.",
    ),
    ZyraHelpEntry(
      "Who needs a Guardian?",
      "Every Seeker chooses a Main Guardian, usually a parent or family member, who is part of every Journey. You can add more Guardians and choose what each one sees.",
    ),
    ZyraHelpEntry(
      'Is ZYRA a dating app?',
      'No — and the difference is built into how it works, not just how we '
          'describe it.\n\n'
          'Dating apps are designed to keep you browsing. The longer you stay, '
          'the better they do. ZYRA is designed for you to leave — married. '
          'That single difference explains most of what follows.\n\n'
          'You follow structured Journeys, not endless conversations. A Journey '
          'moves through stages, with questions that surface what actually '
          'matters before a wedding, rather than small talk that avoids it. '
          'Your Guardian is a real participant in that process, not a spectator. '
          'And there is no endless messaging: conversation opens once the '
          'process reaches it.\n\n'
          'You can browse thoughtfully here. You cannot browse forever.',
    ),
    ZyraHelpEntry(
      'Will people I know see my profile?',
      'Possibly — and we would rather be straight with you about it.\n\n'
          'Anyone signed in with a live profile can appear in Profiles, and that '
          'includes people you know. You can hide your profile completely at '
          'any time from Privacy settings, and blocking someone makes you both '
          'invisible to each other everywhere in ZYRA, immediately.\n\n'
          'What we do not have yet: a way to automatically hide you from your '
          'phone contacts, or to stop someone screenshotting your photos. Both '
          'matter and both are on our list. Until they exist, hiding and '
          'blocking are the tools we can honestly point you to.',
    ),
  ]),
  ZyraHelpCategory("Profiles and Journeys", [
    ZyraHelpEntry(
      "How many Journeys can I hold?",
      "Seeker Basic has 1 Journey place. Seeker One has 3. A request you accept uses a place until the Journey ends.",
    ),
    ZyraHelpEntry(
      "What happens when a Journey ends?",
      "The Journey moves to Ended Journeys with its Timeline, read only. The other person sees “Journey ended”, never a reason.",
    ),
    ZyraHelpEntry(
      "Who can see my photos?",
      "Verified members who can see your profile, and their Guardians, through the app. Someone who hasn’t verified sees them blurred.",
    ),
    ZyraHelpEntry(
      'When does my profile go live?',
      'Completing your profile does not by itself verify your identity. '
          'Follow the verification and profile-status steps shown in the app. '
          'If verification is unavailable, it has not been approved.\n\n'
          'Developer previews are not live profiles.',
    ),
    ZyraHelpEntry(
      'Can I change my date of birth?',
      'Not from inside the app. Age is one of the few things other members '
          'rely on completely, so we do not let it be edited casually. If yours '
          'was entered wrongly, contact Help & support to request a review. '
          'An account change is not made just by opening support.',
    ),
    ZyraHelpEntry(
      "How does compatibility work?",
      "Your Partner preferences answers help ZYRA find people whose values and preferences fit yours. Your private answers stay private. Compatibility Unlock on a profile shows your overall compatibility and a deeper breakdown; opening it never shows either person’s private answers.",
    ),
    ZyraHelpEntry(
      'What is Compatibility Unlock?',
      'Compatibility Unlock uses one credit on another member’s profile to '
          'reveal your overall compatibility and a deeper breakdown, with '
          'authorised Guardian information where available. It never '
          'shows either person’s private answers. Once that profile is '
          'unlocked, viewing the result again does not use another credit.\n\n'
          'Earlier overall-only results and credits remain separate; they are not '
          'converted into deeper access.\n\n'
          '${ZyraMembershipCatalog.compatibilityTerms}\n'
          '${ZyraMembershipCatalog.compatibilityPrices}\n'
          '${ZyraMembershipCatalog.compatibilityAvailability}',
    ),
    ZyraHelpEntry(
      "Why am I seeing fewer people than expected?",
      "Check your age and location filters. Seeker One also has nationality and ethnicity filters. Widening your filters may help. Profiles that are hidden, blocked or unavailable do not appear.",
    ),
    ZyraHelpEntry(
      'How do I invite someone to a Journey?',
      'In Profiles, choose Request a Journey. The button changes to Request sent. Press it again to cancel the invitation.\n\n'
          'An invitation does not open a conversation or reveal private '
          'answers. You both choose whether to begin a Journey.',
    ),
    ZyraHelpEntry(
      "How do I move to another profile?",
      "Use the right arrow to move to another profile. Moving on does not send an invitation. With Seeker One, the left arrow returns through up to ten previously viewed profiles.",
    ),
    ZyraHelpEntry(
      'Where can I find my invitations?',
      'Open My ZYRA, then Journey requests. Received and Sent keep the '
          'two directions separate; Introductions has its own tab.',
    ),
    ZyraHelpEntry(
      'How do I find someone by ZYRA Code?',
      'Open the three dots in Profiles, then Scan. Scan their code or enter '
          'it and choose Check code. Confirm the person, then choose View '
          'profile. Finding a profile does not send an invitation.',
    ),
  ]),
  ZyraHelpCategory("Guardians", [
    ZyraHelpEntry(
      "What can my Guardian see?",
      "The Journeys you allow, at the stages that allow it. Never your private answers or your Compatibility Unlock details.",
    ),
    ZyraHelpEntry(
      "What are Past Journey summaries?",
      "When you switch this on for a Guardian, they can see your Journeys that have ended: the other person’s first name and the dates, nothing else. It is off until you turn it on, for each Guardian separately. Turn it on or off any time on that Guardian’s card in the Guardian tab.",
    ),
    ZyraHelpEntry(
      "Can my match's Guardian read our conversation too?",
      "Their Main Guardian can read a Journey conversation when their Guardian membership includes Chat. An Additional Guardian can read it only while your match has allowed Chat for that Journey. Neither of you begins a Journey without choosing to start it. Private Partner preferences answers and Compatibility Unlock details stay private.",
    ),
  ]),
  ZyraHelpCategory("Membership", [
    ZyraHelpEntry(
      "What does ZYRA cost?",
      "Seeker Basic is a one-off £4.99. Seeker One is £29.99 a month after a 14-day free trial. Guardian One is £19.99 a month after a 14-day free trial. Prices are in Membership.",
    ),
    ZyraHelpEntry(
      "How do I cancel?",
      "In Profile → Membership → Cancel membership, which opens your App Store subscriptions. You keep your plan until the end of the period you paid for.",
    ),
    ZyraHelpEntry(
      'What does Basic include?',
      '${ZyraMembershipCatalog.basicTerms}\n\n'
          'Seeker Basic has 1 Journey place and up to 10 linked Guardians. '
          'One Guardian can be on Guardian Basic; the rest need Guardian One. '
          'Your existing history and Guardian links are kept. '
          'Basic is intended to be ad-supported, but live adverts are not available in this build.\n\n'
          '${ZyraMembershipCatalog.guardianBasicTerms}\n\n'
          '${ZyraMembershipCatalog.availability}',
    ),
    ZyraHelpEntry(
      'What do ${ZyraMembershipCatalog.seekerOneTitle} and ${ZyraMembershipCatalog.guardianOneTitle} include?',
      'Seeker One has 3 Journey places, unlimited profiles, every filter, '
          '10 Guardians and 3 Compatibility Unlocks a month. '
          'Guardian One includes the Journeys your Seekers allow, Journey chat '
          'when permitted, Guardian Circle, Network, Introductions and Connect with Guardian.\n\n'
          'After a previous confirmed membership payment, you can choose '
          'Basic with no new joining fee. Basic access must still be '
          'confirmed, not inferred from subscription expiry alone. '
          'Without confirmed membership, the app is locked apart from billing, '
          'resubscription, purchase restoration, data rights, safety/support, '
          'legal information and sign out.\n\n'
          'You cannot be your own Guardian. Membership never bypasses '
          'matching exclusions, Seeker permission or Main Guardian authority. '
          'A membership change does not erase relationships or history.\n\n'
          '${ZyraMembershipCatalog.guardianAccessTerms}\n\n'
          '${ZyraMembershipCatalog.compatibilityTerms} '
          '${ZyraMembershipCatalog.compatibilityAvailability}',
    ),
  ]),
  ZyraHelpCategory("Safety", [
    ZyraHelpEntry(
      "How do I report someone?",
      "Open their profile, tap ••• and choose Report. A person on the ZYRA team looks at every report within 24 hours. They are never told who reported them.",
    ),
    ZyraHelpEntry(
      "What is the difference between blocking and reporting?",
      "Blocking stops them seeing or contacting you, straight away. Reporting asks the ZYRA team to look into what they did. You can do both.",
    ),
    ZyraHelpEntry(
      'Can someone find out I blocked them?',
      'They are never told, and they cannot see that a block exists. They will '
          'only notice that your profile no longer appears.',
    ),
    ZyraHelpEntry(
      'Something feels wrong and I am not sure it counts',
      'You can report a concern in good faith without being certain that '
          'a rule was broken. Describe what happened and choose the closest '
          'reason. Keep other people’s private details out of general feedback. '
          'Check the submission result and any available case updates.',
    ),
  ]),
  ZyraHelpCategory("Your account", [
    ZyraHelpEntry(
      "How do I take a break?",
      "Pause My Profile in Settings → Privacy hides you from Profiles. Your Journeys and Guardians stay as they are.",
    ),
    ZyraHelpEntry(
      "How do I delete my account?",
      "Settings → Advanced → Delete my account. Your profile disappears straight away, and you have 30 days to change your mind by signing in again.",
    ),
  ]),
];
