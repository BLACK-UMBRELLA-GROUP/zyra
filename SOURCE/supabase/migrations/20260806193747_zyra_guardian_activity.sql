-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806193747, applied name
-- 'zyra_guardian_activity') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Guardian page, step 2: what my Guardians have actually DONE.
--
-- The page reads as a contacts list because it shows attributes and never
-- shows anyone acting. This is the fix, and every row it returns is a real
-- event with a real timestamp. Nothing is synthesised — Founder: "I don't
-- want fake activity. If there is no activity, don't invent it."
--
-- TWO REQUESTED TYPES ARE ABSENT ON PURPOSE:
--   'became_main'  — is_main is a boolean with no timestamp, and for a first
--                    Guardian it would duplicate 'linked' on the same day.
--                    Arrives free if Main reassignment is ever built.
--   'invited_to_journey' — participation is DERIVED from wali_links, not an
--                    event (zyra_attempt_participants returns no timestamp).
--                    There is no invitation, so there is no moment to show.
--
-- SECURITY: SECURITY DEFINER, but every branch is anchored to the caller.
-- There is no parameter, so there is nothing to point at another Seeker.

create or replace function public.zyra_guardian_activity()
returns table(
  wali_id       uuid,
  activity_type text,
  occurred_at   timestamptz,
  detail        text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with my_guardians as (
    select w.wali_id, w.created_at, coalesce(w.is_main, false) as is_main
    from public.wali_links w
    where w.seeker_id = (select auth.uid())
      and w.status = 'active'
  )

  -- They accepted, and the link began.
  select g.wali_id, 'linked'::text, g.created_at, null::text
  from my_guardians g

  union all

  -- They put someone forward. The only type with real data today.
  select s.wali_id, 'suggested', s.created_at, p.first_name
  from public.wali_suggestions s
  join my_guardians g on g.wali_id = s.wali_id
  join public.profiles p on p.id = s.suggested_id
  where s.seeker_id = (select auth.uid())

  union all

  -- They answered a Family Review on one of my Journeys.
  select r.wali_id, 'review_answered', r.responded_at, r.decision
  from public.journey_family_review_responses r
  join my_guardians g on g.wali_id = r.wali_id
  join public.journey_family_reviews rev on rev.id = r.review_id
  join public.matches m on m.id = rev.match_id
  where (select auth.uid()) in (m.seeker_a_id, m.seeker_b_id)

  union all

  -- A review is open and the Main Guardian has not answered it.
  -- Scoped to Main because only the Main Guardian is asked to act — the
  -- same rule the page already states in its own copy.
  select g.wali_id, 'review_waiting', rev.opened_at, null
  from public.journey_family_reviews rev
  join public.matches m on m.id = rev.match_id
  join my_guardians g on g.is_main
  where rev.status = 'open'
    and (select auth.uid()) in (m.seeker_a_id, m.seeker_b_id)
    and not exists (
      select 1 from public.journey_family_review_responses rr
      where rr.review_id = rev.id and rr.wali_id = g.wali_id
    )

  order by 3 desc nulls last;
$function$;

revoke execute on function public.zyra_guardian_activity() from public;
revoke execute on function public.zyra_guardian_activity() from anon;
grant  execute on function public.zyra_guardian_activity() to authenticated;
grant  execute on function public.zyra_guardian_activity() to service_role;
