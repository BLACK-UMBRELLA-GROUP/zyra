// Guardian developer tools: Home and Preview retain their existing behavior.
// Actions is one page-aware catalog of existing local scenario setters.
// Role-denied and unsupported previews remain explicit, never fabricated.
// Protected Founder capability is checked by the host and shared category controls.

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/zyra_dashboard_lab.dart';
import '../theme/zyra_colors.dart';

import '../data/zyra_journey_stages.dart';
import '../screens/auth_gate.dart';
import '../screens/wali/wali_gn_shared.dart';
import '../screens/dev/developer_access_screen.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_developer_access.dart';
import '../services/zyra_promotion_engine.dart';
import '../theme/zyra_text.dart';
import 'zyra_dev_control_system.dart';
import 'zyra_dev_personal_code_fixtures.dart';
import 'zyra_dev_page_options.dart';
import 'zyra_dashboard_lab_controls.dart';
import 'zyra_dev_signup.dart';
import 'zyra_dev_home.dart';
import 'zyra_page_preview_screen.dart';
import 'zyra_dev_scenario.dart';

class WaliDevScenarioPanel extends StatefulWidget {
  final ValueChanged<WaliPage> onOpenPage;
  final ValueListenable<int>? openRequests;

  const WaliDevScenarioPanel({
    super.key,
    required this.onOpenPage,
    this.openRequests,
  });

  @override
  State<WaliDevScenarioPanel> createState() => _WaliDevScenarioPanelState();
}

class _WaliDevScenarioPanelState extends State<WaliDevScenarioPanel> {
  bool _open = false;
  ZyraDevControlSection _section = ZyraDevControlSection.actions;

