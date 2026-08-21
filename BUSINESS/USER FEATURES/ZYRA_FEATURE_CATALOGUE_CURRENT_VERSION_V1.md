# ZYRA — Feature Catalogue

**Version:** V1
**Status:** CURRENT_VERSION — derived from ZYRA_PRODUCT_SPEC V5; not itself a decision record
**Date:** 2026-08-13
**Owner:** Founder
**Governing Reference:** ZYRA_PRODUCT_SPEC, ZYRA_GOVERNANCE

---

## 1. How to use this document

This is the single list of what ZYRA does. It exists because features were previously spread across roughly forty documents with no consolidated view, and because the App Store listing, the website and investor conversations all need one.

This document is **DERIVED**. It creates no decisions and changes no rules. Where it disagrees with ZYRA_PRODUCT_SPEC, **the Product Spec wins** and this catalogue is wrong and must be corrected. Where a source document disagrees with another source document, the conflict is recorded here rather than silently resolved — see Section 2.

Every entry below is traceable to one of five sources: ZYRA_PRODUCT_SPEC V5, USER FEATURES/Summary.md, ZYRA PRICING/Summary.md, ZYRA_DECISIONS V2 (2026-08-01 to 2026-08-04), and ZYRA TERMINOLOGY/Summary.md. Nothing has been added from outside them.

### Build Status vocabulary

| Status | Meaning |
|---|---|
| **Built** | A source states it is implemented, and in most cases verified against the live database. |
| **Built (data layer)** | Database, RLS or function layer implemented and proven; no source statement about the screen. |
| **Built, never exercised** | Implemented, but a source reports zero rows or that the path has never run against real data. |
| **Not built** | A source explicitly states it does not exist or does not work. |
| **Deferred** | Product Spec V5 Section 12 lists it as requiring a dedicated specification; it must not be implemented until that specification is approved. |
| **Not stated in sources** | Nothing in the five sources establishes its build status. This is not a judgement that it is unbuilt. |

ZYRA_DECISIONS V2 carries the status line *"RECORD — all items Founder approved and implemented"*, which covers its Sections 1 to 9. Items in its Section 10 ("Still open") are unbuilt. Build statuses below rest primarily on that document; the Product Spec establishes what is approved, not what is built.

### Tier vocabulary

| Tier | Meaning |
|---|---|
| **Basic** | ZYRA Basic — free, the default entitlement on every account. |
| **ZYRA One** | £34.99 per month or £349.90 per year. Purchasable by any account holder, Seeker or Guardian. |
| **Guardian** | The Guardian role at the default (Guardian Basic) capability set. |
| **Guardian+** | The enhanced Guardian capability set — £9.99 per month, or one entitlement bundled with a linked Seeker's ZYRA One. |
| **All** | Available at every tier on which the feature exists. Role restrictions are stated in the description; Browse and profile decisions, for example, are Seeker-only regardless of tier. |

Guardian capabilities are not stored on the Guardian account. They are granted by AIOS per Journey relationship, based on the entitlement the Guardian's own account holds (AD-081, Capability Independence Principle). A Guardian linked to several Seekers may hold different capability grants for different Journey relationships at the same time.

### Core invariant

One Active Journey per Seeker. This holds on both Seeker tiers, is not removed by any subscription, and Product Spec V5 requires it to be enforced at the database layer rather than only in the application. ZYRA One buys flexibility through Pause, not concurrency.

---

## 2. Conflicts between the source documents

These are recorded, not resolved. Each needs a Founder decision or a stewardship pass on the owning document. Rows in Sections 3 to 5 that are affected carry a **Conflict** marker.

