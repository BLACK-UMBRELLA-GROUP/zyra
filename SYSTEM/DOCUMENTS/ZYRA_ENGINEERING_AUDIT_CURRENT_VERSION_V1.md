---
id: DOC-ZYRA-0076
type: REPORT
status: CURRENT
feature: ARCHITECTURE AND DATA
purpose: ZYRA — Comprehensive Engineering, Architecture, Security & Product Quality Audit
links: []
owner: ZYRA chat
---

# ZYRA — Comprehensive Engineering, Architecture, Security & Product Quality Audit

**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-07-26
**Auditor:** Claude (independent audit pass)
**Requested by:** Founder (Shakeel)
**Nature of this document:** Independent engineering audit. **Nothing in this document has been implemented** *as of its 2026-07-26 date — ⚠️ STALE AS A STATUS PAGE: C-1/C-3/C-4/H-1/H-2/H-3/H-5 and others closed 2026-08-01→08, verified; the live findings ledger is `SUB BUSINESS/ZYRA/CLAUDE.md` §5 (banner added 2026-08-12).* No code, migration, or document was changed in producing it. Every finding is grounded in a direct read of `SOURCE/lib` (74 Dart files, 14,708 lines), `SOURCE/supabase/migrations` (35 migrations), the `APP/` and `SYSTEM/` documentation sets, and **live inspection of the production Supabase project** `sxoaxonzjqkgajmlagyk` (eu-west-1, Postgres 17.6).
**Governing References:** Does not supersede any existing spec. Findings that should become enforced rules are separated into §8 for ratification as Decision Records, not assumed to be in force.

---

## How to read this document

You asked for an honest assessment, not a task list. Three things to know before reading:

1. **Findings are evidence-backed, not generic advice.** Where I claim something, I cite the file and line, the migration, or the SQL I ran against the live database. Where I could not verify something, I say so explicitly rather than assuming the worst.
2. **Things that are already right are stated as such.** §2 is not a courtesy section — several areas of this codebase are genuinely well-built, and knowing which ones is as useful as knowing the gaps.
3. **A prior review already covers performance.** `ZYRA_PERFORMANCE_ENGINEERING_REVIEW_CURRENT_VERSION_V1.md` (2026-07-26) is a good document and its findings independently corroborate mine. I have not re-litigated it — §5.3 records where I confirm it, and where I found something it missed. Its §9 proposed standards are **still unratified**, and that matters (see §11).

---

## 1. Executive Summary

ZYRA is a **well-documented, thoughtfully-reasoned preview build with a genuinely strong security foundation that has three critical holes in it, and one silent functional failure that the mock-data fallback is currently hiding.**

The engineering quality is higher than typical for a project at this stage. RLS is enabled on all 24 public tables with no exceptions. Server-side trust boundaries are real — matches, subscriptions and journey transitions are all written by `SECURITY DEFINER` functions rather than client inserts. The code is unusually well-commented, and the comments explain *reasoning*, not just mechanics, which is rare and valuable.

That foundation makes the gaps more surprising, not less. The four findings that matter most:

| # | Finding | Why it matters |
|---|---|---|
| **C1** | **Developer Access — including hardcoded credentials for 6 real accounts — ships in release builds.** No `kReleaseMode` guard on any of its three entry points. | Anyone who installs the app can sign in as another account, switch plans, and bypass every paywall. |
| **C2** | **The 2026-07-26 "hide raw DOB" fix does not work.** Verified live: `has_column_privilege('authenticated','profiles','date_of_birth','SELECT')` returns **true**. | Every user's exact date of birth is still readable by any signed-in user. The team believes this is fixed. It is not. |
| **C3** | **`profile_complete` is never set to `true` by any code path.** Verified: no write in `lib/`, no write in any migration. The 24 visible profiles were set by seed SQL. | Every genuinely new user is invisible in Browse forever. Discovery is structurally broken for real sign-ups — and the `return mockProfiles` fallback hides it completely. |
| **C4** | **Any authenticated user can grant themselves a paid subscription** via `mock_purchase_wali_premium()`, and can edit their own `profiles.role`, `date_of_birth`, `is_active` and `profile_complete` directly. | Free premium, self-promotion to `role='admin'`, and unverified age in a marriage platform. |

C3 deserves particular emphasis because of *how* it stayed hidden. `ZyraDiscoveryService.fetchCandidates()` returns `mockProfiles` on five separate paths — including "the query returned nothing" and "the query threw". That fallback was a reasonable v1 decision when there was no backend. It is now actively concealing a total failure of the core product loop, and it will show **real users fake profiles in production**. This is the single most important thing in this document.

**Production readiness: not ready.** Not because the architecture is wrong — it mostly isn't — but because the gap between "documented intent" and "enforced reality" is currently wide enough that a determined user with a proxy tool could do meaningful damage, and an honest user might never see a real profile. Full assessment in §10.

**The good news:** every critical finding is narrow and fixable. None require re-architecture. C1 is three `if (kReleaseMode)` guards. C2 is one migration. C3 is one line. The structural work (Realtime migration, image pipeline, state management) is real but is High/Medium priority, not blocking.

---

## 2. Strengths — What Is Already Right

These are stated plainly because they should **not** be changed, and because a future contributor could easily undo them by accident.

### 2.1 Security foundation

- **RLS is enabled on all 24 tables in `public`, with zero exceptions.** Verified live via `pg_class.relrowsecurity`. Every table also has at least one policy. This is the single most important thing to get right in a Supabase app and it is right.
- **Write paths are correctly server-side.** `matches`, `subscriptions`, `conversations`, `timelines`, `timeline_milestones`, `journey_family_reviews` and `profile_unlocks` have **no client INSERT/UPDATE policy at all** — they are written only by `SECURITY DEFINER` functions and triggers. This is textbook least-privilege and was clearly a deliberate design choice, documented in the initial schema migration's comments.
- **The `SECURITY DEFINER` functions do check their caller.** I read the live definitions of `end_journey`, `suspend_journey`, `resume_journey` and `promote_journey_to_active`: all four verify `auth.uid()` is non-null and is a party to the match before acting. The Supabase advisor flags these as anon-callable, but they are **not exploitable** — the advisor is flagging missing defence-in-depth, not a live hole. I want to be precise about that rather than inflating the finding.
- **The private-bucket fix worked.** `storage.buckets.public = false` verified live. Storage RLS correctly scopes writes to `{auth.uid()}/…` and reads to own-or-active-profile. The 2026-07-19 fix here is real and effective — unlike the DOB fix (C2), which is a useful contrast.
- **`onboarding_answers` RLS is genuinely own-row-only**, and `score_candidates()` correctly solves cross-user scoring via `SECURITY DEFINER` rather than by loosening the policy. That was the right call architecturally.
- **`auth_rls_initplan` was proactively fixed** across the original schema (`20260718192519`). Wrapping `auth.uid()` as `(select auth.uid())` is a real optimisation most teams never apply. Newer tables regressed on this (§7.3), but the original pass was correct and deliberate.
- **`wali_invites` tokens now use `gen_random_bytes`** (verified live default), with a 7-day `expires_at`. The 2026-07-19 hardening migration worked.
- **`ZyraAuth.signOut()` has a re-entrancy guard** (`_signingOut`), fixed at the service rather than per-screen so every present and future call site is protected. That is the correct place to fix it.

