---
id: DOC-ZYRA-SIGNUP-V1
type: SPEC
status: CURRENT
feature: SIGN UP
purpose: Spec for LOCK 34 - splash, Apple/Google account creation, sign-up steps, identity check before membership, setup continuation, verified-only rules
owner: ZYRA chat
---

# SIGN UP — SPEC — V1 (LOCKED 18 NOV 2026)

Founder 18 Nov (prototype comments 19:22–21:43, prototype V271 at `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V271.html`), locked with "Yes, lock and queue both (Recommended)" as an exception to AD-AIOS-149 (fixes only), built in the Founder preview on sample data like the rest of the planned app.

## 1. Rules
| Rule | Detail |
|---|---|
| Accounts | Created **only** with Sign in with Apple or Google. No email sign-up, no recovery email (line 120). |
| Button order | iPhone: Apple first, Google second. Android: Google first, Apple second. |
| Verified only | Every person who sees or is seen on ZYRA is verified. Until the identity check passes: Profiles (Seeker) and Network (Guardian) show the gate page (§3.9); the member is not shown to anyone. |
| Pay after verify | The membership step only appears after the identity check passes. No payment or trial can start before. Seeker One trial (14 days) starts only after verification. |
| Journeys need setup | A Journey cannot be requested until setup (§3.8) is complete; Request a Journey says "Finish setting up your profile to start a Journey." |
| Style | Every step: thin gold progress bar with ‹ Back; content in one full-height ivory card (shared card surface, line 114); gold primary button at the bottom; no dead space. Choice steps use full-height swipe cards with dots (Guardian page style): the card swiped to is the choice (no Choose button) and the bottom button follows it. |
| Errors | A wrong entry turns its box red (1.5 pt #AC453E border, light red tint) with one plain line saying what to fix. Primary button stays disabled until valid. |

## 2. Order
Seeker: Splash → Welcome → Seeker or Guardian → Name → Date of birth → Gender → Where do you live? → Nationality → Ethnicity → Photos → Verify your identity → (if verified) Choose your membership → Account ready.
Guardian: Splash → Welcome → Seeker or Guardian → Name → Date of birth → Who are you to your Seeker? → Add your Seeker → Verify your identity → Account ready.
Setup (after "Finish setting up"): Seeker: the **full Partner preferences check** (the existing Partner preferences pages: categories → questions with Prefer / Open to this / Not for me — every item those pages show this member) with a dark setup bar at the bottom "Setting up · Partner preferences · n/N answered" + **Finish later** + **Next ›** → A few words about you → Add a Guardian → You're all set. (Founder 18 Nov: "the finish set up should start the whole preference check".) The age-range-only step is removed. Guardian: A few words about you → You're all set.

## 3. Screens
| # | Screen | Content |
|---|---|---|
| 3.1 | Splash (about 1 s) | Gold **ZYRA** wordmark (wide letter-spacing), "Connecting Through Trust", thin line. Then Welcome. |
| 3.2 | Welcome | Wordmark + "Connecting Through Trust"; two dark espresso pill buttons "Continue with Apple" / "Continue with Google" (order per §1). Nothing else. |
| 3.3 | How will you use ZYRA? | "Swipe to the one that fits you. You can add the other role later." Two swipe cards: **Seeker** (S, LOOKING FOR A SPOUSE: Build your profile and photos · Send and receive Journey requests · Bring your Guardians into each Journey) and **Guardian** (G, SUPPORTING A FAMILY MEMBER: Link to your Seeker with their ZYRA Code · See their Journeys as they allow · Lead Family Review as Main Guardian). |
| 3.4 | Your name | Filled in from Apple/Google ("Filled in from your Apple account. Check it's right; you can change it."). First name max 30, surname max 40 (LOCK 33) with a live count inside each box ("0/30", gold at limit). |
| 3.5 | Date of birth | DD / MM / YYYY boxes. "ZYRA is for adults aged 18 and over. Your identity check confirms it later." Errors: day 1–31, month 1–12, year 4 digits 1926–current ("Enter your year of birth in full, for example 1997."), under 18 ("You need to be 18 or over to join ZYRA.", all three red). Apple and Google do not supply a date of birth. |
| 3.6 | Gender | Title "Gender"; two large cards filling the page: **Male** (M) and **Female** (F); chosen card gold outline + "✓ CHOSEN". |
| 3.7 | Location / Nationality / Ethnicity | Three separate pages, each a type-to-search box filtering a list (max 6 shown, "No match. Try another spelling."). Location and Nationality: one answer. Ethnicity: several (chosen show as gold chips with ✕ and ticks in the list). |
| 3.7b | Photos | 6 spaces, at least 1; first photo = profile picture everywhere (PROFILE_TAB V4 §7). |
| 3.8 | Verify your identity | "Every member is checked so families can trust who they meet. It takes about 2 minutes." Steps: 1 photo of passport or driving licence · 2 short selfie video · 3 we confirm your name and that you're 18 or over. **Verify now** / **Do this later** ("You can look around, but profiles stay hidden and membership can't start until you're verified. No one sees you either."). Provider: the existing identity-check integration. |
| 3.8b | Choose your membership (verified only) | Card circles read **BASIC** and **ONE** in words (Founder 18 Nov: "its ONE NOT 1"), never the digit 1. Swipe cards Seeker Basic (£4.99 once: 1 Journey place · 25 profiles every 4 hours · 10 Guardians, 1 on the free place) and Seeker One (14 days free, then £29.99 a month: 3 Journey places · Unlimited profiles and all filters · 10 Guardians on any plan). Button follows the card: "Pay £4.99 for Seeker Basic" / "Start 14 days free, then £29.99 a month". Checkout until purchases exist: the existing "not available in this build" behaviour. |
| 3.8c | Account ready | Monogram, "Welcome, <first name>", "Your account is ready. Here's what's left." Checklist (green tick when done): Identity check · Photos · Partner preferences ("Set any time in Profile") · Guardians ("Optional · add any time"); Guardian: Identity check · Your Seeker linked. Buttons **Finish setting up** (gold) and **Look around first**; line "You need a finished profile to start a Journey." |
| 3.8d | Setup steps | One sequence (QUESTIONS 167, matches §2). **Seeker:** (1) the full Partner preferences check (existing pages, every item they show this member; answers save as they are given; dark setup bar "Setting up · Partner preferences · n/N answered" with **Finish later** and **Next ›**; Next › is available at any count, unanswered ones stay open in Profile → Partner preferences) → (2) A few words about you → (3) Add a Guardian → (4) You're all set. **Guardian:** A few words about you → You're all set. **Count (QUESTIONS 172):** N is the actual applicable total — the same items, gender filter and conditional hiding the existing Partner preferences pages already use, counted in the same unit; N updates when a controlling answer hides or shows items. Never a fixed 320, never omit items. Master s26 shows the male-Seeker sample (N = 320); a female Seeker sees her own N. **Completion:** setup is complete when You're all set is reached (Enter ZYRA); only then can a Journey be requested. **Resume:** Finish later (bar) or "Finish later and go to ZYRA" opens My ZYRA with the Needs you card (§3.9); **Continue setting up** returns to the step left (to Partner preferences if paused there). There is no age-range-only step. Screen details: A few words about you (300 characters, live count) · Add a Guardian (your ZYRA Code + Share my code; "You can also do this later from the Guardian tab.") · You're all set (green tick, "Your profile is complete. You can now start Journeys.", Enter ZYRA → My ZYRA). Under the button on every setup step **except You're all set** (its own button is Enter ZYRA): **Finish later and go to ZYRA** (QUESTIONS 170). |
| 3.9 | Paused setup / gates | Paused: My ZYRA Needs you card "Finish setting up · You can't start a Journey until your profile is complete. It only takes a few minutes." → **Continue setting up** returns to the step left. Unverified gate (Profiles / Network): shield circle, "VERIFIED MEMBERS ONLY", "Every person on ZYRA is verified", "Verify your identity to see profiles, to be seen, and to choose your membership. It takes about 2 minutes.", **Verify now**. |

## 4. Not in this version
Adverts (pending). Security / account recovery (Founder: "we will talk security further down line").

## 5. Version history
| Version | Date | Change |
|---|---|---|
| V1 | 2026-11-18 | First version (LOCK 34) |
| V1 | 2026-11-19 | QUESTIONS 172: setup bar count = actual applicable total n/N (existing filters), not a fixed 320. No design change |
| V1 | 2026-11-19 | Correction after Codex preflight (QUESTIONS 170): s13 re-rendered (chosen state); Finish later not on You're all set; Back exceptions written. No design change |
| V1 | 2026-11-18 | Correction after Codex preflight (QUESTIONS 166/167): §3.8d one setup sequence with completion and resume; §6 masters (41). No design change |

## 6. Masters (QUESTIONS 166, 18 Nov)
Rendered 430 × 932 @3x from prototype V275 (same sign-up as LOCKed V271), folder `SIGN_UP/MASTERS/`:
| Files | Covers |
|---|---|
| s01 | Splash |
| s02, s03 | Welcome — iPhone (Apple first), Android (Google first) |
| s04, s05 | Seeker or Guardian swipe cards |
| s06, s07 | Name filled from Apple; empty (button disabled) |
| s08–s11 | Date of birth empty, filled, year error, under 18 |
| s12, s13 | Gender none / Male chosen |
| s14, s15, s16 | Location empty and chosen; Nationality chosen |
| s17, s18 | Ethnicity several / empty |
| s19, s20 | Photos empty / two |
| s21 | Verify your identity |
| s22, s23 | Membership — Seeker One / Seeker Basic card (button follows the card) |
| s24, s25 | Account ready — verified / not verified |
| s26–s29 | Setup: Partner preferences with setup bar · A few words about you · Add a Guardian · You're all set |
| s30, s31 | Paused setup (My ZYRA Needs you) · Unverified gate (Profiles) |
| s91, s92 | Error states: offline, server — the existing app error page (unchanged shared state; "Demo: connection comes back" is a prototype-only hint, not app text) |
| g01–g08 | Guardian path: name, relationship empty/chosen, Add your Seeker, verify, account ready, setup about you, all set |
Loading: no sign-up step loads ZYRA data except Apple/Google sign-in and the identity check, which use their own system screens; any wait uses the existing loading spinner (unchanged shared state). Empty states are the empty step masters above. Navigation (QUESTIONS 170, as LOCKed prototype V271): ‹ Back returns one step on every step **except** Splash, Account ready, and the **first setup page** (A few words about you) — setup starts a new sequence from Account ready, so its way out is Finish later and go to ZYRA; You're all set keeps ‹ Back. Skip appears in the preview only. Gender master s13 re-rendered 19 Nov with the gold outline and "✓ CHOSEN" (the 18 Nov picture used a wrong sample value).