  final ZyraDevScenario _s = ZyraDevScenario.instance;
  final ZyraPromotionEngine _promotion = ZyraPromotionEngine.instance;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _s.addListener(_onChange);
    _promotion.addListener(_onChange);
    GNContext.instance.addListener(_onChange);
    widget.openRequests?.addListener(_openRequested);
  }

  @override
  void didUpdateWidget(covariant WaliDevScenarioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openRequests != widget.openRequests) {
      oldWidget.openRequests?.removeListener(_openRequested);
      widget.openRequests?.addListener(_openRequested);
    }
  }

  void _openRequested() {
    if (!mounted || _open || !ZyraDeveloperAccess.canUseDeveloperTools) return;
    setState(() {
      _section = ZyraDevControlSection.actions;
      _open = true;
    });
  }

  @override
  void dispose() {
    _s.removeListener(_onChange);
    _promotion.removeListener(_onChange);
    GNContext.instance.removeListener(_onChange);
    widget.openRequests?.removeListener(_openRequested);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _goHome() async {
    setState(() {
      _open = false;
      _notice = null;
    });
    try {
      await ZyraAuth.signOut();
    } catch (error) {
      debugPrint('ZYRA Guardian developer Home sign-out failed: $error');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate(playSplash: true)),
      (route) => false,
    );
  }

  /// NO CONFIRM DIALOG, and that is a difference from the Seeker panel
  /// rather than an omission. Its Reset deletes real rows — mock plan
  /// writes, wali_suggestions, granted credits — so it asks first.
  /// Nothing on this side writes to the server: every Guardian control
  /// here composes stand-ins in memory. There is nothing to lose and
  /// nothing to confirm.
  void _reset() {
    _s.reset();
    unawaited(_promotion.resetDeveloperPolicy());
    setState(() => _notice = 'Guardian and Seeker previews reset.');
  }

  void _selectSection(ZyraDevControlSection section) {
    setState(() {
      _section = section;
      _open = true;
      _notice = null;
    });
  }

  void _openCompletePreview() {
    setState(() => _open = false);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ZyraPagePreviewScreen.guardian(_s.currentWaliPage),
      ),
    );
  }

  Future<void> _openDeveloperAccess() async {
    final navigator = Navigator.of(context);
    setState(() => _open = false);
    final authorized = await ZyraDeveloperAccess.refreshCurrentAuthorization();
    if (!authorized || !ZyraDeveloperAccess.isAuthorizedOperator) {
      try {
        await ZyraAuth.signOut();
      } catch (error) {
        debugPrint(
          'ZYRA Guardian Developer Access recheck sign-out failed: $error',
        );
      }
      if (!navigator.mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate(playSplash: false)),
        (route) => false,
      );
      return;
    }
    if (!navigator.mounted) return;
    navigator.push<void>(
      MaterialPageRoute(builder: (_) => const DeveloperAccessScreen()),
    );
  }

  void _returnHome() {
    if (!mounted) return;
    unawaited(ZyraDevHome.open(context));
    setState(() => _open = false);
  }

  void _startSignUp() {
    setState(() => _open = false);
    ZyraDevSignUp.start(context);
  }

  Future<void> _copySeekerTestCode(String code, {required bool valid}) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() {
      _notice =
          '${valid ? 'Valid Seeker' : 'Wrong'} code copied. '
          'Paste it into Enter code.';
    });
  }

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

  List<ZyraDevPageOption> _counts({
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
      ZyraDevPageOption(
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

  List<ZyraDevPageOption> _roles({bool network = false}) => [
    for (final role in WaliRole.values)
      ZyraDevPageOption(
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

  List<ZyraDevPageOption> _linkedSeekers() => _counts(
    id: 'guardian-linked-seekers',
    group: 'Linked Seekers',
    singular: 'linked Seeker',
    plural: 'linked Seekers',
    value: _s.waliLinkedSeekers,
    max: ZyraDevScenario.fakeWards.length,
    onChanged: _s.setWaliLinkedSeekers,
  );

  List<ZyraDevPageOption> _unreadBadge() => _counts(
    id: 'guardian-unread',
    group: 'Notification badge only',
    singular: 'unread badge item',
    plural: 'unread badge items',
    zeroLabel: 'Use current unread badge',
    value: _s.waliUnread,
    max: 12,
    onChanged: _s.setWaliUnread,
  );

  List<ZyraDevPageOption> _journeys() => [
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
      ZyraDevPageOption(
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
      ZyraDevPageOption(
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

  List<ZyraDevPageOption> _dashboardOptions() => [
    if (!_s.dashboardLabEnabled && _s.dashboardTab == ZyraDashboardTab.now) ...[
      ..._roles(),
      ..._linkedSeekers(),
      ..._journeys(),
    ],
    ..._unreadBadge(),
  ];

  List<ZyraDevPageOption> _networkOptions() {
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
        ZyraDevPageOption(
          id: 'guardian-network-access-${item.$1.name}',
          group: 'Network access',
          label: item.$2,
          selected: _promotion.developerGuardianNetworkState == item.$1,
          onSelected: () =>
              _promotion.setDeveloperGuardianNetworkState(item.$1),
        ),
      for (final scene in GNScene.values)
        ZyraDevPageOption(
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
        ZyraDevPageOption(
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
        ZyraDevPageOption(
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
          ZyraDevPageOption(
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
      ZyraDevPageOption(
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
      ZyraDevPageOption(
        id: 'guardian-notification-permission',
        group: 'Notification permission',
        label: 'Notification permission banner',
        onSelected: () {
          _promotion.showDeveloperPreview(
            product: ZyraPromotionProduct.notifications,
            role: ZyraPromotionRole.guardian,
          );
          setState(() => _open = false);
        },
      ),
      const ZyraDevPageOption(
        id: 'guardian-introductions-sent-unavailable',
        group: 'Unavailable previews',
        label: 'Introductions sent',
        unavailableReason:
            'No live Guardian list shows sent introductions. '
            'The Network preview has its own existing local request states.',
      ),
    ];
  }

  List<ZyraDevPageOption> _pageOptions(WaliPage page) => switch (page) {
    WaliPage.dashboard => _dashboardOptions(),
    WaliPage.network => _networkOptions(),
    WaliPage.seekers => [
      if (ZyraDeveloperAccess.isMainAppFounderPreview) ...[
        ZyraDevPageOption(
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
        ZyraDevPageOption(
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
      const ZyraDevPageOption(
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

  @override
  Widget build(BuildContext context) {
    // Backstop — see the header. Not an else-branch of the mount point.
    if (!ZyraDeveloperAccess.canUseDeveloperTools || !_open) {
      return const SizedBox.shrink();
    }

    final page = _s.currentWaliPage;

    return Positioned.fill(
      child: Material(
        key: const ValueKey('dev_controls_page'),
        color: ZyraColors.modalSheetSurface.withValues(alpha: 242 / 255),
        child: SafeArea(
          child: Column(
            children: [
              ZyraDevControlsPageHeader(
                pageLabel: page == WaliPage.dashboard
                    ? zyraDashboardOptionsTitle(_s, ZyraDashboardRole.guardian)
                    : page.label,
                selected: _section,
                onSelected: _selectSection,
                onClose: () => setState(() => _open = false),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  children: [
                    if (_notice != null) ...[
                      const SizedBox(height: 10),
                      _WaliInlineNotice(
                        message: _notice!,
                        onDismiss: () => setState(() => _notice = null),
                      ),
                    ],
                    if (_section == ZyraDevControlSection.preview) ...[
                      const SizedBox(height: 10),
                      ZyraDevPreviewLauncher(
                        pageLabel: page.label,
                        onOpen: _openCompletePreview,
                      ),
                    ],
                    if (_section == ZyraDevControlSection.home) ...[
                      const SizedBox(height: 10),
                      ZyraDevHomeTools(
                        busy: false,
                        guardian: true,
                        onHome: _returnHome,
                        onOpenSplashPreview: () =>
                            setState(() => _open = false),
                        onRestart: _goHome,
                        onReset: _reset,
                        onAccounts: _openDeveloperAccess,
                        onSeekerSignUp: _startSignUp,
                        onGuardianSignUp: _startSignUp,
                      ),
                    ],
                    if (_section == ZyraDevControlSection.actions) ...[
                      const SizedBox(height: 10),
                      if (page == WaliPage.dashboard)
                        ZyraDashboardLabControls(
                          scenario: _s,
                          hostRole: ZyraDashboardRole.guardian,
                          additionalOptions: _dashboardOptions(),
                        )
                      else
                        ZyraDevPageOptions(
                          options: _pageOptions(page),
                          contextKey:
                              'guardian:${page.name}:'
                              '${_s.waliRole.name}:'
                              '${GNContext.instance.isMainWali}:'
                              '${_promotion.developerGuardianNetworkState.name}',
                        ),
                    ],

                    if (_section == ZyraDevControlSection.preview) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Internal preview',
                        style: ZyraText.subtext(
                          size: 10,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaliInlineNotice extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _WaliInlineNotice({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    const color = ZyraColors.journeyDotGreen;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 2, 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: ZyraText.subtext(size: 10, color: Colors.white70),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
