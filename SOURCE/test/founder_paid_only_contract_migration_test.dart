import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/'
    '20260924100231_founder_paid_only_returns_guardian_circle_contract.sql',
  ).readAsStringSync();

  test('paid access has no Basic fallback and Active cap is three', () {
    expect(
      sql,
      contains('create or replace function public.zyra_has_paid_role'),
    );
    expect(sql, contains("p_role in ('seeker', 'guardian')"));
    expect(sql, contains("then 3 else 0 end"));
    expect(sql, isNot(contains("then 3 else 1 end")));
  });

  test('Family seats are role specific, bounded and protected', () {
    expect(sql, contains('seeker_places between 0 and 10'));
    expect(sql, contains('guardian_places between 0 and 10'));
    expect(sql, contains("role in ('seeker', 'guardian')"));
    expect(sql, contains('family_subscriptions_non_empty'));
    expect(sql, contains('family_place_reduction_guard'));
    expect(sql, contains('family_seeker_places_still_funded'));
    expect(sql, contains('family_guardian_places_still_funded'));
    expect(sql, contains('family_seat_verified_role_guard'));
    expect(sql, contains('verified_family_member_required'));
    expect(sql, contains('family_owner_row_guard'));
    expect(sql, contains('family_owner_seat_guard'));
    expect(sql, contains('verified_family_owner_required'));
    expect(
      sql,
      contains(
        'revoke all on public.family_seat_assignments '
        'from public, anon, authenticated',
      ),
    );
  });

  test('trials are verified-person bound, single-use and Family-forfeited', () {
    expect(sql, contains('private.verified_people'));
    expect(sql, contains('private.verified_person_accounts'));
    expect(sql, contains('private.seeker_trial_ledger'));
    expect(sql, contains("provider_code in ('stripe')"));
    expect(sql, contains("interval '14 days'"));
    expect(sql, contains('seeker_trial_already_used'));
    expect(sql, contains('family_seat_forfeits_seeker_trial'));
    expect(sql, contains("'family_forfeited'"));
  });

  test('billing grace is bounded to sixteen days', () {
    expect(sql, contains('subscriptions_billing_grace_maximum'));
    expect(sql, contains('family_subscriptions_billing_grace_maximum'));
    expect(sql, contains("interval '16 days'"));
    expect(sql, contains('subscription.billing_grace_until > p_at'));
    expect(sql, contains("family.status = 'billing_grace'"));
  });

  test('Family invitations expire at seven days and remain held', () {
    expect(sql, contains('family_invitation_seven_day_window'));
    expect(sql, contains("interval '7 days'"));
    expect(sql, contains('family_invitation_role_mismatch'));
    expect(
      sql,
      contains(
        'revoke all on function public.zyra_accept_family_invitation(uuid)',
      ),
    );
    expect(
      sql,
      isNot(
        contains(
          'grant execute on function public.zyra_accept_family_invitation(uuid) '
          'to authenticated',
        ),
      ),
    );
  });

  test('Family ownership transfer requires a verified existing member', () {
    expect(sql, contains('family_ownership_transfer_guard'));
    expect(sql, contains('family_transfer_existing_member_required'));
    expect(sql, contains('family_transfer_verified_member_required'));
    expect(sql, contains('family_transfer_must_start_at_renewal'));
  });

  test('Journey returns enforce five recent, capacity and thirty days', () {
    expect(sql, contains('limit 5'));
    expect(sql, contains("raise exception 'journey_capacity_unavailable'"));
    expect(sql, contains("interval '30 days'"));
    expect(sql, contains("status = 'withdrawn'"));
    expect(sql, contains("status = 'recipient_unavailable'"));
    expect(sql, isNot(contains("interval '6 months'")));
  });

  test('Ended-return execution remains held for a separate release GO', () {
    for (final signature in [
      'public.request_new_journey(uuid)',
      'public.respond_to_journey_request(uuid,text)',
      'public.zyra_may_request_new_journey(uuid)',
      'public.zyra_may_request_new_journey_ids()',
      'public.withdraw_journey_request(uuid)',
    ]) {
      expect(
        sql,
        contains('revoke execute on function $signature'),
        reason: '$signature must not become public in this migration',
      );
    }
  });

  test('Additional Guardian View and Chat default on and remain separate', () {
    expect(
      sql,
      contains(
        'create table if not exists public.guardian_journey_permissions',
      ),
    );
    expect(sql, contains('can_view boolean not null default true'));
    expect(sql, contains('can_chat boolean not null default true'));
    expect(sql, contains('guardian_journey_chat_requires_view'));
    expect(sql, contains('case when v_is_main then true'));
    expect(
      sql,
      contains('participant.role = \'guardian\' and participant.can_chat'),
    );
  });

  test('Circle requires each participant to hold their paid role', () {
    expect(sql, contains("zyra_has_paid_role(p_seeker, 'seeker')"));
    expect(sql, contains("zyra_has_paid_role(link.wali_id, 'guardian')"));
  });

  test('deleted messages and report evidence have bounded retention', () {
    expect(sql, contains("interval '12 months'"));
    expect(sql, contains("interval '24 months'"));
    expect(sql, contains("then 'Deleted member'"));
    expect(sql, contains("then 'Former Guardian'"));
    expect(sql, contains('legal_hold boolean not null default false'));
    expect(
      sql,
      matches(
        RegExp(
          r'revoke all on public\.family_message_report_evidence\s+'
          r'from public, anon, authenticated',
        ),
      ),
    );
  });

  test('safety case status stays caller-scoped without a paid-role gate', () {
    expect(
      sql,
      contains('create or replace function public.zyra_my_safety_cases()'),
    );
    expect(sql, contains("where report.reporter_id = (select auth.uid())"));
    expect(
      sql,
      contains('grant execute on function public.zyra_my_safety_cases()'),
    );
  });

  test('migration never mutates the locked Supabase Realtime schema', () {
    expect(sql, isNot(contains('realtime.')));
  });
}
