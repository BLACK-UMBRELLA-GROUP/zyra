---
id: TBC (Fable assigns)
type: EVIDENCE
status: CURRENT
feature: APP SPACING
purpose: Line 77 measured spacing audit, before and after
links: [AD-AIOS-115]
owner: Codex
---

# LOCK 24 spacing audit — 11 November 2026

Each row lists **430 × 932 default / 430 × 932 Larger Text / 375 × 667 default / 375 × 667 Larger Text**, in that order. Units are logical points. The bottom insets are 34/34/0/0 and the top insets 59/59/20/20. Larger Text is 200% using the existing preview test convention. The Flutter test view supplied the full root viewport and insets. The harness mounted the actual Founder shell with its production theme, scroll behavior, sample account fixtures and bundled fonts. It measured rendered rectangles in the root coordinate system and moved the outer scroll position to its actual maximum before measuring the last item. It never contacted a backend.

Baseline ran before app edits. All 16 matrix tests passed across 80 tab roots and 76 additional route or content-state checks. The resting bar top was **848 / 840 / 603 / 595**. Its visible height was **50 / 58 / 50 / 58**. A dash means absent or no applicable pair. Positive numbers are space above the bar and a negative number indicates overlap or an item below the bar. The four slots remain in order even if a pair is absent. A slash without spaces separates measurements within one slot.

The final iOS matrix rechecked the original 156 checkpoints with the full 58 pt LOCK 6 V4 bar and measured 56 newly bar-visible quick-access checkpoints. It also verified 8 Guardian Basic tiles that open Membership. Final bar top was **840 / 840 / 595 / 595**. Each added route was entered through its real My ZYRA tile. The pre-V4 candidate was checked in a separate intermediate run and is excluded from the after column.

The last fixed surface or actual scroll endpoint measured 16 ± 1 pt in **74/80** primary tab-root checkpoints. The six other primary checkpoints were linked Guardian Seekers layouts with zero scroll extent. They retain the g10 helper position (QUESTIONS row 76). **10/56** quick-access checkpoints had actual vertical scroll extent and all ten ended 16 ± 1 pt above the bar. The other 46 quick-access layouts had short or centered content with no scroll extent (QUESTIONS row 79).

Every final checkpoint checked the actual render exception from the recorded frame. The fixed-card drag checks also recorded and asserted their separate result. No final render or drag exceptions were recorded.

## Rule A and Rule C

Fixed footprint and actual scroll-end item are listed separately where both matter. Zero scroll extent records a real rendered Scrollable that could not scroll farther. An inner viewport extent does not count as scrolling the page. Options and Network content could begin below the bar before the fix. The scroll-end line is the applicable comparison in those layouts. The Profile enclosing group includes the existing 1 pt border beyond the Sign out row. Decorative spacers, empty viewports, and hidden placeholders do not count as last items.

The original baseline capture recorded no render exceptions.

