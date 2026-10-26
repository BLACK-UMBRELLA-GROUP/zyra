---
id: DOC-ZYRA-0296
type: SPEC
status: DRAFT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 2 (Onboarding) - how a new member gets in - welcome, choosing Seeker or Guardian first, sign-in, account essentials, first photo, membership choice, the identity check, the profile chapters, consent, the Bio, completeness and publishing - checked against production and decisions
links: [OA-ZYRA-309, OA-ZYRA-317, DOC-ZYRA-0294, DOC-ZYRA-0295, DOC-ZYRA-0291]
owner: Fable
---

# ZYRA BLUEPRINT — PART 2 — ONBOARDING RULES — V1 (DRAFT)

Status: **DRAFT for Shakeel.** Written 26 Oct 2026 from the sign-up screens (`screens/auth/`, `screens/onboarding/`,
`screens/wali/wali_onboarding_flow.dart`) — the planned app reuses them; its own sign-up pages are previews — and the server.
Last column checked against **production** (DOC-ZYRA-0294): **Live** · **Not live** · **Missing**.

## In one paragraph

Onboarding is **progressive**: a short account setup gets you in, and the longer profile is finished inside the app. You choose
which side you need **first** (Seeker or Guardian), sign in with **Google or Apple**, give your **names, gender and date of
birth**, add your **first photo** (Seekers), choose a **membership**, and pass the **identity check**. The app then opens. From
inside it you complete **Chapter 2 (Your Profile)**, give **explicit consent** before the faith and background questions, answer
the **compatibility questions** (about you, then your preferences as green / amber / red), optionally write your **Journey Bio**,
and finally **publish** your profile. Until you publish, nobody can see or match with you.

## 1. Steps

| # | Step | What happens | Decision | Server |
|---|---|---|---|---|
| 1 | Welcome | Splash and welcome slides, including one about the identity check | DR-ZYRA-256, DR-ZYRA-259 | app |
| 2 | Choose first | "Which ZYRA experience do you need first?" — Seeker or Guardian; not a permanent account type | Founder 19 Aug; DR-ZYRA-285 (both roles on one login) | **Different** — server still one role per account |
| 3 | Sign in | Google or Apple; one account with linked sign-in methods | DR-ZYRA-209 | **Live** |
| 4 | Account essentials | First name (and surname line), gender, date of birth (18+); Guardians also give their relationship | DR-ZYRA-252, DR-ZYRA-081 | **Live** — `zyra_create_profile`, minimum-age check |
| 5 | First photo (Seekers) | One photo before the membership choice | DR-ZYRA-264 | **Live** (photo rows) |
| 6 | Membership choice | Basic or One for the chosen role; choosing never charges, starts a trial or verifies | DR-ZYRA-252 | **Missing** — no purchases (OA-ZYRA-317 7) |
| 7 | Identity check | Document, selfie liveness and face match (Sumsub), mandatory; the app does not open until verified | DR-ZYRA-221, DR-ZYRA-220 | storage and functions **Live**; provider **Missing**; production switch **off** |
| 8 | App opens | Seekers see an overview of what is left; the longer profile can wait | DR-ZYRA-286 (progressive onboarding) | app |
| 9 | Chapter 2 — Your Profile | Photos (3–6), location, sect, revert status, country of birth, nationality, ethnicity, languages; each: about you → what you want → how flexible, with optional hard requirements | DR-ZYRA-082, DR-ZYRA-250 | **Live** — `onboarding_answers`, question bank |
| 10 | Special-category consent | Explicit consent just before faith and background questions; without it those answers are not saved | Founder 4 Aug | **Live** — `consents` |
| 11 | Compatibility | Part 1: every private "about you" question in 11 sections; Part 2: the same sections as partner preferences — green (prefer), amber (open to), red (not for me) | DR-ZYRA-250, DR-ZYRA-262 | **Live** — 105 questions in the bank; `zyra_question_is_due` |
| 12 | Journey Bio (optional) | Structured facts written for the Journey Bio, never copied from private answers | DR-ZYRA-280 §5 | app; Bio reveal step **Missing** on the server |
| 13 | Ready and publish | A final review; publishing is an explicit action; visiting the page never completes anything | — | **Live** — `zyra_set_profile_complete`, completeness functions |

## 2. Rules across onboarding

| Rule | Decision | Server |
|---|---|---|
| Nobody can see, match or request you until your profile is complete **and** published | — | **Live** — `profile_complete` gate in Browse and matching |
| Completeness is worked out by the server, never by the app | — | **Live** — `zyra_onboarding_complete`, `zyra_onboarding_missing`, `zyra_my_onboarding_progress` |
| Leaving an optional chapter is never a way round the identity check | DR-ZYRA-221 | app; server check **Live** for Guardian links, **app only** for Journeys (OA-ZYRA-315 a) |
| Once published, gender and date of birth are frozen | Founder 7 Aug | **Live** |
| Answers are private; only compatibility results and chosen public fields are shown | DR-ZYRA-250 | **Live** |
| Guardian onboarding: essentials, relationship, then linking by ZYRA Code | DR-ZYRA-081, DR-ZYRA-231 | **Live** |

## 3. Found while mapping

| # | Finding | Goes to |
|---|---|---|
| 1 | Progressive onboarding (26 Aug) had no recorded decision — only code comments | **Recorded 26 Oct as DR-ZYRA-286** |
| 2 | The identity check is the only thing standing between a new account and the app, and its production switch is off until Sumsub is connected — so today a new account opens the app unverified | Launch gate; OA-ZYRA-317 (8) |
| 3 | The old onboarding spec (`APP/Onboarding/…/Onboarding Rules & UX.md`) still describes gender-coloured backgrounds and older chapter shapes | Archive or rewrite with the clean-up of documents |

## 4. Decided 26 Oct

Progressive onboarding is recorded as **DR-ZYRA-286**.

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-26 | V1 | First draft, checked against production (OA-ZYRA-309) |
| 2026-10-26 | V1 | Progressive onboarding recorded (DR-ZYRA-286) |
