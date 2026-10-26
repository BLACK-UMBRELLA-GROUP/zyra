---
id: DOC-ZYRA-0278
type: SPEC
status: DRAFT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 1 V2 - the planned ZYRA app's screens - how members get in, the Seeker and Guardian tabs, every page by area, what each is for, how you reach it and what it opens; what is real and what is sample
links: [DOC-ZYRA-0286, DOC-ZYRA-0283, DOC-ZYRA-0285, DR-ZYRA-274, OA-ZYRA-309, OA-ZYRA-317]
owner: Fable
---

# ZYRA BLUEPRINT — PART 1 — SCREEN MAP — V2 (DRAFT)

Status: **DRAFT for Shakeel.** Written 26 Oct 2026 from the planned app (DR-ZYRA-274): the Founder preview in
`SOURCE/lib/dev/zyra_one_journey_concept_shell.dart` and its 65 helper files. Every page is listed with its buttons and
messages in the generated inventory **DOC-ZYRA-0286** (`ZYRA_PLANNED_SCREEN_INVENTORY_GENERATED.md`, re-run
`SYSTEM/tools/blueprint/generate_planned_screen_map.py`). V1 described the old member app and is archived in `REPORTS/ARCHIVE/PRODUCT_BLUEPRINT_OLD_APP_2026-10-26/`.

> **Today every page here runs on sample people and cannot save anything.** Only the Founder can open it. Making it work for
> members is OA-ZYRA-317.

## 1. Getting in

| Step | Today (Founder) | Planned (members) |
|---|---|---|
| Open the app | Splash: the ZYRA wordmark with its moving line | Same |
| Not signed in | Welcome → sign in or sign up | Same; sign-up and identity check are the existing ones |
| Signed in | Founder launch screen → the planned app with sample data, as a Seeker or a Guardian | Straight into the planned app with the member's own data (not built) |
| Two roles, one login | Profile → Switch account: Seeker ↔ Guardian; a setup preview for a role not yet set up | Same |

## 2. Tabs

| Seeker tabs | What is there |
|---|---|
| **Profiles** | Browse one profile at a time ("Portrait card": public details, then a swipeable photo gallery). Filters (country, nationality, ethnicity). Per profile: **Request a Journey** (tap again to cancel); options (⋯): Compatibility, Find by ZYRA Code, Filters, Hide, Report. No Save |
| **Journey** | Your current Journeys as cards (Portrait split design), plus your Journey requests. Each card opens the Journey or its options |
| **My ZYRA** | One page: Journey requests, Introductions, current Journeys, Ended Journeys, Guardian information, notifications; gold dots for anything new |
| **Guardian** | Your Guardians (Main and others), invite a Guardian, the Guardian Circle |
| **Profile** | Your profile, edit profile, photos, membership, subscriptions, Compatibility Unlocks, personalisation, settings, help, switch account |

| Guardian tabs | What is there |
|---|---|
| **My ZYRA** | What needs you across your Seekers ("All settled" when nothing does), Guardian updates |
| **Network** | Other families' Seekers you can approach through their Main Guardian ("Speak to Guardian") |
| **Seekers** | The Seekers you support, each with their Journeys and the Guardian Circle |
| **Profile** | Same as the Seeker Profile tab |

## 3. Pages by area (49)

### Browse and requests

The browse options menu (⋯) on Profiles holds Compatibility, Find by ZYRA Code, Filters and Hide.

| Page | For | Reached from | Opens |
|---|---|---|---|
| View profile (`profile`) | One person's full public profile | Profiles, Journey requests, Find by ZYRA Code | Report |
| Filters (`filters`) | Country, nationality, ethnicity | Profiles | — |
| Find by ZYRA Code (`scan`) | Look someone up by their code | Profiles → options (⋯) | View profile |
| Compatibility (`compatibility`) | A browsed person's compatibility, using a Compatibility Unlock | Profiles → options (⋯) | Compatibility Unlocks |
| Journey requests (`requests`) | **Received** and **Sent** tabs: accept, decline, cancel | My ZYRA, Journey | Journey, View profile, choose a place, Report |
| Choose a place (`request_capacity`) | When all 3 places are full: **End & accept request** (pick which Journey ends) or **Keep my Journeys** | Journey requests | — |
| Introductions (`introductions`) | People your Guardians put forward ("No introductions yet") | My ZYRA | — |

