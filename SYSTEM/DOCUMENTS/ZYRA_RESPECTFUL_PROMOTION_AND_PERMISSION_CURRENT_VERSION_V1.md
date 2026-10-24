# ZYRA — Respectful Promotion & Permission Standard

**Version:** V1  
**Status:** CURRENT_VERSION — RATIFIED by direct Founder instruction  
**Date:** 2026-08-23  
**Owner:** Founder  
**Documentation Owner:** Fable  
**Decision:** DR-ZYRA-213  
**Implementation:** OA-ZYRA-255  
**Production telemetry gate:** OA-ZYRA-256

---

## 0. Authority and boundaries

This is the single product authority for:

- when ZYRA may educate a member about device-notification permission;
- when and how ZYRA may promote ZYRA One or Guardian+;
- upgrade placement and locked-feature behaviour;
- the Service versus Marketing structure in notification settings; and
- the privacy-safe promotion/permission analytics taxonomy.

It does **not** re-decide:

| Question | Authority |
|---|---|
| Notification event taxonomy, delivery priority, safety copy and category codes | `ZYRA_NOTIFICATION_SPECIFICATION_CURRENT_VERSION_V1.md` |
| Prices | `ZYRA_PRICING_CURRENT_VERSION_V2.md` |
| Guardian Network behaviour, D14, Main-Wali authority and entitlement | `ZYRA_GUARDIAN_NETWORK_CURRENT_VERSION_V2.md` |
| What survives a plan change | `SUBSCRIPTION_CONTINUITY_PRINCIPLE_CURRENT_VERSION_V1.md` |
| Pre-purchase prerequisites and disclosure | `TRANSPARENCY_CURRENT_VERSION_V1.md` |
| Runtime dependency communication | `DEPENDENCY_CURRENT_VERSION_V1.md` |
| Third-party sponsored-card rules | `ADVERTISING_STANDARD_CURRENT_VERSION_V1.md` |
| What may persist on the phone | `ONDEVICE_DATA_CURRENT_VERSION_V1.md` |

Where one of those authorities changes, the central evaluator consumes the
new fact. It must not carry a second price, entitlement or notification map.

---

## 1. Governing principles

1. **Ask after value, never before trust.** Neither an OS-permission prompt
   nor an upgrade promotion belongs on launch, during onboarding, or before
   the member has received real value.
2. **A declined permission is a decision, not a sales lead.** ZYRA never uses
   romantic urgency, fear of missing a spouse, or repeated interruptions to
   reverse it.
3. **Context may explain; it may not ambush.** Proactive upgrade promotion is
   inline. A full plan screen opens only because the member chose to open it.
4. **A lock tells the truth.** The interface distinguishes no entitlement,
   unmet dependency, unavailable service and unbuilt feature. It never sells
   the wrong cure.
5. **Payment buys capability, never safety, consent, authority or attention.**
6. **One evaluator.** Screens provide context; one central decision service
   decides visibility, cadence and suppression.
7. **No hidden people as bait.** A paid lock never exposes or blurs a real
   person, count, identity, score or activity state.

Prohibited copy includes: “Every missed notification is a missed chance”,
“Love is waiting”, “Someone is waiting for you”, artificial countdowns,
romantic scarcity and any implication that paying improves safety or trust.

---

## 2. Device-notification permission

### 2.1 Eligibility and trigger

| Member context | First qualifying value event | When the ZYRA explainer may appear |
|---|---|---|
| Seeker | First Active Journey successfully begins | On the next calm landing after the success state; never before the write succeeds |
| Guardian | First Seeker link is successfully accepted | On the next calm Guardian Dashboard landing; never inside acceptance |
| Existing member | A **new** qualifying event above after this policy is active | Same rule; historical state never creates a catch-up prompt on launch |

This preserves the existing approved rule that the Seeker permission is first
requested at the first Journey, while defining the respectful presentation
and the Guardian equivalent.

### 2.2 Two-step request

1. ZYRA shows its own short explainer.
2. The system prompt is requested **only** after the member taps **Enable
   notifications**.

