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
import 'zyra_account_state.dart';
import 'zyra_auth.dart';
import 'zyra_internal_preview_client.dart';

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

/// Server-owned progress for the deferred Seeker profile journey.
///
/// Account access and profile readiness are deliberately separate. A Seeker
/// may enter the app after the short account setup while this object remains
/// incomplete; Browse publication and Journey eligibility continue to use
/// the server's existing completeness gate.
class ZyraOnboardingProgress {
  final bool complete;
  final int due;
  final int missing;
  final bool hasChapter2;
  final bool basicProfile;

  const ZyraOnboardingProgress({
    required this.complete,
    required this.due,
    required this.missing,
    required this.hasChapter2,
    required this.basicProfile,
  });

  int get answered => (due - missing).clamp(0, due);
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

  /// Destructive reset is held pending the approved written data contract.
  /// This client hold performs no SDK, RPC, Storage or local account action.
  /// It does not claim that direct server RPC access has been disabled.
  static Future<ZyraResetResult> resetProfile({
    String? expectedUserId,
    int? expectedGeneration,
  }) async {
    return const ZyraResetResult(ZyraResetOutcome.refused);
  }

  static Future<String?> createSeekerProfile({
    required String firstName,
    required String gender,
    required DateTime dob,
    String? expectedUserId,
  }) => _createProfile(
    role: 'seeker',
    firstName: firstName,
    gender: gender,
    dob: dob,
    expectedUserId: expectedUserId,
  );

  static Future<String?> createWaliProfile({
    required String firstName,
    required String gender,
    required DateTime dob,
    String? expectedUserId,
    bool publishOnCreate = true,
  }) =>
      // The existing helper can publish through a separate guarded RPC.
      // Protected signup instead defers this until real IDV, both names and
      // exact own-row confirmation have passed. These are not atomic writes;
      // its secure draft remains recoverable until finalization succeeds.
      _createProfile(
        role: 'wali',
        firstName: firstName,
        gender: gender,
        dob: dob,
        profileComplete: publishOnCreate,
        expectedUserId: expectedUserId,
      );

