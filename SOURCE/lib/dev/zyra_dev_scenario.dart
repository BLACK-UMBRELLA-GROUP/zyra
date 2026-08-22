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
//
// REBUILT 2026-08-12 (Founder-directed dev-panel redesign). Every simulated
// value is now a PRIVATE field behind a guarded setter: same-value writes do
// not notify, so re-tapping a segment no longer makes every listening screen
// re-fetch, and there is exactly one door into each piece of state. The
// generic set_() escape hatch is gone — it let callers mutate fields this
// class did not know were changing, which is exactly how reset() came to
// quietly miss the adverts toggle (found and fixed in the same pass:
// reset() now covers EVERY axis, enumerated in one place, one notify).

import 'package:flutter/foundation.dart';
import '../data/zyra_entitlements.dart';
import '../data/zyra_journey_stages.dart';
import '../models/journey_match.dart';
import '../models/seeker_profile.dart';
import '../models/zyra_gender.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_wali_journey_service.dart';
import '../services/zyra_wali_link_service.dart';
import '../state/app_state.dart' show ZyraPlan;

/// Which Seeker plan a control makes sense for.
enum DevPlan { basic, one }

/// Which page a control affects. A control is only usable while that page
/// is the one on screen.
enum DevPage { browse, connections, guardian, notifications, profile }

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
    DevPage.notifications => 'Notifications',
    DevPage.profile => 'Profile',
  };
}

// ═════════════════════════════════════════════════════════════════════
// THE GUARDIAN SIDE — added 2026-08-13 (DR-ZYRA-152).
// ═════════════════════════════════════════════════════════════════════
//
// ONE STORE, NOT TWO. These enums and the "— Wali side —" fields further
// down live in this class alongside the Seeker ones deliberately: one
// singleton, one reset(), one place a new field can be forgotten from.
// A second scenario store would have its own reset that drifts, which is
// the precise failure the 2026-08-12 rebuild was written to end.
//
// The panel that drives them is a separate WIDGET
// (dev/wali_dev_scenario_panel.dart) because the two shells mount
// different trees — but it reads and writes this object.

/// Which Guardian tab a control affects. The Guardian shell's five tabs,
/// in nav-bar order (Network sits left of Seekers since 2026-08-13).
///
/// Pushed in by WaliHomeShell on every tab change, exactly as HomeShell
/// pushes [DevPage] — the panel is a sibling of the IndexedStack, not a
/// child, so it has no other way to know which tab is showing.
enum WaliPage { dashboard, network, seekers, notifications, profile }

extension WaliPageX on WaliPage {
  String get label => switch (this) {
    WaliPage.dashboard => 'Dashboard',
    WaliPage.network => 'Network',
    WaliPage.seekers => 'Seekers',
    WaliPage.notifications => 'Notifications',
    WaliPage.profile => 'Profile',
  };
}

/// Main Guardian or Additional Guardian.
///
/// NOT cosmetic, and this is why the Guardian panel needed a refusal
/// path the Seeker panel had deleted. `wali_links.is_main` is a real
/// privilege boundary (closed 2026-08-08, GUARDIAN & ROMANTIC RULES
/// §7d): zyra_counterpart_card() returns nothing to an Additional
/// Guardian, so ZyraWaliJourneyService.fetchLinkedJourneys() skips the
/// row entirely, and wali_review_decision() refuses their vote.
///
/// An Additional Guardian therefore sees a SMALLER app, not a different
/// one — and the only way to learn that from a control panel is for the
/// controls they do not get to be VISIBLE and REFUSED. Hiding them, the
/// Seeker panel's rule, would make the whole distinction invisible.
enum WaliRole { main, additional }

extension WaliRoleX on WaliRole {
  String get label =>
      this == WaliRole.main ? 'Main Guardian' : 'Additional Guardian';
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

  // Which segment of Connections is on screen: 0 Journeys · 1 Activity ·
  // 2 Introductions. Written by ConnectionsScreen when a swipe settles
  // (same pushed-in reasoning as currentPage). The panel narrows the
  // Connections card to the section actually showing — you have to BE on
  // Introductions to see the Introductions controls.
  //
  // ADDED 2026-08-12 (Founder: "i gotta be on indroduction to see the
  // introduction optins in toggle").
  //
  // Context, not scenario: reset() leaves it alone, because where you are
  // in the app is not staged data.

  int connectionsSection = 0;

  void setConnectionsSection(int section) {
    final s = section.clamp(0, 2);
    if (connectionsSection == s) return;
    connectionsSection = s;
    notifyListeners();
  }

  // --- Stand-in interactions that must FEEL real ------------------------
  // ADDED 2026-08-12 (Founder: "it says stand-in, nudges need a real
  // paused journey (dev) so please fix and make that"). A dev snackbar
  // where the product would act is the panel lying about the experience.
  // Fake matchIds are deterministic (dev-p0, dev-p1…), so marking one
  // nudged here survives every recompose; composeJourneys reads this set
  // and stamps pauseNudgedAt, which greys the row's button exactly as a
  // real nudge would. reset() clears it with everything else.
  final Set<String> _nudgedFakes = {};
  bool fakeNudged(String matchId) => _nudgedFakes.contains(matchId);
  void markFakeNudged(String matchId) {
    if (!_nudgedFakes.add(matchId)) return;
    notifyListeners();
  }

  // How many staged people are ALREADY in a Journey with someone else.
  //
  // ONE COUNT PER SECTION since 2026-08-13 (Founder: "in toggle the in
  // another journey make 3… so i can choose how many people are in a
  // journey so i can see") — the single potential-first budget of
  // 2026-08-12 couldn't stage "a busy PAUSED person" without first
  // making every potential person busy. Each count marks the FIRST N
  // fakes of its own section (deterministic across recomposes, like the
  // nudge set); composeJourneys clamps by construction, so lowering a
  // row count can never leave more busy people than people. Fakes only —
  // real rows keep whatever the fetch said.
  int _busyPotential = 0;
  int get busyPotential => _busyPotential;
  void setBusyPotential(int v) {
    final n = v.clamp(0, 30);
    if (_busyPotential == n) return;
    _busyPotential = n;
    notifyListeners();
  }

