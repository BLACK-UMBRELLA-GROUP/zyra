TO: Fable / Architecture Reviewer
FROM: Codex / Lead Architect
DATE: 2026-08-28
SUBJECT: Loading Lab + Connections hierarchy + Introduction control — code complete

Founder direct authority has been implemented. No migration was required or
applied, no git action was used and no production trust boundary was widened.

## What changed

1. Shared loading now has ten real developer-selectable animations under
   Style. Meet & pass remains the release/reset default pending Founder device
   selection. Every option has a reduced-motion frame and none renders the
   locked splash wordmark.
2. Potential, Paused and Ended cards use the same top-right Report flag as
   Active. Potential fills its strip with Profile + Compatibility. Paused and
   Ended group Timeline + View Compatibility under JOURNEY; Paused separately
   fills Profile + End Journey. Ended truthfully has Profile alone outside the
   historical group. All `Paused together` copy is gone.
3. Every Connections View Profile uses one modal route: no top-left X; swipe
   down dismisses and a short swipe returns to rest. Other profile-entry paths
   retain their existing close behavior.
4. Test Introductions now opens Connections → Introductions. The real guarded
   RPC remains authoritative. On `dev_accounts_only` only, an authorised
   non-test developer may stage 0–5 explicit, local, non-release `Preview`
   cards. These preserve real rows, are session/reset-bound and inspection-only
   so they cannot call Report or decision/purchase writes. Other failures do
   not fake success.

## Data and navigation flow

```text
Style control
  → ZyraDevScenario
  → shared ValueNotifier<ZyraLoadingStyle>
  → every unpinned ZyraLoading

Test Introductions
  → guarded zyra_dev_set_guardian_suggestions RPC
      ├── success: real count + refresh
      ├── dev_accounts_only: explicit local Preview count
      └── other failure: no fallback
  → ZyraDevSurfaceCoordinator
  → HomeShell existing Connections section controller
  → Introductions

Connections View Profile
  → pushZyraConnectionsProfile
  → SeekerProfileScreen(swipeDownToDismiss: true)
```

## Live files and hashes

- `SOURCE/lib/widgets/zyra_loading.dart` — `40dd86f9adc1b10cf777d7da95524fe065ccb636f9927431069dfb63f12ac459`
- `SOURCE/lib/dev/zyra_dev_scenario.dart` — `2ed58aebb81c6b7158c3f29f84b2ef2b3763447532d6369b6ec5ecd714efad07`
- `SOURCE/lib/dev/dev_scenario_panel_v2.dart` — `1c0011bf9be4325e1cc5cf7a78c38f9d8be1de08dfa8b16c50d682a624f9ece5`
- `SOURCE/lib/dev/zyra_dev_surface_coordinator.dart` — `d21cda2a6a91152a941124d37afce329a7090ad045251065361070aa019e8145`
- `SOURCE/lib/dev/zyra_global_dev_overlay.dart` — `771fc16b9ee7820818062de963b6b503eddf01de3861987c87e4465449265cce`
- `SOURCE/lib/screens/home/home_shell.dart` — `8a5900fd842f34cde2adfefa71180b680b31734515d9012d69ea25be015ce20e`
- `SOURCE/lib/screens/connections/connections_screen.dart` — `44cb47cbd9bf1c5a99d43f286665affbe160d6fcd7fd60c85bdd6c5f225072c7`
- `SOURCE/lib/screens/profile/seeker_profile_screen.dart` — `7684c0651a55da6709e7fece79b796df01bfafa2f4ace7b12eb02030bb0a9da2`
- `SOURCE/test/loading_meet_and_pass_test.dart` — `bb89fbb9bf9aec22d12110f0db37b0a91edf2acc42d5b994e10c0012406c12b5`
- `SOURCE/test/dev_scenario_panel_policy_test.dart` — `9b6eb61c7728446f3d07df39cead00cdde30718a4818796b67c3ec50e2aed939`
- `SOURCE/test/global_dev_overlay_test.dart` — `ecc55674241e2f3618e9ca2525552a6d19d9d4dc3543d2a33cfe1d2a846c613d`
- `SOURCE/test/connections_design_defaults_test.dart` — `f5e469afd725254b2ddbf1d03b03ec4d65665108ecbdcca906aed7878611e3dc`
- `SOURCE/test/connections_profile_dismiss_test.dart` — `f09e6760699a2960e117ee28147dd51c0fe0a8a94b51453375415365f4be1c42`

Documentation reconciled:

- `SYSTEM/DOCUMENTS/ZYRA_SPLASH_SCREEN_HANDOVER_CURRENT_VERSION_V1.md` — `5572b39a4a6cc738f8a5840cb73e7bba915f19264c5667d1dee7399f4c42c430`
- `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` — `91d66cd2fe032061fdbd7644ab7a73aa2efbcbd86b1d6142e68fc8fd0708feb2`
- `APP/Navigation/SEEKER NAVIGATION/Summary.md` — `afa910de965aef5f56d52b42fd9374fddc3eeab046fa0dca6b9507f99daed660`

## Measured evidence

- Formatter: 13 changed Dart files checked, 0 changed.
- Focused changed-path suite: **40/40 PASS**.
- Full Flutter suite: **577/577 PASS**.
- `flutter analyze --no-pub`: **PASS, no issues**.
- Governed visual gate run `f4d0b6ae`: **215/215 render variants PASS**;
  formatter, analyzer, inventory, L1 gate, structural self-tests, ZYRA checker,
  visual render suite and complete Flutter suite all pass. Verdict is
  **BASELINE-PENDING**, not failed: there are zero Founder-approved screenshot
  baselines and Codex did not self-approve any.
- Visual report hash:
  `99229a4e3f4f5ae3d74ffeb24b288edf1e64adb98277c9ddaf38550d07963f60`.
- Signed iOS profile build: **PASS**, 36.6 MB.
- Wireless `flutter install --profile`: **exit 0** on the paired iPhone.
- Automatic Flutter VM-service attachment after launch: **PENDING**; Apple's
  CoreDevice handoff timed out after install. This is recorded honestly and is
  not presented as a successful attached debug session.
- SQL probe: not applicable; no database change.

## Limitations / next gate

- Founder device selection among the ten loaders is pending; no release loader
  was changed.
- Founder device observation of card proportions, swipe feel and Introduction
  Preview behavior is pending.
- `admin@zyraconnect.app` still cannot create server test Introduction rows.
  That guarded boundary remains intentional; only a clearly labelled local
  developer preview was added.
- Please verify this handover against disk, register/reconcile any OA/DR trace
  you consider required, and do not treat Codex's evidence as self-approval.
