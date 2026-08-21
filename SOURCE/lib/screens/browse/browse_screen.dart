// Browse — BROWSE_UX_SPEC_CURRENT_VERSION_V3.md + PROFILE DECISION
// SYSTEM/Summary.md. Current terminology (DR-ZYRA-099, 2026-07-25):
// 🔴 Pass (was: Decline — no record, no notification), 🟡 Save
// (private bookmark), 🟢 Consider (was: Like — Outgoing Potential;
// mutual Consider = Match event = Potential Journey created).
//
// Visual treatment (2026-07-18) adapted from the founder's old Lovable
// prototype (src/routes/home.tsx + AppShell.tsx GLASS_BTN) after his
// review request: full-bleed edge-to-edge photo (no card padding/
// rounding), tap left/right half to cycle multiple photos, a vertical
// dot indicator on the LEFT side that fades while holding the photo
// (matches their actual code — he recalled it as the right side, but
// their source has it on the left; went with the source), and real
// glassmorphism (backdrop blur, not just a flat tint) on a brief
// tinted glass "flash" confirmation on each decision.
//
// 2026-07-25, DR-ZYRA-099 (Founder decision, direct quote: "we will
// stick with swiping actions for cleaner UI"): the floating action
// button row is REMOVED. Primary actions are now swipe gestures on
// the card itself — swipe left = Consider, swipe right = Pass, swipe
// down = Save — with the card following the finger and flying off in
// the swipe direction on release past threshold, snapping back
// otherwise. Terminology renamed Decline→Pass, Like→Consider
// throughout this file's UI layer (enum, handler names, comments).
//
// 2026-07-26 (Founder feedback: "the current swiping action is not
// nice... I kinda want the traffic light colour implements. Green if
// u swipe positive. Yellow if u save and red if u skip"): added live
// drag-direction feedback — _dragDecision/_dragStrength compute the
// same DR-ZYRA-099 direction mapping continuously while dragging, and
// the card shows a soft edge glow + a small top pill (icon + label)
// in the matching traffic-light colour, growing in intensity as the
// drag approaches the commit threshold. Deliberately a light edge
// glow + pill rather than a full-photo colour wash, per the Founder's
// "more light and simple" note — the photo itself stays fully
// visible throughout the drag. Reuses the exact hue family already
// established by the post-commit tint colours (🔴🟡🟢) for
// visual consistency, just at full opacity with the pill/border
// applying their own transparency. Approved via an interactive
// mockup shown to the Founder before this was built (not a first
// guess coded blind).
//
// NOT renamed: AppState's underlying `decline()`/`declined`/`like()`/
// `outgoingLikes` API — those are internal method/field names used
// elsewhere (e.g. profile_screen.dart's Connections counts) and were
// judged out of scope for tonight's UI-layer change; flagged in
// SEEKER NAVIGATION/Summary.md and OA-ZYRA-138 as a known, not-yet-
// closed doc/code terminology gap. This file calls the old method
// names (`AppState.instance.decline(...)`, `.like(...)`) from the new
// `_onPass`/`_onConsider` handlers.
//
// 2026-07-27 (Founder: "im thinking of removing the 3 [dot] button and
// having it [so] if the user presses and holds down on centre without
// swiping and there's a time delay between 3-5 seconds then it opens up
// the 3 buttons which shows up as a placecard in middle screen... again
// being removed if u click anywhere else on screen"). Asked to choose
// between that and a bottom-sheet variant, the Founder picked "remove
// icon, centre placecard" over keeping the "..." icon as a discoverable
// fallback — a deliberate trade-off, not an oversight: the Help/Report
// menu now has NO visible on-screen affordance at all. The "..." icon
// (home_shell.dart) is gone; holding a finger still in roughly the
// middle 76% of the photo's width for ~0.8s TOTAL from finger-down —
// which is Flutter's own 500ms long-press deadline plus
// _centreHoldDuration, NOT _centreHoldDuration alone; see that constant
// for why that distinction caused three failed tuning passes — opens
// HelpReportCard
// (widgets/help_report_sheet.dart) — originally centred via showDialog,
// changed to a bottom sheet in a later pass the same day (see the
// _openHelpReportSheet's own comment below for that change). Dismissed
// by tapping anywhere else either way (showDialog/showModalBottomSheet
// both default to dismissible). Implemented as a timer started in the
// EXISTING onLongPressStart (which
// already drives `_interacting`'s photo-dimming feedback — kept as the
// only in-progress feedback during the hold, per the Founder's chosen
// option) and cancelled on release or on drifting outside a small
// stillness tolerance (onLongPressMoveUpdate) — "without swiping" is
// taken literally: a hold that turns into a drag does not open the menu.
// See _onCentreLongPressStart / _onCentreLongPressMoveUpdate /
// _onCentreLongPressEnd / _openHelpReportCentred below.
//
// ALL OF THE ABOVE RETIRED 2026-08-13 (DR-ZYRA-150). The hidden hold
// never earned its invisibility; with the Bell gone to the nav bar
// (DR-ZYRA-149) the top-right corner was free again, and the Founder
// put a visible ⋮ there. Tapping it asks HomeShell to transform the nav
// bar into the two action pills (Report Profile / Help & Support) —
// see the ⋮ overlay in this build and _ActionModeBar in home_shell.dart.
// Long-press keeps only the photo-dim feedback; the paragraphs above
// stay as the history of how this corner earned its button back.

import 'dart:async';
import '../../widgets/zyra_profile_image.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
// services/HapticFeedback import left with the centre-hold (DR-ZYRA-150)
// — its mediumImpact on menu-open was the file's only haptic.
import '../../models/seeker_profile.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_profile_service.dart';
import '../../services/zyra_guardian_suggestion_service.dart';
import '../../services/zyra_report_service.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../subscription/profile_unlock_screen.dart';
import '../../widgets/zyra_profile_name_block.dart';
import '../../widgets/report_profile_sheet.dart';
import '../../widgets/zyra_glass_dialog.dart';
import '../subscription/upgrade_screen.dart';
import 'match_notification_screen.dart';
import '../../widgets/zyra_loading.dart';
// DR-ZYRA-169 Phase 1 (2026-08-15): the precache pass and the block path
// both talk to the shared disk image cache now.
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/zyra_image_cache.dart';

// 50 profiles per 4 HOURS on ZYRA Basic (Founder, 2026-08-07). The name
// says "daily" from an earlier reading of the rule and is left alone here
// only because renaming it touches six call sites for no behavioural gain
// — the modal copy is what a user reads, and that is corrected.
//
// ── NOT ENFORCED, AND WORTH KNOWING. `_viewed` is an in-memory counter on
// this widget's State. It starts at zero on every cold launch, on every
// rebuild of Browse, and on every tab switch that disposes it. So the cap
// is presentational: it is not persisted, not per-4-hours, not shared
// across devices, and the server knows nothing about it.
//
// Making it real means a persisted counter with a window — the same shape
// as unlock_credits, and the same reason: an entitlement the client alone
// enforces is not an entitlement. Flagged, not built, because it is a
// feature rather than a fix and the Founder has not asked for it.
const int _dailyProfileLimit = 50;

// Swipe distance (px) past which a release commits to the action,
// rather than snapping back. Kept generous so accidental drags while
// viewing a photo don't misfire.
const double _swipeCommitThreshold = 120;

// 2026-07-26 (OA-ZYRA-121, DR-ZYRA-109): governed product rule per
// APP/Premium/ADVERTISING/ADVERTISING_STANDARD_CURRENT_VERSION_V1.md
// rule 5. Kept as a named constant, not inlined, so it stays easy to
// find/change when that review happens — same discipline as
// _dailyProfileLimit above.
//
// CHANGED 2026-07-27 (3rd pass, Founder, screenshot-driven: "when i
// swiped 5 more i saw a new pop up... check if theres 2 advert
// placeholders and if so only keep one"). Was 10, with a SEPARATE
// _upgradeNudgeFrequency constant at 5 driving a second, different
// interstitial (_UpgradeNudgeCard) — both fired correctly, just as two
// undocumented-to-the-user mechanics, which read as a bug. Merged into
// one interstitial (_SponsoredCard now absorbs the Continue/Upgrade
// button row _UpgradeNudgeCard used to own — see that class's doc
// comment), so there's only one frequency left to govern: 5, the more
// recent and more specific of the Founder's two prior instructions.
// ADVERTISING_STANDARD_CURRENT_VERSION_V1.md rule 5 and its Governance
// section are corrected to match (10 → 5), dated, same day.
const int _sponsoredCardFrequency = 5;

// 2026-07-27 (Founder: "for basic account they can save max 10 people
// and save as connection max 25 people where as for zyra one the save
// is max 50 and like is unlimited"). Read "save as connection" as the
// Consider action (DR-ZYRA-099's renamed "Like") — it's the one that
// can actually result in a Connection/Match, which is the only sense in
// which "save" and "connection" pair up given the app's own
// terminology; there's no separate action literally called "save as
// connection" anywhere in the codebase. Stated plainly here so it's
// easy to correct in one line if that reading is wrong.
// REVISED 2026-08-01 (Founder: "for ZYRA One Seeker 50 profile saves is
// a lot so maybe let's do ZYRA Basic can save 5 and ZYRA One can save
// 15"). Was 10 / 50.
//
// Agreed, and it's more than a number change. A Save is a bookmark —
// "don't let me lose this profile" — and a shortlist of 50 is not a
// shortlist, it is a second Browse queue. ZYRA's whole argument is that
// you leave, married, rather than accumulating options; a generous Save
// cap quietly contradicts that.
//
// Consider stays at 25/unlimited. That cap is doing a different job: it
// limits how many people you signal interest TO, not how many you keep
// track of, so it should not shrink alongside this one.
// REVISED AGAIN 2026-08-07 (Founder: "change ZYRA One so they can save max
// 50 people and ZYRA Basic can do max 10, also ZYRA Basic can max consider
// 20 people"). Save goes 5/15 -> 10/50, Consider 25 -> 20.
//
// THIS REVERSES THE 2026-08-01 CHANGE, which took Save from 10/50 down to
// 5/15 — so the numbers are back where they were in July, and the argument
// recorded above for shrinking them ("a shortlist of 50 is not a
// shortlist, it is a second Browse queue") is now overruled. Left in place
// above rather than deleted: it is the reasoning that will come up again
// next time, and a decision reversed twice is worth being able to see.
//
// Consider moving 25 -> 20 goes the OTHER way, which is coherent rather
// than contradictory: Save is a private bookmark and can be generous;
// Consider signals interest to another person and is the one worth
// keeping tight. The gap between them narrowing is the point.
const int zyraBasicSaveLimit = 10;
const int zyraBasicConsiderLimit = 20;
const int zyraOneSaveLimit = 50;
// No _oneConsiderLimit constant — "like is unlimited" for ZYRA One, so
// the Consider cap check is skipped entirely for that plan (see _onConsider).

