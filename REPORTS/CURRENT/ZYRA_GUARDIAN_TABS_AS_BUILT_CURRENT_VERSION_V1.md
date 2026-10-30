---
id: AS-BUILT-ZYRA-LOCK8
type: HANDOVER
status: CURRENT
feature: GUARDIANS
purpose: As-built handover for queue 29, Guardian tabs LOCK 8 V2, local Founder preview
links: [DR-ZYRA-306, DR-ZYRA-280, DR-ZYRA-292, DR-ZYRA-233, OA-ZYRA-325, OA-ZYRA-317, OA-ZYRA-316]
owner: Codex
---

# Guardian tabs — as built, 30 October 2026

Queue 29 implements LOCK 8 V2 in the protected Founder preview. This is a builder's record; Fable's verification and the Founder's acceptance remain separate. Ordinary members still use the old app and sign-in. There was no phone build, install, upload or server change.

## Built from

- `PRODUCT/APPROVED/GUARDIAN_TABS/BRIEFS/BUILD_BRIEF_2026-10-30_V2.md`.
- `PRODUCT/APPROVED/GUARDIAN_TABS/RECORD/GUARDIAN_TABS_SPEC_CURRENT_VERSION_V2.md`, its `LOCK_RECORD.md`, and all twenty actual `MASTERS/g01–g20` pictures, each 1290 × 2796 (430 × 932 at 3×).
- Current LOCK 5 and LOCK 6 V2. The Guardian roots opt into 234 × 50 idle navigation, 18-point icons and a 28-point idle underline. The shared Seeker default stays at the earlier size for separate queue 32. Network stops at its first/last cards and uses the locked disabled/gold arrow states; it never wraps. First touch expands only; full-bar navigation, three-second/scroll collapse and accessibility behavior are retained.

## What exists

Guardian opens on My ZYRA in the order Network, Journeys, My ZYRA, Seekers, Profile. The old Guardian Dashboard, Insights (including its Basic locked card), Updates card and old Network request sections have been removed from this preview. The original presenter was moved to `/Users/shakeelahmad/_to_delete/ZYRA_LOCK8_GUARDIAN_TABS_2026-10-30/`, with its obsolete test cases. The old member app is retained under OA-ZYRA-317.

The sample is Hassan, Main for Adam and Additional for Yusuf. My ZYRA combines the open Adam/Sara Family Review and the pending connection. Pause stops the local review; Reopen gives a fresh displayed 48 hours; Continue displays Building a Life. The stage agrees on Journeys, Seekers and Adam's detail. These operations never call `advanceStage`, a timer, an RPC or a transport.

Journey requests are Main-only and read only, with All Seekers / Adam / Yusuf switching. Network introduces the selected family to the selected Seeker and records the Guardian's own sent connections. Basic-only families are filtered before selection. Introductions are keyed by both Seeker and family. Connect has Sent/Received, accepted/Open chat and dismissed/empty states. Not now records “Not taken up”. The accepted chat is private local presentation: Send shows “Messages send in the app.” Long-press its privacy notice opens the existing report/block presentation; blocking removes only this local connection. No Seeker receives that chat.

Existing Journey, Guardian Circle, account and invite presentations remain in use. The Journey summary receives the approved Adam/Sara sample when the separate Seeker walkthrough is empty. Yusuf's Circle uses Yusuf's local identity, Hassan's Additional role and no Adam contexts, readers or past summaries. The existing local invite handoff remains held and sends nothing. Ended Journeys respects the existing sharing boundary and does not fabricate shared history; server wiring remains OA-ZYRA-317. Guardian Basic differences beyond the brief's removal of Insights remain outside this LOCK.

## Live files and ownership

