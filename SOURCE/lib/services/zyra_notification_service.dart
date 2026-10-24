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

import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, ValueListenable, ValueNotifier;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

import '../main.dart';
import 'zyra_account_state.dart';
import 'zyra_internal_preview_client.dart';

// THE THREE FETCHES DISTINGUISH FAILURE FROM EMPTY — BUG-05 of the
// 2026-08-14 audit (OA-ZYRA-225 path 4, fixed 2026-08-15). Each used to
// return its empty shape on ANY error, so a network failure rendered
// "All caught up — No new notifications" (copy that is most misleading
// exactly when the person needs to retry) and zeroed a badge that was
// still earned. NULL now means "the fetch FAILED — keep what you had /
// show an error"; the empty shape means the server really said empty.
// Read/write failure never manufactures a read acknowledgement.

/// Destinations are hints only: entering one never marks its contents read.
enum ZyraNavSection { connections, guardian }

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

  /// The section this notification is a pointer to. See
  /// [ZyraNotificationService.sectionFor].
  ZyraNavSection? get section => ZyraNotificationService.sectionFor(type);
}

enum ZyraNotificationAckStatus { confirmed, unavailable, revoked }

/// Success is evidenced by the exact IDs returned by the owner-filtered write.
final class ZyraNotificationAckResult {
  final ZyraNotificationAckStatus status;
  final Set<String> confirmedIds;
  ZyraNotificationAckResult.confirmed(Iterable<String> ids)
    : status = ZyraNotificationAckStatus.confirmed,
      confirmedIds = Set.unmodifiable(ids);
  const ZyraNotificationAckResult.unavailable()
    : status = ZyraNotificationAckStatus.unavailable,
      confirmedIds = const {};
  const ZyraNotificationAckResult.revoked()
    : status = ZyraNotificationAckStatus.revoked,
      confirmedIds = const {};
  bool get isConfirmed => status == ZyraNotificationAckStatus.confirmed;
}

/// A mounted reader's real SDK lifetime, not a developer persona or UI owner.
/// Terminal invalidation also catches queued A→B→A auth events before shared
/// account state has caught up. Callers dispose it with their owning screen.
final class ZyraNotificationOwnerLease {
  ZyraNotificationOwnerLease._(this.userId, this.generation, this._openingToken)
    : _previewSession = ZyraInternalPreviewClient.previewSession;
  final String userId;
  final int generation;
  final String _openingToken;
  final int _previewSession;
  bool _revoked = false;
  StreamSubscription<AuthState>? _subscription;

  static ZyraNotificationOwnerLease? capture() {
    try {
      if (ZyraInternalPreviewClient.isActive || ZyraAccountState.isSigningOut) {
        return null;
      }
      final session = supabase.auth.currentSession;
      final id = supabase.auth.currentUser?.id;
      if (session == null ||
          id == null ||
          session.user.id != id ||
          session.expiresAt == null ||
          session.isExpired ||
          !ZyraAccountState.isCurrent(id, ZyraAccountState.generation)) {
        return null;
      }
      final lease = ZyraNotificationOwnerLease._(
        id,
        ZyraAccountState.generation,
        session.accessToken,
      );
      lease._subscription = supabase.auth.onAuthStateChange.listen((state) {
        if (state.session?.user.id != id ||
            state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.signedOut ||
            state.event == AuthChangeEvent.passwordRecovery ||
            (state.event == AuthChangeEvent.initialSession &&
                state.session?.accessToken != lease._openingToken)) {
          lease._revoked = true;
        }
      }, onError: (Object _, StackTrace _) => lease._revoked = true);
      if (lease.isCurrent) return lease;
      lease.dispose();
      return null;
    } catch (_) {
      return null;
    }
  }

  bool get isCurrent {
    if (_revoked) return false;
    try {
      final session = supabase.auth.currentSession;
      final current =
          ZyraAccountState.isCurrent(userId, generation) &&
          !ZyraInternalPreviewClient.isActive &&
          _previewSession == ZyraInternalPreviewClient.previewSession &&
          supabase.auth.currentUser?.id == userId &&
          session?.user.id == userId &&
          session?.expiresAt != null &&
          session?.isExpired == false;
      if (!current) _revoked = true;
      return current;
    } catch (_) {
      _revoked = true;
      return false;
    }
  }

  void dispose() {
    _revoked = true;
    _subscription?.cancel().ignore();
  }
}

class ZyraNotificationService {
  ZyraNotificationService._();

  static final _confirmedAcknowledgements = ValueNotifier<int>(0);

  /// Identifier-free invalidation only. Readers fetch fresh owner-bound state;
  /// this signal never supplies an optimistic unread value or private payload.
  static ValueListenable<int> get confirmedAcknowledgements =>
      _confirmedAcknowledgements;

  // Navigation colour and rows share confirmed server read_at. Neither tab
  // entry nor a fetch is evidence that every underlying item was viewed.

