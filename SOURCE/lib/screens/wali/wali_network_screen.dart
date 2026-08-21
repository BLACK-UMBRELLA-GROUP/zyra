// Wali Network — WALI ARCHITECTURE §WALI NETWORK — ARCHITECTURE.
// Gated behind Wali One capabilities (via included entitlement from
// a linked Seeker's ZYRA One, or the Guardian's own £9.99/month purchase —
// Path 2A). A Standard Wali tapping this tab sees the spec's explanation
// rather than the feature itself. Discover/Requests tabs per spec once
// unlocked; both start empty since no real Network data exists yet.
//
// 2026-07-26 (#19): gating now reads the real entitlement
// (ZyraEntitlementService.hasWaliOne(), backed by
// wali_has_extended_wali() — see 20260726160000_wali_extended_wali_
// real_gating.sql) instead of the local AppState.waliHasWaliOne
// mock toggle. The mock-purchase button now writes a real subscriptions
// row via mock_purchase_wali_premium() — still no real payment, but the
// entitlement it grants is genuinely read back, not just a local flag.

// 2026-08-13 (Founder), THREE CHANGES:
//
//  1. THE PINK FLASH IS FIXED. "When I click Network there's a slight
//     glitch on the male Guardian where for a second I see pink then
//     blue." Cause: this was the ONLY Guardian screen that returned its
//     loading state BEFORE painting its gradient —
//     `if (_loading) return const ZyraLoading();` sat above the
//     Container. Dashboard, Seekers and Profile all paint the gradient
//     first and put the spinner inside it.
//
//     For that one frame the Scaffold showed through, and
//     scaffoldBackgroundColor (main.dart) is
//     `genderGradient(AppState.gender).colors.first` — read ONCE when the
//     theme is built, from the CACHED gender. Switch from a female
//     account to a male Guardian and the stale value is female, so the
//     exposed colour is Rose Pink #D4868F. Then the real gradient paints
//     Royal Blue over it. Exactly one frame of pink, then blue.
//
//     Fixed by painting the gradient first, like every sibling screen.
//     The stale theme colour is a real second-order bug and is NOT fixed
//     here — it can no longer show on this screen, and no other screen
//     exposes it.
//
//  2. THE TOP CONTROL IS THE SHARED PILL. Discover/Requests were two
//     plain rounded buttons; they are now ZyraSegmentedToggle — the same
//     sliding frosted pill as the Seeker's Connections page.
//
//  3. SWIPEABLE, like Connections. The pill tracks the finger through a
//     PageView rather than snapping at the end of the gesture.

import 'package:flutter/material.dart';
import '../../services/zyra_entitlement_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_segmented_toggle.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';

class WaliNetworkScreen extends StatefulWidget {
  const WaliNetworkScreen({super.key});

  @override
  State<WaliNetworkScreen> createState() => _WaliNetworkScreenState();
}

class _WaliNetworkScreenState extends State<WaliNetworkScreen> {
  bool _loading = true;
  bool _hasExtended = false;
  bool _purchasing = false;

  /// Connections' mechanism, verbatim: the pager's live fractional offset,
  /// not the settled page, so the pill sits 40% across at 40% of a swipe.
  final PageController _pager = PageController();
  double _pagerPos = 0;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    _pager.addListener(_onPagerScroll);
    _loadEntitlement();
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
        const SnackBar(content: Text('Guardian+ unlocked (preview build — no payment taken).'), duration: Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't unlock Guardian+ — try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExtended = _hasExtended;
    // THE GRADIENT PAINTS FIRST, always — see change 1 in the header. The
    // loading state lives inside it now, never above it.
    return Container(
      // 2026-07-25: gender-matched gradient, was hardcoded Male — see
      // ZyraColors.genderGradient() doc comment / DR-ZYRA-094.
      decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
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
            else if (!hasExtended)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.white38, size: 28),
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
                              border: Border.all(color: ZyraColors.accentBorder, width: 1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(50),
                                onTap: _purchasing ? null : _purchaseExtendedWali,
                                child: Center(
                                  child: _purchasing
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Text('Get Guardian+ — £9.99/month', style: ZyraText.button(size: 13)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Preview build — no real payment is taken.',
                            style: ZyraText.subtext(size: 10.5, color: Colors.white38),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: ZyraSegmentedToggle(
                  labels: const ['Discover', 'Requests'],
                  position: _pagerPos,
                  // Two segments, so there is room for the fuller size.
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
}

// _NetworkTabButton retired 2026-08-13 — replaced by the shared
// ZyraSegmentedToggle. It was the Guardian side's private answer to a
// question the Seeker side had already answered better.
