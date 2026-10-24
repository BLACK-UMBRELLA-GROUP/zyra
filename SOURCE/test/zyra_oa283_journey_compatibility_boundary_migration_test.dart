import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationPath =
    'supabase/migrations/'
    '20260910184252_oa283_journey_compatibility_rpc_boundary.sql';

String _functionBody(String sql, String name, {String? nextName}) {
  final start = sql.indexOf('create or replace function public.$name(');
  expect(start, greaterThanOrEqualTo(0), reason: '$name must exist');
  final end = nextName == null
      ? sql.indexOf('revoke all on function', start)
      : sql.indexOf('create or replace function public.$nextName(', start);
  expect(end, greaterThan(start), reason: '$name must have a bounded body');
  return sql.substring(start, end);
}

void main() {
  late String sql;

  setUpAll(() {
    sql = File(_migrationPath).readAsStringSync();
  });

  test('OA283 exposes only caller-relative one-argument RPCs', () {
    final state = _functionBody(
      sql,
      'zyra_journey_compatibility_state',
      nextName: 'zyra_reveal_journey_compatibility',
    );
    final reveal = _functionBody(
      sql,
      'zyra_reveal_journey_compatibility',
      nextName: 'zyra_compatibility_for_plus',
    );

    for (final body in [state, reveal]) {
      expect(body, contains('p_match_id uuid'));
      expect(body, contains('mine_revealed boolean'));
      expect(body, contains('counterpart_revealed boolean'));
      expect(body, contains('my_score numeric'));
      expect(body, contains('v_caller uuid := (select auth.uid())'));
      expect(body, isNot(contains('p_other')));
      expect(body, isNot(contains('p_score')));
      expect(body, isNot(contains('p_side')));
      expect(body, isNot(contains('p_revealed')));
      expect(body, isNot(contains('categories boolean')));
    }

    expect(state, contains('stable\nsecurity definer\nset search_path ='));
    expect(reveal, contains('volatile\nsecurity definer\nset search_path ='));
  });

  test('OA283 binds reads and writes to active unpaused current attempt', () {
    final state = _functionBody(
      sql,
      'zyra_journey_compatibility_state',
      nextName: 'zyra_reveal_journey_compatibility',
    );
    final reveal = _functionBody(
      sql,
      'zyra_reveal_journey_compatibility',
      nextName: 'zyra_compatibility_for_plus',
    );
    final plus = _functionBody(sql, 'zyra_compatibility_for_plus');

    for (final body in [state, reveal, plus]) {
      expect(body, contains("v_match.status is distinct from 'active'"));
      expect(
        body,
        contains(
          "v_match.journey_stage is distinct from 'compatibility_reveal'",
        ),
      );
      expect(body, contains('v_match.suspended_by is not null'));
      expect(body, contains('v_match.also_paused_by is not null'));
      expect(
        body,
        contains("v_match.shared_pause_state is distinct from 'none'"),
      );
      expect(body, contains("a.status = 'active'"));
      expect(
        body,
        contains(
          "v_attempt.journey_stage is distinct from 'compatibility_reveal'",
        ),
      );
      expect(body, contains('v_attempt.paused_by is not null'));
      expect(body, contains('v_attempt.also_paused_by is not null'));
      expect(
        body,
        contains("v_attempt.shared_pause_state is distinct from 'none'"),
      );
      expect(
        body,
        contains('v_compat.attempt_id is distinct from v_attempt.id'),
      );
      expect(body, contains('compatibility_attempt_mismatch'));
    }

    final matchLock = reveal.indexOf('from public.matches as m');
    final attemptLock = reveal.indexOf('from public.journey_attempts as a');
    final rowLock = reveal.indexOf('from public.journey_compatibility as jc');
    expect(matchLock, lessThan(attemptLock));
    expect(attemptLock, lessThan(rowLock));
    expect(reveal.substring(matchLock, rowLock), contains('for update'));
    expect(
      RegExp("to_jsonb\\([ma]\\) ->> 'pause_state'").allMatches(sql).length,
      6,
      reason:
          'all three RPCs must enforce the current and staged shared-Pause models',
    );
  });

  test('OA283 reveal changes only the caller side and gates score output', () {
    final reveal = _functionBody(
      sql,
      'zyra_reveal_journey_compatibility',
      nextName: 'zyra_compatibility_for_plus',
    );
    final state = _functionBody(
      sql,
      'zyra_journey_compatibility_state',
      nextName: 'zyra_reveal_journey_compatibility',
    );

    expect(reveal, contains('set seeker_a_revealed = true'));
    expect(reveal, contains('set seeker_b_revealed = true'));
    expect(
      reveal,
      contains(
        'seeker_a_score = coalesce(jc.seeker_a_score, v_computed_score)',
      ),
    );
    expect(
      reveal,
      contains(
        'seeker_b_score = coalesce(jc.seeker_b_score, v_computed_score)',
      ),
    );
    expect(reveal, contains('public.score_candidates(array[v_counterpart])'));
    expect(
      reveal,
      contains('when jc.seeker_b_revealed and not jc.seeker_a_revealed'),
    );
    expect(
      reveal,
      contains('when jc.seeker_a_revealed and not jc.seeker_b_revealed'),
    );
    expect(
      state,
      contains(
        'when v_compat.seeker_a_revealed and '
        'v_compat.seeker_b_revealed then',
      ),
    );
  });

  test('OA283 preserves Plus as score-only through the same boundary', () {
    final plus = _functionBody(sql, 'zyra_compatibility_for_plus');

    expect(plus, contains('public.profile_unlocks as unlocks'));
    expect(plus, contains("'paid_plus_single', 'paid_plus_bundle'"));
    expect(plus, contains('public.score_candidates(array[v_counterpart])'));
    expect(plus, contains('set seeker_a_score = v_score'));
    expect(plus, contains('set seeker_b_score = v_score'));
    expect(plus, isNot(contains('set seeker_a_revealed')));
    expect(plus, isNot(contains('set seeker_b_revealed')));
    expect(plus, isNot(contains('set revealed_at')));
  });

  test('OA283 leaves no dormant client table doorway', () {
    expect(
      sql,
      contains('revoke all privileges on table public.journey_compatibility'),
    );
    expect(sql, contains('from public, anon, authenticated;'));
    expect(sql, contains('drop policy if exists journey_compatibility_read'));
    expect(sql, contains('drop policy if exists journey_compatibility_insert'));
    expect(sql, contains('drop policy if exists journey_compatibility_update'));
    expect(
      sql,
      contains(
        'alter table public.journey_compatibility enable row level security',
      ),
    );

    expect(
      RegExp("set search_path = ''").allMatches(sql).length,
      3,
      reason: 'both new RPCs and the Plus doorway must use an empty path',
    );
    expect(
      RegExp('to authenticated;').allMatches(sql).length,
      3,
      reason: 'exactly the three compatibility RPCs are client-callable',
    );
  });

  test('OA283 post-apply harness pins the direct-call matrix and rollback', () {
    final harness = File(
      'supabase/tests/'
      'zyra_oa283_journey_compatibility_boundary_post_apply.sql',
    ).readAsStringSync();

    expect(harness, startsWith('-- OA-ZYRA-283'));
    expect(harness, contains("migration.version = '20260910184252'"));
    expect(harness, contains('savepoint oa283_scenario'));
    expect(harness, contains('rollback to savepoint oa283_scenario'));
    expect(harness.trimRight(), endsWith('rollback;'));
    expect(harness, contains('OA283 direct SELECT was not denied'));
    expect(harness, contains('OA283 direct INSERT was not denied'));
    expect(harness, contains('OA283 direct UPDATE was not denied'));
    expect(harness, contains('has_any_column_privilege'));
    expect(harness, contains('has an unexpected EXECUTE grantee'));
    expect(harness, contains('public overloads, expected exactly 1'));
    expect(harness, contains('OA283 missing match'));
    expect(harness, contains('Main Guardian'));
    expect(harness, contains('Additional Guardian'));
    expect(harness, contains('compatibility_attempt_mismatch'));
    expect(harness, contains('OA283 Plus without entitlement was not denied'));
    expect(harness, contains('OA283 Plus B: expected caller-owned score-only'));
    expect(
      RegExp("'zyra_compatibility_for_plus'").allMatches(harness).length,
      greaterThanOrEqualTo(7),
      reason:
          'Plus must join null, actor, missing-match, stale/NULL-attempt, '
          'legacy lifecycle and future shared-Pause denial matrices',
    );
    expect(harness, contains("'match_pause_requested'"));
    expect(harness, contains("'attempt_pause_requested'"));
    expect(harness, contains("'match_continue_requested'"));
    expect(harness, contains("'attempt_continue_requested'"));
    expect(harness, contains('OA283 rollback proof'));
  });
}
