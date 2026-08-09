# ZYRA — Session Handover (to the new ZYRA-dedicated chat)

```
Handed over:  2026-07-25
Handed by:    Claude (this session is moving to Black Umbrella
              Group / AIOS governance; ZYRA app build continues
              in a new dedicated chat)
Purpose:      Give the new chat everything it needs to continue
              ZYRA's build without re-deriving context.
```

---

## 0. Onboarding

Follow `STANDARDS_LIBRARY_CURRENT_VERSION_V1.md` Section 11
(Session Onboarding & Repository Familiarisation Standard,
BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/) —
Required Initial Actions, familiarisation procedure, and the
Ready / Ready with Findings / Blocked onboarding outcomes. This
section replaces any earlier ad hoc "please read the repo first"
request — it is now a standing requirement, not a per-session ask.

Documents relevant to this handover, beyond the ones named
throughout the sections below: `SYSTEM/DOCUMENTS/TREEVIEW.md`
(structural map), `ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V2.md`
(purpose/owner/source-of-truth per document), `SYSTEM/LOGS/
CHANGELOG_2026-07.md` (what shipped and when), `SYSTEM/
DECISIONS_REGISTER/DECISIONS_V1.md` DR-ZYRA-103 (why these three
exist), `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md`
OA-ZYRA-141 (the legacy `DEVELOPMENT_TEAM/`/`LIVE_OPERATIONS/`
folder question, left open pending Founder decision).

---

## 1. What ZYRA Is

ZYRA is an Islamic marriage app (Flutter + Supabase). Repo root:
`SUB BUSINESS/ZYRA/` inside the Black Umbrella Group DEVELOPMENT
folder — an independent git repo.

- **Specs / product decisions:** `APP/` (organised by feature area —
  Onboarding, Browse, Matching, Journey, Guardian, Premium, etc.)
- **Business/brand docs:** `BUSINESS/` (pricing, terminology glossary,
  naming)
- **Code:** `SOURCE/` (Flutter app, `lib/`; Supabase migrations,
  `supabase/`)
- **Governance:** `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` (DR-ZYRA-NNN)
  and `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` (OA-ZYRA-NNN)
  — ZYRA's own registers, separate from Black Umbrella's AD-NNN/OA-NNN
  and AD-AIOS-NNN/OA-AIOS-NNN registers.
- **Next identifiers:** DR-ZYRA-104, OA-ZYRA-141. (DR-ZYRA-103 was
  used 2026-07-25 to ratify the TREEVIEW.md / Documentation Index /
  Changelog repository navigation standards — see
  SYSTEM/DOCUMENTS/TREEVIEW.md, ZYRA_DOCUMENTATION_INDEX_CURRENT_
  VERSION_V2.md, SYSTEM/LOGS/CHANGELOG_2026-07.md.)

---

## 2. Live Backend

- **Supabase project:** `sxoaxonzjqkgajmlagyk` (org `pdekarsldtaqlqdthgwh`)
  — the one real ZYRA project. Access via the Supabase MCP tools
  (`execute_sql`, `apply_migration`, `list_migrations`, etc.).
- **Local migration mirrors:** `SOURCE/supabase/migrations/` — kept in
  sync with the live project (every applied migration has a matching
  `.sql` file here).
- **Auth:** Google + Apple sign-in only, user-facing (DR-ZYRA-102).
  Email/password survives only as a hidden Developer Mode test-account
  backdoor (`ZyraAuth.signInWithTestAccount`).
- **Storage:** `profile-photos` bucket, PRIVATE. All display URLs are
  7-day signed URLs. Storage path convention: `{user_id}/{n}.{ext}`.

### Dev/test accounts (password `ZyraTest!2026`)

| Email | Name | Role | Plan |
|---|---|---|---|
| dev.seeker.basic.m@zyra.test | Adam | seeker | ZYRA Basic |
| dev.seeker.basic.f@zyra.test | Maryam | seeker | ZYRA Basic (linked to Ibrahim) |
| dev.seeker.one.m@zyra.test | Yusuf | seeker | ZYRA One (linked to Khadija) |
| dev.seeker.one.f@zyra.test | Aisha | seeker | ZYRA One |
| dev.guardian@zyra.test | Ibrahim | guardian | Basic + One/Extended variant (same account, `extendedWali` local mock toggle) |
| dev.guardian.f@zyra.test | Khadija | guardian | Basic + One/Extended variant (same account, same mock toggle) |

Switch between these via the in-app **Developer Access** screen
(reachable pre-auth from Welcome, and via a build icon top-right once
inside the app). 4 Guardian presets (male/female × Basic/One), 4 Seeker
presets (male/female × Basic/One).

### Fake Browse-candidate profiles (password `ZyraFake!2026`)

20 seeded, fully photographed Seeker profiles exist purely to populate
Browse/Matches with realistic candidates when testing as any of the
accounts above — NOT switchable via Developer Access, they're just
real rows other test accounts will see in Browse:

- 10 male: Bilal, Hamza, Zayd, Usman, Tariq, Sami, Rayyan, Anas, Idris,
  Hassan
- 10 female: Amina, Sara, Noor, Hafsa, Layla, Zainab, Iman, Yasmin,
  Salma, Huda

Each has 5 profile photos (Yasmin has 4 — one upload never succeeded
on retry, harmless gap). Photo source files live at
`SOURCE/supabase/dev_test_photos/` (100 portrait PNGs, ~370MB, not
meant to ship — dev/testing only). Upload scripts (`upload_fake_
photos.sh`, `retry_failed_photos.sh`) and the resulting insert SQL
(`insert_dev_photos.sql`, `insert_retry_photos.sql`) are alongside
them in `SOURCE/supabase/` for reference/reproducibility.

