# TO: Fable
# FROM: Codex
# SUBJECT: Founder style locks + Profile Personalisation — code complete

**Date:** 2026-08-29  
**Status:** CODE COMPLETE; Fable verification and Founder device acceptance pending  
**Authority:** Founder direct instruction in Codex, 2026-08-29  
**Governance:** AD-AIOS-104; Implementation Handover Standard V2  
**OA/DR:** No new product OA/DR identifier was supplied. Fable owns register trace if one is required.  
**Migration:** None authorised, created or applied  

## 1. What exists now

The comparison phase is closed for these product axes:

| Axis | Current state |
|---|---|
| Shared loading | Comet line; every unpinned production loader uses it |
| Background | Midnight Plum default; nine dark member choices in Personalisation |
| Navigation | Floating Glass fixed; no selector |
| Haptic | Subtle default; five semantic member choices in Personalisation |
| Reading text | Poppins default; eighteen member choices in Personalisation; Syne wordmark unchanged |
| Connections cards | Compact Chips fixed in debug/profile/release |
| Connections headings | Accent Marker fixed in debug/profile/release |
| App Surface | Glass Signals fixed; retired stored choices ignored and cleared |
| Home Screen icon | Existing primary Gold Horizon/current-text icon fixed; no selector |

The developer rail is now three doors: Preview, Actions and Home. The Style
door is gone. Home no longer contains App Surface or icon pickers. Connections
Actions no longer contains card/heading pickers. There is no loading picker.

Both Seeker and Guardian Profile now link to one shared Personalisation screen.
It changes presentation only; no matching, entitlement, identity, profile or
server state is touched.

## 2. Why this shape

The Founder explicitly selected fixed winners while retaining only three
member-appropriate choices. Fixed axes therefore resolve in shared production
boundaries rather than page-specific overrides. Background/font/haptic use the
existing app-level notifiers but now have an account-local persistence layer so
they apply immediately, survive navigation/relaunch, hydrate before frame one,
and clear on sign-out.

Light palettes are defended twice: the Personalisation option list filters
them, and `selectAppPalette` refuses them. A stale/deep link cannot restore a
retired light mode.

## 3. Data and navigation flow

```text
Seeker Profile or Guardian Profile
  -> PersonalisationScreen
     -> choose dark background / reading font / haptic semantic
        -> shared notifier updates immediately
        -> ZyraLocalPrefs stores enum name on device

next launch
  -> ZyraLocalPrefs.init()
  -> restore palette/font/haptic before runApp
  -> MaterialApp paints the selected presentation on frame one

sign out
  -> ZyraLocalPrefs.clear()
  -> live palette/font/haptic notifiers reset to defaults
  -> next account inherits nothing
```

App Surface is different: `restoreAppSurfaceStyle` always resolves Glass
Signals and removes any legacy stored value. Connections directly chooses
Compact Chips/Accent Marker. `ZyraLoading()` without an explicit historical
test override directly uses Comet line.

## 4. Live files and SHA-256

