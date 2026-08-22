-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804235945, applied name
-- 'dev_guardian_scenarios') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Developer Mode Guardian scenarios (Founder request, 2026-08-05):
-- "take a toggle to give users I liked, saved or declined 1 2 3 guardians,
-- then make a toggle to add 1 2 3 guardian suggestions".
--
-- Both are @zyra.test-only, same guard as every other dev function.
-- Guardians come from a fixed pool of three seeded dev Guardian accounts
-- (Abdul, Hassan, Tariq — dev.guardian.a/b/c@zyra.test), so the same
-- setting always produces the same people and screenshots stay comparable.

-- 1. Give every profile the caller has Considered / Saved / Passed exactly
--    N Guardians. This is what makes the Compatibility Unlock+ Guardian
--    section testable at 0, 1, 2 and 3 — including the "No Guardian
--    linked." state at 0, which is a real state and not an empty one.
create or replace function public.zyra_dev_set_guardians_on_decided(p_count int)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_me uuid := auth.uid();
  v_pool uuid[];
  v_target uuid;
  v_targets uuid[];
  v_i int;
  v_links int := 0;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not exists (select 1 from auth.users u where u.id = v_me and u.email like '%@zyra.test') then
    raise exception 'dev_accounts_only';
  end if;
  if p_count < 0 or p_count > 3 then raise exception 'count_out_of_range'; end if;

  select array_agg(p.id order by u.email)
    into v_pool
  from public.profiles p
  join auth.users u on u.id = p.id
  where u.email in ('dev.guardian.a@zyra.test','dev.guardian.b@zyra.test','dev.guardian.c@zyra.test');

  if v_pool is null then raise exception 'guardian_pool_missing'; end if;

  -- Everyone this account has decided on, in any direction.
  select array_agg(distinct t) into v_targets from (
    select saved_id  as t from public.saves  where saver_id  = v_me
    union select liked_id     from public.likes  where liker_id  = v_me
    union select passed_id    from public.passes where passer_id = v_me
  ) s;

  if v_targets is null then
    return jsonb_build_object('targets', 0, 'links', 0);
  end if;

  foreach v_target in array v_targets loop
    -- Clear only the pool's links, never a real one made through an invite.
    delete from public.wali_links
      where seeker_id = v_target and wali_id = any(v_pool);

    for v_i in 1..p_count loop
      insert into public.wali_links (seeker_id, wali_id, status, is_main)
      values (v_target, v_pool[v_i], 'active', v_i = 1)
      on conflict (seeker_id, wali_id) do update
        set status = 'active', is_main = excluded.is_main;
      v_links := v_links + 1;
    end loop;
  end loop;

  return jsonb_build_object('targets', array_length(v_targets,1), 'links', v_links);
end;
$$;

-- 2. Guardian Suggestions — N profiles put forward to the caller by their
--    Guardian. Fills the Connections section renamed from "Family
--    Introductions" on 2026-08-05, which had no way to be populated because
--    the Guardian-side UI to create a suggestion does not exist yet.
create or replace function public.zyra_dev_set_guardian_suggestions(p_count int)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_me uuid := auth.uid();
  v_my_gender text;
  v_wali uuid;
  v_ids uuid[];
  v_i int;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not exists (select 1 from auth.users u where u.id = v_me and u.email like '%@zyra.test') then
    raise exception 'dev_accounts_only';
  end if;
  if p_count < 0 or p_count > 3 then raise exception 'count_out_of_range'; end if;

  select gender into v_my_gender from public.profiles where id = v_me;

  -- Prefer a Guardian genuinely linked to this Seeker; otherwise borrow one
  -- from the dev pool so the section can still be populated.
  select wali_id into v_wali from public.wali_links
    where seeker_id = v_me and status = 'active'
    order by is_main desc nulls last limit 1;

  if v_wali is null then
    select p.id into v_wali from public.profiles p join auth.users u on u.id = p.id
      where u.email = 'dev.guardian.a@zyra.test';
  end if;
  if v_wali is null then raise exception 'no_guardian_available'; end if;

  delete from public.wali_suggestions where seeker_id = v_me;

  -- Opposite-gender, browsable Seekers only — a suggestion that breaks the
  -- segregation rule would be a worse bug than an empty list.
  select array_agg(id) into v_ids from (
    select p.id from public.profiles p
    where p.role = 'seeker' and p.is_active and p.profile_complete
      and p.id <> v_me
      and (v_my_gender is null or p.gender <> v_my_gender)
    order by p.created_at
    limit p_count
  ) x;

  if v_ids is null then return jsonb_build_object('created', 0); end if;

  for v_i in 1..array_length(v_ids,1) loop
    insert into public.wali_suggestions (wali_id, seeker_id, suggested_id, status)
    values (v_wali, v_me, v_ids[v_i], 'pending')
    on conflict (wali_id, seeker_id, suggested_id) do nothing;
  end loop;

  return jsonb_build_object('created', array_length(v_ids,1));
end;
$$;

revoke execute on function public.zyra_dev_set_guardians_on_decided(int) from public, anon;
revoke execute on function public.zyra_dev_set_guardian_suggestions(int) from public, anon;
grant execute on function public.zyra_dev_set_guardians_on_decided(int) to authenticated;
grant execute on function public.zyra_dev_set_guardian_suggestions(int) to authenticated;

-- The Seeker already has SELECT on their own wali_suggestions rows
-- (wali_suggestions_select, initial schema). No new read policy needed —
-- the suggested profiles themselves are read through the existing
-- profiles_select, exactly as Browse does.
create index if not exists wali_suggestions_seeker on public.wali_suggestions(seeker_id, status);
