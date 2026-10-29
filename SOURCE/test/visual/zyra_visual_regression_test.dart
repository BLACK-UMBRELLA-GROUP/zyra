import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';
import 'package:zyra/screens/home/seeker_dashboard_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/screens/wali/wali_gn_shared.dart';
import 'package:zyra/screens/wali/wali_dashboard_screen.dart';
import 'package:zyra/screens/wali/wali_network_screen.dart';
import 'package:zyra/screens/wali/wali_seeker_workspace_screen.dart';
import 'package:zyra/screens/wali/wali_seekers_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/services/zyra_dashboard_updates_service.dart';
import 'package:zyra/services/zyra_guardian_seeker_roster_resolver.dart';
import 'package:zyra/services/zyra_wali_journey_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';
import 'package:zyra/widgets/zyra_loading.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

/// Candidate screenshots are deliberately separate from approved baselines.
///
/// Normal invocation performs render/overflow checks and compares only entries
/// explicitly present in `approved/manifest.json`. The capture command adds
/// `--update-goldens --dart-define=ZYRA_CAPTURE_CANDIDATES=true`, which writes
/// to `candidates/`; it can never replace `approved/` by accident.
const _captureCandidates = bool.fromEnvironment('ZYRA_CAPTURE_CANDIDATES');
// Health checks must not overwrite sealed historical candidate copies which
// the promotion ledger still byte-verifies. The normal candidate path remains
// unchanged for the governed visual workflow.
const _healthCapture = bool.fromEnvironment('ZYRA_HEALTH_CAPTURE');
// Theme explorations must preserve sealed earlier candidate copies.
const _candidateDirectory = String.fromEnvironment(
  'ZYRA_VISUAL_CANDIDATE_DIRECTORY',
  defaultValue: 'candidates',
);

/// Founder-approved OA-ZYRA-281 files remain byte-preserved after Phase 3
/// supersedes their Today presentation. Each archived fixture is explicitly
/// paired with its promoted replacement rather than silently disappearing.
const _presentationSupersededFixtures = <String, String>{
  'seeker-dashboard-unread': 'seeker-dashboard-thinned-no-guardian',
  'seeker-dashboard-resolved-actions': 'seeker-dashboard-thinned-connected',
  'seeker-dashboard-home-lower-levels':
      'seeker-dashboard-thinned-pending-invitation',
};

/// Phase 1 rows superseded by the post-067 Founder-directed Guardian delta.
/// The accepted v2 replacements are active; every v1 pixel remains preserved
/// in the archive ledger at its original path.
const _phase1SupersededFixtures = <String, String>{
  'guardianship-manager-empty': 'guardian-manager-empty',
  'guardianship-manager-main-consent-off': 'guardian-manager-main',
  'guardianship-manager-loaded-consent-on': 'guardian-manager-loaded-pending',
  'guardianship-manager-unavailable': 'guardian-manager-unavailable',
  'guardian-detail-main': 'guardian-detail-main-consent-off',
  'guardian-detail-history-unavailable':
      'guardian-detail-main-history-unavailable-consent-off',
};

// OA-ZYRA-316 Tier 1 removes these unused screens. Historical approval
// manifests stay sealed; the active manifests retain their retirement metadata.
const _tier1RetiredFixtures = <String>{
  'guardian-detail-main-consent-off',
  'guardian-detail-additional',
  'guardian-detail-main-history-unavailable-consent-off',
  'notifications-empty',
  'notifications-error',
};

const _visualRoot = ValueKey('zyra-visual-audit-root');

Future<ByteData> _fontBytes(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

class _Device {
  final String id;
  final Size size;

  const _Device(this.id, this.size);
}

const _devices = <_Device>[
  _Device('small', Size(320, 568)),
  _Device('standard', Size(390, 844)),
  _Device('large', Size(430, 932)),
];

class _Fixture {
  final String id;
  final String role;
  final String plan;
  final String state;
  final bool largeText;
  final Widget Function() build;

  const _Fixture({
    required this.id,
    required this.role,
    required this.plan,
    required this.state,
    required this.build,
    this.largeText = false,
  });
}

Widget _gradientBody(Widget child, {String? title}) => Scaffold(
  body: DecoratedBox(
    decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
              child: Text(title, style: ZyraText.heading(size: 25)),
            ),
          Expanded(child: child),
        ],
      ),
    ),
  ),
);

Widget _guardianAccess({required bool entitled, required bool linked}) =>
    _gradientBody(
      GuardianNetworkAccessView(
        hasEntitlement: entitled,
        hasLinkedSeeker: linked,
        onLinkSeeker: () {},
        onMembership: () {},
      ),
      title: 'Network',
    );

Widget _guardianSlider() {
  const wards = [
    WaliLinkedPerson(id: '1', firstName: 'Maryam', isMain: true),
    WaliLinkedPerson(id: '2', firstName: 'Muhammad'),
    WaliLinkedPerson(id: '3', firstName: 'Abdul-Rahman'),
    WaliLinkedPerson(id: '4', firstName: 'Nur'),
    WaliLinkedPerson(id: '5', firstName: 'Ibrahim'),
    WaliLinkedPerson(id: '6', firstName: 'Khadijah'),
  ];
  GNContext.instance.reset();
  return _gradientBody(
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          const GNSeekerSlider(wards: wards),
          const Spacer(),
          ZyraEmptyState(
            icon: Icons.family_restroom_outlined,
            title: 'Six linked Seekers',
            message:
                'The four-name window remains usable while every other Seeker stays available from the overflow control.',
          ),
          const Spacer(),
        ],
      ),
    ),
    title: 'Dashboard',
  );
}

DashboardSnapshot _calmDashboardSnapshot() => const DashboardSnapshot(
  role: DashboardRole.seeker,
  onboarding: DashboardSource.available(<DashboardSignal>[]),
  journeys: DashboardSource.available(
    DashboardJourneyState(
      summary: DashboardJourneySummary(
        id: 'visual-searching',
        kind: DashboardJourneyKind.searching,
        title: 'Ready for introductions',
        detail: 'New introductions will appear when they are available.',
      ),
    ),
  ),
  updates: DashboardSource.available(<DashboardSignal>[]),
  guardianInvitations: DashboardSource.available(<DashboardSignal>[]),
  insights: DashboardSource.available(<DashboardSignal>[]),
  advisories: DashboardSource.available(<DashboardAdvisory>[]),
  stableState: DashboardStableState(
    orientationItems: DashboardSource.available(<DashboardOrientationItem>[
      DashboardOrientationItem(
        id: 'visual-guardian-orientation',
        kind: DashboardOrientationKind.guardian,
        title: 'Guardian',
        valueLabel: 'Not connected',
        target: ZyraDashboardTarget.guardian,
      ),
      DashboardOrientationItem(
        id: 'visual-unread-orientation',
        kind: DashboardOrientationKind.unread,
        title: 'New activity',
        valueLabel: '12',
        target: ZyraDashboardTarget.notifications,
      ),
    ]),
    family: DashboardSource.available(
      DashboardFamilyStatus(
        kind: DashboardFamilyKind.notConnected,
        title: 'No Guardian connected',
        detail: 'Add a Guardian when you are ready.',
        actionLabel: 'Add Guardian',
      ),
    ),
  ),
);

