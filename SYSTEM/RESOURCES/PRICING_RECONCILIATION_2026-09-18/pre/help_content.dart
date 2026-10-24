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
          'becomes a Potential Journey. You may hold as many of those as you '
          'like. When you choose to begin with one person, it becomes your '
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
          'Anyone signed in with a live profile can appear in Browse, and that '
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
      'A Guardian is the family member who takes part in a woman\'s Journey — usually '
          'her father, and otherwise a grandfather, brother or paternal uncle.\n\n'
          'If you are a female Seeker, you will link a Guardian before a Journey '
          'can progress past its early stages. If you are a male Seeker, you do '
          'not need one, and the Guardian sections of the app will not apply to '
          'you — you will meet your match\'s Guardian during the Family Stage.',
    ),
    // ADDED 2026-08-01 (Fable): "a guaranteed support email". Prices taken
    // from BUSINESS/ZYRA PRICING/Summary.md, not invented. Launch
    // promotions deliberately not listed — they change, and this file
    // cannot be corrected without a release until it moves to Supabase.
    ZyraHelpEntry(
      'What does ZYRA cost?',
      'ZYRA One — Seeker is £29.99 a month. Seeker Basic has a £9.99 '
          'one-time joining fee and includes one Active Journey, up to 50 '
          'active Considers, 10 Saves, 5 Considers per day and 25 profile '
          'swipes every 4 hours. It includes adverts after every 5 swipes '
          'and does not include Insights. ZYRA One — Guardian is £19.99 a '
          'month. Guardian Basic has a £9.99 one-time joining fee and can '
          'view a linked Seeker’s Journey '
          'but cannot comment, enter Journey conversations or use Guardian '
          'Network. ZYRA Family is unchanged.\n\n'
          '${ZyraMembershipCatalog.guardianAccessTerms}\n\n'
          '${ZyraMembershipCatalog.compatibilityTerms}\n'
          '${ZyraMembershipCatalog.compatibilityPrices}\n'
          '${ZyraMembershipCatalog.compatibilityAvailability}\n\n'
          'The planned ZYRA One — Seeker membership starts with a 14-day '
          'trial after verification. Basic one-time fees do not start a trial. '
          'A Guardian trial has not been approved. '
          'Payments and paid access activation are not available in this '
          'build; no trial starts just by opening a page.\n\n'
          'Blocking, reporting, privacy and account controls do not require '
          'a subscription.',
    ),
  ]),
  ZyraHelpCategory('Your profile', [
    // CORRECTED 2026-08-01. V1 said photos "passed review" and identity
    // "has been verified". Neither exists — both are mocked delays in
    // profile_ready_screen.dart. This is the answer that most clearly
    // broke this file's own rule.
    ZyraHelpEntry(
      'When does my profile go live?',
      'Once you have finished onboarding and added at least one photo. You can '
          'look around before then — you just will not appear to anyone else '
          'yet.\n\n'
          'Photo review and identity verification are being built and are not '
          'running yet. When they arrive we will tell you clearly, and explain '
          'what changes, before anything changes for you.',
    ),
    // SOFTENED 2026-08-01. The app enforces this; the database does not
    // yet (audit finding C4 is open). V1 promised a guarantee that only
    // half exists. Restore the firmer wording once C4 lands.
    ZyraHelpEntry(
      'Can I change my date of birth?',
      'Not from inside the app. Age is one of the few things other members '
          'rely on completely, so we do not let it be edited casually. If yours '
          'was entered wrongly, email support and we will correct it.',
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
      // Mirrors the unchanged One caps in zyra_entitlements.dart; retiring
      // the comparison does not change the matching/lifecycle limits.
      'ZYRA One supports up to three Active Journeys and ten Paused Journeys. '
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
      'Ending a Journey is deliberate and final — it is not a pause. For the '
          'next 24 hours neither of you can act on it. That quiet period is on '
          'purpose: it protects both people from a decision made in a difficult '
          'moment.\n\n'
          'Afterwards you are free to begin a Journey with someone else. If the '
          'two of you choose to start again together, you begin from the '
          'beginning — the process is not something you can skip back into.',
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
      'Press and hold the middle of their photo in Browse, then choose Report '
          'this profile. Pick a reason and send.\n\n'
          'They are never told, and you stop seeing each other straight away — '
          'that part is immediate. The report itself is recorded and kept.\n\n'
          'We are new, and our review process is still being built, so we will '
          'be straight with you rather than imply more than exists: if '
          'something is urgent, or you feel unsafe, email support@zyraconnect.app as '
          'well and a person will read it.',
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
      'Report it anyway. You do not need to be certain, and you will not get '
          'into trouble for raising something in good faith. We would far '
          'rather look at ten things that turn out to be fine than miss one '
          'that was not.',
    ),
  ]),
  ZyraHelpCategory('Account and plan', [
    ZyraHelpEntry(
      'What does ZYRA One include?',
      'ZYRA One — Seeker provides the complete premium Seeker experience. '
          'ZYRA One — Guardian makes a Guardian eligible to view and comment '
          'across permitted Journeys, enter permitted Journey conversations, '
          'and use Guardian Network to discover and recommend Seekers. The '
          'linked Seeker still controls each Additional Guardian’s View and '
          'Chat access.\n\n'
          'Guardian Basic can view the linked Seeker’s Journey only. It has no '
          'Journey commenting, conversation entry or Guardian Network page. '
          'Invitation, consent, reporting and essential safety controls remain '
          'available without payment.\n\n'
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
      'Privacy settings let you step out of Browse while keeping everything — '
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
      'At the bottom of your Profile tab. This permanently removes your '
          'profile, photos, matches and messages. It cannot be undone.\n\n'
          'If you are unsure, hide your profile instead and come back when you '
          'are ready.',
    ),
  ]),
];
