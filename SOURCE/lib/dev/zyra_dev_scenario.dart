// Developer scenario state — 2026-08-01.
//
// Founder: "make a toggle side button where I can select the options to
// see how it works."
//
// Why this is not a second copy of DeveloperAccess:
//
//   DeveloperAccessScreen switches ACCOUNT. It signs in as a real test
//   user. Heavy, correct, and the only way to exercise RLS or anything
//   server-side.
//
//   This switches STATE ON THE CURRENT ACCOUNT, live, without signing
//   out — for the axes that are orthogonal to which account you are.
//
// THE RULE FOR THIS FILE: a toggle must change something real. A switch
// that flips a bool nothing reads is worse than no switch, because it
// looks like the feature was checked. Every flag below names its reader.
//
// CONTEXT AWARENESS — 2026-08-03 (Founder: "let it only work on the
// correct page and correct user... if I try click it on a wrong area or
// wrong profile I need a red animation to show it can't. Maybe even start
// grouping the toggle section so it's easier for me to see").
//
// Every control now declares which plans it applies to and which page it
// affects. Out of context it is greyed and refuses, with a red shake,
// rather than appearing to work.
//
// That is not decoration. "Consider limit reached" is meaningless on ZYRA
// One — Considers are unlimited there, so the cap it simulates does not
// exist and the modal it would trigger can never fire. Before this, that
// switch would happily flip and then nothing would happen, which reads
// exactly like a bug in the feature rather than a category error in the
// test.

import 'package:flutter/foundation.dart';
import '../data/zyra_entitlements.dart';
import '../models/journey_match.dart';
import '../models/seeker_profile.dart';
import '../services/zyra_wali_link_service.dart';
import '../state/app_state.dart' show ZyraPlan;

/// Which Seeker plan a control makes sense for.
enum DevPlan { basic, one }

/// Which page a control affects. A control is only usable while that page
/// is the one on screen.
enum DevPage { browse, connections, guardian, profile }

/// The popups the panel can ask Browse to show. Each maps to a modal that
/// ALREADY EXISTS in browse_screen.dart — nothing here writes its own copy,
/// which was the complaint that produced this enum (Founder, 2026-08-05:
/// "please include the pop-ups that are on file, not create random ones").
///
///   saveLimit      -> _showCapReachedModal(action: 'Save', …)
///   considerLimit  -> _showCapReachedModal(action: 'Consider', …)
///   dailyLimit     -> _showLimitReachedModal()
///   sponsoredCard  -> the real sponsored card interstitial
enum DevPopup { saveLimit, considerLimit, dailyLimit, sponsoredCard }

extension DevPageX on DevPage {
  String get label => switch (this) {
        DevPage.browse => 'Browse',
        DevPage.connections => 'Connections',
        DevPage.guardian => 'Guardian',
        DevPage.profile => 'Profile',
      };
}

// The UnlockBalance enum and the `unlocks` / `unlockPlus` fields were
// REMOVED 2026-08-04. They held an in-memory credit count that the unlock
// screen read and the server knew nothing about, so once C-1 moved
// entitlement into the `unlock_credits` ledger the panel was setting a
// number with no bearing on whether an unlock would actually succeed — the
// screen said "5 left" and the RPC refused.
//
// Exactly the failure this file's own rule warns about: "a toggle must
// change something real. A switch that flips a bool nothing reads is worse
// than no switch, because it looks like the feature was checked."
//
// The panel now calls zyra_debug_grant_credits() and grants real credits.

class ZyraDevScenario extends ChangeNotifier {
  ZyraDevScenario._();
  static final ZyraDevScenario instance = ZyraDevScenario._();

  // --- Where the user currently is --------------------------------------
  // Written by HomeShell on every tab change. Read by the panel to decide
  // which controls are live.
  //
  // Deliberately pushed in rather than read out: the panel is a sibling of
  // the IndexedStack in HomeShell's Stack, not a child, so it has no other
  // way to know which tab is showing.

