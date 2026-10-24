> **SUPERSEDED — ARCHIVED 2026-08-23 (OA-ZYRA-252).** This was the
> 2026-08-22 governed reconciliation draft, and for one day it carried
> CURRENT_VERSION in the APP folder while the ratified lineage lived in
> SYSTEM/DOCUMENTS — two "current" Guardian Network documents at once,
> which the single-current-version rule forbids. The ONE authoritative
> Guardian Network document is now:
> `ZYRA/SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_NETWORK_CURRENT_VERSION_V2.md`
> (D14 ratified + binding), with the build contract
> (`ZYRA_GN_BUILD_CONTRACT_CURRENT_VERSION_V1.md`) and the implementation
> handover (`ZYRA_GN_HANDOVER_CURRENT_VERSION_V1.md`) beside it. Nothing
> in this file overrides those. Reference-only.

# ZYRA — Guardian Network

> **SUPERSEDED / ARCHIVED 2026-08-23 — DO NOT BUILD FROM THIS FILE.** The
> single authoritative product specification is
> `SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_NETWORK_CURRENT_VERSION_V2.md`. The build
> contract is `SYSTEM/DOCUMENTS/ZYRA_GN_BUILD_CONTRACT_CURRENT_VERSION_V1.md`;
> actual implementation is recorded in
> `SYSTEM/DOCUMENTS/ZYRA_GN_HANDOVER_CURRENT_VERSION_V1.md`. This dated file is
> preserved only as the historical APP-level reconciliation draft.

**Version:** 1  
**Status:** SUPERSEDED / ARCHIVED — reference-only historical draft  
**Date:** 2026-08-22  
**Owner:** Fable, Documentation Owner / Architecture Reviewer  
**Founder authority:** Guardian Network initiative and governed-definition
workflow approved 2026-08-22. Product choices marked **FOUNDER DECISION
REQUIRED** are not approved and must not be treated as production rules.

---

## 1. What this document is

This is the single current reconciliation source for the proposed Guardian
Network initiative. It does four jobs:

1. preserves every relevant rule the Founder has already approved;
2. separates those rules from unbuilt proposals and current dev fixtures;
3. exposes contradictions instead of choosing silently between them; and
4. gives the Founder one bounded decision pack before production work begins.

This document does **not** authorise a database migration, production data
access, a new RLS policy, a new notification, or release behaviour. Codex may
build only the reversible, dev-only review surface separately authorised by
the Founder. Production alignment follows Founder decisions and a fresh
implementation handoff.

### Precedence while this draft is open

- A rule labelled **APPROVED EXISTING RULE** remains binding.
- A rule labelled **FOUNDER DECISION REQUIRED** is not binding product
  behaviour.
- A recommendation is Fable's architecture recommendation, not approval.
- The shipped `wali_suggestions` read path and dev fixture are evidence of
  current implementation, not automatic authority for the future Network.
- Where older documents conflict, this document records the conflict but does
  not supersede either side until the Founder decides.

---

## 2. Vocabulary — keep three products separate

### 2.1 Guardian Network

The proposed Guardian-side capability through which an authorised Guardian,
acting in the explicit context of one represented Seeker, can discover an
eligible person or family and begin a bounded introduction flow.

### 2.2 Guardian Suggestion

The existing one-way product object in `wali_suggestions`: a linked Guardian
puts one profile forward privately to their own Seeker. The suggested person
is not a party to that private consideration and must not learn that they were
suggested or declined.

### 2.3 Family Introduction

The older WALI Architecture V6 concept: one Guardian requests an introduction
from another Guardian; both Guardians agree; then both Seekers decide
independently. This bilateral workflow is documented but not built.

These are related but not interchangeable. Calling a one-way Guardian
Suggestion a completed Family Introduction would imply consent and a mutual
relationship that do not exist.

---

## 3. Product purpose and non-purpose

### APPROVED EXISTING RULES

Guardian Network exists to help a Guardian find suitable people or families
for the Seeker they represent and to facilitate an introduction. It is not:

- a second Seeker Browse deck;
- a family directory;
- a way to enumerate who belongs to another person's Guardian network;
- a route around a Seeker's filters, blocks, hidden state or Journey limit;
- a source of a Seeker's Browse activity, Match list or private answers;
- a Guardian-controlled Match or Journey creator; or
- a surveillance surface.

