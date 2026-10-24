-- OA-ZYRA-305 / F04 PREPARATION-ONLY private legacy calculator + Browse IDs.
-- This is deliberately not deployable alone: existing Flutter Browse and
-- Unlock still call the numeric score_candidates RPC. This file refuses every
-- non-local database. A separately reviewed coordinated cutover artifact is
-- required after caller wiring, immutable result, privacy/retention and exact
-- Founder production GO. This is not full D1-D6/Stage2 implementation or F04
-- closure, and does not certify the remaining ordered-ID transcript as safe.
--
-- No refreshed Standard endpoint, tier rule, purchase/debit, snapshot storage,
-- score-history, category, raw-answer or Guardian-information API is added.
-- Existing Journey definer RPCs continue to call the owner-only public scorer;
-- their mutual/current-attempt/Plus gates and saved-score columns are unchanged.
-- They remain the old per-attempt implementation, NOT DR250's shared immutable
-- viewer/target result. Future saved-result integration remains a dependency.
--
-- Exact captured scorer pg_get_functiondef MD5 8864cc8b0a4422c863951bca17a1b180;
-- source SHA256 f79ae078f70339c242b399d032a617567262d0969f70aa9451ea2525b2fb1ea8,
-- from Oct3 audit artifact SHA256
-- a3f02c512d31bdc1a3ae7b8e860c4f188e1b5d903bae98a6671a5ead3db9c4fb.
-- MD5 is a drift sentinel only. Canonical eligible IDs match Stage1 metadata
-- and retained 104-question bank; this is a whitelist, NOT strict validation,
-- semantic-provenance repair or corrected counterpart applicability.
-- Rollback before commit is atomic. Do not routinely reopen the numeric
-- client oracle; retained local fixtures demonstrate the old/new boundary.

begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';

do $f04$
declare
  v_definition text;
  v_source text;
  v_proc record;
  v_service boolean;
  v_whitelist text := $filter$
  -- Only canonical scored preference topics may read a counterpart answer.
  -- Unknown/Bio/information-only controls cannot become probes or exclusions.
  SELECT COALESCE(jsonb_object_agg(e.key, e.value), '{}'::jsonb)
    INTO v_my_prefs FROM jsonb_each(v_my_prefs) e
    WHERE e.key = ANY (ARRAY[
      'ch3_q1','ch3_q2','ch3_q3','ch3_q4','ch3_q5','ch3_q6','ch3_q7','ch3_q8','ch3_q9',
      'ch3_q11','ch3_q12','ch3_q13','ch3_q14','ch3_q15','ch3_q16','ch3_q18','ch3_q20',
      'ch3_q22','ch3_q23','ch3_q24','ch3_q25','ch3_q26','ch3_q28','ch3_q29','ch3_q30','ch3_q31',
      'ch3_q33','ch3_q34','ch3_q35','ch3_q36','ch3_q37','ch3_q38','ch3_q39','ch3_q40',
      'ch3_q43','ch3_q44','ch3_q46','ch3_q47','ch3_q48','ch3_q49','ch3_q50','ch3_q51',
      'ch3_q52','ch3_q53','ch3_q54','ch3_q55','ch3_q56','ch3_q57','ch3_q60','ch3_q61','ch3_q63',
      'ch3_q64','ch3_q65','ch3_q66','ch3_q67','ch3_q68','ch3_q70','ch3_q71','ch3_q72','ch3_q73',
      'ch3_q74','ch3_q75','ch3_q78','ch3_q81','ch3_q84','ch3_q85','ch3_q86','ch3_q87','ch3_q90',
      'ch3_q95','ch3_q97'
    ]::text[]);
  SELECT COALESCE(jsonb_object_agg(e.key, e.value), '{}'::jsonb)
    INTO v_my_hard FROM jsonb_each(v_my_hard) e
    WHERE e.key = ANY (ARRAY[
      'ch3_q1','ch3_q2','ch3_q3','ch3_q4','ch3_q5','ch3_q6','ch3_q7','ch3_q8','ch3_q9',
      'ch3_q11','ch3_q12','ch3_q13','ch3_q14','ch3_q15','ch3_q16','ch3_q18','ch3_q20',
      'ch3_q22','ch3_q23','ch3_q24','ch3_q25','ch3_q26','ch3_q28','ch3_q29','ch3_q30','ch3_q31',
      'ch3_q33','ch3_q34','ch3_q35','ch3_q36','ch3_q37','ch3_q38','ch3_q39','ch3_q40',
      'ch3_q43','ch3_q44','ch3_q46','ch3_q47','ch3_q48','ch3_q49','ch3_q50','ch3_q51',
      'ch3_q52','ch3_q53','ch3_q54','ch3_q55','ch3_q56','ch3_q57','ch3_q60','ch3_q61','ch3_q63',
      'ch3_q64','ch3_q65','ch3_q66','ch3_q67','ch3_q68','ch3_q70','ch3_q71','ch3_q72','ch3_q73',
      'ch3_q74','ch3_q75','ch3_q78','ch3_q81','ch3_q84','ch3_q85','ch3_q86','ch3_q87','ch3_q90',
      'ch3_q95','ch3_q97'
    ]::text[]);
