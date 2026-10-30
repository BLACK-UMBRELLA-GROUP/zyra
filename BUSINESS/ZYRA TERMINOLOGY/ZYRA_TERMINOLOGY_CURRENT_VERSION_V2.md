---
id: DOC-ZYRA-0126
type: BRAND
status: CURRENT
feature: BUSINESS: ZYRA TERMINOLOGY
purpose: ZYRA terminology V2 - every word members see in the planned app (the Founder preview, DR-ZYRA-274), what it means, where it appears, the retired words that must not come back, and the writing rules for new wording. Source of truth for product vocabulary; the blueprint pages hold the rules behind each word
links: [DOC-ZYRA-0278, DOC-ZYRA-0283, DOC-ZYRA-0290, DOC-ZYRA-0291, DOC-ZYRA-0292, DOC-ZYRA-0293, DOC-ZYRA-0071, DR-ZYRA-274]
owner: ZYRA chat
---

# ZYRA — TERMINOLOGY — V2 (CURRENT)

| Field | Value |
|---|---|
| Status | CURRENT_VERSION — source of truth for every member-facing word. A word in the app that disagrees with this page is a defect |
| Date | 2026-10-29 |
| Owner | ZYRA chat (lead designer); only the Founder changes a name |
| Built from | The 14 approved blueprint pages (26 Oct 2026) and the planned app's screens (DOC-ZYRA-0286). V1 (13 Aug 2026) described the old member app and is archived in `ARCHIVE/` |
| Companion | UX writing DOC-ZYRA-0071 (tone, "you ↔ Maryam"); error and empty states DOC-ZYRA-0070 |

ZYRA is a **marriage** app, not a dating app. The words follow from that: Seeker, Guardian, Journey, Salam, Family Review —
never "date", "match", "swipe", "like", "singles".

## 1. People

| Word | Meaning | Rule page |
|---|---|---|
| **Seeker** | A person looking for a spouse through ZYRA. The one who browses, sends and receives Journey requests, and goes through a Journey | DOC-ZYRA-0278 |
| **Guardian** | A family member — father, brother, grandfather, uncle, legal guardian, family representative or other — linked to a Seeker, who takes part in their Journeys. Never "wali" in the app (the server still uses `wali_*` names; members never see them) | DOC-ZYRA-0290 §1 |
| **Main Guardian** | The Seeker's lead Guardian: in every Journey, decides each Family Review, sees the Seeker's Journey requests and who they are with (DR-ZYRA-292). One per Seeker; the Seeker chooses; a Seeker may have none (then no Journey can move) | DOC-ZYRA-0290 §2–3 |
| **Additional Guardian** | Any other linked Guardian. The Seeker switches **View** and **Chat** on or off for them, Journey by Journey (Chat needs View) | DOC-ZYRA-0290 §3 |
| **ZYRA Code** | Every account's permanent code (`ZYRA-XXXX-XXXX-…`) used to link a Guardian or find a known person. Not a login | DOC-ZYRA-0290 §1 |
| **Family** | Both Seekers' Guardians together, as in "either family blocks", "your families have been introduced" | DOC-ZYRA-0071 |
| Names | Use the person's first name wherever the app knows it ("Ahmad decides"); never he/she — a Guardian may be any relative | DOC-ZYRA-0071 |

## 2. The Journey

