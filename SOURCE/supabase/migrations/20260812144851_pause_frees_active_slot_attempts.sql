-- PAUSE FREES THE ACTIVE SLOT — the attempts mirror ......................
-- Completes pause_frees_active_slot, which updated every enforcement
-- point on `matches` and missed the parallel one on `journey_attempts`:
-- zyra_enforce_one_active_attempt() still counted a.status='active'
-- alone, and a paused Journey's attempt keeps status='active' with only
-- paused_by set — so pause-then-begin was still refused, one table
-- deeper. Found the right way: suite check 68 went red on first run.
--
--   1  zyra_enforce_one_active_attempt() — a paused attempt is not in
--      the Active pool; ignore it in the clash, and skip the check
--      entirely for a row that is itself paused.
--   2  journey_attempts_one_active_per_person — also fire on paused_by,
--      so a RESUME (which clears paused_by and never touches status)
--      re-enters the race-proof advisory-lock check, matching
--      matches_one_active_per_person exactly.
-- journey_attempts_one_active_per_match is deliberately untouched: one
-- active attempt PER MATCH is true whether or not that attempt is paused.

CREATE OR REPLACE FUNCTION public.zyra_enforce_one_active_attempt()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_a uuid;
  v_b uuid;
  v_clash uuid;
begin
  -- A paused attempt (paused_by set) is not in the Active pool — being
  -- paused, or being updated while paused, needs no clash check.
  if new.status <> 'active' or new.paused_by is not null then
    return null;
  end if;

  select m.seeker_a_id, m.seeker_b_id into v_a, v_b
  from public.matches m where m.id = new.match_id;

  -- Serialise on the participants, in a stable order so two transactions
  -- touching the same pair can never deadlock against each other.
  perform pg_advisory_xact_lock(hashtextextended(least(v_a,v_b)::text, 0));
  perform pg_advisory_xact_lock(hashtextextended(greatest(v_a,v_b)::text, 0));

  select a.id into v_clash
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  where a.status = 'active'
    and a.paused_by is null
    and a.id <> new.id
    and (m.seeker_a_id in (v_a, v_b) or m.seeker_b_id in (v_a, v_b))
  limit 1;

  if v_clash is not null then
    raise exception 'one_active_journey_limit'
      using hint = 'One of you already has an Active Journey. End or pause it first.';
  end if;

  return null;
end $function$;

drop trigger if exists journey_attempts_one_active_per_person on public.journey_attempts;
create constraint trigger journey_attempts_one_active_per_person
  after insert or update of status, paused_by on public.journey_attempts
  not deferrable initially immediate
  for each row execute function zyra_enforce_one_active_attempt();