DashboardSnapshot _resolvedDashboardSnapshot() => DashboardSnapshot(
  role: DashboardRole.seeker,
  onboarding: const DashboardSource.available(<DashboardSignal>[]),
  journeys: DashboardSource.available(
    DashboardJourneyState(
      summary: DashboardJourneySummary(
        id: 'visual-active',
        kind: DashboardJourneyKind.active,
        title: 'You & Adam',
        detail: 'Faith & Values · Stage 4 of 8',
        progress: 0.5,
        latestCompletedStage: 'Latest: Compatibility Reveal completed',
        nextMilestone: 'Next: Faith & Values',
        momentum: 'Your Journey moved forward this week.',
      ),
      signals: <DashboardSignal>[
        DashboardSignal(
          id: 'visual-stage-decision',
          kind: DashboardSignalKind.deadlineDecision,
          title: 'Your Journey needs a decision',
          detail: 'Review the current stage before the decision window closes.',
          actionLabel: 'Review decision',
          target: ZyraDashboardTarget.connectionsJourneys,
          dueAt: _visualDecisionDue,
        ),
        DashboardSignal(
          id: 'visual-next-step',
          kind: DashboardSignalKind.ownJourneyMove,
          title: 'Your next Journey step is ready',
          detail: 'Continue when you have had time to reflect.',
          actionLabel: 'Open Journey',
          target: ZyraDashboardTarget.connectionsJourneys,
          eventAt: _visualEventAt,
        ),
      ],
    ),
  ),
  updates: DashboardSource.available(<DashboardSignal>[
    DashboardSignal(
      id: 'visual-notification',
      kind: DashboardSignalKind.meaningfulMovement,
      title: 'A Guardian update is ready',
      detail: 'Open Notifications to review the recorded update.',
      actionLabel: 'Review update',
      target: ZyraDashboardTarget.notifications,
      eventAt: _visualEventAt,
    ),
    DashboardSignal(
      id: 'visual-guardian-activity',
      kind: DashboardSignalKind.meaningfulMovement,
      title: 'Family Review completed',
      detail: 'Today',
      actionLabel: 'Open Guardian',
      target: ZyraDashboardTarget.guardian,
      eventAt: _visualEarlierEventAt,
    ),
  ]),
  guardianInvitations: const DashboardSource.available(<DashboardSignal>[]),
  insights: const DashboardSource.available(<DashboardSignal>[
    DashboardSignal(
      id: 'visual-insight',
      kind: DashboardSignalKind.governedInsight,
      title: 'Faith & Values remains a strong area',
      detail: 'This is a test-only governed insight state.',
      target: ZyraDashboardTarget.preferences,
    ),
  ]),
  stableState: const DashboardStableState(
    orientationItems: DashboardSource.available(<DashboardOrientationItem>[
      DashboardOrientationItem(
        id: 'visual-potentials-orientation',
        kind: DashboardOrientationKind.potentials,
        title: 'Potential Journeys',
        valueLabel: '2',
        target: ZyraDashboardTarget.connectionsJourneys,
      ),
      DashboardOrientationItem(
        id: 'visual-guardian-orientation',
        kind: DashboardOrientationKind.guardian,
        title: 'Guardian',
        valueLabel: 'Connected',
        detail: 'Father · Guardian connected',
        target: ZyraDashboardTarget.guardian,
      ),
      DashboardOrientationItem(
        id: 'visual-unread-orientation',
        kind: DashboardOrientationKind.unread,
        title: 'New activity',
        valueLabel: '7',
        target: ZyraDashboardTarget.notifications,
      ),
    ]),
    family: DashboardSource.available(
      DashboardFamilyStatus(
        kind: DashboardFamilyKind.connected,
        title: 'Father · Guardian connected',
        linkedCount: 1,
      ),
    ),
  ),
);

final _visualDecisionDue = DateTime.utc(2026, 9, 1, 12);
final _visualEventAt = DateTime.utc(2026, 8, 28, 10);
final _visualEarlierEventAt = DateTime.utc(2026, 8, 27, 10);
final _visualComparisonNow = DateTime.utc(2026, 8, 30, 18);

DashboardSnapshot _seekerFamilySnapshot(
  DashboardSource<DashboardFamilyStatus> family,
) {
  final base = _calmDashboardSnapshot();
  return DashboardSnapshot(
    role: base.role,
    onboarding: base.onboarding,
    journeys: base.journeys,
    updates: base.updates,
    guardianInvitations: base.guardianInvitations,
    insights: base.insights,
    advisories: base.advisories,
    stableState: DashboardStableState(
      orientationItems: base.stableState.orientationItems,
      family: family,
    ),
  );
}

DashboardSnapshot _pendingGuardianDashboardSnapshot() => _seekerFamilySnapshot(
  DashboardSource.available(
    DashboardFamilyStatus(
      kind: DashboardFamilyKind.invitationPending,
      title: '2 Guardian invitations pending',
      detail: 'Earliest invitation expires in 2 days.',
      pendingInvitationCount: 2,
      expiresAt: _visualComparisonNow.add(const Duration(days: 2)),
    ),
  ),
);

DashboardSnapshot _unavailableGuardianDashboardSnapshot() =>
    _seekerFamilySnapshot(
      const DashboardSource.unavailable(
        DashboardFailure(code: 'guardian_status_unavailable'),
      ),
    );

Widget _productionDashboardFixture(
  DashboardSnapshot snapshot, {
  required int selectedTab,
}) => ZyraQuietDashboard(
  resolution: const DashboardResolver().resolve(snapshot),
  firstName: 'Maryam',
  comparisonClock: _visualComparisonNow,
  onNavigate: (_) {},
  onRetry: () {},
  selectedTabIndex: selectedTab == 2 ? 1 : 0,
);

Widget _seekerLastKnownUpdatesFixture() {
  const resolver = DashboardResolver();
  final previous = resolver.resolve(_resolvedDashboardSnapshot());
  final base = _calmDashboardSnapshot();
  final failed = resolver
      .resolve(
        DashboardSnapshot(
          role: base.role,
          onboarding: base.onboarding,
          journeys: base.journeys,
          updates: const DashboardSource.unavailable(
            DashboardFailure(code: 'updates_unavailable'),
          ),
          guardianInvitations: base.guardianInvitations,
          insights: base.insights,
          advisories: base.advisories,
          stableState: base.stableState,
        ),
      )
      .retainUpdatesFrom(previous);
  return ZyraQuietDashboard(
    resolution: failed,
    firstName: 'Maryam',
    comparisonClock: _visualComparisonNow,
    onNavigate: (_) {},
    onRetry: () {},
    selectedTabIndex: 0,
  );
}

const _visualGuardianJourney = WaliJourneyView(
  matchId: 'visual-guardian-match',
  linkedSeekerId: 'visual-seeker',
  linkedSeekerName: 'Maryam',
  partner: SeekerProfile(
    id: 'visual-partner',
    firstName: 'Adam',
    age: 31,
    city: '—',
    photos: [],
    gender: 'male',
  ),
  counterpartGuardianName: null,
  counterpartGuardianSurname: null,
  status: 'ended',
  journeyStage: 'phase_2',
);

ZyraDashboardUpdate _visualGuardianUpdate({
  String sourceId = 'visual-domain-update',
  bool? isUnread,
  bool notification = false,
}) => ZyraDashboardUpdate(
  occurredAt: DateTime.utc(2026, 8, 30, notification ? 11 : 10),
  classKey: notification ? 'notification' : 'journey_timeline_milestone',
  sourceId: sourceId,
  titleKey: notification
      ? 'dashboard_updates.notification.new_message.title'
      : 'dashboard_updates.journey.timeline_milestone.title',
  detailKey: notification
      ? 'dashboard_updates.notification.new_message.detail'
      : 'dashboard_updates.journey.timeline_milestone.journey_continued.detail',
  destinationKey: notification ? 'notifications' : 'connections.journeys',
  relatedMatchId: notification ? null : _visualGuardianJourney.matchId,
  isUnread: isUnread,
);

Widget _guardianUpdatesFixture({
  required List<ZyraDashboardUpdate> rows,
  bool failAfterFirstRead = false,
}) {
  ZyraDeveloperAccess.setAuthorizedForTesting(false);
  ZyraDevScenario.instance
    ..resetDashboardLab()
    ..setDashboardLabEnabled(false)
    ..setWaliLinkedSeekers(1);
  AppState.instance.setWaliRealLinkedSeekers(const [
    WaliLinkedPerson(id: 'visual-seeker', firstName: 'Maryam', isMain: true),
  ]);
  var reads = 0;
  return WaliDashboardScreen(
    onNotificationsChanged: () {},
    comparisonNow: _visualComparisonNow,
    loadJourneys: () async => const [_visualGuardianJourney],
    loadOpenReviews: (_) async => const ZyraSourceResult.available(<String>{}),
    loadUpdates: () async {
      reads++;
      if (failAfterFirstRead && reads > 1) return null;
      return ZyraDashboardUpdatesPage(rows: rows, nextCursor: null);
    },
  );
}

const _guardianTodayPeople = <WaliLinkedPerson>[
  WaliLinkedPerson(id: 'visual-main-maryam', firstName: 'Maryam', isMain: true),
  WaliLinkedPerson(id: 'visual-additional-aisha', firstName: 'Aisha'),
  WaliLinkedPerson(id: 'visual-main-zaynab', firstName: 'Zaynab', isMain: true),
];