Recommended copy:

| Context | Title | Body |
|---|---|---|
| Seeker | Stay close to your Journey | Turn on notifications for replies and decisions that need you. You can change this any time. |
| Guardian | Stay close to the people you support | Turn on notifications for requests and Journey decisions that need you. You can change this any time. |

Actions: **Enable notifications · Not now · Don’t ask again**.

### 2.3 Cadence and finality

| Response/state | Binding result |
|---|---|
| Enable tapped | Request OS permission once; record the returned state |
| Not now | 30-day cooldown, then one final explainer at a future equivalent value event |
| First explainer dismissed with back/X | Same as Not now |
| Second explainer dismissed | Permanent interruptive suppression |
| Don’t ask again | Permanent interruptive suppression |
| OS denied or restricted | Permanent interruptive suppression; Settings-only recovery |
| OS authorised | No further request |
| Permission later revoked in OS settings | No interruptive request; Settings-only recovery |

**Lifetime maximum: two ZYRA explainers.** The system prompt itself is never
called without the affirmative Enable tap. “Permanent” means until the member
deliberately uses the Settings control; an app update, sign-in, plan change or
new Journey does not silently reset it.

This is an **account-level product rule across devices**. The local preview in
§8 cannot prove cross-device finality; it must remain labelled provisional
until the OA-ZYRA-256 persistence decision/build is completed.

Settings may always show this neutral recovery row:

> Device notifications are off. Open your phone settings if you want ZYRA
> to alert you outside the app.

No feature is gated behind permission.

---

## 3. Central upgrade-promotion policy

### 3.1 Product and entitlement matrix

| Active context | Current entitlement | Promotion target |
|---|---|---|
| Seeker | ZYRA Basic | ZYRA One |
| Seeker | ZYRA One | None |
| Guardian | Standard Guardian | Guardian+ |
| Guardian | Guardian+ bought independently | None |
| Guardian | Main Wali covered by linked Seeker’s ZYRA One | None |
| Guardian | Additional Guardian without own Guardian+ | Guardian+ |

A multi-role identity resolves the active context first. It does not rename
Guardian+ as ZYRA One. Entitlement is fetched from the server and is never
accepted from local promotion history.

### 3.2 Proactive eligibility

A proactive promotion may be considered only when all are true:

- onboarding is complete;
- seven full days have passed since policy first became eligible for this
  installation/account context;
- at least one successful core value action has occurred;
- the member is not already entitled;
- the feature/plan really changes the outcome;
- no exclusion in §5 applies; and
- the frequency rules below allow it.

Existing users receive no catch-up promotion on rollout. Their first possible
promotion follows a **future contextual value action** after the same seven-day
settling period.

The successful-value marker is deliberately closed, not free-form:

| Context | Events that may set the marker |
|---|---|
| Seeker | a Save/Consider write succeeds; a mutual Match is created; an Active Journey begins; a Journey stage completes |
| Guardian | a Seeker link is accepted; a required Family Review response saves; a Guardian action for a linked Seeker completes |

Setting the marker does not itself show a promotion. A promotion still needs a
permitted §4.1 placement and a calm render after the action. Analytics, safety,
low scores, rejected relationships and merely opening the app never set it.

### 3.3 Presentation and cadence

**Proactive promotion is inline only.** It may be a calm invitation or a
clearly labelled locked feature state. It never opens a modal, plan page or
checkout automatically.

| Limit | Rule |
|---|---|
| Session | Maximum 1 proactive upgrade promotion |
| Rolling period | Maximum 2 proactive upgrade promotions in 30 days, all placements combined |
| Same placement/feature | Maximum once in 30 days |
| X/back soft dismissal | 14-day global proactive cooldown |
| Not now | 30-day global proactive cooldown |
| Not interested | 90-day suppression for that target product |
| Don’t show upgrade suggestions | Permanent target-product suppression until re-enabled in Settings |
| Purchase success | Suppress while entitlement is active |
| Purchase failure | No proactive promotion for 24 hours; manual retry remains available |
| Plan lapse | No proactive promotion for 7 days; contextual truth remains available |

