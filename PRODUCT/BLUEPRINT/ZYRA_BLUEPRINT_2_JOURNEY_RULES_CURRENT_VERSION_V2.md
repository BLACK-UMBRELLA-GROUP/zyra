---
id: DOC-ZYRA-0283
type: SPEC
status: DRAFT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 2 V2 (Journey) - the planned app's Journey rules - browsing and visibility, requests, places, getting ready, the stages, Guardians' access, ending, the archive and Request restart - each marked built, different or missing on the server
links: [OA-ZYRA-309, OA-ZYRA-317, OA-ZYRA-315, DR-ZYRA-274, DR-ZYRA-275, DOC-ZYRA-0278, DOC-ZYRA-0285]
owner: Fable
---

# ZYRA BLUEPRINT — PART 2 — JOURNEY RULES — V2 (DRAFT)

Status: **DRAFT for Shakeel.** Written 26 Oct 2026 from the planned app (DR-ZYRA-274): the rules in
`SOURCE/lib/dev/zyra_view_request_draft_model.dart` and the pages in `zyra_one_journey_concept_shell.dart`. V1 described the old
member app and is archived in `REPORTS/ARCHIVE/PRODUCT_BLUEPRINT_OLD_APP_2026-10-26/`. The last column says what the **server** does today (from DOC-ZYRA-0280):
**Built** = already enforced · **Different** = enforced another way · **Missing** = nothing yet. The gaps are OA-ZYRA-317.

## In one paragraph

You see profiles only while you have a free Journey place (ZYRA One members can keep browsing when full). You **request** a
Journey; the other person accepts or declines. Accepting reserves a place for **both** of you, and the Journey begins only when
**both** say "I'm ready to begin". It then runs through the same eight stages as before — with a **Journey Bio** step after
Compatibility — and every step moves on only when both choose to continue and both Main Guardians are present. Either person
can **end** at any time. There is **no Pause and no Save**. An ended Journey stays readable for three months; starting again
means a brand-new request the other person must accept.

## 1. Seeing people

| Rule | Planned app | Server today |
|---|---|---|
| Who you see | People not hidden, not blocked, and with a free place themselves | **Different** — no place-based visibility |
| When you can browse | While you have a free place; ZYRA One (3 places) can browse even when full | **Missing** |
| Who sees you | Only while you have a free place | **Missing** |
| Hide / block | Hide removes someone from Browse; block removes them everywhere | **Built** (blocks); hide **Missing** |
| Save | Not in the app | **Different** — `saves` table still exists (remove) |

## 2. Places

| Rule | Planned app | Server today |
|---|---|---|
| Places | Basic **1** (after the £4.99 joining fee, DR-ZYRA-275) · ZYRA One **3** | **Different** — Basic 0, One 3 |
| What takes a place | A Journey being prepared or active (both people's places) | **Different** — only active Journeys count |
| Pending requests | Do **not** take a place | **Missing** (no requests to begin) |
| Full and a request arrives (ZYRA One) | Choose **End & accept request** (pick a Journey to end) or **Keep my Journeys** | **Missing** |

## 3. Requests

| Rule | Planned app | Server today |
|---|---|---|
| Send | "Request a Journey" on a visible profile you have no history with; tap again to cancel | **Missing** — Journeys start from a mutual like + one tap |
| Received / Sent | Two tabs in Journey requests; a gold dot for unseen received requests | **Missing** |
| Accept | Needs a free place on both sides | **Missing** |
| Decline / cancel | The request disappears; nothing is reserved | **Missing** |
| Introductions | People your Guardians put forward appear here | **Missing** |
| Limits (how many, how long) | Not chosen yet in the preview | **Open** — needs a Founder decision before building |

## 4. Getting ready and beginning

| Rule | Planned app | Server today |
|---|---|---|
| After accepting | "Preparing": both places reserved | **Missing** |
| Guardian access | Before beginning, each person sees which **paid Additional Guardians** will view the Journey and agrees ("Begin only if you agree") | **Different** — per-Guardian view/chat switches exist, no agreement step |
| Ready | Each person taps "I'm ready to begin"; one person alone never starts it | **Missing** |
| Begin | Only when both are ready; starts at Salam | **Different** — one person's tap starts it |

## 5. Stages

| # | Stage | Moves on when | Server today |
|---|---|---|---|
| 1 | Salam | Both send Salam | **Built** |
| 2 | Compatibility | Both choose to reveal; your score shows once both have | **Built** |
| 2b | **Journey Bio** | Both reveal their Bio, then both continue | **Missing** |
| 3 | Guardian Gate | Both Seekers have a Main Guardian | **Built** |
| 4–6 | Faith & Values · Building a Life · Navigating Life | Both choose "I'm ready for the next step" | **Different** — server has questions, answers and a 48-hour Family Review after each |
| 7 | Family Compatibility | Both continue | **Different** — same as above |
| 8 | Open Conversation | — | **Built** |

| Rule across all stages | Planned app | Server today |
|---|---|---|
| Both must continue | Every step needs both people | **Built** for stages 1–3 |
| Main Guardians | Nothing moves while either Seeker lacks a Main Guardian; End still works | **Built** (DR-ZYRA-236 hold) |
| Identity check | Required before any Journey | **App only** (OA-ZYRA-315 a) |

## 6. Guardians in a Journey

| Rule | Planned app | Server today |
|---|---|---|
| Main Guardian | Always sees the Journey and can chat | **Built** |
| Additional Guardians | See it by default; the Seeker can switch View and Chat off per Journey (Chat needs View) | **Built** |
| Agreed paid access | For a new Journey, paid Additional Guardians the Seeker agreed to stay on (View and Chat) while linked and eligible; the Seeker cannot switch them off for that Journey | **Missing** |
| Chat needs a paid Guardian | Basic Guardians can view but not chat; dropping to Basic switches chat off and it does not come back by itself | **Different** — server requires each Circle participant's own paid role (24 Sep) |
| Unlinking | Removes all of that Guardian's access | **Built** |
| Speak to Guardian | A Guardian can send a request to another Seeker's Main Guardian, who chooses whether to respond | **Missing** |

## 7. Ending, the archive and starting again

| Rule | Planned app | Server today |
|---|---|---|
| End | Either person, any time; confirmation with Keep above a red End | **Built** |
| After ending | Places released; the Journey becomes read-only | **Built** |
| Archive | Bio, Compatibility and Guardians stay readable for **three months** | **Missing** — no 3-month rule |
| Request restart | A **new** Journey with the same person; they must accept; the old one is never reopened. Shown as "not available yet" | **Different** — built (`request_new_journey`, 24-hour wait, 30-day expiry) but switched off |
| Pause | Not in the app | **Different** — full Pause flow (remove) |

## 8. Questions this raises (for the Founder, before OA-ZYRA-317 is designed)

| # | Question |
|---|---|
| Q1 | Do the question stages keep real answers and the 48-hour Family Review, or become the simpler "both continue" steps the preview shows? |
| Q2 | Request limits: how many pending requests per person, and how long before a request expires? |
| Q3 | Request restart: keep the 24-hour wait and 30-day expiry already built? |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-25 | V1 | Old member app (archived in REPORTS/ARCHIVE/PRODUCT_BLUEPRINT_OLD_APP_2026-10-26/) |
| 2026-10-26 | V2 | Rewritten from the planned app (DR-ZYRA-274), each rule marked against the server |
