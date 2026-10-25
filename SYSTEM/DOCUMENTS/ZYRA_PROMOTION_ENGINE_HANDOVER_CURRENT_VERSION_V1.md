# ZYRA — Respectful Promotion and Permission: Implementation Handover

**Document:** `ZYRA_PROMOTION_ENGINE_HANDOVER_CURRENT_VERSION_V1.md`  
**Version:** V1  
**Status:** CURRENT_VERSION — RECONCILED; code and automated evidence complete, Founder phone walkthrough pending  
**Date:** 2026-08-23  
**Implementation owner / author:** Codex, Lead Architect  
**Documentation verifier:** Fable — reconciled against all 24 live-file SHA-256 values and the measured gates on 2026-08-23  
**Product authority:** `ZYRA_RESPECTFUL_PROMOTION_AND_PERMISSION_CURRENT_VERSION_V1.md`  
**Build contract:** `ZYRA_PROMOTION_ENGINE_BUILD_CONTRACT_CURRENT_VERSION_V1.md`  
**Decision / action:** DR-ZYRA-213 / OA-ZYRA-255  
**Standard:** `IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md`

---

## 1. What was built and why

ZYRA now has one role-aware policy engine for notification education, ZYRA
One invitations and Guardian+ invitations. Screens provide context and
authoritative plan/dependency truth; they no longer decide their own cadence.
The implementation follows the Founder principle: value first, one relevant
opportunity, then respect the member's choice.

The build also replaces the Guardian Network's former single entitlement
paywall with the four governed production states, gives both account contexts
one persisted notification-settings implementation, and provides deterministic
developer controls for every new state.

## 2. Architecture and data flow

### 2.1 Central evaluator

`ZyraPromotionEngine.evaluate(PromotionRequest) -> PromotionDecision` is the
single policy boundary. Requests use fixed enums for role, product, feature,
placement, trigger, intent, dependency and exclusion. Decisions distinguish
hidden, inline invitation, locked explanation, notification education,
user-initiated plan entry and user-initiated device settings.

The engine owns the 7-day warm-up, one-per-session and two-per-30-day caps,
same-placement 30-day cap, 14/30/90-day dismissal windows, permanent target
suppression, 24-hour purchase-failure suppression, 7-day plan-lapse
suppression, and the two-lifetime notification explainer limit. Safety and
protection holds are excluded and never enter its evidence log.

### 2.2 Successful-value path

- Seeker: a successful `promoteToActive` server result marks the first Active
  Journey notification moment and a future ZYRA One opportunity.
- Guardian: a successful Guardian-side Seeker-link acceptance marks the first
  link notification moment and a future Guardian+ opportunity.
- Marking eligibility never opens UI. The next calm shell landing asks the
  engine for a decision and may render `ZyraBottomPromotion` above the shared
  floating navigation.
- A proactive CTA opens plan information only after an explicit tap; no
  evaluator outcome starts checkout.

### 2.3 State and trust boundaries

Only cadence/opt-out UI state is JSON-encoded through the existing
`ZyraLocalPrefs`/SharedPreferences boundary. It clears on sign-out, account
switch and account deletion (deletion already calls `ZyraAuth.signOut`). Plan,
entitlement, Seeker links, candidate data, profile/Journey ids, answers,
scores and safety data are never stored there. Seeker plan remains
server-hydrated `AppState` truth; Guardian+ remains
`ZyraEntitlementService` truth.

### 2.4 Developer evidence only

The event sink is a bounded in-memory list with an exact event-name and
attribute allowlist. It rejects unknown/private attributes. It has no SDK,
network call, database call or production collection. Developer reset clears
events and cadence.

## 3. Live files and SHA-256 evidence

Hashes below are the complete SHA-256 values measured from the live working
tree after the final analyzer and full-suite run on 2026-08-23.

