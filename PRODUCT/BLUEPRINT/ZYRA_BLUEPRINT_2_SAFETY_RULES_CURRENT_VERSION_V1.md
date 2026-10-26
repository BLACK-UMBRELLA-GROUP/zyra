---
id: DOC-ZYRA-0297
type: SPEC
status: DRAFT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 2 (Safety) - reporting profiles, photos and messages, blocking, what a safety-concern ending hides, who reviews reports, moderation, retention, the member's safety case list, help, and the built-in safeguards - checked against production; what must exist before launch
links: [OA-ZYRA-309, OA-ZYRA-317, OA-ZYRA-312, DOC-ZYRA-0294, DOC-ZYRA-0057]
owner: Fable
---

# ZYRA BLUEPRINT — PART 2 — SAFETY RULES — V1 (DRAFT)

Status: **DRAFT for Shakeel.** Written 26 Oct 2026 from the report and block screens, the planned app's Report page and
settings, and the server. Last column checked against **production** (DOC-ZYRA-0294): **Live** · **Not live** · **Missing**.
The wider safety design is DOC-ZYRA-0057 (Safety and respect system).

## In one paragraph

Members can **report** a profile or a photo (with a reason and optional details) and **block** anyone. A block ends any Journey
between them, closes the chat both ways, removes them from each other's Browse and shows them as "User not found"; it is
permanent for that Journey. If a Journey is ended for a **safety concern**, the other person only ever sees "prefer not to say".
Members can see the status of their own reports. **But nobody reviews reports yet** — there is no moderation team, tool or
process — and photos are not checked before others see them. Those two, plus the identity check, are the safety gates before
launch.

## 1. Reporting

| Rule | Decision | Server |
|---|---|---|
| Report a profile or a photo from Browse, a Journey, chat, a profile page or the Guardian side | DR-ZYRA-095 | **Live** — `profile_reports` |
| Reasons: fake profile · inappropriate content · harassment · underage · violence · privacy · other; optional details | DR-ZYRA-095 | **Live** — checked by the database |
| Report a Guardian Circle message (evidence captured at the moment of report) | DR-ZYRA-248 | **Not live** |
| You see your own reports and their status (pending, reviewing, actioned, dismissed) | — | **Live** — `zyra_my_safety_cases` |
| Reports are kept for a set time, then purged | f01 (5 Oct) | **Not live** |
| Reporting is never an emergency service; the app says so and points to the right action | — | app |

## 2. Blocking

| Rule | Decision | Server |
|---|---|---|
| Block anyone from their profile, Browse or a Journey | DR-ZYRA-095 | **Live** — `zyra_block_user` |
| A block ends every Journey between you (reason: safety concern) and closes the chat | DR-ZYRA-131 | **Live** |
| No messages either way after a block | DR-ZYRA-131 | **Live** (9 Aug rule) |
| Neither appears in the other's Browse; a blocked person shows as "User not found" | DR-ZYRA-268 | **Live** (Browse) / app |
| Unblocking never reopens an ended Journey | Founder 8 Aug | **Live** |
| A block also removes Guardian Circle access | DR-ZYRA-248 | **Not live** |

## 3. Safety-concern endings

| Rule | Decision | Server |
|---|---|---|
| The other person and their Guardians see "prefer not to say", never "safety concern" and never the note | — (8 Aug) | **Live** — `zyra_match_ending` |

## 4. Who reviews, and moderation

| Need | Today |
|---|---|
| Someone reviews each report and acts (warn, hide, remove) | **Decided:** the Founder, through a review page in AIOS (DR-ZYRA-287, OA-AIOS-413). **Missing** today — 4 test reports sit "pending" |
| Photos checked before others see them | **Missing** (DR-ZYRA-096) |
| Message moderation | **Missing** |
| Removing a member who breaks the rules | **Missing** as a process (account deletion exists only for yourself) |

## 5. Built-in safeguards

| Safeguard | Decision | Server |
|---|---|---|
| Identity check (document, liveness, face match) and duplicate review | DR-ZYRA-221 | storage **Live**; provider **Missing**; switch **off** |
| 18 or over only | — | **Live** — minimum-age check |
| Seekers only match the opposite gender | — | **Live** |
| Families involved: Main Guardian before any Journey moves | DR-ZYRA-236 | **Not live** (hold) / Guardian Gate **Live** |
| Shared-Guardian and own-Guardian matches refused | DR-ZYRA-123 | **Live** |
| Private answers never shown; special-category consent | DR-ZYRA-250 | **Live** |
| Photos stored privately, shown only through short-lived links | DR-ZYRA-085 | **Live** |

## 6. Before launch (safety)

| # | Must exist |
|---|---|
| 1 | Identity check provider connected and the production switch on (OA-ZYRA-317 item 8) |
| 2 | The AIOS report review page (DR-ZYRA-287, OA-AIOS-413) and a member-removal process |
| 3 | Photo moderation |
| 4 | Report retention and Circle message reporting applied (5 Oct and 19 Sep files) |
| 5 | Developer and test-purchase functions removed; sign-up settings checked; leaked-password protection on (OA-ZYRA-312) |
| 6 | Privacy policy, terms and safety guidance pages written |

## 7. Decided 26 Oct

The Founder reviews reports at launch through a review page in AIOS — **DR-ZYRA-287**.

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-26 | V1 | First draft, checked against production (OA-ZYRA-309) |
| 2026-10-26 | V1 | Report review decided (DR-ZYRA-287) |
