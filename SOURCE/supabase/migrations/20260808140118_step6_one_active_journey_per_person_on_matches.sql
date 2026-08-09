-- APPLIED LIVE 2026-08-08, version 20260808140118.
-- OA-ZYRA-156 stage 4e · STEP 6 — one Active Journey PER PERSON,
-- enforced structurally. Authorised by DR-ZYRA-122 decision 2.
--
-- THE DEFECT (audit R7, reproduced live 2026-08-06): the two partial
-- unique indexes are per-SIDE —
--   matches_seeker_a_active UNIQUE (seeker_a_id) WHERE status='active'
--   matches_seeker_b_active UNIQUE (seeker_b_id) WHERE status='active'
-- so one person may be seeker_a on one active Journey and seeker_b on
-- another. Order three ids a < b < c and it falls out immediately. The
-- product spec calls this "the invariant of the ZYRA platform" and
-- requires it at the database layer "regardless of how the request
-- originates".
--
-- WHY ON `matches`: the equivalent trigger on journey_attempts exists and
-- cannot fire on the real path — promote never sets an attempt's status
-- (see 20260808140054). `matches` is what promote writes, so it is where
-- enforcement bites today. DR-ZYRA-122 approved this "on whichever table
-- is authoritative".
--
-- WHY A CONSTRAINT TRIGGER, NOT AN INDEX: no unique index can express
-- "this person appears in EITHER of two columns" — which is exactly why
-- the original two-index attempt could never work.
--
-- Advisory-lock pattern taken verbatim from
-- zyra_enforce_one_active_attempt(): lock both participants in a stable
-- (least, greatest) order so concurrent transactions on the same pair
-- serialise rather than deadlock. This also closes audit R7's second
-- half — the IF EXISTS in promote is a TOCTOU race, since SELECT INTO
-- takes no row lock.

create or replace function public.zyra_enforce_one_active_match()
 returns trigger language plpgsql security definer set search_path to 'public'
as $function$
declare v_clash uuid;
begin
  if new.status <> 'active' then return null; end if;
  perform pg_advisory_xact_lock(hashtextextended(least(new.seeker_a_id, new.seeker_b_id)::text, 0));
  perform pg_advisory_xact_lock(hashtextextended(greatest(new.seeker_a_id, new.seeker_b_id)::text, 0));
  select m.id into v_clash from public.matches m
   where m.status = 'active' and m.id <> new.id
     and (   m.seeker_a_id in (new.seeker_a_id, new.seeker_b_id)
          or m.seeker_b_id in (new.seeker_a_id, new.seeker_b_id) )
   limit 1;
  if v_clash is not null then
    raise exception 'one_active_journey_limit'
      using hint = 'One of you already has an Active Journey. End or pause it first.';
  end if;
  return null;
end $function$;

drop trigger if exists matches_one_active_per_person on public.matches;
create constraint trigger matches_one_active_per_person
  after insert or update of status on public.matches
  for each row execute function public.zyra_enforce_one_active_match();

comment on function public.zyra_enforce_one_active_match() is
  'One Active Journey per PERSON — the platform invariant. The two '
  'per-side partial indexes cannot express it; this can. Kept alongside '
  'them, not instead of. Moves to journey_attempts at step 7, once an '
  'attempt''s status is actually maintained.';

-- VERIFIED 2026-08-08, 5/5: first Active Journey allowed; a SECOND for
-- the same person refused with one_active_journey_limit whether inserted
-- directly or promoted from 'potential'; a potential second pair is fine;
-- an unrelated pair is unaffected.