/// Shadows for white text sitting directly on a photograph.
///
/// ADDED 2026-08-07 (Founder: "if a person uploads a photo and it happens
/// to be in the same section as the name is white, would it then not hide
/// the name, age etc — check for me").
///
/// It does, and by more than it looks. MEASURED against the bottom scrim as
/// it was: the name sat on only 17% black, giving **1.48:1** against a white
/// photo where WCAG asks 3:1 for text that size. The surname managed 1.78:1
/// and the age/city line 2.22:1, both needing 4.5:1. A mid-grey photo failed
/// too — this was never only about pure white.
///
/// ── WHY THE SCRIM IS NOT THE LEVER, which is the part worth recording.
/// Reaching 3:1 on the name by darkening alone needs **42% black at the
/// name's height**, and the name sits two-thirds of the way UP the gradient
/// band. Getting 42% there means dragging the whole band up with it, so
/// every photo — including the many that were perfectly legible — loses its
/// bottom third to a grey wash. On a product whose entire card IS the
/// photograph, that trades a real problem for a worse one.
///
/// ── WHAT A SHADOW DOES INSTEAD. It creates contrast at the glyph EDGE,
/// from the text's own halo, so it does not care what is behind it: white
/// text against its own 80%-black halo is **12.6:1** whether the photo is a
/// snowfield or a night sky. The photo is not dimmed at all.
///
/// Two shadows, doing different jobs:
///   TIGHT   3px, near-opaque — the hard edge that separates letter from
///           background. This is what carries a white photo.
///   WIDE    14px, softer — lifts the block off a BUSY photo, where the
///           problem is not brightness but detail competing with letterforms.
///
/// The scrim still moved (see the bottom gradient), just modestly: 17% → 32%
/// at the name, which is real improvement without the wash. Belt and braces,
/// with the braces doing most of the work.
// _onPhotoTextShadows MOVED 2026-08-13 (DR-ZYRA-163) to
// widgets/zyra_profile_name_block.dart, as kZyraOnPhotoTextShadows. It
// was private here, so every other screen drawing text on a photo did
// without it — which is why the Connections heroes read flatter than
// this one.
//
// It was briefly left behind as an alias, on a note claiming "~20 call
// sites in this file". That number was written without counting: the
// name block was the ONLY consumer, and it moved out with the shadow.
// Alias deleted.

enum _Decision { pass, save, consider }

class BrowseScreen extends StatefulWidget {
  // Renamed from onNavigateToMatches 2026-07-26 (nav bar fix) — the
  // tab it jumps to is now Connections, not a standalone Matches tab.
  final VoidCallback? onNavigateToConnections;

  /// Fired when Browse takes over the whole screen (the sponsored card)
  /// and again when it releases it.
  ///
  /// ADDED 2026-08-01 (Founder: "the skip in the top right is behind the
  /// bell icon so I assume for adverts the bell icon gotta go"). The Bell
  /// and the nav bar are siblings of the tab content in HomeShell's
  /// Stack, layered ABOVE it — so anything Browse renders full-screen
  /// appears underneath them, and its top-right corner is unreachable.
  /// Browse cannot fix that from inside itself; it has to tell the shell.
  final ValueChanged<bool>? onFullScreenTakeover;

  /// THE ⋮'S DOOR — 2026-08-13 (DR-ZYRA-150): tapping the three dots
  /// asks the SHELL to enter action mode (the nav bar becomes the
  /// Report Profile / Help & Support pills), handing it what Report
  /// should do — report whoever is on the card right now. The shell
  /// owns the bar; this screen owns the person. Null in contexts with
  /// no shell (none today).
  /// CARRIES TWO ACTIONS SINCE 2026-08-13 (DR-ZYRA-155). Hide Profile
  /// left the report sheet and became its own option on the bar, so the
  /// card hands over both things the bar can do to whoever is on it.
  /// The shell owns the bar; this screen owns the person.
  final void Function(
    ({VoidCallback report, VoidCallback hide, VoidCallback compatibility})
    actions,
  )?
  onOpenActions;

  const BrowseScreen({
    super.key,
    this.onNavigateToConnections,
    this.onFullScreenTakeover,
    this.onOpenActions,
  });

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  int _index = 0;
  int _viewed = 0;
  int _photoIndex = 0;
  bool _interacting = false;
  // 2026-07-26 (Founder: "if swiped maybe the dots have a little
  // burst... small firework burst or something"). Deliberately a
  // separate flag from `_dragDecision` (which depends on `_dragOffset`
  // and lives inside the swappable per-profile card) — `_advance()`
  // switches `_index` ~280ms into a commit, which would tear down/
  // rebuild anything nested inside that card mid-animation. Being
  // independent of `_index` is what makes this survive that switch.
  //
  // (This comment used to cite `_flash` as the pattern it mirrors.
  // `_flash` was deleted 2026-08-01 — see _onPass's note.)
  _Decision? _burstDecision;

  // The centre-hold machinery (2026-07-27 -> 2026-08-13) is GONE:
  // timer, origin, fraction/stillness constants, the three handlers and
  // _openHelpReportSheet all retired with DR-ZYRA-150 — the ⋮ top-right
  // is Help/Report's visible door now, and the shell's action bar is
  // its surface. Long-press keeps only the photo-dim feedback.

  // 2026-07-26 (OA-ZYRA-121, DR-ZYRA-109) — Sponsored card slot. NOT a
  // real candidate: doesn't consume _index/_current, isn't Pass/Save/
  // Considerable (those verbs don't apply to an ad — see rule 6 of the
  // Advertising Standard: "no ambiguity between a match and an
  // advertisement"), and is dismissed by its own single button rather
  // than the swipe-decision system, so it can never be misread as a
  // real Browse decision or write a decline/save/like row for an ad.
  bool _showingSponsoredCard = false;
  // REMOVED 2026-07-27 (3rd pass) — _showingUpgradeNudge is gone; the
  // interstitial it used to gate is merged into _showingSponsoredCard
  // above. See _sponsoredCardFrequency's doc comment for the full
  // reasoning.

  // Swipe-gesture state (DR-ZYRA-099). _dragOffset is the card's live
  // visual offset while a finger is down; _dragStartGlobal anchors the
  // gesture so onPanUpdate can compute delta without accumulating
  // floating-point drift.
  Offset _dragOffset = Offset.zero;
  Offset? _dragStartGlobal;
  bool _dragCommitted = false;

  /// Whether the completeness gate is what is keeping this deck empty
  /// (OA-ZYRA-193c). Server-answered — see
  /// ZyraProfileService.fetchOnboardingProgress.
  bool _gated = false;
  int _missingCount = 0;

  Future<void> _loadGateState() async {
    final p = await ZyraProfileService.fetchOnboardingProgress();
    if (!mounted || p == null) return;
    setState(() {
      _gated = !p.complete;
      _missingCount = p.missing;
    });
  }

  // Starts EMPTY with a loading flag, and stays empty if there is nothing
  // real to show.
  //
  // 2026-08-04: the mock fallback inside ZyraDiscoveryService is gone
  // (independent review, H-6), so an empty deck now genuinely means "no
  // candidates" rather than "something failed and you are looking at
  // fabricated people". The comment below described that fallback as
  // intentional and correct; it was neither, and it is what let the
  // profile_complete bug hide for a month.
  //
  // FIXED 2026-07-27 (Founder, dev-mode report: "when on dev i click
  // home and change profiles a old picture shows up before it changes
  // to the profile photos... it lasts for a second"). Root cause:
  // _allProfiles used to default to `mockProfiles` synchronously
  // (painted on the very first frame, before initState's fetch below
  // even starts), only replaced once fetchCandidates()'s real network
  // round trip resolved a moment later — so every fresh BrowseScreen
  // (first launch, or any full HomeShell rebuild, e.g. Developer
  // Access's account switcher, or — see home_shell.dart's own fix this
  // same pass — every tab switch back to Browse) always flashed
  // mockProfiles' hardcoded first entry ("Maryam", surnameLine
  // "Hussain" — a stale leftover; the real, migrated Supabase row for
  // Maryam uses "Begum") with a random Picsum stock photo, before
  // swapping to the real fetch result. Now starts empty with a genuine
  // loading flag instead, so nothing paints until fetchCandidates()
  // actually resolves — including its own internal mockProfiles
  // fallback for cases where that's the correct, intentional result
  // (signed out, no real candidates yet, etc.), which this fix doesn't
  // change at all.
  List<SeekerProfile> _allProfiles = [];
  bool _loadingCandidates = true;

  // #21 (Search = Browse's filter controls, per APP/Search/SUMMARY.md's
  // resolved scope) — age range is a pure client-side filter over the
  // already-fetched candidate list (age is already known per-candidate
  // via ages_for(), no new schema/query needed). Null = no filter set.
  int? _minAge;
  int? _maxAge;

  /// ADDED 2026-08-01 (Founder, screenshot: Usman, 35 under CONSIDERED
  /// *and* SAVED). Drops anyone already decided on from a freshly fetched
  /// deck.
  ///
  /// This is where the duplicate actually came from. `_current` returns
  /// null past the end of the list, so Browse does not wrap — but every
  /// refetch reassigned `_allProfiles` wholesale and reset the cursor to
  /// 0, handing back the same seven mock profiles including the ones just
  /// acted on. Decide again, land in a second list.
  ///
  /// Filtered HERE and not in the `_profiles` getter on purpose. `_index`
  /// is a positional cursor into that list, so a reactive filter would
  /// remove the current profile the instant a decision is recorded,
  /// shifting everything left, and then `_advance()`'s `_index++` 280ms
  /// later would skip the next person entirely. Filtering at load keeps
  /// the cursor stable for the whole session.
  ///
  /// Saved is NOT filtered — a bookmark is not a decision (see
  /// AppState's two-axes note). A Saved-but-undecided profile stays
  /// browsable and wears a badge so its reappearance is never confusing.
  List<SeekerProfile> _withoutDecided(List<SeekerProfile> list) {
    final decided = AppState.instance.decidedProfileIds;
    if (decided.isEmpty) return list;
    return list.where((p) => !decided.contains(p.id)).toList();
  }

  /// Last `AppState.deckVersion` this deck was built from. A change means
  /// the account was reset and the deck must be re-fetched, not re-filtered.
  int _deckVersion = AppState.instance.deckVersion;

