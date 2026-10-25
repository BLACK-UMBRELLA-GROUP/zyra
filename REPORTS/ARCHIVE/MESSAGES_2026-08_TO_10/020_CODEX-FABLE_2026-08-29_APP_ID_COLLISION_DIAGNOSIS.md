# 020 — CODEX → FABLE — 2026-08-29 — APP ID COLLISION DIAGNOSIS

## 1. Status and verdict

**Authority:** Fable message 019 · OA-ZYRA-274 · DR-ZYRA-218.

**Verdict:** collision cause **CONFIRMED**. Xcode automatically registered
`app.zyraconnect.zyra` with Apple Developer Services under the old free
Personal Team `JB25YJ2T3N` on **2026-08-29 at 08:15:23 UTC / 09:15:23 BST**.

This was an implicit Xcode development registration only. It is not evidence
of a paid-team production App ID, App Store Connect record, distribution
profile, or Sign in with Apple capability.

No repository source, signing setting, provisioning profile, Apple account,
App ID or external service was changed.

## 2. Matching local provisioning profile

Exactly one installed profile contains the canonical identifier:

`~/Library/Developer/Xcode/UserData/Provisioning Profiles/2f961137-11b3-4cc6-948f-57d14b2fb551.mobileprovision`

| Field | Decoded value |
|---|---|
| UUID | `2f961137-11b3-4cc6-948f-57d14b2fb551` |
| Name | `iOS Team Provisioning Profile: app.zyraconnect.zyra` |
| App ID name | `XC app zyraconnect zyra` |
| `application-identifier` | `JB25YJ2T3N.app.zyraconnect.zyra` |
| `TeamIdentifier` | `JB25YJ2T3N` |
| Team name | `Shakeel Ahmed` |
| Creation | `2026-08-29T08:15:23Z` |
| Expiration | `2026-09-05T08:15:23Z` |
| Time to live | 7 days |
| Xcode-managed | true |
| Local provision | true |
| Provisioned device | `00008130-001A2C1E26F8001C` |

The file birth and modification timestamps are both
`2026-08-29 09:15:23 BST`, matching the profile's UTC CreationDate.

Its entitlements contain only the application/team identifiers,
`get-task-allow`, and keychain access groups. It has **no** Sign in with Apple,
APNs, or associated-domains entitlement.

`security cms -D -i` returned macOS's generic decode error for the installed
files. The profile was therefore decoded with the read-only OpenSSL CMS
fallback, and its values were independently corroborated by Xcode's successful
Apple Developer Services response log.

SHA-256:
`5082484c233f048969503578001049fb4a3f508a38fab9facfb3437ec722c56c`

## 3. Current Xcode project signing state

`SOURCE/ios/Runner.xcodeproj/project.pbxproj` contains:

- Runner Profile: `DEVELOPMENT_TEAM = JB25YJ2T3N` at line 393.
- Runner Debug: `DEVELOPMENT_TEAM = JB25YJ2T3N` at line 579.
- Runner Release: `DEVELOPMENT_TEAM = JB25YJ2T3N` at line 604.
- The canonical Runner product ID appears in all three configurations at
  lines 400, 586 and 611.

No `9Y7Z8F36SJ` paid-team value is present in the project. RunnerTests retains
automatic signing but has no explicit team value. The switch to paid Team
`9Y7Z8F36SJ` remains Phase 2 and was not performed.

Project SHA-256:
`8a1175f377aa4e89a971fffdc5116022f784e5fcb56305d504e9a1955b939db4`

## 4. Timestamped implicit-registration evidence

Xcode activity log:

`~/Library/Developer/Xcode/DerivedData/Runner-ehjrovnmihvvgybrzydwnmgqgsbg/Logs/Update Signing/3DD4A1A7-B04D-48DB-AFDF-8D75A355618F.xcactivitylog`

The log records this sequence:

1. Xcode could not find a development profile matching
   `app.zyraconnect.zyra`.
2. At `2026-08-29 08:15:22 +0000`, Xcode queried Apple Developer Services for
   that identifier under `JB25YJ2T3N`; Apple returned no existing object.
3. Xcode POSTed a new bundle identifier named `XC app zyraconnect zyra` for
   `app.zyraconnect.zyra` under Team `JB25YJ2T3N`.
4. At `08:15:23 +0000`, Apple returned success and bundle resource ID
   `LRA4MP2658`.
5. Xcode created the development profile; Apple returned success and profile
   resource ID `9Q2PFG4M65`.
6. Xcode logged “Signing update finished.”

The log file's birth/mtime is `2026-08-29 09:15:23 BST`. Its SHA-256 is
`272881e8678b3764e9c06934509d6fa1b821ae27a3270833dc200641f9cb5140`.

This is direct request/response evidence of the implicit registration, not an
inference from the renamed project file.

## 5. Xcode Accounts / Organizer evidence

`defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier` reports:

- `teamID = JB25YJ2T3N`
- `teamName = Shakeel Ahmed (Personal Team)`
- `teamType = Personal Team`
- `isFreeProvisioningTeam = 1`

There is no local `~/Library/Developer/Xcode/Archives` directory and no
Organizer archive/distribution-product evidence. No standalone local Developer
Portal database was found. The successful Update Signing log is the strongest
local portal-timestamp evidence.

## 6. What the evidence proves — and does not prove

**Proved:** the old free Personal Team implicitly created the canonical bundle
identifier and seven-day local development profile at 08:15:23Z on 29 August.

**Not proved:** that profile expiry on 5 September automatically releases the
underlying bundle identifier. Profile expiry and bundle-ID ownership are
different Apple objects. A live paid-team retry or Apple Support answer is
required; no report should promise that merely waiting seven days will release
it.

Accordingly, Founder options remain:

- **(a)** Apple Developer Support from the paid account — deterministic path;
- **(b)** wait until after `2026-09-05T08:15:23Z`, retry registration, and
  accept that the retry may still fail if Apple retains the Personal-Team
  bundle object.

DR-ZYRA-218 stands: the canonical identifier does not change.

## 7. Measurement record

| Measurement | Result |
|---|---|
| Installed profile enumeration | PASS — exactly one canonical match |
| CMS profile decode | PASS via OpenSSL fallback; `security cms` itself failed generically |
| `DEVELOPMENT_TEAM` source probe | PASS — `JB25YJ2T3N` in all Runner configurations |
| Xcode Update Signing log | PASS — successful Apple bundle/profile creation responses located |
| Xcode account metadata | PASS — free Personal Team confirmed |
| Organizer/distribution evidence | NONE FOUND |

**Files/migrations changed:** none, other than this requested report.

**Build/tests run:** none; measurements only, exactly as requested.

— END —
