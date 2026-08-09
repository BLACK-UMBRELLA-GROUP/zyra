# ZYRA — Guardian Requirement, Access & Consent Policy

**Version:** V1
**Status:** **PROPOSED — awaiting Founder approval. Nothing here is implemented.**
**Date:** 2026-08-01
**Author:** Claude (Opus), Implementation Lead
**Commissioned by:** Founder via ChatGPT — consolidating the Guardian Gate timing question, the conversation-transparency decision, subscription limitations, and Guardian Network consent into one governed source.
**Supersedes on approval:** the Guardian sections of `WALI_ARCHITECTURE_CURRENT_VERSION_V6.md` that conflict with it (see §1.2).

**Not legal advice.** §7 flags what a solicitor must rule on.

---

## 0. Why this document exists

Three contradictions surfaced in a single day, all from rules spread across
documents that had drifted apart:

1. `WALI_ARCHITECTURE_V6`'s design principle says *"not surveillance"*; its own
   permissions table says *"View messages ✓"*. The database sides with the table.
2. The app told every Guardian they would see progress *"without reading their
   private conversations"*. False.
3. The Guardian Gate is documented as a requirement to begin, but is implemented as
   a stage that runs **after** the Journey has already started.

Consolidating was the right call. This document is the single source of truth for
what a Guardian is, what they may see, when they are required, and what the Seeker is
consenting to.

---

## 1. Ground truth — what is actually built today

**Verified against the live database and source, 2026-08-01.** This section exists
because every contradiction above came from documents describing intent as
though it were behaviour.

### 1.1 What is real

| Capability | State | Evidence |
|---|---|---|
| Guardian account type, own shell | ✅ Built | `wali_home_shell.dart` |
| Linking via invite token | ✅ Built | `wali_invites`, 8-char token, 7-day expiry |
| Main Guardian designation | ✅ Built | `wali_links.is_main`, auto-designated on first active link |
| Guardian reads Journey progress | ✅ Built | `zyra_wali_journey_service.dart` |
| **Guardian reads full conversation** | ✅ **Built** | `messages_select` RLS — access from `status <> 'potential'` |
| Family Review Period (48h) | ✅ Built | `20260726190000_family_review_period.sql` |
| Guardian+ entitlement resolution | ✅ Built | `wali_has_wali_one()` |
| **Guardian Gate blocks Journey start** | ❌ **NOT built** | `promote_journey_to_active` has no Guardian check |
| **Guardian Network sharing** | ❌ **NOT built** | `wali_network_screen.dart` is a paywall screen only; no sharing logic anywhere |
| **Any consent record** | ❌ **NOT built** | `wali_links` columns are: id, seeker_id, wali_id, status, created_at, is_main. **No consent field exists.** |
| Suggest profiles | ❌ Not built | `wali_suggestions` table exists; no UI writes to it |

**The two most consequential lines are the last three.** The Guardian Network is
unbuilt and there is no consent infrastructure — so this can be designed
correctly rather than retrofitted onto something already wrong.

### 1.2 Corrections this document makes to `WALI_ARCHITECTURE_V6`

| V6 says | Correction |
|---|---|
| Design principle: "not surveillance" alongside "View messages ✓" | Both are kept, but the principle describes the **role**, not an access limit. It may never again be used to imply the Guardian cannot read conversations. |
| "A Seeker must have a linked, active Main Guardian to proceed" (ambiguous on *when*) | Made precise in §2. |
| Guardian+: "Guardian Network access ✓" | Unbuilt. Must not be sold or described as available until §5 is implemented. |

---

## 2. When a Guardian is required

### 2.1 The rule

**A Journey may not be promoted to Active unless every participant who requires a
Guardian has an active, linked Main Guardian.**

Enforced **server-side in `promote_journey_to_active`**, not as a later stage.

### 2.2 Why the timing matters more than it appears

This is not tidiness. Guardian conversation access begins the instant
`matches.status` leaves `'potential'`. With the gate in its current position:

> Two Seekers start a Journey with no Guardian linked. They exchange messages
> believing nobody else can read them. A Guardian links three days later and can
> **read the entire back-history**, including everything written before he
> existed.

That is retroactive disclosure of private correspondence to a third party, with
no consent at the time of writing. It is the one scenario where "transparency by
design" is not true — because the people involved could not have known.

Moving the requirement before promotion makes the Start Journey disclosure
accurate from the first message. **This is a safeguarding fix, not a sequencing
preference.**

### 2.3 Who requires a Guardian — OPEN, Founder decision

`WALI_ARCHITECTURE_V6` defines a Guardian as a male guardian supporting a female
Seeker. A male Seeker has no Guardian. The rule must therefore be one of:

