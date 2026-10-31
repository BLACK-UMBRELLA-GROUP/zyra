---
id: DOC-ZYRA-0331
type: LEGAL
status: DRAFT
feature: LEGAL
purpose: Data Protection Impact Assessment for the whole ZYRA member service (ICO template order), drafted from the approved blueprint for a DPO/adviser and solicitor review and the Founder's sign-off; part of the launch legal pack (OA-ZYRA-321)
links: [OA-ZYRA-321, OA-ZYRA-320, DOC-ZYRA-0280, DOC-ZYRA-0290, DOC-ZYRA-0291, DOC-ZYRA-0293, DOC-ZYRA-0295, DOC-ZYRA-0296, DOC-ZYRA-0297, DOC-ZYRA-0205, DOC-ZYRA-0148, DR-ZYRA-221, DR-ZYRA-285, DR-ZYRA-287, DR-ZYRA-292, DR-ZYRA-299, DR-ZYRA-300, DOC-ZYRA-0330, DOC-ZYRA-0332, DOC-ZYRA-0333]
owner: Fable
---
DRAFT for solicitor review - not legal advice - placeholders in [brackets]

# ZYRA — DATA PROTECTION IMPACT ASSESSMENT (WHOLE MEMBER SERVICE) — DRAFT V1 (30 Oct 2026)

> **Header note.** Written by Fable (an AI), not by a lawyer or a qualified data protection officer. It follows the ICO's
> DPIA template order (steps 1-7). The identity-check DPIA (DOC-ZYRA-0205) covers biometrics in depth and is incorporated by
> reference; this document covers the rest of the service. Controller: **[COMPANY NAME, number, address - OA-AIOS-386]**;
> ICO registration **[ICO registration - OA-AIOS-381]**. A DPIA is required here under UK GDPR Art 35 because ZYRA processes
> special-category data (religion, ethnicity) at scale, uses biometric identity checks, and profiles members (compatibility
> scoring) - three items on the ICO's "likely high risk" list.

## Step 1 — Need for a DPIA

| Trigger (ICO list) | Applies? | Where in ZYRA |
|---|---|---|
| Special-category data | Yes | Faith, sect, revert status, ethnicity, nationality answers (DOC-ZYRA-0280 `seeker_details`, `onboarding_answers`; DOC-ZYRA-0296 §1 steps 9-11) |
| Biometric data | Yes | Identity check: selfie liveness and face match (DOC-ZYRA-0296 §1 step 7; DOC-ZYRA-0205) |
| Profiling / automated ordering | Yes | Compatibility scoring orders Browse (DOC-ZYRA-0291 §4; DOC-ZYRA-0148 §4.1) |
| Data about vulnerable people / matching | Yes | Marriage matching; family members as data subjects in their own right (DOC-ZYRA-0148 §3) |
| Innovative sharing with a third party | Yes | A Seeker's requests and Journey data shared with their Main Guardian (DR-ZYRA-292, DR-ZYRA-299) |
| Children | No, by design | 18+ only (DOC-ZYRA-0297 §5); see DOC-ZYRA-0333 for the children's-access assessment |

## Step 2 — Description of the processing

### 2.1 Nature

