# TO: Fable
# FROM: Codex
# SUBJECT: Connections Activity production-parity correction — complete

**Date:** 2026-08-29  
**Status:** CODE, TESTS, DOCUMENTATION, BUILD AND DEVICE INSTALL COMPLETE; Founder visual acceptance and Fable verification pending  
**Authority:** Founder direct correction in Codex, 2026-08-29  
**Governance:** AD-AIOS-104; Implementation Handover Standard V2  
**OA/DR:** No new identifier supplied; please attach to the existing Connections implementation trace or register the correction if required  
**Migration:** None authorised, created or applied  

## 1. Supersession

This handover supersedes the labelled/inspection-only local-card statements in
`027_CODEX-FABLE_2026-08-29_CONNECTIONS_ACTIVITY_INTRODUCTION_REPAIR_COMPLETE.md`.
That file remains historical evidence of the pre-Founder-correction state.
The compact Potential-style shell and expanded-only Report flag from 027 remain
current.

`ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` §35 is now the
authoritative implementation handover. It explicitly supersedes the matching
old statements in §§23, 26 and 32.

## 2. Current customer-facing contract

Every Considered, Saved and Passed card now shows name, age and location in its
persistent compact header. No customer-facing **Preview** badge or development
copy is rendered. Report is hidden while collapsed and appears as the quiet
top-right flag after expansion.

Expansion shows View Profile, then exactly:

| State | Ordered secondary pills |
|---|---|
| Considered | Save → Pass → Compatibility Unlock/View Compatibility |
| Saved | Consider → Pass → Compatibility Unlock/View Compatibility |
| Passed | Consider → Save → Compatibility Unlock/View Compatibility |

The two short decisions share a row and Compatibility receives the full-width
third pill below, preserving the required order without truncating the label.
The enlarged-photo expansion remains retired.

Local Introductions use the same customer-facing card and actions. If moved to
Considered, Saved or Passed they retain **Suggested by Ibrahim** on the card and
the View Profile route.

## 3. Architecture and data flow

```text
Real Activity action
  -> AppState optimistic move
  -> ZyraDiscoveryService
  -> existing server truth

Toggle-created Activity action
  -> ZyraDevScenario destination map
  -> exactly one local section
  -> no AppState decision
  -> no Supabase/service write

Toggle-created Report/Hide
  -> shared report UX
  -> scenario-only hidden set
  -> no AppState removal
  -> no Hidden Profiles persistence
  -> no Supabase report/block write
```

Counts in Developer Access are now described as **starting cards**. Moving a
fixture does not falsify the count: the seed remains owned by its origin
control, while one destination map determines where it currently renders.
Lowering that seed count or Reset prunes the fixture wherever it moved.
Stable profile keys prevent expanded/busy widget state transferring to another
person when a row moves.

Release continues to bypass all fixture composition/state.

## 4. Changed files and hashes

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `9dabf9ff5d2f1e527726e00a986ceef6143c412ef6798201a88d69152d3961c5` | Session-only destinations, hidden set, pruning and Reset |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `75cdd3590414021a7a50584826d7d946b2894c4ee815108f00cce467a16d1e5b` | Truthful starting-card and local-test copy |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `9106eaf954fc5046103e757fd1130b2abfc3556d0c58f90414d55fbe13157d4b` | Shared live/local card UI, action order, location, flag, local bucket routing and attribution |
| `SOURCE/lib/widgets/report_profile_sheet.dart` | `4b03b72ca0da3335315b1067ec90939621f6753064e828aeb9dea4cb9111ce15` | Explicit simulated-hide persistence boundary |
| `SOURCE/test/connections_design_defaults_test.dart` | `0c1ebc3ca0128131f2ba360b37544e15407e2dc0c4c200cab0fb6392e16b61db` | Real/local parity, exact pill order/layout, location, Report, no Preview, attribution and one-bucket proof |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `102a6bde4e9362d5d380e45365567bedbb246c763fa6e650edf9cd1d96265a1d` | Local move/hide/prune/reset policy |
| `SOURCE/test/hidden_profiles_and_support_test.dart` | `9cc2e5cbe5fef4ee5f7fcfa84ba8b2cb0bcdff1116233662af0fe346d7a354c5` | Proof that a toggle report does not mutate AppState or Hidden Profiles |
| `SOURCE/build/ios/iphoneos/Runner.app/Runner` | `56e600982d3ebe5e8a49bcd649e8b6ad99d0e21c64102768a7363c3c7cdbb977` | Exact installed profile executable |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` | `2971d2241c76ff6813bbcff50eb317c54c623d638e670ca251ba04c60fbb5a10` | CURRENT implementation truth and supersession trace |

This mailbox file does not embed its own post-write hash.

## 5. Measured evidence

| Command / observation | Result |
|---|---|
| Focused Activity/developer/local-report suite | PASS; 53/53 |
| `flutter test --no-pub` | PASS; 646/646 |
| `flutter analyze --no-pub` | PASS; no issues |
| `python3 tools/zyra_check.py` | PASS; 175 files; 0 findings; 0 new doc refs |
| 286px / 145% text Activity regression | PASS; no exception/overflow |
| Compatibility pill readability structure | PASS; full-width third pill is >1.8× a decision pill |
| Signed iOS profile build | PASS; `Runner.app` 34.8 MB |
| Physical iPhone install | PASS after removal of the exact interrupted ZYRA placeholder; inventory confirms `app.zyraconnect.zyra` 1.0.0 |
| Automated launch | PASS; `devicectl` launched `app.zyraconnect.zyra` on the physical iPhone |
| Founder device acceptance | PENDING |
| Fable independent disk verification | PENDING |
| SQL probe | Not applicable; no database work |

## 6. Deployment recovery

The first Flutter install was waiting behind a stale 40-minute ZYRA device
launch and an unrelated concurrent `flutter run`. Codex measured and stopped
only those exact ZYRA tooling processes. The interrupted uninstall left an iOS
placeholder; Codex removed only `app.zyraconnect.zyra`, rebuilt cleanly,
installed the full signed app, verified the inventory row and launched it.
No manual Founder action is required for this deployment.

No git command, commit, migration, SQL, credential, package, entitlement or
production-service mutation was performed.
