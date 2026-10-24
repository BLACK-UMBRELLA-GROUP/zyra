# ZYRA Settings visual study — current as-built handover V1

**Status:** CODE BUILT / POST-VERIFIED LOCALLY / FOUNDER VISUAL ACCEPTANCE PENDING  
**Date:** 2026-10-02  
**Authority:** Founder direct request to compare the linked DailyFlutterUI Settings design in the developer toggle; OA-ZYRA-286 one-main-app local-preview boundary.  
**Scope:** Visual comparison only. This record does not approve public adoption of the candidate style.

## What is built

The protected Developer Control Home panel now offers **Settings design → Current / Smooth cards** and **Open Settings**. The choice is in-memory and defaults to Current. Smooth cards adapts the referenced video's rounded grouped surfaces, icon-led rows and gentle entrance to ZYRA purple/gold, while retaining the real Settings information architecture and Seeker/Guardian routes. It does not add dark mode, theme colour, language, text-size controls or a staged-save/review workflow from the video; those are not approved ZYRA capabilities.

The picker is visible only under the exact main-app Founder preview authorization. The alternative layout is read only by `SettingsScreen` while that authorization remains valid; ordinary members/default builds always render Current. The visual choice does not write profile, account or preference data. **Existing Settings actions are still live when opened**; this is a style comparison, not a safe sandbox for changing real account settings. Seeker and Guardian content continues to be derived from their existing state. The current design is preserved as the default.

## Entry points and state

- `SOURCE/lib/dev/dev_settings_design_state.dart`: local `ZyraSettingsDesign` selection; no persistence.
- `SOURCE/lib/dev/dev_settings_design.dart`: guarded Home picker and Open Settings action.
- `SOURCE/lib/dev/zyra_dev_control_system.dart`: mounts the new picker in shared Developer Control Home.
- `SOURCE/lib/dev/wali_dev_scenario_panel.dart`: passes Guardian role to the shared picker; Seeker/global entry uses Seeker default.
- `SOURCE/lib/screens/settings/settings_screen.dart`: existing Settings routes remain intact; only the protected candidate's layout, icon treatment and entrance differ. Candidate summary values wrap/ellipsize on compact screens. Reduced-motion preference disables entrance motion.
- `SOURCE/test/dev_settings_design_test.dart`: comparison, Guardian content, unauthorized fallback and compact/large-text coverage.

No schema, migration, RPC, backend, entitlement, purchase, credit, Auth provider, native icon or app identity changed. No external TikTok asset or package was copied into ZYRA. The reference informed layout/motion only.

## Verification and delivery

- Focused Settings study: **4/4 PASS** (`flutter test --no-pub test/dev_settings_design_test.dart`), including Seeker and Guardian content.
- Scoped analyzer: **PASS, no issues** across the five affected source files.
- Wider `zyra_developer_access_test.dart`: **12 PASS / 3 FAIL**. The three failing assertions are the already-recorded stale onboarding-route expectations under OA-ZYRA-286, not Settings assertions; no full-suite PASS is claimed.
- Signed iOS PROFILE build for `app.zyraconnect.zyra`: **PASS**; strict/deep codesign verification **PASS**. Final built Runner executable SHA-256 `699ea83bac0b805c714ffeddf2892f9d487c9093209a4d4f504d1051060b9902`.
- Explicit final local install to paired iPhone `00008130-001A2C1E26F8001C`: **PASS**, container `1876978F-7CE5-42B9-9B4C-4F16DAEB3B67`. Native launch: **PASS**. This does not prove Founder visual acceptance or a TestFlight upload.

## Remaining gates and handback

1. Founder reviews both Settings styles on device and selects whether Smooth cards should be refined or adopted. Until then Current remains the ordinary-user default.
2. If adopted, review design across the actual Seeker and Guardian accounts and accessibility settings before removing the protected comparison. Do not infer approval for the video's unsupported appearance/language controls or staged save workflow.
3. OA-ZYRA-286 continues to own the broader one-app Founder-preview boundary and three stale Developer Access onboarding assertions. No new OA is needed for this scoped study; no OA is closed by local delivery.

No Git command, production migration, live backend mutation, real credit/purchase, TestFlight upload or public activation was performed.
