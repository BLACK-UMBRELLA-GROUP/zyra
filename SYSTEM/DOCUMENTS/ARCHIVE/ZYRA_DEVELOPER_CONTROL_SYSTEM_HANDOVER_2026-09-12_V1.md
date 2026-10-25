# ZYRA — Developer Control System: Implementation Handover

**Document:** `ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md`  
**Version:** V1  
**Status:** CURRENT_VERSION — THREE-DOOR AS-BUILT STATE UPDATED AND MEASURED; Fable reconciliation and Founder walkthrough pending  
**Date:** 2026-08-23; current amendment 2026-08-29  
**Implementation owner / author:** Codex, Lead Architect  
**Documentation verifier:** PENDING — Fable has not yet reconciled this handover against disk  
**Authority:** Founder direct build instruction, 2026-08-23  
**Governance:** AD-AIOS-104; `IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V3.md`  
**Related visual gate:** DR-ZYRA-214 / OA-ZYRA-257  
**Migration authority:** none requested or used

> **Current-reading rule:** §25 is the current developer-control contract and
> supersedes every older four-door/Style/App-Surface/loading/icon/Connections
> selector statement in this file. Older sections remain as dated lineage.

---

## 1. What was built and why

The former single pull-out developer panel is now four separate right-edge
controls owned above the app Navigator. The controls therefore remain present
across Seeker pages, Guardian pages, Welcome/auth, both sign-up/onboarding
journeys, Settings, Journey routes and other pushed screens:

1. **Preview** follows the page currently open and provides a read-only
   inventory of every normal section, decision, interruption, empty/loading,
   locked and error outcome that page can contain.
2. **Actions** retains the existing role-specific scenario controls and page
   navigation without mixing them with account or visual experiments.
3. **Home** restarts at the public Welcome screen, resets supported developer
   state, opens the ready-made Seeker/Guardian test accounts, begins either
   real sign-up journey, and owns the one app-wide surface selector: Classic
   Glass, Glass Signals or Status Accents. Classic Glass is the current
   default.
4. **Style** provides nine dark-background comparisons, two separately-labelled
   light-background families (Paper White and translucent Crystal UI), seven
   accents for either light family, eighteen app-reading fonts, seven shared
   bottom-navigation styles and five native haptic levels. The approved Syne
   ZYRA wordmark is excluded and remains locked. The current as-built detail and
   evidence live in `ZYRA_STYLE_LAB_COMBINATOR_HANDOVER_2026-08-29_V1.md`.

The separation exists so the Founder can understand what each control changes:
Preview reads, Actions stages, Home changes entry/account context and the
global surface language, and Style changes the remaining session-only
presentation axes. A tester no longer has to search one long mixed panel for
unrelated controls or mistake an app-wide surface choice for a Dashboard-only
experiment.

## 2. Architecture and invariants

- `ZyraGlobalDevOverlayHost` inserts one developer `OverlayEntry` into the
  app Navigator's own overlay. This gives the rail a real Navigator/Tooltip
  ancestor while keeping it above every pushed route.
- `ZyraDevSurfaceCoordinator` selects Entry, Seeker or Guardian tools from the
  live shell. It stores callbacks only; it is not product or account state.
- `ZyraDevControlRail` is shared presentation. Each role keeps its existing
  scenario owner and reader; the build does not introduce a second state store.
- The selected door and panel-open state live only in the mounted panel widget.
- Preview is generated from the current `DevPage` or `WaliPage`. It writes no
  account, scenario, entitlement, link, Journey or server data.
- Actions continues to use `ZyraDevScenario`, the promotion developer boundary,
  and the Guardian Network's existing `GNContext` entry points. No retired
  Guardian preview model was reintroduced.
- Home reuses `DeveloperAccessScreen` and `ZyraDevSignUp`, so account aliases
  and onboarding are not duplicated inside the panel.
- Home also owns `ZyraDevAppSurfacePicker`. It writes the global
  `ZyraColors.appSurfaceStyleSelection` and its device-local name through
  `ZyraLocalPrefs`; it does not write account or server state.
- Starting either sign-up calls `beginEntryFlow(...)`; closing that onboarding
  route calls `endEntryFlow()`. A sign-up launched from a signed-in shell thus
  receives Entry/sign-up actions and restores the prior role tools afterwards.
- Style uses three in-memory `ValueNotifier`s: `ZyraText.appFontSelection`,
  `ZyraColors.devPaletteSelection` and
  `ZyraColors.devLightAccentSelection`. Home's surface selector uses the fourth
  presentation notifier, `ZyraColors.appSurfaceStyleSelection`. `ZyraApp`
  listens to all four (plus navigation style) and rebuilds the mounted app
  without replacing navigator state.
- Each palette carries its brightness. Paper White selects Material light
  roles plus dark-plum heading/body/subtext, buttons, icons, dividers and the
  shared frost/glass/progress/FAB tokens. Its selected accent feeds primary
  actions, soft selection surfaces, sliders, segmented controls and navigation
  highlights. Existing dark palettes retain their exact previous values.
- The contrast pass is token-led and app-wide: shared typography, Material
  colour roles, sheets, menus, toasts, glass cards, icon buttons, bottom
  navigation, empty/error states, Connections, Journey, Guardian, Settings and
  onboarding all resolve through the current palette. White photo-overlay text
  remains deliberately white because its surface is the image, not the page.
- App surface is likewise token-led and app-wide. Shared progress fill/track,
  icon-button fill/border, selected frost fill/border and glass fill/border
  resolve through `ZyraColors.appSurfaceStyle`. Classic Glass keeps those
  surfaces neutral; Glass Signals keeps neutral surfaces while semantic
  signals remain available; Status Accents adds stronger active/status tint.
- Dashboard Actions owns one session-only five-choice layout selector:
  Now / Journey / You is the Lab reset state beside ZYRA Compass, Journey Lens,
  Living Priorities and Progress Story. The surface selector remains
  Home-owned and passes into both Seeker and Guardian mock renderers.
- Poppins is the current app-reading default; Jost and sixteen other
  alternatives remain available. `wordmark()` stays Syne for every choice.
  Midnight Plum is the current background default; every prior option remains.
- Alternate fonts, palettes, navigation and haptics remain session-only. App
  Surface is the deliberate exception: it persists locally and restores before
  `runApp`. The shared restore/sign-out boundary returns it to Classic Glass.
- The global host and each panel refuse developer UI when developer access is
  unavailable. This is a developer/profile control, not production UI.

## 3. Data and navigation flow

```text
MaterialApp.builder
  -> Navigator OverlayEntry
     -> live context: Entry | Seeker | Guardian
        -> right-edge door -> local selected section
     -> Preview -> current page enum -> read-only inventory route
     -> Actions -> existing scenario/service controls -> existing page readers
     -> Home    -> Welcome reset / accounts / sign-up / app-surface notifier
     -> Style   -> in-memory palette/accent/font/nav/haptic controls
                         ↓
                  MaterialApp rebuild boundary
                         ↓
                  shared theme-token readers across mounted routes
                         ↓
                  both Dashboard mock configs receive current surface
```

Failure and safety behaviour:

- Preview has no write path, so leaving it preserves the current scenario.
- Restart attempts real sign-out, records a debug message on failure, then
  returns to `AuthGate(playSplash: true)` as the existing developer Home rule.
- Account switching and sign-up retain their existing auth/onboarding failure
  handling; this system only links to those shared implementations.
- No visual choice can mutate the server plan, identity, preferences or profile.

## 4. Entry points and developer controls

- App owner: `ZyraApp` -> `ZyraGlobalDevOverlayHost` -> Navigator
  `OverlayEntry` -> one context-aware four-door panel.
- Seeker: `HomeShell` attaches its real page callback to the coordinator;
  `DevScenarioPanelV2` remains visible above both tabs and pushed routes.
- Guardian: `WaliHomeShell` attaches its real page callback;
  `WaliDevScenarioPanel` remains visible above both tabs and pushed routes.
- Entry/sign-up: when neither shell is active, or while `ZyraDevSignUp` owns an
  onboarding route, `ZyraEntryDevPanel` supplies Preview, entry Actions, Home
  and the same Style lab.
- Preview title and inventory follow the currently active bottom-navigation
  page. Seeker pages: Browse, Connections, Dashboard, Guardian and Profile.
  Guardian pages: Dashboard, Network, Seekers, Notifications and Profile.
- Home's Test accounts action opens the existing developer landing containing
  Basic Seeker Male/Female and Guardian Male/Female accounts. The two sign-up
  actions launch the full Seeker or Guardian onboarding flow in dev-preview
  mode through the shared launcher.
- Home's **App Surface** group exposes Classic Glass, Glass Signals and Status
  Accents in Entry, Seeker and Guardian contexts. The choice applies across
  ZYRA rather than only to the page currently open.
- Home's **Home Screen Icon** group exposes four Gold Horizon treatments in
  current and large wordmark sizes. Gold Horizon/current is the production
  primary; the other seven are iPhone-only developer alternates.
- Dashboard Actions contains a five-choice hierarchy layout picker but no
  surface picker. It also retains Lab enablement, preview-role, scenario,
  learning and module/order controls.
- The rail test keys are `dev_rail_preview`, `dev_rail_actions`,
  `dev_rail_home` and `dev_rail_style`.

## 5. Mock versus production

| Area | Developer/profile build | Release/production |
|---|---|---|
| Four-door rail | Available app-wide to an authorised developer account, including pushed and sign-up routes | Host and panels return no developer UI |
| Page preview | Read-only deterministic inventory for Entry, Seeker and Guardian contexts | No production route |
| Actions | Existing staged and server-backed developer scenarios, each retaining its prior truth boundary | No developer controls |
| Home/accounts | Existing seeded test-account and dev-preview onboarding entry points | Public auth/onboarding only |
| App surface | Home offers Classic Glass, Glass Signals and Status Accents; selection is device-local and app-wide | No selector; a fresh install starts on Classic Glass through shared tokens |
| Home Screen icon | Eight Gold Horizon-family rows: four current-text and four large-text treatments | Gold Horizon/current is the generated primary icon; alternate switching is absent |
| Fonts/palettes | Nine dark comparisons; one separate Paper White family with seven session-only accents; eighteen reading faces | Current Poppins + Midnight Plum default; no member preference or persistence |
| Dashboard Lab | Now / Journey / You is default/reset with four session-only sibling comparisons; all five A–H mocks build a typed snapshot and consume the same pure `DashboardResolution`; both role renderers receive the Home-owned surface | One separate production renderer consumes a live-adapter resolution; deterministic Lab content is not promoted |
| ZYRA wordmark | Locked Syne | Locked Syne |

## 6. Live files and point-in-time SHA-256 evidence

The hashes below are point-in-time evidence recorded by the earlier
2026-08-24/25 work. They predate the 2026-08-26 app-surface/Dashboard-lock
amendment and are **not** asserted as current digests.

