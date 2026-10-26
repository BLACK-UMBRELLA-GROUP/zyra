---
id: DOC-ZYRA-0287
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 4 - every outside service ZYRA depends on - what it is for, which part of the code uses it, whether it is live, test-only or not connected, where its settings live (never the values), and what the planned app needs from it
links: [OA-ZYRA-309, OA-ZYRA-317, DOC-ZYRA-0280, DR-ZYRA-274, DR-ZYRA-275]
owner: Fable
---

# ZYRA BLUEPRINT — PART 4 — OUTSIDE CONNECTIONS — V1 (CURRENT)

Status: **CURRENT - approved by the Founder, 26 Oct 2026** (all 14 blueprint pages, review pack DOC-ZYRA-0299). Building anything that breaks this page needs a new decision first. Written 26 Oct 2026 from `SOURCE/pubspec.yaml`, `SOURCE/lib` (services and `config/`),
`SOURCE/ios/Runner` (permissions and entitlements) and the website repo `SITE`. **No key, password or token was opened**:
files that hold them are named only. Whether each service is live in production is from the code and the records; the live
check (OA-ZYRA-312) confirms it.

## In one paragraph

ZYRA leans on **one** outside system for nearly everything: **Supabase** (database, sign-in, photo storage, in-app
notifications, usage counts). Members sign in with **Google** or **Apple**. Three things the planned app needs are **not
connected yet**: **payments** (no App Store purchase code at all — memberships and Compatibility Unlocks are prices on a page),
**the identity check** (Sumsub is chosen, the app has a switched-off slot for it), and **phone push notifications** (only
in-app ones exist). The website runs on **Cloudflare**, email on **Google Workspace**.

## 1. Services the app uses

| Service | What ZYRA uses it for | Where in the code | State | Settings live in (never the values) |
|---|---|---|---|---|
| **Supabase** (one project, `sxoaxonzjqkgajmlagyk`) | Database (63 tables, 205 functions), sign-in sessions, the private `profile-photos` bucket, in-app notifications, privacy-safe usage counts (`zyra_record_product_event`) | `supabase_flutter`; every `services/zyra_*_service.dart` | **Live** — the only backend; no server (edge) functions | `lib/config/supabase_config.dart` — kept out of git (`.gitignore`); `.example` copy in git |
| **Google sign-in** | Sign in with a Google account (ID token passed to Supabase) | `google_sign_in`; `services/zyra_auth.dart` | **Live** | `lib/config/oauth_config.dart` — out of git |
| **Sign in with Apple** | Sign in with an Apple ID | `sign_in_with_apple`; `zyra_auth.dart`; iOS entitlement `applesignin` | **Live** | Apple Developer account; entitlement in `Runner.entitlements` |
| **Email codes** | Confirm a change of email address (one-time code) | `zyra_auth.dart` (`OtpType.emailChange`) | **Live** through Supabase's mailer | Supabase dashboard (sender not recorded in the repo — live check) |
| **Apple App Store / TestFlight** | Delivering the app: internal TestFlight for the Founder, a private tester cohort | `config/zyra_internal_founder_policy.dart`, `zyra_external_tester_policy.dart`, `zyra_native_identity_policy.dart` | **Test only** — not on the public App Store | App Store Connect; runbook DOC in `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V3.md` |
| **Google Fonts** | Developer-only font comparisons (Poppins and Syne ship inside the app) | `google_fonts` | **Developer only** | — |
| **Phone features** (not outside services, listed for completeness) | Camera to scan a ZYRA Code; photo library to add photos; Face ID / passcode app lock; secure storage; share sheet | `mobile_scanner`, `image_picker`, `local_auth`, `flutter_secure_storage`, `share_plus` | **Live** | iOS `Info.plist` wording (camera, Face ID, photos) |

## 2. Services the planned app needs but are not connected

| Need | Planned app | Today | Gap |
|---|---|---|---|
| **Payments** (App Store in-app purchase) | Basic £4.99 joining fee (DR-ZYRA-275), ZYRA One monthly, family places, Compatibility Unlocks £2.99 / £6.99 / £9.99 | **No purchase code at all** — no StoreKit or `in_app_purchase` package. Plans are set by developer-only functions (`zyra_dev_set_seeker_plan`, `mock_set_wali_plan`); the release gate stays off until StoreKit receipts are verified | **OA-ZYRA-317 (7)** |
| **Identity check** (Sumsub) | Verified + duplicate-clear before any Journey | A switched-off slot: `zyra_identity_verification_service.dart` has no provider, and its production switch is off on purpose ("turning it on first would lock every existing account"). Phase A storage is live since 29 Aug | **OA-ZYRA-317 (8)** |
| **Phone push notifications** | Request, Journey and Guardian updates reaching a locked phone | **None** — only in-app notifications stored in Supabase; no push service (no APNs, Firebase or OneSignal) | **OA-ZYRA-317 (9)** — **decided: add it** (DR-ZYRA-278) |

## 3. Business services around the app

| Service | Used for | State |
|---|---|---|
| **Cloudflare** | Website `zyraconnect.app` (Cloudflare Pages, site in `ZYRA/SITE`); AIOS at `admin.zyraconnect.app` behind Cloudflare Access | Website live; the local SITE repo has 2 commits not yet published (OA-AIOS-407). The waitlist API answers "not available" (501) on purpose |
| **Google Workspace** | Company email `admin@zyraconnect.app`; AIOS sign-in | Live |
| **GitHub** (`BLACK-UMBRELLA-GROUP` organisation) | Code storage for `zyra` and `zyra-site` | Live; Codex, Claude and Cloudflare apps installed |
| **Store links** | `apps.apple.com` and `play.google.com` links in the app | Links only; Android is not released |

## 4. Found while mapping

| # | Finding | Goes to |
|---|---|---|
| 1 | Sample photos are loaded from an outside website (`picsum.photos`) in 3 non-developer files: the shared sample list in `models/seeker_profile.dart`, and `screens/connections/connections_screen.dart` and `services/zyra_wali_journey_service.dart` in the old app. A phone could fetch random internet images | Clean-up, OA-ZYRA-316 (Tier 1/3) |
| 2 | No crash reporting service; failures are only recorded on the device (`zyra_release_diagnostics`, `zyra_reliability_monitor`) | **Decided: add privacy-safe crash reporting before launch** (DR-ZYRA-278, OA-ZYRA-317 (10)) |
| 3 | One Supabase project serves everything; there is no separate test database | Noted for the server design — test data must never touch members |

## 5. Keys and secrets — where they are, never what they are

| Secret | Kept in | In git? |
|---|---|---|
| Supabase app key | `SOURCE/lib/config/supabase_config.dart` | No (`.gitignore` line 36) |
| Google and Apple sign-in settings | `SOURCE/lib/config/oauth_config.dart` | No (`.gitignore` line 40) |
| Supabase service key, App Store Connect, Cloudflare, Google, GitHub and AI provider keys | The protected keys folder (never opened by any AI) | No |
| `.env` files | Anywhere | No (`*.env` ignored) |

Key rotation is OA-AIOS-395 (Founder creates each new key himself).

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-26 | V1 | First draft from the code, settings and website repo (OA-ZYRA-309) |
| 2026-10-26 | V1 | Push notifications and crash reporting decided (DR-ZYRA-278) |
| 2026-10-26 | V1 | Approved by the Founder ("a" - all 14 pages); status CURRENT |