| Screen | Pair or geometry | Before | After | LOCK / master |
|---|---|---|---|---|
| Seeker One · Profiles | Fixed footprint at start · Request pill → bar | 20 / 12 / 36 / — | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Profiles | Actual last item at end · Request pill → bar | 20 / 12 / 36 / 28 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Profiles | Vertical scroll extents · outer first, inner next | 0/0 / 0/39 / 0/5 / 38/297 | 0/0 / 0/46 / 0/0 / 0/326 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Journey | Fixed footprint at start · Continue pill → bar | 14 / 6 / 34 / 26 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Journey | Actual last item at end · Continue pill → bar | 14 / 6 / 34 / 26 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Journey | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · My ZYRA | Actual last item at end · Notifications tile → bar | 16 / 8 / 36 / 28 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · My ZYRA | Vertical scroll extents · outer first, inner next | 0 / 270 / 79 / 496 | 0 / 0 / 0 / 125 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian | Fixed footprint at start · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian | Actual last item at end · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian | Vertical scroll extents · outer first, inner next | 0 / 207 / 109 / 679 | No vertical scroll / 68 / No vertical scroll / 360 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Profile | Actual last item at end · Sign out row → bar | 67 / 59 / 53 / 45 | 17 / 17 / 17 / 17 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Profile | Enclosing card at end · Sign out group → bar | 66 / 58 / 52 / 44 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Profile | Vertical scroll extents · outer first, inner next | 230 / 915 / 422 / 1244 | 139 / 764 / 363 / 1143 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Journey — empty | Actual last item at end · Browse profiles → bar | 246 / 145.5 / 153 / 42 | 243 / 150.5 / 140 / 22.5 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Journey — empty | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 29 | 0 / 0 / 0 / 0 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Profiles — full places | No separate screen (capacity 3 can browse) | — / — / — / — | — / — / — / — | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Journey options | Fixed footprint at start · Last options card → bar | 14 / — / — / — | 16 / — / — / — | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Journey options | Actual last item at end · Last options card → bar | 14 / 6 / 34 / 26 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Journey options | Vertical scroll extents · outer first, inner next | No vertical scroll / 170.8 / 122.6 / 459.8 | No vertical scroll / 180.8 / 112.6 / 449.8 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Profiles — no matches | Actual last item at end · Adjust filters → bar | 233.5 / 92.5 / 123.5 / 38 | 207.5 / 74.5 / 104.5 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Profiles — no matches | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 111 | 0 / 0 / 0 / 89 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian — Journey access | Fixed footprint at start · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian — Journey access | Actual last item at end · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian — Journey access | Vertical scroll extents · outer first, inner next | 0 / 480 / 113 / 1127 | No vertical scroll / 261 / No vertical scroll / 805 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian — invited | Fixed footprint at start · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian — invited | Actual last item at end · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian — invited | Vertical scroll extents · outer first, inner next | 0 / 247 / 109 / 719 | No vertical scroll / 0 / No vertical scroll / 238 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian — Add card | Fixed footprint at start · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian — Add card | Actual last item at end · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Guardian — Add card | Vertical scroll extents · outer first, inner next | 0 / 207 / 109 / 719 | No vertical scroll / 0 / No vertical scroll / 114 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker One · Quick · Seeker Journey requests | Actual last item at end → bar | — · tab bar absent | 246 / 33.5 / 143 / 16 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker One · Quick · Seeker Journey requests | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 171 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker One · Quick · Seeker Introductions | Actual last item at end → bar | — · tab bar absent | 267.5 / 154.5 / 164.5 / 16 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker One · Quick · Seeker Introductions | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 53 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker One · Quick · Seeker Ended Journeys | Actual last item at end → bar | — · tab bar absent | 267.5 / 136.5 / 164.5 / 33.5 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker One · Quick · Seeker Ended Journeys | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 0 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker One · Quick · Seeker Notifications | Actual last item at end → bar | — · tab bar absent | 556 / 213 / 296 / 16 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker One · Quick · Seeker Notifications | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 43 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker Basic · Profiles | Fixed footprint at start · Request pill → bar | 20 / 12 / 36 / — | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Profiles | Actual last item at end · Request pill → bar | 20 / 12 / 36 / 28 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Profiles | Vertical scroll extents · outer first, inner next | 0/0 / 0/39 / 0/5 / 38/297 | 0/0 / 0/46 / 0/0 / 0/326 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Journey | Fixed footprint at start · Plans card → bar | 14 / 6 / 34 / 26 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Journey | Actual last item at end · Plans card → bar | 14 / 6 / 34 / 26 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Journey | Vertical scroll extents · outer first, inner next | 0/5 / 0/98 / 0/15.6 / 115.4/108.6 | 0/0 / 0/98 / 0/0 / 106.4/108.6 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · My ZYRA | Actual last item at end · Notifications tile → bar | 16 / 8 / 36 / 28 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · My ZYRA | Vertical scroll extents · outer first, inner next | 0 / 270 / 31 / 496 | 0 / 0 / 0 / 125 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Guardian | Fixed footprint at start · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Guardian | Actual last item at end · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Guardian | Vertical scroll extents · outer first, inner next | 0 / 207 / 109 / 679 | No vertical scroll / 68 / No vertical scroll / 360 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Profile | Actual last item at end · Sign out row → bar | 67 / 59 / 53 / 45 | 17 / 17 / 17 / 17 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Profile | Enclosing card at end · Sign out group → bar | 66 / 58 / 52 / 44 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Profile | Vertical scroll extents · outer first, inner next | 230 / 879 / 422 / 1172 | 139 / 728 / 363 / 1071 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Journey — empty | Actual last item at end · Plans card → bar | 164.5 / 22 / 71.5 / 42 | 161.5 / 22.5 / 58.5 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Journey — empty | Vertical scroll extents · outer first, inner next | 0/0 / 9/0 / 0/0 / 285/0 | 0/0 / 0/0 / 0/0 / 243/0 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Profiles — full places | Actual last item at end · Continue / View Journeys → bar | 564 / 308 / 324 / 38 | 556 / 308 / 316 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Profiles — full places | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 88 | 0 / 0 / 0 / 66 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Journey options | Fixed footprint at start · Last options card → bar | 14 / — / — / — | 16 / — / — / — | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Journey options | Actual last item at end · Last options card → bar | 14 / 6 / 34 / 26 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Journey options | Vertical scroll extents · outer first, inner next | No vertical scroll / 170.8 / 122.6 / 459.8 | No vertical scroll / 180.8 / 112.6 / 449.8 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Profiles — no matches | Actual last item at end · Adjust filters → bar | 233.5 / 92.5 / 123.5 / 38 | 207.5 / 74.5 / 104.5 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Profiles — no matches | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 111 | 0 / 0 / 0 / 89 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Guardian — Journey access | Fixed footprint at start · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Guardian — Journey access | Actual last item at end · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Guardian — Journey access | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 227 | No vertical scroll / 0 / No vertical scroll / 213 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Guardian — Add card | Fixed footprint at start · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Guardian — Add card | Actual last item at end · Lowest Guardian pill → bar | 2 / -6 / 22 / 14 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Guardian — Add card | Vertical scroll extents · outer first, inner next | 0 / 207 / 109 / 719 | No vertical scroll / 0 / No vertical scroll / 114 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Journey requests | Actual last item at end → bar | — · tab bar absent | 246 / 33.5 / 143 / 16 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker Basic · Quick · Seeker Journey requests | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 171 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker Basic · Quick · Seeker Introductions | Actual last item at end → bar | — · tab bar absent | 267.5 / 154.5 / 164.5 / 16 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker Basic · Quick · Seeker Introductions | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 53 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker Basic · Quick · Seeker Ended Journeys | Actual last item at end → bar | — · tab bar absent | 267.5 / 136.5 / 164.5 / 33.5 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker Basic · Quick · Seeker Ended Journeys | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 0 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker Basic · Quick · Seeker Notifications | Actual last item at end → bar | — · tab bar absent | 556 / 213 / 296 / 16 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Seeker Basic · Quick · Seeker Notifications | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 43 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian One · Network | Fixed footprint at start · Bottom action row → bar | 11 / — / — / — | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Network | Actual last item at end · Bottom action row → bar | 11 / 107 / 135 / 127 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Network | Vertical scroll extents · outer first, inner next | No vertical scroll / 856 / 358 / 1042 | 0 / 81 / 0 / 288 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Journeys | Fixed footprint at start · Ended Journeys card → bar | 24 / 16 / 44 / 36 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Journeys | Actual last item at end · Ended Journeys card → bar | 24 / 16 / 44 / 36 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Journeys | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 315 | 0 / 0 / 0 / 296 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · My ZYRA | Actual last item at end · Notifications tile → bar | 16 / 8 / 36 / 28 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · My ZYRA | Vertical scroll extents · outer first, inner next | 0 / 527 / 179 / 887 | 0 / 0 / 0 / 247 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Seekers | Actual last item at end · Roster footer text → bar | 476 / 151 / 270 / 32 | 468 / 151 / 262 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Seekers | Last roster card at end → bar (footer follows) | 503 / 231 / 297 / 112 | 495 / 231 / 289 / 96 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Seekers | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 122 | 0 / 0 / 0 / 106 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Profile | Actual last item at end · Sign out row → bar | 67 / 59 / 53 / 45 | 17 / 17 / 17 / 17 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Profile | Enclosing card at end · Sign out group → bar | 66 / 58 / 52 / 44 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Profile | Vertical scroll extents · outer first, inner next | 132 / 741 / 324 / 1005 | 41 / 590 / 265 / 904 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Journeys — empty | Fixed footprint at start · Ended Journeys card → bar | 24 / 16 / 44 / 36 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Journeys — empty | Actual last item at end · Ended Journeys card → bar | 24 / 16 / 44 / 36 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Journeys — empty | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Network — unlinked | Actual last item at end · Invite your Seeker → bar | 646 / 530 / 440 / 280 | 638 / 530 / 432 / 280 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Network — unlinked | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Seekers — unlinked | Actual last item at end · Roster footer text → bar | 698 / 608 / 492 / 402 | 690 / 608 / 484 / 402 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Seekers — unlinked | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian One · Quick · Guardian Journey requests | Actual last item at end → bar | — · tab bar absent | 633 / 430 / 393 / 116 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian One · Quick · Guardian Journey requests | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 0 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian One · Quick · Guardian Connect with Guardian | Actual last item at end → bar | — · tab bar absent | 209 / 49 / 106 / 16 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian One · Quick · Guardian Connect with Guardian | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 207 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian One · Quick · Guardian Introductions | Actual last item at end → bar | — · tab bar absent | 238 / 104.5 / 118 / 16 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian One · Quick · Guardian Introductions | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 146 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian One · Quick · Guardian Notifications | Actual last item at end → bar | — · tab bar absent | 556 / 213 / 296 / 16 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian One · Quick · Guardian Notifications | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 43 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian Basic · Network | Fixed footprint at start · Bottom action row → bar | 11 / — / — / — | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Network | Actual last item at end · Bottom action row → bar | 11 / 107 / 135 / 127 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Network | Vertical scroll extents · outer first, inner next | No vertical scroll / 856 / 358 / 1042 | 0 / 81 / 0 / 288 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Journeys | Fixed footprint at start · Ended Journeys card → bar | 24 / 16 / 44 / 36 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Journeys | Actual last item at end · Ended Journeys card → bar | 24 / 16 / 44 / 36 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Journeys | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 315 | 0 / 0 / 0 / 296 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · My ZYRA | Actual last item at end · Notifications tile → bar | 16 / 8 / 36 / 28 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · My ZYRA | Vertical scroll extents · outer first, inner next | 0 / 550 / 158 / 941 | 0 / 34 / 0 / 335 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Seekers | Actual last item at end · Roster footer text → bar | 476 / 151 / 270 / 32 | 468 / 151 / 262 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Seekers | Last roster card at end → bar (footer follows) | 503 / 231 / 297 / 112 | 495 / 231 / 289 / 96 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Seekers | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 122 | 0 / 0 / 0 / 106 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Profile | Actual last item at end · Sign out row → bar | 67 / 59 / 53 / 45 | 17 / 17 / 17 / 17 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Profile | Enclosing card at end · Sign out group → bar | 66 / 58 / 52 / 44 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Profile | Vertical scroll extents · outer first, inner next | 132 / 741 / 324 / 1000 | 41 / 590 / 265 / 899 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Journeys — empty | Fixed footprint at start · Ended Journeys card → bar | 24 / 16 / 44 / 36 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Journeys — empty | Actual last item at end · Ended Journeys card → bar | 24 / 16 / 44 / 36 | 16 / 16 / 16 / 16 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Journeys — empty | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Network — unlinked | Actual last item at end · Invite your Seeker → bar | 646 / 530 / 440 / 280 | 638 / 530 / 432 / 280 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Network — unlinked | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Seekers — unlinked | Actual last item at end · Roster footer text → bar | 698 / 608 / 492 / 402 | 690 / 608 / 484 / 402 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Seekers — unlinked | Vertical scroll extents · outer first, inner next | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | LOCK 24 A/C · V145/146; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Journey requests | Actual last item at end → bar | — · tab bar absent | 633 / 430 / 393 / 116 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian Basic · Quick · Guardian Journey requests | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 0 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian Basic · Quick · Guardian Connect with Guardian | Actual last item at end → bar | — · tab bar absent | Guardian Basic opens Membership | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian Basic · Quick · Guardian Connect with Guardian | Vertical scroll extent | — · tab bar absent | — | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian Basic · Quick · Guardian Introductions | Actual last item at end → bar | — · tab bar absent | Guardian Basic opens Membership | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian Basic · Quick · Guardian Introductions | Vertical scroll extent | — · tab bar absent | — | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian Basic · Quick · Guardian Notifications | Actual last item at end → bar | — · tab bar absent | 556 / 213 / 296 / 16 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |
| Guardian Basic · Quick · Guardian Notifications | Vertical scroll extent | — · tab bar absent | 0 / 0 / 0 / 43 | LOCK 15 V5 · V156; LOCK 6 V4; LOCK 24 A |

