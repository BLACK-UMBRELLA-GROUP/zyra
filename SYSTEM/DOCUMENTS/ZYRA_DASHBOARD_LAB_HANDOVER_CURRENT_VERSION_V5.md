# ZYRA Dashboard Lab — Implementation Handover

**Version:** V5  
**Status:** CURRENT_VERSION — CODE COMPLETE AND MEASURED; DASHBOARD DEFAULT LANDING; GLOBAL SURFACES; DASHBOARD INVITATIONS; Founder phone review pending  
**Date:** 2026-08-25; updated 2026-08-28  
**Implementer:** Codex, Lead Architect  
**Authority:** Founder instructions, 2026-08-25–27: test five stronger Dashboard hierarchies over one state, make Classic Glass the shared app-surface default, make Dashboard the normal authenticated landing page, move Guardian invitations to Dashboard, repair every Dashboard destination, and expose five active Guardian-page experiments  
**Supersedes:** `SYSTEM/DOCUMENTS/ARCHIVE/ZYRA_DASHBOARD_LAB_HANDOVER_SUPERSEDED_V4.md`  
**Related rules:** `ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md` · `ZYRA_LEARNING_LOOP_DATA_AUDIT_CURRENT_VERSION_V1.md`  
**Production relationship:** The five Dashboard layouts remain developer-only mock renderers, but as of §10G they construct a typed snapshot and consume the same pure `DashboardResolution` as the single production renderer. Dashboard landing, global surface tokens, truthful invitation workflow and explicit destination routing are live. Guardian Pulse is the production Route-2 base; its four sibling Guardian compositions remain developer-only.

## 1 · What exists

The Dashboard Lab exposes five selectable hierarchy comparisons over the same
underlying state:

1. **Now / Journey / You** — attention first, current Journey second, personal
   context third. This is the Lab reset state only.
2. **ZYRA Compass** — one daily focus, compact status board and supporting
   insight.
3. **Journey Lens** — active/potential/paused/searching state is the centre.
4. **Living Priorities** — one primary and two secondary priorities, with
   quieter information progressively disclosed.
5. **Progress Story** — where the member is, what moved and what comes next.

The Dashboard-specific layout selector is session-only and changes both role
mock renderers immediately. There is no Dashboard-specific colour/surface
selector: the one app-wide **App Surface** control lives under the developer
**Home** door and offers:

- **Classic Glass** — ZYRA's existing `glassFill` and `glassBorder` surface
  tokens plus one restrained `actionFill` lavender accent for icons, progress
  and priority indicators. This is the current app-wide default.
- **Glass Signals** — neutral Classic Glass surfaces with meaningful colour
  retained for icons and progress signals.
- **Status Accents** — stronger semantic colour on status surfaces and active
  highlights.

The Home selection is global and device-local: it rebuilds shared theme-token
readers across the mounted app, is passed into both Seeker and Guardian
Dashboard mock configurations, and is restored before `runApp` on relaunch.
Dashboard scenario, role, module and ordering controls remain independent of
that global choice. Sign-out/shared reset clears the stored comparison and
restores Classic Glass; there is no server or member profile preference.

## 2 · Why this was built this way

The Founder asked for five genuinely different ways to answer what needs
attention, what is happening, what changed and what comes next. All five use
the same modules and truth boundary while varying hierarchy, density,
progressive disclosure and narrative. Reset returns Now / Journey / You; this
does not approve it as production design.

The shared information architecture now separates **To Do**, **Journey
Status**, **Insights for You**, **Updates** and **Explore/Guardian Tools**.
Module-order controls preserve the selected order inside those categories.

Classic Glass reuses the live ZYRA design tokens rather than adding a second
purple palette or hard-coded imitation. It removes module-specific colour
tints from the card surfaces, uses the shared glass fill/border, removes the
coloured elevated-card glow, and resolves all module accents to the current
interactive lavender. This makes the Dashboard feel closer to the rest of the
app while keeping the information structure unchanged.

Surface language moved out of the Dashboard Lab because it is not a Dashboard
property. `ZyraColors` owns one app-wide selection, `ZyraApp` listens to it, and
shared progress, icon-button, selected-frost and glass tokens resolve through
that selection. This prevents a Dashboard-only control from claiming to change
an app-wide visual system.

No extra `BackdropFilter` layer was added to every Dashboard card. Classic
Glass uses the existing app glass surface recipe without multiplying full-page
blur work in a long scrolling Dashboard.

## 3 · Seeker and Wali parity

Both developer role previews receive the same selected layout and app-wide
surface through one shared mock renderer and one shared scenario store. Their
mock information remains role-specific:

| Section purpose | Seeker | Wali |
|---|---|---|
| Setup | Remaining onboarding answers | Not shown |
| To Do | Next useful action/decision | Next useful action/decision |
| Journey status | Current Journey | Seekers and Journeys |
| Insights for You | Seeker-only developer mock | Not shown |
| Updates | Personal activity and family progress | Family/Seeker activity |
| Tools | Discovery, Saved, Compatibility, Profile | Guardian Network and Wali tools |

The surface switch never copies Seeker content into the Guardian shell and
never changes destination routing. Outside the enabled Lab, both roles keep
their existing production Dashboard implementations and data sources.

## 4 · Architecture and data flow

