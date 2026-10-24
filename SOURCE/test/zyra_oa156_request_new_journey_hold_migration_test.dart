import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/'
      '20260910195642_oa156_request_new_journey_testflight_hold.sql';

  test('OA-ZYRA-156 hold is grants-only and covers all four app endpoints', () {
    final migration = File(migrationPath).readAsStringSync();

    const signatures = <String>[
      'public.request_new_journey(uuid)',
      'public.respond_to_journey_request(uuid, text)',
      'public.zyra_may_request_new_journey(uuid)',
      'public.zyra_may_request_new_journey_ids()',
    ];
    for (final signature in signatures) {
      expect(
        migration,
        contains('revoke execute on function $signature'),
        reason: signature,
      );
    }

    expect(
      'from public, anon, authenticated;'.allMatches(migration),
      hasLength(4),
    );
    expect(migration, isNot(contains('create or replace function')));
    expect(migration, isNot(contains('grant execute')));
    expect(migration, isNot(contains('zyra_expire_due_journey_requests')));
    expect(migration, isNot(contains('restart_journey(uuid)')));
  });

  test('OA-ZYRA-156 hold aborts on every ruled pre-apply drift', () {
    final migration = File(migrationPath).readAsStringSync();

    expect(migration, contains("raise sqlstate '55000'"));
    expect(migration, contains('from public.journey_requests;'));
    expect(migration, contains('v_request_rows <> 0'));
    expect(migration, contains('group by attempt.match_id'));
    expect(migration, contains('having count(*) > 1'));
    expect(migration, contains('v_second_attempts <> 0'));
    expect(migration, contains("'journey_request_accepted'"));
    expect(migration, contains('v_request_notifications <> 0'));
    expect(
      migration,
      contains("'authenticated', 'public.journey_requests', 'INSERT'"),
    );
    expect(
      migration,
      contains("'authenticated', 'public.journey_requests', 'UPDATE'"),
    );
    expect(
      migration,
      contains("'authenticated', 'public.journey_requests', 'DELETE'"),
    );
    expect(migration, contains('definition_md5'));
    expect(migration, contains('v_overloads <> 1'));
  });

  test('OA-ZYRA-156 hold keeps only the trusted function execution plane', () {
    final migration = File(migrationPath).readAsStringSync();

    final postflight = migration.substring(
      migration.indexOf(r'do $postflight$'),
    );
    expect(postflight, contains("'authenticated', v_oid, 'EXECUTE'"));
    expect(postflight, contains("'anon', v_oid, 'EXECUTE'"));
    expect(postflight, contains("'service_role', v_oid, 'EXECUTE'"));
    expect(postflight, contains("role.rolname = 'postgres'"));
    expect(postflight, contains("role.rolname = 'service_role'"));
  });

  test('OA-ZYRA-156 post-apply harness proves denial and rolls back', () {
    final harness = File(
      'supabase/tests/'
      'zyra_oa156_request_new_journey_hold_post_apply.sql',
    ).readAsStringSync();

    expect(harness.trimLeft(), startsWith('-- OA-ZYRA-156'));
    expect(harness, contains("migration.version = '20260910195642'"));
    expect(harness, contains("array['anon', 'authenticated']"));
    expect(harness, contains('when insufficient_privilege'));
    expect(harness, contains('public.request_new_journey'));
    expect(harness, contains('public.respond_to_journey_request'));
    expect(harness, contains('public.zyra_may_request_new_journey'));
    expect(harness, contains('public.zyra_may_request_new_journey_ids'));
    expect(harness, contains('zyra_expire_due_journey_requests'));
    expect(harness.trimRight(), endsWith('rollback;'));
  });
}
