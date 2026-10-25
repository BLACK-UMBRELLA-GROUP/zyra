# ZYRA — Full Application Review

**Date:** 2026-08-13
**Scope:** Female Seeker · Male Seeker · Guardian
**Baseline:** Female Seeker, unchanged except where a bug was confirmed
**Method:** static read of 122 Dart files, live database queried directly, `zyra_check.py`

---

## The headline

> **There is no "Male Seeker design". There is one Seeker codebase.**

The only gender-conditional UI in the entire app is `ZyraColors.genderGradient()` — 49 call sites, all of which swap a background gradient. Every other `gender ==` branch in `lib/screens/` is pronoun or label copy, not layout, spacing, or component choice.

The database is symmetric too:

| role | gender | profiles | no photos | no DOB | no city | incomplete |
|---|---|---|---|---|---|---|
| seeker | female | 72 | 0 | 0 | 0 | 0 |
| seeker | male | 72 | 0 | 0 | 0 | 0 |

So the errors you saw on Male Seeker are **not** an older design and **not** missing data. They are a real defect that is *invisible* on the Female account — which is a more useful thing to have found, because it means the female baseline is where this class of bug hides, not where it is absent.

---

## 1 · Why Male Seeker broke and Female Seeker did not

**Root cause: `main.dart` froze the theme colour at launch from the *previous* session's cached gender.**