| # | Conflict | Sources |
|---|---|---|
| C1 | **Save and Consider daily limits.** Spec V5 gives Basic 10 Saves per day and 10 Considers per day, and ZYRA One unlimited on both. Decisions V2 Section 5 (2026-08-03) gives Save Basic 5, Save ZYRA One 15, Consider Basic 25 (recorded as confirmed and unchanged), Consider ZYRA One unlimited. Three of the four figures disagree, and Decisions V2 also records a Basic Consider limit of 25 as the pre-existing value where the Spec says 10. | Spec V5 §6, §7; USER FEATURES; Decisions V2 §5 |
| C2 | **Who may Pause a Journey.** Spec V5 §6 lists Pause / Resume under "Not Available on ZYRA Basic", and USER FEATURES agrees. Spec V5 Part 0.3 and the Part 3 §5 heading state pause is available on both plans, capped at 5 for Basic and 10 for ZYRA One (DR-ZYRA-138). The body of Part 3 §5 still says only ZYRA One Seekers may Pause and Resume. The Spec contradicts itself. | Spec V5 §6, Part 0.3, Part 3 §5; USER FEATURES |
| C3 | **How many Paused Journeys are permitted.** Spec V5 §7 lists "Unlimited Paused Journeys" as a ZYRA One benefit and Part 3 §5 carries the same sub-heading, but the text under that heading caps it at 5 Basic and 10 ZYRA One, and Part 3 §2 states 1 active plus up to 10 paused. | Spec V5 §7, Part 3 §2, Part 3 §5 |
| C4 | **Whether mixed-tier Pause behaviour is resolved.** Part 0.6 and Part 3 §5 state it is resolved and Findings 1/6 are closed. Section 10 and Section 12 of the same document state it is pending formal resolution. | Spec V5 Part 0.6, Part 3 §5, §10, §12 |
| C5 | **What the standard Compatibility Unlock reveals.** Spec V5 §8 says the Basic automatic unlock gives overall compatibility percentage *and* alignment category counts. Decisions V2 §8.1 (2026-08-04) moved the green / amber / red tallies up into Plus, leaving Unlock as a single number. | Spec V5 §8; Decisions V2 §8.1 |
| C6 | **Retired terminology still in current-version sources.** USER FEATURES uses "Like" and "Profile Unlock"; ZYRA PRICING heads a section "PROFILE UNLOCK PRICING"; ZYRA TERMINOLOGY still lists "Profile Unlock" as a term to define. "Like" became "Consider" on 2026-07-25 (DR-ZYRA-099) and "Profile Unlock" became "Compatibility Unlock" on 2026-08-03. This catalogue uses the current names throughout. | USER FEATURES; ZYRA PRICING; ZYRA TERMINOLOGY |
| C7 | **Guardian tier and Network naming.** The default Guardian tier is "Guardian Basic" in Spec V5, "Standard Guardian" in USER FEATURES, and unnamed in ZYRA PRICING. The Guardian+ network capability is "Guardian Network access" in USER FEATURES and "Family Network" in Spec V5 §11 and §12. | Spec V5 §7, §11, §12; USER FEATURES |
| C8 | **Governing-document version citations.** Spec V5 cites Journey Capability Grant Rules at V1, V2 and V3 in different places, and Guardian Architecture at V4 and V6. ZYRA TERMINOLOGY cites Guardian Architecture V5 and Product Spec V4. These cannot all be current. | Spec V5 header, §3.2, §4, §6, §7, Part 3 §1; ZYRA TERMINOLOGY |
| C9 | **Blocking is both built and deferred.** Spec V5 §12 defers the safety and blocking system pending a dedicated specification. Decisions V2 §4 describes `profile_blocks` already shipped with two-way RLS, and the unblock half completed on 2026-08-03. | Spec V5 §12; Decisions V2 §4 |
| C10 | **The Guardian's action at the Family Review Period.** Spec V5 §8 gives Continue or raise a concern. USER FEATURES lists "Continue / Pause at Family Review Period" as one row and "Raise concern / flag" as a separate row, introducing a Pause action the Spec does not describe. | Spec V5 Part 3 §8; USER FEATURES |
| C11 | **Spec V5 has been edited after its version was cut.** Its version history ends at V5, 2026-07-26, described as terminology-only. The body carries substantive corrections dated 2026-08-09, 2026-08-11 and 2026-08-12 (DR-ZYRA-138, entitlements matrix, JOURNEY_SUSPENSION V2) that no version-history entry records. | Spec V5 Part 0.3, Part 3 §2, Part 3 §5, §13 |

Decisions V2 §8.3 records one further contradiction — the compatibility screen showing 81% under Unlock and 89% under Plus for the same pair — which was resolved to a single 81% and subsequently ratified on 2026-08-11. It is closed and is not carried forward.

---

## 3. Feature catalogue

### 3.1 Account & Onboarding

| Feature | Description | Tier | Build Status |
|---|---|---|---|
| Sign Up | Account creation, the entry point to the platform. | All | Not stated in sources |
| Role selection | An account chooses Seeker or Guardian at onboarding; the role determines how AIOS applies its entitlement. | All | Not stated in sources |
| Create profile | Build the Seeker profile that Browse and matching draw on. | All | Not stated in sources |
| Profile photos | Upload the photos shown on the Browse card and profile page. | All | Not stated in sources |
| Onboarding Chapter 2 — attributes and preferences | Eight personal attributes stored as typed columns and a preference block stored as JSONB in `seeker_details`; attributes are indexed because the scorer queries them across users. | All | Built (2026-08-04) |
| Onboarding Chapters 3 and 4 — compatibility questions | Roughly 174 questions answered into `onboarding_answers`, with a per-category summary that fires the save. | All | Built, never exercised — table verified correct against the live database but at zero rows; no one has walked Chapter 3 signed in |
| Article 9 consent | Explicit consent screen for special-category data, refusing to proceed on an unrecorded "yes". Declining is a real path that skips to languages and still completes the chapter. | All | Built (2026-08-04) |
| Consent versioning and withdrawal | Consent is append-only; withdrawal is a new row, never an update, and `policy_version` records which wording was agreed. No UPDATE or DELETE policy exists, not even for the subject. | All | Built (data layer) |
| Reference data lists | 197 countries (ISO 3166-1, each with a demonym), 184 languages (ISO 639-1) and 29 ethnicities, replacing a 30/20/12 mock list. | All | Built (2026-08-03) |
| Codes-not-labels storage rule | Country, language and ethnicity rows store the ISO code; CHECK constraints reject label forms outright. Relabelling "Turkey" to "Türkiye" changes no user row. | All | Built and enforced (2026-08-04) |
| Location capture | `ZyraProfileService.saveLocation()` writes `profiles.location_text`, which three services read and nothing previously wrote. | All | Built (2026-08-04) |
| Onboarding completion gate | `profiles.onboarding_complete`, maintained by trigger and required by `zyra_can_view_profile` clause 4 and `zyra_can_match`. Applicability accounts for gender and conditional `showIf` rules, so a correctly skipped question is not counted as missing. | All | Built (2026-08-11) |
| Link a Guardian | A Seeker links a Guardian to their account. | All | Not stated in sources — Guardian-to-Seeker links exist in the live database, per the RLS proofs in Decisions V2 §9 and §9.1 |

### 3.2 Browse & Discovery

