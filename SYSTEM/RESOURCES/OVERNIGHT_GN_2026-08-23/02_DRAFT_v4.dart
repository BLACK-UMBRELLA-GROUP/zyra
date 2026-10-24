// FIRST DRAFT — overnight run 2026-08-23. Working rules applied; Founder ratification of D1-D13 pending. flutter analyze gated.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../dev/guardian_network_preview.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../services/zyra_entitlement_service.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_card_metrics.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_profile_image.dart';
import '../../widgets/zyra_segmented_toggle.dart';
import '../../widgets/zyra_state_widgets.dart';

class WaliNetworkScreen extends StatefulWidget {
  const WaliNetworkScreen({super.key});

  @override
  State<WaliNetworkScreen> createState() => _WaliNetworkScreenState();
}

class _WaliNetworkScreenState extends State<WaliNetworkScreen> {
  bool _loading = true;
  bool _hasExtended = false;
  bool _purchasing = false;

  final PageController _pager = PageController();
  double _pagerPos = 0;

  String? _selectedSeekerId;
  GuardianNetworkPreviewScene? _lastPreviewScene;
  final Map<String, GuardianNetworkCardDecision> _previewDecisions = {};

  // PROVISIONAL MOCK DATA FOR DEV STATE SWITCHER
  bool _devHasExtended = false;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    _pager.addListener(_onPagerScroll);
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      _loading = false;
      _lastPreviewScene = ZyraDevScenario.instance.guardianNetworkScene;
      ZyraDevScenario.instance.addListener(_onPreviewChange);

