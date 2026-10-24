import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const path =
      'supabase/migrations/20260918171910_oa256_product_telemetry_foundation.sql';
  late String sql;

  setUpAll(() => sql = File(path).readAsStringSync());

  test('keeps raw storage private and exposes one hardened write RPC', () {
    expect(sql, contains('create table private.zyra_product_events'));
    expect(
      sql,
      contains(
        'revoke all on table private.zyra_product_events from public, anon, authenticated',
      ),
    );
    expect(sql, contains('security definer'));
    expect(sql, contains("set search_path = ''"));
    expect(sql, contains('if auth.uid() is null then'));
    expect(
      sql,
      contains(
        'revoke all on function public.zyra_record_product_event(text, text, text, text, text, text, text)\n  from public, anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.zyra_record_product_event(text, text, text, text, text, text, text)\n  to authenticated, service_role',
      ),
    );
  });

  test(
    'schema has no persistent person, device, session or free-text field',
    () {
      final table = RegExp(
        r'create table private\.zyra_product_events \((.*?)\n\);',
        dotAll: true,
      ).firstMatch(sql)!.group(1)!;
      for (final forbidden in [
        'user_id',
        'profile_id',
        'journey_id',
        'session_id',
        'device_id',
        'zyra_code',
        'payload',
        'metadata',
        'properties',
        'json',
      ]) {
        expect(table, isNot(contains(forbidden)), reason: forbidden);
      }
    },
  );

  test('client and SQL taxonomies remain pinned to the same values', () {
    for (final value in [
      'browse',
      'connections',
      'myZyra',
      'guardian',
      'journey',
      'profile',
      'zyraCode',
      'membership',
      'identityCheck',
      'support',
      'shown',
      'opened',
      'started',
      'completed',
      'failed',
      'pageView',
      'zyraCodeCheck',
      'zyraCodeRequest',
      'knownPersonConsider',
      'supportAnswer',
      'supportEmail',
      'identityProvider',
      'guardianHistoryConsent',
      'guardianReport',
      'guardianMakeMain',
      'guardianRemove',
      'seeker',
      'guardian',
      'entry',
    ]) {
      expect(sql, contains("'$value'"), reason: value);
    }
    expect(sql, contains('action_key text not null'));
  });

  test('has identifier-free abuse control and fixed raw retention', () {
    expect(sql, contains('pg_catalog.pg_advisory_xact_lock'));
    expect(sql, contains(") >= 5000 then\n    return;"));
    expect(
      sql,
      contains(
        "events.occurred_at < statement_timestamp() - interval '30 days'",
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on function public.zyra_prune_product_events()\n  from public, anon, authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.zyra_prune_product_events()\n  to service_role',
      ),
    );
  });

  test('aggregate evidence is service-role only', () {
    expect(sql, contains('public.zyra_product_event_summary'));
    expect(
      sql,
      contains(
        'revoke all on function public.zyra_product_event_summary(timestamptz, timestamptz)\n  from public, anon, authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.zyra_product_event_summary(timestamptz, timestamptz)\n  to service_role',
      ),
    );
    expect(sql, contains('count(*)::bigint as event_count'));
  });
}