| File in SOURCE | Job |
|---|---|
| `lib/dev/zyra_one_journey_guardian_tabs.dart` | Local review/connection snapshots, seeded candidates, all new page presentations and private chat adapter |
| `lib/dev/zyra_one_journey_concept_shell.dart` | Owns the local state, route/action dispatch, actual Main/link/paid checks, snapshot publication and existing page adapters |
| `lib/dev/zyra_preview_navigation_checkpoint.dart` | Carries the bounded local Guardian snapshot; long app returns preserve decisions while returning to My ZYRA |
| `lib/widgets/zyra_shell_navigation.dart`, `lib/widgets/floating_nav_bar.dart` | Guardian-only LOCK 6 V2 opt-in; existing callers retain defaults |
| `lib/screens/wali/family_messaging_screens.dart`, `lib/dev/zyra_circle_send_button_presentation.dart` | Reused composer/send component, with explicit private-chat presentation parameters; Circle defaults retained |
| `test/visual/lock8_guardian_tabs_capture_test.dart` | Twenty captures, state transitions, count consistency, Main/Additional/revocation, stale callbacks, Circle isolation, tap geometry and 200% compact layout |
| `test/visual/baseline_capture_support.dart` | Optional exact basename for g13; retains the actual app theme, bundled fonts/photos, iOS safe area and network denial |
| Mixed route/title/monthly/resume/Circle/haptic tests | Updated entry fixtures for the five roots; unrelated behavior coverage retained |

The shell's fresh owner admits every action. Navigation, role, UI revision, controls and route epochs revoke retained handlers. Actual Main authority gates reviews and received Adam data; loss of the link/Main/paid state denies private chat and report actions. No callbacks, drafts, messages, photos, credentials or grants are stored in the new snapshot. It is memory-only sample state, and never proves real access.

## Evidence and comparison

`PRODUCT/APPROVED/GUARDIAN_TABS/BUILT/` contains the twenty matching g01–g20 basenames and `MASTER_BESIDE_BUILD.png` (Network master on the left). `REPORTS/EVIDENCE/LOCK8_GUARDIAN_TABS_2026-10-30/` contains JSON, including BUILD.json with the source commit, Flutter version, target/mode and timestamp. No compiled output or source copy is evidence.

All twenty pictures are actual full-phone widget renders, not redraws. Network's white action labels, bold initial, ring clearance and separation from the navigation are checked. The action buttons remain hittable and end at least eight points above the bar. Normal phone and compact 200% reading layouts are covered.

These are not pixel-identical prototype frames. The capture uses the existing real app safe area (59 top, 34 bottom) and shared navigation position: the Guardian idle bar is x98, y848, 234 × 50; the prototype places it at y859. Network preserves the clear action gap within that inherited position. The prototype's rounded phone-edge frame and its hand-drawn glyphs are not app chrome. Shared Material glyphs and the actual app font/palette rendering remain visible differences. No global bar-position or icon redesign was invented. These differences are recorded for the designer/Fable under OA-ZYRA-325; queue 32's authorised size rollout is still separate.

## Verification and remaining work

Final measured checks and code-size table are in the 30 October Codex daily report, Task 14, and the JSON verification record. The exact code commit is recorded there and in BUILD.json. All SDK commands use the pinned `tooling/no_git_driver.mjs` route, sequentially in this primary chat. The native route remains held.

Five pre-existing failures were reproduced using the starting implementation and original tests from c53d0a7, with the current files restored byte-for-byte afterward. Their exact names and written refusal are in verification.json and Task 14. They remain OA-ZYRA-316 test cleanup; this row does not repair unrelated Browse, Compatibility, Journey-ending or Circle interior tests. The new review Pause is expressly the approved Family Review state, not the retired personal Journey Pause.

No migrations, backend wiring, purchases or production writes. Fable owns document verification and any blueprint/inventory reconciliation; Codex did not edit `PRODUCT/BLUEPRINT`. The next owner of real review/connect transport is OA-ZYRA-317; the next owner of prototype/shared-bar differences is the ZYRA designer with Fable under OA-ZYRA-325. No new Founder decision was requested.
