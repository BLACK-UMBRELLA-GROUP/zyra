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

/// RETIRED 2026-08-11 (Founder: "in zyra basic you can also pause a
/// journey its just how much you pause is different") — migration
/// 20260811232500 removed the One-only gate from suspend_journey, so
/// the server no longer raises suspension_requires_one. Both plans now
/// pause; the differentiator is the cap ([PausedLimitReachedException]).
/// Kept briefly so a client running against an un-migrated database
/// degrades to the old message instead of an unhandled throw.
class SuspensionRequiresOneException implements Exception {}

/// Thrown by [ZyraJourneyService.suspendJourney] at the plan's paused
/// cap — 5 on Basic, 10 on ZYRA One (data/zyra_entitlements.dart, the
/// 2026-08-09 matrix). The cap counts pauses the CALLER initiated, so
/// Journeys the other party paused never consume it. Server-enforced in
/// suspend_journey since 2026-08-11.
class PausedLimitReachedException implements Exception {}

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

  /// Sets the caller's own reveal flag and computes THEIR OWN compatibility
  /// figure — how well this other person's answers fit what the caller said
  /// they were looking for. Callers read it back via [fetchCompatibility].
  ///
  /// The doc this replaces described the retired behaviour: wait for both
  /// parties, then compute one shared number guarded by `overall_score IS
  /// NULL`. That column no longer exists (OA-ZYRA-193 a2).
  ///
  /// The mutual gate has NOT gone away — it moved to where it belongs. Both
  /// still have to choose to reveal before either is shown anything; that is
  /// the ritual. What changed is only whose number is behind it.
  static Future<void> revealCompatibility(String matchId, String otherUserId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return;
    try {
      final matchRow = await _fetchMatchRow(matchId);
      if (matchRow == null) return;
      final isSeekerA = matchRow['seeker_a_id'] == user.id;
      final myFlagColumn  = isSeekerA ? 'seeker_a_revealed' : 'seeker_b_revealed';
      final myScoreColumn = isSeekerA ? 'seeker_a_score'    : 'seeker_b_score';
      final myCatsColumn  = isSeekerA ? 'seeker_a_categories' : 'seeker_b_categories';

      final existing = await supabase.from('journey_compatibility').select('match_id').eq('match_id', matchId).maybeSingle();
      if (existing == null) {
        await supabase.from('journey_compatibility').insert({'match_id': matchId});
      }

      await supabase.from('journey_compatibility').update({myFlagColumn: true}).eq('match_id', matchId);

      // ── REWRITTEN 2026-08-11, OA-ZYRA-193 (a2).
      //
      // WAS: compute ONE score, and only in the transaction that completed
      // the pair — so whoever revealed SECOND scored it, from their own
      // perspective, and the couple's "shared" figure depended on who
      // happened to tap last. The guard was `overall_score IS NULL`.
      //
      // NOW: I compute MY figure when I reveal. It is mine, it does not wait
      // for them, and nothing they do can overwrite it. There is no sequence
      // left to be at the mercy of.
      final updated = await supabase
          .from('journey_compatibility')
          .select('$myScoreColumn')
          .eq('match_id', matchId)
          .maybeSingle();
      if (updated == null) return;
      if (updated[myScoreColumn] != null) return;   // already computed — mine is mine

      // FIXED 2026-07-26 (Founder decision — see ZYRA_FABLE_BUILD_REVIEW_
      // 2026-07-19_V1.md §Open Decisions item 1): this used to read
      // otherUserId's onboarding_answers directly from the client,
      // which onboarding_answers' own-row-only RLS always blocked for
      // a second real user — every real Reveal silently fell back to
      // the neutral 50.0 default below. score_candidates() (SECURITY
      // DEFINER, 20260726120200_compatibility_scoring_security_
      // definer.sql) does the read+score server-side instead.
      // NO NEUTRAL FALLBACK ANY MORE. It used to default to 50.0 when
      // scoring was unavailable, which was defensible on a centred scale
      // where 50 meant "no information". On the ratified plain count it
      // would mean "half of everything matched" — a claim, not an absence.
      // Null is stored, and the screen says it cannot say yet.
      double? score;
      try {
        final rows = await supabase.rpc('score_candidates', params: {
          'p_candidate_ids': [otherUserId],
        }) as List;
        if (rows.isNotEmpty) {
          score = ((rows.first as Map<String, dynamic>)['score'] as num?)?.toDouble();
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
      if (score == null) return;

      // Still every category mirroring the overall — OA-ZYRA-193(d) is open,
      // and score_candidates exposes no per-category detail to build a real
      // breakdown from. Unchanged by this pass, and deliberately so: (d) is
      // a product decision, not something to invent here.
      final categoryScores = {
        'Deen': score,
        'Marriage Goals': score,
        'Communication': score,
        'Lifestyle': score,
        'Family Expectations': score,
      };

      await supabase.from('journey_compatibility').update({
        myScoreColumn: score,
        myCatsColumn: categoryScores,
        'revealed_at': DateTime.now().toIso8601String(),
      }).eq('match_id', matchId);
    } catch (e) {
      // 2026-08-12: the reveal write could fail on every poll with no
      // trace — the score simply never persisted. Logged (CLAUDE.md §3).
      debugPrint('ZYRA compatibility write($matchId) failed: $e');
    }
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
          .select('seeker_a_revealed, seeker_b_revealed, seeker_a_score, '
              'seeker_b_score, seeker_a_categories, seeker_b_categories')
          .eq('match_id', matchId)
          .maybeSingle();
      if (row == null) return (mine: false, theirs: false, overallScore: null, categoryScores: null);

      final mine = isSeekerA ? row['seeker_a_revealed'] == true : row['seeker_b_revealed'] == true;
      final theirs = isSeekerA ? row['seeker_b_revealed'] == true : row['seeker_a_revealed'] == true;
      // MY column, always. The record field is still called overallScore so
      // the callers did not all have to change on the same day, but what it
      // carries is this Seeker's own figure and nobody else's — reading the
      // other person's would be reading their private preferences back to
      // someone who never saw them.
      final overallScore =
          ((isSeekerA ? row['seeker_a_score'] : row['seeker_b_score']) as num?)?.toDouble();
      final rawCats = isSeekerA ? row['seeker_a_categories'] : row['seeker_b_categories'];
      final categoryScores = rawCats == null ? null : Map<String, dynamic>.from(rawCats as Map);
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

  // ── REQUEST NEW JOURNEY — OA-ZYRA-159, DR-ZYRA-121 item 8 ──────────────
  //
  // "One person requests; the other decides. Never unilateral, never a
  //  resurrection — a new attempt starts fresh with its own timeline."
  //
  // Replaces restartJourney(), which has thrown since OA-ZYRA-154.

  /// The ended matches on which the signed-in user may request a new Journey.
  ///
  /// BATCHED, for the same reason fetchOpenReviewMatchIds is: the Connections
  /// screen draws every ended Journey at once, and a per-row call is the N+1
  /// this project has a written rule against.
  ///
  /// A MATCH'S ABSENCE CARRIES NO REASON. A 6-month cooldown, a permanent
  /// "don't ask again", a block, a Tier-1 exclusion, an active Journey
  /// elsewhere and an already-pending request all look identical from here —
  /// they are simply not in the set. Do not add a variant of this that
  /// reports why; the asymmetry is the design (OA-ZYRA-159), not an
  /// oversight to be helpfully corrected later.
  ///
  /// Empty on any failure, which hides the button. Failing closed is right:
  /// showing an option that will be refused is worse than not showing it.
  static Future<Set<String>> fetchMayRequestNewJourneyIds() async {
    try {
      final rows = await supabase.rpc('zyra_may_request_new_journey_ids') as List;
      return rows.map((r) => r as String).toSet();
    } catch (e) {
      debugPrint('ZYRA: fetchMayRequestNewJourneyIds failed — $e');
      return {};
    }
  }

  /// Expires Journey requests past their 14-day window. Expiry counts as a
  /// decline (DR-121 item 8) — same cooldown, same notification, deliberately
  /// indistinguishable.
  ///
  /// LAZY, like [resolveFamilyReviewIfDue]. There is no scheduler in this
  /// database, so a request that lapsed while nobody was looking resolves the
  /// moment either party next opens the screen. Pass null to sweep all.
  static Future<void> expireDueJourneyRequests([String? matchId]) async {
    try {
      await supabase.rpc('zyra_expire_due_journey_requests',
          params: {'p_match_id': matchId});
    } catch (e) {
      debugPrint('ZYRA: expireDueJourneyRequests($matchId) failed — $e');
    }
  }

  /// Asks the other Seeker to begin a new Journey.
  ///
  /// Returns null on success, or a user-facing message.
  ///
  /// EVERY REFUSAL THE SERVER CAN GIVE MAPS TO THE SAME SENTENCE. `not_available`
  /// covers a cooldown, a permanent refusal, a block and a Tier-1 exclusion,
  /// and it must keep covering all of them — the requester learning WHICH is
  /// the one thing OA-ZYRA-159 exists to prevent. If a future error name
  /// needs its own copy, check first that it cannot be inferred backwards.
  static Future<String?> requestNewJourney(String matchId) async {
    try {
      await supabase.rpc('request_new_journey', params: {'p_match_id': matchId});
      return null;
    } catch (e) {
      final m = e.toString();
      if (m.contains('not_available')) {
        return "You can't begin a new Journey with them right now.";
      }
      if (m.contains('one_active_journey_limit')) {
        return 'You already have an Active Journey. End or pause it first.';
      }
      if (m.contains('request_already_pending')) {
        return "You've already asked. They haven't answered yet.";
      }
      if (m.contains('cooling_period_active')) {
        return 'This Journey ended less than 24 hours ago.';
      }
      debugPrint('ZYRA: requestNewJourney($matchId) failed — $e');
      return "That didn't go through. Please try again.";
    }
  }

  /// Answers a request. [decision] is 'accept', 'decline' or 'decline_never'.
  ///
  /// The two declines differ ONLY in the hold they leave behind — 6 months
  /// versus permanent — and the requester is told the same thing either way.
  static Future<String?> respondToJourneyRequest(
      String requestId, String decision) async {
    try {
      await supabase.rpc('respond_to_journey_request',
          params: {'p_request_id': requestId, 'p_decision': decision});
      return null;
    } catch (e) {
      final m = e.toString();
      if (m.contains('request_expired')) return 'That request has expired.';
      if (m.contains('already_answered')) return 'That request was already answered.';
      if (m.contains('one_active_journey_limit')) {
        return 'One of you already has an Active Journey.';
      }
      if (m.contains('not_available')) {
        return "You can't begin a new Journey with them right now.";
      }
      debugPrint('ZYRA: respondToJourneyRequest($requestId, $decision) failed — $e');
      return "That didn't go through. Please try again.";
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

  /// {questionId: answerText}. Ordered by created_at ASCENDING so that if
  /// multiple rows ever share a question_id (multiple answerers on
  /// one side), the later insert wins in the returned map.
  ///
  /// The `ascending: true` is load-bearing and was missing until 2026-08-11.
  /// postgrest-dart defaults .order() to DESCENDING, so the map was being
  /// built newest-to-oldest and the last write to win was the OLDEST answer —
  /// the exact opposite of what the sentence above promised. The doc was
  /// right about the intent and the code had never matched it.
  static Future<Map<String, String>> fetchFamilyAnswers(String matchId, String direction) async {
    try {
      final rows = await supabase
          .from('journey_family_answers')
          .select('question_id, answer_text, created_at')
          .eq('match_id', matchId)
          .eq('direction', direction)
          .order('created_at', ascending: true) as List;

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

  /// Throws [PausedLimitReachedException] at the plan's paused cap
  /// (5 Basic / 10 One — server-enforced since 2026-08-11), or
  /// [SuspensionRequiresOneException] only against an un-migrated
  /// database; swallows any other error (caller can refetch state to
  /// see the suspension didn't take effect).
  static Future<void> suspendJourney(String matchId) async {
    try {
      await supabase.rpc('suspend_journey', params: {'p_match_id': matchId});
    } catch (e) {
      if (e.toString().contains('paused_limit_reached')) throw PausedLimitReachedException();
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
    } catch (e) {
      // 2026-08-12 (stewardship pass, CLAUDE.md §3 "never leave a silent
      // catch"): a failed end used to report success to the UI with no
      // trace anywhere. Still swallowed — caller refetches state — but no
      // longer invisible.
      debugPrint('ZYRA endJourney($matchId) failed: $e');
    }
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

  /// DEV ONLY — jump an Active Journey straight to any stage.
  ///
  /// Founder request 2026-08-10, so a section can be reached for testing
  /// without walking the whole Journey to get there.
  ///
  /// ⚠️ THIS SKIPS EVERY GATE: the Pre-Journey Ritual, the Guardian Gate and
  /// the 48-hour Family Review Period. Those three are what make ZYRA a
  /// marriage process rather than a chat app.
  ///
  /// ⚠️ THE GUARD IS SERVER-SIDE, in `zyra_dev_set_journey_stage`, which reads
  /// `auth.users.email` and refuses anything that is not `@zyra.test`. Hiding
  /// the control in Dart is presentation, not protection — contradiction-audit
  /// §3.1 is an entire section on this project trusting client-side gates. If
  /// you are tempted to "just check it in the widget", that finding is why the
  /// real check is not there.
  ///
  /// ⚠️ DROP BEFORE PUBLIC LAUNCH, alongside `mock_purchase_wali_premium()`
  /// and `mock_set_wali_plan()` — engineering audit item #20. It rests on the
  /// `@zyra.test` guard, which is OA-ZYRA-171 and still open.
  ///
  /// Throws [DevOnlyException] when the signed-in account is not a seeded test
  /// account, so the caller can say so rather than swallowing it.
  static Future<String> devSetStage(String matchId, String stage) async {
    try {
      final res = await supabase.rpc('zyra_dev_set_journey_stage', params: {
        'p_match_id': matchId,
        'p_stage': stage,
      });
      return res as String;
    } catch (e) {
      // Matches this file's existing convention (suspendJourney,
      // resumeJourney): string-match the server's error name rather than
      // catching a typed PostgrestException, which is not imported here.
      if (e.toString().contains('dev_only')) throw const DevOnlyException();
      if (e.toString().contains('journey_not_active')) {
        throw const JourneyNotActiveException();
      }
      debugPrint('ZYRA: devSetStage($matchId, $stage) failed — $e');
      rethrow;
    }
  }

  /// DEV ONLY — set the OTHER party's Compatibility Reveal flag.
  ///
  /// Founder request 2026-08-10. The reveal is a two-sided gate and one person
  /// testing alone can only ever see one side of it.
  ///
  /// ⚠️ Server-guarded on `@zyra.test`, like [devSetStage]. It sets the
  /// COUNTERPART's column, never the caller's — verified both ways round
  /// against the live database on 2026-08-10.
  ///
  /// ⚠️ It deliberately does NOT compute the score. Scoring belongs to the
  /// real reveal path, so the correct test is: set the counterpart revealed,
  /// then press Reveal and watch the real code run. A dev function that also
  /// scored would be testing itself.
  ///
  /// ⚠️ DROP BEFORE PUBLIC LAUNCH — OA-ZYRA-184, which now covers eight
  /// functions rather than seven.
  static Future<bool> devSetCounterpartReveal(String matchId, bool revealed) async {
    try {
      final res = await supabase.rpc('zyra_dev_set_counterpart_reveal', params: {
        'p_match_id': matchId,
        'p_revealed': revealed,
      });
      return res as bool;
    } catch (e) {
      if (e.toString().contains('dev_only')) throw const DevOnlyException();
      debugPrint('ZYRA: devSetCounterpartReveal($matchId, $revealed) failed — $e');
      rethrow;
    }
  }

  /// Whether the OTHER party has revealed. Read back so the dev toggle shows
  /// the real state rather than whatever it last set — the two diverge the
  /// moment the other account reveals for real, and a toggle that shows its
  /// own last write is a toggle that lies.
  static Future<bool> fetchCounterpartRevealed(String matchId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false;
    try {
      final matchRow = await _fetchMatchRow(matchId);
      if (matchRow == null) return false;
      final isSeekerA = matchRow['seeker_a_id'] == user.id;
      final theirColumn = isSeekerA ? 'seeker_b_revealed' : 'seeker_a_revealed';
      final row = await supabase
          .from('journey_compatibility')
          .select(theirColumn)
          .eq('match_id', matchId)
          .maybeSingle();
      return row?[theirColumn] == true;
    } catch (e) {
      debugPrint('ZYRA: fetchCounterpartRevealed($matchId) failed — $e');
      return false;
    }
  }

  // ── PROFILE UNLOCK+ EARLY SIGHT — DR-ZYRA-135, closing OA-ZYRA-152 ─────

  /// The compatibility score for a Plus holder, before the other Seeker has
  /// revealed. Null if the caller has no Plus unlock on them, or on failure.
  ///
  /// DR-ZYRA-135, Founder-approved 2026-08-10. It resolved a real conflict:
  /// the Reveal is built as a consent gate — "neither of you sees it until you
  /// both choose" — and Unlock+ sells that number to one person. Both could
  /// not be true. The Founder chose the purchase.
  ///
  /// THE LINE THIS DOES NOT CROSS: the result is bought, the relationship is
  /// not. It sets no reveal flag, advances no stage, and tells the other
  /// person nothing — asserted server-side, checks 4–6 of the DR-135 run.
  /// If you are tempted to have this also mark the caller as revealed
  /// "since they've seen it anyway", that is the consent gate, and it is
  /// theirs to open.
  ///
  /// The entitlement is checked SERVER-SIDE, in zyra_compatibility_for_plus.
  /// Contradiction-audit §3.1 is a whole section on this project gating
  /// entitlements in Dart and believing it.
  static Future<double?> fetchCompatibilityForPlus(String matchId) async {
    try {
      final res = await supabase
          .rpc('zyra_compatibility_for_plus', params: {'p_match_id': matchId});
      if (res == null) return null;
      return (res as num).toDouble();
    } catch (e) {
      // plus_required is the ORDINARY case, not a failure: most people have
      // not bought Plus. Returning null quietly is correct; logging it would
      // fill the console with the normal path.
      if (e.toString().contains('plus_required')) return null;
      debugPrint('ZYRA: fetchCompatibilityForPlus($matchId) failed — $e');
      return null;
    }
  }

  /// DEV ONLY — simulate buying (or refunding) Compatibility Unlock+.
  ///
  /// ⚠️ NINTH consumer of the `@zyra.test` guard. OA-ZYRA-184 lists them all;
  /// it said seven this morning and eight by lunch. DROP BEFORE LAUNCH.
  ///
  /// Removing only ever deletes the simulated `paid_plus_single` row, never a
  /// real unlock of another type — a dev tool that deleted a `paid_single`
  /// would be destroying a record of money.
  /// DEV ONLY. Forces a Compatibility Reveal RESULT — both flags set and a
  /// score of your choosing — so the mutual-reveal screen can be seen at both
  /// ends of the scale.
  ///
  /// WHY THIS EXISTS RATHER THAN REAL DATA. After the 2026-08-10 backfills
  /// every seeded profile scores 77-100 against every other, because they all
  /// carry similar synthetic answers. A low score is not reachable by playing
  /// the product properly, and testing how a bad result READS matters as much
  /// as testing a good one.
  ///
  /// TENTH dev RPC — OA-ZYRA-184 holds the drop list.
  static Future<double?> devSetCompatibility(String matchId, double score) async {
    try {
      final v = await supabase.rpc('zyra_dev_set_compatibility', params: {
        'p_match_id': matchId,
        'p_score': score,
      });
      return (v as num?)?.toDouble();
    } catch (e) {
      debugPrint('ZYRA: devSetCompatibility failed — $e');
      rethrow;
    }
  }

  /// The signed-in Seeker's OWN private ratings for a phase — questionId to
  /// 'reassured' | 'discuss_further' | 'concerns'.
  ///
  /// ADDED 2026-08-11 for the ZYRA intelligence layer, which has nothing to
  /// say without them. Scoped to the caller on purpose and not by accident of
  /// RLS: "Your ratings are private and used only to guide your journey"
  /// (PRE-JOURNEY RITUAL/Summary.md) is a promise made on screen every phase,
  /// so this must never grow an `otherUserId` parameter.
  static Future<Map<String, String>> fetchMyRatings(String matchId, int phase) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return {};
    try {
      final rows = await supabase
          .from('journey_phase_ratings')
          .select('question_id, rating')
          .eq('match_id', matchId)
          .eq('phase', phase)
          .eq('rater_id', user.id) as List;
      return {
        for (final r in rows)
          (r as Map<String, dynamic>)['question_id'] as String: r['rating'] as String,
      };
    } catch (e) {
      debugPrint('ZYRA: fetchMyRatings($matchId, $phase) failed - $e');
      return {};
    }
  }

  /// All of this Seeker's private ratings across phases 1-3, merged.
  /// Open Conversation is where the whole Journey is finally one thing, so
  /// its topic suggestions read from all of it rather than the last phase.
  static Future<Map<String, String>> fetchAllMyRatings(String matchId) async {
    final out = <String, String>{};
    for (final phase in const [1, 2, 3]) {
      out.addAll(await fetchMyRatings(matchId, phase));
    }
    return out;
  }

  /// DEV ONLY. Completes the OTHER party's half of whatever stage the Journey
  /// is standing on, so the flow can be walked alone.
  ///
  /// Every stage from the Salam onwards is a mutual act by design, which
  /// means a single tester stops at the second stage and the remaining six
  /// have never been seen running. This ends the wait and nothing else: it
  /// does not advance the stage, does not skip one, and does not touch the
  /// caller's own half. The server decides what "their half" means from the
  /// current stage - see zyra_dev_counterpart_complete.
  ///
  /// [questionIds] is the current stage's question set, sent because the
  /// bank lives in data/journey_questions.dart and the database has never
  /// been told about it. Empty for the stages that have no questions.
  ///
  /// ELEVENTH dev RPC - OA-ZYRA-184 holds the drop list.
  static Future<String> devCounterpartComplete(String matchId,
      {List<String> questionIds = const []}) async {
    try {
      final res = await supabase.rpc('zyra_dev_counterpart_complete', params: {
        'p_match_id': matchId,
        'p_question_ids': questionIds,
      });
      return res?.toString() ?? 'Done.';
    } catch (e) {
      if (e.toString().contains('dev_only')) throw const DevOnlyException();
      debugPrint('ZYRA: devCounterpartComplete($matchId) failed - $e');
      rethrow;
    }
  }

  /// DEV ONLY, DESTRUCTIVE. Rewinds ONE Journey to Compatibility Reveal and
  /// clears everything the pair did inside it — answers, ratings, salams,
  /// reveals, checkpoints, family answers, reviews, messages, milestones.
  ///
  /// Founder, 2026-08-11: "the reset button in toggle doesn't reset the
  /// journey stage.. say if i wanna start again." Neither Reset was ever
  /// going to: one clears the panel's own toggles and never touches the
  /// server, and the red account reset deliberately leaves matches alone
  /// because they are expensive to rebuild. This is the third thing, named
  /// for what it does.
  ///
  /// ⚠️ NOT [restartJourney]. Starting again for real needs both people to
  /// agree and keeps all history (OA-ZYRA-154 / OA-ZYRA-159). This deletes
  /// it, and must never be reachable from a member-facing screen.
  ///
  /// TWELFTH dev RPC - OA-ZYRA-184 holds the drop list.
  /// [matchId] null rewinds EVERY Journey on this account — which is what the
  /// dev panel's Reset needs, since it runs from HomeShell with no Journey in
  /// front of it.
  static Future<String> devRewindJourney({String? matchId}) async {
    try {
      final res = await supabase
          .rpc('zyra_dev_rewind_journey', params: {'p_match_id': matchId});
      return res?.toString() ?? 'Journey rewound.';
    } catch (e) {
      if (e.toString().contains('dev_only')) throw const DevOnlyException();
      debugPrint('ZYRA: devRewindJourney($matchId) failed - $e');
      rethrow;
    }
  }

  static Future<bool> devSetPlusUnlock(String otherId, bool has) async {
    try {
      final res = await supabase.rpc('zyra_dev_set_plus_unlock',
          params: {'p_other_id': otherId, 'p_has': has});
      return res == true;
    } catch (e) {
      if (e.toString().contains('dev_only')) throw const DevOnlyException();
      debugPrint('ZYRA: devSetPlusUnlock($otherId, $has) failed — $e');
      rethrow;
    }
  }

  /// Whether the signed-in user holds a Plus unlock on [otherId]. Read back
  /// from the server so the dev switch shows the real state rather than its
  /// own last write.
  static Future<bool> fetchHasPlusUnlock(String otherId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false;
    try {
      final rows = await supabase
          .from('profile_unlocks')
          .select('unlock_type')
          .eq('unlocker_id', user.id)
          .eq('unlocked_id', otherId) as List;
      return rows.any((r) => (r as Map<String, dynamic>)['unlock_type']
          .toString()
          .startsWith('paid_plus'));
    } catch (e) {
      debugPrint('ZYRA: fetchHasPlusUnlock($otherId) failed — $e');
      return false;
    }
  }
}

/// The signed-in account is not a seeded `@zyra.test` account, so a developer
/// tool refused it. Raised by the server, never inferred on the client.
class DevOnlyException implements Exception {
  const DevOnlyException();
  @override
  String toString() =>
      'Stage jumping is limited to seeded @zyra.test accounts.';
}

/// A stage jump was attempted on a Journey that is not active — an ended or
/// potential Journey has no stages to move between.
class JourneyNotActiveException implements Exception {
  const JourneyNotActiveException();
  @override
  String toString() => 'Only an Active Journey has stages to move between.';
}
