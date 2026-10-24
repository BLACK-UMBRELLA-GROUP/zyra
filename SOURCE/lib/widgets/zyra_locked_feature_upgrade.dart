// Shared boundary for a Seeker who explicitly taps a membership-locked
// feature. The feature remains visible and the user's deliberate action opens
// membership information; this helper never mutates or grants entitlement.

import 'package:flutter/material.dart';

import '../screens/subscription/upgrade_screen.dart';
import '../services/zyra_promotion_engine.dart';
import '../services/zyra_product_telemetry.dart';
import '../state/app_state.dart';

void recordSeekerLockedFeatureView(
  ZyraPromotionFeature feature, {
  ZyraPromotionPlacement placement = ZyraPromotionPlacement.lockedFeature,
}) {
  ZyraPromotionEngine.instance.recordLockedFeature(
    ctaTapped: false,
    role: ZyraPromotionRole.seeker,
    product: ZyraPromotionProduct.zyraOne,
    feature: feature,
    placement: placement,
  );
}

void openSeekerLockedFeaturePlan(
  BuildContext context, {
  required ZyraPromotionFeature feature,
  ZyraPromotionPlacement placement = ZyraPromotionPlacement.lockedFeature,
}) {
  final engine = ZyraPromotionEngine.instance;
  engine.recordLockedFeature(
    ctaTapped: true,
    role: ZyraPromotionRole.seeker,
    product: ZyraPromotionProduct.zyraOne,
    feature: feature,
    placement: placement,
  );
  if (AppState.instance.plan == ZyraPlan.one || !context.mounted) {
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          const UpgradeScreen(telemetrySurface: ZyraTelemetrySurface.seeker),
    ),
  );
}
