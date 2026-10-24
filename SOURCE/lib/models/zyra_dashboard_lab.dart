import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';

/// Five Founder-facing hierarchy experiments over one shared Dashboard state.
///
/// Option 1 is only the Lab reset state, not a selected production design. The
/// real Seeker and Guardian Dashboards remain unchanged until the Founder
/// chooses a candidate and separately authorises promotion.
enum ZyraDashboardConcept {
  nowJourneyYou(
    '1 · Now / Journey / You',
    'Three layers: what needs you, where your Journey stands, then useful personal context.',
  ),
  zyraCompass(
    '2 · ZYRA Compass',
    'One calm daily heading, a compact status board and supporting insight below.',
  ),
  journeyLens(
    '3 · Journey Lens',
    'Centres the active, potential, paused or searching state and arranges everything around it.',
  ),
  livingPriorities(
    '4 · Living Priorities',
    'Ranks one primary and two secondary priorities while folding quieter information away.',
  ),
  progressStory(
    '5 · Progress Story',
    'Explains where you are, what moved and what comes next as one concise narrative.',
  );

  final String label;
  final String rationale;
  const ZyraDashboardConcept(this.label, this.rationale);
}

enum ZyraDashboardAudiencePreview {
  current('Current account'),
  seeker('Seeker'),
  guardian('Guardian');

  final String label;
  const ZyraDashboardAudiencePreview(this.label);
}

enum ZyraDashboardRole { seeker, guardian }

/// Semantic Dashboard sections shared by the preview and its developer tools.
///
/// Seeker and Guardian have different four-tab structures. Keeping the names
/// and module ownership here means a developer control can never silently
/// drift away from the tab it is reviewing.
enum ZyraDashboardSection { today, updates, insights }

List<ZyraDashboardSection> zyraDashboardSectionsFor(ZyraDashboardRole role) =>
    switch (role) {
      ZyraDashboardRole.seeker => const [
        ZyraDashboardSection.today,
        ZyraDashboardSection.updates,
        ZyraDashboardSection.insights,
      ],
      ZyraDashboardRole.guardian => const [
        ZyraDashboardSection.today,
        ZyraDashboardSection.updates,
        ZyraDashboardSection.insights,
      ],
    };

String zyraDashboardSectionLabel(ZyraDashboardSection section) =>
    switch (section) {
      ZyraDashboardSection.today => 'Today',
      ZyraDashboardSection.updates => 'Updates',
      ZyraDashboardSection.insights => 'Insights',
    };

Set<ZyraDashboardModule> zyraDashboardModulesForSection({
  required ZyraDashboardRole role,
  required ZyraDashboardSection section,
}) => switch ((role, section)) {
  (ZyraDashboardRole.seeker, ZyraDashboardSection.today) => const {
    ZyraDashboardModule.onboarding,
    ZyraDashboardModule.nextStep,
    ZyraDashboardModule.journey,
    ZyraDashboardModule.discovery,
    ZyraDashboardModule.family,
    ZyraDashboardModule.saved,
    ZyraDashboardModule.profile,
  },
  (ZyraDashboardRole.seeker, ZyraDashboardSection.updates) => const {
    ZyraDashboardModule.activity,
    ZyraDashboardModule.milestone,
  },
  (ZyraDashboardRole.seeker, ZyraDashboardSection.insights) => const {
    ZyraDashboardModule.learning,
    ZyraDashboardModule.compatibility,
  },
  (ZyraDashboardRole.guardian, ZyraDashboardSection.today) => const {
    ZyraDashboardModule.nextStep,
    ZyraDashboardModule.family,
    ZyraDashboardModule.network,
    ZyraDashboardModule.seekers,
    ZyraDashboardModule.journey,
    ZyraDashboardModule.profile,
  },
  (ZyraDashboardRole.guardian, ZyraDashboardSection.updates) => const {
    ZyraDashboardModule.activity,
    ZyraDashboardModule.milestone,
  },
  (ZyraDashboardRole.guardian, ZyraDashboardSection.insights) => const {
    ZyraDashboardModule.learning,
  },
};

enum ZyraDashboardTab {
  now('Now'),
  insights('Insights');

  final String label;
  const ZyraDashboardTab(this.label);
}