| Feature | Description | Tier | Build Status |
|---|---|---|---|
| Browse | The primary discovery surface. Appearance-first, showing profile photo, first name, age and location only. No bios, no detailed profile information, no messaging. Seeker-only; Guardian accounts do not use Browse. | All | Built |
| Deliberate absence of an Unlock button in Browse | Browse does not display an Unlock button, so users are never pressed into purchasing while browsing. | All | Not stated in sources |
| Browse volume limit | 50 profiles every 4 hours on Basic; unlimited on ZYRA One. | Basic / ZYRA One | Not stated in sources |
| Save | A private hold meaning "I would like to come back to this profile later". Carries no romantic interest and is never revealed on its own. Seeker-only. | All | Built |
| Consider | An interest signal meaning "I would like to pursue this person". A single Consider is not revealed until reciprocated. Seeker-only. | All | Built |
| Pass | A final rejection. No notification, no explanation, the sender is never informed, the profile disappears silently. Seeker-only. | All | Built |
| One state per profile | Saved, Considering and Passed are mutually exclusive; the most recent action wins. Enforced in three layers — `AppState._clearState()`, three database triggers, and `test/decision_model_test.dart`. Live data migrated: 30 pairs held both, 60 rows became 30, zero conflicts remain. | All | Built (2026-08-03) |
| Saved profiles leave the Browse deck | A consequence of one-state-per-profile; the Browse "Saved" badge became unreachable and was removed. | All | Built |
| Save limit | **Conflict (C1)** — 10 per day on Basic and unlimited on ZYRA One per Spec V5; 5 on Basic and 15 on ZYRA One per Decisions V2. Upgrade copy deliberately does not name the ZYRA One cap, because naming it turns a benefit into a ceiling. | Basic / ZYRA One | Built — figures disputed |
| Consider limit | **Conflict (C1)** — 10 per day on Basic per Spec V5; 25 on Basic per Decisions V2. Unlimited on ZYRA One in both. | Basic / ZYRA One | Built — figures disputed |
| Reset Search | `zyra_reset_search()` clears Passed decisions only, returning those profiles to Browse. | Not stated in sources | Built |
| Decision persistence across launches | Save, Consider and Pass decisions are hydrated at launch in `ZyraSessionRouter`; the `passes` table and its RLS are verified. | All | Built |
| Cached gender for first paint | Gender is cached on device so the gradient renders correctly on first paint, removing a purple-to-pink flash that was a network round trip, not a build-mode artefact. | All | Built |
| Incoming Potentials | ZYRA One Seekers see immediately who has Considered them, and may Consider Back, Save or Pass. Basic Seekers receive nothing and discover matches through their own browsing. | ZYRA One | Not stated in sources |
| Outgoing Potentials | Every Consider a Seeker sends appears in their Outgoing Potentials, so they can track who they have expressed interest in. | All | Not stated in sources |
| Mutual Save Detection | Where two Seekers have saved each other, a Mutual Save Detected signal is raised — but only for the ZYRA One side. A single Save is never revealed. | ZYRA One | Not stated in sources |
| Priority Discovery | Named as a ZYRA One benefit; the full definition requires a dedicated specification. | ZYRA One | Deferred |
| Profile visibility gate | `zyra_can_view_profile` refuses profiles whose owner has not completed onboarding. | All | Built (2026-08-11) |

### 3.3 Matching

| Feature | Description | Tier | Build Status |
|---|---|---|---|
| Match event | Mutual Consider. A Match is an event, not a state: it creates a Potential Journey, appears in each Seeker's Matches section, opens no conversation, consumes no Journey slot, and begins no Guardian involvement. | All | Built, never exercised — `matches` at zero rows |
| Matching eligibility gate | `zyra_can_match` requires completed onboarding on both sides. No question is optional, so a partial profile is not matchable and there is no minimum-items rule. | All | Built (2026-08-11) |
| Compatibility scoring engine | `score_candidates()` produces a plain 0–100 count over the items actually scored: green 1, amber 0.5, red 0. The earlier centred `(total/max)×50+50` scale and its red penalty of −3 are retired. Ratified 2026-08-11. | All | Built |
| Two asymmetric scores | Each Seeker sees how well the other's answers fit their own stated preferences. There is no shared figure; the engine is asymmetric and always was. | All | Built |
| Chapter 2 scoring, extended not replaced | `score_candidates()` reads `seeker_details.preferences` alongside `onboarding_answers`, sharing `v_total` and `v_max` so both chapters land on one 0–100 scale. The Chapter 3/4 block is byte-for-byte unchanged. | All | Built (2026-08-04) |
| Matrix and list preference shapes | Sect is scored as a per-option traffic light; country of birth, nationality, ethnicity and languages are scored as lists — inside the preferred list is green, outside takes the flexibility light. Any shared language counts as green. | All | Built |
| Neutral handling of absence | A skipped answer contributes nothing and never a default green; a candidate who has not completed Chapter 2 contributes nothing rather than being penalised. A user with neither chapter scores everyone 50.0. | All | Built |
| Hard requirement exclusion | Sect carries a hard requirement that excludes rather than scores. Verified on seeded data: 22 of 24 candidates returned, zero red-sect candidates survived. | All | Built |
| Compatibility Unlock | £1.99 for one profile, £7.99 for five. Reveals the overall compatibility percentage — one number. Renamed from "Profile Unlock" and repriced on 2026-08-03. **Conflict (C5)** — Spec V5 §8 still attributes alignment category counts to this tier. | All | Screen built; purchase not chargeable (no payments SDK) |
| Compatibility Unlock Plus | £2.99 for one profile, £9.99 for five. Adds the category-level breakdown and the green / amber / red tallies. A superset of Unlock, so buying Plus unlocks Overall as well. | All | Screen built; purchase not chargeable |
| Free Plus credits on ZYRA One | A ZYRA One Seeker receives 3 free Compatibility Unlock Plus credits. | ZYRA One | Not stated in sources — the itemisation of free versus purchased credits is on the unbuilt buy page |
| Automatic unlock on Active Journey creation | When the Pre-Journey Ritual completes, each Seeker receives their own tier's unlock independently of the other's tier: standard for Basic, Plus for ZYRA One. | Basic / ZYRA One | Not stated in sources — the Journey path has never executed |
| Unlock permanence | One purchase per profile per tier; revisiting never charges again. Enforced by a unique index rather than client checks, because a double tap on a slow connection would otherwise write twice and, once payments are real, charge twice. | All | Built |
| Duplicate unlock rule | If a Seeker paid to unlock a profile and later begins an Active Journey with that person, the automatic unlock has no additional effect. No separate unlock state is tracked. Users pay for earlier access, not for the communication right. | All | Built (via the permanence index) |
| Compatibility screen | One card with two stacked sections — OVERALL (Unlock) above THE DETAIL (Plus) — replacing two swipeable tabs, which taught the wrong relationship by implying the tiers were alternatives. Balance shown in plain words top-right of each section header ("5 left" / "none left"); a padlock on every locked row, so the buyer sees the named categories with every value withheld; an open padlock and "Unlocked" once bought; the button is disabled at zero balance rather than relabelled; "Buy more unlocks" sits as a foot text link. The plus is welded to the word — `Unlock Compatibility+` — so it can never break onto its own line. | All | Built (2026-08-04) |
| Unlocked-data access function | `seeker_details_for_unlocked()`, a `SECURITY DEFINER` function that checks `profile_unlocks` before returning another Seeker's Chapter 2 data. No RLS policy lets one Seeker select the table directly. | All | Built (data layer), proven against the live database |
| Unlocks are personal to the purchaser | A Guardian does not inherit Compatibility Unlocks bought by their Seeker, and does not gain Article 9 data about a third party because the Seeker unlocked it. Shared unlocks, if ever wanted, are a deliberate future feature. | All | Built (data layer), proven against the live database |

