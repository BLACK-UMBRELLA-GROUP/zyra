---
id: DOC-ZYRA-0438
type: PLAN
status: CURRENT
feature: PHONE_INSTALL
purpose: Founder-named task - repair ZYRA's protected iPhone install route (QUESTIONS row 58) so the newest BUILT commit, starting with LOCK 23 (line 74), can be installed on the Founder's iPhone before he leaves on 21 Nov
links: [DOC-ZYRA-0416, AD-AIOS-116, OA-AIOS-420]
owner: Fable (Founder-named task; written for the ZYRA queue)
---

# BUILD BRIEF — ZYRA PROTECTED iPHONE ROUTE REPAIR — 10 Nov 2026

**Founder (10 Nov 2026, BLACK UMBRELLA GROUP chat):** "Fable: repair the install route before 20 Nov. It's flagged in
today's chat note, because you leave on 21 Nov." Flagged by the ZYRA chat (chat note 10 Nov, 15:25: "Protected
install-route repair is now the only thing between this fix and the Founder's phone (deadline 20 Nov)"). This is
tooling repair, not a design change: no app screen, wording or behaviour changes.

## What is broken (Fable checked on disk, 10 Nov)

| # | Finding |
|---|---|
| 1 | The protected route `SOURCE/tooling/verified_host_profile.mjs` reuses a pinned signed native host at `REPORTS/EVIDENCE/OA305_NO_GIT_OPTION2_DELIVERY_2026_10_13.yqJ0ef/PRE/Runner.app` (177 files, hash pinned in the script). **That `PRE/` folder no longer exists.** It is not in `~/_to_delete`, and the USB snapshots of 24 Oct and 8 Nov do not have it either (`REPORTS/EVIDENCE/*` is git-ignored, and the backups skip built apps). It cannot be restored |
| 2 | The native driver stops before compiling: the no-Git sandbox (`tooling/no_git.sb`) refuses Swift Package Manager's nested-manifest step (QUESTIONS row 58) |
| 3 | `SOURCE/build/ios/Profile-production-iphoneos/Runner.app` (1 Nov) is the signed PROFILE build the one-time old installer put on the phone (line 72). It is inside `SOURCE/build`, which the night housekeeping never moves (lesson F39) |
| 4 | The old installer stays forbidden (line 72: one-time use, spent 1 Nov). Do not use it, and do not use any bypass |

## Allowed

| Allowed | Detail |
|---|---|
| A new pinned native host | Choose the safer of: **(a)** re-pin the protected route to the 1 Nov signed PROFILE host in `SOURCE/build/ios/Profile-production-iphoneos/Runner.app`, if it passes every check the script makes (signature, provisioning profile, entitlements, engine payload, file list); or **(b)** build a fresh signed PROFILE native host with the Xcode, Flutter and Dart already on the Mac, from the current `pubspec.lock` and the Swift packages already in `SOURCE/build/ios/SourcePackages` |
| Fix the Swift package step | Let the Swift Package Manager step run inside the existing policy without opening Git to the Dart/Flutter tree: for example run only the native SwiftPM resolution/build outside the no-Git sandbox with package resolution disabled (`-disableAutomaticPackageResolution`, `-skipPackageUpdates`, local packages only), or adjust `no_git.sb` so SwiftPM's own manifest compile is allowed while `git` stays denied. Record the exact change and why it keeps the no-Git rule |
| Keep the new host safe | Keep the pinned host under `SOURCE/build/` (never moved by housekeeping) or another path the night housekeeping and backups are told about. Never again under `REPORTS/EVIDENCE/` |
| Refresh pins | Update the host path, file count, host hash and any profile/engine pins in `verified_host_profile.mjs` (and its tests) to the new reviewed host, with the reason for each change in the task note |
| Keep every safety check | Strict signature, provisioning profile, paired-device, unlocked-device and launch checks stay exactly as strict. No bypass flags, no fake Git, no re-signing tricks |

## Not allowed (lesson F33, OA-AIOS-420)

No macOS, Xcode, Flutter, Dart, CocoaPods, Homebrew or other tool install or upgrade; no SDK, runtime or simulator
download; no new app on the Mac; **no downloads of any kind** (all needed packages are already cached - if one is not,
stop and file a QUESTIONS row with what and how big). No credentials, signing identities, team IDs or account IDs written
into new files or notes. The old one-time installer is not used.

## Steps

1. **Diagnose** with the existing tools (`verified_host_profile.mjs inspect`, `no_git_driver.mjs check`) and list exactly what is missing or refused.
2. **Find out what removed `PRE/`** from the task notes, daily reports and the night housekeeping log (it existed on 13 Oct). Write one line on the cause for Fable's lesson log.
3. **Repair** as allowed above and refresh the pins. Run the route's own tests (`verified_host_profile.test.mjs`, `review_workspace.test.mjs`).
4. **Build** the newest BUILT commit through the repaired route (no install yet). Analyze clean; no new test failures against the line 74 baseline (358 failing, all known).
5. **Phone install only when Shakeel types GO in the ZYRA Codex chat** (he is at home, phone connected by cable and unlocked). Before installing, tell him in one line which build it is (commit, version, and that it includes LOCK 23's one error page) - lesson L41. Install, open, confirm the launch check, screenshot the first frame for the evidence folder.
6. **Task note:** what was missing, the cause of `PRE/` disappearing, which option (a or b) and why, pin changes, test results, phone result. Public checks A-F (this repo is public; no identifiers in the note).

**Deadline: the phone install must be done by 20 Nov 2026** (Founder abroad 21 Nov - 14 Dec; no installs or phone work while away). If steps 1-4 are not BUILT by 18 Nov, Fable's 04:15 review tells the Founder.
