// Pre-Journey Ritual + Journey Suspension data/service layer, per
// APP/Journey/PRE-JOURNEY RITUAL/Summary.md and APP/Journey/JOURNEY
// SUSPENSION/JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md.
//
// Replaces the old client-only Potential/Active Journey stand-in in
// AppState (a synchronous SeekerProfile-list move with no backend
// behind it) now that matches.status/journey_stage/suspended_by and
// the journey_* tables are real schema (2026-07-25 migration). Same
// style as zyra_match_service.dart / zyra_wali_link_service.dart:
// static methods, the global `supabase` getter, ZyraAuth.currentUser,
// try/catch swallowing to safe defaults everywhere except the three
// RPC calls that need to surface a specific error to the UI.
//
// Out of scope here, per the reduced v1 scope agreed for this pass:
// Part B (searchable personal question library), Wali<->Wali
// engagement in the Family Stage (marked TBC in the source spec
// itself), AI-adaptive question selection/summaries (no LLM
// integration exists in this codebase — see journey_questions.dart),
// push notifications (no notification system exists anywhere yet),
// and the 30-day Full-Suspension auto-end timer (needs a server-side
// scheduled job). Realtime is also out of scope for this pass —
// refetchOne() is a plain re-fetch meant to be driven by a
// Timer.periodic in the UI, the same polling approach used nowhere
// else yet but simpler and safer than standing up a new Realtime
// channel subscription for this task.

import '../main.dart';
import '../models/journey_match.dart';
import '../models/seeker_profile.dart';
import 'zyra_auth.dart';
import 'zyra_photo_service.dart';

/// Thrown by [ZyraJourneyService.promoteToActive] when the caller
/// already holds an Active Journey — ZYRA is one-Active-Journey-at-a-
/// time per seeker. The UI needs to show a specific message for this
/// case rather than a generic failure.
class OneActiveJourneyLimitException implements Exception {}

/// Thrown by [ZyraJourneyService.suspendJourney] when the caller
/// doesn't hold a ZYRA One entitlement (suspend_journey enforces this
/// server-side; client-side plan checks are UI-only, e.g. graying out
/// a Pause button).
class SuspensionRequiresOneException implements Exception {}

/// Thrown by [ZyraJourneyService.resumeJourney] when the other seeker
/// started a new Active Journey while this one was suspended — the
/// RPC ends the Journey rather than reinstating it.
class JourneyAutoEndedException implements Exception {}

class ZyraJourneyService {
  ZyraJourneyService._();

  /// Real matches for the signed-in user in any of [statuses], mapped
  /// to JourneyMatch with the OTHER party's profile attached. Empty on
  /// any failure or if not signed in.
  static Future<List<JourneyMatch>> fetchJourneyMatches({required List<String> statuses}) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return [];

    try {
      final rows = await supabase
          .from('matches')
          .select('id, seeker_a_id, seeker_b_id, status, journey_stage, suspended_by')
          .inFilter('status', statuses)
          .or('seeker_a_id.eq.${user.id},seeker_b_id.eq.${user.id}') as List;

      if (rows.isEmpty) return [];

      final matchByOtherId = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        final map = r as Map<String, dynamic>;
        final a = map['seeker_a_id'] as String;
        final b = map['seeker_b_id'] as String;
        final otherId = a == user.id ? b : a;
        matchByOtherId[otherId] = map;
      }

      final otherIds = matchByOtherId.keys.toList();
      if (otherIds.isEmpty) return [];

      final profileRows = await supabase
          .from('profiles')
          .select('id, first_name, location_text, gender, profile_photos(storage_path, display_order)')
          .inFilter('id', otherIds) as List;

      // Raw date_of_birth is no longer selectable by the client — see
      // 20260726120000_hide_raw_dob_expose_age.sql. Ages come from the
      // ages_for() SECURITY DEFINER function instead.
      final ages = await _fetchAges(otherIds);

