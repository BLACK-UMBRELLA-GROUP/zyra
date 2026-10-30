---
id: DOC-ZYRA-0290
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 2 (Guardians) - every Guardian rule of the planned app - linking by ZYRA Code, Main and Additional Guardians, what a Guardian sees and does, chat and paid access, Family Reviews, past Journey summaries, the Guardian Circle, Introductions, Connect with Guardian, Family places - each marked built, different or missing on the server, with its decision
links: [OA-ZYRA-309, OA-ZYRA-317, DOC-ZYRA-0283, DOC-ZYRA-0289, DR-ZYRA-280]
owner: Fable
---

# ZYRA BLUEPRINT — PART 2 — GUARDIAN RULES — V3 (CURRENT)

Status: **CURRENT - approved by the Founder, 26 Oct 2026** (all 14 blueprint pages, review pack DOC-ZYRA-0299). Building anything that breaks this page needs a new decision first. Written 26 Oct 2026 from the planned app (`SOURCE/lib/dev/` — model
`zyra_view_request_draft_model.dart`, shell `zyra_one_journey_concept_shell.dart`, `zyra_one_journey_guardian_presentation.dart`),
the server functions (DOC-ZYRA-0281) and the decisions register. Last column: **Built** · **Different** · **Missing** on the server.
Journey-stage rules that involve Guardians (Guardian Gate, Family Review) are also in the Journey rules, DOC-ZYRA-0283.


> **How to read the server column (added 26 Oct, after the live check DOC-ZYRA-0294):** "Built" here means **in the repository
> files**. Production is about two months behind. Not live today: per-Guardian View/Chat switches and agreed access
> (`zyra_set_guardian_journey_permission`), Family places, the Main-Guardian Journey hold, the Guardian Circle, read receipts,
> the verified trial, Browse ranking (`zyra_browse_ranked_ids`) and the 5 Oct security fixes. Everything else marked Built is live.

## In one paragraph

A Guardian is a family member — father, brother, grandfather, uncle, legal guardian, family representative or other — who links
to a Seeker by entering the other's **permanent ZYRA Code**; the other person accepts. A Seeker's first Guardian becomes the
**Main Guardian**, who leads, is in every Journey and decides each **48-hour Family Review**. Other Guardians are
**Additional**: the Seeker chooses, Journey by Journey, whether they can view and chat. **Chat needs a paid Guardian**
(Guardian One); Guardian Basic can view only. Guardians talk together in the **Guardian Circle**, put people forward as
**Introductions**, and may **Connect with Guardian** of another family's Seeker. Most of this is already on the server; the
Circle is built but not yet live, and Connect with Guardian and the agreed-access step are missing.

## 1. Linking