- `main.dart:34` — `AppState.instance.gender = ZyraLocalPrefs.cachedGender` (last session's value, read before the network)
- `main.dart:166` — `scaffoldBackgroundColor: genderGradient(AppState.instance.gender).colors.first`
- `ZyraApp` is a **StatelessWidget**, so `ThemeData` is built once and never rebuilt

The live gradient below it *does* track gender through a `ListenableBuilder`. The theme did not. After any sign-in or Developer Access switch the two disagreed for the rest of the process.

**Why that is male-only in practice:** launch with a female account cached, switch to a male one, and every gap where a `Scaffold` shows through paints Rose Pink `#D4868F` behind Royal Blue chrome. Test female → female and it is pink on pink. The bug was never male-specific — it is **switch-specific**, and the female baseline is where it is invisible.

This was already known and open as **OA-ZYRA-212**, raised yesterday from the Guardian Network pink-flash fix. It is now closed.

**Two contributing defects, both fixed:**

- `AppState.applyDevPreset` was the only gender writer in the class that did not update the disk cache — so a Developer Access switch changed the live gender and left the cache holding the previous account. The *next* cold start then opened in the wrong gradient.
- `accept_wali_invite_screen.dart` painted its gradient into a `Container` with no expand constraint above a `SingleChildScrollView`, so it shrank to content height and left a band of bare Scaffold — the exact bug fixed in `report_profile_sheet.dart` on 2026-08-03, whose own note warned "every future screen built on `SingleChildScrollView` would inherit the same band". This screen became scrollable three days *after* that warning.

---

## 2 · Completed fixes

| # | Fix | Class |
|---|---|---|
| 1 | `scaffoldBackgroundColor` → `Colors.transparent`; the live gradient behind every route is now the only source | **BUG** — closes OA-ZYRA-212 |
| 2 | `applyDevPreset` writes the gender cache it sets | **BUG** |
| 3 | `accept_wali_invite_screen` gradient fills its box | **BUG** |
| 4 | Connections → Introductions shows a spinner instead of "No introductions yet" during the first fetch | **BUG** |
| 5 | `app_lock_screen` spinner was the only one in the app with no colour — painted Material theme-primary on a gradient | **BUG** |
| 6 | `seeker_wali_tab` "Guardians" title jumped 4px when the first Guardian linked (empty branch padded 8, populated 4) | **BUG** |
| 7 | Mock Guardian dashboard added to the dev toggle | **TOGGLE ONLY** |

Fix 1 is chosen deliberately over "rebuild the theme on gender change". The `builder:` wrapper already paints the live gradient behind every route, so a second copy of that colour in the theme can only ever be a copy that goes stale. This removes the class of bug rather than keeping two values in step.

---

## 3 · Bugs found and NOT fixed

Each needs a decision or is too large to do blind.

| Finding | Evidence | Class |
|---|---|---|
| **Duplicate question id `ch3_q26`** — two questions share one id, differing only by `genderVisibility` and with *different option lists*. Answers are stored in a single flat map keyed by id. The **server was already fixed** for this (`20260811172021_fix_question_is_due_multi_variant_qid.sql`: "assumed one row per qid; ch3_q26 has two gender variants"); the client never was. A male answers 104 questions, a female 103. | `chapter3_categories.dart:187,194` | **BUG — verify on device** |
| **Null gender hides both variants** of `ch3_q26`, so a required question silently disappears and the completeness gate can never be satisfied | `onboarding_question.dart:100-108` | **BUG — verify** |
| **Two opposite-gender helpers disagree on their default** — discovery defaults unknown → male targets, the dev scenario defaults unknown → female counterparts. Both are fed from different sources in one call. | `zyra_discovery_service.dart:83`, `zyra_dev_scenario.dart:724`, used together at `connections_screen.dart:452` | **MODIFY** |
| **Every Guardian created in-app is written `gender: 'male'`** regardless of who they are | `zyra_profile_service.dart:116` | **BUG** |
| **Pronoun ternaries fall through to one gender** — `'male' ? "He'll" : "She'll"`. The one correct version in the codebase uses `_ => 'their'` and its own comment names this exact trap: *"reads correctly for exactly half the users… the kind of bug that survives testing on one account."* | `connections_screen.dart:1018,3896`, `journey_flow_screen.dart:1992`, `profile_screen.dart:317` | **MODIFY** |
| **Additional Guardians see no Journeys at all** | already raised | OA-ZYRA-213 |

---

## 4 · UI inconsistencies

Ranked by how visible each is. **None of these are gendered** — they are cross-screen drift.

1. **`GlassIconButton` is effectively dead** — one call site app-wide, and its doc comment still names two that no longer exist. Back/close is hand-rolled **four different ways**, including a bare `IconButton` on a full-bleed photo with no chrome at all (`seeker_profile_screen.dart:243`).
2. **Settings still uses Material `AlertDialog`** — 10 of them, each with a hardcoded opaque background, while the rest of the app uses the ratified glass modal. An abandoned migration.
3. **Connections has no loading state** — 4,349 lines, the busiest tab, zero `ZyraLoading` before today's fix. Partially addressed; the other two segments still start empty.
4. **Browse's empty state is hand-rolled** and measurably different from the shared one: icon 32 vs 30, title 18 vs 15, padding 32 vs 36. Two adjacent tabs, near-identical copy, different rendering.
5. **The Profile tab is the most drifted screen** — no title, no `ZyraProfileNameBlock`, no `ZyraCardMetrics`, no loading or empty states, and inset 24px where every other tab is 20. The left edge visibly misaligns when you swipe to it.
6. **11 `CircularProgressIndicator` remain**, at 5 different sizes, 2 stroke widths and 4 colours — one inside a *shared widget*, so it leaks everywhere.
7. **No shared pill/chip** — at least 5 implementations, fill alpha ranging .10→.22 and border .18→.42 for the same visual object.
8. **`ZyraCardMetrics` — the design-token class — lives inside a 4,349-line screen file** and is imported from there by four other screens.
9. **Colour literals outside the theme**: 6 exact duplicates of existing tokens, plus **three unrelated red/amber/green triads** and two different destructive reds (`0xFFE08080` and `0xFFB33A3A`).
10. **Header standard is observed on the Guardian side, not the Seeker side** — `fromLTRB(20,16,20,8)` + `heading(26)` appears in 4 files, 3 of them Wali screens.

---

## 5 · Guardian review

### What is real

Journey detail is the strongest Guardian surface and is fully built — stage, counterpart card, Family Review with live countdown, Family Stage answering, Timeline, read-only conversation. Invite/accept both work bidirectionally. Network gating reads a real entitlement.

### What is ratified but has no UI

| Capability | State |
|---|---|
| Suggest a profile to your Seeker | generated data model, **no create UI** |
| See what you put forward | OA-ZYRA-214 |
| Guardian AI Summary | generated — and rendered on the **Seeker's** screen captioned "would be shared", because no Guardian surface can receive it |
| Family Review notifications | must open the Journey to discover a decision is waiting |
| Raise a concern | no Guardian-side route |

### Blocked on a decision or schema

Invitations received (`wali_invites` has no recipient column) · Network Discover/Requests (no data exists) · invite delivery by SMS/email (no backend) · Browse-stage visibility (out of scope by decision).

### Guardian UI conformance

`ZyraProfileNameBlock` and `GlassIconButton` have **zero usages anywhere under `lib/screens/wali/`**. Every Guardian card is hand-rolled except two that borrow only `ZyraCardMetrics.cardRadius`.

Worst offenders: `wali_dashboard_screen` (bespoke Journey card, hand-rolled pill, ward rows with no card at all), `wali_seekers_screen` (no loading state despite an async fetch, hand-rolled `+`), `wali_profile_screen` (nothing shared but `ZyraText`).

**Two documentation defects found:** `wali_home_shell.dart:1` says "fixed 4-tab navigation" and ships 5; `WALI_ARCHITECTURE_V6:503` still says 4. And `journey_flow_screen.dart:29` still claims "Guardian app has no Journey visibility built at all" — that screen exists and is the richest one they have.

---

## 6 · Developer toggle

Now covers Female Seeker, Male Seeker and Guardian. The Guardian panel stages wards, Journeys, stage, Family Review, role, sent invitations and the unread badge — each with a named reader — and refuses the two that have none.

**Added this pass:** a **Guardian dashboard preview**, reachable from the panel, showing what the dashboard could hold with every section marked **BUILT**, **DESIGNED** or **BLOCKED**. It reads the panel's own staged state, so moving a stepper moves the preview. It writes nothing and no route in the real app reaches it.

The status labels carry their word, not just a colour — a status told only in hue is one nobody colour-blind can read.

**Still missing from the toggle:** Guardian profile scenarios (verification, photo, completion) have no reader to drive — building the toggle first would be a flag against nothing.

---

## 7 · Recommended next steps

Ordered by value per unit of risk.

| # | Action | Class |
|---|---|---|
| 1 | Verify the `ch3_q26` duplicate id on a male account through onboarding — the server thought this was worth a migration | **BUG** |
| 2 | Fix `zyra_profile_service.dart:116` — stop writing every Guardian as male | **BUG** |
| 3 | Give the two opposite-gender helpers one shared definition and one default | **MODIFY** |
| 4 | Pronouns → `their` everywhere, following the one correct implementation | **MODIFY** |
| 5 | Move `ZyraCardMetrics` out of `connections_screen.dart` into `lib/theme/` | **MODIFY** |
| 6 | One shared pill widget; retire the 5 | **MODIFY** |
| 7 | Finish the `ZyraLoading` migration — start with the one in a shared widget | **MODIFY** |
| 8 | Finish the glass-dialog migration in Settings | **MODIFY** |
| 9 | Bring `wali_dashboard_screen` onto `ZyraCardMetrics` + `ZyraProfileNameBlock` | **MODIFY** |
| 10 | Decide OA-ZYRA-213 (Additional Guardians see nothing) | **DECISION** |
| 11 | Tokenise the duplicated colour literals; reconcile the two destructive reds | **MODIFY** |
| 12 | Correct the three stale doc comments found | **MODIFY** |
| 13 | Guardian suggestion create-UI | **FUTURE** |
| 14 | Guardian AI Summary delivery | **FUTURE** |
| 15 | Network content, invite delivery | **FUTURE** |

### What I deliberately did not do

You said not to change the Female Seeker experience without a confirmed bug. Because the Seeker screens are **shared**, items 4–11 above would all change the female baseline. They are real inconsistencies, but they are redesign, not repair — so they are recommendations, not commits.

The one exception worth calling out: **fix 1 changes every screen in the app.** It had to, because the defect was in the theme. It removes a colour rather than adding one, and the live gradient behind every route is unchanged, so the female baseline should look identical. That is the thing most worth a careful look on device.