The Guardian supports. The Seeker remains the person whose relationship and
Journey are at stake.

### RECOMMENDED PRODUCT PROMISE

> Your Guardian can put forward someone ZYRA already considers eligible for
> you. You stay in control of whether anything continues.

This wording is a recommendation only; final UX copy belongs to the later
implementation pass.

---

## 4. Binding eligibility and algorithm boundary

### 4.1 Hard eligibility — APPROVED EXISTING RULES

No Guardian Network result may exist unless the represented Seeker and the
candidate pass the same central eligibility boundary used for ordinary Seeker
discovery. A future `can_introduce(guardian, represented_seeker, candidate)`
must fail closed unless all of the following are true:

1. the Guardian has an active link to the represented Seeker;
2. the represented Seeker and candidate pass the central `can_match` rules;
3. the candidate is visible to the represented Seeker under ordinary Browse
   visibility and availability rules;
4. the candidate's visibility is not derived from the Guardian relationship;
5. neither direction is blocked or otherwise safety-excluded;
6. direct Guardian/ward and shared-Guardian exclusions are honoured;
7. the represented Seeker context is explicit and unambiguous; and
8. current entitlement and role authority permit the attempted action.

`can_introduce` must be a server-owned capability predicate before production.
Client filtering is not authority.

### 4.2 Input classification

| Classification | Inputs |
|---|---|
| **Hard eligibility** | Existing central match/discovery requirements; current Seeker discovery preferences that are already hard filters; blocks, hides and safety exclusions; active/profile-complete/availability state; direct Guardian relationship exclusion; shared-Guardian Tier-1 exclusion including active or removed links; one-active-Journey constraints; explicit represented-Seeker context; Network consent once its model is approved. |
| **Ranking** | The same Seeker-to-Seeker compatibility output and existing ranking signals used by ordinary Browse, calculated independently for the selected represented Seeker. Subscription tier may change access or result count only; it must not improve compatibility. |
| **Optional narrowing** | Only filters within the already-eligible result set. Whether a Guardian receives any narrowing controls is a Founder decision. A narrowing control can remove results, never admit an otherwise ineligible result. |
| **Never used** | The Guardian's own romantic preferences or compatibility answers; another ward's answers; the represented Seeker's Browse history, saves, passes, Match list or private Journey answers; Respect Score as ranking; family/network size; Guardian relationship label; Guardian gender; payment tier as a compatibility signal; inferred sensitive data; who else is represented by the candidate's Guardian. |

### 4.3 Compatibility presentation — FOUNDER DECISION REQUIRED

The old architecture says the same compatibility engine operates at Seeker
level. It does not settle whether a Guardian sees:

- no score, only ordered results;
- an overall score;
- category-level percentages; or
- explanatory compatibility text.

**Recommendation:** allow ranking but show no raw compatibility percentage to
the Guardian before both Seekers consent. A score derived from private Seeker
answers is not necessary to make a bounded suggestion and creates an inference
channel. If the Founder wants a reason, use non-sensitive, coarse language such
as “strong alignment” only after a privacy review.

---

## 5. Seeker authority and preferences

### APPROVED EXISTING RULES

1. The represented Seeker's requirements and visibility govern eligibility.
2. A Guardian cannot weaken, replace or bypass those rules.
3. A Guardian action cannot create a Match, Potential Journey or Active
   Journey by itself.
4. Each Seeker makes their own decision independently.
5. The suggested candidate is not notified merely because a Guardian or
   Seeker privately considered, saved, passed or declined them.
6. Guardian access does not reveal the represented Seeker's Browse behaviour,
   Match list, private compatibility answers or private Journey answers.

### FOUNDER DECISION REQUIRED — preference visibility

The Guardian needs enough context to act sensibly, but the current documents
do not approve disclosure of the Seeker's actual private filter values.

**Recommendation:** the system applies the Seeker's preferences invisibly.
The Guardian sees that results are “within [Seeker]'s current preferences” but
not a list of those preferences. The Seeker changes them only in their own
settings.

### FOUNDER DECISION REQUIRED — Network consent

The documents conflict:

- WALI Architecture V6 assumes consent is collected when the link is formed
  and treats Network visibility as available when entitlement permits.
