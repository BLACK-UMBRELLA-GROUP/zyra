---
id: DOC-ZYRA-0299
type: REPORT
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Blueprint review pack for the Founder - the 14 draft blueprint pages in reading order, each in one paragraph, so he can approve them (they then become CURRENT)
links: [OA-ZYRA-309, DOC-ZYRA-0278, DOC-ZYRA-0283, DOC-ZYRA-0289]
owner: Fable
---

# ZYRA BLUEPRINT — REVIEW PACK — 26 OCT 2026

> **APPROVED 26 Oct 2026** - the Founder approved all 14 pages ("a"). They are CURRENT.

**What this is:** the 14 blueprint pages are written, and every question on them now has your decision
(DR-ZYRA-274 → 291). They stay DRAFT until you approve them. You don't need to read 120 KB - each page is below in one
paragraph.

**Update 26 Oct:** Pause My Profile is kept (DR-ZYRA-290); Unlocks are 3 a month, not carried over (DR-ZYRA-288); a family plan holds 10 places in total (DR-ZYRA-291); paid Guardian chat is by the Seeker's permission (DR-ZYRA-289). The pages below include these.

**How to answer** - for each number, one of:

| Answer | Means |
|---|---|
| ✅ | Approve - the page becomes CURRENT, the source of truth |
| ✏️ + what to change | Fable changes it, then it comes back to you |
| ⏭ | Later |

Short form is fine, e.g. "all ✅" or "all ✅ except 3: …".

**Pages 1-10 are the product** - what members see and the rules. **Pages 11-14 are technical** (database, outside
services, build commands, the decision trace) - written from the code and checked by Fable; you can approve them on that
check.

## Reading order

| # | Page | ID | Size | How |
|---|---|---|---|---|
| 1 | Journey rules | DOC-ZYRA-0283 | 8 KB | Read the summary |
| 2 | Membership and payments | DOC-ZYRA-0291 | 7 KB | Read the summary |
| 3 | Guardians | DOC-ZYRA-0290 | 9 KB | Read the summary |
| 4 | Browse (seeing people) | DOC-ZYRA-0292 | 6 KB | Read the summary |
| 5 | Messages | DOC-ZYRA-0293 | 6 KB | Read the summary |
| 6 | Profile and account | DOC-ZYRA-0295 | 6 KB | Read the summary |
| 7 | Sign-up and onboarding | DOC-ZYRA-0296 | 5 KB | Read the summary |
| 8 | Safety | DOC-ZYRA-0297 | 5 KB | Read the summary |
| 9 | Screen map (part 1) | DOC-ZYRA-0278 | 7 KB | Read the summary |
| 10 | Look and feel (part 5) | DOC-ZYRA-0282 | 15 KB | Read the summary |
| 11 | Data (part 3) | DOC-ZYRA-0280 | 13 KB | Approve on Fable's check |
| 12 | Outside connections (part 4) | DOC-ZYRA-0287 | 6 KB | Approve on Fable's check |
| 13 | Build and release (part 6) | DOC-ZYRA-0288 | 7 KB | Approve on Fable's check |
| 14 | Trace (part 7) | DOC-ZYRA-0289 | 8 KB | Approve on Fable's check |

## The pages in one paragraph each

### 1. Journey rules - DOC-ZYRA-0283 (8 KB)

You see profiles only while you have a free Journey place (ZYRA One members can keep browsing when full). You **request** a Journey; the other person accepts or declines. Accepting reserves a place for **both** of you, and the Journey begins only when **both** say "I'm ready to begin". It then runs through the same eight stages as before — with a **Journey Bio** step after Compatibility — and every step moves on only when both choose to continue and both Main Guardians are present. Either person can **end** at any time. There is **no Pause and no Save**. An ended Journey stays readable for three months; starting again means a brand-new request the other person must accept.