  DevPage currentPage = DevPage.browse;

  void setCurrentPage(DevPage page) {
    if (currentPage == page) return;
    currentPage = page;
    notifyListeners();
  }

  // --- Forced limit states ----------------------------------------------
  // Read by: browse_screen.dart `_onSave` and `_onConsider`.
  //
  // RESTORED 2026-08-03 after being removed on 2026-08-01. The removal was
  // right at the time and the restoration is right now, for the same
  // reason in both directions: reaching a cap honestly means 5, 15 or 25
  // deliberate taps, so the modals behind them go unreviewed. The ZYRA One
  // save message said the same thing twice for weeks before anyone got
  // there.
  //
  // Save applies on BOTH plans — Basic caps at 5, ZYRA One at 15, and the
  // two show visibly different copy.
  // Consider applies on Basic ONLY — ZYRA One is unlimited, so there is no
  // cap to reach and no modal to see.

  // REPLACED the `forceSaveLimit` / `forceConsiderLimit` booleans
  // 2026-08-05 (Founder: "after pressing the save limit button, every time
  // I try Browse the save limit message pops up — when I press the button
  // in toggle it should show it just one time").
  //
  // Those were STICKY: once set, every Save for the rest of the session hit
  // the cap branch, so the panel effectively broke Browse until reset. They
  // also only ARMED a state — the modal still needed the right tap
  // afterwards, so the button looked like it had done nothing.
  //
  // A popup is an event. This is a one-shot request: the panel names the
  // popup, Browse shows THE APP'S OWN modal once, and clears it. No
  // invented copy, no lingering state, one showing per press.
  DevPopup? pendingPopup;

  void requestPopup(DevPopup p) {
    pendingPopup = p;
    notifyListeners();
  }

  /// Read-and-clear. Browse calls this; whoever asks first gets it.
  DevPopup? takePendingPopup() {
    final p = pendingPopup;
    pendingPopup = null;
    return p;
  }

  // The sponsored card and the daily cap are requested the same way — both
  // were already built and both were otherwise unreachable in testing: the
  // advert needs five profile views, the daily cap needs fifty.

  // --- Adverts: a STATE, not an event -----------------------------------
  //
  // ADDED 2026-08-07 (Founder: "create a toggle button to show
  // advertisements for the zyra basic user").
  //
  // This sits alongside the one-shot "Show advert" button rather than
  // replacing it, because the two answer different questions and this file
  // previously argued only the first was worth having:
  //
  //   BUTTON  "what does the advert card look like?"      — one, now
  //   TOGGLE  "what is Browse LIKE with adverts in it?"   — every profile
  //
  // The earlier note said "an advert that fires on every swipe is not a
  // real scenario", and as a description of production that is true. But
  // the thing worth reviewing is not the card in isolation — it is the
  // rhythm of being interrupted, whether the Continue button lands where
  // your thumb already is, whether it breaks a run of browsing. One firing
  // never shows that, and 24 seeded profiles give you four in a whole deck.
  //
  // So this IS a deliberate preview state the product would never produce,
  // which the panel's own rule permits as long as it is stated. Stated.
  //
  // Read by browse_screen.dart `_advance()`. Basic only there, because
  // ZYRA One is contractually ad-free and simulating adverts on it would
  // preview a promise being broken.
  bool adsOnEveryProfile = false;

  void setAdsOnEveryProfile(bool v) {
    if (adsOnEveryProfile == v) return;
    adsOnEveryProfile = v;
    notifyListeners();
  }

  // --- Test deck ---------------------------------------------------------
  // REMOVED 2026-08-04, Founder: "remove the 200 colour profile block
  // profiles, I don't want that no more."
  //
  // The deck existed because the seeded profiles had no Chapter 2 data and
  // real photos were slow to sign. Both are now false: the 24 seeded
  // profiles carry sect, ethnicity, languages and preferences, so the real
  // deck exercises more of the product than a synthetic one ever did.