enum ZyraSeekerDashboardTodayState {
  newSeeker('New Seeker'),
  noGuardian('No Guardian'),
  guardianConnected('Guardian connected'),
  guardianInvitationPending('Guardian invitation pending'),
  noJourney('No Journey'),
  potentialJourneys('Potential Journeys'),
  activeJourney('Active Journey'),
  journeyPaused('Journey paused'),
  journeyDecisionPending('Journey decision pending'),
  recentMovement('Recent meaningful movement'),
  calm('Calm · nothing needs attention'),
  loading('Loading'),
  partialFailure('Partial failure'),
  fullFailure('Full failure');

  final String label;
  const ZyraSeekerDashboardTodayState(this.label);
}

enum ZyraGuardianDashboardTodayState {
  noSeekers('No linked Seekers'),
  oneSeeker('One linked Seeker'),
  multipleSeekers('Multiple linked Seekers'),
  mainGuardian('Main Guardian'),
  additionalGuardian('Additional Guardian'),
  noJourney('No Journey'),
  activeJourney('Active Journey'),
  pausedJourney('Paused Journey'),
  journeyDecisionPending('Journey awaiting decision'),
  familyReviewWaiting('Family Review waiting'),
  guardianGateWaiting('Guardian Gate waiting'),
  pendingInvitation('Pending invitation'),
  networkBasicLocked('Guardian Network · No access'),
  networkPremiumActive('Guardian Network · Guardian access'),
  calm('Calm · nothing needs attention'),
  loading('Loading'),
  partialFailure('Partial failure'),
  fullFailure('Full failure');

  final String label;
  const ZyraGuardianDashboardTodayState(this.label);
}

enum ZyraDashboardUpdatesState {
  none('No updates'),
  oneInformational('One informational update'),
  oneActionable('One actionable update'),
  several('Several updates'),
  unread('Unread updates'),
  allRead('All read'),
  mixed('Mixed account / Journey / Guardian');

  final String label;
  const ZyraDashboardUpdatesState(this.label);
}

enum ZyraSeekerDashboardInsightsState {
  insufficient('Insufficient data'),
  basic('Membership inactive insight preview'),
  one('ZYRA One insight'),
  compatibility('Compatibility pattern'),
  discoveryHealth('Discovery Health'),
  preferenceReview('Preference review suggestion'),
  aiExplanation('DEV-only AI explanation');

  final String label;
  const ZyraSeekerDashboardInsightsState(this.label);
}

enum ZyraGuardianDashboardInsightsState {
  insufficient('Insufficient data'),
  familyProcess('Family-process insight'),
  multiSeeker('Multi-Seeker overview'),
  journeyPreparation('Journey preparation'),
  guardianNetwork('Guardian Network insight'),
  premium('Guardian insight');

  final String label;
  const ZyraGuardianDashboardInsightsState(this.label);
}

/// Explicit destinations owned by Dashboard content.
///
/// A module name is not a route: the same Journey module can mean Discovery
/// when no Journey exists, or the Journeys section of Connections once a
/// Potential/Active/Paused Journey exists. Keeping the destination beside the
/// rendered state prevents copy and navigation from drifting apart.
enum ZyraDashboardDestination {
  discovery,
  connectionsJourneys,
  connectionsActivity,
  guardian,
  notifications,
  profile,
  preferences,
  onboarding,
}

enum ZyraDashboardActivityState {
  empty('Empty'),
  normal('Normal'),
  busy('Busy'),
  urgent('Urgent');

  final String label;
  const ZyraDashboardActivityState(this.label);
}

enum ZyraDashboardJourneyPreview {
  none('No active Journey'),
  potentials('Potential Journeys'),
  active('Active Journey'),
  paused('Paused Journey'),
  ended('Recently ended');

  final String label;
  const ZyraDashboardJourneyPreview(this.label);
}

/// Eight stable developer presets from the Founder brief.
///
/// A preset stages only the mock adapter. It never changes a real profile,
/// Guardian link, Journey, entitlement or invitation.
enum ZyraDashboardContextPreset {
  newSeeker('A · New Seeker'),
  guardianInvitation('B · Guardian invitation'),
  potentialJourneys('C · Potential Journeys'),
  activeJourney('D · Active Journey'),
  activeWithGuardian('E · Journey + Guardian'),
  decisionRequired('F · Decision required'),
  pausedJourney('G · Paused Journey'),
  zyraOneInsights('H · ZYRA One insights');

  final String label;
  const ZyraDashboardContextPreset(this.label);
}

