# ZYRA — Flutter Source

Muslim matrimonial platform. Specs live in `../APP/`, decisions in
`../SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md`, session reports in
`../REPORTS/CURRENT/`. Read those before changing anything here.

## Device testing — THE CONFIRMED, CORRECT WAY (2026-07-19, hardened 2026-08-01)

**Every AI session giving Shakeel run instructions must use this — and
only this:**

```
cd "/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE" && ./run.sh
```

ONE LINE, joined with `&&` — corrected 2026-08-14. This block gave two
lines, which is two pastes and two Returns, and directly contradicted
CLAUDE.md §1, where the Founder confirmed the joined form twice on
2026-08-08 ("THIS IS THE CORRECT VERSION", then "THIS IS NEW TERMINAL
CODE"). Two sources of truth for the one instruction that has already
cost two sessions is exactly the failure CLAUDE.md exists to prevent.
CLAUDE.md is the source of truth; this file follows it.

`run.sh` defaults to a profile build (safe untethered) and prints what
to expect. `./run.sh dev` = debug + hot reload, cable must stay in.
Added 2026-08-01 after the debug-mode trap caught a second session —
documentation alone didn't prevent recurrence, so the safe mode is now
the default mechanically.

Raw equivalent, if the script can't be used:

```
flutter run --profile -d 00008130-001A2C1E26F8001C
```

- `00008130-001A2C1E26F8001C` is Shakeel's iPhone (confirm with
  `flutter devices` if it ever changes).
- **`--profile` is mandatory for untethered testing.** Plain
  `flutter run` installs a DEBUG build; iOS kills debug (JIT) apps the
  moment the cable is unplugged and refuses to cold-launch them from
  the icon (white screen → instant close, every time, until
  reinstalled). This looked like a mystery crash for hours on
  2026-07-19. It is not an app bug. Never diagnose "crash after
  unplug" or "won't open from icon" without first asking which mode
  the build was.
- Profile builds: survive unplugging, launch from the icon like a real
  app, keep the DevNavOverlay Back/Home buttons (gated `!kReleaseMode`),
  no hot reload — replug and re-run to pick up code changes.
- Plain `flutter run` (debug, hot reload) is fine ONLY while the cable
  stays connected. Avoid iPhone Mirroring during a debug session — the
  two interfere.
- Full background: `../REPORTS/CURRENT/ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md` §7.

## Developer Mode

In-app test-scenario switcher on the Welcome screen ("Developer
Access"): one tap signs into seeded real Supabase test accounts
(`dev.*@zyra.test`, see `supabase/seed_dev_accounts.sql`) and lands
fully onboarded. No OAuth is needed for that developer path. Real local
OAuth IDs live in gitignored `lib/config/oauth_config.dart`; the matching
Google bundle/package registrations and Supabase provider allow-list remain
external configuration and must be verified after any application-ID change.

## Backend

Supabase project `sxoaxonzjqkgajmlagyk`. Config in
`lib/config/supabase_config.dart` (gitignored, real values in place).
Migrations source-controlled in `supabase/migrations/` — keep them in
sync with the live project (`list_migrations`) after any DB change.
