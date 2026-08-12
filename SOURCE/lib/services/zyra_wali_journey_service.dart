// Wali-side Journey/Timeline/Messages read access — builds the
// "Standard Guardian capabilities" ratified in APP/Standards/
// WALI_ARCHITECTURE_CURRENT_VERSION_V5.md ("View Seeker's active
// Journey progress", "View messages between Seeker and their match",
// "View Timeline") since 2026-07-04 but never built until now
// (2026-07-26). Backed by 20260726130000_wali_journey_visibility.sql,
// which extends matches/conversations/messages/timelines/
// timeline_milestones RLS to a Wali with an 'active' wali_links row,
// scoped to matches that have left 'potential' status (an Active
// Journey exists) — Browse-stage activity stays out of scope
// entirely, per that migration's own header comment and the separate
// DR draft covering the wider visibility conflict.
//
// Read-only throughout: no INSERT/UPDATE grants were added for a Guardian
// on any of these tables (except journey_family_answers, which
// already permitted Guardian writes before this — see
// WaliFamilyStageScreen).
//
// 2026-07-26 (#31): waliReviewDecision()/myReviewDecision()/
// reopenFamilyReview() below add the ONE real write capability a Guardian
// has beyond journey_family_answers — Continue/Pause during a Family
// Review Period (WALI_ARCHITECTURE_CURRENT_VERSION_V6.md's "Family
// Review Period" section). Enforced server-side by wali_review_
// decision()/reopen_family_review() (20260726190000_family_review_
// period.sql), which check the caller is an active main Wali for one
// of the two Seekers on the match — not by anything client-side here.

import '../main.dart';
import '../models/seeker_profile.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'zyra_auth.dart';
import 'zyra_match_service.dart';
import 'zyra_wali_link_service.dart';

class WaliJourneyView {
  final String matchId;
  final String linkedSeekerId;
  final String linkedSeekerName;
  /// The counterpart, as the COUNTERPART CARD allows — first name and age
  /// only. `city` is '—' and `photos` is empty by design, not by failure.
  ///
  /// 2026-08-08: this used to be a full profile read straight off
  /// `profiles`. A Guardian could see the other family's Seeker, their
  /// Guardians, and the co-Guardians on their own side — gender-blind,
  /// mutually, for everyone attached to the Journey. Clause 3 no longer
  /// grants Guardians anything, so this is now built from
  /// zyra_counterpart_card().
  final SeekerProfile partner;

  /// The other family's MAIN Guardian, from the same card. Null when they
  /// have no Main Guardian — a real state worth showing, not an error.
  /// Additional Guardians never receive a card at all.
  final String? counterpartGuardianName;
  final String? counterpartGuardianSurname;

  final String status; // 'active' | 'paused' | 'ended' (never 'potential' — out of scope)
  final String? journeyStage;
  final String? suspendedBy;

  const WaliJourneyView({
    required this.matchId,
    required this.linkedSeekerId,
    required this.linkedSeekerName,
    required this.partner,
    required this.counterpartGuardianName,
    required this.counterpartGuardianSurname,
    required this.status,
    required this.journeyStage,
    required this.suspendedBy,
  });

  bool get isSuspended => suspendedBy != null;
}

class ZyraWaliJourneyService {
  ZyraWaliJourneyService._();

  /// Real Journeys (status <> 'potential') for every Seeker linked to
  /// the signed-in Wali. Empty (not an error) if not signed in, not a
  /// Wali, no linked Seekers, or no real Journey yet for any of them.
  static Future<List<WaliJourneyView>> fetchLinkedJourneys() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return [];