- WALI Requirement and Access Policy V1 confirms no consent field exists and
  proposes Network opt-in off by default, separate photo consent, revocation,
  and possibly per-introduction approval.

**Recommendation:** explicit Seeker opt-in, off by default, revocable at any
time; separate permission for photo visibility; and a per-introduction Seeker
decision before their profile is disclosed to another family. Linking a
Guardian is not consent to advertise the Seeker to a wider network.

---

## 6. Multi-Seeker Guardian context

### APPROVED EXISTING RULES

- One Guardian may represent multiple Seekers.
- Compatibility and eligibility are calculated independently for one ward at
  a time.
- One suggestion/introduction may concern only one represented Seeker and one
  candidate.
- Gender and eligibility are system-enforced, not manually overridden.
- Two Seekers who share a Guardian are Tier-1 excluded from matching. Active
  and removed Guardian links count for that shared-Guardian rule.
- Two Seekers in a Match may not share the same Main Guardian; an existing
  Journey is not silently dissolved if a later relationship change creates a
  conflict.

### FOUNDER DECISION REQUIRED — context selection

WALI Architecture V6 says one eligible ward may be auto-selected and multiple
wards cause a prompt. That is not enough protection against acting for the
wrong person during a long session.

**Recommendation:** every Network screen carries a persistent, visible
“For [Seeker]” context. With one eligible ward it may preselect, but the
context is still shown. With more than one, the Guardian must choose before
any candidates load. Changing context clears transient filters and selections.
No blended household feed is permitted.

---

## 7. Discovery model

### Existing model candidates

| Model | Meaning | Current authority |
|---|---|---|
| **A — Seeker-first** | System selects candidates for the represented Seeker; Guardian sees a bounded subset. | Compatible with the trust audit and same-engine rule. |
| **B — Guardian-first** | Guardian browses people/families based on Guardian-selected criteria. | Not approved; risks a second Browse and preference bypass. |
| **C — Combined** | Seeker eligibility is the hard boundary; Guardian may narrow or order within it. | Not yet approved. |

### FOUNDER DECISION REQUIRED — choose the model

**Recommendation: Model C with a strict interpretation.** Seeker-first
eligibility is absolute. The Guardian may optionally narrow within eligible
results using a small, non-sensitive control set, but cannot broaden the pool
or provide a second set of romantic preferences. Results are finite and
system-curated, not an endless swipe deck.

### FOUNDER DECISION REQUIRED — finite delivery

Choose the delivery shape and cap:

1. a small refreshed set (recommended: 3–5 candidates at a time);
2. a daily/weekly batch; or
3. a request-based “find suggestions” action.

An infinite feed or exact result count is not recommended because both make
enumeration easier. The existing dev fixture's 0/1/3/5/10 control is test data,
not an approved commercial cap.

---

## 8. What a Guardian may see

### APPROVED EXISTING RULES

- Results are system-controlled cards, not Guardian-authored biographies or
  free text.
- The Guardian must not see the represented Seeker's Browse history, Match
  list, private answers or Chapter 3/4 Journey answers.
- The Guardian must not see who else belongs to a candidate's family or
  network merely by discovering that candidate.
- Network visibility must not disclose blocks, hidden users, pass decisions,
  rejected suggestions or why a candidate is absent.

### FOUNDER DECISION REQUIRED — card fields

Current sources disagree:

- WALI Architecture V6 lists initial, age, city, Guardian relationship and a
  Verified Guardian badge.
- The later trust model limits counterpart Guardian cards and removes city and
  photo in that separate context.
- The requirement review proposes separate photo consent.
- The existing Seeker-side Introduction card can resolve and show full profile
  photos after a Guardian suggestion, because it reuses Browse profile reads.

**Recommendation for pre-consent Guardian discovery:** first name or initial,
age, broad area, and a neutral verified-profile state only. No photograph,
biography, exact location, Guardian relationship, Guardian name, network size,
compatibility percentage or contact detail until the approved consent point.
If photos are later enabled, they require separate Seeker consent and
revocation.

“Verified Guardian” must not appear until the product defines and implements
what it proves: identity only, relationship to the Seeker, or both.

---

## 9. Actions and consent path

### APPROVED EXISTING RULES

