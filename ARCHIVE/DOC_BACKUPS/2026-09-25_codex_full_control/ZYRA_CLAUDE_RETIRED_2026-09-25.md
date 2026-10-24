# ZYRA — Session Rules

**Read this before doing anything.** It exists because README instructions
demonstrably do not survive session boundaries: the same device-testing
mistake was made on 2026-07-19 and again on 2026-08-01, by different
sessions, with the fix documented in `SOURCE/README.md` both times.
A file that sessions actually load at startup is the only thing that works.

> **CURRENT OPERATING GUARD — AD-AIOS-109 (2026-09-09):** the active route is
> **Founder ↔ Codex**. Fable/Claude remains stepped back; loading this file or
> Claude becoming available does not restore that authority. Claude sessions
> are read-only unless given a bounded Founder task. ChatGPT is used only when
> the Founder explicitly requests it for a named matter. Codex may build and
> internally verify but never approves; only the Founder approves.

---

## 0. How to write to Shakeel

Founder feedback, 2026-08-01, via ChatGPT: responses read like
architecture papers rather than conversation. He has had to ask ChatGPT
*"what is he actually saying?"* more than once. The engineering was right;
the delivery wasn't.

**Every response starts with 2–5 plain bullets.** What happened, what it
means, what needs a decision. Then detail underneath for anyone who wants
it. He should never have to read three paragraphs to find the answer.

- Lead with the conclusion, never the reasoning.
- Bullets before prose.
- Say "this is broken" / "this is fine" / "I need a decision on X" in
  those words.
- Detail goes *below* the summary, not woven through it.
- Short. He writes in one-line bursts; match that energy.

Don't drop the detail — it has caught real bugs. Just stop making him dig
for the point.

---

## 1. Running the app on Shakeel's phone

**Give him this, and nothing else. ONE LINE, joined with `&&`:**

```
cd "/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE" && ./run.sh
```

Shakeel confirmed this exact form twice on 2026-08-08: *"THIS IS THE
CORRECT VERSION"*, then *"THIS IS NEW TERMINAL CODE."* It was previously
written here as two separate lines, which is two pastes and two Returns.

**Do not split it. Do not put anything in front of it. Do not offer a
variant beside it.** The second correction came right after a session
handed him a `flutter analyze | grep …` one-liner starting with the same
`cd` — two near-identical commands to choose between is worse than one
command. Give this line alone. Offer `flutter analyze` ONLY if he asks for
it, or if a build has actually failed.

> **ONE ACTIVE APP — FOUNDER OVERRIDE 2026-09-12 / OA-ZYRA-286:** `SOURCE/`
> serves one Flutter product, **ZYRA**. The Founder withdrew the separate ZYRA
> Test target; its active native/runtime/server setup and three approved
> Test-only cloud resources are retired, with history preserved in messages
> 112–113. An ordinary UI, copy, accessibility, product-behaviour or business-
> logic change is implemented once in the main source. Protected company
> Founder preview tools exist only locally when the main app is built with the
> explicit default-OFF internal flag, pinned company Founder UUID, exact main
> endpoint and a refreshed protected role. Personal and ordinary accounts keep
> normal member behaviour; email text alone grants nothing. `./run.sh` selects
> the main app. Any explicit unknown, unsupported or retired flavour/Test mode
> refuses; it never defaults or falls through to Production. Missing,
> malformed or mixed protected-build configuration locks before any backend
> connection. DR-ZYRA-228/229 remain historical decisions beneath this named
> override. The current Settings & Identity, Developer Control and App Store
> runbook documents hold the full boundary and live-status gates.

**The splash is 3s and brand purple, and it is NOT a loading state.**
DR-ZYRA-125 and DR-ZYRA-126. Cold start plays it; anything re-entering
`AuthGate` inside a running app passes `playSplash: false` and gets
`ZyraLoading` instead. Never show the splash for a gap — that was the
Developer Access bug of 2026-08-08.

**Use `ZyraLoading`, never `CircularProgressIndicator`.** 38 occurrences
across 23 files still to migrate; do them as you touch the file, not in a
sweep — ~16 are inside buttons and images where the track will not fit.
Style is one constant: `kZyraLoadingStyle` in `widgets/zyra_loading.dart`.

**Never write a Journey stage label. There is one map.**
DR-ZYRA-129 — `SOURCE/lib/data/zyra_journey_stages.dart`. Three screens each
had their own switch over the same eight strings and all three had drifted;
one of them told a Seeker in Family Compatibility that they were still "In
the Pre-Journey Ritual". Labels, guiding questions and the Family Review
override all come from that file. Extend it by adding a FIELD — icons,
colours, descriptions, localisation — never by starting a second mapping.
`phase_1/2/3` are stored values only; the member reads Faith & Values,
Building a Life, Navigating Life.

**A Family Review override on a LIST needs the batched lookup.**
`ZyraJourneyService.fetchOpenReviewMatchIds()`, one query. `fetchFamilyReview()`
is per-match and correct only on a detail screen — per card it is N+1.

**Never tell him to run plain `flutter run`.** That installs a DEBUG build.
iOS kills debug/JIT apps the moment the cable is unplugged and refuses to
cold-launch them from the icon. It looks exactly like "the app is broken"
and it is not — it is build mode. This has cost two sessions already.

`./run.sh` defaults to `--profile` (survives unplugging).
`./run.sh dev` is debug + hot reload — **only** offer this if he explicitly
wants tethered live-tweaking, and say the cable must stay in.

If he reports "the app won't open", check in this order:

