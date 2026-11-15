# FIX BRIEF — STILL PAGES (LOCK 26 V4) — 13 NOV 2026

Spec: `PRODUCT/APPROVED/APP_SWIPE/RECORD/APP_SWIPE_SPEC_CURRENT_VERSION_V4.md` (Scrolling row).

## Problem
On My ZYRA ("Nothing needs you right now"), the whole page can be dragged up and down and bounces, although nothing scrolls. Cause: `_ZyraScrollBehavior` in `SOURCE/lib/main.dart` returns `ZyraMotion.scrollPhysics`, which wraps `BouncingScrollPhysics` in `AlwaysScrollableScrollPhysics`.

## Change
1. In `ZyraMotion`, make the shared up/down scroll feel `BouncingScrollPhysics` with **no** `AlwaysScrollableScrollPhysics`. Content taller than the screen keeps the iPhone bounce; content that fits stays still.
2. Keep `AlwaysScrollableScrollPhysics` **only** where a pull-to-refresh exists (a `RefreshIndicator` needs it). List each place kept in the as-built record.
3. Check that no screen sets its own always-scrollable physics; remove any that are not for pull-to-refresh.
4. Applies app-wide: every page and sheet, Seeker and Guardian, Founder preview and member app.

## Checks
- My ZYRA, all caught up (Seeker and Guardian): dragging up or down does not move the page.
- A long page (e.g. Settings, Timeline, a long chat) still scrolls with iPhone bounce at both ends.
- Pull-to-refresh, where it exists, still works.
- The sideways swipe (LOCK 26 V3) is unchanged.
- Tests for the shared physics are updated; no new failures.
