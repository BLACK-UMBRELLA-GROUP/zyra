# ZYRA Dashboard Lab — Implementation Handover

**Version:** V1  
**Status:** SUPERSEDED — replaced by `ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V2.md` on 2026-08-25  
**Date:** 2026-08-24  
**Implementer:** Codex, Lead Architect  
**Authority:** Founder direct Dashboard redesign brief in Codex, 2026-08-24  
**Related governance:** AD-AIOS-099; AD-AIOS-104; OA-ZYRA-257; `AIOS_HANDOVER_STANDARD_CURRENT_VERSION_V1.md`  
**Production relationship:** Developer-only comparison layer; it does not select or replace the production Dashboard

> **Archive notice:** This is preserved implementation history. It is not the
> current Dashboard Lab authority. Use
> `SYSTEM/DOCUMENTS/ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V2.md`.

## 1 · What was built

A shared Dashboard Lab now renders five genuinely different Dashboard
compositions with the same representative state and reusable cards:

1. **Journey Command Centre** — makes the active Journey and next action the
   dominant control surface.
2. **Modular Personal Hub** — uses a rearrangeable, mixed-size bento layout for
   information density and personal control.
3. **Layered Story** — frames the day as where the user is, what changed and
   what comes next.
4. **Interactive Canvas** — makes the primary modules swipeable feature panels
   with a supporting at-a-glance rail.
5. **Calm Daily Overview** — reduces the page to one reassuring summary and the
   few actions that matter today.

Every concept has Seeker and Guardian content. The Guardian variants emphasise
the people supported, multiple Journeys, family progress and Guardian Network;
the Seeker variants emphasise the user's Journey, Discovery, saved profiles,
compatibility and Guardian activity.

The Lab supports representative empty, normal, busy and urgent states; no,
active and ended Journey states; new activity; pending Wali approval; family
progress; multiple supported Seekers; hero selection; module enable/disable,
reordering and compact/standard/prominent sizing; role preview; and reset.

## 2 · Product boundary and recommendation

This work is deliberately a comparison lab. It does **not** promote a concept
to production, change entitlements, invent backend state, or turn Dashboard
into an inbox. The existing live Seeker and Guardian Dashboards remain the
production fallback whenever Dashboard Lab is disabled or the account lacks
authorised developer access.

**Lead Architect recommendation:** **Layered Story** is the strongest direction
for ZYRA. Its three-part progression explains status without reading like an
analytics dashboard, gives Journey the correct emotional weight and adapts to
both Seeker and Guardian roles. The Founder remains the sole design approver.

The Founder brief referred to Aileron. The live style authority currently
defaults to Poppins and exposes a developer font selector. The Lab therefore
uses `ZyraText` rather than embedding a competing font, so all Dashboard
concepts remain compatible with the shared style controls. This is an explicit
integration decision, not a silent typography override.

## 3 · Architecture and data flow

```text
Authorised developer
      ↓ opens page-aware Action Control
ZyraDashboardLabControls
      ↓ mutates one shared ChangeNotifier
ZyraDevScenario (Dashboard Lab state)
      ↓ resolves role + immutable view config
ZyraDashboardExperience
      ↓ maps representative state to reusable modules
one of five composition builders
      ↓ existing navigation callbacks only
Journey / Discovery / Family / Activity destination

Ordinary account or Lab disabled
      ↓
existing production SeekerDashboardScreen / WaliDashboardScreen
```

`ZyraDashboardExperience` consumes a plain `ZyraDashboardViewConfig`; it does
not read the developer singleton. That boundary allows a Founder-selected
composition to receive a production data adapter later without coupling the
renderer to developer state.

`ZyraDevScenario` is the single owner of Lab state. Both Seeker and Guardian
action panels render `ZyraDashboardLabControls`, so there is no parallel or
role-specific mock store. Reset returns every control to the same documented
representative state.

## 4 · Shared module system

The reusable inventory is Journey, Next Step, Activity, Family, Discovery,
Saved, Compatibility, Profile, Milestone, Seekers and Network. Each module is
mapped to role-specific copy, count/progress, accent, action and urgency.

The five concepts compose this inventory differently instead of duplicating
five complete screens. Layout and state can therefore be compared without
allowing the underlying mock facts to drift between options.

Motion is restrained to entrance, press-scale, page/pill and progress
transitions. `disableAnimations` and `accessibleNavigation` reduce or remove
motion. No animation is required to understand status or invoke an action.

## 5 · Developer controls and entry points

- Seeker: open **Dashboard**, then the page-aware **Action Control**, then
  **Dashboard Lab**.
- Guardian: open **Dashboard**, then its developer scenario panel and
  **Dashboard Lab**.
- Select any of the five concepts and Current/Seeker/Guardian preview.
- Change the activity and Journey states, new-activity flag, pending approval,
  family progress, supported-Seeker count, hero, modules, order and sizes.
- Use **Reset Dashboard Lab** to restore the shared comparison state.

The Lab is guarded by `ZyraDevAccess.isDeveloper`. Developer state is in-memory
and resettable; it is not persisted to user data. Release users cannot surface
these controls through production navigation.

## 6 · Mock versus production behaviour

| Area | Dashboard Lab | Production fallback |
|---|---|---|
| Data | Representative in-memory state | Existing live screen behaviour |
| Role | Current, Seeker or Guardian preview | Authenticated account role |
| Navigation | Existing callbacks where a live destination exists | Existing production routes |
| Entitlement | Does not grant or alter access | Existing entitlement gates |
| Persistence | None | Existing app/backend behaviour |
| Design selection | Five temporary comparison options | Existing Dashboard remains live |