| File | SHA-256 | As-built role |
|---|---|---|
| `SOURCE/lib/main.dart` | `2095f2c708461ad9d601c7256813ea245a86629ded60b27e83d4527086894426` | Initializes local promotion policy before `runApp` |
| `SOURCE/lib/services/zyra_promotion_engine.dart` | `d5cd8069f110ea232a55cbcadf6501773f33a606732aca4ac4eaabaa9699213c` | Central evaluator, proactive/locked decisions, cadence, opt-outs, developer evidence and GN dev-state matrix |
| `SOURCE/lib/services/zyra_local_prefs.dart` | `ff32910fef55157863071e9c09887cbf27dec3befe550069181fea49ec3bb755` | Existing local boundary extended with one non-sensitive policy record |
| `SOURCE/lib/services/zyra_auth.dart` | `c183ea40f5c84773a8b16b2352dd2bce93c0856bd3d6b7c4244cf1fb43956b9e` | Clears promotion state/evidence on sign-out and deletion path |
| `SOURCE/lib/widgets/zyra_bottom_promotion.dart` | `e9ea4dc95638a6ac899bcd0e780ab705a85cf09568e62626fdb0f973d58032c6` | Shared non-blocking, five-second, narrow-safe bottom-nav invitation |
| `SOURCE/lib/widgets/zyra_locked_feature_upgrade.dart` | `048362add8708cf7851433fc0efd9ef48d16d314ba8af7dcf223d8475c104e31` | One locked-feature decision/navigation boundary; never opens checkout |
| `SOURCE/lib/widgets/zyra_paused_limit_refusal.dart` | `4d45c04535a42cd98f160f7547de1d94a8c4f4ddfce5c88504c6b9090d0a8cb6` | Existing paused-Journey upgrade CTA routed through the evaluator |
| `SOURCE/lib/screens/home/home_shell.dart` | `fc139fb99426c397148aca18d3adf8b058100456d72b57ec5b6de6ff1e79f1ed` | Seeker calm-landing host; authoritative Seeker plan passed in |
| `SOURCE/lib/screens/wali/wali_home_shell.dart` | `8c9e1a8aa4200bd95b067df5fde5da47480e84c3c68a9db1963cc91b82f76e78` | Guardian calm-landing host; Guardian+ resolver result passed in |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `787cf9400a8050f320dcd1a346037fbfb94b35a2e4eaf417dfb8adfe0742a6af` | Seeker successful-value marker after real Active Journey promotion |
| `SOURCE/lib/screens/wali/accept_wali_invite_screen.dart` | `9422d3d7e593d8a4477dbe58b52dd7e80e75e0afbe4bd2ab83bc02c74fe37978` | Guardian successful-value marker after real link acceptance |
| `SOURCE/lib/screens/settings/settings_screen.dart` | `1b513c56dea8dc5030477d88dc2f33d86968b0d4d24a64e33e6b0688b93d660f` | Seeker plan entry and upgrade-suggestion control |
| `SOURCE/lib/screens/wali/wali_profile_screen.dart` | `22951e59878ace34b14571b3abc28a45e12505f34ab50a70cffe5279be582389` | Guardian plan entry and upgrade-suggestion control |
| `SOURCE/lib/screens/settings/notification_settings_screen.dart` | `ee957d1b72318e58478474a93cbec45908598817271416d582e4516d3fe96ab3` | Shared role-aware persisted settings UI |
| `SOURCE/lib/screens/wali/wali_notification_settings_screen.dart` | `1a62fa7a2137c5d2605635759f455a1ed4a65058b407d28efcf93ba5ea528f92` | Guardian wrapper over the shared persisted settings UI |
| `SOURCE/lib/screens/wali/wali_network_screen.dart` | `50ec05c3f4ffe2fce4b206bc69529bcf83531818f6d73404972cec74ff76f603` | Four-state production GN access matrix plus retained D14 dev preview |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `6e536093d95b5db43e4a7566cb99935e0dd10d8713d9245d9474079fa829103d` | Seeker prompt previews/reset |
| `SOURCE/lib/dev/wali_dev_scenario_panel.dart` | `a4e946353b8565a7157ad72915fb7503d284f1b3301eca27f954f5d5ed8c6672` | Guardian prompt previews and all GN access states |
| `SOURCE/lib/screens/subscription/upgrade_screen.dart` | `5be71eef61050eba66ac09022c5a79ef09b1e4f7a3ea63e2794c6a17bf216fe4` | Manual view/checkout/result evidence and lapse suppression |
| `SOURCE/lib/screens/browse/browse_screen.dart` | `508ec0e7fba0dff2e0d9faddb7b4d62ef5a441a14268955233af419bd2b91447` | Existing browse/save/consider/ad-free locked CTAs routed through the evaluator |
| `SOURCE/test/zyra_promotion_engine_test.dart` | `dd45febcfd913a3512d0203eb4cf68daec2c5352a13ee5bb9cbfedf3b7db36b5` | Evaluator/cadence/privacy matrix |
| `SOURCE/test/zyra_bottom_promotion_test.dart` | `9a234c7d784bbbf64e560d7545598a81bb96cd008692c00b6d634851ab6bfa95` | Narrow layout, timer and no-auto-navigation tests |
| `SOURCE/test/guardian_network_preview_test.dart` | `d34cfbc0feaab8762cac5a2b72ae99ba2ff7c5efb10b390f0e1aba4b7962bff0` | D14 tests extended with four-state 320/390px matrix |
| `SOURCE/test/notification_settings_parity_test.dart` | `139b532aacf0148efa5a5917691fd0ec9aab9ea7f0a457f15ab236f638a29212` | Shared Seeker/Guardian persistence and honest-failure widget tests |