  int _busyPaused = 0;
  int get busyPaused => _busyPaused;
  void setBusyPaused(int v) {
    final n = v.clamp(0, 30);
    if (_busyPaused == n) return;
    _busyPaused = n;
    notifyListeners();
  }

  int _busyEnded = 0;
  int get busyEnded => _busyEnded;
  void setBusyEnded(int v) {
    final n = v.clamp(0, 30);
    if (_busyEnded == n) return;
    _busyEnded = n;
    notifyListeners();
  }

  // How many staged PAUSED people were paused BY THE TESTER (Founder,
  // 2026-08-13: "i need a toggle where i can choose paused by them or
  // paused by you"). The first N paused fakes carry the tester's own id
  // as suspended_by — so their rows read "Paused by you" and offer
  // Resume — and the rest stay paused by the other side ("Request
  // restart" / the one-shot nudge). Both worlds on one screen.
  int _pausedByYou = 0;
  int get pausedByYou => _pausedByYou;
  void setPausedByYou(int v) {
    final n = v.clamp(0, 30);
    if (_pausedByYou == n) return;
    _pausedByYou = n;
    notifyListeners();
  }

  // How many of the paused-BY-THEM stand-ins the tester has ALSO paused
  // (DR-ZYRA-170, shared holds). Not a panel row — this count is driven
  // by the card's own "Also Pause" action, exactly as takeover settles
  // drive the section counts. Positional: the first N paused-by-other
  // fakes read "Paused by both of you" and offer Resume (lifting the
  // tester's own hand drops them back to paused-by-them).
  int _mirroredPaused = 0;
  int get mirroredPaused => _mirroredPaused;
  void setMirroredPaused(int v) {
    final n = v.clamp(0, 30);
    if (_mirroredPaused == n) return;
    _mirroredPaused = n;
    notifyListeners();
  }

  /// The clean panel presents one understandable ownership choice for its
  /// first Paused preview instead of separate, contradictory counters.
  /// 0 = paused by them, 1 = paused by you, 2 = paused by both.
  int get pausePreviewOwner {
    if (_mirroredPaused > 0) return 2;
    if (_pausedByYou > 0) return 1;
    return 0;
  }

  void setPausePreviewOwner(int owner) {
    final resolved = owner.clamp(0, 2);
    final nextPaused = _pausedJourneys == 0 ? 1 : _pausedJourneys;
    final nextByYou = resolved == 1 ? 1 : 0;
    final nextMirrored = resolved == 2 ? 1 : 0;
    if (_pausedJourneys == nextPaused &&
        _pausedByYou == nextByYou &&
        _mirroredPaused == nextMirrored) {
      return;
    }
    _pausedJourneys = nextPaused;
    _pausedByYou = nextByYou;
    _mirroredPaused = nextMirrored;
    notifyListeners();
  }

  // The three-way Connections page-design switcher lived here for a few
  // hours on 2026-08-12 (A sections · B hero+shelves · C one list) and
  // was REMOVED the same day: the Founder committed to A — "stop
  // exploring alternative layouts and instead focus on making Option A
  // feel polished." Both alternative builders deleted with it; git
  // history keeps them if a future redesign wants the reference.

  // The Sheet/Rows person-surface switcher (concepts 1 and 4) also lived
  // and died on 2026-08-12: after testing both live, the Founder kept the
  // ROWS pattern — the Activity card's expansion model — for every person
  // on Connections, and the toggle went with the choice. One pattern,
  // no switch, nothing to configure.

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
  bool _adsOnEveryProfile = false;
  bool get adsOnEveryProfile => _adsOnEveryProfile;

