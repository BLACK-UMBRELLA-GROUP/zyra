// Historical local sample catalog retained for tests through code only.
// No panel, route, selector, service request or rendered tool is provided.
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:zyra/data/zyra_entitlements.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_dev_personal_code_fixtures.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/models/zyra_dashboard_lab.dart';
import 'package:zyra/screens/wali/wali_gn_shared.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_promotion_engine.dart';
import 'package:zyra/state/app_state.dart';
import 'queue44_dashboard_fixture_catalog.dart';

class Queue44SeekerCatalog {
  Queue44SeekerCatalog({
    required this.current,
    this.onIntroductions,
    this.onSection,
  });
  final bool Function() current;
  final VoidCallback? onIntroductions;
  final ValueChanged<int>? onSection;
  final _scenario = ZyraDevScenario.instance;
  final _promotion = ZyraPromotionEngine.instance;
  final bool _localOnly = ZyraDeveloperAccess.isMainAppFounderPreview;
  String? notice, failure;
  final int _guardiansOnDecided = 0;
  ZyraJourneyLimits get _limits => ZyraEntitlements.of(AppState.instance.plan);
  bool get _isOne => AppState.instance.plan == ZyraPlan.one;
  String get context => _scenario.currentPage == DevPage.connections
      ? 'connections-${_scenario.connectionsSection}'
      : _scenario.currentPage.name;
  String get title => switch (_scenario.currentPage) {
    DevPage.connections =>
      'Connections · ${switch (_scenario.connectionsSection) {
        1 => 'Activity',
        2 => 'Introductions',
        _ => 'Journeys',
      }}',
    DevPage.dashboard =>
      'My ZYRA · ${zyraDashboardOptionsTitle(_scenario, ZyraDashboardRole.seeker)}',
    _ => _scenario.currentPage.label,
  };
  ZyraFixtureChoice _option({
    required String id,
    required String label,
    required String group,
    required FutureOr<void> Function() onSelected,
    bool selected = false,
  }) {
    final captured = context;
    return ZyraFixtureChoice(
      id: id,
      label: label,
      group: group,
      selected: selected,
      onSelected: () async {
        if (!current() ||
            !ZyraDeveloperAccess.canUseDeveloperTools ||
            context != captured) {
          return;
        }
        notice = failure = null;
        try {
          await onSelected();
        } catch (error) {
          failure = error.toString();
        }
      },
    );
  }

  void _showBrowsePopup(DevPopup popup) => _scenario.requestPopup(popup);
  void _setIntroductionPreviews(int count) {
    _scenario.setIntroductionPreviewCount(count);
    onIntroductions?.call();
  }

  Future<void> _copyGuardianTestCode(String code, {required bool valid}) =>
      Clipboard.setData(ClipboardData(text: code));
  Future<void> _setMembership(bool one) async {
    if (!_localOnly) {
      failure =
          'Membership did not change. Server actions are unavailable in a code fixture.';
      return;
    }
    AppState.instance.setPlan(one ? ZyraPlan.one : ZyraPlan.basic);
    notice = 'Account membership was unchanged';
  }

  void _openLiveJourney() =>
      throw UnsupportedError('No live Journey service in a code fixture');
  void _grantCredits(Object tier, int count) =>
      throw UnsupportedError('No credit service in a code fixture');
  void _setGuardiansOnDecided(int count) =>
      throw UnsupportedError('No Guardian service in a code fixture');
  List<ZyraFixtureChoice> _counts({
    required String id,
    required String group,
    required int value,
    required int max,
    required FutureOr<void> Function(int) onSelected,
  }) => [
    for (var count = 0; count <= max; count++)
      _option(
        id: '$id-$count',
        label: '$group · $count',
        group: group,
        selected: value == count,
        onSelected: () => onSelected(count),
      ),
  ];

  List<ZyraFixtureChoice> _browseOptions() => [
    for (final style in ZyraBrowseSwipeFeedbackStyle.values)
      _option(
        id: 'browse-motion-${style.name}',
        label: style.label,
        group: 'Swipe feedback',
        selected: _scenario.browseSwipeFeedbackStyle == style,
        onSelected: () => _scenario.setBrowseSwipeFeedbackStyle(style),
      ),
    _option(
      id: 'browse-save-limit',
      label: 'Save limit',
      group: 'Limit previews',
      onSelected: () => _showBrowsePopup(DevPopup.saveLimit),
    ),
    if (!_isOne) ...[
      _option(
        id: 'browse-consider-limit',
        label: 'Consider limit',
        group: 'Limit previews',
        onSelected: () => _showBrowsePopup(DevPopup.considerLimit),
      ),
      _option(
        id: 'browse-daily-limit',
        label: 'Browsing limit',
        group: 'Limit previews',
        onSelected: () => _showBrowsePopup(DevPopup.dailyLimit),
      ),
    ],
  ];

  List<ZyraFixtureChoice> _connectionsJourneyOptions() => [
    if (!_localOnly)
      _option(
        id: 'connections-live-journey',
        label: 'Open live Journey',
        group: 'Journey lab',
        onSelected: _openLiveJourney,
      ),
    ..._counts(
      id: 'active-journeys',
      group: 'Active Journeys',
      value: ZyraEntitlements.devClamp(
        _scenario.activeJourneys,
        _limits.active,
      ),
      max: ZyraEntitlements.devMaxFor(_limits.active),
      onSelected: _scenario.setActiveJourneys,
    ),
    ..._counts(
      id: 'potential-journeys',
      group: 'Potential',
      value: _scenario.queuedJourneys,
      max: ZyraEntitlements.devMaxFor(_limits.potential),
      onSelected: _scenario.setQueuedJourneys,
    ),
    ..._counts(
      id: 'paused-journeys',
      group: 'Paused',
      value: _scenario.pausedJourneys.clamp(0, _limits.paused),
      max: ZyraEntitlements.devMaxFor(_limits.paused),
      onSelected: _scenario.setPausedJourneys,
    ),
    ..._counts(
      id: 'ended-journeys',
      group: 'Ended',
      value: _scenario.endedJourneys.clamp(0, _limits.ended),
      max: ZyraEntitlements.devMaxFor(_limits.ended),
      onSelected: _scenario.setEndedJourneys,
    ),
  ];

  List<ZyraFixtureChoice> _connectionsActivityOptions() => [
    ..._counts(
      id: 'considered-profiles',
      group: 'Considered',
      value: _scenario.consideredPreviewCount,
      max: 5,
      onSelected: _scenario.setConsideredPreviewCount,
    ),
    ..._counts(
      id: 'saved-profiles',
      group: 'Saved',
      value: _scenario.savedPreviewCount,
      max: 5,
      onSelected: _scenario.setSavedPreviewCount,
    ),
    ..._counts(
      id: 'passed-profiles',
      group: 'Passed',
      value: _scenario.passedPreviewCount,
      max: 5,
      onSelected: _scenario.setPassedPreviewCount,
    ),
    if (!_localOnly) ...[
      for (final count in const [1, 5])
        _option(
          id: 'credits-plus-$count',
          label: 'Compatibility Unlock credits · +$count',
          group: 'Compatibility data',
          onSelected: () => _grantCredits('current', count),
        ),
      ..._counts(
        id: 'guardians-on-decided',
        group: 'Guardians on decided profiles',
        value: _guardiansOnDecided,
        max: 3,
        onSelected: _setGuardiansOnDecided,
      ),
    ],
  ];

  List<ZyraFixtureChoice> _guardianOptions() => [
    if (_localOnly) ...[
      _option(
        id: 'guardian-code-valid',
        label:
            'Valid Guardian · '
            '${ZyraDevPersonalCodeFixtures.validGuardianEntryCode}',
        group: 'ZYRA Code test',
        onSelected: () => _copyGuardianTestCode(
          ZyraDevPersonalCodeFixtures.validGuardianEntryCode,
          valid: true,
        ),
      ),
      _option(
        id: 'guardian-code-invalid',
        label: 'Wrong code · ${ZyraDevPersonalCodeFixtures.invalidEntryCode}',
        group: 'ZYRA Code test',
        onSelected: () => _copyGuardianTestCode(
          ZyraDevPersonalCodeFixtures.invalidEntryCode,
          valid: false,
        ),
      ),
    ],
    if (!_localOnly)
      for (final live in const [false, true])
        _option(
          id: 'guardian-source-${live ? 'live' : 'preview'}',
          label: live ? 'Live' : 'Preview',
          group: 'Data source',
          selected: _scenario.useLiveGuardianData == live,
          onSelected: () => _scenario.setUseLiveGuardianData(live),
        ),
    if (!_scenario.useLiveGuardianData) ...[
      for (final count in const [0, 1, 2, 3])
        _option(
          id: 'guardian-active-journeys-$count',
          label: 'Active Journeys · $count',
          group: 'Active Journeys',
          selected: _scenario.guardianPreviewActiveJourneyCount == count,
          onSelected: () =>
              _scenario.setGuardianPreviewActiveJourneyCount(count),
        ),
      for (final linked in const [false, true])
        _option(
          id: 'main-guardian-${linked ? 'linked' : 'none'}',
          label: linked ? 'Main Guardian · Linked' : 'Main Guardian · None',
          group: 'Main Guardian',
          selected: _scenario.mainGuardian == linked,
          onSelected: () => _scenario.setMainGuardian(linked),
        ),
      ..._counts(
        id: 'additional-guardians',
        group: 'Additional Guardians',
        value: _scenario.additionalGuardianCount,
        max: 5,
        onSelected: _scenario.setAdditionalGuardians,
      ),
    ],
  ];

  List<ZyraFixtureChoice> _profileOptions() => [
    for (final one in const [false, true])
      _option(
        id: 'profile-membership-${one ? 'one' : 'inactive'}',
        label: one ? ZyraMembershipCatalog.seekerOneTitle : 'No access',
        group: 'Membership',
        selected: _isOne == one,
        onSelected: () => _setMembership(one),
      ),
    _option(
      id: 'profile-notification-banner',
      label: 'Notification permission banner',
      group: 'Notifications',
      onSelected: () {
        _promotion.showDeveloperPreview(
          product: ZyraPromotionProduct.notifications,
          role: ZyraPromotionRole.seeker,
        );
      },
    ),
    _option(
      id: 'profile-notification-reset',
      label: 'Reset notification prompt policy',
      group: 'Notifications',
      onSelected: _promotion.resetDeveloperPolicy,
    ),
  ];

  List<ZyraFixtureChoice> get options => switch (_scenario.currentPage) {
    DevPage.browse => _browseOptions(),
    DevPage.connections => switch (_scenario.connectionsSection) {
      1 => _connectionsActivityOptions(),
      2 => _counts(
        id: 'test-introductions',
        group: 'Test Introductions',
        value: _scenario.introductionPreviewCount,
        max: 5,
        onSelected: _setIntroductionPreviews,
      ),
      _ => _connectionsJourneyOptions(),
    },
    DevPage.guardian => _guardianOptions(),
    DevPage.activeJourney => [
      for (final scenario in ZyraPauseDevScenario.values)
        _option(
          id: 'pause-${scenario.name}',
          label: scenario.label,
          group: 'Pause decision state',
          selected: _scenario.pauseScenario == scenario,
          onSelected: () => _scenario.setPauseScenario(scenario),
        ),
    ],
    DevPage.profile => _profileOptions(),
    DevPage.dashboard => zyraDashboardPageOptions(
      _scenario,
      ZyraDashboardRole.seeker,
    ),
  };
}

