-- THE INVISIBLE-JOURNEYS BUG, 2026-08-15 (DR-ZYRA-179).
--
-- matches carries a COLUMN-SCOPED select grant (not table-wide), so a
-- migration that adds a column must also extend the grant. Two didn't:
-- 20260812164117 added pause_nudged_at, 20260815101749 added
-- also_paused_by/also_paused_at. The client has selected
-- pause_nudged_at since 2026-08-12 and also_paused_by since 2026-08-15,
-- so every fetchJourneyMatches / refetchOne since 2026-08-12 died with
-- 42501 -> HTTP 403 -> the client's catch returned [] -> the app showed
-- NO real Journeys for anyone, and the dev scenario's stand-ins painted
-- over the hole. Found from the edge logs: GET /rest/v1/matches -> 403,
-- three times in one screen open, while everything around it 200'd.
--
-- end_reason and end_note stay UNGRANTED on purpose: the safety ending
-- is read server-side (zyra_can_view_profile) and the note is private.
-- profiles' two withheld columns (date_of_birth, onboarding_complete)
-- are likewise intentional — the full column-grant audit found no other
-- gap.
grant select (pause_nudged_at, also_paused_by, also_paused_at)
  on public.matches to authenticated;