| Word | Meaning | Rule page |
|---|---|---|
| **Journey** | The guided path two Seekers walk towards marriage, with their families. Always capitalised | DOC-ZYRA-0283 |
| **Journey request** | How a Journey starts: one Seeker asks ("Request a Journey"), the other accepts or declines. Tabs: **Received**, **Sent**, **Past**. A declined, cancelled or expired request shows as **"Not taken up"**. Requests expire after 7 days | DOC-ZYRA-0283 §3 |
| **Journey place** / **place** | How many Journeys a Seeker can have at once: Basic 1, Seeker One 3. A Journey being prepared or active takes a place; a request does not | DOC-ZYRA-0283 §2 |
| **Preparing** | After both accept: places reserved for both; each taps **"I'm ready to begin"** within 48 hours; the Journey begins only when both are ready | DOC-ZYRA-0283 §4 |
| **Guardian access** | The page before a new Journey begins: which paid Additional Guardians will see it — "Begin only if you agree" | DOC-ZYRA-0283 §4 |
| **Salam** | The first stage: both send Salam | DOC-ZYRA-0283 §5 |
| **Compatibility** | Both choose to reveal; the score shows once both have. Also the name of the Browse action that uses an Unlock | DOC-ZYRA-0283 §5, DOC-ZYRA-0292 §5 |
| **Journey Bio** | Each person's longer introduction, shown once both reveal | DOC-ZYRA-0283 §5 |
| **Faith & Values · Building a Life · Navigating Life** | The three question stages. Each ends in a Family Review | DOC-ZYRA-0283 §5 |
| **Family Review** | The 48 hours after a question stage in which each Main Guardian may continue or pause the move to the next stage; silence means continue | DOC-ZYRA-0283 §5, DOC-ZYRA-0290 §3 |
| **Family Compatibility** | The stage where each Seeker asks the other family's Guardian four questions, and each Guardian asks the other Seeker four | DOC-ZYRA-0290 §3 |
| **Open Conversation** | The final stage | DOC-ZYRA-0283 §5 |
| **Timeline** | The Journey's milestones | DOC-ZYRA-0278 §3 |
| **Messages** | Writing inside a Journey. "Chat" is used only for the Guardian switch and the paid Guardian feature | DOC-ZYRA-0293 |
| **End** / **Keep** | Either person may end at any time. The confirmation shows **Keep** above a red **End**. "Ended Journey", never "cancelled" or "closed" | DOC-ZYRA-0283 §7 |
| **Ended Journeys** | Read-only; Bio, Compatibility and Guardians stay readable for three months | DOC-ZYRA-0283 §7 |
| **Request restart** | A **new** Journey with the same person; they must accept; the old one is never reopened | DOC-ZYRA-0283 §7 |

## 3. Browsing

| Word | Meaning | Rule page |
|---|---|---|
| **Profiles** | The Seeker's browsing tab: one person at a time | DOC-ZYRA-0292 |
| **Request a Journey** | The one action on a profile (tap again to cancel) | DOC-ZYRA-0292 §5 |
| **Filters** | Age, distance, country of residence, nationality, ethnicity | DOC-ZYRA-0292 §3 |
| **Find by ZYRA Code** | Look someone up by their code | DOC-ZYRA-0292 §5 |
| **Hide** | Removes a person from your browsing and stops their requests; they are not told | DOC-ZYRA-0292 §5 |
| **Report** / **Block** | Report a profile; Block removes them everywhere | DOC-ZYRA-0297 |
| **Introductions** | People your Guardians put forward ("Suggested by Ahmad") | DOC-ZYRA-0290 §7 |
| **Pause My Profile** | In Settings: hides your profile and stops new requests; current Journeys carry on (DR-ZYRA-290). The only "pause" left in ZYRA | DOC-ZYRA-0292 §1 |

## 4. Membership and money

| Word | Meaning | Rule page |
|---|---|---|
| **Seeker Basic** / **Guardian Basic** | £4.99 once (no fee if a membership was paid before), no monthly cost. Guardian Basic: view only, no chat | DOC-ZYRA-0291 §1 |
| **Seeker One** / **Guardian One** | The monthly plans (£29.99 / £19.99). Use the role name to members; **"ZYRA One"** only as the umbrella name for the monthly tier when the role is clear. Never "Premium", "Plus", "+" or "Pro" | DOC-ZYRA-0291 §1 |
| **ZYRA Family** / **Family place** | Up to 10 places in total, any mix of Seeker One and Guardian One, billed monthly. "Place" here means a membership seat, not a Journey place — say "Family place" in full where both could be meant | DOC-ZYRA-0291 §3 |
| **Compatibility Unlock** | Shows a browsed person's compatibility. Sold singly or in packs; Seeker One includes 3 a month. Plural "Unlocks". Never "Profile Unlock" | DOC-ZYRA-0291 §4 |
| **Trial** | 14 days of Seeker One, once per verified person | DOC-ZYRA-0291 §2 |
| **Membership** / **Your subscriptions** | The pages that choose and manage a plan | DOC-ZYRA-0278 §3 |
| Paying and chat | Say it plainly, always: Guardian One makes chat **possible**, the Seeker **decides** (DR-ZYRA-289; approved wording in the 29 Oct ZYRA chat note) | DOC-ZYRA-0290 §4 |