      final results = <JourneyMatch>[];
      for (final row in profileRows) {
        final map = row as Map<String, dynamic>;
        final otherId = map['id'] as String;
        final matchRow = matchByOtherId[otherId];
        if (matchRow == null) continue;

        final photosRaw = List<Map<String, dynamic>>.from((map['profile_photos'] as List?) ?? const []);
        photosRaw.sort((a, b) => (a['display_order'] as int).compareTo(b['display_order'] as int));
        final photos = await ZyraPhotoService.signedUrlsFor(
          photosRaw.map((p) => p['storage_path'] as String).toList(),
        );

        final profile = SeekerProfile(
          id: otherId,
          firstName: map['first_name'] as String,
          age: ages[otherId] ?? 0,
          city: (map['location_text'] as String?) ?? '—',
          photos: photos.isEmpty ? ['https://picsum.photos/seed/$otherId/700/1000'] : photos,
          gender: map['gender'] as String,
        );

        results.add(JourneyMatch(
          matchId: matchRow['id'] as String,
          profile: profile,
          status: matchRow['status'] as String,
          journeyStage: matchRow['journey_stage'] as String?,
          suspendedBy: matchRow['suspended_by'] as String?,
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Batch age lookup via the server-side ages_for() function — see
  /// 20260726120000_hide_raw_dob_expose_age.sql. Best-effort: on any
  /// failure, returns an empty map and callers fall back to age 0
  /// rather than breaking Journey/Matches over an age lookup.
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

  static Future<Map<String, dynamic>?> _fetchMatchRow(String matchId) async {
    try {
      return await supabase.from('matches').select('seeker_a_id, seeker_b_id').eq('id', matchId).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  /// Potential -> Active. Throws [OneActiveJourneyLimitException] if
  /// the caller already has an Active Journey; returns false (never
  /// throws) for any other failure.
  static Future<bool> promoteToActive(String matchId) async {
    try {
      await supabase.rpc('promote_journey_to_active', params: {'p_match_id': matchId});
      return true;
    } catch (e) {
      if (e.toString().contains('one_active_journey_limit')) throw OneActiveJourneyLimitException();
      return false;
    }
  }

  /// Best-effort. Swallows errors — the Salam Exchange screen re-reads
  /// state via fetchSalamStatus rather than trusting this call succeeded.
  static Future<void> sendSalam(String matchId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('journey_salams').upsert({'match_id': matchId, 'seeker_id': user.id});
    } catch (_) {}
  }

  static Future<({bool mine, bool theirs})> fetchSalamStatus(String matchId, String otherUserId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return (mine: false, theirs: false);
    try {
      final rows = await supabase.from('journey_salams').select('seeker_id').eq('match_id', matchId) as List;
      final ids = rows.map((r) => (r as Map<String, dynamic>)['seeker_id'] as String).toSet();
      return (mine: ids.contains(user.id), theirs: ids.contains(otherUserId));
    } catch (_) {
      return (mine: false, theirs: false);
    }
  }

  /// Whether [userId] has a linked, active Main Wali — the Wali Gate
  /// requirement. Written generically taking a userId param, though in
  /// practice the Wali Gate only ever checks the ACTING seeker (`me`),
  /// per Summary.md: "A Seeker must have a linked, active Main Wali to
  /// proceed" (their own Wali, not the other party's).
  static Future<bool> hasActiveMainWali(String userId) async {
    try {
      final rows = await supabase
          .from('wali_links')
          .select('id')
          .eq('seeker_id', userId)
          .eq('is_main', true)
          .eq('status', 'active')
          .limit(1) as List;
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Sets the caller's own reveal flag, and — once both parties have
  /// revealed — computes and stores the compatibility score exactly
  /// once (guarded by `overall_score IS NULL`). Callers read the
  /// result back via [fetchCompatibility]; this returns nothing itself.
  static Future<void> revealCompatibility(String matchId, String otherUserId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;
    try {
      final matchRow = await _fetchMatchRow(matchId);
      if (matchRow == null) return;
      final isSeekerA = matchRow['seeker_a_id'] == user.id;
      final myFlagColumn = isSeekerA ? 'seeker_a_revealed' : 'seeker_b_revealed';

      final existing = await supabase.from('journey_compatibility').select('match_id').eq('match_id', matchId).maybeSingle();
      if (existing == null) {
        await supabase.from('journey_compatibility').insert({'match_id': matchId});
      }

      await supabase.from('journey_compatibility').update({myFlagColumn: true}).eq('match_id', matchId);

      final updated = await supabase
          .from('journey_compatibility')
          .select('seeker_a_revealed, seeker_b_revealed, overall_score')
          .eq('match_id', matchId)
          .maybeSingle();
      if (updated == null) return;

      final bothRevealed = updated['seeker_a_revealed'] == true && updated['seeker_b_revealed'] == true;
      if (!bothRevealed || updated['overall_score'] != null) return;

      // FIXED 2026-07-26 (Founder decision — see ZYRA_FABLE_BUILD_REVIEW_
      // 2026-07-19_V1.md §Open Decisions item 1): this used to read
      // otherUserId's onboarding_answers directly from the client,
      // which onboarding_answers' own-row-only RLS always blocked for
      // a second real user — every real Reveal silently fell back to
      // the neutral 50.0 default below. score_candidates() (SECURITY
      // DEFINER, 20260726120200_compatibility_scoring_security_
      // definer.sql) does the read+score server-side instead.
      double score = 50.0; // neutral fallback if scoring is unavailable
      try {
        final rows = await supabase.rpc('score_candidates', params: {
          'p_candidate_ids': [otherUserId],
        }) as List;
        if (rows.isNotEmpty) {
          score = ((rows.first as Map<String, dynamic>)['score'] as num).toDouble();
        }
        // If score_candidates() excludes otherUserId (a Hard
        // Requirement violation), rows comes back empty and the
        // neutral default is kept — Reveal doesn't have a concept of
        // "excluded" post-match, so this is the closest safe fallback.
      } catch (_) {
        // fall through with the neutral default
      }

      // SIMPLIFICATION: a real per-category breakdown would need
      // score_candidates() to expose category-level detail, which it
      // doesn't yet — future work. Every category mirrors the overall
      // score for now.
      final categoryScores = {
        'Deen': score,
        'Marriage Goals': score,
        'Communication': score,
        'Lifestyle': score,
        'Family Expectations': score,
      };

      await supabase.from('journey_compatibility').update({
        'overall_score': score,
        'category_scores': categoryScores,
        'revealed_at': DateTime.now().toIso8601String(),
      }).eq('match_id', matchId);
    } catch (_) {}
  }

  static Future<({bool mine, bool theirs, double? overallScore, Map<String, dynamic>? categoryScores})> fetchCompatibility(
    String matchId,
  ) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return (mine: false, theirs: false, overallScore: null, categoryScores: null);
    try {
      final matchRow = await _fetchMatchRow(matchId);
      if (matchRow == null) return (mine: false, theirs: false, overallScore: null, categoryScores: null);
      final isSeekerA = matchRow['seeker_a_id'] == user.id;

      final row = await supabase
          .from('journey_compatibility')
          .select('seeker_a_revealed, seeker_b_revealed, overall_score, category_scores')
          .eq('match_id', matchId)
          .maybeSingle();
      if (row == null) return (mine: false, theirs: false, overallScore: null, categoryScores: null);

      final mine = isSeekerA ? row['seeker_a_revealed'] == true : row['seeker_b_revealed'] == true;
      final theirs = isSeekerA ? row['seeker_b_revealed'] == true : row['seeker_a_revealed'] == true;
      final overallScore = (row['overall_score'] as num?)?.toDouble();
      final categoryScores = row['category_scores'] == null ? null : Map<String, dynamic>.from(row['category_scores'] as Map);
      return (mine: mine, theirs: theirs, overallScore: overallScore, categoryScores: categoryScores);
    } catch (_) {
      return (mine: false, theirs: false, overallScore: null, categoryScores: null);
    }
  }

  /// Plain insert, matching the "answer all, then reveal" flow —
  /// resubmitting the same question after the phase reveals will fail
  /// against the unique constraint and be silently swallowed, which is
  /// fine: answers aren't editable after submission in this v1.
  static Future<void> submitPhaseAnswer(String matchId, int phase, String questionId, String answerText) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('journey_phase_answers').insert({
        'match_id': matchId,
        'phase': phase,
        'seeker_id': user.id,
        'question_id': questionId,
        'answer_text': answerText,
      });
    } catch (_) {}
  }

  /// {otherPartyOrMineUserId: {questionId: answerText}} for both
  /// seekers in this phase — used both to check "have both submitted
  /// everything" and to render the simultaneous reveal.
  static Future<Map<String, Map<String, String>>> fetchPhaseAnswers(String matchId, int phase) async {
    try {
      final rows = await supabase
          .from('journey_phase_answers')
          .select('seeker_id, question_id, answer_text')
          .eq('match_id', matchId)
          .eq('phase', phase) as List;

      final result = <String, Map<String, String>>{};
      for (final r in rows) {
        final map = r as Map<String, dynamic>;
        final seekerId = map['seeker_id'] as String;
        final questionId = map['question_id'] as String;
        final answerText = map['answer_text'] as String;
        result.putIfAbsent(seekerId, () => {})[questionId] = answerText;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// [rating] is one of 'reassured' / 'discuss_further' / 'concerns'
  /// (Summary.md's private rating phrases). Private to the rater by
  /// RLS — never shown to the other party or the Wali.
  static Future<void> submitRating(String matchId, int phase, String questionId, String rating) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('journey_phase_ratings').insert({
        'match_id': matchId,
        'phase': phase,
        'rater_id': user.id,
        'question_id': questionId,
        'rating': rating,
      });
    } catch (_) {}
  }

  /// [decision] is one of 'continue' / 'ask_more' / 'end'.
  static Future<void> submitCheckpoint(String matchId, int phase, String decision) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('journey_phase_checkpoints').upsert({
        'match_id': matchId,
        'phase': phase,
        'seeker_id': user.id,
        'decision': decision,
      });
    } catch (_) {}
  }

  static Future<Map<String, String>> fetchCheckpoints(String matchId, int phase) async {
    try {
      final rows = await supabase
          .from('journey_phase_checkpoints')
          .select('seeker_id, decision')
          .eq('match_id', matchId)
          .eq('phase', phase) as List;
      return {
        for (final r in rows) (r as Map<String, dynamic>)['seeker_id'] as String: r['decision'] as String,
      };
    } catch (_) {
      return {};
    }
  }

  /// [newStage] is one of the matches.journey_stage CHECK values,
  /// including 'conversation'. Advancing into 'conversation' also
  /// opens the underlying conversation row so messaging actually
  /// unlocks (it defaults to 'closed' until the Ritual completes).
  static Future<void> advanceStage(String matchId, String newStage) async {
    try {
      await supabase.from('matches').update({'journey_stage': newStage}).eq('id', matchId);
      if (newStage == 'conversation') {
        await supabase.from('conversations').update({'status': 'active'}).eq('match_id', matchId);
      }
    } catch (_) {}
  }

  /// [direction] is 'seeker_to_wali' or 'wali_to_seeker'. Plain
  /// insert, same reasoning as submitPhaseAnswer.
  static Future<void> submitFamilyAnswer(String matchId, String direction, String questionId, String answerText) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('journey_family_answers').insert({
        'match_id': matchId,
        'direction': direction,
        'question_id': questionId,
        'answerer_id': user.id,
        'answer_text': answerText,
      });
    } catch (_) {}
  }

