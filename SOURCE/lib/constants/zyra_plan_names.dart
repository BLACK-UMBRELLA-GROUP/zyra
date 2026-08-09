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
// audit found is that nothing in the Flutter app ever reads or writes
// `subscriptions.plan_type` at all — it's seeded directly in
// supabase/seed_dev_accounts.sql and otherwise untouched. AppState's
// `ZyraPlan` enum (basic/one) is a fully separate, local-only mock
// entitlement flag with no connection to the real subscriptions table
// — flipping it (UpgradeScreen, DeveloperAccessScreen) never writes
// to `subscriptions`, and nothing ever reads `subscriptions.plan_type`
// back into AppState.plan. This mirrors the well-known "no real
// payment processing" gap (Founder handover, Immediate Next Steps
// item 6) — wiring plan_type <-> ZyraPlan for real only matters once
// there's an actual purchase flow to drive it, so it's deliberately
// NOT faked here. This file exists so that whenever that wiring
// happens, there is one canonical mapping to use instead of ad hoc
// strings scattered across screens.
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
