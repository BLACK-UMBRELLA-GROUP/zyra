-- F06/F07 synthetic-only fixture: no linked project, real identity/ledger or files.
-- Fresh zyra_f06_f07_synthetic_<suffix>, with externally supplied
-- PGOPTIONS='-c zyra.synthetic_fixture=f06_f07_unlocks'.
-- Fixture -> candidate -> functional assertions -> independent workers -> race assertions.
\set ON_ERROR_STOP on
do $guard$
begin
  if current_database() not like 'zyra\_f06\_f07\_synthetic\_%' escape '\'
     or current_setting('zyra.synthetic_fixture', true) is distinct from 'f06_f07_unlocks'
     or current_user <> 'postgres' then
    raise exception 'F06/F07 fixture refused: synthetic database prefix/GUC/owner required';
  end if;
  if to_regclass('public.profiles') is not null
     or to_regclass('public.profile_unlocks') is not null
     or to_regclass('public.unlock_credits') is not null
     or to_regprocedure('auth.uid()') is not null then
    raise exception 'F06/F07 fixture refused: existing target catalog';
  end if;
end;
$guard$;
begin;
do $roles$
begin
  if not exists (select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls; end if;
  if not exists (select 1 from pg_roles where rolname='supabase_storage_admin') then create role supabase_storage_admin nologin bypassrls; end if;
  if exists (select 1 from pg_roles where rolname in ('anon','authenticated') and (rolsuper or rolbypassrls)) then
    raise exception 'F06/F07 fixture refuses privileged member roles';
  end if;
end;
$roles$;
create schema auth;
create schema private;
revoke all on schema private from public, anon, authenticated, service_role;
grant usage on schema public,auth to anon,authenticated,service_role;
create function auth.uid() returns uuid language sql stable as $function$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$function$;
create table auth.users(id uuid primary key, email text);
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null,
  gender text,
  is_active boolean not null,
  profile_complete boolean not null,
  onboarding_complete boolean not null
);
create table public.wali_links(seeker_id uuid,wali_id uuid,status text);
create table public.matches(id uuid primary key,seeker_a_id uuid,seeker_b_id uuid,end_reason text);
create table public.zyra_attempt_participant_rows(attempt_id uuid,match_id uuid,user_id uuid,role text);
create table public.profile_blocks(blocker_id uuid,blocked_id uuid);
create function public.zyra_block_exists(p_target uuid) returns boolean
language sql stable security definer set search_path = '' as $function$
  select exists(select 1 from public.profile_blocks b
    where (b.blocker_id=(select auth.uid()) and b.blocked_id=p_target)
       or (b.blocked_id=(select auth.uid()) and b.blocker_id=p_target));
