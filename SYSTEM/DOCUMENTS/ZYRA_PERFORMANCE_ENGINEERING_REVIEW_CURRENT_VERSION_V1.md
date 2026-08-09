# ZYRA — Performance, Efficiency & User Experience Engineering Review

**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-07-26
**Owner:** Implementation Lead (Claude)
**Requested by:** Founder (Shakeel) — "New Discussion: Performance, Efficiency & User Experience Standards"
**Nature of this document:** Engineering opinion / discussion paper. Nothing in this document has been implemented as a result of writing it. Every finding below is grounded in a direct read of the current `SOURCE/` code and `SYSTEM/supabase/migrations/` schema on 2026-07-26 — no finding here is generic advice unconnected to this codebase.
**Governing References:** This document does not supersede any existing spec. Where it recommends a rule that should become permanent, that rule is called out explicitly in Section 9 for separate ratification (as a DR), not assumed to be in force by virtue of appearing here.

---

## How to read this document

You asked for an engineering opinion before any implementation — this is that opinion, not a work order. Section 9 lists exactly which items I believe deserve to become permanent, enforced engineering standards (the kind of thing a future contributor, human or AI, could violate by accident without a written rule to catch them). Everything else is a recommendation to weigh, not a rule already in force.

I looked at this from the codebase as it stands today: a Flutter/Dart client with `supabase_flutter`, no state-management package (a single hand-rolled `ChangeNotifier` singleton, `AppState`), no image-caching package, no offline/connectivity package, and a Supabase Postgres backend with RLS and SECURITY DEFINER functions doing the heavy lifting. That context matters — several of the findings below are "the obvious next dependency to add," not exotic optimisation.

---

## 1. Current Strengths

**Startup path is already lean.** `main.dart` does exactly one blocking thing before `runApp()` — `Supabase.initialize()` — everything else (session resolution, per-screen data fetches) happens after first frame, inside `FutureBuilder`s and `initState()` calls that show a spinner rather than blocking the paint. `AuthGate` → `ZyraSessionRouter.resolveHome()` is a single lightweight `profiles.select('role')` lookup, not a cascade of sequential fetches. This is the right shape and is worth explicitly protecting as things grow (see Section 9).

**Progressive, screen-scoped data loading is already the norm.** Nearly every screen fetches its own data in `initState()` rather than requiring a global "load everything" step before the user can see anything. `HomeShell`, `WaliProfileScreen`, `BrowseScreen` all render immediately (often with a mock/fallback dataset) and replace content once the real fetch resolves. This is good architecture for perceived performance and I'd keep it as the default pattern rather than introducing a heavier global bootstrap sequence.

**RLS and SECURITY DEFINER boundaries are already doing real query-shaping work, not just security.** `score_candidates()`, `ages_for()`, `wali_has_extended_wali()` etc. push filtering logic server-side, which is also a performance win — the client never has to fetch the full candidate set and filter client-side. Keep this pattern; it's good for both security and payload size.

**Indexing on the highest-traffic tables is already reasonable.** `messages_conversation_created`, `likes_liker`/`likes_liked`, `profiles_browse`, `wali_links_seeker`/`wali_links_wali` (partial, `WHERE status='active'`), `subscriptions_user` (partial, `WHERE status='active'`) — these all match the actual query shapes I found in the service layer. This isn't an app that was built with no thought to query performance; it's one where a few specific gaps slipped through (Section 2/6).

**The Guardian Gate and Family Stage already enforce real participation, not just entitlement.** Unprompted by this review — I checked this separately for the Guardian linking discussion below — `ZyraJourneyService.hasActiveMainWali()` gates Journey progression on a real `wali_links` row, and Family Stage requires the linked Guardian to actually answer questions, not merely exist as a subscription line item. Whoever built this got the safeguarding-over-monetisation distinction right at the two places it matters most, before it was ever written down as a rule.

---

## 2. Current Weaknesses

**No image caching package anywhere in `pubspec.yaml`.** Every `Image.network(...)` call (Browse photos, profile photos, match screens) relies solely on Flutter's default in-memory `ImageCache`, which is unbounded by URL lifetime awareness and doesn't survive app restarts. There is no disk cache, no cache-eviction policy tuned for this app's photo volume, and — this is your reported symptom — no *preloading* of the next photo in a profile's photo array before the user taps/swipes to it. The delay you noticed swiping between photos is a direct, structural consequence of this: `browse_screen.dart`'s `_tapPhoto()` switches `_photoIndex` and the `Image.network` widget only starts fetching that photo *at the moment it's asked to paint it*, not before.

