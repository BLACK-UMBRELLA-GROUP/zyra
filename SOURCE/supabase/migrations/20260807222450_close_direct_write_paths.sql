-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807222450, applied name
-- 'close_direct_write_paths') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- STEP 0 of the agreed sequence: close the direct write paths.
-- Founder authorised 2026-08-07 after three independent architecture
-- reviews (Opus, ChatGPT, Fable) converged on the same conclusion.
--
-- THE PRINCIPLE. Several tables carry write GRANTS with no matching write
-- POLICY. RLS denies the write, so they look safe — but they are safe by
-- ABSENCE, and absences get filled in. The day someone adds an
-- innocuous-looking policy, the grant behind it is already open.
--
-- The sharpest example, and the reason this is worth doing now:
-- `subscriptions` is SELECT-only by policy but holds full INSERT/UPDATE
-- grants. Add `UPDATE ... USING (user_id = auth.uid())` — which is exactly
-- what anyone would write without thinking — and every user can set their
-- own plan_type to zyra_one for free.
--
-- profile_unlocks already shows the correct shape: the GRANTS were revoked,
-- not merely left unmatched. This brings the rest into line.
--
-- ── A SIDE EFFECT WORTH KNOWING: failures become LOUD.
-- A write blocked by RLS affects 0 rows and raises nothing. A write blocked
-- by a missing grant raises. Demonstrated during the audit:
-- ZyraJourneyService.advanceStage() UPDATEs matches.journey_stage directly
-- and has been a silent no-op — 0 rows, no error, stage unchanged — while
-- being called from the live Journey ritual flow. It will now throw.
-- Its own `catch (_) {}` still swallows that, so the user-visible behaviour
-- is unchanged; the fix for advanceStage is a separate piece of work and is
-- NOT attempted here.

-- ── wali_links ────────────────────────────────────────────────────────
-- Demonstrated hole: a client could INSERT an ACTIVE link naming anyone as
-- their Guardian, with no invite and no consent, bypassing every rule in
-- accept_wali_invite(). That function is SECURITY DEFINER and becomes the
-- sole write path, exactly as zyra_submit_feedback is for app_feedback.
revoke insert, update, delete on public.wali_links from anon, authenticated;

-- Dropped, not left dormant. An unreachable policy is worse than none: if
-- the grant is ever restored, this springs back with semantics nobody
-- reviewed. Updates run through zyra_set_main_guardian(),
-- zyra_clear_main_guardian() and zyra_remove_guardian(), all of which are
-- SECURITY DEFINER and unaffected.
drop policy if exists wali_links_update on public.wali_links;

comment on table public.wali_links is
  'Guardian relationships. WRITE PATH IS accept_wali_invite() AND THE '
  'zyra_*_guardian() RPCs ONLY — client INSERT/UPDATE/DELETE grants were '
  'revoked 2026-08-07 after a demonstrated bypass that let a Seeker create '
  'an active link naming any user as their Guardian without consent. '
  'Do not re-grant. If a new write is needed, add a SECURITY DEFINER '
  'function.';

-- ── matches ───────────────────────────────────────────────────────────
-- Rows are created by create_match_on_mutual_like(), a SECURITY DEFINER
-- trigger that runs as the owner and is unaffected by these grants.
revoke insert, update, delete on public.matches from anon, authenticated;

-- ── subscriptions · unlock_credits ────────────────────────────────────
-- Entitlement. Written only by grant_zyra_one_credits(),
-- zyra_debug_grant_credits() and the mock_* functions, all SECURITY
-- DEFINER, and the mock ones gated to %@zyra.test accounts server-side.
revoke insert, update, delete on public.subscriptions   from anon, authenticated;
revoke insert, update, delete on public.unlock_credits  from anon, authenticated;

-- ── journey_attempts ──────────────────────────────────────────────────
-- RLS is on and it has ZERO policies, so every client operation is already
-- denied. It nonetheless held all six privileges for both roles. Reached
-- only through zyra_my_attempt_participation and SECURITY DEFINER
-- functions, so there is nothing legitimate to take away.
revoke all on public.journey_attempts from anon, authenticated;

comment on table public.journey_attempts is
  'Journey attempts. NO client grants and NO RLS policies, deliberately: '
  'read it through zyra_my_attempt_participation (which filters to '
  'auth.uid()) or a SECURITY DEFINER function. Revoked 2026-08-07 — it '
  'previously held full grants behind zero policies, i.e. it was protected '
  'by an absence rather than a decision.';

-- ── My own error, same day ────────────────────────────────────────────
-- zyra_reset_profile and zyra_submit_feedback were the only two SECURITY
-- DEFINER functions in the schema callable by `anon`. Cause: Postgres
-- grants EXECUTE to PUBLIC on CREATE FUNCTION, and an explicit GRANT to
-- authenticated does not displace it. Every other function here had already
-- been revoked from PUBLIC; I did not follow the convention.
--
-- Impact was nil — both raise not_signed_in when auth.uid() is null — but
-- "harmless because of a second check" is not a grant policy.
revoke execute on function public.zyra_reset_profile() from public;
revoke execute on function public.zyra_submit_feedback(text,text,text,text,text) from public;
grant  execute on function public.zyra_reset_profile() to authenticated;
grant  execute on function public.zyra_submit_feedback(text,text,text,text,text) to authenticated;
