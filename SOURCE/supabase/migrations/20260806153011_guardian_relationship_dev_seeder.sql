-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806153011, applied name
-- 'guardian_relationship_dev_seeder') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Guardian Relationship, step 3: dev fixtures write relationship codes.
--
-- Without this, every link the dev panel creates has a null relationship and
-- the feature looks broken in exactly the environment it is tested in — the
-- mirror image of the bug this whole change exists to fix, where the Dart
-- fakes were the ONLY place a relationship ever appeared.
--
-- Distinct values per guardian so the display is genuinely exercised rather
-- than three identical rows. CREATE OR REPLACE: signature unchanged, so the
-- existing grants are untouched.

create or replace function public.zyra_dev_set_guardians_on_decided(p_count integer)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_me uuid := auth.uid();
  v_pool uuid[];
  v_target uuid;
  v_targets uuid[];
  v_i int;
  v_links int := 0;
  -- Codes, never labels. 'uncle' renders as "Paternal Uncle".
  v_rel text[] := array['father','brother','uncle'];
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
      insert into public.wali_links (seeker_id, wali_id, status, is_main, relationship)
      values (v_target, v_pool[v_i], 'active', v_i = 1, v_rel[v_i])
      on conflict (seeker_id, wali_id) do update
        set status = 'active',
            is_main = excluded.is_main,
            relationship = excluded.relationship;
      v_links := v_links + 1;
    end loop;
  end loop;

  return jsonb_build_object('targets', array_length(v_targets,1), 'links', v_links);
end;
$function$;