## 4. Surface behaviour

### 4.1 Notification permission education

The explainer is non-blocking, attached above bottom navigation, has a visible
five-second line, supports Not now, Don't ask again and close, and appears only
after an approved successful value event on a later calm landing. Native push
is not built: production therefore renders the honest disabled label **Not
connected yet** and says the in-app Notifications tab still works. Developer
preview may exercise an enabled outcome without claiming production success.

### 4.2 Upgrade invitations and settings

Seeker Basic maps only to ZYRA One; Guardian Standard maps only to Guardian+.
Entitled members are suppressed. Manual Profile/Settings plan entry remains
available regardless of proactive opt-out. Both profiles include an Upgrade
suggestions control that can permanently disable/re-enable proactive prompts
for that role's product. Existing Browse, Save, Consider, ad-free and Paused
Journey upgrade CTAs now pass through `decisionForLockedFeature`; their
existing explanation appears before an explicit plan-page tap, and none opens
checkout.

### 4.3 Guardian Network

Production resolves entitlement and linked Seekers independently and renders:

1. Basic + no linked Seeker: Link a Seeker; no purchase lead.
2. Basic + linked Seeker: privacy-safe Guardian+ benefits and See Guardian+.
3. Guardian+ + no linked Seeker: Guardian+ active and Link a Seeker.
4. Guardian+ + linked Seeker while production GN is unavailable: truthful
   not-available-yet message and no purchase claim.

No state shows a real hidden person, count, compatibility score or blurred
private record. Price is removed from the lock. The user must tap See
Guardian+ before plan information appears. Debug mock activation says no
payment is taken. Full D14 remains developer-only.

### 4.4 Notification settings parity

Both contexts now render, in order: Device notifications, Service
notifications, Marketing, Account & Safety. Both call the same existing
`ZyraNotificationPrefsService` five-code RPC boundary. Marketing remains
append-only/default-off server truth, and a failed write rolls the switch back
with an explicit message. Guardian AppState/session-only switches are retired.

## 5. Developer controls

- Seeker Account card: notification banner, ZYRA One banner, reset policy.
- Guardian Network card: D14 full preview, Basic/no Seeker, Basic/linked,
  Guardian+/no Seeker, Guardian+/linked-unavailable.
- Guardian Network card: notification banner and Guardian+ banner.
- Reset clears local policy, developer offer, GN gate selection and the
  in-memory evidence log. None of these controls writes entitlement or links.

## 6. Mock vs production