### Journey

| Page | For | Reached from | Opens |
|---|---|---|---|
| Journey (`journey`) | The Journey itself: getting ready ("I'm ready to begin"), Salam, Compatibility, Journey Bio, Guardian Gate, the stages, messages | Journey tab, Journey requests | Journey Bio, Guardian access, Journey options, Timeline |
| Guardian access (`guardian_access_agreement`) | Before a new Journey begins: which paid Additional Guardians will see it; "Begin only if you agree" | Journey | — |
| Journey Bio (`bio`, `bio_locked`) | Each person's Journey Bio, shown once both choose to reveal | Journey options | — |
| Compatibility score (`journey_compatibility`, locked) | Your score once both reveal | Journey options, Timeline | — |
| Guardians (`journey_guardians`) | Both families' Guardians for this Journey | Journey options | — |
| Timeline (`timeline`) | The Journey's milestones | Journey card, Journey | Compatibility |
| End Journey (`journey_action`) | The End confirmation (Keep above a red End) | Journey options | — |

### Ended Journeys

| Page | For |
|---|---|
| Ended Journeys (`ended`, `past_journeys`) | Read-only list; the place is released |
| Ended Bio / Compatibility / Guardians | Read-only archive of that Journey — access lasts **three months** after it ends |
| Request restart (`ended_restart`) | A **new** Journey with the same person; they must accept. Shown as "not available in this preview" |

### Guardians

| Page | For | Reached from |
|---|---|---|
| Guardian (`guardian`) | One Guardian, or one Seeker's Journey status for a Guardian ("A Main Guardian is needed before the Journey can continue") | Guardian tabs, Guardian Circle |
| Seeker profile (`guardian_linked_profile`) | A linked Seeker, seen by their Guardian | Guardian My ZYRA, Guardian |
| Network profile (`guardian_network_profile`) | Another family's Seeker | Guardian My ZYRA, Network |
| Speak to Guardian (`network_request`) | Send a request to that Seeker's Main Guardian; "they choose whether to respond" | Guardian My ZYRA, Network |
| Guardian Circle (`guardian_circle`) | The families' discussion, one transcript with Journey discussion cards | Guardian tabs, Seeker Guardian tab, My ZYRA |
| Invite a Guardian (`guardian_invite`) | Invite by code | Seeker Guardian tab |
| Held action (`held_action`) | Explains an action that is not available in the preview | Guardian tabs |

### Profile, membership and settings

| Page | For |
|---|---|
| My profile (`own_profile_preview`) | See your profile as others do |
| Edit profile, Photos (`edit_profile`, `manage_photos`) | The existing editors, reused |
| Membership, Membership review, Your subscriptions | Basic (£4.99 one-time joining fee, 1 place) or ZYRA One (monthly, 3 places); review before choosing; manage |
| Compatibility Unlocks (`compatibility_store`) | £2.99 for 1, £6.99 for 3, £9.99 for 5 |
| Personalisation, Settings, Settings detail, Account action | Background, gold accents, haptics; privacy, notifications, account |
| Notifications (`notifications`) | Notification list |
| Activity (`activity_preview_detail`) | One My ZYRA activity item in full |
| Help & support, Report profile (`help_support`, `safety`) | Help; report or block |
| Switch account (`switch_account_signup`, `_setup`) | Move between Seeker and Guardian; set up the other role |

## 4. Left-overs found (go in the clean-up, DOC-ZYRA-0285)

| What | Why it is a left-over |
|---|---|
| `paused` and `saved` pages | Both show "unavailable"; Pause and Save are retired |
| Pause text and buttons inside the Journey page ("Pause requested", "Request Pause", "Request Resume") | Never shown (`canPause: false`) |
| `controls` page and "LOCAL PREVIEW CONTROLS" | Developer controls for walking through flows alone ("simulate peer") — removed when real data arrives |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-25 | V1 | Old member app (archived in REPORTS/ARCHIVE/PRODUCT_BLUEPRINT_OLD_APP_2026-10-26/) |
| 2026-10-26 | V2 | Rewritten from the planned app (DR-ZYRA-274); generated inventory DOC-ZYRA-0286 |