| Option | Rule | Consequence |
|---|---|---|
| **A** *(recommended)* | The **female** participant must have an active Main Guardian | Matches the religious model. A male Seeker is never blocked for lacking something he is not expected to have. |
| **B** | **Both** participants must have one | Blocks every Journey, since male Seekers do not have Guardians. Only viable if ZYRA introduces a male-side guardian concept. |
| **C** | Either party may proceed without one | Contradicts the Guardian Gate entirely and reopens the retroactive-access problem. |

**Recommendation: A.** Not implemented pending confirmation.

### 2.4 What a Seeker can do without a Guardian

| Action | Without a Guardian |
|---|---|
| Create profile, upload photos | ✅ |
| Browse, Consider, Save, Pass | ✅ |
| Match — hold Journey Queue | ✅ (unlimited) |
| **Promote to Active Journey** | ❌ **Blocked** (per §2.1) |
| Message another Seeker | ❌ Conversation only opens inside an Active Journey |
| Block, report, hide profile, delete account | ✅ **Always. Safety is never gated.** |
| Purchase ZYRA One | ✅ — but see §6 |

---

## 3. Access policy — what a Guardian sees

### 3.1 Both Guardians, from Journey activation

Founder decision, 2026-08-01: **transparency by design.** There are no fully
private conversations inside an Active Journey.

| A linked Guardian CAN see | A linked Guardian can NEVER see |
|---|---|
| Journey progress and current stage | Chapter 3 values answers |
| The **full conversation** between both Seekers | Chapter 4 preferences / compatibility settings |
| Family-stage questions and answers | Browse activity — who was seen, saved or passed |
| Timeline milestones | The Seeker's other Journey Queue |
| Family Review Period state, Continue/Pause | Any Journey they are not linked to |

### 3.2 The point most easily missed

`messages_select` grants access to a Guardian linked to **either** participant:

```
wl.seeker_id = ANY(ARRAY[m.seeker_a_id, m.seeker_b_id])
```

So a man's messages are read by **his match's Guardian** — someone he has no
relationship with, did not invite, and may not have known existed.

This is coherent with the philosophy, but it is a materially larger disclosure
than "your Guardian sees your messages", and it lands on someone who never entered
into the guardian relationship. **Every disclosure must say "your Guardian and
theirs".** Saying only "your Guardian" is a second, subtler untruth.

### 3.3 Required disclosures

| Where | What it must say | State |
|---|---|---|
| Start Journey confirmation | Both Guardians can read the conversation from this moment | ✅ Implemented 2026-08-01 |
| Guardian onboarding | You will be able to read conversations; both Seekers are told | ✅ Implemented |
| FAQ / Help Centre | Two entries, incl. the other Seeker's question | ✅ Implemented |
| Seeker onboarding | Stated before a Guardian is ever linked | ❌ **Gap** |
| Terms of Service | Formal clause | ❌ Pending drafting |
| Website (For Guardians & Families) | Public statement | ❌ Pending |

---

## 4. Consent architecture

### 4.1 The principle

Linking a Guardian is not one permission. It is **several distinct disclosures with
very different risk profiles**, and UK GDPR requires consent to be *specific*,
*granular*, *freely given* and *as easy to withdraw as to give*.

### 4.2 The proposed consent set

| # | Permission | Risk | Bundling |
|---|---|---|---|
| **C1** | Guardian sees Journey progress, stages, Family Review | Low | **Bundled** — this is the Guardian role itself. Without it there is no relationship. |
| **C2** | Guardian reads the full conversation once a Journey is Active | High | **Bundled**, but disclosed prominently and separately *worded*. It is inseparable from the product's philosophy — a Seeker who refuses it cannot use ZYRA, and should be told so plainly rather than shown a checkbox that does nothing. |
| **C3** | **Guardian may display the Seeker's profile in their Guardian Network** | **Very high** | **SEPARATE, OPT-IN, DEFAULT OFF** |
| **C4** | **Guardian may share the Seeker's photos within that Network** | **Highest in the product** | **SEPARATE, OPT-IN, DEFAULT OFF, independently revocable** |
| **C5** | Guardian may formally introduce the Seeker to another Guardian | Very high | **SEPARATE, and per-introduction approval — see §5** |

### 4.3 Why C3–C5 cannot be bundled with C1–C2

ChatGPT asked whether these should be separate permissions or one bundled
consent. **This is not a UX preference — it is very likely a legal requirement.**

1. **Granularity.** UK GDPR Art. 7 and ICO guidance are explicit that consent
   covering several distinct processing purposes must be separable. "Accept to
   link your Guardian" that silently authorises photo distribution to unknown third
   parties is the textbook example of what is not valid.
2. **Freely given.** If a Seeker must accept network-sharing to link a Guardian, and
   must have a Guardian to progress (§2.1), then the consent is a condition of
   accessing the service. Art. 7(4) says that weighs heavily against validity.
