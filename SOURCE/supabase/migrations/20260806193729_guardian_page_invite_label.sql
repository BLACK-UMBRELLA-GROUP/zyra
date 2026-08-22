-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806193729, applied name
-- 'guardian_page_invite_label') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Guardian page, step 1: the sender's private note for an invite code.
--
-- A pending invitation has no recipient — the flow is "generate a code,
-- share it however you like", so wali_invites knows a token and who sent it
-- and nothing else. "Ahmed — waiting for acceptance" was unbuildable: there
-- is no Ahmed until someone types the code in.
--
-- This is the sender's reminder to themselves, NOT the Guardian's identity
-- and NOT a claim about who holds the code. Anyone can redeem it; the label
-- only ever says who it was MEANT for.
--
-- Privacy is structural, not policy: wali_invites_select is already
-- `inviter_id = auth.uid()`, so the label is unreadable by anyone else
-- without a new rule. preview_wali_invite — the one function the RECIPIENT
-- calls — has a fixed RETURNS TABLE of three columns and cannot carry it.

alter table public.wali_invites add column if not exists label text;

alter table public.wali_invites
  drop constraint if exists wali_invites_label_length;
alter table public.wali_invites
  add constraint wali_invites_label_length
  check (label is null or char_length(label) <= 40);

comment on column public.wali_invites.label is
  'OWNERSHIP: row-scoped(inviter_id) — the sender''s private note for who '
  'this code was intended for ("Dad", "Uncle Ibrahim"). Never shown to the '
  'recipient and never returned by preview_wali_invite. Not an identity '
  'claim: whoever redeems the code becomes the Guardian regardless.';
