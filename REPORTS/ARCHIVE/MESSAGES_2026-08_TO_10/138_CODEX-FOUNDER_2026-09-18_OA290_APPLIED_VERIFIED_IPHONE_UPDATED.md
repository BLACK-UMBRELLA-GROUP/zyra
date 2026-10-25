# 138 — CODEX → FOUNDER — OA-ZYRA-290 Applied, Verified, iPhone Updated

**Date:** 2026-09-18  
**Programme:** OA-ZYRA-290 / DR-ZYRA-232  
**State:** LIVE · POST-APPLY VERIFIED · DEVICE INSTALLED

## 1. Production cutover

Supabase project `sxoaxonzjqkgajmlagyk` received exactly one migration through
the standard Supabase CLI push mechanism:

- version: `20260918075737`;
- name: `oa290_additional_guardian_journey_access`;
- source SHA-256:
  `347e32e901b266cd4a6e7fa98fd077e51b4963f2b5e3c6620f1645577847a282`.

A disposable migration workspace was populated from live migration history so
the CLI dry run could prove that the target file was the only pending version.
No history repair, MCP-generated orphan migration, additional migration or
source-file modification occurred.

## 2. Post-apply evidence

- exact history row present once and is latest;
- audited assignment table exists, RLS enabled;
- `anon` and `authenticated` have no table access; `service_role` does;
- both required indexes exist;
- access and counterpart RPCs are `SECURITY DEFINER`, owner `postgres`, empty
  search path and explicitly granted only to intended roles;
- unscoped participation remains private; caller-scoped participation remains
  authenticated-only;
- all six amended read policies exist;
- null caller, Main immutable/included, partial arguments and cross-Seeker
  Guardian direct-call cases passed in a rolled-back transaction;
- zero verification assignments persisted.

Production contained no active Journey whose Seeker simultaneously had both a
Main and Additional Guardian. No relationship data was fabricated merely to
force that positive live-role case. Its exact success/revoke state machine is
covered by the 55 passing focused client/migration tests; the first natural
eligible Journey supplies the remaining live observation.

The advisor delta is expected: one private RPC-only RLS table, two intentional
authenticated definer RPC notices, two initially-unused indexes and three
foreign-key index information notices. The one security-definer-view error is
the pre-existing caller-scoped participation finding already recorded in the
standing audit bucket.

## 3. Client and device

- `flutter analyze`: PASS;
- focused affected suite: 55/55 PASS;
- profile iOS build: PASS;
- executable SHA-256:
  `0d5a5ba4d1ec3aae9c3ba14450e140483bfa896cb9a2bbbf87d070d41a2b5284`;
- install: PASS;
- launch: PASS, process confirmed;
- device inventory: exactly `ZYRA`, bundle `app.zyraconnect.zyra`, version
  `1.0.0`, build `2`;
- TestFlight, App Store and git: untouched.

## 4. Founder review surface

The Additional Guardian detail page now uses the available space for:

1. exact active-Journey include/exclude controls;
2. **CAN VIEW** — overview/progress, timeline/conversation and restricted
   counterpart details;
3. **MAIN GUARDIAN LEADS** — Family Review, Guardian Gate, pause/continue and
   protected decisions.

Main remains permanently included. Additional access changes only after the
server confirms them, and failed changes retain the last confirmed state.

## 5. Governance pre-state

- Outstanding Actions:
  `02ab937fd33328e14d895febcd0f83fe0a84912bac3db4f116df40f0902f3fe3`;
- Guardian source of truth:
  `7b62356b9033f79c8828ee19e1e42b2f063fdc871611fc2acbf8915f4f8c6a5c`.
