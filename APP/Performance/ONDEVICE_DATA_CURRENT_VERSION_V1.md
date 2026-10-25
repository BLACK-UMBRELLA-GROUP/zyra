---
id: DOC-ZYRA-0045
type: SPEC
status: CURRENT
feature: APP: PERFORMANCE
purpose: Performance — ONDEVICE DATA CURRENT VERSION V1: ZYRA — On-Device Data & Performance Standard
links: []
owner: ZYRA chat
---

# ZYRA — On-Device Data & Performance Standard

**Date:** 2026-08-15
**Status:** RATIFIED (Founder, 2026-08-15: "All three phases") and BUILT the same day — DR-ZYRA-169. This is the governing document for what ZYRA keeps on the phone.
**Build notes:** three adjustments were made at build time, each recorded in DR-ZYRA-169 — (a) the identity kit caches the first name but NOT the own-photo storage path (once Phase 1 exists, the avatar disk-hits the moment its URL arrives, so a stored path bought nothing); (b) Phase 3 shipped as bounded decodes (RAM/jank win) — the bandwidth half needs server-side image transforms, which are a paid Supabase feature and lack a batch signing API, so it is tracked as OA-ZYRA-233 rather than guessed at; (c) `signedUrlsFor` now delegates to `signedUrlMap`, retiring a second copy of the chunked signer and its harsher all-or-nothing failure mode.
**Scope:** What ZYRA should keep on the user's phone so the app feels significantly faster, without creating privacy, security, stale-data, or maintenance problems.
**Method:** Read directly from the live source on the Mac (services, state, main.dart, pubspec, photo pipeline, auth/sign-out paths, both shells, Help & Support).

---

## 0 · WHAT ZYRA STORES ON-DEVICE TODAY (the baseline)

Before recommending anything, this is the complete, verified inventory. It is short — deliberately so.