  /// {questionId: answerText}. Ordered by created_at so that if
  /// multiple rows ever share a question_id (multiple answerers on
  /// one side), the later insert wins in the returned map.
  static Future<Map<String, String>> fetchFamilyAnswers(String matchId, String direction) async {
    try {
      final rows = await supabase
          .from('journey_family_answers')
          .select('question_id, answer_text, created_at')
          .eq('match_id', matchId)
          .eq('direction', direction)
          .order('created_at') as List;

      final result = <String, String>{};
      for (final r in rows) {
        final map = r as Map<String, dynamic>;
        result[map['question_id'] as String] = map['answer_text'] as String;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Throws [SuspensionRequiresOneException] if the caller doesn't
  /// hold ZYRA One; swallows any other error (caller can refetch state
  /// to see the suspension didn't take effect).
  static Future<void> suspendJourney(String matchId) async {
    try {
      await supabase.rpc('suspend_journey', params: {'p_match_id': matchId});
    } catch (e) {
      if (e.toString().contains('suspension_requires_one')) throw SuspensionRequiresOneException();
    }
  }

  /// Throws [JourneyAutoEndedException] if the other seeker started a
  /// new Active Journey while this one was suspended.
  static Future<void> resumeJourney(String matchId) async {
    try {
      await supabase.rpc('resume_journey', params: {'p_match_id': matchId});
    } catch (e) {
      if (e.toString().contains('auto_ended')) throw JourneyAutoEndedException();
    }
  }

  static Future<void> endJourney(String matchId) async {
    try {
      await supabase.rpc('end_journey', params: {'p_match_id': matchId});
    } catch (_) {}
  }

  /// Plain re-fetch of one match's current status/stage/suspension —
  /// meant to be driven by a Timer.periodic (e.g. every 3 seconds)
  /// while the UI waits on the other party, rather than a Realtime
  /// channel subscription (out of scope for this pass). Null on any
  /// failure or if the match/profile can no longer be found.
  static Future<JourneyMatch?> refetchOne(String matchId, String otherUserId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;
    try {
      final matchRow = await supabase
          .from('matches')
          .select('id, status, journey_stage, suspended_by')
          .eq('id', matchId)
          .maybeSingle();
      if (matchRow == null) return null;

      final profileRow = await supabase
          .from('profiles')
          .select('id, first_name, location_text, gender, profile_photos(storage_path, display_order)')
          .eq('id', otherUserId)
          .maybeSingle();
      if (profileRow == null) return null;

      // Raw date_of_birth is no longer selectable by the client — see
      // 20260726120000_hide_raw_dob_expose_age.sql.
      final ages = await _fetchAges([otherUserId]);

      final photosRaw = List<Map<String, dynamic>>.from((profileRow['profile_photos'] as List?) ?? const []);
      photosRaw.sort((a, b) => (a['display_order'] as int).compareTo(b['display_order'] as int));
      final photos = await ZyraPhotoService.signedUrlsFor(
        photosRaw.map((p) => p['storage_path'] as String).toList(),
      );

      final profile = SeekerProfile(
        id: profileRow['id'] as String,
        firstName: profileRow['first_name'] as String,
        age: ages[otherUserId] ?? 0,
        city: (profileRow['location_text'] as String?) ?? '—',
        photos: photos.isEmpty ? ['https://picsum.photos/seed/${profileRow['id']}/700/1000'] : photos,
        gender: profileRow['gender'] as String,
      );

      return JourneyMatch(
        matchId: matchRow['id'] as String,
        profile: profile,
        status: matchRow['status'] as String,
        journeyStage: matchRow['journey_stage'] as String?,
        suspendedBy: matchRow['suspended_by'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
