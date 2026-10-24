import 'package:flutter/foundation.dart' show debugPrint;

import '../main.dart';
import '../models/zyra_dashboard_resolution.dart';

typedef ZyraDashboardUpdatesInvoker =
    Future<dynamic> Function(Map<String, dynamic> parameters);

/// The complete keyset cursor owned by `public.zyra_dashboard_updates`.
///
/// The server rejects partial cursors. Keeping the three values in one object
/// makes that invalid state unrepresentable in normal client code.
final class ZyraDashboardUpdatesCursor {
  final DateTime occurredAt;
  final String classKey;
  final String sourceId;

  const ZyraDashboardUpdatesCursor({
    required this.occurredAt,
    required this.classKey,
    required this.sourceId,
  });
}

/// One caller-authorised row from the Dashboard Updates projection.
///
/// It deliberately contains only opaque server keys and references. User copy
/// is resolved through the allowlisted renderer below; database rows never
/// become executable or user-facing copy.
final class ZyraDashboardUpdate {
  final DateTime occurredAt;
  final String classKey;
  final String sourceId;
  final String titleKey;
  final String detailKey;
  final String destinationKey;
  final String? relatedMatchId;

  /// TRUE = unread notification; FALSE = reserved explicit read state;
  /// NULL = domain event with no read state.
  final bool? isUnread;

  const ZyraDashboardUpdate({
    required this.occurredAt,
    required this.classKey,
    required this.sourceId,
    required this.titleKey,
    required this.detailKey,
    required this.destinationKey,
    required this.relatedMatchId,
    required this.isUnread,
  });

  ZyraDashboardUpdatesCursor get cursor => ZyraDashboardUpdatesCursor(
    occurredAt: occurredAt,
    classKey: classKey,
    sourceId: sourceId,
  );

  DashboardSignal toDashboardSignal({String? personContext}) {
    final template = ZyraDashboardUpdateTemplates.resolve(
      titleKey: titleKey,
      detailKey: detailKey,
      destinationKey: destinationKey,
    );
    final context = personContext?.trim();
    final title = !template.isGeneric && context != null && context.isNotEmpty
        ? '$context · ${template.title}'
        : template.title;
    return DashboardSignal(
      id: 'update:$classKey:$sourceId',
      kind: DashboardSignalKind.meaningfulMovement,
      title: title,
      detail: template.detail,
      actionLabel: template.actionLabel,
      target: template.target,
      eventAt: occurredAt,
      isUnread: isUnread,
    );
  }
}

final class ZyraDashboardUpdatesPage {
  final List<ZyraDashboardUpdate> rows;
  final ZyraDashboardUpdatesCursor? nextCursor;

  ZyraDashboardUpdatesPage({
    required List<ZyraDashboardUpdate> rows,
    required this.nextCursor,
  }) : rows = List.unmodifiable(rows);
}

final class ZyraDashboardUpdateTemplate {
  final String title;
  final String? detail;
  final ZyraDashboardTarget target;
  final String? actionLabel;
  final bool isGeneric;

  const ZyraDashboardUpdateTemplate({
    required this.title,
    required this.detail,
    required this.target,
    required this.actionLabel,
    this.isGeneric = false,
  });
}

/// Closed client renderer for every key emitted by migration 20260830145711.
///
/// If any one key is unknown, the whole row becomes the same quiet generic
/// update with no navigation. That is the fail-closed direction: it neither
/// invents event meaning nor sends the member to a guessed destination.
final class ZyraDashboardUpdateTemplates {
  const ZyraDashboardUpdateTemplates._();

