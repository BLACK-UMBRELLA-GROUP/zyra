// Wali One entitlement resolution (#19; renamed from "Extended Guardian"
// 2026-07-26 — Founder decision, matching "ZYRA One" naming) — replaces
// the local AppState.waliHasWaliOne mock toggle with a real read
// of wali_has_wali_one(), backed by 20260726160000_wali_extended_
// wali_real_gating.sql (function itself renamed by 20260726180000_
// rename_wali_has_extended_wali_to_wali_one.sql; resolution rule
// unchanged). See those migrations for the exact resolution rule (own
// wali_premium subscription, OR bundled free via a linked Seeker's
// active seeker_premium/ZYRA One).
//
// Deliberately its own small service rather than folded into
// zyra_wali_link_service.dart — entitlement resolution is a distinct
// concern from link management, and this is likely to grow a Seeker-
// side ZYRA One equivalent once #20 (real payment processing) lands.

import 'package:flutter/foundation.dart' show debugPrint;
import '../main.dart';
import 'zyra_auth.dart';

class ZyraEntitlementService {
  ZyraEntitlementService._();

  /// False (not an error) if not signed in or on any failure — a
  /// Guardian should never be blocked from using the app because an
  /// entitlement check failed, just fall back to Guardian Basic.
  static Future<bool> hasWaliOne() async {
    if (ZyraAuth.currentUser == null) return false;
    try {
      final result = await supabase.rpc('wali_has_wali_one');
      return result == true;
    } catch (e) {
      // 2026-08-12: failed with no trace anywhere (CLAUDE.md §3).
      debugPrint('ZYRA mock_set_wali_plan failed: $e');
      return false;
    }
  }

  /// Backs the "Get Guardian+ — £9.99/month" mock-purchase button
  /// in wali_network_screen.dart. Writes a real subscriptions row
  /// (mock_purchase_wali_premium() — no actual payment taken, same
  /// category of mock as the rest of this preview build's purchase
  /// flows). Returns true on success.
  static Future<bool> mockPurchaseWaliPremium() async {
    try {
      await supabase.rpc('mock_purchase_wali_premium');
      return true;
    } catch (e) {
      // 2026-08-12: failed with no trace anywhere (CLAUDE.md §3).
      debugPrint('ZYRA mock_purchase_wali_premium failed: $e');
      return false;
    }
  }

  /// Developer Access only — deterministically sets the signed-in
  /// Wali's OWN subscription row to wali_basic/wali_premium
  /// (mock_set_wali_plan()), so switching between "Guardian — Basic" and
  /// "Guardian — One" presets for the same real test account behaves
  /// consistently instead of a one-way upgrade sticking around. Note
  /// this only controls the account's OWN plan — if it's also linked
  /// to a Seeker with a real active ZYRA One subscription, it will
  /// still resolve as Guardian+ via the free-bundling rule
  /// regardless of this call (see wali_has_wali_one()) — that's
  /// correct, not a bug.
  static Future<bool> mockSetWaliPlan({required bool premium}) async {
    try {
      await supabase.rpc('mock_set_wali_plan', params: {'p_plan': premium ? 'wali_premium' : 'wali_basic'});
      return true;
    } catch (e) {
      // 2026-08-12: a paying Guardian was silently downgraded on any
      // failure, unlogged (CLAUDE.md §3). Behaviour unchanged — fall back
      // to Basic — but the failure now leaves a trace.
      debugPrint('ZYRA entitlement check failed: $e');
      return false;
    }
  }
}
