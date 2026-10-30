---
id: AS-BUILT-ZYRA-LOCK6-V2
type: HANDOVER
status: CURRENT
feature: NAVIGATION
purpose: As-built handover for queue 32, LOCK6 V2 idle navigation across the planned app
links: [DR-ZYRA-304, DR-ZYRA-276, AD-AIOS-115, OA-ZYRA-316, OA-ZYRA-317, OA-ZYRA-325]
owner: Codex
---

# Tab bar — as built, 30 October 2026

Queue 32 completes LOCK6 V2 for the local Founder preview. Fable verification and Founder acceptance remain separate. Ordinary members retain their old app and sign-in until OA-ZYRA-317. No service, migration, native build, phone installation or upload changed.

## Authority and live files

Built from `PRODUCT/APPROVED/TAB_BAR/BRIEFS/BUILD_BRIEF_2026-10-30.md`, `RECORD/LOCK_RECORD.md`, `RECORD/TAB_BAR_SPEC_CURRENT_VERSION_V2.md` and all four `MASTERS/` PNGs. The Founder locked “60%” on 30 October. V1 inputs remain in the feature's existing `ARCHIVE/`; the five previous built artifacts moved unchanged into `BUILT/ARCHIVE_V1/`.

`SOURCE/lib/dev/zyra_one_journey_concept_shell.dart` sets the existing `compactV2` flag true at the sole planned-root navigation call. This includes all five roots in both roles. Its only source change is that flag; no second switch or role-specific renderer was added. `SOURCE/lib/widgets/floating_nav_bar.dart` keeps the existing V2 size interpolation and adds the masters' six-point idle gaps between 38-point slots. Gaps close during expansion and the existing full endpoint remains identical. Its complete legacy renderer prefix is byte-identical to the starting commit.

At 430 × 932 the idle surface is 234 × 50, centered at x98; icons are 18, slot centers 127/171/215/259/303 and underline 28. The full bar remains 390 × 58 with 21-point icons and 24-point underline. The first physical gesture expands only, including held scrubs/cancellation. Subsequent full-bar gestures select; release starts the three-second deadline and page scrolling collapses. VoiceOver/Switch Control/Larger Text retain full targets. Native and MediaQuery Reduce Motion settle instantly, including mid-transition changes. LOCK5 attention clearing and caller-owned activity remain.

The shared widget owns transient animation, timer, pointer and semantics epochs. The shell retains route, role, admission, callback and activity authority. Nothing new is persisted. The Code page's local aliases/camera/actor guards, Guardian five-tab/Network boundary, palettes, glyphs, page bodies, Profiles action bar, ordinary member navigation and action callbacks are unchanged.

## Measured validation and comparisons

Eleven final focused suites pass 165 tests: compact LOCK6; LOCK6 actual-root/capture; Browse options; Browse edge; shared navigation haptics; confirmation layout; tab-open attention; attention model; attention shell; local LOCK9 Code page; LOCK8 Guardian behavior/captures. Four actual-shell cases cover all 20 Basic/One role/root combinations. Two iOS cases render four 1290 × 2796 PNGs into `TAB_BAR/BUILT/`, beside the masters and `master_beside_build.png`. The analyzer reports no issues. Exact wrapper commands and filters are in daily Task 16.

Comparison scope is explicit: all idle centers/slots match the masters. The actual safe area keeps idle y848 versus master y859. Inherited full-state centers are 59.8/137.4/215/292.6/370.2 versus prototype 67/141/215/289/363; full underline 24 versus drawn 34. Existing glyphs, page typography/photo/pill metrics and rounded prototype phone edges differ. Both complete full-state PNG hashes are unchanged by the idle-gap correction. Written refusal: global position, full geometry, glyph or body redesign exceeds row32; OA-ZYRA-325 remains with the designer/Fable.

Twenty-nine original test failures were reproduced against exact starting 96969b: six old three-pill Browse fixtures, 22 legacy dot/haptic cases and one old four-tab Guardian fixture. Current affected fixtures now use LOCK7 geometry and Guardian five-tab attention; six Browse cases still stop at inherited held-Hide behavior and remain excluded, alongside the two previously proven held-cue cases. The 22 legacy cases are outside the passing scope. Tasks 14/15's other inherited failures are not rerun or counted as passing. No tests were deleted. Unrelated production repairs are refused under OA-ZYRA-316.

Local evidence in `REPORTS/EVIDENCE/LOCK6_TAB_BAR_2026-10-30/` contains JSON/BUILD.json only, including exact baseline restoration hashes, comparisons and archive inventory. No source copy or compiled app is evidence. A scoped fresh-ledger UI gate, excluding config files, reports PASS-WITH-FINDINGS (0 critical/high); its advisory findings remain OA-ZYRA-257 and are not a claim of a clean whole-app audit. Next owners: Fable verifies, the design chat compares, and the Founder accepts. Real member adoption remains OA-ZYRA-317.