  @override
  void initState() {
    super.initState();
    _loadGateState();
    // The 200-profile colour deck short-circuit was removed 2026-08-04 at
    // the Founder's request. The 24 seeded profiles now carry real Chapter 2
    // data, which the synthetic deck never did, so Browse always goes to the
    // real fetch.
    _loadDeck();
    AppState.instance.addListener(_onAppStateChanged);
    ZyraDevScenario.instance.addListener(_onDevPopupRequested);
    // Guardian Suggestions are published app-wide by Connections, but Browse
    // is the first tab and may never have been visited — without this, a
    // suggested profile met in the deck would carry no badge until the user
    // happened to open Connections. Cheap: one indexed read, and the result
    // is what the badge above the name is drawn from.
    _loadSuggestedMarks();
  }

  Future<void> _loadSuggestedMarks() async {
    if (AppState.instance.guardianSuggestedBy.isNotEmpty) return;
    final s = await ZyraGuardianSuggestionService.fetchPending();
    if (!mounted || s.isEmpty) return;
    AppState.instance.setGuardianSuggestedBy({
      for (final x in s) x.profile.id: x.suggestedBy,
    });
  }

  /// ADDED 2026-08-05 (Fable). Browse used to fetch exactly once, in
  /// initState, so a dev-panel reset emptied Connections but left this deck
  /// untouched — the profiles only reappeared after an app restart, which is
  /// what the reset snackbar had to tell people to do. Now a reset bumps
  /// `deckVersion`, this hears it, and the deck comes straight back.
  void _onAppStateChanged() {
    if (!mounted) return;

    // "View profile" on a Guardian Suggestion (Founder, 2026-08-05) parks a
    // profile here and switches to this tab. Jump to it, inserting it at the
    // front if it isn't in the deck — a suggestion is usually someone you
    // have not reached yet, and possibly someone already decided on, so it
    // cannot be assumed present.
    final pending = AppState.instance.takePendingBrowseProfile();
    if (pending != null) {
      setState(() {
        final at = _allProfiles.indexWhere((p) => p.id == pending.id);
        if (at == -1) {
          _allProfiles = [pending, ..._allProfiles];
          _index = 0;
        } else {
          _index = at;
        }
        // Arriving on a new person must start at their first photo. Without
        // this, _photoIndex carries over from whoever was on screen when the
        // user left for Connections.
        _photoIndex = 0;
        _loadingCandidates = false;
      });
      _precacheAround(_index);
      return;
    }

    final v = AppState.instance.deckVersion;
    if (v == _deckVersion) return;
    _deckVersion = v;
    setState(() {
      _index = 0;
      _loadingCandidates = true;
    });
    _loadDeck();
  }

  void _loadDeck() {
    ZyraDiscoveryService.fetchCandidates().then((list) {
      if (mounted) {
        setState(() {
          _allProfiles = _withoutDecided(list);
          _loadingCandidates = false;
        });
        _precacheAround(_index);
      }
    });
  }

  /// Shows a popup the dev panel asked for — using THE APP'S OWN modals,
  /// not copies (Founder, 2026-08-05: "please include the pop-ups that are
  /// on file, not create random ones").
  ///
  /// Read-and-clear, so one press produces exactly one showing. The old
  /// design set a sticky flag that made every subsequent Save hit the cap
  /// branch for the rest of the session.
  void _onDevPopupRequested() {
    final popup = ZyraDevScenario.instance.takePendingPopup();
    if (popup == null || !mounted) return;

    switch (popup) {
      case DevPopup.saveLimit:
        // Same call _onSave makes at the cap, including the plan-correct
        // limit and copy — Basic caps at 5, ZYRA One at 15 with a different
        // sentence.
        final saveLimit = AppState.instance.plan == ZyraPlan.one
            ? zyraOneSaveLimit
            : zyraBasicSaveLimit;
        _showCapReachedModal(
          action: 'Save',
          limit: saveLimit,
          upgradeText: 'Upgrade to ZYRA One to save more.',
        );
      case DevPopup.considerLimit:
        _showCapReachedModal(
          action: 'Consider',
          limit: zyraBasicConsiderLimit,
          upgradeText: 'Upgrade to ZYRA One for unlimited Considers.',
        );
      case DevPopup.dailyLimit:
        _showLimitReachedModal();
      case DevPopup.sponsoredCard:
        setState(() => _showingSponsoredCard = true);
        widget.onFullScreenTakeover?.call(true);
    }
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    ZyraDevScenario.instance.removeListener(_onDevPopupRequested);
    super.dispose();
  }