**Signed URLs are re-issued on every Browse load, even though they're valid for 7 days.** `ZyraPhotoService.signedUrlsFor()` calls Supabase Storage's `createSignedUrls` fresh, every single time `fetchCandidates()` runs — there's no local cache of "I already have a valid signed URL for this storage path, expiring at X." A user who opens Browse five times in a day re-signs the same photos five times, each one a real network round trip to Storage before any image bytes are even requested.

**A sequential per-candidate network call in `fetchCandidates()`'s main loop.** This is the single most concrete, fixable finding in this review:

```dart
for (final row in rows) {
  ...
  final photos = await ZyraPhotoService.signedUrlsFor(...);   // one Storage round trip PER candidate, awaited in sequence
  ...
}
```

For N candidates this is N sequential network round trips before Browse can render anything, when it could be one. This is very likely contributing more to "Browse feels slow to open" than the photo-swipe delay itself, because the whole list is blocked on it, not just one photo transition. `signedUrlsFor()` already correctly batches multiple *paths* into a single call — the fix is to hoist that batching one level up, across *all* candidates at once, rather than once per candidate.

**A single global `ChangeNotifier` singleton (`AppState`) with no scoped listening.** Every screen that reacts to app state does the same thing: `AppState.instance.addListener(_onChange); void _onChange() => setState(() {});`. That means *any* field change anywhere — toggling a notification preference, a Guardian link list refresh, a plan change — triggers a full-subtree rebuild of every screen listening to `AppState`, not just the widget that actually depends on the changed field. Six screens currently do this. It works today because the app is small and mock-data-shaped; it will not scale gracefully as more screens listen and as `AppState` grows more fields, because the blast radius of every `notifyListeners()` call grows with every listener added, regardless of relevance.

**Polling is the default "real-time" strategy everywhere, and it's inconsistent in aggressiveness.** This is the most systemic finding in this review. I counted **seven** independent polling loops in the current codebase:

| Location | Interval | Purpose |
|---|---|---|
| `notification_bell.dart` | 20s | unread notification count |
| `journey_flow_screen.dart` (Compatibility Reveal) | 3s | wait for other party's reveal |
| `journey_flow_screen.dart` (Salam Exchange) | 3s | wait for other party's Salam |
| `journey_flow_screen.dart` (Phase 1/2/3) | 3s | wait for other party's answers |
| `journey_flow_screen.dart` (Family Stage) | 5s | wait for linked Guardian's answers |
| `wali_journey_detail_screen.dart` | 5s | wait for Seeker's answers (Guardian side) |
| (cooling-period countdown ticker, 1s) | 1s | UI-only, not network — not a concern itself |

None of this is accidental — `zyra_journey_service.dart`'s own header comment says so directly: *"Realtime is also out of scope for this pass... simpler and safer than standing up a new Realtime channel subscription for this task."* That was a reasonable v1 call. It is not a reasonable permanent architecture. A user sitting on the Phase 2 question screen waiting for their match to answer is making a real network request every 3 seconds indefinitely, for as long as that screen is open — that's the textbook definition of the battery/network drain pattern you described wanting to avoid.

**Missing index on `profile_photos(user_id)`.** The only index on that table is a *partial* unique index (`WHERE is_primary = TRUE`), which doesn't serve the actual hot query — "give me every photo for this user, in `display_order`" — the exact query `fetchCandidates()` runs, nested, for every Browse candidate. On a small table this is invisible; it will not stay invisible.

**`google_fonts` runtime font fetching is a live dependency, not just a build-time one.** Unless explicitly configured to load from bundled assets, `google_fonts` fetches font files over the network the first time each weight/family is used and caches them locally after that. That means first-ever launch (and any launch after cache is cleared) has a network dependency baked into rendering *any text at all* — a real startup/offline risk for something as core as text rendering.