```text
Authorised developer → Home → ZyraDevAppSurfacePicker
      ↓ ZyraColors.selectAppSurfaceStyle(...)
ZyraLocalPrefs.cachedAppSurfaceStyleName → restore before runApp
      ↓
ZyraColors.appSurfaceStyleSelection (global ValueNotifier)
      ├── ZyraApp listener → rebuild mounted app
      │      └── shared progress/icon/frost/glass theme tokens
      └── ZyraDevScenario.dashboardConfigFor(hostRole)
             ↓ ZyraDashboardViewConfig.surfaceStyle + destination intent
Seeker mock host ─┐
                  ├── ZyraDashboardExperience
Guardian mock host┘      ├── selected five-way hierarchy renderer
                         └── _DashboardSurfaceScope
                              ├── Classic Glass → neutral glass + actionFill
                              ├── Glass Signals → neutral glass + semantic signals
                              └── Status Accents → tinted surfaces + semantic signals

Dashboard Actions → ZyraDashboardLabControls
      ├── five session-only layout choices
      └── Lab enablement, preview role and mock scenario controls
```

`ZyraDevScenario.dashboardConcept` owns the session-only layout selection and
passes it into every generated `ZyraDashboardViewConfig`. Reset resolves to
`ZyraDashboardConcept.nowJourneyYou`. `_DashboardSurfaceScope` remains
private to the mock renderer and falls back safely to Classic Glass. Surface
state itself is not owned by `ZyraDevScenario`; the config reads current
`ZyraColors.appSurfaceStyle` so both role renderers receive the global choice.

## 5 · Developer controls

Open **Home → App Surface** from any developer context to select:

- **Classic Glass**;
- **Glass Signals**; or
- **Status Accents**.

Then open either role's **Dashboard → Actions → Dashboard Lab**. Choose Now /
Journey / You, ZYRA Compass, Journey Lens, Living Priorities or Progress Story.
The Lab contains no surface selector. **Preview Role** compares
the same layout and global surface on the Seeker or Guardian mock.

The selection is persisted on the device. **Reset Dashboard Lab** resets mock
scenario state but does not override the app-wide surface. The shared developer
reset, sign-out boundary and **Restore default style** return the surface to
Classic Glass. No member-profile or server write is created, and release
builds expose no selector.

## 6 · Mock versus production

| Area | Dashboard Lab | Production |
|---|---|---|
| Layout | Five hierarchy renderers; Now / Journey / You is the Lab reset state | Existing Seeker and Guardian Dashboard UI remains live; no comparison is promoted |
| Surface control | Home offers Classic Glass, Glass Signals and Status Accents | No developer selector; Classic Glass is the fixed default |
| Surface execution | Selected style flows through shared theme tokens and both mock configs | Tokenized production UI uses the Classic Glass default |
| Role data | Deterministic Seeker/Guardian examples | Existing data adapters and live state remain authoritative |
| Learning | Mock-only states and local responses | Automated conclusions inactive |
| Persistence | Surface `ValueNotifier` plus device-local `ZyraLocalPrefs`; Dashboard scenario remains session-only | No database/account preference or write |
| Backend | No reads/writes added | No schema/RPC/RLS/auth change |

The production/release distinction is deliberate: `ZyraDashboardExperience`
still renders deterministic Lab content. When developer access is unavailable,
or the Lab is off, `SeekerDashboardScreen` and `WaliDashboardScreen` continue
to render their truthful existing Dashboard paths instead.

## 7 · Live files and responsibilities

| File | Current responsibility |
|---|---|
| `SOURCE/lib/theme/zyra_colors.dart` | Three app-surface options, Classic Glass default, global notifier and shared surface-token resolution |
| `SOURCE/lib/services/zyra_local_prefs.dart` | Device-local app-surface name persistence and clear boundary |
| `SOURCE/lib/main.dart` | Listens to the app-surface notifier and rebuilds mounted theme readers without replacing navigation state |
| `SOURCE/lib/services/zyra_session_router.dart` | Routes normal complete/incomplete Seeker sessions to Dashboard; preserves auth/missing-profile branches |
| `SOURCE/lib/screens/home/home_shell.dart` | Dashboard is the default Seeker tab and remains tab index 2 |
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | Home-owned App Surface picker plus shared/default-style restore to Classic Glass |
| `SOURCE/lib/models/zyra_dashboard_lab.dart` | Five-layout model, explicit Dashboard destinations, insight labels and role/scenario configuration |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | Session layout state, Now / Journey / You reset, global surface pass-through and Lab state |
| `SOURCE/lib/dev/zyra_dashboard_lab_controls.dart` | Five-choice layout, role/scenario/learning/module controls; no surface selector |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | Five shared hierarchy renderers, progressive disclosure, typed actions, insight preview and three-way surface interpretation |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | Seeker mock-host gate and existing truthful Dashboard fallback |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | Guardian mock-host gate and existing truthful Dashboard fallback |
| `SOURCE/lib/widgets/zyra_guardian_invitation_dashboard.dart` | Shared role-aware Dashboard status module; live sent/cancel and received-preview actions only; collapses with no visible invitation state |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | Five real Seeker Guardian-page renderers over one data/callback contract — FOUNDER DESIGN SELECTION PENDING |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | Linked-Guardian host; no longer owns invitation status/actions |
| `SOURCE/test/dashboard_lab_test.dart` | Five-choice/reset, A–H state, insight interaction, role/surface and 130%-text coverage |
| `SOURCE/test/dashboard_destination_routing_test.dart` | Full contextual destination matrix, original “See what changed” regression and Connections section-controller semantics |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | Seeker host and developer-boundary coverage definitions |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | Dashboard fixtures across five layouts, both roles, three surfaces, three sizes and 130% text |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | Shared Home selector presence and Restore-default coverage |
| `SOURCE/test/global_dev_overlay_test.dart` | App-wide developer overlay/default isolation coverage |
| `SOURCE/test/style_lab_compatibility_test.dart` | Shared style combinations on compact phones |
| `SYSTEM/RESOURCES/UI_GATE/state_matrix.json` | Declares the current five layouts across both roles, three surfaces and large text |

