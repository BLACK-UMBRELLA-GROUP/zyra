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

import 'package:flutter/material.dart';
import '../../data/zyra_membership_catalog.dart';
import '../../dev/zyra_app_gold_preview.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../services/zyra_entitlement_service.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_promotion_engine.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_card_metrics.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_profile_image.dart';
import '../../widgets/zyra_pull_down_back_scope.dart';
import '../../widgets/zyra_segmented_toggle.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../subscription/upgrade_screen.dart';
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
  bool _hasLinkedSeeker = false;

  final PageController _modePager = PageController();
  double _modePosition = 0;

  void _onModeScroll() {
    if (!_modePager.hasClients || _modePager.page == null) return;
    final next = _modePager.page!;
    if ((next - _modePosition).abs() < 0.001) return;
    setState(() => _modePosition = next);
  }

  @override
  void initState() {
    super.initState();
    _modePager.addListener(_onModeScroll);
    AppState.instance.addListener(_onChange);
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      _loading = false;
      // Founder fix 2026-08-23: rebuild when the dev-scenario store changes
      // (seeker composition edited in the side panel).
      ZyraDevScenario.instance.addListener(_onChange);
      // Draft 3: the shared GN state — seeker selection, stages, scenes —
      // lives in GNContext so this page and the Dashboard stay in step.
      GNContext.instance.addListener(_onChange);
      ZyraPromotionEngine.instance.addListener(_onChange);
    } else {
      _loadAccess();
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
    ZyraPromotionEngine.instance.removeListener(_onChange);
    _modePager.removeListener(_onModeScroll);
    _modePager.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAccess() async {
    final results = await Future.wait<dynamic>([
      ZyraEntitlementService.hasWaliOne(),
      ZyraWaliLinkService.fetchLinkedPeople(asWali: true),
    ]);
    if (mounted) {
      setState(() {
        _hasExtended = results[0] as bool;
        _hasLinkedSeeker = (results[1] as List<WaliLinkedPerson>).isNotEmpty;
        _loading = false;
      });
    }
  }

  // ── build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      switch (ZyraPromotionEngine.instance.developerGuardianNetworkState) {
        case ZyraDeveloperGuardianNetworkState.d14Preview:
          return _buildD14Preview(context);
        case ZyraDeveloperGuardianNetworkState.unlinkedBasic:
          return _buildAccessView(
            hasEntitlement: false,
            hasLinkedSeeker: false,
          );
        case ZyraDeveloperGuardianNetworkState.linkedBasic:
          return _buildAccessView(hasEntitlement: false, hasLinkedSeeker: true);
        case ZyraDeveloperGuardianNetworkState.unlinkedEntitled:
          return _buildAccessView(hasEntitlement: true, hasLinkedSeeker: false);
        case ZyraDeveloperGuardianNetworkState.linkedEntitledUnavailable:
          return _buildAccessView(hasEntitlement: true, hasLinkedSeeker: true);
      }
    }

    return _buildAccessView(
      hasEntitlement: _hasExtended,
      hasLinkedSeeker: _hasLinkedSeeker,
      loading: _loading,
    );
  }

  // ── production access matrix (DR-ZYRA-213) ──────────────────────────────
  Widget _buildAccessView({
    required bool hasEntitlement,
    required bool hasLinkedSeeker,
    bool loading = false,
  }) {
    return Container(
      decoration: ZyraAppGoldDecoration(
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
            if (loading)
              const Expanded(child: ZyraLoading())
            else
              Expanded(
                child: GuardianNetworkAccessView(
                  hasEntitlement: hasEntitlement,
                  hasLinkedSeeker: hasLinkedSeeker,
                  onLinkSeeker: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WaliInviteSeekerScreen(),
                    ),
                  ),
                  onMembership: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UpgradeScreen(
                        telemetrySurface: ZyraTelemetrySurface.guardian,
                      ),
                    ),
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
    final families = selected == null
        ? const <GNFamily>[]
        : ctx.familiesFor(wards, selected);
    final sent = selected == null
        ? 0
        : ctx.previewCountFor(GNNetworkPreviewArea.sent) ??
              ctx.sentCount(selected, families);
    final received = selected == null
        ? 0
        : ctx.previewCountFor(GNNetworkPreviewArea.received) ??
              ctx.incomingCount(selected, families);

    return Container(
      key: const Key('guardian-network-preview'),
      decoration: ZyraAppGoldDecoration(gradient: ZyraColors.brandGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Row(
                key: const Key('gn-network-title-row'),
                children: [
                  Text('Network', style: ZyraText.heading(size: 26)),
                  const Spacer(),
                  if (selected != null)
                    _NetworkSeekerDropdown(wards: wards, selected: selected),
                ],
              ),
            ),
            if (selected != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: ZyraSegmentedToggle(
                  labels: const ['Profiles', 'Sent requests', 'Received'],
                  position: _modePosition.clamp(0.0, 2.0),
                  badges: [0, sent, received],
                  labelSize: 10.5,
                  segmentKeys: const [
                    Key('gn-mode-browser'),
                    Key('gn-mode-sent'),
                    Key('gn-mode-received'),
                  ],
                  onChanged: (i) =>
                      ZyraSegmentedMotion.animateToPage(_modePager, i),
                ),
              ),
              // Keep a visible boundary even when the card list scrolls;
              // this is shared by Browser, Sent and Received and all five
              // card treatments. Expanded body/cards shorten by the same
              // amount, preserving the existing bottom navigation clearance.
              const SizedBox(height: 16),
            ],
            Expanded(
              child: selected == null
                  ? _buildNoSeeker(context)
                  : PageView(
                      key: const Key('gn-mode-page-view'),
                      controller: _modePager,
                      physics: ZyraSegmentedMotion.pagePhysics,
                      children: [
                        _buildDiscover(context, wards, selected),
                        _buildRequests(
                          context,
                          wards: wards,
                          ward: selected,
                          kind: GNNetworkRequestKind.sent,
                        ),
                        _buildRequests(
                          context,
                          wards: wards,
                          ward: selected,
                          kind: GNNetworkRequestKind.received,
                        ),
                      ],
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
    // blank state — the large + and one short line. Founder follow-up:
    // centre it in the usable page, above the floating navigation. No bar
    // above it, no paragraph, no pill button.
    return Padding(
      padding: const EdgeInsets.only(bottom: 96),
      child: Center(
        child: ZyraAddCircle(
          label: 'Invite your Seeker',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WaliInviteSeekerScreen()),
          ),
        ),
      ),
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
      return Center(
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
    final countOverride = ctx.previewCountFor(GNNetworkPreviewArea.browser);
    final nextFamily = ctx.servedFamily(ward, fams);
    final served = ctx.scene == GNScene.empty
        ? const <GNFamily>[]
        : countOverride == null
        ? nextFamily == null
              ? const <GNFamily>[]
              : <GNFamily>[nextFamily]
        : fams.take(countOverride).toList();
    if (capped) {
      return _buildNetworkState(
        ward: ward,
        child: Center(child: _CapReachedCard(live: live)),
      );
    }
    if (served.isEmpty) {
      return _buildNetworkState(
        ward: ward,
        child: Center(
          child: ZyraEmptyState(
            icon: Icons.person_search_outlined,
            title: 'No suitable families right now',
            message:
                'Nothing currently fits this Seeker\'s requirements and availability. ZYRA keeps looking without widening their choices.',
          ),
        ),
      );
    }

    return _buildNetworkFamilyList(
      ward: ward,
      families: served,
      mode: _NetworkCardMode.browser,
      cardBuilder: (family) => _NetworkFamilyCard(
        family: family,
        mode: _NetworkCardMode.browser,
        isMainWali: ctx.isMainWali,
        actionLayout: ctx.networkActionLayout,
        onViewProfile: () {
          ctx.track('card_viewed', family.id);
          showGNProfileSheet(context, family, rung2: false);
        },
        onNext: () {
          ctx.track('family_next', family.id);
          ctx.setStage(ward, family, GNStage.setAside);
          ctx.advance();
        },
        onRequest: () => _showRequestSheet(context, ward, family),
      ),
    );
  }

  Widget _buildRequests(
    BuildContext context, {
    required List<WaliLinkedPerson> wards,
    required WaliLinkedPerson ward,
    required GNNetworkRequestKind kind,
  }) {
    final ctx = GNContext.instance;
    final all = ctx.familiesFor(wards, ward);
    final area = kind == GNNetworkRequestKind.sent
        ? GNNetworkPreviewArea.sent
        : GNNetworkPreviewArea.received;
    final countOverride = ctx.previewCountFor(area);
    final requests = countOverride == null
        ? all.where((family) {
            final stage = ctx.stageOf(ward, family);
            return kind == GNNetworkRequestKind.sent
                ? stage == GNStage.sent
                : stage == GNStage.incoming;
          }).toList()
        : all.take(countOverride).toList();

    if (!ctx.isMainWali) {
      return _buildNetworkState(
        ward: ward,
        storageSuffix: kind.name,
        child: Center(
          child: GNQuietNotice(
            icon: Icons.shield_outlined,
            title: 'Handled by the Main Guardian',
            message:
                'Only the Main Guardian manages requests for ${ward.firstName}.',
          ),
        ),
      );
    }
    if (requests.isEmpty) {
      return _buildNetworkState(
        ward: ward,
        storageSuffix: kind.name,
        child: Center(
          child: ZyraEmptyState(
            icon: kind == GNNetworkRequestKind.sent
                ? Icons.outbox_outlined
                : Icons.mark_email_unread_outlined,
            title: kind == GNNetworkRequestKind.sent
                ? 'No sent requests'
                : 'No received requests',
            message: kind == GNNetworkRequestKind.sent
                ? 'Requests you send for ${ward.firstName} will appear here.'
                : 'Requests another family sends for ${ward.firstName} will appear here.',
          ),
        ),
      );
    }

    final mode = kind == GNNetworkRequestKind.sent
        ? _NetworkCardMode.sent
        : _NetworkCardMode.received;
    final capped = ctx.liveCount(ward, all) >= 3;
    return _buildNetworkFamilyList(
      ward: ward,
      families: requests,
      mode: mode,
      cardBuilder: (family) => _NetworkFamilyCard(
        family: family,
        mode: mode,
        isMainWali: true,
        connectionCapped: capped,
        onViewProfile: () {
          ctx.track('card_viewed', family.id);
          showGNProfileSheet(context, family, rung2: false);
        },
        onWithdraw: () {
          ctx.track('request_withdrawn', family.id);
          ctx.setStage(ward, family, GNStage.closed);
        },
        onGuardian: () {
          ctx.track('guardian_viewed', family.id);
          showGNGuardianSheet(context, family);
        },
        onConnect: () {
          if (capped) return;
          ctx.track('connected', family.id);
          ctx.setStage(ward, family, GNStage.connected);
        },
        onNotForUs: () {
          ctx.track('not_for_us', family.id);
          ctx.setStage(ward, family, GNStage.closed);
        },
      ),
    );
  }

  Widget _buildNetworkState({
    required WaliLinkedPerson ward,
    required Widget child,
    String storageSuffix = 'discover',
  }) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      key: PageStorageKey('guardian-network-$storageSuffix-${ward.id}'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 84),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - 88)
              .clamp(0.0, double.infinity)
              .toDouble(),
        ),
        child: child,
      ),
    ),
  );

  Widget _buildNetworkFamilyList({
    required WaliLinkedPerson ward,
    required List<GNFamily> families,
    required _NetworkCardMode mode,
    required Widget Function(GNFamily family) cardBuilder,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final cardHeight = (constraints.maxHeight - 88)
          .clamp(510.0, 720.0)
          .toDouble();
      return SingleChildScrollView(
        key: PageStorageKey('guardian-network-${mode.name}-${ward.id}'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 84),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < families.length; index++) ...[
              SizedBox(height: cardHeight, child: cardBuilder(families[index])),
              if (index != families.length - 1) const SizedBox(height: 24),
            ],
          ],
        ),
      );
    },
  );

  // ── page-local request surface (Rung 1) ──────────────────────────────────
  void _showRequestSheet(
    BuildContext context,
    WaliLinkedPerson ward,
    GNFamily family,
  ) {
    final ctx = GNContext.instance;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _GuardianRequestPage(
          family: family,
          onSend: () {
            ctx.track('request_sent', family.id);
            ctx.setStage(ward, family, GNStage.sent);
            ctx.advance();
          },
        ),
      ),
    );
  }
}

