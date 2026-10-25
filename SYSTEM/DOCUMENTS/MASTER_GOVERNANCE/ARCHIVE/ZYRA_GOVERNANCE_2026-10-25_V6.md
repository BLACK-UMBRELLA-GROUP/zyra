---
id: DOC-ZYRA-0269
type: RULES
status: SUPERSEDED
feature: ZYRA GOVERNANCE
purpose: ZYRA — Project Governance
links: []
owner: ZYRA chat
---

> **SUPERSEDED 25 Oct 2026** by `MASTER_GOVERNANCE/ZYRA_RULES_CURRENT_VERSION_V1.md` (DOC-ZYRA-0277). History only — its roles table describes the old team.

# ZYRA — Project Governance

**Version:** V6
**Status:** CURRENT_VERSION
**Date:** 2026-08-31
**Contract Type:** PROJECT GOVERNANCE
**Supersedes:** ZYRA_GOVERNANCE_2026-08-31_V5.md (SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/)
**Parent Governance:** BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/

---

## What changed from V5

AD-AIOS-107 (ChatGPT proposal, Founder-adopted 2026-08-31; executed under
OA-AIOS-378) finalises the role titles and the Founder Change-Request
Routing model. §2 is rewritten for the four seats — ChatGPT becomes the
STANDING Lead Product & Systems Architect (superseding V4's "Manual
Advisor — default seat RETIRED" row); Fable is Lead Operations, Governance
& Delivery and absorbs the former Architecture Reviewer verification seat;
Codex is Product Designer & Implementation Engineer. §3's delegations are
retitled accordingly. Default route: Founder -> ChatGPT -> Fable (conflict
check) -> Codex -> Fable verification; direct Founder -> Codex remains
fully valid; conflicts return to the Founder before relay. Canonical
statement: IMPLEMENTATION_HANDOVER_STANDARD (V3), "Founder Change-Request
Routing". §§1, 4, 5, 6, 7 unchanged.

### Historical V5 change

Founder-ratified AD-AIOS-104 / DR-ZYRA-212 adopts **BUILD → DOCUMENT →
TRACE → HANDOVER** and **No undocumented intelligence** for ZYRA. Codex must
create/update the as-built implementation handover for meaningful builds;
Fable verifies it against actual code and reconciles it with the product
specification and build contract. §4.7 makes this a project documentation
rule. All other governance rules carry forward.

### Historical V4 change

One thing again: **the seats** (AD-AIOS-100, Founder-ratified 2026-08-20;
synced here by Fable as Documentation Owner). Codex now designs AND builds
— V3's "does not implement" shape (AD-AIOS-097) is superseded. Claude is
Architecture Reviewer and the API lane. ChatGPT's default seat is retired
(AD-AIOS-100 D1) — manual advisor via the Founder only. Fable holds Company
Operations and all documentation. §2 and §3 are rewritten for the new
seats. §§1, 4, 5, 6, 7 — including the findings-become-actions rule this
document exists to carry — are unchanged from V3.

---

## 1. Purpose

Governs the ZYRA project within Black Umbrella Group. Defines how decisions
are made, how work is authorised, how findings become tracked work, and how
the project reports upward.

---

## 2. Project Authority

| Role | Held by | Authority |
|---|---|---|
| **Founder / Project Owner — Final Authority** | Shakeel | Final authority on all decisions — product, business, privacy, security-risk acceptance, pricing, architecture, implementation approval, supersession and exceptions. Approvals given in conversation are binding and are recorded in the decisions register. |
| **Lead Product & Systems Architect** | ChatGPT | STANDING Founder partner (AD-AIOS-107 — supersedes the "default seat RETIRED" status of AD-AIOS-100 D1): shapes Founder change requests (what/why/expected outcome), proposes product and system architecture, reviews independently when the Founder requests it. Holds no file or register access — participation is Founder-relayed; its proposals become operational only after Founder acceptance AND Fable reconciliation/filing. |
| **Lead Operations, Governance & Delivery** | Fable | Owns source-of-truth documents and the registers; files ALL documentation (Documentation Owner). Checks every routed request for contradictions and relays Founder-approved work to Codex without distortion; verifies as-built handovers against actual code/evidence and reconciles product specification, build contract and implementation reality (absorbing the former Architecture Reviewer verification seat — AD-AIOS-107). Also: schedules, business operations, connectors, estate, finance. Security and documentation sync work may proceed on the Founder's standing instruction; feature work may not. |
| **Product Designer & Implementation Engineer** | Codex | Designs AND builds ZYRA production (AD-AIOS-107): proposes implementation design, implements Flutter/UI/navigation and Supabase/backend, and authors/runs migrations only with explicit written Founder authorisation — all within Founder-approved scope. Creates/updates the governed as-built handover and supplies measured evidence (DR-ZYRA-212). EXPECTED to challenge unsafe, contradictory or technically poor proposals before building. Accountable for surfacing risk and for the correctness of what it builds. Does not self-authorise scope; unresolved product-authority questions are escalated, never decided by Codex. |

**Standing rule (unchanged from practice since 2026-08-01):** agreement
between AI participants is **not** build authorisation. Every implementation
is put to the Founder for approve or deny before it lands — and the
Founder's direct instruction in conversation *is* that approval.

---

## 3. Decision Framework

Requires **Founder** approval:

- New features, or changes to product scope
- Pricing, naming and any user-facing commercial term
- Changes to architecture, data model or security posture
- Changes to this governance document
- Promotion of a working draft to a governed document

Delegated to **Codex** (Product Designer & Implementation Engineer):

- Implementation approach within an approved decision — building it
  directly (AD-AIOS-107), or staging it with named stages, gates and
  evidence
- Raising register entries for findings from its work (§6 makes this an
  obligation, not a discretion; Fable files the entries)

Delegated to the **executing seat** (Codex building production directly;
Fable where the work is in its governance/operations domain or a Founder
instruction names it):

- Code-level and document-level detail within the approved brief
- Internal tooling, code organisation, refactoring that changes no behaviour
- Stopping to raise evidence that contradicts an approved design — never
  working around it silently

---

## 4. Document Governance

4.1 All governed documents follow `NAMING_CONVENTIONS`.
4.2 Only one CURRENT_VERSION may exist per document name.
4.3 Archived versions are reference-only and are never edited.
4.4 Where documentation and conversation history conflict, the latest
approved document wins — and the conflict is named, not silently resolved.
4.5 References cite the **system**, never a versioned filename
(`NAMING_CONVENTIONS` Rule 5).
4.6 Documentation edits are filed by Fable (Documentation Owner); governed
documentation uses full canonical folder names, never shorthand.
4.7 Meaningful ZYRA implementation follows **BUILD → DOCUMENT → TRACE →
HANDOVER**. The current as-built handover records actual files, architecture,
data flow, controls, mock/production boundaries, migrations, named tests and
measurements, limitations, OA-linked gaps and next steps. Fable checks it
against the code. Product specification, build contract and implementation
handover own different questions and must agree or name the discrepancy.
Required fields and gates are inherited from `IMPLEMENTATION_HANDOVER_STANDARD`.

---

## 5. Reporting

5.1 ZYRA reports to Black Umbrella Group through the registers in
`SYSTEM/DECISIONS_REGISTER/` and `SYSTEM/OUTSTANDING_ACTIONS/`.
5.2 The project root is `DEVELOPMENT/SUB BUSINESS/ZYRA/`. It has been since
2026-07-03, when the sub-businesses were separated into independent
repositories.
5.3 Escalations route to the Founder.

---

## 6. Findings become actions — DR-ZYRA-151

> **No finding, recommendation or required decision is complete until it
> carries an OA number — or until the document states explicitly that no
> action is being raised, and why.**

### 6.1 Scope

Applies to every document that identifies something needing to change:
audits, architecture reviews, research reports, external reviews, security
sweeps, and AI-authored findings of any kind. A review that identifies ten
problems leaves behind ten identifiers or ten written refusals. There is no
third outcome.

### 6.2 Why this rule exists

Measured 2026-08-13. Three findings, all correctly identified, all properly
written up, none actioned:

| Finding | Written | Still open after | Why |
|---|---|---|---|
| Pricing drift — app advertised one price, charged another | 2026-08-08 | 5 days | No ID raised |
| Company formation D1–D7 | 2026-08-01 | 12 days, past the report's own "buy this week" | No ID raised |
| Filename migration | ~2026-08-08 | Grew from 55 files to 98 | Parked as "scheduled", no date, no ID |

The registers are not the weak point. **Everything that enters them gets
done.** The weak point is that findings were permitted to live outside them,
in documents — where being read, agreed with and filed is indistinguishable
from being actioned.

A document is not a queue.

### 6.3 The explicit refusal

Not every finding deserves an action, and inflating the register is its own
failure. So the rule permits a second outcome, on one condition: the refusal
must be **written into the document**, naming what was found and why no
action follows. "Noted, not raised — cosmetic, no user impact" is a complete
and acceptable answer. Silence is not.

### 6.4 Applies to the rule's own author

The Ecosystem Maintenance Review of 2026-08-13, which produced this rule, is
subject to it. Its findings were raised as OA-ZYRA-207 through OA-ZYRA-210 on
the day the rule was ratified.

---

## 7. Maturity Model

ZYRA follows the Black Umbrella Group universal maturity model (Levels 1–5).

Current level: **Level 2 — Governed.**

Level 3 requires that findings are systematically tracked to closure. §6 is
the mechanism; the level is not claimed until it has held for a full review
cycle.

---

## Version History

| Version | Date | Change |
|---|---|---|
| V1 | 2026-06-26 | Initial release (authority wrongly vested in the Lead Architect; stale paths). |
| V2 | 2026-08-13 | Authority corrected to the Founder; §6 findings-become-actions added (DR-ZYRA-151). |
| V3 | 2026-08-17 | Seats re-bound per DR-ZYRA-191 / AD-AIOS-097: Codex Lead Architect (briefs, no implementation); Fable and Claude Executors; Fable Documentation Owner; §3 delegation split brief-level vs code-level. Rules otherwise unchanged. |
| V4 | 2026-08-20 | Seats synced to AD-AIOS-100: Codex designs and builds; Claude Architecture Reviewer / API lane; ChatGPT default seat retired (D1); Fable Company Operations + all documentation. §§1, 4–7 unchanged. |
| V5 | 2026-08-23 | AD-AIOS-104 / DR-ZYRA-212: No Undocumented Intelligence adopted; as-built handover duty and Fable reconciliation added to §2 and §4.7. |
| V6 | 2026-08-31 | AD-AIOS-107 (OA-AIOS-378 sync): §2 rewritten to the final four-seat model — ChatGPT standing Lead Product & Systems Architect (supersedes the retired-advisor row); Fable Lead Operations, Governance & Delivery (absorbs the Architecture Reviewer verification seat); Codex Product Designer & Implementation Engineer; Founder & Final Authority explicit. §3 delegations retitled; routing per IMPLEMENTATION_HANDOVER_STANDARD (V3) "Founder Change-Request Routing". §§1, 4–7 unchanged. |