### Changed-file SHA-256 evidence — measured 2026-08-26

| File | SHA-256 |
|---|---|
| `SOURCE/lib/theme/zyra_colors.dart` | `91c1cf87372037b81f6a14da934ff977f2cc0f8fb311d29cdafaaae2361c7841` |
| `SOURCE/lib/models/zyra_dashboard_lab.dart` | `5d069aca716d2237c30faaad482dcdd3bdbff551ddcb5680b7d434f8e777d525` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `a5d216ecb122ec6e20dfca8597feed36eaf1d4b8289d644b9b62486bfc0523c7` |
| `SOURCE/lib/dev/zyra_dashboard_lab_controls.dart` | `c608d3fb8caff3b1d0466c7c823887553cb6a7d66d01e3dc87cc0613444b7470` |
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | `136df69b97fcc0b82967d76267f581905dbb275088ac3e0b8fa1bf124d4f096a` |
| `SOURCE/lib/main.dart` | `a7ae853ff4b9f2640396f1d890f42de062f0304b7d2ae031c5999b53ffea5e32` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | `57b98a0c605fef8abb839e81c57a29418b6851e5e526639a1cda857e8988d176` |
| `SOURCE/test/dashboard_lab_test.dart` | `207f41caee514aea1f43e5a78ce40b45b985254002309dbf9e3a79cda7aabad8` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `a975f9a92b1cbd117533a06de2e6c55b3c15b77661e01616a23365ea781edebd` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | `185d7bab382acc131cf50ca3302134e41153d7a492cba8a0b4e1f0b5e1bd7f05` |
| `SOURCE/test/global_dev_overlay_test.dart` | `f40471fecc2b0663b2137c9647f43bf96228490ec42318cf70cbebb593d7db4d` |
| `SOURCE/test/style_lab_compatibility_test.dart` | `0238d320823be69778d429cf2030ef34c10e512d8cb7911e1c250674964ae43d` |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `f0991a0db493b8ce8f1f1b73f40ff17cdb40096bb22c684a648d47e8b6f85d9d` |
| `SYSTEM/RESOURCES/UI_GATE/state_matrix.json` | `04a1c43d1424168bc963a1fd074d424bd808ab5ca3258801880df72a7e28c74a` |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` | `ad94a5362152c728c44406fb505a5f1d71cd2420ef3638c2885869f694c0da0d` |
| `SYSTEM/DOCUMENTS/ZYRA_STYLE_LAB_COMBINATOR_HANDOVER_2026-08-29_V1.md` | `a8a67395fc25883f067d7e6bb7849151b29f8d43d077ce9e7a2fb6b4d7bcde11` |

This handover omits its own hash because embedding it would change the value.

## 8 · Measured verification

| Measurement | Result on the 2026-08-26 amendment |
|---|---|
| `dart format` on every changed Dart file | PASS · formatter completed with no remaining changes |
| Focused Dashboard/Home/role/style widget suites | PASS · final run completed with zero failures; covers the locked layout, all three Home options, both roles, global reset and Style restore |
| `flutter test --no-pub test/visual/zyra_visual_regression_test.dart --reporter compact` | PASS · **190/190**, including Classic Glass, Glass Signals and Status Accents at small/standard/large sizes |
| `flutter test --no-pub --reporter compact` | PASS · **474/474** full Flutter regression |
| `flutter analyze` | PASS · **No issues found** |
| `python3 tools/zyra_check.py` | PASS · 167 files; **0 findings**; 5 baselined dangling references and 0 new references |
| `python3 -m json.tool SYSTEM/RESOURCES/UI_GATE/state_matrix.json` | PASS · valid JSON; twelve Glass Signals Dashboard fixtures declared |
| `flutter build ios --profile --no-codesign` | PASS · `build/ios/iphoneos/Runner.app`, **36.0 MB** |
| SQL probe | Not applicable · no database change |
| Wireless physical-iPhone delivery | PASS · paired `00008130-001A2C1E26F8001C` detected; profile Xcode build 52.4s; wireless install/launch 31.4s; Flutter VM service confirmed; detached after launch |
| Founder touch/design comparison | PENDING · automated deployment proves build/install/launch, not the Founder's visual selection among five Guardian designs |

The first focused run exposed one stale test-copy expectation after the
default summary gained “Classic Glass”. The expectation was corrected and the
focused and full suites were rerun green. Candidate renders remain evidence
only; no visual baseline or remaining comparison was self-approved.

## 9 · Migrations

No migration was created or applied. No schema, RLS policy, RPC, trigger,
Storage rule, authentication state or entitlement was changed. The only new
persistence is the non-sensitive device-local developer App Surface name.

## 10 · Known limitations and remaining work

1. Now / Journey / You is the Dashboard Lab reset state, with four sibling
   session-only Founder comparisons. Classic Glass remains the app-surface
   default; Glass Signals and Status Accents remain available from Home.
2. Alternate surface selection is intentionally developer-only and persists
   on that device across relaunch. Sign-out/shared reset restores Classic Glass.
3. Classic Glass is a surface-token treatment, not a full-screen stack of
   Gaussian blur filters; this keeps the comparison aligned with current app
   tokens without introducing a likely heat/performance regression.
4. The Dashboard Lab renderers (Now / Journey / You and its four siblings)
   still use deterministic mock content; none is a production Dashboard
   adapter. **Written refusal — no OA raised at the time:** retaining the
   existing data-backed release Dashboards was the intentional truth boundary
   until a production renderer/data-adapter build was authorised. *(Fable
   reconciliation 2026-08-28: that build is now authorised — DR-ZYRA-216 /
   OA-ZYRA-264; "Sectioned Status" in the earlier wording of this item was a
   stale name for the current five-concept family.)*
5. Visual baselines remain Founder-pending under OA-ZYRA-257.
6. OA-ZYRA-259 production learning remains inactive.
7. Fable must verify this V5 handover against disk and reconcile register
   trace/document references.

## 10A · 2026-08-26 authenticated-home and Guardian amendment

- Normal authenticated Seeker sessions now enter `HomeShell(initialTab: 2)`;
  Wali/Guardian sessions continue to enter their Dashboard at index 0. Auth,
  missing-profile and role-selection branches remain ahead of the shell.
- App Surface is one global selection. Shared fills, borders, selected states,
  progress, dialogs, cards, navigation chrome and supported Browser overlays
  consume `ZyraColors` surface tokens across Dashboard, Connections, the
  Seeker Guardian page, Wali/Guardian surfaces, Profile and Browser chrome.
- Guardian account-link invitations have one ongoing-status location:
  Dashboard. Live sent invitations can be cancelled there, but generic bearer
  code entry now lives behind the Seeker Guardian page's top-right `+`. The current schema
  cannot list an addressed recipient, so named received rows are explicitly
  developer preview and never presented as production data.
- The Seeker Guardian page retains linked-Guardian data, activity, detail and
  add flows. The five names and content structures recorded here were the
  second-round state and are superseded by §10C. The shared Focus Carousel,
  top-right Add Guardian control, near-full-page envelope, SafeArea/nav cap,
  removed hierarchy copy and quiet progress dots remain current.
  **FOUNDER DESIGN
  SELECTION PENDING.** These are not Guardian Network
  family-connection designs and are not final product approval.
- Connections keeps the Introductions destination but removes the redundant
  internal singular `Introduction` heading and its abandoned gap.

### Current amendment hashes

| File | SHA-256 |
|---|---|
| `SOURCE/lib/theme/zyra_colors.dart` | `b42b442cd5438dfa02c3ed12ed68b3339d253b0b6a59ee7cd6e6770511afa204` |
| `SOURCE/lib/services/zyra_local_prefs.dart` | `6b3308ca39e3ea7f9453530330c4df517428b4b4d6c7e74443ac328f9836a1ca` |
| `SOURCE/lib/main.dart` | `db774e84427435596e21dc607d95a5b9ad737fa7b74672d1d2571ea436dac5fc` |
| `SOURCE/lib/services/zyra_session_router.dart` | `016ea216d2e61e9230494d297031c2d5cd09f9476a14efe4715ee83be7f99635` |
| `SOURCE/lib/screens/home/home_shell.dart` | `96bfb85bed460fb7a3082ede2b44a1119992877ab10a0016e5adcbf77db4b2b6` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | `66fd2285c089ba84aaa51c559f8e1cec0cee2edc785c3de92f76b8e23d186693` |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | `2ecc207868d9898a18347bb8b0a2f75d27ca4e4311ecbfe8273eee711c287e28` |
| `SOURCE/lib/widgets/zyra_guardian_invitation_dashboard.dart` | `687516b1fe2660eec63e921c1e8b6c836604362ef0f947df308422875898f941` |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `66f22677569c2e7e482e5c65f9e26e0fcd8c1d43c33327a153f9885cff0986c5` |
| `SOURCE/lib/screens/wali/link_guardian_panel.dart` | `8ed079b4efcfff6b8604a99e481b5e442ac3d4f572ee153113eb15d479f34bf6` |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | `5bdcd86517ce695fd93a5509f026fd87f5d6eb08438f82534e0cc1ebb87d0134` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `be47686ec720bbe92d2efc5da6739230388c30faa752dc8d38c611aaf4810b6b` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `6dfac75976081b18df9006c457950a2303f25762577d48d77361158d3e1089d2` |
| `SOURCE/lib/services/zyra_wali_link_service.dart` | `808f1cb54b1c5e20b1166fcf13e7cb7eb02fe30b12178644940f6429915d2824` |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `fa02bd388f9a3e109cd2a54d1ae8da369a5ae75bbf9eea25e24d531bd5cdd618` |
| `SOURCE/test/dashboard_landing_and_surface_persistence_test.dart` | `318e32ef996429482a3b2b20c71fe1722ed4ea700e7825c98ba4e1ebc0f7a6d2` |
| `SOURCE/test/global_app_surface_test.dart` | `0027dcbcc306bf1c9840ca1ac4d696e72fecd03ccb7269f4b825a5378384558c` |
| `SOURCE/test/guardian_page_design_test.dart` | `ca5afd6d575aa86a921f04703f86441465a1195cbdfefb0ecf063e4db64278ab` |
| `SOURCE/test/guardian_design_control_test.dart` | `00372bccc7de089403552b2724d2b9e992d470d6bcd2af23134b95c1e60df7fe` |
| `SOURCE/test/guardian_invitation_dashboard_test.dart` | `81cd6659b2c307d3f07ca559bfc65a559e910f780b6f7d16323d7bfe035a8c9e` |

No OA identifier was invented for this Founder-direct batch. No migration,
commit or git mutation was used; one read-only status inspection occurred.
Fable verification and Founder device design
selection remain external approval steps.

Latest Guardian follow-up measurement, 2026-08-27: Guardian page 14/14;
at least 580 px card height plus at least 8 px navigation clearance on a
393×852 Dynamic Island fixture; full Flutter 488/488;
direct visual 190/190; analyzer clean; ZYRA checker 0 findings; signed iOS
profile build 34.6 MB. The signed app was installed and launched wirelessly;
the iPhone process was confirmed after detaching the local VM-service connector.
The removed-copy and near-full-page sizing assertions are part of the focused
suite. No database or migration work was involved.

## 10B · Historical cleaner-sectioned amendment — superseded by §10D

Founder instruction reopened five comparisons while retaining Sectioned Status
as the layout foundation and reset/default. Dashboard Actions now exposes six
real choices: Sectioned Status, Priority Focus, Compact Groups, Progress View,
Grouped Cards and Guided Path. Both Seeker and Guardian mock hosts consume the
same selected concept immediately; layout state remains session-only.

Every renderer now separates the same data into explicit **To Do**, **Journey
Status**, **Insights for You**, **Updates** and **Explore/Guardian Tools**
categories. The renderer preserves developer module order inside its category.
The former `WHAT ZYRA IS LEARNING` copy is removed from both the Lab renderer
and the existing Seeker-hub preview.

The Seeker-only learning mock is now titled **Insights for You**. Its four
states use `MORE TO EXPLORE`, `WORKING WELL`, `WORTH CONSIDERING` and `REVIEW
OPTION` status language. Expanding an insight shows **What this reflects**,
**How this can help** and aggregate **What shaped this insight** copy. A quiet
options menu supports `Not useful to me` and `Hide similar insights`, with Undo;
feedback remains widget-local and cannot alter a preference or production
learning record. OA-ZYRA-259 production learning remains inactive.

### Current amendment hashes

| File | SHA-256 |
|---|---|
| `SOURCE/lib/models/zyra_dashboard_lab.dart` | `e773c93bd4f696104f82a6025e40395339b6125234c3fa4046d87d61ff53d347` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `80ba27055f6658b1b515e9400d2eafcf4dae43ed4551f40c05ede9119414536b` |
| `SOURCE/lib/dev/zyra_dashboard_lab_controls.dart` | `06e9bc9aaa9a8ac8348099ac663141add8583e4e85ff1ae6560a56e67e5f1d58` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | `45ca1e1b4d84743fe312eb1454097a45527ef22a7dba0efe1fa2c445cb896d4e` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | `de39004af609e4fde9618af5c9fbc9eb62269e2f9464789a9e028bad1b10b514` |
| `SOURCE/test/dashboard_lab_test.dart` | `54986e8405f4952e0ff8a4615a4339dffb347cc55de9c2baadcb1a384ab66cd9` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | `0e2cf09187839e4bcba794a41b9c816202e4a418ff63be90f4f37c5449e857dd` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `54e94c5fae9bab6eb1d3032e303d5cba77d750d60980ea8d4c0a814526eaeff9` |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` | `5bae5dcf3b561c83df36faaac4aa5087dfffffe54d46af391c4e0dba342d98e5` |
| `APP/Navigation/SEEKER NAVIGATION/Summary.md` | `467299ebba74517f00e192d8e3f8855484734f9e6dfeb0d4f983ed5010837522` |

