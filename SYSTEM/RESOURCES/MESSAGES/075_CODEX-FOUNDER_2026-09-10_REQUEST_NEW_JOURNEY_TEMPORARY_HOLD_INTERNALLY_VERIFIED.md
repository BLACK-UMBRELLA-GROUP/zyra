# 075 — CODEX → FOUNDER
# SUBJECT: Request New Journey temporary client/server hold is internally verified and staged; production remains unchanged
# DATE: 2026-09-10
# GOVERNANCE: AD-AIOS-109 · DR-ZYRA-121/227 · OA-ZYRA-156/159/198/283/285
# STATUS: INTERNALLY VERIFIED / STAGED ONLY / NOT APPLIED / NOT UPLOADED / OA-ZYRA-198 APPLY HOLD

## 1 · Outcome

The Founder-approved interim release route is now implemented, independently
reviewed and tested.

1. Request New Journey is held in the app through one central compile-time
   release gate. Ended cards expose no request action or countdown; End/Ended
   screens make no 60-day availability promise; eligibility, request and
   response wrappers short-circuit before Supabase access.
2. A separate grants-only migration is staged to remove `PUBLIC`, `anon` and
   `authenticated` execution from all four server request/eligibility RPCs.
   Function bodies, Journey/request history, RLS and application data are not
   rewritten.
3. Production is unchanged. The migration and its transactional post-apply
   harness have not run. No TestFlight build has been uploaded.
4. The permanent mutual-consent design remains law. The temporary hold can be
   removed only after OA-ZYRA-156 completes the remaining per-attempt storage
   conversion and that restoration receives its own Founder-authorised server
   and app release.
5. The product-choice blocker from message 074 is closed by DR-ZYRA-227. The
   remaining apply-preparation blocker is OA-ZYRA-198 clean migration replay.
   No production Apply GO is requested in this message.

## 2 · Authority and boundaries

The Founder's direct `Approved` reply on 2026-09-10 ratified DR-ZYRA-227 and
authorised implementation and staging of the recommended temporary hold. It
did not authorise:

- applying either staged production migration;
- rewriting the two historical OA-ZYRA-193 record-only migration stubs;
- uploading any signed build to Apple;
- widening distribution beyond the Founder; or
- closing OA-ZYRA-156, OA-ZYRA-198, OA-ZYRA-283 or OA-ZYRA-285.

No git command was used and no private credential store was accessed.

## 3 · Live pre-state measured read-only

Project: `sxoaxonzjqkgajmlagyk` (`ZYRA-APP-LAB's Project`, EU West,
healthy, PostgreSQL 17.6 at inspection).

The exact live public functions were:

| Signature | Owner | Definer | `search_path` | Definition MD5 | Authenticated execute |
|---|---|---:|---|---|---:|
| `request_new_journey(uuid)` | `postgres` | yes | `public` | `897e43500f078122efedf07e74f42d28` | yes |
| `respond_to_journey_request(uuid,text)` | `postgres` | yes | `public` | `f4c650277d3228a79b95d06cc9acfd63` | yes |
| `zyra_may_request_new_journey(uuid)` | `postgres` | yes | `public` | `29995908506ff0f9b8a7343ab21fa3fe` | yes |
| `zyra_may_request_new_journey_ids()` | `postgres` | yes | `public` | `b8d434d35e2195940bbd9fd4221b91d8` | yes |

Each function's ACL was exactly
`postgres`, `authenticated`, `service_role`; `anon` had no execution.

Measured affected state:

- `journey_requests`: 0 rows across all statuses;
- request/accept/decline notification rows: 0;
- matches with more than one Journey attempt: 0;
- `journey_requests` RLS: enabled;
- direct authenticated table/column INSERT, UPDATE and table DELETE: denied;
- migration versions `20260910184252` and `20260910195642`: not applied.

The live write surface is therefore the request/response RPC pair rather than
direct table DML. The server hold must revoke those functions; a hidden button
alone would not be a security boundary.