WaliJourneyView _guardianTodayJourney(
  WaliLinkedPerson person, {
  required String suffix,
  String stage = 'wali_gate',
}) => WaliJourneyView(
  matchId: 'visual-dashboard-$suffix',
  linkedSeekerId: person.id,
  linkedSeekerName: person.firstName,
  partner: SeekerProfile(
    id: 'visual-dashboard-partner-$suffix',
    firstName: suffix == 'additional-hidden' ? 'Hidden Person' : 'Adam',
    age: 30,
    city: '—',
    photos: const [],
    gender: '',
  ),
  counterpartGuardianName: null,
  counterpartGuardianSurname: null,
  status: 'active',
  journeyStage: stage,
  isMock: true,
);

Widget _guardianTodayFixture({
  required List<WaliLinkedPerson> people,
  required List<WaliJourneyView>? journeys,
}) {
  ZyraDeveloperAccess.setAuthorizedForTesting(false);
  final scenario = ZyraDevScenario.instance
    ..resetDashboardLab()
    ..setDashboardLabEnabled(false)
    ..setWaliRole(WaliRole.main)
    ..setWaliLinkedSeekers(people.length)
    ..setWaliActiveJourneys(journeys?.length ?? 0)
    ..setWaliPausedJourneys(0)
    ..setWaliEndedJourneys(0)
    ..setWaliReviewWaiting(false)
    ..setWaliSentInvites(0);
  // Keep the reference alive through construction; its setters establish the
  // deterministic debug/profile composition used by this production widget.
  assert(scenario.waliLinkedSeekers == people.length);
  AppState.instance.setWaliRealLinkedSeekers(people);
  return WaliDashboardScreen(
    onOpenSeekers: () {},
    comparisonNow: _visualComparisonNow,
    loadJourneys: () async => journeys,
    loadOpenReviews: (_) async => const ZyraSourceResult.available(<String>{}),
    loadUpdates: () async =>
        ZyraDashboardUpdatesPage(rows: const [], nextCursor: null),
  );
}

final _managerPeople = <WaliLinkedPerson>[
  WaliLinkedPerson(
    id: 'visual-main-guardian',
    firstName: 'Abdul',
    relationship: 'father',
    isMain: true,
    linkedAt: DateTime.utc(2026, 4, 12),
  ),
  WaliLinkedPerson(
    id: 'visual-additional-guardian',
    firstName: 'Hassan',
    relationship: 'brother',
    linkedAt: DateTime.utc(2026, 5, 8),
  ),
  WaliLinkedPerson(
    id: 'visual-additional-guardian-2',
    firstName: 'Ibrahim',
    relationship: 'uncle',
    linkedAt: DateTime.utc(2026, 6, 21),
  ),
];

Widget _managerFixture({
  required List<WaliLinkedPerson> people,
  bool linksAvailable = true,
  List<PendingInvite> pending = const [],
}) => _gradientBody(
  GuardianshipManagerView(
    people: people,
    linksAvailable: linksAvailable,
    onRetryLinks: () {},
    onOpenGuardian: (_) {},
    onAdd: () {},
    pendingInvitesLoader: () async => ZyraSourceResult.available(pending),
    comparisonNow: _visualComparisonNow,
  ),
);

const _guardianRosterResolver = ZyraGuardianSeekerRosterResolver();

final _guardianRosterMainPeople = <WaliLinkedPerson>[
  WaliLinkedPerson(
    id: 'visual-roster-review-old',
    firstName: 'Zaynab',
    isMain: true,
    relationship: 'father',
    linkedAt: DateTime.utc(2026, 2, 10),
  ),
  WaliLinkedPerson(
    id: 'visual-roster-review-new',
    firstName: 'Aaliyah',
    isMain: true,
    relationship: 'uncle',
    linkedAt: DateTime.utc(2026, 3, 12),
  ),
  WaliLinkedPerson(
    id: 'visual-roster-active',
    firstName: 'Bilal',
    isMain: true,
    relationship: 'brother',
    linkedAt: DateTime.utc(2026, 4, 14),
  ),
  WaliLinkedPerson(
    id: 'visual-roster-paused',
    firstName: 'Hana',
    isMain: true,
    relationship: 'legal_guardian',
    linkedAt: DateTime.utc(2026, 5, 16),
  ),
  WaliLinkedPerson(
    id: 'visual-roster-other',
    firstName: 'Maryam',
    isMain: true,
    relationship: 'father',
    linkedAt: DateTime.utc(2026, 6, 18),
  ),
];

final _guardianRosterAdditionalPeople = <WaliLinkedPerson>[
  WaliLinkedPerson(
    id: 'visual-additional-zara',
    firstName: 'Zara',
    relationship: 'aunt',
    linkedAt: DateTime.utc(2026, 7, 2),
  ),
  WaliLinkedPerson(
    id: 'visual-additional-aisha',
    firstName: 'Aisha',
    relationship: 'sister',
    linkedAt: DateTime.utc(2026, 7, 9),
  ),
  WaliLinkedPerson(
    id: 'visual-additional-umar',
    firstName: 'Umar',
    relationship: 'uncle',
    linkedAt: DateTime.utc(2026, 7, 16),
  ),
];

WaliJourneyView _guardianRosterJourney(
  WaliLinkedPerson person, {
  required String suffix,
  required String stage,
  ZyraJourneyPauseState pause = ZyraJourneyPauseState.active,
}) => WaliJourneyView(
  attemptId: 'visual-attempt-$suffix',
  matchId: 'visual-match-$suffix',
  linkedSeekerId: person.id,
  linkedSeekerName: person.firstName,
  partner: SeekerProfile(
    id: 'visual-partner-$suffix',
    firstName: suffix == 'old-review' ? 'Idris' : 'Adam',
    age: 30,
    city: '—',
    photos: const [],
    gender: '',
  ),
  counterpartGuardianName: null,
  counterpartGuardianSurname: null,
  status: 'active',
  journeyStage: stage,
  pause: pause,
);

GuardianSeekerRosterResolution _guardianRosterPriorityResolution() {
  final oldReview = _guardianRosterJourney(
    _guardianRosterMainPeople[0],
    suffix: 'old-review',
    stage: 'phase_1',
  );
  final newReview = _guardianRosterJourney(
    _guardianRosterMainPeople[1],
    suffix: 'new-review',
    stage: 'phase_2',
  );
  final active = _guardianRosterJourney(
    _guardianRosterMainPeople[2],
    suffix: 'active',
    stage: 'phase_2',
  );
  return _guardianRosterResolver.resolve(
    linkedPeople: _guardianRosterMainPeople.take(3).toList(),
    context: GuardianSeekerRosterContext(
      journeys: [oldReview, newReview, active],
      openReviewMatchIds: {oldReview.matchId, newReview.matchId},
      waitingSinceByMatchId: {
        oldReview.matchId: _visualComparisonNow.subtract(
          const Duration(days: 2),
        ),
        newReview.matchId: _visualComparisonNow.subtract(
          const Duration(hours: 4),
        ),
      },
    ),
  );
}

GuardianSeekerRosterResolution _guardianRosterLowerResolution() {
  final paused = _guardianRosterJourney(
    _guardianRosterMainPeople[3],
    suffix: 'paused',
    stage: 'phase_2',
    pause: const ZyraJourneyPauseState(
      phase: ZyraPausePhase.paused,
      initiatedBy: 'visual-seeker',
    ),
  );
  return _guardianRosterResolver.resolve(
    linkedPeople: _guardianRosterMainPeople.sublist(3),
    context: GuardianSeekerRosterContext(journeys: [paused]),
  );
}

GuardianSeekerRosterResolution _guardianAdditionalResolution() =>
    _guardianRosterResolver.resolve(
      linkedPeople: _guardianRosterAdditionalPeople,
      // Deliberately malicious underlying context: the authority-first
      // resolver must produce the same neutral alphabetical section.
      context: GuardianSeekerRosterContext(
        journeys: [
          _guardianRosterJourney(
            _guardianRosterAdditionalPeople[0],
            suffix: 'hidden-gate',
            stage: 'wali_gate',
          ),
          _guardianRosterJourney(
            _guardianRosterAdditionalPeople[1],
            suffix: 'hidden-paused',
            stage: 'phase_3',
            pause: const ZyraJourneyPauseState(phase: ZyraPausePhase.paused),
          ),
        ],
        openReviewMatchIds: const {'visual-match-hidden-gate'},
      ),
    );

