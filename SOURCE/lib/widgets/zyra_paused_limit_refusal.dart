// The plan-aware "Paused Journeys are full" refusal.
//
// EXTRACTED 2026-08-12 from journey_flow_screen._pauseJourney, the moment a
// second caller appeared: the Connections takeover popup now offers "Pause
// with <name>" as a first-class choice (B1 design, Founder-picked), and its
// pause can hit the same server cap. Two hand-written copies of a
// plan-branching dialog is exactly the drift the 2026-08-12 panel rebuild
// spent a day deleting — so the refusal moved here before the second copy
// could be typed.
//
// The shape is DR-ZYRA-138's: both plans pause, the CAP is the
// differentiator (Basic 5 / One 10, data/zyra_entitlements.dart). The
// upgrade offer appears only where upgrading raises the number — Basic at
// its 5. ZYRA One at its 10 gets the honest ceiling and an OK.

import 'package:flutter/material.dart';

import '../data/zyra_entitlements.dart';
import '../screens/subscription/upgrade_screen.dart';
import '../state/app_state.dart';
import '../theme/zyra_text.dart';
import 'zyra_glass_dialog.dart';

/// Shows the refusal for [PausedLimitReachedException]. Offers the upgrade
/// path on Basic; states the ceiling on ZYRA One. Safe to call from any
/// screen — pushes UpgradeScreen on the caller's navigator if accepted.
Future<void> showZyraPausedLimitRefusal(BuildContext context) async {
  final limits = ZyraEntitlements.of(AppState.instance.plan);
  if (AppState.instance.plan == ZyraPlan.one) {
    await showZyraGlassDialog<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pause_circle_outline, color: Colors.white, size: 30),
          const SizedBox(height: 14),
          Text('Paused Journeys are full',
              style: ZyraText.heading(size: 18), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'ZYRA One holds up to ${limits.paused} paused Journeys, and '
            "you're at the limit. Resume or end one of them to pause "
            'this one.',
            style: ZyraText.subtext(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK', style: ZyraText.button(size: 13)),
            ),
          ),
        ],
      ),
    );
  } else {
    final upgrade = await showZyraGlassChoice(
      context: context,
      icon: Icons.pause_circle_outline,
      title: 'Paused Journeys are full',
      body: 'ZYRA Basic holds up to ${limits.paused} paused Journeys, '
          "and you're at the limit. Resume or end one first — or ZYRA "
          'One holds ${ZyraEntitlements.one.paused}.',
      primaryLabel: 'Upgrade to ZYRA One',
      secondaryLabel: 'Not now',
    );
    if (upgrade == true && context.mounted) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
    }
  }
}
