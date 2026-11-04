// SERVER/BRIEFS/SERVER_0_BRIEF_2026-10-30_V2.md R2 replaces the old hold.
// This is a current local SQL fixture check; no database action or UI master.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationPath =
    'supabase/migrations/'
    '20261030151033_server0_main_guardian_hold_without_pause.sql';

void main() {
  late String sql;

  setUpAll(() {
    final file = File(_migrationPath);
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync().toLowerCase();
  });

  test('demotion is caller-bound and does not unlink the Guardian', () {
    expect(sql, contains('function public.zyra_clear_main_guardian'));
    expect(sql, contains('where seeker_id = v_me'));
    expect(sql, contains('and wali_id = p_wali_id'));
    expect(sql, contains("and status = 'active'"));
    expect(sql, contains('set is_main = false'));

    final clearStart = sql.indexOf(
      'create or replace function public.zyra_clear_main_guardian',
    );
    final clearEnd = sql.indexOf(
      'create or replace function public.zyra_remove_guardian',
    );
    final clearBody = sql.substring(clearStart, clearEnd);
    expect(clearBody, isNot(contains("set status = 'removed'")));
  });

  test('relationship RPCs and gate use hardened explicit grants', () {
    expect(RegExp("set search_path = ''").allMatches(sql).length, 4);
    for (final signature in const [
      'public.zyra_clear_main_guardian(uuid)',
      'public.zyra_remove_guardian(uuid)',
      'public.zyra_journey_main_guardian_gate(uuid)',
    ]) {
      expect(sql, contains('revoke execute on function $signature'));
      expect(sql, contains('grant execute on function $signature'));
    }
    expect(sql, contains('from public, anon'));
    expect(sql, contains('to authenticated, service_role'));
  });

  test('Journey gate returns only caller-relative Main presence', () {
    expect(sql, contains('returns table (\n  self_has_main boolean,'));
    expect(sql, contains('other_has_main boolean'));
    expect(sql, contains('v_me not in (v_a, v_b)'));
    expect(sql, isNot(contains('guardian_first_name')));
    expect(sql, isNot(contains('relationship_label')));
  });

  test(
    'ordinary active writes are held and End bypasses the non-Pause replacement',
    () {
      expect(sql, contains("v_match_status is distinct from 'active'"));
      expect(
        sql,
        contains("raise exception 'main_guardian_required_for_journey'"),
      );
      expect(sql, contains('v_match_status := new.status'));
      expect(
        sql,
        contains('old.journey_stage is distinct from new.journey_stage'),
      );
      expect(sql, isNot(contains('new.pause_state')));
      expect(sql, isNot(contains('old.pause_state')));
      expect(sql, isNot(contains("new.status = 'ended' and")));
      expect(sql, isNot(contains("new.pause_state = 'paused' and")));
    },
  );

  test('message writes resolve their governed conversation attempt', () {
    expect(sql, contains("if tg_table_name = 'messages' then"));
    expect(sql, contains('from public.conversations c'));
    expect(sql, contains("v_payload ->> 'conversation_id'"));
    expect(sql, contains('from public.journey_attempts a'));
  });

  test('all current ordinary Journey write surfaces are covered', () {
    for (final table in const [
      'journey_salams',
      'journey_stage_checkpoints',
      'journey_phase_answers',
      'journey_phase_ratings',
      'journey_phase_checkpoints',
      'journey_family_answers',
      'journey_family_reviews',
      'messages',
    ]) {
      expect(sql, contains("'$table'"), reason: table);
    }
    expect(sql, contains('on public.journey_compatibility'));
    expect(sql, contains('on public.matches'));
    expect(sql, contains('on public.journey_attempts'));
    expect(sql.trimRight(), endsWith('commit;'));
  });
}
