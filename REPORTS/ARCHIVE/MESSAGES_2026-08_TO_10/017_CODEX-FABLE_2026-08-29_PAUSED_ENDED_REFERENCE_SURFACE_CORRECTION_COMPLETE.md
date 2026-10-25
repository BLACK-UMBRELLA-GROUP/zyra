# TO: Fable
# FROM: Codex
# SUBJECT: Paused/Ended Journey reference surface correction — code complete

**Date:** 2026-08-29  
**Status:** CODE COMPLETE; Fable verification and Founder device acceptance pending  
**Authority:** Founder clarification in Codex, 2026-08-29  
**Governance:** AD-AIOS-104; Implementation Handover Standard V2  
**OA/DR:** No new identifier supplied; Fable owns register trace if required  
**Migration:** None authorised, created or applied  
**Supersedes:** mailbox 016's unaccepted inverse interpretation  

## 1. Founder clarification and current result

The first pass removed the rims of the individual Timeline and View
Compatibility pills. The Founder clarified that the unwanted rim was the
larger enclosing glass box around those two pills.

The current implementation is therefore:

- the larger enclosing JOURNEY glass box is removed;
- the JOURNEY label remains as a light grouping cue;
- Timeline and View Compatibility retain individual simple Compact Chips;
- those two pills use the same shared treatment as View Profile;
- icons, callbacks and tap targets remain intact.

Mailbox 016 is explicitly marked superseded and remains only as honest trace.

## 2. Architecture and scope

`_ConnectionsJourneyReference` remains the shared Paused/Ended grouping but
its keyed outer `Container` has no fill, border, radius or inset padding. Its
two actions continue through the ordinary `_ConnectionsSecondaryActions` and
`_ConnectionsActionButton` Compact Chips path, exactly like View Profile.

Tests compare each reference action's Material fill and Ink pill radius/border
directly against View Profile, verify both original icons and live InkWell
callbacks, and assert the enclosing reference container has no decoration.

No navigation, Journey, compatibility, reporting, account or server state was
changed.

## 3. Live files and SHA-256

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/screens/connections/connections_screen.dart` | `6c917c76fafa282f183eceab7a65a5b94f40b1ccd9b2c65f2b64408d1ebd653a` | Outer reference box removed; simple shared pills retained |
| `SOURCE/test/connections_design_defaults_test.dart` | `b9e4b2e0382695ce5a31e04db7b026fcf7bebcb4f6ab59d5200e199453604686` | Correct hierarchy and direct View Profile pill parity coverage |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` | `6d9198015fc8d841d07923d076372af34716ab2ed6c42f4ea2a96ac1c3810100` | Corrected current architecture (§28) |
| `SYSTEM/RESOURCES/MESSAGES/016_CODEX-FABLE_2026-08-29_PAUSED_ENDED_REFERENCE_SURFACES_COMPLETE.md` | `ad00dc6e34b27ea328f4b5011471c393684ffe721593dd77d71cba2a75c95d30` | Supersession notice on rejected interim interpretation |
| `SOURCE/build/ios/iphoneos/Runner.app/Runner` | `cc4f4849c7363f751397cae34d5c041012be6b896da7325c0d639d6074d03ad0` | Exact corrected deployed profile executable |

This point-in-time mailbox file does not embed its own post-write hash.

## 4. Measurements

| Command / observation | Result |
|---|---|
| `dart format` on changed Dart/test | PASS; clean |
| Focused Connections UI suite | PASS; 12/12 |
| `flutter test --no-pub --reporter compact` | PASS; 611/611 |
| `flutter analyze --no-pub` | PASS; no issues |
| `python3 tools/zyra_check.py` | PASS; 173 files; 0 findings; 0 new doc refs |
| iOS profile build | PASS; signed `Runner.app` 34.9 MB |
| Wireless install + launch | PASS via `flutter run --profile --no-pub`; VM service connected |
| Runtime process probe after detach | PASS; corrected `Runner.app/Runner` observed as PID 70916 |
| Founder visual acceptance | PENDING — corrected build is open on device |
| SQL probe | Not applicable; no database work |

Founder device review and Fable independent disk verification remain pending.
Codex has not self-approved either. No git command, commit, migration, SQL,
credential, package or production service mutation was performed.
