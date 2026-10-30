---
id: DOC-ZYRA-0288
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 6 - how ZYRA gets from code to a phone - what you need, the app's identity, the daily commands, the checks before a release, TestFlight builds, database changes, release switches and the public-launch gates; plus what is out of date or machine-specific
links: [OA-ZYRA-309, OA-ZYRA-312, OA-ZYRA-317, DOC-ZYRA-0287]
owner: Fable
---

# ZYRA BLUEPRINT — PART 6 — BUILD AND RELEASE — V1 (CURRENT)

Status: **CURRENT - approved by the Founder, 26 Oct 2026** (all 14 blueprint pages, review pack DOC-ZYRA-0299). Building anything that breaks this page needs a new decision first. Written 26 Oct 2026 from `SOURCE/run.sh`, `SOURCE/tool/`, `SOURCE/tooling/`, `SOURCE/tools/`,
the iOS project settings, `SOURCE/lib/data/zyra_release_gates.dart` and the App Store runbook. **No AI uploads or runs
migrations; only Codex runs git, within core rule 2 (AD-AIOS-114).** The commands below are for Shakeel's own Terminal. One exception for builds: under DR-ZYRA-257 (Founder,
4 Oct) Codex may build and install the profile app on the paired Founder iPhone after a Founder-requested change, while
Shakeel says he is home - see `AGENTS.md`. The build freeze (OA-AIOS-406) pauses that too.

## In one paragraph

ZYRA is an **iPhone app** built with **Flutter 3.44.2** on Shakeel's Mac mini. Day to day, `./run.sh` puts a build on his
iPhone that keeps working when unplugged. TestFlight builds come from two small scripts and are signed by Apple's cloud
signing. The database has **one** live project; changes are migration files applied only with an exact Founder GO. Three
release switches are **off**, and the public launch is **closed** until identity checks, payments, moderation, privacy
wording and store details are done.

## 1. What you need

