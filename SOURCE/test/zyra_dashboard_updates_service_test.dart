import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/services/zyra_dashboard_updates_service.dart';

void main() {
  Map<String, dynamic> row({
    String occurredAt = '2026-08-30T10:00:00Z',
    String classKey = 'notification',
    String sourceId = 'source-1',
    String titleKey = 'dashboard_updates.notification.new_message.title',
    String detailKey = 'dashboard_updates.notification.new_message.detail',
    String destinationKey = 'notifications',
    String? relatedMatchId,
    bool? isUnread = true,
  }) => {
    'occurred_at': occurredAt,
    'class_key': classKey,
    'source_id': sourceId,
    'title_key': titleKey,
    'detail_key': detailKey,
    'destination_key': destinationKey,
    'related_match_id': relatedMatchId,
    'is_unread': isUnread,
  };

  test(
    'parses an allowlisted row and sends the complete RPC contract',
    () async {
      Map<String, dynamic>? calledWith;
      final page = await ZyraDashboardUpdatesService.fetchPage(
        limit: 1,
        invoke: (parameters) async {
          calledWith = parameters;
          return [row()];
        },
      );

      expect(calledWith, {
        'p_limit': 1,
        'p_cursor_occurred_at': null,
        'p_cursor_class_key': null,
        'p_cursor_source_id': null,
      });
      expect(page, isNotNull);
      expect(page!.rows.single.isUnread, isTrue);
      expect(page.nextCursor?.classKey, 'notification');

      final signal = page.rows.single.toDashboardSignal();
      expect(signal.title, 'New message');
      expect(signal.detail, 'A new message is waiting in your Journey.');
      expect(signal.target, ZyraDashboardTarget.none);
      expect(signal.actionLabel, isNull);
      expect(signal.isUnread, isTrue);
    },
  );

  test(
    'NULL unread remains NULL and never becomes an explicit read state',
    () async {
      final page = await ZyraDashboardUpdatesService.fetchPage(
        invoke: (_) async => [
          row(
            classKey: 'journey_timeline_milestone',
            titleKey: 'dashboard_updates.journey.timeline_milestone.title',
            detailKey:
                'dashboard_updates.journey.timeline_milestone.journey_started.detail',
            destinationKey: 'connections.journeys',
            isUnread: null,
          ),
        ],
      );

      expect(page!.rows.single.isUnread, isNull);
      expect(page.rows.single.toDashboardSignal().isUnread, isNull);
    },
  );

  test(
    'an unknown key fails closed to generic copy and no destination',
    () async {
      final page = await ZyraDashboardUpdatesService.fetchPage(
        invoke: (_) async => [row(detailKey: 'not.allowlisted')],
      );

      final signal = page!.rows.single.toDashboardSignal(
        personContext: 'Private name',
      );
      expect(signal.title, 'Update available');
      expect(signal.title, isNot(contains('Private name')));
      expect(signal.detail, 'Open ZYRA to review it.');
      expect(signal.target, ZyraDashboardTarget.none);
      expect(signal.actionLabel, isNull);
    },
  );

  test(
    'one malformed row fails the whole page instead of partially rendering',
    () async {
      final page = await ZyraDashboardUpdatesService.fetchPage(
        invoke: (_) async => [row(), row(sourceId: '')],
      );

      expect(page, isNull);
    },
  );

  test('complete keyset cursors produce disjoint pages', () async {
    final calls = <Map<String, dynamic>>[];
    final first = await ZyraDashboardUpdatesService.fetchPage(
      limit: 1,
      invoke: (parameters) async {
        calls.add(Map.of(parameters));
        return [row(sourceId: 'first')];
      },
    );
    final second = await ZyraDashboardUpdatesService.fetchPage(
      limit: 1,
      cursor: first!.nextCursor,
      invoke: (parameters) async {
        calls.add(Map.of(parameters));
        return [row(occurredAt: '2026-08-30T09:00:00Z', sourceId: 'second')];
      },
    );

    expect(calls.last, {
      'p_limit': 1,
      'p_cursor_occurred_at': '2026-08-30T10:00:00.000Z',
      'p_cursor_class_key': 'notification',
      'p_cursor_source_id': 'first',
    });
    expect(first.rows.single.sourceId, isNot(second!.rows.single.sourceId));
  });

  test('both production roles use the shared RPC reader only', () {
    final seeker = File(
      'lib/services/zyra_dashboard_adapter.dart',
    ).readAsStringSync();
    final guardian = File(
      'lib/screens/wali/wali_dashboard_screen.dart',
    ).readAsStringSync();

    expect(seeker, contains('ZyraDashboardUpdatesService.fetchPage()'));
    expect(guardian, contains('ZyraDashboardUpdatesService.fetchPage'));
    expect(seeker, isNot(contains('fetchRecent(')));
    expect(seeker, isNot(contains('fetchActivityResult(')));
    expect(guardian, isNot(contains('fetchTimelineResult(')));
  });

  test(
    'the closed renderer covers every key emitted by the live migration',
    () {
      final migration = File(
        'supabase/migrations/'
        '20260830145711_oa281_dashboard_updates_projection.sql',
      ).readAsStringSync();
      final renderer = File(
        'lib/services/zyra_dashboard_updates_service.dart',
      ).readAsStringSync();
      final emittedKeys = RegExp(
        r"'(dashboard_updates\.[^']+)'",
      ).allMatches(migration).map((match) => match.group(1)!).toSet();

      expect(emittedKeys, isNotEmpty);
      for (final key in emittedKeys) {
        expect(renderer, contains("'$key'"), reason: 'missing template $key');
      }
      for (final destination in const [
        'notifications',
        'connections.journeys',
        'guardian',
      ]) {
        expect(renderer, contains("'$destination'"));
      }
    },
  );
}