/// Founder-requested learning states for the developer Dashboard preview.
///
/// These describe UI examples only. They are not evidence thresholds and do
/// not activate any inference or preference mutation.
enum ZyraDashboardInsightState {
  insufficientData('Not enough information'),
  positive('Positive pattern'),
  neutral('Neutral pattern'),
  preferenceReview('Preference review');

  final String label;
  const ZyraDashboardInsightState(this.label);
}

enum ZyraDashboardInsightPlan {
  basic('Membership inactive'),
  one('ZYRA One');

  final String label;
  const ZyraDashboardInsightPlan(this.label);
}

const String zyraDashboardInsightsLabel = 'Insights for you';
const String zyraDashboardInsightsHeading = 'INSIGHTS FOR YOU';

enum ZyraDashboardModule {
  journey('Journey', Icons.route_outlined),
  onboarding('Profile setup', Icons.checklist_rounded),
  nextStep('Next step', Icons.arrow_forward_rounded),
  learning(zyraDashboardInsightsLabel, Icons.auto_awesome_outlined),
  activity('New activity', Icons.auto_awesome_outlined),
  family('Family', Icons.diversity_3_outlined),
  discovery('Discovery', Icons.search_rounded),
  saved('Saved', Icons.bookmark_outline_rounded),
  compatibility('Compatibility', Icons.insights_outlined),
  profile('Profile readiness', Icons.person_outline_rounded),
  milestone('Milestone', Icons.verified_outlined),
  seekers('Seekers', Icons.people_outline_rounded),
  network('Guardian Network', Icons.hub_outlined);

  final String label;
  final IconData icon;
  const ZyraDashboardModule(this.label, this.icon);
}

const List<ZyraDashboardModule> zyraDashboardDefaultOrder = [
  ZyraDashboardModule.journey,
  ZyraDashboardModule.onboarding,
  ZyraDashboardModule.nextStep,
  ZyraDashboardModule.learning,
  ZyraDashboardModule.activity,
  ZyraDashboardModule.family,
  ZyraDashboardModule.discovery,
  ZyraDashboardModule.saved,
  ZyraDashboardModule.compatibility,
  ZyraDashboardModule.profile,
  ZyraDashboardModule.milestone,
  ZyraDashboardModule.seekers,
  ZyraDashboardModule.network,
];

const Set<ZyraDashboardModule> zyraDashboardDefaultModules = {
  ...zyraDashboardDefaultOrder,
};

ZyraDashboardRole resolveDashboardRole({
  required ZyraDashboardAudiencePreview preview,
  required ZyraDashboardRole hostRole,
}) => switch (preview) {
  ZyraDashboardAudiencePreview.current => hostRole,
  ZyraDashboardAudiencePreview.seeker => ZyraDashboardRole.seeker,
  ZyraDashboardAudiencePreview.guardian => ZyraDashboardRole.guardian,
};

class ZyraDashboardViewConfig {
  final ZyraDashboardConcept concept;
  final ZyraDashboardRole role;
  final ZyraAppSurfaceStyle surfaceStyle;
  final ZyraDashboardActivityState activityState;
  final ZyraDashboardJourneyPreview journeyPreview;
  final bool newActivity;
  final bool pendingApproval;
  final ZyraDashboardInsightState insightState;
  final ZyraDashboardInsightPlan insightPlan;
  final bool onboardingComplete;
  final int onboardingAnswered;
  final int onboardingTotal;
  final int familyProgress;
  final int supportedSeekers;
  final int potentialJourneys;
  final int savedProfiles;
  final bool hasGuardian;
  final bool guardianActivity;
  final bool familyIntroductionActive;
  final ZyraDashboardContextPreset? contextPreset;
  final Set<ZyraDashboardModule> enabledModules;
  final List<ZyraDashboardModule> moduleOrder;

  const ZyraDashboardViewConfig({
    required this.concept,
    required this.role,
    required this.surfaceStyle,
    required this.activityState,
    required this.journeyPreview,
    required this.newActivity,
    required this.pendingApproval,
    required this.insightState,
    required this.insightPlan,
    required this.onboardingComplete,
    required this.onboardingAnswered,
    required this.onboardingTotal,
    required this.familyProgress,
    required this.supportedSeekers,
    this.potentialJourneys = 3,
    this.savedProfiles = 7,
    this.hasGuardian = true,
    this.guardianActivity = false,
    this.familyIntroductionActive = false,
    this.contextPreset,
    required this.enabledModules,
    required this.moduleOrder,
  });
}