### 2.2 Architecture and code

- **Startup is lean.** `main()` does exactly one blocking thing before `runApp()`. Everything else is post-first-frame. Protect this.
- **Screen-scoped progressive loading is the consistent norm** — no global bootstrap gate.
- **`AppState` listener hygiene is correct.** All 6 screens that call `addListener` also call `removeListener` in `dispose()`. I checked each one. No leaks here.
- **Chat Realtime is properly implemented** — `supabase.channel()` with a server-side `conversation_id` filter, self-message deduplication, and unsubscribe on dispose. This is the right pattern and it is already working. It makes the Journey screens' 3-second polling harder to justify, not easier (§5.2).
- **Error/cancel distinction is modelled properly.** `ZyraPhotoResult` and `ZyraAuthResult` distinguish `cancelled` from `error` so a cancelled photo picker never shows an error banner. This directly implements `ERROR_AND_EMPTY_STATE_STANDARD` and shows the standard is actually being read.
- **The code comments are a genuine asset.** They record *why*, cite the governing spec, and flag their own judgment calls (e.g. the `likes_select` policy comment explicitly flags its interpretation for confirmation rather than silently choosing). Very few codebases do this. It made this audit substantially faster and it will do the same for the next contributor.
- **Safeguarding was prioritised over monetisation where it counts.** `hasActiveMainWali()` gates Journey progression on a real `wali_links` row, not on a subscription. The Family Stage requires the Guardian to actually answer questions. This was right before it was written down as a rule.

### 2.3 Documentation

- The `CURRENT_VERSION` + dated-archive convention is **consistently applied** across `APP/Standards`, `APP/Browse`, `APP/Safety`, `SYSTEM/DOCUMENTS`. Version history tables are maintained. Superseded documents are archived rather than deleted.
- Decision Records are cited **inline in the code** (`DR-ZYRA-079`, `DR-ZYRA-099`, `DR-ZYRA-101`…). The link between decision and implementation is traceable in both directions. This is the strongest part of the governance system.
- `IMAGE_HANDLING_CURRENT_VERSION_V2.md` is a genuinely excellent standard — better than most production image pipelines. Its problem is that none of it is built (§9.1), not that it is wrong.

---

## 3. Weaknesses

Organised by the review areas you specified. Severity keys to §6.

### 3.1 Architecture

| Finding | Severity |
|---|---|
| **No state-management architecture.** `pubspec.yaml` has no provider/riverpod/bloc. A single global `ChangeNotifier` singleton (`AppState`) serves all shared state. `ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md` still says "State Management: **TBD** — pending architectural decision" — dated 2026-06-26, a month ago. The decision was never made; the app just grew around its absence. | 🟠 High |
| **`AppState` mixes three unrelated concerns**: real backend-derived state (`potentialJourneys`), local session state (Browse decisions), and mock/dev state (`plan`, `waliHasWaliOne`). `notifyListeners()` fires all 6 listening screens for any field change. | 🟠 High |
| **Two parallel truth systems throughout.** Nearly every service has a real path and a mock path, chosen at runtime by silent fallback. `AppState.plan` (in-memory mock) and `subscriptions.plan_type` (real) both claim to be the entitlement source. `browse_screen.dart` starts from `mockProfiles`. This was correct when there was no backend; it is now the dominant source of architectural risk. | 🔴 Critical |
| **Business rules live in the client.** Gender segregation, the 50-profile daily limit, ad frequency, and plan gating are all enforced only in Dart. See §3.6. | 🔴 Critical |
| **Stale comments now contradict the schema.** `zyra_match_service.dart:11-13` states "the schema has no column for it (`matches.status` only tracks active/paused/ended)". The 2026-07-25 migration added `'potential'` and `journey_stage`. `fetchRealMatches()` still filters `.eq('status','active')`, so the service named for "Potential Journeys" silently excludes them. | 🟠 High |
| `ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md` §5 documents a source tree of `lib/main.dart` only, and a repo root (`BLACK UMBRELLA GROUP/PROJECTS/ZYRA/`) that no longer exists. | 🟡 Medium |

### 3.2 Flutter implementation

| Finding | Evidence | Severity |
|---|---|---|
| **`TextEditingController` constructed inside `build()`** | `chapter2_flow.dart:483` — a new controller every rebuild. Leaks, and loses cursor position. | 🟠 High |
| **`TextEditingController` never disposed** | `searchable_list_picker.dart:43` (`_PickerSheetState._search`) — no `dispose()` override at all. Leaks once per picker open. | 🟠 High |
| **Unguarded `setState` after async delay** | `browse_screen.dart:336, 353, 366` — one-shot `Timer`s call `_advance()` (line 221) which calls `setState` with no `mounted` check; line 366 calls `Navigator.of(context)` likewise. Navigate away inside the 280 ms window and this throws. These timers are never stored or cancelled. | 🔴 Critical |
| **Per-frame `setState` during drag** | `browse_screen.dart:404` rebuilds the entire Browse subtree — full-bleed image, two gradients, glass buttons — on every pan frame. `floating_nav_bar.dart:78` does the same while scrubbing, and that widget contains a `BackdropFilter`. | 🟠 High |
| **1-second `Timer.periodic` calling `setState(() {})`** | `journey_flow_screen.dart:344` — for a 24-hour countdown. ~86,400 full rebuilds. | 🟡 Medium |
| **Zero `RepaintBoundary` in the codebase** | 0 occurrences across 14,708 lines, alongside 11 `BackdropFilter`/`ImageFilter.blur` uses. | 🟡 Medium |
| **`journey_flow_screen.dart` is 1,184 lines** containing 9+ widget classes and 6 timers | Single file, single responsibility violated. Prime decomposition candidate. | 🟡 Medium |
| **Duplicated `_fetchAges()`** | Byte-identical in `zyra_discovery_service.dart:141`, `zyra_match_service.dart:101`, `zyra_journey_service.dart:138`. | 🟢 Low |
| **Duplicated photo-mapping loop** | The same `photosRaw.sort(...) → signedUrlsFor(...) → SeekerProfile(...)` block appears 5 times across 4 services. | 🟢 Low |
| **`analysis_options.yaml` is the stock template** | `flutter_lints` only, no project rules enabled. | 🟡 Medium |