| Fingerprint | Cause |
|---|---|
| Silent white flash and close, right after unplugging | Debug build. Re-run `./run.sh`. |
| Dead/frozen splash **while still attached** | Launch-path failure — see `main.dart`'s `Supabase.initialize` guard. |
| **"Untrusted Developer"** on first launch after install | **Not a bug.** The signing certificate has not been trusted on that device yet. Settings → General → VPN & Device Management → tap the developer profile → Trust. Needed once per certificate, and again after each reinstall with a new one. |
| iOS alert "Unable to Verify App" / "no longer available" | Provisioning expiry. Free Apple teams expire every 7 days. Reinstall. |
| Fails at build/install, never launches at all | Signing, Runner target, or a real compile error. |

**Signing/delivery facts (source measured 2026-09-12; Apple post-verified 2026-09-13):** the
source bundle ID is `app.zyraconnect.zyra` on iOS and Android (DR-ZYRA-218).
Runner Debug/Profile/Release now use automatic signing with paid Team
`9Y7Z8F36SJ`, and `Runner.entitlements` carries Sign in with Apple `Default`.
The Production App Store Connect record is now verified as `ZYRA Connect`
(Apple ID `6810741513`), with runtime name `ZYRA`. Production build `1.0.0
(3)` is internal `Testing` in `Founder Internal`; build 2 is retained.
Automatic distribution is OFF,
only `admin@zyraconnect.app` is included and no public/external distribution
is authorised. Build 3's one-use upload succeeded and its assignment is
post-verified in mailbox 116; actual Founder device acceptance remains pending.
The separate Test programme is cancelled. This does not authorize any future
archive/upload. Founder accepted local Terminal for quick UI changes and
batched TestFlight for remote testing; secure persistent upload authentication
is a future separately gated setup, not a credential change made here.
Read the current App Store runbook and
never infer future Apple state from local signing bytes.

### 1.1 There is no App Store Sandbox to sign into

Asked 2026-08-01: *"in my Apple developer account, why ain't I signed in on
sandbox?"*

Because **ZYRA has never made a StoreKit call.** Verified against
`pubspec.yaml`: there is no `in_app_purchase`, no StoreKit plugin, no
RevenueCat, no Stripe. The whole dependency list is Supabase, Google Fonts,
image_picker, the two sign-in packages and crypto.

The **Sandbox Account** row in iOS Settings only appears once an app on that
device has actually initiated a sandbox transaction. Nothing has, so there
is no row and nothing to sign into. Creating sandbox testers in App Store
Connect will not make it appear either.

Every "purchase" in the app today is local or a mock RPC:

| Surface | What actually happens |
|---|---|
| Upgrade to ZYRA One | `AppState.setPlan(ZyraPlan.one)` — in memory only |
| Get Guardian+ | `mock_purchase_wali_premium()` — writes a row, takes no money |
| Developer Access plan switch | `mock_set_wali_plan()` |

