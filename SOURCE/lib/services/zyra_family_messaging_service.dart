import 'package:flutter/foundation.dart' show debugPrint;

import '../data/zyra_reference_data.dart' show zyraRelationshipLabel;
import '../main.dart' show supabase, supabaseReady;
import 'zyra_auth.dart';
import 'zyra_wali_link_service.dart' show ZyraSourceFailure, ZyraSourceResult;

enum ZyraFamilyMessageAccess {
  ready,
  membershipRequired,
  linkInactive,
  blocked,
  unavailable,
}

enum ZyraFamilyMessageContextKind { active, potential, paused, ended }

class ZyraFamilyMessageContext {
  final String referenceId;
  final String firstName;
  final ZyraFamilyMessageContextKind kind;

  const ZyraFamilyMessageContext({
    required this.referenceId,
    required this.firstName,
    required this.kind,
  });

  String get stateLabel => switch (kind) {
    ZyraFamilyMessageContextKind.active => 'Active Journey',
    ZyraFamilyMessageContextKind.potential => 'Potential',
    ZyraFamilyMessageContextKind.paused => 'Paused',
    ZyraFamilyMessageContextKind.ended => 'Ended',
  };

  static ZyraFamilyMessageContext? fromRow(Map<String, dynamic> row) {
    final referenceId = row['context_id'];
    final firstName = row['context_first_name'];
    final rawKind = row['context_kind'];
    if (referenceId == null && firstName == null && rawKind == null) {
      return null;
    }
    final kind = switch (rawKind) {
      'active' => ZyraFamilyMessageContextKind.active,
      'potential' => ZyraFamilyMessageContextKind.potential,
      'paused' => ZyraFamilyMessageContextKind.paused,
      'ended' => ZyraFamilyMessageContextKind.ended,
      _ => null,
    };
    if (referenceId is! String ||
        referenceId.isEmpty ||
        firstName is! String ||
        firstName.trim().isEmpty ||
        kind == null) {
      return null;
    }
    return ZyraFamilyMessageContext(
      referenceId: referenceId,
      firstName: firstName.trim(),
      kind: kind,
    );
  }
}

class ZyraFamilyCircleParticipant {
  final String userId;
  final String firstName;
  final String memberRole;
  final bool isMainGuardian;
  final bool isCurrentUser;

  const ZyraFamilyCircleParticipant({
    required this.userId,
    required this.firstName,
    required this.memberRole,
    required this.isMainGuardian,
    required this.isCurrentUser,
  });

  String get roleLabel => switch (memberRole) {
    'seeker' => 'Seeker',
    'guardian' when isMainGuardian => 'Main Guardian',
    'guardian' => 'Additional Guardian',
    _ => 'Circle member',
  };

  static ZyraFamilyCircleParticipant? fromRow(Map<String, dynamic> row) {
    final userId = row['user_id'];
    final firstName = row['first_name'];
    final memberRole = row['member_role'];
    final isMain = row['is_main_guardian'];
    final isCurrent = row['is_current_user'];
    if (userId is! String ||
        userId.isEmpty ||
        firstName is! String ||
        firstName.trim().isEmpty ||
        (memberRole != 'seeker' && memberRole != 'guardian') ||
        isMain is! bool ||
        isCurrent is! bool) {
      return null;
    }
    return ZyraFamilyCircleParticipant(
      userId: userId,
      firstName: firstName.trim(),
      memberRole: memberRole as String,
      isMainGuardian: isMain,
      isCurrentUser: isCurrent,
    );
  }
}

class ZyraGuardianCircleAccess {
  final String? threadId;
  final String seekerId;
  final String seekerFirstName;
  final int participantCount;
  final bool canSend;
  final bool muted;
  final ZyraFamilyMessageAccess access;

  const ZyraGuardianCircleAccess({
    required this.threadId,
    required this.seekerId,
    required this.seekerFirstName,
    required this.participantCount,
    required this.canSend,
    required this.muted,
    required this.access,
  });