class Queue44GuardianCatalog {
  Queue44GuardianCatalog({required this.current});
  final bool Function() current;
  final _s = ZyraDevScenario.instance;
  final _promotion = ZyraPromotionEngine.instance;
  String? notice, failure;
  String get context =>
      '${_s.currentWaliPage.name}:${_s.waliRole.name}:${GNContext.instance.isMainWali}:${_promotion.developerGuardianNetworkState.name}';
  List<ZyraFixtureChoice> get options {
    final captured = context;
    return _pageOptions(_s.currentWaliPage)
        .map(
          (choice) => ZyraFixtureChoice(
            id: choice.id,
            label: choice.label,
            group: choice.group,
            selected: choice.selected,
            unavailableReason: choice.unavailableReason,
            onSelected: choice.onSelected == null
                ? null
                : () async {
                    if (!current() ||
                        !ZyraDeveloperAccess.canUseDeveloperTools ||
                        context != captured) {
                      return;
                    }
                    await choice.onSelected!();
                  },
          ),
        )
        .toList(growable: false);
  }

  Future<void> _copySeekerTestCode(String code, {required bool valid}) =>
      Clipboard.setData(ClipboardData(text: code));
  String? get _roleDenial => _s.waliIsMain
      ? null
      : 'Additional Guardians can open Journey context when the Seeker '
            'includes them, but Family Review, Guardian Gate and protected '
            'decisions remain Main-led. Choose Main Guardian to inspect '
            'those decision previews.';