  /// Saves only the existing public surname column for the captured account.
  /// A successful HTTP status with zero rows is not confirmation. This cannot
  /// publish, change identity/role, or turn preview data into member data.
  static Future<bool> savePublicSurname(
    String surname, {
    required String expectedUserId,
    required String expectedRole,
    required int expectedGeneration,
  }) async {
    final trimmed = surname.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 60 ||
        !const ['seeker', 'wali'].contains(expectedRole)) {
      return false;
    }
    final session = supabase.auth.currentSession;
    bool ownsAccount() =>
        !ZyraInternalPreviewClient.isActive &&
        !ZyraAccountState.isSigningOut &&
        ZyraAccountState.generation == expectedGeneration &&
        ZyraAuth.currentUser?.id == expectedUserId &&
        session?.user.id == expectedUserId;
    if (!ownsAccount()) return false;
    try {
      final saved = await supabase
          .from('profiles')
          .update({'surname_line': trimmed})
          .eq('id', expectedUserId)
          .eq('role', expectedRole)
          .setHeader('Authorization', 'Bearer ${session!.accessToken}')
          .select('id, role, surname_line')
          .maybeSingle();
      return ownsAccount() &&
          saved?['id'] == expectedUserId &&
          saved?['role'] == expectedRole &&
          saved?['surname_line'] == trimmed;
    } catch (_) {
      debugPrint('ZYRA: public surname save could not be confirmed.');
      return false;
    }
  }

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
  static Future<ZyraOnboardingProgress?> fetchOnboardingProgress() async {
    try {
      final rows = await supabase.rpc('zyra_my_onboarding_progress') as List;
      if (rows.isEmpty) return null;
      final r = rows.first as Map<String, dynamic>;
      return ZyraOnboardingProgress(
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

  static Future<bool> setProfileComplete(
    bool complete, {
    String? expectedUserId,
  }) async {
    final user = ZyraAuth.currentUser;
    if (user == null || (expectedUserId != null && user.id != expectedUserId)) {
      return false;
    }
    final session = supabase.auth.currentSession;
    if (expectedUserId != null && session?.user.id != expectedUserId) {
      return false;
    }
    try {
      var request = supabase.rpc(
        'zyra_set_profile_complete',
        params: {'p_complete': complete},
      );
      if (expectedUserId != null) {
        request = request.setHeader(
          'Authorization',
          'Bearer ${session!.accessToken}',
        );
      }
      final res = await request;
      if (expectedUserId != null &&
          ZyraAuth.currentUser?.id != expectedUserId) {
        return false;
      }
      final status = (res as Map?)?['status'] as String?;
      if (status == 'published' || status == 'unpublished') return true;
      debugPrint(
        'ZYRA: setProfileComplete refused. '
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
  static Future<bool> saveLocation(
    String? city, {
    String? expectedUserId,
  }) async {
    final trimmed = city?.trim();
    if (trimmed == null || trimmed.isEmpty) return false;
    try {
      final user = ZyraAuth.currentUser;
      final generation = ZyraAccountState.generation;
      if (user == null ||
          ZyraAccountState.isSigningOut ||
          (expectedUserId != null && user.id != expectedUserId)) {
        return false;
      }
      final saved = await supabase
          .from('profiles')
          .update({'location_text': trimmed})
          .eq('id', user.id)
          .select('id')
          .maybeSingle();
      return saved?['id'] == user.id &&
          !ZyraAccountState.isSigningOut &&
          ZyraAccountState.generation == generation &&
          ZyraAuth.currentUser?.id == user.id;
    } catch (e) {
      // Logged, not swallowed (ES-08). A failure here is not fatal, but it
      // reproduces exactly the em-dash this method exists to fix, and a
      // silent version of that is what hid the bug for a month.
      debugPrint(
        'ZYRA: saveLocation failed — city will show as "—" (${e.runtimeType}).',
      );
      return false;
    }
  }

  static Future<String?> fetchOwnLocation({
    required String expectedUserId,
  }) async {
    final generation = ZyraAccountState.generation;
    if (ZyraAccountState.isSigningOut ||
        ZyraAuth.currentUser?.id != expectedUserId) {
      throw StateError('Account changed.');
    }
    final row = await supabase
        .from('profiles')
        .select('id, location_text')
        .eq('id', expectedUserId)
        .maybeSingle();
    if (ZyraAuth.currentUser?.id != expectedUserId ||
        ZyraAccountState.isSigningOut ||
        ZyraAccountState.generation != generation ||
        row == null ||
        row['id'] != expectedUserId) {
      throw StateError('Profile unavailable.');
    }
    return row['location_text'] as String?;
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
    // Seekers are NOT complete at this point — this runs after the short
    // account essentials, before their deferred profile journey. Publication
    // remains server-owned and must never be awarded by an onboarding screen.
    // Guardians pass true under the existing Guardian rule (see above).
    bool profileComplete = false,
    String? expectedUserId,
  }) async {
    final user = ZyraAuth.currentUser;
    if (expectedUserId != null && user?.id != expectedUserId) {
      return 'Your sign-in changed. Please sign in again before continuing.';
    }
    final session = supabase.auth.currentSession;
    if (expectedUserId != null && session?.user.id != expectedUserId) {
      return 'Your sign-in changed. Please sign in again before continuing.';
    }
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
      var request = supabase.rpc(
        'zyra_create_profile',
        params: createProfileParams(
          role: role,
          firstName: firstName,
          gender: gender,
          dob: dob,
        ),
      );
      if (expectedUserId != null) {
        request = request.setHeader(
          'Authorization',
          'Bearer ${session!.accessToken}',
        );
      }
      await request;
      if (expectedUserId != null &&
          ZyraAuth.currentUser?.id != expectedUserId) {
        return 'Your sign-in changed. Please sign in again before continuing.';
      }
      debugPrint('ZYRA: zyra_create_profile request completed.');

      // Explicit publication callers still use the RPC, never a direct
      // column write. Initial Guardian signup passes publishOnCreate:false
      // and confirms its required first photo before the separate publish.
      if (profileComplete) {
        final published = await setProfileComplete(
          true,
          expectedUserId: expectedUserId,
        );
        if (expectedUserId != null && !published) {
          return "We couldn't confirm your Guardian setup. Please try again.";
        }
      }
      return null;
    } catch (_) {
      return "Something didn't quite work. Please try again — and if it keeps happening, let us know.";
    }
  }
}