| Rule | Decision | Server |
|---|---|---|
| Every account has one **permanent ZYRA Code** (`ZYRA-XXXX-XXXX-…`, random, not a login); share it by copy, QR or the share sheet | DR-ZYRA-231 | **Built** — `zyra_generate_personal_code`, `zyra_my_personal_code`, `zyra_rotate_my_personal_code` |
| Entering or scanning a code shows only a first name and role — no photo | DR-ZYRA-231 §4 | **Built** — `zyra_preview_personal_code` |
| Confirming sends a request to the code's owner, who accepts or declines; requests last **30 days** | DR-ZYRA-231 §5, DR-ZYRA-226 | **Built** — `zyra_request_guardian_link`, `zyra_accept_guardian_request`, `zyra_decline_guardian_request`, `zyra_cancel_guardian_request` |
| Works in either direction (Seeker enters a Guardian's code, or the reverse); a Seeker cannot link a Seeker, nor a Guardian a Guardian | DR-ZYRA-231 | **Built** |
| The Guardian states the relationship: father, brother, grandfather, uncle, legal guardian, family representative, other | DR-ZYRA-226 | **Built** |
| The person asking must have passed the identity check | DR-ZYRA-221 | **Built** — checked on the server (unlike Journeys, OA-ZYRA-315 a) |
| Two people who have a match cannot become each other's Guardian | DR-ZYRA-123 | **Built** — `zyra_can_guardian_link` |
| Two Seekers who share a Guardian (now or before) cannot match; a Seeker cannot match their own Guardian; Journeys already under way are not dissolved | DR-ZYRA-123, DR-ZYRA-124 | **Built** — `zyra_can_match` |
| Planned app: "Invite a Guardian" (Seeker Guardian tab) and "Find by ZYRA Code" | DR-ZYRA-231 | screens exist in the preview |

## 2. Main and Additional Guardians

| Rule | Decision | Server |
|---|---|---|
| The first Guardian linked becomes **Main** automatically | DR-ZYRA-232 | **Built** — trigger `auto_designate_main_wali` |
| The Seeker can make another Guardian Main | DR-ZYRA-232 | **Built** — `zyra_set_main_guardian` |
| A Seeker may deliberately have **no** Main; then no Journey can move (only End works) | DR-ZYRA-236 (replaces DR-ZYRA-136) | **Built** — `zyra_clear_main_guardian`, Journey hold trigger |
| The Seeker can remove any Guardian; removal ends all that Guardian's access | DR-ZYRA-232 | **Built** — `zyra_remove_guardian` |
| Guardians per Seeker by plan: Seeker Basic **1**, Seeker One up to **10** (including Main); a Guardian supports at most **10** Seekers (safety limit) | DR-ZYRA-282, DR-ZYRA-281 | **Different** — the app checks the plan limit on screen only; no server limit |

## 3. Guardians in a Journey

| Rule | Decision | Server |
|---|---|---|
| **Before a Journey:** the Main Guardian sees the Seeker's pending Journey requests, sent and received, and who each is with (public profile card only). Additional Guardians don't. The Seeker is told once when a Guardian becomes Main (one-time message, LOCK 2). **The other person is not told at the request** — it is explained in a Profile section "What Guardians can do" (Founder 29 Oct, "B: Profile section only"; changes DR-ZYRA-292's consequence) | DR-ZYRA-292, Founder 29 Oct | **Missing** (OA-ZYRA-317); wording and privacy notice OA-ZYRA-321 |
| Main is in every active Journey of their Seeker and cannot be switched off | DR-ZYRA-232 §1, DR-ZYRA-233 §1 | **Built** |
| Additional Guardians: the Seeker turns **View** and **Chat** on or off per Journey (Chat needs View); each family controls only its own | DR-ZYRA-232 §2 | **Built** — `zyra_set_guardian_journey_permission` |
| Agreed paid Additional Guardians at the start of a new Journey stay on for it | DR-ZYRA-280 §7 | **Missing** |
| Main Guardians decide each 48-hour Family Review (Continue or Pause the move to the next stage); silence = continue | DR-ZYRA-110, DR-ZYRA-277 | **Built** — `wali_review_decision`, `reopen_family_review` |
| A Guardian sees "the Journey is waiting for a shared decision" / "a Main Guardian is needed" | DR-ZYRA-236 | planned-app wording; server state **Built** |
| Family Compatibility stage: each Seeker asks the other side's Guardian 4 questions, and each Guardian asks the other Seeker 4 | DR-ZYRA-110 | **Built** (`journey_family_answers`) |

## 4. Chat and paid access

| Rule | Decision | Server |
|---|---|---|
| **Guardian Basic** (£4.99 once): can view, **cannot chat** — Main included | DR-ZYRA-268, DR-ZYRA-252 | **Different** — server requires each Circle member's own paid role (DR-ZYRA-248); Journey chat gate to be aligned |
| **Guardian One** (£19.99 / month) or a funded Family Guardian place makes chat **possible**, not automatic — View, link, stage, permission and blocks still apply | DR-ZYRA-268, DR-ZYRA-243 | **Built** — `zyra_has_paid_role` |
| **Paying never guarantees chat.** Writing in a Journey is the Seeker's permission (they choose their Main Guardian and switch each Additional Guardian's Chat on or off) and depends on the stage, blocks and endings. This must be said plainly on the purchase screen before payment and in the member terms | DR-ZYRA-289 | app wording and terms - **Missing** (OA-ZYRA-320) |
| Dropping to Basic switches chat off; it does not come back by itself | DR-ZYRA-268 | **Missing** in the planned form |
| A Seeker's subscription never proves their Guardian paid | DR-ZYRA-268 | **Built** |

## 5. Past Journeys

| Rule | Decision | Server |
|---|---|---|
| The Seeker can give each Guardian (Main or Additional) access to their past Journey summaries — **off** by default, revocable, for that person only; re-linking starts off | DR-ZYRA-233 | **Built** — `zyra_guardian_history_consent`, `zyra_attempt_summary_for_guardian` |
| Active Guardians can see how a Journey ended (a "safety concern" shows as "prefer not to say") | DR-ZYRA-268 | **Built** — `zyra_match_ending` |

## 6. The Guardian Circle

| Rule | Decision | Server |
|---|---|---|
| The families' discussion: one transcript, with Journey discussion cards | DR-ZYRA-248 | **Built, not live** — `zyra_open_family_message_circle`, `zyra_send_family_message`; release switch `familyMessagingEnabled` off; OA-ZYRA-298 not applied live |
| Every Circle member needs their own paid role | DR-ZYRA-248 | **Built** |
| Mute, report a message, read receipts | DR-ZYRA-248 | **Built** — `zyra_set_family_message_muted`, `zyra_report_family_message`, `zyra_mark_family_messages_read` |
| Messages and reports are kept for a set time, then purged | DR-ZYRA-248 | **Built** — `zyra_purge_expired_family_message_data` |
| Blocks and unlinking end Circle access | DR-ZYRA-248 | **Built** — lifecycle triggers |

## 7. Introductions and Connect with Guardian

| Rule | Decision | Server |
|---|---|---|
| A Guardian puts a person forward to their Seeker; it appears in the Seeker's **Introductions** with "Suggested by …"; a gold dot until seen | DR-ZYRA-280 §9, DR-ZYRA-157 | **Built** — `wali_suggestions` table, `zyra_mark_suggestions_seen` |
| **Connect with Guardian:** a Guardian sends a request to another Seeker's Main Guardian, who chooses whether to respond (Guardian Network tab; LOCK 8 — Network also has Introduce to <Seeker>) | DR-ZYRA-280 §8 | **Missing** — client screens only, in both apps |
| Guardian My ZYRA shows what needs them across their Seekers ("All settled" otherwise) | DR-ZYRA-274 | **Built** in part — `zyra_guardian_activity` |

## 8. Family places

| Rule | Decision | Server |
|---|---|---|
| ZYRA Family: up to 10 places in total, any mix of Seeker One and Guardian One, billed monthly | DR-ZYRA-291 | **Different** — server allows 10 of each; cap to change (OA-ZYRA-317) |
| Giving someone a place does not link them or grant View or Chat; they must accept | — | **Built** |
| A Seeker's free trial ends when they take a Family place | — | **Built** — trigger `zyra_forfeit_seeker_trial_on_family_seat` |

## 9. Decided 26 Oct (DR-ZYRA-281)

| # | Question | Decision |
|---|---|---|
| Q1 | Limits on Guardians? | **By plan: Basic 1, One up to 10 per Seeker (DR-ZYRA-282); up to 10 Seekers per Guardian** |
| Q2 | Guardian Basic cannot chat, even Main? | **Kept** (DR-ZYRA-268 stands) |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-26 | V1 | First draft from the planned app, server and decisions (OA-ZYRA-309) |
| 2026-10-26 | V1 | §9 decided (DR-ZYRA-281) |
| 2026-10-26 | V1 | Founder: paid Guardian chat is by the Seeker's permission - purchase screen and terms must say so (DR-ZYRA-289) |
| 2026-10-26 | V1 | Family places: 10 in total, any mix (DR-ZYRA-291) |
| 2026-10-26 | V1 | Approved by the Founder ("a" - all 14 pages); status CURRENT |
| 2026-10-26 | V2 | Founder: the Main Guardian sees who the Seeker's requests are with (DR-ZYRA-292). V1 archived in REPORTS/ARCHIVE/PRODUCT_BLUEPRINT_VERSIONS/ |
| 2026-10-29 | V2 | §3: other person told in a Profile section, not at the request (Founder "B: Profile section only"; ZYRA chat). DR number from Fable |
| 2026-10-29 | V3 | "Speak to Guardian" renamed "Connect with Guardian" (Founder: "let change to connect with gurdian"); Guardian tabs now five (LOCK 8). V2 archived in REPORTS/ARCHIVE/PRODUCT_BLUEPRINT_VERSIONS/ |