  static const _countNames = [
    'No',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
  ];

  List<ZyraFixtureChoice> _counts({
    required String id,
    required String group,
    required String singular,
    required String plural,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
    String? denied,
    String? zeroLabel,
  }) => [
    for (var count = 0; count <= max; count++)
      ZyraFixtureChoice(
        id: '$id-$count',
        group: group,
        label: count == 0 && zeroLabel != null
            ? zeroLabel
            : '${_countNames[count]} ${count == 1 ? singular : plural}',
        selected: value == count,
        onSelected: denied == null ? () => onChanged(count) : null,
        unavailableReason: denied,
      ),
  ];

  List<ZyraFixtureChoice> _roles({bool network = false}) => [
    for (final role in WaliRole.values)
      ZyraFixtureChoice(
        id: 'guardian-role-${role.name}',
        group: 'Guardian role',
        label: role.label,
        selected: network
            ? GNContext.instance.isMainWali == (role == WaliRole.main)
            : _s.waliRole == role,
        onSelected: () {
          _s.setWaliRole(role);
          if (network) {
            GNContext.instance.setMainWali(role == WaliRole.main);
          }
        },
      ),
  ];

  List<ZyraFixtureChoice> _linkedSeekers() => _counts(
    id: 'guardian-linked-seekers',
    group: 'Linked Seekers',
    singular: 'linked Seeker',
    plural: 'linked Seekers',
    value: _s.waliLinkedSeekers,
    max: ZyraDevScenario.fakeWards.length,
    onChanged: _s.setWaliLinkedSeekers,
  );

