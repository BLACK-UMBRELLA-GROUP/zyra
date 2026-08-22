-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807184618, applied name
-- 'profiles_first_name_shape') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- first_name validation at the TABLE, not only in the RPC.
-- Founder decision 2026-08-07: "The database should enforce the same
-- constraints as the UI so every write path behaves identically."
--
-- THE DEFECT. zyra_create_profile() checked btrim() <> '' and
-- char_length() <= 60. But that RPC is not the path the app uses to edit a
-- name — the app writes through the column grant on profiles.first_name,
-- where there was no CHECK constraint, no trim and no character rule at
-- all. A 4,000-character name was accepted and would render on a Browse
-- card. Two write paths, two different sets of rules, and the stricter one
-- was the one nobody used.
--
-- TRIM IN A TRIGGER, LENGTH IN A CHECK. A CHECK can only reject, so a
-- constraint alone would turn " Sara " into an error message rather than
-- into "Sara". The trigger normalises first; Postgres evaluates CHECK
-- constraints after BEFORE-triggers, so the constraint always sees the
-- cleaned value.
--
-- The "is trimmed" half of the CHECK is therefore redundant in normal
-- operation, and kept deliberately: the previous migration disabled a
-- trigger on this very table to run a backfill, and if that ever happens
-- again the constraint still holds. It fails closed — rejecting rather
-- than silently storing padding.
--
-- char_length(), NOT octet_length(). It counts characters, so an Arabic,
-- Urdu or Bengali name gets the same 60 as an English one. octet_length
-- would have given multi-byte scripts roughly a third of the allowance,
-- on an app whose users disproportionately have exactly those names.
--
-- VERIFIED BEFORE APPLYING: of 149 rows, 0 untrimmed, 0 empty after
-- trimming, 0 over 60. Longest existing name is 8 characters. Nothing is
-- rewritten by this migration.

create or replace function public.zyra_normalise_profile_identity()
 returns trigger
 language plpgsql
 set search_path to 'public'
as $function$
BEGIN
  IF NEW.first_name IS NOT NULL THEN
    NEW.first_name := btrim(NEW.first_name);
  END IF;
  RETURN NEW;
END;
$function$;

comment on function public.zyra_normalise_profile_identity() is
  'Trims first_name on every write path. Deliberately NOT extended to '
  'surname_line or bio — those have the same missing-limit problem but no '
  'agreed limit yet, and inventing one here would be a decision smuggled '
  'into a migration. See ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION.';

-- Fires before profiles_updated_at (trigger order is alphabetical per
-- event, and 'n' < 'u'). They touch different columns, so the order does
-- not matter today — noted so it stays true if either one grows.
drop trigger if exists profiles_normalise_identity on public.profiles;
create trigger profiles_normalise_identity
  before insert or update of first_name on public.profiles
  for each row execute function public.zyra_normalise_profile_identity();

alter table public.profiles
  drop constraint if exists profiles_first_name_shape;

alter table public.profiles
  add constraint profiles_first_name_shape
  check (
    first_name = btrim(first_name)
    and char_length(first_name) between 1 and 60
  );
