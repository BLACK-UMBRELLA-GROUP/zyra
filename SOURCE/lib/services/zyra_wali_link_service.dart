// Wali account linking — Paths 1/2 (Seeker invites Wali) and Path 3
// (Wali invites Seeker), per WALI_ARCHITECTURE_CURRENT_VERSION_V5.md.
// One symmetric mechanism serves both directions: whoever initiates
// creates a wali_invites row (a shareable 8-character code — no SMS/
// email backend exists, so sharing is manual/copy-paste for v1); the
// other party enters that code and accept_wali_invite() (a SECURITY
// DEFINER function — see supabase/migrations/wali_invites_and_
// linking.sql) creates the resulting wali_links row regardless of
// which side is signed in.
//
// Deliberately out of scope here: the Wali One capability/
// entitlement resolution engine (Primary Wali, Path A/B grants) —
// that's unbuilt architecture with no schema representation yet.
// This service only creates the LINK, not any capability grant.

import 'package:flutter/foundation.dart';
import '../data/zyra_reference_data.dart';
import '../main.dart';
import 'zyra_auth.dart';

class WaliLinkedPerson {
  final String id;
  final String firstName;

  /// ADDED 2026-08-01. `wali_links.is_main` has existed since the table
  /// was built and is auto-designated on the first active link, but
  /// nothing ever read it — the Seeker's Guardian tab listed every linked
  /// Guardian identically, so the one person who actually acts on the
  /// Journey was indistinguishable from the rest.
  ///
  /// Exactly one link per Seeker carries this. A Seeker has one Main
  /// Guardian; any others are Additional.
  final bool isMain;

  /// How this Guardian is related to their Seeker — the stored CODE
  /// ('father', 'uncle'…), never the label. Use [relationshipLabel] to
  /// display it.
  ///
  /// FIXED 2026-08-06. This field has existed since 2026-08-01 and is
  /// rendered on the Seeker's Guardian tab, but [fetchLinkedPeople] never
  /// selected the column, so it was null for every real user. The only
  /// place "Father" or "Brother" appeared was `ZyraDevScenario.fakeGuardians`
  /// — which is precisely why the tab looked correct in testing and would
  /// have been blank in production.
  ///
  /// Still nullable, and legitimately so: links created before the column
  /// existed have no relationship, and nobody has been asked. A guess would
  /// be inventing data about real people.
  final String? relationship;

  const WaliLinkedPerson({
    required this.id,
    required this.firstName,
    this.isMain = false,
    this.relationship,
  });

  /// "Paternal Uncle" for the code 'uncle'. Null when unrecorded.
  String? get relationshipLabel => zyraRelationshipLabel(relationship);
}

/// One thing a Guardian actually did. Never synthesised — every instance
/// corresponds to a real row with a real timestamp.
///
/// Founder, 2026-08-06: *"I don't want fake activity. Only show activity
/// when something has genuinely happened."* Two requested types are
/// deliberately absent, and their absence is the honest answer rather than a
/// gap: `became_main` has no timestamp anywhere (and would duplicate
/// `linked` on the same day for a first Guardian), and `invited_to_journey`
/// has no event at all, because participation is derived from the link
/// rather than granted by an invitation.
class GuardianActivity {
  final String waliId;
  final String type;
  final DateTime occurredAt;
  final String? detail;

  const GuardianActivity({
    required this.waliId,
    required this.type,
    required this.occurredAt,
    this.detail,
  });

  /// Null when the row has no usable timestamp. Every branch of
  /// `zyra_guardian_activity` selects a NOT NULL column today, so this
  /// should never fire — but an activity entry with no "when" cannot be
  /// rendered, and a null reaching `DateTime.parse` would take the whole
  /// Guardian page down rather than dropping one line from a list.
  static GuardianActivity? fromRow(Map<String, dynamic> r) {
    final raw = r['occurred_at'] as String?;
    if (raw == null) return null;
    return GuardianActivity(
      waliId: r['wali_id'] as String,
      type: r['activity_type'] as String,
      occurredAt: DateTime.parse(raw).toLocal(),
      detail: r['detail'] as String?,
    );
  }

