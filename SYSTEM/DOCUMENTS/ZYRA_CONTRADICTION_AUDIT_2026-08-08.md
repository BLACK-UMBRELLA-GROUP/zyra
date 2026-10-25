---
id: DOC-ZYRA-0140
type: REPORT
status: CURRENT
feature: GENERAL
purpose: ZYRA — Full Contradiction Audit
links: []
owner: ZYRA chat
---

# ZYRA — Full Contradiction Audit

**Date:** 2026-08-08
**Status:** FINDINGS — nothing in this document has been fixed
**Author:** Claude Opus, six parallel reviews, every high-severity claim re-measured by hand
**Scope:** 279 documents · 109 Dart files · 56 migration files · the live database (`sxoaxonzjqkgajmlagyk`) · both registers
**Method:** the live database is treated as the source of truth for what the system *does*. Documents are claims about it.

A **contradiction** here means two things that cannot both be true. Unfinished
work is not a contradiction and is not listed. 45 found.

---

## 0. Read this part if you read nothing else

Three findings stop the app from working or make it lie about safety. All
three were verified by running SQL as the `authenticated` role against the
live database, inside transactions that were rolled back.

| # | What is broken | Verified how |
|---|---|---|
| **1** | **No match can ever be created.** Every Like, Save and Pass the client sends is refused by the database and the error is swallowed | Ran the exact statement as `authenticated`: `42501 permission denied for table likes` |
| **2** | **Blocking someone does nothing, and reports success.** So does unblocking | Same: `42501 permission denied for table profile_blocks` |
| **3** | **Any Seeker can make themselves Main Guardian of another Seeker**, gaining sect, revert status and ethnicity | `accept_wali_invite` reads the *inviter's* role from a client-writable column |

Findings 1 and 2 are the same shape as the release blocker fixed this
morning: a client write, no matching grant, `catch (_) {}` around it. The app
shows a spinner and returns to the same screen. Nothing errors.

---

> **STATUS 2026-08-09 — all three blockers below are FIXED**, and so is
> §2.4. See DR-ZYRA-130 and DR-ZYRA-131. Each fix was verified by re-running the original statement
> as `authenticated` against the live database, rolled back. §2.2 remains
> OPEN.

## 1. BLOCKERS — the app cannot function

### 1.1 · `.upsert()` is refused on five tables. Matching is dead.

> ✅ **FIXED 2026-08-09** — `ignoreDuplicates: true` at the five broken
> sites (`zyra_discovery_service.dart`, `zyra_journey_service.dart`).
> Proven: `DO UPDATE` → 42501; `DO NOTHING` → succeeds; a mutual pair now
> produces a `matches` row with `status='potential'`.
> `onboarding_answers` and `seeker_details` were deliberately NOT changed
> — both have UPDATE and genuinely want merge semantics.
> One behavioural note: on `journey_phase_checkpoints`, DO NOTHING means
> first-write-wins. Checked against the UI first — the buttons only render
> when no checkpoint exists — so nothing is lost.

**Claim A** — the client writes Likes, Saves, Passes, Salams and phase
checkpoints with a bare `.upsert()`:

```dart
// SOURCE/lib/services/zyra_discovery_service.dart:263
await supabase.from('likes').upsert({'liker_id': user.id, 'liked_id': likedId});
} catch (_) {}
```
Also `saves` (`:255`), `passes` (`:404`), `journey_salams`
(`zyra_journey_service.dart:230`), `journey_phase_checkpoints` (`:432`).

**Claim B** — `authenticated` holds INSERT on all five and **UPDATE on none**.
A bare `.upsert()` sends `Prefer: resolution=merge-duplicates`, which PostgREST
turns into `INSERT … ON CONFLICT DO UPDATE`, and PostgreSQL requires the UPDATE
privilege at plan time whether or not a row actually conflicts.

**Evidence** — run as `authenticated`, rolled back:

```
ERROR: 42501: permission denied for table likes
HINT:  Grant the required privileges to the current role with:
       GRANT UPDATE ON public.likes TO authenticated;
```

A **plain** `INSERT` on the same table as the same role **succeeds**. So the
grants are right and the client verb is wrong.