  // FIXED 2026-07-26 (photo preloading pass — see CHATGPT_REPLY_NAVBAR_
  // PHOTO_MENU_2026-07-26.md §2). The ~1s tap-to-next-photo stall was
  // traced to zero image caching anywhere — Image.network() fetches +
  // decodes cold the first time any given URL is shown, and Flutter's
  // ImageCache only makes the *second* view of a URL instant.
  // precacheImage() is Flutter's own built-in mechanism for "fetch and
  // decode now, park it in the cache" — this warms the CURRENT
  // candidate's full photo set (covers in-profile tap-to-next-photo,
  // since all of that candidate's photos are already decoded by the
  // time any of them is tapped) plus the NEXT candidate's first photo
  // only (covers swipe-to-next-profile, without wastefully prefetching
  // photos 2+ of a candidate the user may Pass before ever opening).
  // SWITCHED to the shared cached provider 2026-08-15 (DR-ZYRA-169
  // Phase 1). NetworkImage warmed only the RAM cache, and by URL — so a
  // re-signed URL missed, and nothing survived an app close. The same
  // provider ZyraProfileImage renders with (same manager, same
  // URL-sans-token key) means this prefetch now warms disk AND RAM, and
  // warms the exact entries the render will look up.
  void _precacheAround(int index) {
    final profiles = _profiles;
    if (index >= 0 && index < profiles.length) {
      for (final url in profiles[index].photos) {
        precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheKey: ZyraImageCache.keyFor(url),
            cacheManager: ZyraImageCache.manager,
          ),
          context,
        );
      }
    }
    if (index + 1 < profiles.length) {
      final nextPhotos = profiles[index + 1].photos;
      if (nextPhotos.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(
            nextPhotos.first,
            cacheKey: ZyraImageCache.keyFor(nextPhotos.first),
            cacheManager: ZyraImageCache.manager,
          ),
          context,
        );
      }
    }
  }

  List<SeekerProfile> get _profiles {
    if (_minAge == null && _maxAge == null) return _allProfiles;
    final lo = _minAge ?? 18;
    final hi = _maxAge ?? 120;
    return _allProfiles.where((p) => p.age >= lo && p.age <= hi).toList();
  }

  bool get _filterActive => _minAge != null || _maxAge != null;

  // No longer called anywhere — its only entry point (the top-left tune
  // icon) was removed 2026-07-26. Kept, not deleted; see the removal
  // note further down in build(). Suppressed rather than deleted so
  // `flutter analyze` stays clean without losing this logic.
  // ignore: unused_element
  Future<void> _openFilterSheet() async {
    int lo = _minAge ?? 18;
    int hi = _maxAge ?? 65;
    final result = await showModalBottomSheet<({int? lo, int? hi})>(
      context: context,
      backgroundColor: ZyraColors.luxuryDarkPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Age range', style: ZyraText.heading(size: 17)),
                const SizedBox(height: 4),
                Text(
                  'Only affects who appears in Browse for you.',
                  style: ZyraText.subtext(size: 12.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '$lo – $hi',
                  style: ZyraText.body(size: 15, color: Colors.white),
                ),
                RangeSlider(
                  values: RangeValues(lo.toDouble(), hi.toDouble()),
                  min: 18,
                  max: 70,
                  divisions: 52,
                  activeColor: ZyraColors.accentBorder,
                  inactiveColor: ZyraColors.iconButtonBg,
                  labels: RangeLabels('$lo', '$hi'),
                  onChanged: (v) => setSheetState(() {
                    lo = v.start.round();
                    hi = v.end.round();
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop((lo: null, hi: null)),
                        child: Text('Clear', style: ZyraText.button(size: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop((lo: lo, hi: hi)),
                        child: Text('Apply', style: ZyraText.button(size: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _minAge = result.lo;
      _maxAge = result.hi;
      // Start over within the newly-filtered set — _viewed (the daily
      // limit counter) deliberately does NOT reset; changing a filter
      // isn't a new day.
      _index = 0;
      _photoIndex = 0;
    });
    _precacheAround(0);
  }

  SeekerProfile? get _current =>
      _index < _profiles.length ? _profiles[_index] : null;

  // OA-ZYRA-125 §5: the "0/50 Profiles" counter is hidden during normal
  // browsing entirely. This is the only place the limit surfaces — a
  // modal, shown once, right when it's reached.
  bool get _limitReached => _viewed >= _dailyProfileLimit;

  void _advance() {
    setState(() {
      _viewed++;
      _index++;
      _photoIndex = 0;
      // OA-ZYRA-121 / DR-ZYRA-109 — rule 1 ("Browse and Discovery
      // only") + Model Overview ("Seeker ZYRA One: Completely
      // ad-free"). Checked here, not in build(), so a plan change
      // mid-session (e.g. via Developer Access) takes effect on the
      // very next interaction rather than needing a rebuild trigger
      // of its own.
      if (AppState.instance.plan == ZyraPlan.basic) {
        // The dev toggle forces one on EVERY profile — a deliberate
        // preview state, never a production one. Added 2026-08-07 so the
        // rhythm of being interrupted can be reviewed, not just the card:
        // at the real cadence a 24-profile deck yields four adverts, which
        // is not enough to judge whether it breaks a run of browsing.
        // Gated on Basic here as well as in the panel — ZYRA One is
        // contractually ad-free, and simulating an advert on it would be
        // previewing a promise being broken.
        final everyProfile = ZyraDevScenario.instance.adsOnEveryProfile;
        if (everyProfile || _viewed % _sponsoredCardFrequency == 0) {
          _showingSponsoredCard = true;
        }
      }
    });
    // Outside the setState above, so the shell's own setState is never
    // nested inside this one.
    if (_showingSponsoredCard) widget.onFullScreenTakeover?.call(true);
    _precacheAround(_index);
    if (_viewed == _dailyProfileLimit) {
      // Fires once, exactly on the transition into the limit — not on
      // every subsequent action, which _onPass/_onSave/_onConsider guard
      // against separately below.
      Future.microtask(_showLimitReachedModal);
    }
  }

  void _dismissSponsoredCard() {
    setState(() => _showingSponsoredCard = false);
    widget.onFullScreenTakeover?.call(false);
  }

  Future<void> _showLimitReachedModal() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      // FIXED 2026-08-01 (Founder: "the transparency is ok but look at
      // the edges, it looks like two extra transparent frames sticking
      // out"). Real, and it was a nesting mistake, not a colour one.
      //
      // `margin` sat on the Container INSIDE the ClipRRect, so the clip
      // and the blur described a rectangle 36pt wider on each side than
      // the bordered card. That outer rectangle still got blurred and
      // still got rounded corners — it just had no tint or border — so it
      // read as a second, ghostly frame around the real one.
      //
      // Padding now sits OUTSIDE the ClipRRect. Blur, clip and border all
      // describe exactly the same rectangle.
      builder: (dialogContext) => ZyraGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_bottom, color: Colors.white, size: 30),
            const SizedBox(height: 14),
            // COPY CORRECTED 2026-08-07. The Founder stated the rule
            // plainly — "a basic user can browse 50 profiles every 4
            // hours" — and this modal said something else twice over:
            // "today's limit" (it is not a day, it is four hours) and
            // "New profiles unlock in 2h 30m", which was a hardcoded
            // string counting down from nothing. Anyone who waited
            // 2h 30m and found themselves still capped would have
            // been told a specific, checkable, wrong thing.
            //
            // No countdown now, because there is nothing to count
            // from — see _viewed's own note. Better to say the rule
            // than to invent a number that looks precise.
            Text(
              "You've reached your browsing limit",
              style: ZyraText.heading(size: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "You've viewed $_dailyProfileLimit profiles. ZYRA Basic "
              'includes $_dailyProfileLimit every 4 hours — check back '
              'shortly, or upgrade to ZYRA One for unlimited browsing.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  );
                },
                child: const Text('Upgrade to ZYRA One'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Not now', style: ZyraText.subtext()),
            ),
          ],
        ),
      ),
    );
  }

  // 2026-07-27 — Save/Consider entitlement caps (see zyraBasicSaveLimit/
  // zyraBasicConsiderLimit/zyraOneSaveLimit doc comments above). Same visual
  // language as _showLimitReachedModal but distinct copy — this isn't a
  // daily reset, it's a standing cap until upgrade.
  Future<void> _showCapReachedModal({
    required String action,
    required int limit,
    required String upgradeText,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      // FIXED 2026-08-01 (Founder: "the transparency is ok but look at
      // the edges, it looks like two extra transparent frames sticking
      // out"). Real, and it was a nesting mistake, not a colour one.
      //
      // `margin` sat on the Container INSIDE the ClipRRect, so the clip
      // and the blur described a rectangle 36pt wider on each side than
      // the bordered card. That outer rectangle still got blurred and
      // still got rounded corners — it just had no tint or border — so it
      // read as a second, ghostly frame around the real one.
      //
      // Padding now sits OUTSIDE the ClipRRect. Blur, clip and border all
      // describe exactly the same rectangle.
      builder: (dialogContext) => ZyraGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // REWRITTEN 2026-08-01 (Founder: "for ZYRA One Seeker
            // users show me how the message will appear since they
            // don't have to upgrade").
            //
            // A padlock is the wrong icon for someone already on the
            // top tier — it promises something purchasable behind
            // it, and there is nothing. They get the bookmark
            // instead: this is a full shortlist, not a locked door.
            Icon(
              AppState.instance.plan == ZyraPlan.one
                  ? Icons.bookmark_outline
                  : Icons.lock_outline,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(height: 14),
            Text(
              AppState.instance.plan == ZyraPlan.one
                  ? 'Your $action list is full'
                  : "You've reached your $action limit",
              style: ZyraText.heading(size: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              // FIXED 2026-07-27: this used to always say "ZYRA
              // Basic allows up to $limit" even when a ZYRA One
              // account hit ITS (higher) limit — wrong plan name
              // in that case. Now names whichever plan the limit
              // actually belongs to.
              //
              // FIXED AGAIN 2026-08-01: for a ZYRA One account the
              // two halves said the same thing twice — "ZYRA One
              // allows up to 15. That's the maximum for ZYRA One."
              // Worse, it was a dead end: it stated a rule and gave
              // no way forward. A Basic user has an action (upgrade);
              // a ZYRA One user had none, so the sentence has to
              // supply one. They can remove a Save — the cap is on
              // how many you hold, not how many you may ever make.
              // REWORDED 2026-08-01 (Founder, both branches).
              //
              // Basic: the number 15 is gone. Naming ZYRA One's exact
              // cap in an upgrade prompt turns a benefit into a
              // ceiling — the reader's next thought is "only 15?"
              // rather than "more". It also hard-couples marketing
              // copy to a constant that has already changed once
              // today (50 -> 15).
              //
              // ZYRA One: the old line led with the count and the
              // rule. It now leads with what the person actually
              // wants — keeping this profile — and treats the
              // removal as the means, not the punishment. No number,
              // because they cannot change it and it isn't the point.
              AppState.instance.plan == ZyraPlan.one
                  ? 'To keep this profile, make space by removing a '
                        'Save in Connections.'
                  : "ZYRA Basic allows up to $limit. $upgradeText",
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // ZYRA One accounts can also hit their (much higher)
            // cap — showing "Upgrade to ZYRA One" when they
            // already hold it would be nonsensical, so that
            // button only appears for Basic.
            if (AppState.instance.plan == ZyraPlan.basic)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                    );
                  },
                  child: const Text('Upgrade to ZYRA One'),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppState.instance.plan == ZyraPlan.basic ? 'Not now' : 'OK',
                style: ZyraText.subtext(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2026-07-27 (Founder: "the orange line goes around the screen but
  // can u make it per model for example apple and samsung or google
  // phones where it wraps around the whole screen, u can see the edges
  // of the screen cut out the colour"). Honest limitation: Flutter (and
  // iOS/Android themselves) expose no API that returns a device's true
  // physical corner radius — there is no supported way to ask "is this
  // an iPhone 16 Pro or a Samsung S24" and look up its exact curvature.
  // Genuine per-model precision would need a hardcoded table of
  // hundreds of device models, which isn't standard practice and would
  // go stale with every new phone released. What IS achievable: a
  // platform + safe-area-inset heuristic — the size of the top inset is
  // a reasonable proxy for which "generation" of hardware shape a
  // device has (Dynamic Island vs notch vs neither), which loosely
  // tracks how aggressively rounded that generation's corners are. This
  // rounds the drag-glow border to approximate that, so it curves into
  // the physical corner instead of stopping in a hard 90° corner that
  // gets visually clipped by the real rounded glass — a closer wrap,
  // not an exact one.
  double _deviceCornerRadiusGuess(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        if (topInset >= 55) return 55; // Dynamic Island generation
        if (topInset >= 40) return 47; // notch generation
        return 20; // no notch/island (e.g. Touch ID iPhones) — squarer
      case TargetPlatform.android:
        // Varies more by individual model than iOS does, with no finer
        // signal available cross-platform than this — a reasonable
        // mid-range value across current flagship shapes.
        return 34;
      default:
        return 24;
    }
  }

  // Same hue family as the post-commit tint colours (DR-ZYRA-099's
  // 🔴🟡🟢 palette) — full opacity here since callers apply their own
  // .withValues(alpha: ) on top for the border-glow/pill intensity.
  Color _dragColor(_Decision d) => switch (d) {
    _Decision.pass => const Color(0xFFF47272),
    _Decision.save => const Color(0xFFEED26C),
    _Decision.consider => const Color(0xFF84C88E),
  };

  // DELETED 2026-08-01: _dragIcon(). It supplied the icon for the centred
  // decision badge, which the Founder removed ("I don't want the green
  // tick in the middle, that goes for save and decline also"). Nothing
  // has referenced it since. The no-heart-icons rule it encoded still
  // stands and is recorded in the UX docs, not here.

  String _dragLabel(_Decision d) => switch (d) {
    _Decision.pass => 'Pass',
    _Decision.save => 'Save',
    _Decision.consider => 'Consider',
  };

  // DELETED 2026-08-01: _showFlash() and the _flash field it drove.
  //
  // Once the centred decision badge was removed, nothing READ `_flash`.
  // The setter survived and kept running: two setState() rebuilds of the
  // whole Browse screen plus a 380ms Timer on every single pass, save and
  // consider — the three hottest interactions in the app — to update a
  // field no widget consulted. The note left at the badge's removal said
  // to delete it if nothing else ever consumed it. Nothing did.
  //
  // Post-commit feedback is unaffected: it comes from _BorderFlash via
  // `_burstDecision`, which is separate and still wired.

  // 2026-07-26 (Founder: swipe-dot "burst" on commit) — see
  // `_burstDecision`'s doc comment above for why this is separate from
  // the deleted `_showFlash`. 460ms rather than that flash's old 380ms so the burst ring
  // has time to fully expand and fade rather than being cut off.
  void _triggerBurst(_Decision d) {
    setState(() => _burstDecision = d);
    Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _burstDecision = null);
    });
  }

  /// Reports/blocks whoever is currently on the card. Advances past them
  /// on success — having just reported someone, seeing them still sitting
  /// there would be its own small failure.
  Future<void> _reportCurrentProfile() async {
    final profile = _current;
    if (profile == null) return;

    // Demo candidates (ids '1','2','3' from seeker_profile.dart) have no
    // profiles row, so both the report insert and the block would fail on
    // a uuid cast. Say that plainly instead of showing a generic failure
    // for something that could never have worked. Goes away with the mock
    // fallback itself — see ZyraReportService.isPersistableId.
    if (!ZyraReportService.isPersistableId(profile.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This is a demo profile — reporting works on real profiles.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final handled = await showReportProfileSheet(
      context,
      profileId: profile.id,
      firstName: profile.firstName,
      source: ZyraReportSource.browse,
    );
    if (handled != true || !mounted) return;

    // Drop them from the in-memory deck immediately. The RLS block means
    // they will not come back on the next fetch either, but the user
    // should not have to wait for a refetch to stop seeing them.
    setState(() {
      _allProfiles = _allProfiles.where((p) => p.id != profile.id).toList();
      if (_index >= _profiles.length) _index = _profiles.length;
      _photoIndex = 0;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Thanks. You won't see ${profile.firstName} again."),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Hides whoever is on the card, after a confirmation.
  ///
  /// ITS OWN ACTION SINCE 2026-08-13 (DR-ZYRA-155, Founder): it used to
  /// be a row at the bottom of the report sheet, which meant reaching a
  /// privacy preference by opening an accusation. "Keep the difference
  /// clear: Report Profile — safety/reporting concerns. Hide Profile —
  /// privacy/discovery preference."
  ///
  /// THE CONFIRMATION SAYS WHAT IT ACTUALLY DOES, and this is the part
  /// worth reading. The underlying call is ZyraReportService.block(),
  /// which is MUTUAL and permanent: it hides the two of you from each
  /// other everywhere, enforced in profiles_select's RLS. The sheet row
  /// it replaces said so — "hides you both" — and dropping that line
  /// while promoting the action to a top-level button would quietly
  /// turn a two-way, permanent block into something that reads like
  /// "don't show me this one". Whether a genuine one-way hide should
  /// exist is a real question and a schema change; raised as
  /// OA-ZYRA-217 rather than guessed at here.
  Future<void> _hideCurrentProfile() async {
    final profile = _current;
    if (profile == null) return;

    // Same demo-profile guard the report path carries, and for the same
    // reason: ids '1','2','3' have no profiles row, so the block would
    // fail on a uuid cast.
    if (!ZyraReportService.isPersistableId(profile.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This is a demo profile — hiding works on real profiles.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final confirmed = await showZyraGlassChoice(
      context: context,
      icon: Icons.visibility_off_outlined,
      title: 'Hide this profile?',
      body:
          "You and ${profile.firstName} won't see each other again. "
          'Nothing is reported and nobody is told.',
      primaryLabel: 'Hide Profile',
      secondaryLabel: 'Cancel',
    );
    if (confirmed != true || !mounted) return;

    final ok = await ZyraReportService.block(profile.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That didn't go through — try again.")),
      );
      return;
    }

    // Out of the deck now, not on the next fetch. The RLS block means
    // they will not return either, but waiting for a refetch to stop
    // seeing someone you just hid is its own small failure.
    setState(() {
      _allProfiles = _allProfiles.where((p) => p.id != profile.id).toList();
      if (_index >= _profiles.length) _index = _profiles.length;
      _photoIndex = 0;
    });
    // And out of the disk cache (DR-ZYRA-169): the server stops signing
    // their URLs from this moment; the cached bytes die with the
    // relationship instead of with the 7-day TTL. Fire-and-forget — an
    // eviction miss costs nothing a TTL doesn't already bound.
    ZyraImageCache.evictUrls(profile.photos);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Hidden. You won't see ${profile.firstName} again."),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Opens the Compatibility Unlock page for whoever is on the card.
  ///
  /// ADDED 2026-08-13 (DR-ZYRA-156). NOTHING NEW WAS DESIGNED: this is a
  /// door onto ProfileUnlockScreen, the same screen the Connections
  /// cards have always pushed, with the same profile argument. The
  /// screen already knows how to be both halves of itself — it reads
  /// profile_unlocks and shows what is held, so a profile already
  /// unlocked opens straight to the compatibility rather than to a
  /// price, and zyra_unlock_profile() refuses to charge twice
  /// regardless (it checks profile_unlocks BEFORE the credit balance).
  /// A second purchase surface here would have been a second thing to
  /// keep in step with the ledger, for no gain.
  ///
  /// `journeyRevealed` is deliberately left false. It is true only for
  /// a pair whose Journey already revealed the overall figure, which by
  /// definition cannot be someone still sitting in Browse.
  Future<void> _openCompatibilityForCurrent() async {
    final profile = _current;
    if (profile == null) return;

    // Same demo guard the report and hide paths carry: ids '1','2','3'
    // have no profiles row, so the unlock RPC would fail on a uuid cast
    // and show a generic error for something that could never work.
    if (!ZyraReportService.isPersistableId(profile.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This is a demo profile — compatibility works on real profiles.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileUnlockScreen(profile: profile)),
    );
  }

  /// BUG-02 (2026-08-14 audit, OA-ZYRA-225 — fixed 2026-08-15): the
  /// three decision writes below were fire-and-forget, so a failed
  /// insert meant the card advanced, the UI said done, and the decision
  /// was gone on next launch — a failed Like could silently prevent a
  /// match. The advance STAYS optimistic (yanking a card back
  /// mid-swipe would be worse than the failure); what changes is that
  /// a failure now says so and offers a retry, which is safe because
  /// all three writes are idempotent upserts.
  ///
  /// Demo and dev-scenario profiles never had a row to write and never
  /// will — the isPersistableId guard at each call site keeps them off
  /// this path entirely, exactly as the report/hide/unlock paths
  /// already do, so a stand-in can never trigger a real-looking error.
  void _decisionSaveFailed(String what, Future<bool> Function() retry) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Your $what didn't save — check your connection."),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () async {
            final ok = await retry();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? '$what saved.'
                      : "Still couldn't save — please try again later.",
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onPass() {
    if (_limitReached) {
      _showLimitReachedModal();
      return;
    }
    final profile = _current;
    if (profile != null) {
      AppState.instance.decline(profile);
      // ADDED 2026-08-01. Pass was the only decision that persisted
      // NOTHING — recordSave and recordLike both existed, this did not,
      // because there was no `passes` table to write to. So a decline
      // survived exactly as long as the app stayed open, and everyone
      // passed on came back on the next launch.
      if (ZyraReportService.isPersistableId(profile.id)) {
        ZyraDiscoveryService.recordPass(profile.id).then((ok) {
          if (!ok) {
            _decisionSaveFailed(
              'Pass',
              () => ZyraDiscoveryService.recordPass(profile.id),
            );
          }
        });
      }
    }
    Timer(const Duration(milliseconds: 280), () {
      if (mounted) _advance();
    });
  }

  void _onSave() {
    if (_limitReached) {
      _showLimitReachedModal();
      return;
    }
    // 2026-07-27 — Save cap by plan. Checked against the CURRENT saved
    // count before adding — AppState.save() itself is a no-op if the
    // profile's already saved, so this only ever blocks genuinely new
    // saves once at the cap, not re-saves.
    final saveLimit = AppState.instance.plan == ZyraPlan.one
        ? zyraOneSaveLimit
        : zyraBasicSaveLimit;
    // The dev panel no longer forces this branch — it requests the modal
    // directly (see _onDevPopupRequested). A sticky force flag here meant
    // every Save for the rest of the session hit the cap.
    if (AppState.instance.saved.length >= saveLimit) {
      _showCapReachedModal(
        action: 'Save',
        limit: saveLimit,
        // Only read on the Basic branch now — the ZYRA One copy is
        // written inside the modal, since it needs to offer an action
        // rather than restate the cap.
        //
        // Deliberately does NOT name zyraOneSaveLimit (Founder 2026-08-01:
        // "don't write 15, write save more"). Right call twice over: it
        // stops an upgrade prompt reading as a ceiling, and it decouples
        // this sentence from a constant that changed today.
        upgradeText: 'Upgrade to ZYRA One to save more.',
      );
      return;
    }
    final profile = _current;
    if (profile != null) {
      AppState.instance.save(profile);
      // BUG-02: failure surfaces with a retry — see _decisionSaveFailed.
      if (ZyraReportService.isPersistableId(profile.id)) {
        ZyraDiscoveryService.recordSave(profile.id).then((ok) {
          if (!ok) {
            _decisionSaveFailed(
              'Save',
              () => ZyraDiscoveryService.recordSave(profile.id),
            );
          }
        });
      }
    }
    // REMOVED 2026-07-27 (Founder screenshot: "when we do the save action
    // a message at bottom appears which does not need to be there") — the
    // yellow glass circle above already confirmed the Save (that circle
    // has since been removed too; the border flash now does the job)
    // action; this SnackBar was a redundant second confirmation.
    Timer(const Duration(milliseconds: 280), () {
      if (mounted) _advance();
    });
  }

  void _onConsider() {
    if (_limitReached) {
      _showLimitReachedModal();
      return;
    }
    // 2026-07-27 — Consider ("like") cap by plan. ZYRA One is
    // unlimited (Founder: "like is unlimited") — skipped entirely for
    // that plan rather than checked against a very large number.
    if (AppState.instance.plan == ZyraPlan.basic &&
        AppState.instance.outgoingLikes.length >= zyraBasicConsiderLimit) {
      _showCapReachedModal(
        action: 'Consider',
        limit: zyraBasicConsiderLimit,
        upgradeText: 'Upgrade to ZYRA One for unlimited Considers.',
      );
      return;
    }
    final profile = _current;
    if (profile == null) {
      return;
    }
    final isMatch = AppState.instance.like(profile);
    // BUG-02: this is the write that makes matches exist —
    // create_match_on_mutual_like only fires off a row that lands. A
    // failure surfaces with a retry; see _decisionSaveFailed.
    if (ZyraReportService.isPersistableId(profile.id)) {
      ZyraDiscoveryService.recordLike(profile.id).then((ok) {
        if (!ok) {
          _decisionSaveFailed(
            'Consider',
            () => ZyraDiscoveryService.recordLike(profile.id),
          );
        }
      });
    }
    Timer(const Duration(milliseconds: 280), () {
      // 2026-08-12: this one-shot outlives the screen if the user leaves
      // Browse inside the 280ms window; pushing from a dead context threw.
      if (!mounted) return;
      if (isMatch) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MatchNotificationScreen(
              matchedWith: profile,
              onViewMatch: () {
                Navigator.of(context).pop();
                widget.onNavigateToConnections?.call();
              },
            ),
          ),
        );
      }
      _advance();
    });
  }

  void _tapPhoto(TapUpDetails details, double width) {
    final profile = _current;
    if (profile == null || profile.photos.length <= 1) return;
    final goRight = details.localPosition.dx > width / 2;
    setState(() {
      if (goRight) {
        _photoIndex = _photoIndex >= profile.photos.length - 1
            ? 0
            : _photoIndex + 1;
      } else {
        _photoIndex = _photoIndex <= 0 ? 0 : _photoIndex - 1;
      }
    });
  }

  // --- Swipe gesture handling (DR-ZYRA-099) ---------------------------

  void _onPanStart(DragStartDetails details) {
    _dragStartGlobal = details.globalPosition;
    _dragCommitted = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStartGlobal == null) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  // --- Live drag-direction preview (2026-07-26 swipe redesign) --------
  //
  // Founder feedback: "the current swiping action is not nice... I kinda
  // want the traffic light colour implements. Green if u swipe positive.
  // Yellow if u save and red if u skip." Previously the only feedback
  // during a drag was the card itself moving — the traffic-light colour
  // only appeared as a brief post-commit flash (_showFlash). This
  // computes the same _Decision + an intensity (0-1, capped at the
  // commit threshold) continuously while dragging, so the card can show
  // a live colour wash + label as the finger moves, the same real-time
  // feedback pattern the Founder's own mockup reaction approved.
  //
  // Direction mapping matches DR-ZYRA-099 exactly (left=Consider,
  // right=Pass, down=Save) and _onPanEnd's own horizontal-dominance
  // check — this does not change which gesture means what, only adds
  // visible feedback while it's happening.
  _Decision? get _dragDecision {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    if (dx == 0 && dy == 0) return null;
    final horizontalDominant = dx.abs() > dy.abs();
    if (horizontalDominant) {
      if (dx < -12) return _Decision.consider;
      if (dx > 12) return _Decision.pass;
      return null;
    }
    if (dy > 12) return _Decision.save;
    return null;
  }

  double get _dragStrength {
    final decision = _dragDecision;
    if (decision == null) return 0;
    final distance = decision == _Decision.save
        ? _dragOffset.dy
        : _dragOffset.dx.abs();
    return (distance / _swipeCommitThreshold).clamp(0.0, 1.0);
  }

  void _onPanEnd(DragEndDetails details) {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    final horizontalDominant = dx.abs() > dy.abs();

    if (horizontalDominant && dx.abs() > _swipeCommitThreshold) {
      _commitSwipe(dx > 0 ? _Decision.pass : _Decision.consider);
    } else if (!horizontalDominant && dy > _swipeCommitThreshold) {
      _commitSwipe(_Decision.save);
    } else {
      // Below threshold — snap back to centre.
      setState(() => _dragOffset = Offset.zero);
    }
    _dragStartGlobal = null;
  }

  void _commitSwipe(_Decision decision) {
    if (_dragCommitted) return;
    _dragCommitted = true;
    _triggerBurst(decision);
    // Fling the card the rest of the way off-screen in the swipe
    // direction, then run the matching action exactly as the old
    // button handlers did.
    final flingTarget = switch (decision) {
      _Decision.pass => const Offset(600, 0),
      _Decision.consider => const Offset(-600, 0),
      _Decision.save => const Offset(0, 900),
    };
    setState(() => _dragOffset = flingTarget);
    switch (decision) {
      case _Decision.pass:
        _onPass();
      case _Decision.save:
        _onSave();
      case _Decision.consider:
        _onConsider();
    }
    // Reset the drag offset once _advance() (called by the handlers
    // above, after their own short delay) has moved on to the next
    // profile, so the new card doesn't inherit the old one's fling
    // position.
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _dragOffset = Offset.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 2026-07-26 (OA-ZYRA-121, DR-ZYRA-109) — sponsored slot takes over
    // the whole card area, same full-bleed shape as a real profile so
    // the frequency cap reads naturally within this swipe-deck UI, but
    // with deliberately different chrome (rule 6) and its own dismiss
    // button rather than the swipe-decision gestures.
    if (_showingSponsoredCard) {
      return _SponsoredCard(onDismiss: _dismissSponsoredCard);
    }
    // 2026-07-27 — see _allProfiles/_loadingCandidates doc comment
    // above. Real candidates (or fetchCandidates()'s own mockProfiles
    // fallback, when that's genuinely the correct result) only ever
    // render once this is false, so a stale hardcoded profile is never
    // shown mid-fetch.
    if (_loadingCandidates) {
      return Container(
        decoration: BoxDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: const ZyraLoading(),
      );
    }
    final profile = _current;
    // 2026-07-25, DR-ZYRA-101 audit item 1 (Founder decision: "switch
    // to gradient"): gender-matched gradient, not flat — Browse is
    // only ever reached by a signed-in, onboarded Seeker, so gender is
    // always known here, same as every other profile-context screen
    // fixed under DR-ZYRA-101 (ZyraColors.genderGradient()).
    return Container(
      decoration: BoxDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed photo, edge to edge — no outer padding, no rounding.
          if (profile == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── THE GATE HAS TO SPEAK FIRST. 2026-08-11,
                    // OA-ZYRA-193(c). An unfinished Seeker is not shown
                    // anyone, by design — but "You're all caught up" would
                    // then be a lie told to the one person who can fix it,
                    // and "More profiles will appear as new members join"
                    // would be worse: it blames the population for a door
                    // they are standing in front of.
                    Icon(
                      _gated
                          ? Icons.edit_note_outlined
                          : _filterActive
                          ? Icons.filter_alt_off_outlined
                          : Icons.check_circle_outline,
                      color: Colors.white38,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _gated
                          ? 'A few questions left'
                          : _filterActive
                          ? 'No one matches your age filter'
                          : 'You\'re all caught up',
                      style: ZyraText.heading(size: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _gated
                          ? (_missingCount == 1
                                ? 'One question is still unanswered. ZYRA introduces '
                                      'people on what you have both said, so nobody is '
                                      'shown until yours is complete.'
                                : '$_missingCount questions are still unanswered. ZYRA '
                                      'introduces people on what you have both said, so '
                                      'nobody is shown until yours is complete.')
                          : _filterActive
                          ? 'Try widening the range, or clear it to see everyone again.'
                          : 'More profiles will appear as new members join.',
                      style: ZyraText.subtext(),
                      textAlign: TextAlign.center,
                    ),
                    if (_gated) ...[
                      // No button yet: the onboarding flow has no resume
                      // entry point to send them to, and a button that goes
                      // nowhere is worse than none. Raised as its own action
                      // rather than faked here.
                    ] else if (_filterActive) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _minAge = null;
                          _maxAge = null;
                          _index = 0;
                          _photoIndex = 0;
                        }),
                        child: Text(
                          'Clear filter',
                          style: ZyraText.button(size: 13),
                        ),
                      ),
                    ] else ...[
                      // 2026-07-27 (Founder: "when it says your all
                      // caught up. there should be a button to say reset
                      // search whihc thenm takes them back to browser
                      // and shows all profiles they either skipped or
                      // saved"). Reaching this empty state means _index
                      // has already advanced past every candidate in
                      // _profiles — nothing is filtered OUT of that list
                      // today (Pass/Save/Consider only move _index
                      // forward, they don't remove anyone from
                      // _allProfiles), so restarting from 0 naturally
                      // re-shows exactly that same full set, everyone in
                      // it having already been Passed, Saved, or
                      // Considered. Deliberately does NOT reset _viewed
                      // (the daily limit counter) — re-browsing already-
                      // seen profiles isn't new content for that purpose.
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _index = 0;
                          _photoIndex = 0;
                        }),
                        child: Text(
                          'Reset search',
                          style: ZyraText.button(size: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                onTapUp: (d) => _tapPhoto(d, constraints.maxWidth),
                // Long-press keeps ONLY the photo-dim feedback since
                // 2026-08-13 (DR-ZYRA-150): the centre-hold menu it
                // used to open retired with the ⋮ — a visible button
                // beat a hidden 800ms gesture, the Founder's call.
                onLongPressStart: (_) => setState(() => _interacting = true),
                onLongPressEnd: (_) => setState(() => _interacting = false),
                // Swipe gestures (DR-ZYRA-099) — left = Consider, right =
                // Pass, down = Save. Coexists with the tap/long-press
                // recognisers above: a plain tap has no meaningful pan
                // delta, so onPanEnd's threshold check below simply does
                // nothing and the tap fires normally.
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                // 2026-07-26 (Founder: "I don't like how the swiping
                // effect is... if u swipe it doesn't actually show a
                // swiping action where photo moves but rather the
                // colour scheme shows the user they are going that
                // way"). The photo card previously translated + rotated
                // with the drag (Matrix4.identity()..translate()
                // ..rotateZ()) via an AnimatedContainer wrapper here —
                // removed entirely per that instruction. The card now
                // stays completely fixed in place; the border glow + top
                // pill below (both still driven by _dragColor/
                // _dragStrength, untouched here) are the sole direction
                // feedback. _dragOffset itself is kept — it still drives
                // _dragDecision/_dragStrength's intensity maths and
                // _commitSwipe's brief post-commit hold — only its use
                // for physically positioning the card is gone.
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 2026-07-26 (Founder: "the pictures load a lot
                    // better now but sometimes there's a slight delay so
                    // I see the blue/purple background... maybe add a
                    // loading message/icon/animation"). The spinner moved
                    // into ZyraProfileImage 2026-08-03 behind
                    // `showLoader`, unchanged in appearance — but it now
                    // only runs for network photos. A dev colour block
                    // paints instantly and would otherwise flash a
                    // spinner on every single card.
                    // FIXED 2026-08-05 (Founder: "when I click view profile
                    // for family suggestions it goes to Browse and it's just
                    // a white page").
                    //
                    // This was a bare `profile.photos[_photoIndex]`. Two ways
                    // it threw a RangeError, and a RangeError inside build()
                    // paints nothing — hence a white screen rather than an
                    // error:
                    //
                    //   1. photos was EMPTY. Guardian Suggestions build their
                    //      SeekerProfile from whatever photos signed, and
                    //      before today's storage-policy fix that could be
                    //      none. "View profile" then pushed a photoless
                    //      person straight into this card.
                    //   2. _photoIndex was left over from the PREVIOUS
                    //      profile. Jumping to a suggestion while parked on
                    //      photo 4 of someone with five photos lands on a
                    //      person who has two.
                    //
                    // The policy fix addresses the cause of (1); this
                    // addresses the consequence of both, permanently. A
                    // missing photo is a placeholder, never a blank screen.
                    ZyraProfileImage(
                      profile.photos.isEmpty
                          ? ''
                          : profile.photos[_photoIndex < profile.photos.length
                                ? _photoIndex
                                : 0],
                      showLoader: true,
                    ),
                    // Top gradient — status bar / glass button legibility.
                    Container(
                      alignment: Alignment.topCenter,
                      height: 130,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x66000000), Colors.transparent],
                        ),
                      ),
                    ),
                    // Bottom gradient — identity block legibility.
                    //
                    // STRENGTHENED 2026-08-07, modestly and on purpose. The
                    // identity block sits 130px up, so at the old 300px /
                    // 0x40-at-0.4 the NAME was landing on 17% black: 1.48:1
                    // against a white photo. Now 340px tall with the mid
                    // stop moved up and darkened, which puts the name on 32%
                    // — 2.24:1.
                    //
                    // That still does not reach 3:1, and it is not meant to.
                    // Getting there by scrim alone needs 42% black at the
                    // name's height and washes out the bottom third of every
                    // photo on the platform. The shadows carry the rest —
                    // see kZyraOnPhotoTextShadows for the measurements and
                    // reasoning. This half just stops the small text having
                    // to do it alone.
                    //
                    // Still fully transparent at the top of the band, so
                    // nothing above the identity block is dimmed at all.
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 340,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x4D000000),
                              Color(0xB3000000),
                            ],
                            stops: [0.0, 0.32, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Live drag-direction feedback (2026-07-26 swipe
                    // redesign) — a soft edge glow + top pill label,
                    // rather than a full-photo colour flood, per the
                    // Founder's "more light and simple" note: the photo
                    // stays fully visible underneath, the traffic-light
                    // colour reads at the edges and in the pill instead
                    // of washing over the person's face. IgnorePointer
                    // since this sits above the GestureDetector's own
                    // hit-testing area but must never intercept taps.
                    // 2026-07-27 (3rd pass, Founder, screenshot-driven:
                    // "i like how the colour now wraps around the whole
                    // frame... i think we get rid of the dots"). Now
                    // wrapped in Semantics here, since the drag-preview
                    // dot clusters that used to carry _dragLabel for
                    // screen readers (below, now removed) are gone —
                    // this border glow is the sole live drag-direction
                    // feedback, so it's the one that carries the label.
                    if (_dragDecision != null)
                      Semantics(
                        label: _dragLabel(_dragDecision!),
                        child: IgnorePointer(
                          // THE SHIPPED RIM — restored as the only
                          // treatment, every build (DR-ZYRA-193; the
                          // Founder retired the DR-ZYRA-187 lab after
                          // testing its twelve options: "revert back to
                          // original"). The commit flash (_BorderFlash)
                          // is separate and untouched.
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              // 2026-07-27: rounded to approximate
                              // this device's physical corner shape
                              // — see _deviceCornerRadiusGuess's
                              // doc comment.
                              borderRadius: BorderRadius.circular(
                                _deviceCornerRadiusGuess(context),
                              ),
                              border: Border.all(
                                color: _dragColor(_dragDecision!).withValues(
                                  alpha: 0.15 + _dragStrength * 0.55,
                                ),
                                width: 3 + _dragStrength * 5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // REMOVED 2026-07-27 (3rd pass, Founder: "i like how
                    // the colour now wraps around the whole frame
                    // meaning i think we get rid of the dots and the
                    // animation happens on the outer rim when thumb is
                    // removed for execution"). The 3 fixed-position dot
                    // clusters that lived here through 3 prior passes
                    // (text pill → single growing dot → 4-dot cluster,
                    // see git history / prior comments for that lineage)
                    // are gone outright — the border glow above is now
                    // the only live drag feedback, and the commit
                    // animation (_burstDecision, below in this file) is
                    // now _BorderFlash — a flash on that same border
                    // rim, not a ring at a fixed x/y spot. _SwipeDots
                    // class removed with it; _dragLabel/_dragColor are
                    // untouched (still used above and by _BorderFlash).
                    // Left-side vertical photo dots (matches source: left, not right).
                    if (profile.photos.length > 1)
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: _interacting ? 0.35 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(profile.photos.length, (
                                i,
                              ) {
                                final active = i == _photoIndex;
                                // 2026-07-27 (Founder: "zyra one account
                                // users can upload a video... on the left
                                // side dots area which shows number of
                                // photos for a video its a play button
                                // like the right face triangle") — mockup
                                // only, see SeekerProfile.videoPhotoIndex's
                                // doc comment. Slightly larger than a
                                // plain dot (9px vs 7px) so the triangle
                                // has room to read; icon colour inverts
                                // against the fill the same way the dot's
                                // own fill/backdrop contrast already
                                // works (dark glyph on the white active
                                // fill, light glyph on the dim inactive
                                // fill) so it stays legible in both states.
                                if (profile.videoPhotoIndex == i) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    width: 9,
                                    height: 9,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 0.5,
                                      ),
                                      color: active
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.32,
                                            ),
                                    ),
                                    child: Icon(
                                      Icons.play_arrow,
                                      size: 7,
                                      color: active
                                          ? ZyraColors.luxuryDarkPurple
                                          : Colors.white,
                                    ),
                                  );
                                }
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 0.5,
                                    ),
                                    color: active
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.32),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    // Identity block — bottom-left, large name/age/location.
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 130,
                      child: AnimatedOpacity(
                        opacity: _interacting ? 0.35 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SAVED BADGE REMOVED 2026-08-03.
                            //
                            // It existed because a saved profile stayed
                            // in the Browse deck under the two-axis
                            // model — a bookmark was not a decision, so
                            // you could meet them again and the badge
                            // explained why.
                            //
                            // With one state per profile, saving IS
                            // acting on someone: they leave the deck
                            // like a Consider or a Pass. This branch
                            // became unreachable, so it goes rather than
                            // sitting here looking load-bearing.
                            // GUARDIAN SUGGESTION BADGE — 2026-08-05
                            // (Founder: "a guardian suggested a person but
                            // a person was browsing anyway and saw a person
                            // guardian suggested, or they clicked the link
                            // the guardian suggested for that profile — I
                            // need somewhere in Browse, maybe above the
                            // navigation bar, the words guardian
                            // suggestion").
                            //
                            // Shown whichever way you arrived: tapping
                            // through from Connections, or simply reaching
                            // them in the deck. The fact belongs to the
                            // person, not to the route — meeting someone
                            // your Guardian put forward should feel the
                            // same either way.
                            //
                            // Sits directly above the name rather than
                            // floating over the photo, so it reads as part
                            // of who they are rather than an alert.
                            if (AppState.instance.suggestedBy(profile.id) !=
                                null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Suggested by ${AppState.instance.suggestedBy(profile.id)}',
                                      style: ZyraText.subtext(
                                        size: 11.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            // THE SHARED BLOCK — DR-ZYRA-163. Browse
                            // is where this design was decided
                            // (DR-ZYRA-162, option C of five), and it is
                            // now one widget so the three Connections
                            // surfaces draw the same thing rather than
                            // three approximations of it.
                            ZyraProfileNameBlock(profile: profile),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // OA-ZYRA-125 §5: the "X/50 profiles" counter chip that used to
          // sit here permanently is removed. The limit now only ever
          // surfaces as the modal in _showLimitReachedModal(), triggered
          // right when the limit is hit — see _advance() and the
          // _limitReached guards in _onPass/_onSave/_onConsider.

          // REMOVED 2026-08-01 (Founder: "I don't want the green tick in
          // the middle, that goes for save and decline also"). The centred
          // GlassFlashCircle covered the person's face at the exact moment
          // the user was deciding about them, and duplicated feedback the
          // border flash below already gives around the whole frame —
          // which the Founder has said he likes. Two confirmations for one
          // action, one of them landing on top of the face.
          //
          // _flash / _showFlash were deleted 2026-08-01 — once the badge
          // went, nothing read them. See their note further up.

          // 2026-07-27 (3rd pass, Founder, screenshot-driven: "i like
          // how the colour now wraps around the whole frame meaning i
          // think we get rid of the dots and the animation happens on
          // the outer rim when thumb is removed for execution"). Was 3
          // fixed-position expanding rings (_SwipeBurst), one per
          // direction, each anchored to that direction's now-removed dot
          // cluster. Replaced by a single _BorderFlash — one flash on
          // the same full-perimeter border the live drag glow already
          // draws (_deviceCornerRadiusGuess's rounding matched here so
          // the flash sits exactly where the glow was), colour-coded via
          // `_dragColor(_burstDecision!)`. Only needs one `if` now since
          // it's no longer tied to a fixed x/y spot per direction —
          // Positioned.fill instead of the old Positioned(top/bottom/
          // right: ...) blocks, since this wraps the whole card rather
          // than a small ring near one edge. Kept at this same top
          // level, sibling to the decision flash above, for the same
          // reason the old burst was: driven by `_burstDecision` rather
          // than `_dragDecision` so it survives `_advance()` switching
          // profiles partway through the animation, which nesting it
          // inside the swappable card would cut short.
          if (_burstDecision != null)
            Positioned.fill(
              child: IgnorePointer(
                child: _BorderFlash(
                  color: _dragColor(_burstDecision!),
                  borderRadius: _deviceCornerRadiusGuess(context),
                ),
              ),
            ),

          // 2026-07-25, DR-ZYRA-099: the floating glass action-button row
          // (Pass/Save/Consider buttons) is removed here per the Founder's
          // explicit "stick with swiping actions for cleaner UI" decision.
          // All three actions are now reachable only via the swipe
          // gestures wired into the GestureDetector above (_onPanEnd /
          // _commitSwipe) — see this file's header comment for the
          // full DR-ZYRA-099 rationale.

          // REMOVED 2026-07-26 (Founder, reviewing this page: "that's
          // not needed cos they can change that in setting/onboarding").
          // Checked first, per standing process, rather than removing on
          // request alone: grepped onboarding/ and settings/ for any
          // existing age-range control — there isn't one anywhere else
          // in the app today. This icon was the ONLY way to set an age
          // range, so the capability is gone until it's rebuilt somewhere
          // (Settings, most likely) — flagged back to the Founder rather
          // than silently dropping it. _openFilterSheet/_minAge/_maxAge/
          // _filterActive deliberately left in the class, unused, rather
          // than deleted — cheap to wire to a new entry point later,
          // expensive to rebuild from nothing.
          //
          // Bell + Help/Report menu both now live at HomeShell level,
          // stacked top-right as anchored cards (see home_shell.dart,
          // widgets/notification_bell.dart) — not in this top-left slot
          // any more as of the 2026-07-26 Bell/3-dot reposition pass.
          // THE ⋮ — 2026-08-13 (DR-ZYRA-150, Founder: "put 3 dots on
          // top right. if click the nav bar changes… becomes 2 pills").
          // The visible door that replaced the centre-hold: it hands
          // the shell what Report should mean right now — whoever is
          // on the card — and the shell's action bar does the rest.
          // Sponsored takeovers return before this Stack builds, so
          // the ⋮ hides with the rest of the chrome for free. Last
          // child on purpose: it must sit above every layer of card
          // chrome.
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                // NO GLASS CIRCLE — 2026-08-13 (DR-ZYRA-153, Founder:
                // "you see in Browse we have 3 dots with outer circle,
                // remove the outer circle"). GlassIconButton is left
                // alone: it is the shared component behind the Bell and
                // the Guardian's buttons, and removing its circle there
                // would strip three controls to answer a note about one.
                //
                // THE SHADOW IS NOT DECORATION. The circle was doing a
                // second job nobody asked it to — it carried its own
                // contrast, so the glyph stayed legible over a bright
                // photo. Bare white dots on a pale headshot disappear.
                // A soft dark drop shadow buys that contrast back at a
                // fraction of the visual weight.
                //
                // Sized to a 40pt box, matching what GlassIconButton
                // occupied, so the tap target does not shrink with the
                // circle — the icon is 24pt inside it.
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onOpenActions?.call((
                    report: _reportCurrentProfile,
                    hide: _hideCurrentProfile,
                    compatibility: _openCompatibilityForCurrent,
                  )),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.more_horiz,
                      size: 24,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Color(0x8C000000), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-shot flash on the card's full-perimeter border — the commit-time
/// animation that plays when a swipe is released.
///
/// 2026-07-27 (3rd pass, Founder, screenshot-driven: "i like how the
/// colour now wraps around the whole frame meaning i think we get rid
/// of the dots and the animation happens on the outer rim when thumb is
/// removed for execution"). Replaces the old _SwipeDots (live drag
/// preview) + _SwipeBurst (commit-time ring at one of 3 fixed dot
/// positions) pair entirely. The persistent border glow drawn inline in
/// build() is now the only live-drag feedback; this is the only
/// commit-time animation, and it plays on that same border rather than
/// at a fixed x/y spot. [borderRadius] is passed in from
/// _deviceCornerRadiusGuess so the flash sits exactly on that glow's own
/// rounding instead of guessing its own.
///
/// A fresh instance is only ever mounted while `_burstDecision` is
/// non-null (see that field's own doc comment + the single call site
/// above), so `TweenAnimationBuilder` naturally plays once from 0→1 and
/// is removed when `_burstDecision` resets — no AnimationController/
/// ticker bookkeeping needed, same pattern _SwipeBurst used.
class _BorderFlash extends StatelessWidget {
  final Color color;
  final double borderRadius;
  const _BorderFlash({required this.color, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (context, v, child) {
        final fade = (1 - v).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              // Starts thick and bright, thins as it fades — a flash on
              // the rim, not a steady-state ring — 10px down to 3px
              // over the 450ms life of the animation.
              color: color.withValues(alpha: fade),
              width: 10 - 7 * v,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: fade * 0.6),
                blurRadius: 16 * v,
                spreadRadius: 2 * v,
              ),
            ],
          ),
        );
      },
    );
  }
}

// 2026-07-27 (3rd pass, Founder, screenshot-driven). Was two separate
// interstitials firing at two different frequencies — _SponsoredCard
// below (governed by ADVERTISING_STANDARD_CURRENT_VERSION_V1.md) and
// _UpgradeNudgeCard (ZYRA's own upgrade pitch) — which is exactly what
// the Founder flagged: "when i swiped 5 more i saw a new pop up...
// check if theres 2 advert placeholders and if so only keep one cos
// theres a error there somewhere." Not a bug — both were firing exactly
// as designed — but the fix is the same either way: one interstitial,
// not two. _UpgradeNudgeCard is deleted; _SponsoredCard below absorbs
// its Continue/Upgrade button row (with the text-wrap bug that row had
// fixed, see that class) and drops the ZYRA Basic/One numeric copy per
// "its a advert so u dont need to say zyra basic... saves upto 10 ect".
// _showingUpgradeNudge/_dismissUpgradeNudge/_upgradeNudgeFrequency are
// all gone with it.
//
// 2026-07-26 (OA-ZYRA-121, DR-ZYRA-109) — sponsored card placeholder.
//
// Implements the design/placement decisions from ADVERTISING_STANDARD_
// CURRENT_VERSION_V1.md against this specific full-screen swipe-deck
// UI (the Standard's own language — "sponsored cards within the
// profile feed" — was written before this deck existed in its current
// single-card-at-a-time form; this is the concrete translation of
// that rule onto it):
//   - Rule 1 (Browse/Discovery only): only ever shown from within this
//     screen, inserted in the same full-bleed slot a real candidate
//     would occupy — never on Guardians/Wali screens, Journey stages,
//     or messaging, since this widget is only ever constructed here.
//   - Rule 5 (~every 5 interactions): triggered by
//     _sponsoredCardFrequency in _advance() above — CORRECTED 2026-07-27
//     from ~10 to 5 when this card absorbed _UpgradeNudgeCard's own
//     frequency along with its button row (ADVERTISING_STANDARD_
//     CURRENT_VERSION_V1.md corrected to match, same day).
//   - Rule 6 (visually distinct, clear "Sponsored" label, no ambiguity
//     with a real profile): deliberately NOT a photo — a solid-tint
//     card with an icon, an explicit "Sponsored" pill, and Continue/
//     Upgrade buttons instead of the three-way swipe-decision gesture.
//   - Model Overview (ZYRA One = completely ad-free): this widget is
//     only ever reached via the plan check in _advance() — ZYRA One
//     accounts never trigger _showingSponsoredCard in the first place.
//
// NO real ad network is integrated here — Phase 1 (ADVERTISING_
// STANDARD's own phase model) requires a certified ad network account
// with a category blocklist, which doesn't exist yet. Per the Founder's
// "make a fake advert for the other app my islamic contract, a simple
// mockup" — the body content below is a concrete example creative (a
// fictional app, "My Islamic Contract") standing in for where a real,
// vetted sponsor's own creative will go once Phase 1 is built, instead
// of an abstract "reserved for a sponsor" message. Still labelled as an
// example, not a live partnership — same "preview build" honesty
// pattern used elsewhere in this app for other unbuilt real-money paths
// (e.g. subscription mock-purchase buttons).
/// One benefit line inside the sponsor's creative. Gold tick on the
/// sponsor's own palette, not ZYRA's — see the creative's own note.
class _AdBenefit extends StatelessWidget {
  final String text;
  const _AdBenefit(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 15, color: Color(0xFFC9A227)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: ZyraText.body(size: 12.5, color: const Color(0xE6FFFFFF)),
          ),
        ),
      ],
    );
  }
}