Measured verification: focused Dashboard/current-hub/control suite **74/74**;
direct visual matrix **238/238**, covering all six layouts, both roles, three
app surfaces, small/standard/large fixtures and 130% text; full Flutter suite
**539/539**; analyzer clean; ZYRA checker 0 findings; signed iOS profile build
**34.7 MB**. The build installed and launched wirelessly on paired iPhone
`00008130-001A2C1E26F8001C`; the phone process remained live after detaching the
Mac-side launcher. No migration, Supabase write, commit or git mutation was
used. Founder layout selection beyond the retained Sectioned Status default is
pending; visual candidates were not self-approved.

## 10C · Historical Guardian density amendment — superseded by §10E

The Focus Carousel envelope is unchanged, while its five experimental card
contents are replaced by Guardian Brief, Connection Path, Profile Mosaic, Role
Chapters and Current Focus. The former sparse layouts, Activity Story and Detail
Tray are no longer selectable. Reset returns Guardian Brief. Relationship,
Main/Additional role, active link, linked time and at most one prioritised
current activity fill the card through distinct information structures; no
unsupported identity, photo, verification, location, plan or Journey metric is
invented. Whole-card detail and top-right add callbacks are unchanged.

The focused Guardian/control suite is **16/16** and asserts at least three
structured regions per concept, all three global surfaces, empty/one/six states,
swipe/open/add, Main ordering, 320×568 at 130% text and missing/long fields. A
393×852 Dynamic Island fixture measures every card at least 580 px tall with at
least 8 px navigation clearance. Direct visual is **238/238**, full Flutter is
**540/540**, analyzer is clean and the ZYRA checker reports 0 findings. Signed
iOS profile build succeeded at **34.7 MB**; the paired iPhone was found
wirelessly and install/launch completed with a live VM service and Runner
process before the Mac-side launcher detached. No migration, Supabase write,
commit or git mutation was used. **FOUNDER DESIGN SELECTION PENDING.**