### Product/runtime

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/screens/settings/personalisation_screen.dart` | `a72b0c6f20bc75c844b7a272e81c04242904f94dc826c12b54d7340065d3147c` | Shared member screen; nine dark backgrounds, fonts and haptics |
| `SOURCE/lib/screens/profile/profile_screen.dart` | `a92d136e8cf813e17c022aeb8dd9b5693d653b8fcb770fbb2f3c1ec12cdcdfba` | Seeker Profile entry |
| `SOURCE/lib/screens/wali/wali_profile_screen.dart` | `c84b03fe0d5c7f52e219a7051297d7592013d02d24ca13b403f8f2829d5572fc` | Guardian Profile entry |
| `SOURCE/lib/services/zyra_local_prefs.dart` | `87deec0326329ba23d969205bdc46b11d38fe83979e2dcb8123af2d72706794a` | Palette/font/haptic enum-name persistence and sign-out clear |
| `SOURCE/lib/main.dart` | `99abaa97e6e9f702bf0f722f1de0badbb8254b9efd2c479bde044acba51e565e` | First-frame hydration; locked-surface cleanup |
| `SOURCE/lib/services/zyra_auth.dart` | `0343dcd0255c1abe2dcbbd05c08663ce44a30897175280c80767d7615e125699` | Live preference reset on sign-out |
| `SOURCE/lib/theme/zyra_colors.dart` | `21510e780f7664469ce24272c85b063522b08aeac1f635477300ba0b34811363` | Midnight default, dark-choice guard, Glass Signals lock |
| `SOURCE/lib/theme/zyra_text.dart` | `3acb9d973b5dad91f073db8761eb89e1586e28d349f68b6c71f2666db8cffe75` | Poppins default plus persisted member font selection |
| `SOURCE/lib/theme/zyra_interaction_style.dart` | `324cfe8707532ef8988635b75845c9e9e8f902eb18050a44676a4c9fe3256b9c` | Floating Glass/Subtle defaults and persisted member haptic selection |
| `SOURCE/lib/widgets/zyra_loading.dart` | `f067adad9d783ce8f2d4446a668d2c5086f3c25fb74689d1e0ce6c81c2e41e42` | Comet line fixed for shared loaders |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `673f8ae8ba8b161ee2fc0abc9571c1e5532186c00d5a788e3922b72e1fa5fd9d` | Compact Chips and Accent Marker fixed across modes |

### Developer-control retirement

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | `4d9225a6b5cafca66088c182deb8fa330c4dbaefefb4c831a52a08767f451401` | Three-door rail; Home surface/icon controls removed |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `2bce8ab5e1ccc16765133973671858fb2dba208b208d4aa2b337e0f203afb7b4` | Loading/Style and Connections-design controls removed |
| `SOURCE/lib/dev/zyra_global_dev_overlay.dart` | `9e498ed50fdee5998a8b665598581910dabb7381a23ee728b8f324d1095a08b3` | Three-door Entry switch |
| `SOURCE/lib/dev/wali_dev_scenario_panel.dart` | `973d7c8faba38e5007198c4df34304ee940d00a46e971337873f6690009a90ce` | Three-door Guardian panel |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `1f278937c8cb6fdec2b881be10be40dc4b22c68677a4e738a0f6e8663b5cf4e8` | Removed mutable Connections/loading scenario axes |

### Tests changed/added

| File | SHA-256 |
|---|---|
| `SOURCE/test/personalisation_screen_test.dart` | `5f33b1270639a018082f16eb81045d5c793b8042a0cbced8861470296c7fe9e4` |
| `SOURCE/test/dashboard_landing_and_surface_persistence_test.dart` | `723fe6834d71bc8819dfc48126679ba69eab4125b7de8a8cd3ef2b5d25341d02` |
| `SOURCE/test/connections_design_defaults_test.dart` | `0ed22a14edcb036911d3397c48e18e6c2f2d368caeaa93b204c2d37ac4a632f6` |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `1a166b30c57bad5f8d29bc930e95fd2c9302861609643ea9d5d1ca72ccb75815` |
| `SOURCE/test/loading_meet_and_pass_test.dart` | `7f96eaa61a666cc4c8d2c5080de13c8b5b8ef9cb26daf19d28ca472170abde0b` |
| `SOURCE/test/dashboard_lab_test.dart` | `e75780a25ed55e45cd0bfce1d9c5b253767099e158ff46f7bdb9b09a8a593d31` |
| `SOURCE/test/global_dev_overlay_test.dart` | `8aac659aa25a533055936567ddad6bbe36c6703da2667f2133602771af08257b` |
| `SOURCE/test/style_lab_compatibility_test.dart` | `51a8d5d4c7b9f53d287c3c689d4715868a4b635e1f351d5d54645c3eda5b22f0` |
| `SOURCE/test/floating_nav_bar_haptics_test.dart` | `4573ecfe2721d8f92d9999e5d4c0c2c7096627a28433b4eb24b9cb6a5762cae8` |
| `SOURCE/test/global_app_surface_test.dart` | `45346d01bfca5076d569dd55273a62a5d73cf94ce2a0f1a631bd49c11bf4fc44` |

### Documentation reconciled in this cycle

| File | SHA-256 after amendment |
|---|---|
| `SYSTEM/DOCUMENTS/ZYRA_STYLE_DEFAULT_HANDOVER_CURRENT_VERSION_V1.md` | `78d2621ced7706a3ccd52a0ee5211cb0da67342e5d84823a4d5e41fee1eaf7ea` |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` | `51e1e8b4a789b667d60fb086f1fdafcf56eb84e1e1ca73e0ee10231999709547` |
| `SYSTEM/DOCUMENTS/ZYRA_STYLE_LAB_COMBINATOR_HANDOVER_CURRENT_VERSION_V1.md` | `2f5c628d0d5b5241c44e0445850cd6a63a20f03d49c0125eeeae269caacc1d52` |
| `SYSTEM/DOCUMENTS/ZYRA_SETTINGS_REVIEW_CURRENT_VERSION_V1.md` | `3fb35ebc87289fe3af1cff50a163f8700cf3eb77980fe104ac9ca0ee7055c3ef` |