  /// Written as something a person did, not as a system event. "Suggested
  /// Yusuf to you" rather than "SUGGESTION_CREATED".
  ///
  /// An unknown type returns null rather than a fallback string: a new
  /// activity type added server-side should show nothing until someone
  /// writes its sentence, not leak a raw code onto a Guardian's card.
  String? get line => switch (type) {
        'linked' => 'Accepted your invitation',
        'suggested' =>
          detail == null ? 'Suggested someone to you' : 'Suggested $detail to you',
        'review_answered' => 'Completed Family Review',
        'review_waiting' => 'Waiting on Family Review',
        _ => null,
      };

  /// True where the entry is something still owed, not something done.
  /// The page leans on this for emphasis — a Guardian you are waiting on is
  /// the most important thing the card can tell you.
  bool get isOutstanding => type == 'review_waiting';

  /// "today", "3 days ago", then a date once relative time stops helping.
  String get whenLabel {
    final d = DateTime.now().difference(occurredAt);
    if (d.inDays == 0) return 'today';
    if (d.inDays == 1) return 'yesterday';
    if (d.inDays < 30) return '${d.inDays} days ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${occurredAt.day} ${months[occurredAt.month - 1]} ${occurredAt.year}';
  }
}

/// An invite code that has been generated but not yet redeemed.
///
/// [label] is the SENDER'S private note for who they meant it for, and is
/// never shown to anyone else — `wali_invites_select` is scoped to
/// `inviter_id`, and `preview_wali_invite` cannot return it. It is not a
/// claim about who holds the code: whoever redeems it becomes the Guardian.
class PendingInvite {
  final String token;
  final String? label;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const PendingInvite({
    required this.token,
    required this.createdAt,
    this.label,
    this.expiresAt,
  });

  /// Days until it lapses, or null where no expiry is recorded.
  int? get daysLeft {
    if (expiresAt == null) return null;
    final d = expiresAt!.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }
}

class ZyraWaliLinkService {
  ZyraWaliLinkService._();

  /// Every Guardian's activity, grouped by Guardian, newest first.
  ///
  /// Empty on failure rather than throwing: an activity line is an
  /// enhancement to a card that must still render without it.
  static Future<Map<String, List<GuardianActivity>>> fetchActivity() async {
    if (ZyraAuth.currentUser == null) return const {};
    try {
      final rows = await supabase.rpc('zyra_guardian_activity') as List;
      final out = <String, List<GuardianActivity>>{};
      for (final r in rows) {
        final a = GuardianActivity.fromRow(Map<String, dynamic>.from(r as Map));
        if (a == null) continue;
        (out[a.waliId] ??= []).add(a);
      }
      return out;
    } catch (e) {
      debugPrint('ZYRA: zyra_guardian_activity failed — $e');
      return const {};
    }
  }

  /// Promotes a linked Guardian to Main. Returns true on success.
  ///
  /// Exactly one Main per Seeker is enforced by a partial unique index,
  /// `wali_links_one_main_per_seeker`, so this cannot produce two — the RPC
  /// demotes the incumbent before promoting, which is also the only order
  /// that satisfies the `auto_designate_main_wali` trigger sitting on the
  /// same column.
  static Future<bool> setMainGuardian(String waliId) async {
    if (ZyraAuth.currentUser == null) return false;
    try {
      final ok = await supabase
          .rpc('zyra_set_main_guardian', params: {'p_wali_id': waliId});
      return ok == true;
    } catch (e) {
      debugPrint('ZYRA: setMainGuardian($waliId) failed — $e');
      return false;
    }
  }