No private network information is exposed. No notification, promotion,
Journey, Guardian Network or subscription truth is written by this Lab.

## 7 · Live files and content hashes

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/models/zyra_dashboard_lab.dart` | Concepts, states, modules, sizes and immutable view config | `df9557929bc70ddf6673fc424bf486ab1a9cd519d73c7856233c95e363e872a5` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | Single shared Dashboard Lab state and reset | `4a34bd2d663d66c5c93c1b57a4aa8639e95982344590d0bda4169528fd7bc092` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | Reusable modules and five role-aware compositions | `273daf5265205abf5c43279b71506cfd591e42e54190ba33af6ba954175a9cc5` |
| `SOURCE/lib/dev/zyra_dashboard_lab_controls.dart` | Shared developer controls | `dcec7c819d1b090ef7ae9c96f54d75b4bde7d69e7a0018fe468ffb7c72fe5f6c` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | Authorised Seeker Lab entry and production fallback | `07e3c5db715cc3d84c7bc350ff640cfc832f5bc33132d6682a8a53842e9b5716` |
| `SOURCE/lib/screens/home/home_shell.dart` | Existing Seeker route callbacks, including Discovery | `878faa13b770f804cc05a72d7a76a41e776be83437c9f1a58d91f4608326a78d` |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | Authorised Guardian Lab entry and production fallback | `0db302279b70e8928952fb4fa6e0239ffb3db954332215eb28f4949a0185efe6` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | Seeker page-aware Action Control entry | `3efdf5f210703d6ab6ca2b2209c8c8d64cf6301958ef88c927ee2afedd3aa341` |
| `SOURCE/lib/dev/wali_dev_scenario_panel.dart` | Guardian Action Control entry | `31d2ecfc5d24a9c7f3720d7634ca4d3ac06f6c2386c9df21e369c54a6a81ac6e` |
| `SOURCE/test/dashboard_lab_test.dart` | Concept/role/control/reduced-motion tests | `37aaeaba7696ac0a1c15efb2d2ca2e3aaa317436a70e84d8bb23d32739bd63a2` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | Developer authority and production fallback tests | `a73a566f310c146d4431ef9b4f83730c6a90dd7db627fcd66bd69ca9bf832a18` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | Ten Dashboard fixtures across three phone widths | `f491f2c5dfc8f7d1f761c3afbc2c53dde0d03f82b684f8b0a06a7bbbafb982cd` |
| `SYSTEM/RESOURCES/UI_GATE/state_matrix.json` | Dashboard Lab visual-gate state/fixture inventory | `2e82a74672e410347904227d808952aa66d34ab591313bed2faf296187606ed6` |
| `SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_VISUAL_AUDIT_2026-08-24_37f41f14.md` | Final visual-gate evidence | `35a4997643c4c33906d93cb143383058c9af6f001e00eff257f2a79af9fce52c` |

This handover omits its own hash because embedding it would change that hash.

## 8 · Measured verification

| Measurement | Result |
|---|---|
| `flutter analyze --no-pub` | PASS · no issues |
| Focused Dashboard and integration suite | PASS · 28/28 |
| `flutter test --no-pub --reporter compact` | PASS · 306/306 complete repository tests |
| Dashboard-specific test | PASS · 13/13; all five concepts × both roles at 320×568, controls, reset and reduced motion |
| `flutter test --no-pub test/visual/zyra_visual_regression_test.dart` | PASS · 100/100 |
| Final UI gate | BASELINE-PENDING only · 99 render variants, zero approved baselines, zero overflow/test failure |
| Device render matrix | 320×568, 390×844 and 430×932 for each of 5 concepts × 2 roles |
| `flutter build ios --debug --no-codesign --no-pub` | PASS · `build/ios/iphoneos/Runner.app` |
| Database/SQL probe | Not applicable — no database or persistence change |
| Physical iPhone observation | PENDING — Founder installation and selection review |

The first non-escalated visual-gate attempt was blocked by the sandbox from
opening Flutter's local loopback socket. It is superseded by the successful
final run above and is not a product failure.

No candidate image was self-approved. OA-ZYRA-257 remains the authority for
Founder-approved baselines.

## 9 · Migrations

No migration was created or applied. No schema, RLS, RPC, trigger, storage,
authentication or persisted preference changed.

## 10 · Known limitations and remaining work

1. **Founder concept selection is pending.** This is the intended decision
   point, not a defect. No production concept was selected by Codex.
2. **Production data adapters are not built.** The selected design must be
   mapped to truthful Journey, Guardian, Discovery and activity projections in
   a separately authorised implementation. The Lab does not fabricate those
   projections in production.
3. **Physical-device visual and haptic observation is pending.** Automated
   rendering and iOS compilation passed; the Founder must judge the five
   options in the installed profile build.
4. **Visual baselines remain Founder-pending under OA-ZYRA-257.** Candidate
   captures exist, but zero were promoted.

## 11 · Superseded and still-live behaviour

Nothing was deleted or archived. The existing production Seeker Dashboard
handover remains authoritative for the live hub, and the existing Guardian
Dashboard remains live. This document is the authoritative as-built record for
the developer comparison layer only.

No git command was run. Codex did not self-approve the design or any visual
baseline.

---

## Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-24 | Added five role-aware Dashboard concepts, shared modules and one developer comparison/control system without changing production selection. |
