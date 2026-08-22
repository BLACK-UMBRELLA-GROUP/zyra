-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804105309, applied name
-- 'c1_zyra_one_included_credits_grant') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- ZYRA One's included Compatibility Unlock+ credits, as ledger rows.
--
-- Founder approved 2026-08-03: a ZYRA One Seeker receives 3 free Unlock+
-- credits. Until now that was `+ kZyraOneFreeUnlockPlus` added in the
-- Flutter screen — so the number shown to the user and the number the
-- server would honour were computed in different places under different
-- rules, and the server's rule was "there isn't one".
--
-- Now a grant row like any other. Founder: "future App Store / Play Store
-- purchases should simply grant credits into the same ledger instead of
-- replacing the architecture" — the same applies to plan-included credits.
--
-- ONE-TIME PER USER, enforced by the partial unique index created with the
-- table (unlock_credits_one_zyra_one_grant). Without it a plan change, a
-- resubscribe, or a retried write mints three more free credits each time.
--
-- OPEN QUESTION, flagged not decided: the spec says a ZYRA One Seeker
-- "receives 3 free credits". It does not say whether that is once, or
-- three every month. This grants ONCE. Monthly would need a scheduled job,
-- which does not exist in this project, and inventing a recurring
-- entitlement is a pricing decision rather than an engineering one.

create or replace function public.grant_zyra_one_credits()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.plan_type = 'zyra_one' and new.status = 'active' then
    -- ON CONFLICT DO NOTHING against the partial unique index: a second
    -- activation is a no-op rather than an error, so a plan change never
    -- fails because of this trigger.
    insert into public.unlock_credits (user_id, tier, delta, reason, note)
    values (new.user_id, 'paid_plus_single', 3, 'zyra_one_included',
            'Included with ZYRA One')
    on conflict do nothing;
  end if;
  return new;
end $$;

drop trigger if exists subscriptions_grant_zyra_one_credits on public.subscriptions;
create trigger subscriptions_grant_zyra_one_credits
  after insert or update of plan_type, status on public.subscriptions
  for each row execute function public.grant_zyra_one_credits();

revoke all on function public.grant_zyra_one_credits() from public, anon;

-- Backfill anyone already on ZYRA One, so existing subscribers are not
-- worse off than someone who signs up tomorrow.
insert into public.unlock_credits (user_id, tier, delta, reason, note)
select s.user_id, 'paid_plus_single', 3, 'zyra_one_included',
       'Included with ZYRA One (backfill 2026-08-04)'
from public.subscriptions s
where s.plan_type = 'zyra_one' and s.status = 'active'
on conflict do nothing;