### 3.3 Performance

Corroborates and extends the existing performance review.

- **N+1 signed-URL calls** — `zyra_discovery_service.dart:80` awaits `signedUrlsFor()` once *per candidate*, sequentially, inside the loop. Same pattern at `zyra_match_service.dart:79` and `zyra_journey_service.dart:106`. Already correctly identified in the prior review; I confirm it in three services, not one.
- **No pagination anywhere on the main queries.** `fetchCandidates()` has no `.limit()`. Neither does `fetchJourneyMatches()`, `fetchRealMatches()`, or `fetchMessages()` — the last loads an entire conversation history on every open. Only `fetchRecent()` (notifications, `limit: 50`) paginates. **This is the dominant scalability risk** (§9).
- **Signed URLs defeat the image cache twice over.** They are regenerated on every fetch, so the URL string — and therefore Flutter's `ImageCache` key — changes each time. Adding `cached_network_image` alone will **not** fix this; the signed URL must be cached alongside its expiry, or the cache key must be the storage path. The prior review found the missing cache; this consequence is the part that makes the obvious fix insufficient.
- **`score_candidates()` is O(N) sub-selects inside a PL/pgSQL loop**, called with the full unbounded candidate array. At 10k+ candidates this is the query that will take the database down first.
- **14 eager `ListView(` vs 5 `ListView.builder`** — eager lists build every child regardless of viewport.

### 3.4 Battery

- **Seven concurrent polling loops**, confirmed by grep: `journey_flow_screen.dart` ×5 (3 s ×3, 5 s, 1 s), `wali_journey_detail_screen.dart` (5 s), `notification_bell.dart` (20 s).
- The parent `_JourneyFlowScreenState._refresh()` (line 91) issues **three service calls**, one of which (`refetchOne`) itself makes four round trips. That is ~6 network requests every 3 seconds from the parent alone, before any child poll. A user sitting on a Journey screen generates on the order of **200 requests/minute**.
- **No app-lifecycle handling exists anywhere.** Zero occurrences of `WidgetsBindingObserver`, `didChangeAppLifecycleState`, or `AppLifecycleState`. **Every timer keeps running when the app is backgrounded** — including the 20-second notification poll, which is mounted on both Home shells and therefore effectively always alive. This is the largest single battery and cost item in the app.
- `BackdropFilter` in the persistent `floating_nav_bar` composites a blur on every frame of every screen. Combined with per-frame `setState` while scrubbing, this is a GPU cost on low-end Android.

### 3.5 Memory

- Two confirmed leaks (§3.2): the undisposed picker controller and the in-`build()` controller.
- **No disk image cache and no `ImageCache` tuning.** Full-bleed Browse photos at 700×1000+ decode to several MB each in memory; the default `ImageCache` holds 1000 images / 100 MB.
- **Orphaned Storage objects by design.** `zyra_photo_service.dart:16-20` acknowledges that removing a photo in the Chapter 2 picker deletes neither the Storage object nor the table row. Unbounded growth.
- **No upload limits, verified live:** `storage.buckets.file_size_limit = NULL` and `allowed_mime_types = NULL`. The REST endpoint accepts a file of any size and any type. `image_picker`'s `imageQuality: 85` is client-side only and trivially bypassed.

### 3.6 Network

- Unbounded queries and N+1 signed URLs as above.
- **Polling used where Realtime is already proven to work in this same codebase** (Chat). Architecturally inconsistent.
- **No offline handling.** No connectivity package; 64 `catch (_)` blocks silently convert every network failure into an empty list or a mock. A user on a flaky connection sees "You're all caught up" rather than "Couldn't load — retry".
- **No retry, no backoff, no request deduplication.**
- **Zero logging or telemetry.** 0 occurrences of `print`/`debugPrint`; no crash reporter, no analytics. Against **64 silent catch blocks**, this means production failures are completely invisible. You will not be able to tell C3 is happening from the outside.

### 3.7 Database

| Finding | Severity |
|---|---|
| **Missing index: `profile_photos(user_id)`.** Verified live — only `profile_photos_pkey` and a *partial* unique index `WHERE is_primary = true`, which cannot serve `WHERE user_id = X` for non-primary rows. Every embedded photo fetch in Browse/Matches/Journey seq-scans. | 🟠 High |
| **Missing index: `matches(seeker_b_id)`.** The composite unique `(seeker_a_id, seeker_b_id)` serves `seeker_a_id` as leading column; nothing serves `seeker_b_id`. Every `.or('seeker_a_id.eq.X,seeker_b_id.eq.X')` — which runs every 3 seconds per open Journey — seq-scans `matches`. | 🟠 High |
| **The one-Active-Journey rule is not actually enforced.** `promote_journey_to_active` calls the partial unique indexes its "hard backstop against races". They are not: `matches_seeker_a_active` and `matches_seeker_b_active` are **separate** indexes, so a user may be `seeker_a` on one active match *and* `seeker_b` on another without violating either. The explicit `IF EXISTS` check is a TOCTOU race — `SELECT * INTO m` takes no row lock. This contradicts JOURNEY AVAILABILITY's stated CORE PRINCIPLE. | 🔴 Critical |
| **15 unindexed foreign keys** flagged by the live performance advisor, including `messages.sender_id`, `timeline_milestones.timeline_id`, `matches.suspended_by`. | 🟡 Medium |
| **`auth_rls_initplan` regression on all newer tables.** The original schema was fixed; every table added after (`journey_*`, `notifications`) reintroduced unwrapped `auth.uid()`. 21 policies flagged live. A fixed problem that came back because it was never written down as a rule. | 🟡 Medium |
| **`messages_select` does not filter `deleted_at`.** Soft-deleted messages are still returned. | 🟡 Medium |
| **No `messages` UPDATE policy** — `read_at` can never be set by a client, so read receipts cannot work as designed. | 🟢 Low |
| **No minimum-age CHECK constraint** on `profiles.date_of_birth`. | 🔴 Critical (see §3.8) |