### 3.4 Journey

| Feature | Description | Tier | Build Status |
|---|---|---|---|
| Journey Queue | The passive record of mutual interest, formerly displayed as "Potential Journeys". Unlimited, consumes no Journey slot, carries no obligations and has no expiry timer. May coexist with an Active Journey. | All | Screen built (2026-08-03); underlying path never exercised |
| Journey Queue surfacing | ZYRA surfaces queued Journeys as candidates when a Seeker's slot is free. ZYRA One ranks and recommends them on compatibility and activity signals; Basic sees them unranked. The Seeker decides in both cases. | Basic / ZYRA One | Not stated in sources |
| Remove from Journey Queue | Either Seeker may remove a queued Journey at any time. No notification is sent; the relationship returns to No Relationship. | All | Not stated in sources |
| Pre-Journey Ritual | The activation sequence that turns a queued Journey into an Active Journey, and the only mechanism that creates one. Not optional. Salam Exchange (both Seekers must send before Phase 1 unlocks) → Phase 1 questions, AI-chosen → Phase 2 questions, negative-focused → Phase 3 questions, user-chosen. Every phase is revealed simultaneously to both Seekers. Conversation opens only after Phase 3. | All | Not stated in sources — the Journey path has never executed |
| Active Journey | The live marriage journey. On creation: both profiles unlock per tier, conversation opens, Timeline starts, one slot is consumed per Seeker, and Guardian capabilities activate by AIOS grant. | All | Built, never exercised — ten `journey_*` and `timeline_*` tables at zero rows |
| One Active Journey per Seeker | The platform invariant, on both tiers. Spec V5 requires a database constraint preventing two simultaneous active Journey records for the same Seeker, regardless of how the request originates. | All | Not stated in sources — stated as a requirement; no source confirms the constraint exists |
| Journey slot accounting | No slot for No Relationship or Journey Queue; reserved for both during the Ritual; one per Seeker while Active; freed immediately on End. Each Seeker's slot is managed independently of the other's state. | All | Not stated in sources |
| Pause Journey | The Journey moves to Paused Journeys, the conversation closes temporarily, and Timeline and all progress are preserved. **Conflict (C2)** on which tiers may Pause. | Conflict — ZYRA One only, or both plans | Not stated in sources |
| Resume Journey | Resume any Paused Journey at any time. Timeline continues from exactly where it stopped and the conversation reopens. **Conflict (C2)**. | Conflict — ZYRA One only, or both plans | Not stated in sources |
| Paused Journey cap | **Conflict (C3)** — "unlimited" per Spec V5 §7 and the Part 3 §5 heading; 5 on Basic and 10 on ZYRA One per Part 0.3 and the Part 3 §5 body; 10 on ZYRA One per the Part 3 §2 table. Only one Journey may be Active at any time in every version. | Basic / ZYRA One | Not stated in sources |
| Paused Journeys section | A section in the Journeys tab holding paused Journeys. | All | Screen built (2026-08-03) |
| Auto-Pause on inactivity | An Active Journey with no activity from either party for 7 days moves automatically to Paused. The slot is freed for both Seekers and the Timeline is preserved. May be resumed if both parties agree. The 7-day threshold is subject to review. | All | Not stated in sources |
| End Journey | Either Seeker may end an Active Journey at any time. The conversation closes permanently, the slot is freed for both immediately, and the Timeline is preserved as a read-only archive. Restarting requires the full lifecycle again — discovery, Journey Queue, Ritual, Active Journey. | All | Not stated in sources |
| Soft deletion of ended Journeys | Ended Journeys and their conversations are soft-deleted from day one. Hard deletion is not permitted; the database treats them as archived records, not deleted rows. | All | Not stated in sources — stated as a requirement |
| Ended Journeys section | A permanently visible section in the Journeys tab, previously appearing only once something had ended, so nobody could discover it existed. Its stated purpose is to give users closure instead of a Journey disappearing. | All | Screen built (2026-08-03) |
| Journeys tab structure | Four sections: Active Journey (emphasised with a full-white label and brighter card), Journey Queue, Paused Journeys, Ended Journeys. `matches.status` still uses the value `'potential'` — only the display name changed, because renaming the status value would break RLS policies, service queries and the promote RPC. | All | Built (2026-08-03) |
| Timeline | A shared milestone Timeline per Active Journey, beginning at creation. Full milestone Timeline on all tiers; ZYRA One adds ZYRA Insights within the Timeline narrative. Milestone behaviour requires a dedicated specification. | All / ZYRA One | Built, never exercised — `timeline_*` tables at zero rows; milestone behaviour Deferred |
| Question Journey | Chapters of questions punctuated by Family Review Periods, sitting between the Conversation Stage and the Family Stage in the approved sequence. | All | Not stated in sources |
| Family Review Period | A 48-hour pause after both Seekers complete a Journey stage, before the next unlocks. Both linked Guardians are notified; each may Continue explicitly or raise a concern explicitly; silence for 48 hours auto-continues. Deliberate family awareness, not a veto. **Conflict (C10)** on whether a Pause action also exists. | All | Not stated in sources |
| System intelligence (baseline) | Compatibility calculations, Journey progression, the question library and Timeline milestones, available on every tier. Distinct from ZYRA Intelligence, which is ZYRA One only. | All | Not stated in sources |
| Family Stage | The stage after the Question Journey. Future specification. | All | Deferred |
| Meeting Stage | The stage after the Family Stage. Future specification. | All | Deferred |
| Nikah | The terminal completion of a Journey. Future specification. | All | Deferred |
| Proposal Tracker | Named in ZYRA TERMINOLOGY as a surface where both Seekers and Guardians appear. No definition is given in any source. | Not stated in sources | Not stated in sources |

