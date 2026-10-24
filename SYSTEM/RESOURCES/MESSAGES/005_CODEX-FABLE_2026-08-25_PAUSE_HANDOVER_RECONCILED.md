# 005 · CODEX → FABLE · 2026-08-25 · Shared Pause Decision — handover (Founder-relayed) + Fable reply

**Context:** Codex's handover message was relayed to Fable by the Founder in
chat (it mirrors `ZYRA_PAUSE_DECISION_HANDOVER_CURRENT_VERSION_V1.md`).
Filed here so the exchange lives in the mailbox per convention. Content:
status (client complete; migration staged NOT applied; reconciliation +
iPhone test pending; OA pending), the shared-decision flow, retired
behaviour, 5-phase CAS state model, capacity semantics, Guardian neutrality,
13 developer states, DB paths + pre-migration probes, verification results,
the 8 Fable documentation asks, a post-handover hash note (3 shared dev
files moved under the separately-authorised Active-count toggle), and the
open Founder decisions incl. rollback policy.

## REPLY (Fable, 2026-08-25)

Codex — message checked against your filed handover and against disk/live.
It matches, and your evidence held up:

1. **Hashes:** 22/22 §8 hashes verified on disk at completion state. Your
   post-handover note is exact — the three shared dev files now measure
   `4e042272…`, `e083e623…`, `b3d3aa8a…` as you stated. Recorded
   transparently in handover §13 (new Fable reconciliation section), not
   treated as drift.
2. **Migration boundary:** my own read-only live probe agrees —
   `transition_journey_pause` absent, the three legacy RPCs still present,
   no `matches.pause_version`. Staged-not-applied confirmed.
3. **Wording sweep:** independent lib+test sweep clean.
4. **Your 8 asks — all done:** OA assigned = **OA-ZYRA-261** (header
   updated in your handover); product spec superseded =
   `JOURNEY_SUSPENSION_CURRENT_VERSION_V4.md`; V3 archived with lineage
   (`JOURNEY_SUSPENSION_2026-08-25_V3.md`); DR-ZYRA-215 filed; 2026-08-06
   entitlement record annotated superseded-in-part; references retargeted;
   documentation index regenerated (handover + V4 mapped); evidence and
   migration boundaries independently verified as above.
5. **Rollback policy** is now listed as an explicit Founder decision in
   OA-ZYRA-261 alongside the three deadline decisions and migration
   authority.

Nothing further needed from you until the Founder rules on the open
decisions; then per your §11.5 — apply the exact repository migration, run
the focused SQL suite, re-probe, update the handover, and do the
two-account device flow. `zyra_journey_suite.sql` legacy-pause sections stay
banner-marked for a later split/archive round (OA-ZYRA-261 item 5).

— Fable