### 3.8 Security

**🔴 C1 — Developer Access ships in release builds.**
`DeveloperAccessScreen` is pushed from `welcome_screen.dart:124`, `home_shell.dart:91`, and `wali_home_shell.dart:82`. **None of the three is guarded by `kReleaseMode` or `kDebugMode`.** `welcome_screen.dart` imports `foundation.dart` but only for `defaultTargetPlatform`. The screen contains `_testPassword = '[REDACTED — legacy test credential]'` (line 120) and the emails of 6 real accounts, calls `ZyraAuth.signInWithTestAccount` (email/password auth that is deliberately still enabled server-side), flips `AppState.plan` to `ZyraPlan.one`, and calls the mock purchase RPCs. `DevNavOverlay` **is** correctly guarded (`dev_nav_overlay.dart:78`) — which shows the pattern was known and simply not applied here.

**🔴 C2 — The date-of-birth REVOKE does not work.**
`20260726120000_hide_raw_dob_expose_age.sql` runs `REVOKE SELECT (date_of_birth) ON public.profiles FROM authenticated, anon;`. In PostgreSQL a **column-level REVOKE cannot subtract from a table-level GRANT** — and `authenticated` holds table-level `SELECT` on `profiles`. Verified live:

```sql
SELECT has_column_privilege('authenticated','public.profiles','date_of_birth','SELECT');
-- → true
```

All the client-side work (`ages_for()`, removing `date_of_birth` from every `.select()`) is real and correct. The underlying exposure is not closed. The correct form is `REVOKE SELECT ON public.profiles FROM authenticated;` followed by `GRANT SELECT (id, role, first_name, gender, location_text, bio, is_active, profile_complete, created_at, updated_at) ON public.profiles TO authenticated;`.

**🔴 C4 — Column-level write privileges permit privilege escalation and age falsification.**
`profiles_update` is `USING (id = auth.uid())` with no column restriction, and verified live, `authenticated` holds `UPDATE` on `role`, `date_of_birth`, `is_active` and `profile_complete`. A single `PATCH /rest/v1/profiles?id=eq.<self>` therefore allows:

- `{"role":"admin"}` — the CHECK constraint explicitly permits `'admin'`. Nothing grants admin power *today*, so impact is latent, but the escalation path is live and pre-built.
- `{"date_of_birth":"..."}` — **arbitrary age, with no minimum-age constraint anywhere.** In a marriage platform this is a child-safeguarding issue, not merely a data-integrity one.
- `{"profile_complete":true}` — appear in Browse without completing onboarding or photo review.

**🔴 C4b — Free paid subscriptions.**
`mock_purchase_wali_premium()` and `mock_set_wali_plan('wali_premium')` are live in production, `SECURITY DEFINER`, and `GRANT EXECUTE … TO authenticated`. Both write a real `subscriptions` row with `plan_type='wali_premium'`, `status='active'`, **with no payment**. Both gate on `profiles.role = 'guardian'` — which the caller can set on themselves per C4. Chained: any user grants themselves a paid plan in two HTTP requests.

**🟠 H1 — Gender segregation is not enforced server-side.**
`profiles_select` is `USING (id = auth.uid() OR (is_active AND profile_complete))`. Any authenticated user may read **every** active, complete profile regardless of gender or role. The "Never display same-gender profiles" rule (`APP/Browse/Script/Script_V1.md`) exists only as `.eq('gender', targetGender)` in Dart. `profile_photos_storage_read` has the same shape, so photos are equally reachable. For a platform whose core premise is propriety in line with the community's religious values, this rule belongs in RLS.

**🟠 H2 — Incoming Potentials paywall is bypassable.**
`likes_select` is `USING (liker_id = auth.uid() OR liked_id = auth.uid())`. Seeing who liked you is a ZYRA One feature; RLS grants it to everyone and only the client hides it. The migration comment flags this interpretation and asks for confirmation — that request was never actioned.

**🟠 H3 — `ages_for()` and `score_candidates()` accept arbitrary UUIDs.**
Both are `SECURITY DEFINER` with no check that the caller may see the requested ids. `ages_for(ARRAY[…])` returns ages for *any* profile — inactive, incomplete, same-gender, Guardian — bypassing the row visibility that `profiles_select` is supposed to provide. `score_candidates()` is worse: it is an **inference oracle**. An attacker can set their own `ch4_preferences` so a single option is green, call the RPC against a target, and read the score to determine that target's private Chapter 3 answer. Iterated, this reconstructs another user's private religious and personal values — the most sensitive data in the product.

**🟡 M1 — Invite token entropy.** `gen_random_bytes(4)` = 32 bits ≈ 4.3 × 10⁹. Cryptographically random (good), but short for a token that `preview_wali_invite` exposes to **anon**. With ~1,000 live pending invites an attacker needs ~4.3M requests for one hit — impractical today, and mitigated by the 7-day expiry, but this should be 128-bit. A successful hit attaches an attacker as Guardian to a stranger's account, so the consequence is severe even if the probability is low.

**🟡 M2 — Credentials in version control.** `supabase/seed_dev_accounts.sql` (password `[REDACTED — legacy test credential]`) and `supabase/upload_fake_photos.sh` (anon key + `[REDACTED — legacy test credential]`) are **tracked in git**. `lib/config/supabase_config.dart` and `oauth_config.dart` are correctly gitignored and only `.example` files are tracked — that part is right.

**🟡 M3 — Anon-callable RPC error oracle.** `end_journey`/`suspend_journey`/`resume_journey`/`promote_journey_to_active` return distinguishable errors (`'match not found'` vs `'not a party to this match'`) to unauthenticated callers, allowing match-ID existence enumeration. `auto_designate_main_wali()` is a *trigger* function exposed as an RPC — harmless (it errors if called directly) but should be revoked.