## 10D · 2026-08-27 current Dashboard hierarchy and routing amendment

The current Lab contains exactly five layouts: **Now / Journey / You**, **ZYRA
Compass**, **Journey Lens**, **Living Priorities** and **Progress Story**. All
five consume the same A–H scenario state and module data; Now / Journey / You is
only the developer reset state. None is production-approved. **FOUNDER DESIGN
SELECTION PENDING.**

Dashboard actions now carry explicit destinations rather than a generic
“activity” callback. The current Seeker matrix is:

| Dashboard content | Destination |
|---|---|
| Active, potential, paused or ended Journey; next step; compatibility; milestone; Journey activity | Connections → Journeys |
| Saved profiles; family introduction | Connections → Activity |
| Guardian activity | Guardian |
| Discovery/no-Journey prompt | Browse |
| Incomplete setup | Onboarding |
| Profile readiness | Profile |
| Preference-review insight | Edit Profile / preferences |
| Explicit legacy Notifications card | Notifications manager |

`HomeShell` owns a `ZyraConnectionsSectionController`. It sends a section intent
before selecting the kept-alive Connections tab, so a user who last viewed
Introductions cannot be taken back there by a Journey action. External requests
notify even when the requested section matches the controller's stored value;
user-driven page synchronisation records state without a notification loop.
The original Founder regression is covered directly: active Journey + new
activity + onboarding complete + “See what changed” resolves to Connections →
Journeys and does not call Notifications.