### 3.5 Guardian

| Feature | Description | Tier | Build Status |
|---|---|---|---|
| Guardian role | A male guardian who represents and supports their linked Seeker through the marriage journey in accordance with Islamic guidance. Not the marriage candidate. | Guardian / Guardian+ | Not stated in sources |
| Per-Journey capability grant | Guardian accounts carry identity only. Capabilities are granted by AIOS per Journey relationship from the Guardian's own entitlement, so one Guardian may hold different grants for different Journey relationships simultaneously. | Guardian / Guardian+ | Not stated in sources |
| Guardian capability activation | Guardian capabilities activate at Active Journey creation, per each account's entitlement. | Guardian / Guardian+ | Not stated in sources |
| View Journey progress | See how the linked Seeker's Journey is progressing. | All Guardian tiers | Not stated in sources |
| View messages | See the conversation within the linked Seeker's Active Journey. | All Guardian tiers | Not stated in sources |
| View Timeline | See the linked Seeker's Journey Timeline. | All Guardian tiers | Not stated in sources |
| Family Review Period notification | Both linked Guardians are notified when a Review Period opens. | All Guardian tiers | Not built — the notification system is unbuilt |
| Act at the Family Review Period | Continue explicitly, or raise a concern explicitly. Silence for 48 hours auto-continues. **Conflict (C10)**. | All Guardian tiers | Not stated in sources |
| Raise concern / flag | Raise a concern about the Journey. | All Guardian tiers | Not stated in sources |
| Receive safety alerts | Guardians receive safety alerts relating to their linked Seeker. | All Guardian tiers | Not built — the notification system is unbuilt |
| Family Network access | Access to the network of trusted family representatives. Listed as "Guardian Network access" in USER FEATURES and "Family Network" in Spec V5, which also states the Family Network is exclusive to Guardians holding AIOS-granted Journey capabilities. **Conflict (C7)**. Workflow requires a dedicated specification. | Guardian+ | Deferred |
| Family Introductions | Introductions made through the Family Network. | Guardian+ | Not stated in sources |
| Suggest profiles | A Guardian+ may suggest profiles to their linked Seeker. | Guardian+ | Not stated in sources |
| Guardian AI Summary | An AI-generated summary of the Journey delivered to the Guardian. Delivery is a ZYRA One capability on the Seeker side and a Guardian+ capability on the Guardian side. | Guardian+ | Not stated in sources |
| Included Guardian+ entitlement | A Seeker's ZYRA One includes one Guardian+ entitlement at no extra cost, assignable to any one linked Guardian, covering all that Guardian's Journey relationships with that Seeker. It belongs to the subscription, not the individual: reassigning it reverts the previous holder to Guardian Basic. | ZYRA One → Guardian+ | Not stated in sources |
| Independently purchased Guardian+ | A Guardian who does not receive the included entitlement may buy Guardian+ for £9.99 per month. Behaviour is identical either way once AIOS grants the capability set (AD-081). | Guardian+ | Not stated in sources — payments are unbuilt |
| ZYRA One held by a Guardian | A Guardian account may hold ZYRA One itself, in which case AIOS grants extended Journey-level capabilities. A Seeker's ZYRA One does not determine their Guardian's capability set; each account's capabilities follow its own entitlement. | ZYRA One | Not stated in sources |
| Guardian data scope | A Guardian may read only their own Seeker's Chapter 2 row. Proven live: own Seeker's row returns 1 row; an unrelated Seeker returns 0; a whole-table sweep returns their Seeker only. | Guardian / Guardian+ | Built (data layer), proven |
| No Guardian participation in Browse | Guardians do not browse and do not make Pass, Save or Consider decisions. Browse is a Seeker-only surface. | Guardian / Guardian+ | Not stated in sources |
| No Guardian approval step | There is no Guardian approval or veto of a match. The Guardian's involvement is the Family Review Period, a different mechanism. The older Approve / Concerned / No Opinion vote describes a model that no longer exists. | Guardian / Guardian+ | Not applicable — removed from the product |

### 3.6 Messaging

