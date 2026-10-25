# ZYRA — Fable Build Review & Continuation

**Document:** ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md
**From:** Fable (taking over the build per Claude's 2026-07-18 handoff, Founder instruction "review everything and continue the build")
**Date:** 2026-07-19
**Status:** Session complete. Compile pass (§6) still required on the Founder's machine — no sandbox here has a Flutter SDK either.

---

## 1. Handoff verification — what I checked against the live project

Unlike the previous session, this one has direct access to the live Supabase project, so the handoff's claims were verified against reality, not re-read from documents:

- **Migrations:** all 13 claimed migrations confirmed applied, in the stated order. The handoff said "3 tables added" but listed 2 — live state confirms 2 (`onboarding_answers`, `wali_invites`); 15 public tables total. Handoff typo, nothing missing.
- **Function grants:** exactly as claimed — both trigger functions locked down, both invite functions callable.
- **RLS policies:** all 31 policies read in full and traced against what each service/screen actually queries. Findings below.
- **Migrations folder:** only 1 of 13 migrations was checked in. **Fixed** — all 15 (13 + this session's 2) now exist as source files in `SOURCE/supabase/migrations/`, named by live version. `0001_initial_schema.sql` renamed to `20260718190011_initial_schema.sql`.

## 2. Mistakes found in the 2026-07-18 build (and what was done)

**2.1 — Photo bucket was public; the "narrowed read policy" protected nothing. FIXED.**
`profile-photos` was `public: true`. Public buckets serve objects by URL with no auth/RLS check — so the own-folder read policy restricted only API listing, and any photo was fetchable by anyone, signed out. This directly violates IMAGE_HANDLING_CURRENT_VERSION_V1.md ("Originals never publicly accessible"). Bucket is now private; read RLS mirrors the approved `profile_photos` table policy; all display URLs are 7-day signed URLs. Migration `20260719080749` + code changes in photo/discovery/match services. **DR-ZYRA-085 (PROPOSED).** Needs runtime verification: photo display everywhere on first compiled build.

**2.2 — wali_links UPDATE policy allowed silent link rewriting. FIXED.**
No WITH CHECK + full-column scope meant a signed-in Guardian could rewrite an existing link's `seeker_id` to any Seeker — an unconsented guardianship link, bypassing the invite mechanism. Client UPDATE now restricted to `status` only (wali_suggestions: `status`, `responded_at`). Migration `20260719080735`. **DR-ZYRA-086 (PROPOSED).**

**2.3 — Browse ignored gender. FIXED.**
`fetchCandidates()` never filtered by gender, violating the Browse script spec ("Never display same-gender profiles") — the schema even has an index built for that exact query. Also added `role = 'seeker'` (a Guardian with photos would have appeared as a candidate). Fixed in `zyra_discovery_service.dart`.

**2.4 — Compatibility scoring is dead on arrival under RLS. FLAGGED, not fixed (§5.1).**
`onboarding_answers` RLS is own-row-only, but `_applyCompatibility()` queries *candidates'* rows — which returns empty for real users. Every real candidate scores neutral 50.0: no Hard Requirement exclusion, no real ordering. The handoff's "real compatibility scoring is now wired in" is true of the code path and false of the effect. This needs a Founder decision (privacy trade-off), so it is documented in a code comment and left graceful, not silently fixed.

**2.5 — Invite tokens from a non-crypto source; anon probing surface. FIXED.**
`md5(random())` tokens replaced with `gen_random_bytes`. Anon EXECUTE revoked on both invite functions (`preview_wali_invite` returned the inviter's name for any valid token, signed out; no pre-auth invite flow exists to justify it). Security advisors now show zero anon findings. **DR-ZYRA-086.**

**2.6 — Nonce charset typo. FIXED.** Apple sign-in nonce charset was missing `W`. Harmless, corrected.

**2.7 — Everything else held up.** Auth flow correctly matches `google_sign_in` 6.x / `sign_in_with_apple` 6.x / `supabase_flutter` 2.x API surfaces (the caret constraints cannot pull the breaking 7.x majors). Supabase query syntax valid throughout. Match/chat/timeline RLS traces clean. Navigation audit redone: every screen reachable, no dead buttons found. Note: `pubspec.lock` predates the auth rework (no `google_sign_in` entry) — `flutter pub get` regenerates it; expected.

## 3. Developer Mode — built (Founder request, hybrid approach approved 2026-07-19)

`DeveloperAccessScreen` is now a test-scenario switcher. Six presets — Seeker Basic (male/female), Seeker One (male/female), Guardian, Guardian + Extended Guardian (mock) — each sign into a **real seeded Supabase account** and land on a fully-onboarded Home/WaliHome with AppState pre-populated. The old jump-menu remains below. **DR-ZYRA-087 (PROPOSED).**

Seeded accounts (password `[REDACTED — legacy test credential]`, seed script at `SOURCE/supabase/seed_dev_accounts.sql`, already applied):

| Email | Name | Role | Plan |
|---|---|---|---|
| dev.seeker.basic.m@zyra.test | Adam, 29, London | seeker | seeker_basic |
| dev.seeker.basic.f@zyra.test | Maryam, 27, Birmingham | seeker | seeker_basic |
| dev.seeker.one.m@zyra.test | Yusuf, 31, Manchester | seeker | seeker_premium |
| dev.seeker.one.f@zyra.test | Aisha, 30, Leeds | seeker | seeker_premium |
| dev.guardian@zyra.test | Ibrahim, Birmingham | guardian | wali_basic |

Ibrahim ↔ Maryam have a real active `wali_links` row, so the Guardian dashboard shows genuine backend data. Password auth exists only via `ZyraAuth.signInWithTestAccount` (dev screen only) — Google + Apple remain the only user-facing auth. Notes: test accounts have no photos, so they don't appear in each other's Browse (Browse falls back to mocks); delete all `dev.*@zyra.test` accounts before any real launch.

## 4. Database changes applied this session

| Migration | What |
|---|---|
| 20260719080735_security_hardening_wali_and_invites | §2.2 + §2.5 |
| 20260719080749_private_profile_photos_bucket | §2.1 |
| (seed, not a migration) seed_dev_accounts.sql | §3 |

Security advisors after: only the two *intentional* authenticated-callable invite functions, plus a generic "enable leaked-password protection" auth note (dashboard toggle, optional).

## 5. Open decisions — need Shakeel, not me

1. **Compatibility scoring vs RLS (§2.4).** Options: (a) broaden RLS so `ch3_answers` are readable for active+complete profiles — simplest, but exposes personal values answers to all signed-in users; (b) server-side scoring in a SECURITY DEFINER function — keeps answers private, ports the (still unratified DR-079) formula to SQL; (c) leave neutral until the matching engine design matures. My lean: (b), but the formula should be ratified or amended first so the port happens once.
2. **DOB exposure.** `profiles.date_of_birth` is readable by all signed-in users (the app computes age client-side). Exposing exact birthdate is more than Browse needs — a server-computed age would be tighter. Low urgency, worth a decision before launch.
3. **Plan naming drift.** Schema: `seeker_basic/seeker_premium/wali_basic/wali_premium`. Product: "ZYRA Basic"/"ZYRA One" + Extended Guardian. Reconcile in schema V2 or record the mapping as deliberate.
4. **Guardian read access to Journey/Timeline/messages** — unchanged from the handoff: still deliberately unbuilt, still needs your explicit sign-off on scope before anyone wires it.
5. **DR ratifications outstanding:** DR-ZYRA-079–084 (previous sessions) and now 085–087. Nine PROPOSED records.
6. **Invite expiry.** `wali_invites` never expire (a pending code is valid forever). Product call; one line of SQL when decided.

## 6. Founder checklist — compile pass (unchanged requirement, still not possible in any sandbox)

```
cd SOURCE
flutter pub get
dart run flutter_native_splash:create
flutter clean
flutter run -d macos
```

Then, in order: sign in via Developer Mode presets (tests password auth + RLS + real data paths, no OAuth needed) → check own photos upload/display (tests §2.1's signed URLs — the highest-risk change of this session) → browse as Adam (should show only female seekers with photos; today that's mocks) → Maryam ↔ Ibrahim Guardian dashboard. OAuth still needs Google Cloud credentials + Supabase provider config before "Continue with Google/Apple" work; iOS Sign In with Apple capability still needs adding in Xcode.

---

## 7. Unresolved native crash on physical device — needs Fable, real crash logs required (from Claude, 2026-07-19 evening session)

Shakeel has been live-testing on his own iPhone via `flutter run -d <device-id>` over several hours today. Two real bugs were found and fixed in-session (below), but a further intermittent crash is still occurring and I could not root-cause it — every occurrence happened at or after the point the Terminal-attached debug session disconnected, so there is no Dart stack trace or native crash log for any of them, only Shakeel's description of what he tapped. Flagging this now rather than guessing further.

**7.1 — Fixed this session: concurrent `signOut()` race.**
Root cause: `supabase.auth.signOut()` called twice concurrently (from a double/duplicate tap) races at the native layer with no Dart exception — Terminal shows `supabase.auth: INFO: Signing out user with scope: local` printed multiple times back-to-back, then `Lost connection to device`, app closes.

Two call sites hit this:
- `DeveloperAccessScreen._enterAs()` / `_signOutTestAccount()` — rapid taps between test-account presets. Fixed with a synchronous `bool _switching` guard, checked/set as the first statement before any `await` (a `setState`-based guard wasn't synchronous enough to block the second tap).
- `ProfileScreen._signOut()` / `WaliProfileScreen._signOut()` — real user-facing Sign Out buttons, no guard at all. Rather than patch both screens, fixed it once at the root: `ZyraAuth.signOut()` (`SOURCE/lib/services/zyra_auth.dart`) now has its own static `_signingOut` guard, so every current and future call site is protected regardless of what calls it.

Both confirmed compiling (manual brace/paren balance check only — no Flutter SDK available on my side to `flutter analyze`). Not yet re-tested on-device against the specific repro that found them, because a different crash (7.2) intervened.

**7.2 — NOT fixed, NOT root-caused: crash with zero preceding output.**
Later the same session, `Lost connection to device` appeared straight after the `flutter run` key-commands list with *nothing* printed in between — no `signOut` logs, no exception, nothing. Two separate occurrences, different circumstances:

- Once immediately after using iPhone Mirroring (macOS) and tapping a button in the mirrored view. My best guess in the moment was a tooling conflict — Mirroring and a live Xcode/Flutter debug connection are known to interfere with each other — but this is unconfirmed, not verified against a real log.
- Once with Mirroring not involved at all: app launched normally from `flutter run`, USB cable unplugged (Terminal immediately shows `Lost connection to device`, which is expected the instant a USB-tethered session loses the cable), then Shakeel tapped the temporary debug-only Home button (`DevNavOverlay._goHome()` in `SOURCE/lib/widgets/dev_nav_overlay.dart`, wired via `MaterialApp.builder` in `main.dart`) — and this time the **app itself visibly closed on the phone**, confirmed by Shakeel directly (not just Terminal disconnecting). Since then the app is in a bad state: tapping the icon shows a brief white screen and immediately closes, every time, until reinstalled via `flutter run` again.

I could not reproduce or inspect either of these — by the time each happened, the debug connection was already gone, so there's no stack trace to read, only what Shakeel could describe live over chat.

**What I'd ask Fable to do:**

1. Get a real native crash log before changing anything further — guessing without one is how the 7.1 fixes took as long as they did. `Xcode → Window → Devices and Simulators → select the iPhone → View Device Logs`, or Console.app connected to the device, should have a `.ips` crash report for ZYRA around each crash time. That will show whether this is Dart-side (should show *something* even without full symbolication) or a genuinely native/platform-level crash.
2. Treat `dev_nav_overlay.dart` as a suspect, not a given — it's a same-day addition (Founder testing aid, `kDebugMode`-gated, uses a `GlobalKey<NavigatorState>` to reach the Navigator from outside the widget tree via `MaterialApp.builder`) and it's the one thing in common between the "worked fine, then Home button tapped, then closed" report and the earlier (separately fixed) crash pattern. Worth ruling it out entirely — temporarily stub `_goHome()`/`_goBack()` to no-ops and see if the crash reproduces without it — before looking elsewhere.
3. The "app won't cold-launch afterward" symptom (white screen, instant close, repeatedly, until `flutter run` reinstalls it) is worth attention on its own — that's not just "one crash," it's the app failing to start cleanly afterward, which smells like something corrupted in local session/state persistence (Supabase's local auth cache is the obvious candidate given 7.1 was auth-related) rather than a one-off UI bug.
4. Was not able to confirm whether Shakeel's device is actually paired for wireless debugging (Xcode's "Connect via network" checkbox) or has been running tethered over USB the whole time under a wireless-sounding workflow — worth confirming directly, since it changes what "unplug" should even do to a live session.

---

## 7. RESOLVED — the "unplug crash" was never an app bug (Fable, 2026-07-19, second session)

Claude's evening session flagged an intermittent, un-loggable crash: app dies at/after debugger disconnect, then repeatedly shows a white screen and instantly closes on every cold launch until reinstalled via `flutter run`. Root cause identified without needing a crash log, because the symptom set is exact:

**`flutter run` installs a DEBUG build. Flutter debug builds on physical iPhones run Dart under JIT, and iOS kills JIT apps the moment no debugger is attached — and refuses to cold-launch them at all.** Every reported symptom follows:

- Unplug the USB cable → debugger gone → iOS kills the app the next time Dart code executes. That next execution was Shakeel's tap on the DevNavOverlay Home button — so the tap *looked* like the cause. The overlay is innocent; any tap anywhere would have done it.
- White screen + instant close on every subsequent icon launch → a debug binary can never start standalone on iOS. Nothing is corrupted (Supabase's local session cache was a red herring); the same binary simply refuses to run undebugged, forever, until a new install.
- Zero preceding log output → nothing Dart-side ever went wrong; iOS killed the process from outside.
- The iPhone Mirroring occurrence → same class: the mirroring session interfering with the fragile debug attach.

**The fix is workflow, not code.** For untethered phone testing: `flutter run --profile -d <device-id>` (or `--release`). Both are AOT-compiled: they launch from the icon like a real app and survive unplugging indefinitely. Debug mode remains fine for tethered work (hot reload), as long as the cable stays in.

Code changes made in support:
- `dev_nav_overlay.dart` gate changed `kDebugMode` → `!kReleaseMode`, so the Back/Home testing buttons still appear in profile builds (they remain impossible in release builds — real users never see them).
- "Back button doesn't work": Back was silently doing nothing when there was genuinely nothing to pop (most ZYRA flows use `pushReplacement`/`pushAndRemoveUntil` or internal step state, so the route stack is often empty — as Claude's earlier comment in that file correctly documented). Back now shows a two-second "Nothing to go back to — use Home to reset" notice in that case, so a no-op never looks like a malfunction again. When there *is* a route to pop, it pops exactly as before.
- Claude's 7.1 concurrency guards (`_switching` in DeveloperAccessScreen, `_signingOut` in ZyraAuth) reviewed — both correct, kept unchanged.

*End of Document*
