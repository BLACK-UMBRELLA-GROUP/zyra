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
// and the 30-day Full-Suspension auto-end timer — which was never built
// and is now REMOVED BY DECISION (OA-ZYRA-164, DR-ZYRA-121 item 12: ZYRA
// never ends a Journey automatically; it reminds at 30 and 90 days and
// leaves the choice to the people). Realtime is also out of scope for this pass —
// refetchOne() is a plain re-fetch meant to be driven by a
// Timer.periodic in the UI, the same polling approach used nowhere
// else yet but simpler and safer than standing up a new Realtime
// channel subscription for this task.

import 'package:flutter/foundation.dart' show debugPrint;

import '../main.dart';
import '../models/journey_match.dart';
import '../models/seeker_profile.dart';
import 'zyra_auth.dart';
import 'zyra_photo_service.dart';
import 'zyra_ages_service.dart';

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

/// RETIRED 2026-08-06 — OA-ZYRA-164. The server no longer auto-ends, so
/// this can no longer be thrown. Kept briefly so any caller still catching
/// it is found by the analyzer rather than by a user.
@Deprecated('The platform no longer ends Journeys automatically (DR-ZYRA-121 '
    'item 12). Catch OtherPartyInActiveJourneyException instead.')
class JourneyAutoEndedException implements Exception {}

/// Resume refused: the other Seeker currently holds an Active Journey.
///
/// NOT an ending. The Journey stays exactly as it was — paused, intact,
/// resumable later. This is a "not yet", and the copy must say so.
class OtherPartyInActiveJourneyException implements Exception {}

/// Resume refused: one of the two has blocked the other, or one is now the
/// other's Guardian. Server code `not_eligible_to_continue`.
///
/// This one IS terminal, and the copy must NOT imply otherwise — unlike
/// [OtherPartyInActiveJourneyException], waiting will not help. The
/// Journey stays paused and the only real exit is ending it.
///
/// Added 2026-08-08 with OA-ZYRA-174. Before then resume_journey raised
/// `not_eligible_to_match` off the full zyra_can_match() predicate, which
/// included Tier-1 (the two share a Guardian) — so a third party's action
/// could trap a Journey with an error the Seeker could not act on. Tier-1
/// is now grandfathered for Journeys already under way; only blocks and
/// Tier-0 refuse a resume, and both are visible to the two parties.
class NotEligibleToContinueException implements Exception {}

/// Unreferenced since 2026-08-06 (OA-ZYRA-154) — the 24-hour restart
/// cooling period it reported no longer exists.
///
/// Kept, not deleted: V3 §9 gives Request New Journey a **6-month** cooldown
/// after a decline (OA-ZYRA-159), so a cooldown exception returns shortly.
/// Deleting and re-adding it would lose the trail between the two rules.
class CoolingPeriodActiveException implements Exception {}

/// Outcome of [ZyraJourneyService.advanceStage].
///
/// [reason] is the server's own vocabulary, returned by
/// zyra_advance_stage(): advanced · waiting_for_reveal ·
/// waiting_for_continue · waiting_for_salam · guardian_required_self ·
/// guardian_required_other · stage_moved · journey_paused ·
/// journey_not_active · terminal_stage · call_failed.
///
/// SURFACE IT. The defect this replaced (release blocker, Founder
/// 2026-08-07) was invisible for a month precisely because the old
/// advanceStage() returned void from inside a bare `catch (_) {}` — a
/// write RLS discarded looked identical to one that worked.
class ZyraStageAdvance {
  final bool advanced;
  final String? stage;
  final String reason;
  const ZyraStageAdvance(this.advanced, this.stage, this.reason);

  /// The call itself failed — network, auth, or an exception the server
  /// raised (not_a_party, gated_transition, match_not_found). Distinct
  /// from a legitimate "not yet" reason.
  static const failed = ZyraStageAdvance(false, null, 'call_failed');
}