$function$;
CREATE OR REPLACE FUNCTION public.zyra_can_view_profile(p_target uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    p_target = (select auth.uid())

    -- CLAUSE 2 — your own ward, or your own Guardian. UNCHANGED.
    -- This is the entire legitimate basis of Guardian visibility.
    or exists (
      select 1 from public.wali_links w
      where w.status = 'active'
        and (   (w.seeker_id = p_target and w.wali_id   = (select auth.uid()))
             or (w.wali_id   = p_target and w.seeker_id = (select auth.uid())) )
    )

    -- CLAUSE 3 — the two Seekers of a shared attempt. SEEKERS ONLY.
    --   2026-08-08 (item 1): Guardians removed entirely. Previously any
    --     participant could see any participant, which handed every
    --     Guardian a gender-blind view of the other family.
    --   The old status guard (Step 1) is gone with them — it existed to
    --     stop families meeting at 'potential', and Seeker<->Seeker was
    --     always exempt from it anyway, because clause 4 requires
    --     is_active and this clause is the only thing keeping a PAUSED
    --     counterpart visible in Potential Journeys.
    --   Block guards (Step 1b) retained verbatim, both halves.
    --   2026-08-11: NOT gated on onboarding completeness, on purpose —
    --     see the header. A live Journey outranks a tidy pool.
    or exists (
      select 1
      from public.zyra_attempt_participant_rows me
      join public.zyra_attempt_participant_rows them
        on them.attempt_id = me.attempt_id
      join public.matches mm on mm.id = me.match_id
      where me.user_id   = (select auth.uid())
        and them.user_id = p_target
        and me.role   = 'seeker'
        and them.role = 'seeker'
        -- (b) durable: a safety ending is terminal, block row or not
        and mm.end_reason is distinct from 'safety_concern'
        -- (a) live: a standing block, for pairs with nothing to end
        and not exists (
          select 1 from public.profile_blocks b
          where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
             or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
        )
    )

    -- CLAUSE 4 — browsing.
    --
    -- 2026-08-11, OA-ZYRA-193(c): both parties must have finished
    -- onboarding. Reads the materialised profiles.onboarding_complete
    -- rather than recomputing — this function is the USING clause of
    -- profiles_select and runs per row on every profile read in the app.
    or exists (
      select 1
      from public.profiles p
      cross join lateral (
        select pv.role, pv.gender, pv.onboarding_complete
          from public.profiles pv where pv.id = (select auth.uid())
      ) viewer
      where p.id = p_target
        and p.is_active = true
        and p.profile_complete = true
        and p.onboarding_complete = true          -- they finished
        and viewer.onboarding_complete = true     -- and so did you
        and not public.zyra_block_exists(p_target)
        and viewer.role = 'seeker'
        and viewer.gender is not null
        and p.gender is not null
        and p.gender <> viewer.gender
    );
$function$
;
revoke all on function public.zyra_can_view_profile(uuid) from public,anon;
grant execute on function public.zyra_can_view_profile(uuid) to authenticated,service_role;
alter table public.profiles enable row level security;
create policy profiles_select on public.profiles for select to authenticated
using(public.zyra_can_view_profile(id));
grant select on public.profiles to authenticated;
create table public.saves(saver_id uuid);
create table public.likes(liker_id uuid);
create table public.passes(passer_id uuid);
create table public.subscriptions(user_id uuid primary key, plan_type text,status text);

create table public.profile_unlocks (
  id uuid primary key default gen_random_uuid(),
  unlocker_id uuid not null references public.profiles(id) on delete cascade,
  unlocked_id uuid not null references public.profiles(id) on delete cascade,
  unlock_type text not null check(unlock_type in
    ('paid_single','paid_plus_single','paid_bundle','paid_plus_bundle','automatic_match')),
  created_at timestamptz not null default now(),
  check(unlocker_id<>unlocked_id)
);
create unique index profile_unlocks_once on public.profile_unlocks(unlocker_id,unlocked_id,unlock_type);
create index profile_unlocks_by_unlocker on public.profile_unlocks(unlocker_id);
create index profile_unlocks_unlocked_idx on public.profile_unlocks(unlocked_id);
create table public.unlock_credits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  tier text not null check(tier in ('paid_single','paid_plus_single')),
  delta integer not null check(delta<>0),
  reason text not null check(reason in
    ('zyra_one_included','purchase','debug_grant','spend','refund','adjustment')),
  related_unlock_id uuid references public.profile_unlocks(id) on delete set null,
  note text,
  created_at timestamptz not null default now(),
  constraint unlock_credits_sign_matches_reason check(
    (reason='spend' and delta<0) or (reason='refund' and delta>0)
    or (reason in ('zyra_one_included','purchase','debug_grant') and delta>0)
    or reason='adjustment')
);
create index unlock_credits_balance on public.unlock_credits(user_id,tier);
create unique index unlock_credits_one_zyra_one_grant on public.unlock_credits(user_id,tier)
where reason='zyra_one_included';
create index unlock_credits_related_unlock_idx on public.unlock_credits(related_unlock_id);
alter table public.profile_unlocks enable row level security;
alter table public.unlock_credits enable row level security;
create policy profile_unlocks_select on public.profile_unlocks for select
using(unlocker_id=(select auth.uid()));
create policy unlock_credits_select_own on public.unlock_credits for select
using(user_id=(select auth.uid()));
grant select on public.profile_unlocks,public.unlock_credits to authenticated;
grant all on public.profile_unlocks,public.unlock_credits to service_role;

