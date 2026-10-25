---
id: DOC-ZYRA-0064
type: STANDARD
status: CURRENT
feature: APP: STANDARDS
purpose: Standards — PROFILE ACTIONS MENU STANDARD CURRENT VERSION V1: ZYRA — Profile Actions (⋮) Menu Standard
links: []
owner: ZYRA chat
---

# ZYRA — Profile Actions (⋮) Menu Standard

**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-07-26
**Owner:** ZYRA Product
**Ratified by:** DR-ZYRA-112

**Origin:** DR-ZYRA-095 (2026-07-25) ratified the three-dot menu for
the Browse screen only (Report Profile / Hide Profile / Block User),
and explicitly left open: whether contents should vary by
relationship stage, whether Block needs a confirmation step, and how
Block interacts with an Active Journey. A Founder-relayed ChatGPT
discussion paper ("Discussion: Three-Dot Profile Menu") asked all
three questions directly and asked for engineering/UX judgement
rather than a prescribed answer. This document is that judgement,
ratified. It does not change anything already built — no Report/Hide/
Block code exists yet anywhere in `SOURCE/` (grepped, zero hits) — this
is the design the eventual build should follow.

---

## Principle 1 — Report and Block are a universal safety floor

**Report Profile** and **Block User** are available from this menu at
every relationship stage, without exception. Safety cannot be gated
by how far a relationship has progressed — a Report or Block reason
that becomes true during an Active Journey or after a Journey ends is
exactly as valid as one that becomes true in Browse.

## Principle 2 — Hide Profile is a Browse-recirculation control, not a general dismissal

Hide's entire meaning is "stop recirculating this profile in Browse."
That only means something before a Match exists — once two people have
Matched, there is nothing left to hide from. So Hide appears in
**Browse** and **Saved** (still meaningful — Saving someone doesn't
change whether the user later decides not to see similar/that profile
again) and drops out from **Matches** onward.

## Principle 3 — Stage-specific relationship actions get their own dedicated control, never a slot in this menu

End Journey/Pause (Active Journey) and Continue/Pause (Family Review
Period, built under #31) are deliberately **not** in the ⋮ menu — each
already has its own visible, always-available control on its own
screen (`_JourneyAppBar` in `journey_flow_screen.dart`; the Family
Review banner in `wali_journey_detail_screen.dart`). This is what
keeps the menu "intelligent and context-aware while remaining
predictable," per the Founder's own framing: its **size and meaning
stay constant everywhere** (always safety/disinterest, never
relationship management) even though which of its 3 possible items
show up varies. A future "Unmatch" action (a lighter, non-safety way to
end a pre-Journey Match) would follow this same rule if it's ever
built — flagged below as a genuinely open idea, not folded into this
menu by default.

## Principle 4 — Confirmation friction matches consequence

| Action | Confirmation | Why |
|--------|-------------|-----|
| Hide Profile | None | Fully reversible (optional undo via account settings), lowest possible stakes |
| Report Profile | None / light | Doesn't sever anything by itself — it flags for moderation review, no immediate effect on either user's access to the other |
| Block User | **Required, every time it appears** | Closest to irreversible in effect: removes existing Considers/Matches, disables messaging, and (new, below) force-ends any Active/Family-stage Journey in the same action |

## Resolved gap 1 — Block requires a confirmation step

Yes. A single "Block Sarah? You won't be able to see or contact each
other again." (name interpolated) dialog, Cancel / Block, appears
before any Block executes, at every stage it's available. Report and
Hide do not get this same dialog — asymmetric friction matching
asymmetric consequence, per Principle 4.

## Resolved gap 2 — Block during an Active Journey or Family Stage also ends the Journey

Yes, in the same action, not as a separate step. Block's own existing
definition (DR-ZYRA-095) already says messaging is disabled and future
interaction is prevented — leaving a Journey nominally "Active" while
the two people can no longer message or interact is an inconsistent
state, not just a UX gap: the Journey's Timeline and messaging surface
would have to silently break rather than reflect what actually
happened. So Blocking during Active Journey or Family Stage reads as
one confirmation ("Block Sarah? This will also end your Journey
together. You won't be able to see or contact each other again.") and
one resulting state change, not two.

## Resolved gap 3 — per-stage menu contents

| Stage | Report | Hide | Block | Notes |
|-------|--------|------|-------|-------|
| Browse | Yes | Yes | Yes | Full 3-action menu — current DR-ZYRA-095 baseline, unchanged |
| Saved | Yes | Yes | Yes | Same 3 actions — Hide is still meaningful here (Principle 2) |
| Matches (pre-Journey) | Yes | No | Yes | Hide drops out (Principle 2). An "Unmatch" action is a plausible future addition here — not ratified, see below |
| Active Journey | Yes | No | Yes — also ends Journey | End Journey/Pause stays its own dedicated control (Principle 3) |
| Family Stage | Yes | No | Yes — also ends Journey | Continue/Pause stays its own dedicated control (Principle 3) |
| Completed Journey | Yes | No* | Yes | *Revisit once ended-Journey users can reappear in Browse after the 24h cooling period (#17) — Hide may become relevant again at that point |

## Explicitly not decided here — flagged for a future, separate decision

- **Unmatch** as a distinct, lighter-than-Block action for the Matches
  (pre-Journey) stage. Real value: lets someone end a just-formed
  Match without invoking Block's safety framing, similar to how most
  matching apps separate "unmatch" from "block/report." Not added to
  the table above because the Founder's brief asked about Report/Hide/
  Block specifically, and Principle 3 says new relationship actions
  should get their own control rather than being folded into this menu
  by default — so if this is wanted, it should be its own screen
  affordance, not a fourth ⋮ menu item, and should be its own decision.
- **Guardian-facing Report/Block** — still entirely unspecified, per
  BROWSE_UX_SPEC_CURRENT_VERSION_V4.md's Scope Note. Out of scope for
  this document, which only resolves the three gaps DR-ZYRA-095 named.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| V1 | 2026-07-26 | Initial ratified standard — resolves the three open gaps from DR-ZYRA-095 (Block confirmation, Block-vs-End-Journey, per-stage contents). DR-ZYRA-112. |