      // Initialize mock data
      if (kDebugMode) {
        _devHasExtended = true;
      }
    } else {
      _loadEntitlement();
    }
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      ZyraDevScenario.instance.removeListener(_onPreviewChange);
    }
    _pager.removeListener(_onPagerScroll);
    _pager.dispose();
    super.dispose();
  }

  void _onPagerScroll() {
    if (!_pager.hasClients || _pager.page == null) return;
    final p = _pager.page!.clamp(0.0, 1.0);
    if ((p - _pagerPos).abs() < 0.001) return;
    setState(() => _pagerPos = p);
  }

  void _onChange() => setState(() {});

  void _onPreviewChange() {
    final scene = ZyraDevScenario.instance.guardianNetworkScene;
    if (scene != _lastPreviewScene) {
      _lastPreviewScene = scene;
      _previewDecisions.clear();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadEntitlement() async {
    final has = await ZyraEntitlementService.hasWaliOne();
    if (mounted) {
      setState(() {
        _hasExtended = has;
        _loading = false;
      });
    }
  }

  Future<void> _purchaseExtendedWali() async {
    setState(() => _purchasing = true);
    final ok = await ZyraEntitlementService.mockPurchaseWaliPremium();
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (ok) {
      await _loadEntitlement();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Guardian+ unlocked (preview build — no payment taken).',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't unlock Guardian+ — try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      return _buildFirstDraftPreview(context);
    }

    final hasExtended = _hasExtended;

    if (kDebugMode) {
      // Switch between states for dev purposes
      switch (_devHasExtended) {
        case false:
          return _buildLockedNetworkView(context);
        case true:
          return _buildUnlockedNetworkView(context);
      }
    }

    return hasExtended
        ? _buildUnlockedNetworkView(context)
        : _buildLockedNetworkView(context);
  }

  Widget _buildLockedNetworkView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Network', style: ZyraText.heading(size: 26)),
            ),
            if (_loading)
              const Expanded(child: ZyraLoading())
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: Colors.white38,
                          size: 28,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Network access requires Guardian+ capabilities.',
                          style: ZyraText.body(size: 14, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Included free with a linked Seeker\'s ZYRA One subscription, or available on its own for £9.99/month.',
                          style: ZyraText.subtext(size: 12.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: ZyraColors.accentBg,
                              border: Border.all(
                                color: ZyraColors.accentBorder,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(50),
                                onTap: _purchasing
                                    ? null
                                    : _purchaseExtendedWali,
                                child: Center(
                                  child: _purchasing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Get Guardian+ — £9.99/month',
                                          style: ZyraText.button(size: 13),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Preview build — no real payment is taken.',
                            style: ZyraText.subtext(
                              size: 10.5,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedNetworkView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Network', style: ZyraText.heading(size: 26)),
            ),
            if (_loading)
              const Expanded(child: ZyraLoading())
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: ZyraSegmentedToggle(
                  labels: const ['Discover', 'Requests'],
                  position: _pagerPos,
                  labelSize: 13,
                  onChanged: (i) => _pager.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pager,
                  children: const [
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 100),
                      child: ZyraEmptyState(
                        icon: Icons.diversity_3_outlined,
                        title: 'Discover families',
                        message:
                            'Families appear here once other Guardians with Guardian+ join.',
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 100),
                      child: ZyraEmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No requests yet',
                        message:
                            'Family Introduction Requests will appear here.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFirstDraftPreview(BuildContext context) {
    final scenario = ZyraDevScenario.instance;
    final wards = ZyraDevScenario.composeWaliWards(
      real: AppState.instance.waliRealLinkedSeekers,
    );
    WaliLinkedPerson? selected;
    if (wards.length == 1) {
      selected = wards.first;
    } else if (_selectedSeekerId != null) {
      for (final ward in wards) {
        if (ward.id == _selectedSeekerId) {
          selected = ward;
          break;
        }
      }
    }
    final wardIndex = selected == null ? 0 : wards.indexOf(selected);
    final recommendations = [
      for (var i = 0; i < 4; i++)
        guardianNetworkPreviewRecommendations[(wardIndex * 2 + i) %
            guardianNetworkPreviewRecommendations.length],
    ];

    return Container(
      key: const Key('guardian-network-preview'),
      decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guardian Network',
                          style: ZyraText.heading(size: 26),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Thoughtful recommendations for the Seeker you represent.',
                          style: ZyraText.subtext(size: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const _PreviewMarker(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: ZyraSegmentedToggle(
                labels: const ['Discover', 'Requests'],
                position: _pagerPos,
                labelSize: 13,
                onChanged: (i) => _pager.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pager,
                children: [
                  _GuardianNetworkDiscover(
                    wards: wards,
                    selected: selected,
                    recommendations: recommendations,
                    plan: scenario.guardianNetworkPlan,
                    scene: scenario.guardianNetworkScene,
                    decisionFor: (recommendation, index) {
                      final key = '${selected?.id}/${recommendation.id}';
                      final local = _previewDecisions[key];
                      if (local != null) return local;
                      if (index == 0 &&
                          scenario.guardianNetworkScene ==
                              GuardianNetworkPreviewScene.suggested) {
                        return GuardianNetworkCardDecision.suggested;
                      }
                      if (index == 0 &&
                          scenario.guardianNetworkScene ==
                              GuardianNetworkPreviewScene.passed) {
                        return GuardianNetworkCardDecision.passed;
                      }
                      return GuardianNetworkCardDecision.undecided;
                    },
                    onSelectSeeker: (ward) =>
                        setState(() => _selectedSeekerId = ward.id),
                    onDecision: (recommendation, decision) {
                      if (selected == null) return;
                      setState(() {
                        _previewDecisions['${selected!.id}/${recommendation.id}'] =
                            decision;
                      });
                    },
                    onView: (recommendation) => _showPreviewProfile(
                      context,
                      seekerName: selected?.firstName ?? 'your Seeker',
                      recommendation: recommendation,
                    ),
                    onRetry: () => scenario.setGuardianNetworkScene(
                      GuardianNetworkPreviewScene.recommendations,
                    ),
                    onPreviewOne: () => scenario.setGuardianNetworkPlan(
                      GuardianNetworkPreviewPlan.one,
                    ),
                  ),
                  _GuardianNetworkRequests(
                    seekerName: selected?.firstName,
                    suggested: [
                      for (var i = 0; i < recommendations.length; i++)
                        if (_decisionFor(
                              selected,
                              recommendations[i],
                              i,
                              scenario.guardianNetworkScene,
                            ) ==
                            GuardianNetworkCardDecision.suggested)
                          recommendations[i],
                    ],
                    onView: (recommendation) => _showPreviewProfile(
                      context,
                      seekerName: selected?.firstName ?? 'your Seeker',
                      recommendation: recommendation,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  GuardianNetworkCardDecision _decisionFor(
    WaliLinkedPerson? selected,
    GuardianNetworkPreviewRecommendation recommendation,
    int index,
    GuardianNetworkPreviewScene scene,
  ) {
    final local = _previewDecisions['${selected?.id}/${recommendation.id}'];
    if (local != null) return local;
    if (index == 0 && scene == GuardianNetworkPreviewScene.suggested) {
      return GuardianNetworkCardDecision.suggested;
    }
    if (index == 0 && scene == GuardianNetworkPreviewScene.passed) {
      return GuardianNetworkCardDecision.passed;
    }
    return GuardianNetworkCardDecision.undecided;
  }

  Future<void> _showPreviewProfile(
    BuildContext context, {
    required String seekerName,
    required GuardianNetworkPreviewRecommendation recommendation,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _GuardianNetworkProfileSheet(
        seekerName: seekerName,
        recommendation: recommendation,
      ),
    );
  }
}

class _PreviewMarker extends StatelessWidget {
  const _PreviewMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withAlpha(0.16),
          width: 0.5,
        ),
      ),
      child: Text(
        'FIRST DRAFT',
        style: ZyraText.chapterLabel(
          color: Colors.white54,
        ).copyWith(fontSize: 8),
      ),
    );
  }
}

class _GuardianNetworkDiscover extends StatelessWidget {
  final List<WaliLinkedPerson> wards;
  final WaliLinkedPerson? selected;
  final List<GuardianNetworkPreviewRecommendation> recommendations;
  final GuardianNetworkPreviewPlan plan;
  final GuardianNetworkPreviewScene scene;
  final GuardianNetworkCardDecision Function(
    GuardianNetworkPreviewRecommendation recommendation,
    int index,
  ) decisionFor;
  final ValueChanged<WaliLinkedPerson> onSelectSeeker;
  final void Function(
    GuardianNetworkPreviewRecommendation recommendation,
    GuardianNetworkCardDecision decision,
  ) onDecision;
  final ValueChanged<GuardianNetworkPreviewRecommendation> onView;
  final VoidCallback onRetry;
  final VoidCallback onPreviewOne;

  const _GuardianNetworkDiscover({
    required this.wards,
    required this.selected,
    required this.recommendations,
    required this.plan,
    required this.scene,
    required this.decisionFor,
    required this.onSelectSeeker,
    required this.onDecision,
    required this.onView,
    required this.onRetry,
    required this.onPreviewOne,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('guardian-network-discover'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
      children: [
        Text(
          'SEARCHING FOR',
          style: ZyraText.chapterLabel(color: Colors.white54),
        ),
        const SizedBox(height: 8),
        if (wards.isEmpty)
          const _NetworkContextNotice(
            icon: Icons.person_add_alt_1_outlined,
            title: 'Link a Seeker first',
            message:
                'Guardian Network always works on behalf of one linked Seeker. Add one in the developer panel to preview this context.',
          )
        else
          _NetworkSeekerSelector(
            wards: wards,
            selected: selected,
            onChanged: onSelectSeeker,
          ),
        const SizedBox(height: 16),
        if (wards.length > 1 && selected == null)
          const _NetworkContextNotice(
            icon: Icons.touch_app_outlined,
            title: 'Choose a Seeker',
            message:
                'Select who you are searching for before ZYRA loads any recommendations. Each Seeker has a separate, private context.',
          )
        else if (wards.isNotEmpty && plan == GuardianNetworkPreviewPlan.basic)
          _NetworkPlanNotice(
            seekerName: selected!.firstName,
            onPreviewOne: onPreviewOne,
          )
        else if (wards.isNotEmpty &&
            scene == GuardianNetworkPreviewScene.loading)
          const SizedBox(
            height: 330,
            child: ZyraLoading(label: 'Finding suitable families…'),
          )
        else if (wards.isNotEmpty && scene == GuardianNetworkPreviewScene.error)
          SizedBox(height: 330, child: ZyraUnknownErrorState(onRetry: onRetry))
        else if (wards.isNotEmpty && scene == GuardianNetworkPreviewScene.empty)
          const SizedBox(
            height: 330,
            child: ZyraEmptyState(
              icon: Icons.person_search_outlined,
              title: 'No suitable recommendations yet',
              message:
                  'Nothing currently fits this Seeker’s requirements and availability. ZYRA will keep looking without widening their choices.',
            ),
          )
        else if (wards.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended for ${selected!.firstName}',
                      style: ZyraText.heading(size: 19),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Shortlisted around their choices — never outside them.',
                      style: ZyraText.subtext(size: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'CURATED SET',
                style: ZyraText.chapterLabel(color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (scene == GuardianNetworkPreviewScene.capacity) ...[
            const ZyraErrorBanner(
              message:
                  'This Seeker is at their introduction capacity. You can still review recommendations, but Suggest stays unavailable.',
            ),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < recommendations.length; i++)
            _GuardianNetworkRecommendationCard(
              seekerName: selected!.firstName,
              recommendation: recommendations[i],
              decision: decisionFor(recommendations[i], i),
              capacityReached: scene == GuardianNetworkPreviewScene.capacity,
              onView: () => onView(recommendations[i]),
              onDecision: (decision) =>
                  onDecision(recommendations[i], decision),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Preview fields and recommendation reasons are provisional. No action on this page changes live data.',
              textAlign: TextAlign.center,
              style: ZyraText.subtext(size: 10.5, color: Colors.white38),
            ),
          ),
        ],
      ],
    );
  }
}

class _NetworkSeekerSelector extends StatelessWidget {
  final List<WaliLinkedPerson> wards;
  final WaliLinkedPerson? selected;
  final ValueChanged<WaliLinkedPerson> onChanged;

  const _NetworkSeekerSelector({
    required this.wards,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (wards.length == 1) {
      return _SeekerChoice(
        key: Key('guardian-network-seeker-${wards.first.id}'),
        ward: wards.first,
        selected: true,
        expanded: true,
        onTap: () {},
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < wards.length; i++) ...[
            _SeekerChoice(
              key: Key('guardian-network-seeker-${wards[i].id}'),
              ward: wards[i],
              selected: wards[i].id == selected?.id,
              onTap: () => onChanged(wards[i]),
            ),
            if (i < wards.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SeekerChoice extends StatelessWidget {
  final WaliLinkedPerson ward;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _SeekerChoice({
    super.key,
    required this.ward,
    required this.selected,
    this.expanded = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: selected ? ZyraColors.frostSelectedFill : ZyraColors.frostFill,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 8, 14, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.white.withAlpha(0.28)
                  : ZyraColors.frostBorder,
              width: 0.7,
            ),
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ZyraColors.luxuryDarkPurple.withAlpha(0.75),
                  border: Border.all(
                    color: Colors.white.withAlpha(0.18),
                  ),
                ),
                child: Text(
                  ward.firstName.characters.first.toUpperCase(),
                  style: ZyraText.body(size: 13, color: Colors.white),
                ),
              ),
              const SizedBox(width: 9),
              if (expanded)
                Expanded(
                  child: Text(
                    ward.firstName,
                    style: ZyraText.body(size: 13.5, color: Colors.white),
                  ),
                )
              else
                Text(
                  ward.firstName,
                  style: ZyraText.body(size: 13.5, color: Colors.white),
                ),
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 15, color: Colors.white70),
              ],
            ],
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class _NetworkContextNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _NetworkContextNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ZyraColors.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZyraColors.glassBorder, width: 0.7),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.white54),
          const SizedBox(height: 10),
          Text(title, style: ZyraText.heading(size: 16)),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 12.5),
          ),
        ],
      ),
    );
  }
}

class _NetworkPlanNotice extends StatelessWidget {
  final String seekerName;
  final VoidCallback onPreviewOne;

  const _NetworkPlanNotice({
    required this.seekerName,
    required this.onPreviewOne,
  });

  @override
  Widget build(BuildContext context) {
    return _NetworkContextNoticeWithAction(
      icon: Icons.lock_outline,
      title: 'Network access for $seekerName',
      message:
          '$seekerName’s Basic plan does not supply Guardian+ access. A Guardian’s own Guardian+ entitlement may still provide access.',
      actionLabel: 'Preview with ZYRA One',
      onAction: onPreviewOne,
    );
  }
}

class _NetworkContextNoticeWithAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _NetworkContextNoticeWithAction({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ZyraColors.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZyraColors.glassBorder, width: 0.7),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.white54),
          const SizedBox(height: 12),
          Text(title, style: ZyraText.heading(size: 17)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 12.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: ZyraColors.primaryAction,
                foregroundColor: ZyraColors.onPrimaryAction,
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(
                actionLabel,
                style: ZyraText.button(
                  size: 13,
                  color: ZyraColors.onPrimaryAction,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuardianNetworkRecommendationCard extends StatelessWidget {
  final String seekerName;
  final GuardianNetworkPreviewRecommendation recommendation;
  final GuardianNetworkCardDecision decision;
  final bool capacityReached;
  final VoidCallback onView;
  final ValueChanged<GuardianNetworkCardDecision> onDecision;

  const _GuardianNetworkRecommendationCard({
    required this.seekerName,
    required this.recommendation,
    required this.decision,
    required this.capacityReached,
    required this.onView,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: decision == GuardianNetworkCardDecision.passed ? 0.68 : 1,
      child: Container(
        key: Key('guardian-network-card-${recommendation.id}'),
        margin: const EdgeInsets.only(bottom: ZyraCardMetrics.spacing.toDouble()),
        padding: const EdgeInsets.all(ZyraCardMetrics.padding.toDouble()),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(0.07),
          borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius.toDouble()),
          border: Border.all(
            color: decision == GuardianNetworkCardDecision.suggested
                ? const Color(0xFFDEC979).withAlpha(0.55)
                : Colors.white.withAlpha(0.14),
            width: decision == GuardianNetworkCardDecision.suggested ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ZyraCardMetrics.thumbRadius.toDouble(),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: ZyraCardMetrics.thumb.toDouble(),
                        height: ZyraCardMetrics.thumb.toDouble(),
                        child: ZyraProfileImage(''),
                      ),
                      Text(
                        recommendation.firstName.characters.first,
                        style: ZyraText.heading(
                          size: 21,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ZyraCardMetrics.gap.toDouble()),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${recommendation.firstName}, ${recommendation.age}',
                        style: ZyraText.body(size: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recommendation.region,
                        style: ZyraText.subtext(size: 11.5),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.diversity_3_outlined,
                            size: 13,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              recommendation.familyContext,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ZyraText.subtext(
                                size: 10.5,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _DecisionStatus(decision: decision),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              'WHY THIS MAY FIT $seekerName'.toUpperCase(),
              style: ZyraText.chapterLabel(color: Colors.white38),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reason in recommendation.reasons)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(0.07),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withAlpha(0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: ZyraText.subtext(
                        size: 10.5,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 13),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: decision == GuardianNetworkCardDecision.undecided
                  ? Row(
                      key: const ValueKey('network-actions'),
                      children: [
                        Expanded(
                          child: _NetworkAction(
                            key: Key('network-view-${recommendation.id}'),
                            label: 'View',
                            icon: Icons.visibility_outlined,
                            onTap: onView,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _NetworkAction(
                            key: Key('network-pass-${recommendation.id}'),
                            label: 'Pass',
                            icon: Icons.close,
                            onTap: () =>
                                onDecision(GuardianNetworkCardDecision.passed),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _NetworkAction(
                            key: Key('network-suggest-${recommendation.id}'),
                            label: 'Suggest',
                            icon: Icons.send_outlined,
                            primary: true,
                            enabled: !capacityReached,
                            onTap: () => onDecision(
                              GuardianNetworkCardDecision.suggested,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _DecisionConfirmation(
                      key: ValueKey(decision),
                      decision: decision,
                      onView: onView,
                      onUndo: () =>
                          onDecision(GuardianNetworkCardDecision.undecided),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionStatus extends StatelessWidget {
  final GuardianNetworkCardDecision decision;
  const _DecisionStatus({required this.decision});

  @override
  Widget build(BuildContext context) {
    if (decision == GuardianNetworkCardDecision.undecided) {
      return const SizedBox.shrink();
    }
    final suggested = decision == GuardianNetworkCardDecision.suggested;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: (suggested ? const Color(0xFFDEC979) : Colors.white).withAlpha(
          0.11,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        suggested ? 'SUGGESTED' : 'PASSED',
        style: ZyraText.chapterLabel(
          color: suggested ? const Color(0xFFDEC979) : Colors.white54,
        ).copyWith(fontSize: 7.5),
      ),
    );
  }
}

class _NetworkAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  const _NetworkAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final fill = primary
        ? ZyraColors.primaryAction.withAlpha(enabled ? 255 : 46)
        : Colors.white.withAlpha(enabled ? 20 : 8);
    final foreground = primary
        ? ZyraColors.onPrimaryAction.withAlpha(enabled ? 255 : 82)
        : Colors.white.withAlpha(enabled ? 199 : 64);
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: primary
                  ? Colors.transparent
                  : Colors.white.withAlpha(enabled ? 35 : 15),
              width: 0.5,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.button(size: 11.5, color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecisionConfirmation extends StatelessWidget {
  final GuardianNetworkCardDecision decision;
  final VoidCallback onView;
  final VoidCallback onUndo;

  const _DecisionConfirmation({
    super.key,
    required this.decision,
    required this.onView,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final suggested = decision == GuardianNetworkCardDecision.suggested;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 8, 5, 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            suggested
                ? Icons.check_circle_outline
                : Icons.visibility_off_outlined,
            size: 16,
            color: suggested ? const Color(0xFFDEC979) : Colors.white54,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              suggested
                  ? 'Suggestion staged for the Seeker.'
                  : 'Removed from this recommendation list.',
              style: ZyraText.subtext(size: 11, color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: suggested ? onView : onUndo,
            child: Text(
              suggested ? 'View' : 'Undo',
              style: ZyraText.button(size: 11, color: Colors.white70),
            ),
          ),
          if (suggested)
            TextButton(
              onPressed: onUndo,
              child: Text(
                'Undo',
                style: ZyraText.button(size: 11, color: Colors.white54),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuardianNetworkRequests extends StatelessWidget {
  final String? seekerName;
  final List<GuardianNetworkPreviewRecommendation> suggested;
  final ValueChanged<GuardianNetworkPreviewRecommendation> onView;

  const _GuardianNetworkRequests({
    required this.seekerName,
    required this.suggested,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (seekerName == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 112),
        child: ZyraEmptyState(
          icon: Icons.person_add_alt_1_outlined,
          title: 'No Seeker selected',
          message: 'Link a Seeker before reviewing Network activity.',
        ),
      );
    }
    if (suggested.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 112),
        child: ZyraEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No requests yet',
          message:
              'Suggestions and family introduction activity will appear here once the final consent flow is approved.',
        ),
      );
    }
    return ListView(
      key: const PageStorageKey('guardian-network-requests'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
      children: [
        Text('For $seekerName', style: ZyraText.heading(size: 19)),
        const SizedBox(height: 4),
        Text(
          'Your staged suggestions. No request has been sent to another family.',
          style: ZyraText.subtext(size: 12),
        ),
        const SizedBox(height: 14),
        for (final recommendation in suggested)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFDEC979).withAlpha(87),
                width: 0.7,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ZyraColors.luxuryDarkPurple,
                  ),
                  child: Text(
                    recommendation.firstName.characters.first,
                    style: ZyraText.heading(size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.firstName,
                        style: ZyraText.body(size: 14.5, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Suggested to $seekerName · awaiting their choice',
                        style: ZyraText.subtext(size: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onView(recommendation),
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GuardianNetworkProfileSheet extends StatelessWidget {
  final String seekerName;
  final GuardianNetworkPreviewRecommendation recommendation;

  const _GuardianNetworkProfileSheet({
    required this.seekerName,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        26 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        gradient: ZyraColors.sheetGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
