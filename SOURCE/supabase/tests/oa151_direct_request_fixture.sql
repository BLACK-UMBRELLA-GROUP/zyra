-- OA151 reconstructed fake dependencies ONLY. Not a production schema replay,
-- receipt/provider acceptance, Auth gateway proof or live migration authority.
-- Root runner supplies the guard GUC and a newly owned empty tmpfs database.
\set ON_ERROR_STOP on
do $guard$
begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
     or current_setting('zyra.oa151_local_replay', true) is distinct from 'enabled'
     or current_user <> 'postgres' or session_user <> 'postgres'
     or to_regnamespace('auth') is not null
     or to_regnamespace('oa151_synthetic') is not null
     or to_regnamespace('oa151_kernel') is not null
     or to_regclass('public.profiles') is not null
     or to_regclass('public.matches') is not null then
    raise exception 'OA151 fixture refuses nonempty/unarmed/wrong database';
  end if;
end;
$guard$;
begin;
do $roles$
begin
  if not exists (select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls; end if;
  if exists (select 1 from pg_roles where rolname in ('anon','authenticated') and (rolsuper or rolbypassrls)) then
    raise exception 'OA151 refuses privileged fake member roles';
  end if;
end;
$roles$;
create schema auth;
create schema oa151_synthetic;
revoke all on schema oa151_synthetic from public, anon, authenticated, service_role;
grant usage on schema auth, public to anon, authenticated, service_role;
create function auth.uid() returns uuid language sql stable set search_path = '' as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
revoke all on function auth.uid() from public;
grant execute on function auth.uid() to authenticated, anon, service_role;
create table public.profiles (
  id uuid primary key, role text not null, gender text, admission_ready boolean not null
);
create table oa151_synthetic.funded_receipts (
  user_id uuid primary key references public.profiles(id),
  membership text not null check(membership in ('basic','one','family_seeker')),
  trusted_fake_proof boolean not null,
  valid_until timestamptz not null
);
create table public.matches (
  id uuid primary key, seeker_a_id uuid not null references public.profiles(id),
  seeker_b_id uuid not null references public.profiles(id),
  status text not null check(status in ('potential','active','ended')),
  -- Explicit fake occupancy adapter inputs, not a new product enum proposal.
  pause_state text not null check(pause_state in ('none','pending_pause','paused'))
);
create table public.journey_attempts (
  id uuid primary key, match_id uuid not null references public.matches(id),
  status text not null check(status in ('potential','active','ended'))
);
create table public.wali_links (
  seeker_id uuid not null references public.profiles(id),
  wali_id uuid not null references public.profiles(id), status text not null,
  primary key(seeker_id,wali_id)
);
create table public.conversations (
  id uuid primary key, match_id uuid not null references public.matches(id),
  attempt_id uuid not null references public.journey_attempts(id)
);
create table public.timelines (
  id uuid primary key, match_id uuid not null references public.matches(id),
  attempt_id uuid not null references public.journey_attempts(id)
);
create table oa151_synthetic.pair_denials (
  user_a uuid not null references public.profiles(id),
  user_b uuid not null references public.profiles(id), reason text not null,
  primary key(user_a,user_b), check(user_a<user_b)
);
insert into public.profiles
select ('00000000-0000-0000-0000-00000000a'||n)::uuid,
  case when n='107' then 'guardian' else 'seeker' end,
  case when n in ('101','103','105','108','111','112','113','114','120','202','203','212','222','223','231')
    then 'male' else 'female' end,
  n<>'109'
from unnest(array['101','102','103','104','105','106','107','108','109','110',
  '111','112','113','114','115','116','117','118','119','120','121','130','131',
  '201','202','203','211','212','221','222','223','230','231']) n;
insert into oa151_synthetic.funded_receipts
select p.id,
  case when right(p.id::text,3) in ('101','102','111','114','201','212','221') then 'basic'
       when right(p.id::text,3)='105' then 'family_seeker' else 'one' end,
  right(p.id::text,3)<>'106', now()+interval '1 year'
from public.profiles p where p.role='seeker';
insert into public.matches values
  ('00000000-0000-0000-0000-00000000b111','00000000-0000-0000-0000-00000000a111','00000000-0000-0000-0000-00000000a115','active','none'),
  ('00000000-0000-0000-0000-00000000b121','00000000-0000-0000-0000-00000000a112','00000000-0000-0000-0000-00000000a116','active','none'),
  ('00000000-0000-0000-0000-00000000b122','00000000-0000-0000-0000-00000000a112','00000000-0000-0000-0000-00000000a117','active','pending_pause'),
  ('00000000-0000-0000-0000-00000000b123','00000000-0000-0000-0000-00000000a112','00000000-0000-0000-0000-00000000a118','active','paused'),
  ('00000000-0000-0000-0000-00000000b131','00000000-0000-0000-0000-00000000a113','00000000-0000-0000-0000-00000000a115','active','none'),
  ('00000000-0000-0000-0000-00000000b132','00000000-0000-0000-0000-00000000a113','00000000-0000-0000-0000-00000000a116','active','none'),
  ('00000000-0000-0000-0000-00000000b133','00000000-0000-0000-0000-00000000a113','00000000-0000-0000-0000-00000000a117','active','none'),
  ('00000000-0000-0000-0000-00000000b141','00000000-0000-0000-0000-00000000a114','00000000-0000-0000-0000-00000000a118','active','pending_pause'),
  ('00000000-0000-0000-0000-00000000b150','00000000-0000-0000-0000-00000000a120','00000000-0000-0000-0000-00000000a121','potential','none'),
  ('00000000-0000-0000-0000-00000000b151','00000000-0000-0000-0000-00000000a120','00000000-0000-0000-0000-00000000a119','ended','none');
insert into public.journey_attempts select
  ('00000000-0000-0000-0000-00000000c'||right(id::text,3))::uuid, id,status
from public.matches;
insert into public.wali_links values
  ('00000000-0000-0000-0000-00000000a111','00000000-0000-0000-0000-00000000a107','active'),
  ('00000000-0000-0000-0000-00000000a131','00000000-0000-0000-0000-00000000a107','active');
insert into oa151_synthetic.pair_denials values
  ('00000000-0000-0000-0000-00000000a101','00000000-0000-0000-0000-00000000a130','block'),
  ('00000000-0000-0000-0000-00000000a101','00000000-0000-0000-0000-00000000a131','guardian_or_safety');
create function oa151_synthetic.account_admission(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select role='seeker' and admission_ready from public.profiles where id=p_user),false);
$$;
create function oa151_synthetic.journey_cap(p_user uuid) returns integer
language sql volatile security definer set search_path = '' as $$
  select coalesce((select case when membership='basic' then 1 else 3 end
    from oa151_synthetic.funded_receipts where user_id=p_user
      and trusted_fake_proof and valid_until>clock_timestamp()),0);