| File | SHA-256 | Responsibility in this build |
|---|---|---|
| `SOURCE/lib/dev/zyra_global_dev_overlay.dart` | `5f407d21bad01abfb22ab64329b7c4669bea714f22d975b16675a778cf15ab1a` | Navigator-owned app-wide overlay plus Entry/sign-up four-door panel |
| `SOURCE/lib/dev/zyra_dev_surface_coordinator.dart` | `ffd5d108c20f879c63133a2be8e44a2e0565da294fa2dee7c5b03550214cb8a0` | Entry/Seeker/Guardian context and real shell navigation callbacks |
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | `3a5cfb28a9b7d5a8706451644658c791c31c83d4890401b3e460940c715f19f8` | Historical digest; current file also owns the Home app-surface picker and Classic Glass restore |
| `SOURCE/lib/dev/zyra_page_preview_screen.dart` | `70ca7f72c816b834f9fb46ee04e850689229e3bf27772cf5bad2f6679b23aa20` | Page-aware Entry, Seeker and Guardian read-only inventories |
| `SOURCE/lib/dev/zyra_dev_signup.dart` | `7211f6e606ea76f6ce24264df1307d25bbf1d3d32d89645062e9715936dd3f9e` | Shared real onboarding launcher plus temporary Entry-context ownership |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `72ac3c842f7406ab233e478f2dfc9263dbe957e8fd1a08a3d7345fbd25437d89` | Seeker four-door integration; grouped 15-style Browse selector; all former dropdown routes replaced by inline rail selectors |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `2e196da32313a33c06a127601e031bb8a3a7ce1080ade52cdd9791468d88ac37` | Historical digest; current file also fixes Dashboard layout and passes the global surface into both role configs |
| `SOURCE/lib/dev/wali_dev_scenario_panel.dart` | `3c0c9b9b4304713a3444b8205105959eaa958623a67dd0a6442131131d6a7fce` | Guardian four-door integration and safe animation-controller lifecycle |
| `SOURCE/lib/main.dart` | `f9868dec1e280ca08f6956a58cbc83dcd844471abce9be2f3a2fe7f67c5875f4` | Historical digest; current rebuild boundary also listens to app-surface selection |
| `SOURCE/lib/screens/home/home_shell.dart` | `d5bd339e67e7c9ee3a3bc3f91c83a0d0613dbf2edfcd423536fe3f68eeda17f7` | Seeker context attachment and real tab navigation callback |
| `SOURCE/lib/screens/wali/wali_home_shell.dart` | `b1c08ae8ac37761a974773e8e7fb8c78ca38858ebe0f616f5fbc470675a889af` | Guardian context attachment and real tab navigation callback |
| `SOURCE/lib/theme/zyra_colors.dart` | `0d2b4c16ef06311d8f09f5b6e9202c418dda65fdaed6fd5b27d80057b2ac7689` | Historical digest; current file also owns three surface styles, Classic Glass default and app-wide token resolution |
| `SOURCE/lib/theme/zyra_text.dart` | `d536dd0bd0d8df8a34b8b6b2995715a9d96b5151f6eea4773cf288eb8149c682` | Eighteen reading faces; synchronous bundled Poppins current default; locked Syne wordmark |
| `SOURCE/lib/screens/auth/email_recovery_screen.dart` | `902f48dd6c88185bc89fe99a04cd3a2419ee1a64698ba517e6645ba943599cdb` | Dynamic contrast border compatibility |
| `SOURCE/lib/screens/auth/role_selection_screen.dart` | `9a3fe13156b7568ff2c6c6ee368d205047a372c3988d25c47dfe1ee4cc82686a` | Dynamic progress contrast compatibility |
| `SOURCE/lib/screens/dev/developer_access_screen.dart` | `20b746244bbb56cef0a1b2fa33695406e48472c6613d55c8ba5c8e639e4d2fea` | Existing account entry plus live palette background |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `e28b8a9063804fb21e8a03c9b09271e1b43b6306b0cd54eb4526972ca401e96a` | Shared action hierarchy across all Seeker Connections cards; five section-heading layouts; repeated Introductions heading removed |
| `SOURCE/lib/screens/browse/browse_screen.dart` | `ad9af73f06b50e532da5ded48369f9b5e9423a7dc194dc3e8064f38dac3e00a2` | Corrected gesture semantics plus five colour, five neutral and five profile-motion treatments |
| `SOURCE/lib/screens/journey/journey_flow_screen.dart` | `38fc9001a26d5b87256cf051ed52867cec87616bb97a57d4caec3445f7e1c6b1` | Live palette-compatible Journey backgrounds and accents |
| `SOURCE/lib/screens/matches/journey_timeline_screen.dart` | `5dc5a243b3ad729c56d64ab51f3a430c499025bf84818ac0ddd549c6963ba68e` | Live palette-compatible timeline background |
| `SOURCE/lib/screens/onboarding/account_path_overview_screen.dart` | `54d8b84e21314f93c86746a80c0957402cf0f24eb44a3b00693e710048e94c88` | Live palette-compatible onboarding background |
| `SOURCE/lib/screens/onboarding/compatibility_category_intro_screen.dart` | `668276e4bc113ab0f35513950d6cd3832a17c8e71641301cf94594ee6028516a` | Live palette-compatible onboarding background |
| `SOURCE/lib/screens/onboarding/onboarding_stage_intro_screen.dart` | `15ddcae3233a2e6125d315bc71dd5ff1eac40eaa54ef11f12e90801963ca159e` | Live palette-compatible onboarding background plus short-phone Poppins spacing |
| `SOURCE/lib/screens/onboarding/profile_ready_screen.dart` | `cb788cb6e8febb352210a73b368a067152101ab7df1071f57bc41c20287bace6` | Live palette-compatible onboarding background |
| `SOURCE/lib/screens/onboarding/values_preferences_flow.dart` | `83faea9e5fdaf8fe9cd5ac186c94b4c8d15e7ff6580a710184cdc35763e288e3` | Live palette-compatible compatibility backgrounds |
| `SOURCE/lib/screens/settings/sign_in_security_screen.dart` | `f2b79106613255c75f5c36e3bbe49038536ae100a3d4dd1dfa354339fd622c4b` | Dynamic contrast border compatibility |
| `SOURCE/lib/screens/splash_screen.dart` | `ffd80f5d5bad6219b5e42a21453b56d4536136ff9d9fe88810b537a2ec58353a` | Live palette-compatible splash background; wordmark unchanged |
| `SOURCE/lib/screens/wali/wali_network_screen.dart` | `12e09731bb4ab2870059f7a15f8dc401c3bf56f57c8b455ae04b84f136e00931` | Live palette-compatible Guardian Network background and accents |
| `SOURCE/lib/screens/wali/wali_gn_shared.dart` | `271c0e73ac89d856eda5175fdca0070a24afc3f539add5fcb41b3cf83963787b` | Shared Guardian Network controls and state contrast |
| `SOURCE/lib/screens/wali/wali_onboarding_flow.dart` | `9da50036495cb782ba3d993071b4bf12d75947cea9099615a1169ccb3f56b2e9` | Dynamic progress contrast compatibility |
| `SOURCE/lib/screens/wali/wali_profile_screen.dart` | `25456707b1e8c58a9c3b0a5f410929cd51a5760235bb3fcfd45667ea09363116` | Dynamic icon-surface contrast compatibility |
| `SOURCE/lib/screens/welcome_screen.dart` | `1a941698fc3c82f6986b4b7ad8c717d23c996a476612cc757554c7b0be4f09eb` | Live palette-compatible Welcome background |
| `SOURCE/lib/widgets/zyra_app_lock_gate.dart` | `9b281c3563271707cf83687471d3216c72924df7ad1803339a9902c703acb8b4` | Live palette-compatible lock backgrounds |
| `SOURCE/lib/widgets/zyra_segmented_toggle.dart` | `6717b8256d791700af7dd0d952cd77061acada692b3287860f1276c060067b82` | Shared light-aware sliding selector and accent highlight |
| `SOURCE/lib/widgets/floating_nav_bar.dart` | `fdefcf7bfc2cc12dd83f604263b79cc22caeade0aab3478d7a5352557025c1e3` | Shared light-aware glass navigation and accent highlight |
| `SOURCE/lib/widgets/zyra_state_widgets.dart` | `e3790e74f5cd074faff20badfa567362368ace660337a207be39b5aa18837300` | Shared empty/error/disabled contrast |
| `SOURCE/lib/widgets/glass_icon_button.dart` | `0e2b32df4a6d1202bec8e5794a53908d90ccaf52f11ca97e0ee00c9289f99eb4` | Shared brightness-aware glass icon surface |
| `SOURCE/lib/widgets/zyra_glass_dialog.dart` | `ba78541c7415c70111381ac5ae1910c19b9bd64c61696b19befcd91fa2a4acc1` | Shared brightness-aware glass dialog |
| `SOURCE/lib/widgets/help_report_sheet.dart` | `8756b6a7bacb76cf7370ef30224bc6533f17448114ade4fb06691c30627ab59c` | Shared light-aware sheet text and glass chrome |
| `SOURCE/lib/widgets/zyra_full_screen_error.dart` | `c4d47ec41a94b103e7639cad2a9e4bb1cc06aae65c13c882832da33bed73b167` | Live palette-compatible recovery background and status bar |
| `SOURCE/test/global_dev_overlay_test.dart` | `bd328fb5bebe46517888542302304ac55418e6f51ae9f3010082402749f67b75` | Entry coverage, pushed-route persistence and current-default isolation |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `d744400db04e593f7bdeb82d1402faf886b53bfcb363e10613990f1e7f8c6633` | Four-door, 5+5+5 Browse grouping, inline selector interaction/reset and existing policy coverage |
| `SOURCE/test/app_shell_correctness_test.dart` | `33642b82cc88b0eb6889f489cd210b4a80b2a07aeb270c4a56705ab4f798cd75` | Structural proof of gesture directions, fifteen text-free treatments, motion wiring and no popup dropdown implementation |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `470d60065ef60dab0a1057a572f46795c698e9378290c49e7051b57075f843e4` | 48 render variants now use actual bundled Poppins metrics |
| `SOURCE/pubspec.yaml` | `51c76c7d44683fb7d0137cbffc11fed29926068a6d12e86a4f0624b70be3a530` | Registers six Poppins weights and the OFL licence for offline first paint |
| `SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_UI_AUDIT_2026-08-24_a365b7a3.md` | `c0dd10cc578a9d2f5a41555a74f2a1a0ecbaf6c16bd6449da126374be97c5a67` | Permanent deterministic UI-gate report for the Paper White source tree |
| `SYSTEM/RESOURCES/UI_GATE/state.json` | `cd8a4bba4e2411af1a921fda749f8c027bb34f17778d19bd4d793e9587cc725c` | Updated UI-gate file/finding evidence ledger |

Current 2026-08-26 amendment hashes were remeasured after the final test/build
pass:

| File | SHA-256 |
|---|---|
| `SOURCE/lib/theme/zyra_colors.dart` | `91c1cf87372037b81f6a14da934ff977f2cc0f8fb311d29cdafaaae2361c7841` |
| `SOURCE/lib/main.dart` | `a7ae853ff4b9f2640396f1d890f42de062f0304b7d2ae031c5999b53ffea5e32` |
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | `136df69b97fcc0b82967d76267f581905dbb275088ac3e0b8fa1bf124d4f096a` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `a5d216ecb122ec6e20dfca8597feed36eaf1d4b8289d644b9b62486bfc0523c7` |
| `SOURCE/lib/dev/zyra_dashboard_lab_controls.dart` | `c608d3fb8caff3b1d0466c7c823887553cb6a7d66d01e3dc87cc0613444b7470` |
| `SOURCE/lib/models/zyra_dashboard_lab.dart` | `5d069aca716d2237c30faaad482dcdd3bdbff551ddcb5680b7d434f8e777d525` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | `57b98a0c605fef8abb839e81c57a29418b6851e5e526639a1cda857e8988d176` |

## 7. Verification evidence and current boundary

The detailed results below remain historical evidence for the earlier
four-door/style amendments. The 2026-08-26 app-surface/Dashboard-lock amendment
was separately measured after its final code change: `flutter analyze` found
no issues; the focused control/Dashboard suites passed; the dedicated visual
suite passed **190/190**; the full Flutter suite passed **456/456**;
`tools/zyra_check.py` returned 0 findings across 165 files; and the iOS profile
build produced a 36.0 MB `Runner.app`. Physical-phone comparison remains
Founder-pending. The complete current evidence table and changed-file hashes
are owned by `ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V5.md` §7–8.

- Static analysis: `flutter analyze` — **PASS, no issues**.
- Focused suite: `flutter test --no-pub test/widget_test.dart
  test/dev_scenario_panel_policy_test.dart test/global_dev_overlay_test.dart`
  — **15/15 PASS**.
- Focused coverage includes app-wide persistence above a pushed route, Entry
  and both sign-up contexts, restoration to the prior signed-in role, both role
  shells, all four rail controls, Seeker
  Browse preview, Guardian Network preview, grouped light/dark selection,
  Paper White brightness/foreground/glass contrast, seven selectable accents,
  eighteen reading faces, locked wordmark, account/sign-up actions, and
  retained scenario-truth tests.
- Full regression: `flutter test --no-pub --reporter compact` — **232/232 PASS**.
- Deterministic visual gate: `python3 tools/zyra_ui_gate.py` —
  **PASS-WITH-FINDINGS**, 153 live findings: **0 critical**, **0 high**, 13
  medium and 140 low. No critical/high defect was introduced by this build.
