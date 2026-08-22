-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804105356, applied name
-- 'c1_fix_zyra_one_grant_plan_name') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Correcting the trigger applied minutes ago: it tested
-- `plan_type = 'zyra_one'`, a value the subscriptions CHECK constraint
-- makes impossible. It would have silently never fired.
--
--   CHECK (plan_type IN ('seeker_basic','seeker_premium',
--                        'wali_basic','wali_premium'))
--
-- ZYRA One is `seeker_premium` in the database. The product name changed;
-- the identifier deliberately did not — the Founder's standing rule is
-- that DB identifiers are never renamed, because RLS policies, service
-- queries and RPCs all key off them. zyra_session_router.dart:135 is the
-- authority: `plan = planType == 'seeker_premium' ? ZyraPlan.one : basic`.
--
-- Caught by checking the actual rows and constraint rather than trusting
-- that the product name and the column value matched. They almost never do
-- in this codebase, by design.
--
-- `wali_premium` is deliberately NOT included: it is the Guardian's own
-- plan, and a Guardian cannot hold or use a Compatibility Unlock at all.

create or replace function public.grant_zyra_one_credits()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  -- 'seeker_premium' IS ZYRA One. Not a typo.
  if new.plan_type = 'seeker_premium' and new.status = 'active' then
    insert into public.unlock_credits (user_id, tier, delta, reason, note)
    values (new.user_id, 'paid_plus_single', 3, 'zyra_one_included',
            'Included with ZYRA One')
    on conflict do nothing;
  end if;
  return new;
end $$;

revoke all on function public.grant_zyra_one_credits() from public, anon;

-- Backfill existing ZYRA One subscribers, now against the right value.
insert into public.unlock_credits (user_id, tier, delta, reason, note)
select s.user_id, 'paid_plus_single', 3, 'zyra_one_included',
       'Included with ZYRA One (backfill 2026-08-04)'
from public.subscriptions s
where s.plan_type = 'seeker_premium' and s.status = 'active'
on conflict do nothing;
