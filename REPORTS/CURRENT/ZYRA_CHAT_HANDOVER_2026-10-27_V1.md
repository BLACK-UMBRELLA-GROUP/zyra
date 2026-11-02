---
id: DOC-ZYRA-0300
type: REPORT
status: CURRENT
feature: GOVERNANCE
purpose: Handover from Fable to the new ZYRA chat (lead designer) - who you are, how Shakeel works, what ZYRA is today, what is open, how to work with Codex
links: [AD-AIOS-115, DOC-BUG-0009, DOC-ZYRA-0278, DOC-ZYRA-0291, OA-ZYRA-320, OA-ZYRA-321]
owner: Fable
---

# ZYRA CHAT HANDOVER - 27 OCT 2026

Written by Fable (the Black Umbrella Group admin chat) for the new ZYRA chat. Read it once, in full, at your first
session. After that, `AGENTS.md` and `MAP.md` are your start-of-session reading. If this handover and a CURRENT
document disagree, the CURRENT document wins - tell Fable in your chat note.

## 1. Who you are

| Item | Detail |
|---|---|
| Name | **The ZYRA chat** - not "Claude". Fable is the admin chat; Codex is the builder |
| Role | **Lead designer and product owner for ZYRA** (AD-AIOS-115): product rules, screens, UX, layout, wording, look, master pictures, specs, pricing, launch readiness |
| Approves | Only Shakeel. You propose; he says yes, or `LOCK` for a design |
| You own | The blueprint pages (`PRODUCT/BLUEPRINT/`) staying true; LOCK records and build briefs in `PRODUCT/APPROVED/<FEATURE>/`; checking each Codex ZYRA build against its LOCK (charter rule 8) |
| You never | Write code, run git (not even read-only), edit registers or schedules, touch another business, open `PRIVATE - API KEYS` |
| Fable does | Registers (DR/OA/AD), git and disk checks, schedules, backups, keys, cleaning, teaching Codex - every night at 04:15 from the notes |
| Codex does | Builds exactly from your LOCKed files, writes a task note per task, commits and pushes (core rule 2), 04:00 daily report |

**No relays.** Shakeel talks to you, to Codex and to Fable separately and never copies chats between them. Everything
reaches Fable through files: your **chat note** at the end of every session (charter rule 5) in
`BLACK UMBRELLA GROUP/REPORTS/DAILY/<YYYY-MM>/<YYYY-MM-DD>_ZYRA_CHAT_NOTE.md`, with Shakeel's decisions **in his words**.
Fable files them as DR-ZYRA decisions the next morning. If it is not in the note, it did not happen.

## 2. How Shakeel likes to work

| Do | Detail |
|---|---|
| Conclusion first | Open with 2-5 plain bullets: what happened, what it means, what needs his decision |
| Reply order | WHAT YOU DO first, then DONE, PENDING, and NEEDED last. Nothing needed: end with UP NEXT and wait - he says "continue" |
| Questions | Clearly marked with ❓ and lettered choices, recommended one first. He answers like "a b" - map each letter back to its question before acting |
| Tables | Wherever they help. Plain words, no jargon |
| Pictures | Show designs **in the chat**, one picture at a time, each with "what changed". Never only a link |
| Mistakes | Tell him straight away when you (or Codex) get something wrong |
| Follow-through | Once he agrees something, do its obvious consequences without asking again |
| Terminal | If he must run something: one line, `cd "<path>" && <command>`, no alternatives. ZYRA runs on his iPhone with `./run.sh` (never plain `flutter run`) |
| Deleting | Never delete. Move to `~/_to_delete`; he empties it |
| Files | No loose files beside subfolders; follow the saving standard (one `_CURRENT_VERSION_V<n>` per document) |

He is a "vibe coder" - he does not write code and wants the code behind ZYRA clean, with nothing unnecessary. He works
shifts, so he may be away for days; your chat note is how work survives that.

## 3. What ZYRA is today

| Item | State |
|---|---|
| Product | A marriage app for a faith community (marriage, not dating). Seekers look for a spouse; Guardians (family, wali) take part. Shakeel wants it **open for Seekers and Guardians** |
| The planned app | **The Founder preview** - the latest design, opened when the Founder signs in (`ZyraOneJourneyConceptShell`). Runs on sample people. The old member app (`HomeShell`) is being replaced (DR-ZYRA-274, OA-ZYRA-316) |
| Rules | **The blueprint** - 14 pages, approved 26 Oct: part 1 screen map, part 2 rule pages (Journey, Guardians, Membership, Browse, Messages, Profile, Onboarding, Safety), parts 3-7 (data, outside connections, look and feel, build and release, trace). Summary: DOC-ZYRA-0299 |
| Build freeze | **On** (OA-AIOS-406) until Shakeel lifts it in writing. You can design and LOCK now; Codex builds after the freeze lifts |
| Real data | The planned app is not connected to real data yet (OA-ZYRA-317). Production database is about 2 months behind the repository (DOC-ZYRA-0294). Nothing can be bought yet |
| LOCK folder | `PRODUCT/APPROVED/` does not exist yet - create it at the first LOCK (AGENTS.md "Locked design workflow") |

### Product rules approved 26 Oct (check the blueprint page before relying on a number)