/// Outcome of [ZyraJourneyService.openFamilyReview].
///
/// Deliberately the same shape as [ZyraStageAdvance], and deliberately
/// the same vocabulary where the two overlap. These are the TWO DOORS
/// into one state machine — zyra_advance_stage for the three direct
/// transitions, open_family_review for the four gated ones — and a
/// caller should not have to learn two dialects to ask "why didn't that
/// work".
///
/// [reason] carries the server's own word:
///   opened · stage_moved · journey_paused · journey_not_active ·
///   not_a_gated_transition · invalid_transition · not_a_party ·
///   call_failed
///
/// ADDED 2026-08-09 with the audit 2.2 fix. Until then this call returned
/// `String?` from inside a bare `catch (_)`, and its one caller discarded
/// even that — so a refusal and a success were the same event: a tap, a
/// refresh, and nothing moving. That is the exact shape of the 2026-08-07
/// release blocker, and tightening the server made it MORE reachable, not
/// less. A validation you cannot see refuse you is indistinguishable from
/// a bug.
class ZyraReviewOpen {
  /// The pending review — newly created, or the existing one, since the
  /// RPC is idempotent. Null means it was refused.
  final String? reviewId;
  final String reason;
  const ZyraReviewOpen(this.reviewId, this.reason);

  bool get ok => reviewId != null;