  /// THE MAP. Every type the LIVE database permits, checked against
  /// notifications_type_check on 2026-08-13 rather than against the
  /// migrations in this repo — the repo knew seven types and the
  /// database holds ten (see OA-ZYRA-215). A type this map has not been
  /// taught returns null and shows no dot, which is the safe direction:
  /// a missing dot is a quiet miss, a wrong dot sends someone to the
  /// wrong screen.
  ///
  /// ENDINGS AND DECLINES ROUTE EXACTLY WHERE EVERYTHING ELSE DOES, and
  /// that is load-bearing rather than incidental. OA-ZYRA-161's first
  /// safety rule is that a safety ending must be worded IDENTICALLY to
  /// an ordinary one, and OA-ZYRA-159 merged decline and expiry into one
  /// type so the requester cannot tell them apart. A destination is a
  /// tell in exactly the way wording is: if `journey_ended` lit a
  /// different dot, the dot would announce what the words were careful
  /// not to. One section for all of them, structurally.
  static ZyraNavSection? sectionFor(String type) => switch (type) {
    'new_match' => ZyraNavSection.connections,
    'new_message' => ZyraNavSection.connections,
    'journey_ended' => ZyraNavSection.connections,
    'journey_request' => ZyraNavSection.connections,
    'journey_request_accepted' => ZyraNavSection.connections,
    'journey_request_declined' => ZyraNavSection.connections,
    'milestone_proposed' => ZyraNavSection.connections,
    'milestone_confirmed' => ZyraNavSection.connections,
    'pause_nudge' => ZyraNavSection.connections,
    // SHARED PAUSE HOLDS — DR-ZYRA-170 (2026-08-15). Three types the
    // pause lifecycle finally speaks with: told when paused, told
    // when the other rests too, told when the Journey is active
    // again (the silent re-activation is gone). All point at
    // Connections like every other Journey event. The live
    // notifications_type_check now holds THIRTEEN types and the
    // migration adding them is IN THIS REPO
    // (20260815183000_shared_pause_holds.sql) — narrowing
    // OA-ZYRA-215's repo-lags-live gap rather than widening it.
    'journey_paused' => ZyraNavSection.connections,
    'journey_also_paused' => ZyraNavSection.connections,
    'journey_continued' => ZyraNavSection.connections,
    'wali_request' => ZyraNavSection.guardian,
    'wali_invite_received' => ZyraNavSection.guardian,
    'wali_invite_declined' => ZyraNavSection.guardian,
    'wali_invite_expiring' => ZyraNavSection.guardian,
    'wali_invite_expired' => ZyraNavSection.guardian,
    'wali_invite_revoked' => ZyraNavSection.guardian,
    _ => null,
  };

  /// The types that belong to [section] — the inverse of [sectionFor],
  /// derived from it rather than written twice.
  static List<String> typesFor(ZyraNavSection section) => [
    for (final t in _allTypes)
      if (sectionFor(t) == section) t,
  ];

  /// Every type the map knows. Kept beside [sectionFor] so adding a type
  /// to one without the other is a visible omission rather than a silent
  /// gap in [typesFor].
  static const List<String> _allTypes = [
    'new_match',
    'new_message',
    'wali_request',
    'wali_invite_received',
    'wali_invite_declined',
    'wali_invite_expiring',
    'wali_invite_expired',
    'wali_invite_revoked',
    'journey_ended',
    'journey_request',
    'journey_request_accepted',
    'journey_request_declined',
    'milestone_proposed',
    'milestone_confirmed',
    'pause_nudge',
    'journey_paused',
    'journey_also_paused',
    'journey_continued',
  ];

  /// Which sections currently have something waiting.
  ///
  /// A SET, NOT A COUNT, and deliberately: the dot answers whether there
  /// is anything, not how much. That is the Founder's 2026-08-06 ruling
  /// on the Connections segment dots — "the heading already says how
  /// many; the dot only has to answer whether there is anything" —
  /// applied to the nav bar. Returning counts here would invite a number
  /// onto a control that should not carry one.
  /// Null = the fetch failed (BUG-05): callers hold their last set
  /// rather than clearing dots that may still be earned.
  static Future<Set<ZyraNavSection>?> fetchSectionsWithUnread() async {
    final owner = ZyraNotificationOwnerLease.capture();
    if (owner == null) return null;
    final token = supabase.auth.currentSession!.accessToken;
    try {
      final rows =
          await supabase
                  .from('notifications')
                  .select('type')
                  .eq('user_id', owner.userId)
                  .filter('read_at', 'is', null)
                  .setHeader('Authorization', 'Bearer $token')
              as List;
      if (!owner.isCurrent ||
          supabase.auth.currentSession?.accessToken != token) {
        return null;
      }
      return {
        for (final r in rows)
          // Null-aware element: a type the map has not been taught
          // drops out rather than needing a guard around it.
          ?sectionFor((r as Map<String, dynamic>)['type'] as String),
      };
    } catch (e) {
      debugPrint('ZYRA: fetchSectionsWithUnread failed — $e');
      return null;
    } finally {
      owner.dispose();
    }
  }

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Resolves only the explicit notification ID carried by the allowlisted
  /// Dashboard Updates projection. Domain events and guessed destinations
  /// never become notification acknowledgements.
  static String? dashboardNotificationId(String signalId, bool? isUnread) {
    final parts = signalId.split(':');
    if (isUnread != true ||
        parts.length != 3 ||
        parts[0] != 'update' ||
        !parts[1].startsWith('notification.')) {
      return null;
    }
    final type = parts[1].substring('notification.'.length);
    return _allTypes.contains(type) && _uuid.hasMatch(parts[2])
        ? parts[2]
        : null;
  }