  /// RETIRED 2026-08-10 — DR-ZYRA-136, contradiction-audit finding 2.9.
  /// Always throws.
  ///
  /// THE DOC COMMENT HERE USED TO SAY THE OPPOSITE. It read: "that is
  /// reachable and the Guardian page handles it, but the caller must warn
  /// first" — documenting the no-Main-Guardian state as a legitimate outcome
  /// the UI merely had to explain. The Founder has ruled it is not one, and
  /// the codebase must not be left arguing with its own register.
  ///
  /// What that state actually did: Family Review reads `is_main`, so with
  /// nobody Main there is no voter and a review cannot be resolved at all.
  /// The Guardian's message access closes at the same moment. Oversight ended
  /// with nothing said — which is why the audit called it a defect, and why
  /// the fix is to stop offering the action rather than to warn harder.
  ///
  /// Reassigning Main is [setMainGuardian], which demotes the incumbent and
  /// promotes the replacement in one transaction. Clearing WITHOUT a
  /// replacement is the forbidden act itself, so nothing is left for this to
  /// do.
  ///
  /// Kept rather than deleted, following restartJourney's precedent: a caller
  /// reappearing later fails here with the reason, instead of getting a bare
  /// PostgREST error from a server function that also refuses.
  @Deprecated('A Seeker may not be left without a Main Guardian (DR-ZYRA-136). '
      'Use setMainGuardian to reassign.')
  static Future<bool> clearMainGuardian(String waliId) async {
    throw StateError(
      'clearMainGuardian is retired (DR-ZYRA-136, audit 2.9). It created the '
      'no-Main-Guardian state, in which Family Review has no voter and the '
      "Guardian's message access closes. Use setMainGuardian to reassign.",
    );
  }

  /// Unlinks a Guardian.
  ///
  /// Returns `null` on success, or a user-facing message on failure.
  ///
  /// Removing your MAIN Guardian while others remain is refused by the
  /// server, not merely discouraged by the UI. Nothing promotes a
  /// replacement — `auto_designate_main_wali` only fires on the row being
  /// written — and Family Review reads `is_main`, so a Seeker left with
  /// Guardians and no Main could not have a review resolved at all.
  static Future<String?> removeGuardian(String waliId) async {
    if (ZyraAuth.currentUser == null) return 'You are not signed in.';
    try {
      final ok = await supabase
          .rpc('zyra_remove_guardian', params: {'p_wali_id': waliId});
      if (ok == true) return null;
      return "That didn't go through. Please try again.";
    } catch (e) {
      final m = e.toString();
      if (m.contains('main_guardian_must_be_reassigned')) {
        return 'Choose a new Main Guardian before removing this one.';
      }
      if (m.contains('not_your_guardian')) {
        return 'They are no longer linked to you.';
      }
      // DR-ZYRA-136 / OA-ZYRA-173, added 2026-08-10. Removing your LAST
      // Guardian during a live Journey is refused server-side, because it
      // hands your family's Family Review vote to the other family.
      //
      // The message names both ways out on purpose. A refusal that only says
      // no reads as the app trapping you in a Journey, which is exactly the
      // harm the Founder accepted this rule's cost against — ending and
      // pausing are always free, and the copy has to say so.
      if (m.contains('guardian_required_during_journey')) {
        return 'Your Journey needs a Guardian on your side. Link someone '
            'else first, or end or pause the Journey.';
      }
      debugPrint('ZYRA: removeGuardian($waliId) failed — $e');
      return "That didn't go through. Please try again.";
    }
  }

  /// Cancels an invite code you sent. Returns true if it was still pending
  /// and is now revoked.
  ///
  /// Only pending invites can be revoked. An accepted invite is a live
  /// Guardian link, and unlinking a real person is a different action with
  /// different consequences — it does not happen quietly from a list of
  /// codes.
  static Future<bool> revokeInvite(String token) async {
    if (ZyraAuth.currentUser == null) return false;
    try {
      final ok = await supabase
          .rpc('zyra_revoke_wali_invite', params: {'p_token': token});
      return ok == true;
    } catch (e) {
      debugPrint('ZYRA: revokeInvite($token) failed — $e');
      return false;
    }
  }

