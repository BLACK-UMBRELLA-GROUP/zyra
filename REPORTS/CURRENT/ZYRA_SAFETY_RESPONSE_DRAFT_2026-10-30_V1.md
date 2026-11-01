---
id: DOC-ZYRA-0332
type: REPORT
status: DRAFT
feature: LEGAL
purpose: ZYRA safety response procedure - how members report, how the Founder reviews reports in AIOS, response times, abuse-image handling, emergencies, blocks, appeals, records and escalation; drafted from the Safety rules for solicitor review and Founder approval (OA-ZYRA-321)
links: [OA-ZYRA-321, OA-AIOS-413, DOC-ZYRA-0297, DOC-ZYRA-0290, DOC-ZYRA-0293, DOC-ZYRA-0295, DOC-ZYRA-0280, DR-ZYRA-287, DR-ZYRA-095, DR-ZYRA-131, DR-ZYRA-248, DR-ZYRA-268, DOC-ZYRA-0330, DOC-ZYRA-0331, DOC-ZYRA-0333]
owner: Fable
---
DRAFT for solicitor review - not legal advice - placeholders in [brackets]

# ZYRA — SAFETY RESPONSE PROCEDURE — DRAFT V1 (30 Oct 2026)

> **Header note.** Written by Fable (an AI), not by a lawyer or a trust-and-safety professional. It turns the approved Safety
> rules (DOC-ZYRA-0297) and the Founder's decision to review reports himself through an AIOS page (DR-ZYRA-287, OA-AIOS-413)
> into a working procedure. **Today nobody reviews reports** (DOC-ZYRA-0297 §4) - four test reports sit pending. This procedure
> must be in force, and the review page built, before launch (DOC-ZYRA-0297 §6 item 2). Response times and some thresholds are
> accepted by the Founder on 30 Oct 2026 (DOC-ZYRA-0334). Legal references (Online Safety Act duties, abuse-image law)
> are flagged for the solicitor, not asserted.

## 1. Purpose and who this is for