**🟡 M4 — Leaked-password protection disabled** in Supabase Auth (live advisor). Relevant while the email provider stays enabled for test accounts.

### 3.9 User experience

- **Empty and error states are conflated.** With 64 silent catches, "no results", "RLS denied", and "network down" all render the same empty state. `ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1.md` defines distinct categories; the service layer discards the information needed to honour them.
- **A Guardian can land in the Seeker app.** `zyra_session_router.dart:31` — `catch (_) { return const HomeShell(); }`. A network hiccup during role lookup drops a Guardian into the Seeker experience.
- **Accessibility is absent from user-facing code entirely.** There is exactly **one** semantic annotation in 14,708 lines — `dev_nav_overlay.dart:122`, a debug-only widget that never ships. So the user-facing accessibility count is **zero**, against **299 hardcoded font sizes**. No text-scaling support, no screen-reader labels on any icon-only control (`GlassIconButton`, the swipe deck, `FloatingNavBar`, the notification bell). This will fail an accessibility review and is a legal exposure in several markets.
- **Undiscoverable core gesture.** Browse's swipe directions (physical swipe left / finger travels right-to-left = Consider, physical swipe right / finger travels left-to-right = Pass, down = Save) are non-standard — most dating apps use right = positive. There is no first-run coach mark. Live drag feedback is good, but only *after* the user guesses.
- **The 50-profile daily limit resets on app restart** — `_viewed` is in-memory only.
- **No pull-to-refresh** on Browse, Connections, or Notifications.

### 3.10 Repository quality

- **Version control is effectively absent.** `git rev-list --count HEAD` = **2 commits**, the second dated 2026-07-26. **126 uncommitted modified files** at the start of this audit. **No remote configured** — `git remote -v` returns nothing. There is no off-machine backup of ZYRA. A single disk failure loses the entire project, code and documentation both. Every other finding in this document is recoverable; this one is not.
- **The test suite is broken.** `test/widget_test.dart` is the untouched Flutter counter template referencing `MyApp`, which does not exist (it is `ZyraApp`), and asserting on a counter that was deleted. `flutter test` does not compile. Effective coverage: **0%**.
- **`.limit()` appears only for single-row lookups.** Verified across the service layer: every `.limit()` in `lib/services` is either `.limit(1)` or the notification feed's `.limit(50)`. No list query that grows with the user base is bounded.
- **No CI, no pre-commit hooks, no `flutter analyze` gate.**
- **Documentation index drift.** `ZYRA_STANDARDS_LIBRARY_V1.md` lists 3 standards. At least 8 exist (`IMAGE_HANDLING`, `ERROR_AND_EMPTY_STATE`, `JOURNEY_CAPABILITY_GRANT_RULES`, `WALI_ARCHITECTURE`, `GLOBAL_PLATFORM_PRINCIPLES`, `ADVERTISING_STANDARD`, `SUBSCRIPTION_TRANSPARENCY`, `TIERING`).
- **Outstanding Actions register uses 13 different status vocabularies** across 131 unique OA ids — `Completed`, `Actioned`, `RESOLVED`, `Resolved`, `Recorded`, `Closed`, `Open`, `Open ` (trailing space), `Draft`, `Blocked`, `Awaiting Review`, `Approved`. Not machine-queryable; "what is actually open?" cannot be answered reliably.
- **Decision Register status distribution is thin**: across 279 `DR-` references, only 14 RATIFIED, 2 APPROVED, 3 PROPOSED, 1 REJECTED, 2 SUPERSEDED are explicitly stated. Most decisions carry no status line.
- **Naming is inconsistent between folders** — `Summary.md`, `SUMMARY.md`, `Script_V1.md`, and full `*_CURRENT_VERSION_V*.md` coexist. The convention is well-specified for standards documents and unenforced elsewhere.

### 3.11 Product consistency

| Documented rule | Implementation reality |
|---|---|
| `IMAGE_HANDLING_V2` §Steps 1-8: validation, **EXIF/GPS stripping ("privacy-critical")**, orientation, compression, 5 variants, face detection, CDN, adaptive serving | `ImagePicker(imageQuality: 85)` → `uploadBinary`. **Zero of eight steps implemented.** No moderation, no AI quality evaluation, no safety/authenticity screening, no manual review queue. EXIF stripping is *probably* a side effect of `image_picker`'s re-encode, but that is an unverified implementation detail, not an enforced guarantee — and it does not hold for any non-picker upload path. |
| `IMAGE_HANDLING_V2`: "Profile not live until minimum 3 photos pass review, one approved by moderation, ID verification complete" | No review, no approval, no ID verification. `profile_complete` is never set at all (C3). |
| `IMAGE_HANDLING_V2`: "Images served exclusively via CDN… long-lived caching" | Served via per-request signed Supabase Storage URLs; caching structurally defeated (§3.3). |
| Browse: "Never display same-gender profiles" | Client-side filter only (H1). |
| JOURNEY AVAILABILITY: "Many Journey Queue, One Active Journey" | Not enforceable under concurrency (§3.7). |
| MATCH_UX_SPEC: "Compatibility % not shown until Active Journey" | ✅ Correctly honoured — the score never leaves the service layer. |
| Compatibility scoring | Two implementations (`compatibility_scoring.dart` and `score_candidates()`) that must be hand-synced. **Neither has ever run against real data — `onboarding_answers` has 0 rows live**, so every candidate scores the neutral 50.0. The system is unproven, not broken. |
| PROFILE DECISION SYSTEM: "Decline — no record, no notification" | ✅ Correctly honoured — declines are never persisted. |
| Notification preferences (Settings) | In-memory only; toggles have no effect. The screen discloses this, which is honest, but they are non-functional. |
| `DR-ZYRA-079` (compatibility model) is still **PROPOSED** | Wired into production discovery ordering and the Compatibility Reveal regardless. |

### 3.12 Engineering standards

**Followed well:** the `CURRENT_VERSION` document convention; DR citation in code; server-side write boundaries; the error/empty-state distinction in newer services; `AppState` listener disposal.

**Ignored:** `IMAGE_HANDLING` (entirely); accessibility (no standard exists, hence nothing to ignore — see below); the initial schema migration's own request that "a Founder/Lead Architect pass over the POLICY comments" happen before the policies are treated as final (H2 and the `wali_links` Path 3 gap both trace to that never happening).

