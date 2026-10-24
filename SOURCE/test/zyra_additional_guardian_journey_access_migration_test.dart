import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/'
    '20260918075737_oa290_additional_guardian_journey_access.sql',
  );
  late String sql;

  setUpAll(() {
    expect(migration.existsSync(), isTrue);
    sql = migration.readAsStringSync().toLowerCase();
  });

  test('assignment store is audited, private and active-row unique', () {
    expect(sql, contains('create table public.journey_guardian_assignments'));
    expect(sql, contains('granted_by uuid not null'));
    expect(sql, contains('revoked_by uuid'));
    expect(sql, contains('revoked_at timestamptz'));
    expect(sql, contains('where revoked_at is null'));
    expect(sql, contains('enable row level security'));
    expect(
      sql,
      contains(
        'revoke all on table public.journey_guardian_assignments\n'
        '  from public, anon, authenticated',
      ),
    );
  });

  test('Main is unconditional and Additional is exact-attempt authorised', () {
    expect(sql, contains('where w.is_main is true'));
    expect(sql, contains("a.status = 'active'"));
    expect(sql, contains('jga.attempt_id = a.id'));
    expect(sql, contains('jga.wali_link_id = w.id'));
    expect(sql, contains('jga.seeker_id = w.seeker_id'));
    expect(sql, contains('jga.revoked_at is null'));
    expect(sql, isNot(contains('created_at >')));
  });

  test('Seeker RPC rejects cross-family, ended and Main mutations', () {
    expect(sql, contains('security definer'));
    expect(sql, contains("set search_path = ''"));
    expect(sql, contains('w.seeker_id = v_caller'));
    expect(sql, contains('w.wali_id = p_guardian'));
    expect(sql, contains("w.status = 'active'"));
    expect(sql, contains("raise exception 'main_guardian_always_included'"));
    expect(sql, contains('v_caller in (m.seeker_a_id, m.seeker_b_id)'));
    expect(sql, contains("raise exception 'active_owned_journey_not_found'"));
    expect(sql, contains('from public, anon'));
    expect(sql, contains('to authenticated'));
  });

  test('read surfaces follow participation while decisions stay untouched', () {
    for (final policy in const [
      'conversations_select',
      'messages_select',
      'timelines_select',
      'timeline_milestones_select',
      'journey_family_answers_read',
      'matches_select',
    ]) {
      expect(sql, contains('create policy $policy'), reason: policy);
    }
    expect(
      sql,
      contains('create or replace function public.zyra_counterpart_card'),
    );
    expect(sql, isNot(contains('journey_family_reviews_read')));
    expect(sql, isNot(contains('wali_review_decision')));
    expect(sql, isNot(contains('messages_insert')));
  });
}
