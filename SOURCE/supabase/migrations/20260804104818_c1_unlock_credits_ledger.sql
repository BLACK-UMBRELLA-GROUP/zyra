-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804104818, applied name
-- 'c1_unlock_credits_ledger') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- C-1 — the unlock entitlement ledger. Founder approved 2026-08-04.
--
-- THE VULNERABILITY THIS CLOSES, reproduced end-to-end before writing it:
-- `authenticated` held INSERT on profile_unlocks, the only policy was
-- WITH CHECK (unlocker_id = auth.uid()), and there was no trigger. Two
-- HTTP requests with the publishable key that ships in the app bundle:
-- insert your own unlock row for any UUID, then call
-- seeker_details_for_unlocked(). I ran it. It returned a stranger's sect,
-- revert status, ethnicity, country of birth, nationality and languages.
--
-- WHY MY EARLIER VERIFICATION MISSED IT. Building seeker_details I proved
-- RLS blocked *reading* the table, and it did. I never tested whether the
-- gate itself could be forged, because a unique index on
-- (unlocker_id, unlocked_id, unlock_type) made profile_unlocks feel
-- trustworthy. Three different properties got conflated:
--
--   UNIQUENESS   you cannot unlock the same profile twice   (index)
--   INTEGRITY    the row says what it claims to say          (was true)
--   ENTITLEMENT  you were allowed to create it at all        (NOTHING)
--
-- Only the third one matters for payment, and nothing enforced it.
--
-- Founder: "I want this to become the permanent entitlement system rather
-- than a temporary solution. Future App Store / Play Store purchases
-- should simply grant credits into the same ledger."
--
-- APPEND-ONLY, hence a ledger rather than a balance column. A single
-- integer that goes up and down cannot answer "why does this user have
-- four credits" or "did we actually give them what they paid for", and a
-- lost update silently destroys money. Rows are facts; the balance is
-- derived. When payments land, a store receipt becomes one more row with
-- reason 'purchase' and nothing else changes.

create table if not exists public.unlock_credits (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,

  -- Matches profile_unlocks.unlock_type. Credits are per-tier: three free
  -- Plus credits must not silently pay for a standard unlock.
  tier        text not null check (tier in ('paid_single','paid_plus_single')),

  -- Positive = granted, negative = consumed. Never zero: a no-op row is
  -- noise in an audit trail.
  delta       int  not null check (delta <> 0),

  reason      text not null check (reason in (
                'zyra_one_included',  -- bundled with the ZYRA One plan
                'purchase',           -- real money, once payments exist
                'debug_grant',        -- @zyra.test accounts only
                'spend',              -- consumed by an unlock
                'refund',
                'adjustment'          -- manual correction, must be explained
              )),

  -- Which unlock consumed this credit. Lets "where did my credit go" be
  -- answered without guessing from timestamps.
  related_unlock_id uuid references public.profile_unlocks(id) on delete set null,

  note        text,
  created_at  timestamptz not null default now(),

  -- Grants add, spends subtract. Enforced so a bug cannot write a positive
  -- 'spend' and mint credits.
  constraint unlock_credits_sign_matches_reason check (
    (reason = 'spend'  and delta < 0) or
    (reason = 'refund' and delta > 0) or
    (reason in ('zyra_one_included','purchase','debug_grant') and delta > 0) or
    (reason = 'adjustment')
  )
);

comment on table public.unlock_credits is
  'Append-only entitlement ledger for Compatibility Unlocks. Balance is sum(delta) per user per tier. Never UPDATE or DELETE a row here — corrections are new rows with reason=adjustment.';

create index if not exists unlock_credits_balance
  on public.unlock_credits (user_id, tier);

-- A ZYRA One subscription grants its included credits exactly once.
-- Without this a plan change, a resubscribe, or a retried write mints
-- free credits every time.
create unique index if not exists unlock_credits_one_zyra_one_grant
  on public.unlock_credits (user_id, tier)
  where reason = 'zyra_one_included';

alter table public.unlock_credits enable row level security;

-- READ ONLY, and only your own. Every write goes through the RPCs below;
-- there is deliberately no INSERT, UPDATE or DELETE policy for anyone.
-- A user who could insert their own grant row would be exactly the bug
-- this table exists to fix, one level further down.
create policy unlock_credits_select_own on public.unlock_credits
  for select using (user_id = (select auth.uid()));

