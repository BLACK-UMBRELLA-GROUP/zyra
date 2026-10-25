# 015 — FABLE → CODEX — 2026-08-29 — BUNDLE ID UNIFICATION — GO

## Authority and lineage

Founder decision 2026-08-29, filed as **DR-ZYRA-218**; work
tracked as **OA-ZYRA-268**. Context: Apple Developer Programme
enrolment executed 2026-08-29 (OA-ZYRA-267, awaiting Apple
activation). The identifier must be unified BEFORE any App
Store Connect app record / App ID is created, because it
becomes permanent at that moment.

## The decision (verbatim intent)

Canonical ZYRA application identifier = **app.zyraconnect.zyra**
(reverse-DNS of the owned domain zyraconnect.app). Unify iOS
and Android on it now. You implement and verify all dependent
configuration.

## Current state you are replacing (observed 2026-08-29)

- iOS Runner (all configs): `com.shakeelahmed.zyraapp`
- iOS RunnerTests: `com.zyra.app.RunnerTests`
- Android `applicationId` and `namespace`: `com.zyra.app`

## Scope

1. iOS `PRODUCT_BUNDLE_IDENTIFIER` → `app.zyraconnect.zyra`
   for every Runner build configuration (Debug/Release/
   Profile); RunnerTests → `app.zyraconnect.zyra.RunnerTests`.
2. Confirm Info.plist derives from
   `$(PRODUCT_BUNDLE_IDENTIFIER)`; fix if hardcoded.
3. Android `applicationId` → `app.zyraconnect.zyra`.
   `namespace` / Kotlin package: bring to the same value or
   document a deliberate exception with reasoning in your
   handover (end state must build cleanly either way;
   MainActivity package path moved to match if you change
   namespace).
4. Repo-wide sweep for `com.zyra.app` and
   `com.shakeelahmed.zyraapp` — manifests, Kotlin/Swift
   sources, plist/entitlements, URL schemes, CI/scripts,
   docs in SOURCE. Replace or justify every remaining hit.
5. Dependent configuration verification (the Founder named
   this explicitly): OAuth / deep-link callback schemes
   (Supabase auth, Google Sign-In reversed-client-ID scheme
   if present) still function; any google-services /
   GoogleService-Info files — if none exist, state so in the
   handover; push/associated-domains entitlements (none
   expected yet — confirm).

## Verification you owe before handover

- Debug AND release builds compile for iOS and Android.
- App runs on simulator/device as a fresh install; login and
  one authenticated flow work (proves the OAuth callback
  survived).
- Note in the handover: existing dev installs will appear as
  a separate app (identifier change) — expected, dev-only,
  no production users.

## Hard boundaries

- NO App Store Connect app record, App ID, or certificate
  work — gated on OA-ZYRA-267 activation and Founder-run
  Phase 2.
- No signing changes beyond what the identifier itself
  requires.
- No git — the Founder runs git in his own Terminal.
- No migrations, no unrelated refactors.

## On completion

Handover message (016_CODEX-FABLE_...) with: files touched,
before/after identifier table, sweep results (remaining hits
+ justification), build/run evidence, OAuth check result.
Fable verifies against DR-ZYRA-218, then the identifier is
ready for Runbook Phase 2.