## Rule B

Painted dots use the six-point dot render box. Slot means its 24 pt gesture and layout container. Page side margin uses a full-width surface or the keyed viewport. No number is reported when the chosen state has neither anchor. My ZYRA card-to-card refers to the four horizontal tiles. Profile card-to-card refers to the vertical groups, with the two one-point enclosing borders included in the calculation. The My ZYRA focus kicker belongs inside its focus content. The Guardian card uses its visible baseline viewport when the former scroll child extends beyond the frame. Journey access measures its internal heading to the first Journey tile and the gaps between visible tile slots, including placeholders.

| Screen | Pair or geometry | Before | After | LOCK / master |
|---|---|---|---|---|
| Seeker One · Profiles | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | Profiles details x01; Request Row |
| Seeker One · Profiles | Title → page dots (painted/slot) | 20/11 / 13/4 / 20/11 / 13/4 | 20/11 / 13/4 / 20/11 / 13/4 | Profiles details x01; Request Row |
| Seeker One · Profiles | Page dots → card (painted/slot) | 9/0 / 9/0 / 9/0 / 9/0 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B · Profiles x01; Journey j04; Guardian k01/k04 |
| Seeker One · Profiles | Card → bottom pill | 16 / 16 / 16 / 16 | 16 / 16 / 16 / 16 | Profiles details x01; Request Row |
| Seeker One · Profiles | Card → card | — / — / — / — | — / — / — / — | Profiles details x01; Request Row |
| Seeker One · Profiles | Section label → its card | — / — / — / — | — / — / — / — | Profiles details x01; Request Row |
| Seeker One · Journey | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 13 · j01/j04/j06 |
| Seeker One · Journey | Title → page dots (painted/slot) | 14.5/5.5 / 11/2 / 14.5/5.5 / 11/2 | 14.5/5.5 / 11/2 / 14.5/5.5 / 11/2 | LOCK 13 · j01/j04/j06 |
| Seeker One · Journey | Page dots → card (painted/slot) | 11/2 / 11/2 / 11/2 / 11/2 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B · Profiles x01; Journey j04; Guardian k01/k04 |
| Seeker One · Journey | Card → bottom pill | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 13 · j01/j04/j06 |
| Seeker One · Journey | Card → card | — / — / — / — | — / — / — / — | LOCK 13 · j01/j04/j06 |
| Seeker One · Journey | Section label → its card | — / — / — / — | — / — / — / — | LOCK 13 · j01/j04/j06 |
| Seeker One · My ZYRA | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 · m01/gm01 |
| Seeker One · My ZYRA | Title → page dots (painted/slot) | 21/12 / 21/12 / 21/12 / 21/12 | — / — / — / — | LOCK 15 · m01/gm01 |
| Seeker One · My ZYRA | Page dots → card (painted/slot) | 146/137 / 33/24 / 33/24 / 33/24 | — / — / — / — | LOCK 15 · m01/gm01 |
| Seeker One · My ZYRA | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 15 · m01/gm01 |
| Seeker One · My ZYRA | Card → card | 8/8/8 / 8/8/8 / 8/8/8 / 8/8/8 | 8/8/8 / 8/8/8 / 8/8/8 / 8/8/8 | LOCK 15 · m01/gm01 |
| Seeker One · My ZYRA | Section label → its card | Internal focus kicker / Internal focus kicker / Internal focus kicker / Internal focus kicker | — / — / — / — | LOCK 15 · m01/gm01 |
| Seeker One · Guardian | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 19 · k01/k04/k17/k19 |
| Seeker One · Guardian | Title → page dots (painted/slot) | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | LOCK 19 · k01/k04/k17/k19 |
| Seeker One · Guardian | Page dots → card (painted/slot) | 17/8 / 17/8 / 17/8 / 17/8 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B · Profiles x01; Journey j04; Guardian k01/k04 |
| Seeker One · Guardian | Card → bottom pill | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 19 · k01/k04/k17/k19 |
| Seeker One · Guardian | Card → card | — / — / — / — | — / — / — / — | LOCK 19 · k01/k04/k17/k19 |
| Seeker One · Guardian | Section label → its card | — / — / — / — | — / — / — / — | LOCK 19 · k01/k04/k17/k19 |
| Seeker One · Profile | Page side margin (left/right) | 22/22 / 22/22 / 22/22 / 22/22 | 22/22 / 22/22 / 22/22 / 22/22 | LOCK 21 · p02/p04/p05/p06 |
| Seeker One · Profile | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Seeker One · Profile | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Seeker One · Profile | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Seeker One · Profile | Card → card | 16/16/16 / 16/16/16 / 16/16/16 / 16/16/16 | 16/16/16 / 16/16/16 / 16/16/16 / 16/16/16 | LOCK 21 · p02/p04/p05/p06 |
| Seeker One · Profile | Section label → its card | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Seeker One · Journey — empty | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Seeker One · Journey — empty | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Journey — empty | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Journey — empty | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Journey — empty | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Journey — empty | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Profiles — full places | All pairs | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Journey options | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 13 |
| Seeker One · Journey options | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 13 |
| Seeker One · Journey options | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 13 |
| Seeker One · Journey options | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 13 |
| Seeker One · Journey options | Card → card | 14/14 / 14/14 / 14/14 / 14/14 | 14/14 / 14/14 / 14/14 / 14/14 | LOCK 13 |
| Seeker One · Journey options | Section label → its card | — / — / — / — | — / — / — / — | LOCK 13 |
| Seeker One · Profiles — no matches | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Seeker One · Profiles — no matches | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Profiles — no matches | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Profiles — no matches | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Profiles — no matches | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Profiles — no matches | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Guardian — Journey access | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Seeker One · Guardian — Journey access | Title → page dots (painted/slot) | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | LOCK 24 B |
| Seeker One · Guardian — Journey access | Page dots → card (painted/slot) | 17/8 / 17/8 / 17/8 / 17/8 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B |
| Seeker One · Guardian — Journey access | Card → bottom pill | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 24 B |
| Seeker One · Guardian — Journey access | Card → card | 8/8 / 8/8 / 8/8 / 8/8 | 8/8 / 8/8 / 8/8 / 8/8 | LOCK 24 B |
| Seeker One · Guardian — Journey access | Section label → its card | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 24 B |
| Seeker One · Guardian — invited | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Seeker One · Guardian — invited | Title → page dots (painted/slot) | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | LOCK 24 B |
| Seeker One · Guardian — invited | Page dots → card (painted/slot) | 17/8 / 17/8 / 17/8 / 17/8 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B |
| Seeker One · Guardian — invited | Card → bottom pill | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 24 B |
| Seeker One · Guardian — invited | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Guardian — invited | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Guardian — Add card | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Seeker One · Guardian — Add card | Title → page dots (painted/slot) | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | LOCK 24 B |
| Seeker One · Guardian — Add card | Page dots → card (painted/slot) | 17/8 / 17/8 / 17/8 / 17/8 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B |
| Seeker One · Guardian — Add card | Card → bottom pill | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 24 B |
| Seeker One · Guardian — Add card | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Guardian — Add card | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker One · Quick · Seeker Journey requests | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Journey requests | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Journey requests | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Journey requests | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Journey requests | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Journey requests | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Introductions | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Introductions | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Introductions | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Introductions | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Introductions | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Introductions | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Ended Journeys | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Ended Journeys | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Ended Journeys | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Ended Journeys | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Ended Journeys | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Ended Journeys | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Notifications | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Notifications | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Notifications | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Notifications | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Notifications | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker One · Quick · Seeker Notifications | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Profiles | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | Profiles details x01; Request Row |
| Seeker Basic · Profiles | Title → page dots (painted/slot) | 20/11 / 13/4 / 20/11 / 13/4 | 20/11 / 13/4 / 20/11 / 13/4 | Profiles details x01; Request Row |
| Seeker Basic · Profiles | Page dots → card (painted/slot) | 9/0 / 9/0 / 9/0 / 9/0 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B · Profiles x01; Journey j04; Guardian k01/k04 |
| Seeker Basic · Profiles | Card → bottom pill | 16 / 16 / 16 / 16 | 16 / 16 / 16 / 16 | Profiles details x01; Request Row |
| Seeker Basic · Profiles | Card → card | — / — / — / — | — / — / — / — | Profiles details x01; Request Row |
| Seeker Basic · Profiles | Section label → its card | — / — / — / — | — / — / — / — | Profiles details x01; Request Row |
| Seeker Basic · Journey | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 13 · j01/j04/j06 |
| Seeker Basic · Journey | Title → page dots (painted/slot) | 14.5/5.5 / 11/2 / 14.5/5.5 / 11/2 | 14.5/5.5 / 11/2 / 14.5/5.5 / 11/2 | LOCK 13 · j01/j04/j06 |
| Seeker Basic · Journey | Page dots → card (painted/slot) | 11/2 / 11/2 / 11/2 / 11/2 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B · Profiles x01; Journey j04; Guardian k01/k04 |
| Seeker Basic · Journey | Card → bottom pill | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 13 · j01/j04/j06 |
| Seeker Basic · Journey | Card → card | — / — / — / — | — / — / — / — | LOCK 13 · j01/j04/j06 |
| Seeker Basic · Journey | Section label → its card | — / — / — / — | — / — / — / — | LOCK 13 · j01/j04/j06 |
| Seeker Basic · My ZYRA | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 · m01/gm01 |
| Seeker Basic · My ZYRA | Title → page dots (painted/slot) | 21/12 / 21/12 / 21/12 / 21/12 | — / — / — / — | LOCK 15 · m01/gm01 |
| Seeker Basic · My ZYRA | Page dots → card (painted/slot) | 146/137 / 33/24 / 33/24 / 33/24 | — / — / — / — | LOCK 15 · m01/gm01 |
| Seeker Basic · My ZYRA | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 15 · m01/gm01 |
| Seeker Basic · My ZYRA | Card → card | 8/8/8 / 8/8/8 / 8/8/8 / 8/8/8 | 8/8/8 / 8/8/8 / 8/8/8 / 8/8/8 | LOCK 15 · m01/gm01 |
| Seeker Basic · My ZYRA | Section label → its card | Internal focus kicker / Internal focus kicker / Internal focus kicker / Internal focus kicker | — / — / — / — | LOCK 15 · m01/gm01 |
| Seeker Basic · Guardian | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 19 · k01/k04/k17/k19 |
| Seeker Basic · Guardian | Title → page dots (painted/slot) | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | LOCK 19 · k01/k04/k17/k19 |
| Seeker Basic · Guardian | Page dots → card (painted/slot) | 17/8 / 17/8 / 17/8 / 17/8 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B · Profiles x01; Journey j04; Guardian k01/k04 |
| Seeker Basic · Guardian | Card → bottom pill | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 19 · k01/k04/k17/k19 |
| Seeker Basic · Guardian | Card → card | — / — / — / — | — / — / — / — | LOCK 19 · k01/k04/k17/k19 |
| Seeker Basic · Guardian | Section label → its card | — / — / — / — | — / — / — / — | LOCK 19 · k01/k04/k17/k19 |
| Seeker Basic · Profile | Page side margin (left/right) | 22/22 / 22/22 / 22/22 / 22/22 | 22/22 / 22/22 / 22/22 / 22/22 | LOCK 21 · p02/p04/p05/p06 |
| Seeker Basic · Profile | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Seeker Basic · Profile | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Seeker Basic · Profile | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Seeker Basic · Profile | Card → card | 16/16/16 / 16/16/16 / 16/16/16 / 16/16/16 | 16/16/16 / 16/16/16 / 16/16/16 / 16/16/16 | LOCK 21 · p02/p04/p05/p06 |
| Seeker Basic · Profile | Section label → its card | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Seeker Basic · Journey — empty | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Seeker Basic · Journey — empty | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Journey — empty | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Journey — empty | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Journey — empty | Card → card | 14 / 14 / 14 / 14 | 14 / 14 / 14 / 14 | LOCK 24 B |
| Seeker Basic · Journey — empty | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Profiles — full places | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Seeker Basic · Profiles — full places | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Profiles — full places | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Profiles — full places | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Profiles — full places | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Profiles — full places | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Journey options | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 13 |
| Seeker Basic · Journey options | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 13 |
| Seeker Basic · Journey options | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 13 |
| Seeker Basic · Journey options | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 13 |
| Seeker Basic · Journey options | Card → card | 14/14 / 14/14 / 14/14 / 14/14 | 14/14 / 14/14 / 14/14 / 14/14 | LOCK 13 |
| Seeker Basic · Journey options | Section label → its card | — / — / — / — | — / — / — / — | LOCK 13 |
| Seeker Basic · Profiles — no matches | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Seeker Basic · Profiles — no matches | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Profiles — no matches | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Profiles — no matches | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Profiles — no matches | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Profiles — no matches | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Guardian — Journey access | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Seeker Basic · Guardian — Journey access | Title → page dots (painted/slot) | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | LOCK 24 B |
| Seeker Basic · Guardian — Journey access | Page dots → card (painted/slot) | 17/8 / 17/8 / 17/8 / 17/8 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B |
| Seeker Basic · Guardian — Journey access | Card → bottom pill | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 24 B |
| Seeker Basic · Guardian — Journey access | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Guardian — Journey access | Section label → its card | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 24 B |
| Seeker Basic · Guardian — Add card | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Seeker Basic · Guardian — Add card | Title → page dots (painted/slot) | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | 9.5/0.5 / 9/0 / 9.5/0.5 / 55/46 | LOCK 24 B |
| Seeker Basic · Guardian — Add card | Page dots → card (painted/slot) | 17/8 / 17/8 / 17/8 / 17/8 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B |
| Seeker Basic · Guardian — Add card | Card → bottom pill | 12 / 12 / 12 / 12 | 12 / 12 / 12 / 12 | LOCK 24 B |
| Seeker Basic · Guardian — Add card | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Guardian — Add card | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Seeker Basic · Quick · Seeker Journey requests | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Journey requests | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Journey requests | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Journey requests | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Journey requests | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Journey requests | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Introductions | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Introductions | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Introductions | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Introductions | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Introductions | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Introductions | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Ended Journeys | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Ended Journeys | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Ended Journeys | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Ended Journeys | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Ended Journeys | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Ended Journeys | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Notifications | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Notifications | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Notifications | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Notifications | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Notifications | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Seeker Basic · Quick · Seeker Notifications | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Network | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 8 · g06 |
| Guardian One · Network | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 8 · g06 |
| Guardian One · Network | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 8 · g06 |
| Guardian One · Network | Card → bottom pill | 14 / 15.5 / 23 / 14 | 14 / 15.5 / 23 / 14 | LOCK 8 · g06 |
| Guardian One · Network | Card → card | — / — / — / — | — / — / — / — | LOCK 8 · g06 |
| Guardian One · Network | Section label → its card | — / — / — / — | — / — / — / — | LOCK 8 · g06 |
| Guardian One · Journeys | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 8 · g09/g09b/g09c |
| Guardian One · Journeys | Title → page dots (painted/slot) | 15/6 / 78/69 / 60/51 / 78/69 | 15/6 / 78/69 / 60/51 / 78/69 | LOCK 8 · g09/g09b/g09c |
| Guardian One · Journeys | Page dots → card (painted/slot) | 11/2 / 11/2 / 11/2 / 11/2 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B · Profiles x01; Journey j04; Guardian k01/k04 |
| Guardian One · Journeys | Card → bottom pill | 10 / 10 / 10 / 10 | 10 / 10 / 10 / 10 | LOCK 8 · g09/g09b/g09c |
| Guardian One · Journeys | Card → card | 10 / 10 / 10 / 10 | 10 / 10 / 10 / 10 | LOCK 8 · g09/g09b/g09c |
| Guardian One · Journeys | Section label → its card | — / — / — / — | — / — / — / — | LOCK 8 · g09/g09b/g09c |
| Guardian One · My ZYRA | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 · m01/gm01 |
| Guardian One · My ZYRA | Title → page dots (painted/slot) | 53/44 / 107/98 / 71/62 / 143/134 | — / — / — / — | LOCK 15 · m01/gm01 |
| Guardian One · My ZYRA | Page dots → card (painted/slot) | 96.5/87.5 / 33/24 / 33/24 / 33/24 | — / — / — / — | LOCK 15 · m01/gm01 |
| Guardian One · My ZYRA | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 15 · m01/gm01 |
| Guardian One · My ZYRA | Card → card | 8/8/8 / 8/8/8 / 8/8/8 / 8/8/8 | 8/8/8 / 8/8/8 / 8/8/8 / 8/8/8 | LOCK 15 · m01/gm01 |
| Guardian One · My ZYRA | Section label → its card | Internal focus kicker / Internal focus kicker / Internal focus kicker / Internal focus kicker | — / — / — / — | LOCK 15 · m01/gm01 |
| Guardian One · Seekers | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 8 · g10 |
| Guardian One · Seekers | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 8 · g10 |
| Guardian One · Seekers | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 8 · g10 |
| Guardian One · Seekers | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 8 · g10 |
| Guardian One · Seekers | Card → card | 10 / 10 / 10 / 10 | 10 / 10 / 10 / 10 | LOCK 8 · g10 |
| Guardian One · Seekers | Section label → its card | — / — / — / — | — / — / — / — | LOCK 8 · g10 |
| Guardian One · Profile | Page side margin (left/right) | 22/22 / 22/22 / 22/22 / 22/22 | 22/22 / 22/22 / 22/22 / 22/22 | LOCK 21 · p02/p04/p05/p06 |
| Guardian One · Profile | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Guardian One · Profile | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Guardian One · Profile | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Guardian One · Profile | Card → card | 16/16/16 / 16/16/16 / 16/16/16 / 16/16/16 | 16/16/16 / 16/16/16 / 16/16/16 / 16/16/16 | LOCK 21 · p02/p04/p05/p06 |
| Guardian One · Profile | Section label → its card | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Guardian One · Journeys — empty | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Guardian One · Journeys — empty | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Journeys — empty | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Journeys — empty | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Journeys — empty | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Journeys — empty | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Network — unlinked | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Guardian One · Network — unlinked | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Network — unlinked | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Network — unlinked | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Network — unlinked | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Network — unlinked | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Seekers — unlinked | Page side margin (left/right) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Seekers — unlinked | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Seekers — unlinked | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Seekers — unlinked | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Seekers — unlinked | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Seekers — unlinked | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian One · Quick · Guardian Journey requests | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Journey requests | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Journey requests | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Journey requests | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Journey requests | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Journey requests | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Connect with Guardian | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Connect with Guardian | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Connect with Guardian | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Connect with Guardian | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Connect with Guardian | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Connect with Guardian | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Introductions | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Introductions | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Introductions | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Introductions | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Introductions | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Introductions | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Notifications | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Notifications | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Notifications | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Notifications | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Notifications | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian One · Quick · Guardian Notifications | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Network | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 8 · g06 |
| Guardian Basic · Network | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 8 · g06 |
| Guardian Basic · Network | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 8 · g06 |
| Guardian Basic · Network | Card → bottom pill | 14 / 15.5 / 23 / 14 | 14 / 15.5 / 23 / 14 | LOCK 8 · g06 |
| Guardian Basic · Network | Card → card | — / — / — / — | — / — / — / — | LOCK 8 · g06 |
| Guardian Basic · Network | Section label → its card | — / — / — / — | — / — / — / — | LOCK 8 · g06 |
| Guardian Basic · Journeys | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 8 · g09/g09b/g09c |
| Guardian Basic · Journeys | Title → page dots (painted/slot) | 15/6 / 78/69 / 60/51 / 78/69 | 15/6 / 78/69 / 60/51 / 78/69 | LOCK 8 · g09/g09b/g09c |
| Guardian Basic · Journeys | Page dots → card (painted/slot) | 11/2 / 11/2 / 11/2 / 11/2 | 12/3 / 12/3 / 12/3 / 12/3 | LOCK 24 B · Profiles x01; Journey j04; Guardian k01/k04 |
| Guardian Basic · Journeys | Card → bottom pill | 10 / 10 / 10 / 10 | 10 / 10 / 10 / 10 | LOCK 8 · g09/g09b/g09c |
| Guardian Basic · Journeys | Card → card | 10 / 10 / 10 / 10 | 10 / 10 / 10 / 10 | LOCK 8 · g09/g09b/g09c |
| Guardian Basic · Journeys | Section label → its card | — / — / — / — | — / — / — / — | LOCK 8 · g09/g09b/g09c |
| Guardian Basic · My ZYRA | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 · m01/gm01 |
| Guardian Basic · My ZYRA | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 15 · m01/gm01 |
| Guardian Basic · My ZYRA | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 15 · m01/gm01 |
| Guardian Basic · My ZYRA | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 15 · m01/gm01 |
| Guardian Basic · My ZYRA | Card → card | 8/8/8 / 8/8/8 / 8/8/8 / 8/8/8 | 8/8/8 / 8/8/8 / 8/8/8 / 8/8/8 | LOCK 15 · m01/gm01 |
| Guardian Basic · My ZYRA | Section label → its card | Internal focus kicker / Internal focus kicker / Internal focus kicker / Internal focus kicker | — / — / — / — | LOCK 15 · m01/gm01 |
| Guardian Basic · Seekers | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 8 · g10 |
| Guardian Basic · Seekers | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 8 · g10 |
| Guardian Basic · Seekers | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 8 · g10 |
| Guardian Basic · Seekers | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 8 · g10 |
| Guardian Basic · Seekers | Card → card | 10 / 10 / 10 / 10 | 10 / 10 / 10 / 10 | LOCK 8 · g10 |
| Guardian Basic · Seekers | Section label → its card | — / — / — / — | — / — / — / — | LOCK 8 · g10 |
| Guardian Basic · Profile | Page side margin (left/right) | 22/22 / 22/22 / 22/22 / 22/22 | 22/22 / 22/22 / 22/22 / 22/22 | LOCK 21 · p02/p04/p05/p06 |
| Guardian Basic · Profile | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Guardian Basic · Profile | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Guardian Basic · Profile | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Guardian Basic · Profile | Card → card | 16/16/16 / 16/16/16 / 16/16/16 / 16/16/16 | 16/16/16 / 16/16/16 / 16/16/16 / 16/16/16 | LOCK 21 · p02/p04/p05/p06 |
| Guardian Basic · Profile | Section label → its card | — / — / — / — | — / — / — / — | LOCK 21 · p02/p04/p05/p06 |
| Guardian Basic · Journeys — empty | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Guardian Basic · Journeys — empty | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Journeys — empty | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Journeys — empty | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Journeys — empty | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Journeys — empty | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Network — unlinked | Page side margin (left/right) | 20/20 / 20/20 / 20/20 / 20/20 | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 24 B |
| Guardian Basic · Network — unlinked | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Network — unlinked | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Network — unlinked | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Network — unlinked | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Network — unlinked | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Seekers — unlinked | Page side margin (left/right) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Seekers — unlinked | Title → page dots (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Seekers — unlinked | Page dots → card (painted/slot) | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Seekers — unlinked | Card → bottom pill | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Seekers — unlinked | Card → card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Seekers — unlinked | Section label → its card | — / — / — / — | — / — / — / — | LOCK 24 B |
| Guardian Basic · Quick · Guardian Journey requests | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Journey requests | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Journey requests | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Journey requests | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Journey requests | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Journey requests | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Connect with Guardian | Page side margin (left/right) | — · tab bar absent | Guardian Basic opens Membership | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Introductions | Page side margin (left/right) | — · tab bar absent | Guardian Basic opens Membership | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Notifications | Page side margin (left/right) | — · tab bar absent | 20/20 / 20/20 / 20/20 / 20/20 | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Notifications | Title → page dots (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Notifications | Page dots → card (painted/slot) | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Notifications | Card → bottom pill | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Notifications | Card → card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |
| Guardian Basic · Quick · Guardian Notifications | Section label → its card | — · tab bar absent | — / — / — / — | LOCK 15 V5 · V156; LOCK 6 V4 |

## Boundaries and open decisions

- The independent Profiles details x01, Journey j04, and Guardian k01/k04 layouts each show 12 pt from painted dots to the card. The Request Row master corroborates Profiles. The centered 6 pt mark in the 24 pt dot slot leaves 9 pt after the mark, so a 3 pt slot-to-card gap gives the approved 12 pt.
- Title-to-dot master samples show approximately 22–23 pt for Guardian, Page Dots and My ZYRA and 27–28 pt for Profiles and Journey. No exact approved scale value has a clear majority, and ink edges differ from text layout bounds.
- The side margin masters show approximately 21–22 pt at the outer raster edge. The locked scale offers 16 or 24 pt near those values, with no clear exact majority.
- Card-to-pill samples differ. Guardian k01/k04 show 12 pt, Profiles x01 and Request Row 14 pt, and Journey j04 22 pt. Centered empty states and card gaps need separate decisions where the masters do not agree.
- My ZYRA focus content is centered in an expanded region at default size. Its dot-to-content measurement does not identify an adjacent card like Profiles, Journey, or Guardian. The after fixture no longer plants attention on launch, so absent My ZYRA dots reflect the real number of available focus items.
- Journey options was reached by tapping the real Journey options control. Seeker One can browse with all three places full. Seeker Basic has a separate stop state.
- The planned app is the Founder preview under ZYRA AGENTS.md and DR-ZYRA-274. Legacy HomeShell and WaliHomeShell instantiate shared floating navigation for the ordinary live member app. The local fixtures do not authorize a live role account. The legacy own-profile preview paints an inert copy of the bar under IgnorePointer, ExcludeSemantics and ExcludeFocus. The Browse safety action bar replaces the tab destinations while its action menu is open.
- The LOCK 24 spec names V146 and its LOCK record names V145 for the same Founder selection. There are no dedicated spacing masters. The audit uses the current locked rule and the existing screen masters.