Widget _guardianRosterFixture(GuardianSeekerRosterResolution resolution) =>
    GuardianSeekerRosterView(
      resolution: resolution,
      onRetry: () {},
      onInvite: () {},
      onOpenSeeker: (_) {},
    );

GuardianSeekerRosterEntry _guardianWorkspaceMainEntry() {
  final person = _guardianRosterMainPeople[2];
  final journey = _guardianRosterJourney(
    person,
    suffix: 'workspace-current',
    stage: 'phase_2',
  );
  return GuardianSeekerRosterEntry(
    person: person,
    currentJourney: journey,
    group: GuardianSeekerRosterGroup.inAJourney,
    needsAttention: false,
    waitingSince: null,
    contextLine: 'Journey with Adam · Building a Life',
  );
}

GuardianSeekerRosterEntry _guardianWorkspaceAdditionalEntry() =>
    GuardianSeekerRosterEntry(
      person: _guardianRosterAdditionalPeople[1],
      currentJourney: null,
      group: null,
      needsAttention: false,
      waitingSince: null,
      contextLine: 'Additional Guardian',
    );

Widget _guardianWorkspaceFixture({
  required GuardianSeekerRosterEntry entry,
  List<GuardianAttemptSummary> summaries = const [],
  bool unavailable = false,
}) => GuardianSeekerWorkspaceView(
  entry: entry,
  summaries: summaries,
  summaryUnavailable: unavailable,
  onRetrySummary: () {},
  onOpenJourney: (_) {},
  onOpenNetwork: () {},
);

Widget _styleShowcase(ZyraNavStyle nav, ZyraDevLightAccent accent) {
  ZyraColors.selectDevPalette(ZyraDevPalette.crystalMist);
  ZyraColors.selectDevLightAccent(accent);
  ZyraInteractionStyle.selectNavStyle(nav);
  return Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: ZyraText.heading(size: 26)),
                    const SizedBox(height: 4),
                    Text(
                      'Assalamu alaikum, Maryam.',
                      style: ZyraText.subtext(size: 13.5),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: ZyraColors.glassFill,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: ZyraColors.glassBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your ZYRA', style: ZyraText.heading(size: 20)),
                          const SizedBox(height: 8),
                          Text(
                            'Crystal UI · ${accent.label} accent',
                            style: ZyraText.subtext(size: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        FloatingNavBar(
          currentIndex: 2,
          onTap: (_) {},
          items: const [
            FloatingNavItem(icon: Icons.search, label: 'Browse'),
            FloatingNavItem(icon: Icons.bookmark_border, label: 'Connections'),
            FloatingNavItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              badge: 8,
            ),
            FloatingNavItem(
              icon: Icons.gpp_good_outlined,
              label: 'Guardian',
              dot: true,
            ),
            FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
          ],
        ),
      ],
    ),
  );
}

