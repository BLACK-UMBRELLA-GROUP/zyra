============================================================
ZYRA PROJECT
============================================================
OUTSTANDING ACTIONS V2
APPROVED WORK REGISTER
============================================================

<!-- split_register note -->
ARCHIVED ENTRIES: finished entries are moved whole, unchanged, to ARCHIVE/OUTSTANDING_ACTIONS_V2_CLOSED.md
  (split_register.py; ZYRA audit F-17, 13 Nov 2026). Search there for a closed ID. To reopen
  one, copy it back here with a dated Status line; never edit it in the archive.

Version: V2
Status: Approved — Active Baseline
Historical roles (AD-AIOS-107): ChatGPT — Lead Product & Systems Architect;
  Fable — Lead Operations, Governance & Delivery; Codex — Product Designer &
  Implementation Engineer
Current model (AD-AIOS-109): Founder ↔ Codex is the active route; Codex also
  holds Operations, Governance & Delivery; Fable remains stepped back;
  ChatGPT is Founder-request-only; only the Founder approves. Active stale
  owner, relay and review labels are interpreted through this overlay without
  rewriting historical authorship.
Project Owner: Shakeel
============================================================

CONTENTS

  1.  Purpose
  2.  Scope
  3.  Ownership
  4.  Document Principles
  5.  Action Template
  6.  Action Lifecycle
  7.  Action Identification
  8.  Action Categories
  9.  Priority
  10. Dependencies
  11. Target Publication
  12. Completion
  13. Reporting
  14. Governance Boundaries
  15. Relationship to Other Documents
  16. Synchronisation
  17. Document Maintenance
  18. Future Evolution
  19. Command Integration
  20. Design Principles
  21. Version History
  22. Action Register

============================================================


============================================================
1. PURPOSE
============================================================

Outstanding Actions is the single authoritative register
of all approved work that has not yet been completed.

It provides a central location for tracking implementation
work across the project while remaining independent from
Governance, Execution, Repository Architecture, Decision
Records, and feature documentation.

This document owns only outstanding work.

It does not own:
  • Governance decisions
  • Implementation specifications
  • Architectural reasoning
  • Feature documentation
  • Repository structure definitions

------------------------------------------------------------


============================================================
2. SCOPE
============================================================

This document records only work that has been approved
but has not yet reached completion.

Examples include:

  • Approved features awaiting implementation.
  • Approved documentation updates.
  • Approved architectural improvements.
  • Approved governance improvements.
  • Approved publication work.
  • Approved review work.
  • Approved migration work.
  • Approved maintenance work.
  • Approved cleanup work.
  • Approved repository restructuring.

Ideas, proposals and discussions are not recorded here
until they have completed the governance approval process.

------------------------------------------------------------


============================================================
3. OWNERSHIP
============================================================

Document Owner

Under the historical AD-AIOS-107 role model this document was maintained
by Lead Operations, Governance & Delivery. Under the current AD-AIOS-109
Founder–Codex model, Codex performs that filing duty.

The Project Owner approves additions, removals and
completion of actions.

Codex internal verification remains separate from maintenance and Founder
approval. ChatGPT or Fable participates only when the Founder explicitly
requests it for a named matter.

Action Ownership

Each individual Outstanding Action contains its own
assigned owner.

The owner recorded against an action is responsible for
completing that specific action.

Document ownership and Action ownership are independent
and must never be confused.

------------------------------------------------------------


============================================================
4. DOCUMENT PRINCIPLES
============================================================

------------------------------------------------------------
4.1 Single Source of Outstanding Work
------------------------------------------------------------

This document is the only authoritative source for
approved work that remains outstanding.

Other governance documents may reference Outstanding
Actions, but must never duplicate or maintain
independent lists.

------------------------------------------------------------
4.2 Approval Required
------------------------------------------------------------

Only approved work may enter this document.

Ideas, discussions and proposals remain outside this
document until approved through the governance process.

------------------------------------------------------------
4.3 Living Document
------------------------------------------------------------

Outstanding Actions is a living document.

Actions are continually added, updated, completed,
cancelled or superseded through approved governance
processes.

------------------------------------------------------------
4.4 Historical Accuracy
------------------------------------------------------------

When an action reaches a terminal state it remains
recorded for historical accuracy until removed through
an approved publication.

Historical changes must remain traceable through the
normal publication workflow.

------------------------------------------------------------
4.5 Findings Become Actions (DR-ZYRA-151)
------------------------------------------------------------

No finding, recommendation or required decision — in any
audit, review, research report or AI-authored document —
is complete until it carries an OA number in this
register, or the document states explicitly that no
action is being raised and why. The full rule lives in
ZYRA_GOVERNANCE §6; this register is the queue that rule
points at.

(Added 2026-08-20 under OA-ZYRA-208, executing
DR-ZYRA-151.)

------------------------------------------------------------


============================================================
5. ACTION TEMPLATE
============================================================

Every Outstanding Action uses the following template.

  ID:           OA-[number]
  Title:        Short descriptive title
  Category:     Category from Section 8
  Priority:     Critical / High / Medium / Low
  Status:       Status from Section 6
  Owner:        Role responsible for completion
  Dependencies: OA-[numbers] or None
  Decision:     DR-[number] or None (optional)
  Automation:   Manual / Planned / Automated
  Description:  What needs to be done and why
  Target:       Which publication or milestone

Decision links this action to the Decision Record that
authorised the work, creating a direct audit trail:
  Decision → Outstanding Action → Execution → Completion

Automation defaults to Manual for all current actions.
Update to Planned or Automated when applicable.

------------------------------------------------------------


============================================================
6. ACTION LIFECYCLE
============================================================

An action enters this lifecycle only after successfully
completing the governance approval process.

------------------------------------------------------------
Operational States
------------------------------------------------------------

  Recorded     — Approved. Not yet started.
  In Progress  — Actively being worked on.
  On Hold      — Paused. Awaiting dependency or decision.
  Awaiting Review — Work complete. Awaiting verification.

------------------------------------------------------------
Terminal States
------------------------------------------------------------

  Completed    — Approved and verified. Successful end.
  Cancelled    — No longer required. Approved removal.
  Superseded   — Replaced by another action or decision.

------------------------------------------------------------
State Rules
------------------------------------------------------------

  • Recorded is the entry state for all new actions.
  • Completed is the only successful terminal state.
  • Cancelled and Superseded may occur from any state.
  • Terminal state records are retained until removed
    through an approved publication.

------------------------------------------------------------


============================================================
7. ACTION IDENTIFICATION
============================================================

Every Outstanding Action has a permanent Action ID.

Format: OA-[sequential number]

Examples: OA-001, OA-002, OA-003

Action IDs are never reused.

If an action is cancelled, superseded or completed,
its ID remains permanently associated with that record.

------------------------------------------------------------


============================================================
8. ACTION CATEGORIES
============================================================

  • Governance       — Governance document work
  • Execution        — Execution document work
  • Architecture     — Repository architecture work
  • Documentation    — Feature or SYSTEM document work
  • Repository       — Folder structure and filing work
  • Terminology      — ZYRA Terminology work
  • Cleanup          — Removal of outdated or misplaced content
  • Migration        — Moving content between locations
  • Feature          — APP feature work
  • Review           — Audit or review work

Categories describe the nature of the work only.

They do not affect priority, approval requirements
or lifecycle behaviour.

------------------------------------------------------------


============================================================
9. PRIORITY
============================================================

  Critical  — Blocks other approved work
  High      — Should be completed in the next session
  Medium    — Important but not immediately blocking
  Low       — Future work, no immediate dependency

Priority may change as project requirements evolve.

Changing priority does not require a new approval
provided the action itself remains unchanged.

------------------------------------------------------------


============================================================
10. DEPENDENCIES
============================================================

An Outstanding Action may depend upon one or more
other approved actions before work can begin.

Dependencies are recorded to improve planning and
prevent conflicts.

Dependencies never prevent an action from being
recorded. They explain why it may remain in the
Recorded state.

------------------------------------------------------------


============================================================
11. TARGET PUBLICATION
============================================================

Where applicable, each action identifies the publication
or milestone through which completion is expected.

Target Publication assists planning only.

It does not determine approval or completion.

------------------------------------------------------------


============================================================
12. COMPLETION
============================================================

An action is considered complete only when all of the
following have occurred:

  1. The approved work has been fully carried out.
  2. Required reviews have successfully completed.
  3. Any required publications have been approved and
     filed as the Active Baseline.
  4. The Project Owner confirms completion.

Implementation alone does not constitute completion.

An action that is technically finished but awaiting
publication approval remains in Awaiting Review, not
Completed.

Completed actions remain historically traceable until
removed through an approved publication process.

------------------------------------------------------------


============================================================
13. REPORTING
============================================================

Reports generated from this document may include:

  • Total Outstanding Actions
  • Actions by Category
  • Actions by Priority
  • Actions by Status
  • Actions by Owner
  • Actions by Target Publication
  • Dependency Summary
  • Recently Completed Actions
  • Recently Added Actions
  • Cancelled Actions
  • Superseded Actions

Reports present the current state of the register.

They do not create approvals or modify actions.

------------------------------------------------------------


============================================================
14. GOVERNANCE BOUNDARIES
============================================================

Outstanding Actions records work.

It does not determine whether work should exist.

Outstanding Actions never:

  • Approves work.
  • Rejects work.
  • Creates governance decisions.
  • Creates Decision Records.
  • Creates documentation.
  • Alters implementation specifications.
  • Records unapproved proposals.

Its responsibility begins only after approved work
enters the register.

------------------------------------------------------------


============================================================
15. RELATIONSHIP TO OTHER DOCUMENTS
============================================================

Governance
  Defines principles, approval processes, documentation
  standards, publication workflow, decision lifecycle.
  Outstanding Actions begins only after Governance
  has approved work.

Execution
  Defines how approved work is carried out.
  Outstanding Actions records that work exists and
  tracks its progress.

Repository Architecture
  Defines where everything in the repository lives.
  Outstanding Actions may reference structural work
  but never redefines repository structure.

Decision Records (formerly Architectural Discussions)
  Records the permanent reasoning behind approved
  architectural decisions.
  Outstanding Actions may reference those decisions
  but never duplicates them.
  The DECISIONS area will evolve toward formal
  Decision Records through Governance V3.

Feature Documentation
  Feature Summaries, Scripts, Flow Diagrams and
  References define individual features.
  Outstanding Actions may reference feature documents
  where approved work relates to those features.

------------------------------------------------------------


============================================================
16. SYNCHRONISATION
============================================================

Outstanding Actions participates in the standard
governance publication workflow.

Changes become operational only after:

  • Review.
  • Project Owner approval.
  • Publication.
  • Synchronisation.

Conversational memory never replaces the approved
published document.

The latest approved publication always remains the
active baseline.

------------------------------------------------------------


============================================================
17. DOCUMENT MAINTENANCE
============================================================

This document is maintained through the standard
governance publication workflow.

All additions, updates, cancellations, supersessions
and completions are performed through approved
publications.

Previous publications remain archived for historical
reference.

There is always exactly one active baseline for
this document.

------------------------------------------------------------


============================================================
18. FUTURE EVOLUTION
============================================================

Outstanding Actions is designed to scale alongside
the project.

Future improvements may introduce additional reporting,
automation or workflow enhancements provided they
remain consistent with Governance.

Any future changes must:

  • Preserve existing governance principles.
  • Preserve historical accuracy.
  • Preserve publication integrity.
  • Preserve the active baseline principle.
  • Follow the approved publication workflow.

------------------------------------------------------------


============================================================
19. COMMAND INTEGRATION
============================================================

Various governance commands interact with Outstanding
Actions.

Governance defines the purpose and ownership of each
command.

Execution defines the operational behaviour.

Outstanding Actions records the outcomes of approved
command execution where applicable.

Outstanding Actions never changes as the direct result
of a command alone.

Only approved outcomes produced through the governance
process may modify this register.

------------------------------------------------------------


============================================================
20. DESIGN PRINCIPLES
============================================================

Single Source
  One authoritative register for all approved
  outstanding work.

Traceability
  Every action remains historically traceable
  throughout its lifecycle.

Separation of Responsibility
  Governance approves.
  Execution performs.
  Outstanding Actions tracks.
  Decision Records explains why.

Publication Integrity
  Changes become operational only through approved
  publication and synchronisation.

------------------------------------------------------------


============================================================
21. VERSION HISTORY
============================================================

Version V1
  Initial baseline.
  Established purpose, scope, ownership, lifecycle,
  action template, categories, priority, dependencies,
  completion, reporting, and governance boundaries.
  Owner listed as ChatGPT (named product).

Version V2
  Supersedes V1 as Active Baseline.
  Changes from V1:
    • Ownership updated to role-based language
      (Lead Architect, Architectural Reviewer,
      Project Owner).
    • Repository Architecture added to document
      relationships (Section 15).
    • Decision Records transition note added
      (Section 15, Section 14).
    • Action Template formalised with Decision and
      Automation fields (Section 5).
    • On Hold state added to lifecycle (Section 6).
    • Action Register added (Section 22) with all
      current approved outstanding actions
      (OA-001 through OA-011).
    • Register ordered by OA-ID not Priority.
    • Completion clarified — requires publication
      approval, not just implementation (Section 12).
    • OA-011 architectural maturity note added.
    • Cleanup and Migration categories added
      (Section 8).

------------------------------------------------------------


============================================================
22. ACTION REGISTER
============================================================

This section is the live register of all approved
outstanding actions.

Actions are ordered by Action ID (OA-001, OA-002...).

Priority ordering is never used in the master register.
Priority-grouped views are available through reporting
(Section 13) without changing the register itself.
This keeps the register stable as priorities evolve.

