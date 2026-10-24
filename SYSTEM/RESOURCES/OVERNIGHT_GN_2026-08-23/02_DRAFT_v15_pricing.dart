// GN DRAFT 3.1 — D14-RATIFIED interaction model (2026-08-23). Built to
// ZYRA_GN_BUILD_CONTRACT_CURRENT_VERSION_V1.md (Rules 1-44, as amended
// for Draft 3 — see wali_gn_shared.dart's header).
//
// Founder directive, 2026-08-23, the Dashboard/Network restructure:
//   · The CONNECTIONS context moved to the Wali Dashboard
//     (GNConnectionsPanel in wali_gn_shared.dart). This page is now
//     DISCOVER only — the one place families are served.
//   · The top slider is the Guardian's SEEKERS BY NAME (GNSeekerSlider),
//     the same slider the Dashboard shows. Selection is shared through
//     GNContext: slide to a Seeker on either page and the other page is
//     already on them.
//   · The merge card's "Review request" no longer switches pages — it
//     opens the incoming request in place (showGNIncomingSheet); the
//     same request also sits in the Dashboard's Connections section.
//
// Draft 3.1 (Founder phone feedback, 2026-08-23), four changes:
//   1. The no-Seeker state copies the Seeker-side blank pages and the
//      Dashboard: message + "Invite your Seeker" button — no dev-speak.
//   2. The Seeker slider is the Seeker Connections page's exact pill
//      (ZyraSegmentedToggle) and the SCREEN SWIPES: the body is a
//      PageView, one Discover per Seeker, fill travelling with the
//      finger; swiping writes the shared selection.
//   3. REVERSED same day (Draft 3.2, from screenshots): no Seeker → NO
//      bar at all. The blank page copies the Guardians page exactly —
//      the large + and one short line (ZyraAddCircle); the slider first
//      appears with the first Seeker.
//   4. The served family card FILLS the screen (no dead area below):
//      the page lays out to full height, the card stretches and spaces
//      its content, scrolling only when a small screen truly needs it.
//
// Draft 2.x history kept in git and in OVERNIGHT_GN_2026-08-23/. All
// mock data remains PROVISIONAL and developer-preview only (Rule 44);
// the production path renders the entitlement gate + empty states;
// flutter analyze gated.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../services/zyra_entitlement_service.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_card_metrics.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_state_widgets.dart';
import 'wali_gn_shared.dart';
import 'wali_invite_seeker_screen.dart';

class WaliNetworkScreen extends StatefulWidget {
  const WaliNetworkScreen({super.key});

  @override
  State<WaliNetworkScreen> createState() => _WaliNetworkScreenState();
}

class _WaliNetworkScreenState extends State<WaliNetworkScreen> {
  bool _loading = true;
  bool _hasExtended = false;
  bool _purchasing = false;

  // Production dev shortcut (debug builds only): preview the unlocked
  // layout without a live entitlement row.
  bool _devHasExtended = false;

  // Draft 3.1: the Discover body is a PageView — one page per Seeker —
  // so the screen swipes between Seekers exactly like the Seeker
  // Connections page, the slider fill travelling with the finger.
  // Created lazily on the first preview build (ward count is composed
  // at build time), initial page = the shared selection.
  PageController? _pager;
  double _pagerPos = 0;

  PageController _ensurePager(int initialIndex) {
    var pager = _pager;
    if (pager == null) {
      pager = PageController(initialPage: initialIndex);
      pager.addListener(_onPagerScroll);
      _pager = pager;
      _pagerPos = initialIndex.toDouble();
    }
    return pager;
  }