Both RPCs are restricted to `@zyra.test` accounts and **must be dropped
when real payments land** (audit item #20).

So the order is: add a payment SDK → declare products in App Store Connect
→ then sandbox testers become relevant. Not before.

---

## 2. Current approval model — AD-AIOS-109

The live model is AD-AIOS-109 and
`BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/
FOUNDER_CODEX_OPERATING_MODEL_CURRENT_VERSION_V1.md`: Founder ↔ Codex is the
active route; Fable/Claude remains stepped back; ChatGPT is engaged only when
the Founder explicitly requests it for a named matter. Where Codex both builds
and files, CODEX PREPARED, CODEX INTERNALLY VERIFIED, FOUNDER GO, EXECUTED,
POST-VERIFIED and FOUNDER ACCEPTED remain separately labelled. Internal
verification may block work but never approves it. Only the Founder can change
this model.

**Historical team structure and routing (AD-AIOS-107, 2026-08-31 — final titles;
history AD-AIOS-097 -> 099 -> 100 -> 105 -> 106 in the group AD
register):** **Codex is Product Designer & Implementation Engineer** —
designs and implements ZYRA production code (still: no git, no migrations
without explicit written Founder authorisation, no self-approval), and is
EXPECTED to challenge designs and flag risk before building. Under the current
AD-AIOS-109 overlay, Codex also performs Operations, Governance & Delivery.
**ChatGPT's historical Lead Product & Systems Architect seat is now
Founder-request-only.** **Fable is
Lead Operations, Governance & Delivery** — governance, registers,
source-of-truth documentation, schedules, delivery/relay and verification
of implemented work when explicitly restored by the Founder; it remains
stepped back today.
HISTORICAL DEFAULT CHANGE ROUTE: Founder -> ChatGPT (shapes) -> Fable (conflict
check: CLEAN = relay to Codex undistorted / CONFLICT = contradiction
report to the Founder, no relay) -> Codex builds -> Fable verifies ->
Founder. **That route is historical and superseded by Founder ↔ Codex under
AD-AIOS-109.** Canonical current statement + status
labels: `BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/
IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V3.md`, "Founder
Change-Request Routing", as overlaid by the Founder–Codex Operating Model. A
session reading this file builds or reviews
what the Founder authorised, produces the evidence demanded, and
stops-and-raises anything that contradicts it.
**Standing state:** ZYRA is in a Founder-led live-testing period (recorded
2026-08-29 under AD-AIOS-106; this supersedes the 2026-08-17 DR-ZYRA-191
feature-pause line that previously stood here and had drifted). The
Founder actively directs product/UI changes; each one flows through the
AD-AIOS-109 Founder ↔ Codex route. ChatGPT or Fable joins only when the Founder
explicitly asks for that named matter. Founder instruction remains
the trigger for every feature change; nothing is self-initiated.

**Cross-model agreement is not build authorization.** Standing Founder rule:
any implementation gets flagged to Shakeel for approve/deny first, however
settled a discussion appears — and his direct instruction in conversation
(including a brief he relays himself) IS that approval; do not ask twice.
Discuss and propose freely; do not ship unasked.

### Approval is not "stop thinking"

Founder, 2026-08-06:

> *"Approval should never mean 'stop thinking.' It should mean 'this is our
> current best decision until evidence suggests we should improve it.'"*

Treat approved architecture as **authoritative but not beyond review**. If
implementation uncovers evidence that an approved design is incomplete,
inaccurate, or can be materially improved, **raise it before implementing —
never work around it silently.**

This is not licence to relitigate settled decisions on preference. The bar
is *evidence*, produced by doing the work. OA-ZYRA-156 met it four times:
V3 said fifteen policies asking one question and there were nineteen asking
four; V3's migration cost omitted eleven RPCs; a boolean participant model
would have exposed Seekers' private phase answers to Guardians; and an
approved function signature would have let any user ask whether any other
user was party to any Journey.

Each was an approved design meeting reality. Each was raised, decided by the
Founder, and the architecture changed — rather than the implementation being
bent to fit an assumption already known to be false.

---

## 3. Verification — the project's known failure mode

The 2026-07-26 engineering audit found that ZYRA's root problem is not
architecture or skill, it is **unverified work**. Three of four Critical
findings were fixes designed correctly, implemented plausibly, and never
checked:

- a DOB column `REVOKE` that ran cleanly and did nothing
- `profile_complete`, filtered on in three places and written in none
- a `kReleaseMode` guard applied to one file and not the three that mattered

Therefore:

- **Prove security changes empirically.** "The migration ran" is not
  evidence. Run `has_column_privilege`, attempt the denied read, show the
  result.
- **Never leave a silent `catch`.** There are 64 in the codebase and zero
  logging, which is why the above stayed invisible for a month.
- **Check the runtime, not just the source.** Code that exists is not a
  capability that works — `score_candidates()` is real code that has never
  executed against real data (`onboarding_answers` is empty).

**Flutter availability is environment-specific; check it rather than
assuming.** The current Mac environment exposes Flutter at
`/opt/homebrew/bin/flutter`, but a cloud or restricted session may not.
When the toolchain is unavailable, say so and give Shakeel the governed
command. `python3 tools/zyra_check.py` catches broken imports, deleted methods
still called, and bad named arguments — it is not a substitute for analyzer
or runtime verification.

---

## 3b. Estimating — the six-layer rule and dependency review

**Founder-approved 2026-08-06.** Full standard:
`APP/Standards/SIX_LAYER_REVIEW_STANDARD_CURRENT_VERSION_V1.md`.

**1. Read six layers · 2. Trace dependencies across them · 3. Verify against
the running system.**

No estimate, review or plan is complete until all six have been read:

**schema · RLS policies · RPC bodies · triggers · client · documentation**

Then, for every object you intend to change, ask **what points at it** —
which RPCs, which client code, which policies, views, grants or helper
functions, which documentation, and which approved-but-unbuilt architecture.

Layer review looks *downward* (what does this contain?). Dependency review
looks *upward* (what breaks if I change it?). A dependency lives in the gap
between two layers and is invisible from inside either — dropping a column
does not announce the eleven functions that read it, and a policy body does
not mention the grant it silently requires. **Ask Postgres — `pg_depend`,
`pg_policies`, `pg_proc.prosrc`, `role_table_grants` — rather than
remembering.**

Three estimates during OA-ZYRA-156 were wrong in the same direction, each
made competently from the schema alone:

| Believed | Actual |
|---|---|
| 15 RLS policies | 19 |
| One authorisation question | **Four distinct patterns** — re-pointing them all at one function would have exposed Seekers' private phase answers to Guardians |
| Nine tables to re-point | Nine tables **plus eleven RPCs** |

**Structure is visible from the outside; behaviour is not.** The schema tells
you what exists. Layers 2–5 tell you what it does.

Counting is not reading — "there are fifteen policies" is layer-1 thinking
applied to layer 2, and the real finding was four different rules, which no
amount of counting would surface.

State any layer you did not review, and the risk that carries. **An estimate
with a named gap is useful; one with a silent gap is not.**

---

## 3c. How migrations are done

**Founder-approved 2026-08-06**, from OA-ZYRA-156. The default for every
major migration, not a one-off.

1. Understand the architecture.
2. Produce an implementation plan.
3. Identify dependencies (§3b).
4. Build in **small, verifiable stages**.
5. Verify each stage before continuing.
6. **Stop and raise** behavioural or architectural discoveries before
   implementing them.
7. Update documentation alongside implementation, not months later.

**Step 4 is what makes step 6 possible.** Raising a discovery is only cheap
if stopping is cheap, and stopping is only cheap if each stage leaves the
system whole. OA-ZYRA-156 paused four times — twice because V3's premises
turned out to be wrong — and never once stranded the project, because every
stage was additive and independently verified. A large stage forces you to
choose between abandoning work and pushing on through a discovery you should
have raised.

Corollary: if a stage cannot be left unfinished safely, it is too big.

---

## 3d. Modelling — bookmarks are a smell

**Founder, 2026-08-06.** Emerged from the badge standard; applies far wider.

> **If something seems to require a bookmark against time, you have probably
> framed the problem incorrectly. Look for the item whose state is
> unresolved instead.**

**Why it holds.** A bookmark — `last_seen_at`, `last_synced`, `last_checked`
— is a fact about the **observer**. The thing you actually care about is
almost always a fact about the **object**.

That difference decides how it scales:

| | Grows with | Drifts? |
|---|---|---|
| observer state | users **×** surfaces | yes — nothing else updates it |
| object state | objects | no — it *is* the thing |

Object state also cannot disagree with what it describes, because it is what
it describes. A bookmark can, and eventually will.

**Worked example.** "How many Journeys changed since you last looked" reads
as history and demands a per-user, per-surface timestamp. Reframed as *"how
many Journeys are waiting on you"* it becomes a query over existing rows —
no new schema, no drift, and a clearer product.

**The corollary that matters most:** two apparent exceptions to the badge
standard both dissolved on reframing rather than needing carve-outs. So when
a rule seems to need an exception, suspect the framing before the rule.

**Good standards get shorter as they are refined, not longer.**

---

## 3e. No undocumented intelligence — implementation handover

**Founder-ratified 2026-08-23 (AD-AIOS-104 / DR-ZYRA-212).** Every
meaningful implementation follows **BUILD → DOCUMENT → TRACE → HANDOVER**.

Codex supplies/updates the governed as-built handover in the same work cycle:
what/why, exact files, architecture and data flow, entry points, developer
controls, mock versus production, migrations, named measurements,
limitations/OAs and next steps. Under AD-AIOS-109, Codex performs the filing
and reconciliation while explicitly separating builder evidence, internal
verification, Founder GO, execution, post-verification and Founder acceptance.
ChatGPT or Fable participates only when the Founder explicitly requests it.
Code complete is not handover complete; neither is Founder approval.

Do not leave a material fact in chat for the next session to rediscover. Full
schema: `BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/
IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V3.md`. ZYRA lifecycle:
`SYSTEM/DOCUMENTS/MASTER_CONTRACTS/ZYRA_EXECUTION_CURRENT_VERSION_V5.md`.

---

## 4. Where things live

| What | Where |
|---|---|
| Flutter source | `SOURCE/lib` |
| Migrations | `SOURCE/supabase/migrations` |
| Run script | `SOURCE/run.sh` |
| Engineering audit | `SYSTEM/DOCUMENTS/ZYRA_ENGINEERING_AUDIT_CURRENT_VERSION_V1.md` |
| Muzz teardown | `BUSINESS/COMPETITOR RESEARCH/MUZZ_TEARDOWN_CURRENT_VERSION_V1.md` |
| Journey stage labels | `SOURCE/lib/data/zyra_journey_stages.dart` — the only place |
| Decisions | `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` |
| Open actions | `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` |

Documents use a single-CURRENT_VERSION model — one `*_CURRENT_VERSION_V*.md`
per system, older versions renamed `<SYSTEM>_<YYYY-MM-DD>_V<n>.md`.
The CURRENT_VERSION document always wins over chat history.

---

## 5. Historical snapshot — 2026-08-12 (non-authoritative)

This section is preserved as dated operational history and must not be used as
the current queue or authority. For current state, read AD-AIOS-109 and the
Founder–Codex Operating Model,
OA-AIOS-379, the live ZYRA decision/OA registers and the relevant
CURRENT_VERSION implementation handovers. Do not rewrite product status from
this snapshot by inference.

**Rewritten in the 2026-08-12 stewardship pass** (the previous §5 was four
days stale — the same defect this section's own opening paragraph warns
about). Shipped since 2026-08-08 and reflected below: the app-wide Frost UI
consistency pass (2026-08-11 — real ColorScheme, lavender primary
#CEA2D1/plum text, frosted ⋮ menus, purple-gradient sheets, near-black
0xFF1A1220 fully swept); **Pause belongs to both plans, caps 5/10**
(DR-ZYRA-138 — suspend_journey enforces `paused_limit_reached`;
`suspension_requires_one` retired; JOURNEY_SUSPENSION_CURRENT_VERSION_V2.md
is the authority); the Start Journey flow now warns it will permanently END
the current Journey and does end-then-start on confirm; Timeline milestones
are trigger-written (and the duplicate `journey_ended` bug that shipped with
the trigger was fixed + deduped, migration 20260811233755); OA-193 scoring
method ratified (plain count, two per-person scores, onboarding completeness
gate); function-EXECUTE hygiene re-closed to H-5's zero with default
privileges hardened (20260811233813); the destructive dev functions now
guard EVERY party of a match, not just the caller (20260811233914).

**§5 was five days stale until this rewrite.** It listed audit C4, H1 and H3
as open; all three were closed on 2026-08-04 and verified. A session reading
the old text would have redone finished work or raised closed alarms. Keep
this section current or delete it — a stale status page is worse than none.

### 🔴 READ FIRST — git cannot write through the Cowork device bridge

**Measured 2026-08-08.** The mounted filesystem refuses `unlink()`. So git
creates `.git/index.lock`, cannot remove it, and **every subsequent git
write fails**. `git add` exits 0, prints
`warning: unable to unlink '.git/objects/../tmp_obj_*'`, and stages
nothing.

**This is why there has been no commit since 2026-07-26.** The
`.git/index.lock` on disk was dated `2026-07-26 15:39` — the same minute
as the last successful index write. It is not neglect and it will not fix
itself; every attempt from a bridged session has failed the same way and
will keep doing so.

**Any session reading this: do not try to commit through the bridge.**
Clearing the lock, retrying, or moving it aside does not help — the next
operation recreates it. The commit must be run by Shakeel in Terminal on
the Mac, or by a Cowork task started with "On your computer" rather than
"In the cloud". Stale locks left by failed attempts are named
`.git/index.lock.*` and are safe to delete.

### Two milestones, Founder-agreed 2026-08-06

**Milestone 1 — finish OA-ZYRA-156.** In order:
Family Review RPCs · trigger functions · ~~suspend/resume~~ (done — and the
entitlement model changed under it, DR-ZYRA-138: both plans, caps 5/10) ·
**promote/end (own verification pass)** · Dart migration · final cleanup ·
~~120-profile Chapter 2 backfill~~ (done 2026-08-10) · documentation.

Spec: `SYSTEM/DOCUMENTS/ZYRA_JOURNEY_RPC_MIGRATION_PLAN_CURRENT_VERSION_V1.md`.
Already done and verified: stages 4a, 4b, and 4e part 1
(one-active-Journey-per-person). Nothing is half-migrated — `match_id` and
the `matches` lifecycle columns are still present and authoritative.

**Milestone 2 — the rest of DR-ZYRA-121.**
~~OA-157 protection_holds~~ (built 2026-08-10) · ~~OA-159 Request New
Journey~~ (built 2026-08-10) · OA-160 reference codes · OA-161/162
notifications · OA-163 audit log.

Proceed as approved implementation. Raise only: new evidence affecting an
approved design, behaviour outside approved scope, or a new security,
privacy or governance concern.

### Open, and NOT yours to close

- **Three solicitor questions**, encoded as `pending-legal` in column
  comments so they cannot be answered by accident: whether messages the
  other party sent appear in a subject access export; whether their ratings
  of you do; whether evidence attached to a report does.
- **`v_ch2_weight = 1`** in `score_candidates()`. Still open — but the
  backfill it was waiting on is DONE (2026-08-10, UK-representative, Founder
  instruction "match the real UK distribution"). See
  `SYSTEM/DOCUMENTS/ZYRA_CHAPTER2_BACKFILL_AND_WEIGHT_FINDINGS_2026-08-10.md`.

  The numbers, measured over 10,368 pairs: at weight 1 Chapter 2 moves the
  final score by **5.1%** — the earlier guess of "a few percent" was right.

  **But do not raise it yet, and this is the actual finding.** English is in
  100% of profiles AND 100% of preference lists, so the `languages` rule —
  which greens on ANY match — scores green on **every pair measured**. It is
  26% of Chapter 2's scored mass and it discriminates nothing, while dragging
  every score toward 100. Dropping that one term raises the spread by 43%
  (σ 5.95 → 8.54) and drops the floor from 50 to 25, without touching the top
  of the distribution.

  **Language fix APPLIED** 2026-08-10 (migration
  `ch2_language_match_excludes_english`): English no longer counts toward the
  language match, and a preference list containing only English now SKIPS the
  attribute rather than scoring it as a miss. Spread per viewer 11.4 → 13.2.

  **Chapter 3/4 is now seeded too** — synthetic, 144 Seekers, ~70 answers
  each, every row flagged `is_synthetic`. With both chapters live the measured
  answer is: Chapter 3/4 supplies **133** of `v_max`, Chapter 2 supplies **6**,
  so Chapter 2 is **4.3%** of the score at weight 1.

  `weight ≈ share × 133 / (6 × (1 − share))` — 10% needs 2.5, 20% needs 5.5.

  **METHOD NOW RATIFIED, WEIGHT STILL OPEN — 2026-08-12 amendment.** The
  Founder ratified the scoring method on 2026-08-11 (OA-193a: 0-100 plain
  count, green 1 / yellow 0.5 / red 0; two per-person scores; the centred
  scale and zyra_light_points are gone). The weight — OA-ZYRA-193(e) — is
  now ANSWERABLE but not yet set; `v_ch2_weight = 1` remains in
  score_candidates. The paragraph below is the pre-ratification record:
  *"if you're setting a score system we gotta talk about
  that soon."* The weight was a dial on a method nobody had ratified, and two
  different methods were live — `score_candidates()` uses green +2 /
  yellow +1 / red −3 centred on 50, while the Unlock screen's sample figures
  assume green 1 / amber 0.5 / red 0 on a flat 0-100. Setting the weight
  first would ratify a method by the back door.

  CAUTION, and it is the reason this is still open: full-stack scores now land
  between 77 and 100 with a 10.5-point spread — the engine separates people
  LESS than Chapter 2 did alone. That is a property of the synthetic preference
  model, not of real users. **Do not tune the engine on `is_synthetic` data.**
- **Chapter 2 sect parity** — OA-ZYRA-185. Chapter 4's Hard Requirements are
  per-option; Chapter 2's sect matrix is still per-question. Founder decides
  whether they converge. Not free: `seeker_details` has 24 rows, 8 with the
  flag set.

### Onboarding redesign — RESOLVED 2026-08-10, hold lifted

Founder took **Direction B** (see
`SYSTEM/DOCUMENTS/ZYRA_ONBOARDING_DIRECTION_OPTIONS_2026-08-10.md`).

**The scoring-engine hold is lifted.** The reason it existed was wrong: the
note here said H2 (derive-and-confirm) would change the shape of
`ch4_preferences`. Traced through all six layers, it does not — H2 pre-fills
the same `{question: {option: light}}` map. The only proposal that moved the
schema was H3, via `ch4_hard_requirements`, and that reshape is now DONE:
per-option, with a CHECK constraint refusing the retired `{question: bool}`
form. Migration `onboarding_b_stage1_hard_requirements_become_per_option`,
22/22 verified.

Two behavioural changes worth knowing before touching the engine:

1. **Hard exclusions are evaluated BEFORE, and independently of, the lights.**
   They used to sit inside the `v_light = 'red'` branch, so an exclusion only
   bound if a matching red light also existed. That would have made the
   dealbreakers-first screen silently inert.
2. **A hard-only user is no longer treated as having said nothing.**
   `v_my_hard` now counts alongside `ch4_preferences` and `seeker_details`
   on the flat-50 early return.

**Direction B is complete as of 2026-08-10.** H1 tap-to-exclude, H4 `showIf`
branching and the quick wins all landed the same day. **H2 and H5 remain NOT
approved** — H2 needs its own spec and DR; H5 was deliberately deferred.

Chapter 4's minimum traffic-light taps went **325 → 0**; total deliberate
interactions **518 → 193** (male; 511 → 191 female).

Two of the review's proposals did not survive contact with the real question
set, and both are now measured rather than assumed:

- **H4 saves almost nothing here** — OA-ZYRA-188. All four branching rules the
  review listed describe follow-up questions that do not exist in this set.
  Exactly one real branch was found (`ch3_q3 = No` → skip `ch3_q24`). The
  `ShowIf` mechanism was built anyway because it is small and because it
  forced the pruning fix: a hidden question's answers, preferences and hard
  requirements are now discarded, so nothing is scored on a screen the Seeker
  can no longer see.
- **Batching factual items saves ~8 taps, not ~40** — OA-ZYRA-189, recommended
  against and not built. Category ordering was already concrete-first.
  Pre-populating preferences is H2 in miniature and was refused on scope.

**Before adding any `ShowIf` rule, read its doc comment.** The bar is "asking
this would be nonsense given that answer", not "this is probably implied" — a
hidden Chapter 3 question is a hole in the compatibility data, and
`score_candidates()` treats an absent answer as neutral, so a wrong rule
removes signal silently instead of failing.

Standing rule from that decision, and it is not optional: **a Chapter 4
question's lights are written only once its screen has been shown.**
Pre-seeding all 71 as green on entry would manufacture a complete set of
stated preferences from someone who answered three.

### Regression suites — RUN THESE BEFORE AND AFTER ANY MIGRATION

`SOURCE/supabase/tests/` — two files, 118 assertions, every one mapping to
a defect that was real in this database on 2026-08-08.

| File | Covers | Last run |
|---|---|---|
| `zyra_guard_suite.sql` | visibility & privacy — clause 3, `is_main`, the counterpart card, block guards, grants | **52/52, 2026-08-10** |
| `zyra_journey_suite.sql` | lifecycle — creation, promote, Family Review, pause/resume, endings, one-per-person, **Tier-1**, **ward count**, **OA-174 grandfather** | **63/63, 2026-08-10** |

**The guard suite could not run at all between 2026-08-08 and 2026-08-10** —
see OA-ZYRA-187. Its AREA 4 writes were denied by the results table's own RLS,
added by the same hardening pass that removed the grant as "leftover". The
55/55 above was recorded before that change and was never reproducible. Both
suites are fixed and green as of 2026-08-10; the thirteen migrations applied
in between were checked retrospectively and broke nothing.

Teardown checks are now SCOPED to what each suite created. They used to assert
whole tables were empty, so any unrelated row — a developer's own test Journey
— read as a suite failure.

Both build their own scenario from seeded `@zyra.test` accounts and tear
down. **Run the journey suite before and after step 7** — it drops
`match_id` from thirteen tables and every assertion exercises a path that
step 7 rewrites.

⚠️ **Assertion counts are not the max assertion number.** The journey
suite numbers 0–40 and 46–67 — the 41–45 gap is the old section F,
renumbered to H. 63 checks, not 67. Read the `TOTAL` row, not the tail.

⚠️ **Run whole files, not fragments.** Both suites now create their
results table with **RLS on and no grant** — `public` is PostgREST-exposed
and a results table with RLS off is readable by anon. The advisor caught
four such tables of mine on 2026-08-08.

**The first end-to-end run failed, and the failure was worth having.**
Every assertion had been verified standalone; running the *edited file*
as a whole threw at 29. Two things came out of it, and both are the
reason to run whole files rather than fragments:

1. A test defect — section C's Main Guardian for `fem1` (`565a0208`)
   already actively guarded `male1`, so Tier-1 made the pair unmatchable.
   **This is the second time a test picked a "different" Guardian who
   already guarded the other party.** Assertion 0 now asserts the premise
   (`zyra_can_match(male1,fem1)` is true) before anything else runs.
2. A real product finding — **OA-ZYRA-174**, below.

### Closed 2026-08-08, verified not assumed

- ~~**OA-ZYRA-174 — Tier-1 trapped a paused Journey permanently**~~
  (DR-ZYRA-124, **grandfather**). Tier-1 shipped inside `zyra_can_match`,
  which `resume_journey` re-checks — so a pair who acquired a shared
  Guardian mid-Journey carried on untouched if they never paused, and
  became permanently un-resumable if they paused once. Enforcement
  depended on pressing a button (I3, I4). Now
  `zyra_can_continue_journey` — blocks and Tier-0 only, EXECUTE revoked —
  and `not_eligible_to_continue`, caught in the Dart as
  `NotEligibleToContinueException`. `zyra_can_match` untouched: Tier-1
  still blocks new Likes, matches and promotion.
  **Found only by running the suite as a whole file**, not assertion by
  assertion. Also surfaced: a Guardian link cannot be created over a live
  Journey at all (`romantic_edge_exists`), and four abandoned scratch
  tables of mine were sitting in `public` with RLS off, readable by anon
  over PostgREST — dropped, and both suites now create their results
  table with RLS on and no grant.

- ~~**Guardian surveillance — clause 3**~~. Measured: one Journey with two
  Guardians a side produced a **six-person mutual-visibility clique**,
  gender-blind, four of whom appointed nobody. Closed by four changes
  (clause 3 Seeker-only · `is_main` as a real privilege boundary ·
  `ages_for` capped + singular · `zyra_counterpart_card`), 53 checks, all
  passing. Full record: GUARDIAN & ROMANTIC RULES §7d.
  **Also found and closed:** `zyra_attempt_participants()` was SECURITY
  DEFINER, granted to `authenticated`, and had **no caller check at all** —
  any attempt id returned that attempt's full participant roster.

- ~~**Release blocker — `advanceStage()` silent no-op**~~ (Founder-classified
  2026-08-07). Worse than recorded: the three transitions it served are the
  FIRST three, so **no Journey could leave `compatibility_reveal`** and the
  whole ritual was dead at step one. Replaced by `zyra_advance_stage()`,
  17/17 verified against real rows. Three Founder decisions taken first —
  Guardian Gate needs **both** Seekers' Guardians, leaving the reveal needs
  **both** Continues, and the attempt row is now kept in step. Full record:
  GUARDIAN & ROMANTIC RULES §7c.
- ~~Steps 0, 1 and 1b~~ — `safety_concern` privacy, clause 3 status guard,
  blocking ends the Journey. Same document, §7b.

### Closed since the last rewrite

**Starting again after an ending now exists in its approved form** —
OA-159's Request New Journey shipped 2026-08-10 (`restart_journey()` still
refuses, correctly). And starting a Journey while one is Active is no longer
a server bounce: since 2026-08-11 the dialog states it will permanently END
the current Journey and does end-then-start on confirm.

