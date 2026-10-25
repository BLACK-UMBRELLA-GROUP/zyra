# TO: Fable
# FROM: Codex
# SUBJECT: Connections context controls + Activity previews — code complete

**Date:** 2026-08-29  
**Status:** CODE COMPLETE; Fable verification and Founder device acceptance pending  
**Authority:** Founder direct instruction in Codex, 2026-08-29  
**Governance:** AD-AIOS-104; Implementation Handover Standard V2  
**OA/DR:** No new identifier supplied; Fable owns register trace if required  
**Migration:** None authorised, created or applied  

## 1. What changed and why

Connections developer Actions previously mixed Journey, compatibility and
Introduction controls regardless of which Connections segment was visible.
Considered and Saved also had no direct preview control. The Founder asked for
segment-specific tools and Home at the top of the shared developer rail.

The panel now has one Connections sub-toggle and exactly one contextual group:

| Connections segment | Controls shown |
|---|---|
| Journeys | Open live Journey; Active; Potential; Paused; Ended; pause-state matrix when relevant |
| Activity | Considered; Saved; Passed; compatibility credits; Guardians on decided profiles |
| Introductions | Test Introductions and its truthful server/local state explanation |

Selecting the sub-toggle opens that real Connections segment. Swiping the real
Connections pager still publishes its settled segment back to the developer
scenario, so the panel follows the product UI rather than maintaining a second
navigation truth.

The right-edge rail order is now Home → Preview → Actions on every surface
using the shared rail. Actions remains initially selected when first opened.

## 2. Architecture and data flow

```text
Developer Connections sub-toggle
  -> ZyraDevScenario.connectionsSection (0 / 1 / 2)
  -> ZyraDevSurfaceCoordinator callback
  -> HomeShell shared ConnectionsSectionController
  -> kept-alive Connections PageController moves to the chosen segment

User swipe / product segment tap
  -> Connections PageController settles
  -> ZyraDevScenario.connectionsSection
  -> open developer panel rebuilds with only that segment's controls

Activity preview count (Considered / Saved / Passed)
  -> ZyraDevScenario session count, clamped 0–5
  -> non-release pure composer appends deterministic non-UUID profiles
     beside the real AppState list
  -> shared Activity card, visibly marked Preview and inspection-only
  -> release path bypasses the composer entirely
```

Real `AppState.outgoingLikes`, `saved` and `declined` lists are neither cleared
nor rewritten. Preview cards do not expose Pass, Save, Consider, Compatibility
or Report. Reset clears the three staged counts. It deliberately retains the
current Connections segment because navigation context is not account state.

## 3. Live files and SHA-256

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | `9e6859137644dcdbf374293f11c83eb5a4a1cc56f9fd5d28677233f4f4ba5711` | Shared Home-first three-door rail |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `2a061e0f2874161552c68dae7fbff84e0389d06b1bbaa232a22a584273cbf2b9` | Segment context plus three 0–5 Activity preview counts/reset |
| `SOURCE/lib/dev/zyra_dev_surface_coordinator.dart` | `6d8e915f576061760ee5d634e6e7b3e3a0c47adbb38075b5963ed7153379a554` | Generic Connections-segment callback ownership |
| `SOURCE/lib/dev/zyra_global_dev_overlay.dart` | `61947ec08bba16c6c86d7666440776da9a46c7a32a9968ee297ba8346b014e8d` | Callback plumbing into the app-wide panel |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `1b2e02fe866cd8e8936921cbb03b70e99b9b77fcbae2cfbb7e80d401df9f6134` | Segment sub-toggle and mutually exclusive contextual control groups |
| `SOURCE/lib/screens/home/home_shell.dart` | `372f42529ec65a34ae7728959591f65857e5ac3268e4c7c55f272bfed1d9dc38` | Segment callback into the existing shared controller |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `2b86b9872815417b42a450aa463e4a302377adca6b4089eeb76f4b477c8da519` | Pure Activity preview composition, release bypass and inspection-only cards |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `347a0376f138ddcbf9aa5075703fbeeff5169d78e648d0dccd6950b99d3a1462` | Rail order, segment isolation/callback and count/reset coverage |
| `SOURCE/test/connections_design_defaults_test.dart` | `89fce646d53af6bf63fc8a975d24f6e77cd25b61539cfe2e106e3e15f5e39840` | Activity composer truth preservation, clamp and unique-group ids |
| `SOURCE/test/global_dev_overlay_test.dart` | `161389afe94914b6709767fcc7ef458a91da0c26eee31ffe35c7f269caa27e1b` | Coordinator forwarding/detach boundary |
| `SOURCE/build/ios/iphoneos/Runner.app/Runner` | `b795413a9d2956a8bb77de2d15268e9dd4d1fccf5201840632a3893ba0d74832` | Exact deployed profile executable |

This mailbox file and the amended CURRENT_VERSION handover are point-in-time
documentation and therefore do not embed their own post-write hashes.

## 4. Mock versus production behaviour

- **Production account truth:** real Journey, Activity and Introduction rows
  retain their existing reads and actions.
- **Developer navigation:** the sub-toggle drives the real Connections pager;
  it is not a screenshot or substitute screen.
- **Activity Preview:** debug/profile only, local/session-only, visibly
  labelled, deterministic, non-UUID and inspection-only.
- **Introduction Preview:** unchanged guarded-RPC-first behaviour from §23 of
  the Developer Control handover.
- **Release:** no Activity preview count is read and no preview profile is
  composed.
- **No server changes:** no Supabase call, table, policy or stored member state
  was added for this work.

## 5. Measurements

| Command / observation | Result |
|---|---|
| `dart format` on changed Dart/tests | PASS; final format clean |
| `flutter analyze --no-pub` | PASS; no issues |
| Focused panel/Connections/coordinator suite | PASS; 35/35 |
| `flutter test --no-pub` | PASS; 609/609 |
| `python3 tools/zyra_check.py` | PASS; 173 files; 0 findings; 0 new doc refs |
| iOS profile build | PASS; signed `Runner.app` 34.9 MB |
| Wireless device discovery | PASS; iPhone `00008130-001A2C1E26F8001C` reachable |
| Wireless install + launch | PASS via `flutter run --profile --no-pub`; VM service connected |
| Runtime process probe | PASS; `Runner.app/Runner` observed as PID 70790 |
| Founder visual acceptance | PENDING — current build is open on device |
| SQL probe | Not applicable; no database work |

## 6. Limitations and remaining review

1. Activity preview images use deterministic Picsum development URLs, matching
   the repository's existing mock-profile convention. They require a network
   response to show the sample photo; the card's honest placeholder remains if
   unavailable. This does not affect real profile imagery.
2. Compatibility credits and Guardians-on-decided are placed under Activity
   because they act on decided-profile cards. Fable should flag any product
   reason to expose them elsewhere; no duplicate control was retained.
3. Founder device review and Fable independent disk verification remain
   pending. Codex has not self-approved either.

## 7. Documentation reconciliation

`SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md`
now records the Home-first rail and the contextual Connections contract in
§26. Historical mixed-control statements in earlier dated sections remain as
trace; §26 is the current amendment.

No git command, commit, migration, SQL, credential, package or production
service mutation was performed.
