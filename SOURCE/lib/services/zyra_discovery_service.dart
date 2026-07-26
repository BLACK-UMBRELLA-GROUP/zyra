// Browse discovery + decision persistence. Wires the Browse screen to
// the real `profiles`/`profile_photos` tables for candidate discovery,
// and to `saves`/`likes` for decision persistence.
//
// Real other-Seeker accounts don't exist yet in this preview build —
// realistically only the Founder's own test account is signed in
// today. fetchCandidates() falls back to the existing mockProfiles
// pool whenever the real query returns nothing (not signed in, RLS
// denies, network error, or genuinely zero other real Seekers yet) —
// same graceful-mock-fallback pattern as chapter2_flow.dart's dev/
// no-auth photo path. This keeps Browse always testable while still
// being genuinely live: the moment a second real Seeker signs up and
// completes their profile, they appear for real, no code change
// needed.
//
// Decline is deliberately NOT persisted anywhere, per PROFILE
// DECISION SYSTEM/Summary.md ("no record, no notification") — only
// Save and Like write to the backend.
//
// Compatibility scoring (DR-ZYRA-079, PROPOSED but wired in per that
// DR's own stated next step — see the score_candidates() SECURITY
// DEFINER function, 20260726120200_compatibility_scoring_security_
// definer.sql) is now applied to real candidates: a candidate who
// fails one of the
// signed-in user's Hard Requirements is excluded outright, and the
// remaining candidates are silently ordered by score. The numeric
// score itself is never attached to SeekerProfile or exposed to the
// UI — MATCH_UX_SPEC_CURRENT_VERSION_V1.md / BROWSE_UX_SPEC_CURRENT_
// VERSION_V1.md are both explicit that Compatibility % is "not shown
// anywhere until Active Journey begins." Ordering candidates by an
// unseen score doesn't violate that display rule, but showing the
// number would — so it stays entirely inside this service.

import '../main.dart';
import '../models/seeker_profile.dart';
import 'zyra_auth.dart';
import 'zyra_photo_service.dart';

class ZyraDiscoveryService {
  ZyraDiscoveryService._();

  static Future<List<SeekerProfile>> fetchCandidates() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return mockProfiles;

    try {
      // Own gender first — Browse must "Never display same-gender
      // profiles" (APP/Browse/Script/Script_V1.md), which the original
      // wiring missed. The schema's (gender, is_active,
      // profile_complete) index exists for exactly this query.
      final me = await supabase.from('profiles').select('gender').eq('id', user.id).maybeSingle();
      final myGender = me?['gender'] as String?;
      if (myGender == null) return mockProfiles; // no completed profile yet
      final targetGender = myGender == 'male' ? 'female' : 'male';

      final rows = await supabase
          .from('profiles')
          .select('id, first_name, location_text, gender, profile_photos(storage_path, display_order)')
          .eq('role', 'seeker') // Wali accounts must never appear as candidates
          .eq('gender', targetGender)
          .eq('is_active', true)
          .eq('profile_complete', true)
          .neq('id', user.id) as List;

      if (rows.isEmpty) return mockProfiles;

      // Raw date_of_birth is no longer selectable by the client (see
      // 20260726120000_hide_raw_dob_expose_age.sql) — ages are fetched
      // in one batch call to the ages_for() SECURITY DEFINER function
      // instead, which returns only the derived age.
      final ids = rows.map((r) => (r as Map<String, dynamic>)['id'] as String).toList();
      final ages = await _fetchAges(ids);

      final results = <SeekerProfile>[];
      for (final row in rows) {
        final map = row as Map<String, dynamic>;
        final photosRaw = List<Map<String, dynamic>>.from((map['profile_photos'] as List?) ?? const []);
        if (photosRaw.isEmpty) continue; // no photo — not browsable per Browse spec
        photosRaw.sort((a, b) => (a['display_order'] as int).compareTo(b['display_order'] as int));
        final photos = await ZyraPhotoService.signedUrlsFor(
          photosRaw.map((p) => p['storage_path'] as String).toList(),
        );
        if (photos.isEmpty) continue;

        results.add(SeekerProfile(
          id: map['id'] as String,
          firstName: map['first_name'] as String,
          age: ages[map['id'] as String] ?? 0,
          city: (map['location_text'] as String?) ?? '—',
          photos: photos,
          gender: map['gender'] as String,
        ));
      }
      if (results.isEmpty) return mockProfiles;

      return await _applyCompatibility(user.id, results);
    } catch (_) {
      return mockProfiles;
    }
  }

  /// Excludes candidates who fail a Hard Requirement and orders the
  /// rest by compatibility score, without ever exposing the score
  /// itself. Best-effort — on any failure, returns [candidates]
  /// unchanged rather than breaking Browse over a scoring problem.
  ///
  /// FIXED 2026-07-26 (Founder decision — see ZYRA_FABLE_BUILD_REVIEW_
  /// 2026-07-19_V1.md §Open Decisions item 1): scoring now happens
  /// entirely inside the score_candidates() SECURITY DEFINER function
  /// (20260726120200_compatibility_scoring_security_definer.sql),
  /// which reads both the signed-in user's Ch4 preferences AND each
  /// candidate's Ch3 answers server-side — bypassing the client-facing
  /// own-row-only RLS on onboarding_answers, which stays exactly as
  /// restrictive as before for direct table reads. The client never
  /// sees another user's raw answers, only the returned score.
  static Future<List<SeekerProfile>> _applyCompatibility(String userId, List<SeekerProfile> candidates) async {
    try {
      final candidateIds = candidates.map((c) => c.id).toList();
      final rows = await supabase.rpc('score_candidates', params: {'p_candidate_ids': candidateIds}) as List;
      final scoreByCandidateId = <String, double>{
        for (final row in rows) (row as Map<String, dynamic>)['candidate_id'] as String: (row['score'] as num).toDouble(),
      };

      // Candidates absent from the result were excluded by a Hard
      // Requirement violation server-side.
      final scored = <MapEntry<SeekerProfile, double>>[
        for (final candidate in candidates)
          if (scoreByCandidateId.containsKey(candidate.id)) MapEntry(candidate, scoreByCandidateId[candidate.id]!),
      ];
      scored.sort((a, b) => b.value.compareTo(a.value));
      return scored.map((e) => e.key).toList();
    } catch (_) {
      return candidates;
    }
  }

  /// Batch age lookup via the server-side ages_for() function — see
  /// 20260726120000_hide_raw_dob_expose_age.sql. Best-effort: on any
  /// failure, returns an empty map and callers fall back to age 0
  /// rather than breaking Browse over an age lookup.
  static Future<Map<String, int>> _fetchAges(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final rows = await supabase.rpc('ages_for', params: {'p_ids': ids}) as List;
      return {
        for (final r in rows) (r as Map<String, dynamic>)['id'] as String: (r['age'] as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  /// Best-effort. Mock profile ids aren't real `profiles` rows, so the
  /// FK check fails and the write is silently swallowed — harmless,
  /// since mock candidates have nothing real to persist against.
  static Future<void> recordSave(String savedId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('saves').upsert({'saver_id': user.id, 'saved_id': savedId});
    } catch (_) {}
  }

  static Future<void> recordLike(String likedId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('likes').upsert({'liker_id': user.id, 'liked_id': likedId});
    } catch (_) {}
  }
}
