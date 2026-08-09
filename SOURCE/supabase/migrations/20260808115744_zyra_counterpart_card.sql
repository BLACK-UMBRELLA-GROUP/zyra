-- APPLIED LIVE 2026-08-08, version 20260808115744. Item 4.
-- Rationale: GUARDIAN & ROMANTIC RULES section 7d.
--
-- Item 1 took full-profile visibility away from Guardians. This gives
-- back the minimum a MAIN Guardian needs: who the other family is.
-- Uniform for everyone (no per-user field choice — a sparse card is
-- itself a signal, the Step 0 lesson), Main Guardians only, symmetric.
--
-- FIELDS as authorised: counterpart Seeker first name + age; counterpart
-- MAIN Guardian name. NO city. NO photo.
--
-- "CONTACT" IS NOT INCLUDED — FLAGGED, NOT IMPROVISED. The brief said
-- "name + contact". No contact field exists: profiles carries no phone or
-- email, and the only identifier available is auth.users.email. Exposing
-- that would be a NEW disclosure — a personal email was never reachable
-- through clause 3 even at its most permissive — which is the one thing
-- the operating rule says to stop for. Needs a Founder decision on what
-- the contact channel should be.
--
-- MAIN GUARDIANS ONLY, NOT SEEKERS: a Seeker already sees the counterpart
-- via clause 3, and the counterpart's Guardian roster is the PAID Unlock+
-- product. Giving Seekers this card free would undercut it — a widening.

create or replace function public.zyra_counterpart_card(p_match_id uuid)
 returns table (
   counterpart_first_name text,
   counterpart_age        integer,
   guardian_first_name    text,
   guardian_surname_line  text,
   guardian_contact       text   -- always NULL today; see header
 )
 language sql stable security definer set search_path to 'public'
as $function$
  with m as (
    select mm.* from public.matches mm
    where mm.id = p_match_id
      and mm.status <> 'potential'                          -- families do not meet pre-Journey
      and mm.end_reason is distinct from 'safety_concern'   -- terminal, block row or not (I2)
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
           or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
      )
  ),
  mine as (
    select w.seeker_id as my_ward
    from m join public.wali_links w
      on w.wali_id = (select auth.uid())
     and w.status = 'active' and w.is_main is true
     and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
  ),
  other as (
    select case when mine.my_ward = m.seeker_a_id then m.seeker_b_id
                else m.seeker_a_id end as other_seeker
    from m, mine
  )
  select p.first_name,
         date_part('year', age(p.date_of_birth))::int,
         g.first_name, g.surname_line,
         null::text
  from other
  join public.profiles p on p.id = other.other_seeker
  -- LEFT JOIN: the other family may have no Main Guardian. The card still
  -- renders with that half empty — the honest state, and useful to see.
  left join public.wali_links ow
         on ow.seeker_id = other.other_seeker
        and ow.status = 'active' and ow.is_main is true
  left join public.profiles g on g.id = ow.wali_id;
$function$;

revoke execute on function public.zyra_counterpart_card(uuid) from public, anon;
grant  execute on function public.zyra_counterpart_card(uuid) to authenticated;

comment on function public.zyra_counterpart_card(uuid) is
  'The ONLY route by which a Guardian learns anything about the other '
  'family. Main Guardians only; uniform fields; no city, no photo, no '
  'contact channel (none exists). Replaces the full-profile visibility '
  'clause 3 granted until 2026-08-08. Callers must disclose to the user '
  'what the other family sees.';

-- VERIFIED 2026-08-08, 15/15: both Main Guardians get the card
-- symmetrically; contact is NULL; Additional Guardians, Seekers and
-- unrelated users get nothing; no card at 'potential'; no card after a
-- block; a counterpart with no Main Guardian still yields the Seeker half
-- with the Guardian half empty; anon holds no EXECUTE.