| Area | Production/current app | Developer preview |
|---|---|---|
| Native notification permission | Not connected; honest disabled action | Can stage not-determined/enabled UI outcome |
| Promotion cadence | Local app policy, authoritative plan supplied each evaluation | Same evaluator plus forced one-off banner previews |
| Promotion analytics | No collection | In-memory bounded allowlisted evidence only |
| Seeker plan | Server-hydrated truth supplied by AppState | Existing seeded developer plan switch |
| Guardian+ | Current entitlement resolver | Local access-matrix selector does not mutate entitlement |
| Guardian Network | Four privacy-safe access/availability states | Full existing D14 mock remains available |
| Payment | No new payment integration | Existing mock activation explicitly says no payment |

## 7. Verification evidence

- Documentation reconciliation: Fable independently recomputed every one of
  the **24** SHA-256 values in §3; all match the live files exactly.
- Focused acceptance: `flutter test test/zyra_promotion_engine_test.dart test/zyra_bottom_promotion_test.dart test/guardian_network_preview_test.dart test/notification_settings_parity_test.dart` — **27/27 PASS**.
- Full regression: `flutter test` — **174/174 PASS** (baseline before this work: 154/154); independently rerun by Fable with the same result.
- Static analysis: `flutter analyze` — **PASS, no issues**; independently rerun by Fable with the same result.
- Narrow UI: bottom invitation and all four GN states measured at **320×568**
  and **390×568** with no RenderFlex exception.
- No automatic paywall: widget test confirms display and five-second expiry do
  not invoke the plan callback; only the explicit CTA does.
- Locked-feature route audit: Browse Save/Consider/ad-free limits and the
  Paused Journey limit call the shared `zyra_locked_feature_upgrade.dart`
  boundary; the only `UpgradeScreen` construction across those audited files
  is inside that boundary after `decisionForLockedFeature`.
- Notification parity: both role screens use the shared callback/service
  boundary and a failed persisted write rolls back visibly.
- Static sweep: `wali_notification_settings_screen.dart` contains no AppState
  session-toggle reference.
- Sink sweep: the engine/widget contain no Supabase, HTTP, PostgREST,
  Firebase Analytics, Mixpanel or Amplitude import/call.
- Native-provider sweep: no notification-permission, Firebase Messaging,
  OneSignal or local-notifications package was introduced.
- Device build/install/launch: the final post-audit profile build completed
  Xcode in **31.8s**, then installed and launched successfully on **Shakeel
  Ahmad's iPhone (wireless), iOS 26.6**. The install/launch step measured
  **305.1s** because a stale earlier Flutter deployment was still attached to
  the same bundle; the stale process was identified and terminated, after
  which the final deployment completed. This proves final build/install/launch;
  it does not claim manual observation of every role/access state.

## 8. Migrations and external changes

**None.** No migration, schema, RPC, RLS, Edge Function, backend provider,
analytics SDK, APNs/FCM integration, token registration, real checkout or
Privacy-page claim was added or changed.

## 9. Known limitations and remaining work

- OA-ZYRA-254 remains the separate real APNs/FCM permission/token/sender work.
- OA-ZYRA-256 remains the separate privacy/architecture decision for
  cross-device account-level prompt suppression and any production analytics.
  Current SharedPreferences cadence is app-local and clears on context switch,
  sign-out and deletion as authorised.
- Actual purchase infrastructure is unchanged; new UI never claims otherwise.
- Full Guardian Network production data/processes remain unavailable; this
  build supplies the truthful access matrix, not mock-to-production migration.
- Founder manual phone observations across both roles and all four GN gate
  states remain pending. Automated 320/390px widget evidence and successful
  device install/launch must not be represented as that human observation.

## 10. Retired/drifted behaviour

- Guardian notification settings no longer retain a separate AppState/session
  model; the small wrapper exists only to select Guardian copy.
- The Guardian Network release path no longer claims purchase will unlock an
  unavailable service, no longer leads an unlinked Guardian with an upsell,
  and no longer presents price on the lock.
- Screen-local promotion timing decisions are not authorised. Future surfaces
  must submit a `ZyraPromotionRequest` or use the shared shell surface.

— END OF AS-BUILT HANDOVER — verify hashes before relying on this record. —
