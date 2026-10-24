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
// class did not know were changing. Reset now covers EVERY axis,
// enumerated in one place, with one notify.

import 'package:flutter/foundation.dart';
import '../data/zyra_entitlements.dart';
import '../data/zyra_journey_pause_state.dart';
import '../data/zyra_journey_stages.dart';
import '../models/journey_match.dart';
import '../models/seeker_profile.dart';
import '../models/zyra_dashboard_lab.dart';
import '../models/zyra_gender.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_developer_access.dart';
import '../services/zyra_wali_journey_service.dart';
import '../services/zyra_wali_link_service.dart';
import '../state/app_state.dart' show ZyraPlan;
import '../theme/zyra_colors.dart';

/// Which Seeker plan a control makes sense for.
enum DevPlan { basic, one }

/// Which page a control affects. A control is only usable while that page
/// is the one on screen.
enum DevPage {
  browse,
  connections,
  dashboard,
  guardian,
  profile,

  /// Pushed route context, not a root destination. This lets the app-wide
  /// developer control follow the live Journey instead of continuing to show
  /// the Connections controls underneath it.
  activeJourney,
}

/// Founder-facing Connections card presentation lab.
///
/// [compactChips] is the current testing default. The other five values are
/// live comparisons of the same actions and information; they never alter
/// Journey or profile state. Release builds continue to use [unifiedRail]
/// until the Founder selects a production direction.
enum ZyraConnectionsCardStyle {
  unifiedRail,
  splitPills,
  iconDock,
  stackedRows,
  compactChips,
  framedGrid,
}

extension ZyraConnectionsCardStyleX on ZyraConnectionsCardStyle {
  String get label => switch (this) {
    ZyraConnectionsCardStyle.unifiedRail => 'Unified rail',
    ZyraConnectionsCardStyle.splitPills => 'Split pills',
    ZyraConnectionsCardStyle.iconDock => 'Icon dock',
    ZyraConnectionsCardStyle.stackedRows => 'Stacked rows',
    ZyraConnectionsCardStyle.compactChips => 'Compact chips',
    ZyraConnectionsCardStyle.framedGrid => 'Framed grid',
  };

  String get description => switch (this) {
    ZyraConnectionsCardStyle.unifiedRail =>
      'Active Journey style: one primary action and a quiet action rail.',
    ZyraConnectionsCardStyle.splitPills =>
      'Rounded two-column actions with a stronger button rhythm.',
    ZyraConnectionsCardStyle.iconDock =>
      'Compact icon-and-label dock beneath the main action.',
    ZyraConnectionsCardStyle.stackedRows =>
      'Calm full-width rows with clear direction cues.',
    ZyraConnectionsCardStyle.compactChips =>
      'Three equal controls spanning the full card width.',
    ZyraConnectionsCardStyle.framedGrid =>
      'Structured two-column cells inside one subtle frame.',
  };
}

/// Independent section-title comparisons for Active, Potential, Paused,
/// Ended, Considered, Saved and Passed. Introductions deliberately has no
/// repeated in-page title because the segment itself already names the page.
enum ZyraConnectionsHeadingStyle {
  chapterLeft,
  titleLeft,
  centredRule,
  accentMarker,
  countSplit,
}

extension ZyraConnectionsHeadingStyleX on ZyraConnectionsHeadingStyle {
  String get label => switch (this) {
    ZyraConnectionsHeadingStyle.chapterLeft => 'Chapter left',
    ZyraConnectionsHeadingStyle.titleLeft => 'Title left',
    ZyraConnectionsHeadingStyle.centredRule => 'Centred rule',
    ZyraConnectionsHeadingStyle.accentMarker => 'Accent marker',
    ZyraConnectionsHeadingStyle.countSplit => 'Right rule',
  };

  String get description => switch (this) {
    ZyraConnectionsHeadingStyle.chapterLeft =>
      'Current compact uppercase chapter label.',
    ZyraConnectionsHeadingStyle.titleLeft =>
      'Larger title-case heading aligned with the cards.',
    ZyraConnectionsHeadingStyle.centredRule =>
      'Centred heading held between two quiet divider lines.',
    ZyraConnectionsHeadingStyle.accentMarker =>
      'Left marker with a medium title and no numeric badge.',
    ZyraConnectionsHeadingStyle.countSplit =>
      'Title on the left and a short quiet rule on the right.',
  };
}

/// Session-only visual comparisons for Browse's live swipe response.
///
/// [fullAura] is the current shipped/default response. The other ten are the
/// Founder-approved 3D photo-motion comparisons. They change presentation
/// only: the shared Browse policy still owns left=Consider, down=Save and
/// right=Pass, and no option adds action buttons or changes a decision write.
enum ZyraBrowseSwipeFeedbackStyle {
  fullAura,
  layeredParallax,
  edgePeek,
  floatingDeck,
  carousel3d,
  doorHinge,
  pageCurl,
  depthTunnel,
  subjectSplit,
  magneticTilt,
  horizonLift,
}

extension ZyraBrowseSwipeFeedbackStyleX on ZyraBrowseSwipeFeedbackStyle {
  String get label => switch (this) {
    ZyraBrowseSwipeFeedbackStyle.fullAura => 'Full aura',
    ZyraBrowseSwipeFeedbackStyle.layeredParallax => '1 · Layered parallax',
    ZyraBrowseSwipeFeedbackStyle.edgePeek => '2 · Edge peek',
    ZyraBrowseSwipeFeedbackStyle.floatingDeck => '3 · Floating deck',
    ZyraBrowseSwipeFeedbackStyle.carousel3d => '4 · 3D carousel',
    ZyraBrowseSwipeFeedbackStyle.doorHinge => '5 · Door hinge',
    ZyraBrowseSwipeFeedbackStyle.pageCurl => '6 · Page curl',
    ZyraBrowseSwipeFeedbackStyle.depthTunnel => '7 · Depth tunnel',
    ZyraBrowseSwipeFeedbackStyle.subjectSplit => '8 · Subject split',
    ZyraBrowseSwipeFeedbackStyle.magneticTilt => '9 · Magnetic tilt',
    ZyraBrowseSwipeFeedbackStyle.horizonLift => '10 · Horizon lift',
  };

