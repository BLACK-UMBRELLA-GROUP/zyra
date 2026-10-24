import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/'
    '20260830145711_oa281_dashboard_updates_projection.sql',
  );
  final callerParticipationMigration = File(
    'supabase/migrations/'
    '20260806112743_oa156_stage3b_caller_scoped_participation.sql',
  );
  final participantRowsMigration = File(
    'supabase/migrations/'
    '20260806112625_oa156_stage3b_enriched_participants_and_policies.sql',
  );

  late String sql;
  late String callerParticipationSql;
  late String participantRowsSql;

  setUpAll(() {
    for (final file in [
      migration,
      callerParticipationMigration,
      participantRowsMigration,
    ]) {
      expect(file.existsSync(), isTrue, reason: file.path);
    }
    sql = migration.readAsStringSync().toLowerCase();
    callerParticipationSql = callerParticipationMigration
        .readAsStringSync()
        .toLowerCase();
    participantRowsSql = participantRowsMigration
        .readAsStringSync()
        .toLowerCase();
  });

  test('RPC is caller-scoped, read-only and hardened', () {
    expect(sql, contains('stable\nsecurity definer'));
    expect(sql, contains("set search_path = ''"));
    expect(sql, contains('v_caller uuid := (select auth.uid())'));
    expect(sql, contains('if v_caller is null then'));
    expect(sql, contains('greatest(1, least(coalesce(p_limit, 3), 20))'));
    expect(sql, contains('from public.zyra_my_attempt_participation'));
    expect(sql, contains('revoke execute on function'));
    expect(sql, contains('from public, anon'));
    expect(sql, contains('to authenticated, service_role'));
    expect(sql, isNot(contains('score_candidates')));
    expect(sql, isNot(contains('alter table')));
    expect(sql, isNot(contains('insert into')));
    expect(sql, isNot(contains('update public.')));
    expect(sql, isNot(contains('delete from')));
  });

  test('participation source remains caller-scoped with ruled dimensions', () {
    expect(
      callerParticipationSql,
      contains('select attempt_id, role, match_id, is_main, attempt_status'),
    );
    expect(
      callerParticipationSql,
      contains('where user_id = (select auth.uid())'),
    );
    expect(participantRowsSql, contains("'seeker'::text as role"));
    expect(participantRowsSql, contains("'guardian'"));
    expect(participantRowsSql, contains("w.status = 'active'"));
    expect(participantRowsSql, contains('w.is_main'));
    expect(participantRowsSql, contains('a.status as attempt_status'));
  });

  test('projection retains authority dimensions to explicit branch rules', () {
    expect(
      sql,
      contains(
        'p.attempt_id,\n'
        '      p.match_id,\n'
        '      p.role,\n'
        '      p.is_main,\n'
        '      p.attempt_status',
      ),
    );
    expect(sql, contains("nt.audience_kind = 'direct_recipient'"));
    expect(sql, contains("nt.audience_kind = 'seeker_match'"));
    expect(sql, contains('cp.match_id = n.related_match_id'));
    expect(sql, contains("cp.role = 'seeker'"));
    expect(sql, contains('cp.attempt_id = t.attempt_id'));
    expect(sql, contains('cp.match_id = t.match_id'));
    expect(sql, contains("cp.role = 'guardian'"));
    expect(sql, contains('cp.is_main is true'));
    expect(sql, contains("cp.attempt_status <> 'potential'"));
    expect(sql, contains('cp.attempt_id = r.attempt_id'));
    expect(sql, contains('cp.match_id = r.match_id'));
    expect(sql, contains('and s.seeker_id = v_caller'));
    expect(sql, isNot(contains('s.wali_id = v_caller')));
  });

  test('projection uses deterministic descending keyset pagination', () {
    expect(
      sql,
      contains(
        '(u.occurred_at, u.class_key, u.source_id)\n'
        '        < (p_cursor_occurred_at, p_cursor_class_key, '
        'p_cursor_source_id)',
      ),
    );
    expect(
      sql,
      contains(
        'order by u.occurred_at desc, u.class_key desc, u.source_id desc',
      ),
    );
    expect(
      sql,
      contains("raise exception 'dashboard_updates_cursor_incomplete'"),
    );
  });

  test(
    'notification registry keeps only current notification-only classes',
    () {
      for (final notificationType in const [
        'new_message',
        'wali_request',
        'journey_request',
        'journey_request_declined',
        'pause_nudge',
        'journey_also_paused',
        'wali_invite_received',
        'wali_invite_declined',
        'wali_invite_expiring',
        'wali_invite_expired',
        'wali_invite_revoked',
        'milestone_proposed',
      ]) {
        expect(
          sql,
          contains('dashboard_updates.notification.$notificationType.title'),
          reason: notificationType,
        );
      }

      for (final canonicalDomainMirror in const [
        'new_match',
        'journey_ended',
        'journey_request_accepted',
        'journey_paused',
        'journey_continued',
        'milestone_confirmed',
        'journey_decision_needed',
        'journey_decision_answered',
      ]) {
        expect(
          sql,
          isNot(
            contains(
              'dashboard_updates.notification.$canonicalDomainMirror.title',
            ),
          ),
          reason: canonicalDomainMirror,
        );
      }
      expect(sql, isNot(contains('not exists (')));
    },
  );

  test(
    'only controlled copy keys and governed domain classes are returned',
    () {
      for (final classKey in const [
        'journey.timeline_milestone',
        'guardian.suggestion',
        'guardian.review_opened',
        'guardian.review_answered',
      ]) {
        expect(sql, contains(classKey), reason: classKey);
      }
      expect(sql, isNot(contains('n.title as')));
      expect(sql, isNot(contains('n.body')));
      expect(sql, isNot(contains('rr.decision')));
      expect(sql, isNot(contains('tm.metadata')));
    },
  );

  test('is_unread remains a strict three-state contract', () {
    expect(sql, contains('true as is_unread'));
    expect(RegExp(r'null::boolean as is_unread').allMatches(sql).length, 4);
    expect(sql, isNot(contains('false as is_unread')));
    expect(
      sql,
      contains(
        'true means an unread notification; false is reserved for a future '
        'explicit read-notification projection; null means a domain event '
        'and must never be rendered as read',
      ),
    );
  });

  test('timestamp and attempt-plus-match integrity guards are explicit', () {
    for (final guard in const [
      'n.created_at is not null',
      'tm.occurred_at is not null',
      's.created_at is not null',
      'r.opened_at is not null',
      'rr.responded_at is not null',
      't.attempt_id is not null',
      't.match_id is not null',
      'r.attempt_id is not null',
      'r.match_id is not null',
    ]) {
      expect(sql, contains(guard), reason: guard);
    }
  });

  test('indexes match branch access paths and real response key', () {
    expect(
      sql,
      contains(
        'on public.journey_family_reviews '
        '(attempt_id, opened_at desc, id desc)\n'
        'where attempt_id is not null',
      ),
    );
    expect(sql, contains('(review_id, responded_at desc, wali_id)'));
    expect(
      sql,
      contains('on public.notifications (user_id, created_at desc, id desc)'),
    );
    expect(sql, contains('where read_at is null'));
    expect(sql, isNot(contains('wali_suggestions_dashboard_updates_wali_idx')));
  });

  test('response key and ruled projection wording are precise', () {
    expect(
      sql,
      contains("md5(rr.review_id::text || ':' || rr.wali_id::text)::uuid"),
    );
    expect(sql, contains('deterministic pseudonymous key'));
    expect(sql, contains('not an anonymity guarantee'));
    expect(
      sql,
      contains(
        'meaningful-movement projection — unread-backed notifications + '
        'authoritative domain events; not an inbox or history; the '
        'notifications manager is the history surface',
      ),
    );
  });
}
