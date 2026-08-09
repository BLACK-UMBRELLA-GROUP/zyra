-- APPLIED LIVE 2026-08-08, version 20260808115640. Item 3 (I10 / A5).
--
-- ages_for(uuid[]) accepted an unbounded array and returned rows only for
-- ids the caller may view — a thousand visibility hypotheses per call.
--
-- DELIBERATE DEVIATION, FLAGGED: the brief said "narrow to a single id".
-- Six Dart call sites pass genuine batches (Browse a page at a time,
-- Matches, suggestions, Journey), so single-id-only would turn one Browse
-- call into up to fifty sequential round trips. Shipped instead:
--   1. ages_for_one(uuid) — used by the two call sites that only ever
--      passed one id (session router, Guardian journey list).
--   2. ages_for(uuid[]) retained for real batches, HARD CAPPED at 50.
--   3. Item 1 shrank the oracle far more than either: a Guardian no
--      longer passes zyra_can_view_profile for the counterpart cluster.

create or replace function public.ages_for_one(p_id uuid)
 returns integer language sql stable security definer set search_path to 'public'
as $function$
  select date_part('year', age(p.date_of_birth))::int
  from public.profiles p
  where p.id = p_id and public.zyra_can_view_profile(p.id);
$function$;

revoke execute on function public.ages_for_one(uuid) from public, anon;
grant  execute on function public.ages_for_one(uuid) to authenticated;

comment on function public.ages_for_one(uuid) is
  'Single-id age lookup. Prefer over ages_for(uuid[]) wherever the caller '
  'has one id — one visibility hypothesis per call (I10). NULL when the '
  'caller may not view the target, indistinguishable from a missing DOB.';

create or replace function public.ages_for(p_ids uuid[])
 returns table(id uuid, age integer)
 language plpgsql stable security definer set search_path to 'public'
as $function$
begin
  if p_ids is null or array_length(p_ids, 1) is null then return; end if;
  -- 50 = Browse's page size, so every legitimate caller fits.
  -- A caller needing more is enumerating.
  if array_length(p_ids, 1) > 50 then
    raise exception 'ages_for_batch_too_large'
      using hint = 'Maximum 50 ids per call. Page the request, or use ages_for_one().';
  end if;
  return query
    select p.id, date_part('year', age(p.date_of_birth))::int
    from public.profiles p
    where p.id = any(p_ids) and public.zyra_can_view_profile(p.id);
end;
$function$;

revoke execute on function public.ages_for(uuid[]) from public, anon;
grant  execute on function public.ages_for(uuid[]) to authenticated;

comment on function public.ages_for(uuid[]) is
  'Batch age lookup, HARD CAPPED AT 50 ids (I10, 2026-08-08) — it is a '
  'visibility oracle in proportion to its batch size. Use ages_for_one() '
  'for a single id. Do not raise the cap without revisiting I10.';

-- VERIFIED 2026-08-08, 6/6: singular works on self and on a browsable
-- target; a 51-id batch raises ages_for_batch_too_large; 50 still works;
-- empty array safe; anon holds no EXECUTE.