The quieter-information limit in ZYRA Compass and Journey Lens no longer drops
modules: secondary items remain reachable through progressive disclosure. The
preference insight opens the actual preference editor. Guardian invitation
cancel retry now retries the failed revoke rather than merely refreshing.

## 10E · 2026-08-27 current Guardian-page comparison amendment

The unchanged large Focus Carousel envelope now presents **Guardian pulse**,
**Shared path**, **Action board**, **Activity flow** and **Living link**. Reset
returns Guardian pulse. Each uses the same real linked-Guardian record,
recognised activity list, top-right Add action and whole-card detail callback.
No verification, photo, online state, unsupported Journey metric or other fake
business state is introduced. Empty, one and six Guardians, ID-stable reorder,
all three App Surface modes, 320 px width at 130% text and long/missing values
are included in focused tests. **FOUNDER DESIGN SELECTION PENDING.**

The authoritative detail for these five options is
`ZYRA_GUARDIAN_PAGE_REVIEW_CURRENT_VERSION_V1.md`; prior Guardian option names
in §§10A/10C are retained only as superseded implementation lineage.

## 10F · Final combined implementation evidence — 2026-08-27

| File | SHA-256 |
|---|---|
| `SOURCE/lib/models/zyra_dashboard_lab.dart` | `f9cd3c9f225ebfafa5a00dce81666e4f553d910079546a73a4eb19dc914783eb` |
| `SOURCE/lib/screens/connections/connections_section_controller.dart` | `f4390db6499bf1e629f8599d8ea22dabcb1a4948e662dd9ecf19c86ad5116832` |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `08584a34e9937d9dce8020ac9d7067433569b0ca75190d5b1a9932d65b49d2db` |
| `SOURCE/lib/screens/home/home_shell.dart` | `ea5478be12dab8e0148f48e603fea3f28ef67659b7b4cfd95de1120827d5e6db` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | `527703ff0ce8a6e7f6d332b03e4929218eedf2db5ed2090e1881fc3e123201c9` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | `b634057517143a96b78539e41835b2155e0d0bd9b2252ec5a367ae70d76d7915` |
| `SOURCE/lib/widgets/zyra_guardian_invitation_dashboard.dart` | `91770aa5bcc989683c7accbc0a5907688ba75cd02893d55f8b7a4461d2ef83cd` |
| `SOURCE/lib/screens/browse/browse_swipe_policy.dart` | `47f18a4e28ba09040d2cdca97487537138559e36028b5a7138a5fe18a5ec800e` |
| `SOURCE/lib/screens/browse/browse_screen.dart` | `3c945eace2399d2820651bbec4bfd43ac1a4d48115dd867c52e9d2619d9f150f` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `96e43e6f402614592d20ede610dfef3a9a02112b48e9ce392f049b95b26de741` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `f03e045d81d09c0f74d0e19921e29d8f6207aa169eda1250885bfe37bb1cca71` |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `b3b0dc177b735206b4b0ad70fee005a87aa5702a3fd9a0cc01bd9dac0066b429` |
| `SOURCE/test/dashboard_destination_routing_test.dart` | `1fdc3b434fd950efc302a0dd061e3c159c797c8d41a5e29597951a063d4f80bf` |
| `SOURCE/test/browse_swipe_policy_test.dart` | `7cdd5732bb1f228642acc0131ff60fe2c67b527dde5a68b86a3963c189bb7a45` |
| `SOURCE/test/app_shell_correctness_test.dart` | `cc018528849ca0e2a88d22843072921f7de1a1fe97e98a2f405a24884c5c30a8` |
| `SOURCE/test/guardian_page_design_test.dart` | `e35363800d4afc7e465621a2a170204df63d0797223f02654015293eed27b2e1` |
| `SOURCE/test/guardian_design_control_test.dart` | `b9c98e3b9cbcb4db4fc22024d7d5740d612f6f38f63d991507273a681a73c418` |

