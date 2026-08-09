// Reporting and blocking — 2026-08-01 (Founder request).
//
// Backed by profile_reports and profile_blocks (migrations
// profile_reports_and_blocks + fix_block_mutual_hide_rls_recursion).
// Before this, ZYRA had no way to report or block anyone at all: the
// Browse long-press menu's "Report a Problem" opened the generic Help &
// Support screen, with no subject and nowhere for a report to go.
//
// TWO DISTINCT ACTIONS, deliberately kept separate — the single most
// useful thing taken from the Muzz teardown (MUZZ_TEARDOWN_CURRENT_
// VERSION_V1.md §1.3). Muzz's reason list leads with "I don't want to see
// this person", which is a BLOCK, not a report. Most people reaching for
// "report" only want the person gone. Conflating the two floods the
// moderation queue with non-incidents and makes the user wait for a
// review they never needed.
//
//   block()  -> mutual invisibility, instant, no moderation involvement
//   report() -> goes to a moderation queue, permanent, not retractable
//
// A report ALSO blocks by default (reportAndBlock) — nobody who has just
// reported someone for harassment wants to keep seeing them while the
// report is reviewed.
//
// Blocking is enforced in profiles_select's RLS, not here, so it applies
// to every query path — Browse, Matches, Journey, chat participant
// lookups — including ones not written yet. This service only writes the
// rows; it is not where the rule lives.

import 'package:flutter/foundation.dart' show debugPrint;
import '../main.dart';
import 'zyra_auth.dart';

/// Where the report was raised from. Moderation needs this: a report from
/// an active Journey is a materially different signal to one from a
/// Browse card someone saw for four seconds. Values must match the
/// `source` CHECK constraint on profile_reports.
enum ZyraReportSource { browse, chat, journey, connections, profile, guardian }

/// Values must match the `reason` CHECK constraint on profile_reports.
enum ZyraReportReason {
  fakeProfile,
  inappropriateContent,
  harassment,
  underage,
  violence,
  privacy,
  other,
}

extension ZyraReportReasonX on ZyraReportReason {
  String get dbValue => switch (this) {
        ZyraReportReason.fakeProfile => 'fake_profile',
        ZyraReportReason.inappropriateContent => 'inappropriate_content',
        ZyraReportReason.harassment => 'harassment',
        ZyraReportReason.underage => 'underage',
        ZyraReportReason.violence => 'violence',
        ZyraReportReason.privacy => 'privacy',
        ZyraReportReason.other => 'other',
      };

  /// User-facing label. Plain, non-clinical language — someone using this
  /// screen is usually upset, and this is not the moment for product
  /// voice.
  String get label => switch (this) {
        ZyraReportReason.fakeProfile => 'Impersonation or fake profile',
        ZyraReportReason.inappropriateContent => 'Nudity or sexual content',
        ZyraReportReason.harassment => 'Harassment or abusive behaviour',
        ZyraReportReason.underage => 'Minor or underage',
        ZyraReportReason.violence => 'Violence or disturbing content',
        ZyraReportReason.privacy => 'Privacy or personal information',
        ZyraReportReason.other => 'Something else',
      };

  /// Reasons where we should say plainly that we act fast. Underage is
  /// the one that must never sit in a queue behind a bio complaint.
  bool get isUrgent => this == ZyraReportReason.underage || this == ZyraReportReason.violence;
}

class ZyraReportService {
  ZyraReportService._();

  /// Whether [id] is a real `profiles` row rather than one of the demo
  /// candidates in seeker_profile.dart, whose ids are '1', '2', '3'.
  ///
  /// Needed because ZyraDiscoveryService still falls back to mockProfiles
  /// on five separate paths, so a demo card can appear in Browse and be
  /// long-pressed. Without this check, both block() and report() would
  /// fail on a uuid cast and the user would see a generic "that didn't
  /// work" for something that was never going to work.
  ///
  /// This method should DELETE ITSELF along with the mock fallback — see
  /// ES-02 in the Muzz teardown ("no mock data in production paths"),
  /// which exists precisely because that fallback hid the profile_complete
  /// bug for a month. It is a bridge, not a design.
  static bool isPersistableId(String id) =>
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(id);