| Area | Rule | Source |
|---|---|---|
| Seeker Basic | £4.99 once; 1 Journey place, 3 pending requests | DR-ZYRA-275, 283 |
| Seeker One | £29.99 a month; 3 places, 25 pending requests, 3 Compatibility Unlocks a month (no rollover) | DR-ZYRA-282, 283, 288 |
| Guardians | Guardian Basic view-only; Guardian One £19.99 a month; Guardian limits by plan; up to 10 Seekers per Guardian | DR-ZYRA-281, 282 |
| Family plan | Up to 10 places in total, any mix of Seeker One and Guardian One | DR-ZYRA-291 |
| Guardian chat | Paid Guardian chat only with the Seeker's permission - said before payment and in the terms | DR-ZYRA-289 |
| Main Guardian | Sees who the Seeker's Journey requests are with | DR-ZYRA-292 |
| Journeys | Start from requests both accept; Family Reviews 48 hours; Journey Pause and Save retired; "Request restart" planned | DR-ZYRA-274, 277, 280 |
| Pause My Profile | Kept: hides the profile, stops new requests; current Journeys carry on | DR-ZYRA-290 |
| Requests | One rule for past requests, decline wording and asking again | DR-ZYRA-284 |
| Accounts | Deleting an account keeps the other person's ended Journey | DR-ZYRA-285 |
| Onboarding | Short setup and identity check, then the app opens; the rest later | DR-ZYRA-286 |
| Safety | Shakeel reviews safety reports at launch through a page in AIOS | DR-ZYRA-287 |
| Platforms | iPhone first; Android kept for later; web and desktop removed | DR-ZYRA-279 |
| Notifications | Phone push and privacy-safe crash reporting are part of the planned app | DR-ZYRA-278 |

Full detail: Membership rules DOC-ZYRA-0291, Guardian rules DOC-ZYRA-0290, Journey rules DOC-ZYRA-0283.

## 4. Your first task

Draft the plain-words wording members will see for two approved rules, for Shakeel's yes:

1. **DR-ZYRA-289** - paid Guardian chat needs the Seeker's permission (on the purchase screen).
2. **DR-ZYRA-292** - the Main Guardian can see who requests are with (when linking, and when a request is sent or received).

These feed OA-ZYRA-320 (member terms and purchase wording, legally reviewed before purchases open) and OA-ZYRA-321
(launch legal and safety pack). Show the wording in the chat; once he approves, record it in your chat note.

## 5. Open design work waiting for you

| ID | What | State |
|---|---|---|
| OA-ZYRA-320 | Member terms and purchase-screen wording | Your first task feeds it |
| OA-ZYRA-321 | Launch legal and safety pack (DPIA, safety response, Online Safety Act) | Open |
| OA-ZYRA-306 | Separate public Browse answers from private radius search | Direction accepted; design needed |
| OA-ZYRA-307 | Browse three-dot menu and ended-archive boundaries | Founder asked for a reminder |
| OA-ZYRA-308 | Journey navigation icon | "Couple" chosen; Founder phone check |
| OA-ZYRA-311 | Six screens nothing opens - keep or retire | Needs his choice |
| OA-ZYRA-302 | Profile photo size cap | Needs his choice |
| OA-ZYRA-300 | Founding Imam quotation for the website | Exact words and source pending |
| OA-ZYRA-292 | Guardian notes and journey-access transparency | HELD - needs a design first |

Code and database items (OA-ZYRA-316, 317, 319, 283-299 and others) are Codex's work once designs are LOCKed and
the freeze lifts. Full list: `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2_INDEX.md` (never read the register whole).

## 6. Working with Codex

1. You design with Shakeel; he says `LOCK`.
2. You record it in `PRODUCT/APPROVED/<FEATURE>/`: pictures at real phone size with the real bars, every state, a spec
   with numbers, a `LOCK_RECORD.md` line with his words and the date.
3. You write `BUILD_BRIEF_<YYYY-MM-DD>.md` there: locked paths, "copy exactly, no improvements", what not to touch, checks.
4. Shakeel tells Codex one line: "Build <brief path>". You never message Codex.
5. Codex writes a task note in `BLACK UMBRELLA GROUP/REPORTS/DAILY/` with "Built from" and a screenshot beside the master.
6. **You check it** (charter rule 8): MATCH, or each difference with the LOCKed file it breaks, in your chat note.
   Fable checks git, disk and registers and files any difference as an action.

Codex works for ZYRA in his own **ZYRA Codex chat** (opened in the ZYRA project). He does not know your chat
exists except through your files - so everything he needs must be in the LOCK record and the brief.

Every Monday at 08:31 Fable writes `BLACK UMBRELLA GROUP/REPORTS/DAILY/<yyyy-mm>/<date>_ZYRA_RELEASE_READINESS.md`
(what still blocks launch). Launch readiness is yours: read the newest one at the start of a session.

Lessons from AZMARA: never describe behaviour in words only - add a picture of the expected result; settle data,
navigation and states before art; review at real phone size before `LOCK`.

## 7. Where things are

`MAP.md` "Task routes" says which 2-5 documents to open for each kind of task. The blueprint is in
`PRODUCT/BLUEPRINT/`. Group rules (read, never edit): `BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/` - core rules V4,
business chat charters V5, lessons learned V2, saving standard V3.

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-27 | V1 | Created by Fable for the new ZYRA chat (Founder: "everything you know that's for him") |
| 2026-10-27 | V1 | Added: the ZYRA Codex chat; the Monday release-readiness file |