| Feature | Description | Tier | Build Status |
|---|---|---|---|
| Conversation | Opens at Active Journey creation and stays open throughout. Conversation belongs exclusively to the Active Journey: none exists during the Journey Queue, during the Ritual, or after a Journey ends. | All | Built, never exercised — `conversations` and `messages` at zero rows |
| Send and receive messages | Messaging within the Active Journey. | All | Built, never exercised |
| Read receipts | Message read status within the Active Journey. | All | Built, never exercised |
| Conversation closure on Pause | The conversation closes temporarily when a Journey is paused and reopens on Resume. | All | Not stated in sources |
| Conversation closure on End | The conversation closes permanently when a Journey ends. | All | Not stated in sources |
| ZYRA topic suggestions | Suggested conversation topics within the Active Journey conversation. | ZYRA One | Not stated in sources |
| Mid-conversation ZYRA Insights | Insights surfaced during the conversation. | ZYRA One | Not stated in sources |
| Compatibility context in conversation | Compatibility information surfaced inside the conversation. | ZYRA One | Not stated in sources |
| Guardian ↔ Guardian chat | Direct chat between Guardians. Depends on the Family Stage specification. | Guardian+ | Deferred |
| Guardian communication rules | How Guardians may communicate within a Journey. Depends on the Family Stage specification. | Guardian / Guardian+ | Deferred |

### 3.7 Safety

| Feature | Description | Tier | Build Status |
|---|---|---|---|
| Block a user | `profile_blocks` hides a blocked user in both directions through RLS. Blocked users never appear in Connections. | All | Built |
| Unblock | `unblock()` existed in the service with no caller; the Blocked Users list in Settings supplies the missing half of a feature that shipped with only its first half. | All | Built (2026-08-03) |
| Silent Pass | A Pass sends no notification, gives no explanation, never informs the recipient, and removes the profile silently. | All | Built |
| Private Save | A single Save is never revealed to anyone. Only mutual Saves may generate a signal, and only to ZYRA One users. | All | Built |
| Private match actions | Private actions stay private. Only specifically approved features reveal more, and only where mutual interest has been independently established by both parties. | All | Not stated in sources |
| Stricter RLS on Chapter 2 data | `seeker_details` is deliberately stricter than `profiles`: no policy lets one Seeker select it, and access runs through `seeker_details_for_unlocked()` instead. Proven live — even a holder of a real unlock gets 0 rows on a direct select. | All | Built (data layer), proven |
| Consent defaults to refusal | `has_article9_consent()` returns false for anyone who never consented and on any error — the opposite of how the rest of the codebase treats a failed read, because the cost of being wrong is asymmetric. | All | Built |
| Seed data is greppable | Seeded consent rows carry `policy_version = '2026-08-04-seed'`, so they cannot be mistaken for genuine agreement. | All | Built |
| Safety and blocking system | The overall safety and blocking system requires a dedicated specification. **Conflict (C9)** — parts are already built. | All | Deferred |
| Account deletion and data handling | Required before production launch. | All | Deferred |
| Article 9 legal review | Solicitor review of the consent wording, Privacy Policy, Terms and the Compatibility Unlock flow, before public launch. The Founder has confirmed it will happen; implementation deliberately did not wait. | All | Not built — outstanding |

### 3.8 Notifications

| Feature | Description | Tier | Build Status |
|---|---|---|---|
| Notification system | The notification system requires a dedicated specification. The bell is a placeholder and the notifications store is at zero rows. | All | Not built; specification Deferred |
| Mutual Save Detected | Raised where two Seekers have saved each other, and delivered only to the ZYRA One side. In a Basic-to-Basic pair no one is notified. | ZYRA One | Not built |
| Incoming Potential alert | ZYRA One Seekers are told immediately when someone Considers them. | ZYRA One | Not built |
| Family Review Period notification | Both linked Guardians are notified when a Review Period opens. | All Guardian tiers | Not built |
| Safety alerts to Guardians | Safety alerts delivered to linked Guardians. | All Guardian tiers | Not built |
| Reminder and expiry behaviour | Reminders and expiry prompts across the lifecycle require a dedicated specification. | All | Deferred |

### 3.9 Settings

| Feature | Description | Tier | Build Status |
|---|---|---|---|
| Blocked Users | The list of blocked users, in Settings. Blocking previously had no surface at all: it was one-way and there was nowhere to see or undo it. | All | Built (2026-08-03) |
| Reset Search | Clears Passed decisions only, returning those profiles to Browse. | Not stated in sources | Built |
| Guardian+ entitlement assignment | The Seeker assigns their included Guardian+ entitlement to one linked Guardian, and may reassign it, reverting the previous holder to Guardian Basic. | ZYRA One | Not stated in sources |
| Subscription management | Purchase, upgrade and cancellation of ZYRA One and Guardian+. | All | Not built — no payments SDK in the project |
| Subscription transition rules | What happens to state and entitlements when an account changes tier. Finding E, pending resolution. | All | Deferred |
| Consent withdrawal | Withdrawal is recorded as a new consent row rather than an update. | All | Built (data layer) |

### 3.10 Premium

