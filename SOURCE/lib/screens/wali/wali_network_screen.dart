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

import 'package:flutter/material.dart';
import '../../services/zyra_entitlement_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';

class WaliNetworkScreen extends StatefulWidget {
  const WaliNetworkScreen({super.key});

  @override
  State<WaliNetworkScreen> createState() => _WaliNetworkScreenState();
}

class _WaliNetworkScreenState extends State<WaliNetworkScreen> {
  int _tab = 0; // 0 = Discover, 1 = Requests
  bool _loading = true;
  bool _hasExtended = false;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    _loadEntitlement();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    super.dispose();
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
    if (_loading) {
      return const ZyraLoading();
    }
    final hasExtended = _hasExtended;
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
              child: Text('Network', style: ZyraText.heading(size: 22)),
            ),
            if (!hasExtended)
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(child: _NetworkTabButton(label: 'Discover', selected: _tab == 0, onTap: () => setState(() => _tab = 0))),
                    const SizedBox(width: 10),
                    Expanded(child: _NetworkTabButton(label: 'Requests', selected: _tab == 1, onTap: () => setState(() => _tab = 1))),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ZyraEmptyState(
                    icon: _tab == 0 ? Icons.diversity_3_outlined : Icons.inbox_outlined,
                    message: _tab == 0
                        ? 'No families to discover yet — this fills in once other Guardians with Guardian+ capabilities appear.'
                        : 'No Family Introduction Requests yet.',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NetworkTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NetworkTabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ZyraColors.accentBg : ZyraColors.iconButtonBg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? ZyraColors.accentBorder : ZyraColors.iconButtonBorder, width: 0.5),
        ),
        child: Center(child: Text(label, style: ZyraText.body(size: 12.5, color: Colors.white))),
      ),
    );
  }
}