List<_Fixture> _fixtures() => [
  _Fixture(
    id: 'auth-normal',
    role: 'female-seeker',
    plan: 'basic',
    state: 'normal',
    largeText: true,
    build: () => const WelcomeScreen(),
  ),
  _Fixture(
    id: 'onboarding-intro',
    role: 'male-seeker',
    plan: 'basic',
    state: 'normal',
    largeText: true,
    build: () => OnboardingStageIntroScreen(
      stage: SeekerOnboardingStage.buildProfile,
      welcomeName: 'Shakeel Ahmad',
      onContinue: () {},
    ),
  ),
  _Fixture(
    id: 'seeker-dashboard-thinned-no-guardian',
    role: 'female-seeker',
    plan: 'basic',
    state: 'normal',
    largeText: true,
    build: () => SeekerDashboardScreen(
      unreadCount: 12,
      onOpenConnections: () {},
      onOpenGuardian: () {},
      onNotificationsChanged: () {},
      loadDashboard: () async => _calmDashboardSnapshot(),
    ),
  ),
  _Fixture(
    id: 'seeker-dashboard-thinned-connected',
    role: 'female-seeker',
    plan: 'basic',
    state: 'expanded',
    largeText: true,
    build: () => SeekerDashboardScreen(
      unreadCount: 7,
      onOpenConnections: () {},
      onOpenGuardian: () {},
      onNotificationsChanged: () {},
      loadDashboard: () async => _resolvedDashboardSnapshot(),
    ),
  ),
  _Fixture(
    id: 'seeker-dashboard-thinned-pending-invitation',
    role: 'female-seeker',
    plan: 'basic',
    state: 'expanded-lower-levels',
    largeText: true,
    build: () => SeekerDashboardScreen(
      unreadCount: 7,
      onOpenConnections: () {},
      onOpenGuardian: () {},
      onNotificationsChanged: () {},
      loadDashboard: () async => _pendingGuardianDashboardSnapshot(),
    ),
  ),
  _Fixture(
    id: 'seeker-dashboard-thinned-unavailable',
    role: 'female-seeker',
    plan: 'basic',
    state: 'guardian-status-unavailable',
    largeText: true,
    build: () => SeekerDashboardScreen(
      unreadCount: 0,
      onOpenConnections: () {},
      onOpenGuardian: () {},
      onNotificationsChanged: () {},
      loadDashboard: () async => _unavailableGuardianDashboardSnapshot(),
    ),
  ),
  _Fixture(
    id: 'seeker-dashboard-updates-populated',
    role: 'female-seeker',
    plan: 'basic',
    state: 'updates-populated',
    largeText: true,
    build: () => _productionDashboardFixture(
      _resolvedDashboardSnapshot(),
      selectedTab: 1,
    ),
  ),
  _Fixture(
    id: 'seeker-dashboard-updates-empty',
    role: 'female-seeker',
    plan: 'basic',
    state: 'updates-honest-empty',
    largeText: true,
    build: () =>
        _productionDashboardFixture(_calmDashboardSnapshot(), selectedTab: 1),
  ),
  _Fixture(
    id: 'seeker-dashboard-updates-last-known',
    role: 'female-seeker',
    plan: 'basic',
    state: 'updates-last-known',
    largeText: true,
    build: _seekerLastKnownUpdatesFixture,
  ),
  _Fixture(
    id: 'seeker-dashboard-insights-empty',
    role: 'female-seeker',
    plan: 'basic',
    state: 'insights-honest-empty',
    largeText: true,
    build: () =>
        _productionDashboardFixture(_calmDashboardSnapshot(), selectedTab: 2),
  ),
  _Fixture(
    id: 'guardian-manager-empty',
    role: 'female-seeker',
    plan: 'basic',
    state: 'honest-empty',
    largeText: true,
    build: () => _managerFixture(people: const []),
  ),
  _Fixture(
    id: 'guardian-manager-main',
    role: 'female-seeker',
    plan: 'basic',
    state: 'main-only',
    largeText: true,
    build: () => _managerFixture(people: [_managerPeople.first]),
  ),
  _Fixture(
    id: 'guardian-manager-loaded-pending',
    role: 'female-seeker',
    plan: 'basic',
    state: 'main-additional-pending',
    largeText: true,
    build: () => _managerFixture(
      people: _managerPeople,
      pending: [
        PendingInvite(
          token: 'ZYRA2608',
          label: 'Uncle Yusuf',
          createdAt: DateTime.utc(2026, 8, 29, 12),
          expiresAt: DateTime.utc(2026, 9, 2, 12),
        ),
      ],
    ),
  ),
  _Fixture(
    id: 'guardian-manager-unavailable',
    role: 'female-seeker',
    plan: 'basic',
    state: 'links-unavailable',
    largeText: true,
    build: () => _managerFixture(people: const [], linksAvailable: false),
  ),
  _Fixture(
    id: 'guardian-seeker-roster-empty',
    role: 'guardian',
    plan: 'basic',
    state: 'honest-empty',
    largeText: true,
    build: () => _guardianRosterFixture(
      const GuardianSeekerRosterResolution(
        mainSections: [],
        additionalGuardianships: [],
      ),
    ),
  ),
  _Fixture(
    id: 'guardian-seeker-roster-main-priority',
    role: 'guardian',
    plan: 'basic',
    state: 'needs-you-oldest-first-and-active',
    largeText: true,
    build: () => _guardianRosterFixture(_guardianRosterPriorityResolution()),
  ),
  _Fixture(
    id: 'guardian-seeker-roster-main-lower-groups',
    role: 'guardian',
    plan: 'basic',
    state: 'paused-waiting-other-and-invite',
    largeText: true,
    build: () => _guardianRosterFixture(_guardianRosterLowerResolution()),
  ),
  _Fixture(
    id: 'guardian-seeker-roster-additional-neutral',
    role: 'guardian',
    plan: 'basic',
    state: 'additional-neutral-no-journey-leakage',
    largeText: true,
    build: () => _guardianRosterFixture(_guardianAdditionalResolution()),
  ),
  _Fixture(
    id: 'guardian-seeker-roster-unavailable',
    role: 'guardian',
    plan: 'basic',
    state: 'source-unavailable',
    largeText: true,
    build: () =>
        _gradientBody(ZyraUnknownErrorState(onRetry: () {}), title: 'Seekers'),
  ),
  _Fixture(
    id: 'guardian-seeker-workspace-main-loaded',
    role: 'guardian',
    plan: 'basic',
    state: 'current-ended-and-null-ended-date',
    largeText: true,
    build: () => _guardianWorkspaceFixture(
      entry: _guardianWorkspaceMainEntry(),
      summaries: [
        GuardianAttemptSummary(
          attemptId: 'visual-attempt-workspace-current',
          startedAt: _visualComparisonNow.subtract(const Duration(days: 18)),
          endedAt: null,
          ended: false,
        ),
        GuardianAttemptSummary(
          attemptId: 'visual-attempt-ended-recorded',
          startedAt: DateTime.utc(2026, 5, 3),
          endedAt: DateTime.utc(2026, 6, 21),
          ended: true,
        ),
        GuardianAttemptSummary(
          attemptId: 'visual-attempt-ended-null',
          startedAt: DateTime.utc(2026, 3, 14),
          endedAt: null,
          ended: true,
        ),
      ],
    ),
  ),
  _Fixture(
    id: 'guardian-seeker-workspace-main-empty',
    role: 'guardian',
    plan: 'basic',
    state: 'summary-honest-empty',
    largeText: true,
    build: () =>
        _guardianWorkspaceFixture(entry: _guardianWorkspaceMainEntry()),
  ),
  _Fixture(
    id: 'guardian-seeker-workspace-main-unavailable',
    role: 'guardian',
    plan: 'basic',
    state: 'summary-unavailable',
    largeText: true,
    build: () => _guardianWorkspaceFixture(
      entry: _guardianWorkspaceMainEntry(),
      unavailable: true,
    ),
  ),
  _Fixture(
    id: 'guardian-seeker-workspace-additional',
    role: 'guardian',
    plan: 'basic',
    state: 'role-and-network-only',
    largeText: true,
    build: () =>
        _guardianWorkspaceFixture(entry: _guardianWorkspaceAdditionalEntry()),
  ),
  _Fixture(
    id: 'guardian-dashboard-thinned-main-priority',
    role: 'guardian',
    plan: 'basic',
    state: 'one-priority-mixed-role',
    largeText: true,
    build: () => _guardianTodayFixture(
      people: _guardianTodayPeople,
      journeys: [
        _guardianTodayJourney(_guardianTodayPeople[0], suffix: 'main-priority'),
        _guardianTodayJourney(
          _guardianTodayPeople[1],
          suffix: 'additional-hidden',
        ),
      ],
    ),
  ),
  _Fixture(
    id: 'guardian-dashboard-thinned-additional-neutral',
    role: 'guardian',
    plan: 'basic',
    state: 'additional-journey-hidden',
    largeText: true,
    build: () => _guardianTodayFixture(
      people: _guardianTodayPeople.take(2).toList(),
      journeys: [
        _guardianTodayJourney(
          _guardianTodayPeople[1],
          suffix: 'additional-hidden',
        ),
      ],
    ),
  ),
  _Fixture(
    id: 'guardian-dashboard-thinned-empty',
    role: 'guardian',
    plan: 'basic',
    state: 'honest-empty',
    largeText: true,
    build: () => _guardianTodayFixture(people: const [], journeys: const []),
  ),
  _Fixture(
    id: 'guardian-dashboard-thinned-unavailable',
    role: 'guardian',
    plan: 'basic',
    state: 'journey-source-unavailable',
    largeText: true,
    build: () => _guardianTodayFixture(people: const [], journeys: null),
  ),
  _Fixture(
    id: 'guardian-dashboard-updates-populated',
    role: 'guardian',
    plan: 'basic',
    state: 'updates-populated',
    largeText: true,
    build: () => _guardianUpdatesFixture(
      rows: [
        _visualGuardianUpdate(
          sourceId: 'visual-unread-notification',
          isUnread: true,
          notification: true,
        ),
        _visualGuardianUpdate(),
      ],
    ),
  ),
  _Fixture(
    id: 'guardian-dashboard-updates-empty',
    role: 'guardian',
    plan: 'basic',
    state: 'updates-honest-empty',
    largeText: true,
    build: () => _guardianUpdatesFixture(rows: const []),
  ),
  _Fixture(
    id: 'guardian-dashboard-updates-last-known',
    role: 'guardian',
    plan: 'basic',
    state: 'updates-last-known',
    largeText: true,
    build: () => _guardianUpdatesFixture(
      rows: [_visualGuardianUpdate()],
      failAfterFirstRead: true,
    ),
  ),
  _Fixture(
    id: 'subscription-upgrade',
    role: 'male-seeker',
    plan: 'basic',
    state: 'upgrade',
    largeText: true,
    build: () => const UpgradeScreen(),
  ),
  _Fixture(
    id: 'guardian-network-locked',
    role: 'guardian',
    plan: 'basic',
    state: 'locked',
    largeText: true,
    build: () => _guardianAccess(entitled: false, linked: true),
  ),
  _Fixture(
    id: 'guardian-network-unlinked',
    role: 'guardian',
    plan: 'zyra-one',
    state: 'empty',
    build: () => _guardianAccess(entitled: true, linked: false),
  ),
  _Fixture(
    id: 'guardian-network-unavailable',
    role: 'guardian',
    plan: 'zyra-one',
    state: 'disabled',
    build: () => _guardianAccess(entitled: true, linked: true),
  ),
  _Fixture(
    id: 'shared-loading',
    role: 'female-seeker',
    plan: 'basic',
    state: 'loading',
    build: () => const ZyraLoading.fullScreen(label: 'Preparing your Journey…'),
  ),
  _Fixture(
    id: 'shared-error',
    role: 'female-seeker',
    plan: 'basic',
    state: 'error',
    largeText: true,
    build: () => ZyraFullScreenError(
      kind: ZyraErrorKind.offline,
      onPrimary: () {},
      onSecondary: () {},
      referenceCode: 'ZY-AUDIT',
    ),
  ),
  _Fixture(
    id: 'shared-empty-long-copy',
    role: 'guardian',
    plan: 'basic',
    state: 'empty',
    largeText: true,
    build: () => _gradientBody(
      ZyraEmptyState(
        icon: Icons.people_outline,
        title: 'Nothing is waiting for Muhammad Abdullah Al-Rahman',
        message:
            'Updates for this Seeker in Greater London and the surrounding counties will appear here when there is something useful to review.',
        ctaLabel: 'Return to Dashboard',
        onCta: () {},
      ),
    ),
  ),
  _Fixture(
    id: 'guardian-slider-six-seekers',
    role: 'guardian',
    plan: 'zyra-one',
    state: 'expanded',
    largeText: true,
    build: _guardianSlider,
  ),
  for (final option in const [
    (ZyraNavStyle.floatingGlass, ZyraDevLightAccent.purple),
    (ZyraNavStyle.labelledDock, ZyraDevLightAccent.black),
    (ZyraNavStyle.accentRing, ZyraDevLightAccent.emerald),
    (ZyraNavStyle.softTiles, ZyraDevLightAccent.royalBlue),
    (ZyraNavStyle.goldUnderline, ZyraDevLightAccent.gold),
    (ZyraNavStyle.raisedCapsule, ZyraDevLightAccent.rose),
    (ZyraNavStyle.quietDot, ZyraDevLightAccent.sapphire),
  ])
    _Fixture(
      id: 'style-${option.$1.name}',
      role: 'female-seeker',
      plan: 'basic',
      state: 'selected',
      build: () => _styleShowcase(option.$1, option.$2),
    ),
];