class _NetworkSeekerDropdown extends StatelessWidget {
  const _NetworkSeekerDropdown({required this.wards, required this.selected});

  final List<WaliLinkedPerson> wards;
  final WaliLinkedPerson selected;

  Future<void> _showPicker(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final availableHeight =
            (MediaQuery.sizeOf(sheetContext).height * 0.46 - 90)
                .clamp(112.0, 420.0)
                .toDouble();
        final listHeight = (wards.length * 80.0)
            .clamp(112.0, availableHeight)
            .toDouble();
        return GNSheetShell(
          title: 'CHOOSE SEEKER',
          child: SizedBox(
            key: const Key('gn-seeker-picker-sheet'),
            height: listHeight,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: wards.length,
              separatorBuilder: (_, index) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final ward = wards[index];
                final isSelected = ward.id == selected.id;
                return Material(
                  color: isSelected
                      ? gnGold.withValues(alpha: 0.12)
                      : ZyraColors.surfaceFill,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    key: Key('gn-seeker-dropdown-${ward.id}'),
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => Navigator.of(sheetContext).pop(ward.id),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? gnGold.withValues(alpha: 0.42)
                              : ZyraColors.surfaceBorder,
                          width: 0.7,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ZyraColors.iconButtonBg,
                              border: Border.all(
                                color: isSelected
                                    ? gnGold.withValues(alpha: 0.55)
                                    : ZyraColors.iconButtonBorder,
                              ),
                            ),
                            child: Text(
                              ward.firstName.isEmpty
                                  ? '?'
                                  : ward.firstName.characters.first,
                              style: ZyraText.body(
                                size: 13,
                                color: ZyraColors.foreground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(child: GNSeekerPickerIdentity(person: ward)),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              size: 19,
                              color: gnGold,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
    if (chosen != null) GNContext.instance.selectSeeker(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('gn-seeker-dropdown'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _showPicker(context),
      child: Container(
        key: const Key('gn-seeker-header-control'),
        padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.firstName,
              style: ZyraText.body(size: 14.5, color: ZyraColors.foreground),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: ZyraColors.foregroundSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardianRequestPage extends StatefulWidget {
  const _GuardianRequestPage({required this.family, required this.onSend});

  final GNFamily family;
  final VoidCallback onSend;

  @override
  State<_GuardianRequestPage> createState() => _GuardianRequestPageState();
}

class _GuardianRequestPageState extends State<_GuardianRequestPage> {
  int _backRevision = 0;
  int _backEpoch = 0;
  bool _backTaken = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = ZyraBackNavigationPreview.revisionOf(context);
    if (revision != _backRevision) {
      _backRevision = revision;
      _backEpoch++;
      _backTaken = false;
    }
  }

  bool _currentReturn(int epoch) =>
      mounted &&
      epoch == _backEpoch &&
      !_backTaken &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  void _returnPage(int epoch) {
    if (!_currentReturn(epoch)) return;
    _backTaken = true;
    Navigator.of(context).maybePop();
  }

  void _sendRequest() {
    widget.onSend();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final epoch = _backEpoch;
    return Scaffold(
      // Dismissing the request page reveals the same live canvas family,
      // never an unrelated black strip behind the moving surface.
      backgroundColor: ZyraColors.brandGradient.colors.last,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final surface = GestureDetector(
            key: const Key('gn-request-page-swipe-surface'),
            behavior: HitTestBehavior.opaque,
            child: DecoratedBox(
              decoration: ZyraAppGoldDecoration(
                gradient: ZyraColors.genderGradient(AppState.instance.gender),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 62,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            'Speak to Guardian',
                            style: ZyraText.heading(size: 18),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: gnGold.withValues(alpha: 0.10),
                                border: Border.all(
                                  color: gnGold.withValues(alpha: 0.38),
                                ),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                size: 34,
                                color: gnGold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              widget.family.guardianLabel,
                              textAlign: TextAlign.center,
                              style: ZyraText.heading(size: 21),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Send a request to their Main Guardian?',
                              textAlign: TextAlign.center,
                              style: ZyraText.body(
                                size: 14,
                                color: ZyraColors.foregroundSecondary,
                              ),
                            ),
                            const Spacer(flex: 3),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                key: const Key('gn-request-page-send'),
                                onPressed: _sendRequest,
                                child: Text(
                                  'Send request',
                                  style: ZyraText.button(size: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Not yet',
                                style: ZyraText.subtext(
                                  size: 12,
                                  color: ZyraColors.foregroundMuted,
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
            ),
          );
          return ZyraPullDownCloseCue(
            enabled: !_backTaken,
            onBack: () => _returnPage(epoch),
            routeIdentity: (this, epoch),
            child: surface,
          );
        },
      ),
    );
  }
}

/// Privacy-safe Guardian Network access matrix. This widget receives already
/// resolved link/entitlement truth and never performs either lookup itself,
/// which keeps the four product states deterministic and widget-testable.
class GuardianNetworkAccessView extends StatelessWidget {
  final bool hasEntitlement;
  final bool hasLinkedSeeker;
  final VoidCallback onLinkSeeker;
  final VoidCallback onMembership;

  const GuardianNetworkAccessView({
    super.key,
    required this.hasEntitlement,
    required this.hasLinkedSeeker,
    required this.onLinkSeeker,
    required this.onMembership,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const Key('guardian-network-access-state'),
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 112),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 130)
                .clamp(0, double.infinity)
                .toDouble(),
          ),
          child: Center(child: _content()),
        ),
      ),
    );
  }

  Widget _content() {
    if (!hasEntitlement) {
      return Column(
        key: Key(
          hasLinkedSeeker
              ? 'guardian-network-basic-linked'
              : 'guardian-network-basic-unlinked',
        ),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_rounded,
            key: const Key('guardian-network-content-lock'),
            color: ZyraColors.journeyGold,
            size: 32,
          ),
          SizedBox(height: 16),
          Text(
            'Network is part of ${ZyraMembershipCatalog.guardianOneTitle}',
            style: ZyraText.heading(size: 22),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 9),
          Text(
            'Guardian Network is not available in this build. You can view ${ZyraMembershipCatalog.guardianOneTitle} membership details below.',
            style: ZyraText.subtext(size: 13),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 22),
          _AccessButton(
            label: 'View ${ZyraMembershipCatalog.guardianOneTitle}',
            onTap: onMembership,
            icon: Icons.workspace_premium_outlined,
          ),
        ],
      );
    }

    if (!hasLinkedSeeker) {
      return Column(
        key: const Key('guardian-network-entitled-unlinked'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const _StatusPill(label: ZyraMembershipCatalog.guardianOneTitle),
          SizedBox(height: 18),
          Icon(
            Icons.person_add_alt_1_outlined,
            color: ZyraColors.ink(0.54),
            size: 32,
          ),
          SizedBox(height: 14),
          Text(
            'Link a Seeker first',
            style: ZyraText.heading(size: 21),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 9),
          Text(
            'Your ${ZyraMembershipCatalog.guardianOneTitle} access is active. Link the Seeker you support. Guardian Network is not available in this build.',
            style: ZyraText.subtext(size: 13),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 22),
          _AccessButton(label: 'Link a Seeker', onTap: onLinkSeeker),
        ],
      );
    }

    if (hasEntitlement) {
      return Column(
        key: const Key('guardian-network-entitled-linked-unavailable'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const _StatusPill(label: ZyraMembershipCatalog.guardianOneTitle),
          SizedBox(height: 18),
          Icon(
            Icons.hourglass_top_rounded,
            color: ZyraColors.ink(0.54),
            size: 30,
          ),
          SizedBox(height: 14),
          Text(
            'Guardian Network is not available yet',
            style: ZyraText.heading(size: 20),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 9),
          Text(
            'Your access remains active. We will let you know when trusted family discovery is ready here.',
            style: ZyraText.subtext(size: 13),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    throw StateError('Unreachable Guardian Network access state');
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: ZyraColors.accentBg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: ZyraColors.accentBorder),
    ),
    child: Text(label, style: ZyraText.chapterLabel(color: gnGold)),
  );
}

class _AccessButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const _AccessButton({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: ZyraColors.accentBg,
        border: Border.all(color: ZyraColors.accentBorder),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: ZyraColors.journeyGold),
                  const SizedBox(width: 8),
                ],
                Text(label, style: ZyraText.button(size: 13)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ── One visual card system across Browser, Sent and Received ────────────────

enum _NetworkCardMode { browser, sent, received }

class _NetworkFamilyCard extends StatelessWidget {
  const _NetworkFamilyCard({
    required this.family,
    required this.mode,
    required this.isMainWali,
    required this.onViewProfile,
    this.actionLayout = GNNetworkActionLayout.current,
    this.connectionCapped = false,
    this.onNext,
    this.onRequest,
    this.onWithdraw,
    this.onGuardian,
    this.onConnect,
    this.onNotForUs,
  });
  final GNFamily family;
  final _NetworkCardMode mode;
  final bool isMainWali;
  final GNNetworkActionLayout actionLayout;
  final bool connectionCapped;
  final VoidCallback onViewProfile;
  final VoidCallback? onNext;
  final VoidCallback? onRequest;
  final VoidCallback? onWithdraw;
  final VoidCallback? onGuardian;
  final VoidCallback? onConnect;
  final VoidCallback? onNotForUs;

  @override
  Widget build(BuildContext context) => Container(
    key: Key(switch (mode) {
      _NetworkCardMode.browser => 'gn-served-${family.id}',
      _NetworkCardMode.sent => 'gn-sent-${family.id}',
      _NetworkCardMode.received => 'gn-incoming-${family.id}',
    }),
    child: _portraitFocus(),
  );

  Widget _portraitFocus() => Column(
    key: const Key('gn-card-design-portraitFocus'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onViewProfile,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(42),
              child: _NetworkFamilyPortrait(family: family),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        family.display,
        textAlign: TextAlign.center,
        style: ZyraText.heading(size: 25),
      ),
      const SizedBox(height: 2),
      Text(
        family.region,
        textAlign: TextAlign.center,
        style: ZyraText.subtext(size: 11.75),
      ),
      const SizedBox(height: 11),
      _guardianLine(),
      if (mode != _NetworkCardMode.browser) ...[
        const SizedBox(height: 8),
        _requestContext(),
      ],
      const SizedBox(height: 12),
      _actionArea(),
    ],
  );

  Widget _guardianLine() {
    final content = <Widget>[
      Icon(
        Icons.shield_outlined,
        size: 19,
        color: gnGold.withValues(alpha: 0.88),
      ),
      const SizedBox(width: 9),
      Flexible(
        child: Text(
          family.guardianLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ZyraText.body(size: 13.25),
        ),
      ),
      const SizedBox(width: 8),
      const GNVerifiedBadge(),
    ];
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: content);
  }

  Widget _requestContext() {
    final sent = mode == _NetworkCardMode.sent;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          sent ? Icons.schedule_outlined : Icons.mark_email_unread_outlined,
          size: 16,
          color: gnGold.withValues(alpha: 0.82),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            sent
                ? 'Request sent · Awaiting their Main Guardian'
                : 'Request received · Their Main Guardian is waiting',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZyraText.subtext(size: 10.5),
          ),
        ),
      ],
    );
  }

  // Layout comparisons apply only to Browser. Sent and Received keep their
  // request actions and their existing order; Next still sets a family aside.
  Widget _actionArea() {
    if (mode != _NetworkCardMode.browser ||
        actionLayout == GNNetworkActionLayout.current) {
      return Column(
        key: mode == _NetworkCardMode.browser
            ? const Key('gn-browser-actions-current')
            : null,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_actionPair(), const SizedBox(height: 7), _footerAction()],
      );
    }

    return Column(
      key: Key('gn-browser-actions-${actionLayout.name}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (actionLayout) {
        GNNetworkActionLayout.quietNext => [
          _actionPair(),
          const SizedBox(height: 7),
          Align(alignment: Alignment.centerRight, child: _quietNextAction()),
        ],
        GNNetworkActionLayout.speakFirst => [
          SizedBox(height: 44, child: _speakAction()),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(child: SizedBox(height: 44, child: _profileAction())),
              const SizedBox(width: 8),
              _quietNextAction(),
            ],
          ),
        ],
        GNNetworkActionLayout.profileFirst => [
          SizedBox(height: 44, child: _profileAction()),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(child: SizedBox(height: 44, child: _speakAction())),
              const SizedBox(width: 8),
              _quietNextAction(),
            ],
          ),
        ],
        GNNetworkActionLayout.current => throw StateError(
          'Current actions are built with the request-compatible layout.',
        ),
      },
    );
  }

  Widget _profileAction() => GNActionPill(
    key: const Key('gn-view-profile-action'),
    label: 'View profile',
    onTap: onViewProfile,
  );

  Widget _speakAction() => GNActionPill(
    key: const Key('gn-speak-action'),
    label: isMainWali ? 'Speak to Guardian' : 'Ask Main Guardian',
    goldAccent: true,
    enabled: isMainWali,
    onTap: onRequest ?? () {},
  );

  Widget _quietNextAction() => SizedBox(
    width: 88,
    height: 44,
    child: TextButton.icon(
      key: const Key('gn-next-action'),
      onPressed: onNext,
      style: TextButton.styleFrom(
        foregroundColor: ZyraColors.foreground.withValues(alpha: 0.72),
        textStyle: ZyraText.button(size: 11.5),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
      ),
      label: const Text('Next'),
      icon: const Icon(Icons.chevron_right_rounded, size: 16),
      iconAlignment: IconAlignment.end,
    ),
  );

  Widget _actionPair() {
    final second = switch (mode) {
      _NetworkCardMode.browser => _speakAction(),
      _NetworkCardMode.sent => GNActionPill(
        key: Key('gn-withdraw-${family.id}'),
        label: 'Withdraw request',
        onTap: onWithdraw ?? () {},
      ),
      _NetworkCardMode.received => GNActionPill(
        key: Key('gn-view-guardian-${family.id}'),
        label: 'View Guardian',
        goldAccent: true,
        onTap: onGuardian ?? () {},
      ),
    };
    return Row(
      children: [
        Expanded(
          child: mode == _NetworkCardMode.browser
              ? SizedBox(height: 44, child: _profileAction())
              : _profileAction(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: mode == _NetworkCardMode.browser
              ? SizedBox(height: 44, child: second)
              : second,
        ),
      ],
    );
  }

  Widget _footerAction() {
    return switch (mode) {
      _NetworkCardMode.browser => SizedBox(
        height: 44,
        child: GNActionPill(
          key: const Key('gn-next-action'),
          label: 'Next',
          borderless: true,
          onTap: onNext ?? () {},
        ),
      ),
      _NetworkCardMode.sent => SizedBox(
        height: 44,
        child: Center(
          child: Text(
            'Waiting for their family to respond',
            style: ZyraText.subtext(size: 11),
          ),
        ),
      ),
      _NetworkCardMode.received => SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: GNActionPill(
                key: Key('gn-not-for-us-${family.id}'),
                label: 'Not for us',
                borderless: true,
                onTap: onNotForUs ?? () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: GNActionPill(
                key: const Key('gn-connect-family-action'),
                label: connectionCapped ? 'Request limit reached' : 'Connect',
                goldAccent: true,
                enabled: !connectionCapped,
                onTap: onConnect ?? () {},
              ),
            ),
          ],
        ),
      ),
    };
  }
}

class _NetworkFamilyPortrait extends StatelessWidget {
  const _NetworkFamilyPortrait({required this.family});

  final GNFamily family;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const Key('gn-family-photo'),
      borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius + 2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ZyraProfileImage(family.photoUrl),
          if (family.photoUrl.isEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ZyraColors.royalPurple.withValues(alpha: 0.38),
                    ZyraColors.luxuryDarkPurple.withValues(alpha: 0.72),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  family.initial,
                  style: ZyraText.heading(
                    size: 82,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  ZyraColors.luxuryDarkPurple.withValues(alpha: 217 / 255),
                ],
                stops: [0.45, 1],
              ),
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
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(
          color: Color.alphaBlend(
            gnGold.withValues(alpha: 0.34),
            ZyraColors.surfaceBorder,
          ),
          width: 0.7,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_top_outlined,
            size: 26,
            color: ZyraColors.ink(0.54),
          ),
          SizedBox(height: 8),
          Text('$live of 3 live processes', style: ZyraText.heading(size: 16)),
          SizedBox(height: 5),
          Text(
            'Each family deserves proper attention. Close or complete one of your live processes before starting another — the cap is the same on every plan.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 11.5),
          ),
          SizedBox(height: 10),
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
