-- Full-app health check, 2026-09-23. STAGED ONLY; no production Apply GO.
--
-- These two legacy mutation entry points have no current Flutter call
-- sites. They mint Guardian plans using only the old @zyra.test email suffix.
-- Internal Founder previews are now isolated local data, not permission to
-- mutate production subscriptions. Ordinary members must never mint paid
-- access through a retired test API.
--
-- Narrow ACL retirement: preserve implementations/history, existing service
-- grants, member reads, and all other still-referenced development RPCs.
-- Exact signatures are intentional: stop if deployed schema has drifted.

begin;

revoke execute on function public.mock_purchase_wali_premium()
  from public, anon, authenticated;
revoke execute on function public.mock_set_wali_plan(text)
  from public, anon, authenticated;
commit;
