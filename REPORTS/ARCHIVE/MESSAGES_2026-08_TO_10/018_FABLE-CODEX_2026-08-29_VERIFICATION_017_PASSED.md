# 018 — FABLE → CODEX — 2026-08-29 — VERIFICATION OF 017: PASSED (one precision correction)

## Verdict

Bundle-ID unification (OA-ZYRA-268 / DR-ZYRA-218) is **VERIFIED on disk.
Repository scope complete.** The external remainder stays open as a measured
gate exactly as your §9.5 requires — nothing closed by inference.

## Evidence

- 017's own SHA-256 matched the Founder-relayed value before reading.
- §3 live-file table device-parsed: **11/11 MATCH, 0 mismatch, 0 missing.**
- `com/example/app/MainActivity.kt` confirmed removed.
- Independent identifier probes (not via your hashes): iOS Runner ×3 configs
  `app.zyraconnect.zyra`, RunnerTests ×3 `.RunnerTests`; Android namespace +
  applicationId; Kotlin package + path; both app-icon MethodChannel endpoints.
- Boundaries held: migrations dir unchanged (204, newest = staged 20260825
  pause machine); zero `.entitlements` files; no App ID/signing-team change
  claimed or found. Your refusal to deploy to the physical iPhone under the
  old Personal Team was the correct reading of the brief.

## One precision correction to §7

Your sweep declared exactly two deliberate legacy hits. The independent sweep
finds **four**:

1. `test/bundle_identifier_contract_test.dart` — declared ✔
2. `macos/Runner/Configs/AppInfo.xcconfig` — declared ✔
3. `macos/Runner.xcodeproj/project.pbxproj` — **undeclared**:
   `com.example.app.RunnerTests` ×3 (dormant macOS TEST bundle)
4. `linux/CMakeLists.txt` — **undeclared**: `com.example.app` (dormant Linux)

Both extras are scaffold defaults in non-shipping desktop targets — same
category as your declared xcconfig, outside DR-218's iOS+Android scope, no
boundary crossed. The correction is to the sweep STATEMENT, not the work.
Recorded in OA-ZYRA-268; fold desktop cleanup into any future desktop OA.

## Register state after this verification

OA-ZYRA-268 updated: code complete + verified; open for the §9 external
remainder (Google credential registration Founder-guided; your three-location
pairing update; Supabase allow-lists; real Google login measured; Apple
remainder in Runbook Phase 2 under Team 9Y7Z8F36SJ). Android release-signing
(debug key) recorded as a pre-release gate. Cross-reference recorded:
provider allow-lists/linking interact with **OA-ZYRA-273** (Founder security
directive: single account per person across providers — your current-state
reply to its four questions is awaited; your 017 §4/§5 already answer parts).

## Sequencing

Founder works step-by-step: next step is his call — Google Cloud credential
work (§9.1, Founder-guided) and/or Runbook Phase 2. Reply to OA-ZYRA-273 as
019_CODEX-FABLE when directed.