  // --- Guardians --------------------------------------------------------
  // Read by: seeker_wali_tab.dart.
  //
  // Founder: "whatever number I select, it then shows on the Guardian page
  // a profile card of a mock-up Guardian. For example if I click 1 it
  // makes Abdul father; if two, it's Abdul father and Hassan brother."
  //
  // Linking a Guardian for real needs a second account, an invite code and
  // a 7-day token — which is why that page's layout had never been seen
  // with anyone in it, and why `wali_links.is_main` sat unread since the
  // table was built.
  //
  // Index 0 is always Main. Not a display choice: `wali_links.is_main`
  // auto-designates the first active link, so if the fakes disagreed the
  // panel would show a layout the database cannot produce.
  /// SPLIT 2026-08-06 (Founder: "for wali section can you give option for 1
  /// main wali, 0–5 additional wali and 0–5 pending wali").
  ///
  /// Was a single 0–3 count, which could not produce the states the
  /// rebuilt Guardian page actually has: a Main with no Additional, a
  /// pending-only network, or an empty page while invites are outstanding.
  ///
  /// NO PRODUCT LIMIT EXISTS. Checked before adding these:
  /// `wali_links` has no count constraint, the INSERT policy caps nothing,
  /// `accept_wali_invite` counts nothing, and WALI_ARCHITECTURE V6 states
  /// plainly — "No artificial cap is currently imposed. A formal linking
  /// policy must be specified before production." So 5 is a testing
  /// convenience, NOT an implied maximum, and the page must not be built as
  /// though 6 were the ceiling.
  bool mainGuardian = false;
  int additionalGuardianCount = 0;
  int pendingInviteCount = 0;

  /// Invitations sent TO this user by a Guardian, awaiting their answer.
  ///
  /// ADDED 2026-08-07 as a PREVIEW. This section cannot exist for real yet —
  /// see ZyraDevScenario.fakeReceived below.
  int receivedInviteCount = 0;

  /// When true the Guardian page reads the DATABASE and ignores the panel.
  ///
  /// INVERTED 2026-08-07 (Founder: "if the Dev Panel says 0 Guardians, the
  /// Guardian page should also show 0 Guardians… When I'm using the Dev
  /// Panel I expect the panel to be the source of truth").
  ///
  /// The panel now wins by default and 0 means zero. Live data is a
  /// deliberate opt-in, named on screen, rather than something 0 quietly
  /// meant.
  ///
  /// THE HISTORY, because it took three attempts and the lesson is worth
  /// keeping: the first two versions tried to INFER whether the panel was
  /// driving the page, from the values — `pendingInviteCount > 0`, then
  /// `|| guardianCount > 0`. Both failed the same way, because 0 is
  /// simultaneously a legitimate choice and the resting state, so the two
  /// cannot be told apart. The third made it an explicit flag but still
  /// defaulted to live data, which left the panel and the page disagreeing
  /// on screen.
  ///
  /// A control panel that is only SOMETIMES in charge is a control panel you
  /// cannot trust. It is in charge unless told otherwise.
  bool useLiveGuardianData = false;

  /// Kept as the inverse so existing readers stay legible.
  bool get guardianOverride => !useLiveGuardianData;

  // ── Journeys ─────────────────────────────────────────────────────────
  //
  // ADDED 2026-08-06 (Founder: "add a section for 0–5 journey queued,
  // paused journeys, ended journey, and I'm assuming we only have option
  // for 1 active journey so make that 0/1").
  //
  // The assumption is right, and the database enforces it — `matches` has
  // UNIQUE partial indexes on seeker_a_id and seeker_b_id WHERE
  // status = 'active'. One Active Journey per person, structurally.
  //
  // BUT PAUSED IS NOT A FOURTH STATE. `suspend_journey()` sets suspended_by
  // and leaves the status 'active' — pausing is a FLAG on an Active
  // Journey, and 'paused' was removed from the status CHECK entirely on
  // 2026-08-06 because it had always been unreachable.
  //
  // So Active and Paused are the SAME slot. Separate 0/1 and 0–5 controls
  // would let the panel produce a state the database cannot hold: five
  // paused Journeys are five active ones. One control with three mutually
  // exclusive values says the truth instead of letting two toggles
  // contradict each other.
  int queuedJourneys = 0; // status 'potential'
  int endedJourneys = 0; // status 'ended'