- A Guardian may put forward at most one candidate for one represented Seeker
  in one action.
- A Seeker's final decision is independent and cannot be made by a Guardian.
- Blocks and safety exclusions always win, including after an item was created.
- Repeat actions must be idempotent; a stale card cannot recreate a closed
  request.
- A private pass or decline is not disclosed to the candidate.

### FOUNDER DECISION REQUIRED — choose the primary workflow

**Option 1 — Direct Guardian Suggestion (shipped object).**

Guardian selects one eligible candidate and sends it privately to their own
Seeker. The Seeker can View, Save, Consider or Pass. Nothing is sent to the
candidate or candidate's Guardian until the Seeker takes the ordinary action
that would be available without the Guardian.

**Option 2 — Bilateral Family Introduction (WALI Architecture V6).**

Guardian A requests Guardian B; Guardian B reviews the represented Seeker and
accepts or declines; only after both Guardians agree do both Seekers receive
the introduction; both Seekers must independently accept before a Potential
Journey can exist.

**Option 3 — Two-step hybrid.**

Guardian first suggests privately to their own Seeker. Only if that Seeker
approves may the Main Guardian send a bilateral request to the candidate's
Main Guardian. The candidate Seeker is invited only after their Guardian
accepts, and still decides independently.

**Recommendation: Option 3.** It keeps the built private suggestion useful,
adds Seeker authority before family-to-family disclosure, and preserves the
Founder's earlier bilateral-family concept without allowing Guardians to
advertise a ward before the ward agrees.

### Withdrawal

**Recommendation:** the represented Seeker may withdraw consent until a
mutual Seeker Match exists. A Guardian may withdraw their own pending outward
request. A block closes the object immediately. No withdrawal reopens a prior
candidate or discloses the reason to the other party.

---

## 10. Main versus Additional Guardian

### APPROVED EXISTING RULES

- Main Guardian is an authority designation, not a subscription tier.
- Guardian+ is a capability grant. It may come from a linked Seeker's included
  entitlement or the Guardian's own subscription.
- The capability source does not change what Guardian+ means.
- Additional Guardian does not inherit Main-Guardian Journey authority,
  counterpart-family visibility or Family Review authority merely by being
  linked.
- Existing documents also say supporting Guardians who independently hold
  Guardian+ retain Guardian+ capabilities. This creates a Network-specific
  authority question; it does not automatically make them Main.

### FOUNDER DECISION REQUIRED — Network authority

Choose one:

1. **Main only sends; Additional may view/save privately** (recommended).
2. Main and Additional may both send, with attribution.
3. Seeker configures per-Guardian Network authority.

Under the recommendation, an Additional Guardian with Guardian+ can explore
the bounded eligible set and save a private shortlist for the Main Guardian,
but only the current Main Guardian can disclose the Seeker externally or send
an introduction. Reassignment changes future authority; it does not rewrite
history. Guardian+ entitlement never upgrades Additional to Main.

### FOUNDER DECISION REQUIRED — own-Seeker suggestion

If the Founder prefers the direct private-suggestion workflow only, allowing
an Additional Guardian to suggest privately to their own Seeker may be safe
because it discloses nothing externally. This should be decided separately
from authority to contact another family.

---

## 11. Entitlements and plan boundary

### APPROVED EXISTING RULES

- Guardian Network / Family Introduction capability is Guardian+.
- Guardian+ may be included through a linked Seeker's ZYRA One entitlement or
  purchased by the Guardian for all their relationships.
- Both entitlement sources grant the same capability; no behavioural
  difference is inferred from how it was obtained.
- Subscription loss changes capability, not relationships, ownership,
  history or retention. Data does not disappear merely because access ends.
- Safety, blocking, reporting and consent withdrawal cannot be paywalled.

### FOUNDER DECISION REQUIRED — downgrade behaviour

**Recommendation:** after Guardian+ loss, no new discovery or outbound request
may be created. Existing history persists. A Guardian retains only the minimum
read/action access needed to withdraw their own pending request or respond to a
safety issue. The Seeker can still decide on an already-delivered private
suggestion because their consent must not become hostage to another person's
subscription. Reactivation restores capability against current eligibility,
never stale cached results.