| Table | INSERT | UPDATE | DELETE |
|---|---|---|---|
| `likes` | ✅ | ❌ | ✅ |
| `saves` | ✅ | ❌ | ✅ |
| `passes` | ✅ | ❌ | ✅ |
| `journey_salams` | ✅ | ❌ | ❌ |
| `journey_phase_checkpoints` | ✅ | ❌ | ❌ |

**Consequence.** No `likes` row is ever written, so
`create_match_on_mutual_like` never fires and **no match can be created by any
user**. Independently, no `journey_salams` row is written, so
`zyra_advance_stage` returns `waiting_for_salam` forever — the Journey is
blocked one stage past where `advanceStage()` blocked it, by a different
mechanism. The user taps Send Salam, sees a spinner, and lands back on
*"Send your Salam to … to begin your journey."*

**Root cause.** Migration `oa168_grant_sweep_stages_1_to_3`, applied **today**.
Its plan asserts at `ZYRA_OA168_GRANT_SWEEP_IMPLEMENTATION_PLAN_2026-08-08.md:59`:
*"Client code exercising any unmatched grant: **None.** Every Dart reference to
these tables is a SELECT."* There are eight `.upsert(` call sites. The sweep
matched policies declared `TO authenticated`; these policies are declared
`TO public`, so the match test missed them.

**Fix.** `.upsert(…, ignoreDuplicates: true)` emits `ON CONFLICT DO NOTHING`,
which needs no UPDATE privilege — and is the actual intent at every one of
these sites. Granting UPDATE would also work but widens the surface.

---

### 1.2 · Block and unblock are silently discarded on the safety path

> ✅ **FIXED 2026-08-09** — `zyra_report_service.dart` now calls
> `zyra_block_user` / `zyra_unblock_user`, the SECURITY DEFINER functions
> that were written and never wired. Proven: RPC round-trip leaves 1 row
> then 0. The missing table grants were deliberately NOT added — the RPC
> also ends any live Journey between the two, and two paths that behave
> differently is invariant I3.

**Claim A** — `zyra_report_service.dart:109` blocks by writing the table
directly; `:127` unblocks by deleting from it.

**Claim B** — `authenticated` has **no INSERT, UPDATE or DELETE** on
`profile_blocks`. The RLS policies `profile_blocks_insert` and
`profile_blocks_delete` both exist and are declared `TO public`, with no grant
behind them.

**Evidence** — as `authenticated`, rolled back:
```
ERROR: 42501: permission denied for table profile_blocks
HINT:  GRANT INSERT ON public.profile_blocks TO authenticated;
```

**And the replacement was written and never wired.** `zyra_block_user(p_other)`
exists, is `SECURITY DEFINER`, is granted to `authenticated`, inserts the block
**and ends any live Journey between the two** via
`zyra_end_match_internal(..., 'safety_concern')`. Grep of all 109 Dart files
for `zyra_block_user` and `zyra_unblock_user`: **not called anywhere.**

**Consequence.** In `reportAndBlock` the return value is discarded —
`if (alsoBlock) await block(reportedId);` — and the method returns `true`
because the *report* stored. Someone reporting harassment is told it worked,
keeps seeing that person, and any Journey between them stays open.

---

## 2. SECURITY — reachable by a signed-in user

### 2.1 · 🔴 Any Seeker can become another Seeker's Main Guardian

> ✅ **FIXED 2026-08-09** — migration `20260809150931`.
> `accept_wali_invite` now reads the inviter's role from `profiles` (not
> client-writable, verified) and REFUSES a mismatch rather than silently
> reinterpreting it.
> Exploit reproduced first: attacker reached `is_main=true,
> status=active`. After the fix — exploit REFUSED, and both legitimate
> directions (Guardian→Seeker, Seeker→Guardian) still work.

`accept_wali_invite` reads the **accepter's** role from `profiles` — correctly —
but takes the **inviter's** role from `wali_invites.inviter_role`, a column the
client writes:

```sql
ELSIF v_invite.inviter_role = 'wali' THEN
  IF v_accepter_role <> 'seeker' THEN RAISE EXCEPTION 'This invite is for a Seeker account'; END IF;
  v_seeker_id := v_accepter_id;
  v_wali_id   := v_invite.inviter_id;   -- never checked against profiles.role
```