  /// Active Journeys, and how many of those are paused.
  ///
  /// SPLIT AGAIN 2026-08-07 (Founder: "I don't see paused journey options,
  /// add that"). The Connections page genuinely renders ACTIVE JOURNEY and
  /// PAUSED JOURNEYS as separate sections, so the panel needs to drive both.
  ///
  /// `pausedJourneys` is a SUBSET of `activeJourneys`, never a fourth state
  /// — suspend_journey() sets suspended_by and leaves status 'active'. So
  /// paused can never exceed active, and the panel clamps rather than
  /// letting the two disagree.
  ///
  /// CAP: ONE, on both plans, and the panel now agrees with that.
  ///
  /// ── CHANGED 2026-08-09. Founder: "I'm on ZYRA Basic but I managed to
  /// select 3 for active journey... change it back to 1 only."
  ///
  /// This used to allow up to 3 on the grounds that
  /// ZYRA_JOURNEY_ENTITLEMENT_DECISION leaves the number "deliberately open
  /// pending Islamic review". That reasoning confused two different things:
  ///
  ///   OPEN means nobody has decided whether ZYRA One should ever get 2 or
  ///   3. It is a live question, held for religious guidance.
  ///
  ///   TODAY'S ANSWER is 1, for both plans, and it is not soft. Verified
  ///   2026-08-09: zyra_enforce_one_active_match carries no plan check, and
  ///   matches_seeker_a_active / matches_seeker_b_active are UNIQUE partial
  ///   indexes over every Seeker. Two triggers and two indexes.
  ///
  /// A preview tool may exaggerate quantities — Potential and Ended still
  /// go to 5 — but it should not render a state the server refuses. This
  /// panel showed three Active Journeys on a Basic account, which is not a
  /// preview of an undecided rule; it is a picture of something that cannot
  /// happen. If the number is ever raised, raise it here in the same change
  /// that raises it in the database, not before.
  ///
  /// [pausedJourneys] is capped for the same reason and it is not a
  /// separate rule: a paused Journey is an ACTIVE row with suspended_by
  /// set. matches_status_check permits only potential / active / ended.
  /// Three paused Journeys are three active Journeys.
  int activeJourneys = 0;
  int pausedJourneys = 0;

  /// Total linked Guardians. Kept as a getter so every existing
  /// `guardianCount > 0` check still means "the dev panel is driving this
  /// page" without each caller having to reassemble it.
  int get guardianCount => (mainGuardian ? 1 : 0) + additionalGuardianCount;

  /// Names are the Founder's own. Fixed, so screenshots are reproducible.
  /// CHANGED 2026-08-06: these were display labels ('Father', 'Paternal
  /// uncle'). They are now the stored CODES, so dev data and production
  /// data are the same shape and go through the same label lookup. The old
  /// values had a lowercase 'u' in "Paternal uncle" and would never have
  /// matched anything — which nobody noticed, because until today these
  /// fakes were the ONLY source of a relationship anywhere in the app.
  /// Six, so 1 Main + 5 Additional is reachable. Relationships deliberately
  /// span the whole enum — a list of three fathers would never have shown
  /// that "Family Representative" is the longest label on the card and the
  /// first to wrap.
  static const List<({String name, String relationship})> fakeGuardians = [
    (name: 'Abdul', relationship: 'father'),
    (name: 'Hassan', relationship: 'brother'),
    (name: 'Ibrahim', relationship: 'uncle'),
    (name: 'Yusuf', relationship: 'grandfather'),
    (name: 'Bilal', relationship: 'legal_guardian'),
    (name: 'Kamran', relationship: 'family_representative'),
  ];