  /// Acknowledges only the captured rows, never all rows arriving before the
  /// server executes a request. The captured bearer and explicit user filter
  /// prevent an account switch from redirecting this update to the next actor.
  static Future<ZyraNotificationAckResult> acknowledgeIds(
    Iterable<String> ids,
  ) async {
    final captured = Set<String>.unmodifiable(ids);
    if (captured.any((id) => !_uuid.hasMatch(id))) {
      return const ZyraNotificationAckResult.unavailable();
    }
    final owner = ZyraNotificationOwnerLease.capture();
    if (owner == null) return const ZyraNotificationAckResult.revoked();
    try {
      final token = supabase.auth.currentSession!.accessToken;
      if (!owner.isCurrent) return const ZyraNotificationAckResult.revoked();
      if (captured.isEmpty) {
        return ZyraNotificationAckResult.confirmed(const {});
      }
      final rows = await supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', owner.userId)
          .inFilter('id', captured.toList(growable: false))
          .select('id, read_at')
          .setHeader('Authorization', 'Bearer $token')
          .timeout(const Duration(seconds: 10));
      if (!owner.isCurrent ||
          supabase.auth.currentSession?.accessToken != token) {
        return const ZyraNotificationAckResult.revoked();
      }
      final returned = <String>{};
      for (final row in rows) {
        final id = row['id'];
        final readAt = row['read_at'];
        if (id is! String ||
            !captured.contains(id) ||
            !returned.add(id) ||
            readAt is! String ||
            DateTime.tryParse(readAt) == null) {
          return const ZyraNotificationAckResult.unavailable();
        }
      }
      if (returned.length != captured.length) {
        return const ZyraNotificationAckResult.unavailable();
      }
      _confirmedAcknowledgements.value++;
      return ZyraNotificationAckResult.confirmed(returned);
    } catch (_) {
      return owner.isCurrent
          ? const ZyraNotificationAckResult.unavailable()
          : const ZyraNotificationAckResult.revoked();
    } finally {
      owner.dispose();
    }
  }

  /// Most recent notifications for the signed-in user. Empty if not
  /// signed in or genuinely none; NULL if the fetch failed (BUG-05) —
  /// the screen shows an error-with-retry, never "All caught up".
  static Future<List<ZyraNotification>?> fetchRecent({int limit = 50}) async {
    final owner = ZyraNotificationOwnerLease.capture();
    if (owner == null) return null;
    final token = supabase.auth.currentSession!.accessToken;
    try {
      final rows =
          await supabase
                  .from('notifications')
                  .select(
                    'id, type, title, body, related_match_id, created_at, read_at',
                  )
                  .eq('user_id', owner.userId)
                  .order('created_at', ascending: false)
                  .limit(limit)
                  .setHeader('Authorization', 'Bearer $token')
              as List;
      if (!owner.isCurrent ||
          supabase.auth.currentSession?.accessToken != token) {
        return null;
      }
      return rows.map((r) {
        final map = r as Map<String, dynamic>;
        return ZyraNotification(
          id: map['id'] as String,
          type: map['type'] as String,
          title: map['title'] as String,
          body: map['body'] as String?,
          relatedMatchId: map['related_match_id'] as String?,
          createdAt: DateTime.parse(map['created_at'] as String),
          readAt: map['read_at'] == null
              ? null
              : DateTime.parse(map['read_at'] as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('ZYRA: fetchRecent failed — $e');
      return null;
    } finally {
      owner.dispose();
    }
  }

  /// Unread count for the tab badge. 0 if not signed in or genuinely
  /// none; NULL if the fetch failed (BUG-05) — callers hold the last
  /// known count rather than zeroing a badge that may still be earned.
  static Future<int?> fetchUnreadCount() async {
    final owner = ZyraNotificationOwnerLease.capture();
    if (owner == null) return null;
    final token = supabase.auth.currentSession!.accessToken;
    try {
      final rows =
          await supabase
                  .from('notifications')
                  .select('id')
                  .eq('user_id', owner.userId)
                  .filter('read_at', 'is', null)
                  .setHeader('Authorization', 'Bearer $token')
              as List;
      if (!owner.isCurrent ||
          supabase.auth.currentSession?.accessToken != token) {
        return null;
      }
      return rows.length;
    } catch (e) {
      debugPrint('ZYRA: fetchUnreadCount failed — $e');
      return null;
    } finally {
      owner.dispose();
    }
  }
}