- Final current-default visual gate: `python3 tools/zyra_visual_gate.py
  --force --full` — **48/48 render variants PASS**, analyzer/structural/full
  suite all PASS, no open L2 findings. Status remains BASELINE-PENDING because
  zero screenshots have Founder-approved baselines.
- Physical-device observation of Midnight Plum + Poppins: **PENDING — not yet
  measured by the Founder**. The earlier device install recorded by this
  handover predates the 2026-08-24 default change and is not current evidence.
- Migration/SQL probes: **none**, because this build has no database change.

## 8. Migrations and external changes

No SQL, migration, schema, RPC, RLS, Edge Function, Supabase setting or auth
provider changed. Six official Poppins TTF weights and their OFL licence were
added locally and registered in `pubspec.yaml`; no new Dart package was added.

## 9. Known limitations and remaining work

1. The page Preview is a complete read-only inventory, not a composite copy of
   every mutually exclusive runtime state rendered simultaneously. This is
   deliberate: some outcomes cannot truthfully coexist, and Preview must not
   mutate production/account state. No OA is raised because the Founder asked
   for a page-aware catalogue control and has not requested screenshot/golden
   composites.
2. Palettes and the seven White accents are broad Founder comparison
   directions, not approved production colours. Choosing one does not ratify
   it, persist it or change brand canon. Paper White adapts shared semantic
   theme, glass, sheets and chrome; fixed white retained over profile
   photography is deliberate because those elements contrast against the
   image rather than the app canvas. The Founder phone review remains the
   authority for any screen-specific refinement.
3. Font candidates use the existing `google_fonts` package. A first render may
   depend on that package's normal cache/network behaviour; no new package was
   introduced.
4. `SOURCE/lib/dev/wali_dashboard_preview.dart` is now an unreferenced legacy
   preview after the shared page-aware Preview replaced its panel entry. It was
   not deleted or presented as current. Fable should archive or formally retire
   it during documentation reconciliation; no runtime reader remains. No OA is
   raised here because removal is documentation/lineage housekeeping, not a
   product or production defect.
5. Fable must reconcile hashes, decide whether a separate governed product/build
   contract is warranted, regenerate the ZYRA documentation index, and record
   any register entry. Codex does not self-approve or claim that filing has
   occurred.
6. Alternate App Surface choices remain developer-only. Release exposes no
   toggle and starts on Classic Glass. This is intentional, not a member-theme
   feature.
7. The five current Dashboard Lab renderers (Now / Journey / You family;
   earlier "Sectioned-family" naming is historical) remain deterministic mock
   content. **Written refusal — no OA raised at the time:** the existing
   production Dashboard paths deliberately remain in place so release data
   stays truthful. *(Fable reconciliation 2026-08-28: the production
   renderer/data-adapter build is now authorised — DR-ZYRA-216 /
   OA-ZYRA-264.)*

## 10. Authority map and supersession

| Truth layer | Current authority |
|---|---|
| Founder intent | Direct 2026-08-23 instruction for four separate controls; 2026-08-26 Sectioned Status/Classic Glass defaults; 2026-08-27 five cleaner Sectioned-family comparisons |
| Shared implementation governance | `BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V3.md` |
| Related visual/developer-control quality contract | `ZYRA_UI_CONSISTENCY_GATE_CURRENT_VERSION_V1.md` (DR-ZYRA-214 / OA-ZYRA-257) |
| As-built implementation | This handover plus the live files named in §6; listed hashes are explicitly point-in-time until remeasured |
| Superseded runtime model | One mixed single-door Seeker/Guardian panel; role-specific scenario state remains current, its mixed presentation does not |

## 11. Next owner actions

1. **Founder:** test Preview, Actions, Home and Style on at least one Seeker and
   one Guardian page; compare the three Home-owned app surfaces and refine any
   remaining palette/font/navigation/haptic choices.
2. **Fable:** reconcile this handover against disk, archive the unreferenced
   legacy Guardian preview with lineage intact, update any required register,
   and regenerate the documentation index.
3. **Codex:** implement only Founder-selected production palette/font changes;
   developer selection alone is never product approval.

## 12. 2026-08-25 Connections Active Journey amendment

Founder authority on 2026-08-25 added an **Active Journeys** count to the
Seeker Connections Actions panel. It is a local preview control, separate from
the server-backed **Open live Journey** action:

- ZYRA Basic offers `0` and `1`.
- ZYRA One offers `0`, `1`, `2` and `3`.
- The existing entitlement constants remain the single limit source.
- `composeJourneys` clamps staged Active rows against the current plan, so the
  card list cannot exceed the selected entitlement.
- Opening/remounting the developer panel no longer deletes the selected Active
  preview count. The shared Reset still returns it to zero.
- Mock Active cards remain local developer data and do not create or replace a
  database Journey. A real walkable Journey still uses **Open live Journey**.

Measured verification for this amendment:

- `flutter analyze --no-pub` — **PASS, no issues**.
- `flutter test --no-pub --reporter compact
  test/dev_scenario_panel_policy_test.dart` — **12/12 PASS**. The suite measured
  both exact plan option ranges, one Basic composed Active card, three ZYRA One
  composed Active cards, persistence through legacy-state migration and Reset
  coverage.
- `flutter test --no-pub --reporter compact` — **393/393 PASS**.
- `flutter build ios --debug --no-codesign --no-pub` — **PASS**; produced
  `SOURCE/build/ios/iphoneos/Runner.app`.
- Physical-device observation — **PENDING Founder test**.
- Migration/SQL probe — **not applicable; no database change**.

## 13. 2026-08-25 Connections card and heading lab amendment

Founder authority on 2026-08-25 extended the approved Active Journey action
hierarchy to every Seeker Connections person card without replacing its
existing information or behaviour:

- Active, Potential, Paused and Ended Journey cards;
- Considered, Saved and Passed Activity cards; and
- Guardian Introductions cards.

One shared `_ConnectionsActionDeck` now receives the existing callbacks and
labels from each card. The design selection changes presentation only; it does
not change profile decisions, Journey transitions, unlock state, Timeline,
reporting or database writes. The six live comparisons are **Unified rail**
(the Active Journey direction), **Split pills**, **Icon dock**, **Stacked
rows**, **Compact chips** and **Framed grid**.

A second independent selector applies five heading comparisons to Active,
Potential, Paused, Ended, Considered, Saved and Passed: **Chapter left**,
**Title left**, **Centred rule**, **Accent marker** and **Count split**. The
Introductions segment no longer repeats an `INTRODUCTIONS` subheading inside
its own page. Counts remain available on the main segment/badge and cards begin
without the redundant title.

Presentation switches rebuild the mounted Connections page without a Supabase
re-fetch. Journey count/state changes still re-fetch because their composed
rows genuinely change. Shared Reset restores Unified rail and Chapter left.
Release builds are pinned to those two defaults; the comparison controls remain
developer-only.

Measured verification for this amendment:

- `flutter analyze --no-pub` — **PASS, no issues**.
- Focused policy/correctness suite — **17/17 PASS**.
- `flutter test --no-pub --reporter compact` — **395/395 PASS**.
- `flutter build ios --debug --no-codesign --no-pub` — **PASS**; produced
  `SOURCE/build/ios/iphoneos/Runner.app`.
- Physical-device comparison of all 30 card/heading combinations — **PENDING
  Founder review**.
- Migration/SQL probe — **not applicable; no database change**.

## 14. 2026-08-25 Browse swipe-feedback lab amendment

Founder authority on 2026-08-25 first requested five comparisons, then expanded
the lab to fifteen and corrected the gesture/edge meaning:

- physical swipe left / finger travels right-to-left = **Consider**, green on the left;
- physical swipe right / finger travels left-to-right = **Pass**, red on the right; and
- swipe down = **Save**, yellow revealed from the top.

The dominance calculation, 120-pixel commit threshold and persistence calls are
unchanged. The action mapping and post-commit edge flash were corrected together
so neither the live state nor release confirmation can contradict the decision.

The lab is grouped 5 + 5 + 5:

1. **Colour feedback:** Full aura (retained), Edge bloom, Glass tide, Signal
   arc and Comet sparks. The four rejected colour comparisons were replaced.
2. **Without colour:** Frost edge, Silver brackets, Focus frame, Mono ripple
   and Shadow depth. These use only neutral white/black treatment.
3. **Photo movement:** Photo follows, Photo tilts, Photo breathes, Photo
   perspective and Photo floats. Direct drag tracking has no tween delay;
   release or snap-back uses a 220ms settle.

The fifteen-way selection remains session-only developer state:

- no style places visible copy, a tick, a heart or a thumb over the profile;
- the ten fixed-photo treatments share one `CustomPainter` driven by the drag
  progress Browse already calculates, with no looping controller or timer;
- selecting a style changes only the next/active drag rendering and makes no
  Supabase request; and
- shared developer Reset restores **Full aura**.

The detached `DropdownButton` menu shown over Browse was removed from the
shared Seeker Actions panel. Both the generic style/heading selectors and the
Pause-state selector now expand inside the rail's own scrollable surface and
collapse after selection. No developer dropdown route remains in that panel.

Measured verification for this amendment:

- `flutter analyze` — **PASS, no issues**.
- Focused policy/correctness suite — **20/20 PASS**. It measured the three
  groups of five, selection and Reset, all fifteen rendering/motion branches,
  right/left/top mapping, no visual `Text`/thumb icon, a real inline expansion
  interaction and the absence of dropdown-menu widgets.
- `flutter test --no-pub --reporter compact` — **398/398 PASS**.
- `flutter build ios --debug --no-codesign --no-pub` — **PASS**; produced
  `SOURCE/build/ios/iphoneos/Runner.app`.
- Physical-device comparison of the fifteen live drags — **PENDING Founder
  review**.
- Migration/SQL probe — **not applicable; no database change**.

## 15. 2026-08-26 app-surface and Dashboard-lock amendment — historical, layout lock superseded by §19

The developer control system now records one global surface decision instead
of separate page experiments:

- Home owns the app-wide selector with **Classic Glass**, **Glass Signals**
  and **Status Accents**.
- Classic Glass is `ZyraColors.currentDefaultSurfaceStyle` and is restored by
  both the shared developer reset and **Restore default style**.
- `ZyraApp` listens to `appSurfaceStyleSelection`, so shared theme-token
  readers update across the mounted app without replacing navigation state.
- At this point in history, Dashboard-specific concept and surface selectors
  were removed and Sectioned Status was locked. Founder instruction on
  2026-08-27 superseded only the layout-lock portion; current truth is §19.
- `ZyraDevScenario.dashboardConfigFor(...)` reads the global surface and passes
  it into both Seeker and Guardian `ZyraDashboardExperience` mock renderers.
- Sectioned Status is not yet a production data adapter. Release/non-Lab
  Seeker and Guardian Dashboards retain their existing truthful data UI.
- No member-profile preference, Supabase write or migration was added. The
  developer App Surface name is persisted only in device-local preferences.

Measurement recorded for the 2026-08-26 amendment: visual **190/190**, full Flutter
regression **474/474**, analyzer clean, ZYRA checker 0 findings, valid visual
state JSON and iOS profile build success. Exact commands and live hashes are
recorded in `ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V5.md` §7–8. Physical
iPhone comparison and independent Fable reconciliation remain pending.

## 16. Historical landing/invitations amendment — Guardian options superseded by §21

- **Home → App Surface** remains the singular three-way global selector. It
  applies immediately, survives relaunch, crosses Seeker/Guardian navigation,
  and resets to Classic Glass through the shared reset/sign-out boundary.
- Normal authenticated Seeker routing now lands on Dashboard. Auth,
  missing-profile and role-selection branches remain outside that normal path.
- Dashboard Actions owns Guardian invitation preview staging. Live sent rows
  and cancellation use the existing service; live receipt remains bearer-code
  review. Named received rows are developer preview and say `Preview`.
- On the Seeker **Guardian** page, Actions now exposes **Guardian Page Design**:
  1 Profile Focus, 2 Responsibility Focus, 3 Activity Story, 4 Split Profile
  and 5 Detail Tray. These larger second-round directions all retain the Focus
  Carousel interaction and consume the same linked-Guardian data, genuine
  activity and detail callback. Reset returns Profile Focus. **FOUNDER DESIGN
  SELECTION PENDING.** No option is production-approved by this handover.
