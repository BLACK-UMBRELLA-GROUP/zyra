// Compatibility Unlock persistence.
//
// Founder approved 2026-08-03:
//   "A profile may only be Compatibility Unlocked once per user. Once
//    unlocked, the compatibility remains permanently accessible to that
//    user. Returning to the same profile must never consume another
//    Compatibility Unlock. The action button should permanently change
//    from Compatibility Unlock to View Compatibility after the initial
//    unlock."
//
// RENAMED FROM "Profile Unlock" in the same decision. The old pairing —
// `Profile Unlock` leading to `View Compatibility` — implied two different
// features. `Compatibility Unlock` → `View Compatibility` is one idea
// stated twice.
//
// WHAT IS REAL HERE AND WHAT IS NOT:
//
//   REAL   The unlock record. `profile_unlocks` rows are written and read,
//          RLS-scoped to the caller, with a unique index enforcing
//          once-per-profile-per-tier in the database rather than trusting
//          this class to check first.
//
//   NOT    The payment. There is no payment SDK in the project — verified
//          against pubspec.yaml: no in_app_purchase, no StoreKit, no
//          RevenueCat, no Stripe. Unlocking currently costs nothing.
//
//   NOT    The compatibility score itself. It is computed from
//          `onboarding_answers`, which has zero rows for real users, and
//          the scoring method is still an open to-do in the spec.
//
// So a real user could today unlock a real row and see sample numbers. The
// row is worth writing anyway: the once-only rule and the button-state
// behaviour are the parts being designed, and they need somewhere durable
// to live. When payments land, the purchase gates the insert — the insert
// itself does not change.

import 'package:flutter/foundation.dart';

import '../main.dart';
import 'zyra_auth.dart';

/// What happened when an unlock was attempted.
///
/// REPLACES a bare `bool` (2026-08-04). The old signature could not
/// distinguish "you have no credits" from "the network failed", so the UI
/// showed the same retry message for both — one of which retrying will
/// never fix.
enum UnlockOutcome {
  /// A credit was spent and the profile is now unlocked.
  unlocked,

  /// Already unlocked at this tier. Nothing was charged — the permanence
  /// rule. Treated as success everywhere.
  alreadyUnlocked,

  /// No credits at this tier. Not an error; an answer.
  insufficientCredits,

  /// The profile is one of the built-in sample profiles (`mockProfiles`),
  /// whose ids are '1', '2', '3'… rather than real UUIDs. Unlocked locally
  /// for the rest of the session so the screen can be tried, and no credit
  /// is spent because there is nothing on the server to spend it against.
  ///
  /// ADDED 2026-08-05 (Fable). Before this, tapping Unlock on a sample
  /// profile sent '1' to `zyra_unlock_profile(p_target uuid, …)`, Postgres
  /// rejected it as invalid uuid syntax, and the screen showed "That didn't
  /// go through. Please try again." — advice that could never work, on the
  /// only profiles available to test with. The real cure is removing the
  /// sample deck entirely (independent review, H-6); until that happens the
  /// failure should at least be truthful.
  sampleProfile,

  /// Network or server failure. The only outcome worth retrying.
  failed,
}

/// Which tier an unlock buys. Values must match `profile_unlocks`'
/// unlock_type CHECK constraint.
enum UnlockTier {
  /// Compatibility Unlock — overall score plus Green/Amber/Red counts.
  standard('paid_single'),

  /// Compatibility Unlock Plus — the above plus a category breakdown.
  plus('paid_plus_single');

  const UnlockTier(this.dbValue);
  final String dbValue;
}

class ZyraUnlockService {
  ZyraUnlockService._();

  /// Everything this Seeker has already unlocked, as `'<profileId>:<tier>'`.
  ///
  /// Cached in memory for the session after the first read. The set only
  /// grows — an unlock is permanent, so nothing can invalidate it — which
  /// is what lets every card check ownership without a round trip.
  static final Set<String> _unlocked = {};
  static bool _loaded = false;

  static String _key(String profileId, UnlockTier tier) => '$profileId:${tier.dbValue}';

  /// Real rows have UUID ids; `mockProfiles` uses '1', '2', '3'…
  /// Anything sent to a `uuid` parameter must pass this first, or Postgres
  /// throws a syntax error the UI can only report as a generic failure.
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isSampleProfile(String profileId) => !_uuid.hasMatch(profileId);

  static bool isUnlocked(String profileId, UnlockTier tier) =>
      _unlocked.contains(_key(profileId, tier));

