// Developer scenario panel — a pull-out tab on the right edge.
//
// Founder, 2026-08-01: "make a toggle side button where I can select the
// options to see how it works."
//
// Mounted once in HomeShell's Stack, above the nav bar. Collapsed it is a
// 22pt tab; expanded it is a grouped list of controls that take effect on
// the live screen behind it.
//
// GROUPED AND CONTEXT-GATED — 2026-08-03 (Founder: "let it only work on
// the correct page and correct user... if I try click it on a wrong area
// or wrong profile I need a red animation to show it can't... maybe even
// start grouping the toggle section so it's easier for me to see").
//
// Each control declares the plans it applies to and the page it affects.
// Two things follow:
//
//   GROUPING   Controls are listed under the audience they belong to, so
//              "which of these apply to a Basic Seeker" is answered by
//              looking rather than by remembering.
//   REFUSAL    Out of context, a control is dimmed and shakes red when
//              tapped instead of silently accepting the change.
//
// The refusal is the important half. "Consider limit reached" on ZYRA One
// used to flip happily and then do nothing, because Considers are
// unlimited there and the modal it simulates cannot fire. A switch that
// moves and achieves nothing reads as a broken feature; one that refuses
// and says why reads as a rule.
//
// RELEASE SAFETY — double-guarded, per the 2026-07-26 audit finding that
// Developer Access shipped reachable in a release build:
//   1. HomeShell only builds it when !kReleaseMode.
//   2. build() returns SizedBox.shrink() in a release build regardless.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

import '../data/zyra_entitlements.dart';
import '../main.dart';
// The entitlement caps Browse actually enforces, so the panel's hints
// cannot drift from the product. Made public 2026-08-07 for this — they
// changed twice in a week (5/15 → 10/50) and a hint quoting the old number
// is a confident wrong answer, which is how a debug panel stops being
// trusted. Same `show` pattern settings_screen uses for ZyraCardMetrics.
import '../screens/browse/browse_screen.dart'
    show zyraBasicSaveLimit, zyraBasicConsiderLimit, zyraOneSaveLimit;
import '../screens/welcome_screen.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_guardian_suggestion_service.dart';
import '../services/zyra_journey_service.dart';
import '../services/zyra_unlock_service.dart';
import '../state/app_state.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_glass_dialog.dart';
import 'zyra_dev_scenario.dart';
import 'zyra_dev_signup.dart';

class DevScenarioPanel extends StatefulWidget {
  const DevScenarioPanel({super.key});

  @override
  State<DevScenarioPanel> createState() => _DevScenarioPanelState();
}

class _DevScenarioPanelState extends State<DevScenarioPanel> {
  bool _open = false;

  static const double _panelWidth = 286;
  static const double _tabWidth = 22;