OA-ZYRA-148
Title:       Design & Build Family Conversation Guide (ZYRA One)
Category:    Product / Premium / Family Stage
Priority:    Medium
Status:      Queued — build lane, feature pause (restamped 2026-08-20, OA-AIOS-326; was Open) — approved direction only, no design work done
Owner:       Founder (Shakeel)
Raised:      2026-07-28
Completed:   —
Source:      DR-ZYRA-119 ("Premium Differentiation — Current
             Direction"), Decision item 4.

Description: Approved direction: a ZYRA One capability that
             helps a Seeker prepare their own family for Family
             Compatibility Stage conversations — e.g. suggested
             questions or talking points for the family to raise,
             tailored to what's already been established in the
             Journey so far. Distinct from the existing Guardian+
             "Guardian AI Summary" (Journey Capability Grant Rules
             V4 / AI Tiering V1), which is delivered TO the Guardian
             about the couple's alignment — this would be a
             Seeker-facing prep tool, aimed at the Seeker's family
             generally, not just their linked Guardian.

             Rated during discussion as the strongest fit against
             ZYRA's own stated differentiator (family involvement)
             of any candidate considered, since it deepens that
             mechanic rather than substituting for it. No design
             work exists yet: unclear how it's surfaced in the
             Family Compatibility Stage flow (PRE-JOURNEY RITUAL/
             Summary.md), what it draws on (Phase 1-3 answers?
             Guardian AI Summary content?), or how it fits AI TIERING
             CURRENT_VERSION_V1.md's "System intelligence vs ZYRA
             intelligence" test.

Target:      Founder has asked to hold all AI-adjacent
             differentiation (this includes an AI-generated
             guide) for a dedicated end-of-build AI discussion —
             see OA-ZYRA-149. Do not design or build in isolation
             before that discussion, even though this OA is
             logged separately from it.
Dependencies: OA-ZYRA-149 (the dedicated AI discussion this should
             likely be folded into or sequenced after),
             APP/Premium/AI TIERING/TIERING_CURRENT_VERSION_V1.md,
             PRE-JOURNEY RITUAL/Summary.md (Family Compatibility
             Stage), WALI_ARCHITECTURE_CURRENT_VERSION_V6.md
             (Guardian AI Summary — the adjacent, already-approved
             feature this must stay distinct from).
Automation:  None — awaiting the dedicated AI discussion.

------------------------------------------------------------

OA-ZYRA-149
Title:       Dedicated Product Discussion — AI Differentiation
             (ZYRA Coach, ZYRA Insight, ZYRA Recommendation, AI
             Guidance Generally)
Category:    Product / Premium / AI
Priority:    Medium — deliberately deferred, not urgent
Status:      Parked — deliberately, per Founder instruction. Not
             to be actioned piecemeal.
Owner:       Founder (Shakeel)
Raised:      2026-07-28
Completed:   —
Source:      DR-ZYRA-119 ("Premium Differentiation — Current
             Direction"), Decision item 5.

Description: During the premium-differentiation discussion,
             several AI-guidance ideas came up (an always-
             available "ZYRA Coach" beyond fixed checkpoints,
             expanding existing ZYRA Insight/Recommendation/
             Summary depth per AI TIERING CURRENT_VERSION_V1.md).
             Founder explicitly declined to decide any of these
             now: AI is expected to become one of ZYRA's biggest
             differentiators, and the Founder does not want
             isolated AI decisions made while the rest of the
             platform is still evolving. Instead, a single,
             dedicated product discussion — covering how AI
             should fit naturally into the complete user journey —
             is wanted, timed closer to the end of the build, once
             that complete picture actually exists.

             This OA exists so the intent to have that discussion
             isn't lost across a long build, not to track any
             specific AI feature — the specific ideas raised this
             pass (ZYRA Coach, deeper Insights) are examples for
             that future discussion to reconsider fresh, not a
             pre-committed shortlist.
Target:      Founder to resume near the end of the build, once
             the complete user journey is well understood. Do not
             raise piecemeal AI-tiering questions before then
             unless one arises unavoidably while implementing an
             already-approved, non-AI feature.
Dependencies: APP/Premium/AI TIERING/TIERING_CURRENT_VERSION_V1.md
             (existing ratified AI philosophy this discussion
             would extend, not replace), OA-ZYRA-148 (Family
             Conversation Guide — likely folds into this
             discussion).
Automation:  None — deliberately parked.

------------------------------------------------------------

OA-ZYRA-150
Title:       Dedicated Product Discussions — Guardian-Unavailable
             Path (DR-G) and Published Outcomes Metric (DR-N)
Category:    Product / Safeguarding / Premium
Priority:    Medium — both raised as proposals, deliberately not
             resolved
Status:      Parked — deliberately, per Founder instruction. Not
             to be actioned piecemeal.
Owner:       Founder (Shakeel)
Raised:      2026-08-01
Completed:   —
Source:      DR-ZYRA-120 ("Muzz Teardown Cross-Review"), Decision
             item 4; originally proposed in MUZZ_TEARDOWN_
             CURRENT_VERSION_V1.md as DR-G and DR-N.

Description: Two proposals from the Muzz teardown need their own
             dedicated discussion rather than being folded into
             the wider cross-review:
             (a) Guardian-unavailable path — grace periods, a
             nominated alternate Guardian, and a stated auto-continue
             default when a Guardian doesn't respond. Flagged risk:
             any auto-continue-after-timeout mechanism is
             potentially gameable by a Seeker who wants to avoid
             genuine Guardian oversight (deliberately making their
             Guardian "unreachable" to trigger auto-continuation) —
             this needs to be designed against directly, not
             assumed away.
             (b) Publishing an outcomes metric (e.g. a Nikah/
             marriage-success rate) as a public differentiator.
             Flagged risk: this could create pressure to optimise
             the published number itself rather than the
             underlying unhurried, deliberate experience ZYRA is
             built around (a measurement/incentive concern, not a
             feasibility one).
Target:      Founder to schedule both as separate, dedicated
             discussions — treat with the same weight as the
             Active Journey tiering discussion (DR-ZYRA-119),
             not resolved in a single pass.
Dependencies: WALI_ARCHITECTURE_CURRENT_VERSION_V6.md (for DR-G),
             MUZZ_TEARDOWN_CURRENT_VERSION_V1.md §6 and §11.7
             (both proposals' original framing).
Automation:  None — awaiting dedicated Founder discussions.

------------------------------------------------------------

OA-ZYRA-170
Title:       Function EXECUTE Privileges for 'anon' — Audit and
             Sweep
Category:    Security / Hardening
Priority:    Medium — same shape as OA-ZYRA-168 but for functions
             rather than tables, and unlike tables there is no
             RLS backstop behind a function grant
Status:      PARTIALLY APPLIED — Stages A/A' done and verified.
             Stage B' INCOMPLETE. Acceptance test still red.
             Parked 2026-08-08 pending Founder decision
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   —
Source:      OA-ZYRA-168 Stage 4, deliberately excluded from that
             migration by Founder decision (invariant I7)

Outcome so far: two migrations applied, both Founder-approved —
             oa170_function_execute_sweep_stages_a_and_b and
             oa170_function_execute_sweep_stages_a_prime_b_prime.

             DONE: anon EXECUTE on every function that exists
             today is 0. authenticated unchanged at 56. All three
             policy-dependent functions (zyra_can_match,
             zyra_can_view_profile, zyra_can_read_photo_object —
             the last used by a storage.objects policy) verified
             still executable.

             NOT DONE: new functions still arrive anon-executable.
             Probe evidence: a function created after Stage B'
             carried '{=X/postgres, ...}' — the leading '=X' is
             PUBLIC, which anon inherits.

             Two revokes were required, not one. Stage A/B removed
             anon's EXPLICIT grant and removed anon from the
             default ACL; both worked and neither mattered while
             PUBLIC still granted it. Stage A' removed PUBLIC from
             the two existing functions and worked. Stage B'
             attempted the same on the default ACL and changed
             nothing, because there was no PUBLIC entry in the
             array to remove — PostgreSQL's built-in EXECUTE-to-
             PUBLIC default appears to be applied ON TOP of
             pg_default_acl rather than replaced by it.

             Fourth time this project has been caught by the
             PUBLIC/anon/authenticated relationship, and the first
             in this direction. Effective privilege is the UNION
             of a role's own grant, PUBLIC's grant and anything
             inherited; has_function_privilege() reports the union
             and is the only reliable check.

             CURRENT RISK: none today. anon executes nothing that
             exists and writes nothing anywhere. The gap applies
             from the next function-creating migration onward.

Description: The default ACL grants EXECUTE on every new function
             in schema public to 'anon'. OA-ZYRA-168 removed
             anon's table write grants and changed the table
             default ACL; the FUNCTION default ACL was left alone
             because it needs a different judgement per function.

             This is not a straight sweep. Some functions may
             legitimately need to be callable before
             authentication — preview_wali_invite() is the obvious
             candidate, since a Guardian follows an invite link
             before holding an account. Revoking indiscriminately
             would break that; leaving it indiscriminately leaves
             every future function open to unauthenticated
             callers.

             Note the asymmetry with OA-168: a table grant to anon
             still had RLS behind it, which is why those 75 grants
             were inert. A FUNCTION grant has no equivalent
             backstop — a SECURITY DEFINER function executable by
             anon runs as its owner with no policy layer in the
             way. This is therefore the more consequential of the
             two sweeps, despite being the smaller one.

             This project has been caught three times by the fact
             that REVOKE EXECUTE ... FROM public does not touch
             anon's explicit grant. Any plan here must revoke from
             anon by name and verify with
             has_function_privilege() — invariant I4 corollary.
Target:      AWAITING FOUNDER DECISION — one experiment, not yet
             approved, not applied:

               alter default privileges for role postgres
                 in schema public grant execute on functions to public;
               -- confirm '=X' now appears in the default ACL
               alter default privileges for role postgres
                 in schema public revoke execute on functions from public;
               -- confirm it disappears, then re-run the probe

             If the array can hold a PUBLIC entry and then drop
             it, the revoke sticks and B' is achievable. If it
             cannot, there is no durable default-privileges fix
             for functions and the fallback is (a) every
             function-creating migration ends with an explicit
             'revoke execute ... from public', plus (b) a detector
             flagging any public function carrying a PUBLIC
             EXECUTE grant. (b) is a new check and needs approval
             under invariant I7.

             ACCEPTANCE TEST for closing this OA: a throwaway
             function created after the change is NOT
             anon-executable. Founder-defined 2026-08-08. Do not
             mark complete on catalogue evidence alone — the
             catalogue read correctly while the probe was red.
Dependencies: OA-ZYRA-168 (precedent, method and verification
             pattern); ZYRA_ENGINEERING_INVARIANTS I4.
Automation:  The enumerating query is catalogue-only and cheap.
             Not added to tools/zyra_check.py — invariant I7.

------------------------------------------------------------

OA-ZYRA-179
Title:       Build "Block My Phone Contacts" — Optional Verified
             Number, Honest Coverage Copy, and Do Not Believe the
             Hashing Solves Privacy
Category:    Feature / Safety / Privacy
Priority:    High value, not urgent. Nothing is broken; this is the
             feature the competitor research rates highest
Status:      Assigned — Codex (restamped 2026-08-22, OA-AIOS-341) —
             dispatched 2026-08-21 in the Founder-approved
             handoff pack
             CODEX_HANDOFF_ZYRA_QUEUE_2026-08-21_V1, Batch
             4; Codex implements and returns evidence
             through the Founder; Fable files the closure.
             Was: Open — direction approved (DR-ZYRA-128), NOT started
Owner:       Founder (Shakeel)
Raised:      2026-08-09
Completed:   -
Source:      Founder question about Muzz's Settings. Direction taken
             the same day as DR-ZYRA-128.

Description: Four pieces, none of which exist:

               1. OPTIONAL PHONE VERIFICATION. A number on the
                  account, verified by OTP. Supabase Auth supports
                  phone as a second identity on an existing user.
                  Also unlocks 2FA, which is why a member might add
                  one even if they never use contact blocking.
               2. CONTACTS PERMISSION on device, with the iOS
                  limited-access path handled.
               3. MATCHING, server-side.
               4. THE BLOCK ITSELF — reuses profile_blocks, or a
                  sibling table if contact-blocks need to behave
                  differently (see the open questions).

🔴 THE HASHING TRAP — read this before designing the matching.
             The standard pattern is: hash the contacts on device,
             send hashes, compare against hashed member numbers,
             never store the address book. Correct as far as it
             goes, and it is NOT anonymisation.

             Phone numbers are a tiny keyspace. A UK mobile is
             about 10^9 possibilities; every one can be hashed in
             seconds. A plain or globally-salted hash of a phone
             number is therefore reversible by anyone holding the
             hash and the salt — which is us. Per-user salts do not
             help, because matching requires both sides to hash the
             same way.

             So do not claim the server "never learns" the member's
             contacts. It does learn which of them are on ZYRA —
             that is inherent to the feature. What the design can
             honestly promise:
               - the address book is never persisted, only the
                 resulting block edges;
               - hashes are discarded within the request;
               - the match result is never shown as a list
                 ("3 of your contacts are on ZYRA" is itself a
                 disclosure about those people).
             State that accurately in the Privacy & data screen
             (DR-ZYRA-127) rather than overclaiming.

🔴 THE COVERAGE COPY IS A SHIP CONDITION, not a nicety.
             Per DR-ZYRA-128: the control must say, in its own
             copy at the point of switching on, that it hides the
             member only from contacts who have also added a
             number. Not in help, not in a tooltip. A member who
             believes they are hidden from a specific person and is
             not is worse off than one who never had the switch —
             they stopped worrying.

             Do NOT display a coverage count or percentage. It
             sounds like honesty and it leaks: "12 of your contacts
             are on ZYRA" tells the member something about twelve
             people who did not consent to being told about.

Target:      Founder decisions still open before build:
               (a) is a contact-block TERMINAL (I1/I2, like a
                   profile block), or does it lift when the number
                   leaves the phone's address book? Terminal is
                   consistent with I2 but surprising — the member
                   thinks of it as a live sync;
               (b) does the blocked party learn anything? Profile
                   blocks today are silent, and this should almost
                   certainly match;
               (c) is the same number reusable for 2FA, or is a
                   number added for blocking held separately;
               (d) retention — is the number kept if the member
                   later turns contact blocking off.

             ALSO WORTH DOING FIRST, and independent of all of the
             above: "Discovery & visibility" currently has exactly
             ONE toggle, "Visible in Browse" — all or nothing.
             MUZZ_TEARDOWN records the graduated version:
             "invisible to people you haven't liked, or hidden
             entirely". That needs no phone number, no permission
             and no matching, and it covers part of the same fear.
             Cheap, and shippable now.
Dependencies: Supabase Auth phone identities; profiles;
             profile_blocks; privacy_settings_screen.dart;
             privacy_and_data_screen.dart (its "does not ask for
             your phone number" line becomes wrong the day this
             ships and must change with it); DR-ZYRA-128;
             DR-ZYRA-127; MUZZ_TEARDOWN; invariants I1, I2.
Automation:  OTP verification is Supabase's. The matching is one
             SECURITY DEFINER function. The genuinely hard parts
             are the four decisions above and the copy.

------------------------------------------------------------

OA-ZYRA-190
Title:       Delete Every is_synthetic Row Before Public Launch
Category:    Pre-Launch / Data Integrity
Priority:    BLOCKING for public launch. Harmless while the
             database holds only seeded accounts
Status:      Deferred (restamped 2026-08-20, OA-AIOS-326; was Open) — raised 2026-08-10
Owner:       Founder (Shakeel) confirms the launch gate; Opus
             executes
Raised:      2026-08-10
Completed:   —
Source:      Founder decision 2026-08-10 to seed Chapter 3/4
             "full synthetic, clearly labelled". This is the
             other half of that instruction

Description: The database now contains 144 Seekers with complete
             but INVENTED Chapter 3 and Chapter 4 answers, and
             144 with invented Chapter 2 details.

             Chapter 2 can at least be checked: it was built to
             Census 2021 and the Techne/IIFL denominational
             survey. CHAPTER 3 CANNOT. Those are values — there
             is no census for "how involved should your parents
             be during your marriage". The answers and the
             preference maps came from a deterministic hash and
             an assortative decay rule that I chose.

             THE RISK IS NOT THE DATA, IT IS WHAT GETS BUILT ON
             IT. A compatibility engine tuned until these scores
             "look right" is tuned to an invention. The measured
             spread — 77 to 100, mean 86.3 — is a property of my
             decay rule, not of any real population.

             WHAT MARKS IT:
               onboarding_answers.is_synthetic   (144 rows)
               seeker_details.is_synthetic       (144 rows)
             Both default FALSE, so a real Seeker can never be
             caught by the sweep. Partial index on each.

             ALSO TO DROP: zyra_seed_ch4_questions and
             zyra_seed_answers — scaffolding tables holding the
             question catalogue transcribed from
             chapter3_categories.dart and the intermediate
             answer picks. Both RLS-enabled with grants revoked.

             NOTE THE STALENESS HAZARD: zyra_seed_ch4_questions
             is a TRANSCRIPTION of a Dart file. If the questions
             change and the seed is re-run, it will write answers
             against option strings that no longer exist, and
             score_candidates() will silently match nothing —
             absent answers are neutral, so it fails quiet.
             Regenerate the catalogue before any re-seed.

             TO CLOSE: delete where is_synthetic, drop the two
             scaffolding tables, then assert both tables are
             empty of synthetic rows. Do it in the same sweep as
             OA-ZYRA-184's nine dev RPCs — same gate, same day.

------------------------------------------------------------

OA-ZYRA-193
Update 2026-10-05 — LOCAL PURPOSE BOUNDARY PREPARATION ONLY:
             OA305's F04 package passes baseline+8 synthetic groups for a
             private canonical legacy scorer, ID-only Browse ordering and
             retained Journey gates. It refuses non-synthetic execution and
             is not deployable alone. Existing app numeric callers are not
             rewired. Shared immutable directional results, strict validation,
             corrected measurement, gateway/client encoding, retention and
             inference acceptance remain open. F06/F07 bookkeeping receipts
             are not scoring snapshots. No production apply or activation.
             See ZYRA_APP_GATE_REPAIRS_HANDOVER_CURRENT_VERSION_V1 and dated
             2026-10-05 receipt; no scoring-method/product-policy change.
Update 2026-09-28 — STAGE 1 LOCAL BUILD/EVIDENCE COMPLETE:
             Exact Founder GO recorded below was executed for fifteen new unwired
             research/test files. Final seven synthetic suites: 206 passed;
             scoped analyzer: no issues. All 26 focused SOURCE baselines and
             four added metadata/dependency/configuration hashes still match.
             Current as-built: ZYRA_COMPATIBILITY_CALCULATION_STAGE1_HANDOVER
             CURRENT_VERSION_V1; run evidence: COMPATIBILITY_UNLOCK_STAGE1_
             EXECUTION_EVIDENCE_2026-09-28 (MD/JSON, RESOURCES/REVIEWS).
             Manifest, typed validation, targeted legacy review simulations
             and rational contribution totals are local only. Production
             capture, shared snapshots, grants, server fuse, ledger, privacy,
             retention and activation remain open. No OA closure or Stage2 GO;
             internal verification is not Founder acceptance. Earlier Stage0
             preparation/hold statements below are historical for Stage1 only.
Update 2026-09-28 — STAGE 1 LOCAL EXECUTION GO RECEIVED:
             Founder directly replied "Proceed i authorsie" to the bounded
             Stage 1 request. Exact reviewed local brief pre-execution hash:
             6067114eec02e3845b1024531a1823dfb147e1bbe11d7258d3bbc51099e6d23a.
             Authorised: fifteen new unwired tools/test files, synthetic
             verification and scoped documentation handover. No existing
             SOURCE edit, SQL/database work, runtime wiring, credit/debit,
             purchase, install, distribution or activation. Execution and
             internal checks remain distinct from Founder acceptance. This
             supersedes the Stage 1 hold below only for that exact local scope.
             D1–D6 / DR-ZYRA-250 and later launch/privacy gates are unchanged.
Update 2026-09-28 — POLICY APPROVED / ENGINEERING HELD:
             DR-ZYRA-250 records the Founder's D1–D6 product approval. Twelve
             internal categories and reduced-disclosure Plus direction are
             decided; Chapter2 weight 1 is PROVISIONAL V1 pending corrected
             measurement. This supersedes older active category/weight
             decision requests below, not their historical evidence.
             Canonical mapping/validation, calculation snapshots, semantic
             capture, strict repair, corrected measurement and launch gates
             remain open. No exact tallies/category percentages, bands or
             suppression thresholds are authorised by filing. Stage0 policy/
             specification reconciliation completed; Stage1 brief DRAFT.
             App/service hold is not fresh proof of the required server fuse.
             No build/test/SQL/database/spending/activation occurred.
             Plan and local brief: SYSTEM/RESOURCES/REVIEWS/COMPATIBILITY_
             UNLOCK_IMPLEMENTATION_AND_EVIDENCE_PLAN and
             COMPATIBILITY_UNLOCK_STAGE1_LOCAL_BUILD_BRIEF (2026-09-28 drafts).
             Engineering/risk/evidence gates are not closed by policy approval.
Title:       The Compatibility Scoring METHOD Has Never Been
             Agreed — Two Different Ones Are Already Live
Category:    Product / Compatibility Engine
Priority:    HIGH as a decision. Nothing is broken, but every
             number the product shows rests on a method nobody
             ratified, and two parts of the app disagree about
             what it is
Status:      OPEN — waiting for a Founder decision. PARTIALLY RESOLVED (a)(a2)(b)(c) 2026-08-11 —
             Founder decided from his phone. (d) and (e) remain
             Open. The whole of (d)'s hard TestFlight TRUTH gate
             was SATISFIED 2026-09-10: Exact Trio is honest-empty
             with a two-layer Unlock+ spend fuse, and Journey
             Reveal now keeps the caller-owned real overall score
             while withholding all unproven category detail.
             (d) GAINED THE ORIGINAL HARD GATE 2026-08-29: the last
             on-screen sample marker for the unlock category
             breakdown was removed at Founder instruction
             (conflict reported by Codex, reconciled by Fable
             per AD-AIOS-106, Founder ruled same day) — the
             copy stays removed during live testing, AND
             before TestFlight distribution or any external
             viewing either real category data ships under
             (d) or the category percentages hide entirely
             (honest-empty). This gate is a TestFlight
             blocker and joins the Runbook Phase 5 checks.
             Codex keeps the sample-data boundary in code. Originally raised because the Founder called
             for it 2026-08-10: "if you're setting a score system
             we gotta talk about that soon"
Owner:       Founder (Shakeel) — this is a product decision, not
             an implementation one
Raised:      2026-08-10
Completed:   —
Source:      Founder declined to set v_ch2_weight on 2026-08-10,
             correctly, on the grounds that the weight is a dial
             on a machine that was never agreed

Description: THE FOUNDER IS RIGHT AND THIS SHOULD HAVE BEEN
             RAISED FIRST. v_ch2_weight was offered as a
             decision. It is a parameter of a scoring method
             that has never been approved — tuning it would have
             ratified the method by the back door.

             ZYRA_DECISIONS_CURRENT_VERSION_V2 §10 has said
             "Compatibility scoring. Method undefined." since it
             was written. That is still true, and meanwhile TWO
             DIFFERENT METHODS have appeared in the product:

             1. score_candidates(), live and consumed by Browse
                curation and the Journey reveal:
                  green +2, yellow +1, red -3
                  score = (total / max) x 50 + 50
                So the scale runs 0-100 but CENTRES ON 50, and 50
                means "we know nothing about you", not "half
                compatible". A red answer costs more than a green
                one earns — deliberate, never ratified.

             2. profile_unlock_screen.dart's historical sample
                figures, whose header documented the weighting
                they were built to satisfy:
                  green 1, amber 0.5, red 0, over 88 items
                A plain 0-100 count. No centring, no penalty.
                REMOVED FROM RUNTIME 2026-09-10. Exact Trio now
                shows its ruled structure without values.

             3. Journey Reveal historically persisted five
                category rows by copying the caller's real overall
                score into every row. Those rows were rendered as
                exact percentages. REMOVED FROM THE PRODUCTION
                CLIENT 2026-09-10: new reveals no longer write a
                category map; reads do not select either legacy
                category column; UI caches, rows and category-
                derived insight were removed. The genuine overall
                score remains. Historical JSON is left intact but
                unreachable pending a versioned real-data contract.

             These are not different numbers, they are different
             SCALES. 81% under (2) and 81% under (1) describe
             quite different pairs of people.

             WHAT NEEDS DECIDING, roughly in order:

             a. WHAT DOES THE PERCENTAGE MEAN to a Seeker? Is 50
                the floor of the scale or its middle? Should a
                number below 50 be possible at all?
             a2. WHOSE NUMBER IS IT? Found 2026-08-10 while
                testing the Reveal on the live seeded pair:
                score_candidates() is ASYMMETRIC, because each
                person is scored against the OTHER's
                preferences. Yusuf scores Aisha 84.5%; Aisha
                scores Yusuf 88.2%. Same two people, same data,
                two different numbers.

                The Reveal shows ONE. Which one is an accident
                of sequence: revealCompatibility() computes and
                stores the score when the SECOND person reveals,
                from that person's perspective. So the "shared"
                compatibility of a couple depends on who happened
                to press the button last, and the pair sees a
                number that is true for one of them and not the
                other.

                Options: show each Seeker their own figure (two
                private numbers, no shared one); average them;
                take the lower; or define a genuinely symmetric
                measure. This is not a bug to patch — it is the
                same question as (a), asked about a pair rather
                than a person, and it should be answered with the
                rest of the method.
             b. SHOULD A RED COST MORE THAN A GREEN EARNS?
                Currently -3 against +2. That is a moral position
                about how much a dealbreaker-adjacent mismatch
                should hurt, expressed as a constant.
             c. WHAT COUNTS AS 100%? Today it means every scored
                answer was green — achievable and, on the seeded
                data, achieved by 48% of pairs. If nearly half of
                everyone is "100% compatible", the number stops
                meaning anything.
             d. HOW MANY CATEGORIES, AND WHICH? The Unlock+
                screen shows six (Lifestyle, Work & Education,
                Family Values, Marriage Goals, Personality, Deen)
                and onboarding has nine, and they do not map onto
                each other. score_candidates() returns no
                category detail at all.
             e. ONLY THEN v_ch2_weight — how much sect and
                ethnicity should move a number whose meaning is
                settled.

             DO NOT TUNE ANY OF THIS ON THE SEEDED DATA. The 144
             Chapter 3/4 rows are synthetic (OA-ZYRA-190) and the
             measured spread — 77 to 100, mean 86.3 — is a
             property of the assortative decay rule used to
             generate them, not of any real population. Point (c)
             above is exactly the kind of question that data
             CANNOT answer.

             BLOCKED (now cleared for a/a2/b/c): OA-ZYRA-192
             steps 1-3 (wiring the real number into the paid
             Unlock screen) and the open v_ch2_weight decision in
             CLAUDE.md.

RESOLVED (a)(a2)(b)(c) 2026-08-11 — Founder, by phone.

             (a) 0-100 PLAIN COUNT. green 1, amber 0.5, red 0,
                 over the items actually scored. The +50 centring
                 is retired. It computed something defensible and
                 communicated something false: nobody reads "50%"
                 as "no data". This also ends the two-methods
                 problem in the Founder's favour — the Unlock
                 screen's figures were always built on exactly
                 this weighting.

             (b) NO. Settled by (a) rather than decided
                 separately: a plain count has no penalty term.
                 The -3 is gone. The moral position it encoded is
                 not abandoned — it moves to Hard Requirements,
                 which exclude outright and are already tested
                 before and independently of the lights. An
                 exclusion is a promise; a light is a preference.

             (a2) TWO SCORES, ONE EACH. Founder's own words: "I
                 see my compatibility with her, and she sees her
                 compatibility with me." No shared number.
                 Removes the sequencing defect as a side effect:
                 the single figure used to be computed by
                 whichever party revealed SECOND, so a couple's
                 "shared" compatibility depended on who tapped
                 last.

             (c) NO MINIMUM-ITEMS RULE — the premise was
                 rejected, correctly. Founder: "No answer is
                 optional." There is no thin profile to design
                 around, because a thin profile should not be
                 matchable. Becomes an ONBOARDING COMPLETENESS
                 GATE on entering the pool, which composes with
                 Direction B rather than fighting it: Direction B
                 says do not invent preferences for screens the
                 Seeker never saw; this says they must see every
                 screen. Together — every question is answered,
                 and every answer is real.

                 THE GATE WAS BUILT THE SAME DAY. See below.

             THE GATE, BUILT 2026-08-11:

               profiles.onboarding_complete, maintained by three
               triggers and backfilled, required by
               zyra_can_view_profile clause 4 (browsing, BOTH
               parties) and zyra_can_match.

               Clauses 1-3 are deliberately NOT gated: yourself
               (you must be able to see your own profile while
               fixing it), your Guardian or ward (a family
               relationship does not lapse over three questions),
               and the other Seeker in a shared attempt (a
               running Journey must not half-disappear because a
               profile changed underneath it).

               MATERIALISED, not computed in the policy:
               zyra_can_view_profile is the USING clause of
               profiles_select and runs per row on every profile
               read in the app. Walking the 72-row question bank
               there would have been a cost nobody found until
               Browse got slow for no visible reason.

             ⚠️ THE FIRST ATTEMPT WAS WRONG AND WAS CAUGHT BY
             MEASURING BEFORE ENFORCING. "Every question in the
             bank" excluded 38 of 144 seeded Seekers. They were
             not incomplete: all 38 had answered "No" to ch3_q3
             (do you want children) and had correctly never been
             shown ch3_q24 (when). Enforcing it would have
             removed 26% of the population from Browse for
             answering honestly.

               ch3_q3 = 'Yes'             68 seekers, 68 answered q24
               ch3_q3 = 'No'              38 seekers,  0 answered q24
               ch3_q3 = 'If Allah wills'  30 seekers, 30 answered q24
               ch3_q3 = 'Unsure'           8 seekers,  8 answered q24

             The cause: applicability is gender AND a conditional
             rule, and the conditional half (showIf) lived only in
             Dart. The server held half a rule and did not know
             it. Both halves are now in
             zyra_onboarding_questions.

             AFTER THE FIX: 144 of 144 pass, all six dev accounts
             pass, nobody is locked out. Verified live that an
             incomplete Seeker drops from 69 browsable men to 1 —
             their Journey partner, via the clause-3 exemption —
             and can neither view nor match, while still seeing
             themselves and their Journey partner.

             BUILT THE SAME DAY (2026-08-11):
               - zyra_light_weight() replaces zyra_light_points(),
                 which was dropped rather than left dormant
               - score_candidates() rewritten to the plain count;
                 returns NULL rather than a neutral 50 when it
                 cannot score, and NULL-array guarded
               - journey_compatibility: seeker_a_score /
                 seeker_b_score / _categories added,
                 overall_score and category_scores DROPPED so a
                 stale client fails closed rather than showing a
                 retired-scale number
               - zyra_compatibility_for_plus() and
                 zyra_dev_set_compatibility() rewritten
               - revealCompatibility() computes only the caller's
                 own figure, on their own reveal
               - Compatibility Unlock shows the real number; the
                 sample marker MOVED to the category breakdown,
                 which is still a constant pending (d)
               - Browse ordering made NULL-tolerant: unscored
                 candidates rank last rather than crashing the
                 sort into its catch block

             MEASURED AFTER THE CHANGE, same seeded pool:
               Yusuf->Aisha  84.5 -> 75.0
               Aisha->Yusuf  88.2 -> 78.3
               population    77-100 mean 86.3 -> 70.7-82.7 mean 76.4
               at 100%       48% of pairs -> NONE
               unscoreable   0

             The 48%-score-100% worry in (c) above did not
             survive contact with the real question bank, exactly
             as predicted: it was an artefact of only ~8 questions
             being scored. With ~70 Chapter 4 questions in play,
             no pair in the seeded population is all-green.

             STILL OPEN: (d) categories.

             ── (e) v_ch2_weight — MEASURED 2026-08-14. Not closed,
             but no longer a question worth spending a decision on
             first. Whole population, 10,257 pairs:

               weight   lowest  highest    SD   Ch2 % of denominator
                  1      64.9    87.2    3.17          ~5%
                  3      63.8    88.1    3.29         ~14%
                  5      61.6    89.0    3.61         ~21%
                 10      57.4    90.6    4.68         ~35%
                 20      51.9    92.7    6.57         ~51%

             Weighting Chapter 2 at TWENTY times each Chapter 3
             question — over half the entire score — still produces
             less spread than scoring 20 Chapter 3 questions would
             (SD 6.20). The weight is a small correction to a
             denominator of ~70; it is the wrong lever, and every
             number in that table moves if the question count
             changes. Pick a value for editorial reasons — sect and
             language SHOULD outweigh a lifestyle question — but
             settle OA-ZYRA-227 first.

             ── AND A RE-READING OF THE NOTE ABOVE. "With ~70
             Chapter 4 questions in play, no pair in the seeded
             population is all-green" was recorded on 2026-08-11 as
             reassurance. It is the same 1/sqrt(n) concentration
             OA-ZYRA-227 measures, seen from the other side. Nobody
             scores 100 for the same reason nobody scores 40: the
             average of ~70 bounded terms cannot reach either end.
             The worry in (c) did not go away — it moved.

             UPDATE 2026-09-10 — FOUNDER-DIRECT RELEASE SAFETY
             STEP 1 COMPLETED. `profile_unlock_screen.dart`
             retains the Exact Trio headings and all six ruled
             category names but renders eighteen neutral dashes
             and the truthful status "Detailed compatibility
             isn’t available yet." No sample category values or
             percentage semantics remain. The Detail balance and
             action are absent. A standard unlock can no longer
             enter the old standard-to-Plus chooser while the
             data is unavailable. `zyra_unlock_service.dart`
             independently refuses every new Plus attempt before
             mock, sample or RPC write paths while preserving an
             already-held Plus row and its real Guardian access.
             Focused tests 12/12 pass at 320px and 130% text,
             including both locked and previously-unlocked states
             plus semantic labels; analyzer passes with zero
             issues. Full suite reached 791 passes and retained
             exactly the known 60 unrelated Dashboard golden
             mismatches; no approved pixels were changed.

             SAME-DAY AUDIT FINDING: `zyra_journey_service.dart`
             still builds five `categoryScores` entries by
             assigning each the overall score, and
             `journey_flow_screen.dart` renders them as exact
             percentages. This is now explicitly owned by this
             OA's open (d). TestFlight upload remains held until
             that surface is made truthful or real category data
             is implemented. No new OA identifier created.

             UPDATE 2026-09-10 — FOUNDER-DIRECT RELEASE SAFETY
             STEP 2 COMPLETED. Journey Reveal now writes and reads
             only the caller's real overall score plus the mutual
             reveal lifecycle. It does not request the other
             Seeker's score, and it does not write, select, cache,
             render or interpret category JSON. The UI says
             "Detailed compatibility isn’t available yet." The
             score-only ZYRA Insight also dropped unsupported
             strongest/weakest, population-comparison and marriage-
             outcome language. Historical synthetic category JSON
             stays byte-preserved in the database and is ignored;
             no migration or live database write was performed.
             Focused Journey/app-shell tests, analyzer and the
             repository checker pass. The full suite remains at
             exactly the known 60 unrelated Dashboard golden
             mismatches; no approved pixel was regenerated or
             changed. Product question (d) remains Open for a real
             category method, but no false category percentage now
             ships. Separate shared-row authorization and truthful-
             failure risks are recorded as OA-ZYRA-283/284.

------------------------------------------------------------

OA-ZYRA-226
Update 2026-09-28 — LOCAL RESEARCH PROOF, LIVE FIX STILL OPEN:
             OA193's authorised Stage1 now tests q24/q26/q39 counterpart
             targeting, complete raw validation and affected-only Chapter2/
             Chapter4 review receipts, cancellation and peer preservation.
             Both q26 aliases are rejected in validated/review-editable state.
             Production capture/restore/prune/save/decoder were not edited;
             registered custom-sect research vocabulary is not a live capture
             policy. No closure; separate integration/server GO still required.
Update 2026-09-28 — TARGETING POLICY SETTLED / BUILD HELD:
             DR-ZYRA-250 D2 settles canonical counterpart-target targeting,
             including q24/q26/q39, dependencies, gender variants and Hard
             Requirements. Older "choose inversion or exclusion" and blanket
             "clear all144 rows" targets below are historical, not current
             execution authority. Use explicit target vocabulary/applicability;
             reject ambiguous aliases and partial data. Reconfirm affected
             legacy Amber controls only; structural repair/recollection is
             separate and must preserve unrelated data. No bulk reset approved.
             Stage0 reconciled Onboarding Summary/References/Rules & UX;
             old auto-Green Chapter4 Skip and colour wording are historical.
             Legitimate Chapter2 skip conditions remain separate. Stage1 new-
             files-only synthetic brief is DRAFT; no app or database edits/tests.
Title:       Chapter 4 Gates On YOUR Gender When It Should Gate On
             THEIRS — Two Required Questions Score Nothing
Category:    Compatibility Engine / Onboarding
Priority:    HIGH — proven in live data. Supersedes the framing of
             OA-ZYRA-223, which called this an id collision.
Status:      Blocked (restamped 2026-08-20, OA-AIOS-326; was Open) — root cause proven, fix not built.
Owner:       Founder (one product call), then Engineering
Raised:      2026-08-14
Source:      Verification of OA-ZYRA-223 against source and the live
             database.

Description: THE ROOT CAUSE, in one line: Chapter 3 asks about YOU, so
             gating it on your own gender is right. Chapter 4 asks what
             you want in a PARTNER — and it gates on your own gender
             too. values_preferences_flow.dart:65, _visibleCh4, filters
             _visible(), which is gender-gated by widget.gender.

             CONSEQUENCE 1 — ch3_q26 (polygamy), required in Chapter 4.
             Two variants share the id, one menOnly and one womenOnly,
             with DIFFERENT option lists. Measured across all 144
             seeded Seekers:

               Chapter 3 answers (about themselves)     CORRECT
                 females hold women's options
                 males hold men's options

               Chapter 4 preferences (about a partner)  WRONG
                 females hold WOMEN'S options
                 males hold MEN'S options

             So every woman has rated what SHE might be, not what he
             might be. Sample row, verbatim from the database:
             {"I would only marry as the only wife": "yellow",
              "I would consider being an additional wife": "green"}.
             That is a woman's Chapter 4 PREFERENCE — describing
             herself.

             And because a female's preference keys are women's strings
             while every male candidate's answer is a men's string, the
             lookup can never match. A REQUIRED question on POLYGAMY —
             one of the most consequential compatibility axes this app
             has — contributes nothing to a woman's score, ever.

             ── CORRECTION, 2026-08-14 (same day, engine audit). The
             line above originally read "the two vocabularies do not
             overlap at all… in either direction." THAT IS TRUE FOR
             WOMEN AND FALSE FOR MEN. Both option lists contain the
             string "I'm unsure". Measured:

               female → male   0 of her 4 keys match   contributes zero
               male → female   1 of his 4 keys matches — "I'm unsure"

               women whose q26 answer is "I'm unsure"        6
               men holding a light for "I'm unsure"         72
                 (57 yellow · 9 red · 6 green)
               pairs currently scoring on this key         432

             In those 432 pairs a man's rating of HIS OWN uncertainty
             about taking more than one wife is applied as a judgement
             of HER uncertainty about being an additional wife. Two
             different propositions that happen to share a label.

             So the defect is asymmetric: for women it is a missing
             signal, for men it is a WRONG one. That does not change
             the decision below, but it does make clearing the stored
             preferences a correctness fix rather than tidying.

             ── SCOPE EXTENSION, same audit. ch4_hard_requirements is
             evaluated by the identical string lookup, before scoring,
             and excludes the candidate outright on a hit. All 21 hard
             requirements in the database today sit on gender-neutral
             questions (ch3_q1, ch3_q2, ch3_q52), so none is affected —
             and all 21 are also red in the same person's own matrix,
             which confirms the exclusion direction is right and the UI
             is not inverted. But a hard requirement stored under a
             gendered question would SILENTLY NEVER FIRE. A dealbreaker
             that does nothing is worse than a score that counts
             nothing, because the Seeker was told it was absolute.
             Whatever is decided below must cover hard requirements,
             not only preferences.

             CONSEQUENCE 2 — ch3_q39 (Masjid attendance), menOnly and
             also required in Chapter 4. Measured:

               males:   72 state a preference · 72 answer it
               females:  0 state a preference ·  0 answer it

             The 72 male preferences can never be compared against
             anything, because only females are candidates and none of
             them answer it. And the group who would actually want to
             state this preference — women, about a husband — is never
             asked.

             NEITHER IS AN ID COLLISION. Within one account only one
             variant is ever visible, so nothing overwrites anything.
             OA-ZYRA-223 was looking at the right question for the
             wrong reason.

Target:      1. FOUNDER CALL FIRST, because the fix changes what is
                asked: should Chapter 4 gender-gating invert (you state
                preferences over the COUNTERPART's option set), or
                should gendered questions be excluded from Chapter 4
                entirely? Inverting is the smaller change and keeps a
                real compatibility axis.
             2. If inverting: _visibleCh4 gates on the opposite gender.
                ch3_q26 then shows a man the women's options and a
                woman the men's — which is what each is choosing about.
                ch3_q39 flips to women stating it about a husband.
             3. Existing ch4_preferences for both qids are unusable and
                must be cleared or re-collected — all 144 rows.
             4. Re-measure the score spread afterwards. Two required
                questions currently contributing zero means the live
                spread was measured without them.
             5. ANSWERED 2026-08-14 — no action needed. score_candidates
                is SILENTLY NEUTRAL on a no-overlap lookup:
                  v_light := v_prefs_for_question ->> v_value;
                  IF v_light IS NULL THEN CONTINUE; END IF;
                v_max is never incremented, so a miss neither scores
                nor penalises. Nobody was being penalised; the two
                questions were simply absent from every denominator,
                which is exactly why their absence was invisible.
             6. ADDED 2026-08-14 — the clearing in step 3 must cover
                ch4_hard_requirements as well as ch4_preferences.
Dependencies: OA-ZYRA-223 (superseded framing), OA-ZYRA-193(e) (the
             Chapter 2 weight, measured on a spread that excluded
             these), OA-ZYRA-227 (the wider spread finding — re-measure
             after this is fixed), migration 20260811172021 (the
             server-side half of the same problem, already fixed),
             REPORTS/ZYRA_COMPATIBILITY_ENGINE_AUDIT_2026-08-14.md.

------------------------------------------------------------

OA-ZYRA-227
Update 2026-09-28 — LOCAL ARITHMETIC VERIFIED, DISTRIBUTION PENDING:
             Stage1 independent rational oracle and whole-bank synthetic
             structural cases pass within OA193's 206-test result. No corrected
             population/distribution, rounding presentation or privacy-risk
             measurement was performed. Historical Stage1-GO-pending statement
             below is superseded only for the exact local executed harness;
             Chapter2 weight 1 remains provisional and this OA remains open.
Update 2026-09-28 — CORRECTED MEASUREMENT PENDING:
             DR-ZYRA-250 preserves exact Standard directional overall and
             question-based arithmetic. Historical options to remove the
             percentage, choose fewer questions, add weights or stretch the
             scale below are not adopted. Remeasure after strict targeting/
             validation fixes; Chapter2 weight 1 stays provisional. Synthetic
             distributions cannot stand for real population evidence. No new
             measurements or scope execution occurred; Stage1 GO remains pending.
Title:       The Compatibility Score Cannot Separate People — Its
             Spread Is Set By The QUESTION COUNT, Not By Compatibility
Category:    Compatibility Engine / Product
Priority:    HIGH — a paid, user-facing figure is near-constant.
Status:      Blocked (restamped 2026-08-20, OA-AIOS-326; was Open) — DECISION REQUIRED. Engine is correct; the
             specification it implements is what produces this.
Owner:       Founder (product call), then Engineering
Raised:      2026-08-14
Source:      REPORTS/ZYRA_COMPATIBILITY_ENGINE_AUDIT_2026-08-14.md —
             score_candidates re-implemented in SQL and run over all
             10,257 viable pairs in the live database.

Description: MEASURED, whole population, Chapter 3 with hard-
             requirement exclusions applied:

               lowest score anyone gets            64.3
               highest score anyone gets           86.6
               mean                                76.1
               standard deviation                  3.25
               pairs between 70 and 82      9,597 of 10,257 (93.5%)
               pairs rounding to exactly 76        1,296

             THE CAUSE IS ARITHMETIC, NOT PREFERENCES. The same method
             on fewer questions:

               questions   lowest  highest   SD    in 70–82
                   5        20.0    100.0   12.62    57.2%
                  10        40.0    100.0    8.73    61.2%
                  20        50.0     97.4    6.20    67.8%
                  40        57.7     89.5    4.50    78.7%
                ~70 today   64.3     86.6    3.25    93.5%

             SD x sqrt(question count) = 28.2, 27.6, 27.7, 28.5, 27.2.
             That is 1/sqrt(n) to three significant figures.

             SO EVERY QUESTION ADDED TO CHAPTER 3 MAKES THE SCORE WORSE
             AT TELLING PEOPLE APART. Question 71 does not add nuance;
             it divides the signal by a slightly larger number.

             WHERE IT IS FELT — 1, the paid figure.
             profile_unlock_screen.dart:742 renders the real score at
             44pt after a credit is spent.
               best match, average                 82.9
               gap #1 to #5                         2.35
               gap #1 to #10                        3.48
               gap #1 to #20                        4.97
               gap #1 to last in deck              12.82
             Five unlocks, five credits: 83, 82, 82, 81, 81.

             WHERE IT IS FELT — 2, deck order. Browse sorts by the
             score and never shows it. Within one deck there are 2,354
             groups of candidates holding an IDENTICAL score, averaging
             3.7 people each. Ties resolve through a comparator that
             returns 0, and Dart's List.sort is not documented as
             stable — so three to four people at every score level are
             ordered by nothing in particular.

             THIS ALSO ANSWERS OA-ZYRA-193(e) — see that entry.

             HONEST LIMIT: the 144 Seekers are seeded, so the constant
             (sigma ~28 per question) is measured from generated data.
             The 1/sqrt(n) law is arithmetic and holds regardless. Real
             preferences correlate, which would raise the constant and
             widen the spread somewhat — the mechanism does not change,
             the magnitude might.

Target:      FOUNDER CALL between:
             A. SCORE ON FEWER QUESTIONS — pick the 15–25 that carry
                real matrimonial weight; keep the rest as profile
                content. Restores SD ~6–7 and a ~45-point range.
                Cost: an editorial judgement only the Founder can make.
             B. WEIGHT QUESTIONS INSTEAD OF COUNTING THEM — keep all
                ~70, give each a coefficient. Same judgement, plus a
                schema change and a heavier scorer.
             C. STOP SHOWING A PERCENTAGE — keep the flat score for
                ordering; replace the 44pt number with bands or with
                the green/amber/red tallies (OA-ZYRA-230). Worth doing
                whatever happens to the engine.
             D. STRETCH THE SCALE for display — RECOMMEND AGAINST. It
                manufactures difference that is not there and goes
                stale the moment the question set changes.

             SEQUENCING: OA-ZYRA-226 first. Both broken questions
             currently contribute nothing (and one contributes
             wrongly), so every figure above was measured with them
             absent. Fix the gate, clear the 144 stale rows, re-
             measure, then choose.
Dependencies: OA-ZYRA-226 (fix first, then re-measure), OA-ZYRA-193(e)
             (answered by this), OA-ZYRA-230, OA-ZYRA-221 (Compatibility
             Unlock and declined profiles — same screen).

------------------------------------------------------------

OA-ZYRA-243
Title:       Supabase security-advisor findings — one ERROR view, auth
             toggle, and an RPC guard-confirmation pass
Category:    Database / Security
Priority:    High — the ERROR item is an RLS-bypass class; everything
             here predates launch and should close before it
Status:      Assigned (restamped 2026-08-20, OA-AIOS-326; was Open) — findings verified against the live project
             2026-08-20 during the group security review
             (BLACK_UMBRELLA_SECURITY_REVIEW_2026-08-20_V1.md, F3)
Owner:       Codex (implements) with Claude (Architecture Reviewer)
             per AD-AIOS-099; Founder approves any behavioural change
Raised:      2026-08-20
Completed:   —
Source:      Supabase security advisors (moved to private group storage).
Detail:      Moved to private group storage on 15 Nov 2026 (DOC-BUG-0062):
             BLACK UMBRELLA GROUP/BUSINESS/ZYRA/SECURITY/OA-ZYRA-243_PRIVATE_DETAIL.md
Target:      Items 1–2 before any external testing; items 3–4 before
             launch is declared.
Dependencies: AD-AIOS-099 seat assignments; Supabase project access;
              ZYRA feature-pause exception not required (security work,
              not feature work).

------------------------------------------------------------

OA-ZYRA-249
Title:       Tablet optimisation — how ZYRA behaves on iPad
             and large screens (strategy decision needed)
Status:      Open — audit complete 2026-08-23 (raised by
             Founder: "how are we ensuring the app is
             optimised for tablets"). TODAY'S TRUTH: iPad is
             an enabled native target (TARGETED_DEVICE_
             FAMILY "1,2"), runtime-locked to portrait on
             every device (main.dart setPreferredOrientations
             portraitUp; Android manifest portrait). Two
             deliberate large-screen behaviours exist: the
             splash composes at min(shortestSide, 480) so an
             iPad gets a phone-scale centred composition, and
             the tagline type ramp clamps at 480 design
             width. Everything else is a phone-first single
             column stretched to tablet width — no
             breakpoints, no adaptive/two-pane layouts, no
             global content-width cap (only local caps: chat
             bubbles 72% width, several journey cards 350,
             one wali detail 280). No tablet in the test
             cadence (Founder tests on iPhone). Decision
             needed — options in Description.
Priority:    Medium
Raised:      2026-08-23
Raised by:   Founder
Owner:       Fable (strategy + docs); build per decision
Initiative:  ZYRA product
Description: Because the iPad family is enabled, the App
             Store lists ZYRA on iPad and users WILL run it
             full-screen there, where stretched phone
             layouts read sparse and oversized. Options for
             ratification:
             (A) PHONE-FRAME — one shared wrapper caps
             content width (~480-520pt) and centres it on
             the gender gradient on any wide screen;
             portrait lock stays; cheapest, ships app-wide
             in one pass, and generalises the rule the
             splash already follows.
             (B) TRUE ADAPTIVE — breakpointed tablet
             layouts (e.g. Dashboard list + detail two-pane,
             wider Discover card grid); the real tablet
             experience; significant design + build cost
             per screen.
             (C) DROP THE TARGET — device family iPhone-
             only; ZYRA leaves the iPad listing; cheapest,
             but guardians/parents skew tablet-heavy, so it
             cuts against the Wali side of the product.
             RECOMMENDATION: A now (plus an iPad-simulator
             pass in the release checklist), B later for
             Wali surfaces if tablet usage shows up in
             analytics; C not recommended for a guardian-
             centred product.
Evidence:    ios/Runner.xcodeproj TARGETED_DEVICE_FAMILY;
             main.dart orientation lock; splash_screen.dart
             design-width notes; zyra_text.dart taglineSize
             clamp; grep audit 2026-08-23 (11 LayoutBuilder
             files, 7 local maxWidth caps, no breakpoint
             constants anywhere in lib/)
Target:      Founder picks A / B / C (or phased A then B) ->
             Fable writes the tablet rules into the UI
             architecture docs -> implementation scheduled;
             an iPad pass joins the test cadence either way

------------------------------------------------------------

OA-ZYRA-253
Title:       Paid Membership and Entitlement Activation — current model:
             Seeker One £29.99/month; Guardian One £19.99/month;
             configurable role-count Family; Basic £4.99 once (DR-ZYRA-252)
Update 2026-10-04 (Family onboarding introduction / DR-ZYRA-263):
             Both protected signup roles show the explicit introductory
             comparison, separate from normal renewal. Pricing/Onboarding
             §108/Paid Membership §12/named Family receipt own scope/checks.
             No commercial activation or trial change. Current selected role
             places assume one person per place; verified-person eligibility,
             dual-role treatment and StoreKit products/receipts remain OPEN
             here before checkout. No deduplication or actual billing inferred.
Status:      Open — DR-ZYRA-248 client presentation and forward server
             contract are implemented locally. Real billing, receipt truth,
             verified-person IDV/trial callbacks, regional price points,
             Family operations, server replay and production activation remain
             outstanding.
Current amendment — 2026-10-03 / DR-ZYRA-252:
             Founder restored Seeker/Guardian Basic at £4.99 once, with no
             monthly subscription, and requested signup membership choice
             after account details before IDV. Client implementation and
             affected verification are BUILT / INTERNALLY VERIFIED; the new
             main PROFILE app is installed, with native launch awaiting a
             fresh unlock after auto-lock. Physical acceptance is pending.
             Onboarding Preview §93 / Paid Membership §11 and
             ONBOARDING_BASIC_MEMBERSHIP_CHOICE_2026-10-03_VERIFICATION.json
             record the exact client/source/delivery evidence.
             Preserve the historical paid-only
             evidence below. New choice is private intent, not paid proof;
             default/legacy Basic state must not be advertised as confirmed
             purchased access. Existing staged server contract, products and
             receipts need reconciliation before separate live activation.
             No £4.99 introductory One/Family month or universal extra fee is
             inferred. OA-ZYRA-303 owns signup; OA-ZYRA-293 owns retained quotas
             and non-live adverts. No duplicate action or closure is raised.
Priority:    High
Raised:      2026-08-23
Raised by:   Founder ("ZYRA One is now 39.99 a month and
             Guardian standing alone is 24.99 a month.. we
             also include ZYRA One for a week for 19.99 a week
             and Guardian stand alone for week 14.99")
Owner:       Codex (client and implementation contract); Founder (commercial
             activation and final acceptance)
Initiative:  ZYRA product
Description: Implement DR-ZYRA-248 without fake checkout. Catalogue,
             Membership, Help and website expose only Seeker One £29.99/month,
             Guardian One £19.99/month and the independent 0–10-per-role Family
             formula capped at 40%. A person may hold separate Seeker and
             Guardian accounts, but each role needs its own entitlement/place.
             Keep legacy Basic values parseable only during migration so stale
             rows fail safely with zero product entitlement. Register matching
             regional store products, validate receipts/webhooks, bind the
             one-lifetime Seeker trial to the verified person and enforce paid
             capabilities on the server before activation.
Evidence:    ZYRA_PRICING_CURRENT_VERSION_V6.md; DR-ZYRA-248;
             `20260924100231_founder_paid_only_returns_guardian_circle_contract.sql`
             staged at SHA-256
             `f6af8a28e1b0ce319a8daaa39ff22fc30574bd6c9d47f70a5de8cfec49374006`;
             all 121 Family calculations, final non-visual Flutter suite and
             website pricing/browser checks pass. Production is unchanged.
Target:      Verified store products, receipt pipeline, authoritative Guardian
             entitlement, comment service and server-enforced paid capability
             boundaries; separate exact production activation approval.

------------------------------------------------------------

OA-ZYRA-254
Title:       Push notification pop-ups — deferred build
             (Founder: "add to OA and we do another time")
Status:      Deferred — Founder decision 2026-08-23. TODAY'S
             TRUTH (verified in tree same day): ZYRA has
             IN-APP notifications only — server-written rows
             (new_match / new_message / wali_request) read by
             zyra_notification_service.dart into the
             Notifications tab with a badge on a 20s poll. No
             push packages in pubspec, no OS banners/lock-
             screen alerts, no iOS permission prompt anywhere
             (correct — nothing needs it yet).
Priority:    Medium (deferred — not scheduled)
Raised:      2026-08-23
Raised by:   Founder (notification pop-ups question via the
             Codex chat; answered by Fable, mailbox convention
             created at SYSTEM/RESOURCES/MESSAGES/ the same
             day)
Owner:       Unassigned until scheduled (build brief needed;
             Codex implements per AD-AIOS-099)
Initiative:  ZYRA product
Description: Scope when picked up: (1) DEPENDENCY — paid
             Apple Developer Programme membership (Founder,
             ~£79/yr): APNs push capability is blocked by the
             current Personal Team exactly like Sign in with
             Apple (ZYRA_APPLE_SIGNIN_HANDOVER V1) — one
             membership unblocks both. (2) BUILD — push
             plumbing (APNs/FCM), permission prompt asked at
             the right moment (post-sign-up, never first
             launch), server-side senders, token storage.
             (3) PRODUCT DECISIONS (Founder, at brief):
             which Seeker-side events earn a pop-up (new
             match? new message?); quiet hours; sounds.
             (4) STANDING CONSTRAINT already ratified:
             Guardian Network Rule 36 calm delivery — NO
             per-request GN push, one badge, at most one
             daily digest, zero Seeker identifiers in any
             notification copy ("You have a new Guardian
             Network request." is the model sentence).
Evidence:    zyra_notification_service.dart (in-app only);
             pubspec.yaml (no push packages); GN spec Rule
             36; ZYRA_APPLE_SIGNIN_HANDOVER_CURRENT_VERSION_
             V1.md (Personal Team blocker)
Target:      Founder schedules it ("we do another time") ->
             Apple Developer membership -> brief -> build ->
             handover per IMPLEMENTATION_HANDOVER_STANDARD

------------------------------------------------------------

OA-ZYRA-256
Title:       Decide and govern production promotion analytics and
             cross-device cadence persistence before any collection
Status:      OPEN — waiting for the Founder's GO to change production (built locally; server change staged). PHASE 2 LOCAL/STAGED CONTROLS + AIOS FOUNDER SURFACE COMPLETE /
             COLLECTION OFF — production privacy, independent security
             review, isolated replay, exact apply, aggregate-feed and
             compile-enable gates remain open
Priority:    Pre-launch / Privacy
Raised:      2026-08-23
Raised by:   Fable from the Founder-directed promotion review
Owner:       Founder (production/privacy gates); Codex (implementation and
             evidence); solicitor/privacy review where required
Initiative:  ZYRA privacy / analytics / subscriptions
Description: DR-ZYRA-239 selects first-party, identifier-free fixed events.
             Phase 1 added typed bounded memory, a truthful Founder view,
             initial shell/ZYRA-Code evidence and one staged private-table/
             authenticated-RPC migration. Phase 2 adds completed/failed ZYRA
             Code funnel evidence, fixed 30-day staged raw retention, a
             service-role-only aggregate function, transaction-scoped caller
             serialization and an identifier-free project circuit breaker.
             Phase 2B adds fixed funnel coverage for Membership, Support,
             Identity Check and Guardian management without adding any event
             field or member/action payload.
             Phase 2C adds a separate fixed action enum, zero-inclusive
             Founder feature/action counts and matching staged `action_key`
             storage/aggregation. This distinguishes what control was used
             without recording button copy, ids, text or person data.
             The existing AIOS portal now includes a Founder-only Health &
             Usage page and read-only aggregate API. Both truthfully report
             collection off; AIOS has no Supabase credential or live feed.
             Normal builds keep the remote gate OFF. Before any event leaves
             memory, finish lawful basis/privacy wording and objection
             design; independent retention/access/abuse review; isolated replay and
             direct-call security tests; exact migration apply GO; post-apply
             probes; and a separate compile-enable release gate. Cross-device
             promotion cadence persistence remains unbuilt and must not be
             inferred from the event table.
Evidence:    ZYRA_PRODUCT_OBSERVABILITY;
             ZYRA_PRODUCT_OBSERVABILITY_BUILD_CONTRACT;
             ZYRA_PRODUCT_OBSERVABILITY_HANDOVER;
             BLACK UMBRELLA GROUP/SYSTEM/RESOURCES/REPORTS/
             AIOS_ZYRA_HEALTH_USAGE_PHASE1_2026-09-18_V1.md;
             migration `20260918171910_oa256_product_telemetry_foundation.sql`;
             Phase 2C focused tests 36/36 PASS; analyzer clean; profile build,
             device catalog verification and direct iPhone launch PASS;
             production unchanged.
Target:      Independent SQL/privacy review of the staged controls,
             exact-file/hash apply gate, post-apply verification and separate
             compile-enable release decision.
Dependencies: DR-ZYRA-213; DR-ZYRA-239; OA-ZYRA-255; OA-ZYRA-297

------------------------------------------------------------

OA-ZYRA-258
Title:       Payments architecture — Apple IAP for in-app,
             Stripe for web; ZYRA CONNECT Stripe onboarding
Status:      Open — Stripe connector added by Founder
             2026-08-23; Fable read-only audit same day.
             ACCOUNT STATE (live acct_1U7jIT..., Standard,
             GB): country/currency/timezone CORRECT (GB, GBP,
             Europe/London); name ZYRA CONNECT, url
             zyraconnect.app, statement descriptor
             ZYRACONNECT.APP; payouts daily after 7 days
             (default). NOT READY TO CHARGE: charges_enabled
             false, payouts_enabled false, disabled_reason
             requirements.past_due — Stripe still needs
             business type, representative identity (name,
             DOB, address, phone, email), MCC + product
             description + support phone, a bank account for
             payouts, and ToS acceptance. ALL Founder-only
             items completed in the Stripe Dashboard — Fable
             never enters identity, bank or ToS data. No
             products/prices defined yet (correct at this
             stage). A separate "ZYRA CONNECT sandbox" test
             account exists for development.
Priority:    High (pre-revenue launch blocker chain)
Raised:      2026-08-23
Raised by:   Founder ("I'm guessing this will be payment for
             App Store... check if the settings are correct")
Owner:       Founder (Stripe onboarding + Apple Developer
             membership); Fable (architecture docs, product/
             price mirroring once decided); Codex (client
             integration when briefed)
Initiative:  ZYRA product
Description: ARCHITECTURE (the answer to the Founder's
             question): Stripe does NOT process App Store
             payments. Apple requires In-App Purchase for
             digital subscriptions sold INSIDE an iOS app
             (ZYRA One, Guardian+, Compatibility Unlocks) —
             so the app itself uses Apple IAP (and Google
             Play Billing on Android); Apple/Google take
             their commission (Apple 15% under the Small
             Business Program while under $1M). STRIPE'S
             correct role: subscriptions sold on the WEB
             (zyraconnect.app checkout, the Netflix/Spotify
             model where the app honours a subscription
             bought outside), plus any future non-digital
             payments. Both rails share ONE entitlement
             source (Supabase) so the app never cares where
             a subscription was bought. RECOMMENDED ORDER:
             (1) Apple Developer Programme membership — the
             same GBP79/yr already blocking Apple Sign-In
             and push (OA-102, OA-ZYRA-254) also gates IAP:
             one decision clears three blockers plus
             payments; (2) IAP products mirroring
             ZYRA_PRICING V2 (39.99/mo, 399.90/yr, 19.99/wk;
             Guardian+ 24.99/mo, 14.99/wk; unlock packs);
             (3) Founder completes Stripe onboarding
             (identity/bank/ToS); (4) Stripe web checkout as
             phase 2. Pricing doc note: Apple/Google
             commission does not change retail prices;
             margin impact is a Founder awareness item.
Evidence:    Stripe live account read 2026-08-23 (account
             object, requirements.past_due list, empty
             products); ZYRA_PRICING_CURRENT_VERSION_V2.md
             to-do "Finalise payment provider implementation
             (Stripe — OA pending)" -> THIS OA
Target:      Founder: Apple Developer membership + Stripe
             Dashboard onboarding -> architecture ratified ->
             IAP build brief -> Stripe web phase 2

------------------------------------------------------------

OA-ZYRA-259
Title:       ZYRA Learning Loop — adaptive Dashboard insights
             (Founder directive 2026-08-25; existing-Dashboard
             correction honoured: a learning layer in the
             EXISTING Seeker Dashboard, not a new Dashboard)
Status:      Open — P0 COMPLETE same day: rules draft
             ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md filed
             (learning model + loop states; permitted data
             sources with message-content and Guardian-data
             exclusions; evidence tiers 0/1/2 with 3/5-
             counterpart floors, anonymity floor, 7-day
             dignity cool-off, 90-day decay; observation-not-
             cause wording law incl. entitlement language
             rule; auto-vs-user-confirmed boundary — NO
             behavioural change without confirmed learning,
             preferences never auto-edited; Basic 1 insight /
             One up-to-3 depth split, same honesty both
             tiers; privacy/retention/DSR + Seeker-only rule,
             Guardian surfaces receive nothing; contradiction
             check vs compatibility, Journey, entitlement and
             data-protection docs — clean, two obligations
             imported: Article 9 gate + automated-processing
             disclosure). PRODUCTION LEARNING INACTIVE until
             Founder ratifies rules (P3 gate); Article 9
             families additionally solicitor-gated. Codex
             briefed (MESSAGES/001) for P1: historic-data
             audit, per-family feasibility, missing-
             aggregation list, mock insight cards in the
             existing Dashboard (positive / neutral /
             insufficient-data / preference-review; Basic vs
             One shown), mock clearly separated from
             production learning.
Evidence:    Founder directive 2026-08-25 (Fable + Codex);
             SYSTEM/DOCUMENTS/ZYRA_LEARNING_LOOP_CURRENT_
             VERSION_V1.md; SYSTEM/RESOURCES/MESSAGES/001_
             FABLE-CODEX_2026-08-25_LEARNING_LOOP_BRIEF.md
Target:      Founder ratifies rules + insight copy -> Codex
             P1 data audit + mocks -> P2 silent aggregation
             -> P3 Seeker-visible insights -> P4 confirmed-
             learning recommendation influence

------------------------------------------------------------

OA-ZYRA-266
Title:       Identity verification in the app — photo
             verification, ID-document verification, face
             verification (Founder directive 2026-08-28,
             recorded; definition round pending)
Status:      OPEN — Stripe enquiry HELD by Founder 2026-09-13;
             Gmail draft retained for the Founder to send manually
             when ready. No provider message has been sent by Codex.
             Current outreach note and release condition below.
             HISTORICAL INTAKE STATUS (2026-08-28):
             RECORDED, NOT YET SCOPED. Founder: "we
             gotta add into app identification. photo
             verification / id verification / face
             verification." Nothing is built or promised in
             current Terms wording (Legal Research V1
             explicitly requires a best-efforts verification
             disclaimer BECAUSE none exists). Definition
             round must settle, in order: (1) product scope
             — which of the three layers at launch, which
             users (Seekers only? Guardians?), mandatory vs
             badge; (2) provider vs in-house (candidates to
             evaluate: Stripe Identity, Onfido, Veriff,
             Persona — costs per check are a real unit-
             economics input to pricing); (3) LEGAL GATE:
             face verification/biometric matching is UK GDPR
             special-category (Article 9) biometric data —
             explicit consent + DPIA required; ID-document
             images carry their own retention/security
             duties; joins the existing solicitor
             instruction list alongside the Art. 9
             compatibility axes (OA-ZYRA-259 gate, Chapter 2
             review section 6 — one instruction can cover
             all); (4) "verified" badge product rules —
             Guardian Page Review V1 gap 1 refusal ("no
             verified badge — nothing to verify against")
             becomes closable once this exists; (5) Terms/
             privacy-policy wording update at build time;
             (6) ADDED 2026-08-29 per DR-ZYRA-219 item 8:
             the "full account activation" CAPABILITY MATRIX
             — define exactly which capabilities require a
             verified person identity, ruling at minimum on
             onboarding, Browse, Consider/Save/Pass,
             matching, Potential Journey, Active Journey,
             Guardian linking, messaging, purchases;
             ambiguity prohibited.
             NOTE: Apple Developer membership (OA-ZYRA-267)
             is unrelated technically but both were directed
             in the same Founder message toward App Store
             readiness.
Evidence:    Founder chat directive 2026-08-28; ZYRA_LEGAL_
             RESEARCH_CURRENT_VERSION_V1.md (verification
             disclaimer + Art. 9 handling); ZYRA_GUARDIAN_
             PAGE_REVIEW_CURRENT_VERSION_V1.md gap 1
             PROGRESS 2026-08-29: provider evaluation
             COMPLETE (OA-ZYRA-280 closed; 027 verified).
             Sumsub = conditional launch lead per 027 §11;
             eight acceptance conditions recorded there.
             FOUNDER ACTIONS NOW THE CRITICAL PATH:
             (a) create a Sumsub sandbox/trial account
             (Founder-only — accounts/keys never touch the
             AI seats) and request the written all-in quote
             (IDV + liveness + face match + Similar Search
             API + manual-review routing, chargeable-event
             definitions) plus the DPA/retention/data-
             location pack; (b) optionally request Stripe
             Identity test access via the existing Stripe
             onboarding + written answer on exposing
             duplicate-selfie insight as an account-local
             API/webhook flag (fallback path); (c) the
             capability matrix (DR-ZYRA-219 item 8, listed
             at (6) below) — Fable will draft the decision
             sheet on request; (d) SUPERSEDED by DR-ZYRA-220
             (2026-08-29): NO solicitor engagement — the
             prepared pack was withdrawn/archived the same
             day; its seven questions became the IN-HOUSE
             compliance checklist (Fable drafts consent
             wording, privacy policy and DPIA; Founder
             reviews, accepts provider terms and signs;
             risk acceptance recorded in DR-ZYRA-220). All
             earlier "solicitor gate" mentions across this
             register are historical text and read as
             "DR-ZYRA-220 self-serve compliance path" from
             2026-08-29 onward.
             Profile-photo-vs-selfie matching stays OFF
             until separately proved and approved (027 §11
             condition 8).
             FOUNDER DIRECTION 2026-08-29 (post-027 ruling,
             recorded verbatim-in-substance): (1) Sumsub
             stays CONDITIONAL lead — not finally selected
             until written confirmation of: duplicate-person
             detection capability; programmatic/API access
             to the duplicate signal; duplicate = review/
             flag only, NEVER automatic ban; human-review
             workflow; search limited to ZYRA's own
             population where required; full pricing; DPA;
             retention; data location/residency;
             sub-processors; deletion behaviour; UK/GDPR
             position. Founder handles the account creation
             when ready. (2) Stripe Identity stays LIVE
             FALLBACK — route stays open; written answer
             still needed on API/programmatic exposure of
             the duplicate insight; no test access created
             yet. (3) Veriff OUT while its documented
             behaviour auto-declines duplicates — product
             rule restated: duplicate signal -> human review
             -> Founder/authorised resolution; NEVER an
             automatic ban solely from duplicate detection.
             Re-entry only on written non-blocking
             configuration. (4) GO: Fable drafts the
             capability matrix (Founder-first decision
             sheet; UNKNOWN where written provider evidence
             is absent). (5) GO: Fable prepares the
             solicitor instruction pack from 027 §9 —
             PREPARED ONLY, sent nowhere; engineering
             assumptions separated from legal questions.
             (6) OA-ZYRA-266 is the MASTER IDV record — no
             further IDV OAs unless something becomes a
             genuinely independent project. (7) CHECKPOINT:
             matrix + solicitor pack return to the Founder
             TOGETHER; he then rules on required
             capabilities, Sumsub sandbox/commercial pack,
             Stripe fallback status, and what goes to the
             solicitor. No production implementation before
             those decisions; no provider commitment; no new
             Codex implementation.
             GO-FORWARD PLAN SAVED AS DIRECTED (Founder,
             2026-08-29, post-DR-ZYRA-220): (i) DONE 2026-08-29 —
             matrix RULED as DR-ZYRA-221: verification
             mandatory AT ONBOARDING, app closed to
             unverified users; all rows inherit REQUIRED; (ii) Founder
             creates the Sumsub account (Fable drives the
             browser; Founder types credentials), sandbox
             keys collected, written all-in quote requested
             (Similar Search API inclusion + chargeable-
             event definitions); (iii) Google Cloud Vision
             SafeSearch API enabled on the existing ZYRA App
             project for the nudity/NSFW profile-photo
             checker (Edge Function at upload; ~1,000 free/
             month then ~$1.50/1,000; also satisfies App
             Store Guideline 1.2 moderation with a Report
             button); (iv) PHASE A CODE COMPLETE +
             FABLE-VERIFIED 2026-08-29 (030/031): consent
             screen (verbatim copy, versioned consent),
             fail-closed new-account onboarding for Seeker +
             Guardian, coarse state machine (verified +
             duplicate-clear needed for Active Journey),
             report UI + dev-only INTERNAL PREVIEW
             moderation queue, migration STAGED at
             supabase/migrations/20260829183507_* and
             LIVE-PROBED NOT APPLIED (0 tables/routines);
             existing-account retrofit fuse dormant
             (defaultValue: false) so current members are
             not locked out pre-provider. 656/656 tests.
             MIGRATION APPLIED 2026-08-29 under written
             Founder GO (scope as stated: private schema, no
             enforcement, no user impact, no provider
             dependency, fuse off, reversible pre-
             production). Applied by Fable via the Supabase
             MCP with the byte-identical staged SQL (hash
             re-verified 78eb82c8... before apply); history
             row inserted under the EXACT local version
             20260829183507 so the CLI stays in sync.
             SIX-POINT POST-APPLY VERIFICATION ALL PASS:
             (1) 2 private tables + 8 IDV routines created;
             (2) RLS on both tables, zero anon/authenticated
             grants, schema USAGE false for anon+
             authenticated / true for service_role;
             (3) auth/onboarding untouched (auth.users 150,
             purely additive DDL); (4) no user blocked
             (fuse dormant, 0 attempt rows, nothing live
             reads the tables); (5) no provider call
             possible (attach/record functions refuse
             authenticated, no Edge Functions, no keys);
             (6) feature OFF pending explicit Founder
             activation — applying ≠ enabling, recorded.
             FOUNDER ACTION — SUMSUB FORM NOT YET CONFIRMED:
             mailbox searched in:anywhere for sumsub — ZERO
             threads, so no submission acknowledgement
             exists; treat the form as NOT submitted until
             the Founder confirms or a Sumsub email lands
             (daily triage watches). No provider keys/
             accounts/commercial terms without the Founder.
             VISION: GO to technically prepare/enable the
             SafeSearch API at next console session
             (required by the approved photo-checker
             architecture); BEHAVIOURAL THRESHOLDS remain
             Founder-controlled — 030 §8 values presented
             for approval, NOT ratified. PENDING FOUNDER:
             Sumsub form/account; threshold ruling. PENDING
             FABLE: privacy policy + DPIA drafts. Codex
             activation-audit release blocker recorded (030
             §6): server-wide RLS/RPC enforcement audit
             required before production enforcement.
             DEV-SIGNUP CHECK ANSWERED (Codex, 2026-08-30,
             accepted): dev signup completes VISUALLY via a
             local verified state despite the unavailable
             provider adapter, and devPreview deliberately
             skips both profile-creation calls — no new
             Supabase auth/profile test account is minted
             (pre-existing preview behaviour, not an IDV
             regression); seeded-account switching remains;
             8/8 focused tests. PRACTICAL CONSEQUENCE:
             visual flows + seeded accounts cover Founder
             testing in the interim; creating NEW real test
             accounts waits for Phase B (provider live).
             Original brief: MESSAGES/029 (phased: A now;
             B on keys; C on Vision). Plan history:
             explicit-consent screen (DR-ZYRA-220 in-house
             wording by Fable), Sumsub Flutter SDK
             bank-style ID+face flow, verification gates per
             the ruled matrix, SafeSearch photo pipeline +
             review queue + report mechanism. Fable also
             drafts privacy policy + DPIA for Founder
             sign-off alongside.
             CURRENT OUTREACH UPDATE 2026-09-13 — Founder prefers
             Stripe for a small launch, with Sumsub a possible later
             option; this is not provider activation or clearance of
             eligibility, duplicate-review, privacy or spending gates.
             Codex prepared and read-back verified one Gmail draft:
             From admin@zyraconnect.app;
             To shefat.fatma@growth.stripe.com (existing Stripe UKI
             Growth contact); subject "ZYRA — Stripe Identity
             eligibility and launch setup"; no CC/BCC, attachments
             or links. Draft ID r-6221284074265540589;
             message/thread ID 1a09a5c49f8230e4. Questions cover
             matrimonial-use eligibility, duplicate API/manual review,
             charge/retry bounds, and data-processing/retention terms.
             FOUNDER HOLD: do not send. Founder wants to avoid further
             external disclosure of the business name before securing
             the company name; this records his stated concern, not
             an independent company-name or trade-mark status check.
             He has seen the draft and will send it himself when ready.
             Gmail recheck: retained as DRAFT, unchanged and unsent.
             Owner: Founder (manual send/readiness); Codex (record).
             Release: Founder manually sends, or issues a fresh exact
             instruction to send the then-reviewed draft. "Soon" is
             not a deadline or authority to auto-send or schedule a send.
             No alias/account, provider, app, database or pricing change;
             no new OA identifier. Existing OA-ZYRA-266 remains OPEN.
             PUBLIC-WEBSITE FOLLOW-UP 2026-09-20 — once mandatory identity
             verification is genuinely provider-backed, enforced before app
             use and post-verified, add prominent evidence-backed website copy
             explaining that ZYRA members are verified before they can use the
             member experience. Do not publish an absolute verification claim
             while the provider, enforcement fuse, exceptions, terminology or
             legal wording remain unresolved. The final website statement must
             match the implemented capability and approved disclaimer exactly.
             True pre-state and verification receipt: task-local
             reviews/idv-2026/oa266-stripe-hold-prestate.VE6QA3/ and
             reviews/idv-2026/OA_ZYRA_266_STRIPE_OUTREACH_HOLD_2026-09-13.md
             under /Users/shakeelahmad/Documents/Codex/2026-08-29/
             supabase-plugin-supabase-openai-curated-remote-3/.
Target:      Fable definition brief (scope/provider/legal
             gates) -> Founder decisions -> solicitor
             confirmation for biometric path -> Codex build
             OA(s)

------------------------------------------------------------

OA-ZYRA-268
Title:       Bundle ID unification — app.zyraconnect.zyra
             on iOS + Android (Codex)
Status:      Open — CODE COMPLETE (Codex handover 017,
             hash relayed by Founder and MATCHED) and
             FABLE-VERIFIED on disk 2026-08-29. Remaining
             scope = EXTERNAL provider remainder only, kept
             open as a measured gate per 017 §9 (never
             closed by inference). VERIFICATION: 11/11 live-
             file hashes match; legacy com/example/app
             MainActivity removed; identifiers confirmed
             independently (iOS Runner 3 configs + tests,
             Android namespace/applicationId, Kotlin
             package, both app-icon MethodChannel ends =
             app.zyraconnect.zyra); migrations dir unchanged
             (204, newest = staged 20260825 pause machine);
             zero .entitlements files — no Apple capability/
             signing work, boundary held; 616/616 tests,
             both platforms debug+release builds, simulator
             launch per 017. ONE PRECISION CORRECTION to
             017 §7: the independent sweep found TWO
             additional legacy hits beyond the declared
             pair — macos/Runner.xcodeproj/project.pbxproj
             (com.example.app.RunnerTests x3, dormant macOS
             TEST bundle) and linux/CMakeLists.txt
             (com.example.app, dormant Linux target). Same
             category as the declared macOS xcconfig
             (scaffold defaults in non-shipping desktop
             targets, outside DR-218 iOS+Android scope) —
             no boundary crossed, sweep statement
             incomplete. Codex to fold desktop-target
             cleanup into any future desktop-platform OA.
             EXTERNAL REMAINDER PROGRESS 2026-08-29 (Fable
             drove browser, Founder performed all sign-ins/
             2FA): (1) DONE — Google iOS client REBOUND IN
             PLACE (bundle -> app.zyraconnect.zyra, Team ->
             9Y7Z8F36SJ; client ID UNCHANGED, so no Codex
             three-location pairing update is needed);
             Android client CREATED ("ZYRA Android", package
             app.zyraconnect.zyra, Codex-measured SHA-1),
             client ID 734578322486-1o7jvjl39cnhaqm30akdn9kg
             8ph89kgs.apps.googleusercontent.com. Google
             warns settings may take 5 min - few hours to
             propagate. (2) NOT NEEDED (client ID kept).
             (3) DONE — Supabase Google allow-list saved and
             re-verified as web,iOS,Android (3 IDs, order
             preserved; a mid-string paste error was caught
             by pre-save verification and corrected). REAL
             Google login measurement still owed (Codex,
             after propagation). (4)
             Apple remainder belongs to Runbook Phase 2
             under Team 9Y7Z8F36SJ (App ID, Sign in with
             Apple, entitlements, signing team, Supabase
             Apple client, real Apple login). ANDROID
             RELEASE SIGNING: release currently uses the
             debug key deliberately; production keystore +
             its own Google OAuth registration = pre-release
             gate. CROSS-REF: Supabase provider allow-lists
             and linking behaviour interact with OA-ZYRA-273
             (single-account policy) — settle 273 before any
             Sign-In ships. HISTORY — Founder ruled
             2026-08-29 (DR-ZYRA-218):
             canonical identifier app.zyraconnect.zyra,
             unified on both platforms BEFORE App Store
             Connect / App ID creation (identifier is
             permanent once a store record exists). Current
             state to replace: iOS Runner
             com.shakeelahmed.zyraapp; iOS tests
             com.zyra.app.RunnerTests; Android
             applicationId/namespace com.zyra.app. Codex
             implements and verifies ALL dependent
             configuration: Xcode build configs (Runner +
             RunnerTests -> app.zyraconnect.zyra.RunnerTests),
             Info.plist, entitlements/URL schemes, Android
             gradle applicationId + namespace + manifest +
             Kotlin package path, repo-wide grep for old
             identifiers, OAuth/deep-link callback schemes
             (Supabase/Google Sign-In) still functional,
             debug + release builds compile and run on both
             platforms (fresh install; old dev installs
             appear as a separate app — expected, dev-only).
             Handover message back with evidence on
             completion; Fable verifies. No store records,
             no signing beyond the identifier, no git
             (Founder runs git).
Evidence:    DR-ZYRA-218; Founder decision message
             2026-08-29; ZYRA_APP_STORE_RUNBOOK_CURRENT_
             VERSION_V1.md Phase 2 pre-check; brief
             015_FABLE-CODEX_2026-08-29_BUNDLE_ID_
             UNIFICATION_GO.md
Target:      DONE: implementation, handover 017, Fable
             verification (018). OPEN: Google credential
             registration (Founder-guided) -> Codex pairing
             + Supabase allow-list -> real Google login
             measured; Apple remainder via Runbook Phase 2.
             Close only when real Google AND Apple logins
             are measured on the canonical identifiers.

------------------------------------------------------------

OA-ZYRA-270
Title:       Member fonts — bundle vs runtime retrieval
             decision before release (Personalisation)
Status:      OPEN — Founder directly selected fixed Poppins app reading text
             and a separate Syne ZYRA wordmark on 2026-10-01. Codex pruned
             the member font picker, ignored/cleared legacy account-local
             font choices, and bundled the existing Syne face for offline
             first paint. Poppins was already bundled. Seven focused suites
             passed 59/59 and scoped analysis was clean. The previous
             pre-release choice among bundling all seventeen member fonts,
             pruning the list or accepting runtime retrieval is resolved
             in favour of pruning; protected/retired comparison code remains
             historical only. Current main-app phone installation and
             Founder physical acceptance are tracked in the new Style
             Default §12 receipt; keep OA open until that acceptance.
Evidence:    MESSAGES/013 §7.1; ZYRA_STYLE_DEFAULT_
             HANDOVER_CURRENT_VERSION_V1.md §§11–12;
             ZYRA_POPPINS_SYNE_FONT_LOCK_LOCAL_DELIVERY_2026-10-01_VERIFICATION.json
Target:      Founder physical acceptance of fixed Poppins/Syne presentation

------------------------------------------------------------

OA-ZYRA-272
Title:       Apple Developer membership auto-renew — add a
             payment card before 2027-08 renewal
Status:      Open — Apple banner on developer.apple.com/
             account 2026-08-29: "There's no credit/debit
             card on the Apple Online Store associated with
             your Apple Account to auto-renew your
             membership." Membership (Team 9Y7Z8F36SJ,
             activated 2026-08-29, Order W1578479196) lapses
             at renewal without a card or manual payment;
             lapse pulls live apps from the App Store.
             NUANCE (mailbox, 2026-08-29): Apple ALSO sent
             "You've enabled automatic renewal" the same
             morning — so auto-renew is ON at the membership
             level while the Apple Online Store holds no
             card. Reconcile when adding the card: the
             renewal will fail without a stored payment
             method despite the toggle. FOUNDER-ONLY
             (payment). No urgency this year; must not
             still be open by 2027-07.
Evidence:    developer.apple.com/account banner 2026-08-29;
             OA-ZYRA-267 (closed)
Target:      Founder adds card (or diarises manual renewal)
             -> close. Suggested check at Runbook Phase 6
             submission at the latest

------------------------------------------------------------

OA-ZYRA-275
Title:       Google OAuth consent screen — Testing mode ->
             Production before launch
Status:      Open — pre-release gate. Google Cloud shows the
             ZYRA App consent screen in TESTING mode:
             "OAuth access is restricted to the test users
             listed on your OAuth consent screen" (surfaced
             during Android client creation 2026-08-29).
             Until published to Production, only listed test
             users can complete Google sign-in. Publishing
             may trigger Google verification review
             (branding/scopes). Founder-guided action at
             TestFlight-external/launch time.
Evidence:    Google Cloud console banner 2026-08-29;
             OA-ZYRA-268 external remainder
Target:      Publish consent screen to Production (+ any
             verification) before public release; until
             then keep testers on the test-user list

------------------------------------------------------------

OA-ZYRA-276
Title:       Supabase plan/quota — "Grace period is over"
             banner on the production project
Status:      Open — infrastructure risk. The Supabase
             dashboard for the ZYRA project (org ZYRA-APP-
             LAB, FREE plan) showed 2026-08-29: "Grace
             period is over — Your projects will not be able
             to serve requests when you use up your quota."
             A quota stop would take auth/data down for any
             real device testing or TestFlight wave. Founder
             decision: upgrade plan (or confirm quota
             headroom) BEFORE inviting external testers.
             Sequencing note: sits beside OA-ZYRA-258 money
             plumbing; no change made today.
             QUOTA HEADROOM MEASURED 2026-09-24 by Fable,
             on the Founder's instruction, reading the live
             usage page in his browser. Billing cycle
             18 Sep - 18 Oct 2026, Free plan, one project:
               Storage        0.384 / 1 GB      38%
               Database       0.041 / 0.5 GB     8%
               Egress         0.001 / 5 GB      <1%
               Monthly users  3 / 50,000        <1%
               Edge functions, Realtime messages,
               Realtime connections, cached egress: all ZERO
             NOTHING IS NEAR A LIMIT AND NOTHING IS IN
             OVERAGE. The banner is not a warning about this
             account. Supabase ended the grace period for
             every Free-plan organisation on 2026-08-17 and
             shows the same notice to all of them. The risk
             recorded on 2026-08-29 was real as a question
             and is now answered by measurement.
             WHAT IS ACTUALLY WORTH WATCHING, AND IT IS NOT
             THE BANNER: STORAGE. It is the only metric with
             meaningful consumption, and its daily chart
             shows it climbing across the period. It holds
             member photographs, so it grows with every
             profile - and it stands at 38% of the free
             allowance on THREE monthly active users. Every
             other metric would take tens of thousands of
             users to trouble. Storage will not.
             This reframes the action. The question was
             never "will a quota stop happen before
             TestFlight" - at three users, no. It is "what
             does storage do at two hundred users", and that
             is an arithmetic question the Founder can
             answer before he needs to, rather than an
             infrastructure emergency.
             DATABASE SIZE, for the record: 38.87 MB.
Evidence:    Supabase dashboard banner observed 2026-08-29
             during OA-ZYRA-268 allow-list work. Full usage
             page read 2026-09-24 (org pdekarsldtaqlqdthgwh,
             project sxoaxonzjqkgajmlagyk); figures above.
Target:      Quota headroom confirmed 2026-09-24 -> Founder
             decides whether to upgrade before opening
             testing, knowing storage is the binding
             constraint and not the banner -> close

------------------------------------------------------------

OA-ZYRA-279
Title:       Business Google avatar — Codex design round
             (Founder directive 2026-08-29)
Status:      Open — Codex GO via MESSAGES/025. Fable's first
             pass (static PNG + comet-line animated GIF from
             the 1024 icon) sits in SYSTEM/RESOURCES/BRAND/;
             Founder directed a Codex design round: bring
             the avatar up to ZYRA's modern look, with the
             GOLD made more accurate to the #E8C98A / Gold
             Horizon family (current GIF glow runs too
             white). Options land in the SAME folder;
             constraints: circle-crop safe at 28-40px,
             animated frame 1 must equal the static mark
             (Google freezes animation on many surfaces),
             subtle professional motion, GIF format, brand
             truth only. Upload path already unblocked:
             Workspace profile-editing policy flipped ON
             2026-08-29 (Founder-approved admin change);
             Founder picks the design, Fable performs the
             upload.
Evidence:    Founder directive 2026-08-29 (chat); MESSAGES/
             025; BRAND/ first-pass files
Target:      Codex options + 026 reply -> Founder picks ->
             Fable uploads to the Google account -> close

------------------------------------------------------------

OA-ZYRA-285
Update 2026-10-05 — ISOLATED PREPARATION PASS, NO LIVE CLOSURE:
             Founder-approved local OA305 F04 preparation has private numeric
             authority and ID-only Browse output tested against fake records,
             with8 assertion groups and retained Journey positive gates. The
             artifact deliberately refuses a non-synthetic database. Existing
             Browse/Unlock numeric callers and shared saved-result integration
             require a coordinated cutover; observable ID-order inference,
             full transcripts, retention and risk acceptance remain open.
             Separate F06/F07 candidate passes53 synthetic credit/hold/race
             checks, but is not live and does not create a paid scoring result.
             No ordinary raw-score call, member data or credit was exercised
             against production. Exact production GO remains required. See
             ZYRA_APP_GATE_REPAIRS_HANDOVER_CURRENT_VERSION_V1 and receipt.
Update 2026-09-28 — LOCAL ISOLATION PASS, SERVER/PRIVACY GATES OPEN:
             Stage1 static import/synthetic fixture isolation passes; production
             code does not reach the new harness. This is not an ACL, RLS,
             snapshot, ledger or inference proof. No database/API/catalog query,
             raw production scorer call or real spend occurred. Existing server
             permissions and desired default-off fuse remain unverified here.
             OA193 local-only GO does not authorise this server/security stage;
             all later execution and measured risk/activation gates remain open.
Update 2026-09-28 — OPEN / APPROVED POLICY, NO EXECUTION GO:
             DR-ZYRA-250 settles D1–D6, not this security/evidence work. Private
             internal scorer and purpose-scoped Browse/Standard/Plus/Journey,
             one saved directional result, server-owned default-off Plus gate,
             atomic/idempotent debit/entitlement and different-target balance
             serialization still need implementation/proof under separate GO.
             Measure complete transcripts: Standard baseline plus incremental
             Plus, Browse inclusion/order, preflight/errors/timing, remembered
             old/new projections across policy versions and multiple accounts.
             Original-input-only defect replacement cannot become a refresh
             oracle; absent reproducible originals means unavailable/review.
             Category thresholds/suppression/minimum usefulness, exact retention
             and measured risk acceptance remain Founder decisions. No live
             scorer grants or server fuse reverified here; no spending occurred.
             No new OA is raised for these gates: this action already owns the
             access/inference boundary, alongside OA193's calculation contract.
Title:       Direct score_candidates Access Is a Repeatable Preference-
             Inference Oracle Outside UI Presentation Gates
Category:    Security / Sensitive Inference / Authorization
Priority:    HIGH — block untrusted or external testing until the
             server-owned discovery/scoring boundary is ruled and built;
             Founder-only internal TestFlight may proceed as a controlled
             test with this residual recorded
Status:      Open — discovered during OA-ZYRA-283 live boundary audit
Owner:       Founder / Engineering
Raised:      2026-09-10
Completed:   —
Source:      Live `public.score_candidates(uuid[])` catalog/ACL audit;
             `zyra_discovery_service.dart`

Description: Browse legitimately calls `score_candidates(uuid[])` to exclude
             hard-requirement failures and order visible candidates without
             displaying the number. The function is also directly executable
             by `authenticated`, however, and returns the numeric caller-
             perspective score for each profile that
             `zyra_can_view_profile()` permits. A crafted Data API caller can
             bypass the UI's non-display rule, query one candidate repeatedly
             while changing their own preference matrix, and use score changes
             to infer sensitive facts about that candidate. The same raw call
             also bypasses when the Compatibility Reveal and paid Unlock
             surfaces choose to present the caller-owned score. OA-ZYRA-283
             closes the shared-row counterpart-score and consent-write defect;
             it cannot honestly close this broader scoring oracle without
             redesigning Browse's server boundary.

Target:      Replace public raw scoring with server-owned purpose-specific
             paths: a Browse projection that performs exclusion/order without
             returning per-candidate scores, and entitlement/stage-scoped
             score paths for Profile Unlock and Journey. The internal scorer
             must not be directly executable by client roles. Preserve the
             ratified OA-ZYRA-193 scoring method, hard-requirement exclusion,
             null/no-score semantics and current Browse order. Threat-model
             repeated preference mutation and direct RPC calls; prove PUBLIC,
             anon and authenticated ACLs plus positive Browse/Unlock/Journey
             cases. Separate design/build scope and Founder apply GO required.
Dependencies: OA-ZYRA-193; OA-ZYRA-283; `zyra_can_view_profile`;
             ZYRA_CONTRADICTION_AUDIT sensitive-inference precedent.

------------------------------------------------------------

OA-ZYRA-287
Title:       My ZYRA — Supportive Language first-view candidate
Category:    Feature
Priority:    High
Status:      Awaiting Review — candidate implemented locally;
             Founder visual review and acceptance pending.
Owner:       Codex (implementation, evidence and reconciliation);
             Founder (visual decisions and acceptance)
Dependencies: OA-ZYRA-257 (existing visual-baseline debt only)
Decision:    Founder direct instruction, 2026-09-14; attached
             MY ZYRA FIRST-VIEW BUILD: OPTION 4 SUPPORTIVE LANGUAGE.
Automation:  Manual
Description: Seeker-only reversible first-view candidate in the existing
             Dashboard developer controls. Now uses What Needs You / Where
             You Stand / What Changed / From ZYRA; Insights uses What's
             Working / What Keeps Happening / What You've Learned / What
             May Help. Fifteen scenarios and grouped per-content options;
             current-view rollback retained. New candidate and examples
             require non-release plus existing developer authority; no
             fixture enters a release user interface. Existing-source mode
             uses the current resolver; Insights/editorial/billing examples
             remain mock-only. No database, migration, matching, billing,
             Guardian Dashboard, approved-pixel or TestFlight change.

             REVIEW BOUNDARY: the new presentation is not product acceptance
             or authorisation to activate real Insight families. Exact-item
             navigation remains a disclosed gap: current-source cards use
             canonical owner-tab callbacks; sample cards open a labelled
             local destination preview, never a live request or Journey.
             Missing billing/editorial/reflection/Insight sources are not
             implemented by this visual instruction. No construction OA is
             raised for those explicitly excluded future capabilities; this
             action tracks review of their design examples only. Historic
             OA-ZYRA-281 remains closed; this is a new first-view programme.

             Evidence: ZYRA_MY_ZYRA_SUPPORTIVE_FIRST_VIEW_HANDOVER_CURRENT_
             VERSION_V1.md contains true pre-states, file hashes, routing
             limits, named verification results and the frozen-clock
             candidate manifest. All 72 candidate captures remain
             approved:false. Existing full-suite Dashboard golden mismatches
             remain OA-ZYRA-257; no approved pixels regenerated or promoted.
Target:      Founder opens the Supportive first view, reviews every scenario
             and returns changes/acceptance. Only a later explicit acceptance
             can promote candidates or replace the current production view.

------------------------------------------------------------

OA-ZYRA-292
Title:       Guardian Notes and Reciprocal Journey-Access Transparency
Category:    Product Design / Privacy / Guardian Relationships
Priority:    Medium
Status:      HELD — design and authority contract required; no implementation
Owner:       Founder (product ruling); Codex (future design/security review)
Dependencies: DR-ZYRA-233 · DR-ZYRA-232 · OA-ZYRA-291
Decision:    Guardian comments must not become couple-chat messages. Design a
             separate auditable Guardian Notes boundary and a truthful surface
             showing each Seeker which authorised Guardians can access their
             shared Journey.
Automation:  Manual
Description: Specify note authorship, readers, editing/deletion, retention,
             reporting, notifications and revocation; specify the reciprocal
             access list without leaking unrelated family data. No code,
             migration, UI or policy change is authorised under this action.
Target:      Founder-approved design and security contract before build.
Evidence:    Created from the accepted DR-ZYRA-233 recommendation so these
             privacy/legal questions cannot be mistaken for completed scope.

------------------------------------------------------------

OA-ZYRA-293
Title:       Seeker Basic Authoritative Quotas and Live Advertising
Category:    Membership / Security / Advertising / Privacy
Priority:    High before commercial activation
Status:      OPEN — waiting for the Founder's GO to change production (built locally; server change staged). REOPENED 2026-10-03 — DR-ZYRA-252 restores Basic client policy;
             authoritative quotas/receipts and live advertising remain held
Current scope:
             Verify the restored Basic limits and preserve safe over-cap data.
             Reconcile server quotas/role access with the £4.99 joining product
             before launch. Live adverts require separate provider/privacy/
             consent approvals. No production migration or activation is
             authorized by the client-restoration request. The retired text
             below remains historical evidence, not current instruction.
Current client evidence — 2026-10-03:
             Basic capacities/presentation are restored and internally tested.
             No authoritative quota, receipt or live advertising activation
             occurred. DR-ZYRA-252 / Paid Membership handover §11 /
             ONBOARDING_BASIC_MEMBERSHIP_CHOICE_2026-10-03_VERIFICATION.json.
Owner:       Codex (future implementation/evidence); Founder (provider,
             commercial and privacy approval)
Dependencies: DR-ZYRA-235 · DR-ZYRA-243 · OA-ZYRA-253
Decision:    Preserve this record as evidence of the retired Basic proposal.
             Do not promote its quota or advertising work to production.
Automation:  Manual
Description: The retired proposal would have required atomic server-side
             quota checks and a separately approved advertising provider.
             Neither is now to be built or activated. Do not treat existing
             SharedPreferences, preview adverts, Basic enums or developer
             fixtures as a commercial product or production authority.
Target:      Closed by DR-ZYRA-243. Remove remaining public Basic/ad copy as
             affected surfaces are reconciled; retain only migration-safe
             parsing and clearly isolated developer boundary fixtures.
Evidence:    ZYRA_PRICING_2026-09-24_V5.md;
             JOURNEY_CAPABILITY_GRANT_RULES_2026-09-18_V6.md;
             ZYRA_PAID_MEMBERSHIP_HANDOVER_2026-09-18_V3.md.

------------------------------------------------------------

OA-ZYRA-294
Title:       Optional Main Guardian with Active-Journey Hold
Category:    Feature / Security / Guardian Relationships / Journey Authority
Priority:    High
Status:      OPEN — waiting for the Founder's GO to change production (built locally; server change staged). CLIENT BUILT / DEVICE INSTALLED / MIGRATION STAGED — production
             enforcement awaits isolated replay, review and exact apply GO
Owner:       Codex (implementation/evidence); Founder (production apply and
             visual acceptance)
Dependencies: DR-ZYRA-236 · DR-ZYRA-232 · OA-ZYRA-290 · OA-ZYRA-291
Decision:    Permit deliberate no-Main Guardian state without unlinking;
             surface the missing-Main action in My ZYRA; hold ordinary Active
             Journey participation until both Seekers have Main leadership;
             preserve Pause and End.
Automation:  Manual
Description: Replace Guardian management dialogs/expanding warnings with
             same-footprint Cancel/Confirm pills; add caller-bound demotion;
             project no-Main into Now; add a caller-relative two-side Journey
             gate and server write enforcement over current Journey surfaces.
             Do not auto-promote a replacement and do not expose Guardian
             identity through the gate.
Target:      Founder visually accepts the installed interaction; staged
             migration passes isolated PostgreSQL 17 replay, direct-call and
             write-surface matrix, security review, then receives a separate
             exact-file/hash production GO.
Evidence:    Client focused suite 160/160 PASS; analyzer clean; signed Founder
             profile installed and launched on 2026-09-18. Migration
             `20260918140508_oa294_main_guardian_optional_journey_hold.sql`
             remains staged at SHA-256
             `67683db6045e42e2ae691321b8a35676913c69433392276a07551138dbc8004b`.
             Message 142 carries the file ledger and verification boundary.
             Founder preview management was subsequently completed: Make
             Main, Remove as Main and Remove Guardian confirmations now
             mutate isolated local cards with no auto-promotion. The latest
             Guardian-page/live-truth set passes 17/17; analyzer is clean;
             signed build 1.0.0 (2), executable SHA-256
             `2159caee43bb7a06bc9e839247f2d3118b19919e034b363082ce4aacd6892759`,
             was installed in place and launched on the Founder iPhone.
             The subsequent visual cleanup removed the Main access card,
             reused the Additional disclosure row and neutralised the
             non-destructive Manage actions. The latest focused set passes
             18/18; analyzer is clean; internal-Founder executable SHA-256
             `3bccd098a58e0b0738443051fb83c93b6b15d55e6e3f4fccf2afb807b5bf73a6`
             was installed in place with the existing app data preserved.

------------------------------------------------------------

OA-ZYRA-295
Title:       Known-Person Matching by Permanent ZYRA Code
Category:    Feature / Matching / Privacy / Security
Priority:    High
Status:      OPEN — waiting for the Founder's GO to change production (built locally; server change staged). CLIENT BUILT / MIGRATION STAGED — production remains unchanged
Owner:       Codex (implementation/evidence); Founder (production apply and
             visual acceptance)
Dependencies: DR-ZYRA-237 · DR-ZYRA-231 · DR-ZYRA-221 · DR-ZYRA-123 ·
              OA-ZYRA-289 · OA-ZYRA-293
Decision:    Add a Seeker-only ZYRA Code route to Browse action mode. Safe
             preview may lead to an ordinary Consider; a Match remains mutual.
Automation:  Manual
Description: Add the fifth action-bar destination; scan/enter, neutral lookup,
             Browse-level confirmation and Consider result states; add separate
             hardened preview/mutation RPCs rather than widening Guardian-link
             APIs. Reuse the permanent-code attempt budget and recheck IDV,
             visibility, matching, block, onboarding, gender and Guardian-
             conflict boundaries at write time.
Target:      Founder visually accepts the installed preview. The staged
             migration passes isolated PostgreSQL 17 replay, direct-call and
             mutation/reciprocity tests, security review, then receives a
             separate exact-file/hash production GO. If any usage-limited
             membership remains available at launch, OA-ZYRA-293's server-
             authoritative quota must close before this direct mutation RPC
             can apply; the client must never be the quota authority.
Evidence:    Migration
             `20260918145126_oa295_known_person_code_matching.sql` remains
             staged. Focused Flutter/static tests and analyzer are recorded in
             Message 143; production history has not been changed.

------------------------------------------------------------

OA-ZYRA-296
Title:       Separate Additional-Guardian View and Chat Authority
Category:    Feature / Security / Guardian Relationships / Membership
Priority:    High before Guardian One commercial activation
Status:      OPEN — waiting for the Founder's GO to change production (built locally; server change staged). CLIENT + FORWARD SERVER CONTRACT BUILT / LOCALLY VERIFIED —
             production migration and enforcement not authorised
Owner:       Codex (future implementation/evidence); Founder (production
             migration approval and visual acceptance)
Dependencies: DR-ZYRA-238 · DR-ZYRA-232 · DR-ZYRA-234 · OA-ZYRA-253 ·
              OA-ZYRA-290
Decision:    Additional Guardian View and Chat are separate Seeker-owned
             per-active-Journey permissions, both ON by default; Chat requires
             View. Main View and Chat are always ON while the person is Main.
Automation:  Manual
Description: Replay the now-staged separate View/Chat state, server-confirmed
             read/write RPC and message-write RLS. Turning View off atomically
             revokes Chat. No Basic tier exists; Guardian paid access remains
             separate from link/Journey authority. Preserve Main access,
             Main-only decisions, reciprocal privacy, blocks and EMPTY !=
             FAILED. Complete legal/privacy review before activation.
Target:      Founder approves the authority contract; a generated migration
             passes isolated PostgreSQL replay, direct-call/RLS/advisor tests
             and exact-file/hash review; production apply receives a separate
             explicit GO. Client then replaces preview-only Chat state with
             server-confirmed state.
Evidence:    Guardian page preview now uses separate View and Chat switches,
             View-off disables Chat, Main renders both as Required, membership
             and Help copy disclose eligibility rather than guaranteed access,
             and the scroll viewport now fades into the pager with bottom
             clearance instead of exposing a hard clipped purple seam. The
             latest 16/16 focused Guardian-page/live-truth tests pass and
             analyzer is clean. Signed
             profile build 1.0.0 (2), executable SHA-256
             `7991954d588dd5e0b53bd0aca0fc9dca68a731103f50f35bde3d0461233b399b`,
             was installed and launched on the Founder iPhone. No migration or
             production database change was made by this implementation.
             The subsequent Guardian visual cleanup uses the same collapsible
             Active Journey access row for Main and Additional cards, removes
             the translucent Main access block and retains the Required
             authority labels. The latest focused set passes 18/18 and the
             analyzer remains clean.
             2026-09-24: the canonical client service now reads and confirms
             both live View and Chat state; a forward contract migration
             defaults both ON for Additional Guardians, forces Main ON and
             adds Guardian message-write RLS only where Chat is enabled.
             The forward migration is
             `20260924100231_founder_paid_only_returns_guardian_circle_contract.sql`
             at SHA-256
             `f6af8a28e1b0ce319a8daaa39ff22fc30574bd6c9d47f70a5de8cfec49374006`.
             Focused Guardian truth tests and analyzer pass. PostgreSQL replay
             remains pending; production is unchanged.

------------------------------------------------------------

OA-ZYRA-297
Title:       Complete Production Reliability, Crash Diagnostics and Founder
             Health Reporting
Category:    Reliability / Privacy / Operations / Observability
Priority:    High before public launch
Status:      Open — bounded local technical fingerprints, Founder session
             health and live-local AIOS reporting exist; production aggregate
             ingestion, remote crash provider, service health feed and
             scheduler activation remain held
Owner:       Codex (technical design/implementation); Founder (provider,
             privacy, cost and activation decisions)
Dependencies: DR-ZYRA-239 · OA-ZYRA-169 · OA-ZYRA-256
Decision:    Complete ZYRA reliability evidence without screenshots, replay,
             user content, email/IP retention or automatic production change.
Automation:  Manual until separately activated through the existing daily
             Founder operation; no duplicate schedule
Description: Phase 2 now captures only four fixed technical categories in
             bounded current-process memory and exposes their counts to the
             Founder. It sends no diagnostics remotely and stores no raw
             exception, stack, route or member data. Next evaluate Apple
             diagnostics and a strictly scrubbed EU-region
             error provider; define technical error fingerprints that contain
             no member payload; ingest supported Supabase service-health
             signals; connect the now-built AIOS Health & Usage surface to an
             approved aggregate feed; and permit agents to detect, classify
             and prepare tested repairs.
             Agents must never deploy, apply migrations, release or approve
             fixes automatically. Resolve OA-ZYRA-169 silent catches through
             explicit typed outcomes or approved diagnostics, not raw logs.
Target:      Founder-approved provider/cost/privacy choice; data-processing,
             retention/deletion and access controls; implementation and test
             evidence; then a separate activation GO for the existing daily
             report. Keep production collection off until all gates pass.
Evidence:    ZYRA_PRODUCT_OBSERVABILITY_CURRENT_VERSION_V1.md;
             `SOURCE/lib/services/zyra_reliability_monitor.dart`;
             AIOS `zyra_observability_engine.py`, `/zyra-health` and
             `/api/zyra-health`; AIOS observability/dashboard checks 12/12
             PASS; local live verification PASS with collection off;
             BLACK UMBRELLA GROUP/SYSTEM/RESOURCES/REPORTS/
             AIOS_ZYRA_HEALTH_USAGE_PHASE1_2026-09-18_V1.md;
             current app has no remote crash reporter or diagnostics provider;
             focused Phase 2 checks 22/22 PASS; analyzer clean; Apple and
             Supabase first-party signals researched 2026-09-18.
             WEBSITE-CAPTURE FINDING 2026-09-18: current synthetic Active
             Journey with photos: [] throws StateError via
             SeekerProfile.photoUrl (seeker_profile.dart:79), consumed
             by _ActiveJourneyCard (connections_screen.dart:4562).
             Reproduction/provenance is retained in the website handover
             and app-captures/notes.md. Review under this reliability
             action; no app repair or wider app testing was performed by
             the bounded website work. Public preview uses valid
             Potential/Paused fixtures, never a suppressed exception.

------------------------------------------------------------

OA-ZYRA-298
Title:       Complete and Activate Shared Guardian Circle Messaging
Category:    Feature / Messaging / Privacy / Guardian Relationships
Priority:    High before paid family messaging is advertised
Status:      OPEN — waiting for the Founder's GO to change production (built locally; server change staged). CLIENT PREVIEW BUILT / RETENTION + PAID-PARTICIPANT CONTRACT
             STAGED — production unchanged
Update 2026-10-13 (clear discussion and bounded Past action):
             Family Messaging section11 / Navigation Haptics section82 add
             clearer Now discussing cards and an explicitly supplied date-only
             Past summary. Same Circle/draft retained; no inferred profile,
             archived messages or real history grant. Current/Past resolver
             separation, exact identity/date, Basic/readiness, foreground,
             terminal withdrawal and white-theme checks pass locally.
             Real topic delivery/persistence and authorized Past projection
             remain held here. Native delivery is not measured for this delta;
             Founder away, build/space holds remain OA305/286. No closure.
Owner:       Codex (implementation/evidence); Founder (production apply and
             visual acceptance)
Dependencies: DR-ZYRA-242 · DR-ZYRA-238 · OA-ZYRA-296
Decision:    Build one canonical text-only shared Guardian Circle per Seeker,
             containing the Seeker and every active linked Guardian, with no
             private one-to-one Guardian conversation.
Automation:  Manual
Description: Complete isolated PostgreSQL replay, RLS/direct-call role matrix,
             membership-epoch and pre-join-history denial tests, link/block/
             relink transitions, concurrency/rate tests, retention/deletion,
             report evidence review, Realtime/private-channel review and
             unread notification design. Preserve Journey-chat separation.
             Do not activate from client state.
Target:      Founder visually accepts the preview; reviewed migration receives
             an exact-file/hash production GO; post-apply verification passes;
             only then enable the client release gate.
Evidence:    Founder corrected the former pair interpretation on 2026-09-20.
             Client service, shared Circle surface and relationship routes are
             staged. The Seeker has one Guardian Circle entry; each Guardian
             enters the selected Seeker's Circle. Sender attribution and
             per-message reporting are present. Focused Circle/Guardian/
             Browser suite passed 34/34 and analyzer is clean.
             Migration
             `20260919185927_oa298_family_messaging_foundation.sql` remains
             unapplied at SHA-256
             `893f621b79f6956a5a4f50e957767c924957dd042b9f5c6ed70e8a31f489c073`.
             The superseded pair artifact was never applied. Client release
             gate remains false; production is unchanged.
             DR-ZYRA-248 now resolves the open contract: every current Circle
             participant needs their own paid role entitlement; removal closes
             access immediately; relink starts a fresh readable epoch;
             deleted-sender messages retain a neutral label for 12 months;
             protected reported-message evidence plus bounded context retains
             for 24 months after case closure unless legal/safety hold extends
             it. These rules are staged in the 2026-09-24 forward migration
             `20260924100231_founder_paid_only_returns_guardian_circle_contract.sql`
             at SHA-256
             `f6af8a28e1b0ce319a8daaa39ff22fc30574bd6c9d47f70a5de8cfec49374006`.
             Static contract tests pass; PostgreSQL replay remains pending.

------------------------------------------------------------

OA-ZYRA-299
Title:       Complete Journey Return Authority and Ended-Attempt Safety
Category:    Feature / Journey / Membership / Security
Priority:    High
Status:      OPEN — waiting for the Founder's GO to change production (built locally; server change staged). PRODUCT RULES RESOLVED / CLIENT + FORWARD SERVER CONTRACT STAGED
             — Ended execution and production migration remain held
Owner:       Codex (implementation/evidence); Founder (production apply and
             visual acceptance)
Dependencies: DR-ZYRA-241 · DR-ZYRA-244 · DR-ZYRA-227 · OA-ZYRA-156
Decision:    Keep Active/Potential/Paused/Ended separate and expired history
             in Profile. Paid initiation is limited to each member's five most
             recent Paused and five most recent Ended rows, with no age limit.
             Requests expire in 30 days; decline creates a 30-day cooldown;
             withdrawal has none. Incoming requests remain visible. Both
             people must be below the three-Active cap before send/accept.
             Paused resumes the same record; Ended creates a fresh attempt.
Automation:  Manual
Description: Complete isolated replay, direct-call/RLS/concurrency tests and
             OA-ZYRA-156 attempt ownership. Prove incoming pinning, sender
             withdrawal, recipient-unavailable closure without billing-detail
             leakage, permanent no-future-request, and three-cap races. Keep
             Ended RPC execution revoked until the fresh-attempt ritual audit
             passes. Preserve block/safety exclusions.
Target:      Exact reviewed migrations pass isolated replay, direct-call/RLS
             and concurrency tests, then receive separate production GOs.
Evidence:    Connections again uses separate Active, Potential, Paused and
             Ended sections. Profile now owns a Past Journeys Paused/Ended
             selector. Incoming Paused requests have their own Requests for
             you subsection. Migration
             `20260919191016_oa299_journey_return_initiation_gate.sql` remains
             unapplied at SHA-256
             `0ff28ae7c6d98da43b1b6d608c93c9dfb2039b4bde0c28ad5a78e63d58111460`.
             Existing Request New Journey client/server holds remain intact.
             DR-ZYRA-248 resolved the limits on 2026-09-24. Client age copy was
             removed; a privacy-preserving Available / Not currently available
             lookup and the staged 30-day/five-recent/cap authority now live in
             `20260924100231_founder_paid_only_returns_guardian_circle_contract.sql`.
             Its SHA-256 is
             `f6af8a28e1b0ce319a8daaa39ff22fc30574bd6c9d47f70a5de8cfec49374006`.
             Focused contract tests and analyzer pass. PostgreSQL replay
             remains pending; production unchanged.

------------------------------------------------------------

OA-ZYRA-300
Title:       Add the Founding Imam Ahad Quotation to the Public Website
Category:    Website / Brand / Editorial
Priority:    Medium before public launch
Status:      OPEN — exact quotation, source and publication wording pending;
             nothing published by this action
Owner:       Founder (exact quote/source and final acceptance); Codex
             (website implementation and evidence)
Dependencies: Public website current version and Founder-supplied source
Decision:    Present the Imam Ahad quotation that informed ZYRA's purpose as
             a deliberate trust-and-purpose moment on the public website.
Automation:  Manual
Description: Obtain and preserve the exact approved quotation, speaker name,
             original source/context, attribution format and any required
             publication permission. Design it into the website's narrative
             without implying endorsement beyond the verified source and
             without altering the quotation. Check responsive layout,
             accessibility and reduced-motion presentation.
Target:      Founder confirms the exact quote and source; Codex prepares the
             final website placement; Founder visually accepts the live copy.
Evidence:    Founder direction in Codex task, 2026-09-20. Repository search
             found no governed copy of the quotation, so no wording was
             invented or published.

------------------------------------------------------------

OA-ZYRA-301
Title:       Set Up ZYRA's Marketing Channels — Facebook, Instagram, TikTok
             and Any Other Channel Worth Having
Category:    Marketing / Brand / Accounts
Priority:    Medium now, High as the launch date approaches. Nothing here
             blocks the app being built. All of it blocks the app being
             found.
Status:      IN PROGRESS — Marketing Command Centre V4 implemented and
             internally verified 2026-10-04. The non-secret nine-platform
             account register, master-idea variants and 1–3-idea calendar are
             live locally. Real handles/security facts still require Founder
             reconciliation; no external connection or public post is
             recorded or authorised.
Owner:       Founder (handles, human-only account/credential steps and every
             public approval) · Codex (main operator: research, planning,
             content, administration, security/compliance coordination,
             records, app and website integration) · ChatGPT (bounded support
             only when engaged)
Raised:      2026-09-23
Raised by:   Founder, 2026-09-23: "also add to oa for us to make facebook,
             instagram, tiktko and any other amerketing to get zyra marteked"
Initiative:  INI-002 / ZYRA
Authority:   AD-AIOS-111 (Codex full operating control; Founder sole approval)

CURRENT IMPLEMENTATION UPDATE 2026-10-04
             Founder GO: "ok do those", following Codex's inspection and
             recommendation to build the social control centre, master-idea
             variant model and calendar without connecting live accounts.
             ZYRA Marketing System V4 now adds:
               - nine non-secret account rows for Facebook, Instagram,
                 Threads, TikTok, YouTube, X, Pinterest, Reddit and Snapchat;
               - owner, public profile, login-identity label, business status,
                 MFA, passkey, recovery, delegated-access and integration state;
               - explicit rejection of password, token, recovery-code and API-
                 key fields;
               - master ideas with linked platform variants;
               - a Europe/London calendar capped at three distinct ideas per
                 day while permitting reused platform variants;
               - exact approval identity expanded to destination account,
                 schedule, media reference and optional media SHA-256;
               - fail-closed live connection, automated publishing and public-
                 reply policy with no corresponding execution route.
             Eleven engine tests and four AIOS bridge tests pass; Python
             compilation passes. No social account, scheduler, credential,
             payment or publishing API was connected. The running AIOS process
             still holds its earlier bridge module until its next authorised
             restart; static interface assets are already on disk.

PREVIOUS IMPLEMENTATION UPDATE 2026-09-25
             The ZYRA Marketing System V3 was current at that date. AIOS exposed the
             Founder-only Marketing Command Centre at `/marketing/`, backed by
             the governed ZYRA workflow and one atomic state store. It contains
             the eight-role team, content pipeline, research, exact-preview
             approval, manual publishing packs, community escalation,
             analytics and a `COLLECT_ONLY` Inspiration inbox. Saved-video
             URLs are retained in order; identical URLs are marked as repeats;
             no video is fetched, analysed or implemented during collection.
             Eight workflow tests, three bridge tests and live HTTP/UI probes
             passed. No social, model, advertising, payment or publishing API
             is connected.

WHAT THIS COVERS
             The named three, plus the channels that usually matter for an
             app like this one. Written out so the list is a decision and not
             an assumption:
               Facebook      — page, not a personal profile
               Instagram     — the main visual channel for this audience
               TikTok        — the main reach channel for this audience
               YouTube       — for longer explanation, and it is where
                               search sends people who want to understand
                               what an app actually does
               X / Twitter   — low effort to hold the name, low priority to
                               use
               LinkedIn      — for the business, not the product
               WhatsApp      — a business account, because a large part of
                               this audience will want to message rather
                               than fill in a form
               Pinterest     — worth a look, not worth assuming
             Whether each one is actually used is the Founder's call. Whether
             the NAME is reserved on each one is a different question and the
             answer is usually yes, early, because names are taken by
             strangers and cannot be bought back cheaply.

WHY THIS IS BEING RAISED NOW RATHER THAN AT LAUNCH
             Two reasons, and neither is impatience.
             First, handles. "zyra" is a short, pronounceable, already-popular
             word. The exact handle is very unlikely to be free everywhere,
             which means the real decision is what the consistent fallback is
             across all channels — and that decision is much cheaper to make
             once, now, than to discover one channel at a time later.
             Second, the app store listings and the website will both want to
             link to these, and the links have to exist before the listing is
             written.

THE TOONBEE GATE IS REMOVED - CORRECTED 2026-09-24
             As first written on 2026-09-23 this action said nothing could go
             public until OA-ZYRA-235 was resolved. THAT GATE WAS FABLE'S
             MISTAKE AND IT IS NOW LIFTED. The Founder has said what Toonbee
             is: a website for making animated AI videos, which he noted in
             case it helped with advertising. It is a tool he might use, not a
             risk to clear, and it has no bearing on reserving a handle or
             opening an account.
             Fable built the gate from OA-ZYRA-235's forceful wording without
             knowing what the word meant - treating an unknown as a hazard
             because that felt like the careful choice. It was not careful; it
             blocked real work for no reason. Recorded plainly so the register
             shows both the error and its correction.
             THE REAL TASK SURVIVES, as ordinary work rather than a gate: when
             ad creative is being produced, look at Toonbee and decide whether
             it is worth using. See ACTION 7 below.

WHAT THIS MUST NOT DO
             A constraint, from the Founder's own governance: ZYRA is a
             matrimonial product for a faith community. Marketing copy carries a trust and
             modesty standard that ordinary app marketing does not. Nothing in
             this action authorises any wording; every public sentence is the
             Founder's to approve.

ACTIONS
  1. DONE 2026-09-24 — OA-ZYRA-235 answered and closed. Toonbee is a website
     for making animated AI videos. It gates nothing.
  2. OPEN — Codex checks handle availability across the channels listed above
     and reports which exact names are free, so one consistent handle can be
     chosen rather than a different one per channel.
  3. IN PROGRESS — Founder states that the social accounts have been created.
     Exact handle, public URL, login identity, business status, recovery and
     access evidence remain to be reconciled one platform at a time.
  4. IN PROGRESS — Codex implemented the nine-platform non-secret account
     register on 2026-10-04. Its rows intentionally start as
     NEEDS_RECONCILIATION; completing them requires the Founder/account evidence
     and the acceptance controls in OA-AIOS-392 REC-004/014.
  5. OPEN — Codex adds the links, share behaviour and link-preview images on
     the website and in the app, once the handles are fixed.
  6. OPEN — Codex prepares a written plan for what each channel is FOR. A channel with no
     stated purpose becomes a channel nobody posts to, and an abandoned
     account is worse than no account because it looks like an abandoned
     company.
  7. OPEN — evaluate Toonbee when ad creative is being made, carried across
     from OA-ZYRA-235. Whether an AI animated-video tool suits ZYRA is a real
     question and not only a cost one: a matrimonial product for a faith community is judged
     on whether it feels trustworthy and respectful, and generated video can
     read as cheap in a way that damages exactly that. Worth trying, worth
     looking at honestly before it goes out under the ZYRA name.
  8. OPEN — MARKETING PAGES, raised by the Founder 2026-09-24 alongside the
     channels. Distinct from the public website: landing pages a specific
     advert points at, an app-store-facing page, and whatever a campaign
     needs. Codex owns the build under AD-AIOS-110 since it is product
     surface. Two things must be settled before any is built - what each page
     is trying to get the visitor to DO, and what happens to the details of
     anyone who fills something in on it, which is where OA-AIOS-381 and the
     data protection position stop being theoretical.

Dependencies: OA-ZYRA-235 (Toonbee — ANSWERED AND CLOSED 2026-09-24; it was
             never a blocker and the gate Fable wrote here has been removed) ·
             OA-AIOS-383 (business account and credential
             discipline) · OA-AIOS-381 (ICO registration — a public marketing
             presence that collects any enquiry data makes the data
             protection position more visible, not less) · existing material
             in BUSINESS/BRAND MESSAGING, BUSINESS/COMPETITOR RESEARCH,
             BUSINESS/APP NAME CREATION, BUSINESS/ZYRA LAUNCH GUIDE,
             BUSINESS/WEBSITE
Target:      Handles checked and one consistent name chosen -> accounts
             created by the Founder under the business identity -> recorded in
             the account register -> links live on the website and in the app
             -> a written purpose per channel -> marketing pages specified and
             built -> Toonbee looked at when ad creative is made -> close
Evidence:    Founder instruction in chat, 2026-09-23. No account created, no
             handle reserved and no copy written under this action as at the
             date it was raised.

MARKETING CLAIMS / MEDIA PROGRESS — 2026-10-06
             Under bounded private preparation authority, two original drafts
             now exist: 18 evidence-linked proposed claim decisions with 19
             source pins, and a dated manifest of 54 asset paths / 13,687,230
             bytes across exactly five roots (14 website, 11 brand, 13 icon,
             one splash and 15 font assets). All 18 claim publication decisions
             are HOLD. These counts describe the original dated inventory, not
             a freshly measured asset set or cleared public deliverables.
             Root rechecked 19/19 source pins and four provenance pins; 53/54
             original asset pins match. The one changed original app Syne notice
             belongs to APP BUILD's separately authorised local packaging repair,
             not corruption. Both original drafts and their historical hashes
             are preserved; no replacement manifest is claimed by this filing.
             Marketing's later provenance check matched official Google Fonts
             commit 54fb97bd69162b95b2aa2c3996ffd71466c1aec2 to the published
             2017 Syne OFL and a 2019 version-2.200 binary. No erroneous website
             year was established; no 2017 -> 2019 website notice rewrite occurred.
             Exact Syne inclusion, app-to-website transfer, 1 October receipt and
             5 October ledger linkage were strengthened, not original acquisition
             or instancing proof. Six Jost 3.710/copyright-2020 binaries are
             compatible with the cited notice; exact acquisition remains unproven.
             Marketing reported an initial old-ledger drift stop, followed by
             one authorised stable retry at 13:00 BST. Cause is unknown; the
             retry did not expand scope or silently discard the first outcome.
             APP BUILD's later sealed receipt records three exact font-text
             targets and two pubspec asset-registration lines changed only;
             all 13 TTFs, dependency lock/config and retained signed IPA remain
             unchanged. Root read the complete 266-line receipt and verified 36
             exact pins, including true prebackups and three physical unsigned
             UTF-8 text matches/manifest entries. The first iOS bundle command
             failed on the SdkRoot tooling requirement and its log is retained.
             The second unsigned android-arm debug bundle completed with exit
             zero and --no-pub: platform-neutral local asset packaging, NOT a
             signed iOS artifact, store submission or intended-release proof.
             These text/manifest checks are not additional runtime tests.
             Final acquisition/instancing and commercial rights, choice of assets,
             final content/claims, channel/territory permission, the exact final
             artifact and Founder acceptance remain OPEN. No account, public
             copy/post, campaign, live integration, legal clearance or launch
             acceptance is asserted. OA-AIOS-392 REC-009 records the coordinated
             readiness progress; this existing specialist OA retains ownership.
             Original Group evidence under SYSTEM/RESOURCES/REPORTS/:
             ZYRA_MARKETING_CLAIMS_DRAFT_2026-10-06_V1.md — moved to the private group folder (7 Nov 2026)
             SHA-256: 0055efc0a2fd80c24e3bbd05b1acda8154cde554dba448fdb9167bb268f710f3
             ZYRA_MARKETING_MEDIA_RIGHTS_MANIFEST_DRAFT_2026-10-06_V1.md
             SHA-256: f8ff00bd993cb5eb8d59c5a2641b8cdd1ae7ed641fa5351a1177f76a17961db8
             Later ZYRA evidence under SYSTEM/RESOURCES/REVIEWS/
             ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_FONT_NOTICE_REPAIR.json
             SHA-256: 1f26b5bb52d15e8707fab688f9e7d49c47d9c9cf5ca84569a3378d931e2eacd7
             App pubspec post SHA-256 (receipt-bound, not reread in this filing):
             3023a05e77d2f7f3b4d698a4d5fe1ace2f725787befff0923262fe32cf2d8588

ACTION 6 CHANNEL-PURPOSE PREPARATION — 2026-10-06
             Codex created and internally checked a private channel-purpose
             draft for the union of nine modelled channels plus LinkedIn and
             WhatsApp Business. It records audience/purpose hypotheses, format/
             reuse and qualified website handoff, estimated workload, proposed
             first/hold/reserve ordering, explicit claim/source mappings and all
             18 publication holds. This is local preparation executed, not
             Founder-selected channels, account reconciliation, public activity
             or acceptance. Action 6 remains OPEN pending Founder choices and
             acceptance; no whole OA or REC is closed.
             Root read the complete 260-line draft and verified six source pins,
             11 unique channel rows, all 18 HOLD decisions and the existing
             maximum of three master ideas per Europe/London day. This cap is
             not a daily quota or three posts on every platform. LinkedIn and
             WhatsApp are outside the current nine-platform model; this draft
             adds neither to its engine. Website is a destination, not a twelfth
             channel. FIRST/HOLD/RESERVE are recommendations, not activated or
             Founder-selected priorities, topics, cadence, workload or staffing.
             Account identity/security, channel/territory, exact final claims,
             media rights, destination/public/legal gates and Founder GO retain
             their separate acceptance requirements. No source, account,
             provider, public post, engine, state or calendar change was executed
             for this draft. No readiness score or launch clearance is inferred.
             OA-AIOS-392 REC-009 records coordinated progress only; this existing
             specialist OA and Action 6 retain ownership.
             Exact Group evidence under SYSTEM/RESOURCES/REPORTS/:
             ZYRA_MARKETING_CHANNEL_PURPOSE_DRAFT_2026-10-06_V1.md — moved to the private group folder (7 Nov 2026)
             SHA-256: 576d34efe5217ce41c0021cb941b7f73f5afe0cd5fa895bf99d1ea75981fea06

ADMIN ACTION6 CONTENT-PREPARATION RECONCILIATION — 2026-10-07
             Later private preparation under the renewed Founder local-work
             instruction, not approved campaign/channel selection. One text-only
             pack has three complete candidate briefs: B01 intent before an
             introduction; B02 optional practical Seeker–Guardian conversation;
             B03 Founder-introduction template. Each includes hook, script,
             caption, audience, production checklist and claim restrictions.
             Founder name/motivation/background are unfilled, not invented.
             All18 individual publication HOLDs remain. Zero media assets,
             accounts/channels/cadence/response owners/schedules selected;
             no render, measured speaking duration, public account or legal/IP
             acceptance. Root checked structure and10 input pins; ADMIN and a
             separate read-only Codex check matched this exact packet, not a
             fresh product/provider or promotional-rights audit.
             Action6 remains OPEN for Founder choice, personal facts, exact
             media/rights/destination/export checks and separate public-content GO.
             OA-AIOS-392 REC009 is coordination only. No app/website/AIOS engine,
             account/security/provider/calendar/publication/spend action.
             Group SYSTEM/RESOURCES/REPORTS/
             ZYRA_MARKETING_CONTENT_BRIEF_PACK_DRAFT_2026-10-06_V1.md — moved to the private group folder (7 Nov 2026) — 21,975B
             SHA-256: 30a4689d011ccce49bae9e548048faab170c8184f2b069cd5d792516b822ae3c
             Root dated internal receipt:
             release-resume-marketing-verified-2026-10-06-2346.json — 5,261B
             SHA-256: 3449109e49e4f551127ff713937f3fed39010e59e401266d9ce50e45852cb440
             No new ID, owner/status/closure/score change or Founder acceptance.

ADMIN ACTION6 PRIVATE PLATFORM VARIANTS COMPLETED — 2026-10-07
             Later routine-local away-work preparation is EXECUTED and internally
             checked, not pending execution of this finite documentary packet.
             Three unchanged master briefs now have nine private candidates:
             B01/B02/B03 × TikTok/Instagram/Facebook, with hooks/scripts/captions,
             restrictions and39 sequential TEXT storyboard beats. The companion
             index binds all9 exact sections and eight unchanged input anchors.
             It is informational/non-executable, not an engine/state import,
             approval token, publishing route, calendar or activated campaign.
             All C01–C18 publication decisions remain HOLD. Seven root selections
             stay empty; GO/Founder/release acceptance null. Every variant retains
             empty assets/null account,destination,owner,schedule,budget,GO and
             acceptance. B01/B03 scripts/captions preserve full development/
             unconfirmed-launch qualification; B02 preserves optional/advice/
             not-live-feature/privacy boundaries. B03 requires actual Founder
             public name/own motivation/recording; optional background unfilled.
             No biography, likeness, rights, asset, account or channel chosen.
             ADMIN read both complete outputs, matched9 section bytes/hashes,
             all39 beats and8 named input pins. Separate read-only internal check
             agrees. Root's305 support assertions are ATTRIBUTED documentary
             support evidence, not305 runtime tests or a new ADMIN execution.
             Byte bindings do not prove current capability truth. No render,
             speaking/read-time/mobile legibility, actual media rights, account/
             platform/territory/destination acceptance, response staffing/cadence,
             public copy GO or public operation has occurred.
             Action6 and this whole OA remain OPEN for Founder selection/revision,
             approved production inputs and exact final preview/public GO and
             acceptance. Private candidate preparation is complete; repeated
             unchanged holds must not launch more unselected campaigns/loops.
             OA-AIOS-392 REC009 coordinates only; OA-AIOS-390 keeps destination.
             No shared engine/AIOS state/app/website/account/security/provider/
             native-job/calendar/public/spend change, new ID/status/owner/
             closure/score or Founder acceptance.
             Group SYSTEM/RESOURCES/REPORTS/:
             ZYRA_MARKETING_PLATFORM_VARIANTS_DRAFT_2026-10-07_V1.md — moved to the private group folder (7 Nov 2026) —33,941B
             SHA-256: 0b28de6e8e66b4c58ce3502f508f6dac6381ce9a217c16edb81cdbe0b341c2ae
             ZYRA_MARKETING_APPROVAL_LIBRARY_DRAFT_2026-10-07_V1.json —17,393B
             SHA-256: 2e86d4c2385f32c0f33f6fc5bbe63a5869a6a043d68501fe36225c894d7c765b
             Root receipt release-marketing-platform-variants-verified-2026-10-07.json
             —9,402B / SHA-256:
             6d7bdf807dc6ffbd4f54aea8e2c7dad71abb9a8d997daae1e519d011ef13b6fa

------------------------------------------------------------

OA-ZYRA-302
Title:       Profile photo uploads have no dimension cap - agree the bounding
             box, then harden the bucket
Category:    App / Storage / Cost control
Priority:    MEDIUM. Nothing is broken today and no real member has been
             affected. It is a latent defect that becomes expensive the moment
             real members upload from modern phones, which is precisely when
             it would be hardest to fix quietly.
Status:      OPEN - awaiting the Founder's decision on the cap. Codex
             recommends 1440 on both axes. No code and no Supabase
             configuration has been changed by anyone.
Owner:       Codex (implementation, both parts) - Founder (decides the cap and
             approves the bucket limits) - Fable (raised it, holds the record)
Raised:      2026-09-24
Raised by:   Fable, while measuring Supabase quota headroom for OA-ZYRA-276
Initiative:  INI-002 / ZYRA
Authority:   AD-AIOS-110

THE DEFECT
             `lib/services/zyra_photo_service.dart:274`, in `pickAndUpload()`,
             calls ImagePicker with `imageQuality: 85` and NO `maxWidth` or
             `maxHeight`. The JPEG is re-encoded but the pixel dimensions are
             whatever the camera produced. Bytes are then read straight to
             `uploadBinary` with no resize step anywhere in between.
             A 12-megapixel photo therefore uploads at 4032 px wide to be
             shown, at most, in a full-screen phone view.

FABLE'S HEADLINE NUMBER WAS MEASURING THE WRONG THING - CORRECTED
             Fable reported "average 3.65 MB per photo" from the storage table
             and built the case on it. THAT AVERAGE WAS DOMINATED BY SEED
             DATA. Codex checked rather than accepting it, and a re-query by
             Fable confirms him exactly:
               99 objects  image/png   uploaded 2026-07-25   366 MB
                                       average 3,782 kB each
                4 objects  image/jpeg  uploaded 2026-08-19   1.79 MB
                                       average 447 kB each
             The 99 PNGs are seeded test assets that never went through the
             app's picker, and the ImagePicker setting cannot affect them.
             THE ONLY OBJECTS THAT CAME THROUGH THE UPLOAD PATH ARE THE FOUR
             JPEGs, AND THEY AVERAGE 447 kB - which is unremarkable.
             So the defect is real and the arithmetic about what it would cost
             is real, but the measurement Fable used to dramatise it was
             measuring something else. Four samples is also too few to
             characterise user behaviour. This is the third time in two days
             that a number has been repeated without interrogating what it was
             counting; it is recorded here for that reason as much as this
             one.
             WHAT SURVIVES THE CORRECTION: the code has no cap, so the
             exposure is latent rather than absent. It has not bitten because
             only four real uploads exist.

CODEX'S RECOMMENDATION, AND WHY IT BEAT FABLE'S
             1440 on BOTH axes, keeping quality 85.
             BOTH AXES ARE NECESSARY. ImagePicker preserves aspect ratio, so a
             portrait photo capped on width alone keeps its long edge. Fable
             proposed `maxWidth` only in the first pass and raised the
             question in message 152; Codex confirmed it as a defect in the
             proposal, not a preference.
             1440 RATHER THAN 1080 because Browse, Profile Preview,
             Connections and Guardian Network all present full-screen,
             edge-to-edge photographs. Fable recommended 1080 on the
             assumption that photos appear in small circles and cards. That
             assumption was wrong and it came from not knowing the screens.
             This is the authority split working: Fable found the defect from
             the infrastructure side and got the remedy wrong from the product
             side, which is Codex's.

IDENTITY AND MODERATION - NO FORENSIC ORIGINAL IS NEEDED
             Profile photos are NOT identity-verification evidence. The
             approved IDV architecture sends the document and selfie from the
             device straight to the specialist provider, and ZYRA is
             specifically not meant to retain either. Photo-to-selfie
             comparison is not implemented and is a separate legal and product
             question. The moderation queue is a developer preview and 1440 px
             is ample for the screening planned. If a future process ever
             needs forensic originals, that belongs on a separate controlled
             evidence path - not achieved by silently keeping every member's
             profile photograph at camera resolution.

A SECOND GAP CODEX FOUND, WHICH FABLE HAD NOT CHECKED
             The live `profile-photos` bucket has NO server-side file-size
             limit and NO MIME-type allow-list. A client resize only governs
             the app behaving normally; a modified or outdated client can
             still upload whatever it likes. The client fix is therefore
             necessary and not sufficient.

EGRESS - FABLE'S FIGURES NARROWED
             Fable's estimate treated the Free plan's 5 GB as a single pool.
             Supabase provides SEPARATE 5 GB cached and 5 GB uncached
             allowances. The bucket is private, and private objects have a
             poorer shared-CDN hit rate because access is checked per user.
             The app also holds a seven-day on-device byte cache keyed WITHOUT
             the signed-URL token, so re-signing a URL does not force the same
             device to re-download - which Fable did not know and which
             materially softens repeat browsing. It does not help first views,
             new devices, cleared caches or other members.
             Codex confirms the preload behaviour that drives the worst case:
             Browse preloads every photo of the current profile plus the first
             photo of the next. Fable's "250 loads for 50 profiles" therefore
             holds as a FIRST-LOAD EQUIVALENT, and should be described that
             way rather than as a monthly capacity forecast.
             Codex also cautions that 200-350 kB per resized photo is
             plausible but not guaranteed - it varies by content and format,
             and should be measured across a representative iPhone and Android
             sample before any capacity figure is published.

RE-EXAMINATION ON UPGRADED MODELS - 2026-09-24, MESSAGE 154
             The Founder moved both agents to higher models and asked for each
             matter to be re-examined before he approves. Fable re-checked its
             side and put eight matters to Codex for CONFIRM or REVISE. Two are
             new.
             NEW - LOCATION DATA IN PHOTOS. THE MOST IMPORTANT ITEM ON THIS OA
             IF IT PROVES TRUE. There is no EXIF or metadata stripping anywhere
             in lib/; bytes go from readAsBytes() straight to uploadBinary.
             Resolved versions: image_picker 1.2.3, image_picker_android
             0.8.13+19, image_picker_ios 0.8.13+6. Fable's understanding is
             that image_picker copies the original EXIF, including GPS, onto
             the resized image on both platforms. THIS IS NOT PROVEN for these
             versions and is recorded as a hypothesis awaiting a real-device
             test, not as a finding. If true: every real member's photo carries
             where it was taken, the whole file reaches other members' devices
             through signed URLs and the image cache, and for a matrimonial
             product with women members that is a safety exposure as well as a
             UK GDPR data-minimisation failure. The fix would belong in the same
             change as the resize.
             NEW - A SEQUENCING TRAP between the bucket hardening and the seed
             replacement: a size ceiling or MIME allow-list applied first could
             reject the replacement uploads. Proposed order: app cap, measure,
             replace seeds, then apply bucket limits.
             VERIFIED BY FABLE THIS TURN: storage.buckets shows profile-photos
             private, file_size_limit NULL, allowed_mime_types NULL - Codex's
             hardening finding confirmed. Separate cached and uncached 5 GB
             egress allowances confirmed from the usage page.
             OPEN QUESTION FOR CODEX: the seed PNGs, if replaced "under the
             same paths", stay PNG and stay comparatively large; converting to
             JPEG requires updating profile_photos.storage_path in the same
             step.

CODEX'S RE-EXAMINATION RETURNED - 2026-09-24, MESSAGE 155
             Three CONFIRM (1 the cap, 2 both axes, 6 egress), five REVISE, all
             of them tightening rather than reversing:
             MATTER 3 - LOCATION. SOURCE-LEVEL CONFIRMATION, DEVICE TEST NOT
             RUN. Codex read the exact installed picker source: the Android
             implementation EXPLICITLY copies GPS EXIF onto the resized image;
             the iOS implementation reattaches the original metadata with no
             GPS exclusion. Fable's hypothesis is therefore upgraded from
             recollection to a credible retention path established in code.
             It is still NOT proof that a given photo leaks location; that
             needs GPS-positive originals compared against downloaded stored
             objects on both platforms. Codex has an iPhone connected but no
             physical Android and no verified GPS-tagged captures, and
             declined to give a completion date he could not stand behind.
             Codex also states that resizing, or requestFullMetadata:false,
             is NOT a reliable safeguard - explicit sanitisation is required,
             with orientation applied before the orientation tag is removed.
             WHO HAS BEEN EXPOSED: NO REAL MEMBER. Codex established that
             every one of the 103 stored objects belongs to a test-domain
             account, and storage.buckets holds only this one bucket, and the
             only upload path in lib/ is zyra_photo_service.dart. The defect
             has been caught before it reached a member - which holds only
             while no real member uploads before the fix ships.
             MATTER 4 - seeds to JPEG q85 under NEW .jpg paths, matching MIME;
             upload and verify, transactionally update every storage_path row,
             check Browse, then retire originals. New paths also defeat the
             app's path-keyed cache showing stale files.
             MATTER 5 - order revised: measure and privacy-test the candidate
             BEFORE shipping; then ship, replace seeds, then bucket limits after
             checking older-client behaviour. Size and MIME limits neither strip
             metadata nor make a file safe.
             MATTER 7 - Codex withdrew his own earlier claim that 1440 is ample
             for moderation. Adequacy is untested against a real moderation
             system.
             MATTER 8 - test set widened again: JPEG and PNG, orientation, a
             genuine low-memory Android, confirm the high-megapixel source
             really is that resolution, inspect downloaded stored objects not
             picker previews, record bytes, processing time and failures.
             FAIL CLOSED: a processing failure must never fall back to
             uploading the unprocessed original.

             FABLE'S VIEW ON WHAT THIS MEANS FOR THE DECISION: the source
             evidence is enough to decide the FIX now. The device test is what
             proves the fix works; it is not needed to justify building it.
             Waiting for the test before deciding would leave the retention
             path open for no gain.

TEST INPUTS MEASURED 2026-09-24 - THE ORIGINALS DO CARRY LOCATION
             The Founder took three photographs away from his home and placed
             them in SYSTEM/RESOURCES/TEMPORARY/PHOTO_PRIVACY_TEST_2026-09-24
             under BLACK UMBRELLA GROUP. Fable read them directly.
             ALL THREE CARRY A FULL GPS BLOCK - fifteen tags each. Coordinates
             deliberately NOT transcribed into this register or into chat; the
             finding is that they exist, not what they say.
               IMG_0444.HEIC  5,367,472 bytes
               IMG_0445.HEIC  1,314,348 bytes
               IMG_0446.HEIC  5,464,018 bytes
             Each carries: latitude and longitude with hemisphere refs,
             altitude, GPSHPositioningError of about TWO METRES, the direction
             the camera was pointing, walking speed at the moment of capture,
             and a GPS timestamp to the second.
             ALSO CARRIED, AND WORTH ITS OWN LINE: Make "Apple", Model
             "iPhone 15 Pro Max", the exact lens, ISO, aperture, shutter, and
             DateTimeOriginal to the second. EVEN WITH GPS REMOVED, that set
             is a device fingerprint - it links photographs from one handset to
             each other across different profiles. Stripping location alone is
             therefore not the whole job; the sanitisation in ACTION 2 should
             remove all non-essential metadata, keeping only what is needed to
             display the image correctly.
             THE SIZE CASE IS ALSO NOW EVIDENCED PROPERLY. These are 5712 x
             4284, roughly 24 megapixels, at up to 5.5 MB. Fable's earlier
             "average 3.65 MB" was measuring seed PNGs and the only four real
             uploads averaged 447 kB, which had weakened the argument. A real
             modern handset produces FIVE MEGABYTE originals, so the uncapped
             upload path is exactly the exposure it was claimed to be - now
             shown from a real device rather than inferred.
             WHAT THIS DOES AND DOES NOT PROVE: it establishes the test inputs
             are valid. It does NOT yet show what the app does with them. That
             is the upload comparison still outstanding.
             HANDLING: the folder is now excluded in BLACK UMBRELLA GROUP/
             .gitignore and carries a written warning. The three files are the
             Founder's real location and are to be DELETED once Codex reports.

ACTIONS
  0. DONE 2026-09-24 - Codex returned CONFIRM/REVISE on all eight matters,
     message 155. Matter 3's device test remains OPEN and is not a privacy
     sign-off.
  0a. WITHDRAWN 2026-09-24 - the Founder cancelled the approval message Fable
     had drafted: "TASK 2 IS NOT NEEDED. CANCEL THAT". No approval has been
     given and none is now being sought.
     WHAT THAT MEANS, STATED PLAINLY SO NOBODY LATER ASSUMES OTHERWISE: the
     1440 x 1440 cap and the metadata sanitisation are NOT authorised and are
     NOT being built. Both agents recommend them; neither has been approved.
     The evidence behind the recommendation is unaffected and remains in this
     entry - the picker source copies GPS on both platforms, and the Founder's
     own three photographs carry fifteen GPS tags plus a device fingerprint.
     This is a deferral of the decision, not a finding that the decision was
     wrong. It returns when the Founder wants it.
  0b. PART DONE 2026-09-24 - iPhone GPS-tagged captures SUPPLIED AND VERIFIED
     (three HEIC files, full GPS confirmed by Fable). STILL OPEN: an Android
     route for the location test, and a real low-memory Android for Matter 8
     before launch.
  0f. ANSWERED 2026-09-24 - WHY THE UPLOADS DID NOT LAND. Codex: the Founder
     was uploading through a DEVELOPER path, not a real member account, so the
     photos never went to the production bucket. None of Fable's four guesses
     was right; it was a fifth option nobody outside the app could have seen.
     Recorded because the guessing cost a round of checks that a single line
     from Codex settled - when the question is "what did the app do", ask the
     agent who owns the app before measuring the database.
     CONSEQUENCE: the end-to-end privacy test CANNOT run until the Founder
     tests on a real account. PARKED until then on his instruction.
     THE THREE VERIFIED ORIGINALS KEEP THEIR VALUE - they proved the inputs
     carry GPS and that a current handset produces 5 MB files. That evidence
     stands whatever happens to the upload test.

  0g. NOTED 2026-09-24 - CODEX HAS SHIPPED THE SUPABASE KEY MIGRATION
     (message 151) WITHOUT WAITING TO BE CHASED. Fable read
     lib/config/supabase_config.dart directly: the app now uses
     `_productionPublishableKey` in `sb_publishable_` format, the field is
     renamed from anonKey to publishableKey, and
     zyra_supabase_config_policy.dart now REJECTS any key not matching
     ^sb_publishable_[A-Za-z0-9_-]+$ - so the app cannot start on a legacy
     JWT or a privileged secret key even by mistake. That guard is more than
     message 151 asked for.
     WHAT THIS DOES NOT YET DO: revoking the exposed legacy service_role key
     still requires disabling legacy JWT keys at Supabase, and that waits on a
     shipped build being confirmed on a real device. OA-AIOS-383 stays open.

  0e. OPEN 2026-09-24 - THE FOUNDER'S THREE UPLOADS NEVER REACHED PRODUCTION.
     He reported adding three photos to the app. Fable measured immediately
     after: storage.objects still 103 objects with newest created_at
     2026-08-19; profile_photos still 597 rows with newest 2026-08-05; and
     exactly ONE Supabase project exists on the account, so there is no
     second destination they could have reached. NOTHING ARRIVED.
     Candidate explanations, undetermined from Fable's side: a local or dev
     Supabase stack; a silent upload failure; a screen that never calls
     pickAndUpload; or an RLS rejection.
     A DEFECT FOUND WHILE LOOKING: pickAndUpload() ends `catch (_) { return
     const ZyraPhotoResult.error(); }`. Every failure mode collapses into one
     untyped error with the reason discarded. This is why the question cannot
     be answered from outside the app, and it is worth fixing on its own
     merits - at minimum log the caught error in debug builds.
     Referred to Codex in message 156.

  0d. PARKED 2026-09-24 ON FOUNDER INSTRUCTION - the upload comparison. The
     Founder reports the photo-upload step is not reachable in the current
     build, so the end-to-end test cannot run yet. Deferred to whenever that
     surface is available.
     WHAT PARKING THIS DOES NOT DO: it does not weaken the case for the fix.
     The Android picker source explicitly copies GPS; the iOS source
     reattaches metadata with no GPS exclusion; and the originals are now
     measured as carrying fifteen GPS tags plus a device fingerprint. The
     remedy is decided on that evidence. The upload comparison proves the
     remedy WORKS - it is acceptance testing, not the reason to build.
     Codex must not treat this as a reason to defer the implementation.
     THE TEST FILES STAY. Fable recommended deleting them and retaking
     them later; the FOUNDER RULED OTHERWISE on 2026-09-24 - they remain in
     place as part of this action. Settled, and not to be raised again. The
     folder is gitignored and carries a written warning, which is the
     protection that was actually needed.
  0c. RECOMMENDED - no external tester uploads real photos until the
     sanitising change ships. Founder decision.
  1. OPEN - Founder decides the cap. Both Codex and Fable now recommend
     1440 x 1440 at quality 85.
  2. OPEN - Codex implements it, with tests proving the output dimensions and
     the upload behaviour.
  3. OPEN - measure real output across representative iPhone and Android
     photos; record median and worst case. No capacity figure is published
     before this.
  4. OPEN - separately approve a bucket file-size ceiling and an image
     MIME allow-list, sized from action 3.
  5. OPEN - the 99 seeded PNGs. They do NOT age out; they sit there until
     replaced. They power the Browse test deck, so deleting them breaks that
     deck. Codex recommends resize-and-replace under the same paths as its own
     maintenance action once the cap is live. Fable's earlier suggestion to
     "let it age out" was wrong and is withdrawn.

Dependencies: OA-ZYRA-276 (Supabase plan and quota - this is where the
             question came from) · mailbox messages 152 and 153 · AD-AIOS-110
Target:      Founder picks the cap -> Codex ships it with tests -> real output
             measured -> bucket limits approved and applied -> seeded assets
             resized -> close
Evidence:    storage.objects queried by Fable 2026-09-24, twice - the second
             query by mimetype and date is what exposed the seed-versus-real
             split. Codex's independent verification of owners, domains and
             sign-in recency, message 153.

------------------------------------------------------------

OA-ZYRA-306
Title:       Separate Public Browse Answers and Private Radius Search
Category:    Product / Privacy / Discovery
Priority:    High before real-member filter activation
Status:      OPEN — Founder direction accepted; local sample UI only
Update 2026-10-17 (real Filters request; read-only verification):
             Founder asks to remove sample-only copy, replace City pills
             with typed dropdown selection and Distance pills with a slider,
             and make selected-area distances genuinely operational, not
             guessed or display-only. Current concept Filters independently
             combines exact city equality with a fixed Manchester sample
             radius; changing City does not change its radius origin.
             Existing valid-point/Haversine/null-unknown handling is reusable,
             but fictional coordinates are not member-location evidence.
             Public Source has no real geocoder/location acquisition or
             trusted candidate-radius reader. Own location persistence and
             ordinary discovery currently use profiles.location_text.
             A read-only metadata query on the runbook-pinned main project
             confirms location_text is text, the inspected public/private
             location-column projection has no member-coordinate field and
             the named radius/distance/place-search function projection is
             empty. No member rows or precise locations were read; this is
             scoped metadata evidence, not an exhaustive live security audit.
             No Source/UI, provider, location collection, schema, stored data,
             device or native build change is made. Removing the warning
             alone would misrepresent the current fixture-only behavior.
             Next Founder decision: authorize preparation of verified chosen-
             city selection and a private location-backed radius contract,
             alongside the UI changes, with no inferred/backfilled coordinates
             from legacy free text and no public candidate coordinates. The
             selected area must own the radius origin; exact-city equality
             must not silently exclude surrounding radius matches. Any city-
             centre-only precision contract must be explicit, not described
             as exact person/GPS or road distance. Exact production migration,
             real collection/provider activation and live GO remain separate.
             This finding stays with OA306/OA151; no duplicate OA or closure.
Owner:       Codex (implementation and evidence); Founder (exact live GO)
Authority:   DR-ZYRA-267; Founder explicitly chose separate public answers.
Description: Capture public nationality and ethnicity separately with a
             clear Browser disclosure notice and a fresh versioned member
             choice, never migrate or expose private compatibility answers.
             Withdrawal must immediately remove display and filter inference.
             Use a narrow caller-bound eligible Browser projection; keep raw
             seeker_details policies unchanged. Filter results must not infer
             an unconsented private answer. Existing Article9 grants and the
             has_article9_consent helper do not prove this new public purpose.
             Reconcile historical unlocked-reader/never-show consent drift
             with OA305's compatibility/privacy boundary, not by widening it.
             Country means residence, not birth/nationality. Actual radius
             requires user-initiated while-in-use location, private trusted
             candidate location/distance predicates, provenance/freshness,
             denied/revoked/offline/unknown handling and no public coordinates.
             Preserve blocks, admission, full capacity and unavailable!=empty.
Prepared:    Protected preview supports invented public labels, composed
             age/country/heritage/distance filters and explicit sample origin;
             it collects no device location or real member answer. This is
             not real data capture, consent grant, server filtering or SQL.
Target:      Owner/withdrawal/direct-role tests, narrow-field/RLS and radius
             query/index tests, exact payload review, Founder live GO, actual
             deployment and post-verification before real-member activation.
Dependencies: OA-ZYRA-151/303/305; DR-ZYRA-267.
Automation:  Manual; no external action or recurring notification scheduled.

------------------------------------------------------------

OA-ZYRA-307
Title:       Review Browse Three Dot Menu and Ended Archive Boundaries
Category:    Product / UX / Safety
Priority:    High before adopting a gallery for real members
Status:      OPEN — Founder requested reminder after gallery selection
Owner:       Codex (review and implementation); Founder (gallery choice)
Authority:   DR-ZYRA-268 and direct request to retain/revisit the three dots.
Description: Once the Founder chooses a gallery, prompt him to check the
             Browse three-dot placement and Hide/Block actions. Preserve
             Report access and safe confirmations without photo/navigation
             collision. Hiding is reversible private feed exclusion; blocking
             removes counterpart access and shows User not found. Do not
             remove safety authority because the swipe system was retired.
             Confirm Ended archives are only in My ZYRA, read-only and without
             old restart requests; archive messages must retain attempt/owner
             authorization and become inaccessible when blocked. OA151 owns
             any fresh request after rediscovery and legacy attempt mapping.
Target:      Founder chooses a gallery -> menu review reminder -> scope and
             exact implementation -> navigation/permission tests -> scoped
             phone delivery/Founder acceptance. This entry is the requested
             outstanding-action reminder, not an invented scheduled date.
Dependencies: OA-ZYRA-151/290/299/305; DR-ZYRA-267/268.
Automation:  Manual.

------------------------------------------------------------

OA-ZYRA-308
Title:       Founder Choice of Journey Navigation Icon
Category:    Product / UX
Priority:    Normal
Status:      OPEN — Couple selected, client verified and locally delivered;
             Founder physical acceptance pending
Update 2026-10-13 (Founder Couple selection):
             Founder directly selected Couple, requested removal of the other
             toolbar/toggle choices and matching navigation glyph sizes.
             This resolves the choice, not physical acceptance or app release.
             Navigation Haptics section77 / scoped quiet-launch packet retain
             client/source measurements and exact local delivery separately.
             Existing selected highlight, tint, routing, semantics, targets,
             badges and haptics remain; no launcher artwork or authority change.
             Final31-suite617/0/0 regression, clean analysis/format and12
             inspected candidate images pass. Same-main PROFILE installed and
             immediately native-launched at00:14 BST on13 October; exact new
             container/processPID3189 and unchanged source/artifact verified.
             Section77 and its immutable packet own the detailed receipts.
             No public release, authority grant or OA closure is implied.
Owner:       Codex (implementation and checks); Founder (visual choice)
Authority:   DR-ZYRA-270 and direct request to show ten options here first.
Description: Replace the rejected shared-path icon only after the Founder
             chooses from the ten conversation concepts or gives a new design
             direction. Retain the existing navigation theme, icon footprint,
             selected highlight, haptics, routing and accessibility. The title
             correction is independent and does not select an icon. Keep the
             prior delivery record without treating native launch as acceptance.
Target:      Founder choice -> scoped glyph implementation -> rendering and
             navigation checks -> standing scoped phone delivery -> acceptance.
Dependencies: OA-ZYRA-151; Navigation Haptics handover §36.
Automation:  Manual; no scheduled reminder or external message.

------------------------------------------------------------

OA-ZYRA-310
Title:       Visual regression baselines are out of date - all 124 approved goldens fail
Category:    Testing / UI consistency gate
Priority:    MEDIUM - the visual safety net is not working until this is fixed
Date:        2026-10-25
Status:      OPEN - found by Fable on 25 Oct while checking OA-AIOS-408. The Founder ran
             test/visual/zyra_visual_regression_test.dart: 194 pass, 124 fail, every
             failure a 99.99% pixel difference. Cause checked by looking at one pair: the
             approved image (30 Aug, OA-ZYRA-282 phase 3) shows the old "Dashboard" (Today /
             Updates / Insights); the app now draws "My ZYRA" (Now / Insights). The
             baselines predate the October redesign; the path move did not cause this (the
             manifest-audit test, which reads the moved UI_GATE files, passes).
Owner:       Fable prepares the review set · Founder approves each new baseline
             (automatic_updates_allowed = false)
Next:        After the build freeze review: list which of the 124 variants still exist,
             retire the ones whose screens are gone, capture candidates for the rest, Founder
             approves visually, then the approved manifest and the governed copy in
             SYSTEM/tools/ui_gate/BASELINES are replaced together.
Acceptance:  zyra_visual_regression_test.dart passes with Founder-approved baselines.

------------------------------------------------------------

OA-ZYRA-311
Title:       Six screens nothing in the app opens - keep or retire
Category:    Code health / Product blueprint
Priority:    LOW - no member impact; dead screens confuse agents and the blueprint
Date:        2026-10-25
Status:      OPEN - found by Fable while building blueprint part 1 (OA-ZYRA-309). No app code
             creates these screens; only tests (or nothing) do: JourneyMapScreen,
             NotificationsScreen (a shell test asserts it is NOT used in the shell),
             ZyraGuardianCirclesInboxScreen, GuardianDetailScreen,
             WaliNotificationSettingsScreen, ModerationReviewQueueScreen (developer).
             Nothing changed - build freeze.
Update:      25 Oct - blueprint part 5 found 4 shared widgets the app never uses (tests only or
             nothing): fab_continue_button, glass_icon_button, zyra_family_pricing_card,
             zyra_paused_limit_refusal. Same decision as the screens: use on purpose or retire.
Owner:       Founder decides per screen after the freeze · Codex retires with its tests
Acceptance:  Each screen is either reachable on purpose or retired with its tests, and the
             screen inventory shows no unreached screens.

------------------------------------------------------------

OA-ZYRA-312
Title:       Developer test functions in the production database - check they cannot be reached
Category:    Security / Database
Priority:    MEDIUM - guarded today; the guard depends on a sign-up setting
Date:        2026-10-25
Status:      OPEN - found by Fable in blueprint part 3 (OA-ZYRA-309). 13 functions
             (zyra_dev_* and zyra_debug_grant_credits) run with owner rights and are granted to
             every signed-in member; each refuses unless the caller's email ends in @zyra.test.
             Safe only while no one can create or confirm an account with such an email. Also:
             zyra_onboarding_questions was first created outside the migrations, so its
             security settings are not in the repository. Nothing changed - build freeze.
Update:      26 Oct - Add to the live check: are the 16 @zyra.test seed accounts (seed_dev_accounts.sql) and
             fake photos in production? Which migrations are applied live vs the repository (24 Sep
             paid-only; OA-ZYRA-298 Guardian Circle messaging noted as not live)?
Update:      26 Oct - Also check live: do zyra_my_hidden_profile_ids, zyra_set_profile_hidden,
             zyra_my_profile_pause_state, zyra_set_my_profile_pause or wali_has_wali_one exist in production
             (they are not in any migration)?
Update:      26 Oct - LIVE CHECK DONE (Founder GO, read only): DOC-ZYRA-0294. 13 developer functions live, callable
             by any signed-in account, guarded by @zyra.test; production has 149 test accounts and 4 others, no
             real members. zyra_onboarding_questions: RLS on, functions only - safe (that part closed). Remaining
             before launch: remove developer/mock functions; confirm sign-up settings; leaked-password
             protection on.
Next:        With the Founder's GO, read-only checks on the live project: email sign-up and
             confirmation settings; row-level security on zyra_onboarding_questions. Then
             decide: keep with a stronger guard (confirmed email + allow-list), or move the
             helpers out of production.
Acceptance:  No member can run a developer function; every table's security is in the migrations.

------------------------------------------------------------

OA-ZYRA-313
Title:       Colour theme document out of date - bring it in line with the app
Category:    Brand documentation
Priority:    MEDIUM - documents only; agents reading the tables get wrong colours
Date:        2026-10-25
Status:      OPEN (corner scale only; document rewritten 25 Oct) - found by Fable in blueprint part 5 (OA-ZYRA-309). BUSINESS/COLOUR THEME/
             Summary.md (DOC-ZYRA-0102) has correct dated banners on top but out-of-date tables
             underneath: old purple values, male/female gradients, sheet #2A1F33, lavender button
             fill, glass dialogs; only 4 colours listed; no font record. Full list: DOC-ZYRA-0282 §9.
             Also: no single corner scale in code (14/18/12/20/16/24 all common).
Next:        Founder GO -> Fable rewrites Summary.md as one current version from the code, banners
             folded in, history moved to an archive copy (documentation, allowed in the freeze).
             The corner scale is a design decision for after the freeze.
Update:      25 Oct - Founder GO ("a for both"). Fable rewrote Summary.md, Flow Diagram.md and
             References.md as V2 from the code; V1 copies archived unchanged in BUSINESS/COLOUR THEME/
             ARCHIVE/ with a SUPERSEDED banner; onboarding rules COLOUR SYSTEM marked history.
             Document part DONE. Still OPEN only for the corner-scale decision (after the freeze).
Owner:       Fable writes · Founder approves
Acceptance:  Every value in the colour theme document matches zyra_colors.dart / zyra_text.dart.

------------------------------------------------------------

OA-ZYRA-314
Title:       Look-and-feel code fixes - Journey haptics, privacy-word contrast, stray file
Category:    UI / Accessibility / Repository hygiene
Priority:    MEDIUM
Date:        2026-10-25
Status:      OPEN - found by Fable in blueprint part 5 (OA-ZYRA-309). Nothing changed - build freeze.
             (a) screens/journey/journey_flow_screen.dart calls HapticFeedback.selectionClick() directly
             4 times, so it vibrates even when the member chose Off; everything else goes through
             ZyraInteractionStyle.emitSelectionHaptic(). (b) Privacy words (Public #C8DC8C@50%,
             Unlock #DCB964@45%, Private #B496D2@45%) are 3.6 / 2.7 / 2.3 contrast on the default
             background - under the 4.5 needed for normal text. (c) SOURCE/lib/screens/browse/
             .fuse_hidden0000001200000001 (93 KB, 4 Aug) is a left-over file from a mounted-drive
             delete and is tracked in git.
Next:        (c) can move to ~/_to_delete now with the Founder's GO (then Founder commits).
             (a) and (b) are code changes for after the freeze: route the 4 calls through the shared
             helper; raise the privacy-word opacity until it passes 4.5 (Founder looks on device).
Update:      25 Oct - (c) DONE with the Founder's GO: the file moved to ~/_to_delete/ZYRA_2026-10-25/.
             The Founder's next commit records its removal from git. (a) and (b) wait for the freeze to lift.
Owner:       Fable (c) · Codex (a)(b) after the freeze · Founder approves
Acceptance:  Haptic Off means no vibration anywhere; privacy words pass 4.5; no stray files in git.

UPDATE 31 Oct (Fable): item (a) DONE - queue line 22 (d1de664, 30 Oct) routes every haptic through the shared helper;
Fable's search finds no direct HapticFeedback call outside zyra_interaction_style.dart. Items (b) privacy-word
contrast and (c) the stray file remain; (b) is part of the Ivory recolour (LOCK 14, OA-ZYRA-327).
------------------------------------------------------------

OA-ZYRA-315
Title:       Journey rules - server gaps and loose ends found in blueprint part 2
Category:    Security / Journey
Priority:    HIGH for (a)(b) - rules only the app enforces; MEDIUM for the rest
Date:        2026-10-25
Status:      OPEN - found by Fable in blueprint part 2 (OA-ZYRA-309). Nothing changed - build freeze.
             (a) Identity check (verified + duplicate clear) is enforced only in the app; the server
             function zyra_my_identity_verification_allows_active_journey is never called.
             (b) open_family_review checks the stage but not that both Seekers answered every question;
             only the app holds the button back. (c) Paused cap is 10 but only the 5 most recently paused
             can be asked to resume (zyra_guard_paused_return_initiation). (d) Journey lifecycle document
             DOC-ZYRA-0256 (V3, Aug) still describes Basic/ZYRA One, pause caps 5/10, one Active Journey.
             (e) Refusal stubs suspend_journey, resume_journey, nudge_paused_journey, restart_journey.
             (f) The 24 Sep paid-only migration is marked repository/staging only - production may differ.
Next:        (f) joins the OA-ZYRA-312 read-only live check (Founder GO). (c) Founder states the intent.
             (d) Fable can mark DOC-ZYRA-0256 superseded by DOC-ZYRA-0283 now (documentation).
             (a)(b)(e) are server changes for after the freeze (Codex), each with an impersonation test.
Update:      25 Oct - (d) DONE (Founder "do a"): DOC-ZYRA-0256 marked SUPERSEDED by DOC-ZYRA-0283.
             Founder: "we dont have paused no more" - see OA-ZYRA-316; (c) depends on it.
Owner:       Founder decides (c)(f) · Fable (d) · Codex (a)(b)(e) after the freeze
Acceptance:  Every Journey rule the app shows is also refused by the server; caps and resume window agree.

------------------------------------------------------------

OA-ZYRA-316
Title:       Two apps in one codebase - decide which is ZYRA, then a deep clean-code review
Category:    Product / Code health
Priority:    HIGH (Founder, 25 Oct: "I kinda need to ensure the code building these apps dont have
             unnecessary things ... i want clean code")
Date:        2026-10-25
Status:      OPEN (choice made 25 Oct, DR-ZYRA-274; review next) - found by Fable checking the Founder's statement that Pause is gone.
             When the Founder signs in, the app opens ZyraFounderLaunchScreen -> a LOCAL PREVIEW
             (ViewRequestDraftScreen / ZyraOneJourneyConceptShell, SOURCE/lib/dev, sample data, no real
             members). In that preview Pause is unreachable (canPause: false; only End is accepted),
             retired 9 Oct. Every other member gets the ORDINARY app (HomeShell, journey_flow_screen):
             it still offers the full shared Pause flow, backed by the server (transition_journey_pause,
             caps, 13 pause-lock triggers). So the Founder has been reviewing a different app from the
             one members would get. Scale: lib 171,658 lines / 342 files; lib/dev 45,620 lines / 84 files;
             the preview ~24,700 lines; Pause in 40 non-dev files; leftover Pause code inside the preview too.
Next:        1 Founder decides which app is ZYRA (question asked 25 Oct). 2 Fable runs a read-only deep
             review: every feature in both apps side by side, dead code, dev-only code shipped to members,
             duplicates, retired features still wired (Pause, Save, restart), unused files. 3 One clean-up
             plan the Founder approves item by item; Codex builds it after the freeze.
Update:      25 Oct - DECIDED, DR-ZYRA-274: the latest Codex design (the Founder preview) is the planned
             ZYRA; the old member app is replaced; code cleaned anyway. Founder asked that Fable/Codex work
             out what the preview is without him explaining. Who does what: Fable reviews and writes the
             exact clean-up list; Codex removes and tests after the freeze; Fable checks the result.
             Lessons L30, L31, F12, S13 logged. Next: step 2 (deep read of the planned app).
Update:      26 Oct - Step 2 DONE: deep review DOC-ZYRA-0285 (REPORTS/CURRENT/ZYRA_PLANNED_APP_DEEP_REVIEW_
             2026-10-26_V1.md). Clean-up in 5 tiers: 1 unused files (22 / 5,767 lines); 2 retired features
             (Pause, Save, old stubs); 3 old app (26 files / 19,280 lines + journey_flow_screen); 4 design
             alternatives (~150 in 18 sets, Founder decides each); 5 tests (207,814 lines, 3,984 images).
             Server gaps raised as OA-ZYRA-317. Lessons L33, L34, F13. DR-ZYRA-274 corrected (Request
             restart is planned, not retired). Next: Founder decisions on Tier 4 and Basic places.
Update:      26 Oct - Founder decided (A, A): DR-ZYRA-275 Basic = 1 place after the £4.99 joining fee;
             DR-ZYRA-276 Tier 4 - keep only chosen designs, plus the 10 member backgrounds and the
             developer font/navigation comparisons (about 140 options in 17 sets, corrected count).
             Clean-up plan complete; Codex starts Tier 1 after the freeze.
Update:      26 Oct - Add to Tier 1/3: sample photos fetched from picsum.photos in models/seeker_profile.dart,
             connections_screen.dart and zyra_wali_journey_service.dart (blueprint part 4 §4).
Update:      26 Oct - From blueprint part 6 (DOC-ZYRA-0288 §9): merge the three tool folders (tool/, tooling/,
             tools/ + __pycache__); 377 MB fake photos in SOURCE/supabase/dev_test_photos (17 still tracked
             in git despite .gitignore); empty supabase/functions and supabase/staging; Android/web/desktop
             folders (36 MB) for an iPhone-only app - Founder decision.
Update:      26 Oct - DECIDED, DR-ZYRA-279: keep android/; remove web/, windows/, linux/, macos/.
Update:      26 Oct - Add: old-app call to the dropped function wali_has_wali_one (zyra_entitlement_service.dart);
             old Browse tables saves/passes/likes once the request model replaces them.
Owner:       Founder decides · Fable reviews and plans · Codex removes after the freeze
Acceptance:  One app; every line of code is used by it or by its tests; retired features gone from app
             and server.
Update:      29 Oct - DR-ZYRA-293 (Founder): Tiers 1, 2 and 4 and the matching tests DONE by Codex - a7b6fe3,
             6d5735c, d08b2d1, 9e903fb, 3f64e39 (pushed); retired files and pictures moved to ~/_to_delete
             (OA-ZYRA-316_* folders, about 115 MB). App code 171,658 -> 162,681 lines (342 -> 320 files, DOC-ZYRA-0284).
             Tier 3 (old member app, sign-in routes) waits for OA-ZYRA-317. Glass Signals kept (DR-ZYRA-296).

UPDATE 31 Oct (Fable): queue line 29 (600f539, 30 Oct) removed the old Guardian Dashboard, Insights and Updates
layouts from the preview; queue line 30 retired three local Code-page tests (moved to ~/_to_delete). Line 35 (all
developer toggles, DR-ZYRA-324) waits on OA-ZYRA-327.
------------------------------------------------------------

OA-ZYRA-317
Title:       Connect the planned app to real data - server support it does not have yet
Category:    Product / Database
Priority:    HIGH - the planned ZYRA cannot serve real members without it
Date:        2026-10-26
Update:      14 Nov (Fable): after the live apply, check on the iPhone that a real ZYRA code link opens the found card
             through `zyra_resolve_code_link` (line 109 tested it on throw-away only; line 117 checked sample codes).
Status:      12 Nov (Fable): new server needs from the 11 Nov LOCKs (DR-ZYRA-344/345) - QUESTIONS 83-84, 87-89, 91-92, 94-95: 10 Guardians with one Basic place, plan flag for rings, resend expired invitation, Circle past topics (no 30-day close), topic scores only for One or an Unlock, ignore Basic Nationality/Ethnicity filters, invitation knows the Basic place is used, keep crop originals and delete Storage files when a photo is removed; profile video = queue line 85. Earlier: OPEN - found in the planned-app deep review (DOC-ZYRA-0285 §4). The database lacks:
             (1) Introductions - a request to BEGIN a Journey (today: mutual like + one tap);
             (2) Preparing - both ready, places reserved for both; (3) Basic = 1 place after the £4.99
             joining fee (today: Basic gets 0, 24 Sep paid-only migration); (4) Journey Bio step;
             (5) Pause and Save removed (today: full Pause flow, saves table); (6) Request restart is
             built but switched off. Plus OA-ZYRA-315 (a)(b): identity check and both-answered rule
             enforced only in the app.
Next:        Founder confirms the membership rule (3). Fable writes one server design for 1-6 (after
             the live read-only check in OA-ZYRA-312). Codex builds after the freeze, one area at a
             time, then connects the preview screens to real data area by area.
Update:      26 Oct - (3) DECIDED, DR-ZYRA-275: Basic = 1 place after the £4.99 joining fee.
Update:      26 Oct - Three Founder questions WAITING (Founder: "ask me again later"): Q1 question stages keep
             real answers + 48-hour Family Review (A) or become "both continue" (B); Q2 request limits (5
             pending, 7-day expiry, 48 hours to get ready?); Q3 Request restart: keep 24 h wait + 30-day
             expiry, or 7-day expiry like other requests. Fable recommends A, A, B. Re-ask after the
             commits are done. Source: blueprint part 2 V2 §8.
Update:      26 Oct - Questions ANSWERED (DR-ZYRA-277): Q1 A keep real answers + 48-hour Family Review;
             Q2 A 5 pending requests, 7-day expiry, 48 hours to get ready; Q3 B restart keeps the 24-hour
             wait then 7-day expiry. Open for the design: what happens when the ready window runs out.
Update:      26 Oct - Blueprint part 4 (DOC-ZYRA-0287) adds three outside-service gaps: (7) payments - no App
             Store purchase code at all, plans set by developer functions; (8) identity check - Sumsub chosen,
             slot switched off; (9) phone push notifications - none (in-app only); also no crash reporting.
             (9) and crash reporting need Founder decisions before the design.
Update:      26 Oct - DECIDED, DR-ZYRA-278: (9) phone push notifications added; (10) privacy-safe crash
             reporting before public launch (Fable proposes providers, Founder picks).
Update:      26 Oct - DR-ZYRA-280: nine planned-app rules confirmed (requests, place-based visibility,
             reserved places, end-to-accept, Journey Bio, 3-month archive, agreed paid Guardians, Speak to
             Guardian, Introductions) - all part of this design.
Update:      26 Oct - DR-ZYRA-281: (11) Guardian limits - 5 Guardians per Seeker, 10 Seekers per Guardian,
             enforced on the server in the link request/accept functions. Guardian Basic no-chat confirmed.
Update:      26 Oct - DR-ZYRA-282: plan contents decided (Basic/One table); Guardians per Seeker by plan
             (Basic 1, One 10) replaces DR-ZYRA-281's 5; 10 Seekers per Guardian stays. Server limits for
             browsing (25 per 4 hours on Basic), requests, revisits and Guardians belong in this design.
Update:      26 Oct - From Browse rules (DOC-ZYRA-0292): (12) the app calls 4 functions no migration creates -
             hide (zyra_my_hidden_profile_ids, zyra_set_profile_hidden) and Pause My Profile
             (zyra_my_profile_pause_state, zyra_set_my_profile_pause) - "prepared, not deployed"; (13) server
             filters for age, distance, country, nationality, ethnicity; (14) Browse ranks with the legacy
             scorer, not the six approved policies (DR-ZYRA-250).
Update:      26 Oct - DR-ZYRA-283: pending requests Basic 3 / One 25 (replaces 5). Open: a past-requests
             view, what the sender sees on a decline, and re-request rules (asked 26 Oct).
Update:      26 Oct - DR-ZYRA-284: Past tab (30 days), "Not taken up" wording, 30-day wait after a decline,
             Hide also stops requests. Request questions closed.
Update:      26 Oct - Live check: production is ~2 months behind the repository - 17 files (25 Aug - 5 Oct) never
             applied, incl. shared pause, Main-Guardian hold, Circle messaging, read receipts, Browse ranking,
             trial, 5 Oct security fixes. The design starts by deciding keep / rewrite / drop for each.
Update:      26 Oct - DR-ZYRA-285: (15) account deletion detaches instead of cascading shared Journeys; (16) one
             login with Seeker and Guardian role contexts.
Owner:       Founder decides · Fable designs · Codex builds after the freeze
Acceptance:  Every planned-app screen works for real members with the server enforcing its rules.

Update 29 Oct (Founder "yes both"): Fable starts the server design now - one document for items 1-6 plus OA-315 (a)(b),
for the Founder's yes, then a brief in ZYRA/PRODUCT/APPROVED/SERVER/ and a BUILD_QUEUE line (charters rule 9).
Codex builds area by area after approval. The freeze no longer blocks it (lifted for ZYRA 29 Oct).
Update:      30 Oct (Fable, from the 29 Oct notes) - add to the server design: (a) request records - Past items now
             stay with no end date (DR-ZYRA-300); decide what the server keeps, and for how long, with the DPIA
             (OA-ZYRA-321); (b) a first-link event so the one-time Main Guardian message (B1, DR-ZYRA-294) can show
             when a first Guardian links - the preview only has Make Main; (c) the Circle consent and link-date
             check on the server (OA-ZYRA-324).
Update:      30 Oct (triage, DOC-BUG-0031) - server points folded in from closed August/September actions, for the
             server design: attempt-keyed conflicts (156), ended_by/ended_at/end_reason (158), reference codes (160),
             notification map and preferences (161, 215, 216, 231), per-attempt Guardian review and FK cascade on
             Guardian delete (162, 175-177), audit log (163), Browse paging and curation data (178, 153), Guardian
             invite expiry (232), ward activity privacy (234), Meet the Guardians threshold (240), between-stage
             checkpoints (241), post-end window (242), truthful failure states (284), surname capture (145).


Update 30 Oct 05:38: server design DRAFT written - ZYRA/REPORTS/CURRENT/ZYRA_SERVER_DESIGN_2026-10-30_V1.md
(DOC-ZYRA-0329): 10 gaps, six build areas in the Founder's order, 6 open questions. Waits for the Founder's yes;
then the ZYRA chat queues one brief per area (SERVER 0 live pass first).
APPROVED 30 Oct 11:10 (Founder, clickable "Yes, approved"): DOC-ZYRA-0329 is CURRENT with his six §6 answers (Q1 expires,
can ask again; Q2 hide both ways; Q4 paused profile keeps sent requests; Q5 the 17-file plan; Q6 Connect with Guardian
after the core). Next: the ZYRA chat queues SERVER 0 (live read-only pass), then areas 1-6 in order; Codex builds each
from its brief; Fable checks each at 04:15.
UPDATE 31 Oct (Fable): new server needs from 30 Oct decisions - (1) the Guardian summary of a shared past Journey
gains the other person's first name (DR-ZYRA-308); (2) each member's home town as a real place with its position,
approximate current area optional, distance in real km, Location = near / country / worldwide, no City filter
(DR-ZYRA-319, 320); (3) Connect with Guardian: accepted = private Guardian chat, Seekers with only a Guardian Basic
not on Network (DR-ZYRA-322; after SERVER 6, DR-ZYRA-312 Q6). SERVER 0 V2 is READY for the isolated catch-up only
(line 33; DR-ZYRA-313); live apply needs a confirmed backup and his words "apply SERVER 0 to live".
Update:      6 Nov - Fable (own action): draft list of the ten safety server functions the AIOS review page needs
             (review, warn, suspend, remove, restore on appeal, duplicate check, retention, block pattern) with
             shared audit and key rules: DOC-BUG-0043, BLACK UMBRELLA GROUP/REPORTS/CURRENT/
             ZYRA_SAFETY_SERVER_FUNCTIONS_DRAFT_2026-11-06_V1.md. Three Founder choices inside. Not a build line.
Update:      11 Nov - Fable: profile video server side (LOCK 29 V2; Founder "Fable builds the video server work" and
             clickable "App strips, server refuses (Recommended)") - brief DOC-ZYRA-0445, queue line 85, throw-away only;
             app line 84 waits for it. Live needs SERVER 0 live first, then "apply profile video to live". Reviewer
             approvals come from the AIOS review page (OA-AIOS-413).
------------------------------------------------------------

OA-ZYRA-319
Title:       Database files - message send rule lost its block/ended checks; 24 Sep and 5 Oct migrations
             cannot be replayed in order
Category:    Security / Database
Priority:    HIGH - possible safety regression; the app cannot be rebuilt from its migration files
Date:        2026-10-26
Status:      OPEN (repository only - not live, DOC-ZYRA-0294) - found by Fable reading the migrations for blueprint part 2 Messaging (DOC-ZYRA-0293 §6).
             Not run or tested yet. (1) 20260924100231 (marked "repository/staging only") replaces the
             9 Aug messages_insert rule (20260809161716, which refused blocked people, closed conversations
             and ended Journeys) with one that checks only participation and attempt_status <> 'potential'.
             (2) The same file defines zyra_attempt_participant_rows with a can_chat column; 20261005114141
             (f02) re-creates the view without it - CREATE OR REPLACE VIEW cannot drop a column, so a replay
             of all migrations in order would fail at 5 Oct. (3) The Guardian send path checks can_chat but
             not the Guardian's own paid role (DR-ZYRA-268).
Update:      26 Oct - Live check (DOC-ZYRA-0294): the live messages_insert is the SAFE 9 Aug rule; the weak 24 Sep
             file was never applied. Not a live safety issue. Still HIGH as a repository problem: replay fails
             at 5 Oct and the weak rule waits in an unapplied file.
Next:        With the Founder's GO: (a) the read-only live check (OA-ZYRA-312) shows which version is live;
             (b) a replay of all migrations on a throw-away local database proves (2). Then Fable writes the
             fix design; Codex builds it after the freeze (the safety part may justify a one-off GO earlier).
Owner:       Founder decides · Fable checks and designs · Codex builds
Acceptance:  All migrations replay cleanly in order; sending refuses blocked, closed and ended Journeys
             and unpaid Guardians, proven by tests.

------------------------------------------------------------

OA-ZYRA-320
Title:       Member terms and purchase-screen wording - written and legally reviewed before purchases open
Category:    Legal / Payments
Priority:    HIGH before purchases open (launch gate)
Date:        2026-10-26
Status:      OPEN - raised from DR-ZYRA-289. The website terms page today only says member terms are awaiting
             approval (SITE/src/pages/terms.astro); no member terms exist yet.
Scope:       (1) Paid Guardian chat is by the Seeker's permission, never guaranteed by payment (DR-ZYRA-289) -
             on the purchase screen before payment and in the terms. (2) Everything priced in DOC-ZYRA-0291:
             Basic one-off, One monthly with auto-renewal, the 14-day trial once per verified person, Family
             places, Unlocks (3 a month with Seeker One, DR-ZYRA-288). (3) The clause matrix in the legal
             research DOC-ZYRA-0148 (cooling-off, auto-renewal, Guardian notice, special-category data).
Owner:       Fable drafts · a solicitor reviews · Founder approves
Next:        After the freeze and before OA-ZYRA-317 item 7 (purchases). Needs the company formed (OA-AIOS-386)
             for the company details.
Acceptance:  Approved terms published; every purchase screen states what payment does and does not give.

Update 29 Oct (Founder "yes both"): Fable starts drafting now from the approved wording in the 29 Oct ZYRA chat
note (A1-A4, B1-B4). Company details stay as placeholders until OA-AIOS-386.
Scope added 29 Oct (ZYRA chat note (c)): the catalog text `guardianAccessTerms` in
`SOURCE/lib/data/zyra_membership_catalog.dart` is softer than DR-ZYRA-289 and says Additional Guardians start with
Chat on - replaced by the approved wording (A1-A4) at the Membership LOCK; the terms must match it.
Update 30 Oct 05:36: member terms DRAFT written - ZYRA/REPORTS/CURRENT/ZYRA_MEMBER_TERMS_DRAFT_2026-10-30_V1.md
(DOC-ZYRA-0330), A4 verbatim, B1/B4 used, B2/B3 withdrawn per DR-ZYRA-299. [DECISION NEEDED] items listed for the
Founder; then solicitor review.
Update 3 Nov (Fable, own action): clause 3.8 Phone access and location added to the draft terms
(BLACK UMBRELLA GROUP/LEGAL/ZYRA/, DOC-ZYRA-0330) from LOCK 12 V2 (DOC-ZYRA-0375); matches DPIA risk R14;
solicitor item 8. Still waiting: company details (OA-AIOS-386), ICO (OA-AIOS-381), solicitor, Founder approval.
------------------------------------------------------------


OA-ZYRA-321
Title:       Launch legal and safety pack - DPIA, safety response and Online Safety Act check, from the blueprint
Category:    Legal / Safety / Privacy
Priority:    HIGH before launch (launch gate)
Date:        2026-10-26
Status:      OPEN - opened when the Founder withdrew the 14 old drafts (OA-AIOS-404, "a"). The four legal/safety
             drafts of 6-12 Oct are research input only: REPORTS/ARCHIVE/DRAFTS_DECIDED_2026-10-26/.
Scope:       (1) DPIA for the whole member service, written from the approved blueprint (special-category
             answers, identity check, Guardians as data subjects, Main Guardian request visibility
             DR-ZYRA-292, retention). (2) Safety response: the Founder reviews reports (DR-ZYRA-287), abuse
             images, escalation, emergencies. (3) Online Safety Act / Ofcom applicability. (4) Privacy notice
             sections. Joins OA-ZYRA-320 (member terms) for one solicitor review.
Owner:       Fable drafts · a solicitor reviews · Founder approves
Next:        After the freeze; needs the company formed (OA-AIOS-386) and the ICO registration (OA-AIOS-381).
Acceptance:  Signed DPIA, approved safety procedure, recorded OSA assessment, privacy notice published.

Update 29 Oct (Founder "yes both"): Fable starts the DPIA, safety response and OSA check now, from the blueprint
(DR-ZYRA-287, 289, 292). Company and ICO details stay as placeholders until OA-AIOS-386 and OA-AIOS-381.
Update:      30 Oct (Fable) - two Founder decisions of 29 Oct for the DPIA, privacy notice and solicitor review:
             DR-ZYRA-299 (the other person is no longer told at the request that a Main Guardian sees it - only in
             a Profile section; chosen against the ZYRA chat's advice; transparency) and DR-ZYRA-300 (declined and
             expired requests kept with no time limit; storage limitation).

Update 30 Oct 05:41: DRAFTS written - DPIA (DOC-ZYRA-0331), safety response (DOC-ZYRA-0332), Online Safety Act
check (DOC-ZYRA-0333), all in ZYRA/REPORTS/CURRENT/. [DECISION NEEDED] items listed for the Founder; then solicitor
review with OA-ZYRA-320.
UPDATE 31 Oct (Fable): the DPIA and privacy notice must also cover (1) a Guardian seeing the other person's first
name and dates for a shared past Journey - that person never agreed (DR-ZYRA-308); (2) approximate location and
distance filtering (DR-ZYRA-319, 320, 321), stored only after the DPIA; (3) GeoNames place data (CC-BY 4.0 -
attribution in the app's licences page) if used.
DONE 31 Oct (Fable, own action): DPIA draft DOC-ZYRA-0331 gains R13 (first name of a shared past Journey) and R14
(location) with measures; solicitor question added for R13.
DONE 4 Nov (Fable, own action): safety response DOC-ZYRA-0332 checked against all six DOC-ZYRA-0297 §6 items - adds §5a member
removal process (10 steps), notices A-D, §12 rows 8-10; finding: no server function to suspend/disable/remove a member
(for OA-ZYRA-317 / OA-AIOS-413). Founder to decide: re-joining after removal permanent or a set period.
------------------------------------------------------------

OA-ZYRA-323
Title:       Codex's native iOS build route is held - phone and simulator builds and captures cannot run
Category:    Build tooling / Release
Priority:    HIGH - iPad and iPhone SE pictures (DR-ZYRA-297), phone checks and any TestFlight build depend on it
Date:        2026-10-30
Status:      UPDATED 1 Nov (Fable): the Founder's one-time PROFILE install ran 1 Nov 00:03 (queue line 72, 83dcb15, DR-ZYRA-339) and is used up. Founder, 31 Oct: repair the protected install route before 21 Nov (he is abroad 21 Nov - 14 Dec, OA-AIOS-420). Deadline 20 Nov. Was: OPEN - from the 29 Oct ZYRA chat note (items l, n) and Codex tasks 6-24: the native route is "HELD" by
             a SwiftPM nested-sandbox refusal in Codex's no_git_driver.mjs; on 29 Oct the paired iPhone 15 Pro Max
             was disconnected and no matching simulator existed. Codex captured with the visual-test render
             instead (430x932 @3x, no native status bar) and, rightly, did not install, bypass or create a
             simulator without authority (task 6).
Owner:       Codex finds the cause and proposes the smallest safe fix · Founder approves · Fable checks
Next:        Codex says in his next report what exactly is held and what he needs (including whether iPhone SE and
             iPad simulators must be created); the Founder says yes or no.
Acceptance:  Codex builds and captures on the simulator (iPhone SE, iPhone 15 Pro Max, iPad) and on the phone with
             no sandbox bypass; the route is written in DOC-ZYRA-0288.

UPDATE 31 Oct (Fable): two one-time Founder exceptions on 30 Oct - "Allow this one profile install" (Codex Task 12,
iPhone update; he confirmed "It responds normally") and "Allow one PROFILE install and capture (Recommended)" (Task
19, Filters keyboard pictures). Both consumed; the hold stays. Release checklist must carry the iPhone purpose texts
for Location, Camera, Photos and Face ID (LOCK 12 V2 spec) and new-colour App Store pictures (LOCK 14).
------------------------------------------------------------

OA-ZYRA-324
Title:       Guardian Circle shows past Journey summaries with sharing off and from before the Guardian linked -
             fix in the preview, then check the server and the old member app
Category:    Privacy / Guardians
Priority:    HIGH - breaks DR-ZYRA-233 (past Journey summaries only with the Seeker's consent)
Date:        2026-10-30
Status:      OPEN - found by Codex in the LOCK 3 preflight (queue line 7, 29 Oct; ZYRA/REPORTS/EVIDENCE/
             LOCK3_GUARDIAN_INFO_2026-10-29/): in the Founder preview Hassan (linked 20 Sep) sees topics from
             Hafsa's Journey that ended 10 Sep, with "Share past Journey summaries" off; the resolver gives 12 past
             topics with no consent or link-date check. Line 13's fix failed because it still showed named topics
             (DR-ZYRA-233 item 4 allows only anonymous facts). The server and the members' old app are not
             checked yet (ZYRA chat item cc).
Owner:       ZYRA chat corrects the LOCK 3 spec and queues it · Codex builds · Fable checks the server functions and
             the old app read-only
Next:        (1) ZYRA chat: corrected spec §3b and a new queue line. (2) Fable: read-only check of the server's
             Circle/archive functions and the old app's Circle screen; result added here.
Acceptance:  No Guardian sees a past Journey summary without the Seeker's consent or from before the link - in the
             preview, on the server and in the old app - with tests that prove it.
Update:      30 Oct (Fable, step 2 done, read-only): (a) the members' old app offers past-Journey topics in the Circle
             only in preview mode (family_messaging_screens.dart: topic options need preview data) and calls no archive
             function - no leak there. (b) Server, as written in the repo: zyra_attempt_summary_for_guardian (18 Sep, oa291)
             gives a Guardian four anonymous fields only, and ended Journeys only from the current link period unless the
             Seeker switched history on for that link - matches DR-ZYRA-233; the 5 Oct f02 "Guardian read boundary" also
             stops ended Journeys giving any detail. (c) Production: the live check (DOC-ZYRA-0294) lists f02 as never
             applied, so production lacks that boundary - part of OA-ZYRA-317's catch-up (Founder's GO). Left: step 1.

UPDATE 31 Oct (Fable): preview part DONE - queue line 18 (abb446f, 30 Oct): Guardian Circle past topics and archives
need that Guardian's sharing switch, show first names and dates only (DR-ZYRA-308), disappear when sharing is off;
removed links lose consent. Production boundary remains part of OA-ZYRA-317.
------------------------------------------------------------

OA-ZYRA-325
Title:       Founder-preview defects found by the ZYRA chat on 29 Oct
Category:    Product / Planned app
Priority:    MEDIUM - the Founder sees them now; members would after launch
Date:        2026-10-30
Status:      OPEN - from the 29 Oct ZYRA chat note (items v, w, x, y, dd and the 18:30 baseline finding):
             1. Preview my profile shows "Request a Journey" and the Profiles tab bar on the member's own profile.
             2. Edit profile shows Gender "Brother" (a Guardian relationship word, not a gender).
             3. Overall compatibility shows "Demo Guardian · Father" instead of the Seeker's Main Guardian.
             4. Guardian My ZYRA is titled "Guardian Dashboard" and still shows Insights (scrapped, DR-ZYRA-306) -
                covered by LOCK 8 once built.
             5. Privacy & data and Pause My Profile show developer text to members ("Founder input needed before
                launch", "No server setting is read or changed").
             6. Privacy & data renders on a light background, unlike the rest of the app.
Owner:       ZYRA chat designs each fix (a LOCK or a Founder-named line in BUILD_QUEUE.md) · Codex builds · Fable files
Next:        ZYRA chat queues the fixes; item 4 goes with LOCK 8 (queue line 17).
Acceptance:  Each item fixed in the preview and checked by the ZYRA chat against a new baseline picture.

UPDATE 31 Oct (Fable): the Guardian Dashboard title and Insights are gone from the preview (queue line 29, 30 Oct);
remaining items wait for the ZYRA chat's build checks (OA-ZYRA-328).
UPDATE 5 Nov (Fable): Codex used this ID for queue lines 44 (developer controls removed, ff49601/e565a2a) and 73
(test cleanup, df8cfbe/bb2fe54/05243a8), both BUILT 4 Nov under DR-ZYRA-341; item 5 (developer text) should be gone with
line 44 - ZYRA chat to confirm in its build check. Remaining test failures: OA-ZYRA-348.
------------------------------------------------------------

OA-ZYRA-331
Title:       Next baseline capture - add the missing states
Category:    Baseline pictures
Priority:    LOW
Date:        2026-10-31
Status:      OPEN - from the ZYRA chat's 30 Oct note (z, 08:40 and 09:20): the Browse Hide confirmation and the Green
             / Yellow / Red preference pages have no real screenshot, so the prototype draws them from code (lesson
             S21). The Compatibility pages 2-7 likewise.
Owner:       ZYRA chat (capture brief and queue line) · Codex captures
Next:        ZYRA chat: add these states to the next capture brief.
Acceptance:  Each state has a baseline picture; the prototype uses it.
------------------------------------------------------------

OA-ZYRA-332
Title:       Two nationalities both labelled "Dominican" in the reference list
Category:    Data / Onboarding
Priority:    LOW
Date:        2026-10-31
Status:      OPEN - from the ZYRA chat's 30 Oct note (nn2). SOURCE/lib/data/zyra_reference_data.dart lines 109-110:
             Dominica and Dominican Republic both have the nationality word "Dominican" (correct in English). The new
             Filters shows the country in brackets (zyra_browse_filter.dart line 75); the sign-up nationality picker
             (onboarding chapter 2) was not checked.
Owner:       ZYRA chat checks the sign-up picker against a screenshot · Codex fixes only if a LOCK or Founder-named
             brief says so
Next:        ZYRA chat: look at the sign-up nationality picker.
Acceptance:  A member can tell the two apart wherever nationality is chosen or shown.
------------------------------------------------------------

OA-ZYRA-333
Title:       Adverts for Basic members - later, when the app is near finished
Category:    Monetisation / Basic plans
Priority:    LOW - not before the app is near finished
Date:        2026-11-01
Status:      OPEN - LATER. Founder, 31 Oct 06:57 (ZYRA chat): "i want added to oa but we wont do yet but when we get
             to section or clsoer to app finiashed is setting up adverts for basic users and a tour of app for first
             time users". No design or queue line yet.
Owner:       ZYRA chat proposes when the app is near finished · Founder decides
Next:        Nothing now; raise when the app is near finished.
Acceptance:  An approved advert design for Seeker and Guardian Basic, LOCKed and queued.
------------------------------------------------------------

OA-ZYRA-334
Title:       First-time app tour for new members - later, when the app is near finished
Category:    Onboarding
Priority:    LOW - not before the app is near finished
Date:        2026-11-01
Status:      OPEN - LATER. Same Founder words as OA-ZYRA-333 (31 Oct 06:57, ZYRA chat).
Owner:       ZYRA chat proposes when the app is near finished · Founder decides
Next:        Nothing now; raise when the app is near finished.
Acceptance:  An approved first-time tour, LOCKed and queued.
------------------------------------------------------------

OA-ZYRA-336
Title:       Preview sample data disagrees between the Seeker and Guardian views
Category:    Founder preview / sample data
Priority:    LOW
Date:        2026-11-01
Status:      UPDATED 2 Nov (Fable): 1 Nov check item (d) - the build d02 now shows Sara 'Stage 1 of 8 · Salam
             Exchange · Your turn: send Salam' while master j02/d02, the prototype and the Guardian side show Stage 4
             Family Review, 41 hours left. Question 8 was answered 1 Nov (line 56 BUILT); the Seeker sample is still
             not aligned. Was: OPEN - ZYRA chat morning check 31 Oct, item (b): the Seeker Journey tab shows Sara 'Your turn: answer
             Faith & Values' while the Guardian's My ZYRA and Journeys show Adam & Sara in Family Review, 41 hours
             left; master j02 shows Family Review. QUESTIONS.md row 8 (line 56) raises the same sample conflict.
Owner:       ZYRA chat writes the sample rule into a brief · Codex aligns the preview
Next:        ZYRA chat: answer QUESTIONS.md row 8 with one shared sample.
Acceptance:  Both views show the same Journey state.
------------------------------------------------------------

OA-ZYRA-337
Title:       Settings still lists 'Pause My Profile' though Pause is retired for ZYRA
Category:    Product rules / Settings
Priority:    MEDIUM - app, masters and prototype contradict DR-ZYRA-274
Date:        2026-11-01
Status:      OPEN - ZYRA chat morning check 31 Oct, item (f): Settings shows 'Pause My Profile' in the app, the LOCK
             12 masters and the prototype, but DR-ZYRA-274 retired Pause. Needs a decision: remove the row, or record
             an exception.
Owner:       ZYRA chat shows the choice · Founder decides
Next:        ZYRA chat: one clickable question to Shakeel.
Acceptance:  The row removed (LOCK + queue line) or an exception filed as a decision.
------------------------------------------------------------

OA-ZYRA-338
Title:       Masters to redraw at the next change of their feature
Category:    Design records
Priority:    LOW
Date:        2026-11-01
Status:      UPDATED 2 Nov (Fable): add 1 Nov check item (b) - LOCK 19 and LOCK 18 masters draw the bottom pill
             label gold; the app shows it in ink everywhere (line 71 rule); the prototype now follows the app (V138).
             Was: OPEN - ZYRA chat morning check 31 Oct, items (c), (d), (e), (h): LOCK 12 master has a centred Settings
             title (app left-aligned); LOCK 10 Country row grey 'Change' + arrow (app gold 'Change ›'); LOCK 8
             masters draw a different Network/Introductions icon (app uses the spec's 'group' icon); LOCK 3 masters
             keep '‹ Back' and retired Profile rows. In each case the app is right and the BUILT pictures are the
             reference.
Owner:       ZYRA chat
Next:        ZYRA chat: redraw each master when its feature next changes.
Acceptance:  Masters match the built app.
------------------------------------------------------------

OA-ZYRA-341
Title:       Main Guardian card built without its gold outline (LOCK 19 V2)
Category:    Build fidelity / charters rule 8
Priority:    MEDIUM - a LOCKed detail missing from the build
Date:        2026-11-02
Status:      OPEN - ZYRA chat 1 Nov 05:41 check of line 48, item (a): masters k01, k02, k03, k17, k18 draw the Main
             Guardian (Hassan) card with a gold border; the built cards have the plain border. LOCK 19 V2 and LOCK 14
             V5 ("gold borders stay gold") apply; the prototype keeps gold.
Owner:       ZYRA chat writes a fix line (LOCKed already) · Codex builds
Next:        ZYRA chat: one fix-to-match-masters line in BUILD_QUEUE.md naming k01-k03, k17, k18.
Acceptance:  BUILT pictures show the gold outline on the Main Guardian card; chat note says MATCH.
------------------------------------------------------------

OA-ZYRA-342
Title:       Line 48 ZYRA Family sheets sit higher than the masters; price sheet splits "Now"
Category:    Build fidelity / charters rule 8
Priority:    LOW
Date:        2026-11-02
Status:      OPEN - ZYRA chat 1 Nov 05:41 check of line 48, item (c): built ZYRA Family sheets sit about 30 pt higher,
             and the price sheet puts "Now" in its own row above the "New" card (masters: one card). Words and buttons
             match.
Owner:       ZYRA chat (fix line, or record that the build is right and redraw) · Codex
Next:        ZYRA chat: decide at the next Guardian card change.
Acceptance:  Build and masters agree.
------------------------------------------------------------

OA-ZYRA-343
Title:       Shared floating shadow is a hard grey slab, masters show a soft shadow on ivory
Category:    Build fidelity / charters rule 8
Priority:    MEDIUM - app-wide
Date:        2026-11-03
Status:      OPEN - ZYRA chat 2 Nov 05:42 build check (2026-11-02_ZYRA_CHAT_NOTE.md), item (a): under the Guardian Journeys and Ended Journeys cards, the "for Adam" pill, the tab bar,
             the Seeker-page cards and the Sent/Received switch the app draws a solid grey offset band about 10 pt
             deep; LOCK 14 V5 masters show a soft "floating look". Comes from the shared widget (Codex QA recorded it
             as shared styling it was not allowed to change).
Owner:       ZYRA chat (fix line from the LOCK, or record the build as right) · Codex builds
Next:        ZYRA chat: queue one fix line for the shared shadow from LOCK 14 V5.
Acceptance:  Built shadow matches the LOCK 14 V5 masters app-wide.
------------------------------------------------------------

OA-ZYRA-344
Title:       Icons drawn filled in the app; masters use outline icons
Category:    Build fidelity / charters rule 8
Priority:    MEDIUM - app-wide
Date:        2026-11-03
Status:      OPEN - ZYRA chat 2 Nov 05:42 build check (2026-11-02_ZYRA_CHAT_NOTE.md), item (b): tab bar (Network, Journey, My ZYRA, Guardian, Profile), empty-state icons and the Ended
             Journeys clock are filled; masters are outline.
Owner:       ZYRA chat (fix line from the LOCK, or record the build as right) · Codex builds · Founder if a choice
Next:        ZYRA chat: same fix line as OA-ZYRA-343, or ask Shakeel which style stays.
Acceptance:  Icons match the masters.
------------------------------------------------------------

OA-ZYRA-345
Title:       Settings cards grey-beige and footer letter-spaced (line 62)
Category:    Build fidelity / charters rule 8
Priority:    LOW
Date:        2026-11-03
Status:      OPEN - ZYRA chat 2 Nov 05:42 build check (2026-11-02_ZYRA_CHAT_NOTE.md), item (c): s01/s02 cards are a flat grey-beige fill, masters ivory cards with a soft shadow;
             footer reads "Z Y R A", master "ZYRA".
Owner:       ZYRA chat (fix line from the LOCK, or record the build as right) · Codex builds
Next:        ZYRA chat: include in the OA-ZYRA-343 fix line.
Acceptance:  Settings matches LOCK 22 V4 masters.
------------------------------------------------------------

OA-ZYRA-346
Title:       Guardian Journeys photo card about 24 pt shorter than the g09 masters (line 56)
Category:    Build fidelity / charters rule 8
Priority:    LOW
Date:        2026-11-03
Status:      OPEN - ZYRA chat 2 Nov 05:42 build check (2026-11-02_ZYRA_CHAT_NOTE.md), item (d): the Ended Journeys card therefore sits higher.
Owner:       ZYRA chat (fix line from the LOCK, or record the build as right) · Codex builds
Next:        ZYRA chat: decide at the next Guardian tabs change.
Acceptance:  Card height matches g09 masters.
------------------------------------------------------------

OA-ZYRA-347
Title:       Network first-card back arrow looks disabled (line 63)
Category:    Build fidelity / charters rule 8
Priority:    LOW
Date:        2026-11-03
Status:      OPEN - ZYRA chat 2 Nov 05:42 build check (2026-11-02_ZYRA_CHAT_NOTE.md), item (e): the ‹ arrow at the first card is transparent in the build; master shows a light round button.
Owner:       ZYRA chat (fix line from the LOCK, or record the build as right) · Codex builds
Next:        ZYRA chat: decide at the next Network change.
Acceptance:  Arrow matches the g06 master.
------------------------------------------------------------

OA-ZYRA-348
Title:       358 app tests still fail after lines 44 and 73 - 43 OPEN questions (rows 13-55) need sorting
Category:    Quality / Tests
Priority:    MEDIUM - the "Test baseline and final interface pass" ROADMAP row and its GitHub issue stay open until 0
Date:        2026-11-05
Status:      OPEN - Codex 4 Nov (line 73, bb2fe54): 649 -> 644 (line 44) -> 358 failures in 36 files; every case has a
             reason in TEST_CLEANUP/BUILT/QUEUE73_CLASSIFICATION.json and an OPEN row in PRODUCT/APPROVED/QUESTIONS.md
             (13-55): current app defects, Tier 3 contract gaps, old fixture lineage, and 112 visual cases waiting for
             exact current masters and designer build checks.
Owner:       ZYRA chat answers each row from LOCKs / specs (or marks it for the Founder) · Founder decides any app fix
             while ZYRA design is paused (AD-AIOS-123) · Codex builds · Fable files
Next:        ZYRA chat: sort rows 13-55 into "answer from a LOCK", "app fix (needs Founder GO after the pause)" and
             "retire"; one bundled question to Shakeel, not 43.
Acceptance:  Rows 13-55 ANSWERED or WITHDRAWN; failures at 0 or each remaining one tied to an approved fix line.
             11 Nov (Fable): the ZYRA chat answered rows 13-55 on 10 Nov (row 21 by the Founder: "Deeper red #AC453E (Recommended)", DR-ZYRA-343). Line 75 BUILT 10 Nov (f32dd47, 32fd666; Q59 b052b26, f4b70c9): 358 -> 39 failures, 6,972 pass. Ten new OPEN rows 61-70 (scoped app fixes or reference choices) - ZYRA chat to answer by 12 Nov (2 days). ROADMAP row stays open.
             14 Nov (Fable, Codex line 109 report): full Flutter run at d3d67bf found one more failing test, not caused by line 109 - guardian_circle_discussion_bubble_test.dart:668 expects the literal `!current()` but the committed Guardian Circle code uses `!foreground()`. Carried into line 111: decide from the current code (LOCK 20 V4) whether the test or the code is out of date, fix that one, write the reason.
------------------------------------------------------------

OA-ZYRA-349
Title:       Line 44 build check: Guardian Settings has no LOCK master (paired with the Seeker Settings master)
Category:    Build fidelity / charters rule 8
Priority:    LOW
Date:        2026-11-05
Status:      OPEN - ZYRA chat 5 Nov 13:28 build check (2026-11-05_ZYRA_CHAT_NOTE.md), item (a): DEV_TOGGLES/BUILT/
             MASTER_BUILD_PAIRS guardian_settings was compared with Seeker master s01.
Owner:       ZYRA chat (add a Guardian Settings master, or record that LOCK 22 V4 covers both roles)
Next:        ZYRA chat, when ZYRA design restarts (AD-AIOS-123).
Acceptance:  Guardian Settings has its own master or a written note that s01 covers it.
------------------------------------------------------------

OA-ZYRA-350
Title:       Line 44 build check: seeker_one_browse pair compares two different states
Category:    Build fidelity / charters rule 8
Priority:    LOW
Date:        2026-11-05
Status:      OPEN - ZYRA chat 5 Nov build check, item (b): master shows "Request sent", capture shows "Request a Journey".
Owner:       Codex (recapture in the master's state) · ZYRA chat checks
Next:        With the next ZYRA fix line allowed after the pause.
Acceptance:  Pair shows the same state and the ZYRA chat records MATCH or the differences.
------------------------------------------------------------

OA-ZYRA-351
Title:       56 LOCK masters moved out by group line 30 must be re-rendered with placeholder photos (restart task)
Category:    Build fidelity / public repo (AD-AIOS-121, AD-AIOS-137)
Priority:    MEDIUM - no build check of these LOCKs can compare master and build until it is done
Date:        2026-11-11
Status:      OPEN - ZYRA chat note 10 Nov 05:39 item (a): after line 30 the MASTERS folders of APP_COLOURS, GUARDIAN_CARD,
             GUARDIAN_CIRCLE, GUARDIAN_TABS, JOURNEY_BLOCK_HIDE, JOURNEY_TAB, PAGE_DOTS, PROFILE_TAB, REQUESTS_AND_GUARDIANS,
             TAB_BAR and UNITY_PASS miss the 56 pictures moved to the private LEGAL folder (list in PICTURE_CLASSIFICATION.tsv);
             201 BUILT pictures likewise. ZYRA restarted 10 Nov (DR-ZYRA-342), so this is now due.
Owner:       ZYRA chat (re-render the masters with placeholder photos) · Codex (recapture BUILT on a queue line) · Fable (check)
Next:        ZYRA chat: one queue line after line 76, on Shakeel's GO.
Acceptance:  Every LOCK with moved pictures has masters and BUILT pairs again, none showing unproven sample photos.
------------------------------------------------------------

OA-ZYRA-352
Title:       Blueprint pages to match DR-ZYRA-344/345 (plans, Guardians per Seeker, Circle past topics, filters by plan)
Category:    Blueprint upkeep (standard §4b.3)
Priority:    MEDIUM - the blueprint is CURRENT; it now disagrees with the Founder's 11 Nov decisions
Date:        2026-11-12
Status:      IN PROGRESS - 12 Nov: MEMBERSHIP V2 done (V1 archived by rename to REPORTS/ARCHIVE/PRODUCT_BLUEPRINT_VERSIONS/). Left: JOURNEY, BROWSE, TRACE, GUARDIAN_RULES. Pages named by the ZYRA chat: MEMBERSHIP V1 §6 + line 31 + §8 Q1 (Basic sends 5, Basic may end a Journey,
             10 Guardians with one Guardian Basic place for Seeker Basic, One extras, Guardian One trial and ring), JOURNEY V2
             line 62, BROWSE V2 lines 89/103 (Nationality and Ethnicity filters = Seeker One), TRACE line 32, GUARDIAN_RULES
             V4 §6 (30-day past-topics rule replaced by LOCK 20 V3).
Owner:       Fable
Next:        Fable: update each page in a new version (archive the old by rename), quoting DR-ZYRA-344/345.
Acceptance:  No blueprint page contradicts DR-ZYRA-344/345.
------------------------------------------------------------

OA-ZYRA-354
Title:       Line 84 fresh native host (profile video trim and sound removal) deferred to after 14 Dec
Category:    Delivery / iPhone route (OA-AIOS-420)
Priority:    MEDIUM - the profile video cannot reach the iPhone until a fresh native host is built
Date:        2026-11-12
Status:      CLOSED 14 Nov - Founder un-deferred line 84 (DR-ZYRA-352): one online fetch of the pinned Swift packages
             approved; line 84 PRIORITY. History: QUESTIONS 110 (Fable 10:50): no supported way on the Mac to deny outbound traffic for one native
             Xcode run while SwiftPM keeps its manifest sandbox (nested sandbox refused; PF and filter extensions need a
             system change or an install - both forbidden). Line 84 WAITING, "do not start before 15 Dec 2026".
             Kept: verified GoogleUtilities 8.1.3 tree (114 files, 688,051 B) and the Q108 build-only workspace plan.
Next:        15 Dec - Fable re-checks for a supported outbound boundary; if none, asks Shakeel (clickable) to approve one
             named small download or another route. Then line 84 runs from step 0.
Owner:       Fable (route) · Shakeel (approval if a download is needed) · Codex (build)
Acceptance:  Fresh signed Profile host verified offline; line 84 BUILT; phone install on Shakeel's GO.
Update:      12 Nov - Founder confirmed (clickable): "Keep it deferred (Recommended)" - no one-time exception.
------------------------------------------------------------


OA-ZYRA-355
Title:       Design ZYRA's emails in one session with the ZYRA chat; weekly reminder to Shakeel until then
Category:    Product / emails (DR-ZYRA-348)
Priority:    LOW - no member email goes out before launch
Date:        2026-11-13
Status:      OPEN - Founder 12 Nov 17:09: "we will talk about email later ... just remind me as again every. 7 days".
             List: PRODUCT/APPROVED/EMAILS/RECORD/EMAIL_LIST_CURRENT_VERSION_V1.md (welcome, you subscribed, subscription
             ending, sorry to see you go, the five LOCK 32 inactivity emails, recovery). The ZYRA chat asked Fable to set a
             7-day reminder (first Thu 19 Nov); the 04:15 task does not create schedules on its own - asked Shakeel 13 Nov.
Owner:       Shakeel (session, yes to the reminder) · ZYRA chat (design) · Fable (reminder)
Next:        Shakeel: yes to the weekly reminder; then Fable creates it and switches it off after the email session.
Acceptance:  Every listed email designed and LOCKed; reminder switched off.
------------------------------------------------------------

OA-ZYRA-356
Title:       ZYRA queue tidy: two lines numbered 100; lines 93 and 97 marked QUESTION with no OPEN row; Fable rows 88-89
Category:    Design loop (charters rules 9-10)
Priority:    MEDIUM
Date:        2026-11-13
Status:      OPEN - 13 Nov 04:15: BUILD_QUEUE has two "100" lines (Fable's name-limit server line and the ZYRA chat's
             My ZYRA title fix, both BUILT). Lines 93 and 97 are QUESTION but their rows (132, 133, 136) are ANSWERED -
             the app side is BUILT and on the iPhone; only the live server apply waits (OA-ZYRA-317). QUESTIONS 88 and 89
             (Fable, server contracts, 11 Nov) are still OPEN - 2 days.
Owner:       ZYRA chat (renumber, status) · Fable (rows 88-89)
Next:        ZYRA chat: renumber the second 100 as the next free line and point its note at it; mark 93 and 97 BUILT with
             "live server apply waits for OA-ZYRA-317" (or reopen a row). Fable: answer rows 88-89.
Acceptance:  Unique line numbers; every QUESTION line has an OPEN row; rows 88-89 ANSWERED.
------------------------------------------------------------


OA-ZYRA-357
Title:       F-01 BUILT meant preview only - 75 BUILT lines, no server link in the planned app
Category:    ZYRA audit finding
Priority:    CRITICAL
Date:        2026-11-13
Status:      IN PROGRESS - 13 Nov Fable (Q4): queue rule added - BUILT = Preview; server and wiring lines carry "Live:
             no" until the Founder applies them. Wiring plan (P0-3) not started.
Owner:       Fable (states, wiring plan with the ZYRA chat); Founder decides
Next:        Fable + ZYRA chat: wiring plan - order of screens and a server contract for each (after line 110).
Acceptance:  Every BUILT server line shows Live yes/no; a wiring plan exists and is approved.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-358
Title:       F-02 Live server is 33 updates behind the repository
Category:    ZYRA audit finding
Priority:    HIGH
Date:        2026-11-13
Status:      OPEN - queue line 110 (DOC-ZYRA-0507, clean production server, Founder "Yes, clean new server").
Owner:       Founder approves live; Codex prepares
Next:        Codex builds line 110 on throw-away databases; live step only on the Founder's own words.
Acceptance:  Production project built from the repository; each server line records applied live.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-359
Title:       F-03 5 October security fixes are not live
Category:    ZYRA audit finding
Priority:    HIGH
Date:        2026-11-13
Status:      OPEN - inside line 110; run the 64 existing server tests on the new project first.
Owner:       Codex
Next:        With line 110.
Acceptance:  Server tests pass on the new production project.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-360
Title:       F-04 Test shortcuts and 149 shared-password test accounts reachable on the live project
Category:    ZYRA audit finding
Priority:    HIGH
Date:        2026-11-13
Status:      OPEN - line 110 removes shortcuts, test tables and accounts from production. Founder to-do (OA-AIOS-446):
             Supabase Confirm email ON; two-step sign-in on Supabase, GitHub, Apple, Cloudflare and Google (audit Q1).
Owner:       Founder; Codex
Next:        Founder: the two settings checks. Codex: line 110.
Acceptance:  No test back door on production; both settings confirmed by the Founder.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-361
Title:       F-05 Account deletion leaves photos and erases reports
Category:    ZYRA audit finding
Priority:    HIGH
Date:        2026-11-13
Status:      OPEN - inside line 110 plus a deletion test on the lab with an account that has Journeys.
Owner:       Codex
Next:        With line 110.
Acceptance:  Deletion matches the Profile rules; test recorded.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-362
Title:       F-06 Free plan, no backups
Category:    ZYRA audit finding
Priority:    CRITICAL
Date:        2026-11-13
Status:      OPEN - Founder 13 Nov decision (3): paid plan before the first real member.
Owner:       Founder (cost); Fable (recovery page)
Next:        Before the first real member: paid plan on production, one restore drill, one page of recovery steps
             (Fable).
Acceptance:  Daily backups on; one restore drill recorded; recovery page filed.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-363
Title:       F-07 No scheduler or email sender - five locked time rules need a clock
Category:    ZYRA audit finding
Priority:    HIGH
Date:        2026-11-13
Status:      OPEN - design now, build after connect (AD-AIOS-149 fixes only).
Owner:       Fable (Jobs spec); Founder (email service)
Next:        Fable: one Jobs spec - each job, how often, what happens on failure, run log. Founder: choose the email
             service (with OA-ZYRA-355).
Acceptance:  Jobs spec approved; scheduler and email service chosen.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-364
Title:       F-08 No purchase system
Category:    ZYRA audit finding
Priority:    HIGH
Date:        2026-11-13
Status:      OPEN - waits the Founder's route decision (Apple direct or a purchases service).
Owner:       Founder; ZYRA chat (spec); Codex
Next:        Purchases spec first (products, trial, restore, refunds, server receipt check, renewal reminders), after
             wiring.
Acceptance:  Purchases spec approved and built on Apple's system.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-365
Title:       F-09 Terms and privacy pack thin for launch
Category:    ZYRA audit finding
Priority:    HIGH
Date:        2026-11-13
Status:      OPEN - start now; longest wait.
Owner:       Founder
Next:        Founder sends the adviser the section 7 checklist (audit Q2).
Acceptance:  Adviser review under way; pages updated from it.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-366
Title:       F-10 No crash reporting; 248 swallowed errors
Category:    ZYRA audit finding
Priority:    HIGH
Date:        2026-11-13
Status:      OPEN - before outside testers.
Owner:       Founder decides; Codex
Next:        Founder: Europe-hosted crash reporting with no personal data, or Apple's own reports for a first small
             group.
Acceptance:  Crash reports reach the Founder; weekly review set.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-367
Title:       F-11 No automatic checks; 37 failing tests
Category:    ZYRA audit finding
Priority:    HIGH
Date:        2026-11-13
Status:      OPEN - queue line 111 (DOC-ZYRA-0508), not before 21 Nov.
Owner:       Codex
Next:        Line 111.
Acceptance:  Zero failures; checks run on every push; red means not BUILT.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-368
Title:       F-12 Two apps tangled; planned app inside the dev folder
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      DEFERRED - after the first wired flows.
Owner:       Codex
Next:        Move the planned app out of the dev folder, then remove old screens and tests feature by feature.
Acceptance:  One app.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-369
Title:       F-13 Very large files
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      OPEN - rule as you go.
Owner:       Codex
Next:        Rule: no file over 1,500 lines; split a file when next touched; one shared pattern for server data during
             wiring.
Acceptance:  No new file over 1,500 lines.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-370
Title:       F-14 Design values hand-typed
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      OPEN - after connect.
Owner:       ZYRA chat (spec); Codex
Next:        Spacing and colour tokens for the planned app; a check that fails on new hand-typed colours.
Acceptance:  Tokens in use; check in place.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-371
Title:       F-15 Text contrast below minimums (probable)
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      OPEN - Founder 13 Nov "Show me options first (Recommended)" (DR-ZYRA-350).
Owner:       ZYRA chat; Founder decides
Next:        ZYRA chat shows options in the prototype: body text 4.5 to 1, darker gold for gold text, dark text on
             gold buttons, no thin lettering under 16 pt.
Acceptance:  Founder choice recorded and built.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-372
Title:       F-16 Few end-to-end tests
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      DEFERRED - with wiring.
Owner:       Codex
Next:        Five end-to-end tests on the lab server: sign-up, request to accept, Guardian link, delete account,
             sandbox purchase.
Acceptance:  Five flows proven.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-373
Title:       F-17 Registers too large to read or load
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      IN PROGRESS - 13 Nov Fable (Q6): 266 closed actions moved whole to
             ARCHIVE/OUTSTANDING_ACTIONS_V2_CLOSED.md; register 1.5 MB to 267 KB. Decisions register kept (only 4
             superseded entries). Left: README status as a dated table; CURRENT_VERSION file names (C-9) - 90 files
             point at the current names.
Owner:       Fable
Next:        README dated status table; rename with a reference update when the Founder agrees.
Acceptance:  Open-only register; README status table; names follow the version rule.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-374
Title:       F-18 Heavy repository history
Category:    ZYRA audit finding
Priority:    LOW
Date:        2026-11-13
Status:      DEFERRED - rule only.
Owner:       Fable
Next:        Rule: no new pictures or evidence in the code repository.
Acceptance:  Rule recorded.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-375
Title:       F-19 Public source: ids and a default tester password visible; open licence
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      OPEN - (a) remove default tester details, pass them in at build time (audit Q3, Codex, needs a queue line
             from the ZYRA chat). (b) licence: Founder 13 Nov "All rights reserved from now (Recommended)", DR-ZYRA-350; repositories to
             private is a Founder to-do (OA-AIOS-446).
Owner:       Codex (a); Founder (b)
Next:        (a) ZYRA chat queues Q3. (b) Founder answer.
Acceptance:  No tester details in source; licence decision recorded.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-376
Title:       F-20 Supabase checker items
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      OPEN - with line 110.
Owner:       Codex
Next:        On production: no test tables, the view respects row rules, leaked-password check on (may need the paid
             plan), remove permissions from functions the app never calls.
Acceptance:  Clean checker report on production.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-377
Title:       F-21 Out-of-date statements (audit section 4)
Category:    ZYRA audit finding
Priority:    LOW
Date:        2026-11-13
Status:      IN PROGRESS - 13 Nov Fable (Q5): README developer panel, roadmap test count and server estimate, agent
             rules (old app still opens for members), DR-ZYRA-277 restart expiry note, LOCK 27 against DR-ZYRA-250
             (already reconciled in LOCK 27 V3), queue line 100 (one line now). Left: C-7 Circle spec header (ZYRA
             chat), C-11 and C-12 code wording (Codex, with F-22), C-6 (line 99).
Owner:       Fable; ZYRA chat; Codex
Next:        ZYRA chat: C-7 header. Codex: C-11, C-12 with F-22.
Acceptance:  Each section 4 row corrected or owned.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-378
Title:       F-22 Store items missing
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      OPEN - before the first outside test build.
Owner:       Codex
Next:        Store checklist: privacy declaration file, push decision, link-opening setup, remove unused location
             permission wording (C-11), project description (C-12).
Acceptance:  Checklist complete.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-379
Title:       F-23 Android not prepared
Category:    ZYRA audit finding
Priority:    LOW
Date:        2026-11-13
Status:      DEFERRED - Founder 13 Nov "iPhone first (Recommended)" (DR-ZYRA-350); Android after launch.
Owner:       Founder
Next:        Record the decision; prepare Android after launch.
Acceptance:  Decision recorded.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-380
Title:       F-24 No admin tool or audit log
Category:    ZYRA audit finding
Priority:    HIGH
Date:        2026-11-13
Status:      OPEN - scheduled.
Owner:       Fable; Founder
Next:        Fable: written procedure and saved queries for reports, holds, deletion and data requests. Later a small
             private admin page with its own role and log.
Acceptance:  Founder can act on a report the same day.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-381
Title:       F-25 Photo records readable by any signed-in member
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      OPEN - Founder 13 Nov "ZYRA chat designs, I approve (Recommended)" (DR-ZYRA-350).
Owner:       ZYRA chat; Founder decides
Next:        Decide who may see which photos (gender, blocks, hidden profiles), align the record rule with the file
             rule, decide on a screenshot notice.
Acceptance:  Rule decided and built.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-382
Title:       F-26 Nothing measured (speed)
Category:    ZYRA audit finding
Priority:    LOW
Date:        2026-11-13
Status:      DEFERRED - until wiring.
Owner:       Codex
Next:        Targets: opens in 2 seconds, smooth swipes, lists load 20 at a time; measure on the Founder's iPhone.
Acceptance:  Targets measured.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-383
Title:       F-27 High cost per task
Category:    ZYRA audit finding
Priority:    MEDIUM
Date:        2026-11-13
Status:      IN PROGRESS - 13 Nov Fable (Q7): built_brief_check.py refuses edits to BUILT briefs; Codex trial at
             medium effort (AD-AIOS-150). Left: server-contract part in every brief; batch small fixes into one line.
Owner:       Fable
Next:        Brief template gains a server-contract part.
Acceptance:  Lower cost per line in the nightly Codex table.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-384
Title:       F-28 Website headers
Category:    ZYRA audit finding
Priority:    LOW
Date:        2026-11-13
Status:      OPEN - scheduled.
Owner:       Codex
Next:        Add a headers file; compare live with local; policy pages come with F-09.
Acceptance:  Headers live.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-385
Title:       F-29 Wording held in code
Category:    ZYRA audit finding
Priority:    LOW
Date:        2026-11-13
Status:      DEFERRED - during wiring.
Owner:       Codex
Next:        Route new wording through one wording file.
Acceptance:  One wording file.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-386
Title:       F-30 171 packages, no update routine
Category:    ZYRA audit finding
Priority:    LOW
Date:        2026-11-13
Status:      IN PROGRESS - 13 Nov Fable (Q8): queue line 112, monthly package check and Flutter version pinned in a
             file.
Owner:       Fable; Codex
Next:        Codex builds line 112; Fable's 04:15 review adds the next check on the 1st of each month.
Acceptance:  Monthly report filed; Flutter version pinned.
Source:      ZYRA audit 13 Nov 2026 (ZYRA chat doc, sections 13-14); Founder 13 Nov "Yes, file them all (Recommended)"
------------------------------------------------------------

OA-ZYRA-387
Title:       Build-check differences 13 Nov - lines 88, 92, 95, 101 do not match their LOCKed masters
Category:    Build check difference (core rule 11, charters rule 8)
Priority:    MEDIUM
Date:        2026-11-13
Status:      OPEN - 14 Nov: waiting for the ZYRA chat's fix briefs (the chat sent items b-e to Shakeel on 13 Nov).
Owner:       ZYRA chat (fix briefs and queue lines); Codex (build)
Next:        (b) line 88 Ended Journeys card: first name, short UK dates ("29 Oct 2026"), no "Ended Journey" or "Start
             date not recorded" wording; (c) line 92 Partner preferences "Save changes" / "Use this answer" as the gold
             main button (LOCK 30); (d) line 95 Past tab pill ivory with gold border, no darker fill (APP COLOURS V8);
             (e) line 101 Seeker Basic with no Guardians shows 9 Guardian One places, not 10; "any 10 Guardians" link
             dark text; Guardian card rows spaced as the prototype.
Acceptance:  Each item rebuilt from a fix brief and recorded MATCH in a chat note.
Source:      ZYRA chat note 13 Nov 05:40 (build checks, rule 8); filed by Fable 14 Nov 04:15
------------------------------------------------------------

OA-ZYRA-388
Title:       Dead route - guardian_network_profile builder has no opener (line 90 capture gap)
Category:    Technical debt
Priority:    LOW
Date:        2026-11-13
Status:      OPEN - backlog; not ZYRA real-backlog night work (AD-AIOS-133 excludes ZYRA) - needs a queue line.
Owner:       ZYRA chat (queue line); Codex (remove or wire)
Next:        ZYRA chat decides remove or wire and queues a fix line.
Acceptance:  No route without an opener; line 90 gap list updated.
Source:      ZYRA chat note 13 Nov 05:40 (build checks, rule 8); filed by Fable 14 Nov 04:15
------------------------------------------------------------

OA-ZYRA-389
Title:       Server call to resend the same expired Guardian invitation to its recipient (QUESTIONS 88)
Category:    Server contract (wiring)
Priority:    LOW
Date:        2026-11-14
Status:      DEFERRED - connect-first work after 14 Dec (AD-AIOS-149). No resend call exists; the app shows Expired
             without Send again until then (QUESTIONS 88 answer).
Owner:       Fable (contract in the wiring brief); Codex (build)
Next:        Specify a sender-owned resend of the same invitation in the SERVER 0 / wiring brief after line 110.
Acceptance:  Resend call built and tested on a throw-away database; app shows Send again on Expired.
Source:      ZYRA QUESTIONS 88 (11 Nov), answered by Fable 14 Nov 04:15
------------------------------------------------------------

OA-ZYRA-390
Title:       Build-check differences, 14 Nov morning check (lines 103, 105, 108; built pictures)
Category:    Build check (charters rule 8)
Priority:    MEDIUM
Date:        2026-11-15
Status:      OPEN - filed by Fable 15 Nov 04:15 from the ZYRA chat note 14 Nov 05:46 (items a-e).
Owner:       ZYRA chat (fix briefs, CODE_PAGE V3/V4 masters); Codex (build, pictures)
Detail:      (a) built pictures for lines 103, 105, 113, 114 are only in REPORTS/EVIDENCE, not in <FEATURE>/BUILT/
             (third day); (b) line 105 selected My code / Their code pill has a darker taupe fill - prototype is ivory
             with a gold border (APP COLOURS V8), likely the shared pill widget also behind line 95; CODE_PAGE/MASTERS
             still hold the old LOCK 9 V2 pictures; (c) line 103 Seeker Past list shows a chat icon tile instead of the
             person's photo; (d) line 103 mute toast covers a sheet row; (e) line 108 comparison picture not on the Mac.
Next:        ZYRA chat writes one fix brief (fixes only, AD-AIOS-149 / OA-AIOS-446 item 5) and re-renders the CODE_PAGE
             masters; Codex saves the line 108 picture into CODE_PAGE/BUILT/.
Acceptance:  Each item MATCH in a later ZYRA chat build check.
Source:      2026-11-14_ZYRA_CHAT_NOTE.md, morning check
------------------------------------------------------------

OA-ZYRA-391
Title:       Founder to confirm two number calls the ZYRA chat made for QUESTIONS 145 (line 115)
Category:    Founder confirmation
Priority:    LOW
Date:        2026-11-15
Status:      OPEN - filed by Fable 15 Nov 04:15 from the ZYRA chat note 14 Nov item (f).
Owner:       Shakeel (confirm or overrule); ZYRA chat (asks him)
Detail:      Profile Switch button 34 pt (like Preview/Edit) and a 16 pt gap above the tab bar (LOCK 24 app-wide; spec
             said 14). Line 115 is BUILT with these values.
Next:        ZYRA chat asks Shakeel with a clickable question; a change is a new fix line.
Acceptance:  His answer recorded in the ZYRA chat note.
Source:      2026-11-14_ZYRA_CHAT_NOTE.md item (f)
------------------------------------------------------------

TOTAL REGISTERED (this file): 309 (OA-001 through OA-ZYRA-309,
  Historical Identifiers, permanent — plus this note)
NEXT IDENTIFIER: OA-ZYRA-392 (Enterprise format, active
  2026-07-12 — see BLACK UMBRELLA GROUP/SYSTEM/OUTSTANDING_
  ACTIONS/OUTSTANDING_ACTIONS_V1.md, OA-127)
GOVERNING STANDARD: ENTERPRISE_OBJECT_IDENTITY_STANDARD_
  CURRENT_VERSION_V1.md (BLACK UMBRELLA GROUP/SYSTEM/
  ARCHITECTURE/), active 2026-07-12