  /// Invite codes this user has sent that nobody has redeemed yet.
  static Future<List<PendingInvite>> fetchPendingInvites() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return const [];
    try {
      final rows = await supabase
          .from('wali_invites')
          .select('token, label, created_at, expires_at')
          .eq('inviter_id', user.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false) as List;
      return [
        for (final r in rows)
          PendingInvite(
            token: (r as Map<String, dynamic>)['token'] as String,
            label: r['label'] as String?,
            createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
            expiresAt: r['expires_at'] == null
                ? null
                : DateTime.parse(r['expires_at'] as String).toLocal(),
          ),
      ];
    } catch (e) {
      debugPrint('ZYRA: fetchPendingInvites failed — $e');
      return const [];
    }
  }

  /// Creates a new invite as the signed-in user (role is looked up
  /// from their own profiles row) and returns the shareable token, or
  /// null on failure.
  /// [label] is an optional private note for who the code is meant for —
  /// "Dad", "Uncle Ibrahim". It exists so the Pending Invitations section
  /// can read as people rather than as a list of eight-character codes.
  /// Trimmed, capped at the column's 40, and dropped if blank so an
  /// untouched field stores null rather than an empty string.
  /// [relationship] is the CODE, and applies only when a **Guardian** is
  /// inviting a Seeker (Flow B).
  ///
  /// Founder rule, 2026-08-07: *"The relationship is a statement about the
  /// Guardian, so the Guardian makes it — once per link, at the point they
  /// create that link."* In Flow B the Guardian is gone by the time the
  /// link exists, so their answer travels on the invite and
  /// `accept_wali_invite` transfers it to `wali_links.relationship`.
  ///
  /// Ignored for a Seeker-sent invite — the database refuses it there
  /// anyway, because the Guardian is asked at acceptance instead.
  static Future<String?> createInvite({String? label, String? relationship}) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;

    try {
      final profileRow = await supabase.from('profiles').select('role').eq('id', user.id).maybeSingle();
      final role = profileRow?['role'] as String?;
      if (role == null) return null;

      final clean = label?.trim();
      final row = await supabase
          .from('wali_invites')
          .insert({
            'inviter_id': user.id,
            'inviter_role': role,
            if (clean != null && clean.isNotEmpty)
              'label': clean.length > 40 ? clean.substring(0, 40) : clean,
            if (role == 'wali' && relationship != null) 'relationship': relationship,
          })
          .select('token')
          .single();
      return row['token'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// The relationship this Guardian last used, for pre-filling the next
  /// invite. Null when they have no links yet.
  ///
  /// Founder, 2026-08-07: *"If a Guardian has no linked Seekers yet, the
  /// field should start blank. If they already have linked Seekers, prefill
  /// with their most recently used relationship, but never lock it."*
  ///
  /// A convenience, never an assumption — the caller must keep it editable.
  /// A man who invited his daughter last month must not silently label his
  /// niece "Daughter".
  static Future<String?> lastUsedRelationship() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;
    try {
      final rows = await supabase
          .from('wali_links')
          .select('relationship, created_at')
          .eq('wali_id', user.id)
          .not('relationship', 'is', null)
          .order('created_at', ascending: false)
          .limit(1) as List;
      if (rows.isEmpty) return null;
      return (rows.first as Map<String, dynamic>)['relationship'] as String?;
    } catch (e) {
      debugPrint('ZYRA: lastUsedRelationship failed — $e');
      return null;
    }
  }

  /// Looks up who sent an invite before the user commits to
  /// accepting it. Returns null if the token is invalid/unknown —
  /// distinct from a thrown error, which the caller treats as a
  /// generic failure per ERROR_AND_EMPTY_STATE_STANDARD.
  static Future<Map<String, String>?> previewInvite(String token) async {
    try {
      final rows = await supabase.rpc('preview_wali_invite', params: {'p_token': token.trim().toUpperCase()}) as List;
      if (rows.isEmpty) return null;
      final row = rows.first as Map<String, dynamic>;
      return {
        'inviterFirstName': row['inviter_first_name'] as String? ?? '',
        'inviterRole': row['inviter_role'] as String? ?? '',
        'status': row['invite_status'] as String? ?? '',
        // 2026-08-08, Founder-approved. How many Seekers this person
        // already guards. Shown so someone can see whether they are being
        // asked to join a family or a collection — the adversarial review
        // found no cap on Guardians per person, and every hard cap refuses
        // somebody legitimate (the uncle with four nieces). The number
        // costs an honest Guardian nothing.
        //
        // Only meaningful when inviterRole is a Guardian; the UI decides
        // whether to render it. Active links only — a present-tense fact.
        'wardCount': (row['inviter_ward_count'] as num?)?.toInt().toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  /// Accepts an invite. Returns null on success, or a user-facing
  /// error message on failure (invite already used, wrong role for
  /// this invite, not signed in, etc. — accept_wali_invite raises a
  /// specific message for each case, surfaced here directly since
  /// they're already written as plain-language copy).
  ///
  /// [relationship] is the stored CODE ('father', 'uncle'…) and applies only
  /// when a Guardian is accepting: it describes how they are related to the
  /// Seeker they are about to be linked to. A Seeker accepting a Guardian's
  /// invite passes null, because the question is not theirs to answer about
  /// themselves. Null also leaves any relationship already on the link
  /// intact, so re-accepting never blanks it.
  static Future<String?> acceptInvite(String token, {String? relationship}) async {
    try {
      await supabase.rpc('accept_wali_invite', params: {
        'p_token': token.trim().toUpperCase(),
        'p_relationship': relationship,
      });
      return null;
    } catch (e) {
      final message = e.toString();
      if (message.contains('Cannot accept your own invite')) return "That's your own invite code.";
      if (message.contains('Invite not found or already used')) return 'That code is invalid or already used.';
      if (message.contains('This invite is for a Guardian account')) return 'That code is for a Guardian to accept, not a Seeker.';
      if (message.contains('This invite is for a Seeker account')) return 'That code is for a Seeker to accept, not a Guardian.';
      if (message.contains('This invite code has expired')) return 'This code has expired — ask them to generate a new one.';
      return "That didn't work. Check the code and try again.";
    }
  }

  /// Seeker's own linked Guardian(s), or Guardian's own linked Seeker(s) —
  /// whichever applies to the signed-in user's role. Empty (not an
  /// error) if not signed in, not yet linked, or on any failure.
  static Future<List<WaliLinkedPerson>> fetchLinkedPeople({required bool asWali}) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return [];

    try {
      final column = asWali ? 'wali_id' : 'seeker_id';
      final otherColumn = asWali ? 'seeker_id' : 'wali_id';
      // is_main added to the select 2026-08-01 — see WaliLinkedPerson.
      // relationship added 2026-08-06, closing the gap where the field was
      // rendered but never fetched.
      final linkRows = await supabase
          .from('wali_links')
          .select('$otherColumn, is_main, relationship')
          .eq(column, user.id)
          .eq('status', 'active') as List;
      if (linkRows.isEmpty) return [];

      final linkByOtherId = <String, Map<String, dynamic>>{
        for (final r in linkRows)
          (r as Map<String, dynamic>)[otherColumn] as String: r,
      };
      final otherIds = linkByOtherId.keys.toList();
      final profileRows = await supabase.from('profiles').select('id, first_name').inFilter('id', otherIds) as List;

      final people = profileRows.map((r) {
        final map = r as Map<String, dynamic>;
        final id = map['id'] as String;
        final link = linkByOtherId[id];
        return WaliLinkedPerson(
          id: id,
          firstName: map['first_name'] as String,
          isMain: (link?['is_main'] as bool?) ?? false,
          relationship: link?['relationship'] as String?,
        );
      }).toList();

      // Main first. The Seeker's tab renders it as its own section, and a
      // caller should not have to sort to find the one that matters.
      people.sort((a, b) => (b.isMain ? 1 : 0).compareTo(a.isMain ? 1 : 0));
      return people;
    } catch (_) {
      return [];
    }
  }
}