- Invitation status/actions no longer live on the Seeker Guardian page. The
  Dashboard shows only existing pending/received-preview state. Generic code
  entry and invite generation now share the Guardian page's top-right `+` flow.
- Connections Actions keeps the Introductions destination but the rendered
  page no longer includes the redundant singular `Introduction` heading.

Measurement recorded for the 2026-08-26 amendment: 82/82 landing/surface/Dashboard/Guardian tests;
22/22 Guardian Network/Journey tests; 190/190 direct visual render checks;
474/474 full Flutter tests; analyzer clean; formatter clean; structural checker
0 findings. The signed profile build was installed and launched wirelessly on
the paired iPhone, then detached. Founder design selection remains pending. No
migration was created or applied.

## 17. 2026-08-27 larger Focus Carousel amendment — superseded by §20

The five first-round Seeker Guardian-page designs were replaced on direct
Founder instruction. The one page-aware **Guardian Page Design** control now
compares five larger directions in the Focus Carousel family:

1. Profile Focus
2. Responsibility Focus
3. Activity Story
4. Split Profile
5. Detail Tray

One shared PageView controller, Main-first ordering rule, bounded indicator and
stable Guardian-ID selection serve all five. Each presentation receives the
same `WaliLinkedPerson`, genuine `GuardianActivity` resolver, add callback and
detail callback. The larger cards can show relationship, Main/Additional role,
active-link status, linked date and recognised activity that previously
required opening the detail page. One Add Guardian control now sits in the
top-right page header for empty and linked states; no bottom duplicate remains,
and direct carousel cards target near-full-page height but are capped by actual
SafeArea constraints after reserving the header, progress, shared floating-nav
metrics and 8 px clearance. Compact-height variants condense their decoration
without reducing the 130% text fixture. The trusted-circle subtitle, inner
`YOUR GUARDIANS` label and numeric `1 of N` counter are removed; bounded progress
dots remain. Detail Tray retains its compact carousel because its information
tray uses the remaining page height. Make Main, Remove and Report remain in the
established detail route; the experimental carousel does not duplicate those
state-changing actions. Preview data remains developer-only and the production
path still reads the live service.

Reset now restores **Profile Focus**. All five remain **FOUNDER DESIGN
SELECTION PENDING** and no visual direction is promoted to an approved baseline.

Current hashes:

| File | SHA-256 |
|---|---|
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `66f22677569c2e7e482e5c65f9e26e0fcd8c1d43c33327a153f9885cff0986c5` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `be47686ec720bbe92d2efc5da6739230388c30faa752dc8d38c611aaf4810b6b` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `6dfac75976081b18df9006c457950a2303f25762577d48d77361158d3e1089d2` |
| `SOURCE/test/guardian_page_design_test.dart` | `ca5afd6d575aa86a921f04703f86441465a1195cbdfefb0ecf063e4db64278ab` |
| `SOURCE/test/guardian_design_control_test.dart` | `00372bccc7de089403552b2724d2b9e992d470d6bcd2af23134b95c1e60df7fe` |

Measured verification: Guardian page 14/14; all three App Surface
modes across all five options; empty/one/six Guardians; carousel selection and
open callback; top-right add placement/action; Main-first and role-reorder
identity preservation; genuine activity and outstanding-item priority; 320×568
at 130% text; long/missing fields; redundant-copy removal; at least 580 px card
height and at least 8 px nav clearance at 393×852; full Flutter 488/488; direct visual 190/190;
analyzer clean; formatter clean; static checker 0 findings; signed iOS profile
build 34.6 MB. It was installed and launched wirelessly on the paired iPhone;
the device process was confirmed after the local VM-service connector detached.
No migration, Supabase write, commit or git mutation was used.

## 18. 2026-08-27 Gold Horizon primary icon amendment

The production primary app icon is now **Gold Horizon · Current text**. The
authorised Home control presents eight real icon builds in two clear groups:

- Current text: Gold Horizon, Soft Horizon, Rising Horizon, Split Horizon.
- Large text: Gold Horizon, Soft Horizon, Rising Horizon, Split Horizon.

The primary has no alternate name; the other seven are iOS alternate icons.
The deterministic Swift generator draws one shared purple background and the
locked Syne wordmark stencil for every variant, writes the primary source to
`assets/icon/icon.png`, and `flutter_launcher_icons` propagates that primary to
iOS, Android, macOS and web. Developer switching remains unavailable in release.

Current hashes:

| File | SHA-256 |
|---|---|
| `SOURCE/lib/services/zyra_dev_app_icon.dart` | `3a6f115b84572d8aa3feebda864904619c6a543f18a45045d8e0a013d6d4894a` |
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | `fdf8c282d6d8be078c7af89d13b6f2144f14ca8785a44a36865bb3d04d4bd8d2` |
| `SOURCE/tool/generate_dev_app_icons.swift` | `565804abe665a70d4358398c1583713e5fa641b862ca35a308671fc7cb009dbf` |
| `SOURCE/ios/Runner/AppDelegate.swift` | `25469c6e14f970ec0f5261a648c3620399a4fb54ddf281aa8100ac7005150eda` |
| `SOURCE/ios/Runner.xcodeproj/project.pbxproj` | `97180c859a9e26147b8d6296d7990e4c3a895048eddb9bf3631d8261c55d37ee` |
| `SOURCE/assets/icon/icon.png` | `fc0e0b2433c6d6b279f8ead96c7cc106a2201e9cff6f89ed1a1a78fcc0f687af` |
| `SOURCE/test/zyra_dev_app_icon_test.dart` | `6e46efb6698c5fe2b3fd4751737272bd2d1f433e0eb2c66e757618b9eff4f30d` |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `b88614dbcc0acf93f9457907eaa0ccb785005eaedf914dc6ffc8512d95471db9` |

Measured: eight enum rows, four current/four large, one primary/seven distinct
alternate names, native asset generation success, `flutter_launcher_icons`
success, full Flutter 488/488, analyzer clean, ZYRA checker 0 findings and
signed iOS profile build 34.6 MB. Founder visual selection among the seven
alternates remains pending; the primary selection is Founder-directed.

## 19. Historical six-choice Dashboard amendment — superseded by §21

Dashboard Actions now exposes one page-aware **Dashboard Layout** comparison:
Sectioned Status, Priority Focus, Compact Groups, Progress View, Grouped Cards
and Guided Path. The shared `ZyraDevScenario` owns the session-only selection,
feeds it to both role configurations and resets to Sectioned Status. The App
Surface control remains exclusively under Home, so layout and global surface
cannot drift into competing owners.

All six renderers consume the same modules and divide them into To Do, Journey
Status, Insights for You, Updates and Explore/Guardian Tools. Module arrows now
preserve their chosen order inside each category. The Seeker-only insight mock
uses four constructive status chips and a quieter options menu for dismissal;
its expanded view separates what the pattern reflects, how it may help and the
aggregate evidence that shaped it. Responses are local preview state only.
Production learning remains inactive under OA-ZYRA-259.

Current hashes:

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

Measured: focused Dashboard/current-hub/control suite 74/74; direct visual
matrix 238/238 across six layouts, both roles, three app surfaces, three sizes
and 130% text; full Flutter 539/539; analyzer clean; ZYRA checker 0 findings;
signed iOS profile build 34.7 MB. Wireless install/launch and post-detach device
process confirmation passed on the paired iPhone. No migration, Supabase write,
commit or git mutation was used. Founder comparison selection remains pending;
Sectioned Status remains the reset/default and no visual baseline was
self-approved.

## 20. Historical Guardian Brief amendment — superseded by §21

Founder review kept the large Focus Carousel card envelope but rejected the
sparse content distribution, the separate Detail Tray and reliance on an
Activity Story whose information can be found elsewhere. **Guardian Page
Design** now exposes five fresh real Flutter choices in this exact order:

1. Guardian Brief
2. Connection Path
3. Profile Mosaic
4. Role Chapters
5. Current Focus

All five use the same `WaliLinkedPerson`, recognised `GuardianActivity`,
top-right Add Guardian action and whole-card detail callback. Their card width,
near-full-page height calculation, SafeArea/nav cap, 8 px clearance, Main-first
ordering, stable Guardian-ID selection and bounded progress dots remain shared.
No new bottom control, counter, title or invitation surface was introduced.
Reset now returns **Guardian Brief**.

The layouts fill the existing space through relationship, Journey-role,
connection and current-state structures. Activity is reduced to one prioritised
current signal, with an outstanding Family Review taking priority; it is not a
replacement timeline. Empty activity uses the truthful “No Guardian activity
to show” boundary because an empty resolver can also represent an unavailable
RPC. Production fields remain limited to first name, recorded relationship,
Main/Additional role, active link, linked timestamp where present and recognised
activity. No photo, verification, location, online state, plan, trust score,
relationship proof, permissions or Journey count was invented. Make Main,
Remove and Report remain in the established detail route. A stale header comment
in that route was corrected to match its existing guarded Remove implementation.

Current hashes:

| File | SHA-256 |
|---|---|
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `05db0ff3f2a51d0d1e81a24f4de0c6d4be19dd98508c2dfbcfb6ecdc8b55ff1c` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `284c711028c3e4c0b1c8774178095e4aad743bbd7205d9db4122a840171f9ad7` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `3f00dbabf6b9749d06663f73314ca998c904204d2b86720f3c7495a2e61f2dac` |
| `SOURCE/lib/screens/wali/guardian_detail_screen.dart` | `3efca6ba3ffd279df714b2a30f99de0e011e0baecd9ff22674cc8e728f705cef` |
| `SOURCE/test/guardian_page_design_test.dart` | `024fd7412d24d201be24ff6fac829959afc8d98f28731cfede8e270e661051bc` |
| `SOURCE/test/guardian_design_control_test.dart` | `eb9b4ab94f6193ccc8fd83cb6cbaa6798891875fbb5b187410cf5c9d976ba11d` |

Measured before signed delivery: focused Guardian/control **16/16**; all five
have three or more asserted content regions; three App Surface modes; empty,
one and six Guardians; swipe/open/add; Main ordering and ID-stable reorder;
393×852 Dynamic Island fixture with card height at least 580 px and nav clearance
at least 8 px; 320×568 at 130% text; long/missing fields; direct visual matrix
**238/238**; full Flutter **540/540**; analyzer clean; formatter clean; ZYRA
checker 0 findings. The signed iOS profile build succeeded at **34.7 MB**. The
paired iPhone was discovered wirelessly; the deployment Xcode build completed
in 34.5s and install/launch in 24.5s, with a live Flutter VM service and Runner
process confirmed before detaching the Mac-side launcher. No migration,
Supabase write, commit or git mutation was used. These remain
**FOUNDER DESIGN SELECTION PENDING**; no visual baseline was self-approved.

## 21. 2026-08-27 Dashboard-route, Browse and Guardian controls — Browse lab superseded by §29

Current page-aware comparison controls are:

- **Dashboard Layout:** Now / Journey / You, ZYRA Compass, Journey Lens,
  Living Priorities and Progress Story. Reset = Now / Journey / You. These are
  five real Flutter layouts over the same A–H data; none is selected for
  production.
- **Guardian Page Design:** Guardian pulse, Shared path, Action board, Activity
  flow and Living link. Reset = Guardian pulse. Guardian Pulse is the
  production Route-2 base; the four siblings remain developer-only. All use
  the same large envelope and truth-preserving linked/activity input.
- **Browse Swipe Feedback (historical 15-treatment state; superseded by §29):**
  all fifteen treatments used one policy. Physical
  swipe left / negative dx / finger travel right-to-left = Consider/Like with
  the left-side cue; physical swipe right / positive dx / finger travel
  left-to-right = Pass/Dislike with the right-side cue; downward = Save with the
  top cue. This final Founder direction supersedes the earlier same-day
  interpretation.

