// Wires the Matches tab (Potential Journeys) and Chat screen to the
// real matches/conversations/messages tables. Matches are created
// server-side the instant a mutual Like exists, by the
// create_match_on_mutual_like trigger (see supabase/migrations/
// match_creation_on_mutual_like.sql) — this service is purely a
// read/write layer over what the trigger already produced; the app
// never creates a match row directly (matches has no client INSERT
// policy by design, per ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md §5).
//
// The Potential-Journey vs Active-Journey distinction stays UX-only
// and client-side, exactly as it was before real backend wiring — the
// schema has no column for it (matches.status only tracks
// active/paused/ended), per MATCH_UX_SPEC_CURRENT_VERSION_V1.md.

import '../main.dart';
import '../models/seeker_profile.dart';
import 'zyra_auth.dart';
import 'zyra_photo_service.dart';
import 'zyra_ages_service.dart';

class ZyraChatMessage {
  final String id;
  final String text;
  final bool fromMe;
  final DateTime createdAt;
  const ZyraChatMessage({required this.id, required this.text, required this.fromMe, required this.createdAt});
}

class ZyraMilestone {
  final String type; // match_created / conversation_started / family_stage / meeting / nikah
  final DateTime occurredAt;
  const ZyraMilestone({required this.type, required this.occurredAt});
}

class ZyraMatchService {
  ZyraMatchService._();

  /// Real mutual matches for the signed-in user, mapped to
  /// SeekerProfile so they can be merged straight into
  /// AppState.potentialJourneys. Empty (never an error surfaced to
  /// the UI) if not signed in, no real matches yet, or on any
  /// failure — the Matches tab already has its own empty-state copy.
  static Future<List<SeekerProfile>> fetchRealMatches() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return [];

    try {
      final rows = await supabase
          .from('matches')
          .select('seeker_a_id, seeker_b_id')
          .eq('status', 'active')
          .or('seeker_a_id.eq.${user.id},seeker_b_id.eq.${user.id}') as List;

      if (rows.isEmpty) return [];

      final otherIds = rows.map((r) {
        final map = r as Map<String, dynamic>;
        final a = map['seeker_a_id'] as String;
        final b = map['seeker_b_id'] as String;
        return a == user.id ? b : a;
      }).toSet().toList();

      if (otherIds.isEmpty) return [];

      final profileRows = await supabase
          .from('profiles')
          .select('id, first_name, location_text, gender, profile_photos(storage_path, display_order)')
          .inFilter('id', otherIds) as List;

      // Raw date_of_birth is no longer selectable by the client — see
      // 20260726120000_hide_raw_dob_expose_age.sql. Ages come from the
      // ages_for() SECURITY DEFINER function instead.
      final ages = await _fetchAges(otherIds);

      final results = <SeekerProfile>[];
      for (final row in profileRows) {
        final map = row as Map<String, dynamic>;
        final photosRaw = List<Map<String, dynamic>>.from((map['profile_photos'] as List?) ?? const []);
        photosRaw.sort((a, b) => (a['display_order'] as int).compareTo(b['display_order'] as int));
        final photos = await ZyraPhotoService.signedUrlsFor(
          photosRaw.map((p) => p['storage_path'] as String).toList(),
        );
        results.add(SeekerProfile(
          id: map['id'] as String,
          firstName: map['first_name'] as String,
          age: ages[map['id'] as String] ?? 0,
          city: (map['location_text'] as String?) ?? '—',
          photos: photos.isEmpty ? ['https://picsum.photos/seed/${map['id']}/700/1000'] : photos,
          gender: map['gender'] as String,
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
  /// rather than breaking the Matches tab over an age lookup.
  static Future<Map<String, int>> _fetchAges(List<String> ids) async {
    // Delegates since 2026-08-08 — see ZyraAgesService for why four
    // identical private copies of this became one.
    return ZyraAgesService.forIds(ids, context: 'matches');
  }

  /// Resolves the real conversation id for a match between the
  /// signed-in user and [otherUserId], or null if none exists (a
  /// mock Browse candidate, no real match yet, or not signed in) —
  /// ChatScreen falls back to its existing local-only mock behaviour
  /// whenever this returns null.
  static Future<String?> resolveConversationId(String otherUserId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;

    try {
      final matchRows = await supabase
          .from('matches')
          .select('id')
          .or(
            'and(seeker_a_id.eq.${user.id},seeker_b_id.eq.$otherUserId),'
            'and(seeker_a_id.eq.$otherUserId,seeker_b_id.eq.${user.id})',
          )
          .limit(1) as List;
      if (matchRows.isEmpty) return null;
      final matchId = (matchRows.first as Map<String, dynamic>)['id'] as String;

      final convRows = await supabase.from('conversations').select('id').eq('match_id', matchId).limit(1) as List;
      if (convRows.isEmpty) return null;
      return (convRows.first as Map<String, dynamic>)['id'] as String;
    } catch (_) {
      return null;
    }
  }

  /// Ordered milestones for the match between the signed-in user and
  /// [otherUserId], oldest first. Empty if not signed in, no real
  /// match exists (mock Active Journey), or on any failure — the
  /// Timeline screen has its own empty-state copy for "nothing here
  /// yet" so this never needs to distinguish those cases for the UI.
  static Future<List<ZyraMilestone>> fetchTimeline(String otherUserId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return [];

    try {
      final matchRows = await supabase
          .from('matches')
          .select('id')
          .or(
            'and(seeker_a_id.eq.${user.id},seeker_b_id.eq.$otherUserId),'
            'and(seeker_a_id.eq.$otherUserId,seeker_b_id.eq.${user.id})',
          )
          .limit(1) as List;
      if (matchRows.isEmpty) return [];
      final matchId = (matchRows.first as Map<String, dynamic>)['id'] as String;

      final timelineRows = await supabase.from('timelines').select('id').eq('match_id', matchId).limit(1) as List;
      if (timelineRows.isEmpty) return [];
      final timelineId = (timelineRows.first as Map<String, dynamic>)['id'] as String;

      final milestoneRows = await supabase
          .from('timeline_milestones')
          .select('milestone_type, occurred_at')
          .eq('timeline_id', timelineId)
          .order('occurred_at') as List;

      return milestoneRows.map((r) {
        final map = r as Map<String, dynamic>;
        return ZyraMilestone(type: map['milestone_type'] as String, occurredAt: DateTime.parse(map['occurred_at'] as String));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<ZyraChatMessage>> fetchMessages(String conversationId) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return [];
    try {
      final rows = await supabase
          .from('messages')
          .select('id, sender_id, content, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at') as List;
      return rows.map((r) {
        final map = r as Map<String, dynamic>;
        return ZyraChatMessage(
          id: map['id'] as String,
          text: map['content'] as String,
          fromMe: map['sender_id'] == user.id,
          createdAt: DateTime.parse(map['created_at'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Best-effort. Returns true on success so the caller can decide
  /// whether to roll back an optimistic local append on failure.
  static Future<bool> sendMessage(String conversationId, String text) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false;
    try {
      await supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'content': text,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
