import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationPath =
    'supabase/migrations/'
    '20260918094504_oa291_per_guardian_past_journey_summaries.sql';
const _postApplyPath =
    'supabase/tests/'
    'zyra_oa291_per_guardian_past_summary_post_apply.sql';

String _functionDefinition(String sql, String functionName) {
  final start = RegExp(
    'create or replace function public\\.$functionName\\b',
    caseSensitive: false,
  ).firstMatch(sql);
  if (start == null) throw StateError('$functionName definition missing');
  final end = sql.indexOf(r'$function$;', start.start);
  if (end < 0) throw StateError('$functionName terminator missing');
  return sql.substring(start.start, end + r'$function$;'.length);
}

void main() {
  final migration = File(_migrationPath).readAsStringSync();
  final postApply = File(_postApplyPath).readAsStringSync();
  final trigger = _functionDefinition(migration, 'auto_designate_main_wali');
  final consent = _functionDefinition(
    migration,
    'zyra_guardian_history_consent',
  );
  final legacy = _functionDefinition(
    migration,
    'zyra_main_guardian_history_consent',
  );
  final summary = _functionDefinition(
    migration,
    'zyra_attempt_summary_for_guardian',
  );

  test('migration is staged and does not widen current-Journey authority', () {
    expect(migration, contains('STAGED ONLY. Do not apply'));
    expect(
      migration,
      isNot(contains('alter table public.journey_guardian_assignments')),
    );
    expect(migration, isNot(contains('create policy')));
    expect(migration, isNot(contains('score_candidates')));
  });

  test('role-neutral link epoch rotates only across inactive boundaries', () {
    expect(migration, contains('add column guardian_link_authority_id uuid'));
    expect(migration, contains('wali_links_guardian_link_authority_state'));
    expect(
      trigger,
      contains(
        'new.guardian_link_authority_id := pg_catalog.gen_random_uuid()',
      ),
    );
    expect(trigger, contains("old.status is distinct from 'active'"));
    expect(
      trigger,
      contains(
        'new.guardian_link_authority_id := old.guardian_link_authority_id',
      ),
    );
    expect(trigger, contains('new.guardian_link_authority_id := null'));
    expect(
      trigger,
      isNot(
        contains(
          'old.is_main is distinct from true\n'
          '       or old.guardian_link_authority_id',
        ),
      ),
    );
  });

  test('permission is Seeker-owned, per Guardian and server-confirmed', () {
    expect(consent, contains('p_guardian uuid'));
    expect(consent, contains('p_enabled boolean default null'));
    expect(consent, contains('v_caller uuid := (select auth.uid())'));
    expect(consent, contains('w.seeker_id = v_caller'));
    expect(consent, contains('w.wali_id = p_guardian'));
    expect(consent, contains("w.status = 'active'"));
    expect(consent, isNot(contains('w.is_main is true')));
    expect(
      consent,
      contains('insert into public.guardian_journey_history_consents'),
    );
    expect(
      consent,
      contains('delete from public.guardian_journey_history_consents c'),
    );
    expect(consent, contains("set search_path = ''"));
    expect(
      migration,
      contains(
        'revoke execute on function '
        'public.zyra_guardian_history_consent(uuid, boolean)\n'
        '  from public, anon;',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function '
        'public.zyra_guardian_history_consent(uuid, boolean)\n'
        '  to authenticated, service_role;',
      ),
    );
  });

  test('legacy Main client remains a narrow compatibility wrapper', () {
    expect(legacy, contains('w.is_main is true'));
    expect(
      legacy,
      contains(
        'from public.zyra_guardian_history_consent(v_guardian, p_enabled)',
      ),
    );
    expect(legacy, isNot(contains('insert into')));
    expect(legacy, isNot(contains('delete from')));
  });

  test('summary remains caller-bound and four-field only', () {
    expect(summary, contains('select (select auth.uid()) as user_id'));
    expect(summary, contains('where c.user_id is not null'));
    expect(summary, contains('w.seeker_id = p_seeker'));
    expect(summary, contains('w.wali_id = c.user_id'));
    expect(summary, contains("w.status = 'active'"));
    expect(summary, contains('p_seeker in (m.seeker_a_id, m.seeker_b_id)'));
    expect(summary, contains('a.ended_at >= w.active_since'));
    expect(
      summary,
      contains(
        'c.guardian_link_authority_id =\n'
        '                w.guardian_link_authority_id',
      ),
    );
    expect(
      summary,
      contains(
        'returns table (\n'
        '  attempt_id uuid,\n'
        '  started_at timestamptz,\n'
        '  ended_at timestamptz,\n'
        '  ended boolean\n'
        ')',
      ),
    );
    for (final forbidden in const [
      'journey_stage',
      'counterpart_first_name',
      'messages',
      'answers',
      'end_reason',
      'private_notes',
      'safety_reports',
    ]) {
      expect(summary.toLowerCase(), isNot(contains(forbidden)));
    }
  });

  test('post-apply proof is transactional and covers the authority matrix', () {
    expect(postApply, startsWith('-- OA-ZYRA-291 / DR-ZYRA-233'));
    expect(postApply, contains(r'\set ON_ERROR_STOP on'));
    expect(postApply, contains('begin;'));
    expect(postApply, endsWith('rollback;\n'));
    expect(postApply, contains('v_main'));
    expect(postApply, contains('v_additional'));
    expect(postApply, contains('v_outsider'));
    expect(postApply, contains('zyra_set_main_guardian'));
    expect(postApply, contains('zyra_remove_guardian'));
    expect(postApply, contains('re-linked Guardian did not restart OFF'));
    expect(postApply, contains('null caller received Journey summaries'));
    expect(postApply, contains('output contract changed'));
    expect(postApply, contains('anon retained RPC execution'));
    expect(
      postApply,
      contains('authenticated retained direct consent-table access'),
    );
  });
}