**No offline-awareness anywhere.** There is no `connectivity_plus` (or equivalent) in `pubspec.yaml`, and no screen distinguishes "you're offline" from "something went wrong" — nearly every service method's error handling is a blanket `catch (_) { return <safe empty default> }`. That's a defensible short-term choice (nothing crashes), but it means a user with a flaky connection sees "You're all caught up" (Browse's empty state) instead of "You're offline," which is confusing in exactly the way your brief says you want to avoid ("this should never feel like a software bug").

---

## 3. Performance Risks (as the app scales)

- **The sequential signed-URL loop and the missing `profile_photos` index compound each other.** Right now there are effectively 1-2 real Seeker accounts in the system, so N is tiny and neither issue is felt. The moment there are hundreds of candidates in a Browse query, both become O(N) round trips and unindexed table scans respectively, on the exact screen users open most often.
- **`score_candidates()` runs per Browse load, over the full onboarding-answer set of every candidate.** I didn't find a cached/precomputed compatibility score anywhere — it's recomputed live every time Browse fetches candidates. This is fine at low volume; at scale, this is the kind of computation that benefits from being precomputed on a schedule (or invalidated only when either party's answers change) rather than recomputed synchronously in the request path of the screen users open most.
- **`AppState`'s unscoped rebuild pattern gets worse, not better, as features are added.** Every new screen that needs *any* piece of shared state currently reaches for the same `addListener` pattern, meaning the app's total rebuild cost per state change grows linearly with feature count, not with relevance.

## 4. Battery Risks

- **The seven polling loops above are the primary battery risk in this app**, full stop. Polling continues for as long as the hosting screen is mounted, with no `WidgetsBindingObserver`/`AppLifecycleState` check to pause polling when the app is backgrounded — so a phone left on the Phase 2 screen with the app backgrounded (on platforms/configurations where the isolate keeps running) continues making network requests it has no user-visible reason to make.
- **None of the timers currently back off.** A conversation where the other party has gone quiet for an hour still polls every 3-5 seconds at the same rate as the first minute.

## 5. Memory Risks

- **Unbounded default `ImageCache` with no eviction policy tuned to this app.** Flutter's default image cache has a fixed item/byte ceiling (`PaintingBinding.instance.imageCache.maximumSize`/`maximumSizeBytes`), unmodified anywhere in this codebase — meaning the defaults (1000 images / 100MB) are in effect. For a photo-heavy Browse experience, that ceiling is arguably too generous for a phone with 3-4GB RAM and other apps in the background, or too stingy once thumbnailing (Section 7) reduces per-image cost. Either way, it's an unreviewed default, not a decision.
- **No explicit `dispose()` gaps found** in the screens I read (Timers are cancelled in `dispose()` consistently — that discipline is good and present already), but I did not have time in this pass to audit every screen for controller/listener leaks exhaustively; that's a good candidate for the automated check described in Section 9.
- **Full-resolution originals, always.** `ZyraPhotoService.pickAndUpload()` uploads with `imageQuality: 85` (a reasonable JPEG compression on upload) but there is no server-side or client-side *thumbnail variant* — Browse, which shows a photo at a fraction of its original dimensions, downloads and decodes the exact same bytes as the full profile-photo viewer would. That's wasted memory and network on every single Browse card.

## 6. Network Risks

- **The signed-URL re-signing and sequential-loop issues above are the two concrete network risks today.**
- **No request batching/backoff/retry strategy exists anywhere** — every service method is a single fire-and-forget `await`, wrapped in `try/catch` that silently falls back rather than retrying. That's the right failure *mode* (never crash, never block the user) but the wrong failure *strategy* for transient network blips — a single dropped packet on a mobile network currently reads identically to "there is truly nothing to show," when a one-time retry would silently fix most of those cases.

## 7. UX Improvements (tied to your photo-swipe example specifically)

Your example is the clearest, most fixable item in this whole review. To get "next photo appears instantly," in order of impact:

1. **Preload adjacent photos.** The moment a profile becomes `_current`, kick off `precacheImage()` for every photo in that profile's array, not just the one being shown. This alone would likely eliminate the delay you're describing, since by the time a user taps to the next photo, Flutter's image cache already has the decoded bytes.
2. **Add `cached_network_image` (or equivalent).** Gives disk-backed caching (survives app restarts, not just in-memory), a built-in placeholder/fade-in transition (masks any remaining latency instead of showing a blank frame), and a memory-cache size Flutter's own default doesn't tune for you.
3. **Batch-sign all candidates' photo URLs in one call, once, per Browse session** — not per candidate, not on every re-open within the 7-day validity window. This fixes the *list-level* load delay, distinct from the *photo-level* swipe delay you specifically flagged.
4. **Generate and serve a thumbnail variant for Browse-card display**, reserving the full-resolution original for the rare "view full profile photo" case (if that even exists yet). Smaller bytes over the network, smaller decode cost, smaller memory footprint per cached image — the single highest memory/network return for a photo-heavy discovery screen.

## 8. Recommended Architectural Improvements

- **Replace journey/notification polling with Supabase Realtime channel subscriptions**, at least for the highest-traffic ones (Phase 1/2/3 answer-waiting, Family Stage). This is the single highest-leverage change in this whole review — it turns seven always-on timers into event-driven pushes, which is strictly better for battery, network, and perceived responsiveness (a Realtime push arrives the moment the other party acts, rather than up to 3-5 seconds later).
- **Introduce a real state-management approach with scoped rebuilds** (`ValueNotifier` per concern, `Provider`/`Riverpod`-style selective listening, or simply splitting `AppState` into several smaller `ChangeNotifier`s scoped by concern — profile, journeys, Guardian, preferences) before more screens accumulate the blanket `addListener` pattern. This is a bigger lift the longer it's deferred, because every new screen that copies the existing pattern adds another all-or-nothing listener to unwind later.
- **Move compatibility scoring toward precompute-and-invalidate rather than compute-on-every-Browse-load**, once there's a real volume of Seekers to make this worth doing (not urgent today, worth deciding the shape of before it's urgent).
- **Add an offline/connectivity signal** (`connectivity_plus` or platform-native check) so empty/error states can honestly say "you're offline" instead of silently rendering as if there's simply nothing to show.
- **Bundle Google Fonts as local assets rather than runtime-fetched**, removing a network dependency from core text rendering and improving first-run/offline behaviour.

## 9. Recommendations to Consider Permanent Engineering Standards

These are the ones I'd actually propose writing down as enforceable rules — the kind that should live in a `SYSTEM/DOCUMENTS` standard, not just this discussion:

1. **No new "wait for the other side" feature may use a polling `Timer` by default — Realtime subscriptions are the required pattern going forward.** The existing seven polling loops are accepted technical debt to migrate, not a precedent to keep copying.
2. **Any new image displayed in a list/feed context must be preloaded/cached, never a bare `Image.network()`.** Concretely: adopt `cached_network_image` as the only sanctioned way to display a remote photo anywhere in the app, and require `precacheImage()` for "next item" content (next photo, next Browse card).
3. **Any new shared-state field must be added to a scoped notifier, not the single `AppState` `ChangeNotifier`,** once the state-management refactor lands — until then, new fields should at minimum be grouped so unrelated screens aren't forced to rebuild for each other's changes.
4. **Every new hot-path table/query must ship with its supporting index in the same migration** — the `profile_photos(user_id)` gap should have been caught by this rule if it existed; make it explicit so it's checked, not assumed.
5. **Startup must stay "one blocking network call, then progressive per-screen loads."** This is already true today — worth protecting explicitly so a future feature doesn't quietly add a second blocking call before `runApp()`.
6. **All timers/listeners must be lifecycle-aware** (pause on background, resume on foreground) once any polling remains after the Realtime migration — no silent background network activity.

---

## What I did not review in this pass

Push notification delivery cost (not built yet — #33 is still pending real FCM/APNs credentials), payment/IAP network behaviour (#20, not built), and a full leak audit of every screen's `dispose()` — flagged as a good candidate for a follow-up pass, possibly automatable via `flutter analyze` custom lints or a scripted `initState`/`dispose` symmetry check, rather than a manual review.

---

## Next Step

This document is the discussion you asked for. Nothing above has been implemented. My recommendation on sequencing, if you want one: the photo-preload/cache fix (Section 7) is small, isolated, and directly answers your reported symptom — a reasonable first thing to actually build once we've agreed direction. The Realtime migration (Section 8) is the highest-leverage item overall but touches five screens and is a bigger, more deliberate piece of work worth its own scoping pass rather than folding into a quick fix.