  List<ZyraFixtureChoice> _unreadBadge() => _counts(
    id: 'guardian-unread',
    group: 'Notification badge only',
    singular: 'unread badge item',
    plural: 'unread badge items',
    zeroLabel: 'Use current unread badge',
    value: _s.waliUnread,
    max: 12,
    onChanged: _s.setWaliUnread,
  );

  List<ZyraFixtureChoice> _journeys() => [
    ..._counts(
      id: 'guardian-active',
      group: 'Active Journeys',
      singular: 'active Journey',
      plural: 'active Journeys',
      value: _s.waliActiveJourneys,
      max: _s.waliLinkedSeekers,
      onChanged: _s.setWaliActiveJourneys,
      denied: _roleDenial,
    ),
    for (var i = 0; i < ZyraJourneyStages.all.length; i++)
      ZyraFixtureChoice(
        id: 'guardian-stage-$i',
        label: ZyraJourneyStages.all[i].label,
        group: 'Journey stage',
        selected: _s.waliStageIndex == i,
        onSelected: _roleDenial == null ? () => _s.setWaliStageIndex(i) : null,
        unavailableReason: _roleDenial,
      ),
    ..._counts(
      id: 'guardian-paused',
      group: 'Paused Journeys',
      singular: 'paused Journey',
      plural: 'paused Journeys',
      value: _s.waliPausedJourneys,
      max: (_s.waliLinkedSeekers - _s.waliActiveJourneys).clamp(
        0,
        _s.waliLinkedSeekers,
      ),
      onChanged: _s.setWaliPausedJourneys,
      denied: _roleDenial,
    ),
    ..._counts(
      id: 'guardian-ended',
      group: 'Ended Journeys',
      singular: 'ended Journey',
      plural: 'ended Journeys',
      value: _s.waliEndedJourneys,
      max: 5,
      onChanged: _s.setWaliEndedJourneys,
      denied: _roleDenial,
    ),
    for (final waiting in [false, true])
      ZyraFixtureChoice(
        id: 'guardian-review-${waiting ? 'waiting' : 'none'}',
        label: waiting ? 'Review awaiting you' : 'No review awaiting you',
        group: 'Family Review',
        selected: _s.waliReviewWaiting == waiting,
        onSelected: _roleDenial == null && _s.waliActiveJourneys > 0
            ? () => _s.setWaliReviewWaiting(waiting)
            : null,
        unavailableReason:
            _roleDenial ??
            (_s.waliActiveJourneys == 0
                ? 'Choose a linked Seeker and an active Journey first.'
                : null),
      ),
  ];

