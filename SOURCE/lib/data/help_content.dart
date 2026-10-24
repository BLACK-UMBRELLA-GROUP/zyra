// Help centre content.
//
// V2 — 2026-08-01, after an independent review by Fable and a second pass
// by ChatGPT. Six answers in V1 described things that do not exist; three
// of those were mine transposing Muzz's behaviour into ZYRA's help centre
// while the teardown was fresh. All corrected below and marked.
//
// DATA, NOT SCREENS. Support content is wrong constantly. If the copy is
// compiled into widgets, every correction needs an App Store review.
// NEXT STEP: move this list into a Supabase `help_articles` table
// (category, question, answer, sort_order) — the shape already maps 1:1,
// so it is a migration with no screen changes. Deep links per answer
// should be added to the schema at that point, not before.
//
// THE RULE THIS FILE BROKE ONCE AND MUST NOT AGAIN:
// never describe an unbuilt system in the present tense. A help centre
// that lies is worse than one that is missing — a user reading "your
// identity has been verified" believes a check happened. Before adding
// any answer, confirm the behaviour exists in code. Every claim below was
// verified against the source, the migrations, or the pricing document on
// 2026-08-01.
//
// TONE: APP/UX Writing/Summary.md — warm, respectful, calm, never
// "generic software". Fable's review found the voice here to be the
// strongest in the app; the corrections below preserve it rather than
// retreating into legal register.

import 'zyra_membership_catalog.dart';

class ZyraHelpEntry {
  final String question;
  final String answer;
  const ZyraHelpEntry(this.question, this.answer);

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return question.toLowerCase().contains(q) ||
        answer.toLowerCase().contains(q);
  }
}

class ZyraHelpCategory {
  final String title;
  final List<ZyraHelpEntry> entries;
  const ZyraHelpCategory(this.title, this.entries);
}