Rests on 6 decisions (DR-ZYRA-236, 274, 275, 277, 283, 284). Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_2_JOURNEY_RULES_CURRENT_VERSION_V2.md`

### 2. Membership and payments - DOC-ZYRA-0291 (7 KB)

ZYRA has two plans for each role. **Basic** costs **£4.99 once** (free if you have paid for a membership before) and has no monthly fee. **One** is monthly — **Seeker One £29.99**, **Guardian One £19.99** — and Seeker One starts with **one 14-day trial per verified person, for life**. A family plan holds **up to 10 places in total, any mix of Seeker One and Guardian One** (DR-ZYRA-291), with a growing discount. **Compatibility Unlocks** are separate: £2.99 for one, £6.99 for three, £9.99 for five; Seeker One includes **3 every month** (DR-ZYRA-288). The server already knows who has paid, handles trials, billing grace and cancellation — but **nothing can be bought yet**: there is no App Store purchase code, so plans are set by developer functions. What each plan *includes* is decided (§6, DR-ZYRA-282): Basic - 1 Journey place, 25 profiles every 4 hours, 3 pending requests, 1 Guardian; Seeker One - 3 places, unlimited browsing, 25 pending requests, up to 10 Guardians. Potential, Paused, Saved and Considers are retired; the code still shows them until the clean-up.

Rests on 12 decisions (DR-ZYRA-135, 221, 235, 243, 248, 250, 252, 268, 275, 281, 282, 283). Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_2_MEMBERSHIP_RULES_CURRENT_VERSION_V1.md`

### 3. Guardians - DOC-ZYRA-0290 (9 KB)

A Guardian is a family member — father, brother, grandfather, uncle, legal guardian, family representative or other — who links to a Seeker by entering the other's **permanent ZYRA Code**; the other person accepts. A Seeker's first Guardian becomes the **Main Guardian**, who leads, is in every Journey and decides each **48-hour Family Review**. Other Guardians are **Additional**: the Seeker chooses, Journey by Journey, whether they can view and chat. **Chat needs a paid Guardian** (Guardian One); Guardian Basic can view only. Guardians talk together in the **Guardian Circle**, put people forward as **Introductions**, and may **Speak to Guardian** of another family's Seeker. Most of this is already on the server; the Circle is built but not yet live, and Speak to Guardian and the agreed-access step are missing.

Rests on 20 decisions (DR-ZYRA-110, 123, 124, 136, 157, 221, 226, 231, 232, 233, 236, 243, 248, 252, 268, 274, 277, 280, 281, 282). Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_2_GUARDIAN_RULES_CURRENT_VERSION_V2.md`

### 4. Browse (seeing people) - DOC-ZYRA-0292 (6 KB)

The **Profiles** tab shows one person at a time on a **Portrait card**: public details first, then a swipeable photo gallery. Only Seekers of the opposite gender who are active, complete, not blocked and **with a free Journey place** appear — and only while **you** have a free place (Seeker One can keep browsing when full). People are ordered **by compatibility** (the server already ranks this way). You can filter by **age, distance, country of residence, nationality and ethnicity**. From a card you **Request a Journey** (tap again to cancel), or open the options menu for **Compatibility** (using an Unlock), **Find by ZYRA Code**, **Filters**, **Hide** and **Report / Block**. Seeker Basic sees **25 profiles every 4 hours**. There is no Save, Pass or Consider any more.

Rests on 17 decisions (DR-ZYRA-095, 123, 131, 135, 162, 163, 211, 231, 250, 268, 274, 276, 277, 280, 282, 283, 284). Open questions on the page: none (Pause My Profile decided: DR-ZYRA-290).

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_2_BROWSE_RULES_CURRENT_VERSION_V1.md`

### 5. Messages - DOC-ZYRA-0293 (6 KB)

In a Journey, the two Seekers talk through the stages (Salam, answers, Family questions); the **free conversation opens only at the last stage, Open Conversation**, once the last 48-hour Family Review has passed. Main Guardians and included Additional Guardians can read it, and can write only if they are paid and allowed. A block ends the Journey and closes the conversation; an ended Journey's messages stay readable as an archive for three months. Families also talk in the **Guardian Circle**, which is built but not live. **One serious problem was found:** in the newest version of the database files, the rule that decides who may send a message no longer checks blocks or whether the Journey has ended, and two of those files cannot be applied one after the other (§6).