  List<ZyraFixtureChoice> _dashboardOptions() => [
    if (!_s.dashboardLabEnabled && _s.dashboardTab == ZyraDashboardTab.now) ...[
      ..._roles(),
      ..._linkedSeekers(),
      ..._journeys(),
    ],
    ..._unreadBadge(),
  ];

  List<ZyraFixtureChoice> _networkOptions() {
    final context = GNContext.instance;
    final preview =
        _promotion.developerGuardianNetworkState ==
        ZyraDeveloperGuardianNetworkState.d14Preview;
    const previewRequired =
        'Choose D14 full preview to inspect the local Network scene.';
    return [
      ..._roles(network: true),
      ..._linkedSeekers(),
      for (final item in <(ZyraDeveloperGuardianNetworkState, String)>[
        (ZyraDeveloperGuardianNetworkState.d14Preview, 'D14 full preview'),
        (
          ZyraDeveloperGuardianNetworkState.unlinkedBasic,
          'No access · no Seeker',
        ),
        (
          ZyraDeveloperGuardianNetworkState.linkedBasic,
          'No access · linked Seeker',
        ),
        (
          ZyraDeveloperGuardianNetworkState.unlinkedEntitled,
          'Guardian access · no Seeker',
        ),
        (
          ZyraDeveloperGuardianNetworkState.linkedEntitledUnavailable,
          'Guardian access · unavailable',
        ),
      ])
        ZyraFixtureChoice(
          id: 'guardian-network-access-${item.$1.name}',
          group: 'Network access',
          label: item.$2,
          selected: _promotion.developerGuardianNetworkState == item.$1,
          onSelected: () =>
              _promotion.setDeveloperGuardianNetworkState(item.$1),
        ),
      for (final scene in GNScene.values)
        ZyraFixtureChoice(
          id: 'guardian-network-scene-${scene.name}',
          group: 'Network scene',
          label: switch (scene) {
            GNScene.standard => 'Standard recommendations',
            GNScene.merge => 'Incoming request and recommendation',
            GNScene.capReached => 'Request limit reached',
            GNScene.empty => 'No recommendations',
            GNScene.loading => 'Recommendations loading',
            GNScene.error => 'Recommendations unavailable',
          },
          selected: context.scene == scene,
          onSelected: preview ? () => context.setScene(scene) : null,
          unavailableReason: preview ? null : previewRequired,
        ),
      for (final design in GNNetworkCardDesign.values)
        ZyraFixtureChoice(
          id: 'guardian-network-card-${design.name}',
          group: 'Network card design',
          label: design.label,
          selected: context.networkCardDesign == design,
          onSelected: preview
              ? () => context.setNetworkCardDesign(design)
              : null,
          unavailableReason: preview ? null : previewRequired,
        ),
      for (final layout in GNNetworkActionLayout.values)
        ZyraFixtureChoice(
          id: 'guardian-network-actions-${layout.name}',
          group: 'Network Profiles actions',
          label: layout.label,
          selected: context.networkActionLayout == layout,
          onSelected: preview
              ? () => context.setNetworkActionLayout(layout)
              : null,
          unavailableReason: preview ? null : previewRequired,
        ),
      for (final area in GNNetworkPreviewArea.values)
        for (var count = 1; count <= 3; count++)
          ZyraFixtureChoice(
            id: 'guardian-network-${area.name}-$count',
            group: switch (area) {
              GNNetworkPreviewArea.browser => 'Profiles',
              GNNetworkPreviewArea.sent => 'Sent requests',
              GNNetworkPreviewArea.received => 'Received requests',
            },
            label: '$count ${count == 1 ? 'profile' : 'profiles'}',
            selected: context.previewCountFor(area) == count,
            onSelected: preview
                ? () => context.setPreviewCount(area, count)
                : null,
            unavailableReason: preview ? null : previewRequired,
          ),
      ZyraFixtureChoice(
        id: 'guardian-network-reset',
        group: 'Network scene',
        label: 'Reset Network preview',
        onSelected: preview
            ? () {
                context.reset();
                _s.setWaliRole(WaliRole.main);
              }
            : null,
        unavailableReason: preview ? null : previewRequired,
      ),
      ZyraFixtureChoice(
        id: 'guardian-notification-permission',
        group: 'Notification permission',
        label: 'Notification permission banner',
        onSelected: () {
          _promotion.showDeveloperPreview(
            product: ZyraPromotionProduct.notifications,
            role: ZyraPromotionRole.guardian,
          );
        },
      ),
      const ZyraFixtureChoice(
        id: 'guardian-introductions-sent-unavailable',
        group: 'Unavailable previews',
        label: 'Introductions sent',
        unavailableReason:
            'No live Guardian list shows sent introductions. '
            'The Network preview has its own existing local request states.',
      ),
    ];
  }

