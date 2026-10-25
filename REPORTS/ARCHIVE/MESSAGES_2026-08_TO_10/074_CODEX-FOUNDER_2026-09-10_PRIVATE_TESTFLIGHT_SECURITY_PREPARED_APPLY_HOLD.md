# 074 — CODEX → FOUNDER
# SUBJECT: Private TestFlight security preparation complete; one Founder product ruling required before apply
# DATE: 2026-09-10
# GOVERNANCE: AD-AIOS-109 · DR-ZYRA-121/122/135 · OA-ZYRA-156/159/198/283/284/285
# STATUS: PREPARED / STAGED ONLY / PRODUCTION UNCHANGED / APPLY HOLD

## 1 · Outcome

The first private-TestFlight preparation stage is complete, but the live
security cutover is deliberately not being presented for approval yet.

1. OA-ZYRA-283 now has a staged caller-owned Compatibility Reveal RPC
   boundary and an RPC-wired Flutter client.
2. The migration has not been applied and no build has been uploaded to
   Apple.
3. Focused tests, analyzer, repository checks and the unsigned iOS release
   compile pass. The full Flutter run retains exactly the 60 already-known
   OA-ZYRA-257 Dashboard golden mismatches and introduced no new failure.
4. Independent review found a separate, older cross-attempt Journey defect
   that prevents calling the current app technically ready while Request New
   Journey remains available.
5. OA-ZYRA-156 and OA-ZYRA-198 were reopened in the register instead of
   inventing duplicate action identifiers or concealing incomplete work.

## 2 · Live pre-state measured read-only

Production project: `sxoaxonzjqkgajmlagyk` (`ZYRA-APP-LAB's Project`,
EU West, healthy at inspection).

- migration `20260910184252`: absent;
- new OA-ZYRA-283 RPCs: absent;
- matches / attempts: 5 / 5;
- matches with more than one attempt: 0;
- Journey requests: 0 total, 0 pending, 0 accepted;
- compatibility rows: 3, all bound to the matching current attempt;
- direct `authenticated` SELECT/INSERT/UPDATE on the shared compatibility
  table remains live under the old policies;
- no DDL, DML, ACL, account, key, build-upload or other production mutation
  was performed.

The zero-request/zero-second-attempt state makes a temporary feature hold
low-risk: no existing request or second-attempt user state would be stranded.

## 3 · OA-ZYRA-283 staged artifact

Migration:
`SOURCE/supabase/migrations/20260910184252_oa283_journey_compatibility_rpc_boundary.sql`

SHA-256:
`63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d`

It creates caller-relative state/reveal RPCs, hardens the Plus RPC to the same
active/current/unpaused Compatibility Reveal boundary, closes direct client
table access, and exposes only the caller-owned score. It includes a
forward-compatible shared-Pause check for the separately staged pause-state
migration. The exact bytes remain staged only.

Prepared post-apply harness:
`SOURCE/supabase/tests/zyra_oa283_journey_compatibility_boundary_post_apply.sql`

SHA-256:
`e75657d67be8b84457e5ad2e63920bb3bff161b80092954f28fd43bf010ace7c`

The Plus path now joins the same null-caller, missing/nonparty/Guardian,
stale/NULL-attempt, legacy lifecycle and future shared-Pause denial matrix as
the ordinary RPCs. The harness also pins both asymmetric Seeker-side positive
Plus branches, column ACLs, unexpected function overloads and unexpected
execution grantees. It has not been executed because the migration is not live.

## 4 · Blocking cross-attempt finding

DR-ZYRA-121 says every new Journey attempt starts fresh and preserves the old
attempt's history. The implementation only completed that conversion for
conversations and timelines.

The current production schema still keys compatibility, Salams and Journey
checkpoints by `match_id`. `respond_to_journey_request(..., 'accept')` creates
attempt 2 while keeping the prior rows, as it should. The result is unsafe:

- the trusted client can become stuck because its new-attempt insert conflicts
  with the old match-keyed row;
- match-keyed Salams, reveal flags and Continue checkpoints can satisfy gates
  on the new attempt for a modified/direct caller; and
- deleting or rebinding the old rows would violate the approved history rule.

The trusted Flutter UI exposes Request New Journey. No production Flutter
caller of the acceptance service was found, but the authenticated acceptance
RPC is directly callable. That is not a sound release boundary.

This is existing OA-ZYRA-156 work. Its recorded OA-ZYRA-155 blocker had in fact
closed in 2026, so the action was corrected to REOPENED / UNBLOCKED.