3. **Special-category data.** A ZYRA profile carries religious practice and
   ethnicity — Article 9 data. Distributing it to third parties needs *explicit*
   consent for that specific disclosure.
4. **It is the wrong thing to do.** A woman's photographs shown by her guardian
   to men she has never met, without her seeing who they are, is the single
   highest-harm capability in the product. In this community the reputational
   consequence of that going wrong is not recoverable.

**Note the irony.** ZYRA's entire case against Muzz is that we do not do things
to users behind their back. A bundled consent that quietly authorises photo
distribution would be exactly the pattern the teardown criticised, wearing our
own branding.

---

## 5. Guardian Network — design requirements

**Unbuilt. These are the conditions under which it may be built.**

1. **Off by default.** No Seeker appears in any Network without an affirmative,
   separate opt-in.
2. **Visible.** The Seeker can see, at any time, which Guardians her Guardian has shared
   her with. A network she cannot see is one she cannot meaningfully consent to.
3. **Per-introduction approval** (recommended). The Guardian proposes; the Seeker
   approves before her profile reaches a specific other Guardian. Blanket
   "any Guardian in my network, any time" is the weakest defensible form.
4. **Photos separable from profile.** C4 revocable without revoking C3.
5. **Instantly revocable**, and revocation is not a negotiation with the Guardian.
6. **Audit trail.** Who was shown what, and when. Required to answer a subject
   access request, and to investigate a complaint.
7. **Purge on revocation.** Removing the link or the consent removes the Seeker
   from the Network and invalidates any cached or signed URLs. "They disappear
   from the list" is not sufficient if the underlying photo links still resolve.
8. **Receiving Guardians are data recipients.** They must be bound by the Terms as a
   condition of Network access — including a prohibition on saving, screenshotting
   or forwarding.

### 5.1 What ZYRA cannot promise

Once a photo is visible to another human, technical controls end. The Terms must
say so plainly, and the consent screen must not imply otherwise. Screenshot
protection (a Muzz feature ZYRA lacks — see the teardown) would reduce but not
eliminate this.

---

## 6. Subscription interaction

**Founder's standing rule: no one may buy a subscription expecting functionality
they cannot use.**

| Feature | Requires an active Guardian? |
|---|---|
| Unlimited browsing, Saves, Likes | No |
| Incoming Potentials | No |
| Pause / Resume Journey | Requires an Active Journey → therefore requires a Guardian (§2.1) |
| Guardian+ entitlement (bundled) | **Yes — worthless without a linked Guardian** |
| Guardian Network | Yes, plus C3–C5 (unbuilt) |

**Required pre-purchase warning, where the buyer is a Seeker with no linked Guardian:**

> Some ZYRA One features need a linked Guardian — including the Guardian+ entitlement
> included with your subscription. Subscribing does not remove that requirement.
> You can link a Guardian at any time.

Status: ❌ not implemented. The general subscription disclosure (price, renewal,
14-day right) **was** implemented 2026-08-01; this conditional warning was not.

---

## 7. For the solicitor

1. **Is C2 lawful as a condition of service?** ZYRA's position is that reading
   conversations is constitutive of the product, so a Seeker who declines cannot
   use it — analogous to declining a core term. Needs confirming.
2. **Article 9 route** for religious data — carried over from
   `ZYRA_LEGAL_RESEARCH` §2A, and now compounded by C3–C5 disclosing that data
   to third parties.
3. **Is the Seeker or ZYRA the controller** for Network disclosures? Both,
   probably jointly — which changes what the Terms must contain.
4. **Are receiving Guardians controllers** once they hold her data?
5. **Capacity and coercion.** ZYRA gives one adult power over another's
   process. What is ZYRA's duty where a Guardian is coercive, and what escalation
   route must exist?
6. **Online Safety Act** — the Guardian is a third party reading user-to-user
   communications. Does that alter ZYRA's duties?

---

## 8. Founder decisions required

| # | Decision | Blocks |
|---|---|---|
| 1 | §2.3 — who requires a Guardian: female only (A), both (B), or neither (C) | The `promote_journey_to_active` migration |
| 2 | Ratify §1.2 corrections to `WALI_ARCHITECTURE_V6` | Every document citing V6 |
| 3 | Confirm C3/C4/C5 are separate, opt-in, default-off | Guardian Network build |
| 4 | Per-introduction approval, or blanket network consent | Guardian Network build |
| 5 | Approve the §6 pre-purchase warning wording | Upgrade screen |
| 6 | Seeker-onboarding disclosure of Guardian message access | Onboarding copy |
| 7 | Escalation route for an obstructive or coercive Guardian | Safeguarding, Terms |

---

## 9. Version History

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-01 | Initial policy. Consolidates the Guardian Gate timing bug, the conversation-transparency decision, subscription limitations and Guardian Network consent. Grounded in a verified audit of what is built. |