  /// Loads the caller's unlocks. Called once per launch from the session
  /// router; safe to call again.
  static Future<void> load() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;
    try {
      final rows = await supabase
          .from('profile_unlocks')
          .select('unlocked_id, unlock_type')
          .eq('unlocker_id', user.id) as List;
      _unlocked
        ..clear()
        ..addAll([
          for (final r in rows)
            '${(r as Map<String, dynamic>)['unlocked_id']}:${r['unlock_type']}',
        ]);
      _loaded = true;
    } catch (e) {
      // Logged, not swallowed. A failure here makes an already-unlocked
      // profile look locked, which would read as having lost something
      // paid for — worth seeing in the console rather than guessing at.
      debugPrint('ZYRA: unlock load failed — $e');
    }
  }

  static bool get loaded => _loaded;

  /// Spends one credit to unlock a profile.
  ///
  /// REWRITTEN 2026-08-04 to close C-1 (independent review, reproduced
  /// end-to-end before the fix).
  ///
  /// This used to be a direct `INSERT INTO profile_unlocks`. The client
  /// decided that an unlock had been paid for, and the database believed
  /// it — so two HTTP requests with the publishable key that ships in this
  /// app bundle granted anyone another member's sect, revert status,
  /// ethnicity, birth country and nationality.
  ///
  /// `authenticated` no longer holds INSERT, UPDATE or DELETE on
  /// `profile_unlocks` at all. The row can only be created by
  /// `zyra_unlock_profile()`, which verifies a credit balance in the
  /// `unlock_credits` ledger and writes the unlock and the debit in one
  /// transaction.
  ///
  /// Permanence is enforced server-side too: revisiting a profile already
  /// unlocked returns `already_unlocked` with `charged: false`, so a double
  /// tap on a slow connection cannot spend twice.
  static Future<UnlockOutcome> unlock(String profileId, UnlockTier tier) async {
    if (isUnlocked(profileId, tier)) return UnlockOutcome.alreadyUnlocked;

    final user = ZyraAuth.currentUser;
    if (user == null) {
      // Mock/offline session — nothing to spend and nowhere to write.
      // Remember locally so the button behaves for the rest of the session.
      _unlocked.add(_key(profileId, tier));
      return UnlockOutcome.unlocked;
    }

    // Signed in, but looking at a sample profile: same situation as above —
    // there is no server-side profile to unlock — so handle it the same way
    // rather than sending '1' to a uuid parameter and reporting the
    // resulting syntax error as a network problem.
    if (isSampleProfile(profileId)) {
      _unlocked.add(_key(profileId, tier));
      return UnlockOutcome.sampleProfile;
    }

    try {
      final res = await supabase.rpc('zyra_unlock_profile', params: {
        'p_target': profileId,
        'p_tier': tier.dbValue,
      });
      final status = (res as Map?)?['status'] as String?;
      switch (status) {
        case 'unlocked':
          _unlocked.add(_key(profileId, tier));
          return UnlockOutcome.unlocked;
        case 'already_unlocked':
          _unlocked.add(_key(profileId, tier));
          return UnlockOutcome.alreadyUnlocked;
        case 'insufficient_credits':
          return UnlockOutcome.insufficientCredits;
        default:
          debugPrint('ZYRA: unlock returned unexpected status "$status"');
          return UnlockOutcome.failed;
      }
    } catch (e) {
      debugPrint('ZYRA: unlock($profileId, ${tier.dbValue}) failed — $e');
      return UnlockOutcome.failed;
    }
  }

  /// Credit balance per tier, from the `unlock_credits` ledger.
  ///
  /// ADDED 2026-08-04. Balances previously existed only as an in-memory
  /// enum in the dev panel — there was no server-side notion of how many
  /// unlocks anyone owned, which is precisely why nothing could check one.
  ///
  /// Returns 0 for a tier with no rows. Never null: a failed read must not
  /// be mistaken for "you have credits".
  static Future<Map<UnlockTier, int>> balances() async {
    final out = {for (final t in UnlockTier.values) t: 0};
    if (ZyraAuth.currentUser == null) return out;
    try {
      final rows = await supabase.rpc('unlock_balance') as List?;
      for (final r in rows ?? const []) {
        final m = Map<String, dynamic>.from(r as Map);
        // Plain loop rather than `.firstOrNull`, which lives in
        // package:collection and is not a dependency of this project.
        for (final t in UnlockTier.values) {
          if (t.dbValue == m['tier']) {
            out[t] = (m['balance'] as num?)?.toInt() ?? 0;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('ZYRA: unlock_balance failed — showing 0. $e');
    }
    return out;
  }

  /// Dev-only credit grant. Refused server-side for anything other than a
  /// `@zyra.test` account — same guard as `mock_purchase_wali_premium`.
  ///
  /// Exists because payments do not, and without it Compatibility Unlock
  /// would be untestable: a Seeker with no purchase route has a permanent
  /// balance of zero.
  static Future<bool> debugGrant(UnlockTier tier, int count) async {
    if (kReleaseMode) return false;
    try {
      await supabase.rpc('zyra_debug_grant_credits',
          params: {'p_tier': tier.dbValue, 'p_count': count});
      return true;
    } catch (e) {
      debugPrint('ZYRA: debug credit grant refused — $e');
      return false;
    }
  }

  /// Test-account ids are not real `profiles` rows, so the FK would reject
  /// them. Mirrors ZyraReportService.isPersistableId.
  static void clearForSignOut() {
    _unlocked.clear();
    _loaded = false;
  }
}