## 5. Guardians' own words

| Word | Meaning | Rule page |
|---|---|---|
| **My ZYRA** | The home tab for both roles: what needs you; for Guardians "All settled" when nothing does | DOC-ZYRA-0278 §2 |
| **Seekers** | The Guardian tab listing the Seekers they support | DOC-ZYRA-0278 §2 |
| **Network** | The Guardian tab for other families' Seekers | DOC-ZYRA-0278 §2 |
| **Connect with Guardian** | A request to another Seeker's Main Guardian, who chooses whether to respond (renamed from "Speak to Guardian", Founder 29 Oct) | DOC-ZYRA-0290 §7 |
| **Guardian Circle** | The families' shared discussion for a Journey | DOC-ZYRA-0290 §6 |
| **Invite a Guardian** | The Seeker's way to add a Guardian by code | DOC-ZYRA-0290 §1 |

## 6. Internal names — never shown to members

| Internal | Say instead |
|---|---|
| Guardian Gate (stage 3) | Nothing — the screen says what is needed: "A Main Guardian is needed before the Journey can continue" |
| Stage 1, Stage 2, Pre-Journey, Preparing state, "attempt" (server), `wali`, `wali_premium`, `seeker_premium` | The stage's own words; "Journey"; "Guardian"; the plan name |
| Portrait card, Floating Glass, Midnight Plum, Couple icon | Design names for the team only |
| Founder preview, planned app, old app, Tier 1–4 | Build and clean-up words; never in the app |
| Pending, Processing, Status, Submit, Confirm, Workflow, Request received | People's words: "Waiting for Ahmad", "Ahmad accepted your request" (DOC-ZYRA-0071) |

## 7. Retired words — must not come back

| Retired | Why | Since |
|---|---|---|
| Wali, Wali One | Renamed Guardian, Guardian One | 2026-08 / 26 Oct |
| Guardian+, Premium, Plus | The paid tier is **Guardian One** / **Seeker One** | 26 Oct 2026 (DOC-ZYRA-0291) |
| Profile Unlock, Unlock Profile, Compatibility Unlock Plus, Compatibility Preview(+) | **Compatibility Unlock** only | 2026-08-03 |
| Like, Decline, Match (as a verb), Consider, Save, Pass, Saved, Potential, Potential Journey, Incoming / Mutual Potential, Considers | Browse has one action: Request a Journey (DR-ZYRA-274, DR-ZYRA-280) | 26 Oct 2026 |
| Pause (a Journey), Paused Journey, Resume | Journeys are not paused; only **Pause My Profile** remains (DR-ZYRA-274, DR-ZYRA-290) | 25–26 Oct 2026 |
| Speak to Guardian | Renamed **Connect with Guardian** | 29 Oct 2026 |
| Proposal Tracker, Connections, Potentials, Discovery, Trust Score, Match Confidence | Old-app names with no planned-app screen | 26 Oct 2026 |
| Slot | Say **place** | 26 Oct 2026 |
| Date, swipe, singles, hook up | Not a dating app | always |

## 8. Writing rules for any new wording

1. Check the word here first, then the rule page it points to. A new word needs the Founder's yes and a row on this page.
2. People before software (DOC-ZYRA-0071): name the person, say what happened between people, never what the system did.
3. Capitalise ZYRA's own nouns (Journey, Seeker, Guardian, Salam, Family Review, Compatibility Unlock, ZYRA Code); ordinary words stay lower case (place, request, chat).
4. Openness is declared, never discovered (DR-ZYRA-292): if someone else can see something, the member is told at the moment it starts to matter.
5. Money words say what payment does **and does not** give (DR-ZYRA-289).

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-08-13 | V1 | Promoted glossary of the old member app (OA-ZYRA-209) |
| 2026-10-29 | V2 | "Speak to Guardian" renamed "Connect with Guardian" (Founder) |
| 2026-10-29 | V2 | Rewritten by the ZYRA chat from the approved blueprint (DR-ZYRA-274): planned-app vocabulary, internal names never shown, retired words; V1 archived in `ARCHIVE/ZYRA_TERMINOLOGY_2026-10-29_V1.md` |