| Feature | Description | Tier | Build Status |
|---|---|---|---|
| ZYRA Basic | The free default entitlement on every account. Not a trial — a complete product supporting a full marriage journey. | Basic | Not stated in sources |
| ZYRA One | £34.99 per month. Purchasable by any account holder, Seeker or Guardian; the account's role determines how AIOS applies it. | ZYRA One | Not built — unchargeable |
| ZYRA One annual | £349.90 per year, on a 10-months-paid, 12-months-received model. | ZYRA One | Not built — unchargeable |
| Guardian+ | £9.99 per month when purchased independently by a Guardian, or one entitlement bundled with a linked Seeker's ZYRA One. Identical capabilities either way. | Guardian+ | Not built — unchargeable |
| Compatibility Unlock packs | £1.99 for one profile, £7.99 for five (a 19.7% saving, shown as 20%). Purchasable on every tier — manual unlocks operate independently of subscription. | All | Not built — unchargeable |
| Compatibility Unlock Plus packs | £2.99 for one profile, £9.99 for five (a 33.2% saving, shown as 33%). Carries a BEST VALUE badge; Unlock does not. | All | Not built — unchargeable |
| Deliberate price anchoring | The two five-packs sit £2 apart on purpose, so Plus reads as the smarter buy. Savings shown in-app are exact, not rounded up. | All | Not stated in sources |
| Three free Plus credits | A ZYRA One Seeker receives 3 free Compatibility Unlock Plus credits. | ZYRA One | Not stated in sources |
| 7-day ZYRA One trial | Activates automatically when a Seeker's first Active Journey begins — not on Match. The trigger is confirmed; the full terms are deferred. | Basic | Not stated in sources; full rules Deferred |
| Founder Members | The first 1,000 people to purchase ZYRA One, counted purely by headcount and not restricted by role or gender: 50% off for the first 6 months, then 25% off for the following 6. Applies to ZYRA One only. | ZYRA One | Not built — unchargeable |
| Early Adopters | The next 5,000 purchasers of ZYRA One, on the same headcount basis: 25% off for 12 months. Applies to ZYRA One only. | ZYRA One | Not built — unchargeable |
| Buy page | Owns prices, the BEST VALUE badge, and the itemisation of free versus purchased credits — three things the specification requires and no screen currently shows. | All | Not built |
| Payments | Stripe is the intended provider. There is no payments SDK in the project, so every price above is currently unchargeable. | All | Not built |
| ZYRA Intelligence | Recommendations, Insights, Summaries, adaptive questions, conversation topic suggestions and Guardian AI Summary delivery. Active for ZYRA One Seekers from Active Journey creation. | ZYRA One | Not stated in sources |

---

## 4. Tier comparison

### 4.1 ZYRA Basic vs ZYRA One (Seeker)

| Capability | ZYRA Basic | ZYRA One |
|---|---|---|
| Price | Free | £34.99 / month · £349.90 / year |
| Create profile, upload photos | Yes | Yes |
| Browse volume | 50 profiles every 4 hours | Unlimited |
| Save limit | **Conflict (C1)** — 10 per day (Spec V5) or 5 (Decisions V2) | **Conflict (C1)** — unlimited (Spec V5) or 15 (Decisions V2) |
| Consider limit | **Conflict (C1)** — 10 per day (Spec V5) or 25 (Decisions V2) | Unlimited |
| Journey Queue | Unlimited, passive, no slot consumed | Unlimited, passive, no slot consumed |
| Journey Queue ranking | Surfaced without intelligent ranking | Ranked and recommended on compatibility and activity signals |
| Active Journey slots | 1 | 1 — unchanged; ZYRA One buys Pause, not concurrency |
| Pause / Resume Journey | **Conflict (C2)** — No (Spec V5 §6, USER FEATURES) or Yes, capped (Spec V5 Part 0.3, Part 3 §5) | Yes |
| Paused Journey cap | **Conflict (C3)** — none, or 5 | **Conflict (C3)** — unlimited, or 10 |
| Incoming Potentials | No | Yes, shown immediately |
| Outgoing Potentials | Yes | Yes |
| Mutual Save Detection | No | Yes |
| Priority Discovery | No | Yes (definition deferred) |
| Pre-Journey Ritual | Yes | Yes |
| Conversation, messaging, read receipts | Yes | Yes |
| Conversation topic suggestions and mid-conversation Insights | No | Yes |
| Timeline | Full milestone Timeline | Full milestone Timeline plus ZYRA Insights in the narrative |
| System intelligence (compatibility calculations, Journey progression, question library, Timeline milestones) | Yes | Yes |
| ZYRA Intelligence (Recommendations, Insights, Summaries, adaptive questions, Guardian AI Summary delivery) | No | Yes |
| Automatic unlock at Active Journey creation | Standard Compatibility Unlock | Compatibility Unlock Plus |
| Free Compatibility Unlock Plus credits | None | 3 |
| Manual Compatibility Unlock purchase | Yes | Yes |
| Link a Guardian | Yes | Yes |
| Included Guardian+ entitlement | No | One, assignable to any one linked Guardian |
| 7-day ZYRA One trial | Yes, on first Active Journey begin | Not applicable |

Deliberately excluded from ZYRA One, because they conflict with the platform philosophy: unlimited simultaneous conversations, multiple simultaneous Active Journeys, and random boosts that encourage swiping behaviour.

### 4.2 Guardian vs Guardian+

| Capability | Guardian (Guardian Basic) | Guardian+ |
|---|---|---|
| Price | Free | £9.99 / month, or one entitlement bundled with a linked Seeker's ZYRA One |
| View Journey progress | Yes | Yes |
| View messages | Yes | Yes |
| View Timeline | Yes | Yes |
| Receive Family Review Period notifications | Yes | Yes |
| Act at the Family Review Period | Yes | Yes |
| Raise concern / flag | Yes | Yes |
| Receive safety alerts | Yes | Yes |
| Family Network access | No | Yes |
| Family Introductions | No | Yes |
| Suggest profiles | No | Yes |
| Guardian AI Summary | No | Yes |
| View own Seeker's Chapter 2 data | Yes | Yes |
| Inherit the Seeker's Compatibility Unlocks | No | No |
| Browse and profile decisions (Pass, Save, Consider) | No | No |
| Approve or veto a match | No — no such step exists | No — no such step exists |

Capabilities are identical whether Guardian+ arrives bundled or independently purchased (AD-081). USER FEATURES notes that three rows from the retired Guardian table — the Approve / Concerned / No Opinion vote, "Read chats" as a Guardian-only unlock, and Guardian-to-Guardian chat as a paid tier feature — were not carried forward because no current source confirms them. They need re-confirming against Guardian Architecture directly rather than being assumed.

---

## 5. Not yet built

### 5.1 Stated as not implemented

