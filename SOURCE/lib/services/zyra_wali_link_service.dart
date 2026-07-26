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
// Deliberately out of scope here: the Extended Wali capability/
// entitlement resolution engine (Primary Wali, Path A/B grants) —
// that's unbuilt architecture with no schema representation yet.
// This service only creates the LINK, not any capability grant.

import '../main.dart';
import 'zyra_auth.dart';

class WaliLinkedPerson {
  final String id;
  final String firstName;
  const WaliLinkedPerson({required this.id, required this.firstName});
}

class ZyraWaliLinkService {
  ZyraWaliLinkService._();

  /// Creates a new invite as the signed-in user (role is looked up
  /// from their own profiles row) and returns the shareable token, or
  /// null on failure.
  static Future<String?> createInvite() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;

    try {
      final profileRow = await supabase.from('profiles').select('role').eq('id', user.id).maybeSingle();
      final role = profileRow?['role'] as String?;
      if (role == null) return null;

      final row = await supabase
          .from('wali_invites')
          .insert({'inviter_id': user.id, 'inviter_role': role})
          .select('token')
          .single();
      return row['token'] as String?;
    } catch (_) {
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
  static Future<String?> acceptInvite(String token) async {
    try {
      await supabase.rpc('accept_wali_invite', params: {'p_token': token.trim().toUpperCase()});
      return null;
    } catch (e) {
      final message = e.toString();
      if (message.contains('Cannot accept your own invite')) return "That's your own invite code.";
      if (message.contains('Invite not found or already used')) return 'That code is invalid or already used.';
      if (message.contains('This invite is for a Wali account')) return 'That code is for a Wali to accept, not a Seeker.';
      if (message.contains('This invite is for a Seeker account')) return 'That code is for a Seeker to accept, not a Wali.';
      if (message.contains('This invite code has expired')) return 'This code has expired — ask them to generate a new one.';
      return "That didn't work. Check the code and try again.";
    }
  }

  /// Seeker's own linked Wali(s), or Wali's own linked Seeker(s) —
  /// whichever applies to the signed-in user's role. Empty (not an
  /// error) if not signed in, not yet linked, or on any failure.
  static Future<List<WaliLinkedPerson>> fetchLinkedPeople({required bool asWali}) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return [];

    try {
      final column = asWali ? 'wali_id' : 'seeker_id';
      final otherColumn = asWali ? 'seeker_id' : 'wali_id';
      final linkRows = await supabase
          .from('wali_links')
          .select(otherColumn)
          .eq(column, user.id)
          .eq('status', 'active') as List;
      if (linkRows.isEmpty) return [];

      final otherIds = linkRows.map((r) => (r as Map<String, dynamic>)[otherColumn] as String).toSet().toList();
      final profileRows = await supabase.from('profiles').select('id, first_name').inFilter('id', otherIds) as List;

      return profileRows
          .map((r) => WaliLinkedPerson(id: (r as Map<String, dynamic>)['id'] as String, firstName: r['first_name'] as String))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