  /// Hides [otherUserId] and the caller from each other, everywhere,
  /// immediately. No report is filed and nobody is notified.
  ///
  /// Idempotent — a duplicate block hits the UNIQUE (blocker_id,
  /// blocked_id) constraint, which is treated as success rather than an
  /// error, because from the user's point of view the desired state is
  /// already true.
  // ═══════════════════════════════════════════════════════════════════
  // RELEASE BLOCKER FIX, 2026-08-09 — audit finding 1.2.
  // Blocking did nothing and reported success. Both directions.
  // ═══════════════════════════════════════════════════════════════════
  //
  // This method wrote `profile_blocks` directly. `authenticated` has NO
  // INSERT, UPDATE or DELETE on that table — the RLS policies
  // profile_blocks_insert and profile_blocks_delete both exist and are
  // declared TO public, with no grant behind them. Every block was
  // refused with 42501. Verified live 2026-08-09, rolled back.
  //
  // Someone reporting harassment was told it worked, kept seeing that
  // person, and any Journey between them stayed open.
  //
  // AND THE REPLACEMENT WAS ALREADY WRITTEN. zyra_block_user(p_other) is
  // SECURITY DEFINER, granted to `authenticated`, inserts the block AND
  // ends any live Journey between the two via zyra_end_match_internal(…,
  // 'safety_concern'). A grep of all 109 Dart files found it called
  // NOWHERE. Same for zyra_unblock_user. Both verified callable and
  // working as `authenticated` on 2026-08-09.
  //
  // So this is not "add the missing grant" — granting the table would
  // leave two paths that do different things, and the direct write is the
  // weaker one. It does not end the Journey (invariant I3).

  /// Hides [otherUserId] and the caller from each other, everywhere,
  /// immediately, AND ends any live Journey between them. No report is
  /// filed and nobody is notified.
  ///
  /// Idempotent — blocking someone already blocked is success, because
  /// from the user's point of view the desired state is already true.
  static Future<bool> block(String otherUserId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false;
    try {
      await supabase.rpc('zyra_block_user', params: {'p_other': otherUserId});
      return true;
    } catch (e) {
      debugPrint('ZYRA: block($otherUserId) failed — $e');
      return false;
    }
  }

  /// Reverses a block the caller made. Free and self-service, from the
  /// Settings list — DR-K (proposed) forbids ever SELLING the undo, not
  /// letting someone correct their own mistake.
  static Future<bool> unblock(String otherUserId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false;
    try {
      // Via the RPC, for the same reason as block() above — the direct
      // DELETE was refused with 42501 and reported success.
      await supabase.rpc('zyra_unblock_user', params: {'p_other': otherUserId});
      return true;
    } catch (e) {
      debugPrint('ZYRA: unblock($otherUserId) failed — $e');
      return false;
    }
  }

  /// Ids the caller has blocked. Note this is only blocks the caller
  /// MADE — RLS deliberately prevents anyone seeing who blocked them.
  static Future<List<String>> blockedIds() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return const [];
    try {
      final rows = await supabase.from('profile_blocks').select('blocked_id').eq('blocker_id', user.id) as List;
      return rows.map((r) => (r as Map<String, dynamic>)['blocked_id'] as String).toList();
    } catch (e) {
      debugPrint('ZYRA: blockedIds() failed — $e');
      return const [];
    }
  }

  /// Files a report AND blocks, which is almost always what the user
  /// wants — nobody reporting harassment wants to keep seeing that person
  /// while the report is reviewed.
  ///
  /// Returns true only if the REPORT was stored. The block is best-effort
  /// on top: if the report saved but the block failed, that is still a
  /// success from a safety standpoint (moderation has the signal) and the
  /// user can block manually.
  ///
  /// Unlike almost every other write in this codebase, a failure here is
  /// surfaced to the user rather than silently swallowed. A report that
  /// quietly vanishes is the worst possible outcome for this feature.
  /// [alsoBlock] false files the report and leaves the relationship alone.
  ///
  /// ADDED 2026-08-06 for Guardian reports. Report and remove answer two
  /// different questions — *"this person broke the rules"* versus *"I no
  /// longer want them linked"* — and they are not always the same decision.
  /// Someone may report an impersonated Guardian account and still want the
  /// link kept while it is looked into.
  ///
  /// It is also not merely semantic here: blocking sets the condition
  /// `zyra_block_exists` tests, and `guardians_for_unlocked` checks that
  /// before disclosing Guardians. Blocking your own Guardian would quietly
  /// change what other Seekers see on YOUR profile.
  static Future<bool> reportAndBlock({
    required String reportedId,
    required ZyraReportReason reason,
    String? detail,
    ZyraReportSource source = ZyraReportSource.browse,
    bool alsoBlock = true,
  }) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false;
    try {
      await supabase.from('profile_reports').insert({
        'reporter_id': user.id,
        'reported_id': reportedId,
        'reason': reason.dbValue,
        'detail': (detail != null && detail.trim().isNotEmpty) ? detail.trim() : null,
        'source': source.name,
      });
    } catch (e) {
      debugPrint('ZYRA: report($reportedId, ${reason.dbValue}) FAILED — nothing was stored. $e');
      return false;
    }

    // Best-effort, deliberately after the report and not bundled into it:
    // the report is the part that must not be lost.
    //
    // The return value used to be discarded outright. Keeping the
    // contract (true means the REPORT stored — see the doc above) but not
    // the silence: for a month `block()` returned false on every single
    // call and nothing anywhere said so. Audit finding 1.2.
    if (alsoBlock) {
      final blocked = await block(reportedId);
      if (!blocked) {
        debugPrint('ZYRA: report($reportedId) stored, but the accompanying '
            'block FAILED. The reporter can still see this person.');
      }
    }
    return true;
  }
}
