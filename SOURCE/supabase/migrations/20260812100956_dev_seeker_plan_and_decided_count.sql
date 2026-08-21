-- Dev panel rebuild, 2026-08-12 (Founder-directed). Two additions:
--
-- 1. zyra_dev_set_seeker_plan(p_plan) — the panel's new Membership control.
--    Until now the mock purchase flow flipped only AppState.plan (client),
--    while every server-enforced entitlement — the pause caps 5/10 above
--    all — read subscriptions.plan_type, which nothing in the app ever
--    wrote. Testing "ZYRA One" against a server that still believed
--    seeker_basic. This closes that split for @zyra.test accounts: the
--    panel writes BOTH sides, and zyra_session_router reads this row back
--    on the next launch, so the simulated plan also survives restarts.
--
-- 2. zyra_dev_guardians_on_decided() — read-back for the panel's
--    "Guardians on people you decided on" segment. The Introductions
--    segment learned to ask the server on open (2026-08-09, after the
--    Founder hit a row the panel said was 0 and could not clear); this is
--    the same fix applied to the one remaining control that mirrored
--    server state from memory. A panel that claims to be the source of
--    truth has to ask.
--
-- Both carry the same guard as every dev function: @zyra.test only,
-- raised as dev_accounts_only. SECURITY DEFINER + pinned search_path per
-- the hardening sweep; explicit grants because default privileges now
-- revoke EXECUTE from PUBLIC (migration 20260811233813).

create or replace function public.zyra_dev_set_seeker_plan(p_plan text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not exists (
    select 1 from auth.users u
    where u.id = v_me and u.email like '%@zyra.test'
  ) then
    raise exception 'dev_accounts_only'
      using hint = 'zyra_dev_set_seeker_plan() is only callable by seeded @zyra.test accounts.';
  end if;
  if p_plan not in ('seeker_basic', 'seeker_premium') then
    raise exception 'unknown_plan'
      using hint = 'seeker_basic or seeker_premium.';
  end if;
  -- Seekers only: a wali account's plan is wali_basic/wali_premium and is
  -- driven by its own mock flow (mock_set_wali_plan).
  if not exists (
    select 1 from public.profiles p where p.id = v_me and p.role = 'seeker'
  ) then
    raise exception 'seekers_only';
  end if;

  -- One active seeker row per user (partial unique index on user_id WHERE
  -- status='active'). Update it in place; insert only when the seed left
  -- no row at all.
  update public.subscriptions
     set plan_type = p_plan, started_at = now()
   where user_id = v_me
     and status = 'active'
     and plan_type in ('seeker_basic', 'seeker_premium');
  if not found then
    insert into public.subscriptions (user_id, plan_type, status, started_at)
    values (v_me, p_plan, 'active', now());
  end if;

  return jsonb_build_object('plan', p_plan);
end;
$$;

revoke execute on function public.zyra_dev_set_seeker_plan(text) from public, anon;
grant execute on function public.zyra_dev_set_seeker_plan(text) to authenticated;

create or replace function public.zyra_dev_guardians_on_decided()
returns integer
language plpgsql
security definer
set search_path to 'public'
stable
as $$
declare
  v_me uuid := auth.uid();
  v_pool uuid[];
  v_count int;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not exists (
    select 1 from auth.users u
    where u.id = v_me and u.email like '%@zyra.test'
  ) then
    raise exception 'dev_accounts_only';
  end if;

  -- The same pool zyra_dev_set_guardians_on_decided() writes from.
  select array_agg(p.id order by u.email)
    into v_pool
  from public.profiles p
  join auth.users u on u.id = p.id
  where u.email in ('dev.guardian.a@zyra.test','dev.guardian.b@zyra.test','dev.guardian.c@zyra.test');

  if v_pool is null then return 0; end if;

  -- The setter applies the SAME count to every decided-on target, so the
  -- state reads back as the largest pool-link count any target holds —
  -- which is the applied count, or 0 when cleared / nothing decided yet.
  select coalesce(max(cnt), 0) into v_count from (
    select count(*) as cnt
    from public.wali_links wl
    where wl.wali_id = any(v_pool)
      and wl.status = 'active'
      and wl.seeker_id in (
        select saved_id  from public.saves  where saver_id  = v_me
        union select liked_id  from public.likes  where liker_id  = v_me
        union select passed_id from public.passes where passer_id = v_me
      )
    group by wl.seeker_id
  ) t;

  return v_count;
end;
$$;

revoke execute on function public.zyra_dev_guardians_on_decided() from public, anon;
grant execute on function public.zyra_dev_guardians_on_decided() to authenticated;