Dashboard content no longer guesses one generic callback. A typed destination
routes Journey/compatibility/milestone/activity actions to Connections →
Journeys; Saved and family-introduction actions to Connections → Activity;
Guardian activity to Guardian; no-Journey discovery to Browse; setup to
Onboarding; profile to Profile; and preference review to the preference editor.
The full Notifications manager remains available from the production
Dashboard's compact header utility/badge. A shared Connections section controller overrides the
kept-alive tab's last subsection before navigation, preventing a Journey action
from reopening Introductions or Activity by accident.

The exact original regression is automated: onboarding complete + active
Journey + new activity + “See what changed” opens Connections → Journeys and
does not invoke Notifications. Guardian invitation cancellation retry now
retries the actual revoke operation. Compact Guardian cards are exercised at
320 px/130% text without overflow. All three experiments remain
**FOUNDER DESIGN SELECTION PENDING** where a design choice is involved. No
migration, production entitlement change or server-side verification bypass is
part of these controls.

## 22. 2026-08-28 shared production-resolution amendment

OA-ZYRA-264 introduced no new developer control. It changed the boundary behind
the existing Dashboard Layout selector:

- the five Lab concepts still use the same A–H mock dataset and remain
  authorised-developer-only;
- each concept now builds a `DashboardSnapshot` and consumes the shared pure
  `DashboardResolver` result;
- the retired private Lab priority score no longer competes with production;
- production uses `ZyraSeekerDashboardAdapter` plus one
  `ZyraResolvedDashboard` renderer and never reads the developer scenario as
  account truth;
- Guardian Pulse is the production Route-2 base while the other four Guardian
  Page Design choices remain developer-only comparisons.

Reset semantics are unchanged: Dashboard Layout resets to Now / Journey / You;
Guardian Page Design resets to Guardian Pulse; App Surface remains owned by the
Home control. The combined focused suite passed **119/119** and the governed
gate passed 215 render variants plus the complete Flutter suite. Full current
hashes/data flow live in
`ZYRA_SEEKER_DASHBOARD_HANDOVER_CURRENT_VERSION_V1.md` §12. No migration,
entitlement gate, production learning activation or release bypass was added.

## 23. 2026-08-28 loading, Connections and Introduction amendment

Founder authority added three coordinated developer/product changes without a
database migration.

### Loading comparison

The Seeker Style door now contains ten real shared loading motions and an
in-panel preview. Once selected, the shared loading value applies globally;
the picker itself is currently owned by that Seeker panel.
The choice is session-only, applies immediately to unpinned `ZyraLoading`
instances, honours reduced motion and Reset returns Meet & pass. The locked
ZYRA splash wordmark remains outside repeatable loaders. Release continues to
use Meet & pass until Founder selection; the ten-way comparison is
**FOUNDER DESIGN SELECTION PENDING**.

### Connections hierarchy and profile dismissal

Potential, Paused and Ended cards now share Active Journey's quiet top-right
Report flag. Potential gives its remaining width to View Profile and
Compatibility. Paused and Ended group Timeline plus the already-revealed
compatibility report under one `JOURNEY` reference area. Paused then gives the
separate two-control strip to View Profile and End Journey; Ended exposes only
the truthful View Profile destination outside its historical references. The
phrase `Paused together. Either of you can request to resume.` and all
`Paused together` card copy are removed.

Every Connections View Profile callback now uses one modal route contract.
The Connections profile omits the top-left X, shows a small drag handle and
dismisses on a downward distance or velocity threshold. A short drag animates
back into place. Non-Connections callers retain their existing close control.

### Introduction test state

> **Superseded presentation/action boundary:** the labelled,
> inspection-only local-row behaviour recorded below was the measured state at
> that delivery. Section 35 is authoritative for the current customer-facing
> card and local-only action architecture.

The existing Test Introductions selector now navigates to Connections →
Introductions after a change. The guarded `@zyra.test` RPC remains authoritative
when allowed. If and only if it returns `dev_accounts_only` for an authorised
developer such as `admin@zyraconnect.app`, the panel stages 0–5 local rows that
are explicitly marked `Preview`; it states that no server row was written.
Real suggestions remain visible and unchanged. Preview IDs are non-UUID,
`unseen:false`, non-release, session-only and inspection-only: View Profile is
available, while Report, Pass, Save, Consider and Compatibility are withheld
so a preview cannot invoke a production write or later resemble account data.
Other RPC errors remain truthful failures and create no fallback.

Current code evidence:

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/widgets/zyra_loading.dart` | `40dd86f9adc1b10cf777d7da95524fe065ccb636f9927431069dfb63f12ac459` | Ten loading motions and shared runtime selector |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `2ed58aebb81c6b7158c3f29f84b2ef2b3763447532d6369b6ec5ecd714efad07` | Loading and local Introduction session/reset state |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `1c0011bf9be4325e1cc5cf7a78c38f9d8be1de08dfa8b16c50d682a624f9ece5` | Loading control; real-RPC/Preview Introduction behavior and truthful copy |
| `SOURCE/lib/dev/zyra_dev_surface_coordinator.dart` | `d21cda2a6a91152a941124d37afce329a7090ad045251065361070aa019e8145` | Developer-only Introduction navigation callback |
| `SOURCE/lib/dev/zyra_global_dev_overlay.dart` | `771fc16b9ee7820818062de963b6b503eddf01de3861987c87e4465449265cce` | Callback plumbing into the global panel |
| `SOURCE/lib/screens/home/home_shell.dart` | `8a5900fd842f34cde2adfefa71180b680b31734515d9012d69ea25be015ce20e` | Existing Connections section controller bridge |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `44cb47cbd9bf1c5a99d43f286665affbe160d6fcd7fd60c85bdd6c5f225072c7` | Journey-card hierarchy, report flag, modal profile route and local Preview rendering boundary |
| `SOURCE/lib/screens/profile/seeker_profile_screen.dart` | `7684c0651a55da6709e7fece79b796df01bfafa2f4ace7b12eb02030bb0a9da2` | Opt-in swipe-down dismissal with unchanged non-Connections default |
| `SOURCE/test/loading_meet_and_pass_test.dart` | `bb89fbb9bf9aec22d12110f0db37b0a91edf2acc42d5b994e10c0012406c12b5` | Ten motions, reduced motion, selector and wordmark boundary |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `9b6eb61c7728446f3d07df39cead00cdde30718a4818796b67c3ec50e2aed939` | Selector/reset, real-RPC and local fallback truthfulness |
| `SOURCE/test/global_dev_overlay_test.dart` | `ecc55674241e2f3618e9ca2525552a6d19d9d4dc3543d2a33cfe1d2a846c613d` | Seeker callback ownership |
| `SOURCE/test/connections_design_defaults_test.dart` | `f5e469afd725254b2ddbf1d03b03ec4d65665108ecbdcca906aed7878611e3dc` | Exact Potential/Paused/Ended hierarchy, widths, compact text and Introduction 0/1/5 boundaries |
| `SOURCE/test/connections_profile_dismiss_test.dart` | `f09e6760699a2960e117ee28147dd51c0fe0a8a94b51453375415365f4be1c42` | No-X, full downward dismissal and short-drag return |

Measured evidence: formatter clean; changed-path **40/40 PASS**; complete
Flutter **577/577 PASS**; analyzer clean; structural/reference checker clean;
governed visual gate **215 variants PASS / BASELINE-PENDING**, with no open L2
finding and no self-approved baseline. Signed iOS profile build passed at
36.6 MB and the app package was installed wirelessly. The subsequent Flutter
VM-service attachment timed out in Apple's wireless CoreDevice handoff; this
does not reverse the successful build/install evidence and Founder device
observation remains pending. No migration, Supabase policy, entitlement,
package, credential, git action or production Introduction bypass was added.

## 24. 2026-08-28 Dashboard Home, all-gold loaders and Midnight Plum icon amendment

This amendment records OA-ZYRA-265 Dashboard developer parity plus two direct
Founder-authorised companion UI changes in the same relay. The loading/icon
changes are not misattributed to DR-ZYRA-217; Fable owns any additional
register trace.

### Dashboard controls

No new Dashboard control was added. Production now uses the conditional
six-level Seeker Home over the extended resolution. The existing five-layout
Dashboard Lab remains developer-only and keeps all quiet mock modules
reachable after resolver-ranked content. Home continues to own the one global
App Surface choice. Guardian Dashboard and Guardian control behaviour are
unchanged.

### Shared loading palette

All ten animated loading options and all ten reduced-motion frames now use the
same app gold token, `ZyraColors.journeyGold` (`#E8C98A`). This supersedes only
the mixed-colour facts in §23. Meet & pass remains the release and Reset
default; the selector, timings, geometries and no-wordmark rule are unchanged.

### App icon palette

The primary icon and seven live selectable alternates retain the Golden/Gold
Horizon treatments and current/large text-size variants, but their background
is now exact Midnight Plum (called “Midnight Purple” in the Founder relay):
`#684D78` at the top to `#241A2C` at the bottom. iOS, Android, macOS, web and
source assets were regenerated from the checked-in Swift generator.

Eleven `.appiconset` directories remain on disk. The live controller and
AppDelegate reference the primary plus seven alternates. The unreferenced
`ZyraGoldHorizonCurrent` and `ZyraGoldenDawnCurrent/Large` directories are
retired on-disk lineage, not selectable options, and were not represented as
live designs.

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/widgets/zyra_loading.dart` | `8fd625580317587597e17f5a8a634b35e508b252f718a42dd74f80bca9c6d797` | Ten all-gold animated/reduced-motion loaders |
| `SOURCE/lib/widgets/zyra_comet_rule.dart` | `04d2506583accf1688927ac1146142b35b98fca52fb728bf7874f34f0a221177` | Gold shared rule painter |
| `SOURCE/tool/generate_dev_app_icons.swift` | `238c0d396d318aae133870b6daca207d75cb249a09a87fe056e7e0557a8a02a7` | Midnight Plum multi-platform icon generator |
| `SOURCE/assets/icon/icon.png` | `ed28cff7c1090f934979de34f8c709231f0a233764585120f83d7d367e6ee1e8` | Regenerated source icon |
| `SOURCE/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | `fa53f80958cbb37089ee6278f86e96d95aa6870010fcb12a0d06d0a2044f5954` | Representative primary iOS asset |
| `SOURCE/test/loading_meet_and_pass_test.dart` | `ff77e1369cbdab10a28575e1598f54e51c091327a42e1a96ddd680d9a1a604bb` | All ten gold/reduced-motion/default/no-wordmark contracts |
| `SOURCE/test/zyra_dev_app_icon_test.dart` | `debfe1369a393186b50db1814109042ffc9073882c716e49ee4f38060292f765` | Live icon registration, size and Midnight Plum checks |

Measured evidence: loading/icon focused **11/11 PASS**; combined focused
Dashboard/loading/icon **92/92 PASS**; complete Flutter **599/599 PASS**;
analyzer clean; final governed gate **219 render variants PASS /
BASELINE-PENDING**. No migration, SQL, package, credential, server state,
release-default or visual-baseline approval changed.

— END OF AS-BUILT HANDOVER — verification and approval status are explicit. —

## 25. 2026-08-29 three-door lock and member Personalisation amendment — CURRENT

Direct Founder authority retired the general Style comparison surface after
selection. The right-edge control contains exactly **Home, Preview and
Actions**, in that top-to-bottom order. Home keeps restart/reset/test-account/sign-up controls but no longer
renders App Surface or app-icon choices. Actions no longer renders Connections
card-action or heading choices. There is no Loading-motion picker.

Current fixed product choices are Comet line, Floating Glass, Compact Chips,
Accent Marker, Glass Signals and the primary Gold Horizon/current-text icon.
Midnight Plum, Poppins and Subtle remain defaults, while their approved member
choice axes moved to the shared Seeker/Guardian Profile → Personalisation
screen: nine dark backgrounds, eighteen reading faces and five semantic haptic
levels. Light backgrounds are not available.

The runtime boundary is deliberate:

- unpinned `ZyraLoading` always resolves `kZyraLoadingStyle.cometLoop`;
- startup ignores and clears retired stored App Surface names and resolves
  Glass Signals;
- Connections rendering directly resolves Compact Chips and Accent Marker in
  debug/profile/release rather than reading developer scenario state;
- Floating Glass and Gold Horizon are no longer selectable in developer UI;
- background/font/haptic preferences use local `SharedPreferences`, hydrate
  before frame one and clear on sign-out; no server/profile truth is changed.