### Still open

- ~~**No git remote / uncommitted files**~~ — **CLOSED 2026-08-12**
  (OA-ZYRA-134). Founder committed in Terminal (`6f05c05`, 132 files) and
  pushed to a **private GitHub remote: ZYRA-APP-LAB/zyra** (377MB first
  push). Bonus finding: the name collided because the OA-114 automation
  publisher had pushed a snapshot of the OLD workspace layout back in
  July — preserved, renamed **zyra-archive**. The 🔴 bridge box above
  remains true: commits still cannot run through the bridge; future
  commits are a Terminal paste. Outstanding half: the external-drive
  local backup (GIT_REMOTE_DECISION option B) once a drive is named.
- **OA-ZYRA-173** — removing your last Guardian mid-Journey hands your
  family's Family Review vote to the other family. Raised, not fixed:
  the intended behaviour is a Founder call.
- **OA-ZYRA-176** — 🔴 **Tier-1 evaporates if the shared Guardian deletes
  his account.** `zyra_remove_guardian` soft-sets `'removed'`, so check 48
  passes — but `delete_own_account` → `auth.users` → `profiles` CASCADE →
  `wali_links` CASCADE **hard-deletes the row**, and Tier-1 asks whether a
  row exists. No row, no exclusion. Verified chain, 2026-08-08. A Guardian
  who just leaves the app silently un-protects every pair of wards he held.
  **Check 48 currently proves I1 holds while a supported path breaks it.**
