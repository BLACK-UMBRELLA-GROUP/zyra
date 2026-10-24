# TO: Fable
# FROM: Codex
# SUBJECT: Active Journey pause controls + collapsed report visibility — code complete

**Date:** 2026-08-29  
**Status:** CODE COMPLETE; Fable verification and Founder device acceptance pending  
**Authority:** Founder direct instruction in Codex, 2026-08-29  
**Governance:** AD-AIOS-104; Implementation Handover Standard V2  
**OA/DR:** No new identifier supplied; Fable owns register trace if required  
**Migration:** None authorised, created or applied  

## 1. What changed and why

Pause Decision State was still exposed under Connections even though its
four scenarios describe an open Active Journey. A second PAUSE PREVIEW picker
also remained inside the Journey's local stage-jumper panel. The Founder asked
for that control to follow the Active Journey context instead.

The global developer rail now changes to **Active Journey** when a Journey is
open and exposes one Pause Decision State control there. Connections no longer
contains it, and the duplicate Journey-local pause picker is retired. Changes
made through the global control update the currently visible Journey without
closing or reopening it.

Potential, Paused and Ended cards also previously exposed Report before their
profile content was expanded. Those three card types now keep Report hidden
while collapsed and reveal it with the expanded identity row. The separate
Active Journey card is intentionally unchanged.

## 2. Architecture and data flow

```text
Open JourneyFlowScreen
  -> preserve prior ZyraDevScenario.currentPage
  -> currentPage = DevPage.activeJourney
  -> global rail rebuilds with Active Journey actions

Pause Decision State selection
  -> ZyraDevScenario.pauseScenario (single development truth)
  -> mounted JourneyFlowScreen listener
  -> visible pause preview / outcome state updates immediately

Close JourneyFlowScreen
  -> remove scenario listener
  -> restore prior page only if activeJourney still owns the context

Potential / Paused / Ended card
  -> collapsed: identity summary only; no Report control
  -> expanded: full identity row plus Report control
```

The local Journey stage jumper continues to own only specialist stage and Life
Snapshot test controls. No Supabase state, production Journey state,
entitlement or member data is written by the page-aware pause selector.

## 3. Live files and SHA-256

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `4d83b3459eff66b75fc2e0a662a5694adfd8ea4ce955391df38fff96653176f3` | Active Journey page-aware developer context |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `2019ad99b0f095d4d833095ad68600fdcc95b9d08eb541f31e02f378138718de` | Pause control removed from Connections and placed under Active Journey |
| `SOURCE/lib/dev/zyra_page_preview_screen.dart` | `1407b8bc5ef9eeae7d172d160347c81ae7dd3a1d859819955e2d1461cf1c2a0e` | Active Journey preview taxonomy |
| `SOURCE/lib/screens/journey/journey_flow_screen.dart` | `98cc8cb6da3b44915bbbe81fb52a1b85e9227d11ff5555438b8b602b03f9b73f` | Context lifecycle, live scenario listener and retired duplicate picker |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `5fd70478bb2ed71817afda622049e98e01628205dc8d55b54f982f9ba767fd7c` | Expanded-only Report control for Potential/Paused/Ended cards |
| `SOURCE/test/connections_design_defaults_test.dart` | `6d2569bf34c46bfd3406c5f6d29ea34ef2fa6e3c67b8fd77cae978b3c351a46f` | Collapsed/expanded/re-collapsed Report visibility coverage |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `ed373d0968b66303a1632997641e7190b8d8a326c853edef90a8d7a6b7a0f21c` | Pause-control ownership policy coverage |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` | `4bacb466519aaf28c35c9ffc0938f9cf83433703af0a63dafdd9898cad67b985` | Current architecture amendment (§27) |
| `SOURCE/build/ios/iphoneos/Runner.app/Runner` | `dc4b7808e6e57fa41fc5aa67d91f92c0a45f701f36856930f642be80fc737d0b` | Exact deployed profile executable |

This mailbox file is point-in-time evidence and therefore does not embed its
own post-write hash.

## 4. Mock versus production behaviour

- **Developer only:** Active Journey context and Pause Decision State are
  reachable only through the existing guarded developer system.
- **Production Journey truth:** no persisted Journey state or server response
  is replaced or written by these controls.
- **Production Report action:** unchanged; only its collapsed-card visibility
  changes for Potential, Paused and Ended.
- **Active Journey Report:** unchanged and remains available on its existing
  active card.
- **Release:** developer page context and controls remain unavailable through
  the existing release guards.

## 5. Measurements

| Command / observation | Result |
|---|---|
| `dart format` on changed Dart/tests | PASS; final format clean |
| `flutter analyze --no-pub` | PASS; no issues |
| Focused panel/Connections/overlay/pause suite | PASS; 50/50 |
| `flutter test --no-pub --reporter compact` | PASS; 611/611 |
| `python3 tools/zyra_check.py` | PASS; 173 files; 0 findings; 0 new doc refs |
| iOS profile build | PASS; signed `Runner.app` 34.9 MB |
| Wireless device discovery | PASS; iPhone `00008130-001A2C1E26F8001C` reachable |
| Direct install-path launch probe | EXPECTED PATH FAILURE; iOS rejected that path's development signature, so it was not used as completion evidence |
| Wireless Flutter install + launch | PASS via `flutter run --profile --no-pub`; VM service connected |
| Runtime process probe after detach | PASS; `Runner.app/Runner` observed as PID 70886 |
| Founder visual acceptance | PENDING — current build is open on device |
| SQL probe | Not applicable; no database work |

## 6. Limitations and remaining review

1. Active Journey is a pushed product route, so its developer page context is
   intentionally temporary. The guarded restore prevents a newer page choice
   from being overwritten, but Fable should independently verify this
   ownership boundary on disk.
2. The Report visibility change applies to Potential, Paused and Ended only.
   Active is explicitly outside the Founder request and remains unchanged.
3. Founder device review and Fable independent verification remain pending.
   Codex has not self-approved either.

## 7. Documentation reconciliation

`SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md`
now records the page-aware pause ownership and collapsed Report contract in
§27. §26 remains the current Connections-segment contract except where §27
explicitly moves Pause Decision State into Active Journey.

No git command, commit, migration, SQL, credential, package or production
service mutation was performed.