  static const failed = ZyraReviewOpen(null, 'call_failed');
}

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
          .select('id, seeker_a_id, seeker_b_id, status, journey_stage, suspended_by, ended_at')
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
          endedAt: matchRow['ended_at'] == null ? null : DateTime.parse(matchRow['ended_at'] as String),
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
    // Delegates since 2026-08-08 — see ZyraAgesService for why four
    // identical private copies of this became one.
    return ZyraAgesService.forIds(ids, context: 'journeys');
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
      // ignoreDuplicates: true — RELEASE BLOCKER FIX 2026-08-09, audit
      // finding 1.1. A bare .upsert() sends ON CONFLICT DO UPDATE, which
      // needs the UPDATE privilege at plan time; `authenticated` has
      // INSERT on this table and no UPDATE, so every Salam was refused
      // with 42501 and swallowed here. zyra_advance_stage then returned
      // waiting_for_salam forever and the Journey could not leave the
      // Salam Exchange — a SECOND, independent cause of the same stuck
      // screen the advanceStage no-op caused on 2026-08-07.
      //
      // DO NOTHING is also the right semantics: the primary key IS
      // (match_id, seeker_id) and there is no payload. A Salam is sent
      // once; sending it again is a no-op, not an overwrite.
      await supabase.from('journey_salams').upsert(
        {'match_id': matchId, 'seeker_id': user.id},
        onConflict: 'match_id,seeker_id',
        ignoreDuplicates: true,
      );
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
  /// per Summary.md: "A Seeker must have a linked, active Main Guardian to
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
      // ignoreDuplicates: true — audit finding 1.1, same 42501 as the
      // Salam above.
      //
      // THIS ONE CARRIES A PAYLOAD, so DO NOTHING is a real behavioural
      // choice and not just a permission workaround: the FIRST decision
      // stands and a later submission is ignored. Checked before making
      // it — journey_flow_screen renders the Continue / End buttons only
      // `if (myCheckpoint == null)`, so there is no path in the app to
      // change a checkpoint once it is recorded. First-write-wins matches
      // what the UI already promises.
      //
      // If a "change your mind" flow is ever added, this needs an RPC or
      // a self-scoped UPDATE grant — not a bare upsert. Leaving that note
      // here rather than discovering it as a silent no-op later.
      await supabase.from('journey_phase_checkpoints').upsert(
        {
          'match_id': matchId,
          'phase': phase,
          'seeker_id': user.id,
          'decision': decision,
        },
        onConflict: 'match_id,phase,seeker_id',
        ignoreDuplicates: true,
      );
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

  /// Advances one of the THREE ungated Pre-Journey Ritual transitions:
  /// compatibility_reveal -> salam_exchange -> wali_gate -> phase_1.
  ///
  /// Takes the stage the caller believes it has COMPLETED, not the one
  /// it wants next. The server owns the map, so a client cannot name a
  /// destination and there is no skip-ahead to validate; it also acts as
  /// a compare-and-swap token, so a stale screen gets 'stage_moved'
  /// rather than dragging the Journey backwards.
  ///
  /// The four Family-Review-gated transitions (phase_1->2, phase_2->3,
  /// phase_3->family_stage, family_stage->conversation) are REFUSED by
  /// the server — they go through [openFamilyReview]. Accepting them
  /// here would be a way to skip the 48-hour review period.
  ///
  /// REPLACED 2026-08-08 (release blocker, Founder-classified
  /// 2026-08-07). The previous implementation wrote matches.journey_stage
  /// directly. `matches` has a SELECT policy and no UPDATE policy, so
  /// RLS discarded the write: 0 rows, no exception, inside catch (_) {}.
  /// Because these are the FIRST three transitions, no Journey could ever
  /// leave compatibility_reveal. Verified live before and after.
  ///
  /// The 'conversation' branch is gone with it: that stage is reachable
  /// only via the gated path, and resolve_family_review_if_due() /
  /// wali_review_decision() already open the conversation row server-side.
  static Future<ZyraStageAdvance> advanceStage(String matchId, String fromStage) async {
    try {
      final rows = await supabase.rpc('zyra_advance_stage', params: {
        'p_match_id': matchId,
        'p_from_stage': fromStage,
      });
      if (rows is! List || rows.isEmpty) {
        debugPrint('[ZyraJourneyService.advanceStage] $matchId from=$fromStage returned no row');
        return ZyraStageAdvance.failed;
      }
      final r = rows.first as Map<String, dynamic>;
      return ZyraStageAdvance(
        r['advanced'] == true,
        r['stage'] as String?,
        (r['reason'] as String?) ?? 'unknown',
      );
    } catch (e) {
      // ES-08. Never silent again — this is the exact call site whose
      // silence hid the blocker.
      debugPrint('[ZyraJourneyService.advanceStage] $matchId from=$fromStage failed: $e');
      return ZyraStageAdvance.failed;
    }
  }

  // --- Family Review Period (#31) ---------------------------------------
  //
  // WALI_ARCHITECTURE_CURRENT_VERSION_V6.md: "After both Seekers
  // complete a Journey stage, the next stage does not unlock
  // immediately. Instead, the Journey enters a 48-hour Family Review
  // Period." Backed by 20260726190000_family_review_period.sql — see
  // that migration's own header comment for the full v1 scope
  // reasoning (which transitions are gated, who participates,
  // resolution rules) and DR-ZYRA-110.

  /// Opens (or returns the existing) pending Family Review for
  /// [matchId]'s transition from [fromStage] to [toStage]. Safe to call
  /// from both Seekers' clients without double-opening — the RPC is
  /// idempotent.
  ///
  /// SINCE 2026-08-09 the server VALIDATES this call rather than trusting
  /// it (audit 2.2 — it used to accept any stage pair, so one Seeker
  /// alone could jump the whole Journey to Conversation). It now refuses
  /// a transition that is not one of the four gated ones, a to_stage that
  /// is not the real successor, a from_stage that is not where the
  /// Journey actually is, and an ended or paused Journey.
  ///
  /// Which means this can now legitimately FAIL for a user doing nothing
  /// wrong — most realistically `stage_moved`, when the other Seeker's
  /// client opened the review a moment earlier. So it returns a reason
  /// instead of null. See [ZyraReviewOpen].
  static Future<ZyraReviewOpen> openFamilyReview(String matchId, String fromStage, String toStage) async {
    try {
      final id = await supabase.rpc('open_family_review', params: {
        'p_match_id': matchId,
        'p_from_stage': fromStage,
        'p_to_stage': toStage,
      });
      if (id == null) {
        debugPrint('[ZyraJourneyService.openFamilyReview] $matchId '
            '$fromStage->$toStage returned null');
        return ZyraReviewOpen.failed;
      }
      return ZyraReviewOpen(id as String, 'opened');
    } catch (e) {
      // Named server errors are matched on the message, which is the
      // idiom already used for one_active_journey_limit,
      // suspension_requires_one and not_eligible_to_continue above.
      debugPrint('[ZyraJourneyService.openFamilyReview] $matchId '
          '$fromStage->$toStage refused: $e');
      final s = e.toString();
      if (s.contains('stage_moved')) return const ZyraReviewOpen(null, 'stage_moved');
      if (s.contains('journey_paused')) return const ZyraReviewOpen(null, 'journey_paused');
      if (s.contains('journey_not_active')) return const ZyraReviewOpen(null, 'journey_not_active');
      if (s.contains('not_a_gated_transition')) return const ZyraReviewOpen(null, 'not_a_gated_transition');
      if (s.contains('invalid_transition')) return const ZyraReviewOpen(null, 'invalid_transition');
      if (s.contains('not a party')) return const ZyraReviewOpen(null, 'not_a_party');
      return ZyraReviewOpen.failed;
    }
  }

  /// Current review for [matchId] (pending OR paused — resolved/
  /// 'continued' reviews are historical and not returned once the
  /// stage has actually moved on). Null if there's no live review.
  static Future<({String id, String status, String toStage, DateTime deadlineAt})?> fetchFamilyReview(String matchId) async {
    try {
      final row = await supabase
          .from('journey_family_reviews')
          .select('id, status, to_stage, deadline_at')
          .eq('match_id', matchId)
          .inFilter('status', ['pending', 'paused'])
          .maybeSingle();
      if (row == null) return null;
      return (
        id: row['id'] as String,
        status: row['status'] as String,
        toStage: row['to_stage'] as String,
        deadlineAt: DateTime.parse(row['deadline_at'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  /// Which of [matchIds] currently have an OPEN Family Review — ONE
  /// query for the whole list.
  ///
  /// [fetchFamilyReview] answers "what is the review" for a single match
  /// and is right for a detail screen. This answers only "is one open"
  /// and is the one a LIST must use: a per-card fetchFamilyReview is N+1,
  /// and on the Guardian Dashboard N is the number of Seekers a Guardian
  /// looks after.
  ///
  /// Same definition of open as fetchFamilyReview — 'pending' or 'paused'
  /// — deliberately, so the two can never disagree about whether a
  /// Journey is stalled.
  ///
  /// RLS (20260726190000_family_review_period.sql) grants this to a party
  /// to the match, or to a linked Guardian with is_main = TRUE. An
  /// ADDITIONAL Guardian reads nothing here and so never sees the Family
  /// Review override on their list. That is the existing policy, not a
  /// limitation introduced by this method — the detail screen has always
  /// behaved the same way.
  ///
  /// Empty on any failure, which degrades to showing the underlying
  /// stage. That is never wrong, only less specific.
  static Future<Set<String>> fetchOpenReviewMatchIds(List<String> matchIds) async {
    if (matchIds.isEmpty) return {};
    try {
      final rows = await supabase
          .from('journey_family_reviews')
          .select('match_id')
          .inFilter('match_id', matchIds)
          .inFilter('status', ['pending', 'paused']) as List;
      return {
        for (final r in rows) (r as Map<String, dynamic>)['match_id'] as String,
      };
    } catch (_) {
      return {};
    }
  }

  /// Best-effort lazy timeout check — called from the same 3-second
  /// poll journey_flow_screen.dart already runs for every other stage.
  /// No-op server-side if there's nothing due yet.
  static Future<void> resolveFamilyReviewIfDue(String matchId) async {
    try {
      await supabase.rpc('resolve_family_review_if_due', params: {'p_match_id': matchId});
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

  static Future<void> resumeJourney(String matchId) async {
    try {
      await supabase.rpc('resume_journey', params: {'p_match_id': matchId});
    } catch (e) {
      if (e.toString().contains('other_party_in_active_journey')) {
        throw OtherPartyInActiveJourneyException();
      }
      // OA-ZYRA-174, 2026-08-08. Was `not_eligible_to_match`, raised off the
      // whole zyra_can_match() predicate; now the narrower blocks-and-Tier-0
      // check. Left unnamed it would reach the UI as a raw PostgrestException.
      if (e.toString().contains('not_eligible_to_continue')) {
        throw NotEligibleToContinueException();
      }
      debugPrint('ZYRA: resumeJourney($matchId) failed — $e');
      rethrow;
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
          .select('id, status, journey_stage, suspended_by, ended_at')
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
        endedAt: matchRow['ended_at'] == null ? null : DateTime.parse(matchRow['ended_at'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  /// RETIRED 2026-08-06 — OA-ZYRA-154, DR-ZYRA-121. Always throws.
  ///
  /// `restart_journey()` reopened an ended Journey on ONE party's request.
  /// It deleted six tables of history and cleared `ended_at` before doing
  /// so, meaning someone who ended a Journey because they felt unsafe could
  /// be returned to it without consent and with no record that it had ever
  /// ended. The server now refuses, and the UI no longer offers it.
  ///
  /// Kept rather than deleted so a caller reappearing during the Journey
  /// migration fails loudly here, with the reason, instead of getting a
  /// bare Postgres error from the RPC.
  ///
  /// Replaced by Request New Journey — V3 §9, OA-ZYRA-159.
  @Deprecated('Use Request New Journey (OA-ZYRA-159). Restart is not permitted: '
      'a Journey cannot be reopened without the other person agreeing.')
  static Future<void> restartJourney(String matchId) async {
    throw StateError(
      'restart_journey is retired (OA-ZYRA-154). Starting again requires the '
      'other party to accept — see Request New Journey, OA-ZYRA-159.',
    );
  }
}
