# ZYRA — App Store Launch Runbook

**Version:** V1
**Status:** CURRENT_VERSION — live working runbook; steps tick off as they complete
**Date:** 2026-09-12
**Author:** Fable
**Register:** OA-ZYRA-267 (enrolment GO) · unblocks OA-102 (Apple Sign-In), OA-ZYRA-254 (push), OA-ZYRA-258 (IAP/payments step 1)
**Owner key:** [FOUNDER] = only you can do it (account/payment/identity — the AI team never touches these) · [CODEX] = implementation · [FABLE] = docs/registers/verification

---

## PHASE 0 — one decision before paying: Individual or Organisation

Apple offers two enrolment types (verified against Apple's current enrolment page, 2026-08-28):

| | Individual | Organisation |
|---|---|---|
| Needs | Apple ID with 2FA, your legal name, address (no P.O. box) | Registered **legal entity** (no trading names), **D-U-N-S number**, authority to bind the company, **work email on the company domain**, **public working website** |
| Seller name shown on the App Store | Your personal legal name | The company name |
| Speed | Usually fastest (often 24–48h) | D-U-N-S check adds days if you don't already have one |

**ZYRA's position:** the website requirement is already satisfied (zyraconnect.app, live) and a company-domain email is easy (e.g. hello@ / developer@zyraconnect.app). The open question from the legal research is whether the legal entity (Black Umbrella Group / ZYRA entity) is **registered at Companies House yet**.

**Recommendation:** if the company IS registered → enrol as **Organisation** (get the free D-U-N-S first if none exists — Apple provides a lookup/request tool during enrolment). If NOT registered → enrol as **Individual today** to unblock all development (TestFlight, Sign-In, push, IAP sandbox), and migrate to Organisation before public launch (Apple supports converting via Apple Support; apps can also transfer between accounts). Do not let company paperwork block development.

**Second small decision:** enrol with a dedicated Apple ID the company controls (e.g. developer@zyraconnect.app) rather than a personal daily-use Apple ID. This account will own the app forever.

## PHASE 1 — enrolment [FOUNDER, ~30 minutes + Apple's approval wait]

1. Choose/create the Apple ID (Phase 0) and make sure **two-factor authentication is ON** (appleid.apple.com → Sign-In and Security).
2. Go to **developer.apple.com/programs/enroll** → Start Your Enrollment, signed in with that Apple ID.
3. Entity type per Phase 0. Enter legal name/entity details exactly as registered — no abbreviations.
4. (Organisation only) supply D-U-N-S, your role/authority, work email, website.
5. Agree to the Apple Developer Program License Agreement.
6. Pay — **US $99/year base; the local GBP price (~£79/yr) shows at checkout**; auto-renews yearly on your payment method.
7. Wait for the activation email. Individual: usually 24–48h. Organisation: can take longer (verification call possible).
8. **Tell Fable when active** → I file the finance record (annual subscription) and flip OA-ZYRA-267.

### EXECUTION RECORD — Phases 0–1 (2026-08-29)

Phase 0 decided: INDIVIDUAL (Founder, 2026-08-29). Phase 1
executed same day — Apple Account admin@zyraconnect.app
created with 2FA (1 trusted number); both agreements accepted
by Founder; paid GBP 79/yr, Apple Store Order W1578479196.
ACTIVATED 2026-08-29 (same day): membership ACTIVE, Team ID
9Y7Z8F36SJ, enrolled as Individual — OA-ZYRA-267 CLOSED.
Renewal: no card on file for auto-renew -> OA-ZYRA-272.
Phase 2 sequencing: App ID/app record creation waits for
OA-ZYRA-268 (app.zyraconnect.zyra unification, DR-ZYRA-218);
Founder ASC sign-in + agreements can run any time. Fable
drove browser navigation; Founder typed every identity,
credential and payment field. Finance record filed (AIOS
finance store, ref W1578479196). OA-ZYRA-267 updated.

PHASE 2 PRE-CHECK (Fable, 2026-08-29, read-only): bundle
identifiers are currently INCONSISTENT — iOS Runner =
com.shakeelahmed.zyraapp, iOS tests = com.zyra.app.RunnerTests,
Android applicationId = com.zyra.app. None is backed by an
owned domain (owned: zyraconnect.app -> app.zyraconnect.*).
RULED 2026-08-29 (DR-ZYRA-218): canonical identifier =
app.zyraconnect.zyra, unified on both platforms BEFORE the
App ID / app record is created. Codex implements + verifies
dependent configuration under OA-ZYRA-268 (brief 015).

### PHASE 2 PRE-CHECK EXECUTION — 2026-08-29

Codex completed the repository-side unification under DR-ZYRA-218 /
OA-ZYRA-268: iOS Runner = `app.zyraconnect.zyra`, RunnerTests =
`app.zyraconnect.zyra.RunnerTests`, and Android application ID / namespace /
Kotlin package = `app.zyraconnect.zyra`. Debug and release builds compile on
both mobile platforms; built-product probes report the canonical ID, and a
fresh iOS Simulator install launches. No App ID, App Store Connect record,
certificate, signing-team change or migration was created.

The external-auth portion is deliberately not overstated: the live Supabase
Google allow-list still contains the web client plus the pre-unification iOS
client, and its Apple allow-list still contains
`com.shakeelahmed.zyraapp`. Google Cloud must register/rebind the canonical
iOS bundle and Android package + signing SHA-1 before real OAuth is re-tested.
Apple's canonical client ID, App ID, capability, entitlement and paid-team
signing remain Runbook Phase 2 work. Full evidence and hashes are in
`SYSTEM/RESOURCES/MESSAGES/017_CODEX-FABLE_2026-08-29_BUNDLE_ID_UNIFICATION_COMPLETE.md`.

## PHASE 2 — App Store Connect foundations [FOUNDER 15 min, then CODEX]

9. [FOUNDER] Sign in at appstoreconnect.apple.com → accept the pending agreements banner (free apps agreement at minimum).
10. [FOUNDER] Users & Access: keep yourself Account Holder. (Codex has no Apple identity — builds are made on your Mac, so no extra users are needed yet.)
11. [CODEX] Confirm/settle the app's **bundle identifier** in the Xcode project (permanent once shipped), register it in Certificates/Identifiers with capabilities: Push Notifications, Sign in with Apple, In-App Purchase.
12. [FOUNDER, guided] In App Store Connect → Apps → “＋” → New App: platform iOS, name **ZYRA** (availability is first-come; secure it early), primary language English (UK), the bundle ID from step 11, SKU (e.g. ZYRA-001).
13. [CODEX] Switch Xcode signing to the new team (automatic signing) and produce the first archived build.

### PHASE 2 EXECUTION RECORD (2026-08-29, Fable-driven browser session)

Google: iOS OAuth client rebound in place (bundle
app.zyraconnect.zyra, Team 9Y7Z8F36SJ, client ID unchanged);
Android client "ZYRA Android" created (canonical package +
measured SHA-1). Supabase: Google allow-list = web, iOS,
Android (saved, re-verified). Apple: App ID registration
BLOCKED — identifier held by another team (diag1 diagnostic
proved collision, not policy) -> OA-ZYRA-274; ASC app record
and name reservation wait on it. Path (a) executed same day:
Apple Developer Support CASE 20000150964412 raised asking for
release; reply lands at admin@zyraconnect.app. New pre-release gates filed:
OA-ZYRA-275 (Google consent screen Testing->Production),
OA-ZYRA-276 (Supabase free-plan quota banner). Founder
performed every sign-in/2FA; no secrets recorded.

### PHASE 2 PRE-CUTOVER RE-MEASUREMENT — 2026-09-11 (historical checkpoint)

The 2026-08-29 collision record above is historical, not current source
truth. A local read-only audit now proves that Runner Debug/Profile/Release
use automatic signing, paid Team `9Y7Z8F36SJ`, canonical bundle
`app.zyraconnect.zyra`, and the Sign in with Apple entitlement. A retained
Store export made on 2026-09-10 also proves that the paid-team App ID and
capability existed at export time.

That retained IPA predates the Request New Journey TestFlight hold and must
never be uploaded. It is evidence only. A fresh unsigned release compile from
current source passed as version `1.0.0` build `2`; this is preparation
evidence, not a signed archive or upload candidate.

Authenticated read-only Apple verification completed later on 2026-09-11.
Apple Developer shows explicit App ID `app.zyraconnect.zyra` on paid Team
`9Y7Z8F36SJ`, description ZYRA, with In-App Purchase, Push Notifications and
Sign in with Apple enabled. App Store Connect shows app record `ZYRA Connect`,
Apple ID `6810741513`; TestFlight shows `No Builds` and no internal-testing
group. No Apple setting, tester, build or metadata was changed. OA-ZYRA-274 is
closed. A direct host-keychain check now finds two valid Apple Development
identities and no Apple Distribution identity. The eventual fresh archive must
therefore still prove Xcode's authenticated automatic/cloud distribution-
signing path.

Phase 3 remains held behind the governed database release sequence and a
separate Founder upload authority. The next signed archive must be created
fresh from the post-gate source; neither the retained IPA nor the unsigned
compile is eligible for upload.

### PHASE 3 OFFLINE RELEASE PREPARATION — 2026-09-11 (historical checkpoint)

The phone-free, non-transmitting preparation is complete:

- source version is now `1.0.0+2`, rather than relying on a command-line build
  override;
- `Info.plist` explicitly declares `ITSAppUsesNonExemptEncryption=false` after
  a release-source audit found standard HTTPS/platform security and SHA-256
  OAuth nonce hashing only, with no custom cipher or proprietary encryption;
- `ios/TestFlightInternalExportOptions.plist` is now the governed export
  contract: App Store Connect method, automatic signing, paid Team
  `9Y7Z8F36SJ`, `destination=export`, automatic build-number management off and
  `testFlightInternalTestingOnly=true`;
- feedback submissions now read the installed bundle version instead of
  hard-coding build 1;
- the dedicated release-preflight contract passes 7/7, all 560 non-visual
  tests pass, analyzer and repository checks are clean, both property lists
  validate, and a fresh unsigned iOS release compile proves installed identity
  `ZYRA`, bundle `app.zyraconnect.zyra`, version `1.0.0`, build `2`, and the
  export-compliance flag;
- the full visual run still records the same 60 approved-baseline mismatches
  already present before this configuration-only work. No approved pixel was
  regenerated or changed.

At that checkpoint this preparation had not created a signed archive or IPA,
contacted App Store Connect, applied a migration, accessed production or
consumed an Upload GO. The retained build-1 IPA at SHA-256
`4685a31b...7415` remains evidence only and is explicitly denylisted from
upload.

### PHASE 3 POST-CUTOVER ARCHIVE/EXPORT RECORD — 2026-09-11

The Founder authorised one exact two-migration production cutover on project
`sxoaxonzjqkgajmlagyk`. Both byte-pinned migrations were applied atomically in
the ruled order while ZYRA remained closed, and the complete post-apply
verification passed. Only then did Codex create a fresh signed archive and
export an internal-only IPA at version `1.0.0`, build `2`.

The exported IPA is:

- path: `/private/tmp/zyra-testflight-internal-1.0.0-build2-20260911-postcutover-63381feb-0ac36fd4/export/ZYRA.ipa`;
- SHA-256: `1e17a1c3475db1bcb01e59415768d94480538bb601aedcdc8fdd706ea1a7b673`;
- display name `ZYRA`, bundle `app.zyraconnect.zyra`, minimum iOS `13.0`,
  `ITSAppUsesNonExemptEncryption=false`, arm64;
- signed by Apple Distribution for Team `9Y7Z8F36SJ`, with
  `get-task-allow=false`, `beta-reports-active=true` and Sign in with Apple
  `Default`;
- provisioned by `iOS Team Store Provisioning Profile:
  app.zyraconnect.zyra`, expiring 2027-09-10; and
- exported using a byte-identical copy of the governed internal-only export
  options.

Archive integrity, deep/strict signature, identity, entitlements, profile and
hash checks passed. The first restricted-shell signature check returned
`CSSMERR_TP_NOT_TRUSTED` because that shell could not read host Keychain trust;
an independent system-trust check passed without changing signing state.
App Store Connect was then re-read authenticated and still showed `No Builds`
and no internal group. No Apple upload occurred and no Upload GO was consumed.

### PHASE 3 TESTFLIGHT ACTIVATION — 2026-09-12

Under the Founder's exact single-use upload authorities, Apple retained the
exact IPA above and now shows ZYRA `1.0.0 (2)` as `Ready to Test`. The local
upload wrapper failed while serialising Apple's success result, so no retry was
made; App Store Connect later provided the authoritative completed state.

The sole internal-testing group is `Founder Internal`. Automatic distribution
is OFF, its only listed tester is `admin@zyraconnect.app`, and its only assigned
build is ZYRA `1.0.0 (2)`. The tester is `Invited`; Founder acceptance,
installation and device result remain pending. No external tester/group or
public App Store release was authorised or changed.

Apple's delivery email reported non-blocking warning `ITMS-90068:
MinimumOSVersion too low`. The already-uploaded build 2 is immutable and
truthfully remains minimum iOS 13.0. All three Xcode source configurations now
require iOS 15.0, with a release-preflight regression check, for the next
build. A corrected binary would be a new build number and requires its own
archive/export/upload authority; build 2 must not be retried or replaced under
the consumed upload authority.

## PHASE 3 — TestFlight (the immediate win) [CODEX builds, FOUNDER tests]

14. [CODEX COMPLETE] The exact post-cutover internal-only IPA is uploaded and `Ready to Test`; `Founder Internal` is configured manually with only the Founder account and build 2.
15. [FOUNDER] TestFlight app on your iPhone → accept the internal-tester invite → install ZYRA over the air. **From this point, no more cables or `flutter run` for your device tests.** Internal testing is instant, no review, up to 100 internal testers.
16. External testers (family/testers later) require a light Beta App Review pass — Phase 5's readiness items apply in miniature.

## PHASE 4 — money plumbing (sequenced per OA-ZYRA-258) [FOUNDER + CODEX]

17. [FOUNDER] App Store Connect → Business: sign the **Paid Applications Agreement**, add **banking** and **tax** details (UK). Founder-only, same rule as Stripe onboarding. IAP products cannot go live without this.
18. [CODEX] Create IAP products mirroring **ZYRA_PRICING_CURRENT_VERSION_V2** exactly: ZYRA One £39.99/mo · £399.90/yr · £19.99/wk; Guardian+ £24.99/mo · £14.99/wk; the unlock packs (£1.99/£7.99/£2.99/£9.99) as consumables/non-consumables as specified at build time. Auto-renewable subscriptions in one subscription group per product line; sandbox testing with sandbox Apple IDs.
19. [CODEX] **Sign in with Apple** (OA-102) — REQUIRED by Apple because ZYRA offers Google sign-in. Ships before public release.
20. [CODEX] Push notifications (OA-ZYRA-254) — APNs key from the developer account; product rules for which notifications exist stay Founder-approved.

## PHASE 5 — App Review readiness (start early — real blockers live here)

21. **Age rating** [FOUNDER+FABLE]: Apple's new tier system (4+/9+/13+/16+/18+) with a required questionnaire — a matrimony/dating app should expect and declare **18+**, which matches ZYRA's own 18+ eligibility. Set manually higher if the questionnaire suggests lower.
22. **Privacy nutrition labels** [FABLE drafts, FOUNDER approves]: full data-collection disclosure (identity, photos, religious-belief answers = sensitive data, messages, purchases). Must match the privacy policy exactly.
23. **Privacy policy URL** [FOUNDER+CODEX]: zyraconnect.app/privacy is still the waitlist-era page. Before public release it needs the app-grade Article 9, Guardian-data, provider, retention and deletion disclosures under DR-ZYRA-220's in-house compliance route; the superseded solicitor gate is not current law.
24. **Guideline 1.2 operations:** blocking, in-app profile reporting and the moderation-review queue now exist from IDV Phase A. Before public submission, verify the live operational path, response ownership and disclosures end to end; implementation alone is not evidence that moderation is operational.
25. **Mandatory identity verification:** DR-ZYRA-221 requires verification during onboarding and prevents the app opening for an unverified account; every role inherits the gate, and Active Journey also requires the duplicate flag resolved. The Phase A state/gate exists, but the real provider path remains a public-release blocker until the authorised provider integration, compliance material and device evidence are complete.
26. **Territory decision** [FOUNDER]: recommend **UK-only at first release**. EU distribution triggers Digital Services Act trader requirements (published trader address/phone in the EU storefront) — decide deliberately later.

### ADDED PHASE 5 GATE (2026-08-29, Founder-ruled via AD-AIOS-106)

Unlock category percentages are hard-coded samples with no on-screen
marker (Founder instruction). BEFORE TestFlight or any external viewing:
real category data ships (OA-ZYRA-193(d)) OR the category percentages hide
entirely. This is a blocking check.

## PHASE 6 — submission [ALL]

27. Store listing: name, subtitle, description, keywords, screenshots (6.7" + 6.1" minimum sets), support URL (zyraconnect.app), marketing URL optional.
28. App Review notes: **demo account credentials** for the reviewer (a seeded Seeker + linked Guardian pair so the reviewer can see the real flows), and a short explanation of the Guardian model.
29. Submit → typical review measured in days; expect dating-category scrutiny (distinctiveness is a strength here — the Guardian/Journey model is exactly what 4.3 spam rules punish generic dating apps for lacking).
30. Release: choose **manual release** so launch timing stays yours.

## Standing rules

Payment, Apple ID, agreements and banking/tax remain Founder-only. Codex never
runs git and never applies a migration or uploads a build without the exact
Founder authority required by the current operating model. Every phase that
changes the app produces measured evidence; Codex keeps this runbook current,
and only the Founder accepts risk, applies gates or approves completion.

## Current immediate TestFlight gates — re-measured 2026-09-12

The 2026-08-28 statement that TestFlight needed only enrolment plus a build is
superseded by the later security and migration findings. The current bounded
Founder-internal sequence is:

1. OA-ZYRA-198 clean local replay: **PASSED**. Under message 085's exact
   one-use Founder authority, one fresh disposable, seedless, isolated local
   PostgreSQL 17.6 reset ran the unchanged 207 active migrations plus exact V2
   and probe-score bridges: 209 unique versions. It exited 0 and reached and
   completed both staged September migrations. Message 086 records the raw-log
   identity and teardown. This is local replay evidence only; production was
   not accessed or changed, and the replay authority is consumed. It
   authorises neither production apply nor Apple archive/upload.
2. **PASSED.** The Founder issued the separate exact production Apply GO; Codex
   applied the byte-pinned OA-ZYRA-283 boundary and Request New Journey hold
   atomically in order, then completed the post-apply verification without
   reopening the app. The one-use Apply GO is consumed.
3. **PASSED.** Apple portal truth is verified: paid-team App ID, capabilities
   and App Store Connect record exist.
4. **PASSED.** The exact internal-only IPA at SHA-256
   `1e17a1c3475db1bcb01e59415768d94480538bb601aedcdc8fdd706ea1a7b673`
   is uploaded once and `Ready to Test`; the forbidden build-1 evidence stays
   unchanged. The consumed upload workflow must not be retried.
5. **PASSED.** `Founder Internal` exists with automatic distribution OFF,
   only `admin@zyraconnect.app`, and only ZYRA `1.0.0 (2)`. No external or
   public distribution exists.
6. **PENDING FOUNDER.** Accept the invitation in TestFlight, install ZYRA and
   return the device result for OA-ZYRA-283 acceptance.

The report/moderation path, app-grade privacy disclosures, identity-
verification posture, paid agreements and public store metadata remain public-
release gates. They are not silently waived by an internal TestFlight build.

---

*V1 · 2026-08-28 · Facts verified against Apple's enrolment page and current App Store Connect age-rating guidance on 2026-08-28. Prices shown at Apple checkout govern.*