  /// Labels are the Founder's own examples. One is deliberately null: an
  /// invite with no label is the common case, and it renders as the raw
  /// token, which is the outcome the label exists to avoid — worth being
  /// able to see rather than only ever testing the happy path.
  static const List<({String? label, int daysLeft})> fakePendingInvites = [
    (label: 'Dad', daysLeft: 5),
    (label: 'Uncle Ibrahim', daysLeft: 3),
    (label: null, daysLeft: 6),
    (label: 'Imam', daysLeft: 1),
    (label: 'Family Friend', daysLeft: 0),
  ];

  /// Activity for the fake Guardians, so the dev panel exercises the
  /// Guardian page's whole point rather than showing empty cards.
  ///
  /// ADDED 2026-08-06 with the Family Management rebuild. Without it the
  /// panel would display a working feature looking broken — the exact trap
  /// the relationship fixtures set earlier the same day, where the fakes
  /// were the only source of a value the real fetch never selected.
  ///
  /// Shapes deliberately chosen to cover all four states the card can
  /// render: something owed (Abdul), a plain event (Hassan), several
  /// events (Ibrahim), and nothing at all — index 3+ returns empty, which
  /// is the case the honest empty copy exists for.
  static List<GuardianActivity> fakeActivityFor(String devId) {
    final now = DateTime.now();
    return switch (devId) {
      'dev-guardian-0' => [
          GuardianActivity(
            waliId: devId,
            type: 'review_waiting',
            occurredAt: now.subtract(const Duration(days: 2)),
          ),
          GuardianActivity(
            waliId: devId,
            type: 'suggested',
            occurredAt: now.subtract(const Duration(days: 9)),
            detail: 'Yusuf',
          ),
          GuardianActivity(
            waliId: devId,
            type: 'linked',
            occurredAt: now.subtract(const Duration(days: 61)),
          ),
        ],
      'dev-guardian-1' => [
          GuardianActivity(
            waliId: devId,
            type: 'review_answered',
            occurredAt: now.subtract(const Duration(days: 5)),
            detail: 'approve',
          ),
          GuardianActivity(
            waliId: devId,
            type: 'linked',
            occurredAt: now.subtract(const Duration(days: 40)),
          ),
        ],
      'dev-guardian-2' => [
          GuardianActivity(
            waliId: devId,
            type: 'suggested',
            occurredAt: now.subtract(const Duration(hours: 5)),
            detail: 'Nuh',
          ),
          GuardianActivity(
            waliId: devId,
            type: 'suggested',
            occurredAt: now.subtract(const Duration(days: 3)),
            detail: 'Zakariya',
          ),
          GuardianActivity(
            waliId: devId,
            type: 'linked',
            occurredAt: now.subtract(const Duration(days: 18)),
          ),
        ],
      // Guardians 3–5 have no activity, on purpose. Someone who has just
      // linked has genuinely done nothing, and the honest empty copy on the
      // detail page needs a case that reaches it.
      _ => const [],
    };
  }

