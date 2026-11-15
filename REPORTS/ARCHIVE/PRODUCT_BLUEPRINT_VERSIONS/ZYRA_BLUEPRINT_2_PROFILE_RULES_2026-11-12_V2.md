---
id: DOC-ZYRA-0295
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 2 (Profile and account) - what a profile holds and who sees what, photos, identity freeze, edit and preview, Pause My Profile, hidden people, reset, delete, two roles on one login, sign-in and recovery, personalisation, notifications, App Lock, feedback - each marked against PRODUCTION (live check 26 Oct) and its decision
links: [OA-ZYRA-309, OA-ZYRA-317, DOC-ZYRA-0294, DOC-ZYRA-0278, DOC-ZYRA-0292]
owner: Fable
---

# ZYRA BLUEPRINT — PART 2 — PROFILE AND ACCOUNT RULES — V2 (CURRENT)

Status: **CURRENT - approved by the Founder, 26 Oct 2026** (all 14 blueprint pages, review pack DOC-ZYRA-0299). Building anything that breaks this page needs a new decision first. Written 26 Oct 2026 from the planned app's Profile tab and settings
(`zyra_one_journey_account_presentation.dart`, `zyra_one_journey_settings_details.dart`), the profile and photo screens it reuses,
and the server. **The last column is checked against production** (live check DOC-ZYRA-0294): **Live** · **Not live** (in a
repository file only) · **Missing** (nowhere).

## In one paragraph

A profile has **public details** (first name, age, city, bio and **3 to 6 photos**), details shown only after a Compatibility
Unlock, and **private answers** that are never shown (faith and background answers are special-category data with a consent
record). Once published, **gender and date of birth are frozen**. From the Profile tab you preview your profile as others see it,
edit it and your photos, manage membership, change the background, gold accents and haptics, set notifications and App Lock, and
reach help and feedback. You can **reset** your profile (answers and discovery history, keeping the account) or **delete** your
account. Two things in the planned app do not exist on the server yet: **Pause My Profile** (kept - hides your profile and stops new requests; current Journeys carry on, DR-ZYRA-290) and the **hidden people list**. One login
holding both a Seeker and a Guardian account is shown in the app but the server still allows one role per account.

## 1. What a profile holds, and who sees it

| Part | Who sees it | Decision | Server |
|---|---|---|---|
| First name (surname line optional), age (never the date of birth), city, bio | Everyone who can see you in Browse | — (DOC-ZYRA-0052 Profile Unlocks) | **Live** — raw date of birth hidden, age via `ages_for` |
| Photos (3 to 6; the first is added before choosing a membership) | Same, through private links | DR-ZYRA-085, DR-ZYRA-264 | **Live** — private bucket, signed links |
| Unlock details (background and faith detail) | Only after a Compatibility Unlock, or inside a Journey | DR-ZYRA-135, DR-ZYRA-250 | **Live** — `seeker_details_for_unlocked` |
| Private answers (onboarding questions) | Nobody; used only for compatibility | DR-ZYRA-250 | **Live** — functions only |
| Special-category consent (Article 9) recorded when answering | You | — | **Live** — `consents` table |
| Privacy labels on each field: **Public · Unlock · Private** | You, while editing | — | app (label words too faint — OA-ZYRA-314) |

## 2. Identity and photos

| Rule | Decision | Server |
|---|---|---|
| Once a profile is first published, **gender and date of birth can never change**; withdrawing yourself is always allowed | Founder 7 Aug ("identity freeze") | **Live** |
| First names are tidied (spaces trimmed) on every save | — | **Live** |
| At least 3 photos, up to 6; crop and adjust before upload | DR-ZYRA-096 | app; photo rows **Live** |
| Each photo row is tied to its owner's file | f03 (5 Oct) | **Not live** |
| Photo moderation before others see a photo | DR-ZYRA-096 | **Missing** — launch gate |

## 3. Profile tab actions