Verified: `authenticated` holds INSERT on `wali_invites`, `inviter_role` is in
the INSERT column grant, and the only policy is
`with_check (inviter_id = auth.uid())` — which the attacker satisfies honestly.

`zyra_can_guardian_link` does **not** save this. Its whole body is: both ids
non-null, not equal, and no `matches` row between them. **No role check, no
gender check.**

Then `auto_designate_main_wali` fires and sets `is_main = TRUE` if the target
has no Main Guardian.

**What that buys the attacker.** Main Guardian is the top trust tier:
`seeker_details_select_guardian` (sect, revert status, ethnicity, nationality —
GDPR Article 9 special-category data), `zyra_can_view_profile` clause 2,
`zyra_counterpart_card`, a Family Review vote, and the `is_main` branch of
`messages_select`.

It needs the target to enter the token — but that is exactly the normal
Guardian flow, and nothing in the invite preview reveals that the "Guardian"
is a Seeker account.

---

### 2.2 · 🔴 `open_family_review` accepts any stage pair, and can be self-resolved

> ✅ **FIXED 2026-08-09** — migration `20260809162503`, DR-ZYRA-132.
> `open_family_review` now applies the same four lifecycle tests
> `zyra_advance_stage` does, and enforces the successor map it was
> already refusing on behalf of. `resolve_family_review_if_due` gained a
> staleness guard. Eight tests: the exploit and four other refusals, the
> legitimate path, the 48-hour auto-continue, and a stale review left
> untouched.
>
> The client now HEARS the refusal — `openFamilyReview` returned `String?`
> from a bare `catch (_)` and its one caller discarded it, so hardening the
> server would have made refusals more reachable and still invisible.

`zyra_advance_stage` enforces a fixed successor map and refuses the four gated
transitions with a hint naming the safe alternative:

```sql
raise exception 'gated_transition'
  using hint = 'This transition opens a Family Review Period. Call open_family_review() instead.';
```

That alternative validates **nothing**. Verified: `open_family_review` never
references `journey_stage`; there is **no CHECK constraint** on
`journey_family_reviews.from_stage` or `to_stage`; both it and
`resolve_family_review_if_due` are EXECUTE-able by `authenticated`.

One Seeker, alone, calls `open_family_review(match, 'compatibility_reveal',
'conversation')`, waits 48 hours, calls `resolve_family_review_if_due(match)` —
and the pair is in the Conversation stage with the chat open, having skipped
the Salam exchange, **both Guardian gates**, Phases 1–3 and the Family
Compatibility Stage. No Guardian voted. The other Seeker did not consent.

This also contradicts its own sibling: `wali_review_decision` refuses to
continue unless a Main Guardian affirmatively voted.

---

### 2.3 · Other reachable defects