Measured results:

- focused combined Dashboard/Browse/Guardian suites: **74/74**;
- Guardian page/control responsive suite: **16/16**;
- Browse policy/app-shell focused suite: **25/25**;
- full Flutter regression: **498/498**;
- direct visual/no-overflow matrix: **212/212**;
- `flutter analyze`: **No issues found**;
- `python3 tools/zyra_check.py`: **169 files, 0 findings, 0 new dangling references**;
- signed iOS profile build: **PASS**, `Runner.app` **34.8 MB**;
- wireless device: paired iPhone detected and wireless-debug check passed;
  `flutter install --profile` completed with exit 0. Apple's lower-level
  CoreDevice launcher timed out, so launch/process observation was not claimed.

No migration, schema/RLS/RPC/auth change, Supabase write, git command or visual
baseline approval was part of this batch. Historical candidate images remain
unapproved lineage; they were not regenerated or promoted.

Founder supersession later on 2026-08-27 fixes the final Browser gesture as:
physical swipe left / negative dx / right-to-left finger travel =
Consider/Like; physical swipe right / positive dx / left-to-right finger travel
= Pass/Dislike; downward = Save. The focused Browser suite remained **25/25**,
the full suite remained **498/498**, analysis stayed clean, and a fresh signed
34.8 MB build was installed wirelessly with exit 0.

## 10G · OA-ZYRA-264 shared resolver amendment — 2026-08-28

DR-ZYRA-216 supersedes the Lab-specific priority boundary. The five Lab
presentations remain visual experiments and retain their A–H mock inputs, but
`ZyraDashboardExperience` now translates the selected mock state into a
`DashboardSnapshot` and orders every concept from one pure
`DashboardResolver` result. It no longer owns a competing private priority
score. The production Seeker path is a separate single renderer,
`ZyraResolvedDashboard`, over the same `DashboardResolution` contract.

This does not make mock Lab content production truth. Production snapshots are
built only by `ZyraSeekerDashboardAdapter` from existing server-backed reads.
Developer authorization still guards the Lab. No new toggle was added.

Current evidence for this amendment:

| File | SHA-256 |
|---|---|
| `SOURCE/lib/models/zyra_dashboard_resolution.dart` | `3fdbbf062a8c9cf64f62cf19587bca7aa18ab33b11c47a5278d6baf94a505058` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | `ca4e1b6c21923f569c49a4e6914fb18ff169b0d684196027d3e469cad158dd2e` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | `42c37e085f86f0ec439d236d77594afde840f4d3ed3c6cb77297233a267f2386` |
| `SOURCE/lib/widgets/zyra_resolved_dashboard.dart` | `3b25056a5d2de21b4ac02f5ddecbebe0bdde644fb136043a8fbfc36df3c274b3` |
| `SOURCE/test/dashboard_lab_test.dart` | `2d9b5576896cc26bfc70e455a71c9b409f212e8c930a38cde097a16f8249ce83` |

Measured: combined OA-ZYRA-264 focused suite **119/119**; all Lab A–H states,
five layouts, Seeker/Guardian parity and three App Surface modes passed; the
governed gate passed 215 render variants and the complete Flutter suite. See
`ZYRA_SEEKER_DASHBOARD_HANDOVER_CURRENT_VERSION_V1.md` §12 for the full
production data flow, exact command evidence, limitations and owner chain.

## 10H · OA-ZYRA-265 extended-resolution / Dashboard Home amendment — 2026-08-28

The single production `ZyraResolvedDashboard` now presents the DR-ZYRA-217
six-level Seeker Home. The five Dashboard Lab skins remain developer-only
presentation comparisons; no new toggle or second production renderer was
created.

The extended shared model adds source-aware stable state, calm advisories,
Journey proof lines, Recently and Intelligence. The Lab still delegates its
primary ranking to `DashboardResolver`. It then appends any configured mock
module not returned by the production recency/intelligence caps, preserving
the original stable mock order. This makes Learning and other quiet comparison
states reachable through each skin's existing progressive disclosure without
weakening the production caps or activating production learning.