Full hashes, test commands, 606/606 regression evidence and device deployment
evidence are recorded in mailbox handover 013. No migration or git action was
used. Historical Style/picker implementations and alternate icon assets remain
on disk as lineage only, with no live control path; Fable owns their eventual
archive/removal reconciliation. Founder device acceptance and Fable
independent verification are pending.

## 26. 2026-08-29 Connections context controls amendment — CURRENT

> **Superseded Activity fixture boundary:** section 35 replaces this section's
> inspection-only/local-label statements. The page-aware control ownership and
> release isolation recorded here remain current.

Direct Founder authority made Connections Actions follow the segment actually
being reviewed. The Connections card begins with one Journeys / Activity /
Introductions sub-toggle. Selecting it moves the real kept-alive Connections
pager, and a user swipe or product-segment tap updates the same context back
into the panel.

The sections no longer expose one mixed control list:

- **Journeys:** Open live Journey plus Active, Potential, Paused and Ended
  preview counts. Paused retains its explicit pause-state matrix.
- **Activity:** Considered, Saved and Passed preview counts plus the existing
  compatibility-credit and Guardians-on-decided tools.
- **Introductions:** Test Introductions only, retaining the guarded server RPC
  and explicitly labelled local fallback described in §23.

Considered/Saved/Passed counts add 0–5 deterministic local Preview rows beside
real account truth in debug/profile builds. They never replace or mutate
`AppState` decisions, never render in release, use non-UUID ids, and reuse the
same inspection-only Activity-card boundary as local Introduction previews:
View Profile remains available; move, compatibility and report actions are
withheld. Reset clears all three counts while preserving `connectionsSection`
because the latter records navigation context rather than staged data.

The shared rail is now ordered **Home → Preview → Actions** everywhere it is
used. This changes reachability order only; Actions remains the initially
selected door and no product/account state moved into the rail.

Measured completion evidence and current hashes are recorded in mailbox
handover 014. Focused Connections/control tests passed **35/35**, the complete
Flutter suite passed **609/609**, analyzer and the 173-file structural checker
were clean, and the signed 34.9 MB iOS profile build installed and launched on
the paired wireless iPhone. No migration, SQL, entitlement, package,
credential, git action or production-data mutation was added. Founder device
acceptance and Fable independent verification remain pending.

## 27. 2026-08-29 Active Journey pause controls and collapsed-report amendment — CURRENT

Direct Founder authority moved **Pause Decision State** out of Connections
Actions and into the page-aware **Active Journey** Actions surface. Opening a
Journey temporarily changes the shared developer context to Active Journey;
closing it restores the previous context only when that Journey still owns the
context. This guard prevents a later navigation choice from being overwritten.

The shared `ZyraDevScenario.pauseScenario` remains the single mock-state
source. `JourneyFlowScreen` listens to it while mounted, so changing Awaiting
response / Resume available / Resume declined / Ended from the global rail
updates the visible Journey immediately. The older Journey-local PAUSE PREVIEW
picker was retired; the local stage jumper remains only for specialist Journey
stage and Life Snapshot controls. No production Journey, Supabase or
entitlement truth can be mutated by these developer controls.

Potential, Paused and Ended Journey cards now suppress their Report control
while collapsed and reveal it only inside the expanded identity row. The
Active Journey card keeps its existing always-visible Report control because
it is already presented as the active expanded experience.

Measured completion evidence and current hashes are recorded in mailbox
handover 015. The focused panel/Connections/overlay/pause suite passed
**50/50**, the complete Flutter suite passed **611/611**, analyzer and the
173-file structural checker were clean, and the 34.9 MB iOS profile build was
installed and launched on the paired wireless iPhone. No migration, SQL,
entitlement, package, credential, git action or production-data mutation was
added. Founder device acceptance and Fable independent verification remain
pending.

## 28. 2026-08-29 Paused/Ended Journey reference surface amendment — CURRENT

Direct Founder clarification removed the redundant **outer** glass box around
the two Journey references shown after Paused and Ended cards expand.
**Timeline** and **View Compatibility** retain their individual Compact Chips
pills and now use the same simple action treatment as **View Profile**. Their
icons, labels, callbacks, layout space and tap targets remain intact. The
JOURNEY label remains as hierarchy without drawing another enclosing surface.

The interim opposite interpretation (inner pills removed while the outer box
remained) was deployed but rejected before acceptance and is preserved only as
superseded evidence in mailbox 016. It is not the current design. The corrected
change affects no navigation, Journey, compatibility, reporting, account or
server state.

Measured completion evidence and current hashes are recorded in mailbox
handover 017. The focused Connections suite passed **12/12**, the complete
Flutter suite passed **611/611**, analyzer and the 173-file structural checker
were clean, and the 34.9 MB iOS profile build was installed and launched on
the paired wireless iPhone. No migration, SQL, entitlement, package,
credential, git action or production-data mutation was added. Founder device
acceptance and Fable independent verification remain pending.

## 29. 2026-08-29 Browse 3D photo-motion lab replacement — CURRENT

Direct Founder authority replaced the fifteen-treatment **Visual response**
lab with exactly eleven choices: the existing **Full aura** remains first and
is still the session/reset default, followed by ten 3D photo-motion options:
Layered parallax, Edge peek, Floating deck, 3D carousel, Door hinge, Page curl,
Depth tunnel, Subject split, Magnetic tilt and Horizon lift. The retired colour,
neutral and earlier five photo-motion alternatives are no longer selectable or
represented by the developer-state enum.

All ten new treatments use the live Browse card rather than adding action
buttons. They share the one `ZyraBrowseSwipePolicy` mapping and therefore do
not alter decision semantics, thresholds, persistence or fling outcomes:

- physical swipe left / negative dx = **Consider**, with the left cue;
- physical swipe right / positive dx = **Pass**, with the right cue; and
- swipe down / positive dy = **Save**, with the top cue.

For every 3D option, Browse renders the next real profile beneath the current
profile using its first photo and shared `ZyraProfileNameBlock`. The active and
underlying profiles are driven by the same drag progress and 220ms settle, so a
cancelled gesture returns both layers together while a committed gesture reveals
the next profile before `_advance()` replaces the active index. Existing image
pre-caching supplies that next profile; no new network request, timer, database
write or mock profile source was introduced. Full aura remains the current
fixed-photo production/default response and does not build the underlying
preview layer.

`Subject split` gives the identity block its own shallower transform; Door
hinge and Page curl change their transform origin according to left, right or
down; the remaining treatments each have distinct current/next depth,
perspective, scale and counter-motion. The post-commit `_BorderFlash` remains
shared across all choices. A stale in-code 2026-08-25 comment that reversed the
final left/right mapping was corrected to the 2026-08-27 Founder amendment; no
runtime mapping changed because the shared policy was already correct.

Exact changed implementation and regression files:

- `SOURCE/lib/dev/zyra_dev_scenario.dart`
- `SOURCE/lib/screens/browse/browse_screen.dart`
- `SOURCE/test/app_shell_correctness_test.dart`
- `SOURCE/test/browse_swipe_policy_test.dart`
- `SOURCE/test/dev_scenario_panel_policy_test.dart`

| Live file | SHA-256 |
|---|---|
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `4907cc5026b2e084f1cad0bb1a19d2fe764f3635f91745e491489cdff7b79a12` |
| `SOURCE/lib/screens/browse/browse_screen.dart` | `2973185a2e6241a2f5e556904905ec8379e2a797d67d61e7447ec813744d3367` |
| `SOURCE/test/app_shell_correctness_test.dart` | `5cf2d75b10b41b14a2f379e5b11f768b41f22964d1b7a95429673c12b839b808` |
| `SOURCE/test/browse_swipe_policy_test.dart` | `528aa5a93129451720b0d705ac6d6e6a271cc2ce4f581c99561ef18470a20738` |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `6f64864175a1c9aecc2a25892e2102ae977b3fc4e9005d520627755ea720308d` |

Measured completion evidence:

- Focused Browse/control/correctness suite — **35/35 PASS**.
- Complete Flutter suite — **625/625 PASS**.
- `flutter analyze` — **PASS, no issues**.
- `python3 tools/zyra_check.py` — **174 files, 0 findings**.
- Signed iOS profile build — **PASS**, `Runner.app` **34.8 MB**.
- Physical iPhone install — **PASS**; device inventory shows one ZYRA bundle,
  `app.zyraconnect.zyra` version 1.0.0. Flutter replaced the previous installed
  build, so device-local cache/session-only developer state may be reset.
- Automated launch — **BLOCKED BY iOS TRUST**, not by the app build: SpringBoard
  refused the Personal Team signature until the user explicitly trusts the
  developer profile in Settings → General → VPN & Device Management.
- Migration/SQL/entitlement/package/credential/git action — **none**.
- Founder on-device comparison and Fable independent handover verification —
  **PENDING**.

## 30. 2026-08-29 Browse motion test-deck expansion — CURRENT

Direct Founder authority added five local Browse preview profiles behind the
account's fetched candidate deck so the ten 3D Visual response options can be
tested across repeated card-to-card transitions. When the current account has
one live candidate, Developer Access now presents six cards in sequence: that
unchanged live candidate first, then five deterministic local previews.

The preview identities are opposite-gender to the signed-in Seeker and have
distinct names, ages and UK locations. The female set is Amira (28,
Manchester), Hana (31, Birmingham), Safiya (26, Leicester), Noor (30,
Glasgow) and Layla (29, Leeds); the male equivalent is Adam (30, Manchester),
Hamza (28, Birmingham), Zayd (32, Leicester), Idris (27, Glasgow) and Omar
(31, Leeds). All five deliberately reuse the first suitable card's already
loaded photo collection, so this motion-testing aid adds no image variety or
extra download requirement.

This is a developer-only composition boundary. `BrowseScreen` calls it only
when `ZyraDeveloperAccess.canUseDeveloperTools` is true; release Browse still
renders only fetched account truth. The preview ids use the non-UUID
`dev-browse-preview-*` namespace, so existing Browse guards prevent Save,
Consider, Pass, report, hide and compatibility-unlock server writes for these
cards. Real candidates remain first and are never replaced. Reset/reload keeps
the normal AppState decision filtering, and no Supabase row or migration was
created.

The Browse Actions panel now explains that five local cards follow the live
card. Regression coverage proves six cards from a one-card input, five unique
ids/names/ages/locations, shared photo reuse, and opposite-gender composition.

| Live file | SHA-256 |
|---|---|
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `b3ba87233fe387f701b88b649ec25078b275a16e78e0b724862323553737a1f1` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `32f3507bd5bcb0a46a94fc4f982adb023909ebe8ab35d09c5cf098b78b75ae29` |
| `SOURCE/lib/screens/browse/browse_screen.dart` | `ed03882f6d00efa9e97008501c314a81d00097c9c10d23c7f94422e3d62d49d8` |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `7e77473aafb85b34323c6e673aceb983800c609567971edfbf8f032c30584de1` |

Measured completion evidence:

- Focused Browse/developer/correctness suite — **37/37 PASS**.
- Complete Flutter suite — **627/627 PASS**.
- `flutter analyze` — **PASS, no issues**.
- `python3 tools/zyra_check.py` — **174 files, 0 findings**.
- Signed iOS profile build — **PASS**, `Runner.app` **34.8 MB**.
- Migration/SQL/network/entitlement/package/credential/git action — **none**.
- Device install was not repeated, so the Founder's existing local app/session
  was not overwritten. Founder on-device acceptance and Fable independent
  verification remain **PENDING**.

## 31. 2026-08-29 Connections collapsed-arrow alignment — CURRENT

Direct Founder authority aligned the collapsed **Considered**, **Saved** and
**Passed** Activity-card arrows to the collapsed **Potential Journey** card.
The defect was structural: Potential reserved a 32px centre-right slot around
its down arrow, while Activity rendered a bare icon inside a top-aligned row.
The glyphs matched but their positions could not.

Journey and Activity now use one `_ConnectionsCollapsedExpandArrow` widget,
sharing the same 32px width, centred alignment, 20px down-arrow glyph and
colour. The Activity identity row also centres its children vertically, so the
arrow remains centred against the complete 52px collapsed card header. This
applies equally to Considered, Saved and Passed. Expanded cards are unchanged:
their only collapse affordance remains the centred up arrow at the bottom, and
no duplicate top arrow was reintroduced.