| # | Data | Where | Cleared on sign-out? |
|---|------|-------|----------------------|
| 1 | Supabase auth session (JWT + refresh token) | SharedPreferences, written by `supabase_flutter` itself | Yes — `supabase.auth.signOut()` |
| 2 | `zyra.cached_gender` | SharedPreferences via `ZyraLocalPrefs` | Yes — `ZyraLocalPrefs.clear()` |
| 3 | `zyra.cached_role` (seeker/wali, DR-ZYRA-166) | SharedPreferences via `ZyraLocalPrefs` | Yes |
| 4 | `zyra.app_lock_enabled` (boolean only — no PIN, auth delegated to the OS) | SharedPreferences via `ZyraLocalPrefs` | Yes |
| 5 | Everything else — profile, decisions, journeys, unlocks, consent answer, notifications, photos | **Memory only** (AppState singleton + Flutter's in-RAM image cache) | Dies with the process |

There is **no disk image cache, no local database, no path_provider/sqflite/hive, no secure-storage store**. `zyra_local_prefs.dart` carries an explicit scope rule — "only values needed to paint correctly BEFORE the network answers… not a general local database… NOT A SECURE STORE" — and the sign-out path (`zyra_auth.dart`) clears local prefs, per-account unlocks, the cached Article-9 consent answer, and the in-memory App Lock. Account deletion (`delete_own_account` RPC) removes the user's own Storage files first, then cascades server-side, then signs out locally.

**Verdict on the current approach (your question 7):** the *privacy* side is already excellent — minimal, deliberate, and hygienic on logout/switch/deletion. The *performance* side is under-built in exactly one large place (images) and two small ones (first-frame identity, repeated URL signing). This review is mostly about closing those three gaps without loosening the discipline that is already there.

---

## 1 · CURRENT PROBLEMS (questions 1, 2, 8, 9)

### P1 — Every photo is re-downloaded on every launch. *(Biggest cost, biggest win)*
Photos live in a **private bucket** and are displayed through **signed URLs (7-day expiry)** via `Image.network` — which uses only Flutter's in-RAM cache. Kill the app and every byte downloads again: the Browse deck, every Connections row, every Journey tile. The photo service's own comments show the scale — a full Browse deck asks for ~290 photo paths. On mobile data this is the single largest avoidable cost in both bandwidth and perceived speed.

### P2 — Signed-URL rotation defeats caching even *within* a session.
Every fetch **re-signs** the same storage paths, and each signing produces a *different URL string* for the same bytes. Flutter's image cache keys on the URL — so after any Connections `_refresh()` (which runs after every pause/end/begin action), the same photos re-download because their URLs changed. Any caching solution must key on the **storage path**, never the URL. This is also why simply adding a stock caching widget without a custom cache key would appear to work and silently cache nothing.

### P3 — Avatars download the same originals as full-screen photos.
A 56-pixel thumbnail in a Connections row fetches the identical original object as the full-screen Browse card. Supabase Storage supports transform parameters on signed URLs; small surfaces could request small images.

### P4 — The signing pass itself repeats.
Each list fetch performs a fresh batched signing round-trip (chunked at 40–80 paths, with retry). The URLs live 7 days, but ZYRA re-mints them many times per session. An in-memory path→URL memo would remove most of these calls. (Deliberately **in-memory** — see NEVER STORE, item N2.)

### P5 — First frame knows your gender but not your name.
Gender and role are cached for frame one (the purple-flash fix, and DR-ZYRA-166's routing fallback), but first name, surname line, and location still need the cold-start round trip — the documented "Your Profile / —" flash on slow connections. The same narrow scope rule that admitted gender admits the name.

### P6 — Stale-data risk today is low *by construction* — new caching must keep it that way.
Because almost nothing persists, the UI and server can barely disagree across launches (your question 9). The one live risk is in-memory: AppState's decision lists hydrate once per launch, so a second device's actions aren't seen until relaunch — acceptable, and refreshed on every action. The architecture below adopts a hard rule so this property survives: **a cached value may paint, never decide.**

### P7 — Two minor notes, recorded for completeness.
`zyra.cached_role` could route user B by user A's role in the narrow case of a crash-before-sign-out followed by a different account's *failed* profile lookup — worth a one-line guard someday, not urgent. And photo *removal* currently orphans Storage objects (already flagged in `zyra_photo_service.dart` as a pre-launch cleanup).

### P8 — Could excessive local storage cause problems? (your question 8)
Yes, four ways, and the architecture below is shaped by them: device storage pressure (bounded by a size cap + LRU); OS backup leakage (avoided by caching only into the OS *cache* directory, which iOS excludes from iCloud backup and may purge under pressure — both desirable here); a wider privacy surface (bounded by TTL + wipe-on-sign-out + App Lock); and stale photos (bounded by TTL; note that photo *changes* self-invalidate because each upload creates a new storage path).

---

## 2 · SAFE TO CACHE (persists between sessions — questions 2 & 5)

| Data | Why it is safe | Lifetime | Cleared when |
|------|----------------|----------|--------------|
| **Profile photo bytes**, keyed by storage path, for profiles actually rendered | Photos of active+complete profiles are already visible to any signed-in Seeker under RLS; the cache only keeps what the user already saw, inside the app sandbox (iOS encrypts at rest; App Lock adds a face) | 7 days TTL (matches signed-URL life) + LRU size cap ≈ 150 MB | Sign-out, account deletion, blocking that user, TTL, LRU |
| **First-frame identity kit** — gender ✓, role ✓, App Lock flag ✓, first name ✓ (all built) | Your own identity, on your own device, for frame one; same scope rule `zyra_local_prefs.dart` already enforces. (Own-photo path was reviewed in and trimmed at build time — see Build notes.) | Until overwritten | Sign-out (existing `clear()`) |
| **UI preferences** (App Lock today; any future toggles) | Settings, not data | Until changed | Sign-out |
| Static content — stage maps, questions, moment copy | Already compiled into the binary | n/a | n/a |

Nothing else earns persistence in v1. Notably **not** cached to disk: connection/journey lists (even as name-and-stage skeletons). They would make the Connections tab paint instantly after cold start, but "who am I in a Journey with" is the most sensitive fact ZYRA holds — I recommend leaving it out of v1 and revisiting only if cold-start paint still feels slow *after* images are cached. That is a Founder call; the review's default is **no**.

---

## 3 · SHORT-LIVED CACHE (session-lifetime, memory only — question 4)

| Data | Form | Lifetime |
|------|------|----------|
| Signed-URL memo (storage path → URL + signed-at) | In-memory map in the photo service | Session; re-sign any entry older than ~6 days |
| Browse deck, Connections lists, journeys, timeline | AppState / screen state, as today | Session (IndexedStack already preserves them across tab switches) |
| Ages (id → age) | In-memory memo | Session |
| Unread badge & section dots | In-memory, hold-last-on-failure (built in DR-ZYRA-167) | Session |
| Article-9 consent answer | In-memory memo (exists — `ZyraConsentService._cached`) | Session; cleared on sign-out |

The pattern: within a session, memory is the cache; across sessions, only §2 survives.

---

## 4 · SERVER ONLY (always fetched fresh — question 6)

- **Journey state** — stage, pause/suspension, restart requests, Family Review status. Two people and their Guardians move this; it is why the 3–5s polls exist. Never cached.
- **Messages** and conversation state.
- **Notifications** — list and counts (the in-memory hold-last on a failed poll is error-honesty, not a cache).
- **Plan / entitlements / subscription status** — anything that *gates*. A wrong cached plan either blocks a paying user or hands out ZYRA One free. Today it is fetched in the blocking cold-start hydration; keep exactly that.
- **Compatibility scores, unlock state at decision time** — paid content, server-checked.
- **The Browse candidate deck** — availability, blocks, Tier rules are server-computed truths that change under you.
- **All writes** — no offline write queue in v1. DR-ZYRA-167's truthful-failure model ("it didn't save — retry") is the correct behaviour for a matrimonial app; queueing a Pass or a Like made offline and replaying it later invents ordering and consent hazards for no real gain.

---

## 5 · NEVER STORE LOCALLY (question 3 + your privacy section)

- **N1** — Tokens beyond Supabase's own session store; never mirror or log them.
- **N2** — **Signed URLs on disk.** A signed URL is a bearer capability — anyone holding the string can fetch the photo for 7 days, outside the app. Cache the *bytes* (keyed by path) and memo URLs *in memory only*.
- **N3** — Date of birth (the client cannot even SELECT it today — keep it that way), guardian contact details, phone numbers.
- **N4** — Messages, family answers, phase answers, end reasons (the concealment design in `zyra_match_ending` must not be defeated by a local copy), blocks, reports.
- **N5** — Consent history (the server is the Article-9 log; the in-memory memo is the most that is acceptable).
- **N6** — One-time codes and invite tokens — never persisted, never logged (standing rule).
- **N7** — Other users' structured profile records. Rendered photo bytes under TTL are the ceiling of what another person's data may leave the network layer.
- **N8** — Compatibility category breakdowns (paid content and sensitive inference in one).

### After logout / switch / deletion / another person using the phone
The existing sign-out block already clears local prefs, unlocks, consent, and the in-memory lock — the pattern is right. Two additions are required the day the image cache ships: **empty the disk image cache and the in-RAM `ImageCache` inside the same sign-out block**, and the same on account deletion. With those, the after-states are: logout → device holds nothing but an empty app; switch → second account inherits nothing (the reason the gradient/lock clears exist today); deletion → server rows gone, device wiped by the sign-out path it already triggers; another person picking up the phone → App Lock (already a flagship feature) in front of everything, and nothing readable outside the sandbox.

---

## 6 · RECOMMENDED ARCHITECTURE

Four layers, one rule.

```
L1  First-frame kit     SharedPreferences · ~6 keys · cleared on sign-out
L2  Session memory      AppState + URL memo + RAM image cache (today's model, kept)
L3  Disk image cache    bytes keyed by STORAGE PATH · TTL 7d · LRU 150 MB · OS cache dir
L4  Auth session        supabase_flutter's own store (untouched)
```

**The one rule: a cached value may paint, never decide.** Nothing cached gates a capability, passes a guard, or feeds a write. The server's answer replaces the cached paint the moment it arrives (stale-while-revalidate), so the UI and server cannot *stay* in disagreement — your question 9 answered structurally rather than case by case.

**Where the image cache goes:** `ZyraProfileImage` — the codebase already forced every photo *render* through this one widget ("ONE place decides, deliberately"). Swapping its `Image.network` for a cached loader with `cacheKey = storage path` upgrades Browse, Connections, Journey tiles, chat headers, and the Guardian views at one insertion point. This is the architectural payoff of a decision already made. Two companions come along: Browse's photo *pre-loading* (two `precacheImage(NetworkImage(…))` calls, added 2026-07-26 to fix the tap-to-next-photo stall) must switch to the same cached provider with the same path key, or the prefetch warms the wrong cache; and the widget currently receives only the signed URL, so the storage path needs threading alongside it through the profile models — small, mechanical.

**Self-management (your no-manual-clearing requirement), five mechanisms:**

1. **Expiry** — TTL on every disk entry (7 days, matching signed-URL life).
2. **Size** — LRU cap (~150 MB) enforced by the cache layer itself; the OS may additionally purge the cache directory under storage pressure, which is a feature.
3. **Corruption recovery** — every cache read wrapped in try/catch; any failure is a cache *miss*, answered by the network. This is already the codebase's pattern (`ZyraLocalPrefs.init()` degrades to the neutral gradient rather than failing the boot).
4. **Schema version** — one `zyra.cache_schema_version` int; when an app update changes cache shape, mismatch wipes caches once at startup. No user ever "clears data to fix an update".
5. **Event invalidation** — sign-out/deletion → wipe all layers; blocking a user → evict their cached images immediately; changing your own photos → self-invalidating (new upload = new storage path = new key).

A user on this architecture never has a reason to clear anything: there is no state a fresh fetch doesn't overwrite, no growth a cap doesn't bound, and no corruption a miss doesn't heal.

**Explicitly not recommended for v1:** a local database (sqflite/hive), offline mode, persisted lists of other people, background prefetching of profiles not yet viewed, or a Settings "Clear cache" button. Each adds a second source of truth or a surface that admits the app breaks — the exact things `zyra_local_prefs.dart`'s scope rule exists to prevent.

**Sequencing (ratified 2026-08-15; build state as of DR-ZYRA-169):**

1. **Phase 1 — the felt speed:** ✅ BUILT. Disk image cache keyed by tokenless URL (`ZyraImageCache`), rendered through `ZyraProfileImage`, warmed by Browse's precache pass, wiped on sign-out/deletion/block, schema-versioned. Two dependencies declared (`cached_network_image` + its engine `flutter_cache_manager`, declared directly for the same reason `shared_preferences` was).
2. **Phase 2 — the polish:** ✅ BUILT. First name in the first-frame kit (every writer caches, per the DR-ZYRA-165 lesson); in-memory signed-URL memo (6-day refresh against the 7-day URL), cleared on sign-out.
3. **Phase 3 — the diet:** ✅ BUILT as bounded decodes (small renders decode at display size automatically). Bandwidth-side transform sizing is OA-ZYRA-233 — pending a Supabase plan check and a device visual pass.
4. **Not scheduled:** connection-skeleton persistence — only if cold-start paint still disappoints after Phases 1–2, and only as its own Founder decision.

---

## 7 · USER SUPPORT — do we need a "refresh the app" instruction?

**Yes, one FAQ entry; no button.** Help & Support is already a searchable FAQ with a "Still need us?" contact block — the right home. Add a single entry along the lines of *"Something looks out of date?"* → pull down or reopen the app; if something still looks wrong, sign out and back in (which resets everything ZYRA keeps on the device). Worded as the rare fallback it is — because under the architecture above, sign-out genuinely *is* a full local reset, so the instruction is truthful and complete. No "Clear cache" control in Settings: a maintenance button is an admission the maintenance is the user's job, which is precisely what you have said it must not be.

---

## The headline answer

ZYRA can safely keep three things on the phone: **the photos the user has already seen** (bytes only, path-keyed, TTL'd, capped, wiped on sign-out), **the half-dozen facts frame one needs** (gender, role, lock flag, first name), and **its existing session memory**. That combination removes the app's largest repeated download and its last cold-start flashes — the two things a user feels — while everything that could lie, leak, or linger (journey state, messages, entitlements, other people's data, bearer URLs) stays server-only or memory-only. The privacy discipline already in the codebase doesn't need loosening to get the speed; it needs one disk cache with the same manners the rest of the code already has.