Map<String, Map<String, dynamic>> _approvedBaselines() {
  final decoded = _readManifest('test/visual/approved/manifest.json');
  final rows = (decoded['baselines'] as List<dynamic>? ?? const []);
  return {
    for (final raw in rows)
      if (raw is Map<String, dynamic> && raw['id'] is String)
        raw['id'] as String: raw,
  };
}

Map<String, dynamic> _readManifest(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Map<String, Map<String, dynamic>> _retiredBaselines() {
  final manifest = _readManifest('test/visual/approved/manifest.json');
  return {
    for (final row
        in (manifest['retired_baselines'] as List).cast<Map<String, dynamic>>())
      row['id'] as String: row,
  };
}

// Removed screenshots no longer participate in rendering or portable byte
// audits. Preserve their original metadata against the sealed approval record;
// the task's move audit verifies the bytes at the recorded _to_delete paths.
void _expectTier1Retirement(Map screenshot) {
  final id = screenshot['id'] as String;
  final retired = _retiredBaselines()[id];
  expect(retired, isNotNull, reason: '$id needs an explicit retirement record');
  final sourcePath =
      (screenshot['path'] ?? screenshot['source_path']) as String;
  final approvedPath = screenshot['approved_path'] as String;
  expect(retired?['source_path'], sourcePath);
  expect('test/visual/${retired?['path']}', approvedPath);
  for (final field in ['sha256', 'bytes', 'version']) {
    expect(retired?[field], screenshot[field], reason: '$id $field drift');
  }
  expect(retired?['retirement_reference'], contains('OA-ZYRA-316 Tier 1'));
  expect(retired?['retired_date'], '2026-10-29');
  expect(retired?['retired_by'], 'Founder (Shakeel)');
  expect(retired?['retired_to'], endsWith('/SOURCE/$approvedPath'));
  expect(retired?['retired_source_to'], endsWith('/SOURCE/$sourcePath'));
  expect(File(sourcePath).existsSync(), isFalse);
  expect(File(approvedPath).existsSync(), isFalse);
}

void _applyRoleAndPlan(_Fixture fixture) {
  final state = AppState.instance;
  state.gender = switch (fixture.role) {
    'male-seeker' => 'male',
    'female-seeker' => 'female',
    _ => 'female',
  };
  state.plan = fixture.plan == 'zyra-one' ? ZyraPlan.one : ZyraPlan.basic;
  state.name = fixture.role == 'guardian' ? 'Amina' : 'Maryam';
  state.surnameLine = 'Fatima Abdullah Al-Rahman';
  state.location = 'Greater London and the surrounding counties';
  state.age = 29;
}

Widget _testApp(Widget child, {required double textScale}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    useMaterial3: true,
    brightness: ZyraColors.isLightPalette ? Brightness.light : Brightness.dark,
    textTheme: ZyraText.textTheme(
      ZyraColors.isLightPalette
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: ZyraColors.actionFill,
      brightness: ZyraColors.isLightPalette
          ? Brightness.light
          : Brightness.dark,
    ),
  ),
  builder: (context, appChild) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: true,
    ),
    child: RepaintBoundary(key: _visualRoot, child: appChild!),
  ),
  home: child,
);