$filter$;
begin
  if pg_catalog.current_database() !~ '^zyra_oa305_f04_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa305_f04_local_replay', true)
       is distinct from 'prepared_local_replay' then
    raise exception 'F04 preparation only: coordinated client/saved-result/privacy cutover not authorised';
  end if;
  if pg_catalog.to_regnamespace('zyra_f04_private') is not null
     or pg_catalog.to_regprocedure('public.zyra_browse_ranked_ids(uuid[])') is not null
     or pg_catalog.to_regprocedure('public.score_candidates(uuid[])') is null
     or pg_catalog.to_regprocedure('public.zyra_can_view_profile(uuid)') is null
     or pg_catalog.to_regprocedure('public.zyra_block_exists(uuid)') is null then
    raise exception 'F04 precondition: objects missing or candidate already present';
  end if;
  select p.* into strict v_proc from pg_catalog.pg_proc p
    where p.oid = 'public.score_candidates(uuid[])'::regprocedure;
  v_definition := pg_catalog.pg_get_functiondef(v_proc.oid);
  if pg_catalog.md5(v_definition) <> '8864cc8b0a4422c863951bca17a1b180'
     or pg_catalog.pg_get_userbyid(v_proc.proowner) <> 'postgres'
     or not v_proc.prosecdef or v_proc.provolatile <> 's'
     or v_proc.proconfig is distinct from array['search_path=public']
     or pg_catalog.has_function_privilege('anon', v_proc.oid, 'execute')
     or not pg_catalog.has_function_privilege('authenticated', v_proc.oid, 'execute') then
    raise exception 'F04 precondition: captured scorer body/posture drifted';
  end if;
  if exists (select 1 from pg_catalog.aclexplode(coalesce(v_proc.proacl,
      pg_catalog.acldefault('f', v_proc.proowner))) a
      where a.privilege_type = 'EXECUTE' and a.grantee not in (
        0, (select oid from pg_catalog.pg_roles where rolname = 'anon'),
        (select oid from pg_catalog.pg_roles where rolname = 'authenticated'),
        (select oid from pg_catalog.pg_roles where rolname = 'service_role'),
        v_proc.proowner)) then
    raise exception 'F04 precondition: unexpected scorer grantee';
  end if;
  v_service := pg_catalog.has_function_privilege('service_role', v_proc.oid, 'execute');
  -- The clone does not write rows or change stored inputs, hards, snapshots,
  -- credits, Journey flags or any existing relationship/visibility function.
  create schema zyra_f04_private authorization postgres;
  revoke all on schema zyra_f04_private from public, anon, authenticated, service_role;
  v_source := replace(v_definition, 'public.score_candidates(',
    'zyra_f04_private.score_candidates_legacy(');
  v_source := replace(v_source, 'SET search_path TO ''public''', 'SET search_path TO ''''');
  v_source := replace(v_source, 'FROM onboarding_answers', 'FROM public.onboarding_answers');
  v_source := replace(v_source, 'FROM seeker_details', 'FROM public.seeker_details');
  v_source := replace(v_source, 'zyra_light_weight(', 'public.zyra_light_weight(');
  v_source := replace(v_source,
    '  IF v_my_prefs = ''{}''::jsonb AND v_my_ch2 = ''{}''::jsonb AND v_my_hard = ''{}''::jsonb THEN',
    v_whitelist || chr(10) ||
    '  IF v_my_prefs = ''{}''::jsonb AND v_my_ch2 = ''{}''::jsonb AND v_my_hard = ''{}''::jsonb THEN');
  if v_source = v_definition or position(v_whitelist in v_source) = 0
     or position('FROM onboarding_answers' in v_source) > 0
     or position('FROM seeker_details' in v_source) > 0 then
    raise exception 'F04 precondition: exact private-clone transformation incomplete';
  end if;
  execute v_source;
  revoke all on function zyra_f04_private.score_candidates_legacy(uuid[])
    from public, anon, authenticated, service_role;

  -- Stable old signature retained for postgres-owned Journey definer calls.
  -- No client receives a numeric result through this internal-only adapter.
  create or replace function public.score_candidates(p_candidate_ids uuid[])
  returns table(candidate_id uuid, score numeric)
  language sql stable security definer set search_path = '' as $adapter$
    select c.candidate_id, c.score
    from zyra_f04_private.score_candidates_legacy(p_candidate_ids) c;
  $adapter$;
  revoke execute on function public.score_candidates(uuid[]) from public, anon, authenticated;
  if pg_catalog.has_function_privilege('service_role', 'public.score_candidates(uuid[])', 'execute')
       is distinct from v_service then
    raise exception 'F04 postcondition: trusted server scorer rights changed';
  end if;
end;
$f04$;

-- Purpose projection only: output rows contain candidate_id, no numbers,
-- labels, counts, denominators, categories or missing-answer diagnostics.
-- Returned order is still observable; inference research/risk acceptance
-- remains open. No paid entitlement or immutable paid result is created.
create function public.zyra_browse_ranked_ids(p_candidate_ids uuid[])
returns table(candidate_id uuid)
language sql stable security definer set search_path = '' as $browse$
  with viewer as (
    select p.id, p.gender from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'seeker'
      and p.gender in ('male', 'female')
  ), input as (
    select x.id, min(x.ordinality) as input_order
    from pg_catalog.unnest(p_candidate_ids) with ordinality x(id, ordinality)
    group by x.id
  ), eligible as (
    select i.id, i.input_order
    from input i join public.profiles p on p.id = i.id cross join viewer v
    where p.role = 'seeker' and p.gender in ('male', 'female')
      and p.gender <> v.gender and p.id <> v.id
      and p.is_active and p.profile_complete
      and public.zyra_can_view_profile(p.id)
      and not public.zyra_block_exists(p.id)
  ), scores as (
    select s.candidate_id, s.score
    from zyra_f04_private.score_candidates_legacy(
      array(select e.id from eligible e order by e.input_order)) s
  )
  select e.id from eligible e join scores s on s.candidate_id = e.id
  order by s.score desc nulls last, e.input_order;
$browse$;
revoke all on function public.zyra_browse_ranked_ids(uuid[])
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_browse_ranked_ids(uuid[]) to authenticated;

do $postcheck$
begin
  if pg_catalog.has_function_privilege('authenticated', 'public.score_candidates(uuid[])', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.zyra_browse_ranked_ids(uuid[])', 'execute')
     or not pg_catalog.has_function_privilege('authenticated', 'public.zyra_browse_ranked_ids(uuid[])', 'execute')
     or pg_catalog.has_schema_privilege('authenticated', 'zyra_f04_private', 'usage')
     or pg_catalog.has_schema_privilege('anon', 'zyra_f04_private', 'usage')
     or pg_catalog.has_function_privilege('authenticated',
       'zyra_f04_private.score_candidates_legacy(uuid[])', 'execute')
     or pg_catalog.has_function_privilege('anon',
       'zyra_f04_private.score_candidates_legacy(uuid[])', 'execute')
     or pg_catalog.has_function_privilege('service_role',
       'zyra_f04_private.score_candidates_legacy(uuid[])', 'execute')
     or exists (select 1 from pg_catalog.pg_proc p where p.oid in (
         'zyra_f04_private.score_candidates_legacy(uuid[])'::regprocedure,
         'public.score_candidates(uuid[])'::regprocedure,
         'public.zyra_browse_ranked_ids(uuid[])'::regprocedure)
       and (not p.prosecdef or p.provolatile <> 's'
         or p.proconfig is distinct from array['search_path=""']
         or pg_catalog.pg_get_userbyid(p.proowner) <> 'postgres')) then
    raise exception 'F04 postcondition: purpose/private effective rights failed';
  end if;
end;
$postcheck$;
commit;