    try {
      final linked = await ZyraWaliLinkService.fetchLinkedPeople(asWali: true);
      if (linked.isEmpty) return [];
      final linkedIds = {for (final p in linked) p.id: p.firstName};

      // RLS (20260726130000_wali_journey_visibility.sql) already
      // restricts this to matches where the signed-in Wali has an
      // active link to one of the two seekers, and status <>
      // 'potential' — the explicit filters below are defensive, not
      // load-bearing.
      final rows = await supabase
          .from('matches')
          .select('id, seeker_a_id, seeker_b_id, status, journey_stage, suspended_by')
          .neq('status', 'potential') as List;
      if (rows.isEmpty) return [];

      final results = <WaliJourneyView>[];
      for (final row in rows) {
        final map = row as Map<String, dynamic>;
        final a = map['seeker_a_id'] as String;
        final b = map['seeker_b_id'] as String;
        final String linkedSeekerId;
        final String partnerId;
        if (linkedIds.containsKey(a)) {
          linkedSeekerId = a;
          partnerId = b;
        } else if (linkedIds.containsKey(b)) {
          linkedSeekerId = b;
          partnerId = a;
        } else {
          continue; // shouldn't happen under RLS, but be defensive
        }

        // The card is keyed on the match, not the person — it is the
        // Journey that entitles a Main Guardian to know who the other
        // family is, and only for as long as that Journey stands.
        final card = await _fetchCounterpartCard(map['id'] as String, partnerId);
        if (card == null) continue; // not this Journey's Main Guardian

        results.add(WaliJourneyView(
          matchId: map['id'] as String,
          linkedSeekerId: linkedSeekerId,
          linkedSeekerName: linkedIds[linkedSeekerId]!,
          partner: card.partner,
          counterpartGuardianName: card.guardianFirstName,
          counterpartGuardianSurname: card.guardianSurnameLine,
          status: map['status'] as String,
          journeyStage: map['journey_stage'] as String?,
          suspendedBy: map['suspended_by'] as String?,
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// The counterpart card — the ONLY route by which a Guardian learns
  /// anything about the other family (zyra_counterpart_card, 2026-08-08).
  ///
  /// Returns null when the caller is not the MAIN Guardian of one of the
  /// two Seekers, when the Journey has not started, or when a block or a
  /// safety ending stands. All four are correct empty states, not errors.
  ///
  /// What it deliberately does NOT return: city, photos, gender, bio,
  /// Chapter answers — and no contact channel, because none exists in the
  /// schema yet and inventing one out of the Guardian's auth email would
  /// be a new disclosure. Flagged for the Founder.
  ///
  /// The old implementation also fell back to a picsum.photos stock image
  /// when a counterpart had no photo, rendering a stranger's face as a
  /// real user's (audit R8). That path is gone with it.
  static Future<_CounterpartCard?> _fetchCounterpartCard(String matchId, String partnerId) async {
    try {
      final rows = await supabase.rpc('zyra_counterpart_card', params: {
        'p_match_id': matchId,
      });
      if (rows is! List || rows.isEmpty) return null;
      final c = rows.first as Map<String, dynamic>;
      return _CounterpartCard(
        partner: SeekerProfile(
          id: partnerId,
          firstName: (c['counterpart_first_name'] as String?) ?? '—',
          age: (c['counterpart_age'] as num?)?.toInt() ?? 0,
          city: '—',              // withheld by the card, not missing
          photos: const [],       // withheld by the card, not missing
          gender: '',             // not disclosed to Guardians
        ),
        guardianFirstName: c['guardian_first_name'] as String?,
        guardianSurnameLine: c['guardian_surname_line'] as String?,
      );
    } catch (e) {
      // ES-08 — never silent. A Guardian seeing an empty Journey list
      // because of a swallowed error looks identical to having none.
      debugPrint('[ZyraWaliJourneyService] counterpart card for $matchId failed: $e');
      return null;
    }
  }

  /// Read-only Timeline for a Journey the Guardian supervises. Empty on
  /// any failure or if there's genuinely nothing yet.
  static Future<List<ZyraMilestone>> fetchTimeline(String matchId) async {
    try {
      // OA-ZYRA-159 stage 4b, 2026-08-10. WAS: .eq('match_id', matchId).
      // timelines belong to an ATTEMPT since stage 4a, so match_id no longer
      // identifies one row. Resolved through ZyraMatchService.currentAttemptId,
      // which reads zyra_my_attempt_participation — a Guardian appears in that
      // view as a participant, so one helper serves both roles and there is a
      // single implementation to keep in step with the server-side trigger.
      final attemptId = await ZyraMatchService.currentAttemptId(matchId);
      if (attemptId == null) return [];

      final timelineRows = await supabase
          .from('timelines')
          .select('id')
          .eq('attempt_id', attemptId)
          .limit(1) as List;
      if (timelineRows.isEmpty) return [];
      final timelineId = (timelineRows.first as Map<String, dynamic>)['id'] as String;

      final milestoneRows = await supabase
          .from('timeline_milestones')
          .select('milestone_type, occurred_at')
          .eq('timeline_id', timelineId)
          // OLDEST FIRST, matching the Seeker's Timeline exactly. These two
          // queries must move together: a Guardian and the Seeker they support
          // reading the same Journey in opposite orders is worse than either
          // order being wrong.
          .order('occurred_at', ascending: true) as List;

      return milestoneRows.map((r) {
        final map = r as Map<String, dynamic>;
        return ZyraMilestone(type: map['milestone_type'] as String, occurredAt: DateTime.parse(map['occurred_at'] as String));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// #31 — Family Review Period. Records this Wali's Continue/Pause
  /// decision on [reviewId] (from ZyraJourneyService.fetchFamilyReview()).
  /// The RPC itself verifies the caller is an active main Guardian for one
  /// of the two Seekers on the review's match — this is the only
  /// enforcement point, not a client-side gate, so there's nothing to
  /// check here beyond swallowing failures. [decision] is 'continue' or
  /// 'pause'. Returns true on success.
  static Future<bool> waliReviewDecision(String reviewId, String decision) async {
    try {
      await supabase.rpc('wali_review_decision', params: {'p_review_id': reviewId, 'p_decision': decision});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// #31 — this Guardian's own decision (if any) already recorded on
  /// [reviewId], so the UI can show "You chose Continue — waiting on
  /// the other family" instead of re-showing the buttons. Null if this
  /// Wali hasn't responded yet, signed out, or on any failure.
  static Future<String?> myReviewDecision(String reviewId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;
    try {
      final row = await supabase
          .from('journey_family_review_responses')
          .select('decision')
          .eq('review_id', reviewId)
          .eq('wali_id', user.id)
          .maybeSingle();
      return row == null ? null : row['decision'] as String;
    } catch (_) {
      return null;
    }
  }

  /// #31 — reopens a 'paused' review for a fresh 48h window once the
  /// family has actually spoken (see the migration's own scope note:
  /// the source spec never specifies a resolution mechanic for a
  /// Pause beyond "ZYRA support is available to assist"). Returns true
  /// on success.
  static Future<bool> reopenFamilyReview(String reviewId) async {
    try {
      await supabase.rpc('reopen_family_review', params: {'p_review_id': reviewId});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Read-only conversation messages for a Journey the Wali
  /// supervises. Wali has no send capability — no insert path exists
  /// for this role on `messages` (see the visibility migration's own
  /// comment). Empty on any failure.
  static Future<List<ZyraChatMessage>> fetchMessages(String matchId) async {
    try {
      // OA-ZYRA-159 stage 4b, 2026-08-10. WAS: .eq('match_id', matchId).
      //
      // This one matters most of the four. A Guardian reading by match_id
      // after a second Journey with the same person would have been shown
      // the PREVIOUS attempt's messages — a conversation the current Journey
      // did not consent to exposing, and DR-ZYRA-121 item 11 makes Guardian
      // involvement per-attempt precisely so a new Guardian inherits nothing.
      // Silent, and a privacy failure rather than a display bug.
      final attemptId = await ZyraMatchService.currentAttemptId(matchId);
      if (attemptId == null) return [];

      final convRows = await supabase
          .from('conversations')
          .select('id')
          .eq('attempt_id', attemptId)
          .limit(1) as List;
      if (convRows.isEmpty) return [];
      final conversationId = (convRows.first as Map<String, dynamic>)['id'] as String;

      final rows = await supabase
          .from('messages')
          .select('id, sender_id, content, created_at')
          // OLDEST FIRST, matching the Seeker's chat. Same reason.
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true) as List;
      return rows.map((r) {
        final map = r as Map<String, dynamic>;
        return ZyraChatMessage(
          id: map['id'] as String,
          text: map['content'] as String,
          fromMe: false, // Guardian never sends — every message is "theirs" from this viewpoint
          createdAt: DateTime.parse(map['created_at'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}


/// Internal holder for one zyra_counterpart_card() row.
class _CounterpartCard {
  final SeekerProfile partner;
  final String? guardianFirstName;
  final String? guardianSurnameLine;
  const _CounterpartCard({
    required this.partner,
    required this.guardianFirstName,
    required this.guardianSurnameLine,
  });
}