  static const _titles = <String, String>{
    'dashboard_updates.notification.new_message.title': 'New message',
    'dashboard_updates.notification.wali_request.title':
        'Guardian connection updated',
    'dashboard_updates.notification.journey_request.title':
        'New Journey request',
    'dashboard_updates.notification.journey_request_declined.title':
        'Journey request update',
    'dashboard_updates.notification.pause_nudge.title':
        'Whenever you are ready',
    'dashboard_updates.notification.journey_also_paused.title':
        'Your Journey is paused',
    'dashboard_updates.notification.wali_invite_received.title':
        'Guardian invitation received',
    'dashboard_updates.notification.wali_invite_declined.title':
        'Guardian invitation update',
    'dashboard_updates.notification.wali_invite_expiring.title':
        'Guardian invitation expiring',
    'dashboard_updates.notification.wali_invite_expired.title':
        'Guardian invitation expired',
    'dashboard_updates.notification.wali_invite_revoked.title':
        'Guardian invitation withdrawn',
    'dashboard_updates.notification.milestone_proposed.title':
        'Milestone to confirm',
    'dashboard_updates.journey.timeline_milestone.title': 'Journey milestone',
    'dashboard_updates.guardian.suggestion.title':
        'Guardian suggestion received',
    'dashboard_updates.guardian.review_opened.title': 'Family Review opened',
    'dashboard_updates.guardian.review_answered.title':
        'Family Review response recorded',
  };

  static const _details = <String, String>{
    'dashboard_updates.notification.new_message.detail':
        'A new message is waiting in your Journey.',
    'dashboard_updates.notification.wali_request.detail':
        'Your Guardian connection has changed.',
    'dashboard_updates.notification.journey_request.detail':
        'A new Journey request is ready to review.',
    'dashboard_updates.notification.journey_request_declined.detail':
        'A Journey request is no longer moving forward.',
    'dashboard_updates.notification.pause_nudge.detail':
        'A paused Journey has an update waiting.',
    'dashboard_updates.notification.journey_also_paused.detail':
        'Both people are now taking space.',
    'dashboard_updates.notification.wali_invite_received.detail':
        'A Guardian invitation is ready to review.',
    'dashboard_updates.notification.wali_invite_declined.detail':
        'A Guardian invitation is no longer moving forward.',
    'dashboard_updates.notification.wali_invite_expiring.detail':
        'A Guardian invitation is close to expiring.',
    'dashboard_updates.notification.wali_invite_expired.detail':
        'A Guardian invitation has expired.',
    'dashboard_updates.notification.wali_invite_revoked.detail':
        'A Guardian invitation has been withdrawn.',
    'dashboard_updates.notification.milestone_proposed.detail':
        'A Journey milestone is waiting for confirmation.',
    'dashboard_updates.journey.timeline_milestone.liked.detail':
        'A Like was recorded.',
    'dashboard_updates.journey.timeline_milestone.match_created.detail':
        'A match was created.',
    'dashboard_updates.journey.timeline_milestone.journey_started.detail':
        'A Journey began.',
    'dashboard_updates.journey.timeline_milestone.compatibility_revealed.detail':
        'Compatibility was revealed.',
    'dashboard_updates.journey.timeline_milestone.salam_exchanged.detail':
        'Salam was exchanged.',
    'dashboard_updates.journey.timeline_milestone.guardian_linked.detail':
        'A Guardian step was completed.',
    'dashboard_updates.journey.timeline_milestone.phase_1_complete.detail':
        'Faith & Values was completed.',
    'dashboard_updates.journey.timeline_milestone.phase_2_complete.detail':
        'Building a Life was completed.',
    'dashboard_updates.journey.timeline_milestone.phase_3_complete.detail':
        'Navigating Life was completed.',
    'dashboard_updates.journey.timeline_milestone.family_stage.detail':
        'Family Compatibility was reached.',
    'dashboard_updates.journey.timeline_milestone.conversation_started.detail':
        'Open Conversation began.',
    'dashboard_updates.journey.timeline_milestone.journey_paused.detail':
        'The Journey was paused.',
    'dashboard_updates.journey.timeline_milestone.journey_continued.detail':
        'The Journey continued.',
    'dashboard_updates.journey.timeline_milestone.journey_ended.detail':
        'The Journey ended.',
    'dashboard_updates.journey.timeline_milestone.meeting.detail':
        'A meeting was confirmed.',
    'dashboard_updates.journey.timeline_milestone.nikah.detail':
        'Nikah was confirmed.',
    'dashboard_updates.guardian.suggestion.detail':
        'A Guardian suggestion is ready to review.',
    'dashboard_updates.guardian.review_opened.detail':
        'A Family Review is ready.',
    'dashboard_updates.guardian.review_answered.detail':
        'A Guardian response was added to the Family Review.',
  };