The compatibility `worthKnowing` getter is retained as lineage for the Lab.
That does **not** claim full MY ZYRA/FAMILY/RECENTLY renderer parity: production
owns those conditional sections in `ZyraResolvedDashboard`. Lab data remains
mock and developer-authorised; production continues to read only
`ZyraSeekerDashboardAdapter`.

Measured on the live disk:

- Dashboard Lab suite: **17/17 PASS**, including A–H, five layouts, three
  surfaces, 130% text, Learning states and progressive disclosure;
- focused combined Dashboard/loading/icon command: **92/92 PASS**;
- complete Flutter suite: **599/599 PASS**;
- analyzer: no issues;
- no migration, SQL, plan gate, production learning or Guardian Dashboard
  change.

Current implementation hashes:

| File | SHA-256 |
|---|---|
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | `f16d9325e76971f820dec3abf248b333713f3c6a703e58af1664cc6566d6b4fb` |
| `SOURCE/lib/models/zyra_dashboard_resolution.dart` | `04e2af7ad50fe1c57d10f309385863773630c445c83c9f9bd038050b9717f7be` |
| `SOURCE/test/dashboard_lab_test.dart` | `2d9b5576896cc26bfc70e455a71c9b409f212e8c930a38cde097a16f8249ce83` |

Founder selection among Lab layouts remains pending and separate from the
production Home acceptance. Candidate screenshots remain unapproved.

## 11 · Archive and authority

This V5 file is the only current Dashboard Lab as-built authority. V1–V4 are
archived and marked superseded. The thirty screenshots for the pre-Sectioned
mixed models remain separately archived under
`SYSTEM/RESOURCES/UI_GATE/ARCHIVE/RETIRED_DASHBOARD_MODELS_2026-08-25/`.

No commit or git mutation was run. Now / Journey / You is the Lab reset state
and Classic Glass remains the app-surface default; Codex did not self-promote any mock renderer to
production or approve a visual baseline, entitlement rule or production
learning system.

---

## Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-24 | Added five role-aware Dashboard comparison concepts. |
| V2 | 2026-08-25 | Added Sectioned Status and correctness cleanup. |
| V3 | 2026-08-25 | Added OA-ZYRA-259 P1 learning mocks and evidence. |
| V4 | 2026-08-25 | Replaced the mixed models with six Sectioned Status family options and enforced Seeker/Wali parity. |
| V5 | 2026-08-25 | Added Status Accents and Classic Glass as independent shared colour treatments, with full functional/visual coverage. |
| V5 amendment | 2026-08-26 | Locked Sectioned Status, removed Dashboard-specific concept/surface selectors, moved the three-way surface control to Home, and made Classic Glass the app-wide default while preserving truthful production Dashboard paths. |
| V5 amendment 2 | 2026-08-26 | Made Dashboard the normal authenticated landing page, persisted the global three-way App Surface locally, moved account-link invitation status/actions to Dashboard, added five experimental Seeker Guardian-page renderers, and removed the redundant Connections heading. |
| V5 amendment 3 | 2026-08-27 | Replaced the first-round Guardian-page comparisons with five larger Focus Carousel directions, moved Add Guardian to the top-right, widened/tallened the cards, added truthful inline Guardian detail/activity, and expanded compact/swipe/reorder coverage. |
| V5 amendment 4 | 2026-08-27 | Expanded direct Guardian carousel cards to near-full-page height, removed three redundant hierarchy labels/counters, retained bounded progress dots, and added measured height/copy regression coverage. |
| V5 amendment 5 | 2026-08-27 | Removed generic invite-code entry from Dashboard, placed it behind Guardian `+`, and capped large Guardian cards against the real SafeArea and shared floating navigation. |
| V5 amendment 6 | 2026-08-27 | Re-enabled five Sectioned Status-family comparisons beside the default, grouped information into To Do/Journey/Insights/Updates/Tools, renamed the learning surface Insights for You, added aggregate explanation and compact dismissal interactions, and expanded 130%-text visual coverage. |
| V5 amendment 7 | 2026-08-27 | Replaced the five Guardian card contents while retaining the approved large Focus Carousel envelope; removed Detail Tray and Activity Story, added Guardian Brief/Connection Path/Profile Mosaic/Role Chapters/Current Focus, and measured structured density plus compact/nav safety. |
| V5 amendment 8 | 2026-08-27 | Replaced the six historical Dashboard comparisons with five new hierarchy experiments, added typed destination routing and kept-alive Connections section targeting, and covered the original “See what changed” regression. |
| V5 amendment 9 | 2026-08-27 | Replaced the Guardian Brief set with Guardian pulse/Shared path/Action board/Activity flow/Living link while retaining the large shared carousel envelope and real-data boundary. |
| V5 amendment 10 | 2026-08-28 | Re-pointed all five mock Lab presentations at the shared pure Dashboard resolver while retaining one separate production renderer and the mock/live boundary. |
| V5 amendment 10 | 2026-08-27 | Applied the Founder’s final Browse direction: left = Consider/Like, right = Pass/Dislike, down = Save; kept preview, cue edge, release and fling in one tested policy. |
| V5 amendment 11 | 2026-08-28 | Kept every quiet developer-only module reachable after resolver ranking while production moved to the conditional six-level Seeker Home. |