$$;
create function oa151_synthetic.existing_occupancy(p_user uuid) returns integer
language sql stable security definer set search_path = '' as $$
  select count(*)::integer from public.matches
    where p_user in(seeker_a_id,seeker_b_id) and status='active'
      and pause_state in('none','pending_pause');
$$;
create function oa151_synthetic.pair_available(p_a uuid,p_b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select p_a<>p_b and exists(select 1 from public.profiles a join public.profiles b
    on b.id=p_b where a.id=p_a and a.role='seeker' and b.role='seeker'
      and a.gender<>b.gender)
    and not exists(select 1 from oa151_synthetic.pair_denials
      where user_a=least(p_a,p_b) and user_b=greatest(p_a,p_b));
$$;
revoke all on all functions in schema oa151_synthetic from public,anon,authenticated,service_role;
alter table public.profiles enable row level security;
create policy oa151_profiles_own on public.profiles for select to authenticated using(id=(select auth.uid()));
alter table public.matches enable row level security;
create policy oa151_matches_existing on public.matches for select to authenticated
  using((select auth.uid()) in(seeker_a_id,seeker_b_id));
alter table public.journey_attempts enable row level security;
create policy oa151_attempts_existing on public.journey_attempts for select to authenticated
  using(exists(select 1 from public.matches m where m.id=match_id));
alter table public.wali_links enable row level security;
create policy oa151_links_existing on public.wali_links for select to authenticated
  using((select auth.uid()) in(seeker_id,wali_id));
alter table public.conversations enable row level security;
alter table public.timelines enable row level security;
grant select on public.profiles,public.matches,public.journey_attempts,public.wali_links,
  public.conversations,public.timelines to authenticated;
revoke insert,update,delete on public.profiles,public.matches,public.journey_attempts,
  public.wali_links,public.conversations,public.timelines from public,anon,authenticated;
create function oa151_synthetic.canonical_fingerprint() returns text
language sql stable security definer set search_path = '' as $$
  select md5(jsonb_build_object(
    'profiles',(select jsonb_agg(to_jsonb(x) order by id) from public.profiles x),
    'matches',(select jsonb_agg(to_jsonb(x) order by id) from public.matches x),
    'attempts',(select jsonb_agg(to_jsonb(x) order by id) from public.journey_attempts x),
    'guardians',(select jsonb_agg(to_jsonb(x) order by seeker_id,wali_id) from public.wali_links x),
    'conversations',(select jsonb_agg(to_jsonb(x) order by id) from public.conversations x),
    'timelines',(select jsonb_agg(to_jsonb(x) order by id) from public.timelines x))::text);
$$;
revoke all on function oa151_synthetic.canonical_fingerprint() from public,anon,authenticated,service_role;
create table oa151_synthetic.baseline(
  fingerprint text not null, public_functions_fingerprint text not null
);
insert into oa151_synthetic.baseline select
  oa151_synthetic.canonical_fingerprint(),
  md5(coalesce((select jsonb_agg(jsonb_build_object(
    'signature',p.oid::regprocedure::text,'definition',pg_get_functiondef(p.oid),
    'acl',p.proacl::text,'owner',p.proowner,'config',p.proconfig)
    order by p.oid)::text from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind='f'),'[]'));
create function oa151_synthetic.assert_true(p_ok boolean,p_label text) returns void
language plpgsql set search_path = '' as $$ begin
  if p_ok is distinct from true then raise exception 'OA151 ASSERTION: %',p_label; end if;
end; $$;
create function oa151_synthetic.expect_error(p_sql text,p_fragment text) returns void
language plpgsql set search_path = '' as $$
declare seen boolean:=false;
begin
  begin execute p_sql; exception when others then
    if position(p_fragment in sqlerrm)=0 then raise exception 'OA151 wrong denial: %',sqlerrm; end if;
    seen:=true;
  end;
  if not seen then raise exception 'OA151 expected denial absent: %',p_fragment; end if;
end; $$;
-- Test helpers are invoker-only: they cannot grant member access to adapters/data.
grant usage on schema oa151_synthetic to authenticated;
revoke all on function oa151_synthetic.assert_true(boolean,text),
  oa151_synthetic.expect_error(text,text) from public,anon,service_role;
grant execute on function oa151_synthetic.assert_true(boolean,text),
  oa151_synthetic.expect_error(text,text) to authenticated;
comment on schema oa151_synthetic is 'RECONSTRUCTED OA151 FAKE-ONLY TEST DEPENDENCIES. NOT PRODUCTION PARITY.';
commit;
