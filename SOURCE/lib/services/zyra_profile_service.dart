// Writes the `profiles` row once onboarding has collected the fields
// the schema requires (ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md —
// first_name, date_of_birth, gender are all NOT NULL). Called from
// OnboardingFlow (Seeker, Chapter 1 completion) and WaliOnboardingFlow
// (Wali, onboarding completion).
//
// Guarded by ZyraAuth.isSignedIn throughout this build: if Supabase
// isn't configured, or the user reached onboarding without a real
// session (shouldn't happen in the real flow, but the mock/dev-access
// jump-menu can land here directly for testing), this silently no-ops
// rather than throwing — AppState's in-memory fields keep working
// exactly as before either way.

import 'package:flutter/foundation.dart' show debugPrint;
import '../main.dart';
import 'zyra_auth.dart';

/// The three things a reset can do, kept apart because they need three
/// different sentences. A blocked reset is not a failure — it is the
/// feature working — and reporting it as "something went wrong" would send
/// someone to support over a rule we chose on purpose.
enum ZyraResetOutcome { done, blockedByJourney, refused, failed }

class ZyraResetResult {
  final ZyraResetOutcome outcome;
  final int activeJourneys;
  const ZyraResetResult(this.outcome, {this.activeJourneys = 0});
}

class ZyraProfileService {
  ZyraProfileService._();

  static Map<String, dynamic> createProfileParams({
    required String role,
    required String firstName,
    required String gender,
    required DateTime dob,
  }) => {
    'p_role': role,
    'p_first_name': firstName,
    'p_gender': gender,
    'p_dob': dob.toIso8601String().split('T').first,
  };

  /// Reset profile — start fresh without deleting the account.
  ///
  /// Founder decision 2026-08-07. Clears answers, details, photos, bio,
  /// location AND all discovery history in both directions — including
  /// other people's likes, saves and passes about this user, which is the
  /// only way "start fresh" actually means anything. Someone who has been
  /// passed over stays invisible to those people otherwise, which is
  /// exactly who they were trying to reach.
  ///
  /// KEEPS identity (still frozen — a reset is not a route to becoming
  /// someone else), Guardians, unlock credits, subscription, matches,
  /// consent evidence and any reports made against them.
  ///
  /// Refuses while an Active Journey exists. See zyra_reset_profile() for
  /// the full reasoning on each of those.
  static Future<ZyraResetResult> resetProfile() async {
    if (!ZyraAuth.isSignedIn) {
      return const ZyraResetResult(ZyraResetOutcome.failed);
    }
    try {
      final res =
          await supabase.rpc('zyra_reset_profile') as Map<String, dynamic>;
      final status = res['status'] as String?;

      if (status == 'blocked') {
        return ZyraResetResult(
          ZyraResetOutcome.blockedByJourney,
          activeJourneys: (res['active'] as num?)?.toInt() ?? 1,
        );
      }
      if (status == 'refused') {
        return const ZyraResetResult(ZyraResetOutcome.refused);
      }
      if (status != 'reset') {
        debugPrint(
          'ZYRA: zyra_reset_profile returned an unknown status — $res',
        );
        return const ZyraResetResult(ZyraResetOutcome.failed);
      }

      // The rows are already gone; this clears the objects behind them.
      // Best-effort by design — the reset itself has committed, so failing
      // here must not report failure and invite a retry that would do
      // nothing. Orphaned objects are a storage cost, not a broken account.
      //
      // The RPC returns ONLY paths under this user's own prefix, so there
      // is nothing here that could remove someone else's file even if the
      // bucket would allow it.
      try {
        final paths =
            (res['storage_paths'] as List?)?.cast<String>() ?? const <String>[];
        if (paths.isNotEmpty) {
          await supabase.storage.from('profile-photos').remove(paths);
        }
      } catch (e) {
        debugPrint(
          'ZYRA: profile reset succeeded, photo objects were not removed.\n$e',
        );
      }

      return const ZyraResetResult(ZyraResetOutcome.done);
    } catch (e) {
      debugPrint('ZYRA: zyra_reset_profile failed.\n$e');
      return const ZyraResetResult(ZyraResetOutcome.failed);
    }
  }

  static Future<String?> createSeekerProfile({
    required String firstName,
    required String gender,
    required DateTime dob,
  }) => _createProfile(
    role: 'seeker',
    firstName: firstName,
    gender: gender,
    dob: dob,
  );