| Item | Description | Source |
|---|---|---|
| What ZYRA is | A marriage-seeking app in which a Seeker's family Guardians are part of each staged Journey | DOC-ZYRA-0290 "In one paragraph" |
| Who the data subjects are | Seekers; Guardians (full accounts, full data subjects); the other Seeker in a Journey; people named in free text (bios, messages); people shown in photos | DOC-ZYRA-0148 §3 |
| How data is collected | Google/Apple sign-in; onboarding answers; photos; identity-check provider (Sumsub, planned); messages; reports; store purchase records | DOC-ZYRA-0296 §1 |
| Where it is held | Supabase (AWS eu-west-1, Ireland - adequacy applies); photos in a private bucket served by short-lived signed links | DOC-ZYRA-0148 §4.1; DOC-ZYRA-0297 §5 (DR-ZYRA-085) |
| Processors | Supabase; Google and Apple (sign-in, payments); identity provider **[Sumsub - contract not yet signed, DOC-ZYRA-0205 §7]**; Apple and Google push notification services (when push is built); **[crash reporting provider - OA-ZYRA-297]**; no analytics provider - product events collection is off (DOC-ZYRA-0280) (DOC-ZYRA-0334 #14) | DOC-ZYRA-0280; DOC-ZYRA-0148 §4.1 |
| Automated decisions | Compatibility scoring ranks who a Seeker sees; no solely-automated decision with legal or similar effect - members choose whom to request; identity duplicate flags go to human review | DOC-ZYRA-0205 §3 (Art 22); DOC-ZYRA-0148 §4.1 |

### 2.2 Data inventory (from DOC-ZYRA-0280, blueprint part 3). **SC** = special-category (Art 9).

| Area | Data | SC | Lawful basis (Step 4) | Who sees it |
|---|---|---|---|---|
| Account | Name, date of birth (age shown, never DOB), gender, location, bio, role, sign-in identity, recovery email | — | Contract | Other members (public fields); ZYRA |
| Photos | 3-6 photos, order, main photo | — (may reveal religion/ethnicity - treat with care) | Contract | Members who can see you in Browse, via signed links |
| Faith and background | Sect, revert status, country of birth, nationality, ethnicity, languages | **SC** (religion, ethnic origin) | Explicit consent (Art 9(2)(a)), recorded in `consents` before the questions | Unlock details: only after a paid Compatibility Unlock or inside a Journey; private answers: nobody |
| Compatibility answers | 105 private "about you" questions and partner preferences (green/amber/red), hard requirements | **SC in part** (religious practice) | Explicit consent; contract for the scoring result | Nobody; used only to compute scores |
| Consents | Every consent given or withdrawn, append-only | — | Legal obligation (accountability) | ZYRA |
| Identity check | Provider reference, result, duplicate flag; event receipts as hashes; one hashed row per verified person; account-to-person map | **SC** (biometric, at the provider) | Contract/LI (Art 6); explicit consent (Art 9) - see DOC-ZYRA-0205 §3 | Server only (private schema) |
| Discovery | Likes, passes, saves, hidden people, blocks, reports, protection holds | — | Contract; LI (safety) for blocks, reports, holds | Reports never shown to the person reported |
| Journeys | Match status and stage, requests (sent/received/declined/expired), salams, stage and phase answers, ratings, compatibility reveal, milestones, Timeline, conversation and messages | — (free text may contain SC) | Contract; LI (safety) for retention after endings | The two Seekers; Main Guardian and included Additional Guardians (active Journeys only) |
| Guardians | Links, relationship, Main flag, invites, suggestions, per-Journey View/Chat permissions, past-summary consent, family questions and answers, Family Review decisions, ZYRA Codes and look-ups | — | Contract (both Seeker and Guardian are contract parties) | Review responses never shown to the Seekers |
| Guardian Circle | Threads, messages, memberships, read/mute state, reports, protected evidence copies | — | Contract; LI (safety) for reports and evidence | Circle members; evidence to the reviewer only |
| Membership | Subscriptions, Family plans, seats, invitations, ownership transfers, trial ledger per verified person, Unlock purchases and credits | — | Contract; legal obligation (tax/accounting records) | ZYRA; the store holds payment details - ZYRA never sees card numbers |
| Notifications and feedback | In-app notifications, preferences log, feedback, anonymous product events (off) | — | Contract; consent for push (when built, DR-ZYRA-278) | ZYRA |

### 2.3 Scope and scale

| Item | Value |
|---|---|
| Members at launch | Launch target **[number]** members in the first year (DOC-ZYRA-0334 #15) |
| Territories | UK only in the first year (DOC-ZYRA-0334 #15); no transfers outside the UK/EEA beyond the processors named above |
| Retention | See Step 2.5 |

### 2.4 Context

| Factor | Note |
|---|---|
| Expectations | Members join a marriage app that says, on the welcome slides and in the terms, that family Guardians are involved and that an identity check is mandatory (DOC-ZYRA-0296 §1 step 1; DR-ZYRA-221). The Guardian model goes further than any competitor's chaperone (DOC-ZYRA-0148 §3) |
| Power imbalance | A Guardian can hold up a Journey (Family Review) and sees the Seeker's requests. The ZYRA chat's 29 Oct advice ("declared, never discovered") was to tell the other person at the moment of each request; the Founder chose a Profile section instead (DR-ZYRA-299) - recorded as a residual transparency risk (Step 5 R3) |
| Vulnerability | Coercive family dynamics are a known risk (DOC-ZYRA-0148 §3 Q4); the Seeker alone controls linking, Main designation, per-Journey View/Chat and removal (DOC-ZYRA-0290 §2-3) |

### 2.5 Retention (blueprint rules; gaps marked)

| Data | Rule | Source |
|---|---|---|
| Active account | For as long as the account exists | — |
| Deleted account | Photos removed, then the account and 68 of 70 linked records cascade | DOC-ZYRA-0295 §5 (DR-ZYRA-134) |
| The other person's ended Journey after a deletion | Timeline and messages kept **3 months** for the other Seeker; Guardian links end; Circle shows "Former member" | DOC-ZYRA-0295 §5, §7 (DR-ZYRA-285) |
| Ended Journey archive | Messages readable to the two Seekers for **3 months**, never reopened | DOC-ZYRA-0293 §4 |
| Past Journeys list | 3 months | DOC-ZYRA-0295 §3 |
| Declined and expired Journey requests | Kept **12 months**, then anonymised (replaces "no time limit") | Founder 29 Oct (DR-ZYRA-300), amended by DOC-ZYRA-0334 #13 - resolves Step 5 R6; DR-ZYRA-300 to be amended |
| Safety reports and evidence | Kept after deletion for **24 months**, then purged | DOC-ZYRA-0297 §1; DOC-ZYRA-0295 §5; DOC-ZYRA-0334 #13 |
| Guardian Circle messages and reports | Kept while the Journey record exists, then **12 months**, then purged | DOC-ZYRA-0290 §6; DOC-ZYRA-0334 #13 |
| Identity-check results | Per DOC-ZYRA-0205; documents and biometrics at the provider only | DOC-ZYRA-0205 §5 risk 4-5 |
| Trial ledger / verified-person hash | Lifetime (to enforce one trial and one account per person) - survives deletion | DOC-ZYRA-0291 §2; DOC-ZYRA-0280 `verified_people`; **flag for solicitor: justify under LI** |
| Consents log | Append-only; kept **6 years** after deletion | DOC-ZYRA-0280; DOC-ZYRA-0334 #13 |

## Step 3 — Consultation

| Who | How | Status |
|---|---|---|
| Members | A closed pilot of invited members before public launch; their feedback is recorded against this DPIA | DOC-ZYRA-0334 #16 |
| Solicitor | Reviews this DPIA with DOC-ZYRA-0330, 0332, 0333 | OA-ZYRA-321 |
| DPO/adviser | No DPO required at ZYRA's scale; the named adviser **[solicitor]** is the privacy contact (DOC-ZYRA-0148 §4.1) | DOC-ZYRA-0334 #16 |
| Processors | Sumsub contract (bias documentation, under-18 handling, breach duties, rights SLA) | DOC-ZYRA-0205 §5 |

## Step 4 — Necessity, proportionality and lawful bases

| Purpose | Art 6 basis | Art 9 condition (where SC) | Necessity note |
|---|---|---|---|
| Running the account, profile, Browse, Journeys, Guardians, membership | Contract (Art 6(1)(b)) | — | Core service; members cannot be matched without it |
| Faith and background matching | Contract for the scoring; **explicit consent** for holding the answers | Art 9(2)(a) explicit consent, taken just before the questions; without consent the answers are not saved (DOC-ZYRA-0296 §1 step 10) | A marriage app for Muslims cannot work without faith data; consent is genuine because the questions are the member's own choice of what to disclose. **Flag:** the ICO expects consent to be withdrawable - withdrawal is a new `consents` row; the app offers the control in Settings → Privacy (DOC-ZYRA-0334 #17) |
| Identity check | Contract / LI | Explicit consent for biometrics (known freely-given tension - DOC-ZYRA-0205 §3, DR-ZYRA-220) | Necessary to keep minors and duplicates out; proportionate because ZYRA holds only references and results |
| Sharing with Guardians | Contract (the Seeker chooses and controls Guardians; the Guardian is a contract party too) | — | Data minimisation: Main sees requests + public card; Additional see only what the Seeker switches on; nobody sees private answers or Family Review responses (DOC-ZYRA-0290 §3; DOC-ZYRA-0280) |
| Disclosure of a request to the **other** person's Main Guardian | **Legitimate interests** (the other Seeker's family involvement is the product's purpose) with transparency via the Profile section | — | **The weakest point:** the person whose request is seen is told once, in a Profile section, not at the moment (DR-ZYRA-299). Solicitor to confirm LI balance; alternative is restoring B2/B3 wording at the request |
| Safety: blocks, reports, protection holds, evidence copies, keeping reports after deletion | Legitimate interests (member safety); legal obligation where the Online Safety Act applies (DOC-ZYRA-0333) | Art 9(2)(g) substantial public interest / DPA 2018 Sch 1 para 18 safeguarding - **solicitor to confirm** where a report contains SC | Proportionate: evidence captured at the moment of report only; reviewer access only |
| Compatibility scoring (profiling) | Contract | — | Not a solely-automated significant decision; disclosed in the Privacy Notice; the member chooses |
| Tax and purchase records | Legal obligation | — | Store receipts; ZYRA holds no card data |
| Push notifications (when built) | Consent | — | DR-ZYRA-278 |

Individual rights: access, rectification (profile edit; DOB and gender frozen after publish - DOC-ZYRA-0295 §2, so rectification of those goes through support), erasure (delete account, DOC-ZYRA-0295 §5), restriction (Pause My Profile is a partial analogue), portability (Settings → Download my data - to be built, **[OA placeholder]**; DOC-ZYRA-0334 #17), objection to LI processing, withdrawal of consent, complaint to the ICO.

## Step 5 — Risks (L = likelihood, S = severity; Remote/Possible/Probable × Minimal/Significant/Severe)

| # | Risk to individuals | L | S | Overall |
|---|---|---|---|---|
| R1 | Special-category answers (faith, ethnicity) exposed to other members or leaked | Possible | Severe | High |
| R2 | A coercive Guardian uses Journey visibility or Family Review to control a Seeker | Possible | Severe | High |
| R3 | The other Seeker does not realise their request and public card are seen by a Main Guardian (DR-ZYRA-299) | Probable | Significant | High |
| R4 | Identity-check harms (false reject, bias, provider breach, minors) | Possible | Significant | Medium (see DOC-ZYRA-0205) |
| R5 | Messages or photos used for abuse, harassment or image-based abuse; no photo moderation at launch | Possible | Severe | High |
| R6 | Data kept longer than needed: declined/expired requests with no limit (DR-ZYRA-300), undated report and Circle retention, lifetime verified-person hash | Probable | Significant | High |
| R7 | Reports reviewed by one person (the Founder) - delay, inconsistency, conflict of interest, unavailability | Probable | Significant | High |
| R8 | A deleted member's data lingers in the other person's ended Journey (DR-ZYRA-285) | Probable | Minimal | Low |
| R9 | Send rule in repository files lost block/ended checks (DOC-ZYRA-0293 §6) - a blocked person could message | Possible (not live today) | Severe | Medium |
| R10 | Profiling by compatibility score unfairly hides some members | Possible | Significant | Medium |
| R11 | Guardian added without a real family relationship (impersonation of a Guardian) | Possible | Significant | Medium |
| R12 | Breach of the main database | Remote | Severe | Medium |

## Step 6 — Measures to reduce risk

| Risk | Measures (built / planned, with source) | Effect | Residual | Approved? |
|---|---|---|---|---|
| R1 | Private answers never shown, functions only; Unlock details only after a paid Unlock or in a Journey; consent before the questions; RLS; private schema (DOC-ZYRA-0295 §1, DOC-ZYRA-0297 §5, DR-ZYRA-250) | Reduced | Low-Medium | [ ] |
| R2 | Seeker alone links, designates Main, sets View/Chat per Journey, removes any Guardian; may have no Main; Family Review responses hidden from Seekers; safety-concern endings show "prefer not to say" (DOC-ZYRA-0290 §2-3; DOC-ZYRA-0297 §3). **Planned:** in-app guidance on coercive control and a "report my Guardian" route from the Guardian's page, hidden from the Guardian (DOC-ZYRA-0334 #18) | Reduced | Medium | [ ] |
| R3 | B1 and B4 notices to the Seeker and Main Guardian; Profile section "What Guardians can do"; Privacy Notice section "What Guardians see" (DOC-ZYRA-0290 §3; DR-ZYRA-299). **Recommended:** restore the one-line B2/B3 notice at the request (withdrawn 29 Oct) or add a one-time first-request notice | Reduced | **Medium-High until the solicitor confirms** | [ ] Founder to decide |
| R4 | All DOC-ZYRA-0205 §5 measures; provider contract terms | Reduced | Medium-Low | [ ] |
| R5 | Photo moderation before display (launch gate, DOC-ZYRA-0297 §6 item 3); report and block from every surface; evidence captured at report; safety procedure DOC-ZYRA-0332; OSA duties DOC-ZYRA-0333 | Reduced once built | Medium | [ ] |
| R6 | Retention set (DOC-ZYRA-0334 #13): reports 24 months; Circle messages while the Journey record exists then 12 months; consents 6 years; Past requests 12 months then anonymised; the lifetime verified-person hash still needs an LI justification from the solicitor | Reduced | Low-Medium | [ ] |
| R7 | Safety procedure with response times, a named deputy and an escalation path when the Founder is unavailable (DOC-ZYRA-0332 §10); records of every decision | Reduced | Medium | [ ] |
| R8 | 3-month limit on the other person's archive (DR-ZYRA-285); the deleted member is shown as "has left ZYRA", not by name **[confirm with Codex at build]** | Reduced | Low | [ ] |
| R9 | OA-ZYRA-319: fix the send rule before any of those files are applied; production still has the 9 Aug rule | Eliminated once fixed | Low | [ ] |
| R10 | Disclose scoring in the Privacy Notice; Browse still shows everyone eligible, scoring only orders; no solely-automated decision | Reduced | Low | [ ] |
| R11 | Guardian states relationship; Seeker must accept; identity check for the requester; Main Guardian can be changed or removed (DOC-ZYRA-0290 §1-2) | Reduced | Low-Medium | [ ] |
| R12 | RLS, private storage, signed links, server-authoritative functions, leaked-password protection (OA-ZYRA-312), 5 Oct security fixes to go live (DOC-ZYRA-0294) | Reduced | Low | [ ] |

## Step 7 — Sign-off and outcomes

| Item | Name / date | Notes |
|---|---|---|
| Measures approved by | Founder: Shakeel Ahmad, [date] | Carry the DOC-ZYRA-0334 answers into the blueprint and OA-ZYRA-317 |
| Residual risks approved by | Founder: [date] | If any residual risk stays High after measures, prior consultation with the ICO (Art 36) is required - **solicitor to advise on R3 and R6** |
| DPO/adviser advice | **[solicitor]**, [date] | Advice accepted / overruled (reason) |
| Solicitor review | [name], [date] | With DOC-ZYRA-0330, 0332, 0333 |
| Review date | 6 months after launch, and on any change to Guardian visibility, retention or the identity provider | Fable proposal; **[review date - confirm]** |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-30 | V1 | First draft from DOC-ZYRA-0280 and the part 2 blueprint pages; DR-ZYRA-299 and DR-ZYRA-300 recorded as risks R3 and R6 |
| 2026-10-30 | V1 | Founder accepted all 25 decisions (DOC-ZYRA-0334); placeholders applied |

## Placeholders still to fill

| Placeholder | Where | Who |
|---|---|---|
| [COMPANY NAME, number, address - OA-AIOS-386], [ICO registration - OA-AIOS-381] | Header note | Founder |
| [Sumsub - contract not yet signed] | Step 2.1 | Founder (OA-ZYRA-317 item 8) |
| [crash reporting provider - OA-ZYRA-297] | Step 2.1 | Founder |
| [number] launch target | Step 2.3 | Founder |
| [solicitor] named adviser | Step 3, Step 7 | Founder |
| [OA placeholder] for Download my data | Step 4 | Fable (raise the OA) |
| [review date - confirm]; names and dates in Step 7 | Step 7 | Founder, solicitor |