- **OA-ZYRA-177** — `wali_review_decision` counts `DISTINCT wali_id`, so
  two Seekers sharing a Main Guardian collapse the Family Review to **one
  vote**. Measured: one 'continue' advanced `phase_1 → phase_2` with no
  second approval. Same line of SQL as OA-173, different way in. May be
  correct — one man, one judgement — but nobody decided it.
- **OA-ZYRA-175** — Tier-0 uses `status = 'active'`; Tier-1 uses
  `('active','removed')`. So retiring a shared Guardian does **not**
  unlock Tier-1 (suite check 48 proves it), but retiring your **own**
  Guardian **does** unlock Tier-0 — the closer relationship is the more
  permissive one, which is backwards and is the exact I1 failure Tier-1
  was written to avoid. **Cannot fire today**: `zyra_can_match` also
  requires both parties be `role='seeker'`, and all 4 Guardians are
  `role='wali'` (measured). **It becomes reachable the day
  `profiles.role` is deleted** — which is item 4 of the dual-role build
  order. Settle it *before* that lands, not after. Raised, not fixed.
- **Concurrent sessions are now a real hazard.** On 2026-08-08 another
  session applied OA-170 migrations at 11:28 and 11:40 while this one was
  mid-build, and the OA register gained items 166–172 between two reads of
  it. Re-read a register immediately before appending; assert on the
  anchor rather than trusting an offset. `OUTSTANDING_ACTIONS_V2.md` also
  contained the "Register Metadata" block **twice**; the empty orphan
  heading was removed 2026-08-12 — one block remains, at end-of-file;
  append before it. Flagged, not silently merged.