  static Future<String?> createWaliProfile({
    required String firstName,
    required String gender,
    required DateTime dob,
  }) =>
      // profileComplete: true — FIXED 2026-08-01 (audit finding C3,
      // second symptom). Unlike a Seeker, a Guardian has nothing further to
      // complete: "Guardian accounts carry identity only" (WALI_ARCHITECTURE
      // V5), there are no photos and no ID check, so this row IS complete
      // the moment it's written. Leaving it false meant profiles_select's
      // RLS (`id = auth.uid() OR (is_active AND profile_complete)`) hid
      // every Guardian from everyone else — including from their own linked
      // Seeker. zyra_wali_link_service.dart:108 reads profiles directly
      // for linked people's names, so that query silently returned
      // nothing and the Wali/Seeker link rendered nameless. Set here,
      // atomically with the insert, rather than as a follow-up write that
      // could fail and leave a half-created Wali.
      _createProfile(
        role: 'wali',
        firstName: firstName,
        gender: gender,
        dob: dob,
        profileComplete: true,
      );

  /// Marks the signed-in user's profile complete — the single switch that
  /// makes them visible to anyone else on the platform.
  ///
  /// ADDED 2026-08-01 (audit finding C3 — the highest-impact bug in the
  /// codebase). Nothing anywhere wrote `profile_complete`. It defaults to
  /// FALSE, and three separate things gate on it being true:
  ///   • profiles_select RLS — hides the whole row from other users
  ///   • profile_photos_select RLS + storage read policy — hides photos
  ///   • ZyraDiscoveryService.fetchCandidates — `.eq('profile_complete', true)`
  /// So no genuinely new Seeker could EVER appear in Browse. The 24
  /// visible profiles in the dev database are visible only because the
  /// seed SQL set the flag by hand. The bug stayed hidden because
  /// fetchCandidates falls back to mockProfiles on an empty result, so
  /// Browse always looked populated.
  ///
  /// Returns true on success. Logged rather than silently swallowed
  /// (ES-08) — if this call fails the user is invisible to the entire
  /// platform, which is exactly the class of failure that must never be
  /// silent again.
  /// MOVED BEHIND AN RPC 2026-08-04 (C-3). `profile_complete` is a
  /// publication gate, not a user setting — it is what makes someone
  /// visible to the whole platform — so the client no longer writes it.
  /// `zyra_set_profile_complete()` re-checks identity fields and, for a
  /// Seeker, that at least one photo exists.
  ///
  /// Returns true only when the server actually published. A false here can
  /// now mean "incomplete" as well as "failed", and the reason is logged.
  /// How far through onboarding this Seeker is, as the SERVER sees it.
  ///
  /// ADDED 2026-08-11 with the completeness gate (OA-ZYRA-193c). The gate is
  /// enforced in zyra_can_view_profile and zyra_can_match, which means an
  /// unfinished Seeker sees an empty Browse and is told nothing about why.
  /// That is the failure this exists to prevent: a refusal with no
  /// explanation is indistinguishable from a broken app, and this codebase
  /// has already lost a month to exactly that with `profile_complete`.
  ///
  /// Read from the server rather than counted client-side on purpose. The
  /// client knows which questions it SHOWED; only the server knows which
  /// ones the gate is actually waiting on, and if the two ever disagree the
  /// one holding the door is the one worth asking.
  static Future<
    ({
      bool complete,
      int due,
      int missing,
      bool hasChapter2,
      bool basicProfile,
    })?
  >
  fetchOnboardingProgress() async {
    try {
      final rows = await supabase.rpc('zyra_my_onboarding_progress') as List;
      if (rows.isEmpty) return null;
      final r = rows.first as Map<String, dynamic>;
      return (
        complete: r['complete'] == true,
        due: (r['questions_due'] as num?)?.toInt() ?? 0,
        missing: (r['questions_missing'] as num?)?.toInt() ?? 0,
        hasChapter2: r['has_chapter_2'] == true,
        basicProfile: r['basic_profile'] == true,
      );
    } catch (e) {
      debugPrint('ZYRA: fetchOnboardingProgress failed - $e');
      return null;
    }
  }

