---
id: DOC-ZYRA-FTOUR-V1
type: SPEC
status: CURRENT
feature: FIRST-TIME WALKTHROUGH
purpose: Spec for LOCK 36 - the one-time walkthrough shown after a member's first sign-up
owner: ZYRA chat
---
# FIRST-TIME WALKTHROUGH — SPEC — V1 (LOCKED 19 NOV 2026)
Founder 19 Nov 18:40: "ok for now lets lock in and we will improve further down line" → clickable "Lock and queue now" (exception to AD-AIOS-149, like LOCK 34). Prototype V289 (private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V289.html`, layout button **First-time tour**).

## 1. Rules
| Item | Rule |
|---|---|
| When | Once, the first time a member enters the app after sign-up (Look around first, Finish setting up → ZYRA, or You're all set → Enter ZYRA). Never again automatically for that account. |
| Replay | Settings → SUPPORT → **Replay the walkthrough** (first row, NEW tag) starts it again from the welcome. |
| Skip | **None** (Founder 19 Nov 17:45: "we cant skip the tour"). |
| Moving on | Tap anywhere or the gold **Next** (last step: **Finish**). Tapping the left 20 % of the screen goes back one step. No timer. |
| Look | The page stays visible under a light warm shade (`rgba(43,36,32,.5)`). The thing being explained is cut out of the shade with a 2 pt gold edge (`#A9792E`). The current tab icon is always cut out too, so the member knows where they are. |
| Note | Small opaque ivory note (`#FBF7F0`, radius 20, soft shadow), 20 pt from each side, with a pointer to the lit thing. Contents: gold label "<PAGE> · PAGE n OF 5", title (19 pt), one line (14.5 pt muted), step dots for that page, gold **Next** pill. |
| Placement (QUESTIONS 175 — one rule) | The note **never covers the lit item or the current tab icon**. Measure the note's real height, then: (1) **below** the lit item if the note ends at least 12 pt above the top of the tab bar; else (2) **above** the lit item if it starts at least 48 pt from the top of the screen; else (3) the item is too tall — **only its top part is lit** (cut-out and gold edge end where the note begins, minimum 64 pt lit) and the note sits 14 pt under that part. The note may sit over shaded, unlit page content: it is opaque, so its words never sit on page words. Intro steps (tab icon lit) always use (2). |
| Gesture | A soft touch point (40 pt circle, white 60 %, 2 pt gold edge) acts out the action on the lit thing, on a loop: **tap** (press + gold ripple) or **swipe** (press + slide left). Reduce Motion: shown still, no loop. |
| Welcome / end | Centred ivory card with gold ZYRA wordmark. Welcome: "Hi <first name>, welcome" / "Let’s walk through the app together, one page at a time. It only takes a minute." / **Let’s go**. End: "That’s everything, <first name>" / "You can see this again any time from Settings. Bismillah — let’s begin." / **Start using ZYRA** → returns to the page the member was on. |
| Sample state | Shown on the member's own real pages. A new member's Journey tab shows its empty state. |

## 2. Steps — Seeker (gesture in brackets)
| # | Page | Lit | Title | Line |
|---|---|---|---|---|
| 1 | Profiles | tab icon (tap) | This is Profiles | This is where you meet people. Everyone here is verified, and you see one person at a time. |
| 2 | Profiles | profile card (swipe) | Each card is one person | Swipe left or right to move to the next person. |
| 3 | Profiles | profile card, tap near top (tap) | See their photos | Tap the card to move through their photos, one after another. |
| 4 | Profiles | Request button (tap) | Ready to begin? | When it feels right, tap here to ask for a Journey. They’ll receive your request. |
| 5 | Journey | tab icon (tap) | This is Journey | When someone accepts, your Journey happens here. It moves in stages, with your families beside you. |
| 6 | Journey | Browse profiles (tap) | Nothing here yet | That’s normal. Your first Journey starts from a profile you like, so this takes you back to Profiles. |
| 7 | My ZYRA | tab icon (tap) | This is My ZYRA | Your home page. Whenever something needs you, you’ll find it here first. |
| 8 | My ZYRA | Needs you card (swipe) | Needs you | Requests, replies and next steps show here, newest first. Swipe if there’s more than one. |
| 9 | My ZYRA | status pills (tap) | At a glance | The Journey places you’re using, your notifications and your partner preferences. |
| 10 | My ZYRA | quick-access tiles (tap) | Quick access | Your Journey requests, introductions from your Guardians, ended Journeys and notifications. |
| 11 | Guardian | tab icon (tap) | This is Guardian | On ZYRA you never do this alone. Your Guardians, a parent or relative, walk every Journey with you. |
| 12 | Guardian | Guardian name row (swipe) | Your Guardians | Each card is one Guardian. Swipe to see the next, and tap ••• for options. |
| 13 | Guardian | Journey access list (tap) | What they can see | For each Journey, choose whether this Guardian can view it and chat in it. |
| 14 | Guardian | chat + add buttons (tap) | Talk and add | Chat with all your Guardians in one place, or tap + to add another. |
| 15 | Profile | tab icon (tap) | This is Profile | Everything about you: your photos, your plan and your settings. |
| 16 | Profile | photo (tap) | Your profile | Preview it the way others see it, or tap Edit to change it. |
| 17 | Profile | Membership row (tap) | Your membership | Your plan and how many Journey places you have. |
| 18 | Profile | Settings row (tap) | Settings | Everything else you might need lives here. |

## 3. Steps — Guardian
| # | Page | Lit | Title | Line |
|---|---|---|---|---|
| 1 | Network | tab icon (tap) | This is Network | Families on ZYRA. Here you look for a match for the Seeker you support. |
| 2 | Network | Seeker switch pill (tap) | Choose your Seeker | If you support more than one Seeker, switch between them here. |
| 3 | Network | action bar (tap) | Introduce or connect | Introduce someone to your Seeker, or speak with their Guardian first. |
| 4 | Journeys | tab icon (tap) | This is Journeys | Every Journey your Seeker begins shows here, stage by stage. |
| 5 | Journeys | Open Journey (tap) | Open a Journey | See where it is and take part when it’s your turn. |
| 6 | My ZYRA | tab icon (tap) | This is My ZYRA | Your home page. Whenever something needs you, you’ll find it here first. |
| 7 | My ZYRA | Needs you card (swipe) | Needs you | Family Review and anything else waiting for you shows here, newest first. |
| 8 | My ZYRA | quick-access tiles (tap) | Quick access | Journey requests, introductions and notifications. |
| 9 | Seekers | tab icon (tap) | This is Seekers | The people you support. Each one has their own card. |
| 10 | Seekers | Seeker cards (swipe) | Swipe through | Each card shows their current Journey. Swipe to the end to invite another Seeker. |
| 11 | Seekers | chat + invite buttons (tap) | Talk and invite | Chat in the Guardian Circle, or tap + to invite a Seeker. |
| 12 | Profile | tab icon (tap) | This is Profile | Your details, your plan and your settings. |
| 13 | Profile | Membership row (tap) | Your membership | Your plan and what it lets you do. |
| 14 | Profile | Settings row (tap) | Settings | Everything else you might need lives here. |
If a lit item is not on the member's page (e.g. a Guardian with no current Journey), that step lights the tab icon instead; wording unchanged.

## 4. Masters
`FIRST_TOUR/MASTERS/` — 430 × 932 @3x from prototype V290 (re-rendered 19 Nov for QUESTIONS 175; every step checked: note overlaps neither the lit item nor any tab icon): `t00`–`t19` (Seeker welcome, 18 steps, end), `tg00`–`tg15` (Guardian), `t99_settings_replay_row.png`. Touch point shown mid-gesture.

## 5. Not in this version
Founder: "we will improve further down line" — later versions may change wording, add pages or a server-side "seen" flag.

## 6. Version history
| Version | Date | Change |
|---|---|---|
| V1 | 2026-11-19 | First version (LOCK 36), prototype V289 |
| V1 | 2026-11-19 | QUESTIONS 175: one placement rule (never cover the lit item or the tab icon; tall items lit at the top part only); all 37 masters re-rendered from V290. No change to wording or steps |