- **OA-ZYRA-198 is closed; OA-ZYRA-283's exact production cutover is executed
  and post-verified (measured 2026-09-11).** Both approved migrations were
  applied atomically and in order to project `sxoaxonzjqkgajmlagyk`; both
  harnesses and the complete catalog, ACL, denial, zero-state,
  concurrency/idempotency, application-health and advisor checks passed while
  ZYRA remained closed. The exact `1.0.0 (2)` IPA is now uploaded and `Ready
  to Test`; `Founder Internal` has automatic distribution OFF, only
  `admin@zyraconnect.app`, and only build 2. Founder installation/device
  acceptance remains pending. All eight
  substantive OA-193 record files carry their exact retained statements and
  the body hashes are pinned 10/10. Under the Founder's exact approval, live-
  history duplicates `20260811102840`/`20260811103056` were preserved under
  `SYSTEM/RESOURCES/MIGRATION_HISTORY/OA-ZYRA-198_2026-09-11_CHRONOLOGY_
  ARCHIVE/` and excluded from active replay (209 -> 207 files). The corrected
  104500 -> 110300 -> 111500 sequence now passes. The one authorised unlinked
  zero-state reset next stopped at `20260811153416`, SQLSTATE `42P01`:
  `zyra_onboarding_questions` has no earlier repository creator. The subsequent
  Founder-authorised read-only recovery exhausted active migrations, governed
  archives/snapshots, OA-198 scratch evidence, local Claude/Fable evidence and
  the retained production migration table: the predecessor was ad-hoc SQL and
  its CREATE/INSERT bytes, version, schema detail and statement boundaries do
  not exist in the retained record. The pinned 2026-08-10 Dart source can support
  a deterministic 72-row/71-qid reconstruction, but it is not historical SQL.
  The Founder approved message 079's recommended replay-only treatment. The
  first bridge lives outside the active migration path at
  `SYSTEM/RESOURCES/MIGRATION_HISTORY/OA-ZYRA-198_2026-09-11_RECONSTRUCTED_
  REPLAY_BRIDGE/20260811153415_oa198_reconstructed_question_bank_replay_bridge.sql`
  (28,387 bytes; SHA-256
  `461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055`).
  The Founder then gave its exact one-replay GO. One fresh isolated PostgreSQL
  17.6 reset executed once and stopped inside bridge statement 11, SQLSTATE
  `22023` (`ACL arrays must be one-dimensional`), in the column-ACL
  postcondition. Successor 153416 did not start. No repair, retry or
  post-failure database query followed; message 081 records the exact input,
  raw-log hash and teardown. The executed bridge hash is rejected for
  execution. Do not overwrite or rerun it, and do not edit the eight exact
  bodies. Under a later exact Founder approval, corrected V2 was created
  outside the active path and changes only that ACL query. Its SQL is 28,501
  bytes, mode 0600, SHA-256
  `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1`.
  The read-only PostgreSQL 17 null/empty/nonempty/malformed-ACL runtime harness
  passes, as does one full V2 execution against only its minimal predecessor
  contract; no application migrations were loaded. The Founder then gave a
  separate exact single-use reset GO naming this V2 hash. One fresh,
  credential-free, seedless PostgreSQL 17.6 reset ran from the 207 unchanged
  active files plus V2 only. V2 and the full question-bank successor chain
  passed. The runner later stopped in `20260811233813`, statement 7, SQLSTATE
  `42P01`, because `public.zyra_probe_score` does not exist; the last fully
  completed predecessor was `20260811233755`. Neither staged September
  migration was reached. No repair, retry or post-failure database query
  followed; the stack/network were removed and the VM stopped. Message 084
  records the raw-log identity and teardown. The current replay authority is
  consumed. Exhaustive follow-up found no retained creator SQL/version. A
  bounded read-only live catalog inspection recovered the exact three-column
  table structure without reading row values. The resulting schema-only
  replay bridge is quarantined outside the active path at artificial version
  `20260811233812`, 7,302 bytes, mode 0600, SHA-256
  `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46`.
  It plus unchanged 11233813 passed a network-none PostgreSQL 17.6 integration
  and read-only security harness; four artifact tests pass. Message 085 is that
  pre-execution evidence. The Founder then gave the exact single-use GO naming
  both bridge hashes. One fresh, seedless, isolated PostgreSQL 17.6 reset ran
  the unchanged 207 active files plus both bridges: 209 unique versions. It
  exited 0, applied every version exactly once and reached both September
  migrations. No repair/retry or post-result database query followed; the
  project/network were removed and the VM stopped. Message 086 records the raw
  log and teardown. The one-use replay authority is consumed. The Founder
  accepted that post-verified result on 2026-09-11; OA-ZYRA-198 is closed by
  message 087 and its clean-replay prerequisite is satisfied. The exact
  production Apply GO was consumed by the successful cutover. A fresh
  internal-only `1.0.0 (2)` IPA is verified at SHA-256
  `1e17a1c3475db1bcb01e59415768d94480538bb601aedcdc8fdd706ea1a7b673`;
  it is uploaded and `Ready to Test` in the sole manual internal group. Apple
  reported non-blocking warning `ITMS-90068` because immutable build 2 declares
  iOS 13.0; all three source build configurations now require iOS 15.0 for the
  next build. No retry occurred, and any new archive/upload requires a new
  build number and separate exact Founder authority. Never use `db pull`,
  `db push`, migration repair or production as a repair tool. Messages
  078–086 preserve the complete recovery, reconstruction and execution trail.