| # | Contradiction | Evidence | Reachable |
|---|---|---|---|
| 2.4 ✅ **FIXED 2026-08-09** (migration `20260809161716`, DR-ZYRA-131 — blocks honoured in both directions, ended Journeys and closed conversations refused; six tests, and the push stops because the trigger only fires on a successful insert) | `messages_insert` never checked `conversations.status`, `journey_stage` or `profile_blocks`. Blocking removes someone from your view but leaves **their channel to you open**, and `notify_new_message` pushes their name + 140 chars of content to you | policy `with_check` mentions status: `false`; blocks: `false` | On any match |
| 2.5 | Either Seeker can set **both** reveal flags and overwrite `overall_score` / `category_scores` — `journey_compatibility` UPDATE is granted with no WITH CHECK. A mutual-consent flag one party can set for the other is not consent | `has_table_privilege('authenticated','journey_compatibility','UPDATE')` → `true` | On any match |
| 2.6 ✅ **FIXED 2026-08-09** (migration `20260809170940`, DR-ZYRA-133 — the accept path now calls `expire_wali_invite_if_due()` as a predicate, keeping one definition of expired) | `accept_wali_invite` **never checked expiry**. The only expiry enforcement is in `preview_wali_invite`, which the client is trusted to call first | no `expires_at` in the accept path; 0 functions raise an expiry error | Today |
| 2.7 ✅ **FIXED 2026-08-09** (same migration — UPDATE **revoked entirely** from `authenticated` after auditing every write path; `wali_invites_update` dropped with it. Note: it was not three columns, it was **all of them**) | `wali_invites` UPDATE grant covered `status`, `expires_at`, `token`. The inviter can move `revoked`/`expired` back to `pending` and push `expires_at` out indefinitely | column grants include all three | Today |
| 2.8 | Article 9 data is released at the **cheaper** tier. `guardians_for_unlocked` (names) requires `paid_plus_single`; `seeker_details_for_unlocked` (sect, revert status, ethnicity) accepts **any** unlock row | `paid_plus_single` present in one, absent in the other | On any unlock |
| 2.9 ⛔ **REJECTED 2026-08-09 — not a defect** (DR-ZYRA-133). `zyra_wali_link_service.dart` documents the no-Main state as deliberate: *"demoting can leave a Seeker with Guardians and no Main. That is reachable and the Guardian page handles it."* Two positions disagree; the Founder decides. Building the guard would have removed a documented capability on the strength of an audit note | `zyra_clear_main_guardian` has none of the guard `zyra_remove_guardian` enforces for the same invariant — one call leaves a Seeker with Guardians but no Main, which is the state the other function exists to prevent | `main_guardian_must_be_reassigned` present in one, absent in the other | Today, 1 RPC |
| 2.10 ✅ **FIXED 2026-08-09** (migration `20260809171807`, DR-ZYRA-134 — `accepted_by` now `ON DELETE SET NULL`, so the inviter's row survives with the departed member dissociated). Your count of ONE blocking FK was correct; a claim that `matches.suspended_by` was a second one is withdrawn — it cannot fire, because the match row cascades away first | `delete_own_account` failed with a raw FK violation for **anyone who has accepted a Guardian invite**. 66 of 70 FKs cascade; `wali_invites.accepted_by` is `NO ACTION` and the invite row survives the accepter | `confdeltype='a'` on that FK | On first accepted invite |
| 2.11 | `has_article9_consent()` exists, `consents` has 24 rows, and **nothing calls it**. Sect, revert status and ethnicity are writable with no consent row | 0 functions, 0 policies reference it | Today |
| 2.12 | `notification_preferences` records consent across five categories that **no notification path reads**. `create_notification` is unconditional. Opting out changes the settings screen and nothing else | 0 functions reference both | Today |

---

## 3. MONEY

| # | Contradiction | The two claims |
|---|---|---|
| 3.1 | **All entitlement gating is client-side.** The Upgrade button grants ZYRA One free | `upgrade_screen.dart:160` `AppState.instance.setPlan(ZyraPlan.one)` — no DB write · **0** RLS policies reference subscriptions. The only server-side plan check in the database is `suspend_journey` |
| 3.2 | **One £34.99 subscription grants Guardian+ to every linked Guardian, account-wide** | Grant Rules V4:100 *"includes **one** Guardian+ entitlement"*, V4:124 *"specific to the Seeker–Guardian relationship"* · `wali_has_wali_one()` takes no arguments and `EXISTS` over all active links. Live: one Seeker, two Guardians, both resolve `true` |
| 3.3 | **Upgrade screen under-quotes all four unlock prices** by £1–£5 — and the same binary holds the correct figures on another screen | `upgrade_screen.dart:68-73` £0.99/£2.99/£1.99/£4.99 · `profile_unlock_screen.dart:106-109` £1.99/£7.99/£2.99/£9.99 |
| 3.4 | **DR-075 still ratifies the old prices as Active**, and the index says the register wins | `DECISIONS_V1.md:3209` £0.99/£2.99 · every current doc £1.99/£7.99. The rename and reprice were **never entered in the Decisions Register** |
| 3.5 | **Server will charge twice** for a profile already unlocked at Plus. The superset rule lives only in Dart | Profile Unlocks Summary:292 *"charging again for a part already bought would break the permanence rule"* · `zyra_unlock_profile` matches `unlock_type` exactly |
| 3.6 | **"Unlimited Saves" sold, capped at 50** | Spec V5:351 · `browse_screen.dart:182` `zyraOneSaveLimit = 50` |
| 3.7 | **Basic limits: 10/day documented, 20 lifetime coded** | Spec V5:306-307 *"10 per day"* · `zyraBasicConsiderLimit = 20`, and both checks test a cumulative list with no time window — 10 Saves *ever*, not per day |
| 3.8 | **"Unlimited Paused Journeys" cannot exist** | Spec V5:356 · `matches_status_check` permits only `potential/active/ended`; `attempts_pause_needs_active` *requires* `status='active'` for a pause to be recordable |
| 3.9 | **Ad-free is listed as a ZYRA Basic benefit** on the paywall — the inverse of the standard and the code | `upgrade_screen.dart:50` in `_basicFeatures` · `ADVERTISING_STANDARD:24-25` and `browse_screen.dart:617` both make ad-free the ZYRA One benefit |
| 3.10 | **Four vocabularies for two capability sets**, including in the legal acknowledgement | `zyra_plan_names.dart` header says *"Standard Wali / Wali One"*, its own mapping eight lines later says *"Standard Guardian / Guardian+"*, `upgrade_screen.dart:130` says *"Guardian One"*, the live function is `wali_has_wali_one` |

---

## 4. DOCUMENT vs. REALITY

| # | Contradiction | The two claims |
|---|---|---|
| 4.1 | **Does a paused Journey free the slot?** Two `CURRENT_VERSION` documents, both Founder-approved **the same day**, say opposite things. The database says no | JOURNEY_SUSPENSION V1:100-101 *"Slot freed immediately"* · JOURNEY_ENTITLEMENT_DECISION V1:120 *"Paused still consumes the Active slot"*. Consequence: the Basic-Seeker protection that made premium-gated Pause defensible does not exist, and `other_party_in_active_journey` is unreachable dead code |
| 4.2 | **Restart is documented as built; it refuses unconditionally — and the End dialog still promises it** | JOURNEY AVAILABILITY:277 *"Built 2026-07-26… Either party may choose to Restart"* and `journey_flow_screen.dart:172` *"Restarting later means going through the full process again"* · `restart_journey` raises `restart_requires_mutual_consent` before doing anything. This is the highest-consequence tap in the product |
| 4.3 | **Endings notify the two Seekers only; the approved matrix says both Guardians are pushed** | LIFECYCLE V3 §11 *"End — ordinary: push, push, push"* · `zyra_end_match_internal` makes exactly **one** `create_notification` call. Pinned in place by suite assertion 35 asserting `1/0` |
| 4.4 | **Half the Guardians see "No Journey yet" while their ward is mid-Journey** | WALI_ARCHITECTURE V6:349 grants all Guardians *"View Journey progress"* · `zyra_wali_journey_service.dart:123` drops every Journey whose counterpart card returns null, and only Main gets a card. Live: 10 of 20 active links are non-Main |
| 4.5 | **Every Guardian is told at onboarding they can read the conversation; `messages_select` grants it only to Main** | `wali_onboarding_flow.dart:128` *"you can read the conversation once a Journey becomes active"* · policy requires `r.is_main IS TRUE`. The Seeker is separately told at link time that this person reads their messages — overstating what they are consenting to |
| 4.6 | **Family Review authority has three answers** | V6:236 every Guardian votes · V6:251 Primary only, and Primary requires Guardian+ · `wali_review_decision` enforces Main-only with **no** entitlement test. `wali_has_wali_one()` has zero callers in the database |
| 4.7 | **Guardian gender: banned, used as the canonical example, and unenforced** | V6:86 *"a male guardian"* and V6:696 lists female Guardians as deferred · V6:291-301 makes "Mum" a Primary Guardian in its worked example · no gender predicate in the schema or `accept_wali_invite`; live data already holds a female Guardian link |
| 4.8 | **A CURRENT_VERSION policy tells the Founder to reject the rule that already shipped** | WALI_REQUIREMENT_AND_ACCESS_POLICY:103 *"Option B blocks every Journey… only viable if ZYRA introduces a male-side guardian concept"* · `zyra_advance_stage`'s `wali_gate` requires a Main Guardian on **both** sides. Option B is live. The document also misquotes V6 to justify the rejection |
| 4.9 | **The one actionable Guardian prompt can never fire** | `zyra_guardian_activity` queries `rev.status = 'open'` · `journey_family_reviews_status_check` permits only `pending/continued/paused`. The dev scenario hard-codes the row, so the one place it would have been caught demonstrates it working |
| 4.10 | **Resume-time auto-End is documented as current; the exception is marked unthrowable** | JOURNEY MANAGEMENT:50 *"the paused Journey Auto-Ends"* · `resume_journey` refuses and leaves it intact; `JourneyAutoEndedException` is `@Deprecated` *"can no longer be thrown"* |
| 4.11 | **Product Spec V5 cites Guardian Architecture V4 and V6 for the same subject** | V5:300 and :367 → V4 (an archive) · V5:336 and :344 → V6 (current). The Basic-tier Guardian section routes readers to a two-revision-old permission model |
| 4.12 | **Two `acceptInvite` error branches can never fire** | Dart matches `'This invite is for a Guardian account'` · the server raises `'…for a **Wali** account'`. The terminology rename reached the Dart string comparisons but not the SQL `RAISE`. A user who redeems the wrong invite type gets *"That didn't work. Check the code and try again."* — untrue and unactionable |

---

## 5. GOVERNANCE — the records disagree with each other

| # | Contradiction | Detail |
|---|---|---|
| 5.1 | **Two decisions registers with disjoint content, and nothing says which governs** | `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` (untagged) vs `SYSTEM/DOCUMENTS/ZYRA_DECISIONS_CURRENT_VERSION_V2.md` (tagged). The register contains **zero** of the ~20 decisions in the CURRENT_VERSION document. Neither mentions the other. CLAUDE.md and the index both point only at the untagged one — while your own rule says the tagged one wins |
| 5.2 | **Both registers say "END OF DOCUMENT" with roughly half their entries below it** | `DECISIONS_V1.md:2789`, with 57 of 124 decisions after it — including every August decision · `OUTSTANDING_ACTIONS_V2.md:4424`, with 58 of 162 after it. Any reader or tool that stops at the marker concludes the last decision was DR-067 |
| 5.3 | **The documentation index hands out two identifiers that are already in use** | Index:356-357 says next are `OA-ZYRA-141` and `DR-ZYRA-104` · both were issued long ago; the registers say `OA-ZYRA-178` and `DR-ZYRA-125`. Following the index files a duplicate on top of an unratified Guardian-privacy proposal |
| 5.4 | **TREEVIEW is the declared authority on what files exist, and names only superseded versions** | Lists `BROWSE_UX_SPEC…V3`, `JOURNEY_CAPABILITY_GRANT_RULES…V3`, `WALI_ARCHITECTURE…V5`, `PRODUCT_SPEC…V4`. Contains **zero** of the six real current filenames. `WALI_ARCHITECTURE_CURRENT_VERSION_V5.md` is cited 30 times repo-wide and exists in no form |
| 5.5 | **The OA register's metadata overstates its contents by 16, and two cited OA IDs were never issued** | Metadata claims an unbroken OA-001→OA-ZYRA-177 run; the file holds 162 entries with a 15-wide hole at 105–119. `TERMINOLOGY_STANDARDS_V1:15` cites `OA-105`; `DR-074` cites `OA-117`. Neither exists |
| 5.6 | **The index claims to list every governed document; 37 of 56 are absent** | Including `ZYRA_ENGINEERING_INVARIANTS_CURRENT_VERSION_V3` — the document that says *"These outrank feature documents"*. Someone onboarding via the index never learns the invariants exist |
| 5.7 | **Save/Consider limits: three CURRENT_VERSION documents, three sets of numbers** | Basic Save 5 / 10 / 10 · Basic Consider 25 / 10 / 10 · ZYRA One Save 15 / unlimited. The Decisions doc claims its numbers are already implemented |
| 5.8 | **Incoming Potentials was rejected by a ratified DR and is still sold four times in the current Product Spec** | DR-ZYRA-119 (2026-07-28) *"**rejected**, not merely delayed"* · Spec V5:508 *"ZYRA One feature"*, with a four-row behaviour matrix. V5 predates the rejection by two days and no pass has removed it |
| 5.9 | **DR-ZYRA-079 is simultaneously RATIFIED, "proposed, not yet accepted", and undefined** | `DECISIONS_V1.md:3441` *"RATIFIED 2026-07-25"* · `:3454` *"Decision (proposed, not yet accepted)"* · `ZYRA_DECISIONS_CURRENT_VERSION_V2:421` *"Method undefined"*. Two weightings are in play (+2/+1/-3 vs 1/0.5/0) and the 81% figure and every worked example are built on the unratified one |
| 5.10 | **OA-ZYRA-147 is Open and "not designed or built" for a ledger that shipped** — and cites retired prices from a document that declares them superseded | Register:7566 vs `unlock_credits` + `zyra_unlock_profile()` live |
| 5.11 | **OA-ZYRA-134 and CLAUDE.md disagree on the last commit date** | Register: *"no commit since 2026-07-03, 91 uncommitted files"* · CLAUDE.md: 2026-07-26, 345 files. One of them is wrong about whether three weeks or five of work is unbacked |
| 5.12 | **Naming Conventions asserts a Rule 6 it does not contain** | `:38` *"Rule 6 applies now regardless"* · `## 5. Rules` lists 1–5 |
| 5.13 | **ZYRA PRICING References.md still governs the tier structure its own Summary.md retired** | Summary:139 *"retired 2026-07-12… not merely renamed"* · References:43 *"must stay in sync on tier names and structure"* for Basic/Pro/Premium |
| 5.14 | **DR-ZYRA-123 cites invariant I10, which has never existed** | The invariants document defines I1–I7 across all three versions. **This one is mine** — I wrote DR-ZYRA-123 today and cited a proposed invariant as though ratified. It should read I1 only, or I8–I10 should be ratified into V4 |

---

## 6. What I checked and found clean

Worth recording, so nobody re-investigates:

- **All 41 RPCs the Dart calls exist** with matching parameter names and grants.
- **All 32 columns named in `.select()`** exist and are readable. No Dart selects `profiles.date_of_birth` — correctly withheld.
- **No `SECURITY DEFINER` function is EXECUTE-able by `anon`.** All 68 set `search_path`. All 52 reachable by `authenticated` perform a caller check. The dev/mock functions are all gated on `email LIKE '%@zyra.test'` server-side.
- **`profile_photos` visibility matches `zyra_can_view_profile` exactly** — verified by impersonation, not by reading: as a female Seeker, 70 profiles visible, 70 photo-users visible, and zero photo rows visible for a profile she cannot view.
- **Safety-ending concealment is sound.** `zyra_match_ending` mirrors `matches_select` and downgrades `safety_concern` to `prefer_not_to_say` for everyone but the person who raised it, backed by two CHECK constraints.
- **One-active-Journey is doubly enforced and the two enforcements agree** — both constraint triggers take advisory locks in the same participant order.
- **`matches` ↔ `journey_attempts` mirroring is complete.** Every write path maintains both. No Dart file references `journey_attempts` at all, consistent with "matches stays authoritative until step 7".
- **CHECK-versus-literal sweep across all 76 function bodies** found exactly one mismatch (4.9). Fourteen other enumerated columns all agree.
- **The Subscription Continuity Principle is correctly implemented.** No paid state destroys a relationship; `resume_journey` deliberately carries no plan check.
- **DR identifier sequence is intact** — 124 entries, no duplicates, no gaps. OA identifiers have no duplicates either (only the 15-wide hole in 5.5).
- **No duplicate CURRENT_VERSION filenames** for any system; no dated archive newer than its current version.

---

## 7. Suggested order

1. **1.1 and 1.2 together** — one migration. Change eight `.upsert(` sites to `ignoreDuplicates: true`, and wire `zyra_block_user` / `zyra_unblock_user`, which already exist and do more than the direct writes did.
2. **2.1** — read the inviter's role from `profiles`, not from the invite row. Two lines.
3. **2.2** — validate `p_from_stage` against `matches.journey_stage` and `p_to_stage` against the successor map, inside `open_family_review`.
4. **2.4, 2.5** — add the missing predicates to `messages_insert`; narrow the `journey_compatibility` grant to the caller's own reveal column.
5. **2.9, 2.10, 2.6, 2.7** — small, each self-contained.
6. **5.1 and 5.2** — until the two registers are reconciled and the stray END OF DOCUMENT markers are removed, every other document fix risks being written against the wrong record.
7. Money (§3) before any payment SDK is attached. None of it can charge anyone today.

**One caveat on coverage.** Six reviews plus my own verification is thorough,
not exhaustive. I verified every finding in §0–§2 by hand against the live
database. §3–§5 rest on the agents' quoted evidence, which I spot-checked but
did not re-run line by line. The `APP/` UX specifications and the onboarding
question banks had the lightest treatment.
