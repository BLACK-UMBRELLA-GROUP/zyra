# TO: Fable
# FROM: Codex
# SUBJECT: Paused/Ended Journey reference surfaces — code complete

**Date:** 2026-08-29  
**Status:** SUPERSEDED BEFORE FOUNDER ACCEPTANCE; see mailbox 017  
**Authority:** Founder direct instruction in Codex, 2026-08-29  
**Governance:** AD-AIOS-104; Implementation Handover Standard V2  
**OA/DR:** No new identifier supplied; Fable owns register trace if required  
**Migration:** None authorised, created or applied  

> **Supersession notice:** the Founder clarified that the larger enclosing
> JOURNEY glass rim — not the two individual action-pill rims — was to be
> removed. This interim implementation was corrected immediately. It is kept
> only as honest trace and must not be treated as the current design or build.

## 1. What changed and why

Expanded Paused and Ended Journey cards placed Timeline and View Compatibility
inside individual glass pills, even though both already live inside one
bordered JOURNEY group. The Founder asked to remove that redundant nested
surface.

Both references now render as clean icon-and-label actions on the existing
JOURNEY surface. Their icons, labels, callbacks, width allocation and tap
targets remain intact. The outer JOURNEY glass group remains unchanged.

## 2. Architecture and scope

`_ConnectionsActionItem` now supports an item-scoped `surfaceFree` presentation
flag. Only the Timeline and View Compatibility items created by
`_ConnectionsJourneyReference` set it. `_ConnectionsActionButton` responds by
using transparent Material and no Ink decoration while retaining InkWell and
its rounded interaction boundary.

This avoids a separate widget fork and preserves the existing shared action
layout. Potential, Active, Activity, profile and destructive actions remain on
their existing Compact Chips surfaces. No navigation or product state changed.

## 3. Live files and SHA-256

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/screens/connections/connections_screen.dart` | `c47c2d4c291dc8da5dc51d3916e1da23c333547814e120d5a2e78c7db345a68b` | Surface-free Paused/Ended Journey reference actions |
| `SOURCE/test/connections_design_defaults_test.dart` | `01dcbd0c42ac9c0afe4a841ddb120c5bd2d5ee9af1c98745c11c6cc05f7265a5` | Both states retain icons/actions/taps, remove inner surfaces and retain outer group |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` | `b5648a1124d67bd6c9a8454fb1f4692318b834920dfba25502fc7ba022b24a7f` | Current UI architecture amendment (§28) |
| `SOURCE/build/ios/iphoneos/Runner.app/Runner` | `f9221709e6941096ba730e002400c3e98d104209a62e6e70236a1da717784c4f` | Exact deployed profile executable |

This point-in-time mailbox file does not embed its own post-write hash.

## 4. Mock versus production behaviour

The visual change applies equally to mock and production Paused/Ended cards
because both use the same renderer. It changes presentation only. No mock
state, Supabase call, persisted Journey state, entitlement or production data
path was added or changed.

## 5. Measurements

| Command / observation | Result |
|---|---|
| `dart format` on changed Dart/test | PASS; clean |
| Focused Connections UI suite | PASS; 12/12 |
| `flutter test --no-pub --reporter compact` | PASS; 611/611 |
| `flutter analyze --no-pub` | PASS; no issues |
| `python3 tools/zyra_check.py` | PASS; 173 files; 0 findings; 0 new doc refs |
| iOS profile build | PASS; signed `Runner.app` 34.9 MB |
| Wireless install + launch | PASS via `flutter run --profile --no-pub`; VM service connected |
| Runtime process probe after detach | PASS; `Runner.app/Runner` observed as PID 70911 |
| Founder visual acceptance | PENDING — current build is open on device |
| SQL probe | Not applicable; no database work |

## 6. Remaining review

Founder device review and Fable independent disk verification remain pending.
Codex has not self-approved either. No git command, commit, migration, SQL,
credential, package or production service mutation was performed.
