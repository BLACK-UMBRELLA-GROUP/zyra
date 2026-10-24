import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationPath =
    'supabase/migrations/20260830200416_oa282_dr225_guardian_history_consent.sql';
const _appliedSecurityPath =
    'supabase/migrations/20260830183151_oa282_guardian_server_truth_security.sql';
const _postApplyMatrixPath =
    'supabase/tests/zyra_oa282_guardian_server_truth_post_apply.sql';

String _functionDefinition(String sql, String functionName) {
  final startMatch = RegExp(
    'create or replace function public\\.$functionName\\b',
    caseSensitive: false,
  ).firstMatch(sql);
  if (startMatch == null) {
    throw StateError('$functionName definition missing');
  }
  final end = sql.indexOf(r'$function$;', startMatch.start);
  if (end < 0) {
    throw StateError('$functionName terminator missing');
  }
  return sql.substring(startMatch.start, end + r'$function$;'.length);
}

void main() {
  final migration = File(_migrationPath).readAsStringSync();
  final assignmentTrigger = _functionDefinition(
    migration,
    'auto_designate_main_wali',
  );
  final consentRpc = _functionDefinition(
    migration,
    'zyra_main_guardian_history_consent',
  );
  final summary = _functionDefinition(
    migration,
    'zyra_attempt_summary_for_guardian',
  );
  final removeGuardian = _functionDefinition(
    File(_appliedSecurityPath).readAsStringSync(),
    'zyra_remove_guardian',
  );
  final postApplyMatrix = File(_postApplyMatrixPath).readAsStringSync();

  test('Phase 0 is one staged server migration with no UI or apply action', () {
    final replacements = RegExp(
      r'create\s+or\s+replace\s+function\s+public\.',
      caseSensitive: false,
    ).allMatches(migration);
    expect(replacements, hasLength(3));
    expect(migration, contains('STAGED ONLY. Do not apply'));
    expect(migration, contains('auto_designate_main_wali'));
    expect(migration, contains('zyra_main_guardian_history_consent'));
    expect(migration, contains('zyra_attempt_summary_for_guardian'));
    expect(migration, isNot(contains('score_candidates')));
    expect(migration, isNot(contains('zyra_dashboard_updates')));
    expect(migration, isNot(contains('seeker_wali_tab.dart')));
  });

  test('consent is bound to a rotating current-Main assignment epoch', () {
    expect(migration, contains('add column main_guardian_authority_id uuid'));
    expect(migration, contains('wali_links_main_guardian_authority_state'));
    expect(
      assignmentTrigger,
      contains(
        'new.main_guardian_authority_id := pg_catalog.gen_random_uuid()',
      ),
    );
    expect(assignmentTrigger, contains("old.status is distinct from 'active'"));
    expect(assignmentTrigger, contains('old.is_main is distinct from true'));
    expect(
      assignmentTrigger,
      contains('new.main_guardian_authority_id := null'),
    );
    expect(assignmentTrigger, contains("set search_path = ''"));
    expect(assignmentTrigger, contains('from public.wali_links w'));
  });

  test('active_since tracks only the current continuous active period', () {
    expect(migration, contains('add column active_since timestamptz'));
    expect(
      migration,
      contains(
        'update public.wali_links\n'
        'set active_since = created_at\n'
        "where status = 'active';",
      ),
    );
    expect(migration, contains('add constraint wali_links_active_since_state'));
    expect(
      assignmentTrigger,
      contains('new.active_since := pg_catalog.clock_timestamp()'),
    );
    expect(assignmentTrigger, contains("old.status is distinct from 'active'"));
    expect(assignmentTrigger, contains('new.active_since := old.active_since'));
    expect(assignmentTrigger, contains('new.active_since := null'));
    expect(
      RegExp(r'set\s+created_at\s*=', caseSensitive: false).hasMatch(migration),
      isFalse,
    );
  });

  test('consent table is current-state only and has no client data path', () {
    expect(
      migration,
      contains('create table public.guardian_journey_history_consents'),
    );
    expect(
      migration,
      contains(
        'wali_link_id uuid primary key\n'
        '    references public.wali_links(id) on delete cascade',
      ),
    );
    expect(migration, contains('main_guardian_authority_id uuid not null'));
    expect(
      migration,
      contains(
        'alter table public.guardian_journey_history_consents '
        'enable row level security',
      ),
    );
    expect(migration, isNot(contains('create policy')));
    expect(
      migration,
      contains(
        'revoke all on table public.guardian_journey_history_consents\n'
        '  from public, anon, authenticated;',
      ),
    );
  });

  test('single RPC is caller-derived, Seeker-owned and server-confirming', () {
    expect(consentRpc, contains('p_enabled boolean default null'));
    expect(consentRpc, contains('v_caller uuid := (select auth.uid())'));
    expect(consentRpc, contains('where w.seeker_id = v_caller'));
    expect(consentRpc, contains("w.status = 'active'"));
    expect(consentRpc, contains('w.is_main is true'));
    expect(consentRpc, isNot(contains('p_seeker')));
    expect(consentRpc, isNot(contains('p_wali')));
    expect(
      consentRpc,
      contains('insert into public.guardian_journey_history_consents'),
    );
    expect(
      consentRpc,
      contains('delete from public.guardian_journey_history_consents c'),
    );
    expect(consentRpc, contains('return query'));
    expect(consentRpc, contains("set search_path = ''"));
    expect(
      migration,
      contains(
        'revoke execute on function '
        'public.zyra_main_guardian_history_consent(boolean)\n'
        '  from public, anon;',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function '
        'public.zyra_main_guardian_history_consent(boolean)\n'
        '  to authenticated, service_role;',
      ),
    );
  });

  test('summary keeps the exact governed four-field shape', () {
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
    expect(summary, isNot(contains('journey_stage')));
    expect(summary, isNot(contains('end_reason')));
    expect(summary, isNot(contains('counterpart')));
    expect(summary, isNot(contains('paused_by')));
  });

  test(
    'caller is auth-derived, null-safe, active Main-only, and ward-bound',
    () {
      expect(summary, contains('select (select auth.uid()) as user_id'));
      expect(summary, contains('where c.user_id is not null'));
      expect(summary, contains('w.seeker_id = p_seeker'));
      expect(summary, contains('w.wali_id = c.user_id'));
      expect(summary, contains("w.status = 'active'"));
      expect(summary, contains('w.is_main is true'));
      expect(summary, contains('p_seeker in (m.seeker_a_id, m.seeker_b_id)'));
      expect(summary, isNot(contains('p_wali')));
      expect(summary, isNot(contains('p_guardian')));
    },
  );

  test('DR-225 is temporal, consent-bound, and positive-allowlist', () {
    expect(summary, contains("a.status = 'active'"));
    expect(summary, contains("a.status = 'ended'"));
    expect(summary, contains('w.active_since'));
    expect(summary, contains('a.ended_at >= w.active_since'));
    expect(summary, isNot(contains('a.ended_at >= w.created_at')));
    expect(summary, contains('c.wali_link_id = w.id'));
    expect(
      summary,
      contains(
        'c.main_guardian_authority_id =\n'
        '                w.main_guardian_authority_id',
      ),
    );
    expect(summary, isNot(contains("a.status <> 'potential'")));
  });

  test(
    'definer is stable, empty-path, qualified, read-only, and tightly granted',
    () {
      final normalized = summary.toLowerCase();
      expect(normalized, contains('language sql\nstable\nsecurity definer'));
      expect(normalized, contains("set search_path = ''"));
      expect(summary, contains('from public.journey_attempts a'));
      expect(summary, contains('join public.matches m'));
      expect(summary, contains('from public.wali_links w'));
      expect(
        summary,
        contains('from public.guardian_journey_history_consents c'),
      );
      expect(
        RegExp(
          r'\b(insert\s+into|update|delete\s+from|merge\s+into|execute)\b',
          caseSensitive: false,
        ).hasMatch(summary),
        isFalse,
      );
      expect(
        migration,
        contains(
          'revoke execute on function '
          'public.zyra_attempt_summary_for_guardian(uuid)\n'
          '  from public, anon;',
        ),
      );
      expect(
        migration,
        contains(
          'grant execute on function '
          'public.zyra_attempt_summary_for_guardian(uuid)\n'
          '  to authenticated, service_role;',
        ),
      );
    },
  );

  test('the applied removal-hint security baseline remains represented', () {
    expect(
      removeGuardian,
      contains(
        "'An active or paused Journey requires you to keep a '\n"
        "                   'Guardian. Assign another Guardian where possible, or '\n"
        "                   'end the Journey through the governed flow before '\n"
        "                   'removing this one.'",
      ),
    );
    expect(removeGuardian, isNot(contains('end or pause the Journey')));
  });

  test('canonical harness carries the exact H1 H2 and H3 corrections', () {
    expect(postApplyMatrix, contains('array[\'search_path=""\']::text[]'));
    expect(postApplyMatrix, isNot(contains("array['search_path=']::text[]")));

    final deleteLinks = postApplyMatrix.indexOf(
      'delete from public.wali_links w\n'
      '  where w.seeker_id in (seeker_a, unrelated_user);',
    );
    final insertMain = postApplyMatrix.indexOf(
      "values (seeker_a, main_guardian, 'active', true);",
    );
    final insertAdditional = postApplyMatrix.indexOf(
      "values (seeker_a, additional_guardian, 'active', false);",
    );
    expect(deleteLinks, greaterThanOrEqualTo(0));
    expect(insertMain, greaterThan(deleteLinks));
    expect(insertAdditional, greaterThan(insertMain));
    expect(postApplyMatrix, contains('set paused_by = seeker_a'));
    expect(postApplyMatrix, contains('paused_at = clock_timestamp()'));
    expect(postApplyMatrix, isNot(contains("set pause_state = 'paused'")));
  });

  test('canonical harness preserves the original twelve meanings', () {
    for (final label in const [
      'case 1 unauthenticated',
      'case 2 unrelated caller',
      'case 3 Seeker caller',
      'case 4 Main Guardian',
      'case 5 Additional Guardian',
      'case 6 dual-role caller',
      'case 7 removed Guardian',
      'case 8 inactive relationship',
      'case 9 potential attempt',
      'case 10 active attempt',
      'case 11 paused attempt',
      'case 12 ended attempt',
    ]) {
      expect(postApplyMatrix, contains(label));
    }
  });

  test('canonical harness adds every ruled DR-225 case and rolls back', () {
    for (final label in const [
      'pre-link ended hidden by default',
      'ended-after-link visible by default',
      'active-started-before-link visible',
      'toggle ON all history',
      'toggle OFF immediate revert',
      'Main reassignment consent auto-reset',
      'former Main loses all access',
      'removed-relinked Main stale consent',
      'activation did not set both periods',
      'same-active-link repromotion reused old consent',
      'unrelated current-Main update changed epoch/period/consent',
      'removal did not clear period/epoch or rewrote created_at',
      'reactivation did not refresh active_since while preserving created_at',
      'relink away-gap ended hidden by active_since',
      'relink active Journey remains visible',
      'relink fresh consent reveals away-gap history',
      'future-status fail-closed pin',
    ]) {
      expect(postApplyMatrix, contains(label));
    }
    expect(postApplyMatrix, contains("m.version = '20260830200416'"));
    expect(postApplyMatrix, contains("set status = 'future_status_probe'"));
    expect(postApplyMatrix.trimRight(), endsWith('rollback;'));
  });
}
