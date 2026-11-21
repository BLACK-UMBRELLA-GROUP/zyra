---
id: DOC-ZYRA-0481
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 31 - the admin-only Developer panel (opened by tapping a page title) that loads sample Journeys, Ended Journeys, Journey requests and Introductions on the admin account only
links: [OA-ZYRA-325, AD-AIOS-115]
owner: ZYRA chat
---

# DEVELOPER PANEL — SPEC — V2 (LOCKED 12 NOV 2026 · V2 18 NOV 2026)

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

## 7. V2 additions (LOCKED 18 NOV 2026)
Founder 18 Nov 22:02: "in app i need that toggle button back so i can choose a active journey to test - deep check the toggle and get codex to add it again and check what would be needed in toggle inc sign up and the different options in the prototype and i need that in app for me to test it". This extends §2 and relaxes §6's line-44 exclusion **for the admin account only**: the plan/role view and sign-up shortcuts the Founder now asks for come back inside this one panel. Members still see nothing.

### 7.1 Where it opens (deep check found gaps)
| Rule | Detail |
|---|---|
| Every page title | Tapping the large page title opens the panel on **every** page of the planned app (Founder preview): Profiles, Journey, My ZYRA, Guardian, Profile and every page opened from them, **Seeker and Guardian sides**. V1 is wired mainly in old-app screens and the My ZYRA dashboard; most planned-app titles are not wrapped. Codex lists every title wired in the as-built record. |
| Fallback | Pages without a title (sign-up steps): long-press the progress bar. |

### 7.2 Contents V2 (top to bottom)
| Section | Controls | Effect (real, on sample data for the admin account only) |
|---|---|---|
| VIEW AS | Seeker One · Seeker Basic · Guardian One · Guardian Basic | The whole preview switches role and plan (tabs, limits, locks, upgrade prompts). The real account and server plan are unchanged; the account line shows "Viewing as <plan> · real plan <plan>". |
| SIGN UP | **Start sign-up** (runs LOCK 34 from the splash; no account is created; ends back in the preview) · **Unverified** on/off (Profiles / Network gate, LOCK 34 §3.9) · **Setup unfinished** on/off (Journey requests blocked, Needs you "Finish setting up") | As in LOCK 34 |
| JOURNEYS | **Active Journeys** 0–3 (capped by the viewed plan's places) · **Open Journey** picker listing each sample Journey (Sara, Maryam, Noor) · **Stage** picker for the chosen Journey: every Journey stage the app has, in the app's order · **Ended Journeys** 0–3 | Choosing a Journey and stage opens that Journey on the Journey tab at that stage |
| JOURNEY REQUESTS | Received 0–3 · Sent 0–3 · Past None / Mixed / Same person (V1) | As V1 |
| INTRODUCTIONS | From your Guardians 0–3 (V1) | As V1 |
| MY ZYRA | Preset: All caught up · Typical day · New member · Everything | Fills Needs you with that sample set (same sets as the prototype) |
| NOTICES | 2-year inactivity: None · email 1–5 · Welcome back (LOCK 32) | Shows that state and its email preview |
| ERROR PAGES | Phone offline · ZYRA server down · Session ended | Opens the shared error page for that case; its Try again returns to the preview |
| Reset | **Clear sample data** | Everything above back to the real account and real data; View as = real plan; Unverified / Setup off |
| Done | Pill | Closes |

### 7.3 Rules kept
Admin account only via the server role claim; every build; nothing for members; release-safety test extended to every new control; defaults = real account; choices persist until changed, Clear sample data or sign-out.

### 7.4 Clarifications (QUESTIONS 171, 173, 174 — 19 Nov, ZYRA chat)
| Item | Rule |
|---|---|
| Setup unfinished before line 121 (Q171) | The switch ships in line 123 with the **gate only**: Request a Journey says "Finish setting up your profile to start a Journey." The My ZYRA **Finish setting up** card and its **Continue setting up** button depend on line 121 and are added with it (resume = the saved setup step, LOCK 34 §3.8d/3.9). Until then the **Everything** preset leaves that one card out; all its other items stay. |
| No real membership (Q173) | If the admin account has no active membership (or it can't be read), the preview starts as **Seeker One** sample data and the account line says honestly **"Viewing as Seeker One · real plan: none"**. Clear sample data returns to this same start. No new no-membership layout; nothing is granted on the server. |
| Guardian and NOTICES (Q174) | LOCK 32 applies only to accounts **that have Ended Journeys** (Inactivity spec §1 "Who"); Guardian accounts have none of their own, so they never get the 2-year emails or Welcome back. When View as is Guardian One or Guardian Basic, the **NOTICES** row is not shown. No Guardian archive, no role switch, no other member's history. |

## Change log (V2)
| 2026-11-18 | V2 | §7: every page title on both sides; View as, Sign up, Journey and stage pickers, My ZYRA presets, notices, error pages (Founder 22:02) |
| 2026-11-19 | V2 | §7.4 clarifications after Codex preflight (QUESTIONS 171, 173, 174). No design change |
