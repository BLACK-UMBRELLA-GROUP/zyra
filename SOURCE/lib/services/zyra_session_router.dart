// Decides which screen a signed-in user lands on — used both right
// after sign-in (welcome_screen.dart, Google/Apple OAuth) and on cold
// app start when an existing session is found (auth_gate.dart), so
// both paths agree.
//
// Looks up the `profiles` row for the current session: role='seeker'
// -> HomeShell, role='wali' -> WaliHomeShell. No profile row yet (user
// signed up but never finished onboarding, e.g. closed the app
// mid-flow) -> RoleSelectionScreen, so they resume rather than land on
// a broken/empty Home.

import 'zyra_local_prefs.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../main.dart';
import '../models/zyra_error_state.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/wali/wali_home_shell.dart';
import '../state/app_state.dart';
import '../constants/zyra_plan_names.dart';
import 'zyra_auth.dart';
import 'zyra_discovery_service.dart';
import 'zyra_unlock_service.dart';

class ZyraSessionRouter {
  ZyraSessionRouter._();

  static Future<Widget> resolveHome() async {
    final user = ZyraAuth.currentUser;
    if (user == null) {
      return const RoleSelectionScreen(); // shouldn't be reached without a session; safe fallback
    }

    try {
      // FIXED 2026-08-01 (Founder: "the first time it loads it loads the
      // user page but with the OLD PURPLE background... I have to keep
      // clicking the homepage and selecting user for it to refresh").
      //
      // ROOT CAUSE: AppState was only ever written by onboarding
      // (saveChapter1) or by Developer Access (applyDevPreset). NOTHING
      // read it back from the database. So on every cold start with a
      // persisted session, the singleton was completely empty —
      // AppState.gender was null, ZyraColors.genderGradient(null)
      // returned the NEUTRAL brand gradient, and every profile-context
      // screen rendered the pre-auth purple instead of the ratified
      // male-blue / female-pink (DR-ZYRA-094). Picking a user in
      // Developer Access "fixed" it only because applyDevPreset happens
      // to set gender — hence the refresh dance.
      //
      // The gradient was the visible symptom; it was not the worst part.
      // The same emptiness meant, on every relaunch:
      //   • Profile showed "Your Profile" instead of the user's name
      //   • Location showed "—", age row vanished entirely
      //   • plan defaulted to ZyraPlan.basic — so a REAL ZYRA One
      //     subscriber saw sponsored cards, hit the daily Browse limit,
      //     and was refused Pause Journey until they happened to visit a
      //     screen that reset it. A paying user silently losing their
      //     entitlement on every launch.
      //
      // Fetched here because this is the single cold-start path (AuthGate
      // -> resolveHome) and it already had to read `profiles` for
      // routing. Widening that existing round trip costs nothing extra.
      //
      // NOTE: date_of_birth is deliberately NOT selected — that column's
      // client SELECT was revoked (audit C2). Age comes from ages_for(),
      // the same SECURITY DEFINER function Browse and Matches use.
      final row = await supabase
          .from('profiles')
          // surname_line ADDED 2026-08-07. It was already selectable and
          // already read by Browse for everyone ELSE — the owner's own
          // profile page was the one place still showing a bare first name.
          .select('role, first_name, surname_line, gender, location_text')
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) {
        return const RoleSelectionScreen(); // signed up, onboarding never finished
      }

      await _hydrate(user.id, row);

      final role = row['role'] as String?;
      // Remembered for the failure path below — see there for why.
      ZyraLocalPrefs.setCachedRole(role);
      return role == 'wali' ? const WaliHomeShell() : const HomeShell();
    } catch (e) {
      // FALLS BACK TO THE REMEMBERED ROLE — 2026-08-14 (DR-ZYRA-166).
      //
      // This returned HomeShell unconditionally. A Guardian whose profile
      // lookup failed — a network hiccup, an RLS change, a cold start on
      // a bad connection — was handed the SEEKER app: Browse, a swipe
      // deck, Connections. Not a degraded Guardian experience; someone
      // else's product. The 2026-08-12 pass logged this and left the
      // behaviour, which made it visible without making it right.
      //
      // The cache is written on every successful resolve, so any device
      // that has signed in once knows what it is. A remembered role is a
      // strictly better guess than a hardcoded one, and on a device that
      // has never resolved a role there is nothing to go on and the old
      // default stands.
      final remembered = ZyraLocalPrefs.cachedRole;
      // A remembered role can safely open its own shell through an ordinary
      // connection hiccup. With no remembered role, guessing "Seeker" can
      // expose the wrong product to a Guardian; and an expired session must
      // always return to sign-in rather than opening a cached shell. Let
      // AuthGate present the approved full-screen recovery in both cases.
      if (remembered == null ||
          zyraErrorKindFor(e) == ZyraErrorKind.sessionExpired) {
        debugPrint('ZYRA resolveHome failed ($e) — recovery page required.');
        rethrow;
      }
      debugPrint('ZYRA resolveHome failed ($e) — falling back to $remembered.');
      return remembered == 'wali' ? const WaliHomeShell() : const HomeShell();
    }
  }

  /// Best-effort population of AppState. Deliberately never throws: a
  /// failure here degrades the app to its old behaviour (neutral
  /// gradient, Basic plan) rather than blocking sign-in, which is what
  /// resolveHome's own catch is protecting against.
  static Future<void> _hydrate(String userId, Map<String, dynamic> row) async {
    int? age;
    ZyraPlan? plan;

    // PARALLEL, not sequential — 2026-08-01 (Founder: "when the app loads
    // it still switches from purple to pink on the user for about a
    // second").
    //
    // That flash is the cold-start wait: main.dart's `builder:` paints the
    // NEUTRAL brand gradient behind everything, and the gender-matched
    // gradient can only replace it once we know the gender, which needs a
    // round trip. My first version of this method made it worse by adding
    // two MORE sequential round trips after the profile read — three trips
    // of latency stacked end to end, all of them blocking the first paint.
    //
    // Neither of these is needed to resolve the gradient, so they run
    // together instead of one after the other: total wait is now one round
    // trip, not three.
    //
    // FULLY removing the flash needs the gender cached on-device so launch
    // N+1 paints correctly with no network at all. That means adding
    // shared_preferences as a direct dependency — a call worth making
    // deliberately rather than slipping into a UI fix, so it is not done
    // here. Flagged for the Founder.
    await Future.wait([
      () async {
        try {
          // ages_for_one, not ages_for — one id, one visibility
          // hypothesis (I10, 2026-08-08). The batch form is now capped at
          // 50 and reserved for callers that genuinely have a page of ids.
          final one = await supabase.rpc(
            'ages_for_one',
            params: {'p_id': userId},
          );
          if (one != null) age = (one as num).toInt();
        } catch (_) {
          // age stays null — Profile hides the row, nothing else needs it
        }
      }(),
      () async {
        try {
          // subscriptions has a UNIQUE index on (user_id) WHERE status =
          // 'active', so there is at most one row to find.
          final sub = await supabase
              .from('subscriptions')
              .select('plan_type')
              .eq('user_id', userId)
              .eq('status', 'active')
              .maybeSingle();
          final planType = sub?['plan_type'] as String?;
          // Only seeker_premium maps to ZYRA One. wali_premium is the
          // Guardian's own entitlement, resolved separately by
          // ZyraEntitlementService.hasWaliOne(), not through AppState.plan.
          //
          // 2026-08-12: compares against the canonical db value from
          // constants/zyra_plan_names.dart instead of a raw literal — that
          // file existed precisely for this and had zero importers.
          plan = planType == ZyraSubscriptionPlanType.seekerPremium.dbValue
              ? ZyraPlan.one
              : ZyraPlan.basic;
        } catch (e) {
          debugPrint('ZYRA plan fetch failed: $e'); // 2026-08-12, CLAUDE.md §3
          // plan stays null -> hydrateFrom leaves the existing default
        }
      }(),
    ]);

    AppState.instance.hydrateFrom(
      name: row['first_name'] as String?,
      surnameLine: row['surname_line'] as String?,
      gender: row['gender'] as String?,
      location: row['location_text'] as String?,
      age: age,
      plan: plan,
    );

    // DECISION HYDRATION — ADDED 2026-08-01.
    //
    // Founder, on device: "when I close the app the data goes. I'm
    // assuming this is temporary in dev mode and of course the real user
    // won't experience this."
    //
    // They would have. `saves`, `likes` and `passes` were all being
    // WRITTEN and none of them were ever READ BACK. AppState was filled
    // only by acting in Browse during that session, so every Connections
    // list emptied on relaunch while the rows sat in Postgres untouched.
    // Nothing about it was dev-only.
    //
    // Deliberately NOT inside the Future.wait above. Everything in that
    // block is needed to resolve the gender gradient and therefore blocks
    // first paint; this is not, and it is the heaviest call in the method
    // (three table reads, a profile read and a batched Storage signing
    // pass). Blocking launch on it would trade one bug for a slower cold
    // start — the exact mistake the note above records making once.
    //
    // Fire-and-forget with a notifyListeners() at the end, so Connections
    // fills in a beat after Home rather than delaying Home.
    unawaited(_hydrateDecisions());
  }

  /// Best-effort, never throws. A failure leaves the lists empty, which is
  /// the pre-2026-08-01 behaviour — degraded, not broken.
  static Future<void> _hydrateDecisions() async {
    try {
      // Unlocks load alongside decisions — both are "what has this Seeker
      // already done", both are needed before Connections renders, and
      // neither blocks first paint.
      await ZyraUnlockService.load();
      final d = await ZyraDiscoveryService.fetchDecisions();
      AppState.instance.hydrateDecisions(
        saved: d.saved,
        considered: d.considered,
        passed: d.passed,
      );
    } catch (_) {
      // Intentionally silent — see doc comment.
    }
  }
}