  static const _destinations = <String, ZyraDashboardTarget>{
    // Notification-only rows already live in My ZYRA > Now. Keeping this
    // server key allowlisted while resolving it to no destination prevents a
    // circular route to the retired Notifications screen.
    'notifications': ZyraDashboardTarget.none,
    'connections.journeys': ZyraDashboardTarget.connectionsJourneys,
    'guardian': ZyraDashboardTarget.guardian,
  };

  static ZyraDashboardUpdateTemplate resolve({
    required String titleKey,
    required String detailKey,
    required String destinationKey,
  }) {
    final title = _titles[titleKey];
    final detail = _details[detailKey];
    final target = _destinations[destinationKey];
    if (title == null || detail == null || target == null) {
      return const ZyraDashboardUpdateTemplate(
        title: 'Update available',
        detail: 'Open ZYRA to review it.',
        target: ZyraDashboardTarget.none,
        actionLabel: null,
        isGeneric: true,
      );
    }
    return ZyraDashboardUpdateTemplate(
      title: title,
      detail: detail,
      target: target,
      actionLabel: switch (target) {
        ZyraDashboardTarget.connectionsJourneys => 'Open Journey',
        ZyraDashboardTarget.guardian => 'Open Guardian',
        _ => null,
      },
    );
  }
}

/// Shared production reader used by both Dashboard roles.
final class ZyraDashboardUpdatesService {
  ZyraDashboardUpdatesService._();

  static Future<ZyraDashboardUpdatesPage?> fetchPage({
    int limit = 3,
    ZyraDashboardUpdatesCursor? cursor,
    ZyraDashboardUpdatesInvoker? invoke,
  }) async {
    final effectiveLimit = limit.clamp(1, 20);
    final parameters = <String, dynamic>{
      'p_limit': effectiveLimit,
      'p_cursor_occurred_at': cursor?.occurredAt.toUtc().toIso8601String(),
      'p_cursor_class_key': cursor?.classKey,
      'p_cursor_source_id': cursor?.sourceId,
    };
    try {
      final raw = await (invoke ?? _invoke)(parameters);
      if (raw is! List) throw const FormatException('updates_not_a_list');
      final rows = <ZyraDashboardUpdate>[
        for (final value in raw) _parseRow(value),
      ];
      return ZyraDashboardUpdatesPage(
        rows: rows,
        nextCursor: rows.length == effectiveLimit ? rows.last.cursor : null,
      );
    } catch (error) {
      debugPrint('ZYRA: zyra_dashboard_updates failed — $error');
      return null;
    }
  }

  static Future<dynamic> _invoke(Map<String, dynamic> parameters) =>
      supabase.rpc('zyra_dashboard_updates', params: parameters);

  static ZyraDashboardUpdate _parseRow(dynamic value) {
    if (value is! Map) throw const FormatException('updates_row_not_a_map');
    final row = Map<String, dynamic>.from(value);
    final occurredAt = DateTime.tryParse(_requiredString(row, 'occurred_at'));
    if (occurredAt == null) {
      throw const FormatException('updates_occurred_at_invalid');
    }
    final unread = row['is_unread'];
    if (unread != null && unread is! bool) {
      throw const FormatException('updates_is_unread_invalid');
    }
    final related = row['related_match_id'];
    if (related != null && related is! String) {
      throw const FormatException('updates_related_match_id_invalid');
    }
    return ZyraDashboardUpdate(
      occurredAt: occurredAt.toUtc(),
      classKey: _requiredString(row, 'class_key'),
      sourceId: _requiredString(row, 'source_id'),
      titleKey: _requiredString(row, 'title_key'),
      detailKey: _requiredString(row, 'detail_key'),
      destinationKey: _requiredString(row, 'destination_key'),
      relatedMatchId: related as String?,
      isUnread: unread as bool?,
    );
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('updates_${key}_invalid');
    }
    return value.trim();
  }
}
