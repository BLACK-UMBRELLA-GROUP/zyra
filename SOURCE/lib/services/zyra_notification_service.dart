// In-app notifications (#16) — reads the `notifications` table added in
// 20260726140000_notifications.sql. Backs the Bell icon (top-right, per
// APP/Navigation/SEEKER NAVIGATION/Summary.md's ratified "Notifications
// use the Bell Icon... not a navigation tab" rule) and the notifications
// feed screen.
//
// Rows are written server-side only (mutual-Like trigger, new-message
// trigger, accept_wali_invite RPC) — this service never inserts, only
// reads and marks read_at. Works for both Seeker and Guardian accounts;
// notifications.user_id is just whichever profile the event was for.

import '../main.dart';
import 'zyra_auth.dart';

class ZyraNotification {
  final String id;
  final String type; // 'new_match' | 'new_message' | 'wali_request'
  final String title;
  final String? body;
  final String? relatedMatchId;
  final DateTime createdAt;
  final DateTime? readAt;

  const ZyraNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.relatedMatchId,
    required this.createdAt,
    required this.readAt,
  });

  bool get isRead => readAt != null;
}

class ZyraNotificationService {
  ZyraNotificationService._();

  /// Most recent notifications for the signed-in user. Empty (not an
  /// error) if not signed in or on any failure.
  static Future<List<ZyraNotification>> fetchRecent({int limit = 50}) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return [];
    try {
      final rows = await supabase
          .from('notifications')
          .select('id, type, title, body, related_match_id, created_at, read_at')
          .order('created_at', ascending: false)
          .limit(limit) as List;
      return rows.map((r) {
        final map = r as Map<String, dynamic>;
        return ZyraNotification(
          id: map['id'] as String,
          type: map['type'] as String,
          title: map['title'] as String,
          body: map['body'] as String?,
          relatedMatchId: map['related_match_id'] as String?,
          createdAt: DateTime.parse(map['created_at'] as String),
          readAt: map['read_at'] == null ? null : DateTime.parse(map['read_at'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Unread count for the Bell icon badge. 0 (not an error) if not
  /// signed in or on any failure.
  static Future<int> fetchUnreadCount() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return 0;
    try {
      final rows = await supabase.from('notifications').select('id').filter('read_at', 'is', null) as List;
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> markRead(String id) async {
    try {
      await supabase.from('notifications').update({'read_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (_) {
      // Best-effort — not worth surfacing a failure to mark something read.
    }
  }

  static Future<void> markAllRead() async {
    try {
      await supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .filter('read_at', 'is', null);
    } catch (_) {}
  }
}
