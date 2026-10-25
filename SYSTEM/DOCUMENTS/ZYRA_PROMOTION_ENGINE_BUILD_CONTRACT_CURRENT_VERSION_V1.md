---
id: DOC-ZYRA-0159
type: SPEC
status: CURRENT
feature: GENERAL
purpose: ZYRA — Promotion Engine Build Contract
links: []
owner: ZYRA chat
---

# ZYRA — Promotion Engine Build Contract

**Version:** V1  
**Status:** CURRENT_VERSION — APPROVED implementation contract  
**Date:** 2026-08-23  
**Product authority:** `ZYRA_RESPECTFUL_PROMOTION_AND_PERMISSION_CURRENT_VERSION_V1.md`  
**Decision / Action:** DR-ZYRA-213 / OA-ZYRA-255  
**Implementation owner:** Codex  
**Documentation owner:** Fable  
**Migrations:** None authorised

---

## 1. Build outcome

Replace scattered upgrade/permission judgement with one role-aware decision
engine and make both Seeker and Guardian surfaces obey the ratified cadence,
locked-state, settings and privacy rules.

This contract authorises app-local implementation only:

1. central evaluator and local cadence state;
2. role-aware notification education UI with an honest not-connected state;
3. central ZYRA One / Guardian+ promotion presentation;
4. Guardian Network locked/dependency/availability states;
5. shared persisted notification settings for both roles; and
6. developer-only, in-memory event evidence.

It does not authorise APNs/FCM, notification tokens, server senders, analytics
SDK/backend, payments, schema/RPC/RLS changes or any migration.

---

## 2. Required architecture

### 2.1 One evaluator

Create one service/model boundary equivalent to:

```text
evaluate(PromotionRequest) -> PromotionDecision
```

Required request fields:

- `roleContext`: seeker | guardian
- `targetProduct`: zyraOne | guardianPlus | notificationPermission
- `featureKey` and `placementKey`: fixed enums
- `trigger`: fixed enum
- `presentationIntent`: proactive | lockedFeatureTap | manualPlanEntry
- authoritative entitlement result
- dependency state
- new/existing-policy dates and successful-value marker
- prompt-history snapshot
- sensitive/exclusion flags
- current session impression count

Required decision outcomes:

- `hidden(reason)`
- `inlineInvitation`
- `lockedExplanation(state)`
- `notificationEducation`
- `openPlanOnUserTap`
- `openDeviceSettingsOnUserTap`

No screen may calculate time windows or plan eligibility independently.

The successful-value marker accepts only these fixed events:

- Seeker: successful Save/Consider write, mutual Match creation, Active Journey
  start, or Journey-stage completion.
- Guardian: accepted Seeker link, successfully saved Family Review response, or
  another completed Guardian action for a linked Seeker.

An event marks eligibility only; it never displays a promotion directly.

### 2.2 Entitlement boundary

- Seeker entitlement comes from the current server-hydrated plan.
- Guardian+ comes from `ZyraEntitlementService`/the current authoritative
  resolver, including Main-Wali coverage through a linked Seeker's ZYRA One.
- Local prompt history never grants capability and never overrides the server.
- `AppState.waliHasWaliOne` remains a mock/display aid, not production truth.

### 2.3 Local state

Persist only promotion UI state needed for cadence:

- policy-first-seen timestamp;
- successful-value marker by context;
- proactive impression timestamps and current-session count;
- same feature/placement last impression;
- soft-dismiss, not-now and purchase-failure cooldown timestamps;
- target-product decline-until timestamp;
- target-product permanent suppression flag;
- notification explainer count, last outcome and OS-state mirror for paint.

Use the existing local-preferences boundary, not a second persistence system.
Clear every field on sign-out, account switch and deletion. Do not store plan,
Guardian links, candidates, scores, safety state, profile ids or Journey ids.

### 2.4 Developer event sink

One in-memory event sink accepts only the event names/attributes in the product
standard. It must be compiled/routed as developer evidence, cleared by reset,
and make no network/database call.

---

## 3. Required surface behaviour

### 3.1 Notification education

- Implement the Seeker first-Active-Journey and Guardian first-link-success
  eligibility markers.
- Show the explainer only on the next calm landing.
- Because native notification integration is absent, the current production
  action must say notifications are not connected yet or be disabled with an
  honest explanation; it must not simulate an OS success.
- Developer scenarios may stage unknown/not-now/denied/authorised states.
- Apply two-lifetime maximum, 30-day retry and permanent-stop rules exactly.

### 3.2 Upgrade promotion