Focused regression coverage renders the live Potential and all three live
Activity-card implementations, then proves both vertical centre alignment and
the exact same right inset. No navigation, decision, Journey, profile, server,
database or developer-state behaviour changed.

| Live file | SHA-256 |
|---|---|
| `SOURCE/lib/screens/connections/connections_screen.dart` | `a6fdbb8ffa312721004a4363d691a2a7a2a63abba16c18a7b6e67e2041292d06` |
| `SOURCE/test/connections_design_defaults_test.dart` | `08a4dc5f5fc410a9929304b41a2f9293595bb6728b29aa127850455015987dbd` |

Measured completion evidence:

- Focused Connections layout suite — **13/13 PASS**.
- Complete Flutter suite — **628/628 PASS**.
- `flutter analyze` — **PASS, no issues**.
- `python3 tools/zyra_check.py` — **174 files, 0 findings**.
- Signed iOS profile build — **PASS**, `Runner.app` **34.8 MB**.
- Migration/SQL/network/entitlement/package/credential/git action — **none**.
- Device install was not repeated, preserving the Founder's current local
  app/session. Founder on-device acceptance and Fable independent verification
  remain **PENDING**.

## 32. 2026-08-29 Connections Activity-card and Introduction-control repair — CURRENT

> **Superseded before Founder device acceptance:** section 35 replaces the
> action order, visible Preview treatment and action-withholding statements in
> this section. The compact Potential-style shell, expanded-only Report flag
> and Introduction control repair remain current.

Direct Founder authority unified **Considered**, **Saved**, **Passed** and the
shared **Introduction** presentation with the compact Potential Journey card
model. The identity thumbnail/name row now remains the single header in both
collapsed and expanded states. Expanding reveals the action deck in place; it
does not enlarge the photo or render a second profile header. The full-photo
experience remains available through **View Profile**.

Report is no longer an action pill on these live Activity cards. It appears as
the quiet top-right flag only after expansion, matching the approved Journey
pattern. The collapsed arrow occupies the same shared slot as Potential and the
single up-arrow at the bottom collapses the expanded card. The live action
matrix is:

| Activity state | Decision/bookmark pills | Shared actions |
|---|---|---|
| Considered | Pass; Save | View Profile; Compatibility Unlock/View Compatibility |
| Saved | Pass; Consider | View Profile; Compatibility Unlock/View Compatibility |
| Passed | Save; Consider | View Profile; Compatibility Unlock/View Compatibility |

Introduction rows reuse this compact card shell. Deterministic local developer
Introduction previews remain visibly labelled **Preview** and inspection-only:
they expose View Profile but no Report, decision, bookmark or compatibility
write. Real Introduction rows retain the live Activity actions.

The **Test Introductions** control no longer depends on parsing one particular
Supabase error string. An authorised Founder/admin OAuth account that is not a
seeded `@zyra.test` identity now stages the requested local Preview directly and
opens Connections → Introductions. Seeded test identities retain the guarded
server RPC. If that RPC succeeds but returns `created: 0`, or if it is
unavailable, the control shows an explicit labelled local Preview instead of an
empty page. Selecting zero clears local previews without claiming to clear
server rows. A local Preview bypasses only the debug/profile pending-load gate;
release still waits for live Introduction truth.

Exact current implementation and regression files:

| Live file | SHA-256 |
|---|---|
| `SOURCE/lib/screens/connections/connections_screen.dart` | `e06b29ca6621f849ee477c53be4dccd8db525ca10ef8541630eac1e97cab7ef8` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `b5623ab7cd2cf1319e7b52359c265f4410f4d429bb56d18c03e23563010d1acb` |
| `SOURCE/test/connections_design_defaults_test.dart` | `a08c52051ad9d05d49d714c43436cbdcf98890432db9a3daf9cb036527f6eeb3` |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `5d51722a625410b61be46bac8f5078bc53af126344100402c010a880e0606f70` |
| `SOURCE/build/ios/iphoneos/Runner.app/Runner` | `130490bee0e599fd7bca602ab80cfd6959d77e2906db8afaa781f7c28645b956` |

Measured completion evidence:

- Final focused Connections/developer/control/correctness suite — **53/53 PASS**.
- Complete Flutter suite — **636/636 PASS**.
- `flutter analyze --no-pub` — **PASS, no issues**.
- `python3 tools/zyra_check.py` — **175 files, 0 findings, 0 new doc refs**.
- Signed iOS profile build — **PASS**, `Runner.app` **34.8 MB**.
- Physical iPhone install — **PASS**; device inventory shows one ZYRA bundle,
  `app.zyraconnect.zyra` version 1.0.0.
- Automated launch — **BLOCKED BY iOS TRUST**, not by Flutter or the app build:
  SpringBoard refused the current development signature until the user trusts
  its developer profile in Settings → General → VPN & Device Management.
- Migration/SQL/network/entitlement/package/credential/git action — **none**.
- Founder on-device acceptance and Fable independent verification — **PENDING**.

## 33. 2026-08-29 Browse hide/report, Hidden Profiles, support, Full Aura and Guardian repair — CURRENT

Direct Founder authority implemented the launch-safe Browse profile-action
boundary, the Settings recovery surface, the requested support presentation,
the corrected Full Aura direction mapping and the locked Guardian card action.
No database migration was authorised or created.

### 33.1 Hide Profile and Hidden Profiles

Browse no longer displays the old “real profiles only” blocker. Selecting
**Hide Profile** now presents an explicit confirmation explaining that the two
people will stop seeing one another, a live Journey will end, no report is
created and unhiding will not restore an ended Journey. A real UUID uses the
existing `zyra_block_user` RPC. A non-UUID developer preview is handled only by
an account-scoped device store and is never sent to Supabase.

After a successful hide, the person is removed from the current Browse deck,
the in-memory decision lists, pending Browse state, potential/active Journey
state and cached signed image URLs. Server RLS remains authoritative for real
profiles. Developer previews are filtered against the local hidden-id set when
the test deck is rebuilt.

Settings now contains **Hidden Profiles**. It merges the authoritative server
blocked-id list with a minimal device summary captured from identity data that
was already visible at hide time. Each row can show the person's name, age and
city without retaining photos or signed storage URLs. Unhide requires
confirmation. Real UUIDs call `zyra_unblock_user`; developer preview ids are
removed locally only. A successful unhide clears the local summary and
refreshes Browse.

The current backend operation is mutual blocking, not a silent one-way hide,
and it terminates a live Journey. This is disclosed in the product copy rather
than misrepresented. OA-ZYRA-217 already tracks the unresolved one-way-hide
product/backend decision, so no duplicate action was raised. Older or
cross-device blocks that pre-date the local summary can still be safely
unblocked but may render as **Hidden profile — Details unavailable on this
device** because RLS correctly prevents refetching the blocked person's
profile. No new action was raised by Codex: solving that presentation-only
fallback requires a new server summary contract or migration, which the
Founder explicitly withheld; Fable should decide whether to register that
future enhancement.

### 33.2 Report flow

Browse reporting no longer displays the demo-only blocker. A real UUID submits
the existing `profile_reports` row first, then performs the existing block RPC
as a separate step. If the report succeeds but hiding fails, the sheet says
the report was sent and exposes **Retry hiding**; retry cannot duplicate the
report. Guardian reports remain report-only under the existing policy.

Developer preview reports exercise the same completion UI locally, capture the
safe local hidden summary when appropriate and never call the report or block
services with a fake id. OA-ZYRA-237 remains the existing record for the wider
moderation-queue/triage workflow; this change makes the current submission
path operational but does not claim that unresolved operations work is closed.

### 33.3 Help & Support

Every live app-source support reference now uses
`support@zyraconnect.app`. The Help & Support email row launches the exact
`mailto:support@zyraconnect.app` URI through the platform email handler and
provides an honest fallback if no email application opens. `url_launcher`,
which was already resolved transitively in the lockfile, is now declared as a
direct application dependency.

The **Signed in as** label and account email render as one responsive line with
ellipsis rather than wrapping. Stale `support@zyra.app` references remain in
governed business, legal and Settings-summary documents. Codex did not alter
those Fable-owned records; Fable documentation reconciliation is pending
against the already-current canonical ZYRA email document.

### 33.4 Full Aura and Guardian presentation

The Full Aura edge mapping now matches the gesture meaning: **Pass** is a red
line growing on the left edge and **Consider** is a green line growing on the
right edge. Gesture thresholds, fling direction and decision writes are
unchanged.

The live Seeker Guardian page is locked to **Guardian Pulse**. The full-profile
action now lives as a real **View full Guardian profile** control inside the
visible Guardian card; the whole card is no longer an invisible tap target and
the detached duplicate footer affordances were removed. The Guardian design
selector and alternative descriptions were removed from Developer Access.
Dormant renderer lineage remains in source for controlled retirement but is no
longer user- or developer-selectable.

### 33.5 Exact implementation and regression files

Added:

- `SOURCE/lib/services/zyra_hidden_profile_store.dart`
- `SOURCE/lib/screens/settings/hidden_profiles_screen.dart`
- `SOURCE/test/hidden_profiles_and_support_test.dart`

Removed:

- `SOURCE/lib/screens/settings/blocked_users_screen.dart`

Changed:

- `SOURCE/pubspec.yaml`
- `SOURCE/pubspec.lock`
- `SOURCE/lib/widgets/report_profile_sheet.dart`
- `SOURCE/lib/screens/browse/browse_screen.dart`
- `SOURCE/lib/screens/connections/connections_screen.dart`
- `SOURCE/lib/state/app_state.dart`
- `SOURCE/lib/screens/settings/settings_screen.dart`
- `SOURCE/lib/screens/settings/help_support_screen.dart`
- `SOURCE/lib/screens/wali/wali_profile_screen.dart`
- `SOURCE/lib/data/help_content.dart`
- `SOURCE/lib/screens/browse/browse_swipe_policy.dart`
- `SOURCE/lib/screens/wali/seeker_guardian_designs.dart`
- `SOURCE/lib/screens/wali/seeker_wali_tab.dart`
- `SOURCE/lib/dev/dev_scenario_panel_v2.dart`
- `SOURCE/lib/screens/profile/profile_screen.dart`
- `SOURCE/test/browse_swipe_policy_test.dart`
- `SOURCE/test/guardian_page_design_test.dart`
- `SOURCE/test/guardian_design_control_test.dart`