## 4 · Client hold

`SOURCE/lib/data/zyra_release_gates.dart` defines
`requestNewJourneyEnabled = false` and the one truthful unavailable message.

The bounded client changes are:

- Connections does not fetch request eligibility while held;
- Ended Journey cards do not show Request New Journey, its inline form,
  countdown, cooling promise or request-window copy;
- request-send and response wrappers return before any Supabase RPC;
- the Journey end confirmation, just-ended completion and reopened Ended view
  say the route is temporarily unavailable rather than promising 60 days;
- Timeline, View Compatibility, historical Journey data, expiry processing,
  the developer rewind and the retired always-refusing restart method retain
  their existing behaviour.

No alternative Flutter request/accept/decline caller was found. Dashboard and
notification code are informational consumers only.

## 5 · Staged server hold

Migration:
`SOURCE/supabase/migrations/20260910195642_oa156_request_new_journey_testflight_hold.sql`

SHA-256:
`0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545`

The migration:

1. pins the exact four signatures, overload count, `postgres` owner,
   `SECURITY DEFINER` posture, deployed body MD5 and present ACL;
2. aborts unless request rows, request notification rows and multi-attempt
   matches are all zero;
3. aborts unless request-table RLS remains enabled and direct authenticated
   DML remains denied;
4. revokes `EXECUTE` on the exact four functions from `PUBLIC`, `anon` and
   `authenticated`;
5. retains only the trusted `postgres` and `service_role` execution plane; and
6. proves the exact final grantee set before commit.

It changes no function body, table, row, policy, trigger or comment. Any
catalog/body/ACL/state drift raises SQLSTATE `55000` and stops the cutover.

Prepared post-apply harness:
`SOURCE/supabase/tests/zyra_oa156_request_new_journey_hold_post_apply.sql`

SHA-256:
`be2980edfc388d2dab08fd92e87623f5e110b38563c7a083ddbc0a63d6bb7015`

It is transactional and unexecuted. It will verify migration history,
function identity, exact ACLs, direct anon/authenticated `42501` denial on all
four RPCs, unchanged table RLS/DML posture, retained expiry and retired-restart
access, zero affected state and rollback.

## 6 · Exact source identity

True pre-files were copied before editing to
`/private/tmp/zyra_request_hold_pre_20260910.hSXi3z`. A new/absent artifact is
recorded as absent; the CLI-created migration was captured empty before its
first content edit.

| File | True pre state / SHA-256 | Current SHA-256 |
|---|---|---|
| `SOURCE/lib/data/zyra_release_gates.dart` | absent | `aa6c66cee36840272e61291fc8ba936cc0f1dd320271a4702efd9da5b25a671e` |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `b71bb061f6c2a249bec7e926558c146d03a81ae8159d30827f7e18f6c37bb918` | `8ec7f02b180d63cfc271d6bf93a8f0fa838a4f3e848ee6c32f83f80ac087acc0` |
| `SOURCE/lib/screens/journey/journey_flow_screen.dart` | `f3bc503e0131ef9ae46af322b68b0c8ad6d1384481d4b759bc69b1443438bce6` | `074a8626fa0b0a043871bb9dede8c0ec4c79c7481f6d1cfc9d5054b12b1424f0` |
| `SOURCE/lib/services/zyra_journey_service.dart` | `3caab8cb3a6eb100f0d50eb868d0bb15ef437e19526a6ffe698137c3868cc275` | `17a6e0b2785bed0428ffa0d2188f1b407eb78cbbd63262f15dbab1f5c9a62c62` |
| `SOURCE/test/connections_design_defaults_test.dart` | `874c65011b6f58587f41fccc5082c321c4b5e6f29998b30949cf023efcaf647e` | `058e275683a7bee97c85ef13258f04e9bb4025627634fa20f2c63ea5eaf7e1e4` |
| hold migration | CLI-created empty `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545` |
| hold migration static test | absent | `5f568f430322ad7e2d0ece8f55f2ec277b4db2e2314452fd1571cfa56f929ba9` |
| hold post-apply harness | absent | `be2980edfc388d2dab08fd92e87623f5e110b38563c7a083ddbc0a63d6bb7015` |
| decisions register | `2777736fd025a18c25e68d20e555e0f89f7382fc58efc0e27a9c10e485058cdd` | `67e5d0a7cefff495792b02f7b27239f27bfccfc815135a8cf10f58a6f937cf77` |
| OA register | `2295409fb804caea4e149a5806919fb6a0383d488aaf3e892669ca6caa05c269` | `5d36ba2adac8caec9ba483631c8aa886efc4255da9a90873ee888bc05936eb79` |
| Compatibility boundary handover | `12b2ef6978d8bbd2010811eda168cc829284d07fcb2fa1ff1957eb166ceb31be` | `17343655fd7e275fbf1f5c408958f8406b7e7c98910fc4d33dae5bd7c27e95aa` |
| generated documentation index | `bfc74445f004fba42cf34dd6c18c3b7016450685d6911b8203a61a49119195c6` | `8d864bc3ace7b6cb19158be3994212e2936dbc0525456c2c5d11ff128645d9cd` |

