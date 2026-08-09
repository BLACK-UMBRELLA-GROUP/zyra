# SESSION HANDOVER — 2026-08-09

Written at the end of the session, for whoever picks this up next
(including Shakeel on Monday). Everything here is either measured or
flagged as unmeasured. Nothing is assumed.

---

## 1. The one thing to read

**No match has ever existed.**

Measured against the live database on 2026-08-09: **149 users, 0 matches,
0 conversations, 0 messages — in the product's entire history.**

Be precise about the cause, because an earlier draft of this note was not.
Likes WERE being written until the OA-168 grant sweep on **2026-08-08**;
four survive, dated 26–27 July, and none of them were mutual, so no match
was ever created. From the sweep onward every Like, Save and Pass was
additionally refused outright with `42501` and swallowed by a
`catch (_) {}`. Both are fixed.

Either way the consequence stands: every assumption built on "the matching
flow works" is untested in production, and the first real match will be
the first real test of everything downstream.

---

## 2. What changed today

| # | What | Where | Proven? |
|---|---|---|---|
| DR-129 | One canonical Journey stage map; 9 call sites migrated, 3 drifted copies deleted | `lib/data/zyra_journey_stages.dart` | Hand-verified only |
| DR-130 | Matching writes restored (`ignoreDuplicates: true`, 5 sites) | `zyra_discovery_service`, `zyra_journey_service` | SQL shape proven live |
| DR-130 | Blocking wired to `zyra_block_user` / `zyra_unblock_user` | `zyra_report_service` | RPC round-trip proven |
| DR-130 | Guardian self-promotion closed | migration `20260809150931` | Exploit reproduced, then refused |
| DR-131 | `messages_insert` honours blocks, ended Journeys, closed conversations | migration `20260809161716` | 6 tests |
| DR-132 | `open_family_review` validates the transition; staleness guard on resolve | migration `20260809162503` | 8 tests |
| DR-132 | Client now surfaces a review refusal instead of swallowing it | `ZyraReviewOpen` + `journey_flow_screen` | Hand-verified only |
| DR-133 | Invite expiry checked on accept; UPDATE on `wali_invites` revoked entirely | migration `20260809170940` | 5 tests |
| DR-133 | Corrected my own wrong comment in that migration | migration `20260809171103` | Comment only, behaviour identical |
| DR-134 | Account deletion unblocked — `accepted_by` now `ON DELETE SET NULL` | migration `20260809171807` | Before/after + control |

Every SQL test was run as the `authenticated` role inside a transaction
that was rolled back. Nothing in those tests persists.

---

## 3. 🔴 What is NOT verified

**No Dart in this session has been compiled.** There is no Flutter
toolchain in the Cowork container, and it cannot be installed —
`pub.dev` and Google's Flutter CDN are both unreachable from it (checked
2026-08-09). Every Dart change was verified by brace/paren balance across
all 114 files, symbol resolution, and call-site tracing. That is not the
same as `flutter analyze`.

**Run `flutter analyze` before trusting any of it.**

Then test by hand on the device:

1. Like someone who has liked you → does a match appear?
2. Report-and-block someone → do they disappear, and can they still message you?
3. Send a Guardian invite in both directions → do both still work?
4. Walk a Journey through a gated transition → does the Family Review open?

---

## 4. Where the contradiction audit stands

`SYSTEM/DOCUMENTS/ZYRA_CONTRADICTION_AUDIT_2026-08-08.md` — 45 findings.

| Finding | Status |
|---|---|
| 1.1 matching dead | ✅ closed |
| 1.2 blocking fake | ✅ closed |
| 2.1 guardian escalation | ✅ closed |
| 2.2 stage-skip | ✅ closed |
| 2.4 messages ignore blocks | ✅ closed |
| 2.6 invite expiry unchecked | ✅ closed |
| 2.7 inviter can rewrite the invite | ✅ closed |
| 2.9 clear_main has no guard | ⛔ rejected — not a defect, see DR-ZYRA-133 |
| 2.10 account deletion blocked | ✅ closed |
| 2.5, 2.8, 2.11, 2.12 | open |
| §3 money (10 findings) | open |
| §4 document vs reality (12) | open |
| §5 governance (14) | open |

