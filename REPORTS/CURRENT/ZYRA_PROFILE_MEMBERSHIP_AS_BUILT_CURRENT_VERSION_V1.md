---
id: ASBUILT-ZYRA-LINE119
type: HANDOVER
status: CURRENT
feature: PROFILE AND MEMBERSHIP
purpose: As-built record of the Founder-requested Profile, Membership and Guardian visual fixes in queue line 119
links: [AD-AIOS-115, AD-AIOS-149, OA-ZYRA-317, DOC-ZYRA-0419]
owner: Codex
---

# Profile and Membership fixes — as built

Line 119 implements the 18 November Founder comments recorded in
`PRODUCT/APPROVED/PROFILE_TAB/BRIEFS/FIX_BRIEF_2026-11-18_MEMBERSHIP_ROW.md`,
items 1, 2 and 2b–2g. These are fixes to the existing Founder preview. Live: no.

Profile keeps LOCK 21 V5's header, groups, one-line rows, short-screen scrolling
and navigation. Both roles show Membership with their plan on the right; a
Guardian's funded Family place shows its existing payer. Your places opens the
same subscriptions page. Basic's existing comparison destination is retained.

Membership exposes Current, Seeker, Guardian and ZYRA Family. The old Unlocks
section is no longer offered. An older in-memory draft naming that section
restores to Current, retaining its plan choices. Compatibility Unlocks remains
reachable from Profile and keeps its separate store and Terms flow. Current
places its existing management content at the bottom, with 20 pt side margins
and 16 pt before the bottom safe area. Longer content scrolls; the cancellation
card, wording, App Store action and action guards are unchanged.

Guardian Basic's Network uses the full available page with the brief's 102 pt
lock circle, the three prototype explanations and the existing membership
action. It uses a Seeker's name only for one linked Seeker; otherwise it uses
the approved plural wording. Guardian One's existing Network is retained.
Both roles use the existing Seeker navigation icon list and shared rendering.
The two locked Guardian My ZYRA tiles place an 18 pt badge at the icon's bottom
right and keep Guardian One on one status line in the shared status style.

## Files and ownership

| File under SOURCE/lib/ | Job |
|---|---|
| `dev/zyra_one_journey_account_presentation.dart` | Profile labels and plan value; existing cancellation card |
| `widgets/zyra_membership_choices.dart` | Four tabs, legacy draft fallback and bottom-aligned Current content |
| `screens/subscription/upgrade_screen.dart` | Removes the ordinary Membership page's inline store slot |
| `dev/zyra_one_journey_concept_shell.dart` | Shared nav icons, sample linked names and existing route ownership |
| `dev/zyra_one_journey_guardian_tabs.dart` | Basic Network gate |
| `widgets/zyra_focus_dashboard.dart` | Locked tile badge and status layout |

The shell still owns role, verified preview admission, plan, Family payer,
local wallet and route revisions. Presentation callbacks retain their existing
owner/epoch guards. The new name list projects the same Adam/Yusuf sample
roster already shown in Profile. It introduces no persisted data, developer
control, payment flow, entitlement grant or server call. Migrations: none.

## Evidence and verification

The reference is the brief's exact Founder comments, existing LOCK 21 V5 and
the preserved V245 prototype containing the V235–V243 changes. Later prototype
changes were excluded. The brief expressly specifies a 102 pt circle; V245's
content-box CSS measures 88 pt. The implementation follows the explicit brief.

`PRODUCT/APPROVED/PROFILE_TAB/BUILT/LINE119/BUILD.json` identifies tested source
hashes, toolchain and local screenshots. `LINE119_CHECKS.json` records scoped
tests, full-suite results, analysis, public review and remaining observations.
Eight real-font 430 × 932 frames are under
`REPORTS/EVIDENCE/LINE119_2026-11-18/BUILT/`, including all four Profile states,
both One Current pages, Guardian Basic Network and My ZYRA. Comparison evidence
is beside them. Screenshots are local ignored evidence, never test approval.

Focused tests cover unchanged destinations and guards, four-tab selection,
bottom alignment, Family payer, names for zero/one/multiple Seekers, the badge,
shared icons, short screens and Larger Text. Existing spacing and still-page
checks retain paid Network behavior. No phone build, installation or device
observation was performed. Line 117 owns delivery on the applicable Founder GO;
ZYRA Claude and the Founder own visual acceptance. Live integration remains
OA-ZYRA-317. Existing unrelated archive-route inventory gaps remain with their
existing actions, including OA-ZYRA-388; this task changes no archive route.

Final verification: 265 scoped cases passed across the final runs. The full
offline-ci run passed 7,349 and skipped 122; its initial shader-asset failure
and four stale headline assertions all passed in the final-source 56-case
retry. There are 7,354 distinct passing cases after those retries and zero
unresolved failures. Full analysis and formatting passed.