  static ZyraGuardianCircleAccess? fromRow(Map<String, dynamic> row) {
    final threadId = row['thread_id'];
    final seekerId = row['seeker_id'];
    final seekerName = row['seeker_first_name'];
    final participantCount = row['participant_count'];
    final canSend = row['can_send'];
    final muted = row['muted'];
    if ((threadId != null && threadId is! String) ||
        seekerId is! String ||
        seekerId.isEmpty ||
        seekerName is! String ||
        seekerName.trim().isEmpty ||
        participantCount is! num ||
        participantCount < 1 ||
        canSend is! bool ||
        muted is! bool) {
      return null;
    }
    return ZyraGuardianCircleAccess(
      threadId: threadId as String?,
      seekerId: seekerId,
      seekerFirstName: seekerName.trim(),
      participantCount: participantCount.toInt(),
      canSend: canSend,
      muted: muted,
      access: _accessFrom(row['access_reason']),
    );
  }
}

class ZyraGuardianCircleSummary {
  final String threadId;
  final String seekerId;
  final String seekerFirstName;
  final int participantCount;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool canSend;
  final bool muted;
  final ZyraFamilyMessageAccess access;

  const ZyraGuardianCircleSummary({
    required this.threadId,
    required this.seekerId,
    required this.seekerFirstName,
    required this.participantCount,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.canSend,
    required this.muted,
    required this.access,
  });

  static ZyraGuardianCircleSummary? fromRow(Map<String, dynamic> row) {
    final threadId = row['thread_id'];
    final seekerId = row['seeker_id'];
    final seekerName = row['seeker_first_name'];
    final participantCount = row['participant_count'];
    final canSend = row['can_send'];
    final muted = row['muted'];
    final unread = row['unread_count'];
    if (threadId is! String ||
        threadId.isEmpty ||
        seekerId is! String ||
        seekerId.isEmpty ||
        seekerName is! String ||
        seekerName.trim().isEmpty ||
        participantCount is! num ||
        participantCount < 1 ||
        canSend is! bool ||
        muted is! bool ||
        unread is! num) {
      return null;
    }
    return ZyraGuardianCircleSummary(
      threadId: threadId,
      seekerId: seekerId,
      seekerFirstName: seekerName.trim(),
      participantCount: participantCount.toInt(),
      lastMessage: row['last_message'] as String?,
      lastMessageAt: _date(row['last_message_at']),
      unreadCount: unread.toInt(),
      canSend: canSend,
      muted: muted,
      access: _accessFrom(row['access_reason']),
    );
  }
}

class ZyraFamilyMessage {
  final String id;
  final String? senderId;
  final String? senderFirstName;
  final String? senderRelationship;
  final String? senderRoleLabel;
  final String body;
  final DateTime createdAt;
  final bool lifecycle;
  final ZyraFamilyMessageContext? context;
  final List<ZyraFamilyMessageReader> readBy;
  final bool unreadForMe;

  const ZyraFamilyMessage({
    required this.id,
    required this.senderId,
    required this.senderFirstName,
    this.senderRelationship,
    this.senderRoleLabel,
    required this.body,
    required this.createdAt,
    this.lifecycle = false,
    this.context,
    this.readBy = const [],
    this.unreadForMe = false,
  });

  String? get senderIdentityLabel {
    final name = senderFirstName?.trim();
    if (name == null || name.isEmpty) return null;
    final relationship = zyraRelationshipLabel(senderRelationship);
    final role = senderRoleLabel?.trim();
    return <String>[
      name,
      if (relationship != null && relationship.isNotEmpty) relationship,
      if (role != null && role.isNotEmpty && role != name) role,
    ].join(' · ');
  }