-- Exact five Oct5 catalog definitions, not app-owned approximations.
CREATE OR REPLACE FUNCTION public.grant_zyra_one_credits()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  -- 'seeker_premium' IS ZYRA One. Not a typo.
  if new.plan_type = 'seeker_premium' and new.status = 'active' then
    insert into public.unlock_credits (user_id, tier, delta, reason, note)
    values (new.user_id, 'paid_plus_single', 3, 'zyra_one_included',
            'Included with ZYRA One')
    on conflict do nothing;
  end if;
  return new;
end $function$
;
CREATE OR REPLACE FUNCTION public.zyra_debug_grant_credits(p_tier text, p_count integer DEFAULT 5)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_me uuid := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = v_me AND u.email LIKE '%@zyra.test'
  ) THEN
    RAISE EXCEPTION 'debug_grant_disabled'
      USING HINT = 'Credit grants are limited to seeded test accounts. Real payment processing is not built yet.';
  END IF;

  IF p_tier NOT IN ('paid_single','paid_plus_single') THEN
    RAISE EXCEPTION 'unknown_tier';
  END IF;
  IF p_count < 1 OR p_count > 50 THEN
    RAISE EXCEPTION 'count_out_of_range';
  END IF;

  INSERT INTO public.unlock_credits (user_id, tier, delta, reason, note)
  VALUES (v_me, p_tier, p_count, 'debug_grant', 'dev panel');

  RETURN jsonb_build_object('status','granted','tier',p_tier,'added',p_count);
END;
$function$
;
CREATE OR REPLACE FUNCTION public.zyra_dev_reset_account()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_me uuid := auth.uid();
  v_saves int; v_likes int; v_passes int; v_unlocks int; v_credits int;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  -- Dev/preview accounts only. Same guard as the mock purchase functions.
  if not exists (
    select 1 from auth.users u
    where u.id = v_me and u.email like '%@zyra.test'
  ) then
    raise exception 'dev_accounts_only'
      using hint = 'zyra_dev_reset_account() is only callable by seeded @zyra.test accounts.';
  end if;

  delete from public.saves           where saver_id    = v_me;  get diagnostics v_saves   = row_count;
  delete from public.likes           where liker_id    = v_me;  get diagnostics v_likes   = row_count;
  delete from public.passes          where passer_id   = v_me;  get diagnostics v_passes  = row_count;
  delete from public.profile_unlocks where unlocker_id = v_me;  get diagnostics v_unlocks = row_count;
  delete from public.unlock_credits  where user_id     = v_me;  get diagnostics v_credits = row_count;

  return jsonb_build_object(
    'saves', v_saves, 'likes', v_likes, 'passes', v_passes,
    'unlocks', v_unlocks, 'credits', v_credits
  );