  /// Gives every profile this account has Considered, Saved or Passed
  /// exactly [count] Guardians, from the fixed dev pool (Abdul, Hassan,
  /// Tariq). Founder request, 2026-08-05 — the Compatibility Unlock+
  /// Guardian section could not otherwise be seen at 1, 2 or 3, and 0 is a
  /// real state too ("No Guardian linked.").
  ///
  /// Real Guardian links made through an invite are never touched; the
  /// function only clears links belonging to the pool.
  Future<void> _setGuardiansOnDecided(int count) async {
    try {
      final res = await supabase
          .rpc('zyra_dev_set_guardians_on_decided', params: {'p_count': count});
      final m = (res as Map?)?.cast<String, dynamic>();
      final targets = (m?['targets'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(targets == 0
            ? 'Nobody decided on yet — Consider, Save or Pass someone first. (dev)'
            : count == 0
                ? 'Cleared Guardians on $targets profile${targets == 1 ? "" : "s"}. '
                    'Unlock+ now shows "No Guardian linked." (dev)'
                : 'Gave $count Guardian${count == 1 ? "" : "s"} to $targets '
                    'profile${targets == 1 ? "" : "s"}. Reopen a Compatibility page to see it. (dev)'),
      ));
    } catch (e) {
      debugPrint('ZYRA dev: set guardians failed — $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e'.contains('dev_accounts_only')
            ? 'Refused — Guardian scenarios are limited to @zyra.test accounts. (dev)'
            : "That didn't go through (see console). (dev)"),
      ));
    }
  }

  /// Puts [count] profiles into Connections › Introductions, as
  /// though this Seeker's Guardian had suggested them. Founder request,
  /// 2026-08-05. The Guardian-side UI to create one for real is unbuilt, so
  /// without this the section can only ever be empty.
  Future<void> _setGuardianSuggestions(int count) async {
    try {
      final res = await supabase
          .rpc('zyra_dev_set_guardian_suggestions', params: {'p_count': count});
      final created = ((res as Map?)?['created'] as num?)?.toInt() ?? 0;
      AppState.instance.bumpSuggestions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(count == 0
            ? 'Cleared Introductions. (dev)'
            : created == 0
                ? 'No eligible profiles to suggest — needs browsable Seekers of the opposite gender. (dev)'
                : 'Added $created Introduction${created == 1 ? "" : "s"}. '
                    'Open Connections › Introductions. (dev)'),
      ));
    } catch (e) {
      debugPrint('ZYRA dev: set guardian suggestions failed — $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e'.contains('dev_accounts_only')
            ? 'Refused — Guardian scenarios are limited to @zyra.test accounts. (dev)'
            : "That didn't go through (see console). (dev)"),
      ));
    }
  }

  /// Starts the REAL onboarding flow from a blank slate.
  ///
  /// The behaviour lives in ZyraDevSignUp.start(), shared with Developer
  /// Access. It was implemented here alone on 2026-08-07 and that was
  /// wrong: this panel is mounted only in HomeShell, so moving the entry
  /// point here made "test signing up as a new user" unreachable from the
  /// signed-out state where you would actually start. See that file.
  ///
  /// Closes the panel first — otherwise the pull-out sits over the flow it
  /// just launched, which is how the Home button ended up covering the
  /// Connections title for a week.
  void _startSignUp({required bool isWali}) {
    setState(() => _open = false);
    ZyraDevSignUp.start(context, isWali: isWali);
  }

  /// Grants real credits through the ledger, then says what happened.
  /// Refused server-side for anything that is not a @zyra.test account.
  Future<void> _grantCredits(UnlockTier tier, int count) async {
    final ok = await ZyraUnlockService.debugGrant(tier, count);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Granted $count ${tier == UnlockTier.plus ? "Unlock+" : "Unlock"} '
              'credit${count == 1 ? "" : "s"}. Reopen the Compatibility page to see it. (dev)'
          : 'Refused — credit grants are limited to @zyra.test accounts. (dev)'),
    ));
  }

  /// FULL RESET of this account's state — Founder, 2026-08-04: "I need a
  /// profile reset button in toggle since I can't reset all things".
  ///
  /// The existing "Reset" beside SCENARIOS only clears the panel's own
  /// in-memory flags. It never touched the database, so a testing session
  /// accumulated saves, passes, unlocks and spent credits with no way back
  /// short of a new account.
  ///
  /// Clears, for the signed-in user only:
  ///   saves · likes · passes   every Browse/Connections decision
  ///   profile_unlocks          so profiles re-lock and can be bought again
  ///   unlock_credits           back to a zero balance
  ///
  /// Deliberately does NOT touch: the profile row, photos, Chapter 2
  /// answers, consent records or Guardian links. Those take real effort to
  /// set up, and a reset that destroyed them would make the button too
  /// dangerous to press — which is how you end up back with no reset at all.
  Future<void> _resetProfileState() async {
    // Uses the app's own glass dialog rather than Flutter's stock
    // AlertDialog on a flat purple, which is what this was first written
    // with. It never ships, but a debug surface that looks nothing like the
    // product is a debug surface you stop trusting your eyes on.
    final confirmed = await showZyraGlassChoice(
      context: context,
      icon: Icons.restart_alt,
      title: 'Reset this account?',
      // ── 2026-08-11, SECOND PASS. Founder: "the reset account isn't quite
      // right, why cos when i pressed reset it started with send salam not
      // started with start journey again."
      //
      // My first answer was to leave this button alone and add a separate one
      // inside the Journey. That was the wrong call: he pressed RESET, and a
      // button called Reset that leaves you halfway through a Journey has not
      // reset anything he can see. The old note said matches were too
      // expensive to destroy — still true, and still respected: the match,
      // the Guardian link and how you met all survive. What goes is what the
      // two of them DID.
      body: 'Clears every Save, Consider, Pass, unlock and credit, and puts '
          'every Journey back to its first stage — answers, ratings, Salams, '
          'reveals and messages cleared.\n\nKeeps your profile, photos, '
          'Chapter 2 answers, consent, Guardians, your matches and how you '
          'met them.',
      primaryLabel: 'Reset',
      secondaryLabel: 'Cancel',
    );
    if (confirmed != true || !mounted) return;

    if (ZyraAuth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in — nothing on the server to reset. (dev)')),
      );
      return;
    }

    // REWRITTEN 2026-08-05 (Fable). This was five client-side deletes with
    // hand-written column names, three of which used `seeker_id` — a column
    // that exists on none of saves/likes/passes (they use saver_id, liker_id
    // and passer_id). Every one failed, and profile_unlocks failed too
    // because `authenticated` correctly lost DELETE on it when the
    // free-unlock hole was closed. Hence the recurring "Partially reset —
    // these failed: saves likes passes profile_unlocks".
    //
    // It is now one SECURITY DEFINER call — zyra_dev_reset_account(), guarded
    // to @zyra.test accounts — so the column names live next to the schema
    // and the whole reset is a single transaction: it either happens or it
    // doesn't. No more partial states to reason about.
    String? error;
    Map<String, dynamic>? counts;
    try {
      final res = await supabase.rpc('zyra_dev_reset_account');
      // Two calls rather than one function, deliberately: account state and
      // Journey state are separate concerns with separate blast radii, and
      // zyra_dev_reset_account() is used elsewhere. The button composes them;
      // neither RPC grows a second job.
      await ZyraJourneyService.devRewindJourney();
      counts = (res as Map?)?.cast<String, dynamic>();
    } catch (e) {
      error = '$e';
      debugPrint('ZYRA dev reset failed — $e');
    }

    AppState.instance.clearDecisionsForReset();
    ZyraUnlockService.clearForSignOut();
    if (!mounted) return;

    final String message;
    if (error != null) {
      message = error.contains('dev_accounts_only')
          ? 'Reset is only available on the seeded @zyra.test accounts.'
          : 'Reset failed — nothing was changed (see console).';
    } else {
      final cleared = counts == null
          ? ''
          : ' Cleared ${counts.values.fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0))} rows.';
      // No longer "restart the app": clearDecisionsForReset() bumps
      // AppState.deckVersion, which Browse listens for and re-fetches on.
      message = 'Account reset.$cleared Everyone is back in Browse, and every '
          'Journey is at its first stage.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Bumped per control id when a control is used out of context. The
  /// matching _Deniable sees the change and runs its shake.
  final Map<String, int> _denied = {};

  ZyraDevScenario get _s => ZyraDevScenario.instance;

  // _refuse REMOVED 2026-08-09. It shook a segment that was over the
  // per-plan cap, back when every plan shared one row and illegal values
  // were shown dimmed. The rows are now BUILT from the plan (see _limits),
  // so an illegal value is never drawn and there is nothing to refuse.
  // flutter analyze had it as dead code.

  /// The current plan's Journey limits — the single source for every
  /// segment below. data/zyra_entitlements.dart holds the numbers.
  ZyraJourneyLimits get _limits => ZyraEntitlements.of(AppState.instance.plan);

  @override
  void initState() {
    super.initState();
    _s.addListener(_onChange);
    AppState.instance.addListener(_onChange);
    _syncIntroductionsCount();
  }

  /// Bring the Introductions segment in line with the rows that actually
  /// exist. Best-effort and silent: if it fails the panel simply shows its
  /// last value, which is no worse than the behaviour this replaces.
  Future<void> _syncIntroductionsCount() async {
    try {
      final pending = await ZyraGuardianSuggestionService.fetchPending();
      if (!mounted) return;
      final n = pending.length.clamp(0, 5);
      if (n != _guardianSuggestions) setState(() => _guardianSuggestions = n);
    } catch (_) {}
  }

  @override
  void dispose() {
    _s.removeListener(_onChange);
    AppState.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  DevPlan get _plan => AppState.instance.plan == ZyraPlan.one ? DevPlan.one : DevPlan.basic;

  /// Whether a control is shown at all.
  ///
  /// CHANGED 2026-08-07 (Founder: "make the toggle page reflect the account
  /// I'm signed in on — right now I'm on ZYRA Basic but I'm seeing ZYRA One
  /// options; put the ZYRA One toggles in when I switch account").
  ///
  /// The plan mismatch used to DIM rather than hide, on the argument that a
  /// greyed control "is telling you something true about the product". That
  /// held when there were six controls. It does not now: on Basic, four of
  /// the eleven Browse-and-Guardian controls were permanently grey, and a
  /// list where a third of the rows can never be pressed is a list you stop
  /// reading. The plan is already stated at the top of the panel by _Now,
  /// which is where that fact belongs.
  ///
  /// Both filters now hide. The panel shows what you can actually do, here,
  /// as this account — and everything reappears the moment you switch.
  bool _visible(Set<DevPlan> plans, DevPage? page) {
    if (!plans.contains(_plan)) return false;
    // page == null -> usable anywhere. See _Control.page.
    if (page != null && _s.currentPage != page) return false;
    return true;
  }

  /// Kept for the rare control that is shown-but-refused. Nothing uses it
  /// today; it stays because the _Deniable shake mechanism it feeds is
  /// still the right answer for a control that is visible and momentarily
  /// unusable, and deleting both halves would mean rebuilding them.
  String? _blockedBecause(Set<DevPlan> plans, DevPage? page) {
    if (!plans.contains(_plan)) {
      return plans.length == 1 && plans.first == DevPlan.basic
          ? 'ZYRA Basic accounts only'
          : 'ZYRA One accounts only';
    }
    if (page != null && _s.currentPage != page) {
      return 'Open ${page.label} to use this';
    }
    return null;
  }

  /// Panel-local, not persisted: these mirror server state that was just
  /// written, so the segment shows what was last chosen this session. A
  /// fresh launch reads 0, which is honest — the panel does not know the
  /// server's count without asking, and asking on open would be a network
  /// call for a cosmetic default.
  int _guardiansOnDecided = 0;
  /// How many Introductions exist — a real count, matching the segment
  /// labels 0-5.
  ///
  /// READ FROM THE SERVER ON OPEN, 2026-08-09. It used to default to 0 with
  /// the note "asking on open would be a network call for a cosmetic
  /// default". That was wrong twice over. The control writes REAL
  /// wali_suggestions rows, so after a restart the panel said 0 while
  /// Connections showed 1 — and because tapping the already-selected 0
  /// fires no change event, THE ROW COULD NOT BE CLEARED FROM THE PANEL AT
  /// ALL. Founder hit exactly that on 2026-08-09.
  ///
  /// A panel that claims to be the source of truth has to ask.
  int _guardianSuggestions = 0;

  void _deny(String id) => setState(() => _denied[id] = (_denied[id] ?? 0) + 1);

  /// Closes the panel and asks Browse to show one of ITS OWN popups.
  ///
  /// No snackbar and no invented wording (Founder, 2026-08-05: "the save
  /// limit reached message isn't the one the app uses, you just made one
  /// up"). The panel names the popup; browse_screen shows the real modal.
  /// Closing first matters — the popup appears on the screen behind this
  /// one, so leaving the panel open would hide the thing just asked for.
  void _showPopup(DevPopup popup) {
    setState(() => _open = false);
    ZyraDevScenario.instance.requestPopup(popup);
  }

  /// The small Reset beside SCENARIOS.
  ///
  /// WAS `() => _s.reset()` — panel toggles only, instant, no confirm. That
  /// is still what it does by default, and it is still the right default: the
  /// toggles are local state and clearing them should cost nothing.
  ///
  /// But it now OFFERS the Journey rewind too, because "Reset" sitting above
  /// a Journey stuck at Salam Exchange reads as a promise it was not keeping.
  /// Asked rather than assumed — this one destroys server data and the other
  /// one never has.
  Future<void> _resetScenarios() async {
    _s.reset();
    if (!mounted) return;
    final also = await showZyraGlassChoice(
      context: context,
      icon: Icons.restart_alt,
      title: 'Toggles cleared. Journeys too?',
      body: 'Every Journey on this account goes back to Compatibility Reveal, '
          'and what you both did inside it is cleared — answers, ratings, '
          'Salams, the reveal, messages.\n\nYour matches, your Guardians and '
          'how you met stay exactly as they are.',
      primaryLabel: 'Reset Journeys too',
      secondaryLabel: 'Just the toggles',
    );
    if (also != true || !mounted) return;
    try {
      final said = await ZyraJourneyService.devRewindJourney();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$said (dev)')));
    } catch (e) {
      debugPrint('ZYRA dev: rewind journeys failed - $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e'.contains('dev_only')
            ? 'Refused — rewinding Journeys is limited to @zyra.test accounts. (dev)'
            : "That didn't go through (see console). (dev)"),
      ));
    }
  }

  /// Hard reset to Welcome, clearing the whole navigation stack.
  ///
  /// Same behaviour as DevNavOverlay's old floating button — deliberately
  /// pushAndRemoveUntil rather than a pop, because popping from deep in
  /// onboarding used to leave a half-built stack behind (see
  /// dev_nav_overlay.dart's own note).
  ///
  /// Uses the app-wide navigator key, not this widget's context: the panel
  /// sits above every route, so its own context is not inside the stack it
  /// needs to clear.
  void _goHome() {
    final nav = zyraNavigatorKey.currentState;
    if (nav == null) return;
    setState(() => _open = false);
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Backstop — see the header. Not an else-branch of the mount point.
    if (kReleaseMode) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      bottom: 0,
      right: _open ? 0 : -_panelWidth,
      width: _panelWidth + _tabWidth,
      child: Row(
        children: [
          _Tab(open: _open, onTap: () => setState(() => _open = !_open)),
          Expanded(
            child: Material(
              color: const Color(0xF20E0B12),
              child: SafeArea(
                left: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  children: [
                    // HOME — MOVED HERE 2026-08-03 (Founder: "put the home
                    // button in the toggle tab at top... maybe change it
                    // from home icon to word Home, but let it sit at top
                    // of the toggle section").
                    //
                    // It was a floating circle pinned to the top-left of
                    // every screen (DevNavOverlay), which is why it has
                    // been sitting on top of the "Connections" title in
                    // every screenshot this week. Inside the panel it
                    // covers nothing and is one tap further away — the
                    // right trade for something that wipes the navigation
                    // stack.
                    //
                    // The word rather than the glyph, as asked: a house
                    // icon on a debug control could plausibly mean "go to
                    // the Home tab". It does not. It signs out to Welcome.
                    _HomeButton(onTap: _goHome),
                    const SizedBox(height: 8),
                    // ADDED 2026-08-04. Sits beside Home because both are
                    // session-level actions rather than scenario toggles —
                    // and both are destructive enough to want a moment's
                    // pause, which is why one signs out and the other asks
                    // first.
                    _ResetProfileButton(onTap: _resetProfileState),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SCENARIOS', style: ZyraText.chapterLabel(color: Colors.white70)),
                        GestureDetector(
                          onTap: _resetScenarios,
                          child: Text('Reset',
                              style: ZyraText.subtext(size: 11, color: const Color(0xFF9AD0FF))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _Now(plan: _plan, page: _s.currentPage),

                    // ── BROWSE ─────────────────────────────────────────
                    //
                    // REGROUPED 2026-08-07 (Founder: "as you can see save
                    // limit at top, then Guardian open, then consider limit
                    // — group it neater please").
                    //
                    // Save limit used to sit up here on its own, under a
                    // "ZYRA Basic and ZYRA One" heading, while the other
                    // four Browse controls sat 300 lines below under "ZYRA
                    // Basic only". Correct by plan, incoherent on screen:
                    // one Browse control, then two empty nav headings, then
                    // the rest of Browse.
                    //
                    // The plan headings are gone. They earned their place
                    // when a wrong-plan control was DIMMED and you needed
                    // to know why — now it is hidden, so a heading naming a
                    // plan sits above controls that only ever appear on
                    // that plan anyway. _Now already states which plan you
                    // are on, once, at the top.
                    //
                    // Limits first, adverts second: those are the two
                    // things Browse can do to you, and they read as two
                    // ideas rather than five buttons.
                    _NavGroup(Icons.search, 'Browse', page: DevPage.browse, state: this),
                    // A BUTTON, not a switch, since 2026-08-05 (Founder:
                    // "it's a save limit toggle — I want as buttons, so when
                    // I press the button in toggle I see the pop-up show
                    // up"). The switch only ARMED the state; the modal still
                    // needed a Save tap in Browse afterwards, so the control
                    // looked like it had done nothing.
                    _Control(
                      id: 'save_limit',
                      label: 'Save limit reached',
                      // Interpolated from the SAME constants Browse enforces,
                      // made public 2026-08-07 for exactly this. A hint that
                      // says "caps at 5" beside a product that caps at 10 is
                      // worse than no hint — it is a confident wrong answer,
                      // and that is how the panel stopped being trusted last
                      // time.
                      hint: 'Basic caps at $zyraBasicSaveLimit, ZYRA One at '
                          '$zyraOneSaveLimit — different copy each.',
                      page: DevPage.browse,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _FireButton(
                        label: 'Show save limit',
                        onFire: () => _showPopup(DevPopup.saveLimit),
                      ),
                    ),
                    _Control(
                      id: 'consider_limit',
                      label: 'Consider limit reached',
                      hint: 'Caps at $zyraBasicConsiderLimit. Unlimited on '
                          'ZYRA One, so there is nothing to simulate there.',
                      page: DevPage.browse,
                      plans: const {DevPlan.basic},
                      state: this,
                      child: _FireButton(
                        label: 'Show consider limit',
                        onFire: () => _showPopup(DevPopup.considerLimit),
                      ),
                    ),
                    _Control(
                      id: 'daily_limit',
                      label: 'Browsing limit reached',
                      hint: '50 every 4 hours on Basic. Fires on your next '
                          'profile instead of after fifty.',
                      page: DevPage.browse,
                      plans: const {DevPlan.basic},
                      state: this,
                      child: _FireButton(
                        label: 'Show browsing limit',
                        onFire: () => _showPopup(DevPopup.dailyLimit),
                      ),
                    ),

                    // Adverts. Basic only — ZYRA One is contractually
                    // ad-free, so there is nothing to simulate there and
                    // simulating it would preview a broken promise.
                    _NavGroup(Icons.campaign_outlined, 'Adverts',
                        page: DevPage.browse, state: this),
                    _Control(
                      id: 'sponsored_card',
                      label: 'Show a sponsored card',
                      hint: 'Fires on your next profile. Normally every 5.',
                      page: DevPage.browse,
                      plans: const {DevPlan.basic},
                      state: this,
                      child: _FireButton(
                        label: 'Show advert',
                        onFire: () => _showPopup(DevPopup.sponsoredCard),
                      ),
                    ),
                    _Control(
                      id: 'ads_always',
                      label: 'Advert on every profile',
                      hint: 'A preview state the product would never produce '
                          '— for judging the rhythm, not the card.',
                      page: DevPage.browse,
                      plans: const {DevPlan.basic},
                      state: this,
                      child: _Segment(
                        options: const ['Off', 'On'],
                        index: _s.adsOnEveryProfile ? 1 : 0,
                        onChanged: (i) =>
                            setState(() => _s.setAdsOnEveryProfile(i == 1)),
                      ),
                    ),
                    // REWIRED 2026-08-04. These were segmented "None / 1 / 5"
                    // controls writing an in-memory enum — which the unlock
                    // screen read, and the SERVER knew nothing about. Once
                    // C-1 moved entitlement into the `unlock_credits`
                    // ledger, the panel was setting a number that no longer
                    // had any bearing on whether an unlock would succeed:
                    // the screen said "5 left" and the RPC refused, which is
                    // exactly what the Founder hit.
                    //
                    // Now they GRANT real credits through
                    // zyra_debug_grant_credits(), refused server-side for
                    // anything that is not a @zyra.test account.
                    //
                    // "+1 / +5" not "1 / 5" because the ledger is
                    // append-only. You cannot set a balance to five; you add
                    // five. Labelling it "5" would be lying about what the
                    // button does.
                    _NavGroup(Icons.shield_outlined, 'Connections',
                        page: DevPage.connections, state: this),
                    _Control(
                      id: 'unlock',
                      label: 'Grant Compatibility Unlock credits',
                      hint: 'Adds real credits to the ledger. The number on '
                          'the screen is now the number the server enforces.',
                      page: DevPage.connections,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _GrantRow(
                        onGrant: (n) => _grantCredits(UnlockTier.standard, n),
                      ),
                    ),
                    _Control(
                      id: 'unlock_plus',
                      label: 'Grant Compatibility Unlock+ credits',
                      hint: 'ZYRA One already grants 3 automatically when the '
                          'subscription activates.',
                      page: DevPage.connections,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _GrantRow(
                        onGrant: (n) => _grantCredits(UnlockTier.plus, n),
                      ),
                    ),
                    // ORDERED AND NAMED TO MATCH THE SCREEN, 2026-08-07
                    // (Founder: "put it in order how it shows on app and
                    // change Queued to Potential like it's showing on the
                    // screen").
                    //
                    // Connections reads ACTIVE → POTENTIAL → PAUSED →
                    // ENDED, so the panel now does too. A control panel
                    // whose order and vocabulary differ from the surface it
                    // drives is one you have to translate twice — once for
                    // the name, once for the position.
                    _Control(
                      id: 'journey_active',
                      label: 'Active Journeys',
                      // 2026-08-11: the hint now says what 0 and 1 DO, because
                      // this row is the only thing standing between an empty
                      // Connections page and a testable Journey, and neither
                      // behaviour is guessable from a number.
                      hint: '0 hides your real Journey; 1 shows it — the real '
                          'match, so Reveal and the rest work. Beyond that, '
                          'stand-ins for layout only. '
                          '${_limits.active} on this plan.',
                      page: DevPage.connections,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        // SUPERSEDED the "capped at 1" note that stood here
                        // this morning. That note was right about the
                        // DATABASE and wrong about the PRODUCT, and leaving
                        // it above a 0-3 row would have been a comment
                        // arguing with its own code.
                        //
                        // ── PLAN-ADAPTIVE, 2026-08-09. Founder: "0/1/2/3 for
                        // Active Journey but for ZYRA Basic, 0/1."
                        //
                        // 🔴 THE DATABASE DOES NOT AGREE YET:
                        // zyra_enforce_one_active_match refuses any second
                        // status='active' row with no plan check, and
                        // matches_seeker_a_active / matches_seeker_b_active
                        // are unique partial indexes over every Seeker. This
                        // row shows the AGREED model; the migration is
                        // pending review.
                        options: ZyraEntitlements.devOptions(_limits.active),
                        index: ZyraEntitlements.devClamp(
                            _s.activeJourneys, _limits.active),
                        onChanged: (i) => _s.set_(() => _s.activeJourneys = i),
                      ),
                    ),

                    // RENAMED from "Queued" 2026-08-07 — the section heading
                    // says POTENTIAL JOURNEYS, and "queue" was internal
                    // vocabulary that outlived the screen it came from.
                    _Control(
                      id: 'journeys_potential',
                      label: 'Potential Journeys',
                      hint: 'A mutual match nobody has opened yet. '
                          '${_limits.potential == null ? "Unlimited" : "${_limits.potential} max"} '
                          'on this plan; row stops at '
                          '${ZyraEntitlements.devSegmentCeiling}.',
                      page: DevPage.connections,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        // Unlimited on ZYRA One, 25 on Basic — same row,
                        // because 26 segments does not fit a phone and an
                        // unlimited one has no end. 🔴 So this cannot stage
                        // Basic AT its cap of 25, which is the one state the
                        // "choose one to end" flow needs.
                        options: ZyraEntitlements.devOptions(_limits.potential),
                        index: ZyraEntitlements.devClamp(
                            _s.queuedJourneys, _limits.potential),
                        onChanged: (i) => _s.set_(() => _s.queuedJourneys = i),
                      ),
                    ),

                    _Control(
                      id: 'journey_paused',
                      label: 'Paused Journeys',
                      hint: 'Independent of the count above — pick this on '
                          'its own to jump straight to a paused layout. '
                          '${_limits.paused} max on this plan.',
                      page: DevPage.connections,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        // ── UNCAPPED FROM 1 AND MADE PLAN-ADAPTIVE, 2026-08-09.
                        // Founder: "you can have more than one paused
                        // Journey... max 5 for Basic, max 10 for ZYRA One",
                        // and a paused Journey does NOT consume an active
                        // slot. That also settles audit finding 4.1, where
                        // two CURRENT_VERSION documents disagreed on exactly
                        // this. 🔴 The database still has to catch up.
                        options: ZyraEntitlements.devOptions(_limits.paused),
                        index: ZyraEntitlements.devClamp(
                            _s.pausedJourneys, _limits.paused),
                        onChanged: (i) => _s.set_(() => _s.pausedJourneys = i),
                      ),
                    ),

                    _Control(
                      id: 'journeys_ended',
                      label: 'Ended Journeys',
                      hint: 'Ended more than 24h ago, so Restart is reachable '
                          'rather than inside the cooling period. '
                          '${_limits.ended} shown on this plan.',
                      page: DevPage.connections,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        // A DISPLAY cap, not an entitlement — Founder,
                        // 2026-08-09: "purely a UI cap... I never want
                        // Journey history deleted automatically."
                        options: ZyraEntitlements.devOptions(_limits.ended),
                        index: ZyraEntitlements.devClamp(
                            _s.endedJourneys, _limits.ended),
                        onChanged: (i) => _s.set_(() => _s.endedJourneys = i),
                      ),
                    ),

                    _NavGroup(Icons.people_outline, 'Guardian',
                        page: DevPage.guardian, state: this),

                    // THE SOURCE OF TRUTH, stated rather than inferred.
                    //
                    // ADDED 2026-08-07 (Founder: "when I'm using the Dev
                    // Panel I expect the panel to be the source of truth.
                    // If I want to test my real linked Guardians, I'd rather
                    // have a separate option such as Use Live Guardian
                    // Data").
                    //
                    // Default is PANEL, so every count below means exactly
                    // what it says and 0 means zero. Live is a deliberate
                    // opt-in with its own name on screen.
                    _Control(
                      id: 'guardian_source',
                      label: 'Guardian data',
                      hint: 'Panel — the counts below are the whole truth. '
                          'Live — read the database and ignore them.',
                      page: DevPage.guardian,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        options: const ['Panel', 'Live'],
                        index: _s.useLiveGuardianData ? 1 : 0,
                        onChanged: (i) =>
                            _s.set_(() => _s.useLiveGuardianData = i == 1),
                      ),
                    ),

                    _Control(
                      id: 'guardian_main',
                      label: 'Main Guardian',
                      hint: 'Abdul (Father). Set 0 to see the page with '
                          'Additional Guardians but no Main — a state the '
                          'database can reach once Remove exists.',
                      page: DevPage.guardian,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        options: const ['0', '1'],
                        index: _s.mainGuardian ? 1 : 0,
                        onChanged: (i) => _s.set_(() => _s.mainGuardian = i == 1),
                      ),
                    ),

                    // SPLIT 2026-08-06 (Founder: "give option for 1 main
                    // wali, 0–5 additional wali and 0–5 pending wali").
                    //
                    // NO PRODUCT LIMIT EXISTS — checked before building
                    // this. wali_links has no count constraint, the INSERT
                    // policy caps nothing, accept_wali_invite counts
                    // nothing, and WALI_ARCHITECTURE V6 records it as an
                    // open pre-production item: "No artificial cap is
                    // currently imposed."
                    //
                    // So 5 is where testing stops being useful, NOT a
                    // maximum the product enforces.
                    _Control(
                      id: 'guardians_additional',
                      label: 'Additional Guardians',
                      hint: 'Hassan, Ibrahim, Yusuf, Bilal, Kamran — one per '
                          'relationship, so the longest label is covered.',
                      page: DevPage.guardian,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        options: const ['0', '1', '2', '3', '4', '5'],
                        index: _s.additionalGuardianCount,
                        onChanged: (i) =>
                            _s.set_(() => _s.additionalGuardianCount = i),
                      ),
                    ),

                    _Control(
                      id: 'guardians_received',
                      label: 'Invitations received',
                      hint: 'PREVIEW — wali_invites has no recipient, so this '
                          'list cannot exist until invites are addressed '
                          'rather than shared as codes.',
                      page: DevPage.guardian,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        options: const ['0', '1', '2', '3', '4', '5'],
                        index: _s.receivedInviteCount,
                        onChanged: (i) => _s.set_(() => _s.receivedInviteCount = i),
                      ),
                    ),

                    _Control(
                      id: 'guardians_pending',
                      label: 'Pending invitations',
                      hint: 'Dad, Uncle Ibrahim, (unlabelled), Imam, Family '
                          'Friend. One has no label on purpose — that is the '
                          'case where the card falls back to the raw code.',
                      page: DevPage.guardian,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        options: const ['0', '1', '2', '3', '4', '5'],
                        index: _s.pendingInviteCount,
                        onChanged: (i) =>
                            _s.set_(() => _s.pendingInviteCount = i),
                      ),
                    ),

                    // ADDED 2026-08-05 (Founder: "take a toggle to give
                    // users I liked, saved or declined 1 2 3 guardians,
                    // then make a toggle to add 1 2 3 guardian
                    // suggestions").
                    //
                    // Both write REAL rows — wali_links and
                    // wali_suggestions — rather than in-memory flags, for
                    // the reason the credit control was rebuilt on
                    // 2026-08-04: a panel that sets a number the server
                    // does not know about is how a feature ends up
                    // untestable and unenforced at the same time.
                    //
                    // The Guardians-on-decided control is NOT page-gated —
                    // it changes what a Compatibility page will show
                    // whenever you next open one — so it MOVED to the ANY
                    // PAGE group at the bottom, 2026-08-07. Left here it
                    // was the last thing still producing the scatter the
                    // Founder pointed at: a lone control under a Guardian
                    // heading that had just hidden itself.
                    // "Introductions", not a second "Connections". Both
                    // groups sit on the same tab, so before the headings
                    // learned to hide, this read as CONNECTIONS twice with
                    // unrelated controls under each. Naming it for the
                    // segment it actually affects is the same fix applied to
                    // the control below in July: the panel should use the
                    // app's words, not its own.
                    _NavGroup(Icons.mail_outline, 'Introductions',
                        page: DevPage.connections, state: this),
                    // RENAMED AND MOVED 2026-08-07 (Founder: "give me the
                    // option to add remove introductions 0–5").
                    //
                    // This control already existed as "Guardian Suggestions"
                    // — the same mismatch as Current Journey. The app calls
                    // the segment INTRODUCTIONS (renamed 2026-08-06 at the
                    // Founder's request), and a panel that uses the old
                    // internal name is a panel you have to translate.
                    //
                    // Also moved from the Guardian group to Connections,
                    // because that is where the result appears. The DATA is
                    // Guardian-created; the SURFACE is Connections, and the
                    // panel is grouped by where you go to look.
                    //
                    // 0 RESTORED, replacing 1/3/5/Max. The old note said
                    // there was no zero by choice, since "Reset account
                    // state" cleared them anyway — but that reset wipes
                    // saves, passes, unlocks and credits too. Needing a full
                    // account reset to see an empty Introductions list is
                    // exactly the kind of blunt instrument the Founder asked
                    // to be rid of. Zero is also a real state the page has
                    // its own copy for.
                    _Control(
                      id: 'introductions',
                      label: 'Introductions',
                      hint: 'People your Guardian has put forward. Writes '
                          'real wali_suggestions rows — Connections › '
                          'Introductions.',
                      page: DevPage.connections,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        options: const ['0', '1', '2', '3', '4', '5'],
                        index: _guardianSuggestions,
                        onChanged: (i) {
                          setState(() => _guardianSuggestions = i);
                          _setGuardianSuggestions(i);
                        },
                      ),
                    ),

                    // REMOVED 2026-08-04, Founder: "remove the 200 colour
                    // profile block profiles, I don't want that no more."
                    // The 24 seeded profiles now carry real Chapter 2 data,
                    // so a synthetic deck no longer buys anything the real
                    // one cannot.

                    // The five Browse controls that used to sit here — the
                    // Consider cap, the browsing cap and the two advert
                    // ones — MOVED UP 2026-08-07 to join Save limit under a
                    // single BROWSE heading. See that block for why.
                    //
                    // The "ZYRA Basic only" heading went with them and was
                    // not replaced: plan mismatches are hidden now, so a
                    // heading naming a plan sat above controls that only
                    // ever appeared on that plan anyway.

                    // ── ANY PAGE ───────────────────────────────────────
                    //
                    // LAST, and always shown. Everything above belongs to
                    // one tab and vanishes with it; this belongs to none,
                    // so it needs a heading that does not vanish either —
                    // otherwise it is a control floating under whichever
                    // group happened to survive, which is exactly the mess
                    // this pass was cleaning up.
                    const _NavGroup(Icons.tune, 'Any page'),
                    // MOVED FROM Developer Access 2026-08-07 (Founder: "in
                    // toggle, move them pages there").
                    //
                    // They were on a screen you reach by signing out, which
                    // is the wrong place for the one thing you want to try
                    // WITHOUT losing the account you are in. Here they are
                    // two taps from anywhere.
                    //
                    // Both reset AppState to a blank slate and push the REAL
                    // onboarding flow — no pre-filled persona, no tier
                    // picker. You answer every question as a first-time user
                    // would, which is the only way the flow gets tested
                    // rather than the outcome.
                    _Control(
                      id: 'signup_seeker',
                      label: 'Seeker sign-up',
                      hint: 'Blank slate, real questions — Chapter 1 through '
                          'Profile Ready.',
                      page: null,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _FireButton(
                        label: 'Start Seeker sign-up',
                        onFire: () => _startSignUp(isWali: false),
                      ),
                    ),
                    _Control(
                      id: 'signup_guardian',
                      label: 'Guardian sign-up',
                      hint: 'Name, date of birth, relationship, then Invite a '
                          'Seeker.',
                      page: null,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _FireButton(
                        label: 'Start Guardian sign-up',
                        onFire: () => _startSignUp(isWali: true),
                      ),
                    ),
                    _Control(
                      id: 'guardians_on_decided',
                      label: 'Guardians on people you decided on',
                      hint: 'Considered, Saved and Passed profiles get this '
                          'many Guardians. 0 shows "No Guardian linked." '
                          'Takes effect next time you open a Compatibility '
                          'page, so it is worth setting before you walk there.',
                      page: null,
                      plans: const {DevPlan.basic, DevPlan.one},
                      state: this,
                      child: _Segment(
                        options: const ['0', '1', '2', '3'],
                        index: _guardiansOnDecided,
                        onChanged: (i) {
                          setState(() => _guardiansOnDecided = i);
                          _setGuardiansOnDecided(i);
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      'Debug and profile builds only. Never present in a '
                      'release build — guarded at the mount point and again '
                      'inside this widget.',
                      style: ZyraText.subtext(size: 10, color: Colors.white24),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Current context, so a refusal is never a surprise.
class _Now extends StatelessWidget {
  final DevPlan plan;
  final DevPage page;
  const _Now({required this.plan, required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        'You are on ${page.label} · ${plan == DevPlan.one ? 'ZYRA One' : 'ZYRA Basic'}',
        style: ZyraText.subtext(size: 10.5, color: Colors.white54),
      ),
    );
  }
}

/// Sub-heading inside a plan group, naming the NAV TAB a set of controls
/// affects.
///
/// ADDED 2026-08-06 (Founder: "make the toggle page neater, maybe in groups
/// of navigation bar"). The panel was already grouped by PLAN, which answers
/// "can I use this?" but not "where do I go to see it?" — and with fourteen
/// controls the second question is the one you actually have while holding
/// the phone.
///
/// ── HIDES ITSELF WHEN ITS PAGE IS NOT THE CURRENT ONE, 2026-08-07.
///
/// Founder: "as you can see save limit at top, then Guardian open, then
/// consider limit — group it neater please."
///
/// That is exactly what this was doing. _Control learned to hide on the
/// wrong page; these headers did not, so on Browse the panel drew
/// "Browse", one control, then the bare words "Connections" and "Guardian"
/// with nothing under either, then more Browse controls. The headings
/// looked like the grouping had gone wrong when in fact only the headings
/// had.
///
/// Now every group states which page it heads and disappears with its
/// contents. The PLAN grouping above it is gone entirely — with plan
/// mismatches hidden too, a heading saying "ZYRA Basic only" sat above
/// controls that were only ever visible on Basic anyway.
class _NavGroup extends StatelessWidget {
  final IconData icon;
  final String label;

  /// The page whose controls this heads. Null means "always shown".
  final DevPage? page;
  final _DevScenarioPanelState? state;

  const _NavGroup(this.icon, this.label, {this.page, this.state});

  @override
  Widget build(BuildContext context) {
    if (page != null && state != null && state!._s.currentPage != page) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.45)),
          const SizedBox(width: 7),
          Text(label.toUpperCase(),
              style: ZyraText.subtext(size: 10.5, color: Colors.white54)),
          const SizedBox(width: 9),
          Expanded(
            child: Container(height: 0.5, color: Colors.white.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}

// _GroupHeader REMOVED 2026-08-07. It drew the outer plan grouping —
// "ZYRA BASIC AND ZYRA ONE" / "ZYRA BASIC ONLY" — which existed to explain
// why a control was dimmed. Plan mismatches are hidden now, so every
// heading it drew sat above controls that only ever appeared on that plan
// anyway, and it was the thing splitting Browse across 300 lines.
//
// Deleted rather than left unused: an unreferenced widget in a debug file
// is one somebody re-adds a call to six weeks later without reading why it
// stopped being used.

/// One control plus its context rules.
///
/// When blocked it renders dimmed, shows the reason, swallows the tap and
/// asks the panel to shake it red. `AbsorbPointer` is what makes the
/// refusal real rather than cosmetic — without it the inner switch would
/// still change under the red flash.
class _Control extends StatelessWidget {
  final String id;
  final String label;
  final String? hint;

  /// The page this control only makes sense on, or null when it applies
  /// anywhere. Nullable since 2026-08-05: the two Guardian scenario
  /// controls change server state that any screen will pick up next time it
  /// loads, so gating them to one page would only make them harder to
  /// reach without preventing any mistake.
  final DevPage? page;
  final Set<DevPlan> plans;
  final Widget child;
  final _DevScenarioPanelState state;

  const _Control({
    required this.id,
    required this.label,
    required this.hint,
    required this.page,
    required this.plans,
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final blocked = state._blockedBecause(plans, page);
    final on = blocked == null;

    // HIDDEN on both page AND plan mismatch — see _visible(). Page hiding
    // came first (2026-08-07, "the features only show on the page I'm on");
    // plan hiding followed the same day, for the same reason at a smaller
    // scale: rows that can never be pressed are rows you stop reading.
    if (!state._visible(plans, page)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Deniable(
        tick: state._denied[id] ?? 0,
        child: GestureDetector(
          onTap: on ? null : () => state._deny(id),
          child: Opacity(
            opacity: on ? 1 : 0.42,
            child: AbsorbPointer(
              absorbing: !on,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ZyraText.subtext(size: 12.5, color: Colors.white)),
                  if (hint != null || !on) ...[
                    const SizedBox(height: 2),
                    Text(
                      on ? hint! : blocked,
                      style: ZyraText.subtext(
                        size: 10,
                        color: on ? Colors.white38 : const Color(0xFFE08080),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shakes and flashes red whenever [tick] changes.
///
/// Driven by a counter rather than a bool so repeated taps on the same
/// blocked control each get their own shake — a bool would only animate
/// the first time.
class _Deniable extends StatefulWidget {
  final int tick;
  final Widget child;
  const _Deniable({required this.tick, required this.child});

  @override
  State<_Deniable> createState() => _DeniableState();
}

class _DeniableState extends State<_Deniable> with SingleTickerProviderStateMixin {
  // `value: 1` is the fix for "every control looks blocked" (2026-08-05,
  // Fable). The glow below is `(1 - t) * 0.9`, so it is brightest at t = 0
  // and gone at t = 1 — correct while a denial is decaying, but the
  // controller ALSO rests at 0 before it has ever run, which painted the
  // full red border on every control from the moment the panel opened,
  // whether or not it was usable on the current page. Starting at rest = 1
  // means idle is genuinely idle; `forward(from: 0)` still plays the whole
  // shake when a control really is denied.
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant _Deniable old) {
    super.didUpdateWidget(old);
    if (widget.tick != old.tick) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // Damped sine: three full swings, amplitude decaying to zero.
        // Written this way rather than with remainder() arithmetic because
        // it is obviously correct at a glance — it starts at 0, ends at 0,
        // and cannot drift.
        final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
        final glow = (1 - t) * 0.9;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: const Color(0xFFE05555).withValues(alpha: glow * 0.16),
              border: Border.all(
                color: const Color(0xFFE05555).withValues(alpha: glow * 0.75),
                width: 1,
              ),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A one-shot trigger. Used where the thing being tested is an EVENT (an
/// advert, a limit modal) rather than a state you can sit in — a switch
/// would imply it stays on, and neither of those can.
class _FireButton extends StatelessWidget {
  final String label;
  final VoidCallback onFire;
  const _FireButton({required this.label, required this.onFire});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: onFire,
            child: Center(child: Text(label, style: ZyraText.button(size: 12.5))),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _Tab({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: _DevScenarioPanelState._tabWidth,
          height: 92,
          decoration: BoxDecoration(
            color: const Color(0xF20E0B12),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 0.5),
          ),
          child: Center(
            child: Icon(
              open ? Icons.chevron_right : Icons.tune,
              size: 15,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  /// Highest selectable index. Anything above renders dimmed and calls
  /// [onBlocked] instead of [onChanged] — the value is still VISIBLE, so
  /// you can see the cap rather than wondering why the row is short.
  final int? maxIndex;
  final VoidCallback? onBlocked;

  const _Segment({
    required this.options,
    required this.index,
    required this.onChanged,
    this.maxIndex,
    this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Builder(builder: (_) {
              // Over the cap: shown, dimmed, and refused on tap. Hiding it
              // would leave you guessing why the row got shorter; clamping
              // silently would look like the tap missed.
              final capped = maxIndex != null && i > maxIndex!;
              return Expanded(
                child: GestureDetector(
                  onTap: () => capped ? onBlocked?.call() : onChanged(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: i == index ? Colors.white.withValues(alpha: 0.20) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      options[i],
                      style: ZyraText.subtext(
                        size: 11.5,
                        color: Colors.white.withValues(
                            alpha: capped ? 0.15 : (i == index ? 1 : 0.45)),
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// The word, not a house glyph (Founder). Full width at the top of the
/// panel so it reads as a page-level action rather than another scenario.
/// Full account reset. Same shape as _HomeButton, tinted red — it deletes
/// rows, and a destructive control should not look identical to a
/// navigation one.
class _ResetProfileButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFE08080);
    return Material(
      color: danger.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: danger.withValues(alpha: 0.35), width: 1),
          ),
          child: Text('Reset account state',
              style: ZyraText.button(size: 13, color: danger)),
        ),
      ),
    );
  }
}

/// "+1 / +5" credit grants.
///
/// Buttons, not a segmented selector, because the ledger is append-only:
/// there is no such thing as setting a balance to 5, only adding 5. The old
/// segmented "None / 1 / 5" control implied a value you could choose, which
/// stopped being true the moment entitlement moved server-side.
class _GrantRow extends StatelessWidget {
  final ValueChanged<int> onGrant;
  const _GrantRow({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, int n) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onGrant(n),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1),
                  ),
                  child: Text(label, style: ZyraText.button(size: 12, color: Colors.white)),
                ),
              ),
            ),
          ),
        );
    return Row(children: [btn('+1', 1), btn('+5', 5)]);
  }
}

class _HomeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HomeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
          ),
          child: Text('Home', style: ZyraText.button(size: 13, color: Colors.white)),
        ),
      ),
    );
  }
}