Rests on 11 decisions (DR-ZYRA-110, 131, 190, 232, 233, 236, 268, 274, 277, 278, 280). Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_2_MESSAGING_RULES_CURRENT_VERSION_V1.md`

### 6. Profile and account - DOC-ZYRA-0295 (6 KB)

A profile has **public details** (first name, age, city, bio and **3 to 6 photos**), details shown only after a Compatibility Unlock, and **private answers** that are never shown (faith and background answers are special-category data with a consent record). Once published, **gender and date of birth are frozen**. From the Profile tab you preview your profile as others see it, edit it and your photos, manage membership, change the background, gold accents and haptics, set notifications and App Lock, and reach help and feedback. You can **reset** your profile (answers and discovery history, keeping the account) or **delete** your account. Two things in the planned app do not exist on the server yet: **Pause My Profile** (kept - hides your profile and stops new requests; current Journeys carry on, DR-ZYRA-290) and the **hidden people list**. One login holding both a Seeker and a Guardian account is shown in the app but the server still allows one role per account.

Rests on 16 decisions (DR-ZYRA-085, 095, 096, 134, 135, 149, 209, 231, 232, 239, 250, 252, 264, 268, 284, 285). Open questions on the page: none (Pause My Profile decided: DR-ZYRA-290).

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_2_PROFILE_RULES_CURRENT_VERSION_V1.md`

### 7. Sign-up and onboarding - DOC-ZYRA-0296 (5 KB)

Onboarding is **progressive**: a short account setup gets you in, and the longer profile is finished inside the app. You choose which side you need **first** (Seeker or Guardian), sign in with **Google or Apple**, give your **names, gender and date of birth**, add your **first photo** (Seekers), choose a **membership**, and pass the **identity check**. The app then opens. From inside it you complete **Chapter 2 (Your Profile)**, give **explicit consent** before the faith and background questions, answer the **compatibility questions** (about you, then your preferences as green / amber / red), optionally write your **Journey Bio**, and finally **publish** your profile. Until you publish, nobody can see or match with you.

Rests on 15 decisions (DR-ZYRA-081, 082, 209, 220, 221, 231, 250, 252, 256, 259, 262, 264, 280, 285, 286). Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_2_ONBOARDING_RULES_CURRENT_VERSION_V1.md`

### 8. Safety - DOC-ZYRA-0297 (5 KB)

Members can **report** a profile or a photo (with a reason and optional details) and **block** anyone. A block ends any Journey between them, closes the chat both ways, removes them from each other's Browse and shows them as "User not found"; it is permanent for that Journey. If a Journey is ended for a **safety concern**, the other person only ever sees "prefer not to say". Members can see the status of their own reports. **But nobody reviews reports yet** — there is no moderation team, tool or process — and photos are not checked before others see them. Those two, plus the identity check, are the safety gates before launch.

Rests on 11 decisions (DR-ZYRA-085, 095, 096, 123, 131, 221, 236, 248, 250, 268, 287). Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_2_SAFETY_RULES_CURRENT_VERSION_V1.md`

### 9. Screen map (part 1) - DOC-ZYRA-0278 (7 KB)

The planned app, page by page. Members open the app, sign in, and land in the planned app (today only you can, with sample people). Seekers get five tabs - Profiles (one profile at a time, Request a Journey; no Save), Journey (your Journeys and requests), My ZYRA (one page of everything new), Guardian (your Guardians and the Circle) and Profile (your profile, membership, settings, Switch account). Guardians get their own tabs. Every page, button and message is listed in the generated inventory DOC-ZYRA-0286.

