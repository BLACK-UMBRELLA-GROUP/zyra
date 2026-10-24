# TO: Fable
# FROM: Codex
# SUBJECT: Connections Activity-card unification + Introduction-control repair — code complete

**Date:** 2026-08-29  
**Status:** CODE COMPLETE; Fable verification and Founder device acceptance pending  
**Authority:** Founder direct instruction in Codex, 2026-08-29  
**Governance:** AD-AIOS-104; Implementation Handover Standard V2  
**OA/DR:** No new identifier supplied; Fable owns register trace if required  
**Migration:** None authorised, created or applied  

## 1. What changed

Considered, Saved and Passed now copy the compact Potential Journey expansion
model instead of enlarging the profile photo. The thumbnail/name header stays
present, expansion reveals controls in place, View Profile owns the full-photo
experience, and Report is the top-right flag rather than a pill.

The action matrix is unchanged in business meaning and now reads clearly:

| State | Decision/bookmark pills | Shared actions |
|---|---|---|
| Considered | Pass; Save | View Profile; Compatibility Unlock/View Compatibility |
| Saved | Pass; Consider | View Profile; Compatibility Unlock/View Compatibility |
| Passed | Save; Consider | View Profile; Compatibility Unlock/View Compatibility |

The shared Introduction card inherits the same compact shell. Local developer
Preview rows remain labelled and inspection-only; live rows retain real actions.

The Test Introductions control now works for the authorised Founder/admin OAuth
account without pretending that it is a seeded server-test identity. It stages
an explicit local Preview and opens the actual Introductions segment. Seeded
`@zyra.test` accounts retain the guarded RPC path. A non-throwing RPC result of
`created: 0` and an unavailable RPC both produce a truthful labelled local
Preview instead of a blank page. No production row or verification state is
granted by this fallback.

## 2. Architecture and truth boundaries

```text
Live Considered / Saved / Passed / Introduction row
  -> one shared compact Activity shell
  -> persistent identity header
  -> expanded action deck
  -> top-right Report flag (live rows only)

Developer Test Introductions count
  -> seeded @zyra.test identity: guarded Supabase RPC
  -> authorised non-seeded operator: local/session Preview
  -> RPC created=0 or unavailable: explicit local/session Preview
  -> real Connections → Introductions segment opens

Release build
  -> local Preview composer and load-gate bypass remain unavailable
  -> live server truth remains authoritative
```

No Activity decision semantics, navigation destination, compatibility unlock,
report flow, entitlement, RLS, server function or database state changed.

## 3. Live files and SHA-256

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/screens/connections/connections_screen.dart` | `e06b29ca6621f849ee477c53be4dccd8db525ca10ef8541630eac1e97cab7ef8` | Compact shared Activity/Introduction shell, expanded Report flag and preview-aware load gate |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `b5623ab7cd2cf1319e7b52359c265f4410f4d429bb56d18c03e23563010d1acb` | Deterministic Test Introduction server/local routing |
| `SOURCE/test/connections_design_defaults_test.dart` | `a08c52051ad9d05d49d714c43436cbdcf98890432db9a3daf9cb036527f6eeb3` | Card/action/report, compact large-text, Introduction load-gate and inspection-only coverage |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `5d51722a625410b61be46bac8f5078bc53af126344100402c010a880e0606f70` | Introduction count/reset, fallback, RPC success and created=0 coverage |
| `SOURCE/build/ios/iphoneos/Runner.app/Runner` | `130490bee0e599fd7bca602ab80cfd6959d77e2906db8afaa781f7c28645b956` | Exact installed profile executable |

The CURRENT_VERSION handover and this point-in-time mailbox file do not embed
their own post-write hashes.

## 4. Measurements

| Command / observation | Result |
|---|---|
| `dart format` on four changed Dart/test files | PASS; 0 changes required |
| Final focused Connections/developer/control/correctness suite | PASS; 53/53 |
| `flutter test --no-pub --reporter compact` | PASS; 636/636 |
| `flutter analyze --no-pub` | PASS; no issues |
| `python3 tools/zyra_check.py` | PASS; 175 files; 0 findings; 0 new doc refs |
| Compact/large-text Activity-card fixture | PASS at 286px and 145% text scale; no exception/overflow |
| iOS profile build | PASS; signed `Runner.app` 34.8 MB |
| Paired physical-device install | PASS; `app.zyraconnect.zyra` 1.0.0 present |
| Automated device launch | BLOCKED by iOS developer-profile trust; SpringBoard security refusal measured |
| Founder visual acceptance | PENDING |
| Fable independent disk verification | PENDING |
| SQL probe | Not applicable; no database work |

## 5. Review notes

1. The launch block is not a Flutter runtime/build failure. The current Xcode
   project signed successfully with its configured development team, but iOS
   requires the user to trust that developer profile before SpringBoard will
   open this installed build.
2. Developer previews are intentionally session-only. They are not evidence of
   a production Introduction row and cannot expose the write actions.
3. `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md`
   §32 is the current implementation amendment.

No git command, commit, migration, SQL, credential, package or production
service mutation was performed.
