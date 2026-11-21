---
id: DOC-ZYRA-0481
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 31 - the admin-only Developer panel (opened by tapping a page title) that loads sample Journeys, Ended Journeys, Journey requests and Introductions on the admin account only
links: [OA-ZYRA-325, AD-AIOS-115]
owner: ZYRA chat
---

# DEVELOPER PANEL — SPEC — V1 (LOCKED 12 NOV 2026)

## Why this exists, and what it replaces
On 30 Oct the Founder removed **every** developer control ("Absolutely everything", queue line 44, BUILT). On 12 Nov the
Founder asked for one developer section back: **"i need codex to remake toggle section for developer only with
[the ZYRA admin account's email] email only. and the toggle lives if i clikc on title … options to have 3 journeries, ened journey-journey
request send recvived-past/ introductions"**. This spec is that one panel only. Everything else line 44 removed (role, plan,
wallet switchers, the control rail, page/design option pickers, scenario panels, developer sign-up shortcuts) **stays removed**.

Reference: prototype V204 (private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V226.html`):
tap any page title on the Seeker side. No master pictures (charter rule 13); layout from the app's existing ivory bottom
sheet (LOCK 28 sheet, APP COLOURS V8).

## 1. Who sees it
| Rule | Detail |
|---|---|
| Account | Only the signed-in **ZYRA admin account** (address held privately; not written in the repo). Authority is the **server role claim** (`zyra_role` in Supabase `app_metadata`, which only a trusted server context can set — `lib/services/zyra_developer_access.dart`), never the email text in the app |
| Builds | **Every build** — Xcode, TestFlight and the App Store app — but only for that account (Founder 12 Nov: "Every build, admin only") |
| Everyone else | Nothing changes: the title is not tappable, no hint, no extra semantics, no `dev_` keys in the tree |

## 2. Opening and closing
| Item | Rule |
|---|---|
| Open | Tap the **page title** (the large heading, e.g. Profiles, Journey, My ZYRA, Guardian, Profile, Journey requests, Introductions, Ended Journeys) on any Seeker page |
| Sheet | Ivory bottom sheet, dimmed backdrop, grabber; scrolls if taller than the screen (max ~88 % of the height) |
| Close | **Done**, tapping the backdrop, or swiping down. The page underneath shows the new data at once |

## 3. Contents (top to bottom)
| Part | Detail |
|---|---|
| Title | **Developer** (21 pt light) |
| Account line | `<the signed-in admin email> · <plan>` (the account's **real** plan, e.g. Seeker One) / **Sample data on this account only. Members never see it.** |
| JOURNEYS | **Active Journeys** — segmented 0 · 1 · 2 · 3, small line "Seeker One has 3 places" / "Seeker Basic has 1 place"; numbers above the plan's places are disabled. **Ended Journeys** — 0 · 1 · 2 · 3 |
| JOURNEY REQUESTS | **Received** 0 · 1 · 2 · 3 · **Sent** 0 · 1 · 2 · 3 · **Past** None · Mixed · Same person (small line: "“Same person” = 20 requests to Sara") |
| INTRODUCTIONS | **From your Guardians** 0 · 1 · 2 · 3 |
| Reset | Plain row button **Clear sample data** → every control back to the account's real data (nothing sample left anywhere); toast "Sample data cleared." |
| Done | Pill button **Done** |
Section labels: 10 pt caps, letter-spaced, dark gold (APP COLOURS V8 ivory gold text). Segmented control: one rounded
track, selected value on a raised ivory pill.

## 4. What each control does (it must be real, not a picture)
| Control | Effect |
|---|---|
| Active Journeys n | The Journey tab, My ZYRA ("n of 3 places in use"), Guardian tab and request capacity all read n sample Journeys at their sample stages |
| Ended Journeys n | Ended Journeys page lists n sample ended Journeys (each with ••• → Request a new Journey / Remove from my Journeys, TIME_RULES line 93 step 5b) and the My ZYRA Ended Journeys count |
| Received / Sent n | Journey requests Received / Sent tabs, My ZYRA "Journey requests" count and Needs-you item use n sample requests; Accept, Decline, Cancel work on them as on real ones |
| Past | None = empty state; Mixed = one "You declined" + one "Not taken up"; Same person = Mixed plus **20** "Not taken up" requests to Sara about three weeks apart (shows the grouped card, LOCK 2 V3 §2.2, and the 30-day ask-again date) |
| Introductions n | Introductions page lists n sample introductions (photo, name, "Put forward by <Guardian> · <relation>", newest "New introduction" in gold, older "Introduced <date>"; tap opens the profile) and the My ZYRA count |
Defaults when the panel first opens = the account's real data. Choices stay until changed or **Clear sample data**;
signing out clears them.

## 5. Where the sample data lives
Founder 12 Nov: **"App sample data now"** — Journeys and Journey requests do not exist on the server yet (SERVER 1). Sample
data is held by the app for the admin account only and is never written to shared tables or shown to anyone else. When
SERVER 1 lands, the same controls create and remove **real test records** owned by the admin account (Fable designs that
server part; logged in QUESTIONS).

## 6. Must not change
Member screens, words and behaviour for every non-admin account; LOCK tests; the line 44 release-safety test still fails if
any developer control is reachable for a non-admin account.

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-11-12 | V1 | LOCKed by the Founder (`LOCK_RECORD.md`, LOCK 31) |