  String get description => switch (this) {
    ZyraBrowseSwipeFeedbackStyle.fullAura =>
      'Current default: traffic-light colour surrounds the full screen.',
    ZyraBrowseSwipeFeedbackStyle.layeredParallax =>
      'Photo, identity and the next profile move at different depths.',
    ZyraBrowseSwipeFeedbackStyle.edgePeek =>
      'The current profile clears quickly to expose the next profile edge.',
    ZyraBrowseSwipeFeedbackStyle.floatingDeck =>
      'The active profile lifts above a stacked next-profile layer.',
    ZyraBrowseSwipeFeedbackStyle.carousel3d =>
      'Profiles rotate through depth like a restrained 3D carousel.',
    ZyraBrowseSwipeFeedbackStyle.doorHinge =>
      'The profile pivots from the opposite edge as the next one appears.',
    ZyraBrowseSwipeFeedbackStyle.pageCurl =>
      'A softer perspective fold suggests turning to the next profile.',
    ZyraBrowseSwipeFeedbackStyle.depthTunnel =>
      'The current profile recedes while the next profile comes forward.',
    ZyraBrowseSwipeFeedbackStyle.subjectSplit =>
      'The profile and its identity details separate into layered motion.',
    ZyraBrowseSwipeFeedbackStyle.magneticTilt =>
      'The profile is pulled towards the gesture with stronger 3D tilt.',
    ZyraBrowseSwipeFeedbackStyle.horizonLift =>
      'The profile lifts forward while the next profile rises beneath it.',
  };

  String get groupLabel => switch (this) {
    ZyraBrowseSwipeFeedbackStyle.fullAura => 'Current default',
    _ => '3D photo movement',
  };

  bool get movesPhoto => this != ZyraBrowseSwipeFeedbackStyle.fullAura;

  bool get previewsNextProfile => movesPhoto;
}

/// The popups the panel can ask Browse to show. Each maps to a modal that
/// ALREADY EXISTS in browse_screen.dart — nothing here writes its own copy,
/// which was the complaint that produced this enum (Founder, 2026-08-05:
/// "please include the pop-ups that are on file, not create random ones").
///
///   saveLimit      -> _showCapReachedModal(action: 'Save', …)
///   considerLimit  -> _showCapReachedModal(action: 'Consider', …)
///   dailyLimit     -> _showLimitReachedModal()
enum DevPopup { saveLimit, considerLimit, dailyLimit }

