---
id: DOC-ZYRA-0444
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Test clean-up round 2 — apply the ZYRA chat's answers to QUESTIONS rows 13–55 (line 73) and make the small app fixes those answers name
links: [AD-AIOS-116]
owner: ZYRA chat
---

# TEST CLEAN-UP ROUND 2 — 10 NOV 2026

**Why:** line 73 (BUILT 4 Nov) left 358 failures in 36 files and 43 questions (rows 13–55). The ZYRA chat answered
them on 10 Nov in `QUESTIONS.md`; the Founder answered row 21 the same day (LOCK 14 V6). This line applies those answers.
Founder, 10 Nov: "ok we aint gonna wait for lablebox so we are gonna get this app ready".

**ROADMAP row (charter rule 12):** "Test baseline and final interface pass" in `ZYRA/ROADMAP.md`. Tick it only when
lines 44, 73 and 75 are all BUILT and the full suite is green; otherwise leave it open and write the remaining count in
the task note. Only Fable changes ROADMAP rows or hours.

**Copy exactly. No improvements.** No upgrades (standing rule, strict 21 Nov – 14 Dec). Unclear → file a question in
`QUESTIONS.md` and continue with the next group. Source: `TEST_CLEANUP/BUILT/QUEUE73_CLASSIFICATION.json`.

## Shared rules (quoted in the answers)

| Rule | Meaning |
|---|---|
| R1 | Every Back or Cancel returns to the screen it was opened from (its immediate parent, still mounted). A modal Cancel returns to the page under the modal |
| R2 | Keep the protection a test proves (exactly-once; stale-owner, revoked or forged write refused; cross-person and cross-role isolation; disclosure) and re-test it on the CURRENT LOCK host. A captured action must do nothing after the place changes, the page is left, the role changes or access is withdrawn. Retire the old-host case to `~/_to_delete/ZYRA_TESTS_RETIRED_<date>/`. Never build a synthetic copy of a removed widget |
| RV | The visual goldens for LOCK 8 V4–V9, LOCK 15 V3 / 18 V2, LOCK 19 V2/V3, LOCK 20 V2, LOCK 21 and LOCK 22 V1–V6 were checked on 10 Nov and match. Regenerate those from the current build (name the LOCK and master in a comment). Retire cases no LOCK covers. Runtime/layout/finder failures → repair the fixture (R1/R2); if the app itself breaks, add a Finding row |

## Steps

| Step | Detail |
|---|---|
| 1 | **Tests:** for each row 13–55 marked ANSWERED, apply its answer to the listed test cases (Update / Retire / Fixture as the answer says). Cite the QUESTIONS row number in a comment beside each changed case |
| 2 | **App fix — Q13:** the accessible Next-page control gives one haptic tick on tap (HAPTICS brief rule 2) |
| 3 | **App fix — Q14:** releasing a held control runs the same locked action as a tap on it, or nothing if the finger left the control |
| 4 | **App fix — Q15:** a rejected, stale or scroll-cancelled tap gives no haptic tick |
| 5 | **App fix — Q17:** the Guardian tab with no Guardians must not throw; it shows the LOCK 19 Add a Guardian card (master k08) as the only card |
| 6 | **App fix — Larger Text wrap:** on the Guardian Network tab at Larger Text (390 pt wide) no word may break mid-word (today "Netwo/rk", "Introd/uce"). Wrap at word boundaries; if a single word cannot fit, shrink that label one step rather than splitting it. Nothing else on the screen changes |
| 7 | **App fix — Q21 (LOCK 14 V6, `APP_COLOURS/RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V6.md`):** small danger text (End Journey, Remove, Decline, Report, Block labels) uses `#AC453E`; `#B84A42` stays for icons, outlines, traffic-light dots and large text. Update the contrast test to expect 4.5 : 1 or more |
| 8 | **Q45:** if line 74 is BUILT, the preview-access test already checks the one app-error page (LOCK 23 e03); if not, leave it for line 74 |
| 9 | Pass = full suite green, or every remaining failure listed with its reason and QUESTIONS row. No new skips without a reason in the code |
| 10 | **App check — Q59 (LOCK 23):** the release framework fallback (last-resort app restart) shows the one error page with the `page` words, **no 15 s auto-retry and no "We keep trying" row**, Try again = the existing restart. If today it restarts on a timer, remove the timer. Add a test that the page never restarts the app on its own |
| 11 | Task note: table per file (Update / Retire / Fixture / App fix / Finding, count), before/after totals (start 358), files moved; commit within core rule 2; mark queue line 75 BUILT or FAILED. Do not install on the iPhone in this line |
