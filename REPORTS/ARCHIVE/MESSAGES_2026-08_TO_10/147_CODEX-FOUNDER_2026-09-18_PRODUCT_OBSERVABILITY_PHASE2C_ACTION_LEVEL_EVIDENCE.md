# CODEX → FOUNDER — Product Observability Phase 2C Action-Level Evidence

**Date:** 2026-09-18  
**Status:** CODE COMPLETE / IPHONE INSTALLED + LAUNCHED / PRODUCTION OFF  
**Authority:** Founder instruction “continue”; DR-ZYRA-239; OA-ZYRA-256

## 1. Outcome

The local observability channel can now distinguish which governed action was
used, rather than reporting only a broad feature. The Founder Health & Usage
screen lists every governed feature and action, including zero-use entries,
so the most-used and least-used controls can both be seen truthfully.

Production collection remains compile-time off. The migration is still
staged and unapplied. No cloud, provider, scheduler or privacy setting changed.

## 2. Fixed action taxonomy

1. Page view.
2. ZYRA Code check.
3. ZYRA Code request.
4. Known-person Consider.
5. Support answer.
6. Support email.
7. Identity provider.
8. Guardian history consent.
9. Guardian report.
10. Guardian Make Main.
11. Guardian remove.

These are enum values, not visible button text. Names, emails, codes, ids,
questions, error text and arbitrary payloads remain impossible through the
typed event API.

## 3. Staged server parity

The unapplied migration now requires fixed `action_key` values in the private
table and write RPC. The aggregate summary groups by action as well as feature,
event, surface, platform and app version/build. The existing private-table,
fixed retention, circuit-breaker and service-role-only controls remain.

Staged migration SHA-256:
`dd20f85ed308c85efca18b9e33564405fce760fc1238190dc50a6ed673614dca`.

## 4. Verification

- focused action/SQL/funnel/identity/ZYRA-Code/Guardian tests: **36/36 PASS**;
- `flutter analyze`: **PASS — no issues**;
- iOS profile build: **PASS**;
- signed executable SHA-256:
  `648754b5be0aee1f12a4746e5bc5f8df07107b1f40d8fa9acdae15f6584fab7b`.

## 5. iPhone truth

Three direct attempts initially stopped before app transfer because Apple
CoreDeviceService failed to initialize, including after restarting only that
helper. The supported Flutter deployment path then installed and launched the
new build in 27.5s. Flutter subsequently lost its local profile VM socket; that
was a tooling-channel failure after deployment, not an installation failure.
Device catalog verification passed and a separate direct app launch passed.
The iPhone now has ZYRA `1.0.0 (2)` with the Phase 2C build.

## 6. True edit-time lineage

The full fourteen-file Phase 2C pre/post ledger is filed in
`ZYRA_PRODUCT_OBSERVABILITY_HANDOVER_CURRENT_VERSION_V1.md`. The governance
pre-state hashes were captured before edit. No reconstructed file is used as
an audit anchor.

## 7. Held gates

No migration apply, production telemetry compile enablement, privacy wording,
crash provider, scheduler or automatic repair agent was authorized or executed.