-- =====================================================================
-- BALANCE
-- =====================================================================
create or replace function public.unlock_balance(p_tier text default null)
returns table(tier text, balance int)
language sql
stable
security definer
set search_path to 'public'
as $$
  select c.tier, coalesce(sum(c.delta), 0)::int
  from public.unlock_credits c
  where c.user_id = (select auth.uid())
    and (p_tier is null or c.tier = p_tier)
  group by c.tier;
$$;

-- =====================================================================
-- SPEND — the only way a profile_unlocks row can now be created.
-- =====================================================================
create or replace function public.zyra_unlock_profile(p_target uuid, p_tier text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
DECLARE
  v_me      uuid := auth.uid();
  v_balance int;
  v_unlock  uuid;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  IF p_tier NOT IN ('paid_single','paid_plus_single') THEN
    RAISE EXCEPTION 'unknown_tier' USING HINT = 'paid_single or paid_plus_single';
  END IF;

  IF p_target = v_me THEN
    RAISE EXCEPTION 'cannot_unlock_self';
  END IF;

  -- Same visibility rule as everything else. Without it, this function
  -- would confirm the existence of any UUID you cared to name.
  IF NOT public.zyra_can_view_profile(p_target) THEN
    RAISE EXCEPTION 'not_visible';
  END IF;

  -- PERMANENCE, Founder-ratified: "returning to the same profile must
  -- NEVER consume another unlock." Checked BEFORE the balance, so someone
  -- with zero credits still reaches what they already paid for — and a
  -- double tap on a slow connection cannot charge twice.
  IF EXISTS (
    SELECT 1 FROM public.profile_unlocks u
    WHERE u.unlocker_id = v_me AND u.unlocked_id = p_target AND u.unlock_type = p_tier
  ) THEN
    RETURN jsonb_build_object('status','already_unlocked','charged',false);
  END IF;

  SELECT coalesce(sum(delta),0)::int INTO v_balance
  FROM public.unlock_credits
  WHERE user_id = v_me AND tier = p_tier;

  IF v_balance < 1 THEN
    RETURN jsonb_build_object('status','insufficient_credits','charged',false,'balance',v_balance);
  END IF;

  -- One statement, one transaction. The unlock and the debit cannot
  -- diverge: if either fails, neither happened.
  INSERT INTO public.profile_unlocks (unlocker_id, unlocked_id, unlock_type)
  VALUES (v_me, p_target, p_tier)
  RETURNING id INTO v_unlock;

  INSERT INTO public.unlock_credits (user_id, tier, delta, reason, related_unlock_id)
  VALUES (v_me, p_tier, -1, 'spend', v_unlock);

  RETURN jsonb_build_object('status','unlocked','charged',true,'balance',v_balance - 1);
END;
$$;

-- =====================================================================
-- DEBUG GRANT — @zyra.test only. Same guard as mock_purchase_wali_premium.
-- Founder: "keep an @zyra.test debug grant so we can continue testing."
-- =====================================================================
create or replace function public.zyra_debug_grant_credits(p_tier text, p_count int default 5)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
DECLARE
  v_me uuid := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = v_me AND u.email LIKE '%@zyra.test'
  ) THEN
    RAISE EXCEPTION 'debug_grant_disabled'
      USING HINT = 'Credit grants are limited to seeded test accounts. Real payment processing is not built yet.';
  END IF;

  IF p_tier NOT IN ('paid_single','paid_plus_single') THEN
    RAISE EXCEPTION 'unknown_tier';
  END IF;
  IF p_count < 1 OR p_count > 50 THEN
    RAISE EXCEPTION 'count_out_of_range';
  END IF;

  INSERT INTO public.unlock_credits (user_id, tier, delta, reason, note)
  VALUES (v_me, p_tier, p_count, 'debug_grant', 'dev panel');

  RETURN jsonb_build_object('status','granted','tier',p_tier,'added',p_count);
END;
$$;

-- =====================================================================
-- THE REVOKE. The whole point.
-- =====================================================================
revoke insert, update, delete on public.profile_unlocks from authenticated;
revoke insert, update, delete on public.profile_unlocks from anon;

-- The old client-side INSERT policy is now unreachable and misleading.
drop policy if exists profile_unlocks_insert on public.profile_unlocks;

revoke all on function public.unlock_balance(text)                from public, anon;
revoke all on function public.zyra_unlock_profile(uuid, text)     from public, anon;
revoke all on function public.zyra_debug_grant_credits(text, int) from public, anon;
grant execute on function public.unlock_balance(text)                to authenticated;
grant execute on function public.zyra_unlock_profile(uuid, text)     to authenticated;
grant execute on function public.zyra_debug_grant_credits(text, int) to authenticated;
