// GN DRAFT 2 — D14-RATIFIED interaction model (2026-08-23). Built to
// ZYRA_GN_BUILD_CONTRACT_CURRENT_VERSION_V1.md (Rules 1-44). All mock data
// in-file and PROVISIONAL (Rule 44); production path renders entitlement
// gate + empty states only; flutter analyze gated.

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
import '../../widgets/zyra_profile_image.dart';
import '../../widgets/zyra_segmented_toggle.dart';
import '../../widgets/zyra_state_widgets.dart';

// ── D14 PROVISIONAL mock model (Rule 44: in-file, dev-only) ─────────────────

enum _GNPhotoLevel { card, afterConnect, never } // Rule 34

enum _GNStage {
  none, // servable
  setAside, // Rule 19
  sent, // Rung 1 — awaiting their Wali
  incoming, // Rung 1 — their request awaiting us
  connected, // Rung 2
  proceedMine, // Rung 3 — we confirmed, awaiting them
  revealed, // Rung 4 — introduced to both Seekers
  closed, // Rule 27 — "No longer active"
}

enum _GNScene { standard, merge, capReached, empty, loading, error }

class _GNFamily {
  const _GNFamily({
    required this.id,
    required this.initial,
    required this.display,
    required this.region,
    required this.band,
    required this.guardianLabel,
    required this.photoLevel,
    required this.reasons,
    this.incomingAtStart = false,
    this.theirWaliConfirmed = false,
  });
  final String id;
  final String initial;
  final String display; // "H., 27" — initials only (Rule 12)
  final String region;
  final String band;
  final String guardianLabel;
  final _GNPhotoLevel photoLevel;
  final List<String> reasons;
  final bool incomingAtStart;
  final bool theirWaliConfirmed;
}

const _gnGold = Color(0xFFDEC979);

// PROVISIONAL mock families per ward index (Rule 44).
const List<_GNFamily> _gnFamiliesA = [
  _GNFamily(
    id: 'fam-h',
    initial: 'H',
    display: 'H., 27',
    region: 'West Midlands, UK',
    band: 'HIGH FIT',
    guardianLabel: 'Guided by her father',
    photoLevel: _GNPhotoLevel.card,
    reasons: ['Practising', 'Nearby region', 'High compatibility'],
  ),
  _GNFamily(
    id: 'fam-s',
    initial: 'S',
    display: 'S., 29',
    region: 'Yorkshire, UK',
    band: 'GOOD FIT',
    guardianLabel: 'Guided by her brother',
    photoLevel: _GNPhotoLevel.afterConnect,
    reasons: ['Within preferences', 'Also speaks Urdu'],
  ),
  _GNFamily(
    id: 'fam-t',
    initial: 'T',
    display: 'T., 26',
    region: 'North West, UK',
    band: 'GOOD FIT',
    guardianLabel: 'Guided by her uncle',
    photoLevel: _GNPhotoLevel.never,
    reasons: ['Practising', 'Within preferences'],
  ),
  _GNFamily(
    id: 'fam-m',
    initial: 'M',
    display: 'M., 31',
    region: 'Greater London, UK',
    band: 'HIGH FIT',
    guardianLabel: 'Guided by his father',
    photoLevel: _GNPhotoLevel.afterConnect,
    reasons: ['High compatibility', 'Practising'],
    incomingAtStart: true,
    theirWaliConfirmed: true,
  ),
];