### The next four, in the audit's own suggested order

- **2.5 — reveal flags.** Either Seeker can set *both* flags: consent
  given on someone else's behalf. Fixable with a `WITH CHECK`.
  **But note the second half:** `overall_score` and `category_scores` are
  computed on the phone and posted to the server
  (`zyra_journey_service.dart:376`). The compatibility percentage is not
  trustworthy today and no policy patch fixes that — it needs scoring
  moved server-side. That is a design decision, not a bug fix.
- **2.9 needs YOUR decision, not a fix.** The audit calls it a defect;
  `zyra_wali_link_service.dart` documents the no-Main state as deliberate.
  With no Main Guardian, Family Review has no voter and the Guardian's
  message access closes — oversight silently stops. Either that is
  acceptable and `zyra_remove_guardian`'s guard is what is wrong, or it is
  not and the Guardian page should stop offering the action.
- **2.10** — ✅ **fixed 2026-08-09**, DR-ZYRA-134.

---

## 4b. 🔴 Two things I got wrong today

Recorded because a handover that only lists successes is not a handover.

1. **"Matching had never worked"** overstated the cause. No match has ever
   existed, but Likes were being written until 8 August. Corrected in §1.
2. **"There are two blocking FKs on account deletion."** There is one.
   `matches.suspended_by` cannot fire, because the match row cascades away
   before the constraint is checked. I reasoned instead of testing.
   Corrected in DR-ZYRA-134 and in the audit.

Also, one before-state test omitted its closing `RAISE` and committed
instead of rolling back, writing a single `wali_invites` row to live. It
was removed within the minute and the database re-counted. Every other
test this session rolled back.

---

## 5. Traps found today, recorded so nobody re-finds them

- **`journey_attempts` has RLS ENABLED WITH ZERO POLICIES.** Every row is
  invisible to `authenticated`. Joining it inside any RLS policy makes
  that policy false for everyone and *silently* breaks the feature. It
  would have broken all messaging. Read the lifecycle through
  `zyra_my_attempt_participation` (SECURITY DEFINER) instead.
- **`profile_blocks` RLS hides who blocked you** — deliberately. So an
  inline `EXISTS` on it inside a policy is evaluated as the sender and
  passes for exactly the person it is meant to stop. Use
  `zyra_block_exists()`.
- **A tightened server needs a client that can hear "no".** Hardening
  `open_family_review` would have made refusals more reachable while
  keeping them invisible, because the caller discarded the result. That is
  the 2026-08-07 release blocker's exact shape. Check the caller whenever
  you add a server-side validation.

---

## 6. Git

Last commit before today: **`a6806ad`, 26 July** — 425 changed files ago,
including this note.

**Tracked as OA-ZYRA-180**, with the exact command and the safety check
that was run before recommending it. A daily 09:00 reminder
(`trig_01GAqnsNhhk91qDhBR9rWCc6`) checks whether the commit has landed and
deletes itself once it has.

**There is no remote configured.** A commit puts the work in local
history, which protects against edits and mistakes. It is *not* a backup
against losing the machine. Setting up a private remote is a separate,
worthwhile job.

Git cannot write through the Cowork device bridge (the mount refuses
`unlink()`), so the commit must be run by hand in Terminal. A stale
`.git/index.lock` dated 8 August WAS present and was moved aside; every
`git status` run through this mount leaves another one behind, which is
why the prepared command begins with `rm -f .git/index.lock`.

**Secret scan before recommending the commit:** every file `git add -A`
would stage was scanned for JWT-shaped strings, `sk-` keys and PEM private
keys. **Zero hits.** Seven files match the word `service_role` — all are
grant documentation referring to the Postgres role by name, which is what
those documents are about. `supabase_config.dart`, `oauth_config.dart` and
`SOURCE/build/` are all correctly ignored.

---

## 7. Still needs the Mac

- `flutter analyze`
- `./run.sh` and the four manual tests in §3
- the commit
- `supabase db pull` — the live database is ahead of the repo, and today
  added six more migrations to the file tree
- `TOOLS/zyra_backup.sh`