| Need | Value | Where it is recorded |
|---|---|---|
| Computer | A Mac (today: Shakeel's Mac mini, Apple silicon) | — |
| Flutter | **3.44.2**, stable channel, at `/opt/homebrew/share/flutter`; Dart **3.12** or later | `SOURCE/tooling/sdk_pins.json` (with file checksums) |
| Xcode | Not recorded anywhere | **Gap** — record the version used |
| Apple Developer team | `9Y7Z8F36SJ` | iOS project settings |
| Phone | iPhone on iOS **15.0** or later | iOS project settings |
| Two settings files (not in git) | `SOURCE/lib/config/supabase_config.dart` and `oauth_config.dart`, made from their `.example` copies; values come from the protected keys folder, filled in by Shakeel only | DOC-ZYRA-0287 §5 |

## 2. The app's identity

| Field | Value |
|---|---|
| Bundle ID | `app.zyraconnect.zyra` |
| Build flavour / Xcode scheme | `production` (the only one; any other flavour is locked before the app connects) |
| Version | `1.0.0+5` (`SOURCE/pubspec.yaml`) |
| Display name | Set at build time (`APP_DISPLAY_NAME`) |
| Sign-in capability | Sign in with Apple; keychain sharing |

## 3. Everyday commands (Shakeel's Terminal)

| To | Run |
|---|---|
| Check the code for errors | `cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && flutter analyze` |
| Put ZYRA on the iPhone (works unplugged) | `cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && ./run.sh` |
| Developer mode with hot reload (cable stays in) | `cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && ./run.sh dev` |
| The public version, with no Founder previews | `cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && ./run.sh release` |
| Run the app's tests | `cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && flutter test` |

`./run.sh` uses **profile** mode on purpose: a plain `flutter run` installs a debug build that iOS kills when unplugged
(this happened twice in July–August). The script is tied to **one** iPhone (its device ID is written in the script).

## 4. Checks before any release

| Check | Tool | State today |
|---|---|---|
| Code analysis | `flutter analyze` | Run by Shakeel after every change |
| App tests | `flutter test` (464 test files) | 124 screenshot tests fail on old baselines — OA-ZYRA-310 |
| ZYRA's own static checker | `SOURCE/tools/zyra_check.py` (errors that broke past builds) | Present |
| UI and visual gates | `SOURCE/tools/zyra_ui_gate.py`, `zyra_visual_gate.py` | Present |
| Release switches | `zyra_release_gates.dart` (§7) | All three off |

## 5. TestFlight builds

| Build | Script | Who sees what |
|---|---|---|
| Internal (Founder) | `SOURCE/tool/build_internal_founder_ipa.sh` → Apple internal-testing export | The Founder gets the planned-app preview; nobody else |
| Tester cohort | `SOURCE/tool/build_external_review_ipa.sh` → external TestFlight export | Testers see sample data only |

Both make an `.ipa` file only. **Uploading, signing changes and App Store Connect steps are separate actions, each needing
Shakeel's exact GO**, and he does all credential and agreement steps himself. Signing uses Apple's cloud-managed distribution
signing (no local distribution key on the Mac, checked 12 Sep). Latest uploaded build recorded: build 3 (13 Sep).

## 6. Database changes

| Rule | Detail |
|---|---|
| Where | `SOURCE/supabase/migrations/` — 229 files, applied in order |
| Which database | **One** live Supabase project for everything; no test copy |
| Who applies | Only with Shakeel's exact GO for that migration |
| Repository vs live | **Not the same today.** The 24 Sep "paid-only" migration is marked repository/staging only, and Guardian Circle messaging (OA-ZYRA-298) is noted as not live. The read-only live check (OA-ZYRA-312) will list every difference |

## 7. Release switches (all OFF)

| Switch | Turns on when |
|---|---|
| `requestNewJourneyEnabled` | Request restart is rebuilt on attempt-owned records (OA-ZYRA-156) — now also DR-ZYRA-277 |
| `paidOnlyMembershipEnforced` | App Store purchases are verified (StoreKit), family seats and the account screen ship together — now with Basic = 1 place (DR-ZYRA-275) |
| `familyMessagingEnabled` | Guardian Circle messaging is applied to the live database |

## 8. Public launch — closed until all are done

Identity check provider (Sumsub) · photo and message moderation · privacy wording and data disclosures · App Store products
and payments · store listing, age rating and territories · the restrictions in OA-ZYRA-184 and OA-ZYRA-285 · the planned app
connected to real members (OA-ZYRA-317).

## 9. Found while mapping

| # | Finding | Goes to |
|---|---|---|
| 1 | **Three tool folders** in `SOURCE`: `tool/` (6 build scripts), `tooling/` (8 build-safety files), `tools/` (Python checkers, plus a `__pycache__` folder) | Clean-up (OA-ZYRA-316): one folder |
| 2 | **The "runbook" was a 192 KB delivery log.** The actual steps (§1–7) started at line 1,253 under 30+ dated delivery rounds (lesson L28) | **Done 26 Oct:** runbook V3 is a few pages; V2 archived (OA-ZYRA-318) |
| 3 | **377 MB of fake test photos** in `SOURCE/supabase/dev_test_photos/`; ignored by git, yet **17** of them are still tracked | Clean-up; move to the USB evidence if worth keeping |
| 4 | **Developer seed scripts for the only database**: 16 `@zyra.test` accounts (`seed_dev_accounts.sql`), fake photo upload and backstory seeds | Live check (OA-ZYRA-312): are test accounts in production? Then remove or isolate |
| 5 | Empty folders `supabase/functions/` and `supabase/staging/` (retired) | Clean-up |
| 6 | Android, web, Windows, Linux and macOS project folders (36 MB) for an iPhone-only app | **Decided (DR-ZYRA-279):** keep Android; remove web, Windows, Linux, macOS in the clean-up |
| 7 | `run.sh` is tied to one iPhone and one Founder account | Fine for now; written here so a new phone is not mistaken for a broken build |
| 8 | Xcode version not recorded | Add to `sdk_pins.json` |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-26 | V1 | First draft from the build scripts, iOS settings, release switches and runbook (OA-ZYRA-309) |
| 2026-10-26 | V1 | Runbook rewritten (V3); platform folders decided (DR-ZYRA-279) |
| 2026-10-29 | V1 | Founder (ZYRA chat): **iPhone and iPad at launch** — answering "What should ZYRA do at launch?" with "iPhone and iPad". Today the app already installs on iPad (`TARGETED_DEVICE_FAMILY = 1,2`; iPad allows all four orientations, iPhone portrait only). iPad layouts must be designed and LOCKed per area; awaiting a DR number from Fable |
| 2026-10-26 | V1 | Approved by the Founder ("a" - all 14 pages); status CURRENT |
| 2026-10-26 | V1 | Git line aligned with core rules V3 (AD-AIOS-114) |