This mailbox file is the point-in-time completion evidence and therefore does
not embed its own post-write hash. Fable can hash it directly during
independent verification.

## 5. Mock, production and retired boundaries

- **Production/live local:** member palette/font/haptic choices persist only
  on this device. They are real presentation settings, not mock profile data.
- **Production fixed:** Comet line, Floating Glass, Compact Chips, Accent
  Marker, Glass Signals and primary Gold Horizon/current-text.
- **No server write:** Personalisation never writes Supabase.
- **Historical/test-only:** explicit loading styles, app-surface/nav variant
  implementations and alternate app-icon assets/controllers remain on disk for
  lineage and focused regression. No live Developer-control or member route
  exposes them.
- **Release safety:** developer rail remains guarded by existing developer
  access/build boundaries. Removing selectors did not add a release bypass.

## 6. Measurements

| Command / observation | Result |
|---|---|
| `dart format` on changed Dart/tests | PASS; final format clean |
| `flutter analyze --no-pub` | PASS; no issues |
| Focused style/Personalisation/Connections/control suite | PASS; 57/57 |
| `flutter test --no-pub` | PASS; 606/606 |
| `python3 tools/zyra_check.py` | PASS; 173 files; 0 findings; 0 new doc refs |
| Compact Personalisation widget fixture | PASS at 320×568; no overflow/exception |
| iOS profile build | PASS; `Runner.app` 34.9 MB |
| Device visibility | PASS; paired iPhone `00008130-001A2C1E26F8001C` reachable |
| Install/run | PASS through signed `flutter run --profile`; VM service connected |
| Detached relaunch | PASS; `devicectl` launched bundle successfully |
| Runtime process probe | PASS; `Runner.app/Runner` observed as PID 70535 |
| Founder visual acceptance | PENDING — app is open for review |
| SQL probe | Not applicable; no database work |

The first direct launch after `flutter install` was denied by iOS because that
replacement had not completed the trusted signed run path. `flutter run
--profile` rebuilt/signed/installed/launched successfully; after ending the
local attach, a fresh `devicectl` launch succeeded. This is recorded rather
than hidden because it distinguishes package presence from a proven launch.

## 7. Limitations and written refusals

1. Only Poppins is bundled. The other seventeen member-visible fonts retain
   their pre-existing `google_fonts` runtime/cache path and may fall back or
   reflow on first offline use. **Written refusal to invent an OA:** the Founder
   explicitly asked to move the existing choices to Personalisation, no runtime
   failure was measured, and Codex does not own the OA register. Fable should
   assign an OA if offline guarantees are required for every font.
2. Historical comparison widgets/enums and alternate icon assets remain in the
   repository but have no runtime selector. **Written refusal to delete now:**
   removal would discard design lineage and broaden this lock task; Fable owns
   archive/reconciliation under the handover standard.
3. Founder visual acceptance and Fable independent verification are pending;
   neither is claimed by Codex.

## 8. Authority map and next steps

| Layer | Authority |
|---|---|
| Product selection | Founder direct instruction, 2026-08-29 |
| Cross-project handover rule | AD-AIOS-104 / Implementation Handover Standard V2 |
| Current style as-built | `ZYRA_STYLE_DEFAULT_HANDOVER_CURRENT_VERSION_V1.md` §11 |
| Current developer-control as-built | `ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` §25 |
| Point-in-time hashes/evidence | This file |
| Superseded comparison model | `ZYRA_STYLE_LAB_COMBINATOR_HANDOVER_CURRENT_VERSION_V1.md`, marked historical pending Fable archive |

Next owners:

1. Founder reviews the open iPhone build.
2. Fable verifies this file against disk, files any required register trace,
   and archives/renames the superseded Style-lab handover.
3. If the Founder selects a non-Poppins font for production, decide whether to
   bundle it before release rather than rely on runtime font retrieval.

No git command, commit, migration, SQL, credential or production service
mutation was performed. Codex has not self-approved this work.
