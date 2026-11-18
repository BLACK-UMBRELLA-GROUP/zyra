---
id: DOC-ZYRA-0307
type: DECISION
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: LOCK record for LOCK 2 - Journey requests and Guardians (Seeker side) - the Founder's words, what is locked, and where the locked files are
links: [AD-AIOS-115, DR-ZYRA-284, DR-ZYRA-292, DR-ZYRA-162, DOC-ZYRA-0290, DOC-ZYRA-0283]
owner: ZYRA chat
---

# LOCK RECORD — JOURNEY REQUESTS AND GUARDIANS

| Date | Founder's words | What it locks |
|---|---|---|
| 2026-10-29 18:11 | "ok we can remove saras main gurdia can you requests. maybe these can be in a secion in profiel or somethign which shows what gurdian can do... now add everything to files so i can type go and codex will build and update app" | LOCK 2 as shown in the ZYRA chat prototype (V8): `RECORD/REQUESTS_AND_GUARDIANS_SPEC_CURRENT_VERSION_V1.md` and `MASTERS/` |
| 2026-10-29 17:20–18:15 (choices in the ZYRA chat) | "Show the surname" · "No sorry add past" · "End & accept request / Keep my Journeys" · "Request sent" · Main Guardian message at linking: "Keep it" · Where to tell people the Main Guardian sees requests: "B: Profile section only" | The decided details in the spec §2 |

| 2026-10-29 18:42 | "no i think we remomve listed date and ensure it stays there" | Past items stay; no "listed until" date (spec §2.2 updated before any build) |

**Not locked here:** the Profile section "What Guardians can do" (Founder's idea, 29 Oct). It is designed next and LOCKed
separately (LOCK 7, Profile). Until it exists, nothing in the planned app tells the other person that a Main Guardian can
see their request — see spec §4.

**Device sizes:** masters are iPhone 15 Pro Max (430 × 932 @3x). The Founder decided "iPhone and iPad" on 29 Oct; iPad and
iPhone SE layouts for these screens are not designed yet and are not part of this LOCK.
| 2026-10-30 06:2x | Morning check found Codex's build (line 11) adds things not in the masters: icons on the buttons, outlined Decline/Cancel, a report flag, gold border on an opened card, gold outline on the Profiles card after Request sent, gold "End & accept request" once a Journey is chosen, the app's Sent empty line, and no "‹ Back" (no page in the real app shows Back). Question: keep them or match the pictures? → **"whatever you reccomend"** → ZYRA chat recommends **keep the built version**: it matches the rest of the real app | The pictures in `BUILT/` (commit ddadaf3) are now the reference for this LOCK. No rebuild. The developer button "Demo: recipient accepts" is not part of it (removed with the preview controls, blueprint part 1 §4) |
| 2026-10-31 ~13:35 | "ok now shwo me interactivly how it works if my journey is full and i choose another one via rewuest" → "in profile you can still request no problem but im talking like say you both accept what happens also make it interactive so i can test buttons" → "if 2 people accept but your or thier journey section is full then you gotta decide before accepting who to end it with… give all exmaple" → clickable **"Yes, hold the ending (Recommended)"** + **"Neutral wording (Recommended)"** → clickable **"LOCK it (Recommended)"** | **LOCK 2 V2**: spec V2 §2.5 (accepting when places are full, four cases, held ending, neutral wording, Choose to begin) and the 12 new masters in `MASTERS/` (accept__*, sent__*, my_zyra__accepted_choose_place, preparing__both_ready, requests__past_let_go). Prototype V133. Queue line 65 |

| 2026-11-12 ~17:00 | Developer-panel question "if i send a journey to sara 20 times … how would it show" → clickable **"A · One card per person (Recommended)"** · limit, typed: **"no limit cos they other person might be busy but maybe after 5 attemmots it can go up 14 days then another 5 30 days with 30 days being max limit"** | **LOCK 2 V3**: `RECORD/REQUESTS_AND_GUARDIANS_SPEC_CURRENT_VERSION_V3.md` §2.2 (grouped Past card, ask-again line, 7 / 14 / 30-day wait); reference prototype V204 |
| 2026-11-12 17:14–17:25 | "ok but my journey request card and ended journey request cards look different id want them to be same copying journey request style. nake sense" · "that shoudl apply to all inc introductions" → clickables **"LOCK it (Recommended)"**, **"\"Not taken forward\" (Recommended)"**, **"Into a Past tab"** · deletion: "but if a member left then under gdpr we keep data copy but for user it should go same time the user goes. if its deleted account then it should go no" → **"Ends and goes at once (Recommended)"** · "it shoulnt say this memebr has left zyra it should be account unavalibale but thats copying muzz so give suggestions" → **"D · Profile no longer active"** | **LOCK 2 V4**: spec V4 §2.6 and §2.7; reference prototype V212. Masters (OA-ZYRA-393; added 16 Nov Q161, owner fixed 17 Nov Q163, prototype V231): `ended_journeys__list.png`, `ended_journeys__open.png`, `ended_journeys__empty.png`, `introductions__received.png`, `introductions__received_open.png`, `introductions__received_empty.png`, `introductions__past.png`, `introductions__past_empty.png`, `guardian_introductions_made__not_taken_forward.png`. Fixture owner: Seeker Adam; declined sample = Noor from Hassan (Guardian preview = Hassan) |

Pictures showing sample photos moved to the private group folder 9 Nov 2026 (OA-AIOS-430); recaptured with placeholders when ZYRA restarts.