**Known sandbox constraint worth knowing:** direct outbound HTTPS
calls to Supabase's REST/Storage API are blocked from this session's
sandboxed shell (allowlisted proxy only lets the Supabase MCP tool's
own channel through, which has no file-upload capability). Any future
photo/binary upload work needs a script the Founder runs locally on
his own Mac (full network access), not something runnable from the
sandbox shell directly.

---

## 3. Build Status (as of 2026-07-25)

**Fully built and live:**
- Full onboarding (Chapters 1–5), Chapter 3/4 structure ratified at
  104 + 70 questions across 9 categories (Chapter 3 Classification —
  Ch4 Mapping.md is authoritative; Summary.md/Flow Diagram.md now
  match it).
- Browse, Save/Pass/Consider decisions (renamed from Decline/Save/
  Like per DR-ZYRA-099 — swipe gestures + terminology fully swept,
  including the canonical glossary).
- Real Match creation (mutual Consider → Potential Journey), fixed
  2026-07-25 so a second mutual Consider is no longer silently
  dropped if the user already has one Active Journey.
- **Full Pre-Journey Ritual** (`journey_flow_screen.dart`): Compatibility
  Reveal, Salam Exchange, Guardian Gate, Phases 1–3 (fixed-order questions,
  private ratings, Continue/End checkpoint), Family Stage (Guardian→Seeker
  direction only).
- **Journey Suspension** (Pause/Resume/End): full RPCs
  (`suspend_journey`/`resume_journey`/`end_journey`), ZYRA One-gated,
  Auto-End handled, UI wired into Matches and the Ritual screen.
- One-Active-Journey-at-a-time enforced server-side
  (`promote_journey_to_active` RPC).
- Compatibility scoring (DR-ZYRA-079) — now **ratified**, along with
  its live wiring into Browse (DR-ZYRA-084). Neutral 50% fallback when
  scoring data is unavailable.
- Gender-based theming (Blue/male, Pink/female, neutral Purple
  pre-auth) wired everywhere a signed-in Seeker/Guardian is shown a
  screen.
- Guardian linking (real invite-token flow), Guardian dashboard/seekers/
  network/profile tabs.
- Floating nav bar: Browse/Matches/Profile (Seeker), Dashboard/
  Seekers/Network/Profile (Guardian) — deliberately different, per spec.
  **Now drag/scrub-enabled**: press-and-slide across the bar switches
  tabs live, following the finger directly (no animation lag while
  touching).
- Subscription Transparency Touchpoint 2 (the "Before you subscribe"
  Guardian-dependency notice) built into the Upgrade screen.

**Known, deliberate gaps (flagged in code/docs, not silently
skipped):**
- No AI/LLM integration anywhere — "AI-adaptive question selection"
  is a fixed-order stand-in (`journey_questions.dart`).
- No push notification system anywhere in the app.
- No 30-day Suspension auto-end timer (needs a server-side scheduled
  job).
- No Guardian-side UI for the Family Stage (Seeker only answers their own
  side; Guardian↔Guardian is TBC per the source spec itself).
- No 24-hour cooling period after End Journey.
- No real payment processing — Upgrade screen flips a local mock
  entitlement only.
- No Supabase Realtime — Journey/Ritual screens poll every ~3s instead.
- `SOURCE/lib/widgets/` (shared Flutter component library) has no
  documentation of its own anywhere in `APP/`.
- `subscriptions.plan_type` has a real `wali_premium` value in the
  schema that nothing reads yet — Extended Guardian gating is still a
  local `AppState.waliHasExtendedWali` mock toggle, not server-driven.

---

## 4. Governance Process to Keep Following

**DR-ZYRA-101 ("Implementation Review")** — mandatory before any code
change of substance:
1. Read the full governing doc(s), not just a summary.
2. Identify every DR/OA touching the feature, and every other
   screen/system it might cross-reference.
3. Ask "what is the full impact across the application?", not "which
   files do I need to touch?"
4. Raise discovered scope rather than assume it — format: *"Implementing
   X will also affect Y and Z. Shall I update all affected areas as
   part of this implementation?"*
5. State confidence explicitly once done: *"Repository reviewed.
   Primary implementation complete. Potentially affected areas
   identified: [...]. Please confirm scope before I continue."*

**Document convention:** single CURRENT_VERSION file per system;
superseded versions get renamed to `<NAME>_<YYYY-MM-DD>_V<n>.md` and
archived, never deleted.

**Build command — always:**
```
flutter run --profile -d <device-id>
```
Never plain `flutter run` — iOS kills debug builds the moment the
cable is unplugged, which looks like random crashes but isn't.

**Verification discipline used throughout this build:** no `flutter
analyze` available in this sandbox — brace/paren/bracket balance is
checked manually via a small Python counter run through the shell
tool after every non-trivial file edit.

---

## 5. Immediate Next Steps (pick up here)

Nothing is mid-flight — the last completed unit of work was the fake
Browse-candidate photo population. Good next steps, in rough priority
order, all previously surfaced but not yet built:

1. Guardian-side Family Stage answering UI (currently Seeker-only).
2. A real notification system (blocks several Journey/Suspension
   requirements that are currently silently skipped).
3. The 24-hour cooling period after End Journey.
4. Documentation for `SOURCE/lib/widgets/`.
5. Wiring `subscriptions.plan_type = 'wali_premium'` into real
   Extended Guardian gating (replacing the local mock toggle).
6. Real payment processing (App Store / Play Store IAP, or Stripe for
   web) — currently entirely mocked.

---

*End of handover. Everything above is grounded in the actual repo
state as of 2026-07-25 — check `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md`
and `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` directly for
full detail on any item referenced here.*