| Live file | SHA-256 |
|---|---|
| `SOURCE/pubspec.yaml` | `e8b3af2663a4f4b63e72a5e0b74bc4659cd5e6137f5cb12f171cac7181890700` |
| `SOURCE/pubspec.lock` | `c19b2f5b55e4d8f962a808d53a08323adf5a7095a88f5f671832d9592ab49524` |
| `SOURCE/lib/services/zyra_hidden_profile_store.dart` | `d51b3f71e26e6884d2ab4547a0685225c08eba7c5ddaff677340e80bd39475bf` |
| `SOURCE/lib/screens/settings/hidden_profiles_screen.dart` | `de9fc02018b6f0f99d56402e4a4067fb59c95250e99e3fa8073f94c3e6bec91d` |
| `SOURCE/lib/widgets/report_profile_sheet.dart` | `5b97aa2acfa335930d8568f947014e04a01d3907345e0dfde00b711236f811a4` |
| `SOURCE/lib/screens/browse/browse_screen.dart` | `6e7d158f3d2e81e89ae4434d8f8f55acd7896b44cbf623779092f6deaf69978e` |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `e06b29ca6621f849ee477c53be4dccd8db525ca10ef8541630eac1e97cab7ef8` |
| `SOURCE/lib/state/app_state.dart` | `8a93632564ec5129f1bc2a7c995329e9b435ef926cad708e6214d5ebd2ff4c5a` |
| `SOURCE/lib/screens/settings/settings_screen.dart` | `6cb2cc0359df785da85d8fe5b907e4624722afa94099104ae2e075db4f0b89b2` |
| `SOURCE/lib/screens/settings/help_support_screen.dart` | `536cdac40d543fc6c1448b76de39e70a5734aeec5d88c03fe463149ac9e21bde` |
| `SOURCE/lib/screens/wali/wali_profile_screen.dart` | `0f964fad8e51f576897e6b2400b93bc71369f23c40037b46bc334208a363d40a` |
| `SOURCE/lib/data/help_content.dart` | `d037b5bf48aaa6a569805566e674f26ac647f3ae4348d88bdcb05c61d7c83f05` |
| `SOURCE/lib/screens/browse/browse_swipe_policy.dart` | `4fb09e95276da80af294742e5ec1d7f3455371685080d2e199017cd91f5d7102` |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `2fa7af2d6874d6712735421952511b2dae6007b791515557514f1e48b5e542a6` |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | `410a3149a3b75ddbba202ba1d5f5bfddeee60d03d0d8617e85c9fbcaa5c18a11` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `b5623ab7cd2cf1319e7b52359c265f4410f4d429bb56d18c03e23563010d1acb` |
| `SOURCE/lib/screens/profile/profile_screen.dart` | `84667c2ee098f740d5879bdb59062e561f9e937c5d638c4c852d147760664a82` |
| `SOURCE/test/hidden_profiles_and_support_test.dart` | `769f7a667b07215129b3259ae4e3abc492c02827079d5102744f129745c71765` |
| `SOURCE/test/browse_swipe_policy_test.dart` | `9924d604a77ac2747197a2415e1938fc442edb4a31087d1c590a816dac77dccd` |
| `SOURCE/test/guardian_page_design_test.dart` | `3b7c9acedbb1e4eb99ecae4d400a521d0496e2f7ba35190f752180d0c52e0102` |
| `SOURCE/test/guardian_design_control_test.dart` | `94b13819143c287dbf52871c22462608d675cd1ad099296d11b2532b7b1bec1d` |

Measured completion evidence:

- Focused hide/report/support/Full Aura/Guardian suite — **29/29 PASS**.
- Complete Flutter suite — **636/636 PASS**.
- `flutter analyze` — **PASS, no issues**.
- `python3 tools/zyra_check.py` — **175 files, 0 findings**.
- Signed iOS profile build — **PASS**, `Runner.app` **34.8 MB**.
- Migration/SQL/Supabase data/credential/entitlement/git action — **none**.
- Device install was not repeated, preserving the Founder's current local
  app/session. Founder on-device acceptance and Fable independent handover
  verification remain **PENDING**.

## 34. 2026-08-29 Browse action haptic and Compatibility Breakdown comparison — CURRENT

Direct Founder authority added native haptic feedback to Browse's visible
three-dot action door and reopened exactly two Compatibility Unlock+ detail
comparisons in the shared Developer **Home** controls.

The Browse control now emits the member-selected native haptic semantic before
opening the existing action mode. The default is one selection click; a member
who has selected **Off** still opens the menu normally and receives no haptic.
The 40pt hit target, icon and action callbacks are unchanged.

Home now exposes exactly:

1. **Three-part rail** — each category is one proportional Aligned, Discuss
   and Opposed rail, with the aligned percentage stated at the row edge.
2. **Exact trio** — each category presents the three percentages in aligned
   columns.

The selector is one shared session state because Browse and Journey surfaces
open the same `ProfileUnlockScreen`; there are not separate copies to drift.
Reset returns to Three-part rail. The former Green / Amber / Red member labels
are now **Aligned · Discuss · Opposed**, including the locked preview and the
Unlock+ choice copy. Once either tier is visible, the redundant open-padlock
and **Unlocked** footer is removed.

### 34.1 Product-integrity boundary

The Founder also asked to remove the sentence saying the category breakdown is
an example. That removal was **not implemented**. Read-only inspection proved
that `score_candidates()` still returns only an overall result;
`profile_unlock_screen.dart` still uses fixed category values, and Journey's
stored category map still mirrors the overall score into every category.
OA-ZYRA-192 and OA-ZYRA-193(d) already record this exact launch blocker.

Deleting the qualifier now would make fixed paid sample values look like real
person-to-person results. A truthful removal requires a Founder-authorised
backend contract/migration returning real per-category Aligned, Discuss and
Opposed totals. No duplicate OA was raised. This is a written refusal of that
single unsafe presentation change, not a refusal of the approved visual lab.
No migration was authorised or created.

### 34.2 Exact implementation and regression files

Added:

- `SOURCE/test/browse_more_actions_haptics_test.dart`

Changed:

- `SOURCE/lib/dev/zyra_dev_scenario.dart`
- `SOURCE/lib/dev/zyra_dev_control_system.dart`
- `SOURCE/lib/screens/browse/browse_screen.dart`
- `SOURCE/lib/screens/subscription/profile_unlock_screen.dart`
- `SOURCE/test/dev_scenario_panel_policy_test.dart`
- `SOURCE/test/app_shell_correctness_test.dart`
- `SOURCE/test/connections_design_defaults_test.dart`

| Live file | SHA-256 |
|---|---|
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `9dabf9ff5d2f1e527726e00a986ceef6143c412ef6798201a88d69152d3961c5` |
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | `2bb40fe53cc56b5c82cb50f8d10e1bac10f7a821b2aadb1a64eca0472d8264d2` |
| `SOURCE/lib/screens/browse/browse_screen.dart` | `48bb3154b396f45a804c580d92e6f1b05cfcd2c4d7dc15287d897fc7fb669796` |
| `SOURCE/lib/screens/subscription/profile_unlock_screen.dart` | `ce767ef80fb6fe5284587f65730533906e2126945f6adff818c16d6c320e84db` |
| `SOURCE/test/browse_more_actions_haptics_test.dart` | `5d0241f358c514fae60f9f651f1cd23403ab263be45aaa9cb5452b72e8aeaf5d` |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `102a6bde4e9362d5d380e45365567bedbb246c763fa6e650edf9cd1d96265a1d` |
| `SOURCE/test/app_shell_correctness_test.dart` | `98d55e3466120e9d71d2ca8873f26c09b19f9208500701edb4945a8f24a96473` |
| `SOURCE/test/connections_design_defaults_test.dart` | `43420604b7ebc92f89ca7395c72b97d16545ac114642366dc5ca8403de9c6e6b` |

Measured completion evidence:

- Focused haptic/Home-selector/correctness/Connections suite — **54/54 PASS**.
- Complete Flutter suite — **641/641 PASS**.
- `flutter analyze --no-pub` — **PASS, no issues**.
- `python3 tools/zyra_check.py` — **175 files, 0 findings**.
- Signed iOS profile build — **PASS**, `Runner.app` **34.8 MB**.
- Migration/SQL/Supabase data/credential/entitlement/git action — **none**.
- Device install was not repeated, preserving the Founder's current local
  app/session. Founder choice between the two layouts and Fable independent
  handover verification remain **PENDING**.

## 35. 2026-08-29 Connections Activity production-parity correction — CURRENT

Direct Founder authority corrected the local Activity test rows before device
acceptance. Toggle-created people no longer expose a customer-visible
**Preview** badge and no longer use an inspection-only card. Local and live
people now use the same customer-facing Considered, Saved, Passed and
Introduction presentation; only their write boundary differs.

### 35.1 Current visible contract

Collapsed cards keep one compact identity row showing **name, age and
location**. Report is absent while collapsed. Expansion keeps that identity
row, adds the quiet Report flag in its top-right and reveals **View Profile**
followed by exactly three secondary pills:

| Activity state | Pill 1 | Pill 2 | Pill 3 |
|---|---|---|---|
| Considered | Save | Pass | Compatibility Unlock / View Compatibility |
| Saved | Consider | Pass | Compatibility Unlock / View Compatibility |
| Passed | Consider | Save | Compatibility Unlock / View Compatibility |

The two short state decisions share one row. Compatibility is the full-width
third pill below them so its complete label remains readable rather than being
ellipsized in a narrow three-column strip. View Profile remains the primary
pill above all three. The retired enlarged-photo expansion remains absent.

Introduction retains its existing Pass, Save, Consider and Compatibility
actions. A local Introduction moved into another Activity section retains its
**Suggested by Ibrahim** attribution in both the card and View Profile route.
Stable profile-based widget keys prevent one person's expanded/busy state from
being reused by the next row after a move.

### 35.2 Data flow and safety boundary

Production rows retain the existing flow:

`Activity action → AppState optimistic state → ZyraDiscoveryService → server`

Developer-toggle rows use non-UUID ids and a dedicated session-only flow:

`Activity action → ZyraDevScenario destination map → exactly one rendered section`

The origin count is a seed count. A moved fixture is removed from its origin,
appears once in its destination and is pruned wherever it moved when the seed
count is lowered. Reset clears all seed counts, destination overrides and
local hidden ids. Developer copy now calls these **starting cards** so the
count does not falsely claim to be the current destination count.

Local decision actions return before `AppState` or any discovery service.
Local Report/Hide uses the same visible report flow but delegates completion
to the scenario-only hidden set. `applySimulatedHideLocally: false` prevents a
toggle fixture from entering AppState or the persisted Hidden Profiles store.
Real rows and the separate Browse demo flow keep their existing persistence.
Release builds neither read nor compose these fixtures.

### 35.3 Supersession and limitations

This section supersedes only the labelled/inspection-only fixture statements
in §§23, 26 and 32 and historical mailboxes 011, 014 and 027. Those records
remain preserved as measured history. Their page-aware controls, server-RPC
fallback, compact card shell and expanded-only Report flag remain current.

No business rule, schema, RPC, entitlement, package, credential or migration
changed. Compatibility values remain governed by the existing Compatibility
implementation and its open correctness actions; this correction changes
reachability and presentation only. Founder on-device visual acceptance and
Fable independent verification are **PENDING**.

### 35.4 Exact implementation and regression evidence

Changed:

- `SOURCE/lib/dev/zyra_dev_scenario.dart`
- `SOURCE/lib/dev/dev_scenario_panel_v2.dart`
- `SOURCE/lib/screens/connections/connections_screen.dart`
- `SOURCE/lib/widgets/report_profile_sheet.dart`
- `SOURCE/test/connections_design_defaults_test.dart`
- `SOURCE/test/dev_scenario_panel_policy_test.dart`
- `SOURCE/test/hidden_profiles_and_support_test.dart`

| Live file | SHA-256 |
|---|---|
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `9dabf9ff5d2f1e527726e00a986ceef6143c412ef6798201a88d69152d3961c5` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `75cdd3590414021a7a50584826d7d946b2894c4ee815108f00cce467a16d1e5b` |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `9106eaf954fc5046103e757fd1130b2abfc3556d0c58f90414d55fbe13157d4b` |
| `SOURCE/lib/widgets/report_profile_sheet.dart` | `4b03b72ca0da3335315b1067ec90939621f6753064e828aeb9dea4cb9111ce15` |
| `SOURCE/test/connections_design_defaults_test.dart` | `0c1ebc3ca0128131f2ba360b37544e15407e2dc0c4c200cab0fb6392e16b61db` |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `102a6bde4e9362d5d380e45365567bedbb246c763fa6e650edf9cd1d96265a1d` |
| `SOURCE/test/hidden_profiles_and_support_test.dart` | `9cc2e5cbe5fef4ee5f7fcfa84ba8b2cb0bcdff1116233662af0fe346d7a354c5` |
| `SOURCE/build/ios/iphoneos/Runner.app/Runner` | `56e600982d3ebe5e8a49bcd649e8b6ad99d0e21c64102768a7363c3c7cdbb977` |

Measured completion evidence:

- Focused Activity/developer/local-report suite — **53/53 PASS**.
- Complete Flutter suite — **646/646 PASS**.
- `flutter analyze --no-pub` — **PASS, no issues**.
- `python3 tools/zyra_check.py` — **175 files, 0 findings, 0 new doc refs**.
- Signed iOS profile build — **PASS**, `Runner.app` **34.8 MB**.
- Physical iPhone install — **PASS**; inventory confirms ZYRA 1.0.0 at
  `app.zyraconnect.zyra`.
- Automated launch — **PASS**; `devicectl` launched
  `app.zyraconnect.zyra` successfully on the physical iPhone.
- Migration/SQL/Supabase data/credential/entitlement/package/git action —
  **none**.