Manual entry through Profile/Settings/Subscription is always available and
does not consume the proactive cap. A member tapping a locked feature is also
user-initiated; §4 governs that response.

---

## 4. Placement and locked-feature behaviour

### 4.1 Permitted placements

| Placement | Rule |
|---|---|
| Profile/Settings plan row | Always available; user-initiated |
| Contextual ZYRA Intelligence invitation | Inline only; central cadence applies |
| A real Basic plan limit where One increases the limit | Explain after the refusal, never before the attempted action; central cadence applies to the offer |
| Existing sponsored-card slot in Browse | Must not create a second insertion; central evaluator supplies the upgrade portion and the Advertising Standard governs the slot |
| Guardian Network locked state | §4.3 |
| Full plan comparison | Opens only from an explicit tap |

Never place a promotion in a safety, relationship-decision or consent action.

### 4.2 Four different unavailable states

| State | Required response |
|---|---|
| Not entitled | Explain the plan that contains the capability; optional **See [plan]** action |
| Dependency missing | State that the capability is already included where true; lead with the dependency action, not another sale |
| Service unavailable | Truthful retry/status state; never an upgrade |
| Feature not built/live | Truthful availability state; no purchase-to-unlock claim |

The CTA is **See ZYRA One** or **See Guardian+**, not an automatic checkout.
Prices appear on the governed plan screen only and must be read from the
pricing authority, never copied into scattered locked states.

After a user-initiated lock explanation is dismissed, another tap within 24
hours shows the explanation inline rather than reopening a sheet. It must
still explain the lock; “Don’t show upgrade suggestions” cannot turn a paid
feature into a dead control.

### 4.3 Guardian Network state matrix

| Entitlement/link state | Required presentation |
|---|---|
| No linked Seeker, not entitled | Dependency state. Primary action: **Link a Seeker**. Do not push a purchase before the Network can be used |
| Linked Seeker, not entitled | Privacy-safe Guardian+ lock. Action: **See Guardian+** |
| Guardian+ active, no linked Seeker | “Guardian+ is active.” Primary action: **Link a Seeker**. Never upsell again |
| Guardian+ active and linked, production Network unavailable | Honest availability state. Never imply purchase will make the unbuilt service live |
| Developer preview | D14 mock may be staged; every purchase action says no payment is taken and no production availability is implied |

The locked state may explain the capability in general. It may not reveal:

- whether any family or candidate exists;
- incoming-request or recommendation counts;
- a name, image, region, score, compatibility band or activity state;
- whether another Seeker consented; or
- a blurred/obscured real card as purchase bait.

Production truth remains: the complete D14 flow is developer-only until the
GN production contract and consent/backend gates are built.

---

## 5. Absolute exclusions and cooling periods

No promotion or permission explainer is shown during:

- cold launch, splash, sign-in, onboarding, account recovery or verification;
- an OS permission prompt or another modal/keyboard-critical action;
- reporting, blocking, safety, moderation or account-restriction flows;
- Guardian unlink/Main-Wali change;
- Journey end/decline/pause/resume confirmations;
- Family Review, “Proceed to the Seekers”, or “Not for us” decisions;
- compatibility reveal or a low/alarming score moment; or
- purchase failure handling.

Cooldowns:

- **72 hours** after a report, block, safety or moderation event;
- **24 hours** after a Journey ending/decline or family “Not for us”; and
- **24 hours** after payment failure.

Protection-hold existence or cause never enters the evaluator or analytics.
Religious/ethnicity answers, compatibility answers/scores and safety signals
are never promotion inputs.

---

## 6. Notification Settings information architecture

One shared, role-aware settings implementation serves Seeker and Guardian.
The existing five persisted category codes remain unchanged.

### Device notifications

One status row reports the OS state and, where off, offers **Open device
settings**. OS permission affects delivery outside the app; it does not
rewrite category consent or erase the in-app feed.

