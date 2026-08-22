-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807204003, applied name
-- 'app_feedback') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Feedback — "a feedback section where we can improve the app from users
-- requests". Founder 2026-08-07.
--
-- A TABLE RATHER THAN AN EMAIL, deliberately. Help & Support already ends
-- in "email us", and that is right for a person who is stuck. This is the
-- opposite case: someone who is fine and has an idea. Those arrive in
-- volume, need counting and grouping, and die in an inbox.
--
-- ── WHAT IS STORED, AND WHAT IS NOT.
-- Category, message, and the three things that make a report actionable:
-- app version, platform, and where in the app they were. Nothing else.
--
-- NOT stored: device model, OS version, locale, screen size, any
-- identifier beyond user_id. Every one of those is defensible on its own
-- and none is necessary to read a sentence someone wrote, which is
-- Article 5(1)(c) — collect what you need for the stated purpose and stop.
-- Add a field when a real report cannot be actioned without it.
--
-- user_id IS stored, and nullable. Stored because feedback you cannot
-- reply to is half a conversation, and because one person filing forty
-- items is a fact worth being able to see. Nullable because it is a
-- foreign key with ON DELETE SET NULL: someone exercising erasure must not
-- have their deletion blocked by a suggestion they made, and the
-- suggestion itself is not personal data once it is detached.
--
-- ── VISIBILITY. A user can read their OWN feedback and nobody else's.
-- There is no admin read policy here because there is no admin (see the
-- Identity Correction note in the approved settings document) — reading is
-- done with the service role, which bypasses RLS. The absence is
-- deliberate: an admin policy with no admin behind it is a door left ajar
-- for whoever eventually claims that role.
--
-- ── NO UPDATE, NO DELETE. Not even for the author. Editing feedback after
-- it is read makes a record of what people asked for untrustworthy, and a
-- delete grant would let someone withdraw a report of a problem after it
-- was acted on. Erasure is handled by the FK above, which is the route
-- that actually has to work.

create table if not exists public.app_feedback (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references auth.users(id) on delete set null,
  category     text not null,
  message      text not null,
  app_version  text,
  platform     text,
  screen       text,
  created_at   timestamptz not null default now(),

  constraint app_feedback_category_known
    check (category in ('idea','problem','other')),

  -- 4000 characters is generous for a sentence and finite for a column.
  -- Trimmed by the RPC before it ever reaches here, so an all-whitespace
  -- message is refused rather than stored as blank.
  constraint app_feedback_message_shape
    check (message = btrim(message) and char_length(message) between 1 and 4000),

  constraint app_feedback_short_meta
    check (
      (app_version is null or char_length(app_version) <= 40) and
      (platform    is null or char_length(platform)    <= 40) and
      (screen      is null or char_length(screen)      <= 80)
    )
);

comment on table public.app_feedback is
  'User-submitted ideas and problem reports. Append-only: no UPDATE or '
  'DELETE grant exists for anyone, including the author. user_id is '
  'ON DELETE SET NULL so an erasure request is never blocked by it.';

comment on column public.app_feedback.user_id is
  'OWNERSHIP: row-scoped(user_id). Nullable — becomes NULL when the account '
  'is deleted, at which point the row is no longer personal data.';
comment on column public.app_feedback.message is
  'OWNERSHIP: row-scoped(user_id). The user''s own words, disclosable to '
  'them under Article 15.';
comment on column public.app_feedback.category is
  'OWNERSHIP: row-scoped(user_id)';
comment on column public.app_feedback.app_version is
  'OWNERSHIP: row-scoped(user_id). Collected because "it broke" is not '
  'actionable without knowing which build.';
comment on column public.app_feedback.platform is
  'OWNERSHIP: row-scoped(user_id). ios | android, nothing finer — the '
  'device model is not needed to read a sentence.';
comment on column public.app_feedback.screen is
  'OWNERSHIP: row-scoped(user_id). Where they were when they wrote it.';

create index if not exists app_feedback_created_idx
  on public.app_feedback (created_at desc);
create index if not exists app_feedback_user_idx
  on public.app_feedback (user_id) where user_id is not null;

alter table public.app_feedback enable row level security;

-- SELECT own only. No policy grants anyone a second person's row.
drop policy if exists app_feedback_select_own on public.app_feedback;
create policy app_feedback_select_own on public.app_feedback
  for select using (user_id = (select auth.uid()));

-- A policy is unreachable without a table grant beneath it, so this is
-- half of the pair and neither half is optional.
grant select (id, category, message, created_at) on public.app_feedback to authenticated;

-- INSERT goes through the RPC, NOT a direct grant. The RPC trims, stamps
-- user_id server-side, and rate-limits — none of which a client-side
-- insert would do, and all of which stop the table becoming a free
-- write-anything endpoint for anyone holding the anon key and a session.

create or replace function public.zyra_submit_feedback(
  p_category    text,
  p_message     text,
  p_app_version text default null,
  p_platform    text default null,
  p_screen      text default null
)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_me     uuid := auth.uid();
  v_msg    text := btrim(coalesce(p_message, ''));
  v_recent int;
  v_id     uuid;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  IF p_category NOT IN ('idea','problem','other') THEN
    RAISE EXCEPTION 'invalid_category';
  END IF;

  IF v_msg = '' THEN
    RETURN jsonb_build_object('status','empty');
  END IF;
  IF char_length(v_msg) > 4000 THEN
    RETURN jsonb_build_object('status','too_long','max',4000);
  END IF;

  -- Rate limit. Not anti-abuse theatre: without it one stuck retry loop
  -- writes thousands of identical rows and the useful feedback is buried
  -- under it. Ten an hour is far more than anyone sends in good faith.
  --
  -- clock_timestamp(), not now(): now() is transaction start time, and
  -- the difference has already produced one wrong result in this codebase
  -- (three consent events sharing a timestamp, 2026-08-06).
  SELECT count(*) INTO v_recent
    FROM public.app_feedback
   WHERE user_id = v_me
     AND created_at > clock_timestamp() - interval '1 hour';

  IF v_recent >= 10 THEN
    RETURN jsonb_build_object('status','rate_limited');
  END IF;

  INSERT INTO public.app_feedback
    (user_id, category, message, app_version, platform, screen)
  VALUES
    (v_me, p_category, v_msg,
     left(nullif(btrim(coalesce(p_app_version,'')), ''), 40),
     left(nullif(btrim(coalesce(p_platform,'')),    ''), 40),
     left(nullif(btrim(coalesce(p_screen,'')),      ''), 80))
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('status','sent','id',v_id);
END;
$function$;

comment on function public.zyra_submit_feedback(text,text,text,text,text) is
  'The only write path into app_feedback. Trims, validates, stamps user_id '
  'server-side and rate-limits to 10/hour. There is deliberately no INSERT '
  'grant on the table itself.';

grant execute on function public.zyra_submit_feedback(text,text,text,text,text)
  to authenticated;