**Missing entirely — no standard exists:** logging/observability; accessibility; testing; index-with-migration; lifecycle-aware timers; build-mode gating of developer tooling; pagination; git/backup discipline.

---

## 4. Risks — Prioritised Register

### 🔴 Critical

| ID | Risk | Impact |
|---|---|---|
| **R1** | Developer Access ships in release builds with hardcoded credentials (C1) | Account takeover of test accounts; full paywall bypass; plan manipulation |
| **R2** | `profile_complete` never written — no real user is ever discoverable (C3) | Core product loop non-functional for genuine sign-ups |
| **R3** | `mockProfiles` fallback shows **fake profiles to real users** on five code paths | Trust collapse in a religious-trust product; also hides R2 |
| **R4** | DOB column REVOKE ineffective (C2) | PII exposure of every user's exact birthdate; a fix believed complete but absent |
| **R5** | Users can self-edit `role`, `date_of_birth`, `profile_complete` (C4) | Latent privilege escalation; **age falsification / child-safeguarding**; onboarding bypass |
| **R6** | `mock_purchase_wali_premium()` live in production (C4b) | Free paid subscriptions; revenue integrity |
| **R7** | One-Active-Journey not enforceable under concurrency (§3.7) | Violates a stated CORE PRINCIPLE; incorrect Journey state |
| **R8** | `picsum.photos` stock photos shown as real users' profile pictures | `zyra_match_service.dart:87`, `zyra_journey_service.dart:115,589`, `zyra_wali_journey_service.dart:144` — a stranger's photo rendered as your match. Severe in this product category. Also an uncontrolled third-party dependency in a hot path. |
| **R9** | Unbounded queries with no pagination | Database and client failure between 10k and 100k users (§9) |
| **R10** | Unguarded `setState`/`Navigator` after async delay in Browse | Crash on the most-used screen |
| **R11** | No git remote, 2 commits, 126 uncommitted files | **Total project loss on single-disk failure** |

### 🟠 High

| ID | Risk |
|---|---|
| R12 | Gender segregation not enforced in RLS (H1) |
| R13 | Incoming Potentials paywall bypassable via RLS (H2) |
| R14 | `score_candidates()` inference oracle over private values answers (H3) |
| R15 | `ages_for()` bypasses profile row visibility (H3) |
| R16 | No app-lifecycle handling — 7 timers run in background indefinitely |
| R17 | Missing indexes on `profile_photos(user_id)` and `matches(seeker_b_id)` |
| R18 | 64 silent catches + zero logging = production failures invisible |
| R19 | No state-management architecture; decision open for 1 month |
| R20 | Two confirmed memory leaks (controllers) |
| R21 | No upload size or MIME limit on the Storage bucket |
| R22 | Zero test coverage; test suite does not compile |
| R23 | Image pipeline standard 0% implemented (no moderation, no safety screening) |

### 🟡 Medium

R24 `auth_rls_initplan` regression on all newer tables · R25 15 unindexed FKs · R26 Invite token 32-bit entropy · R27 Credentials tracked in git · R28 Accessibility absent · R29 Guardian→Seeker shell misroute on network error · R30 Daily limit resets on restart · R31 `deleted_at` not filtered · R32 Stale code comments contradicting schema · R33 Documentation index drift · R34 OA status vocabulary fragmentation · R35 Anon RPC error oracle · R36 Leaked-password protection off · R37 1-second countdown rebuilds · R38 No `RepaintBoundary` · R39 Stock `analysis_options.yaml`

### 🟢 Low

R40 Duplicated `_fetchAges` ×3 · R41 Duplicated photo-mapping ×5 · R42 `journey_flow_screen.dart` at 1,184 lines · R43 No `messages` UPDATE policy · R44 Eager `ListView` usage · R45 Inconsistent file naming · R46 No pull-to-refresh · R47 Orphaned storage objects

---

## 5. Recommendations

### 5.1 Immediate — before any further feature work

1. **Configure a git remote and push.** Private GitHub/GitLab. Commit the 126 pending files first. This is the highest value-per-minute action available and it protects everything else in this document.
2. **Guard all three Developer Access entry points** with `if (!kReleaseMode)`, matching the pattern already correct in `dev_nav_overlay.dart:78`.
3. **Re-do the DOB revoke properly** — table-level REVOKE plus an explicit column GRANT list. Then verify with `has_column_privilege` rather than assuming.
4. **Restrict `profiles` column-level UPDATE** to the columns a user may legitimately change, and add a `CHECK` for minimum age. `role` and `profile_complete` should be server-controlled only.
5. **`DROP FUNCTION mock_purchase_wali_premium, mock_set_wali_plan`** — or gate them behind a role that production users cannot hold.
6. **Write `profile_complete = true`** at the correct end-of-onboarding point (R2).
7. **Delete every `mockProfiles` and `picsum.photos` fallback from production paths** (R3, R8). Replace with an honest empty state. This is what makes R2 visible.

### 5.2 Short term

8. Add the two missing indexes; add `.limit()` + cursor pagination to all four unbounded queries.
9. Add a lifecycle observer that suspends all timers on background.
10. Migrate the seven polling loops to Realtime — the pattern already works in `chat_screen.dart`.
11. Add `sentry_flutter` (or equivalent) and replace the 64 silent catches with logged, typed failures.
12. Batch signed-URL generation across all candidates; cache signed URLs against their expiry.
13. Fix both controller leaks and the unguarded `setState`s in Browse.
14. Set `file_size_limit` and `allowed_mime_types` on the `profile-photos` bucket.
15. Move gender segregation into `profiles_select` and `profile_photos_storage_read`.
16. Constrain `ages_for()` and `score_candidates()` to ids the caller is permitted to see.
17. Fix the test file so `flutter test` compiles; add CI running `flutter analyze` + `flutter test`.

### 5.3 Structural — needs its own scoping pass

18. **Choose a state-management approach and close the month-old TBD.** Riverpod is the natural fit given the existing `ChangeNotifier`/service-layer shape.
19. **Build the image pipeline** (validation, EXIF strip, variants, CDN, moderation) — or formally reduce `IMAGE_HANDLING_V2` to a v1 scope and record the reduction as a DR. Right now the standard describes a system that does not exist, which is worse than either building it or scoping it down.
20. **Decompose `journey_flow_screen.dart`** into per-stage files.
21. **Redesign entitlements as a single server-authoritative source.** Delete `AppState.plan`.
22. **Enforce one-Active-Journey correctly** — `SELECT … FOR UPDATE`, or a single partial unique index over a normalised participant representation.