No Basic/ZYRA One ranking advantage is approved. A future plan may change
batch size, frequency or analytics, but never eligibility, safety or the
Seeker's final authority.

---

## 12. Relationship and exclusion rules

### APPROVED EXISTING RULES

1. An active Guardian link is required to act for a represented Seeker.
2. A Guardian cannot introduce themselves to their own ward.
3. A direct active Guardian/ward pair cannot match.
4. Two Seekers sharing any Guardian are Tier-1 match-excluded; active and
   removed links count.
5. Two Seekers in a Match may not share a Main Guardian.
6. Blocks are terminal for discovery and introduction while they exist.
7. Existing Match/Journey state and central availability rules are rechecked
   at every state transition, not only when the card first loaded.
8. Guardian relationship labels (father, brother, etc.) are descriptive link
   data, not compatibility or ranking inputs.

### FOUNDER DECISION REQUIRED — existing history

Decide whether a candidate with prior Match/Journey history may appear after
the ordinary rediscovery rules allow it. **Recommendation:** defer entirely to
the same central rediscovery rule used by Browse. Guardian Network must neither
accelerate nor permanently forbid a pair on its own.

---

## 13. Abuse, safety and privacy controls

### Non-negotiable architecture constraints

- Server-side `can_introduce`; deny by default.
- Rate limits per Guardian, represented Seeker, candidate and time window.
- Finite opaque result batches; no total count and no family membership list.
- No free-text message attached to discovery or first request.
- No exact location or direct contact details.
- No screenshot-prevention claim: the app may deter and audit, but cannot
  promise screenshots are technically impossible.
- Every view and action attributable in an audit trail.
- Block, deactivate, delete, hide, consent revoke, Main reassignment and link
  removal invalidate cached authority immediately.
- Signed media URLs short-lived and purged/allowed to expire on revocation.
- Reports and blocks available without Guardian+.
- No notification or error may reveal that a hidden/blocked candidate exists.
- The candidate does not learn they were privately suggested, saved, passed or
  declined.
- Respect Score never ranks or exposes candidates.

### FOUNDER DECISION REQUIRED — caps

Set the exact discovery batch, save, outbound-pending and daily-send caps.
**Recommendation for the review prototype only:** show 3–5 results, allow at
most 10 private saves per represented Seeker, and at most 3 pending outbound
family requests. Production values require abuse testing and are not approved
by this document.

### FOUNDER DECISION REQUIRED — Guardian verification

Network access should eventually require a defined verified-Guardian state,
but “verified Guardian” is unresolved. Decide whether it proves:

1. identity only;
2. identity plus the represented Seeker's confirmation of relationship; or
3. identity plus external relationship evidence.

Until defined and implemented, no badge or algorithm preference may imply
more than the system has proven.

---

## 14. Notification contract

The app has an `introductions` notification preference, default enabled, but
that preference does not prove that the following events or delivery paths are
built.

### APPROVED EXISTING RULES

- Opening/seeing a suggestion does not notify the Guardian.
- The candidate is not notified about private Guardian/Seeker consideration.
- Notifications cannot reveal sensitive profile facts on a lock screen.
- Notification opt-out does not change in-app state or consent.

### FOUNDER DECISION REQUIRED — event matrix

Recommended minimum matrix:

| Event | Recipient | Recommended message rule |
|---|---|---|
| Private suggestion delivered | Represented Seeker | “Your Guardian suggested someone.” No candidate name on lock screen. |
| Seeker approves external introduction | Acting Main Guardian | Actionable; no private answer detail. |
| Family request received | Candidate's Main Guardian | Actionable request, identity fields only after approved consent point. |
| Family request declined/withdrawn/expired | Sending Main Guardian | Neutral “request closed”; no reason. |
| Both Guardians agree | Each Seeker | Independent action required; neither Seeker sees the other's decision. |
| Both Seekers accept | Both Seekers, then authorised Guardians | Existing Match/Potential Journey language; never claim an Active Journey early. |
| Consent revoked/block/link removed | Affected authorised party only | Neutral closure; do not disclose block or hidden status. |

Decide whether a private suggesting Guardian learns that their own Seeker
Passed. **Recommendation:** no. They may learn that a suggestion progressed,
or that it closed, but not a rejection reason or view timing. This reduces
family pressure.

---