| Action | What it does | Decision | Server |
|---|---|---|---|
| Preview my profile | See yourself as others do | — | app |
| Edit profile, Photos | The existing editors | — | **Live** |
| Membership, subscriptions, Compatibility Unlocks | Membership page (DOC-ZYRA-0291) | DR-ZYRA-252, 282 | purchases **Missing** |
| Past Journeys | Read-only ended Journeys, 3 months | DR-ZYRA-268, 280 | read **Live**; 3-month limit **Missing** |
| Invite | Share ZYRA | — | app (share sheet) |
| Personalisation | Background (10 choices), gold accents, haptics — kept per account on the phone | Colour theme V2 | app |
| Notification settings | Choose which updates you get | DR-ZYRA-149, 154 | **Live** — `zyra_set_notification_preference` |
| Phone access (Settings → PRIVACY) | One page showing what ZYRA may use on the phone — Location, Notifications, Photos, Camera, Face ID — with why and the current state; a permission not yet asked goes straight to the iPhone prompt, one already decided opens ZYRA's iPhone Settings; Location is the approximate area; NEW until opened; never Contacts, microphone, tracking (LOCK 12 V2, DR-ZYRA-321; built 30 Oct, queue 40) | — | **Missing** — client only; purpose strings in the release checklist (OA-ZYRA-323) |
| App Lock | Face ID / passcode to open ZYRA | — | app |
| Sign-in and security | Google or Apple sign-in; one account with linked sign-in methods; a recovery email that needs no password | DR-ZYRA-209 | sign-in **Live**; recovery email change **Live** (email code) |
| Help, Feedback, Privacy policy, Terms | Help pages; feedback form; legal pages | DR-ZYRA-239 | feedback **Live** (`app_feedback`); legal text is a launch gate |
| Sign out | — | — | **Live** |

## 4. Visibility controls

| Control | What it does | Decision | Server |
|---|---|---|---|
| **Pause My Profile** | Take a break: your profile disappears from Browse and nobody can send you a new request. Journeys you are already in carry on as normal (there is no Journey pause); your account, Guardians, history and paid plan stay, and billing continues. Unpause any time | DR-ZYRA-290 | **Missing** — the app's functions exist nowhere |
| **Hidden people** | See and undo the people you hid; hiding also stops them requesting you | DR-ZYRA-095, DR-ZYRA-284 | **Missing** — functions exist nowhere |
| Guardian privacy | What your Guardians can see (per Journey, past summaries) | DR-ZYRA-232, 233 | **Live** (old model) / **Not live** (5 Oct read rules) |

## 5. Reset and delete

| Action | What happens | Decision | Server |
|---|---|---|---|
| **Reset profile** | Clears your answers, details, photos and all discovery history so you can be seen afresh; the account stays | Founder 7 Aug | **Live** — `zyra_reset_profile` |
| **Delete account** | Removes your photos, then your account; everything linked to it is deleted with it (68 of 70 links cascade) | DR-ZYRA-134 | **Live** — `delete_own_account` |
| What deletion does to **the other person's** Journey, the Guardian links, the Circle and shared messages | The Journey ends as "This member has left ZYRA"; the other Seeker keeps Timeline and messages for 3 months; Guardian links end; Circle shows "Former member"; safety reports kept | DR-ZYRA-285 | **Different** — today the shared Journey is deleted for both people |

## 6. Two roles, one login

| Rule | Decision | Server |
|---|---|---|
| One login can hold a Seeker and a Guardian account and switch between them (Profile → Switch account); identity and security shared, plan separate | DR-ZYRA-285 | **Different** — a profile has one role; a second role needs a second account (DR-ZYRA-231 notes the code system supports both, the profile model does not) |

## 7. Decided 26 Oct (DR-ZYRA-285)

| # | Question | Decision |
|---|---|---|
| Q1 | What the other person keeps when someone deletes their account | **Their ended Journey, Timeline and messages for 3 months; links end; Circle shows "Former member"** |
| Q2 | Two roles on one login | **Yes** — needs server work |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-26 | V1 | First draft, checked against production (OA-ZYRA-309) |
| 2026-10-26 | V1 | §7 decided (DR-ZYRA-285) |
| 2026-10-26 | V1 | Founder: keep Pause My Profile, defined (DR-ZYRA-290) |
| 2026-10-26 | V1 | Approved by the Founder ("a" - all 14 pages); status CURRENT |
| 2026-10-30 | V2 | Phone access page (LOCK 12). V1 archived in REPORTS/ARCHIVE/PRODUCT_BLUEPRINT_VERSIONS/ |
| 2026-10-31 | V2 | Phone access row brought up to LOCK 12 V2 as built 30 Oct (straight to the iPhone prompt; approximate area) - Fable, 04:15 maintenance |
