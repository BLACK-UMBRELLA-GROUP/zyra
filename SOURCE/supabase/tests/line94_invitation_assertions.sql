-- Q120 and Q125 / DOC-ZYRA-0473 V2 / OA-ZYRA-317.
\set ON_ERROR_STOP on
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

grant select on server0_v2_fixture_actors to authenticated;
create temporary table line94_invitation(token text, expires_at timestamptz);
grant select, insert on line94_invitation to authenticated;

create function pg_temp.line94_invite_assert(p_ok boolean, p_label text)
returns void language plpgsql security invoker as $$
begin
  if p_ok is distinct from true then raise exception 'Q125 FAIL: %', p_label; end if;
  raise notice 'Q125 PASS: %', p_label;
end;
$$;

create function pg_temp.line94_invite_reject(p_expected text)
returns void language plpgsql security invoker as $$
begin
  begin
    perform public.zyra_create_guardian_invitation();
  exception when others then
    if sqlerrm is distinct from p_expected then raise; end if;
    raise notice 'Q125 PASS: %', p_expected;
    return;
  end;
  raise exception 'Q125 unexpectedly created an invitation';
end;
$$;

select pg_temp.line94_invite_assert(
  not has_function_privilege('anon','public.zyra_create_guardian_invitation()','execute')
  and not has_table_privilege('authenticated','public.wali_invites','insert'),
  'invitation RPC is authenticated and direct writes remain held'
);

insert into public.wali_links(seeker_id, wali_id, status, is_main, relationship)
select seeker.id, guardian.id, 'active', true, 'father'
from server0_v2_fixture_actors seeker cross join server0_v2_fixture_actors guardian
where seeker.fixture_label = 'fem1' and guardian.fixture_label = 'gb';

insert into public.wali_invites(inviter_id, inviter_role, created_at, expires_at)
select id, 'seeker', now() - interval '8 days', now() - interval '1 day'
from server0_v2_fixture_actors where fixture_label = 'fem1';

set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub',id,'role','authenticated')::text,true)
from server0_v2_fixture_actors where fixture_label = 'gb';
select pg_temp.line94_invite_reject('seeker_required');

select set_config('request.jwt.claims', jsonb_build_object('sub',id,'role','authenticated')::text,true)
from server0_v2_fixture_actors where fixture_label = 'fem1';
insert into line94_invitation select * from public.zyra_create_guardian_invitation();
select pg_temp.line94_invite_assert((
  select invitation.expires_at = row.expires_at
    and row.expires_at = row.created_at + interval '14 days'
    and row.issued_by_guardian_invitation_rpc
    and invitation.token ~ '^ZYRA-[0-9A-F]{4}(-[0-9A-F]{4}){4}$'
  from line94_invitation invitation join public.wali_invites row using (token)
), 'Seeker Basic with linked Guardian can mint a 14-day token using the approved generator');

select pg_temp.line94_invite_assert((
  select count(*) = 1 from public.wali_invites where status = 'expired'
), 'send again keeps the expired invitation and creates a new row');

do $$
begin
  for n in 1..8 loop
    perform public.zyra_create_guardian_invitation();
  end loop;
end;
$$;
select pg_temp.line94_invite_assert((
  select count(*) = 9 from public.wali_invites where status = 'pending'
), 'one linked Guardian plus nine pending invitations fits the limit');
select pg_temp.line94_invite_reject('guardian_limit');

select set_config('request.jwt.claims', jsonb_build_object('sub',id,'role','authenticated')::text,true)
from server0_v2_fixture_actors where fixture_label = 'gb';
select pg_temp.line94_invite_assert(
  (select count(*) = 0 from public.wali_invites row join line94_invitation test using (token)),
  'another member cannot read the issued token from the invitation table'
);
select pg_temp.line94_invite_assert((
  select preview.expires_at = test.expires_at
    and preview.invite_status = 'pending' and not (to_jsonb(preview) ? 'token')
  from line94_invitation test
  cross join lateral public.preview_wali_invite(test.token) preview
), 'a bearer can preview the authoritative expiry without a token in the response');

reset role;
rollback;