class _SponsoredCard extends StatelessWidget {
  final VoidCallback onDismiss;
  const _SponsoredCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      // CHANGED 2026-08-01 (Founder: "if the advert will be a square
      // because of Google ad settings and doesn't take full screen, that
      // means the background can't be black as it is now").
      //
      // The reasoning is right and it matters more than it sounds. Google's
      // MEDIUM_RECTANGLE unit is 300x250 — on a 6.7" phone that is roughly
      // a third of the screen. The other two thirds are THIS colour, so it
      // is not a border, it is most of the view. ZYRA has no black
      // anywhere; a black screen doesn't read as "an advert inside ZYRA",
      // it reads as something having gone wrong.
      //
      // Luxury Dark Purple, not genderGradient(). The old comment here was
      // right that rule 6 of ADVERTISING_STANDARD ("no ambiguity between a
      // match and an advertisement") argues against wearing the profile
      // gradient — a full purple gradient is exactly what a profile card
      // sits on. #3D2A4A keeps that separation while still being a ZYRA
      // colour: it is the tone every ratified gradient already ends in
      // (DR-ZYRA-094), so the screen is continuous with the app rather
      // than a hole punched through it.
      //
      // Separation now rests where it should — on the SPONSORED label and
      // on the creative's own clashing brand palette, not on making the
      // whole screen ugly.
      color: ZyraColors.luxuryDarkPurple,
      child: SafeArea(
        // REBUILT 2026-08-01 (Founder chose the blend of layouts 1 and 5,
        // variant B: "skip at top right... but still an upgrade to ZYRA
        // One is somewhere needed"). Three changes from the old version:
        //
        //   1. SPONSORED moves to a header row on the left, with Skip
        //      opposite it top-right. Previously the label floated in the
        //      middle of the page above the creative and there was no way
        //      out except the buttons at the bottom.
        //   2. The sponsor's creative sits centred in the space that
        //      frees up, rather than the whole page being one centred
        //      column with large empty margins top and bottom.
        //   3. The two bottom buttons stack instead of sitting side by
        //      side, and swap emphasis — see the Row->Column note there.
        child: Column(
          children: [
            // Header: attribution left, exit right.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SPONSORED',
                    style: ZyraText.subtext(
                      size: 11,
                      color: Colors.white54,
                    ).copyWith(letterSpacing: 1.2),
                  ),
                  // Skip is a real, always-visible exit — not buried in
                  // the buttons at the bottom. An ad you cannot leave
                  // from the moment it appears is the thing that makes
                  // interstitials hated.
                  TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Skip',
                      style: ZyraText.body(size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 2026-07-27: example-creative mock-up (see class doc
                    // comment) — a small "app icon" tile instead of the old
                    // generic megaphone, so it reads as a specific advert
                    // rather than an abstract ad-slot placeholder.
                    // CREATIVE REBUILT 2026-08-01 (Founder: "please show
                    // the advert like it's an advert — make a mock-up
                    // advert like how an advertiser will show it").
                    //
                    // The old version was a 64px grey icon tile, a title
                    // and two lines of body — an ad SLOT rather than an
                    // ad. No advertiser buys a placement and then fills
                    // it with the host app's own UI kit.
                    //
                    // This is a full creative: the sponsor's own brand
                    // colours (deep green + gold, deliberately nothing
                    // like ZYRA's purple), a hero panel, a logo lockup,
                    // a headline, and benefit lines. The point of the
                    // clashing palette is not decoration — it is rule 6
                    // of ADVERTISING_STANDARD ("no ambiguity between a
                    // match and an advertisement"). An advert that used
                    // ZYRA's own colours would be doing the opposite.
                    //
                    // STILL A MOCK-UP. Nothing here is a real sponsor and
                    // the disclosure line below says so on screen. When
                    // real placements exist, this whole block becomes
                    // data (image URL, headline, body, brand colour, CTA
                    // label, destination) fetched per-placement — the
                    // layout stays, the content stops being hardcoded.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0F4A3C), Color(0xFF06231D)],
                        ),
                        border: Border.all(
                          color: const Color(
                            0xFFC9A227,
                          ).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC9A227),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.balance,
                                  color: Color(0xFF06231D),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Text(
                                'Aman Wills',
                                style: ZyraText.heading(
                                  size: 15,
                                  color: const Color(0xFFF3E4B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Your family,\nprotected properly.',
                            style: ZyraText.heading(
                              size: 25,
                            ).copyWith(height: 1.25),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'A Shariah-compliant will, written with you in under '
                            '20 minutes. Reviewed by scholars and UK solicitors.',
                            style: ZyraText.subtext(
                              size: 13,
                              color: const Color(0xCCFFFFFF),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          const _AdBenefit('Fixed £90 — no hidden fees'),
                          const SizedBox(height: 8),
                          const _AdBenefit('Faraid shares calculated for you'),
                          const SizedBox(height: 8),
                          const _AdBenefit('Update it free for life'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Example creative — design mock-up only, not a live sponsor.',
                      style: ZyraText.subtext(
                        size: 10.5,
                        color: Colors.white38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Row -> Column, 2026-08-01. Two changes worth being
                    // explicit about, because they reverse an earlier
                    // decision:
                    //
                    // STACKED, not side by side. Two pills of similar
                    // weight sitting next to each other made it genuinely
                    // unclear which belonged to the sponsor and which to
                    // ZYRA — against ADVERTISING_STANDARD rule 6 ("no
                    // ambiguity between a match and an advertisement").
                    // Stacked and styled differently, the sponsor's CTA
                    // is filled and ZYRA's is outlined, so whose is whose
                    // is readable at a glance.
                    //
                    // The old "Continue" is gone: it did the same thing
                    // as Skip, which now lives in the header. One exit,
                    // not two labelled differently.
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        // Placeholder — a real sponsor's own destination
                        // goes here. Dismisses for now rather than
                        // pretending to open something.
                        onPressed: onDismiss,
                        child: const Text('Learn more'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          onDismiss();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UpgradeScreen(),
                            ),
                          );
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Upgrade to ZYRA One — no ads',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