## 15. Edge-state contract

Every production design and test suite must cover these states.

| State | Required safe behaviour |
|---|---|
| No active represented Seeker | Network unavailable; link/invite path only. |
| One represented Seeker | May preselect, but persistent context remains visible. |
| Several represented Seekers | Guardian chooses one before data loads; no blended feed. |
| Selected link removed | Clear result data immediately; outbound authority ends. |
| Main Guardian reassigned | Old Main loses outward authority immediately; history attribution remains. |
| Additional Guardian opens Network | Behaviour waits on Founder authority decision; never silently act as Main. |
| Guardian+ lost | No new discovery/outbound actions; safe closure/withdrawal remains. |
| Seeker revokes Network/photo consent | Remove future visibility and cached/signed media; close or redact pending objects safely. |
| Candidate blocks/hides/deactivates/deletes | Candidate disappears neutrally; stale actions fail closed. |
| Preferences change | Revalidate before every action; cached eligibility is never authority. |
| Candidate starts another Journey | Revalidate availability and close/refuse stale action neutrally. |
| Duplicate suggestion/request | Idempotent existing object; no duplicate notification. |
| Same/shared Guardian discovered | Central exclusions refuse; do not reveal why. |
| Both users are represented by one Main Guardian | Refuse under shared-Main rule; do not offer self-negotiation. |
| Prior Match/Journey | Follow central rediscovery rule only after Founder confirms scope. |
| Block after request | Close immediately; no reason revealed; safety records preserved. |
| Report during entitlement loss | Reporting remains available and does not restore discovery access. |
| Notification disabled | In-app object remains; no push/email. |
| App offline/retry | No optimistic claim that an introduction was sent; idempotent retry. |
| Account/context switch | Clear all Network cache and selected ward before new context renders. |
| Seeker cannot complete profile | No Network eligibility; explain to that Seeker, not to unrelated Guardians. |
| Existing Active Journey grandfathered after rule conflict | Do not dissolve automatically; prevent new invalid actions. |

---

## 16. Approved existing rules versus new Founder decisions

### 16.1 APPROVED EXISTING RULES — retained

1. Network is Guardian+ and is not a second Browse.
2. It uses Seeker-level eligibility and the same central compatibility engine.
3. Guardian cannot bypass Seeker preferences, safety, blocks or visibility.
4. Guardian cannot create a Match/Journey; Seekers decide independently.
5. One Guardian may represent multiple Seekers; one explicit Seeker context is
   used at a time.
6. Main is authority; Guardian+ is capability; they are not the same concept.
7. Guardian does not gain Browse/Match/private-answer surveillance.
8. Direct and shared-Guardian exclusions apply.
9. Subscription change does not erase relationship/history data.
10. Existing private Guardian Suggestions do not notify the suggested person
    of consideration or rejection.
11. Safety controls are not paywalled.

### 16.2 NEW FOUNDER DECISIONS — approved 2026-08-22

The Founder approved the **work programme**, not the unresolved product model:

1. Fable owns the Guardian Network product-rule reconciliation and governed
   documentation.
2. Codex may build a reversible dev-only UI in parallel from approved existing
   rules and clearly provisional states.
3. No migration, production permission or final backend contract is authorised
   during this definition phase.
4. The Founder will test the prototype and decide unresolved choices; Fable
   then finalises the source of truth; Codex then aligns UI/backend.

### 16.3 FOUNDER DECISIONS STILL REQUIRED

1. Direct suggestion, bilateral family request, or the recommended hybrid.
2. Explicit Network opt-in and separate photo/per-introduction consent.
3. Seeker-first versus strict combined discovery model.
4. Whether Guardians receive any optional narrowing controls.
5. Compatibility score/reason visibility to Guardians.
6. Finite batch shape and exact caps.
7. Exact pre-consent card fields and photo timing.
8. Main versus Additional Guardian Network authority.
9. Downgrade handling for pending items.
10. Notification outcomes, especially whether the suggesting Guardian learns
    a private Pass.
11. What “Verified Guardian” proves.
12. Prior-pair rediscovery treatment (recommended: identical to Browse).

These decisions are tracked together under OA-ZYRA-246.

---

## 17. Contradiction register