  List<ZyraFixtureChoice> _pageOptions(WaliPage page) => switch (page) {
    WaliPage.dashboard => [
      ...zyraDashboardPageOptions(_s, ZyraDashboardRole.guardian),
      ..._dashboardOptions(),
    ],
    WaliPage.network => _networkOptions(),
    WaliPage.seekers => [
      if (ZyraDeveloperAccess.isMainAppFounderPreview) ...[
        ZyraFixtureChoice(
          id: 'seeker-code-valid',
          label:
              'Valid Seeker · '
              '${ZyraDevPersonalCodeFixtures.validSeekerEntryCode}',
          group: 'ZYRA Code test',
          onSelected: () => _copySeekerTestCode(
            ZyraDevPersonalCodeFixtures.validSeekerEntryCode,
            valid: true,
          ),
        ),
        ZyraFixtureChoice(
          id: 'seeker-code-invalid',
          label:
              'Wrong code · '
              '${ZyraDevPersonalCodeFixtures.invalidEntryCode}',
          group: 'ZYRA Code test',
          onSelected: () => _copySeekerTestCode(
            ZyraDevPersonalCodeFixtures.invalidEntryCode,
            valid: false,
          ),
        ),
      ],
      ..._roles(),
      ..._linkedSeekers(),
      ..._counts(
        id: 'guardian-sent-invites',
        group: 'Invitations',
        singular: 'pending invitation',
        plural: 'pending invitations',
        value: _s.waliSentInvites,
        max: ZyraDevScenario.fakeWaliInvites.length,
        onChanged: _s.setWaliSentInvites,
      ),
      const ZyraFixtureChoice(
        id: 'guardian-invitations-received-unavailable',
        group: 'Unavailable previews',
        label: 'Invitations received',
        unavailableReason:
            'Invitations are bearer codes until redeemed. '
            'There is no addressed received-invitation list to preview.',
      ),
    ],
    // Retained for legacy preview callers; the shell routes Notifications
    // to My ZYRA, where the same badge controls now live.
    WaliPage.notifications => _unreadBadge(),
    WaliPage.profile => const [],
  };
}