  static ZyraFamilyMessage? fromRow(Map<String, dynamic> row) {
    final id = row['message_id'];
    final sender = row['sender_id'];
    final senderName = row['sender_first_name'];
    final senderRelationship = row['sender_relationship'];
    final senderRoleLabel = row['sender_role_label'];
    final body = row['body'];
    final createdAt = _date(row['created_at']);
    final kind = row['kind'];
    final readBy = row['read_by'];
    final unreadForMe = row['unread_for_me'];
    if (id is! String ||
        id.isEmpty ||
        (sender != null && sender is! String) ||
        (senderName != null && senderName is! String) ||
        (senderRelationship != null && senderRelationship is! String) ||
        (senderRoleLabel != null && senderRoleLabel is! String) ||
        body is! String ||
        body.trim().isEmpty ||
        createdAt == null ||
        readBy is! List ||
        unreadForMe is! bool ||
        (kind != 'message' && kind != 'lifecycle')) {
      return null;
    }
    return ZyraFamilyMessage(
      id: id,
      senderId: sender as String?,
      senderFirstName: senderName is String ? senderName.trim() : null,
      senderRelationship: senderRelationship is String
          ? senderRelationship.trim()
          : null,
      senderRoleLabel: senderRoleLabel is String
          ? senderRoleLabel.trim()
          : null,
      body: body,
      createdAt: createdAt,
      lifecycle: kind == 'lifecycle',
      context: ZyraFamilyMessageContext.fromRow(row),
      readBy: ZyraFamilyMessageReader.listFrom(readBy),
      unreadForMe: unreadForMe,
    );
  }
}

class ZyraFamilyMessageReader {
  final String userId;
  final String firstName;
  final String? roleLabel;
  final DateTime? readAt;

  const ZyraFamilyMessageReader({
    required this.userId,
    required this.firstName,
    required this.roleLabel,
    required this.readAt,
  });

  static List<ZyraFamilyMessageReader> listFrom(Object? value) {
    if (value == null) return const [];
    if (value is! List) return const [];
    final readers = <ZyraFamilyMessageReader>[];
    for (final item in value) {
      if (item is! Map) return const [];
      final row = Map<String, dynamic>.from(item);
      final userId = row['user_id'];
      final firstName = row['first_name'];
      final roleLabel = row['role_label'];
      final readAt = _date(row['read_at']);
      if (userId is! String ||
          userId.isEmpty ||
          firstName is! String ||
          firstName.trim().isEmpty ||
          (roleLabel != null && roleLabel is! String) ||
          readAt == null) {
        return const [];
      }
      readers.add(
        ZyraFamilyMessageReader(
          userId: userId,
          firstName: firstName.trim(),
          roleLabel: roleLabel is String ? roleLabel.trim() : null,
          readAt: readAt,
        ),
      );
    }
    return readers;
  }
}

class ZyraFamilyMessagingService {
  ZyraFamilyMessagingService._();

