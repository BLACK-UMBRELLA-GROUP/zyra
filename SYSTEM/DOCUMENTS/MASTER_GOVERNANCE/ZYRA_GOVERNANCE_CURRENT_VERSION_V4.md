# ZYRA — Project Governance

**Version:** V4
**Status:** CURRENT_VERSION
**Date:** 2026-08-20
**Contract Type:** PROJECT GOVERNANCE
**Supersedes:** ZYRA_GOVERNANCE_2026-08-20_V3.md (SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/)
**Parent Governance:** BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/

---

## What changed from V3

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
| **Founder / Project Owner** | Shakeel | Final authority on all decisions — product, commercial, architectural. Approvals given in conversation are binding and are recorded in the decisions register. |
| **Lead Architect** | Codex | Designs AND builds (AD-AIOS-100): proposes architecture, implements it, and authors/runs migrations — all within Founder-approved scope. Accountable for surfacing risk and for the correctness of what it builds. Does not self-authorise scope. |
| **Architecture Reviewer / API lane** | Claude | Reviews the Lead Architect's designs and returned evidence; implements API-lane work on Founder dispatch. Accountable for the honesty of its reviews and the correctness of what it builds. |
| **Company Operations & Documentation** | Fable | Connectors, estate, finance and the registers; files ALL documentation and register entries (Documentation Owner). Product/UX work on Founder instruction. Security and documentation sync work may proceed on the Founder's standing instruction; feature work may not. |
| **Manual Advisor** | ChatGPT | Default seat RETIRED (AD-AIOS-100 D1). Advises only when the Founder consults it directly; its input reaches the team only through the Founder. |

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

Delegated to the **Lead Architect** (Codex):

- Implementation approach within an approved decision — building it
  directly (AD-AIOS-100), or staging it as briefs with named executors,
  stages, gates and evidence
- Raising register entries for findings from its work (§6 makes this an
  obligation, not a discretion; Fable files the entries)

Delegated to the **executing agent** (Codex building directly; Fable or
Claude where a brief or Founder dispatch names them):

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