The generated index now records 594 documents, 95 current.

## 7 · Verification

- focused app-shell/client/migration tests: 41 passed, 0 failed;
- client-only hold suite: 24 passed, 0 failed;
- independent client call-surface review: PASS, no blocker;
- independent migration and post-apply-harness review: PASS, no blocker;
- `flutter analyze`: no issues;
- complete Flutter suite: 808 passed and exactly 60 failed, all in the
  pre-existing OA-ZYRA-257 Dashboard golden set; no new non-golden failure;
- approved pixels regenerated or edited: 0;
- `python3 tools/zyra_check.py`: 186 files, 0 findings;
- checker unit test: 1 passed;
- `flutter build ios --release --no-codesign`: passed, 24.8 MB Runner app;
- server migration apply: not run;
- post-apply harness: not run;
- signed IPA archive/upload: not run;
- git: not used;
- private credentials: not accessed.

## 8 · Controlled future cutover

After OA-ZYRA-198 is resolved and a clean replay passes, the exact production
package must state both hashes and use this order:

1. keep the Founder app closed and the cutover quiesced;
2. apply OA-ZYRA-283 migration `20260910184252` at SHA-256
   `63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d`;
3. without reopening the app or uploading a build, apply hold migration
   `20260910195642` at SHA-256
   `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545`;
4. run both post-apply harnesses, catalog/ACL checks, zero-state checks and
   advisors; and
5. only after a separate exact Upload GO, upload the RPC-wired,
   Request-New-Journey-held binary to Founder-only TestFlight.

Hard stops are: any artifact or live-definition hash drift; an unexpected
function overload/grantee; any request row, request notification or
multi-attempt match; any direct-call denial failure; any Compatibility
boundary data leak/mutation; or any application-health regression.

The safe recovery from an OA-ZYRA-283 failure is a new forward migration or a
held binary, never restoration of shared-table client access. Regranting the
four request RPCs would deliberately reopen the unsafe second-attempt route,
so it is permitted only as part of the future OA-ZYRA-156 restoration package,
not as an emergency release shortcut.

## 9 · Remaining blocker and next gate

OA-ZYRA-198 remains open because repository migrations
`20260811152220` and `20260811152255` are record-only `SELECT 1` stubs while
the applied migration history contains substantive OA-ZYRA-193 statements.
A clean reset cannot reconstruct the schema required by OA-ZYRA-283.

The next safe action is a governed history-recovery and clean-replay
preparation round. That work requires its own explicit Founder authority; it
must preserve applied history and cannot silently overwrite audit anchors.
Only after the replay passes should Codex return with the final exact two-
migration Apply GO package.

— Codex / Operating Partner, 2026-09-10