end;
$function$
;
CREATE OR REPLACE FUNCTION public.zyra_dev_set_plus_unlock(p_other_id uuid, p_has boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Plus simulation is limited to seeded @zyra.test accounts.';
  END IF;
  IF p_other_id = caller THEN RAISE EXCEPTION 'not_a_party'; END IF;

  IF p_has THEN
    INSERT INTO profile_unlocks (unlocker_id, unlocked_id, unlock_type)
    VALUES (caller, p_other_id, 'paid_plus_single')
    ON CONFLICT DO NOTHING;
  ELSE
    -- Removes ONLY the simulated Plus row, never a real purchase of another
    -- type. A dev tool that deleted a paid_single would be destroying a
    -- record of money.
    DELETE FROM profile_unlocks
     WHERE unlocker_id = caller AND unlocked_id = p_other_id
       AND unlock_type = 'paid_plus_single';
  END IF;
  RETURN p_has;
END;
$function$
;
CREATE OR REPLACE FUNCTION public.zyra_unlock_profile(p_target uuid, p_tier text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_me      uuid := auth.uid();
  v_balance int;
  v_unlock  uuid;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  IF p_tier NOT IN ('paid_single','paid_plus_single') THEN
    RAISE EXCEPTION 'unknown_tier' USING HINT = 'paid_single or paid_plus_single';
  END IF;

  IF p_target = v_me THEN
    RAISE EXCEPTION 'cannot_unlock_self';
  END IF;

  -- Same visibility rule as everything else. Without it, this function
  -- would confirm the existence of any UUID you cared to name.
  IF NOT public.zyra_can_view_profile(p_target) THEN
    RAISE EXCEPTION 'not_visible';
  END IF;

  -- PERMANENCE, Founder-ratified: "returning to the same profile must
  -- NEVER consume another unlock." Checked BEFORE the balance, so someone
  -- with zero credits still reaches what they already paid for — and a
  -- double tap on a slow connection cannot charge twice.
  IF EXISTS (
    SELECT 1 FROM public.profile_unlocks u
    WHERE u.unlocker_id = v_me AND u.unlocked_id = p_target AND u.unlock_type = p_tier
  ) THEN
    RETURN jsonb_build_object('status','already_unlocked','charged',false);
  END IF;

  SELECT coalesce(sum(delta),0)::int INTO v_balance
  FROM public.unlock_credits
  WHERE user_id = v_me AND tier = p_tier;

  IF v_balance < 1 THEN
    RETURN jsonb_build_object('status','insufficient_credits','charged',false,'balance',v_balance);
  END IF;

  -- One statement, one transaction. The unlock and the debit cannot
  -- diverge: if either fails, neither happened.
  INSERT INTO public.profile_unlocks (unlocker_id, unlocked_id, unlock_type)
  VALUES (v_me, p_target, p_tier)
  RETURNING id INTO v_unlock;

  INSERT INTO public.unlock_credits (user_id, tier, delta, reason, related_unlock_id)
  VALUES (v_me, p_tier, -1, 'spend', v_unlock);

  RETURN jsonb_build_object('status','unlocked','charged',true,'balance',v_balance - 1);
END;
$function$
;
revoke all on function public.zyra_unlock_profile(uuid,text),
 public.zyra_debug_grant_credits(text,integer),public.zyra_dev_set_plus_unlock(uuid,boolean),
 public.zyra_dev_reset_account(),public.grant_zyra_one_credits() from public,anon;
grant execute on function public.zyra_unlock_profile(uuid,text),
 public.zyra_debug_grant_credits(text,integer),public.zyra_dev_set_plus_unlock(uuid,boolean),
 public.zyra_dev_reset_account() to authenticated,service_role;
grant execute on function public.grant_zyra_one_credits() to service_role;
create trigger synthetic_subscription_grant after insert or update of plan_type,status
on public.subscriptions for each row execute function public.grant_zyra_one_credits();

insert into auth.users values
 ('00000000-0000-0000-0000-00000000f601','actor-a@synthetic.invalid'),
 ('00000000-0000-0000-0000-00000000f602','target-b@synthetic.invalid'),
 ('00000000-0000-0000-0000-00000000f603','target-c@synthetic.invalid'),
 ('00000000-0000-0000-0000-00000000f604','target-d@synthetic.invalid'),
 ('00000000-0000-0000-0000-00000000f605','target-e@synthetic.invalid'),
 ('00000000-0000-0000-0000-00000000f606','target-f@synthetic.invalid'),
 ('00000000-0000-0000-0000-00000000f607','guardian@synthetic.invalid'),
 ('00000000-0000-0000-0000-00000000f608','incomplete@synthetic.invalid'),
 ('00000000-0000-0000-0000-00000000f609','synthetic-different-race@zyra.test'),
 ('00000000-0000-0000-0000-00000000f60a','synthetic-same-race@zyra.test'),
 ('00000000-0000-0000-0000-00000000f60b','synthetic-rr-race@zyra.test'),
 ('00000000-0000-0000-0000-00000000f60c','synthetic-rollback@zyra.test'),
 ('00000000-0000-0000-0000-00000000f60d','synthetic-direct-debit@zyra.test'),
 ('00000000-0000-0000-0000-00000000f620','race-target-one@synthetic.invalid'),
 ('00000000-0000-0000-0000-00000000f621','race-target-two@synthetic.invalid'),
 ('00000000-0000-0000-0000-00000000f622','new-target@synthetic.invalid');
insert into public.profiles
select id,case when id='00000000-0000-0000-0000-00000000f607' then 'wali' else 'seeker' end,
 case when id in ('00000000-0000-0000-0000-00000000f601','00000000-0000-0000-0000-00000000f608',
   '00000000-0000-0000-0000-00000000f609','00000000-0000-0000-0000-00000000f60a',
   '00000000-0000-0000-0000-00000000f60b','00000000-0000-0000-0000-00000000f60c',
   '00000000-0000-0000-0000-00000000f60d') then 'male' else 'female' end,
 true,true,id<>'00000000-0000-0000-0000-00000000f608' from auth.users;
insert into public.wali_links values
 ('00000000-0000-0000-0000-00000000f601','00000000-0000-0000-0000-00000000f607','active');
insert into public.profile_unlocks(id,unlocker_id,unlocked_id,unlock_type) values
 ('00000000-0000-0000-0000-00000000f631','00000000-0000-0000-0000-00000000f601','00000000-0000-0000-0000-00000000f602','paid_plus_single'),
 ('00000000-0000-0000-0000-00000000f632','00000000-0000-0000-0000-00000000f601','00000000-0000-0000-0000-00000000f603','paid_plus_bundle'),
 ('00000000-0000-0000-0000-00000000f633','00000000-0000-0000-0000-00000000f601','00000000-0000-0000-0000-00000000f604','paid_bundle'),
 ('00000000-0000-0000-0000-00000000f634','00000000-0000-0000-0000-00000000f601','00000000-0000-0000-0000-00000000f605','automatic_match');
insert into public.unlock_credits(user_id,tier,delta,reason,note) values
 ('00000000-0000-0000-0000-00000000f601','paid_single',2,'purchase','synthetic opening balance'),
 ('00000000-0000-0000-0000-00000000f601','paid_plus_single',4,'purchase','synthetic opening balance'),
 ('00000000-0000-0000-0000-00000000f607','paid_single',1,'purchase','synthetic Guardian authority rejection'),
 ('00000000-0000-0000-0000-00000000f608','paid_single',1,'purchase','synthetic incomplete rejection'),
 ('00000000-0000-0000-0000-00000000f609','paid_single',1,'purchase','synthetic different-target race'),
 ('00000000-0000-0000-0000-00000000f60a','paid_single',1,'purchase','synthetic same-target race'),
 ('00000000-0000-0000-0000-00000000f60b','paid_single',1,'purchase','synthetic repeatable-read race'),
 ('00000000-0000-0000-0000-00000000f60c','paid_single',1,'purchase','synthetic rollback'),
 ('00000000-0000-0000-0000-00000000f60d','paid_single',1,'purchase','synthetic direct debit');
insert into public.unlock_credits(id,user_id,tier,delta,reason,related_unlock_id) values
 ('00000000-0000-0000-0000-00000000f641','00000000-0000-0000-0000-00000000f601',
  'paid_plus_single',-1,'spend','00000000-0000-0000-0000-00000000f631');
commit;