  /// Fake Journeys for the Connections page.
  ///
  /// `isMock: true` on every one — the model already carries that flag for
  /// exactly this, and it is what stops a screen trying to call
  /// `end_journey` on a match id the server has never heard of.
  ///
  /// Ended ones get an `endedAt` well past the 24-hour cooling period, so
  /// Restart is reachable rather than permanently greyed out.
  /// [viewerGender] is passed in rather than read from AppState, so this
  /// file keeps depending on nothing but the models. The fakes are shown the
  /// opposite gender, matching the gender segregation Browse enforces.
  /// [pool] is REAL profiles — with real photos — that the fake Journeys are
  /// wrapped around.
  ///
  /// CHANGED 2026-08-07 (Founder: "I get this white box, so make them profile
  /// cards… if needed make profiles with photos we already have").
  ///
  /// The first version invented people with `photos: const []`, and an empty
  /// photo list renders as a blank white tile — which is what the white box
  /// was. Inventing a profile means inventing everything a card draws, and
  /// the one thing that cannot be invented client-side is a signed photo URL.
  ///
  /// So the fakes now borrow real seeded profiles and only fabricate the
  /// JOURNEY STATE around them. Everything a card renders is genuine; only
  /// the status is staged.
  static List<JourneyMatch> fakeJourneys({
    String? viewerGender,
    List<SeekerProfile> pool = const [],
    ZyraPlan viewerPlan = ZyraPlan.basic,
  }) {
    final s = ZyraDevScenario.instance;
    final now = DateTime.now();
    final out = <JourneyMatch>[];
    final otherGender = viewerGender == 'female' ? 'male' : 'female';

    var next = 0;
    // Falls back to a synthesised profile only when no real pool arrived —
    // better a blank card than a crash, but the pool is the intended path.
    SeekerProfile take(String name, int age) {
      if (pool.isEmpty) {
        return SeekerProfile(
          id: 'dev-$name', firstName: name, age: age,
          city: 'Birmingham', photos: const [], gender: otherGender,
        );
      }
      return pool[next++ % pool.length];
    }

    JourneyMatch make(String id, String name, int age, String status,
            {String? stage, String? suspendedBy, DateTime? endedAt}) =>
        JourneyMatch(
          matchId: id,
          profile: take(name, age),
          status: status,
          journeyStage: stage,
          suspendedBy: suspendedBy,
          endedAt: endedAt,
          isMock: true,
        );

    // ── TEN NAMES PER LIST, 2026-08-09, up from five.
    //
    // The dev panel now offers up to 10 for Potential, Paused and Ended
    // (ZYRA One's caps — see data/zyra_entitlements.dart). With five names
    // the generator silently produced five rows for a toggle that said ten,
    // which is a control panel lying about the state it just created — the
    // exact failure this panel exists to avoid.
    // One lookup for all four loops below.
    final limits = ZyraEntitlements.of(viewerPlan);

    const queuedNames = ['Yusuf', 'Bilal', 'Idris', 'Musa', 'Zaid',
        'Harun', 'Tariq', 'Rayyan', 'Kamal', 'Adnan'];
    final nQueued = ZyraEntitlements.devClamp(s.queuedJourneys, limits.potential);
    for (var i = 0; i < nQueued && i < queuedNames.length; i++) {
      out.add(make('dev-q$i', queuedNames[i], 26 + i, 'potential'));
    }

    // SIMULATION ONLY — the two counts are now INDEPENDENT.
    //
    // In production, paused is a subset of active: suspend_journey() sets
    // suspended_by and leaves the status 'active', and a unique index allows
    // one active Journey per person. The panel used to enforce that, which
    // meant previewing a paused layout required creating an active Journey
    // and pausing it first.
    //
    // Here `activeJourneys` means RUNNING and `pausedJourneys` means PAUSED,
    // and the two simply add up. Every row is isMock and never reaches the
    // database, so nothing real is violated — production keeps its index.
    //
    // 2026-08-09: the counts are CLAMPED TO THE CURRENT PLAN by the same
    // helper the panel's segments use, so switching ZYRA One -> Basic with
    // Paused at 8 shows Basic's 5 in both places. Without a shared clamp
    // the row and the list drift apart on a plan switch, and the panel
    // stops being the source of truth it claims to be.
    const activeNames = ['Amina', 'Sara', 'Zaynab', 'Maryam', 'Khadija'];
    const pausedNames = ['Fatima', 'Aisha', 'Safiya', 'Halima', 'Nadia',
        'Rabia', 'Sumaya', 'Zahra', 'Iman', 'Noor'];
    final nActive = ZyraEntitlements.devClamp(s.activeJourneys, limits.active);
    for (var i = 0; i < nActive && i < activeNames.length; i++) {
      out.add(make('dev-a$i', activeNames[i], 27 + i, 'active',
          stage: 'conversation'));
    }
    final nPaused = ZyraEntitlements.devClamp(s.pausedJourneys, limits.paused);
    for (var i = 0; i < nPaused && i < pausedNames.length; i++) {
      out.add(make('dev-p$i', pausedNames[i], 26 + i, 'active',
          stage: 'conversation', suspendedBy: 'dev-other'));
    }

    const endedNames = ['Layla', 'Hafsa', 'Ruqayya', 'Asma', 'Juwayriya',
        'Umm Kulthum', 'Zaynab bint Ali', 'Ramla', 'Barira', 'Nusayba'];
    final nEnded = ZyraEntitlements.devClamp(s.endedJourneys, limits.ended);
    for (var i = 0; i < nEnded && i < endedNames.length; i++) {
      out.add(make('dev-e$i', endedNames[i], 25 + i, 'ended',
          endedAt: now.subtract(Duration(days: 2 + i))));
    }

    return out;
  }