- Route every proactive invitation and locked-feature CTA through the engine.
- Do not auto-push `UpgradeScreen` or Guardian purchase from a proactive event.
- Existing manual Profile/Settings entry remains available.
- Consolidate duplicated screen-level cooldown/cap decisions into the engine;
  screens retain only actual product-limit enforcement.
- The Browse sponsored-card slot remains one slot; do not insert a second
  upgrade card beside it.
- Prices live on plan surfaces and remain sourced from the pricing authority.

### 3.3 Guardian Network

The production surface must render the four states from the product standard:

1. unlinked + not entitled -> Link a Seeker;
2. linked + not entitled -> See Guardian+;
3. entitled + unlinked -> Guardian+ active + Link a Seeker;
4. entitled + linked but GN production unavailable -> truthful unavailable/not
   yet live state, no purchase-to-unlock claim.

The developer D14 preview may continue to bypass production data, but the
developer panel must expose locked/dependency states so the gate is testable.
Every mock purchase path must state that no payment is taken.

### 3.4 Notification Settings parity

- Seeker and Guardian use the same persisted
  `ZyraNotificationPrefsService` and five server category codes.
- Remove the Guardian screen's AppState/session-only preference behaviour.
- Render: Device notifications; Service notifications; Marketing; Account &
  Safety, in that order.
- Service and marketing copy is role-aware without changing stored codes.
- Marketing switches remain append-only and default off; a failed write rolls
  the switch back with an explicit error.
- Device status is honest when native permission plumbing is absent.

---

## 4. Copy contract

Use these meanings; wording may be polished without changing the claim:

| State | Meaning that must survive |
|---|---|
| Notification explainer | Notifications are for replies/decisions that need the member; changeable later; no romantic urgency |
| ZYRA One lock | Available with ZYRA One; See ZYRA One; no automatic checkout |
| Guardian+ lock | Available with Guardian+; Guardian+ is the product name in Guardian context |
| Main-Wali coverage | A linked Seeker's ZYRA One may already include Main-Wali access |
| GN unlinked | Link a Seeker first; do not lead with purchase |
| GN unavailable/unbuilt | Honest current availability; payment does not make an unbuilt service live |
| Mock purchase | Preview only; no payment taken |

Never use hidden candidate data, blurred real cards, urgency, artificial
scarcity, score-based shame or a safety/trust promise.

---

## 5. Required tests and measurements

### 5.1 Evaluator unit matrix

At minimum prove:

1. launch/onboarding/auth/verification always suppress;
2. new account before 7 days suppresses;
3. existing account receives no catch-up-on-launch;
4. one/session and two/30-day caps;
5. same feature/placement 30-day cap;
6. 14-day soft dismiss, 30-day not-now, 90-day decline and permanent stop;
7. purchase failure 24h and lapse 7d;
8. top entitlement suppresses;
9. role context maps Seeker -> ZYRA One and Guardian -> Guardian+;
10. Main-Wali bundled entitlement suppresses Guardian+ upsell;
11. user-initiated locked tap remains explanatory under permanent proactive
    suppression and does not auto-open checkout;
12. every §5 product-standard sensitive state suppresses;
13. protection-hold/safety details are absent from request/events;
14. notification first value triggers, two-lifetime max and permanent OS-denial;
15. permitted analytics fields pass and prohibited fields are rejected.

### 5.2 Widget/device matrix

- Seeker Basic, Seeker One, Guardian Standard, Guardian+ and Main-Wali-covered
  variants.
- GN four-state matrix at narrow and standard phone widths.
- Seeker and Guardian notification settings both persist through the server
  service and fail honestly.
- Developer reset clears cadence/event state.
- Sign-out/account-switch test proves local promotion state clears.
- No proactive flow auto-opens a plan/paywall screen.

### 5.3 Completion evidence

Codex returns:

- exact files changed;
- explicit confirmation: no migrations/backend/provider/analytics SDK;
- named tests with pass counts;
- `flutter analyze` result;
- device observations for the two role contexts and all GN lock states;
- grep proving Guardian notification settings no longer use AppState session
  toggles and no production analytics/network sink was added; and
- as-built handover update under the No Undocumented Intelligence standard.

Fable reconciles this contract, the product standard and actual code before
OA-ZYRA-255 can close.

---

## 6. Stop-and-raise conditions

Stop before implementation if:

- native permission/plugin work becomes necessary;
- a schema/RPC/RLS/migration is needed;
- real payment or production analytics is proposed;
- a current entitlement cannot represent the role matrix;
- the locked state would expose private candidate/request facts; or
- an existing current authority contradicts this contract.

Those are scope/architecture changes, not implementation details.