---

## 6. Quick Wins

Each of these is under an hour, self-contained, and closes a Critical or High risk.

| Fix | Effort | Closes |
|---|---|---|
| `git remote add origin … && git push` | 5 min | R11 |
| Three `if (!kReleaseMode)` guards | 10 min | R1 |
| Write `profile_complete = true` at onboarding completion | 10 min | R2 |
| `CREATE INDEX ON profile_photos(user_id)` + `matches(seeker_b_id)` | 10 min | R17 |
| `DROP FUNCTION mock_purchase_wali_premium, mock_set_wali_plan` | 5 min | R6 |
| Set bucket `file_size_limit` / `allowed_mime_types` | 5 min | R21 |
| Add `dispose()` to `_PickerSheetState` | 5 min | R20 (half) |
| Hoist the `chapter2_flow.dart:483` controller out of `build()` | 15 min | R20 (half) |
| `mounted` guards on the four Browse timers | 15 min | R10 |
| Enable leaked-password protection in the Auth dashboard | 2 min | R36 |
| `.limit(50)` on `fetchMessages` | 5 min | Part of R9 |
| Fix `test/widget_test.dart` to reference `ZyraApp` | 10 min | R22 (compile) |

**Roughly 1.5 hours of work closes six Critical risks.**

---

## 7. Long-Term Improvements

1. **Realtime everywhere** — retire polling as a pattern (largest single win for battery, cost and responsiveness).
2. **Server-authoritative business rules** — daily limits, ad frequency, gender segregation and entitlements move out of Dart. Assume a hostile client.
3. **Image pipeline + moderation** — the largest unbuilt system, and a hard prerequisite for public launch in this category.
4. **Observability** — crash reporting, structured logging, RPC latency dashboards.
5. **Test strategy** — unit tests for compatibility scoring; **pgTAP tests asserting RLS from the perspective of a second user** (C2, H1 and H2 would all have been caught by these); widget tests for Browse and the Journey state machine.
6. **Offline-first** — local cache + optimistic writes + a sync queue.
7. **Design system** — extract the repeated glass/gradient/typography patterns into a component library; wire `ZYRA_WIDGET_LIBRARY_CURRENT_VERSION_V1.md` to real code.
8. **Accessibility programme** — semantic labels, text scaling, contrast audit, VoiceOver/TalkBack passes.
9. **Data retention & privacy** — GDPR/UK-GDPR retention schedule, export, and audit logging for a matchmaking dataset containing religious belief (special-category data under UK GDPR Art. 9).

---

## 8. Suggested New Engineering Standards

Per your instruction, these are separated because **they should be ratified as standards before implementation**, not implemented ad hoc. Several map onto §9 of the existing performance review, which remains unratified — I recommend ratifying that document's list together with these rather than maintaining two parallel proposals.

| Proposed | Rule | Rationale from this audit |
|---|---|---|
| **ES-01 Build-Mode Gating** | Any developer/test affordance must be compile-time excluded from release builds. No runtime flags. | R1. The pattern already exists in `dev_nav_overlay.dart` and simply wasn't applied. |
| **ES-02 No Mock Data in Production Paths** | Mock/placeholder data may never be returned by a service that a real user can reach. Absence of data is an empty state, never fake data. | R3, R8. This rule alone would have surfaced R2 a month ago. |
| **ES-03 Server-Authoritative Rules** | Any rule with a safety, religious-propriety, or revenue consequence must be enforced in RLS or a `SECURITY DEFINER` function. Client checks are UX only. | R12, R13, R30. |
| **ES-04 Verify Security Fixes Empirically** | Every security migration must ship with a query proving the new state (`has_column_privilege`, a denied-select test). "The migration ran" is not evidence. | R4 — this is exactly how C2 was missed. |
| **ES-05 Index With Migration** | Every new hot-path query ships its supporting index in the same migration; every FK gets a covering index. | R17, R25. Matches the existing review's item 4. |
| **ES-06 Pagination By Default** | No unbounded `.select()` on a table that grows with users. | R9. |
| **ES-07 Lifecycle-Aware Timers** | Every timer/subscription pauses on background and resumes on foreground. | R16. Extends the existing review's item 6 to include subscriptions. |
| **ES-08 No Silent Catch** | `catch` must log with context. A caught error may be converted to a safe default only after being recorded. | R18 — the enabling condition for most of this audit's invisibility. |
| **ES-09 Realtime Over Polling** | New "wait for the other party" features use Realtime. | Matches the existing review's item 1. |
| **ES-10 Image Display** | Only `cached_network_image`; `precacheImage` for next-item content; **signed URLs cached against expiry so the cache key is stable.** | Extends the existing review's item 2 — without the stable-key clause the cache still misses. |
| **ES-11 Disposal Symmetry** | Every controller/subscription created in `initState` is disposed in `dispose`. No controller construction inside `build()`. Enforceable via a custom lint. | R20. |
| **ES-12 Accessibility Baseline** | Semantic labels on icon-only controls; no hardcoded font sizes that ignore `textScaleFactor`; minimum contrast. | R28. No standard currently exists. |
| **ES-13 Version Control & Backup** | Every project has an off-machine remote. No more than one working day of uncommitted work. | R11. |
| **ES-14 Test Gate** | `flutter analyze` and `flutter test` must pass before any change is considered complete. RLS changes require a pgTAP test asserting the policy from a second user's perspective. | R22, and would have caught C2/H1/H2. |
| **ES-15 Age Assurance** | Minimum-age constraint enforced in the database; `date_of_birth` immutable after profile creation without support intervention. | R5. Safeguarding, and a regulatory expectation in this category. |

---

## 9. Scalability Assessment