  /// True when any Journey toggle is driving the Connections page.
  bool get journeysOverridden =>
      queuedJourneys > 0 || activeJourneys > 0 || pausedJourneys > 0 || endedJourneys > 0;

  /// Invitations this Seeker has RECEIVED from a Guardian.
  ///
  /// PREVIEW ONLY, and it cannot be otherwise today: `wali_invites` has no
  /// recipient. The flow is "generate a code, share it however you like", so
  /// nobody — including ZYRA — knows who an invite is for until they type
  /// the code in. There is nothing to list.
  ///
  /// Making this real needs invites to become ADDRESSED (sent to an account,
  /// a phone number or an email) rather than bearer tokens. That is a
  /// product decision, not a screen. This exists so the layout can be judged
  /// before that decision is taken.
  static List<({String from, String relationship, int daysAgo})> fakeReceived(int count) {
    const all = [
      (from: 'Abdul', relationship: 'father', daysAgo: 0),
      (from: 'Hassan', relationship: 'brother', daysAgo: 2),
      (from: 'Ibrahim', relationship: 'uncle', daysAgo: 5),
      (from: 'Yusuf', relationship: 'grandfather', daysAgo: 9),
      (from: 'Bilal', relationship: 'legal_guardian', daysAgo: 14),
    ];
    return [for (var i = 0; i < count && i < all.length; i++) all[i]];
  }

  /// Fake pending invites, shaped so the section renders every variant:
  /// labelled, unlabelled, and expiring today.
  static List<PendingInvite> fakePending(int count) {
    final now = DateTime.now();
    return [
      for (var i = 0; i < count && i < fakePendingInvites.length; i++)
        PendingInvite(
          // A plausible token, so an unlabelled invite shows what a real
          // one would rather than something obviously fake.
          token: 'DEV${(i + 1) * 11117 % 100000}'.padRight(8, 'X').substring(0, 8),
          label: fakePendingInvites[i].label,
          createdAt: now.subtract(Duration(days: 7 - fakePendingInvites[i].daysLeft)),
          expiresAt: now.add(Duration(days: fakePendingInvites[i].daysLeft)),
        ),
    ];
  }

  // ---------------------------------------------------------------------

  void set_(void Function() change) {
    change();
    notifyListeners();
  }

  void reset() {
    pendingPopup = null;
    // guardianCount is a getter as of 2026-08-06 — clear what feeds it.
    useLiveGuardianData = false;
    mainGuardian = false;
    additionalGuardianCount = 0;
    pendingInviteCount = 0;
    receivedInviteCount = 0;
    queuedJourneys = 0;
    activeJourneys = 0;
    pausedJourneys = 0;
    endedJourneys = 0;
    notifyListeners();
  }
}