  static Future<bool> setProfileComplete(bool complete) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false;
    try {
      final res = await supabase.rpc(
        'zyra_set_profile_complete',
        params: {'p_complete': complete},
      );
      final status = (res as Map?)?['status'] as String?;
      if (status == 'published' || status == 'unpublished') return true;
      debugPrint(
        'ZYRA: setProfileComplete refused — $res. '
        'Profile stays invisible to other users.',
      );
      return false;
    } catch (e) {
      debugPrint(
        'ZYRA: setProfileComplete($complete) failed — profile stays invisible to other users. $e',
      );
      return false;
    }
  }

  /// Writes the Seeker's city to `profiles.location_text`.
  ///
  /// ADDED 2026-08-04. `location_text` has existed since the table was
  /// built and THREE services read it:
  ///
  ///   zyra_discovery_service.dart:123   `city: map['location_text'] ?? '—'`
  ///   zyra_discovery_service.dart:264   same
  ///   zyra_match_service.dart:86        same
  ///
  /// Nothing anywhere wrote it. Chapter 2 asks "Where do you currently
  /// live?", stores the answer in AppState, and that was the end of it —
  /// so every genuinely-onboarded Seeker showed an em-dash where their
  /// city should be, on their Browse card and on every match.
  ///
  /// It stayed invisible for the same reason the `profile_complete` bug
  /// did: the seeded dev profiles have the column filled in by hand, so
  /// the only profiles anyone ever looked at already had a city.
  ///
  /// UPDATE, not upsert. An upsert here would need the full row and would
  /// risk the same un-publishing failure mode documented on `_createProfile`
  /// below. By Chapter 2 the row already exists — Chapter 1 created it.
  ///
  /// Free text by design: there is no geocoding in this project and no plan
  /// for any (see chapter2_flow.dart's note on why mileage bands were
  /// dropped). "London" and "london" are two different strings here and
  /// nothing pretends otherwise.
  static Future<bool> saveLocation(String? city) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false; // mock/offline session — nothing to write
    final trimmed = city?.trim();
    if (trimmed == null || trimmed.isEmpty) return false;
    try {
      await supabase
          .from('profiles')
          .update({'location_text': trimmed})
          .eq('id', user.id);
      return true;
    } catch (e) {
      // Logged, not swallowed (ES-08). A failure here is not fatal, but it
      // reproduces exactly the em-dash this method exists to fix, and a
      // silent version of that is what hid the bug for a month.
      debugPrint(
        'ZYRA: saveLocation("$trimmed") failed — city will show as "—". $e',
      );
      return false;
    }
  }

  /// Toggles the signed-in user's own `is_active` flag — the same
  /// column Browse's discovery query already filters on
  /// (zyra_discovery_service.dart: `.eq('is_active', true)`) and that
  /// profiles_select's RLS policy uses to decide whether a row is
  /// visible to anyone other than its owner. Setting this false
  /// genuinely removes the Seeker from Browse for everyone else —
  /// this is real, not cosmetic. Added 2026-07-26 for the Privacy
  /// settings screen (Settings/Search/Notifications build-out).
  /// Returns true on success.
  static Future<bool> setVisibility(bool visible) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false;
    try {
      await supabase
          .from('profiles')
          .update({'is_active': visible})
          .eq('id', user.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Current `is_active` value for the signed-in user, or null if not
  /// signed in / on any failure (caller should treat null as unknown,
  /// not as a specific value).
  static Future<bool?> fetchVisibility() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;
    try {
      final row = await supabase
          .from('profiles')
          .select('is_active')
          .eq('id', user.id)
          .maybeSingle();
      return row?['is_active'] as bool?;
    } catch (_) {
      return null;
    }
  }

  /// Returns an error message on failure, or null on success/no-op.
  static Future<String?> _createProfile({
    required String role,
    required String firstName,
    required String gender,
    required DateTime dob,
    // Seekers are NOT complete at this point — this runs at Chapter 1,
    // long before photos, so they stay false until ProfileReadyScreen's
    // checks pass. Guardians pass true (see createWaliProfile).
    bool profileComplete = false,
  }) async {
    final user = ZyraAuth.currentUser;
    if (user == null) {
      return null; // not signed in via Supabase — mock-only path, nothing to write
    }

    try {
      // RPC, not an upsert — C-3, 2026-08-04. `authenticated` no longer
      // holds INSERT or unrestricted UPDATE on `profiles`, because that
      // grant let any user set role='admin' (a value the column's own CHECK
      // explicitly permits), rewrite their date of birth, switch gender past
      // the segregation rule, and publish themselves.
      //
      // The RPC refuses 'admin' outright, enforces 18+, and freezes gender
      // and DOB once a profile is published — while still allowing a name
      // correction, which is the one thing people legitimately come back for.
      //
      // The old upsert's careful `profile_complete` handling is no longer
      // needed here: the RPC never touches that column at all, so
      // re-entering Chapter 1 cannot un-publish a live Seeker. The failure
      // mode is gone rather than guarded against.
      final res = await supabase.rpc(
        'zyra_create_profile',
        params: createProfileParams(
          role: role,
          firstName: firstName,
          gender: gender,
          dob: dob,
        ),
      );
      debugPrint('ZYRA: zyra_create_profile -> $res');

      // Guardians are complete the moment their row exists — no photos, no
      // further chapters. Goes through the publication RPC like everything
      // else rather than writing the column directly.
      if (profileComplete) await setProfileComplete(true);
      return null;
    } catch (_) {
      return "Something didn't quite work. Please try again — and if it keeps happening, let us know.";
    }
  }
}