const List<_GNFamily> _gnFamiliesB = [
  _GNFamily(
    id: 'fam-k',
    initial: 'K',
    display: 'K., 31',
    region: 'Greater London, UK',
    band: 'HIGH FIT',
    guardianLabel: 'Guided by his father',
    photoLevel: _GNPhotoLevel.afterConnect,
    reasons: ['Practising', 'High compatibility'],
  ),
  _GNFamily(
    id: 'fam-r',
    initial: 'R',
    display: 'R., 28',
    region: 'South East, UK',
    band: 'GOOD FIT',
    guardianLabel: 'Guided by his uncle',
    photoLevel: _GNPhotoLevel.never,
    reasons: ['Within preferences', 'Nearby region'],
  ),
];

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

  // PROVISIONAL MOCK STATE FOR THE D14 DEV PREVIEW (Rule 44)
  bool _devHasExtended = false;
  _GNScene _scene = _GNScene.standard;
  bool _isMainWali = true; // Rule 37 dev toggle
  bool _choosing = false; // Rule 23: algorithm-serve transition
  final Map<String, _GNStage> _stage = {};
  final List<String> _analytics = []; // Rule 41 PROVISIONAL tracker

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    _pager.addListener(_onPagerScroll);
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      _loading = false;
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

  // ── Rule 41: PROVISIONAL analytics tracker ──────────────────────────────
  void _track(String event, [String detail = '']) {
    final line = detail.isEmpty ? event : '$event · $detail';
    _analytics.add(line);
    if (kDebugMode) {
      debugPrint('[GN-ANALYTICS] $line');
    }
  }

  // ── mock helpers ────────────────────────────────────────────────────────
  List<_GNFamily> _familiesFor(int wardIndex) =>
      wardIndex.isEven ? _gnFamiliesA : _gnFamiliesB;

  String _key(WaliLinkedPerson ward, _GNFamily f) => '${ward.id}/${f.id}';

  _GNStage _stageOf(WaliLinkedPerson ward, _GNFamily f) {
    final s = _stage[_key(ward, f)];
    if (s != null) return s;
    return f.incomingAtStart ? _GNStage.incoming : _GNStage.none;
  }

  void _setStage(WaliLinkedPerson ward, _GNFamily f, _GNStage s) {
    setState(() => _stage[_key(ward, f)] = s);
  }

  int _liveCount(WaliLinkedPerson ward, List<_GNFamily> fams) {
    var n = 0;
    for (final f in fams) {
      final s = _stageOf(ward, f);
      if (s == _GNStage.sent ||
          s == _GNStage.connected ||
          s == _GNStage.proceedMine) {
        n++;
      }
    }
    return n; // Rule 40
  }

  _GNFamily? _servedFamily(WaliLinkedPerson ward, List<_GNFamily> fams) {
    for (final f in fams) {
      final s = _stageOf(ward, f);
      if (s == _GNStage.none) return f;
      if (s == _GNStage.incoming) return f; // Rule 24 merge card
    }
    return null;
  }

  void _advance() {
    // Rule 23: the algorithm chooses the next family; brief transition.
    setState(() => _choosing = true);
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _choosing = false);
    });
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
                  labels: const ['Discover', 'Connections'],
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
                            'Connection requests from other families will appear here.',
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

  // ── D14 preview (developer tools only) ──────────────────────────────────
  Widget _buildD14Preview(BuildContext context) {
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
    final fams = _familiesFor(wardIndex);
    final incomingCount = selected == null
        ? 0
        : fams.where((f) => _stageOf(selected!, f) == _GNStage.incoming).length;

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
                          'Nothing reaches a Seeker until both Walis agree.',
                          style: ZyraText.subtext(size: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const _PreviewMarker(),
                ],
              ),
            ),
            // 2E chrome: Seeker avatar button beside the view slider.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Row(
                children: [
                  _SeekerAvatarButton(
                    ward: selected,
                    onTap: wards.length <= 1
                        ? null
                        : () => _showSeekerSheet(context, wards),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZyraSegmentedToggle(
                      labels: [
                        'Discover',
                        incomingCount > 0
                            ? 'Connections · $incomingCount'
                            : 'Connections',
                      ],
                      position: _pagerPos,
                      labelSize: 13,
                      onChanged: (i) => _pager.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pager,
                children: [
                  _buildDiscover(context, wards, selected, fams),
                  _buildConnections(context, selected, fams),
                ],
              ),
            ),
            if (kDebugMode) _buildDevPanel(context),
          ],
        ),
      ),
    );
  }

  // ── Discover (Rung 0, Rules 22-24) ──────────────────────────────────────
  Widget _buildDiscover(
    BuildContext context,
    List<WaliLinkedPerson> wards,
    WaliLinkedPerson? selected,
    List<_GNFamily> fams,
  ) {
    if (wards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 112),
        child: _NetworkContextNotice(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Link a Seeker first',
          message:
              'Guardian Network always works on behalf of one linked Seeker. Add one in the developer panel to preview this context.',
        ),
      );
    }
    if (selected == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 112),
        child: _NetworkContextNotice(
          icon: Icons.touch_app_outlined,
          title: 'Choose a Seeker',
          message:
              'Select who you are searching for before ZYRA serves any families. Each Seeker has a separate, private context.',
        ),
      );
    }
    if (_scene == _GNScene.loading || _choosing) {
      return const Center(
        child: ZyraLoading(label: 'ZYRA is choosing the next family…'),
      );
    }
    if (_scene == _GNScene.error) {
      return Center(
        child: SizedBox(
          height: 330,
          child: ZyraUnknownErrorState(
            onRetry: () => setState(() => _scene = _GNScene.standard),
          ),
        ),
      );
    }

    final live = _liveCount(selected, fams);
    final capped = _scene == _GNScene.capReached || live >= 3;
    final served =
        _scene == _GNScene.empty ? null : _servedFamily(selected, fams);
    final setAsideCount =
        fams.where((f) => _stageOf(selected, f) == _GNStage.setAside).length;

    return ListView(
      key: const PageStorageKey('guardian-network-discover'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 112),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Chosen for ${selected.firstName}',
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
        if (capped)
          _CapReachedCard(
            live: live,
            onManage: () => _pager.animateToPage(
              1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            ),
          )
        else if (served == null)
          const SizedBox(
            height: 300,
            child: ZyraEmptyState(
              icon: Icons.person_search_outlined,
              title: 'No suitable families right now',
              message:
                  'Nothing currently fits this Seeker\'s requirements and availability. ZYRA keeps looking without widening their choices.',
            ),
          )
        else if (_stageOf(selected, served) == _GNStage.incoming ||
            _scene == _GNScene.merge)
          _MergeCard(
            family: served,
            onReview: () {
              _track('incoming_reviewed', served.id);
              _pager.animateToPage(
                1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
              );
            },
          )
        else
          _ServedFamilyCard(
            family: served,
            isMainWali: _isMainWali,
            onView: () {
              _track('card_viewed', served.id);
              _showProfileSheet(context, selected, served, rung2: false);
            },
            onGuardian: () {
              _track('guardian_viewed', served.id);
              _showGuardianSheet(context, served);
            },
            onSetAside: () {
              _track('set_aside', served.id);
              _setStage(selected, served, _GNStage.setAside);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Set aside — restore anytime from the list below.'),
                  duration: Duration(seconds: 2),
                ),
              );
              _advance();
            },
            onRequest: () => _showRequestSheet(context, selected, served),
          ),
        if (setAsideCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Center(
              child: TextButton(
                onPressed: () => _showSetAsideSheet(context, selected, fams),
                child: Text(
                  'Set aside ($setAsideCount) — restore ›',
                  style: ZyraText.subtext(size: 11.5, color: Colors.white54),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Preview fields and families are PROVISIONAL mock data. No action on this page changes live data.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 10.5, color: Colors.white38),
          ),
        ),
      ],
    );
  }

  // ── Connections (Rules 24-32, 37) ───────────────────────────────────────
  Widget _buildConnections(
    BuildContext context,
    WaliLinkedPerson? selected,
    List<_GNFamily> fams,
  ) {
    if (selected == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 112),
        child: ZyraEmptyState(
          icon: Icons.person_add_alt_1_outlined,
          title: 'No Seeker selected',
          message: 'Choose a Seeker before reviewing Network activity.',
        ),
      );
    }
    if (!_isMainWali) {
      // Rule 37: Additional Guardians see neutral status only.
      final live = _liveCount(selected, fams);
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 112),
        child: ZyraEmptyState(
          icon: Icons.shield_outlined,
          title: 'Handled by the Main Wali',
          message:
              '$live live process(es) for ${selected.firstName} are handled by the Main Wali. Additional Guardians advise the family — they do not see the other family\'s details.',
        ),
      );
    }

    final incoming =
        fams.where((f) => _stageOf(selected, f) == _GNStage.incoming).toList();
    final sent =
        fams.where((f) => _stageOf(selected, f) == _GNStage.sent).toList();
    final connected = fams
        .where((f) =>
            _stageOf(selected, f) == _GNStage.connected ||
            _stageOf(selected, f) == _GNStage.proceedMine ||
            _stageOf(selected, f) == _GNStage.revealed)
        .toList();
    final closed =
        fams.where((f) => _stageOf(selected, f) == _GNStage.closed).toList();
    final live = _liveCount(selected, fams);

    if (incoming.isEmpty && sent.isEmpty && connected.isEmpty && closed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 112),
        child: ZyraEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No connections yet',
          message:
              'Requests you send, requests other families send for ${selected.firstName}, and connected Walis all appear here.',
        ),
      );
    }

    return ListView(
      key: const PageStorageKey('guardian-network-connections'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'For ${selected.firstName}',
                style: ZyraText.heading(size: 19),
              ),
            ),
            Text(
              '$live OF 3 LIVE',
              style: ZyraText.chapterLabel(
                color: live >= 3 ? _gnGold : Colors.white38,
              ),
            ),
          ],
        ),
        if (incoming.isNotEmpty) ...[
          _sectionLabel('INCOMING — OLDEST FIRST'),
          for (final f in incoming)
            _IncomingCard(
              ward: selected,
              family: f,
              capped: live >= 3,
              onGuardian: () {
                _track('guardian_viewed', f.id);
                _showGuardianSheet(context, f);
              },
              onConnect: () {
                _track('connected', f.id);
                _setStage(selected, f, _GNStage.connected);
              },
              onNotForUs: () {
                _track('not_for_us', f.id);
                _setStage(selected, f, _GNStage.closed);
              },
            ),
        ],
        if (sent.isNotEmpty) ...[
          _sectionLabel('SENT'),
          for (final f in sent)
            _SentCard(
              family: f,
              onWithdraw: () {
                _track('request_withdrawn', f.id);
                _setStage(selected, f, _GNStage.closed);
              },
            ),
        ],
        if (connected.isNotEmpty) ...[
          _sectionLabel('CONNECTED'),
          for (final f in connected)
            _ConnectedCard(
              ward: selected,
              family: f,
              stage: _stageOf(selected, f),
              onGuardian: () {
                _track('guardian_viewed', f.id);
                _showGuardianSheet(context, f);
              },
              onProfile: () {
                _track('card_viewed', '${f.id} rung2');
                _showProfileSheet(context, selected, f, rung2: true);
              },
              onWithdraw: () {
                _track('request_withdrawn', f.id);
                _setStage(selected, f, _GNStage.closed);
              },
              onProceed: () {
                if (f.theirWaliConfirmed) {
                  _track('proceed_confirmed', f.id);
                  _track('introduction_revealed', f.id);
                  _setStage(selected, f, _GNStage.revealed);
                } else {
                  _track('proceed_confirmed', f.id);
                  _setStage(selected, f, _GNStage.proceedMine);
                }
              },
            ),
        ],
        if (closed.isNotEmpty) ...[
          _sectionLabel('HISTORY'),
          for (final f in closed) _ClosedRow(family: f),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'Closures show only "No longer active" — one neutral state for every cause. Seeker-side progress after an introduction lives on the Guardian Dashboard.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 10.5, color: Colors.white38),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Text(text, style: ZyraText.chapterLabel(color: Colors.white54)),
    );
  }

  // ── sheets ──────────────────────────────────────────────────────────────
  void _showSeekerSheet(BuildContext context, List<WaliLinkedPerson> wards) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SheetShell(
        title: 'SEARCHING ON BEHALF OF',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final ward in wards)
              ListTile(
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _selectedSeekerId = ward.id);
                },
                leading: _InitialCircle(text: ward.firstName),
                title: Text(
                  ward.firstName,
                  style: ZyraText.body(size: 14, color: Colors.white),
                ),
                trailing: ward.id == _selectedSeekerId
                    ? const Icon(Icons.check, size: 16, color: _gnGold)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  void _showGuardianSheet(BuildContext context, _GNFamily family) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SheetShell(
        title: 'THE OTHER GUARDIAN',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _InitialCircle(text: 'G', size: 44, gold: true),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.guardianLabel,
                        style: ZyraText.body(size: 14.5, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Main Guardian · represents 1 Seeker',
                        style: ZyraText.subtext(size: 11),
                      ),
                    ],
                  ),
                ),
                const _VerifiedBadge(),
              ],
            ),
            const SizedBox(height: 12),
            _factRow('Verification', 'ID verified · 2026'),
            _factRow('Region', family.region),
            const SizedBox(height: 10),
            Text(
              'PROVISIONAL field set — the Guardian-profile contents are a pending Founder decision. No free text (D6); no responsiveness indicators (Rule 29).',
              style: ZyraText.subtext(size: 10, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _factRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ZyraText.subtext(size: 11.5))),
          Text(value, style: ZyraText.body(size: 12, color: Colors.white)),
        ],
      ),
    );
  }

  void _showProfileSheet(
    BuildContext context,
    WaliLinkedPerson ward,
    _GNFamily family, {
    required bool rung2,
  }) {
    final showPhoto = rung2
        ? family.photoLevel != _GNPhotoLevel.never
        : family.photoLevel == _GNPhotoLevel.card;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _SheetShell(
        title: rung2 ? 'PROFILE — CONNECTED (RUNG 2)' : 'CARD — RUNG 0',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _FamilySeal(family: family, size: 54, showPhoto: showPhoto),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.display,
                        style: ZyraText.heading(size: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${family.region} · ${family.band.toLowerCase()}',
                        style: ZyraText.subtext(size: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!showPhoto)
              Text(
                family.photoLevel == _GNPhotoLevel.afterConnect && !rung2
                    ? 'Photo is shared after the Walis connect.'
                    : 'No photo is shared in Guardian Network.',
                style: ZyraText.subtext(size: 11, color: Colors.white54),
              ),
            if (rung2) ...[
              const SizedBox(height: 6),
              Text(
                'Connected unlock: the ordinary Browse-level profile appears here (PROVISIONAL in this draft). Never unlocked: contact details, exact location, private answers, numeric scores, histories (Rule 29).',
                style: ZyraText.subtext(size: 11),
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                'More unlocks only when both Walis connect (Rule 28).',
                style: ZyraText.subtext(size: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRequestSheet(
    BuildContext context,
    WaliLinkedPerson ward,
    _GNFamily family,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SheetShell(
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
                  _track('request_sent', family.id);
                  _setStage(ward, family, _GNStage.sent);
                  _advance();
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
    List<_GNFamily> fams,
  ) {
    final aside =
        fams.where((f) => _stageOf(ward, f) == _GNStage.setAside).toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SheetShell(
        title: 'SET ASIDE — RESTORE ANYTIME',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in aside)
              ListTile(
                leading: _FamilySeal(family: f, size: 36, showPhoto: false),
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
                    _track('restored', f.id);
                    _setStage(ward, f, _GNStage.none);
                  },
                  child: Text(
                    'Restore',
                    style: ZyraText.button(size: 12, color: _gnGold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAnalyticsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _SheetShell(
        title: 'ANALYTICS EVENTS — PROVISIONAL TRACKER (RULE 41)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_analytics.isEmpty)
              Text(
                'No events yet — interact with the preview.',
                style: ZyraText.subtext(size: 12),
              )
            else
              for (final line in _analytics.reversed.take(20))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    line,
                    style: ZyraText.subtext(size: 11, color: Colors.white70),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // ── dev panel (Rule 44: kDebugMode only) ────────────────────────────────
  Widget _buildDevPanel(BuildContext context) {
    Widget chip(String label, bool on, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: on
                  ? _gnGold.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: on
                    ? _gnGold.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.14),
                width: 0.6,
              ),
            ),
            child: Text(
              label,
              style: ZyraText.subtext(
                size: 10,
                color: on ? _gnGold : Colors.white54,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      color: Colors.black.withValues(alpha: 0.3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'DEV',
              style: ZyraText.chapterLabel(color: Colors.white38),
            ),
            const SizedBox(width: 8),
            for (final scene in _GNScene.values)
              chip(
                scene.name,
                _scene == scene,
                () => setState(() => _scene = scene),
              ),
            chip(
              _isMainWali ? 'role: Main' : 'role: Additional',
              !_isMainWali,
              () => setState(() => _isMainWali = !_isMainWali),
            ),
            chip(
              'analytics (${_analytics.length})',
              false,
              () => _showAnalyticsSheet(context),
            ),
            chip('reset', false, () {
              setState(() {
                _stage.clear();
                _analytics.clear();
                _scene = _GNScene.standard;
                _isMainWali = true;
              });
            }),
          ],
        ),
      ),
    );
  }
}

// ── shared small widgets ──────────────────────────────────────────────────

class _PreviewMarker extends StatelessWidget {
  const _PreviewMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 0.5,
        ),
      ),
      child: Text(
        'DRAFT 2 · D14',
        style: ZyraText.chapterLabel(
          color: Colors.white54,
        ).copyWith(fontSize: 8),
      ),
    );
  }
}

class _SeekerAvatarButton extends StatelessWidget {
  const _SeekerAvatarButton({required this.ward, required this.onTap});
  final WaliLinkedPerson? ward;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = ward?.firstName;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ZyraColors.luxuryDarkPurple.withValues(alpha: 0.8),
          border: Border.all(
            color: _gnGold.withValues(alpha: 0.7),
            width: 1.2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label == null || label.isEmpty
                  ? '?'
                  : label.characters.first.toUpperCase(),
              style: ZyraText.body(size: 14, color: Colors.white),
            ),
            if (onTap != null)
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF221A38),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '▾',
                    style: ZyraText.body(size: 6, color: _gnGold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.text, this.size = 30, this.gold = false});
  final String text;
  final double size;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZyraColors.luxuryDarkPurple.withValues(alpha: 0.8),
        border: Border.all(
          color: gold
              ? _gnGold.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        text.isEmpty ? '?' : text.characters.first.toUpperCase(),
        style: ZyraText.body(size: size * 0.4, color: Colors.white),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gnGold.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        '✓ VERIFIED',
        style: ZyraText.chapterLabel(color: _gnGold).copyWith(fontSize: 7.5),
      ),
    );
  }
}

