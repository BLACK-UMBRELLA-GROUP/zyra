import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationPath =
    'supabase/migrations/'
    '20260917133709_guardian_journey_summary_for_all_active_guardians.sql';

String _functionDefinition(String sql) {
  final start = RegExp(
    r'create\s+or\s+replace\s+function\s+'
    r'public\.zyra_attempt_summary_for_guardian\b',
    caseSensitive: false,
  ).firstMatch(sql);
  if (start == null) throw StateError('summary function missing');
  final end = sql.indexOf(r'$function$;', start.start);
  if (end < 0) throw StateError('summary function terminator missing');
  return sql.substring(start.start, end + r'$function$;'.length);
}

void main() {
  final migration = File(_migrationPath).readAsStringSync();
  final summary = _functionDefinition(migration);

  test('migration is staged and replaces only the summary boundary', () {
    expect(migration, contains('STAGED ONLY. Do not apply'));
    expect(
      RegExp(
        r'create\s+or\s+replace\s+function\s+public\.',
        caseSensitive: false,
      ).allMatches(migration),
      hasLength(1),
    );
    expect(migration, isNot(contains('create table')));
    expect(migration, isNot(contains('alter table')));
    expect(migration, isNot(contains('create policy')));
  });

  test('every caller must hold the requested Seeker active link', () {
    expect(summary, contains('select (select auth.uid()) as user_id'));
    expect(summary, contains('where c.user_id is not null'));
    expect(summary, contains('w.seeker_id = p_seeker'));
    expect(summary, contains('w.wali_id = c.user_id'));
    expect(summary, contains("w.status = 'active'"));
    expect(summary, contains('current_guardian_link'));
    expect(
      summary,
      isNot(contains("w.status = 'active'\n      and w.is_main is true")),
    );
    expect(summary, contains('p_seeker in (m.seeker_a_id, m.seeker_b_id)'));
  });

  test('all active Guardians receive the same narrow four-field shape', () {
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
    expect(summary, contains("a.status = 'active'"));
    expect(summary, contains("a.status = 'ended'"));
    expect(summary, contains('a.ended_at >= w.active_since'));
    for (final forbidden in const [
      'journey_stage',
      'counterpart',
      'messages',
      'compatibility',
      'end_reason',
      'notes',
      'safety',
    ]) {
      expect(summary.toLowerCase(), isNot(contains(forbidden)));
    }
  });

  test('full-history consent remains current-Main-only', () {
    expect(summary, contains('w.is_main is true'));
    expect(
      summary,
      contains('from public.guardian_journey_history_consents c'),
    );
    expect(summary, contains('c.wali_link_id = w.id'));
    expect(
      summary,
      contains(
        'c.main_guardian_authority_id =\n'
        '                  w.main_guardian_authority_id',
      ),
    );
  });

  test('definer boundary stays hardened and tightly granted', () {
    final normalized = summary.toLowerCase();
    expect(normalized, contains('language sql\nstable\nsecurity definer'));
    expect(normalized, contains("set search_path = ''"));
    expect(summary, contains('from public.wali_links w'));
    expect(summary, contains('from public.journey_attempts a'));
    expect(summary, contains('join public.matches m'));
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
  });
}
