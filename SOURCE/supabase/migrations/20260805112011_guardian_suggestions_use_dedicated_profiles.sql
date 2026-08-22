-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260805112011, applied name
-- 'guardian_suggestions_use_dedicated_profiles') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Guardian Suggestions now draw from dedicated, photographed profiles
-- (Founder, 2026-08-05: "guardian suggestions shows white paper… just add
-- a new name and take one of the saved photos we already have on file
-- (max 5)… max 3 guardian suggestion profiles").
--
-- The first version suggested whichever opposite-gender Seeker sorted
-- first by created_at. Those were the original seeded accounts, none of
-- which have photos — so the card rendered as a full-height grey
-- placeholder. Six profiles now exist for this purpose alone
-- (dev.sugg.f1..f3 / m1..m3 — Safiyyah, Ruqayyah, Zaynab, Ilyas, Musa,
-- Idris), each with 5 photos reused from the bucket, three per gender so
-- the feature works whichever gender is signed in. Only three are ever
-- suggested at once, which is the cap requested.
--
-- Falls back to any browsable opposite-gender Seeker WITH photos if the
-- dedicated set is missing, and only then to one without — a suggestion
-- with no picture is still better than an empty section, but it is now
-- the last resort rather than the default.
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

  select wali_id into v_wali from public.wali_links
    where seeker_id = v_me and status = 'active'
    order by is_main desc nulls last limit 1;
  if v_wali is null then
    select p.id into v_wali from public.profiles p join auth.users u on u.id = p.id
      where u.email = 'dev.guardian.a@zyra.test';
  end if;
  if v_wali is null then raise exception 'no_guardian_available'; end if;

  delete from public.wali_suggestions where seeker_id = v_me;
  if p_count = 0 then return jsonb_build_object('created', 0); end if;

  select array_agg(id) into v_ids from (
    select p.id
    from public.profiles p
    left join auth.users u on u.id = p.id
    where p.role = 'seeker' and p.is_active and p.profile_complete
      and p.id <> v_me
      and (v_my_gender is null or p.gender <> v_my_gender)
    order by
      -- dedicated suggestion profiles first, then anyone with photos,
      -- then the rest.
      (u.email like 'dev.sugg.%') desc,
      (exists (select 1 from public.profile_photos ph where ph.user_id = p.id)) desc,
      p.created_at
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

revoke execute on function public.zyra_dev_set_guardian_suggestions(int) from public, anon;
grant execute on function public.zyra_dev_set_guardian_suggestions(int) to authenticated;