| Item | What the sources say |
|---|---|
| Payments | No SDK in the project. Every price in this document is currently unchargeable. Stripe implementation is an outstanding action. |
| Buy page | Owns prices, the BEST VALUE badge and the free-versus-purchased credit itemisation — three things the specification requires and no screen shows. |
| Notifications | Zero rows; the bell is still a placeholder. Every notification listed in Section 3.8 depends on this. |
| Matches → Journey → Chat | Ten `journey_*` and `timeline_*` tables, plus `matches`, `conversations` and `messages`, are all at zero rows. The entire path has never executed against real data. |
| Chapter 3 answers | `onboarding_answers` is at zero rows. It was verified correct against the live database — primary key, all three RLS policies, foreign key, call site and a full JSONB round trip — and is empty because no one has walked Chapter 3 signed in. The real defect there was a silent `catch (_) {}` on the only input compatibility will ever have; it is now logged. |
| Seeded profile population | 200 seeded Supabase profiles are wanted; 26 exist. Colour-block versions sit behind a dev toggle, and real rows need 200 auth accounts. |
| `profiles.bio` | The column exists and is referenced nowhere. Drop it or use it. |
| Article 9 solicitor review | Review of the consent wording, Privacy Policy, Terms and the Compatibility Unlock flow, before public launch. |

### 5.2 Specified as deferred — must not be implemented until specified

From Product Spec V5 Section 12. These are intentional gaps, not oversights.

| Item | Reason given |
|---|---|
| Pause behaviour in mixed-tier Journeys (Finding 1/6) | Pending formal resolution — though Part 0.6 and Part 3 §5 of the same document state it is already resolved (**Conflict C4**) |
| Family Stage | Full specification required |
| Guardian communication rules | Depends on the Family Stage specification |
| Guardian ↔ Guardian chat | Depends on the Family Stage specification |
| Match Action definitions | Depends on the Family Stage specification |
| Family Network workflow | Depends on the Family Stage specification |
| Compatibility Unlock Plus — full functionality | Dedicated specification required |
| Priority Discovery — full definition | Dedicated specification required |
| Timeline milestone behaviour | Depends on stage transition specifications |
| Notification system | Dedicated specification required |
| Journey activation UX | Screen flow and interaction design required |
| Reminder and expiry behaviour | Dedicated specification required |
| Meeting Stage | Future specification |
| Nikah Stage | Future specification |
| Archive display for ended Journeys | Soft-delete confirmed; display rules deferred |
| Account deletion and data handling | Required before production launch |
| Safety and blocking system | Dedicated specification required (**Conflict C9** — parts are already built) |
| Subscription transition rules | Finding E, pending resolution |
| ZYRA One trial — full rules | Trigger confirmed at first Active Journey begin; full terms deferred |

### 5.3 Open decisions that gate work

| Item | Status |
|---|---|
| Compatibility scoring — how many categories, and which | Open. Part (d) of OA-ZYRA-193, still open after the 2026-08-11 ratification. The built compatibility screen already shows six named categories behind padlocks, so the screen is ahead of the decision. |
| `v_ch2_weight` — the weight of a Chapter 2 attribute | Open. Set to 1, so one Chapter 2 attribute counts the same as one Chapter 3 question. Chapters 3 and 4 ask roughly 174 questions against Chapter 2's 6 attributes, so at weight 1 Chapter 2 moves the final score by only a few percent, which may understate sect and ethnicity for this audience. Left at the neutral value rather than inventing a multiplier; it is a one-line change. Note that this understates Chapter 2's real influence, since sect carries a hard requirement that excludes rather than scores. |
| Regional pricing | To be reviewed before launch. |
| Competitor price validation | To be done before public release. |
| Subscription & Billing Script Summary | To be completed against the current model. |
| Payments Flow Blueprint | To be completed against the current model. |
| Guardian table re-confirmation | The retired Approve / Concerned / No Opinion vote, "Read chats" as a Guardian-only unlock, and Guardian-to-Guardian chat as a paid tier feature were dropped rather than guessed at. If any are still real product behaviour, they need re-confirming against Guardian Architecture directly. |

### 5.4 Standing risks recorded in the sources

| Risk | Detail |
|---|---|
| Unmarked sample compatibility figures | The yellow SAMPLE banner was removed from the compatibility screen on Founder instruction. Nothing on that screen now marks the figures as fake. The buy link still refuses honestly, but a screenshot of "81% overall" travels without a warning. Acceptable while the build is internal; it becomes a real risk at the first demo, investor deck or TestFlight. Recorded, not overridden. |

### 5.5 Named in the sources but undefined

ZYRA TERMINOLOGY carries an approved to-do list of terms that have no definition anywhere in the sources: Potential, Consideration, Connection, Match, Timeline, Proposal Tracker, Profile Unlock, Network, Incoming Potential, Mutual Potential, Notifications, Discovery, Subscription Terminology, AI Terminology, Trust Score, Verification, Compatibility Preview, Compatibility Preview+, and Match Confidence.

Several of these name things that exist elsewhere in this catalogue under a settled name — Match, Timeline, Incoming Potential, Notifications — and are terminology gaps rather than missing features. Trust Score, Verification, Match Confidence, Compatibility Preview and Compatibility Preview+ appear nowhere else in the five sources. They are **not** listed as features in Section 3, because a term on a glossary to-do list is not evidence that a feature exists. "Profile Unlock" and "Compatibility Preview" also predate the 2026-08-03 rename to Compatibility Unlock and should be struck from that list rather than defined.

---

*End of ZYRA Feature Catalogue V1. Derived from ZYRA_PRODUCT_SPEC V5 (2026-07-26), ZYRA_DECISIONS V2 (2026-08-01 to 2026-08-04), USER FEATURES/Summary.md, ZYRA PRICING/Summary.md and ZYRA TERMINOLOGY/Summary.md. No facts originate outside those five documents.*