const List<ZyraHelpCategory> zyraHelpCategories = [
  // LEADS THE FILE, 2026-08-01. Fable's single best finding: for an
  // audience the product docs describe as "cautious about marriage apps
  // existing at all", this is the objection that decides whether someone
  // stays — and V1 never addressed it. ChatGPT's steer that the answer
  // must explain WHY rather than just say "no" is followed.
  ZyraHelpCategory('About ZYRA', [
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
      'How does ZYRA work?',
      'You browse, and when two people are both open to each other, that '
          'becomes a Potential Journey, within your membership allowance. '
          'When you choose to begin with one person, it becomes your '
          'Active Journey — a structured process with stages, guided questions '
          'and your family involved.\n\n'
          'Each Journey progresses deliberately, with both people choosing '
          'whether to continue.',
    ),
    // ADDED 2026-08-01 (Fable): the biggest real-world anxiety in this
    // market. Answered honestly, including the parts ZYRA has not built —
    // the teardown lists contact-blocking, a discreet icon and screenshot
    // protection as gaps, and pretending otherwise here would be the same
    // failure this file just corrected.
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
  ZyraHelpCategory('Getting started', [
    ZyraHelpEntry(
      'How do I sign in?',
      'With Apple or Google. There is no password to create or forget, and we '
          'never see one.',
    ),
    // ADDED 2026-08-01 (Fable): the Guardian category explained linking one
    // but never who is expected to have one — a male Seeker had no way to
    // tell whether any of it applied to him.
    ZyraHelpEntry(
      'Who needs a Guardian?',
      'Seekers can use the Guardian section to involve their family in '
          'their marriage Journey. The Main Guardian leads the responsibilities '
          'assigned to that role; Additional Guardians have the access you '
          'permit.\n\n'
          'The app shows which Guardian steps are needed for your Journey. '
          'Paying for membership never grants relationship authority.',
    ),
    // ADDED 2026-08-01 (Fable): "a guaranteed support email". Prices taken
    // from BUSINESS/ZYRA PRICING/Summary.md, not invented. Launch
    // promotions deliberately not listed — they change, and this file
    // cannot be corrected without a release until it moves to Supabase.
    ZyraHelpEntry(
      'What does ZYRA cost?',
      '${ZyraMembershipCatalog.basicTerms}\n\nSeeker One is '
          '£29.99 a month and Guardian One is £19.99 a month in the UK. '
          'Country-specific launch prices use local purchasing power and the '
          'store price shown before confirmation is authoritative.\n\n'
          '${ZyraMembershipCatalog.familyTerms}\n'
          '${ZyraMembershipCatalog.familyAvailability}\n\n'
          '${ZyraMembershipCatalog.guardianBasicTerms}\n\n'
          '${ZyraMembershipCatalog.guardianAccessTerms}\n\n'
          '${ZyraMembershipCatalog.compatibilityTerms}\n'
          '${ZyraMembershipCatalog.compatibilityPrices}\n'
          '${ZyraMembershipCatalog.compatibilityAvailability}\n\n'
          'Seeker One has one planned 14-day trial per verified person for '
          'life, starting only after verification and payment authorisation. '
          'Guardian One and ZYRA Family do not have a trial. '
          'Payments and paid access activation are not available in this '
          'build; no trial starts just by opening a page.\n\n'
          'After a confirmed previous membership payment, moving from One '
          'to Basic does not require another joining fee. Compatibility '
          'Unlock purchases and unpaid trials do not waive that fee. '
          'Payment history and Basic access still need to be confirmed; '
          'choosing a plan or reaching subscription expiry alone is not '
          'payment proof. Without confirmed membership access, product '
          'features lock. Resubscription, '
          'billing, purchase restoration, data rights, safety/support, legal '
          'information and sign out remain available.',
    ),
  ]),
  ZyraHelpCategory('Your profile', [
    // CORRECTED 2026-08-01. V1 said photos "passed review" and identity
    // "has been verified". Neither exists — both are mocked delays in
    // profile_ready_screen.dart. This is the answer that most clearly
    // broke this file's own rule.
    ZyraHelpEntry(
      'When does my profile go live?',
      'Completing your profile does not by itself verify your identity. '
          'Follow the verification and profile-status steps shown in the app. '
          'If verification is unavailable, it has not been approved.\n\n'
          'Developer previews are not live profiles.',
    ),
    // SOFTENED 2026-08-01. The app enforces this; the database does not
    // yet (audit finding C4 is open). V1 promised a guarantee that only
    // half exists. Restore the firmer wording once C4 lands.
    ZyraHelpEntry(
      'Can I change my date of birth?',
      'Not from inside the app. Age is one of the few things other members '
          'rely on completely, so we do not let it be edited casually. If yours '
          'was entered wrongly, contact Help & support to request a review. '
          'An account change is not made just by opening support.',
    ),
    ZyraHelpEntry(
      'Who can see my photos?',
      'Only signed-in members whose own profile is live — and never anyone you '
          'have blocked, which is enforced by the platform rather than by the '
          'app politely not asking.\n\n'
          'Your photos are stored privately and served through links that '
          'expire. They are not sitting on a public address anyone could pass '
          'around.',
    ),
  ]),
  ZyraHelpCategory('Matching and Journeys', [
    ZyraHelpEntry(
      'How does compatibility work?',
      'From the values questions you answered during onboarding. You told us '
          'what matters to you and where you are flexible, and ZYRA quietly '
          'orders the people you see by how well that lines up. Anyone who '
          'fails a Hard Requirement — something you marked as non-negotiable — '
          'is not shown to you at all.\n\n'
          'You will not see a compatibility percentage while browsing. A number '
          'invites you to shop rather than consider. It appears once a Journey '
          'begins and you both choose to reveal it.',
    ),
    ZyraHelpEntry(
      'What is Compatibility Unlock?',
      'Compatibility Unlock uses one credit on another member’s profile to '
          'reveal your overall compatibility and a deeper breakdown, with '
          'authorised Guardian information where available. It never '
          'shows either person’s private answers. Once that profile is '
          'unlocked, viewing the result again does not use another credit.\n\n'
          'The full reveal is not available in this build, so a new '
          'Compatibility Unlock credit cannot currently be spent. Earlier '
          'overall-only results and credits remain separate; they are not '
          'converted into deeper access.\n\n'
          '${ZyraMembershipCatalog.compatibilityTerms}\n'
          '${ZyraMembershipCatalog.compatibilityPrices}\n'
          '${ZyraMembershipCatalog.compatibilityAvailability}',
    ),
    ZyraHelpEntry(
      'What is the difference between Consider, Save and Pass?',
      'Consider means you are open to a Journey — if they consider you back, '
          'you match. Save is private: it keeps someone in mind without telling '
          'them anything. Pass simply moves on, and is never recorded or shown '
          'to them.',
    ),
    ZyraHelpEntry(
      'Will someone know if I passed on them?',
      'No. Passing leaves no record and sends no notification. Nobody is ever '
          'told they were declined.',
    ),
    ZyraHelpEntry(
      'How many Journeys can I hold?',
      'Seeker Basic supports one Active Journey, ten Potential Journeys '
          'and one Paused Journey. Seeker One supports up to three Active '
          'Journeys, Unlimited Potential Journeys and ten Paused Journeys. '
          'Potential Journeys do not use an Active slot.\n\n'
          'The limits help you give each person meaningful attention. Pausing '
          'or continuing still follows the shared Journey rules; membership '
          'never skips the other person’s agreement.',
    ),
    // ADDED 2026-08-01 (Founder decision on Guardian conversation
    // visibility). Two entries, because the V2 rewrite of this file
    // dropped the old "What does my Guardian actually see?" answer entirely
    // — so there was no gap to correct, there was simply nothing.
    //
    // The old answer had said "They do not read your private
    // conversations." That was false. messages_select's RLS grants an
    // active linked Wali full read access the moment a Journey leaves
    // 'potential'. Three sources disagreed — the WALI_ARCHITECTURE
    // permissions table said the Wali CAN read messages, the app's Guardian
    // onboarding said they cannot, and the database sided with the table.
    //
    // Founder decision: the access is deliberate and stays. So it is now
    // stated plainly, everywhere, and framed as the design choice it is.
    ZyraHelpEntry(
      'What can my Guardian see?',
      'Your Main Guardian is included in your active Journeys, and you cannot '
          'switch off their View or plan-enabled Chat access while they remain '
          'Main. For each Additional Guardian, you choose View and Chat '
          'separately for that specific Journey. Chat requires View, and you '
          'can withdraw either permission.\n\n'
          'A Guardian with View access can see Journey progress and the '
          'family-stage questions you both answer. They can read the '
          'conversation between you and your match only when Chat access is '
          'also on and their Guardian membership includes Chat.\n\n'
          'That last part is deliberate, and we tell you before you begin. '
          'ZYRA is built for a marriage process with family present, not for '
          'private one-to-one messaging. If you want conversations nobody else '
          'can see, ZYRA is honestly not the right app for you.\n\n'
          'What your Guardian can never see: your values answers, your '
          'compatibility settings, or who you browse, save or pass on. Those '
          'stay yours.',
    ),
    // The question the OTHER Seeker will ask, which nobody had answered.
    // The policy grants access to a Guardian linked to EITHER party — so a
    // man's messages are read by his match's Guardian, someone he has no
    // relationship with and may not have known existed. Saying only "your
    // Guardian" anywhere would be a second, subtler untruth.
    ZyraHelpEntry(
      'Can my match\'s Guardian read our conversation too?',
      'Their Main Guardian can read an active Journey conversation when their '
          'Guardian membership includes Chat. An Additional Guardian can read '
          'it only while your match has separately allowed Chat for that '
          'Journey.\n\n'
          'Neither of you can be brought into a Journey without choosing to '
          'start it. '
          'Nothing is shared while a Journey is still Potential, so if this is '
          'not what you want, simply do not begin.',
    ),
    // ADDED 2026-08-01 (Fable): the cooling period is genuinely built
    // (_EndedView, 24h) and was completely undocumented.
    ZyraHelpEntry(
      'What happens when a Journey ends?',
      'Ending a Journey is deliberate and final — it is not a pause. '
          'Your shared Timeline is kept as the record of that attempt. '
          'Ending it does not automatically begin another Journey.\n\n'
          'Restarting an ended Journey is not available in this build. '
          'Membership does not reopen an ended attempt or bypass either '
          'person’s choice.',
    ),
    // CORRECTED 2026-08-01. V1 named "age, location, sect and ethnicity"
    // as filters. Only age exists (browse_screen's _minAge/_maxAge). Three
    // of the four were Muzz's filter list, written in here from memory
    // while the teardown was fresh. In an answer whose whole job was to
    // PREVENT support emails.
    ZyraHelpEntry(
      'Why am I seeing fewer people than expected?',
      'Most often your age filter, which is the one you can set today — '
          'widening it usually helps. More filters are on the way.\n\n'
          'ZYRA also only ever shows you people whose profile is live, who you '
          'have not already decided on, and who you have not blocked.',
    ),
  ]),
  ZyraHelpCategory('Safety and reporting', [
    // REWRITTEN 2026-08-01. V1 said reports are sent "to our team to
    // review". There is no queue, no triage, and status never leaves
    // 'pending' — a documented open critical.
    //
    // ChatGPT proposed "Reports are reviewed by ZYRA... as our moderation
    // systems evolve". Opus declined that wording: it still states that
    // review happens. A woman reporting harassment would read it and
    // believe a person will look. Nobody will. This version keeps every
    // true part (the block is instant, the report is kept), avoids
    // exposing internals, and adds an escalation route that genuinely
    // reaches a human — which makes it safer than the confident version,
    // not just more honest. Founder to confirm the wording.
    ZyraHelpEntry(
      'How do I report someone?',
      'Press and hold the middle of their photo in Profiles, then choose Report '
          'this profile. Pick a reason and send.\n\n'
          'They are never told, and you stop seeing each other straight away — '
          'that part is immediate. The report itself is recorded and kept.\n\n'
          'Check the submission result rather than assuming it was sent. '
          'You can view available case updates from Help & support. '
          'A recorded report does not mean someone has reviewed it. '
          'Reports and support email are not emergency services; if you are '
          'in immediate danger, contact your local emergency services.',
    ),
    ZyraHelpEntry(
      'What is the difference between blocking and reporting?',
      'Blocking is instant and private: you and that person disappear from '
          'each other, and nothing is filed. Reporting also hides them, and '
          'keeps a record.\n\n'
          'If you simply do not want to see someone, blocking is enough. You do '
          'not need to accuse anyone of anything.',
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
  ZyraHelpCategory('Account and plan', [
    ZyraHelpEntry(
      'What does Basic include?',
      '${ZyraMembershipCatalog.basicTerms}\n\n'
          'Seeker Basic includes one Active Journey, ten Potential Journeys, '
          'one Paused Journey, five Saved profiles, 25 active Considers, '
          'five Considers per day, 25 profile swipes per four-hour window '
          'and one linked Guardian. Insights and initiating Paused or Ended '
          'Journey returns are not included. Your existing history and '
          'Guardian links are kept. Basic is intended to be ad-supported, '
          'but live adverts are not available in this build.\n\n'
          '${ZyraMembershipCatalog.guardianBasicTerms}\n\n'
          '${ZyraMembershipCatalog.availability}',
    ),
    ZyraHelpEntry(
      'What do ${ZyraMembershipCatalog.seekerOneTitle} and ${ZyraMembershipCatalog.guardianOneTitle} include?',
      'Seeker One includes paid Seeker access, 3 Active Journeys, Unlimited Potential '
          'Journeys, 10 Paused Journeys, 50 Saved profiles, Unlimited active '
          'and daily Considers, and up to 10 linked Guardians including Main. '
          'Initiate returns from the five most recent Paused and five most '
          'recent Ended Journeys, and revisit 10 declined profiles. '
          'My ZYRA Insights is coming soon. '
          'Guardian One provides paid Guardian access. Main Guardians have '
          'View and Chat across Active Journeys; Additional Guardians begin '
          'with both enabled per Journey and the Seeker may change them.\n\n'
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
    // MERGED 2026-08-01 (Fable): "How do I take a break?" and "How do I
    // hide my profile?" were the same answer twice — both said Privacy
    // settings, step out of Browse, everything kept.
    ZyraHelpEntry(
      'How do I take a break or hide my profile?',
      'Privacy settings let you step out of Profiles while keeping everything — '
          'your Journeys, matches and messages stay exactly as they are, and '
          'come back with you.\n\n'
          'There is no penalty for taking as long as you need. If you want '
          'longer away, pausing is always better than deleting.',
    ),
    // CORRECTED 2026-08-01. V1 said "Settings > Manage account" — that is
    // Muzz's navigation, not ZYRA's. Deletion lives at the bottom of the
    // Profile tab (profile_screen.dart), and on the Wali profile for Wali
    // accounts. Wrong path, in the one answer where a frustrated user is
    // least willing to hunt.
    ZyraHelpEntry(
      'How do I delete my account?',
      'Open Profile › Settings › Account › Advanced › Delete account. '
          'Read the confirmation and check the result. Records subject to '
          'a safety or legal retention requirement are separate.\n\n'
          'If you are unsure, hide your profile instead and come back when you '
          'are ready.',
    ),
  ]),
];