| Item | Detail |
|---|---|
| Purpose | Make sure every report is seen by a person, acted on within a set time, recorded, and that the most serious content (abuse images, threats to life, under-18s) is handled lawfully and fast |
| Reviewer | The Founder, through the AIOS review page (DR-ZYRA-287, OA-AIOS-413) |
| Deputy | **[named person]** - a named deputy reviewer for when the Founder is working, travelling or otherwise unavailable (§10; DOC-ZYRA-0334 #19) |
| Applies to | Reports about profiles, photos, Journey messages and Guardian Circle messages; blocks; safety-concern endings; emergencies raised by any route (app, email, store review, police contact) |

## 2. How a member reports (DOC-ZYRA-0297 §1)

| Step | What the member does | Source |
|---|---|---|
| 1 | Taps Report on a profile, photo, Journey, chat, profile page or from the Guardian side | DR-ZYRA-095 |
| 2 | Picks a reason: fake profile · inappropriate content · harassment · underage · violence · privacy · other; adds optional details | DR-ZYRA-095 (checked by the database) |
| 3 | For a Guardian Circle message: the message is copied into protected evidence at the moment of report | DR-ZYRA-248; `family_message_report_evidence` |
| 4 | Sees the report in "my reports" with a status: pending → reviewing → actioned / dismissed | `zyra_my_safety_cases` |
| 5 | The reported person is never told who reported them | DOC-ZYRA-0280 `profile_reports` |
| 6 | The app says, on the Report page: "ZYRA is not an emergency service. If someone is in danger, call 999." | DOC-ZYRA-0297 §1 |

**Gap for build:** reporting a **Journey message** (not just a profile or photo) is not listed as a surface in DOC-ZYRA-0297 §1 - **accepted (DOC-ZYRA-0334 #21):** message-level reporting with evidence capture, as the Circle already has, goes to OA-ZYRA-317.

## 3. What the Founder sees in the AIOS review page (OA-AIOS-413 - to build)

| Field | Why |
|---|---|
| Queue of open reports, oldest first, with priority band (§5) and age against the response time | So nothing is missed |
| Reason, details, reporter role (Seeker/Guardian), reported person, surface (profile/photo/message/Circle) | Context |
| The reported content: profile card, the photo, the message with the evidence copy - **shown behind a "reveal" click, blurred by default** | So the reviewer is not exposed to harmful images without choosing to be, and abuse images are not viewed twice (§6) |
| Prior history: earlier reports about the same person, blocks against them, identity-check status, account age | Pattern spotting |
| Actions: dismiss · warn · hide photo/content · suspend (with days) · remove account · escalate (police/IWF) · note to member | DOC-ZYRA-0297 §4 "warn, hide, remove" |
| A free-text decision note and the time of decision (audit log, append-only) | §11 records |
| Nothing from the identity-check documents themselves (ZYRA holds only references - DOC-ZYRA-0205) | Data minimisation |

**Accepted (DOC-ZYRA-0334 #21):** the reviewer sees the reported message plus the 10 messages either side, not the full conversation.

## 4. Response times (accepted by the Founder, 30 Oct 2026)

| Priority | Examples | First look | Decision |
|---|---|---|---|
| **P1 Emergency** | Threat to life, suicide risk, a child, a sexual image of a child, a live threat of violence | **Within 2 hours**, any time | Within 24 hours; police/IWF referral immediately if applicable |
| **P2 Serious** | Harassment, sexual content, violence, privacy breach (doxxing), suspected under-18 without a child image | Within 24 hours | Within 72 hours |
| **P3 Standard** | Fake profile, inappropriate content, "other" | Within 72 hours | Within 7 days |

**Accepted (DOC-ZYRA-0334 #20):** these times are the public commitment in the terms (DOC-ZYRA-0330 §8) and the Online Safety Act complaints process (DOC-ZYRA-0333).

## 5. Review steps (every report)

| # | Step |
|---|---|
| 1 | Open the report; set status "reviewing"; assign the priority band |
| 2 | Read the reason and details before revealing any image (§6 applies if an image may be an abuse image) |
| 3 | Check history: prior reports, blocks, identity status |
| 4 | Decide: dismiss (no breach) · warn · hide content · suspend · remove · escalate. Apply the least action that removes the risk; a single credible P1 report is enough to suspend while investigating |
| 5 | Record the decision and reason in the log (§11); set status actioned/dismissed - the reporter sees the status only, never the action taken against the other member (DOC-ZYRA-0330 §8.3) |
| 6 | If content is removed from a Journey or profile, the affected member gets a plain notice with the appeal route (§9) **[notice template wording - Fable to draft]** |
| 7 | **Reviewer wellbeing:** no more than **[N]** P1/P2 reviews in one sitting; take a break after any abuse image; this is a one-person team - see §10 |

## 6. Abuse images (CSAM and intimate-image abuse) - handle with great care

| Rule | Why |
|---|---|
| **Do not view twice.** If a photo is reported as, or appears to be, a sexual image of a child, do not open it again, do not download it, do not share it with anyone except the police or the IWF. One look to confirm the category is the maximum; the review page's blur-by-default protects this | Possession and distribution of such images is a serious offence even for a moderator; the solicitor must confirm the exact position and whether a "memorandum of understanding"-style protection exists for ZYRA's reviewer |
| **Preserve.** Immediately hide the image from all members; keep the stored file and the metadata (uploader, upload time, who reported, when) unchanged in the private bucket; do not delete it until the police or IWF say so or the retention period in §11 passes | Evidence |
| **Report.** Child sexual abuse material: report to the **Internet Watch Foundation** (IWF) and the police. Intimate images shared without consent, threats to share, or extortion: report to the police; tell the victim about the **Revenge Porn Helpline** and StopNCII. **[verify current referral routes and any mandatory-reporting duty - Online Safety Act 2023 and the Crime and Policing legislation in force at launch; solicitor]** | Law and best practice |
| **Suspend** the uploading account at once; do not warn the person that a referral has been made | Avoids tipping off |
| **Under-18 suspicion** (reason "underage") without an abuse image: suspend, request a re-check through the identity provider, remove the account if under 18 (DOC-ZYRA-0297 §5 minimum-age check) | 18+ service |
| **IWF membership and hash-matching:** **Accepted (DOC-ZYRA-0334 #24-25):** ZYRA registers as an IWF member before public launch; hash-matching is added when images are allowed in chat, which they are not at launch (DOC-ZYRA-0297 §6 item 3) | Prevention |

## 7. Emergencies (threat to life, violence, suicide risk)

| Step | Action |
|---|---|
| 1 | If a message or report shows an immediate risk to a person's life: call **999** (UK) and give the police what the account holds (name, age, city, the message); do not wait for the full review |
| 2 | Reply to the reporter in the app or by email with the emergency numbers (999; Samaritans 116 123) - never promise to intervene in person |
| 3 | Suspend the account that poses the risk; keep everything (§6 "preserve") |
| 4 | Record the time of each call and who was spoken to (§11) |
| 5 | **Lawful disclosure to police** is on request or where necessary to prevent a crime or protect life (DPA 2018 Sch 2 para 2 / Art 6(1)(d) vital interests) - **solicitor to confirm the basis and a short disclosure checklist** |

## 8. Blocks and safety-concern endings (DOC-ZYRA-0297 §2-3)

| Rule | Source |
|---|---|
| A block is the member's own instant protection: it ends every Journey between the two (reason: safety concern), closes the chat both ways, removes them from each other's Browse ("User not found"), and removes Circle access. It is permanent for that Journey; unblocking never reopens it | DR-ZYRA-095, DR-ZYRA-131, DR-ZYRA-268, DR-ZYRA-248 |
| A block is not a report. The reviewer does not act on a block alone; the app offers "Also report?" after a block (accepted, DOC-ZYRA-0334 #22) | — |
| The other person and their Guardians see only "prefer not to say" for a safety-concern ending; the note is never shown | DOC-ZYRA-0297 §3 |
| Pattern rule: if one person is blocked by **3** different members in **30** days, the review page raises a P2 case automatically (accepted, DOC-ZYRA-0334 #22) | Proposal |

## 9. Appeals

| Rule | Note |
|---|---|
| A member whose content was hidden or whose account was suspended or removed may appeal within **14 days** by email to **[support@zyraconnect.app - confirm]** | Online Safety Act complaints duty (DOC-ZYRA-0333) |
| The appeal is looked at afresh by **the Founder or the deputy, whichever did not make the original decision** (DOC-ZYRA-0334 #23) - never only by the person who made the original decision where a second person exists | Fairness |
| Decision within **14 days**, with a short reason; abuse-image and police-referral cases are not reopened on appeal | — |
| The reporter may also complain if they think a report was wrongly dismissed; same route | OSA complaints |

## 10. Escalation when the Founder is unavailable

| Situation | What happens |
|---|---|
| Founder at work or asleep | P1 alerts page the Founder's phone (AIOS push to the Founder's phone, SMS fallback - DOC-ZYRA-0334 #19); if no acknowledgement within 2 hours, the deputy takes it |
| Founder away (travel, holiday) | The deputy holds the queue; the Founder reviews the log on return |
| No deputy named | **This is a launch blocker.** A one-person review process with no cover cannot meet a 2-hour P1 time. **Accepted (DOC-ZYRA-0334 #19): the Founder names a deputy - [named person] - under a short confidentiality agreement before launch.** |
| Conflict of interest (the reviewer knows the member) | Hand to the deputy; record it |

## 11. Records

| Record | Where | Kept for |
|---|---|---|
| Every report, status change, decision and reason, reviewer, timestamps | AIOS review page audit log (append-only) + `profile_reports` / `family_message_reports` | **24 months** (DOC-ZYRA-0334 #13) |
| Police / IWF referrals: date, reference number, what was sent | A private referral register in AIOS (not the ZYRA database) | **[e.g. 7 years - solicitor]** |
| Preserved evidence for referrals | Private bucket, hidden from members | Until the authority confirms, then per retention rule |
| Appeals and outcomes | Same audit log | As reports |
| Quarterly summary: counts by reason, time to first look, time to decision, actions, appeals | AIOS report | Feeds the Online Safety Act risk-assessment review (DOC-ZYRA-0333) |

## 12. Before launch (checklist, from DOC-ZYRA-0297 §6)

| # | Must exist | Owner |
|---|---|---|
| 1 | AIOS review page with blur-by-default, actions and audit log (OA-AIOS-413) | Codex (AIOS), Fable brief |
| 2 | A named deputy and the P1 alert route (§10) | Founder |
| 3 | Photo moderation before display (DR-ZYRA-096) | OA-ZYRA-317 |
| 4 | Report retention (24 months) and purge applied; Circle message reporting live | Founder decision → OA-ZYRA-317 |
| 5 | Message-level reporting in Journeys and the "report my Guardian" route (accepted #18, #21) | OA-ZYRA-317 |
| 6 | Safety guidance page in the app (meet in public, involve family, how to report, 999) | Fable drafts, Founder approves |
| 7 | This procedure approved and the four test reports cleared | Founder |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-30 | V1 | First draft from DOC-ZYRA-0297 and DR-ZYRA-287 |
| 2026-10-30 | V1 | Founder accepted all 25 decisions (DOC-ZYRA-0334); placeholders applied |

## Placeholders still to fill

| Placeholder | Where | Who |
|---|---|---|
| [named person] deputy reviewer | §1, §10 | Founder |
| [support@zyraconnect.app - confirm] | §9 | Founder |
| [N] reviews per sitting (reviewer wellbeing) | §5 step 7 | Founder |
| [notice template wording - Fable to draft] | §5 step 6 | Fable |
| [verify current referral routes and any mandatory-reporting duty] | §6 | Solicitor |
| [e.g. 7 years - solicitor] referral register retention | §11 | Solicitor |