| Scale | Assessment |
|---|---|
| **100 users** | Fine. Nothing in this document bites at this size. Seq scans on 100 rows are free. The Critical security findings apply equally at every scale and are not scale-dependent. |
| **10,000 users** | **First real strain.** `fetchCandidates()` returns up to ~5,000 unpaginated rows, then makes ~5,000 sequential signed-URL round trips. `score_candidates()` performs ~5,000 sub-selects per Browse open. Missing indexes turn every 3-second Journey poll into a seq scan of `matches`. The notification bell alone generates ~1.8M requests/day. **Expect Browse to become unusable here.** |
| **100,000 users** | **Structural failure without the §5.2 work.** ~50k-row payloads per Browse; `score_candidates()` is the first thing to fall over. Storage grows unbounded (no size limit, no orphan cleanup). Polling load ≈ 200 req/min/active user. Postgres connection exhaustion via PostgREST becomes the binding constraint. Egress costs from re-downloading uncached images become material. |
| **1,000,000 users** | Requires re-architecture regardless of fixes: a dedicated matching/recommendation service rather than `score_candidates()` in PL/pgSQL, read replicas, a CDN in front of Storage, sharded or partitioned `messages`, and push notifications replacing polling entirely. The RLS-and-`SECURITY DEFINER` model remains sound — it is the unbounded query shapes and the scoring loop that do not survive. |

**Two structural blockers regardless of scale:** unbounded queries (R9) and `score_candidates()`'s O(N) loop. Both should be addressed while the dataset is still small enough that the fix is cheap.

---

## 10. Overall Production Readiness Assessment

**Verdict: not production-ready. Approximately 1–2 weeks of focused work from a defensible public beta, assuming the image-moderation question is scoped rather than fully built.**

| Dimension | Rating | Note |
|---|---|---|
| Architecture | 🟠 Adequate | Sound shape; the mock/real duality and the open state-management decision are the debt |
| Security foundation | 🟢 Strong | RLS everywhere, correct server-side write boundaries, `SECURITY DEFINER` callers checked |
| Security execution | 🔴 Critical gaps | C1, C2, C4, C4b — all narrow, all fixable |
| Data correctness | 🔴 Critical gaps | C3, one-Active-Journey race |
| Performance | 🟠 Known & documented | Prior review is accurate; unimplemented |
| Battery | 🟠 Poor | 7 unmanaged timers, no lifecycle handling |
| Scalability | 🟠 Fails ~10k | Unbounded queries and the scoring loop |
| UX | 🟠 Good visual craft | Error/empty conflation and accessibility are the gaps |
| Accessibility | 🔴 Absent | 1 semantic hint in 14,708 lines |
| Testing | 🔴 None | Suite does not compile |
| Observability | 🔴 None | No logging, no crash reporting, 64 silent catches |
| Documentation | 🟢 Strong | Best-in-class for this project size; some drift |
| Governance | 🟠 Good design, uneven application | Convention excellent for standards, unenforced elsewhere |
| Version control | 🔴 Critical | 2 commits, no remote |

### The honest summary

Someone has been building this carefully. The reasoning quality in both the documentation and the code comments is genuinely above average, the security *model* is sound, and several decisions (server-side write boundaries, safeguarding over monetisation, the private-bucket fix) are correct in ways that inexperienced teams routinely get wrong.

The problem is not the thinking. It is **verification**. Three of the four Critical findings are cases where a fix was designed correctly, implemented plausibly, and never checked:

- The DOB revoke was written, ran without error, and does nothing.
- `profile_complete` was designed into the schema, filtered on in three places, and never written.
- Developer Access was correctly guarded in one file and not in the three that mattered.

That is a single systemic gap — no verification step, no tests, no observability — presenting as four separate bugs. **ES-04, ES-08 and ES-14 together address the root cause**, and I would prioritise them over any individual fix in this document. Otherwise this same class of finding will recur in the next audit.

The second theme is **the mock scaffolding outliving its purpose.** Every mock fallback was a correct decision when written. Collectively they now form a layer that makes the app look like it works when it does not. `mockProfiles` hiding a total discovery failure is the clearest example, and `picsum.photos` rendering a stranger's face as a user's match is the most damaging one. **ES-02 is the rule that retires this whole class of risk.**

Neither theme is a competence problem. Both are the natural consequence of building fast without a verification loop — and both are cheap to fix now, at 26 users, rather than at 26,000.

---

## 11. Suggested Next Steps

1. **Read §6 and do the 1.5 hours.** Six Critical risks close. Git remote first.
2. **Ratify §8 (and the existing performance review's §9) as Decision Records** before implementing further. Several findings here are direct consequences of a rule that was known but never written down.
3. **Decide the image-moderation question explicitly** — build it, or record a scoped-down v1 as a DR. Do not leave a standard in force that describes a system that does not exist.
4. **Then** proceed to §5.2, and scope §5.3 separately.

---

## 12. Audit Method & Coverage

| Area | Method |
|---|---|
| Flutter | Full read of all 74 files / 14,708 lines; systematic grep for timers, disposal, lifecycle, image loading, `setState`, catch blocks, accessibility |
| Database | Full read of all 35 migrations; live inspection of `sxoaxonzjqkgajmlagyk` — `pg_policies`, `pg_indexes`, `information_schema.column_privileges`, `has_column_privilege`, `pg_get_functiondef`, `storage.buckets`, row counts |
| Advisors | Live `get_advisors` for both `security` and `performance` |
| Documentation | All `SYSTEM/DOCUMENTS`, `APP/Standards`, key `APP/*` specs, Decision Register, Outstanding Actions |
| Repository | `git log`, `git status`, `git ls-files`, `git remote` |

**Not covered:** runtime profiling on a physical device (no device available in this session); iOS/Android native configuration (`Info.plist`, `AndroidManifest.xml`, entitlements, ATS); `flutter analyze` output (Flutter toolchain not present in the audit sandbox); load testing; penetration testing beyond read-only privilege inspection. **No write operation of any kind was performed against the live database.**

---

## 13. Version History

| Version | Date | Change |
|---|---|---|
| V1 | 2026-07-26 | Initial comprehensive audit — architecture, Flutter, performance, battery, memory, network, database, security, scalability, UX, repository, product consistency, standards, risk register |

---

## 14. Governing References

- `ZYRA_PERFORMANCE_ENGINEERING_REVIEW_CURRENT_VERSION_V1.md` — corroborating performance review (unratified)
- `ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md` — contains a stale state-management TBD and an obsolete source path
- `ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md` — source for the initial schema migration
- `IMAGE_HANDLING_CURRENT_VERSION_V2.md` — the standard §3.11 measures against
- `ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1.md`
- `WALI_ARCHITECTURE_CURRENT_VERSION_V6.md`
- `ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5.md`
- `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md`
- `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md`
