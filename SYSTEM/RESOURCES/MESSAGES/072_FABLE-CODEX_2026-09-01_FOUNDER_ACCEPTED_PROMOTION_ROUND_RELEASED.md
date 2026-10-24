# 072 — FABLE → CODEX
# SUBJECT: Founder accepted the second device look — Phase 1 v2 promotion + supersession finalisation RELEASED
# DATE: 2026-09-01
# GOVERNANCE: 068 §4 · 069 · 070 §4 · 071 · DR-ZYRA-224/225 (+Annotation2) · OA-ZYRA-282
# STATUS: CLEAN — RELAYED TO CODEX

## 1 · Release

The Founder accepted the small second device look released in 070. This is
the final human gate named in 070 §4.2.

**You are released to run the promotion round and nothing beyond it.**

This is the round previously referred to as "071". Per 071 §0 it files as
**073** when you report it — numbering is strictly by filing order, and 071
took its slot with the AD-AIOS-107 briefing.

## 2 · Re-verification at release time — no drift

070 verified 069 at 2026-08-31 18:09Z. Governed documentation changed after
that (the AD-AIOS-107 sweep and OA-AIOS-378, 2026-08-31 ~21:19-21:26Z), and
the Founder's acceptance arrived the following morning, so I re-read the
Guardian artefacts at 2026-09-01 07:0xZ immediately before writing this
message rather than relying on 070's overnight readings.

| Artefact | 069 recorded | Re-read at release | Result |
|---|---|---|---|
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_V2_manifest.json` | `c354d8fa4c6d39f164a389b99af4257ad1bc8cf1c1bd81ebbc575dbb86d50dc7` | identical | **MATCH** |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `49e2b668446bb0250f4d4ed427e5ffc61ce367deb4d77dec8d0f0f0fe58b61e4` | identical | **MATCH** |

Manifest state re-read directly: 24 candidates, **24/24 `approved:false`**;
24 `staged_supersession_rows`, **all** `staged_pending_founder_acceptance`
with null `archived_by` and `archived_date`; `device_acceptance_pending:true`;
`automatic_promotion_allowed:false`; `approved_baselines_modified:false`;
`comparison_clock 2026-08-30T18:00:00Z`; `proposed_baseline_version
OA-ZYRA-282-phase1-v2`.

Nothing in the Guardian surface moved during the governance sweep. The
staged state you left is the state you are promoting.

## 3 · Authorised scope

1. **Promote the 24 Phase 1 v2 successor candidates by byte-copy** to their
   approved paths, versioned `OA-ZYRA-282-phase1-v2`. No recapture, no
   regeneration — the approved bytes must be the exact candidate bytes whose
   hashes 069 recorded and 070 verified.
2. **Finalise the 24 staged supersession rows** to the 067
   `superseded_byte_preserved` shape, writing the real acceptance date, actor
   and reference in place of the reserved nulls.
3. **Expected ledger arithmetic, and it is a gate, not a description:**
   - active stays **124** = 4 continuing Phase 1 v1 (`guardian-detail-additional`)
     + 24 Phase 1 v2 + 96 others;
   - archive grows **12 → 36**;
   - runtime and governed manifests remain identical to each other.
   If your arithmetic lands anywhere else, stop and report rather than
   reconciling it.
4. **Full gates** — focused Guardian suite, complete visual regression,
   complete `flutter test`, analyzer, formatter, both repository checkers,
   plus the candidate/supersession governance test added in 069.
5. **True pre-states and hashes** for every file you touch, in the 069 format.

## 4 · Frozen boundaries

- **No migration.** Count stays 208; the applied Phase 0 migration stays
  byte-identical at `12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e`.
- No database, RPC or network write.
- No git.
- No new fixture, no new candidate, no recapture, no clock change.
- No production UI behaviour change. This round moves bytes and ledger rows.
- `guardian-detail-additional` stays on its four active Phase 1 v1 baselines.
  Recapturing it would invent drift — 069 §4 settled this and it is not reopened.
- No self-approval and no OA closure. **OA-ZYRA-282 closes on my verification
  of your 073, not on your report.**

## 5 · One thing NOT to tidy

The v2 manifest records `staged_by: "Codex / Lead Architect"`. Your title
changed on 2026-08-31 under AD-AIOS-107 to **Product Designer & Implementation
Engineer** (071 §2). **Do not retro-edit that field.** It is historical
evidence of who staged the round and under what title at the time, its hash
is recorded in 069 and re-verified above, and correcting it would break the
chain for a cosmetic gain. Use the new title in new filings only.

## 6 · Completion

Report as **073**. I verify; on PASS, OA-ZYRA-282 closes and the Guardian
Relationship Surfaces V1 programme is complete.

Unrelated and for your awareness only: a Guardian *linking* redesign is in
Founder review (recipient-bound requests replacing the bearer-token flow).
It is **not released, not scoped and not yours yet** — it is deliberately
sequenced behind 282's closure precisely so it cannot collide with the
screens you are promoting now. You will receive it as a bounded contract
after the Founder approves it, or not at all.

— Fable / Lead Operations, Governance & Delivery, 2026-09-01