## 5 · Separate replay-evidence defect

OA-ZYRA-198 claimed the repository could replay the full live schema. It
cannot. Applied migration versions `20260811152220` and `20260811152255` are
only `SELECT 1` record stubs in the repo even though live migration history
retains the substantive OA-ZYRA-193 two-score columns and function bodies.
OA-ZYRA-283 references that live shape, so a clean repo replay cannot compile
it.

OA-ZYRA-198 was reopened. Before any production GO, the exact retained
statement arrays need a governed, hash-verified recovery or an equivalent
production-schema replay environment, followed by a real compile/replay.

## 6 · Founder decision required

Two safe routes exist:

1. **Recommended for the first Founder-only TestFlight:** temporarily disable
   Request New Journey at both server and UI. The server must return no
   eligible matches and refuse request creation/acceptance; the ended-card
   action must disappear. Direct-call denial, zero pending requests and
   old-client failure must be tested. The feature returns only after
   OA-ZYRA-156 is completed.
2. Complete the full OA-ZYRA-156 populated-data, per-attempt conversion now.
   This is the permanent answer but is a substantially wider, higher-risk
   migration across keys, policies, RPCs, triggers and client reads/writes.

Route 1 is recommended because it creates the smallest honest security
boundary for one trusted Founder tester and does not delete or reinterpret any
Journey history. It is a temporary suspension of an approved feature, so it
requires the Founder's explicit product ruling before Codex stages it.

## 7 · Exact file identity

| File | True pre state/SHA-256 | Current SHA-256 |
|---|---|---|
| `SOURCE/lib/services/zyra_journey_service.dart` | `dbd4adcc…` | `3caab8cb3a6eb100f0d50eb868d0bb15ef437e19526a6ffe698137c3868cc275` |
| `SOURCE/test/app_shell_correctness_test.dart` | `9e451822…` | `2c955eb02fd76ed64ed0696ad74c1c6330233e06bafd7efae0b72359868eeeb2` |
| OA-ZYRA-283 migration | absent / empty creation `e3b0c442…` | `63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d` |
| OA-ZYRA-283 static test | absent | `35270d058d47c681ec41958c749b86959ff6cd8f37dc7fee413892e89c98e365` |
| OA-ZYRA-283 post-apply harness | absent | `e75657d67be8b84457e5ad2e63920bb3bff161b80092954f28fd43bf010ace7c` |
| `APP/Journey/PRE-JOURNEY RITUAL/Summary.md` | `caa571ea…` | `25b5d1808bb749b371d7c2fc07aadfb2b4348274d6240be594cdf334dccc86cd` |
| OA register | `664a5ee1…` before the programme; `5abfc006…` before blocker filing | `2295409fb804caea4e149a5806919fb6a0383d488aaf3e892669ca6caa05c269` |
| Compatibility boundary handover | absent | current file is the canonical detailed handover |

True pre snapshots are retained under `/private/tmp/zyra_oa283_pre_20260910/`
and `/private/tmp/zyra_oa283_blocker_pre_20260910/` for this active session.

## 8 · Verification

- focused app-shell + OA-ZYRA-283 tests: 20/20 pass;
- final OA-ZYRA-283 static test: 6/6 pass after Plus-matrix extension;
- full Flutter suite: 800 pass, exactly 60 known OA-ZYRA-257 golden failures;
- `flutter analyze`: no issues;
- repository checker: 185 files, 0 findings;
- repository checker unit test: 1/1 pass;
- unsigned iOS release compile: pass, 24.8 MB Runner app;
- independent boundary review: caller-owned/pause amendment clean; Request
  New Journey and clean-replay findings above remain blockers;
- migration apply: not run;
- post-apply SQL/concurrency harness: not run;
- signed IPA build/upload: not run;
- git: not used;
- private credentials: not accessed.

## 9 · Next sequence after the ruling

If the Founder selects the recommended temporary hold, Codex will:

1. stage the server-and-UI hold and its direct-call tests;
2. repair/prove clean schema replay without rewriting live history;
3. re-run the full source, SQL and release-build checks;
4. present exact migration hashes, production impact, stop thresholds and
   forward-repair plan for a separate one-use apply GO;
5. apply nothing until that exact GO is received;
6. post-verify live, build a fresh signed Founder-internal IPA, and ask for a
   separate upload GO before sending anything to Apple.

— Codex / Operating Partner, 2026-09-10