| ID | Conflict | Current handling |
|---|---|---|
| GN-C1 | WALI Architecture V6 bilateral family request versus shipped one-way `wali_suggestions`. | Kept as two distinct objects; Founder chooses the future primary workflow. |
| GN-C2 | V6 assumes consent at linking; requirement review says no consent field exists and recommends opt-in. | No claim of consent; Founder decision required before production. |
| GN-C3 | V6 lists city/relationship/badge; later privacy work limits comparable Guardian cards; current Introduction profile can show photos. | Exact Network card fields unresolved; no production field set approved here. |
| GN-C4 | Supporting Guardian+ holders retain capabilities; later trust rules reserve official family visibility/actions to Main. | Capability does not imply Main authority; Network-specific division awaits Founder. |
| GN-C5 | “Family Network” and “Guardian Network” both name the feature; “Family Introductions” also names a Journey stage in older prose. | Canonical feature name in this document is **Guardian Network**; object names are Guardian Suggestion and Family Introduction. Journey Family Review remains separate. |
| GN-C6 | Product Spec says Family Network workflow is deferred pending dedicated spec; V6 labels a detailed flow approved. | This dedicated reconciliation is the missing specification step; old flow is not treated as built. |
| GN-C7 | Current RLS permits any active linked Guardian to insert `wali_suggestions`; Main-only authority is unresolved. | Existing permission is evidence of an over-broad possible future boundary, not approval to expose creation UI. No migration authorised. |
| GN-C8 | `wali_suggestions` status is joint Guardian/Seeker data, while client comments say the Guardian must not learn view timing; notification outcome is unspecified. | Views remain private; outcome notification requires Founder decision. |
| GN-C9 | Older account-type architecture conflicts with ratified one-identity/two-context model. | Dual-role architecture governs; Guardian is a relationship/context, not an immutable account type. |

---

## 18. Production implementation gate

Production work may begin only after OA-ZYRA-246 is Founder-resolved and this
document is revised from reconciliation draft to approved specification.
The implementation handoff must then include:

1. one central server-owned `can_introduce` contract;
2. a six-layer schema/RLS/RPC/client/docs dependency review;
3. data ownership and retention classification for every new object/column;
4. explicit grants and RLS tests for Seeker, Main Guardian, Additional
   Guardian, unrelated Guardian, candidate and blocked users;
5. multi-ward context-isolation tests;
6. idempotency, stale-state, downgrade, reassignment, revoke and block tests;
7. notification preference and non-enumeration tests;
8. cache/media purge behaviour;
9. two-account and multi-Guardian device evidence; and
10. documentation supersession of the affected Guardian sections.

No migration is approved by this document. OA-ZYRA-247 owns later alignment
after Founder decisions.

---

## 19. Evidence and governing sources

- `APP/Standards/WALI_ARCHITECTURE_CURRENT_VERSION_V6.md`
- `APP/Standards/WALI_REQUIREMENT_AND_ACCESS_POLICY_CURRENT_VERSION_V1.md`
- `APP/Standards/JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V4.md`
- `APP/Standards/SUBSCRIPTION_CONTINUITY_PRINCIPLE_CURRENT_VERSION_V1.md`
- `APP/Safety/SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V3.md`
- `APP/Matching/MATCH UX/MATCH_UX_SPEC_CURRENT_VERSION_V1.md`
- `SYSTEM/DOCUMENTS/ZYRA_DUAL_ROLE_ARCHITECTURE_REVIEW_CURRENT_VERSION_V1.md`
- `SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_ROMANTIC_RULES_CURRENT_VERSION_V1.md`
- `SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_OPEN_TOPICS_CURRENT_VERSION_V1.md`
- `SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_SURVEILLANCE_AUDIT_2026-08-08.md`
- `SYSTEM/DOCUMENTS/ZYRA_VIEW_MATCH_SPLIT_RESPONSE_2026-08-07.md`
- `SYSTEM/DOCUMENTS/ZYRA_TRUST_MODEL_ADVERSARIAL_PASS_2_2026-08-08.md`
- `ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5.md`
- DR-ZYRA-104/105/106/123/124/136/137/157/160/171
- Current `wali_suggestions` schema, RLS, service and Seeker-side Introduction
  UI, inspected read-only 2026-08-22.

---

**End of current governed reconciliation.**
