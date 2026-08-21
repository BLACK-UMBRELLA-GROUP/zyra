// Canonical mapping between the `subscriptions.plan_type` DB
// identifiers (20260718190011_initial_schema.sql: 'seeker_basic',
// 'seeker_premium', 'wali_basic', 'wali_premium' — a plain TEXT
// column with a CHECK constraint, not a Postgres enum) and the
// product-facing names used throughout the UI (ZYRA Basic / ZYRA One
// for Seekers, Standard Wali / Wali One for Walis).
//
// Added 2026-07-26 (DR-ZYRA-101 audit — "plan-name drift" flagged in
// ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md §Open Decisions item 3).
//
// IMPORTANT — what this fixes and what it doesn't:
// The naming mismatch itself is intentional and not a bug: the DB
// identifiers are internal/stable, the product names are what users
// see, and that's a completely normal separation. The REAL gap this
// audit found was that nothing in the Flutter app ever read or wrote
// `subscriptions.plan_type` at all — AppState's `ZyraPlan` enum
// (basic/one) was a fully separate, local-only mock entitlement flag.
//
// PARTIALLY CLOSED SINCE. Two things now cross the gap, both through
// this file's mapping:
//   READ   zyra_session_router.dart (2026-08-12) reads plan_type back
//          into AppState.plan on every sign-in and cold start.
//   WRITE  the dev panel's Membership control (2026-08-12) writes it
//          for @zyra.test accounts via zyra_dev_set_seeker_plan(), so
//          server-enforced entitlements (pause caps) test against the
//          plan being simulated.
// What remains deliberately unwired is REAL purchasing — UpgradeScreen
// still flips only the mock, matching the known "no real payment
// processing" gap (Founder handover, Immediate Next Steps item 6).
// When IAP arrives, it drives the same column through this same
// mapping.
//
// wali_premium (Wali One) is doubly dormant: unused by any Dart
// code AND never granted by any real purchase flow — Wali's
// Extended-Guardian gate today is a local mock switch
// (AppState.waliHasWaliOne via wali_network_screen.dart's "Get
// Guardian+" button), not backed by this column at all.

/// The four real values `subscriptions.plan_type` accepts.
enum ZyraSubscriptionPlanType {
  seekerBasic,
  seekerPremium,
  waliBasic,
  waliPremium;

  String get dbValue => switch (this) {
        ZyraSubscriptionPlanType.seekerBasic => 'seeker_basic',
        ZyraSubscriptionPlanType.seekerPremium => 'seeker_premium',
        ZyraSubscriptionPlanType.waliBasic => 'wali_basic',
        ZyraSubscriptionPlanType.waliPremium => 'wali_premium',
      };

  /// The name shown to users for this plan.
  String get displayName => switch (this) {
        ZyraSubscriptionPlanType.seekerBasic => 'ZYRA Basic',
        ZyraSubscriptionPlanType.seekerPremium => 'ZYRA One',
        ZyraSubscriptionPlanType.waliBasic => 'Standard Guardian',
        ZyraSubscriptionPlanType.waliPremium => 'Guardian+',
      };

  static ZyraSubscriptionPlanType? fromDbValue(String? value) => switch (value) {
        'seeker_basic' => ZyraSubscriptionPlanType.seekerBasic,
        'seeker_premium' => ZyraSubscriptionPlanType.seekerPremium,
        'wali_basic' => ZyraSubscriptionPlanType.waliBasic,
        'wali_premium' => ZyraSubscriptionPlanType.waliPremium,
        _ => null,
      };
}