### Service notifications — default ON

- Matches & Journeys
- Guardian Activity
- Introductions

These are product preferences, not marketing consent. The Notification
Specification remains authoritative: a disabled category suppresses creation,
not merely display.

### Marketing — explicit opt-in, default OFF

- Product Updates
- Marketing Emails

They are independent append-only consent decisions. Service permission,
notification permission, subscription purchase and analytics never imply
marketing consent.

### Account & Safety

Shown as a non-toggle explanatory row. Account/security notifications have no
category switch under the Notification Specification. OS-level denial may
prevent push, but ZYRA must retain the in-app/account route.

---

## 7. Analytics taxonomy and privacy boundary

### 7.1 Governed event names

Promotion:
`promotion_evaluated` · `promotion_suppressed` · `promotion_impression` ·
`promotion_opened` · `promotion_dismissed` · `promotion_declined` ·
`locked_feature_viewed` · `locked_feature_cta_tapped` ·
`upgrade_screen_viewed` · `checkout_started` · `purchase_succeeded` ·
`purchase_failed` · `purchase_restored`.

Permission/settings:
`notification_education_shown` · `notification_education_dismissed` ·
`notification_permission_requested` · `notification_permission_result` ·
`notification_device_settings_opened` ·
`notification_preference_changed` · `marketing_consent_changed`.

### 7.2 Allowed attributes

`policy_version` · `role_context` · `target_product` · `feature_key` ·
`placement` · `trigger` · `presentation` · `outcome` ·
`suppression_reason` · `permission_state` · `platform` · `app_version`.

Every value comes from a fixed enum/taxonomy, not free text.

### 7.3 Prohibited attributes

Names; profile, match or Journey ids; notification titles/bodies; exact or
coarse personal location; onboarding/compatibility answers; numeric scores;
safety state/cause; candidate/request counts; GN counterpart identity; message
content; Guardian notes; device advertising identifiers.

### 7.4 Current truth

The app has **no production analytics SDK or pipeline**, and Privacy & Data
explicitly says it uses no analytics. OA-ZYRA-255 may implement this taxonomy
only as a local, in-memory developer evidence log. No SDK, database write,
remote collection or Privacy-page claim change is authorised by this decision.

Production collection requires OA-ZYRA-256: provider/first-party architecture,
purpose and lawful-basis review, retention, access controls, privacy wording,
opt-out/consent decision where applicable, and Founder approval before code.

---

## 8. Mock, local persistence and production boundary

- Promotion/permission cadence state may persist in `SharedPreferences` as UI
  preference state for this build; it is cleared on sign-out, account switch
  and account deletion under the On-Device Data Standard.
- Plan and entitlement are server-only and never cached as promotion state.
- Developer analytics is memory-only and dies with the process.
- Real APNs/FCM transport, device token storage and server delivery remain
  deferred under OA-ZYRA-254.
- No migration is authorised by DR-ZYRA-213.

Local persistence is sufficient only for preview/device UX verification. It
does not satisfy the account-level permanent-stop rule after sign-out or on a
second device. Before public launch, cross-device server persistence is
required under OA-ZYRA-256; its schema/migration still needs separate Founder
authorisation.

---

## 9. Open decisions and actions

| Item | Disposition |
|---|---|
| Local central evaluator, screens, parity and dev evidence | OA-ZYRA-255 — authorised build |
| Real APNs/FCM/provider/token pipeline | Existing OA-ZYRA-254 — deferred |
| Production analytics provider/first-party design, lawful basis, retention, privacy wording and cross-device prompt history | OA-ZYRA-256 — decision/build gate |
| Exact billing product/store integration | Existing pricing/payment actions; not re-raised here |

No other open decision blocks the local build contract.

---

## 10. Change control

Changing trigger moments, caps, cooldowns, permanent-stop semantics,
sensitive exclusions, role/plan mapping, analytics fields or GN locked-state
privacy requires a new Founder decision and a version bump. Individual screens
may not weaken these rules locally.
