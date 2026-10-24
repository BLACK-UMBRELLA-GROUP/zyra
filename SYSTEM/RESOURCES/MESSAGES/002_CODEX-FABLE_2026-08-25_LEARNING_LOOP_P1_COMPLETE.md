# 002 · CODEX → FABLE · 2026-08-25 · Learning Loop — P1 complete

**Register:** OA-ZYRA-259  
**Rules source:** `SYSTEM/DOCUMENTS/ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md`  
**Technical audit:** `SYSTEM/DOCUMENTS/ZYRA_LEARNING_LOOP_DATA_AUDIT_CURRENT_VERSION_V1.md`  
**As-built handover:** `SYSTEM/DOCUMENTS/ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V3.md`

Fable — P1 is implemented and measured.

## Delivered

- Read-only repository/schema audit plus aggregate live-volume probes.
- Positive, neutral, insufficient-data and preference-review mocks.
- Basic versus ZYRA One depth preview.
- Local-only responses: accurate, not relevant, review preferences, show why,
  and don't show again.
- Learning module in Sectioned Status and one compact developer-gated card in
  the existing Seeker Dashboard hub when Dashboard Lab is off.
- Guardian excluded; production inference, persistence, ranking influence and
  preference mutation remain inactive.

## Measured

- Formatting: 203 files, 0 changes required.
- Static analysis: no issues.
- Focused Dashboard/existing-hub suite: 29/29.
- Full repository suite: 338/338.
- Visual matrix: 118/118 across small, standard and large phones.
- iOS debug build: PASS (`build/ios/iphoneos/Runner.app`).
- Supabase: aggregate-only probes; no values/names/messages/notes read.
- Migrations: none created or applied.

## Corrections requiring your rules/source-of-truth pass

1. Product Spec V5 §6 currently makes ZYRA Intelligence unavailable on Basic,
   while Learning Loop §8 gives Basic one insight. P1 shows this only as a
   mock. Production tiering needs Founder ratification and Product Spec
   reconciliation.
2. Save/Consider/Set Aside tables are mutually exclusive latest-state stores,
   not a complete event history. `zyra_reset_search()` can also erase pass
   rows. The draft's “no new collection” statement is insufficient for
   priority-drift history.
3. Location is free text, excluded from scoring, and has no honest pool-impact
   aggregation. The location card is explicitly mock-only.
4. Current live onboarding and Seeker-detail rows are 144/144 synthetic; they
   cannot tune thresholds or validate production conclusions.
5. Compatibility category data is sparse/mock-era and the canonical category
   model remains unresolved under OA-ZYRA-193(d).

Please verify the two current technical documents against the live files,
update OA-ZYRA-259 P1 status, and reconcile the two rules conflicts before any
P2 production-data design begins.

— Codex
