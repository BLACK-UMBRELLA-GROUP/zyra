---
id: DOC-ZYRA-0254
type: GUIDE
status: CURRENT
feature: RELEASE
purpose: ZYRA release runbook - who gets which build, putting ZYRA on the Founder's iPhone, making and uploading a TestFlight build, signing, evidence, the release switches and the public-launch gates, in a few pages
links: [DOC-ZYRA-0288, OA-ZYRA-318, OA-ZYRA-312, OA-ZYRA-317]
owner: Fable
---

# ZYRA — RELEASE RUNBOOK — V3 (CURRENT)

Rewritten 26 Oct 2026 (OA-ZYRA-318, Founder GO). V2 — a 192 KB log of every delivery round — is archived unchanged as
`SYSTEM/DOCUMENTS/ARCHIVE/ZYRA_APP_STORE_RUNBOOK_2026-10-26_V2.md`; evidence files written before 26 Oct cite it by its old
name. Full detail on tools and settings: blueprint part 6, DOC-ZYRA-0288. **Keep this runbook short:** when a step changes,
change the step; record each delivery in its evidence folder, not here (lesson L28).

## 1. One app, three audiences

| Who | Gets | How |
|---|---|---|
| **The Founder** (exact company account, refreshed Founder role, internal build) | The planned-app preview with sample data, developer tools | `./run.sh` on his iPhone, or the internal TestFlight build |
| **A personal or member account** | The ordinary member app | Any build |
| **The public** (public build) | The ordinary member app; no developer access even for the Founder | Not released — §6 |

Matching an email is never enough: the Founder build checks the exact account ID, the main database and the Founder role.
The cancelled second-app programme stays cancelled.

## 2. Putting ZYRA on the Founder's iPhone

| Step | Command (Shakeel's Terminal) |
|---|---|
| 1. Check the code | `cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && flutter analyze` |
| 2. Install (plug in to install; afterwards it keeps working unplugged) | `cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && ./run.sh` |

`./run.sh` builds in **profile** mode on purpose: a plain `flutter run` installs a debug build, which iOS kills once the
cable is unplugged (it happened twice in Jul–Aug). So never plain `flutter run`.

For the install the iPhone must be plugged in, unlocked and trusted. If it says no matching device, the phone changed — run
`cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && flutter devices` and update `DEVICE` in `run.sh`.
Codex uses its own checked build route (`SOURCE/tooling/`, no git) and records each delivery in `ZYRA/REPORTS/EVIDENCE/`.

## 3. Making a TestFlight build

| Step | Who | What |
|---|---|---|
| 1. Checks pass | Codex / Shakeel | `flutter analyze` clean; tests run — known exception: 124 old screenshot baselines (OA-ZYRA-310) |
| 2. Build the file | Shakeel | Internal: `cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && sh tool/build_internal_founder_ipa.sh` · tester cohort: `cd "/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE" && sh tool/build_external_review_ipa.sh` |
| 3. Signing | Apple | Apple's cloud-managed distribution signing (no local distribution key on the Mac). If Apple wants to create certificates or profiles, that needs Shakeel's exact GO first |
| 4. Upload | **Shakeel only** | With Apple's upload tool, after his exact GO for that build number |
| 5. Assign | **Shakeel only** | App Store Connect → TestFlight → internal group (or the private tester group) |

Never use the tester-cohort export for the Founder build, or the reverse. Bump the build number in `SOURCE/pubspec.yaml`
(`version: 1.0.0+N`) before each upload.

## 4. Where things stand (update this table, not a log)

| Item | Now |
|---|---|
| Last TestFlight upload | Build 3, 13 Sep 2026 (internal, assigned privately) |
| Last install on the Founder's iPhone | Delivery O8XRQc, 22 Oct 2026 |
| Built, not installed | QZALFp (Circle picker), 23 Oct 2026 — install held |
| Public App Store | Not released |

## 5. Evidence

Each delivery keeps its own folder in `ZYRA/REPORTS/EVIDENCE/` (screenshots, JSON, BUILD.json). Never copy builds or source
into evidence. A check that failed stays recorded as failed; it is never rewritten as a pass.

## 6. Release switches and public launch

| Switch (`SOURCE/lib/data/zyra_release_gates.dart`) | Off until |
|---|---|
| `requestNewJourneyEnabled` | Request restart rebuilt (OA-ZYRA-156, DR-ZYRA-277) |
| `paidOnlyMembershipEnforced` | App Store purchases verified, with Basic = 1 place (DR-ZYRA-275) |
| `familyMessagingEnabled` | Guardian Circle messaging applied to the live database |

**Public launch stays closed** until: identity check (Sumsub) · moderation · privacy wording and disclosures · App Store products
and payments · store listing, age rating and territories · OA-ZYRA-184 and OA-ZYRA-285 · the planned app connected to real
members (OA-ZYRA-317).

## 7. Standing rules

- Only the Founder approves. No git, migration, provider change, Apple registration, signing change or upload without his exact GO.
- Stop if the account, team, bundle ID, database project, signing or build number is not what this runbook says.
- Shakeel does every credential, agreement, payment and tax step himself. No secrets in chat, screenshots or evidence.
  Never enter the protected keys folder.

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-09-12 | V1 | Archived (ARCHIVE/ZYRA_APP_STORE_RUNBOOK_2026-09-12_V1.md) |
| 2026-09-12 → 10-26 | V2 | One-app runbook that grew into a delivery log (archived) |
| 2026-10-26 | V3 | Rewritten short by Fable (OA-ZYRA-318) |
| 2026-10-26 | V3 | §2 says why only `./run.sh` (profile build), from the cold-start tests |