- **Nothing happens when a report is submitted.** Rows are written and
  blocking works, but there is no queue, no triage, no notification, and
  `status` never leaves `'pending'`. Raised as **OA-ZYRA-237** (Critical,
  2026-08-17, from Codex's full-app review) — awaits a Founder-approved
  engineering brief. Do not describe reporting as "working" without this
  caveat.
- **120 of 144 seeded Seekers have no Chapter 2 data**, so they all score a
  flat 50. Milestone 1 fixes this. Until then, pick test actors that hold
  `seeker_details` or your test measures nothing — this already produced one
  worthless baseline.

### Closed 2026-08-04, verified not assumed

- ~~C-1 free unlocks -> Article 9 disclosure~~ — reproduced end-to-end, then
  closed with the `unlock_credits` ledger and `zyra_unlock_profile()`.
  `authenticated` holds no write on `profile_unlocks`.
- ~~C-3 privilege escalation (audit C4)~~ — creation and publication behind
  RPCs; column-level grants limit direct writes to name, city, bio,
  visibility. `role='admin'` unreachable.
- ~~C-4 no minimum age~~ — `profiles_adult_only`, plus a 1900 sanity bound.
- ~~H-1 gender segregation client-side~~ — now in `profiles_select` via
  `zyra_can_view_profile()`, with explicit Guardian clauses. A naive version
  would have broken same-gender Guardian pairs, of which the seed data has
  none.
- ~~H-2/H-3 arbitrary UUIDs~~ — both take the same visibility predicate.
- ~~H-5 anonymous EXECUTE~~ — 0 of 35 SECURITY DEFINER functions reachable
  by `anon`.
- ~~Mock data in Browse~~ — all five `return mockProfiles` paths gone; every
  failure logs its reason.
- ~~`resume_journey` auto-ended a paused Journey~~ — OA-164. Not listed in
  V3; found while verifying.

### Closed 2026-08-01

- ~~Developer Access in release builds~~ · ~~`date_of_birth` readable~~
  (column GRANT list is explicit — a NEW COLUMN on `profiles` is invisible
  to the client until added to it) · ~~`profile_complete` never written~~ ·
  ~~free paid subscriptions~~ · ~~unguarded `Supabase.initialize()`~~