  void setAdsOnEveryProfile(bool v) {
    if (_adsOnEveryProfile == v) return;
    _adsOnEveryProfile = v;
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
  bool _mainGuardian = false;
  int _additionalGuardianCount = 0;
  int _pendingInviteCount = 0;

  bool get mainGuardian => _mainGuardian;
  int get additionalGuardianCount => _additionalGuardianCount;
  int get pendingInviteCount => _pendingInviteCount;

  void setMainGuardian(bool v) {
    if (_mainGuardian == v) return;
    _mainGuardian = v;
    notifyListeners();
  }

  void setAdditionalGuardians(int v) {
    if (_additionalGuardianCount == v) return;
    _additionalGuardianCount = v;
    notifyListeners();
  }

  void setPendingInvites(int v) {
    if (_pendingInviteCount == v) return;
    _pendingInviteCount = v;
    notifyListeners();
  }

  /// One dev invite was cancelled on the Guardian page. The page calls this
  /// rather than reaching into the field (the old `set_()` route), so the
  /// panel's segment and the page always agree on the count.
  void consumePendingInvite() {
    if (_pendingInviteCount <= 0) return;
    _pendingInviteCount -= 1;
    notifyListeners();
  }

  /// Invitations sent TO this user by a Guardian, awaiting their answer.
  ///
  /// ADDED 2026-08-07 as a PREVIEW. This section cannot exist for real yet —
  /// see ZyraDevScenario.fakeReceived below.
  int _receivedInviteCount = 0;
  int get receivedInviteCount => _receivedInviteCount;

  void setReceivedInvites(int v) {
    if (_receivedInviteCount == v) return;
    _receivedInviteCount = v;
    notifyListeners();
  }

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
  bool _useLiveGuardianData = false;
  bool get useLiveGuardianData => _useLiveGuardianData;

  void setUseLiveGuardianData(bool v) {
    if (_useLiveGuardianData == v) return;
    _useLiveGuardianData = v;
    notifyListeners();
  }

  /// Kept as the inverse so existing readers stay legible.
  bool get guardianOverride => !_useLiveGuardianData;

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
  int _queuedJourneys = 0; // status 'potential'
  int _endedJourneys = 0; // status 'ended'

  int get queuedJourneys => _queuedJourneys;
  int get endedJourneys => _endedJourneys;

  void setQueuedJourneys(int v) {
    if (_queuedJourneys == v) return;
    _queuedJourneys = v;
    notifyListeners();
  }

  void setEndedJourneys(int v) {
    if (_endedJourneys == v) return;
    _endedJourneys = v;
    notifyListeners();
  }

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
  int _activeJourneys = 0;
  int _pausedJourneys = 0;

  int get activeJourneys => _activeJourneys;
  int get pausedJourneys => _pausedJourneys;

  void setActiveJourneys(int v) {
    if (_activeJourneys == v) return;
    _activeJourneys = v;
    notifyListeners();
  }

  /// DR-ZYRA-180. A public nudge for dev controls that change SERVER
  /// rows rather than staged counts — seeding a real Journey changes
  /// what the real fetch returns, and ConnectionsScreen's scenario
  /// listener answers a notify with a full re-fetch. Nothing staged
  /// changes here.
  void refreshJourneys() => notifyListeners();

  void setPausedJourneys(int v) {
    if (_pausedJourneys == v) return;
    _pausedJourneys = v;
    notifyListeners();
  }

  /// One-time bridge from the 2026-08-12 control collection to the clean
  /// 2026-08-18 panel. These axes were removed because they either created a
  /// dead-end Active stand-in or staged impossible cross-section mixtures.
  /// Clearing them on the panel's first mount prevents an old hot-reload
  /// session from carrying invisible switches into the new interface.
  void migrateToCleanSeekerPanel() {
    final changed =
        _adsOnEveryProfile ||
        _activeJourneys != 0 ||
        _busyPotential != 0 ||
        _busyPaused != 0 ||
        _busyEnded != 0;
    if (!changed) return;
    _adsOnEveryProfile = false;
    _activeJourneys = 0;
    _busyPotential = 0;
    _busyPaused = 0;
    _busyEnded = 0;
    notifyListeners();
  }

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
  ///
  /// Real Journeys are account truth and are always returned. Scenario
  /// counts add preview cards around them; zero means zero PREVIEWS, not
  /// zero real people. This supersedes the 2026-08-12 absolute-count model,
  /// which could hide a working Journey and replace it with a fake Active
  /// card that could not enter the flow.
  static List<JourneyMatch> composeJourneys({
    String? viewerGender,
    String? currentUserId,
    List<SeekerProfile> pool = const [],
    ZyraPlan viewerPlan = ZyraPlan.basic,
    List<JourneyMatch> realActive = const [],
    List<JourneyMatch> realPotential = const [],
    List<JourneyMatch> realPaused = const [],
    List<JourneyMatch> realEnded = const [],
  }) {
    final s = ZyraDevScenario.instance;
    final now = DateTime.now();
    // Real account truth is always present. Scenario counts now mean EXTRA
    // preview cards; zero removes previews, never real people. The old
    // absolute-count model could hide a working server Journey and replace it
    // with a dead-end Active stand-in that looked identical.
    final out = <JourneyMatch>[
      ...realPotential,
      ...realActive,
      ...realPaused,
      ...realEnded,
    ];
    final otherGender = ZyraGender.oppositeCode(viewerGender);

    var next = 0;
    // Falls back to a synthesised profile only when no real pool arrived —
    // better a blank card than a crash, but the pool is the intended path.
    SeekerProfile take(String name, int age) {
      if (pool.isEmpty) {
        return SeekerProfile(
          id: 'dev-$name',
          firstName: name,
          age: age,
          city: 'Birmingham',
          photos: const [],
          gender: otherGender,
        );
      }
      return pool[next++ % pool.length];
    }

    JourneyMatch make(
      String id,
      String name,
      int age,
      String status, {
      String? stage,
      String? suspendedBy,
      String? alsoPausedBy,
      DateTime? suspendedAt,
      DateTime? pauseNudgedAt,
      DateTime? endedAt,
      bool inAnotherJourney = false,
    }) => JourneyMatch(
      matchId: id,
      profile: take(name, age),
      status: status,
      journeyStage: stage,
      suspendedBy: suspendedBy,
      alsoPausedBy: alsoPausedBy,
      suspendedAt: suspendedAt,
      pauseNudgedAt: pauseNudgedAt,
      endedAt: endedAt,
      inAnotherJourney: inAnotherJourney,
      isMock: true,
    );

    // "In another Journey" — PER SECTION since 2026-08-13: the first N
    // fakes of each section are busy, N being that section's own panel
    // count. FAKES ONLY (an Active Journey with the tester cannot also
    // be with someone else, so the active loop has no count). Clamped by
    // construction: a fake index only exists for a built fake.
    //
    // "Paused by you": the first N paused fakes carry the tester's own
    // id, so iInitiated reads true exactly as on a real row.
    final me = currentUserId ?? ZyraAuth.currentUser?.id ?? 'dev-me';

    // ── TEN NAMES PER LIST, 2026-08-09, up from five.
    //
    // The dev panel now offers up to 10 for Potential, Paused and Ended
    // (ZYRA One's caps — see data/zyra_entitlements.dart). With five names
    // the generator silently produced five rows for a toggle that said ten,
    // which is a control panel lying about the state it just created — the
    // exact failure this panel exists to avoid.
    // One lookup for all four loops below.
    final limits = ZyraEntitlements.of(viewerPlan);

    const queuedNames = [
      'Yusuf',
      'Bilal',
      'Idris',
      'Musa',
      'Zaid',
      'Harun',
      'Tariq',
      'Rayyan',
      'Kamal',
      'Adnan',
    ];
    final nQueued = ZyraEntitlements.devClamp(
      s.queuedJourneys,
      limits.potential,
    );
    for (var i = 0; i < nQueued; i++) {
      if (i >= queuedNames.length) break;
      out.add(
        make(
          'dev-q$i',
          queuedNames[i],
          26 + i,
          'potential',
          inAnotherJourney: i < s._busyPotential,
        ),
      );
    }

    // SIMULATION ONLY — the two counts are now INDEPENDENT.
    //
    // In production, paused is a subset of active: suspend_journey() sets
    // suspended_by and leaves the status 'active', and a unique index allows
    // one active Journey per person. The panel used to enforce that, which
    // meant previewing a paused layout required creating an active Journey
    // and pausing it first.
    //
    // Here `activeJourneys` means extra RUNNING previews and
    // `pausedJourneys` means extra PAUSED previews. Every preview is isMock
    // and never reaches the database; real rows above remain untouched.
    //
    // 2026-08-09: the counts are CLAMPED TO THE CURRENT PLAN by the same
    // helper the panel's segments use, so switching ZYRA One -> Basic with
    // Paused at 8 shows Basic's 5 in both places. Without a shared clamp
    // the row and the list drift apart on a plan switch, and the panel
    // stops being the source of truth it claims to be.
    const activeNames = ['Amina', 'Sara', 'Zaynab', 'Maryam', 'Khadija'];
    const pausedNames = [
      'Fatima',
      'Aisha',
      'Safiya',
      'Halima',
      'Nadia',
      'Rabia',
      'Sumaya',
      'Zahra',
      'Iman',
      'Noor',
    ];
    // Active previews exist only as a defensive bridge for an old hot-reload
    // session or a preview Potential card promoted locally. The clean panel
    // never exposes an Active count: its Journey action finds/seeds a real
    // match. Connections also converts any surviving Active preview into a
    // real walkable Journey when entered.
    final nActive = ZyraEntitlements.devClamp(s.activeJourneys, limits.active);
    for (var i = 0; i < nActive; i++) {
      if (i >= activeNames.length) break;
      out.add(
        make(
          'dev-a$i',
          activeNames[i],
          27 + i,
          'active',
          stage: 'conversation',
        ),
      );
    }
    final nPaused = ZyraEntitlements.devClamp(s.pausedJourneys, limits.paused);
    for (var i = 0; i < nPaused; i++) {
      if (i < pausedNames.length) {
        final fakeId = 'dev-p$i';
        final f = i;
        out.add(
          make(
            fakeId,
            pausedNames[f],
            26 + i,
            'active',
            stage: 'conversation',
            // The first N are paused BY THE TESTER (panel's "Paused by
            // you" count) — their rows read "Paused by you" and offer
            // Resume; the rest stay paused by the other side.
            suspendedBy: f < s._pausedByYou ? me : 'dev-other',
            // DR-ZYRA-170: the tester's mirrored holds sit on the first
            // paused-by-other fakes — "Paused by both of you".
            alsoPausedBy:
                (f >= s._pausedByYou && f < s._pausedByYou + s._mirroredPaused)
                ? me
                : null,
            inAnotherJourney: f < s._busyPaused,
            // A stand-in the tester already nudged stays nudged across
            // recomposes — the ids are deterministic, so the set in the
            // scenario is enough for the row to grey like a real one.
            pauseNudgedAt: s._nudgedFakes.contains(fakeId) ? now : null,
            // The FIRST stand-in carries a 95-day-old pause so the
            // time-honesty line ("Paused · 3 months", DR-ZYRA-142) is
            // previewable solo; the rest are fresh pauses with no line.
            suspendedAt: i == 0
                ? now.subtract(const Duration(days: 95))
                : now.subtract(const Duration(days: 3)),
          ),
        );
      }
    }

    const endedNames = [
      'Layla',
      'Hafsa',
      'Ruqayya',
      'Asma',
      'Juwayriya',
      'Umm Kulthum',
      'Zaynab bint Ali',
      'Ramla',
      'Barira',
      'Nusayba',
    ];
    final nEnded = ZyraEntitlements.devClamp(s.endedJourneys, limits.ended);
    for (var i = 0; i < nEnded; i++) {
      if (i < endedNames.length) {
        final f = i;
        out.add(
          make(
            'dev-e$i',
            endedNames[f],
            25 + i,
            'ended',
            endedAt: now.subtract(Duration(days: 2 + i)),
            inAnotherJourney: f < s._busyEnded,
          ),
        );
      }
    }

    return out;
  }

  /// True when any Journey row is above zero — used to skip the candidate
  /// pool fetch when nothing would be drawn from it.
  bool get anyJourneysStaged =>
      _queuedJourneys > 0 ||
      _activeJourneys > 0 ||
      _pausedJourneys > 0 ||
      _endedJourneys > 0;

  // journeysOverridden and holdsRealActiveJourneys REMOVED 2026-08-12: in
  // dev builds composeJourneys() is now the only source of the Connections
  // list, so there is no longer an "overridden vs real" fork for either
  // getter to arbitrate. The rows are always in charge; release builds
  // never call any of this.

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
  static List<({String from, String relationship, int daysAgo})> fakeReceived(
    int count,
  ) {
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
          token: 'DEV${(i + 1) * 11117 % 100000}'
              .padRight(8, 'X')
              .substring(0, 8),
          label: fakePendingInvites[i].label,
          createdAt: now.subtract(
            Duration(days: 7 - fakePendingInvites[i].daysLeft),
          ),
          expiresAt: now.add(Duration(days: fakePendingInvites[i].daysLeft)),
        ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════
  // — Wali side — DR-ZYRA-152, 2026-08-13
  // ═══════════════════════════════════════════════════════════════════
  //
  // Same rule as everything above: A TOGGLE MUST CHANGE SOMETHING REAL,
  // and every field here names its reader.
  //
  // TWO CONTROLS THE BRIEF ASKED FOR ARE DELIBERATELY ABSENT, because a
  // field nothing renders is the exact failure this file's header rule
  // exists to prevent. Both appear in the panel as REFUSED rows pointing
  // at Developer Access, rather than as steppers writing into nothing:
  //
  //   Invitations received  `wali_invites` has no recipient column. An
  //                         invite is a bearer code typed into
  //                         accept_wali_invite_screen — there is no list
  //                         to stage, and no screen that renders one.
  //                         (Same limit the Seeker panel records against
  //                         its own receivedInviteCount, which survives
  //                         only because seeker_wali_tab draws a PREVIEW
  //                         section for it. No Guardian equivalent exists.)
  //   Introductions sent    ZyraGuardianSuggestionService.fetchPending()
  //                         reads suggestions FOR a Seeker; both of its
  //                         callers are Seeker screens. Nothing on the
  //                         Guardian side shows what this Guardian put
  //                         forward, so there is nothing to top up.
  //
  // Readers for what IS here:
  //   waliLinkedSeekers  → composeWaliWards() → WaliSeekersScreen,
  //                        WaliDashboardScreen
  //   active/stage/      → composeWaliJourneys() → WaliDashboardScreen,
  //   paused/ended         WaliJourneyDetailScreen
  //   reviewWaiting      → waliOpenReviewIds() → Dashboard badge;
  //                        waliStagedReview() → detail screen
  //   waliRole           → gates BOTH of the above, and is the reason the
  //                        refusal path came back (see [WaliRole])
  //   sentInvites        → composeWaliSentInvites() →
  //                        WaliInviteSeekerScreen
  //   waliUnread         → WaliHomeShell's Notifications tab badge

  /// Where the Guardian currently is. Context, not scenario — reset()
  /// leaves it alone, exactly as it leaves [currentPage] alone.
  WaliPage currentWaliPage = WaliPage.dashboard;

  void setCurrentWaliPage(WaliPage page) {
    if (currentWaliPage == page) return;
    currentWaliPage = page;
    notifyListeners();
  }

  /// Main or Additional. Defaults to Main because that is the role the
  /// Guardian flows were built for and the one a fresh link receives —
  /// `wali_links.is_main` auto-designates the first active link.
  WaliRole _waliRole = WaliRole.main;
  WaliRole get waliRole => _waliRole;
  bool get waliIsMain => _waliRole == WaliRole.main;

  void setWaliRole(WaliRole r) {
    if (_waliRole == r) return;
    _waliRole = r;
    notifyListeners();
  }

  /// Seekers under this Guardian. Real links first, stand-ins topping up.
  // Staged Browse-activity counts for the Dashboard's ward chips —
  // DR-ZYRA-171. STAGED ONLY, by design: a ward's Saved/Considered/
  // Declined lists have no Guardian read path in RLS today, so these
  // numbers exist purely so the Founder can review the design. The real
  // read is its own privacy decision, raised in the register.
  // ── THE JOURNEY EXPERIENCE LAB — DR-ZYRA-172 ─────────────────────
  // Which of the five candidate first-page experiences the Journey's
  // Compatibility Reveal wears. 0 = today's build; 1-5 per
  // JourneyExperienceLab.labels (Path · Chamber · Ascent · Ritual ·
  // Table). Chrome around the REAL view — never a mock of it.
  int _journeyExperience = 0;
  int get journeyExperience => _journeyExperience;

  void setJourneyExperience(int v) {
    final n = v.clamp(0, 5);
    if (_journeyExperience == n) return;
    _journeyExperience = n;
    notifyListeners();
  }

  int _wardSaved = 0;
  int get wardSaved => _wardSaved;
  void setWardSaved(int v) {
    final n = v.clamp(0, 99);
    if (_wardSaved == n) return;
    _wardSaved = n;
    notifyListeners();
  }

  int _wardConsidered = 0;
  int get wardConsidered => _wardConsidered;
  void setWardConsidered(int v) {
    final n = v.clamp(0, 99);
    if (_wardConsidered == n) return;
    _wardConsidered = n;
    notifyListeners();
  }

  int _wardDeclined = 0;
  int get wardDeclined => _wardDeclined;
  void setWardDeclined(int v) {
    final n = v.clamp(0, 99);
    if (_wardDeclined == n) return;
    _wardDeclined = n;
    notifyListeners();
  }

  int _waliLinkedSeekers = 0;
  int get waliLinkedSeekers => _waliLinkedSeekers;
  void setWaliLinkedSeekers(int v) {
    final n = v.clamp(0, fakeWards.length);
    if (_waliLinkedSeekers == n) return;
    _waliLinkedSeekers = n;
    notifyListeners();
  }

  /// Journeys belonging to those Seekers.
  ///
  /// ACTIVE + PAUSED IS CAPPED BY THE WARD COUNT, not by a number chosen
  /// here: one Active Journey per Seeker is the platform invariant
  /// (UNIQUE partial indexes on matches.seeker_a_id / seeker_b_id WHERE
  /// status = 'active'), and pausing sets suspended_by while leaving the
  /// status 'active' — the same slot. Two Journeys for one ward is a
  /// picture of something the database refuses. Ended rows are history,
  /// not slots, so they are not capped against it.
  int _waliActiveJourneys = 0;
  int _waliPausedJourneys = 0;
  int _waliEndedJourneys = 0;

  int get waliActiveJourneys => _waliActiveJourneys;
  int get waliPausedJourneys => _waliPausedJourneys;
  int get waliEndedJourneys => _waliEndedJourneys;

  void setWaliActiveJourneys(int v) {
    final n = v.clamp(0, _waliLinkedSeekers);
    if (_waliActiveJourneys == n) return;
    _waliActiveJourneys = n;
    notifyListeners();
  }

  void setWaliPausedJourneys(int v) {
    final n = v.clamp(0, _waliLinkedSeekers);
    if (_waliPausedJourneys == n) return;
    _waliPausedJourneys = n;
    notifyListeners();
  }

  void setWaliEndedJourneys(int v) {
    final n = v.clamp(0, _waliPartners.length);
    if (_waliEndedJourneys == n) return;
    _waliEndedJourneys = n;
    notifyListeners();
  }

  /// Which stage the staged Active Journeys sit at — an INDEX into
  /// [ZyraJourneyStages.all], never a stage name written here. That map
  /// is the only one (DR-ZYRA-129); this stores a position in it so a
  /// renamed label reaches the panel without a second edit.
  int _waliStageIndex = 0;
  int get waliStageIndex => _waliStageIndex;
  ZyraJourneyStage get waliStage =>
      ZyraJourneyStages.all[_waliStageIndex.clamp(
        0,
        ZyraJourneyStages.all.length - 1,
      )];

  void setWaliStageIndex(int v) {
    final n = v.clamp(0, ZyraJourneyStages.all.length - 1);
    if (_waliStageIndex == n) return;
    _waliStageIndex = n;
    notifyListeners();
  }

  /// A Family Review waiting on THIS Guardian — the one thing on the
  /// Guardian's dashboard that is genuinely blocked on them.
  ///
  /// Main Guardians only, and that is not a panel rule: wali_review_
  /// decision() checks the caller is an active MAIN Wali for one of the
  /// two Seekers, so an Additional Guardian has no vote to cast.
  bool _waliReviewWaiting = false;
  bool get waliReviewWaiting => _waliReviewWaiting && waliIsMain;

  void setWaliReviewWaiting(bool v) {
    if (_waliReviewWaiting == v) return;
    _waliReviewWaiting = v;
    // A fresh review has not been answered. Without this, turning the
    // toggle off and on again would restore a review that still
    // remembered last round's decision.
    _waliReviewDecision = null;
    notifyListeners();
  }

  /// What this Guardian chose on the staged review — 'continue' or
  /// 'pause', null until they act.
  ///
  /// THIS IS THE POINT OF THE SECTION. The panel's rule is that a dev
  /// snackbar where the product would act is the panel lying about the
  /// experience, so the stand-in Continue / Pause buttons write here and
  /// the screen re-reads it, greying the buttons and showing "You chose
  /// Continue — waiting on the other family" exactly as a real vote does.
  String? _waliReviewDecision;
  String? get waliReviewDecision => _waliReviewDecision;

  void setWaliReviewDecision(String? d) {
    if (_waliReviewDecision == d) return;
    _waliReviewDecision = d;
    notifyListeners();
  }

  /// Invite codes this Guardian has sent and nobody has redeemed.
  int _waliSentInvites = 0;
  int get waliSentInvites => _waliSentInvites;
  void setWaliSentInvites(int v) {
    final n = v.clamp(0, fakeWaliInvites.length);
    if (_waliSentInvites == n) return;
    _waliSentInvites = n;
    notifyListeners();
  }

  /// Unread notifications on the Guardian's Notifications tab badge.
  ///
  /// THE BELL IS A TAB, not the top-right overlay it was: WaliHomeShell
  /// dropped the floating Bell on 2026-08-13 and the unread count now
  /// feeds FloatingNavItem.badge. This overrides that count when above
  /// zero, so the badge's own layout (1, 9, 10+) is reachable without
  /// generating ten real notifications.
  int _waliUnread = 0;
  int get waliUnread => _waliUnread;
  void setWaliUnread(int v) {
    final n = v.clamp(0, 12);
    if (_waliUnread == n) return;
    _waliUnread = n;
    notifyListeners();
  }

  /// True when any Guardian-side row is above zero — lets a screen skip
  /// composition entirely when the panel is at rest.
  bool get anyWaliStaged =>
      _waliLinkedSeekers > 0 ||
      _waliActiveJourneys > 0 ||
      _waliPausedJourneys > 0 ||
      _waliEndedJourneys > 0 ||
      _waliSentInvites > 0 ||
      _waliUnread > 0 ||
      _waliReviewWaiting;

  /// The Guardian's stand-in wards. Deterministic, so a Journey staged
  /// against `dev-ws1` is still against `dev-ws1` after a recompose.
  ///
  /// Relationships are the STORED CODES, matching fakeGuardians above —
  /// dev data and production data go through the same label lookup, which
  /// is how the 'Paternal uncle' casing bug hid for a week.
  static const List<({String name, String relationship})> fakeWards = [
    (name: 'Aaliyah', relationship: 'father'),
    (name: 'Umar', relationship: 'uncle'),
    (name: 'Sumayyah', relationship: 'brother'),
  ];

  /// Counterparts, in the shape zyra_counterpart_card() actually returns:
  /// first name and age, nothing else.
  ///
  /// `city` '—', `photos` empty and `gender` '' are NOT laziness here, and
  /// this is the one place a stand-in is more honest with an empty photo
  /// list than with a borrowed real profile: a Guardian is not shown the
  /// other family's photos, city or gender at all (clause 3, closed
  /// 2026-08-08). Borrowing a real profile the way composeJourneys does
  /// for the Seeker would preview a disclosure that does not happen.
  static const List<({String name, int age, String? guardian, String? surname})>
  _waliPartners = [
    (name: 'Bilal', age: 29, guardian: 'Ismail', surname: 'family of Khan'),
    (name: 'Khadija', age: 26, guardian: 'Nuh', surname: 'family of Patel'),
    (name: 'Yusuf', age: 31, guardian: null, surname: null),
    (name: 'Safiya', age: 27, guardian: 'Adnan', surname: 'family of Malik'),
    (name: 'Idris', age: 33, guardian: 'Tariq', surname: 'family of Sheikh'),
  ];

  /// Labels for staged sent invites. One is null on purpose — an invite
  /// with no label is the common case and renders as the raw token, which
  /// is the outcome the label exists to avoid.
  static const List<({String? label, int daysLeft})> fakeWaliInvites = [
    (label: 'Aaliyah', daysLeft: 6),
    (label: null, daysLeft: 4),
    (label: 'My nephew', daysLeft: 2),
    (label: 'Cousin Idris', daysLeft: 0),
  ];

  /// Seekers under this Guardian — REAL LINKS FIRST, stand-ins topping up.
  ///
  /// Real-first for the same reason composeJourneys is: a fabricated ward
  /// cannot be tested with. Its id is not a uuid, so every Guardian action
  /// that reaches the server against it is handed something that is not a
  /// row. Slot 0 is the genuine link when one exists.
  ///
  /// 0 MEANS ZERO, real links included — the panel is the source of truth
  /// while it is driving, which is what makes Reset mean reset.
  static List<WaliLinkedPerson> composeWaliWards({
    List<WaliLinkedPerson> real = const [],
  }) {
    final s = ZyraDevScenario.instance;
    final out = <WaliLinkedPerson>[];
    for (var i = 0; i < s._waliLinkedSeekers; i++) {
      if (i < real.length) {
        out.add(real[i]);
      } else {
        final f = i - real.length;
        if (f >= fakeWards.length) break;
        out.add(
          WaliLinkedPerson(
            id: 'dev-ws$i',
            firstName: fakeWards[f].name,
            // A Seeker has exactly one Main Guardian, and this Guardian is
            // either it or not — the role is a property of the LINK, so
            // every staged ward agrees with the role segment.
            isMain: s.waliIsMain,
            relationship: fakeWards[f].relationship,
          ),
        );
      }
    }
    return out;
  }

  /// Journeys for the staged wards, in the shape the Guardian screens read.
  ///
  /// AN ADDITIONAL GUARDIAN GETS NOTHING, and that is measured behaviour
  /// rather than a decision taken here. ZyraWaliJourneyService.
  /// fetchLinkedJourneys() builds every row through
  /// zyra_counterpart_card(), which returns null to anyone who is not the
  /// Journey's MAIN Guardian, and the loop then `continue`s. So today an
  /// Additional Guardian's Dashboard is empty of Journeys entirely.
  ///
  /// (wali_dashboard_screen's own comment says an Additional Guardian
  /// "sees the plain stage", which was true before the counterpart card
  /// landed on 2026-08-08 and has been stale since. Raised, not silently
  /// fixed — see DR-ZYRA-152.)
  static List<WaliJourneyView> composeWaliJourneys({
    required List<WaliLinkedPerson> wards,
    List<WaliJourneyView> real = const [],
  }) {
    final s = ZyraDevScenario.instance;
    if (!s.waliIsMain) return const [];

    final realActive = [
      for (final j in real)
        if (j.status != 'ended' && !j.isSuspended) j,
    ];
    final realPaused = [
      for (final j in real)
        if (j.status != 'ended' && j.isSuspended) j,
    ];
    final realEnded = [
      for (final j in real)
        if (j.status == 'ended') j,
    ];

    // One Active Journey per Seeker — see the field comment. Paused takes
    // what Active left, so the two can never claim the same ward.
    final slots = wards.length;
    final nActive = s._waliActiveJourneys.clamp(0, slots);
    final nPaused = s._waliPausedJourneys.clamp(0, slots - nActive);
    final nEnded = s._waliEndedJourneys.clamp(0, _waliPartners.length);

    final out = <WaliJourneyView>[];
    var partner = 0;

    WaliJourneyView make(
      String id,
      WaliLinkedPerson ward,
      String status, {
      String? stage,
      String? suspendedBy,
    }) {
      final p = _waliPartners[partner++ % _waliPartners.length];
      return WaliJourneyView(
        matchId: id,
        linkedSeekerId: ward.id,
        linkedSeekerName: ward.firstName,
        partner: SeekerProfile(
          id: 'dev-wp$id',
          firstName: p.name,
          age: p.age,
          city: '—', // withheld by the card, not missing
          photos: const [], // withheld by the card, not missing
          gender: '', // not disclosed to Guardians
        ),
        counterpartGuardianName: p.guardian,
        counterpartGuardianSurname: p.surname,
        status: status,
        journeyStage: stage,
        suspendedBy: suspendedBy,
        isMock: true,
      );
    }

    final stageValue = s.waliStage.value;

    for (var i = 0; i < nActive; i++) {
      if (i < realActive.length) {
        out.add(realActive[i]);
      } else if (i < wards.length) {
        out.add(make('dev-wj$i', wards[i], 'active', stage: stageValue));
      }
    }
    for (var i = 0; i < nPaused; i++) {
      final wardIndex = nActive + i;
      if (i < realPaused.length) {
        out.add(realPaused[i]);
      } else if (wardIndex < wards.length) {
        out.add(
          make(
            'dev-wp$i',
            wards[wardIndex],
            'active',
            stage: stageValue,
            // Paused BY THE OTHER FAMILY. A Guardian cannot pause a
            // Journey — suspend_journey() is a Seeker capability — so
            // staging one paused "by you" would preview a control this
            // role does not have.
            suspendedBy: 'dev-other',
          ),
        );
      }
    }
    for (var i = 0; i < nEnded; i++) {
      if (i < realEnded.length) {
        out.add(realEnded[i]);
      } else if (wards.isNotEmpty) {
        // Ended Journeys are history, so they reuse wards freely — the
        // same Seeker having ended one Journey and started another is
        // the ordinary case, not an edge one.
        out.add(make('dev-we$i', wards[i % wards.length], 'ended'));
      }
    }
    // No endedAt is stamped: WaliJourneyView carries no timestamp, and a
    // Guardian's Journey list shows "Journey ended" with no cooling
    // period behind it. Nothing to fabricate here.
    return out;
  }

  /// Journeys the Dashboard should badge as having a Family Review open.
  ///
  /// STAND-INS ONLY. Staging a review against a REAL matchId would put a
  /// Continue button on screen that then calls wali_review_decision()
  /// with an id the server has no review row for — the panel showing a
  /// decision that cannot be taken.
  static Set<String> waliOpenReviewIds(List<WaliJourneyView> journeys) {
    final s = ZyraDevScenario.instance;
    if (!s.waliReviewWaiting) return const {};
    return {
      for (final j in journeys)
        if (j.isMock && j.status != 'ended' && !j.isSuspended) j.matchId,
    };
  }

  /// The staged Family Review, in the record shape
  /// wali_journey_detail_screen already renders. Null is the same "no
  /// review" the real fetch returns, so the screen needs no new branch.
  ///
  /// `toStage` is the NEXT stage in the canonical sequence, derived from
  /// the one map rather than named here — a review is the gate BETWEEN
  /// two stages, so the stage it leads to cannot be invented separately.
  static ({String id, String status, String toStage, DateTime deadlineAt})?
  waliStagedReview() {
    final s = ZyraDevScenario.instance;
    if (!s.waliReviewWaiting) return null;
    final i = s._waliStageIndex;
    final next = i + 1 < ZyraJourneyStages.all.length
        ? ZyraJourneyStages.all[i + 1].value
        // Open Conversation is terminal — there is no stage after it and
        // therefore no review that could gate one. Falling back to the
        // current stage keeps the record well-formed; the panel refuses
        // the toggle there instead of relying on this.
        : ZyraJourneyStages.all[i].value;
    return (
      id: 'dev-review-0',
      status: 'pending',
      toStage: next,
      // Inside the 48h window and not a round number, so the countdown
      // renders as "41h 12m" rather than something that reads as a
      // placeholder.
      deadlineAt: DateTime.now().add(const Duration(hours: 41, minutes: 12)),
    );
  }

  /// Invite codes this Guardian has sent — real rows first, stand-ins
  /// topping up, same rule as everywhere else.
  static List<PendingInvite> composeWaliSentInvites({
    List<PendingInvite> real = const [],
  }) {
    final s = ZyraDevScenario.instance;
    final now = DateTime.now();
    final out = <PendingInvite>[];
    for (var i = 0; i < s._waliSentInvites; i++) {
      if (i < real.length) {
        out.add(real[i]);
      } else {
        final f = i - real.length;
        if (f >= fakeWaliInvites.length) break;
        out.add(
          PendingInvite(
            token: 'DEVW${(f + 1) * 7919 % 10000}'
                .padRight(8, 'X')
                .substring(0, 8),
            label: fakeWaliInvites[f].label,
            createdAt: now.subtract(
              Duration(days: 7 - fakeWaliInvites[f].daysLeft),
            ),
            expiresAt: now.add(Duration(days: fakeWaliInvites[f].daysLeft)),
          ),
        );
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------

  // set_() REMOVED 2026-08-12. It ran an arbitrary closure and notified,
  // which meant state could change without this class knowing WHICH state —
  // the reason reset() drifted out of step with the fields (adsOnEveryProfile
  // was resettable by nothing). Every mutation now goes through a named,
  // guarded setter above.

  /// Everything simulated, back to zero, in one notify. "Zero means zero.
  /// Every time." (Founder, 2026-08-12.)
  ///
  /// Enumerates EVERY simulated axis — when a field is added to this class,
  /// it is added here in the same change or the panel's Reset silently lies,
  /// which is the failure this file's header rule exists to prevent.
  /// `currentPage` is deliberately untouched: it records where the user IS,
  /// not a simulation. Server-backed dev state (credits, Introductions,
  /// Guardians-on-decided, the plan row) is the panel's reset flow to clear —
  /// it lives in the database, not here.
  void reset() {
    pendingPopup = null;
    _adsOnEveryProfile = false;
    _useLiveGuardianData = false;
    _mainGuardian = false;
    _additionalGuardianCount = 0;
    _pendingInviteCount = 0;
    _receivedInviteCount = 0;
    _queuedJourneys = 0;
    _activeJourneys = 0;
    _pausedJourneys = 0;
    _endedJourneys = 0;
    _nudgedFakes.clear();
    _busyPotential = 0;
    _busyPaused = 0;
    _busyEnded = 0;
    _pausedByYou = 0;
    _mirroredPaused = 0;
    // — Wali side — DR-ZYRA-152. Enumerated here in the same change that
    // added them, per this method's own rule. `currentWaliPage` is
    // deliberately absent for the same reason `currentPage` is: it
    // records where the Guardian IS, not a simulation.
    _journeyExperience = 0;
    _wardSaved = 0;
    _wardConsidered = 0;
    _wardDeclined = 0;
    _waliRole = WaliRole.main;
    _waliLinkedSeekers = 0;
    _waliActiveJourneys = 0;
    _waliPausedJourneys = 0;
    _waliEndedJourneys = 0;
    _waliStageIndex = 0;
    _waliReviewWaiting = false;
    _waliReviewDecision = null;
    _waliSentInvites = 0;
    _waliUnread = 0;
    notifyListeners();
  }
}