  void _onPagerScroll() {
    final pager = _pager;
    if (pager == null || !pager.hasClients || pager.page == null) return;
    if ((pager.page! - _pagerPos).abs() < 0.001) return;
    setState(() => _pagerPos = pager.page!);
  }

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      _loading = false;
      // Founder fix 2026-08-23: rebuild when the dev-scenario store changes
      // (seeker composition edited in the side panel).
      ZyraDevScenario.instance.addListener(_onChange);
      // Draft 3: the shared GN state — seeker selection, stages, scenes —
      // lives in GNContext so this page and the Dashboard stay in step.
      GNContext.instance.addListener(_onChange);
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
    // UNGATED removes — OA-ZYRA-250 (2026-08-23). The gated pair here is
    // exactly what crashed Draft 2.x live: switch accounts through the
    // dev panel and canUseDeveloperTools flips before dispose runs, so
    // the ZyraDevScenario listener outlived this State and the next
    // notify (Seeker-side setCurrentPage) called setState on a defunct
    // element. removeListener on a never-registered listener is a
    // documented no-op — remove without gates, in every build.
    ZyraDevScenario.instance.removeListener(_onChange);
    GNContext.instance.removeListener(_onChange);
    _pager?.removeListener(_onPagerScroll);
    _pager?.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
    _syncPagerToSelection();
  }

  /// When the Dashboard (or anything else) changes the shared selection,
  /// this page's pager glides to that Seeker. A no-op while the change
  /// originated here — the pager is already on (or crossing into) the
  /// selected page.
  void _syncPagerToSelection() {
    final pager = _pager;
    if (pager == null || !pager.hasClients) return;
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
    final wards = ZyraDevScenario.composeWaliWards(
      real: AppState.instance.waliRealLinkedSeekers,
    );
    if (wards.isEmpty) return;
    final selected = GNContext.instance.effectiveSelected(wards);
    var index = 0;
    for (var i = 0; i < wards.length; i++) {
      if (wards[i].id == selected?.id) {
        index = i;
        break;
      }
    }
    final page = pager.page;
    if (page != null && page.round() != index) {
      pager.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
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

  // ── build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      return _buildD14Preview(context);
    }

    final hasExtended = _hasExtended;

    if (kDebugMode) {
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

  // ── production paths (unchanged behaviour: gate + empty states, Rule 44) ─
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
                          'Included with a linked Seeker\'s ZYRA One for their Main Wali, or available on its own for £24.99/month.',
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
                                          'Get Guardian+ — £24.99/month',
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedNetworkView(BuildContext context) {
    // Draft 3: no Discover/Connections toggle any more — Connections
    // lives on the Dashboard, so the unlocked production placeholder is
    // Discover's empty state alone.
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
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 100),
                  child: ZyraEmptyState(
                    icon: Icons.diversity_3_outlined,
                    title: 'Discover families',
                    message:
                        'Families appear here once other Guardians with Guardian+ join. Requests and connections appear on your Dashboard.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── D14 preview (developer tools only) ──────────────────────────────────
  Widget _buildD14Preview(BuildContext context) {
    final ctx = GNContext.instance;
    final wards = ZyraDevScenario.composeWaliWards(
      real: AppState.instance.waliRealLinkedSeekers,
    );
    final selected = ctx.effectiveSelected(wards);
    var selectedIndex = 0;
    for (var i = 0; i < wards.length; i++) {
      if (wards[i].id == selected?.id) {
        selectedIndex = i;
        break;
      }
    }
    // The slider's fill: live pager position once the pager exists, the
    // settled index on the very first frame.
    final sliderPos = _pager == null || wards.isEmpty
        ? selectedIndex.toDouble()
        : _pagerPos.clamp(0.0, (wards.length - 1).toDouble()).toDouble();

    return Container(
      key: const Key('guardian-network-preview'),
      decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Network', style: ZyraText.heading(size: 26)),
                  ),
                  if (!kReleaseMode)
                    GNDevChip(onTap: () => showGNDevSheet(context)),
                ],
              ),
            ),
            // Founder 2026-08-23 (Draft 3/3.1): the top slider IS the
            // Seekers — the Seeker Connections page's pill, its fill
            // travelling with the swipe below, selection shared with the
            // Dashboard through GNContext. Draft 3.2 REVERSED 3.1's
            // waiting-bar: no Seeker linked → no bar at all — the page
            // shows only the + invitation (the picture-1 pattern).
            if (wards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                child: GNSeekerSlider(
                  wards: wards,
                  position: sliderPos,
                  onSelect: (i) => _pager?.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            Expanded(
              child: wards.isEmpty
                  ? _buildNoSeeker(context)
                  : PageView.builder(
                      controller: _ensurePager(selectedIndex),
                      itemCount: wards.length,
                      onPageChanged: (i) => ctx.selectSeeker(wards[i].id),
                      itemBuilder: (context, i) =>
                          _buildDiscover(context, wards, wards[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── the no-Seeker state (Draft 3.2: the picture-1 pattern, exactly) ─────
  Widget _buildNoSeeker(BuildContext context) {
    // Founder, from screenshots 2026-08-23: copy the Guardians page's
    // blank state — the large + and one short line near the top. No bar
    // above it, no paragraph, no pill button.
    return Column(
      children: [
        const SizedBox(height: 40),
        Center(
          child: ZyraAddCircle(
            label: 'Invite your Seeker',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WaliInviteSeekerScreen()),
            ),
          ),
        ),
      ],
    );
  }

  // ── Discover (Rung 0, Rules 22-24) — one full-height page per Seeker ────
  Widget _buildDiscover(
    BuildContext context,
    List<WaliLinkedPerson> wards,
    WaliLinkedPerson ward,
  ) {
    final ctx = GNContext.instance;
    if (ctx.scene == GNScene.loading || ctx.choosing) {
      return const Center(
        child: ZyraLoading(label: 'ZYRA is choosing the next family…'),
      );
    }
    if (ctx.scene == GNScene.error) {
      return Center(
        child: SizedBox(
          height: 330,
          child: ZyraUnknownErrorState(
            onRetry: () => ctx.setScene(GNScene.standard),
          ),
        ),
      );
    }

    final fams = ctx.familiesFor(wards, ward);
    final live = ctx.liveCount(ward, fams);
    final capped = ctx.scene == GNScene.capReached || live >= 3;
    final served = ctx.scene == GNScene.empty
        ? null
        : ctx.servedFamily(ward, fams);
    final setAsideCount = fams
        .where((f) => ctx.stageOf(ward, f) == GNStage.setAside)
        .length;

    // Whatever owns the stretch zone between the heading and the footer.
    Widget stage;
    if (capped) {
      stage = Center(child: _CapReachedCard(live: live));
    } else if (served == null) {
      stage = const Center(
        child: ZyraEmptyState(
          icon: Icons.person_search_outlined,
          title: 'No suitable families right now',
          message:
              'Nothing currently fits this Seeker\'s requirements and availability. ZYRA keeps looking without widening their choices.',
        ),
      );
    } else if (ctx.stageOf(ward, served) == GNStage.incoming ||
        ctx.scene == GNScene.merge) {
      final family = served;
      stage = Center(
        child: _MergeCard(
          family: family,
          onReview: () {
            ctx.track('incoming_reviewed', family.id);
            showGNIncomingSheet(context, wards: wards, ward: ward);
          },
        ),
      );
    } else {
      final family = served;
      stage = _ServedFamilyCard(
        family: family,
        isMainWali: ctx.isMainWali,
        onView: () {
          ctx.track('card_viewed', family.id);
          showGNProfileSheet(context, family, rung2: false);
        },
        onGuardian: () {
          ctx.track('guardian_viewed', family.id);
          showGNGuardianSheet(context, family);
        },
        onSetAside: () {
          ctx.track('set_aside', family.id);
          ctx.setStage(ward, family, GNStage.setAside);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Set aside — restore anytime from the list below.'),
              duration: Duration(seconds: 2),
            ),
          );
          ctx.advance();
        },
        onRequest: () => _showRequestSheet(context, ward, family),
      );
    }

    // Draft 3.1 (Founder): the card takes the screen — the page lays out
    // to the full height and scrolls only when a small screen truly
    // cannot fit it. No dead area below the card.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          key: PageStorageKey('guardian-network-discover-${ward.id}'),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 112),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 116)
                  .clamp(0.0, double.infinity)
                  .toDouble(),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chosen for ${ward.firstName}',
                          style: ZyraText.heading(size: 19),
                        ),
                      ),
                      Text(
                        'ONE FAMILY AT A TIME',
                        style: ZyraText.chapterLabel(color: Colors.white38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The algorithm serves eligible families — there is nothing to browse or search.',
                    style: ZyraText.subtext(size: 11.5),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: stage),
                  if (setAsideCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Center(
                        child: TextButton(
                          onPressed: () =>
                              _showSetAsideSheet(context, ward, fams),
                          child: Text(
                            'Set aside ($setAsideCount) — restore ›',
                            style: ZyraText.subtext(
                              size: 11.5,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Preview fields and families are PROVISIONAL mock data. No action on this page changes live data.',
                      textAlign: TextAlign.center,
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
        );
      },
    );
  }

  // ── page-local sheets (Rung 1 request · set-aside pile) ─────────────────
  void _showRequestSheet(
    BuildContext context,
    WaliLinkedPerson ward,
    GNFamily family,
  ) {
    final ctx = GNContext.instance;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GNSheetShell(
        title: 'HOW REQUEST CONNECTION WORKS',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your request goes to their Main Wali — and to no one else.\n\n'
              '· They may quietly not respond; after 14 days it simply becomes "No longer active". Nobody is shown a refusal.\n'
              '· If they choose "Connect with this family", both Walis unlock each other\'s profiles and a structured exchange.\n'
              '· The Seekers see nothing until BOTH Walis choose "Proceed to the Seekers" — then both see it at the same moment.\n'
              '· ${ward.firstName} can have at most 3 live processes.',
              style: ZyraText.body(size: 12.5, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  ctx.track('request_sent', family.id);
                  ctx.setStage(ward, family, GNStage.sent);
                  ctx.advance();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: ZyraColors.primaryAction,
                  foregroundColor: ZyraColors.onPrimaryAction,
                  minimumSize: const Size.fromHeight(44),
                ),
                child: Text(
                  'Request connection',
                  style: ZyraText.button(
                    size: 13,
                    color: ZyraColors.onPrimaryAction,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(
                  'Not yet',
                  style: ZyraText.subtext(size: 12, color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetAsideSheet(
    BuildContext context,
    WaliLinkedPerson ward,
    List<GNFamily> fams,
  ) {
    final ctx = GNContext.instance;
    final aside = fams
        .where((f) => ctx.stageOf(ward, f) == GNStage.setAside)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GNSheetShell(
        title: 'SET ASIDE — RESTORE ANYTIME',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in aside)
              ListTile(
                leading: GNFamilySeal(family: f, size: 36, showPhoto: false),
                title: Text(
                  f.display,
                  style: ZyraText.body(size: 13.5, color: Colors.white),
                ),
                subtitle: Text(
                  'May be served again after 30 days while eligible',
                  style: ZyraText.subtext(size: 10),
                ),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    ctx.track('restored', f.id);
                    ctx.setStage(ward, f, GNStage.none);
                  },
                  child: Text(
                    'Restore',
                    style: ZyraText.button(size: 12, color: gnGold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Discover cards (page-local) ─────────────────────────────────────────────

class _ServedFamilyCard extends StatelessWidget {
  const _ServedFamilyCard({
    required this.family,
    required this.isMainWali,
    required this.onView,
    required this.onGuardian,
    required this.onSetAside,
    required this.onRequest,
  });
  final GNFamily family;
  final bool isMainWali;
  final VoidCallback onView;
  final VoidCallback onGuardian;
  final VoidCallback onSetAside;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final showPhoto = family.photoLevel == GNPhotoLevel.card; // Rule 34
    return Container(
      key: Key('gn-served-${family.id}'),
      padding: const EdgeInsets.all(ZyraCardMetrics.padding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(color: gnGold.withValues(alpha: 0.35), width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Draft 3.1: the card fills its page — Spacers distribute what
          // used to be dead space below it, so it reads as one composed
          // surface with the actions resting at the bottom.
          const Spacer(),
          GNFamilySeal(family: family, size: 116, showPhoto: showPhoto),
          const SizedBox(height: 12),
          Text(family.display, style: ZyraText.heading(size: 22)),
          const SizedBox(height: 4),
          Text(family.region, style: ZyraText.subtext(size: 12.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: gnGold.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Text(
              family.band,
              style: ZyraText.chapterLabel(color: gnGold).copyWith(fontSize: 8),
            ),
          ),
          if (!showPhoto)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                family.photoLevel == GNPhotoLevel.afterConnect
                    ? 'Photo is shared after the Walis connect'
                    : 'No photo is shared in Guardian Network',
                style: ZyraText.subtext(size: 10, color: Colors.white38),
              ),
            ),
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final reason in family.reasons)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    reason,
                    style: ZyraText.subtext(size: 10.5, color: Colors.white70),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          GestureDetector(
            onTap: onGuardian,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 7,
                runSpacing: 4,
                children: [
                  Text(
                    family.guardianLabel,
                    style: ZyraText.subtext(size: 11, color: Colors.white70),
                  ),
                  const GNVerifiedBadge(),
                  Text(
                    'View Guardian ›',
                    style: ZyraText.subtext(size: 10.5, color: gnGold),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: GNActionPill(label: 'View', onTap: onView),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: GNActionPill(label: 'Set aside', onTap: onSetAside),
              ),
              const SizedBox(width: 7),
              Expanded(
                flex: 2,
                child: GNActionPill(
                  label: isMainWali
                      ? 'Request connection'
                      : 'Ask Main Wali', // Rule 37
                  primary: true,
                  enabled: isMainWali,
                  onTap: onRequest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MergeCard extends StatelessWidget {
  const _MergeCard({required this.family, required this.onReview});
  final GNFamily family;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('gn-merge-${family.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gnGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(color: gnGold.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Column(
        children: [
          GNFamilySeal(family: family, size: 64, showPhoto: false),
          const SizedBox(height: 10),
          Text(
            'This family has already requested connection.',
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 14, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(
            '${family.display} · ${family.guardianLabel.toLowerCase()} — their request is waiting for you, here and on your Dashboard. One process per pair (Rule 24).',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GNActionPill(
              label: 'Review request',
              primary: true,
              onTap: onReview,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapReachedCard extends StatelessWidget {
  const _CapReachedCard({required this.live});
  final int live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(color: gnGold.withValues(alpha: 0.4), width: 0.7),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_top_outlined,
            size: 26,
            color: Colors.white54,
          ),
          const SizedBox(height: 8),
          Text('$live of 3 live processes', style: ZyraText.heading(size: 16)),
          const SizedBox(height: 5),
          Text(
            'Each family deserves proper attention. Close or complete one of your live processes before starting another — the cap is the same on every plan.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 11.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Manage them from your Dashboard — everything about your Seekers lives there.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 10.5, color: gnGold),
          ),
        ],
      ),
    );
  }
}