void main() {
  final approved = _approvedBaselines();
  final retired = _retiredBaselines();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'visual-test-key',
    );
    final readingFont = FontLoader('PoppinsAudit')
      ..addFont(_fontBytes('assets/fonts/Poppins-ExtraLight.ttf'))
      ..addFont(_fontBytes('assets/fonts/Poppins-Light.ttf'))
      ..addFont(_fontBytes('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(_fontBytes('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(_fontBytes('assets/fonts/Poppins-SemiBold.ttf'))
      ..addFont(_fontBytes('assets/fonts/Poppins-Bold.ttf'));
    final wordmarkFont = FontLoader('SyneAudit')
      ..addFont(_fontBytes('assets/fonts/Syne-SemiBold.ttf'));
    await Future.wait([readingFont.load(), wordmarkFont.load()]);
    if (_captureCandidates) {
      final materialIcons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await materialIcons.load();
    }
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
    ZyraText.testWordmarkFontFamily = 'SyneAudit';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    GNContext.instance.reset();
  });

  test('active approved manifests are identical and fully byte-audited', () {
    final runtime = _readManifest('test/visual/approved/manifest.json');
    final governed = _readManifest(
      '../SYSTEM/tools/ui_gate/BASELINES/manifest.json',
    );
    expect(runtime['automatic_updates_allowed'], isFalse);
    expect(governed['automatic_updates_allowed'], isFalse);
    expect(runtime['active_baseline_count'], 112);
    expect(runtime['archived_baseline_count'], 36);
    expect(runtime['active_version'], 'OA-ZYRA-282-phase1-v2');
    expect(runtime['active_versions'], [
      'OA-ZYRA-281-v1',
      'OA-ZYRA-282-phase2-v1',
      'OA-ZYRA-282-phase3-v1',
      'OA-ZYRA-282-phase1-v2',
    ]);
    expect(jsonEncode(runtime['baselines']), jsonEncode(governed['baselines']));
    expect(
      jsonEncode(runtime['archived_baselines']),
      jsonEncode(governed['archived_baselines']),
    );
    expect(runtime['retired_baseline_count'], 12);
    expect(
      jsonEncode(runtime['retired_baselines']),
      jsonEncode(governed['retired_baselines']),
    );
    expect(
      jsonEncode(runtime['retired_unapproved_captures']),
      jsonEncode(governed['retired_unapproved_captures']),
    );
    expect(approved, hasLength(112));
    expect(
      approved.values.map((entry) => entry['path']).toSet(),
      hasLength(112),
    );
    final versions = <String, int>{};
    for (final entry in approved.values) {
      for (final key in const [
        'id',
        'path',
        'screen',
        'state',
        'role',
        'plan',
        'device',
        'approved_date',
        'approved_by',
        'governing_reference',
        'version',
      ]) {
        expect(entry[key], isNotNull, reason: 'approved baseline missing $key');
      }
      versions.update(
        entry['version'] as String,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final path = entry['path'] as String;
      final file = File('test/visual/$path');
      expect(file.existsSync(), isTrue, reason: 'missing approved file $path');
      final bytes = file.readAsBytesSync();
      expect(bytes.length, entry['bytes'], reason: '$path byte drift');
      expect(
        sha256.convert(bytes).toString(),
        entry['sha256'],
        reason: '$path hash drift',
      );
    }
    expect(versions, {
      'OA-ZYRA-281-v1': 28,
      'OA-ZYRA-282-phase2-v1': 36,
      'OA-ZYRA-282-phase3-v1': 32,
      'OA-ZYRA-282-phase1-v2': 16,
    });
  });

  test('Tier 1 retired screens have no active fixtures or baselines', () {
    final fixtureIds = _fixtures().map((fixture) => fixture.id).toSet();
    expect(fixtureIds.intersection(_tier1RetiredFixtures), isEmpty);
    expect(retired, hasLength(12));
    expect(retired.keys.toSet().intersection(approved.keys.toSet()), isEmpty);
    for (final entry in retired.values) {
      final fixture = (entry['id'] as String).split('__').first;
      expect(_tier1RetiredFixtures, contains(fixture));
      expect(
        entry['retirement_reason'],
        contains('Unused GuardianDetailScreen'),
      );
      expect(entry['retired_to'], contains('/_to_delete/OA-ZYRA-316_TIER1_'));
      expect(File('test/visual/${entry['path']}').existsSync(), isFalse);
      expect(File(entry['source_path'] as String).existsSync(), isFalse);
    }
    final runtime = _readManifest('test/visual/approved/manifest.json');
    final captures = (runtime['retired_unapproved_captures'] as List)
        .cast<Map<String, dynamic>>();
    expect(captures, hasLength(7));
    for (final capture in captures) {
      final path = capture['path'] as String;
      expect(path, startsWith('SOURCE/test/visual/candidates/notifications-'));
      expect(File('../$path').existsSync(), isFalse);
      expect(capture['retirement_reference'], 'OA-ZYRA-316 Tier 1');
      expect(capture['retired_to'], endsWith('/$path'));
      expect(capture['sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(capture['bytes'], greaterThan(0));
    }
  });

  test('superseded pixels are archived without byte deletion', () {
    final runtime = _readManifest('test/visual/approved/manifest.json');
    final archived = (runtime['archived_baselines'] as List)
        .cast<Map<String, dynamic>>();
    expect(archived, hasLength(36));
    expect(
      archived
          .map((entry) => entry['id'])
          .toSet()
          .intersection(approved.keys.toSet()),
      isEmpty,
    );
    final currentFixtureIds = _fixtures().map((fixture) => fixture.id).toSet();
    const variants = ['small', 'standard', 'large', 'standard__text-130'];

    for (final replacement in _presentationSupersededFixtures.entries) {
      expect(
        currentFixtureIds,
        contains(replacement.value),
        reason: '${replacement.key} has no registered Phase 3 replacement',
      );
      expect(
        currentFixtureIds,
        isNot(contains(replacement.key)),
        reason: '${replacement.key} must not compare new UI to old pixels',
      );
      for (final variant in variants) {
        final id = '${replacement.key}__$variant';
        expect(approved[id], isNull, reason: '$id must not remain active');
        final baseline = archived.singleWhere((entry) => entry['id'] == id);
        expect(baseline['archive_status'], 'superseded_byte_preserved');
        expect(baseline['archived_date'], '2026-08-31');
        expect(baseline['archived_by'], 'Founder (Shakeel)');
        expect(
          baseline['archive_reference'],
          contains('066_FABLE-CODEX_2026-08-31'),
        );
        expect(baseline['superseded_by'], '${replacement.value}__$variant');
        expect(approved, contains('${replacement.value}__$variant'));
        final path = baseline['path'] as String;
        expect(baseline['byte_preserved_at'], path);
        final file = File('test/visual/$path');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'missing approved file $path',
        );
        final bytes = file.readAsBytesSync();
        expect(bytes.length, baseline['bytes'], reason: '$id byte drift');
        expect(
          sha256.convert(bytes).toString(),
          baseline['sha256'],
          reason: '$id hash drift',
        );
      }
    }
  });

  test('all OA-ZYRA-282 candidate manifests record governed promotion', () {
    final registeredFixtures = _fixtures().map((fixture) => fixture.id).toSet();
    final runtime = _readManifest('test/visual/approved/manifest.json');
    final archived = (runtime['archived_baselines'] as List)
        .cast<Map<String, dynamic>>();
    const phases = <({String file, int count, int fixtures, String version})>[
      (
        file: 'OA-ZYRA-282_PHASE_1_manifest.json',
        count: 28,
        fixtures: 7,
        version: 'OA-ZYRA-282-phase1-v1',
      ),
      (
        file: 'OA-ZYRA-282_PHASE_2_manifest.json',
        count: 36,
        fixtures: 9,
        version: 'OA-ZYRA-282-phase2-v1',
      ),
      (
        file: 'OA-ZYRA-282_PHASE_3_manifest.json',
        count: 32,
        fixtures: 8,
        version: 'OA-ZYRA-282-phase3-v1',
      ),
    ];
    for (final phase in phases) {
      final manifest = _readManifest(
        '../SYSTEM/tools/ui_gate/CANDIDATES/${phase.file}',
      );
      expect(manifest['comparison_clock'], '2026-08-30T18:00:00Z');
      expect(manifest['automatic_promotion_allowed'], isFalse);
      expect(manifest['approved_baselines_modified'], isFalse);
      expect(manifest['device_acceptance_pending'], isFalse);
      expect(manifest['fixture_count'], phase.fixtures);
      expect(manifest['variant_count'], phase.count);
      expect(manifest['promoted_variant_count'], phase.count);
      expect(manifest['promoted_baseline_version'], phase.version);
      expect(manifest['founder_approved_date'], '2026-08-31');
      expect(manifest['approved_by'], 'Founder (Shakeel)');
      expect(manifest['approval_reference'], contains('066_FABLE-CODEX'));

      final declaredFixtures = (manifest['fixtures'] as List)
          .map((raw) => (raw as Map)['id'] as String)
          .toSet();
      expect(declaredFixtures, hasLength(phase.fixtures));
      if (phase.version == 'OA-ZYRA-282-phase1-v1') {
        expect(
          declaredFixtures.intersection(_phase1SupersededFixtures.keys.toSet()),
          _phase1SupersededFixtures.keys.toSet(),
        );
        expect(
          registeredFixtures,
          containsAll(
            declaredFixtures
                .difference(_phase1SupersededFixtures.keys.toSet())
                .difference(_tier1RetiredFixtures),
          ),
        );
        for (final replacement in _phase1SupersededFixtures.entries) {
          expect(registeredFixtures, isNot(contains(replacement.key)));
          expect(
            registeredFixtures.contains(replacement.value),
            !_tier1RetiredFixtures.contains(replacement.value),
          );
        }
      } else {
        expect(registeredFixtures, containsAll(declaredFixtures));
      }

      final screenshots = manifest['screenshots'] as List;
      expect(screenshots, hasLength(phase.count));
      for (final raw in screenshots) {
        final screenshot = raw as Map;
        final id = screenshot['id'] as String;
        expect(screenshot['approved'], isTrue);
        expect(screenshot['approved_date'], '2026-08-31');
        expect(screenshot['approved_by'], 'Founder (Shakeel)');
        expect(screenshot['version'], phase.version);
        if (retired.containsKey(id)) {
          _expectTier1Retirement(screenshot);
          expect(approved[id], isNull);
          continue;
        }
        final sourcePath =
            (screenshot['path'] ?? screenshot['source_path']) as String;
        final approvedPath = screenshot['approved_path'] as String;
        final sourceFile = File(sourcePath);
        final approvedFile = File(approvedPath);
        expect(sourceFile.existsSync(), isTrue, reason: 'missing $sourcePath');
        expect(
          approvedFile.existsSync(),
          isTrue,
          reason: 'missing $approvedPath',
        );
        final sourceBytes = sourceFile.readAsBytesSync();
        final approvedBytes = approvedFile.readAsBytesSync();
        expect(sourceBytes, approvedBytes, reason: '$id copy drift');
        expect(
          sourceBytes.length,
          screenshot['bytes'],
          reason: '$id byte drift',
        );
        expect(
          sha256.convert(sourceBytes).toString(),
          screenshot['sha256'],
          reason: '$id hash drift',
        );
        final wasPhase1Superseded =
            phase.version == 'OA-ZYRA-282-phase1-v1' &&
            _phase1SupersededFixtures.keys.any(
              (fixture) => id.startsWith('${fixture}__'),
            );
        if (wasPhase1Superseded) {
          final archivedRow = archived.singleWhere(
            (entry) => entry['id'] == id,
          );
          expect(archivedRow['version'], phase.version);
          expect(archivedRow['sha256'], screenshot['sha256']);
          expect(approved[id], isNull);
        } else {
          expect(approved[id]?['version'], phase.version);
          expect(approved[id]?['sha256'], screenshot['sha256']);
        }
      }
    }
  });

  test('Phase 1 v2 successors are promoted and supersessions finalized', () {
    final manifest = _readManifest(
      '../SYSTEM/tools/ui_gate/CANDIDATES/'
      'OA-ZYRA-282_PHASE_1_V2_manifest.json',
    );
    expect(manifest['programme'], 'OA-ZYRA-282');
    expect(manifest['comparison_clock'], '2026-08-30T18:00:00Z');
    expect(manifest['automatic_promotion_allowed'], isFalse);
    expect(manifest['approved_baselines_modified'], isFalse);
    expect(manifest['device_acceptance_pending'], isFalse);
    expect(manifest['fixture_count'], 6);
    expect(manifest['variant_count'], 24);
    expect(manifest['variants_per_fixture'], 4);
    expect(manifest['proposed_baseline_version'], isNull);
    expect(manifest['promoted_baseline_version'], 'OA-ZYRA-282-phase1-v2');
    expect(manifest['promoted_variant_count'], 24);
    expect(manifest['supersession_status'], 'finalized_founder_accepted');
    expect(manifest['staged_date'], '2026-08-31');
    expect(manifest['staged_by'], 'Codex / Lead Architect');
    expect(manifest['staging_reference'], contains('068_FABLE-CODEX'));
    expect(manifest['founder_approved_date'], '2026-09-01');
    expect(manifest['approved_by'], 'Founder (Shakeel)');
    expect(manifest['approval_reference'], contains('072_FABLE-CODEX'));

    final registeredFixtures = _fixtures().map((fixture) => fixture.id).toSet();
    final replacementRows = (manifest['superseded_approved_fixtures'] as List)
        .cast<Map<String, dynamic>>();
    expect(replacementRows, hasLength(6));
    for (final replacement in _phase1SupersededFixtures.entries) {
      final row = replacementRows.singleWhere(
        (candidate) => candidate['approved_fixture'] == replacement.key,
      );
      expect(row['candidate_fixture'], replacement.value);
      expect(row['variant_count'], 4);
      expect(registeredFixtures, isNot(contains(replacement.key)));
      expect(
        registeredFixtures.contains(replacement.value),
        !_tier1RetiredFixtures.contains(replacement.value),
      );
    }

    final screenshots = (manifest['screenshots'] as List)
        .cast<Map<String, dynamic>>();
    expect(screenshots, hasLength(24));
    for (final screenshot in screenshots) {
      expect(screenshot['approved'], isTrue);
      expect(screenshot['proposed_version'], isNull);
      expect(screenshot['approved_date'], '2026-09-01');
      expect(screenshot['approved_by'], 'Founder (Shakeel)');
      expect(screenshot['version'], 'OA-ZYRA-282-phase1-v2');
      expect(screenshot['governing_reference'], contains('072_FABLE-CODEX'));
      if (retired.containsKey(screenshot['id'])) {
        _expectTier1Retirement(screenshot);
        expect(approved[screenshot['id']], isNull);
        continue;
      }
      final path = screenshot['path'] as String;
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'missing candidate $path');
      final bytes = file.readAsBytesSync();
      expect(bytes.length, screenshot['bytes'], reason: '$path byte drift');
      expect(
        sha256.convert(bytes).toString(),
        screenshot['sha256'],
        reason: '$path hash drift',
      );
      final approvedPath = screenshot['approved_path'] as String;
      final approvedFile = File(approvedPath);
      expect(
        approvedFile.existsSync(),
        isTrue,
        reason: 'missing promoted copy $approvedPath',
      );
      expect(approvedFile.readAsBytesSync(), bytes);
      final active = approved[screenshot['id']];
      expect(active, isNotNull);
      expect(active?['path'], approvedPath.replaceFirst('test/visual/', ''));
      expect(active?['version'], 'OA-ZYRA-282-phase1-v2');
      expect(active?['sha256'], screenshot['sha256']);
    }

    final runtime = _readManifest('test/visual/approved/manifest.json');
    final archived = (runtime['archived_baselines'] as List)
        .cast<Map<String, dynamic>>();
    expect(runtime['active_baseline_count'], 112);
    expect(runtime['archived_baseline_count'], 36);
    final staged = (manifest['staged_supersession_rows'] as List)
        .cast<Map<String, dynamic>>();
    expect(staged, hasLength(24));
    for (final row in staged) {
      final id = row['id'] as String;
      expect(approved[id], isNull, reason: '$id must not remain active');
      expect(row['archive_status'], 'superseded_byte_preserved');
      expect(row['archived_date'], '2026-09-01');
      expect(row['archived_by'], 'Founder (Shakeel)');
      expect(row['archive_reference'], contains('072_FABLE-CODEX'));
      expect(row['archive_reason'], contains('Founder-accepted'));
      expect(row['byte_preserved_at'], row['path']);
      expect(
        approved[row['superseded_by']] ?? retired[row['superseded_by']],
        isNotNull,
      );
      final ledgerRow = archived.singleWhere((entry) => entry['id'] == id);
      expect(jsonEncode(ledgerRow), jsonEncode(row));
      final oldFile = File('test/visual/${row['path']}');
      expect(oldFile.existsSync(), isTrue, reason: 'missing archive $id');
      final oldBytes = oldFile.readAsBytesSync();
      expect(oldBytes.length, row['bytes'], reason: '$id archive byte drift');
      expect(
        sha256.convert(oldBytes).toString(),
        row['sha256'],
        reason: '$id archive hash drift',
      );
    }

    final continuing = approved.values
        .where((row) => row['version'] == 'OA-ZYRA-282-phase1-v1')
        .map((row) => row['id'] as String)
        .toList();
    expect(continuing, isEmpty);
    expect(
      retired.values.where((row) => row['version'] == 'OA-ZYRA-282-phase1-v1'),
      hasLength(4),
    );
  });

  for (final fixture in _fixtures()) {
    final variants = <({String id, _Device device, double scale})>[
      for (final device in _devices)
        (id: '${fixture.id}__${device.id}', device: device, scale: 1.0),
      if (fixture.largeText)
        (
          id: '${fixture.id}__standard__text-130',
          device: _devices[1],
          scale: 1.3,
        ),
    ];

    for (final variant in variants) {
      testWidgets('${variant.id} renders without overflow or exceptions', (
        tester,
      ) async {
        tester.view.physicalSize = variant.device.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
        ZyraColors.selectDevLightAccent(ZyraDevLightAccent.purple);
        ZyraInteractionStyle.restoreDefaults();
        _applyRoleAndPlan(fixture);

        await tester.pumpWidget(
          _testApp(fixture.build(), textScale: variant.scale),
        );
        await tester.pump(const Duration(milliseconds: 80));
        if (fixture.id.startsWith('guardian-dashboard-updates-')) {
          await tester.pumpAndSettle();
          await tester.drag(
            find.byKey(
              const PageStorageKey('guardian-dashboard-visual-seeker'),
            ),
            const Offset(0, -700),
          );
          await tester.pumpAndSettle();
          if (fixture.id == 'guardian-dashboard-updates-last-known') {
            final refresh = tester
                .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
                .show();
            await tester.pumpAndSettle();
            await refresh;
          }
        }
        if (fixture.id == 'seeker-dashboard-thinned-connected' ||
            fixture.id == 'seeker-dashboard-thinned-pending-invitation') {
          // Quiet Index replaced permanent Family summary sections. Keep
          // exercising the real page rather than seeking a retired widget.
          expect(
            find.byKey(const ValueKey('my-zyra-quiet-dashboard')),
            findsOneWidget,
          );
          await tester.drag(
            find.byKey(const ValueKey('my-zyra-quiet-scroll-0')),
            const Offset(0, -220),
          );
          await tester.pump(const Duration(milliseconds: 80));
        }
        if (fixture.id == 'guardian-manager-loaded-pending') {
          await tester.drag(
            find.byKey(const PageStorageKey('guardianship-manager')),
            const Offset(0, -520),
          );
          await tester.pumpAndSettle();
        }
        if (fixture.id == 'guardian-seeker-roster-main-lower-groups') {
          // Seekers now uses one horizontal page per person, rather than
          // the superseded vertically grouped roster. Exercise that actual
          // surface without replacing any approved historical pixels.
          await tester.drag(
            find.byKey(const ValueKey('guardian-seeker-page-view')),
            const Offset(-300, 0),
          );
          await tester.pumpAndSettle();
        }
        if (fixture.id == 'guardian-seeker-workspace-main-loaded') {
          await tester.drag(
            find.byKey(const PageStorageKey('guardian-seeker-workspace')),
            const Offset(0, -320),
          );
          await tester.pumpAndSettle();
        }
        expect(find.byKey(_visualRoot), findsOneWidget);

        if (_captureCandidates) {
          await expectLater(
            find.byKey(_visualRoot),
            matchesGoldenFile(
              '${_healthCapture ? 'health_candidates' : _candidateDirectory}/${variant.id}.png',
            ),
          );
        } else {
          final baseline = approved[variant.id];
          if (baseline != null) {
            await expectLater(
              find.byKey(_visualRoot),
              matchesGoldenFile(baseline['path'] as String),
            );
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