Rests on 1 decision (DR-ZYRA-274). Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_1_SCREEN_MAP_CURRENT_VERSION_V2.md`

### 10. Look and feel (part 5) - DOC-ZYRA-0282 (15 KB)

ZYRA is a **dark, glass-on-purple** app. Every page sits on one background gradient — **Midnight Plum #30203F → #160E20**, corner to corner — and everything on it is translucent white "glass" with a thin **gold edge** where something is selected or important. Text is **Poppins**, mostly thin (200 for headings, 300 for body), in white at four strengths. The word **ZYRA** itself is **Syne SemiBold in pale gold #E5CE8E**. Corners are soft (cards 14, sheets and dialogs 24, buttons fully round). Motion is short and eases out (most moves 180–420 ms, `easeOutCubic`), and every tap selection gives a **subtle** haptic that members can change.

Written from the code (part 5 also from colour theme V2), not from decisions. Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_5_LOOK_AND_FEEL_CURRENT_VERSION_V1.md`

### 11. Data (part 3) - DOC-ZYRA-0280 (13 KB)

ZYRA keeps its data in Supabase (Postgres): **63 tables**, **205 database functions**, **74 triggers**, one **private** photo bucket and **no server (edge) functions** in the repository. The app reaches almost everything through functions rather than reading tables directly: 194 of the 205 functions run with the database owner's rights and check the caller themselves, and 14 public tables have row-level security switched on with **no** direct-access rules at all — so the only way in is a function. 12 tables sit in a private schema the app cannot reach.

Written from the code (part 5 also from colour theme V2), not from decisions. Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_3_DATA_CURRENT_VERSION_V1.md`

### 12. Outside connections (part 4) - DOC-ZYRA-0287 (6 KB)

ZYRA leans on **one** outside system for nearly everything: **Supabase** (database, sign-in, photo storage, in-app notifications, usage counts). Members sign in with **Google** or **Apple**. Three things the planned app needs are **not connected yet**: **payments** (no App Store purchase code at all — memberships and Compatibility Unlocks are prices on a page), **the identity check** (Sumsub is chosen, the app has a switched-off slot for it), and **phone push notifications** (only in-app ones exist). The website runs on **Cloudflare**, email on **Google Workspace**.

Rests on 3 decisions (DR-ZYRA-274, 275, 278). Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_4_OUTSIDE_CONNECTIONS_CURRENT_VERSION_V1.md`

### 13. Build and release (part 6) - DOC-ZYRA-0288 (7 KB)

ZYRA is an **iPhone app** built with **Flutter 3.44.2** on Shakeel's Mac mini. Day to day, `./run.sh` puts a build on his iPhone that keeps working when unplugged. TestFlight builds come from two small scripts and are signed by Apple's cloud signing. The database has **one** live project; changes are migration files applied only with an exact Founder GO. Three release switches are **off**, and the public launch is **closed** until identity checks, payments, moderation, privacy wording and store details are done.

Rests on 4 decisions (DR-ZYRA-257, 275, 277, 279). Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_6_BUILD_AND_RELEASE_CURRENT_VERSION_V1.md`

### 14. Trace (part 7) - DOC-ZYRA-0289 (8 KB)

Every rule now traces to a decision. **Nine planned-app rules had no decision of their own** — they came in with the preview, because no decision was recorded between 10 and 25 Oct (lesson S13) — and were confirmed on 26 Oct as DR-ZYRA-280 (§2). **Three places where code contradicts a decision** are in §3; all are already tracked.

Rests on 37 decisions (DR-ZYRA-095, 110, 131, 135, 136, 142, 157, 160, 190, 198, 202, 211, 220, 221, 226, 227, 229, 231, 232, 235, 236, 241, 243, 248, 250, 252, 266, 268, 274, 275, 276, 277, 278, 279, 280, 282, 283). Open questions on the page: none.

File: `PRODUCT/BLUEPRINT/ZYRA_BLUEPRINT_7_TRACE_CURRENT_VERSION_V1.md`

## What happens when you approve

Each approved page: status DRAFT → CURRENT, "Approved by the Founder, <date>" in its header, a change-log row, and the map
regenerated. The version number stays the same (approving is not a change of meaning - saving standard rule 6). After
that, building anything that breaks a CURRENT page needs a new decision first.