extension DevPageX on DevPage {
  String get label => switch (this) {
    DevPage.browse => 'Profiles',
    DevPage.connections => 'Connections',
    DevPage.dashboard => 'Dashboard',
    DevPage.guardian => 'Guardian',
    DevPage.profile => 'Profile',
    DevPage.activeJourney => 'Active Journey',
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

/// The three production Activity destinations available to a local test
/// profile. This state lives here rather than in [AppState]: developer-toggle
/// people must be able to move between real-looking cards without ever
/// becoming account decisions or reaching Supabase.
enum ZyraActivityTestState { considered, saved, passed }

const String kZyraActivityTestProfilePrefix = 'zyra-local-activity-preview-';
const String kZyraIntroductionTestProfilePrefix =
    'zyra-local-introduction-preview-';

String zyraActivityTestProfileId(ZyraActivityTestState origin, int index) =>
    '$kZyraActivityTestProfilePrefix${origin.name}-$index';

String zyraIntroductionTestProfileId(int index) =>
    '$kZyraIntroductionTestProfilePrefix$index';

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

  // ── DASHBOARD LAB — Founder comparison build, 2026-08-24 ────────────
  // One shared store serves both account shells. The role preview is an
  // override, not an account mutation; Current account is the honest default.
  // Every field is session-only and ignored unless developer access is live.
  bool _dashboardLabEnabled = true;
  ZyraDashboardConcept _dashboardConcept = ZyraDashboardConcept.nowJourneyYou;
  ZyraDashboardContextPreset? _dashboardContextPreset =
      ZyraDashboardContextPreset.activeJourney;
  ZyraDashboardAudiencePreview _dashboardAudience =
      ZyraDashboardAudiencePreview.current;
  ZyraDashboardActivityState _dashboardActivityState =
      ZyraDashboardActivityState.normal;
  ZyraDashboardJourneyPreview _dashboardJourneyPreview =
      ZyraDashboardJourneyPreview.active;
  bool _dashboardNewActivity = true;
  bool _dashboardPendingApproval = false;
  ZyraDashboardInsightState _dashboardInsightState =
      ZyraDashboardInsightState.positive;
  ZyraDashboardInsightPlan _dashboardInsightPlan =
      ZyraDashboardInsightPlan.basic;
  bool _dashboardLearningOnCurrentHub = true;
  bool _dashboardOnboardingComplete = false;
  int _dashboardOnboardingAnswered = 35;
  static const int dashboardOnboardingTotal = 68;
  int _dashboardFamilyProgress = 2;
  int _dashboardSupportedSeekers = 3;
  int _dashboardPotentialJourneys = 0;
  int _dashboardSavedProfiles = 2;
  bool _dashboardHasGuardian = true;
  bool _dashboardGuardianActivity = false;
  bool _dashboardFamilyIntroductionActive = false;
  ZyraDashboardTab _dashboardTab = ZyraDashboardTab.now;
  ZyraSeekerDashboardTodayState _dashboardSeekerTodayState =
      ZyraSeekerDashboardTodayState.calm;
  ZyraGuardianDashboardTodayState _dashboardGuardianTodayState =
      ZyraGuardianDashboardTodayState.noSeekers;
  ZyraDashboardUpdatesState _dashboardUpdatesState =
      ZyraDashboardUpdatesState.none;
  ZyraSeekerDashboardInsightsState _dashboardSeekerInsightsState =
      ZyraSeekerDashboardInsightsState.insufficient;
  ZyraGuardianDashboardInsightsState _dashboardGuardianInsightsState =
      ZyraGuardianDashboardInsightsState.insufficient;
  bool _dashboardGuardianPremium = false;
  bool _dashboardGuardianNowOptionSelected = false;
  bool _dashboardGuardianInsightsOptionSelected = false;
  bool _dashboardGuardianJourneyDecisionPending = false;
  final Set<ZyraDashboardModule> _dashboardModules = {
    ...zyraDashboardDefaultModules,
  };
  final List<ZyraDashboardModule> _dashboardOrder = [
    ...zyraDashboardDefaultOrder,
  ];

  bool get dashboardLabEnabled => _dashboardLabEnabled;
  ZyraDashboardConcept get dashboardConcept => _dashboardConcept;
  ZyraDashboardContextPreset? get dashboardContextPreset =>
      _dashboardContextPreset;
  ZyraDashboardAudiencePreview get dashboardAudience => _dashboardAudience;
  ZyraDashboardActivityState get dashboardActivityState =>
      _dashboardActivityState;
  ZyraDashboardJourneyPreview get dashboardJourneyPreview =>
      _dashboardJourneyPreview;
  bool get dashboardNewActivity => _dashboardNewActivity;
  bool get dashboardPendingApproval => _dashboardPendingApproval;
  ZyraDashboardInsightState get dashboardInsightState => _dashboardInsightState;
  ZyraDashboardInsightPlan get dashboardInsightPlan => _dashboardInsightPlan;
  bool get dashboardLearningOnCurrentHub => _dashboardLearningOnCurrentHub;
  bool get dashboardOnboardingComplete => _dashboardOnboardingComplete;
  int get dashboardOnboardingAnswered => _dashboardOnboardingAnswered;
  int get dashboardFamilyProgress => _dashboardFamilyProgress;
  int get dashboardSupportedSeekers => _dashboardSupportedSeekers;
  int get dashboardPotentialJourneys => _dashboardPotentialJourneys;
  int get dashboardSavedProfiles => _dashboardSavedProfiles;
  bool get dashboardHasGuardian => _dashboardHasGuardian;
  bool get dashboardGuardianActivity => _dashboardGuardianActivity;
  bool get dashboardFamilyIntroductionActive =>
      _dashboardFamilyIntroductionActive;
  ZyraDashboardTab get dashboardTab => _dashboardTab;
  ZyraSeekerDashboardTodayState get dashboardSeekerTodayState =>
      _dashboardSeekerTodayState;
  ZyraGuardianDashboardTodayState get dashboardGuardianTodayState =>
      _dashboardGuardianTodayState;
  ZyraDashboardUpdatesState get dashboardUpdatesState => _dashboardUpdatesState;
  ZyraSeekerDashboardInsightsState get dashboardSeekerInsightsState =>
      _dashboardSeekerInsightsState;
  ZyraGuardianDashboardInsightsState get dashboardGuardianInsightsState =>
      _dashboardGuardianInsightsState;
  bool get dashboardGuardianPremium => _dashboardGuardianPremium;
  bool dashboardGuardianOptionSelected(ZyraDashboardTab tab) => switch (tab) {
    ZyraDashboardTab.now => _dashboardGuardianNowOptionSelected,
    ZyraDashboardTab.insights => _dashboardGuardianInsightsOptionSelected,
  };
  Set<ZyraDashboardModule> get dashboardModules =>
      Set.unmodifiable(_dashboardModules);
  List<ZyraDashboardModule> get dashboardOrder =>
      List.unmodifiable(_dashboardOrder);

  ZyraDashboardViewConfig dashboardConfigFor(ZyraDashboardRole hostRole) =>
      ZyraDashboardViewConfig(
        concept: _dashboardConcept,
        role: resolveDashboardRole(
          preview: _dashboardAudience,
          hostRole: hostRole,
        ),
        surfaceStyle: ZyraColors.appSurfaceStyle,
        activityState: _dashboardActivityState,
        journeyPreview: _dashboardJourneyPreview,
        newActivity: _dashboardNewActivity,
        pendingApproval: _dashboardPendingApproval,
        insightState: _dashboardInsightState,
        insightPlan: _dashboardInsightPlan,
        onboardingComplete: _dashboardOnboardingComplete,
        onboardingAnswered: _dashboardOnboardingComplete
            ? dashboardOnboardingTotal
            : _dashboardOnboardingAnswered,
        onboardingTotal: dashboardOnboardingTotal,
        familyProgress: _dashboardFamilyProgress,
        supportedSeekers: _dashboardSupportedSeekers,
        potentialJourneys: _dashboardPotentialJourneys,
        savedProfiles: _dashboardSavedProfiles,
        hasGuardian: _dashboardHasGuardian,
        guardianActivity: _dashboardGuardianActivity,
        familyIntroductionActive: _dashboardFamilyIntroductionActive,
        contextPreset: _dashboardContextPreset,
        enabledModules: Set.unmodifiable(_dashboardModules),
        moduleOrder: List.unmodifiable(_dashboardOrder),
      );

  void setDashboardLabEnabled(bool value) {
    if (_dashboardLabEnabled == value) return;
    _dashboardLabEnabled = value;
    notifyListeners();
  }

  /// Records an explicit Founder choice in the Guardian Dashboard dropdown.
  /// Defaults remain stored for deterministic fixtures, but they must not
  /// render as though the Founder selected them on a fresh preview.
  void markDashboardGuardianOptionSelected(ZyraDashboardTab tab) {
    final alreadySelected = dashboardGuardianOptionSelected(tab);
    if (alreadySelected) return;
    switch (tab) {
      case ZyraDashboardTab.now:
        _dashboardGuardianNowOptionSelected = true;
      case ZyraDashboardTab.insights:
        _dashboardGuardianInsightsOptionSelected = true;
    }
    notifyListeners();
  }

  void setDashboardConcept(ZyraDashboardConcept value) {
    if (_dashboardConcept == value) return;
    _dashboardConcept = value;
    notifyListeners();
  }

  /// Stages one deterministic Founder-review story across every layout.
  ///
  /// These values only feed the developer Dashboard adapter. Invitation
  /// counts deliberately reuse the existing invitation preview store so the
  /// real Review/Accept/Decline/Cancel interactions are exercised rather than
  /// copied into a decorative Dashboard card.
  void setDashboardContextPreset(ZyraDashboardContextPreset value) {
    _dashboardAudience = ZyraDashboardAudiencePreview.seeker;
    _dashboardContextPreset = value;
    _applyDashboardContextPreset(value);
    notifyListeners();
  }

  void _applyDashboardContextPreset(ZyraDashboardContextPreset value) {
    _dashboardModules
      ..clear()
      ..addAll(zyraDashboardDefaultModules);
    _receivedInviteCount = 0;
    _pendingInviteCount = 0;
    _mainGuardian = true;
    _dashboardHasGuardian = true;
    _dashboardGuardianActivity = false;
    _dashboardFamilyIntroductionActive = false;
    _dashboardPotentialJourneys = 0;
    _dashboardSavedProfiles = 2;
    _dashboardOnboardingComplete = true;
    _dashboardOnboardingAnswered = dashboardOnboardingTotal;
    _dashboardJourneyPreview = ZyraDashboardJourneyPreview.none;
    _dashboardActivityState = ZyraDashboardActivityState.normal;
    _dashboardNewActivity = false;
    _dashboardPendingApproval = false;
    _dashboardInsightState = ZyraDashboardInsightState.positive;
    _dashboardInsightPlan = ZyraDashboardInsightPlan.basic;
    _dashboardFamilyProgress = 2;

    switch (value) {
      case ZyraDashboardContextPreset.newSeeker:
        _mainGuardian = false;
        _dashboardHasGuardian = false;
        _dashboardSavedProfiles = 0;
        _dashboardOnboardingComplete = false;
        _dashboardOnboardingAnswered = 14;
        _dashboardActivityState = ZyraDashboardActivityState.empty;
        _dashboardInsightState = ZyraDashboardInsightState.insufficientData;
        _dashboardFamilyProgress = 0;
      case ZyraDashboardContextPreset.guardianInvitation:
        _mainGuardian = false;
        _dashboardHasGuardian = false;
        _receivedInviteCount = 1;
        _dashboardNewActivity = true;
      case ZyraDashboardContextPreset.potentialJourneys:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.potentials;
        _dashboardPotentialJourneys = 3;
        _dashboardSavedProfiles = 5;
      case ZyraDashboardContextPreset.activeJourney:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.active;
        _dashboardNewActivity = true;
      case ZyraDashboardContextPreset.activeWithGuardian:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.active;
        _dashboardGuardianActivity = true;
        _dashboardNewActivity = true;
        _dashboardFamilyProgress = 3;
      case ZyraDashboardContextPreset.decisionRequired:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.active;
        _dashboardActivityState = ZyraDashboardActivityState.urgent;
        _dashboardNewActivity = true;
        _dashboardPendingApproval = true;
      case ZyraDashboardContextPreset.pausedJourney:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.paused;
        _dashboardInsightState = ZyraDashboardInsightState.neutral;
      case ZyraDashboardContextPreset.zyraOneInsights:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.active;
        _dashboardActivityState = ZyraDashboardActivityState.busy;
        _dashboardNewActivity = true;
        _dashboardInsightPlan = ZyraDashboardInsightPlan.one;
        _dashboardInsightState = ZyraDashboardInsightState.preferenceReview;
        _dashboardSavedProfiles = 7;
    }
  }

  void _markDashboardContextCustom() {
    _dashboardContextPreset = null;
  }

  void setDashboardAudience(ZyraDashboardAudiencePreview value) {
    if (_dashboardAudience == value &&
        (value == ZyraDashboardAudiencePreview.seeker ||
            _dashboardContextPreset == null)) {
      return;
    }
    _dashboardAudience = value;
    if (value != ZyraDashboardAudiencePreview.seeker) {
      _dashboardContextPreset = null;
    }
    notifyListeners();
  }

  void setDashboardTab(ZyraDashboardTab value) {
    if (_dashboardTab == value) return;
    _dashboardTab = value;
    notifyListeners();
  }

  void setDashboardSeekerTodayState(ZyraSeekerDashboardTodayState value) {
    _dashboardSeekerTodayState = value;
    _dashboardContextPreset = null;
    _dashboardOnboardingComplete = true;
    _dashboardOnboardingAnswered = dashboardOnboardingTotal;
    _dashboardJourneyPreview = ZyraDashboardJourneyPreview.none;
    _dashboardNewActivity = false;
    _dashboardPendingApproval = false;
    _dashboardActivityState = ZyraDashboardActivityState.empty;
    _dashboardHasGuardian = false;
    _dashboardGuardianActivity = false;
    _dashboardFamilyIntroductionActive = false;
    _dashboardPotentialJourneys = 0;
    _dashboardSavedProfiles = 0;
    _receivedInviteCount = 0;
    switch (value) {
      case ZyraSeekerDashboardTodayState.newSeeker:
        _dashboardOnboardingComplete = false;
        _dashboardOnboardingAnswered = 14;
      case ZyraSeekerDashboardTodayState.noGuardian:
      case ZyraSeekerDashboardTodayState.noJourney:
      case ZyraSeekerDashboardTodayState.calm:
      case ZyraSeekerDashboardTodayState.loading:
      case ZyraSeekerDashboardTodayState.partialFailure:
      case ZyraSeekerDashboardTodayState.fullFailure:
        break;
      case ZyraSeekerDashboardTodayState.guardianConnected:
        _dashboardHasGuardian = true;
      case ZyraSeekerDashboardTodayState.guardianInvitationPending:
        _receivedInviteCount = 1;
      case ZyraSeekerDashboardTodayState.potentialJourneys:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.potentials;
        _dashboardPotentialJourneys = 3;
      case ZyraSeekerDashboardTodayState.activeJourney:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.active;
      case ZyraSeekerDashboardTodayState.journeyPaused:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.paused;
      case ZyraSeekerDashboardTodayState.journeyDecisionPending:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.active;
        _dashboardPendingApproval = true;
        _dashboardActivityState = ZyraDashboardActivityState.urgent;
      case ZyraSeekerDashboardTodayState.recentMovement:
        _dashboardJourneyPreview = ZyraDashboardJourneyPreview.active;
        _dashboardNewActivity = true;
        _dashboardActivityState = ZyraDashboardActivityState.normal;
    }
    notifyListeners();
  }

  void setDashboardGuardianTodayState(ZyraGuardianDashboardTodayState value) {
    _dashboardGuardianNowOptionSelected = true;
    _dashboardGuardianTodayState = value;
    _dashboardContextPreset = null;
    _waliRole = WaliRole.main;
    _waliLinkedSeekers = 1;
    _waliActiveJourneys = 0;
    _waliPausedJourneys = 0;
    _waliEndedJourneys = 0;
    _waliReviewWaiting = false;
    _waliReviewDecision = null;
    _waliSentInvites = 0;
    _dashboardGuardianPremium = false;
    _dashboardGuardianJourneyDecisionPending = false;
    switch (value) {
      case ZyraGuardianDashboardTodayState.noSeekers:
        _waliLinkedSeekers = 0;
      case ZyraGuardianDashboardTodayState.oneSeeker:
      case ZyraGuardianDashboardTodayState.mainGuardian:
      case ZyraGuardianDashboardTodayState.noJourney:
      case ZyraGuardianDashboardTodayState.calm:
      case ZyraGuardianDashboardTodayState.loading:
      case ZyraGuardianDashboardTodayState.partialFailure:
      case ZyraGuardianDashboardTodayState.fullFailure:
        break;
      case ZyraGuardianDashboardTodayState.multipleSeekers:
        _waliLinkedSeekers = 3;
        _waliActiveJourneys = 1;
        _waliPausedJourneys = 1;
      case ZyraGuardianDashboardTodayState.additionalGuardian:
        _waliRole = WaliRole.additional;
      case ZyraGuardianDashboardTodayState.activeJourney:
        _waliActiveJourneys = 1;
      case ZyraGuardianDashboardTodayState.pausedJourney:
        _waliPausedJourneys = 1;
      case ZyraGuardianDashboardTodayState.journeyDecisionPending:
        _waliActiveJourneys = 1;
        _dashboardGuardianJourneyDecisionPending = true;
      case ZyraGuardianDashboardTodayState.familyReviewWaiting:
        _waliActiveJourneys = 1;
        _waliReviewWaiting = true;
      case ZyraGuardianDashboardTodayState.guardianGateWaiting:
        _waliActiveJourneys = 1;
        final gate = ZyraJourneyStages.all.indexWhere(
          (stage) => stage.value == 'wali_gate',
        );
        if (gate >= 0) _waliStageIndex = gate;
      case ZyraGuardianDashboardTodayState.pendingInvitation:
        _waliLinkedSeekers = 0;
        _waliSentInvites = 1;
      case ZyraGuardianDashboardTodayState.networkBasicLocked:
        break;
      case ZyraGuardianDashboardTodayState.networkPremiumActive:
        _dashboardGuardianPremium = true;
    }
    notifyListeners();
  }

  void setDashboardUpdatesState(ZyraDashboardUpdatesState value) {
    if (_dashboardUpdatesState == value) return;
    _dashboardUpdatesState = value;
    _dashboardNewActivity = switch (value) {
      ZyraDashboardUpdatesState.none ||
      ZyraDashboardUpdatesState.allRead => false,
      _ => true,
    };
    notifyListeners();
  }

  void setDashboardSeekerInsightsState(ZyraSeekerDashboardInsightsState value) {
    _dashboardSeekerInsightsState = value;
    _dashboardInsightState = switch (value) {
      ZyraSeekerDashboardInsightsState.insufficient =>
        ZyraDashboardInsightState.insufficientData,
      ZyraSeekerDashboardInsightsState.preferenceReview =>
        ZyraDashboardInsightState.preferenceReview,
      ZyraSeekerDashboardInsightsState.discoveryHealth =>
        ZyraDashboardInsightState.neutral,
      _ => ZyraDashboardInsightState.positive,
    };
    _dashboardInsightPlan =
        value == ZyraSeekerDashboardInsightsState.one ||
            value == ZyraSeekerDashboardInsightsState.aiExplanation
        ? ZyraDashboardInsightPlan.one
        : ZyraDashboardInsightPlan.basic;
    notifyListeners();
  }

  void setDashboardGuardianInsightsState(
    ZyraGuardianDashboardInsightsState value,
  ) {
    final selectionChanged = !_dashboardGuardianInsightsOptionSelected;
    _dashboardGuardianInsightsOptionSelected = true;
    if (_dashboardGuardianInsightsState == value) {
      if (selectionChanged) notifyListeners();
      return;
    }
    _dashboardGuardianInsightsState = value;
    if (value == ZyraGuardianDashboardInsightsState.premium) {
      _dashboardGuardianPremium = true;
    }
    notifyListeners();
  }

  void setDashboardGuardianPremium(bool value) {
    if (_dashboardGuardianPremium == value) return;
    _dashboardGuardianPremium = value;
    notifyListeners();
  }

  void setDashboardActivityState(ZyraDashboardActivityState value) {
    if (_dashboardActivityState == value && _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardActivityState = value;
    if (value == ZyraDashboardActivityState.empty) {
      _dashboardNewActivity = false;
      _dashboardPendingApproval = false;
    } else if (value == ZyraDashboardActivityState.urgent) {
      _dashboardPendingApproval = true;
      _dashboardNewActivity = true;
    }
    notifyListeners();
  }

  void setDashboardJourneyPreview(ZyraDashboardJourneyPreview value) {
    if (_dashboardJourneyPreview == value && _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardJourneyPreview = value;
    notifyListeners();
  }

  void setDashboardNewActivity(bool value) {
    if (_dashboardNewActivity == value && _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardNewActivity = value;
    notifyListeners();
  }

  void setDashboardPendingApproval(bool value) {
    if (_dashboardPendingApproval == value && _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardPendingApproval = value;
    if (value) {
      _dashboardModules.add(ZyraDashboardModule.nextStep);
    }
    notifyListeners();
  }

  void setDashboardInsightState(ZyraDashboardInsightState value) {
    if (_dashboardInsightState == value && _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardInsightState = value;
    _dashboardModules.add(ZyraDashboardModule.learning);
    notifyListeners();
  }

  void setDashboardInsightPlan(ZyraDashboardInsightPlan value) {
    if (_dashboardInsightPlan == value && _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardInsightPlan = value;
    _dashboardModules.add(ZyraDashboardModule.learning);
    notifyListeners();
  }

  void setDashboardLearningOnCurrentHub(bool value) {
    if (_dashboardLearningOnCurrentHub == value) return;
    _dashboardLearningOnCurrentHub = value;
    notifyListeners();
  }

  void setDashboardOnboardingComplete(bool value) {
    if (_dashboardOnboardingComplete == value &&
        _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardOnboardingComplete = value;
    if (value) {
      _dashboardModules.remove(ZyraDashboardModule.onboarding);
    } else {
      _dashboardModules.add(ZyraDashboardModule.onboarding);
    }
    notifyListeners();
  }

  void setDashboardOnboardingAnswered(int value) {
    final resolved = value.clamp(0, dashboardOnboardingTotal - 1);
    if (_dashboardOnboardingAnswered == resolved &&
        !_dashboardOnboardingComplete &&
        _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardOnboardingAnswered = resolved;
    _dashboardOnboardingComplete = false;
    _dashboardModules.add(ZyraDashboardModule.onboarding);
    notifyListeners();
  }

  void setDashboardFamilyProgress(int value) {
    final resolved = value.clamp(0, 4);
    if (_dashboardFamilyProgress == resolved &&
        _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardFamilyProgress = resolved;
    _dashboardFamilyIntroductionActive = true;
    notifyListeners();
  }

  void setDashboardFamilyIntroductionActive(bool value) {
    if (_dashboardFamilyIntroductionActive == value &&
        _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardFamilyIntroductionActive = value;
    notifyListeners();
  }

  void setDashboardHasGuardian(bool value) {
    if (_dashboardHasGuardian == value && _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardHasGuardian = value;
    if (!value) _dashboardGuardianActivity = false;
    notifyListeners();
  }

  void setDashboardGuardianActivity(bool value) {
    if (_dashboardGuardianActivity == value &&
        _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardGuardianActivity = value;
    if (value) _dashboardHasGuardian = true;
    notifyListeners();
  }

  void setDashboardPotentialJourneys(int value) {
    final resolved = value.clamp(0, 5);
    if (_dashboardPotentialJourneys == resolved &&
        _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardPotentialJourneys = resolved;
    notifyListeners();
  }

  void setDashboardSavedProfiles(int value) {
    final resolved = value.clamp(0, 10);
    if (_dashboardSavedProfiles == resolved &&
        _dashboardContextPreset == null) {
      return;
    }
    _markDashboardContextCustom();
    _dashboardSavedProfiles = resolved;
    notifyListeners();
  }

  void setDashboardSupportedSeekers(int value) {
    final resolved = value.clamp(0, 6);
    if (_dashboardSupportedSeekers == resolved) return;
    _markDashboardContextCustom();
    _dashboardSupportedSeekers = resolved;
    notifyListeners();
  }

  void setDashboardModuleEnabled(ZyraDashboardModule module, bool enabled) {
    final changed = enabled
        ? _dashboardModules.add(module)
        : _dashboardModules.remove(module);
    if (!changed) return;
    notifyListeners();
  }

  void moveDashboardModule(ZyraDashboardModule module, int delta) {
    final from = _dashboardOrder.indexOf(module);
    final to = (from + delta).clamp(0, _dashboardOrder.length - 1);
    if (from < 0 || from == to) return;
    _dashboardOrder.removeAt(from);
    _dashboardOrder.insert(to, module);
    notifyListeners();
  }

  /// Moves a module only against neighbours owned by the same Dashboard tab.
  void moveDashboardModuleWithin(
    ZyraDashboardModule module,
    int delta,
    Set<ZyraDashboardModule> sectionModules,
  ) {
    final sectionOrder = _dashboardOrder
        .where(sectionModules.contains)
        .toList();
    final sectionFrom = sectionOrder.indexOf(module);
    final sectionTo = (sectionFrom + delta).clamp(0, sectionOrder.length - 1);
    if (sectionFrom < 0 || sectionFrom == sectionTo) return;
    final other = sectionOrder[sectionTo];
    final from = _dashboardOrder.indexOf(module);
    final to = _dashboardOrder.indexOf(other);
    _dashboardOrder[from] = other;
    _dashboardOrder[to] = module;
    notifyListeners();
  }

  void resetDashboardLab({bool notify = true}) {
    _dashboardLabEnabled = true;
    _dashboardConcept = ZyraDashboardConcept.nowJourneyYou;
    _dashboardAudience = ZyraDashboardAudiencePreview.current;
    _dashboardContextPreset = null;
    _dashboardTab = ZyraDashboardTab.now;
    _dashboardSeekerTodayState = ZyraSeekerDashboardTodayState.calm;
    _dashboardGuardianTodayState = ZyraGuardianDashboardTodayState.noSeekers;
    _dashboardUpdatesState = ZyraDashboardUpdatesState.none;
    _dashboardSeekerInsightsState =
        ZyraSeekerDashboardInsightsState.insufficient;
    _dashboardGuardianInsightsState =
        ZyraGuardianDashboardInsightsState.insufficient;
    _dashboardGuardianPremium = false;
    _dashboardGuardianNowOptionSelected = false;
    _dashboardGuardianInsightsOptionSelected = false;
    _dashboardGuardianJourneyDecisionPending = false;
    _dashboardLearningOnCurrentHub = false;
    _dashboardSupportedSeekers = 0;
    _dashboardOrder
      ..clear()
      ..addAll(zyraDashboardDefaultOrder);
    _dashboardModules
      ..clear()
      ..addAll(zyraDashboardDefaultModules);
    _dashboardOnboardingComplete = true;
    _dashboardOnboardingAnswered = dashboardOnboardingTotal;
    _dashboardJourneyPreview = ZyraDashboardJourneyPreview.none;
    _dashboardNewActivity = false;
    _dashboardPendingApproval = false;
    _dashboardActivityState = ZyraDashboardActivityState.empty;
    _dashboardInsightState = ZyraDashboardInsightState.insufficientData;
    _dashboardInsightPlan = ZyraDashboardInsightPlan.basic;
    _dashboardHasGuardian = false;
    _dashboardGuardianActivity = false;
    _dashboardFamilyIntroductionActive = false;
    _dashboardPotentialJourneys = 0;
    _dashboardSavedProfiles = 0;
    _receivedInviteCount = 0;
    _pendingInviteCount = 0;
    _waliRole = WaliRole.main;
    _waliLinkedSeekers = 0;
    _waliActiveJourneys = 0;
    _waliPausedJourneys = 0;
    _waliEndedJourneys = 0;
    _waliReviewWaiting = false;
    _waliReviewDecision = null;
    _waliSentInvites = 0;
    _waliUnread = 0;
    if (notify) notifyListeners();
  }

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

  /// Local-only rows used to exercise the three Activity groups without
  /// changing the signed-in account's real decisions. Their controls live in
  /// the developer panel; the cards themselves deliberately use production
  /// presentation so the Founder is reviewing the real interface.
  int _consideredPreviewCount = 0;
  int _savedPreviewCount = 0;
  int _passedPreviewCount = 0;

  /// A fixture begins in the group which created it. Once an action is tapped,
  /// this map becomes its one local destination. Keeping this out of AppState
  /// prevents a deterministic fixture being regenerated in its old group and
  /// duplicated in the new one.
  final Map<String, ZyraActivityTestState> _localProfileDestinations = {};
  final Set<String> _hiddenLocalProfileIds = {};

  int get consideredPreviewCount => _consideredPreviewCount;
  int get savedPreviewCount => _savedPreviewCount;
  int get passedPreviewCount => _passedPreviewCount;

  ZyraActivityTestState? localProfileDestination(String profileId) =>
      _localProfileDestinations[profileId];

  bool isLocalProfileHidden(String profileId) =>
      _hiddenLocalProfileIds.contains(profileId);

  void moveLocalProfile(String profileId, ZyraActivityTestState destination) {
    if (_localProfileDestinations[profileId] == destination &&
        !_hiddenLocalProfileIds.contains(profileId)) {
      return;
    }
    _hiddenLocalProfileIds.remove(profileId);
    _localProfileDestinations[profileId] = destination;
    notifyListeners();
  }

  void hideLocalProfile(String profileId) {
    if (!_hiddenLocalProfileIds.add(profileId)) return;
    _localProfileDestinations.remove(profileId);
    notifyListeners();
  }

  void _pruneActivitySlots(ZyraActivityTestState origin, int retained) {
    for (var index = retained; index < 5; index++) {
      final id = zyraActivityTestProfileId(origin, index);
      _localProfileDestinations.remove(id);
      _hiddenLocalProfileIds.remove(id);
    }
  }

  void _pruneIntroductionSlots(int retained) {
    for (var index = retained; index < 5; index++) {
      final id = zyraIntroductionTestProfileId(index);
      _localProfileDestinations.remove(id);
      _hiddenLocalProfileIds.remove(id);
    }
  }

  void setConsideredPreviewCount(int count) {
    final next = count.clamp(0, 5);
    if (_consideredPreviewCount == next) return;
    _pruneActivitySlots(ZyraActivityTestState.considered, next);
    _consideredPreviewCount = next;
    notifyListeners();
  }

  void setSavedPreviewCount(int count) {
    final next = count.clamp(0, 5);
    if (_savedPreviewCount == next) return;
    _pruneActivitySlots(ZyraActivityTestState.saved, next);
    _savedPreviewCount = next;
    notifyListeners();
  }

  void setPassedPreviewCount(int count) {
    final next = count.clamp(0, 5);
    if (_passedPreviewCount == next) return;
    _pruneActivitySlots(ZyraActivityTestState.passed, next);
    _passedPreviewCount = next;
    notifyListeners();
  }

  /// Extra production-style Introduction cards used only when the guarded
  /// server developer RPC refuses a non-`@zyra.test` developer account.
  ///
  /// Zero means no fallback rows. Real server suggestions are never removed
  /// or replaced; Connections adds these deterministic rows in non-release
  /// builds only. The developer panel, not the customer card, identifies the
  /// state as a test fixture.
  int _introductionPreviewCount = 0;
  int get introductionPreviewCount => _introductionPreviewCount;

  void setIntroductionPreviewCount(int count) {
    final next = count.clamp(0, 5);
    if (_introductionPreviewCount == next) return;
    _pruneIntroductionSlots(next);
    _introductionPreviewCount = next;
    notifyListeners();
  }

  ZyraBrowseSwipeFeedbackStyle _browseSwipeFeedbackStyle =
      ZyraBrowseSwipeFeedbackStyle.fullAura;

  ZyraBrowseSwipeFeedbackStyle get browseSwipeFeedbackStyle =>
      _browseSwipeFeedbackStyle;

  void setBrowseSwipeFeedbackStyle(ZyraBrowseSwipeFeedbackStyle value) {
    if (_browseSwipeFeedbackStyle == value) return;
    _browseSwipeFeedbackStyle = value;
    notifyListeners();
  }

  /// Adds five local Browse cards behind the account's genuine candidates so
  /// the Founder can test the 3D next-profile handoff as a sequence rather
  /// than against a one-card deck.
  ///
  /// This helper is deliberately passive: [BrowseScreen] calls it only after
  /// [ZyraDeveloperAccess.canUseDeveloperTools] has authorised the session.
  /// The generated ids are non-UUIDs, so the existing Browse write guards
  /// keep Save, Consider, Pass, report, hide and unlock away from Supabase.
  /// The anchor photo is reused on purpose; these cards test motion and deck
  /// continuity, not identity or image variety.
  static List<SeekerProfile> composeBrowsePreviewProfiles({
    required List<SeekerProfile> real,
    required String? viewerGender,
    int extraCount = 5,
  }) {
    final count = extraCount.clamp(0, 5);
    if (count == 0) return List<SeekerProfile>.of(real);

    final targetGender = ZyraGender.oppositeCode(viewerGender);
    var anchor = mockProfiles.firstWhere(
      (profile) => profile.gender == targetGender,
    );
    for (final profile in real) {
      if (profile.gender == targetGender && profile.photos.isNotEmpty) {
        anchor = profile;
        break;
      }
    }

    const femaleIdentities = [
      (firstName: 'Amira', surnameLine: 'Rahman', age: 28, city: 'Manchester'),
      (firstName: 'Hana', surnameLine: 'Siddiqui', age: 31, city: 'Birmingham'),
      (firstName: 'Safiya', surnameLine: 'Ali', age: 26, city: 'Leicester'),
      (firstName: 'Noor', surnameLine: 'Mahmood', age: 30, city: 'Glasgow'),
      (firstName: 'Layla', surnameLine: 'Ahmed', age: 29, city: 'Leeds'),
    ];
    const maleIdentities = [
      (firstName: 'Adam', surnameLine: 'Rahman', age: 30, city: 'Manchester'),
      (
        firstName: 'Hamza',
        surnameLine: 'Siddiqui',
        age: 28,
        city: 'Birmingham',
      ),
      (firstName: 'Zayd', surnameLine: 'Ali', age: 32, city: 'Leicester'),
      (firstName: 'Idris', surnameLine: 'Mahmood', age: 27, city: 'Glasgow'),
      (firstName: 'Omar', surnameLine: 'Ahmed', age: 31, city: 'Leeds'),
    ];
    final identities = targetGender == 'male'
        ? maleIdentities
        : femaleIdentities;
    final preview = <SeekerProfile>[];
    for (var i = 0; i < count; i++) {
      final identity = identities[i];
      preview.add(
        SeekerProfile(
          id: 'dev-browse-preview-${targetGender[0]}-$i',
          firstName: identity.firstName,
          surnameLine: identity.surnameLine,
          age: identity.age,
          city: identity.city,
          photos: anchor.photos,
          gender: targetGender,
        ),
      );
    }
    return [...real, ...preview];
  }

  void setConnectionsSection(int section) {
    final s = section.clamp(0, 2);
    if (connectionsSection == s) return;
    connectionsSection = s;
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

  // The shared decision flow's complete preview axis. Plan is deliberately
  // separate, allowing every state to be reviewed as Basic and ZYRA One.
  ZyraPauseDevScenario _pauseScenario = ZyraPauseDevScenario.active;
  ZyraPauseDevScenario get pauseScenario => _pauseScenario;

  void setPauseScenario(ZyraPauseDevScenario scenario) {
    final nextCount = _pausedJourneys == 0 ? 1 : _pausedJourneys;
    if (_pauseScenario == scenario && _pausedJourneys == nextCount) return;
    _connectionsPreviewIsolated = true;
    _pauseScenario = scenario;
    _pausedJourneys = nextCount;
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
  int _guardianPreviewActiveJourneyCount = 1;

  bool get mainGuardian => _mainGuardian;
  int get additionalGuardianCount => _additionalGuardianCount;
  int get pendingInviteCount => _pendingInviteCount;
  int get guardianPreviewActiveJourneyCount =>
      _guardianPreviewActiveJourneyCount;

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

  /// Founder-only layout preview for the Seeker's Guardian page. It changes
  /// only the local Main/Additional Guardian access rows, never Journey truth.
  void setGuardianPreviewActiveJourneyCount(int value) {
    final next = value.clamp(0, 3).toInt();
    if (_guardianPreviewActiveJourneyCount == next) return;
    _guardianPreviewActiveJourneyCount = next;
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

  void consumeReceivedInvite() {
    if (_receivedInviteCount <= 0) return;
    _receivedInviteCount -= 1;
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

  /// Fixture data is never an ordinary member's fallback. The stored panel
  /// preference applies only while the protected developer authority is live.
  bool get guardianOverride =>
      ZyraDeveloperAccess.canUseDeveloperTools && !_useLiveGuardianData;

  // ── Journeys ─────────────────────────────────────────────────────────
  //
  // ADDED 2026-08-06 (Founder: "add a section for 0–5 journey queued,
  // paused journeys, ended journey, and I'm assuming we only have option
  // for 1 active journey so make that 0/1").
  //
  // Active and Paused are capacity categories over status='active' match
  // rows. A pending Pause/Continue decision stays in Active; only mutual
  // Pause and its pending resume live in Paused. The scenario below mirrors
  // that model instead of simulating ownership by one Seeker.
  // False on a fresh app launch so developer access never hides live rows
  // merely by existing. Reset and the Connections controls turn this on:
  // from that point the page is an isolated preview and zero genuinely means
  // no cards, while the server rows remain untouched.
  bool _connectionsPreviewIsolated = false;
  bool get connectionsPreviewIsolated => _connectionsPreviewIsolated;

  List<T> connectionsRealRows<T>(List<T> rows) =>
      _connectionsPreviewIsolated ? <T>[] : rows;

  int _queuedJourneys = 0; // status 'potential'
  int _endedJourneys = 0; // status 'ended'

  int get queuedJourneys => _queuedJourneys;
  int get endedJourneys => _endedJourneys;

  void setQueuedJourneys(int v) {
    if (_queuedJourneys == v && _connectionsPreviewIsolated) return;
    _connectionsPreviewIsolated = true;
    _queuedJourneys = v;
    notifyListeners();
  }

  void setEndedJourneys(int v) {
    if (_endedJourneys == v && _connectionsPreviewIsolated) return;
    _connectionsPreviewIsolated = true;
    _endedJourneys = v;
    notifyListeners();
  }

  /// Extra Running and mutually Paused preview rows. Counts are clamped by
  /// the current plan. [pauseScenario] controls the first row's precise
  /// decision state, including pending states that remain in Active.
  int _activeJourneys = 0;
  int _pausedJourneys = 0;

  int get activeJourneys => _activeJourneys;
  int get pausedJourneys => _pausedJourneys;

  void setActiveJourneys(int v) {
    if (_activeJourneys == v && _connectionsPreviewIsolated) return;
    _connectionsPreviewIsolated = true;
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
    final nextScenario = v > 0 && _pauseScenario == ZyraPauseDevScenario.active
        ? ZyraPauseDevScenario.mutuallyPaused
        : _pauseScenario;
    if (_pausedJourneys == v &&
        _pauseScenario == nextScenario &&
        _connectionsPreviewIsolated) {
      return;
    }
    _connectionsPreviewIsolated = true;
    _pausedJourneys = v;
    _pauseScenario = nextScenario;
    notifyListeners();
  }

  /// One-time bridge from the 2026-08-12 control collection to the clean
  /// 2026-08-18 panel. The busy counters were removed because
  /// they staged impossible or retired states. Active Journey is intentionally
  /// retained: the Connections panel exposes it again as a plan-aware preview
  /// count (legacy inactive fixture 0-1 / ZYRA One 0-3).
  void migrateToCleanSeekerPanel() {
    final changed = _busyPotential != 0 || _busyPaused != 0 || _busyEnded != 0;
    if (!changed) return;
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
      ZyraJourneyPauseState pause = ZyraJourneyPauseState.active,
      DateTime? suspendedAt,
      DateTime? endedAt,
      bool inAnotherJourney = false,
    }) => JourneyMatch(
      matchId: id,
      profile: take(name, age),
      status: status,
      journeyStage: stage,
      pause: pause,
      suspendedAt: suspendedAt,
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
    // Both categories are stored as status='active' match rows, while the
    // shared pause_state determines which capacity and section they occupy.
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
        final scenario = i == 0
            ? s._pauseScenario
            : ZyraPauseDevScenario.mutuallyPaused;
        final pause = scenario.stateFor(
          viewerId: me,
          otherId: 'dev-other-$i',
          now: now,
        );
        out.add(
          make(
            fakeId,
            pausedNames[f],
            26 + i,
            scenario.isEnded ? 'ended' : 'active',
            stage: 'conversation',
            pause: pause,
            inAnotherJourney: f < s._busyPaused,
            suspendedAt: i == 0
                ? now.subtract(const Duration(days: 95))
                : now.subtract(const Duration(days: 3)),
            endedAt: scenario.isEnded ? now : null,
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
  //   waliUnread         → WaliHomeShell's My ZYRA tab badge

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

  /// Unread notifications on the Guardian's My ZYRA tab badge.
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

  // GUARDIAN NETWORK PREVIEW CONTROLS RETIRED — 2026-08-23 (OA-ZYRA-251).
  // The first-draft plan/scene state that lived here drove the retired
  // 2026-08-22 preview model (dev/guardian_network_preview.dart, archived
  // in SYSTEM/RESOURCES/OVERNIGHT_GN_2026-08-23/ARCHIVE_RETIRED_PREVIEW/
  // with its test). The current Guardian Network (D14, GN Draft 3.x)
  // keeps ALL of its staging in GNContext — lib/screens/wali/
  // wali_gn_shared.dart — behind the DEV chip on the Network and
  // Dashboard pages. This store still composes the WARDS the Network
  // works on behalf of (waliLinkedSeekers above); that control remains
  // real and current.

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
    (name: 'Maryam', relationship: 'grandfather'),
    (name: 'Yusuf', relationship: 'legal_guardian'),
    (name: 'Zaynab', relationship: 'family_representative'),
    (name: 'Hamza', relationship: 'uncle'),
    (name: 'Safiya', relationship: 'other'),
    (name: 'Idris', relationship: 'brother'),
    (name: 'Khadija', relationship: 'father'),
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
  /// This composes the richer Journey view used by Main-only surfaces.
  /// Additional Guardians receive their separate four-field summary inside
  /// the Seeker workspace, so they still do not enter this counterpart/stage
  /// path.
  static List<WaliJourneyView> composeWaliJourneys({
    required List<WaliLinkedPerson> wards,
    List<WaliJourneyView> real = const [],
  }) {
    final s = ZyraDevScenario.instance;
    final now = DateTime.now();
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
      ZyraJourneyPauseState pause = ZyraJourneyPauseState.active,
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
        pause: pause,
        isMock: true,
      );
    }

    final stageValue = s.waliStage.value;

    for (var i = 0; i < nActive; i++) {
      if (i < realActive.length) {
        out.add(realActive[i]);
      } else if (i < wards.length) {
        out.add(
          make(
            'dev-wj$i',
            wards[i],
            'active',
            stage: stageValue,
            pause: i == 0 && s._dashboardGuardianJourneyDecisionPending
                ? ZyraJourneyPauseState(
                    phase: ZyraPausePhase.pauseDecisionPending,
                    initiatedBy: wards[i].id,
                    requestedBy: wards[i].id,
                    requestedAt: now,
                    version: 1,
                  )
                : ZyraJourneyPauseState.active,
          ),
        );
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
            // Guardian wording is neutral: it sees the Journey state,
            // never which Seeker opened the decision.
            pause: const ZyraJourneyPauseState(
              phase: ZyraPausePhase.paused,
              initiatedBy: 'dev-seeker',
              version: 2,
            ),
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
  // the reason reset() drifted out of step with the fields. Every mutation
  // now goes through a named,
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
    _useLiveGuardianData = false;
    _mainGuardian = false;
    _additionalGuardianCount = 0;
    _pendingInviteCount = 0;
    _receivedInviteCount = 0;
    _guardianPreviewActiveJourneyCount = 1;
    _connectionsPreviewIsolated = true;
    _queuedJourneys = 0;
    _activeJourneys = 0;
    _pausedJourneys = 0;
    _endedJourneys = 0;
    _busyPotential = 0;
    _busyPaused = 0;
    _busyEnded = 0;
    _pauseScenario = ZyraPauseDevScenario.active;
    _browseSwipeFeedbackStyle = ZyraBrowseSwipeFeedbackStyle.fullAura;
    _introductionPreviewCount = 0;
    _consideredPreviewCount = 0;
    _savedPreviewCount = 0;
    _passedPreviewCount = 0;
    _localProfileDestinations.clear();
    _hiddenLocalProfileIds.clear();
    resetDashboardLab(notify: false);
    ZyraColors.selectAppSurfaceStyle(ZyraColors.currentDefaultSurfaceStyle);
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