class _FamilySeal extends StatelessWidget {
  const _FamilySeal({
    required this.family,
    required this.size,
    required this.showPhoto,
  });
  final _GNFamily family;
  final double size;
  final bool showPhoto;

  @override
  Widget build(BuildContext context) {
    if (showPhoto) {
      // PROVISIONAL photo placeholder (Rule 34: level permits at this rung).
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: size, height: size, child: const ZyraProfileImage('')),
              Container(
                color: ZyraColors.luxuryDarkPurple.withValues(alpha: 0.35),
              ),
              Text(
                family.initial,
                style: ZyraText.heading(size: size * 0.4, color: Colors.white),
              ),
              Positioned(
                bottom: 2,
                child: Text(
                  'PHOTO',
                  style: ZyraText.chapterLabel(color: Colors.white70)
                      .copyWith(fontSize: 6),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZyraColors.luxuryDarkPurple,
        border: Border.all(
          color: _gnGold.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
      child: Text(
        family.initial,
        style: ZyraText.heading(size: size * 0.4, color: Colors.white70),
      ),
    );
  }
}

class _NetworkContextNotice extends StatelessWidget {
  const _NetworkContextNotice({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

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

class _ServedFamilyCard extends StatelessWidget {
  const _ServedFamilyCard({
    required this.family,
    required this.isMainWali,
    required this.onView,
    required this.onGuardian,
    required this.onSetAside,
    required this.onRequest,
  });
  final _GNFamily family;
  final bool isMainWali;
  final VoidCallback onView;
  final VoidCallback onGuardian;
  final VoidCallback onSetAside;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final showPhoto = family.photoLevel == _GNPhotoLevel.card; // Rule 34
    return Container(
      key: Key('gn-served-${family.id}'),
      padding: const EdgeInsets.all(ZyraCardMetrics.padding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(
          color: _gnGold.withValues(alpha: 0.35),
          width: 0.7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 6),
          _FamilySeal(family: family, size: 96, showPhoto: showPhoto),
          const SizedBox(height: 10),
          Text(family.display, style: ZyraText.heading(size: 20)),
          const SizedBox(height: 3),
          Text(family.region, style: ZyraText.subtext(size: 12)),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _gnGold.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Text(
              family.band,
              style:
                  ZyraText.chapterLabel(color: _gnGold).copyWith(fontSize: 8),
            ),
          ),
          if (!showPhoto)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                family.photoLevel == _GNPhotoLevel.afterConnect
                    ? 'Photo is shared after the Walis connect'
                    : 'No photo is shared in Guardian Network',
                style: ZyraText.subtext(size: 10, color: Colors.white38),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final reason in family.reasons)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    style:
                        ZyraText.subtext(size: 10.5, color: Colors.white70),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    family.guardianLabel,
                    style: ZyraText.subtext(size: 11, color: Colors.white70),
                  ),
                  const SizedBox(width: 7),
                  const _VerifiedBadge(),
                  const SizedBox(width: 7),
                  Text(
                    'View Guardian ›',
                    style: ZyraText.subtext(size: 10.5, color: _gnGold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionPill(label: 'View', onTap: onView),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _ActionPill(label: 'Set aside', onTap: onSetAside),
              ),
              const SizedBox(width: 7),
              Expanded(
                flex: 2,
                child: _ActionPill(
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

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.enabled = true,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fill = primary
        ? ZyraColors.primaryAction.withValues(alpha: enabled ? 1.0 : 0.18)
        : Colors.white.withValues(alpha: enabled ? 0.08 : 0.03);
    final foreground = primary
        ? ZyraColors.onPrimaryAction.withValues(alpha: enabled ? 1.0 : 0.32)
        : Colors.white.withValues(alpha: enabled ? 0.78 : 0.25);
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
                  : Colors.white.withValues(alpha: enabled ? 0.14 : 0.06),
              width: 0.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZyraText.button(size: 11.5, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _MergeCard extends StatelessWidget {
  const _MergeCard({required this.family, required this.onReview});
  final _GNFamily family;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('gn-merge-${family.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _gnGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(color: _gnGold.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Column(
        children: [
          _FamilySeal(family: family, size: 64, showPhoto: false),
          const SizedBox(height: 10),
          Text(
            'This family has already requested connection.',
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 14, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(
            '${family.display} · ${family.guardianLabel.toLowerCase()} — their request is waiting in Connections. One process per pair (Rule 24).',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _ActionPill(
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
  const _CapReachedCard({required this.live, required this.onManage});
  final int live;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(
          color: _gnGold.withValues(alpha: 0.4),
          width: 0.7,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_top_outlined,
              size: 26, color: Colors.white54),
          const SizedBox(height: 8),
          Text('$live of 3 live processes',
              style: ZyraText.heading(size: 16)),
          const SizedBox(height: 5),
          Text(
            'Each family deserves proper attention. Close or complete one of your live processes before starting another — the cap is the same on every plan.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 11.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _ActionPill(
              label: 'Manage connections',
              primary: true,
              onTap: onManage,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  const _IncomingCard({
    required this.ward,
    required this.family,
    required this.capped,
    required this.onGuardian,
    required this.onConnect,
    required this.onNotForUs,
  });
  final WaliLinkedPerson ward;
  final _GNFamily family;
  final bool capped;
  final VoidCallback onGuardian;
  final VoidCallback onConnect;
  final VoidCallback onNotForUs;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('gn-incoming-${family.id}'),
      margin: const EdgeInsets.only(bottom: ZyraCardMetrics.spacing),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(color: _gnGold.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FamilySeal(family: family, size: 42, showPhoto: false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family.display,
                      style: ZyraText.body(size: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Their Wali requested connection for ${ward.firstName}',
                      style: ZyraText.subtext(size: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onGuardian,
            child: Text(
              '${family.guardianLabel} · ✓ verified · View Guardian ›',
              style: ZyraText.subtext(size: 10.5, color: _gnGold),
            ),
          ),
          const SizedBox(height: 10),
          if (capped)
            Text(
              '3 of 3 live processes — close one before connecting (Rule 40).',
              style: ZyraText.subtext(size: 10.5, color: _gnGold),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ActionPill(label: 'Not for us', onTap: onNotForUs),
                ),
                const SizedBox(width: 7),
                Expanded(
                  flex: 2,
                  child: _ActionPill(
                    label: 'Connect with this family',
                    primary: true,
                    onTap: onConnect,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SentCard extends StatelessWidget {
  const _SentCard({required this.family, required this.onWithdraw});
  final _GNFamily family;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('gn-sent-${family.id}'),
      margin: const EdgeInsets.only(bottom: ZyraCardMetrics.spacing),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          _FamilySeal(family: family, size: 36, showPhoto: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  family.display,
                  style: ZyraText.body(size: 13, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Awaiting their Wali · quietly becomes "No longer active" after 14 days',
                  style: ZyraText.subtext(size: 10),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onWithdraw,
            child: Text(
              'Withdraw',
              style: ZyraText.subtext(size: 11, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({
    required this.ward,
    required this.family,
    required this.stage,
    required this.onGuardian,
    required this.onProfile,
    required this.onWithdraw,
    required this.onProceed,
  });
  final WaliLinkedPerson ward;
  final _GNFamily family;
  final _GNStage stage;
  final VoidCallback onGuardian;
  final VoidCallback onProfile;
  final VoidCallback onWithdraw;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    final revealed = stage == _GNStage.revealed;
    final mineConfirmed = stage == _GNStage.proceedMine || revealed;
    return Container(
      key: Key('gn-connected-${family.id}'),
      margin: const EdgeInsets.only(bottom: ZyraCardMetrics.spacing),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _gnGold.withValues(alpha: revealed ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(color: _gnGold.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialCircle(text: ward.firstName, gold: true),
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Transform.translate(
                  offset: const Offset(-8, 0),
                  child: _FamilySeal(family: family, size: 30, showPhoto: false),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      revealed ? 'Introduced' : 'Connected',
                      style: ZyraText.body(size: 13.5, color: _gnGold),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${family.display} · ${family.guardianLabel.toLowerCase()}',
                      style: ZyraText.subtext(size: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (revealed) ...[
            Text(
              'Both Walis agreed — the introduction is now visible to ${ward.firstName} and to ${family.display}\'s family, at the same moment. Their decisions continue on the Guardian Dashboard.',
              style: ZyraText.subtext(size: 11, color: Colors.white70),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _ActionPill(
                    label: 'Their profile',
                    onTap: onProfile,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _ActionPill(
                    label: 'Their Wali',
                    onTap: onGuardian,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              family.theirWaliConfirmed
                  ? 'Their Wali has confirmed "Proceed to the Seekers".'
                  : 'Structured exchange is open (no free text — D6).',
              style: ZyraText.subtext(size: 10.5),
            ),
            const SizedBox(height: 8),
            if (mineConfirmed)
              Text(
                'You have confirmed — awaiting their Wali. You can withdraw until both confirm.',
                style: ZyraText.subtext(size: 10.5, color: _gnGold),
              )
            else
              SizedBox(
                width: double.infinity,
                child: _ActionPill(
                  label: 'Proceed to the Seekers',
                  primary: true,
                  onTap: onProceed,
                ),
              ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: onWithdraw,
                child: Text(
                  'Withdraw — shown only as "No longer active"',
                  style: ZyraText.subtext(size: 10, color: Colors.white38),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClosedRow extends StatelessWidget {
  const _ClosedRow({required this.family});
  final _GNFamily family;

  @override
  Widget build(BuildContext context) {
    // Rule 30: privacy-minimal neutral record only.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            '${family.initial}.',
            style: ZyraText.body(size: 12.5, color: Colors.white54),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              family.region,
              style: ZyraText.subtext(size: 11, color: Colors.white38),
            ),
          ),
          Text(
            'No longer active',
            style: ZyraText.subtext(size: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        22 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        gradient: ZyraColors.sheetGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: ZyraText.chapterLabel(color: Colors.white38),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