  static Future<ZyraSourceResult<ZyraGuardianCircleAccess>> openCircle(
    String seekerId,
  ) async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    if (ZyraAuth.currentUser == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    try {
      final raw = await supabase.rpc(
        'zyra_open_family_message_circle',
        params: {'p_seeker': seekerId},
      );
      final row = _oneRow(raw);
      final value = row == null ? null : ZyraGuardianCircleAccess.fromRow(row);
      return value == null
          ? const ZyraSourceResult.unavailable(
              ZyraSourceFailure.invalidResponse,
            )
          : ZyraSourceResult.available(value);
    } catch (error) {
      debugPrint('ZYRA Guardian Circle access failed (${error.runtimeType}).');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  static Future<ZyraSourceResult<List<ZyraGuardianCircleSummary>>>
  fetchCircles() async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    if (ZyraAuth.currentUser == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    try {
      final raw = await supabase.rpc('zyra_family_message_circles');
      final rows = _rows(raw);
      if (rows == null) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final result = <ZyraGuardianCircleSummary>[];
      for (final row in rows) {
        final parsed = ZyraGuardianCircleSummary.fromRow(row);
        if (parsed == null) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        result.add(parsed);
      }
      return ZyraSourceResult.available(result);
    } catch (error) {
      debugPrint('ZYRA Guardian Circles failed (${error.runtimeType}).');
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  static Future<ZyraSourceResult<List<ZyraFamilyCircleParticipant>>>
  fetchParticipants(String threadId) async {
    if (!supabaseReady) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.notReady);
    }
    if (ZyraAuth.currentUser == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    try {
      final raw = await supabase.rpc(
        'zyra_family_message_participants',
        params: {'p_thread': threadId},
      );
      final rows = _rows(raw);
      if (rows == null) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final participants = <ZyraFamilyCircleParticipant>[];
      for (final row in rows) {
        final participant = ZyraFamilyCircleParticipant.fromRow(row);
        if (participant == null) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        participants.add(participant);
      }
      return ZyraSourceResult.available(participants);
    } catch (error) {
      debugPrint(
        'ZYRA Guardian Circle participants failed (${error.runtimeType}).',
      );
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  static Future<ZyraSourceResult<List<ZyraFamilyMessage>>> fetchMessages(
    String threadId, {
    DateTime? before,
  }) async {
    try {
      final raw = await supabase.rpc(
        'zyra_family_messages_v3',
        params: {
          'p_thread': threadId,
          'p_before': before?.toUtc().toIso8601String(),
          'p_limit': 50,
        },
      );
      final rows = _rows(raw);
      if (rows == null) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      final result = <ZyraFamilyMessage>[];
      for (final row in rows.reversed) {
        final parsed = ZyraFamilyMessage.fromRow(row);
        if (parsed == null) {
          return const ZyraSourceResult.unavailable(
            ZyraSourceFailure.invalidResponse,
          );
        }
        result.add(parsed);
      }
      return ZyraSourceResult.available(result);
    } catch (error) {
      debugPrint(
        'ZYRA Guardian Circle messages failed (${error.runtimeType}).',
      );
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }

  static Future<bool> send(String threadId, String body) async {
    final clean = body.trim();
    if (clean.isEmpty || clean.length > 2000) return false;
    try {
      await supabase.rpc(
        'zyra_send_family_message',
        params: {'p_thread': threadId, 'p_body': clean},
      );
      return true;
    } catch (error) {
      debugPrint('ZYRA Guardian Circle send failed (${error.runtimeType}).');
      return false;
    }
  }

  static Future<void> markRead(String threadId) async {
    try {
      await supabase.rpc(
        'zyra_mark_family_messages_read',
        params: {'p_thread': threadId},
      );
    } catch (error) {
      debugPrint(
        'ZYRA Guardian Circle read marker failed (${error.runtimeType}).',
      );
    }
  }

  static Future<bool> setMuted(String threadId, {required bool muted}) async {
    try {
      await supabase.rpc(
        'zyra_set_family_message_muted',
        params: {'p_thread': threadId, 'p_muted': muted},
      );
      return true;
    } catch (error) {
      debugPrint('ZYRA Guardian Circle mute failed (${error.runtimeType}).');
      return false;
    }
  }

  static Future<bool> report({
    required String threadId,
    required String messageId,
    required String reason,
  }) async {
    try {
      await supabase.rpc(
        'zyra_report_family_message',
        params: {
          'p_thread': threadId,
          'p_message': messageId,
          'p_reason': reason,
        },
      );
      return true;
    } catch (error) {
      debugPrint('ZYRA Guardian Circle report failed (${error.runtimeType}).');
      return false;
    }
  }
}

ZyraFamilyMessageAccess _accessFrom(Object? value) => switch (value) {
  'ready' => ZyraFamilyMessageAccess.ready,
  'membership_required' => ZyraFamilyMessageAccess.membershipRequired,
  'link_inactive' => ZyraFamilyMessageAccess.linkInactive,
  'blocked' => ZyraFamilyMessageAccess.blocked,
  _ => ZyraFamilyMessageAccess.unavailable,
};

DateTime? _date(Object? value) => value is String
    ? DateTime.tryParse(value)?.toLocal()
    : value is DateTime
    ? value.toLocal()
    : null;

Map<String, dynamic>? _oneRow(Object? raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  final rows = _rows(raw);
  return rows?.length == 1 ? rows!.single : null;
}

List<Map<String, dynamic>>? _rows(Object? raw) {
  if (raw is! List) return null;
  final rows = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is! Map) return null;
    rows.add(Map<String, dynamic>.from(item));
  }
  return rows;
}
