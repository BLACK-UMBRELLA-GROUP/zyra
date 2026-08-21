# ZYRA — Transitional Moments

**CURRENT VERSION V1 · Approved by Founder 2026-08-13 ("yeh i like all of it").**
Registered as DR-ZYRA-147. Design ratified — classification, weights, grammar and draft copy direction. The §5 questions remain OPEN (wording depth, haptics, seen_moments store, Guardian-side moment) and the Active Journey per-stage treatments are being designed in the follow-up gallery before any implementation. No code exists yet; implementation begins only on explicit Founder instruction.

---

## 1. What a ZYRA moment is

A transitional page is the app choosing to spend the user's time. That is only justified when the moment itself is worth more than the screen it delays. ZYRA's advantage is that its product genuinely contains such moments — two people choosing each other, a family joining, a marriage — so the design problem is not inventing drama, it is *not wasting* the drama that is already there.

The grammar every moment shares, so they feel like one product:

- **A breath, then words, then a step.** Dark calm over the gender gradient, one small mark, lines arriving one at a time (about 600ms apart), then a single primary action. Nothing moves fast.
- **Words carry it.** Syne headings, short declarative lines. No confetti, no badges, no hearts (standing rule), no illustration style ZYRA doesn't already own.
- **Always tap-through.** Any tap settles the page instantly to its finished state. A moment the user cannot skip is a toll, and tolls read as disrespect. Nothing here ever blocks twice.
- **One accent per moment.** Frost for thresholds, warm lavender glow for celebrations, near-neutral for closures. Coral appears in no moment — endings are dignified, not alarmed.
- **The next step is named.** Every moment ends by saying what happens now, in one line. Celebration without orientation is a dead end.

### The three weights

| Weight | What it is | Cost to user |
|---|---|---|
| **FULL MOMENT** | Its own page, timed reveal, then action | ~4–6 s, skippable |
| **ONE BREATH** | Single acknowledgement page, two or three lines, one action | ~2 s, skippable |
| **IN-PLACE BEAT** | No page — the existing screen acknowledges (a settle animation, a line, a snackbar) | ~0 s |

"Does this deserve a transitional moment?" usually resolves into choosing a weight, not a yes/no.

---

## 2. ESSENTIAL — the product is poorer without these

| # | Moment | Trigger | Weight | Frequency |
|---|---|---|---|---|
| E1 | **Match Created** | Mutual Consider creates the match | FULL | Every time |
| E2 | **Journey Begins** | promoteToActive succeeds | FULL | Every time |
| E3 | **Open Conversation unlocked** | Stage reaches `conversation` | FULL | Once per Journey |
| E4 | **Journey Ended** | endJourney succeeds | ONE BREATH+ | Every time |
| E5 | **Nikah recorded** | Both Seekers confirm the nikah milestone | FULL (the crown) | Once |
| E6 | **Profile ready / welcome** | Onboarding completes | FULL | Once ever |

**E1 · Match Created.** The single biggest gap today. `match_notification_screen.dart` already exists but is functional — this is an upgrade of an existing surface, not a new route. Why it deserves it: mutuality is the first two-sided fact in the product; everything before it was one person acting alone. What it must achieve: say plainly that *both* chose ("You've both chosen each other"), slow the pace so it registers, then orient — she now sits in Potential Journeys, one person at a time, both families present. First match ever adds one extra explainer line; every later match keeps the moment but not the tutorial.

**E2 · Journey Begins.** The threshold from choice to commitment, and the moment RLS opens to both Guardians — weight here is honesty, not theatre. Achieves: mark the intention, name the company ("both families present"), hand into Compatibility Reveal as the opening. Every time, because beginning is never routine — but it stays short, since the begin confirm (inline, just ratified) already carried the decision.

**E3 · Open Conversation unlocked.** The destination stage. Eight structured stages end and free messaging begins — the single largest change of texture in the product. Achieves: credit the work ("the structure has done its work"), state what is now different, reaffirm the Guardians remain present. Once per Journey by nature.

**E4 · Journey Ended.** Not a celebration — a closure. The Founder's own ruling ("closure instead of a Journey disappearing") already governs the Ended section; this extends it to the moment itself. Achieves: dignity, and the keepsake promise ("everything you built is kept") said at the exact second loss is felt. Slightly heavier than one breath: this is the one place slowing down is kindness. Every time.

**E5 · Nikah recorded.** The product's entire purpose, achieved. If ZYRA has one screen a couple screenshots and keeps, it is this one. Achieves: gratitude, the pair's names and date, the promise that the whole story remains theirs. Once, and it should feel once-in-a-product. (Wording depth — e.g. *Alhamdulillah* — is a Founder call; see §5.)

**E6 · Profile ready.** `profile_ready_screen.dart` exists — upgrade it to a true welcome: greet by name, state ZYRA's pace ("slow on purpose") once, and hand into Browse. Once ever; it is the app's handshake.

---

## 3. RECOMMENDED — worth it, at the right weight

| # | Moment | Trigger | Weight | Frequency |
|---|---|---|---|---|
| R1 | **Compatibility Reveal complete** | Reveal viewed by both | ONE BREATH | Once per Journey |
| R2 | **Phase complete** (Faith & Values / Building a Life / Navigating Life) | Both seal a phase | ONE BREATH, one shared design | Every phase |
| R3 | **Family Compatibility complete** | Family stage passes | ONE BREATH | Once per Journey |
| R4 | **First Guardian linked** | Wali link accepted | FULL | Once ever |
| R5 | **ZYRA One activated** | Subscription starts | ONE BREATH | Per activation |
| R6 | **Restart accepted** ("new Journey accepted") | Other party accepts the ask | ONE BREATH | Every time |
| R7 | **Meeting recorded** | Both confirm the meeting milestone | ONE BREATH | Once per Journey |
| R8 | **Journey Resumed** | Resume succeeds | IN-PLACE BEAT | Every time |

Notes worth keeping: **R2 is one design, parameterised by the canonical stage map** — stage label + its guiding question ("Are we fundamentally compatible? — you've both answered") + "your answers are open to each other now, word for word, on your Timeline". Three phases must never get three bespoke screens; that is how drift starts. **R4** has two audiences — the Seeker's moment *and* the Guardian's own ("you now walk with Shakeel") on the Wali side; both surfaces exist (`accept_wali_invite_screen`, `wali_onboarding_flow`). **R6** is emotionally larger than it looks — second chances are rare and both people said yes again — but one breath is enough; the Journey Begins moment follows it anyway. **R8** deliberately stays in place: resuming should feel like *continuity*, and a page would make it feel like starting over.

---

## 4. UNNECESSARY — and why, honestly

| Moment | Why no page |
|---|---|
| **Salam Exchange complete** | The exchange itself is the moment — a page after it would applaud the applause. The next stage's opening line acknowledges it in place. |
| **Guardian Gate complete** | Administrative passage. Fold one line into whatever opens next; a page would dramatise paperwork. |
| **Journey Paused** | Ratified quiet philosophy (DR-ZYRA-142): pauses are seasons, never events. A transition would contradict the product's own ruling. The inline confirm is the whole moment. |
| **Compatibility Unlock purchased** | A purchase. The report itself is the payoff, and it opens immediately — a page between payment and payoff is friction wearing a bow. |
| **First Timeline milestone (generic)** | Covered by the specific ones that matter (Meeting, Nikah). A generic "first milestone!" cheapens both. |
| **Every stage-advance not listed above** | Stacked moments become wallpaper. The budget exists so the big ones stay big. |
| **Account created (before onboarding)** | Nothing has been earned yet; the welcome belongs at *profile ready* (E6), when there is a person to greet. |

---

## 5. Open questions for the Founder

1. **Religious wording depth.** Draft copy stays restrained (e.g. "Alhamdulillah" appears only in the Nikah moment). Whether moments should carry fuller Islamic phrasing — Bismillah at Journey Begins, a du'a at Nikah — is yours to set, ideally with wording you'd stand behind culturally and Islamically.
2. **Sound and haptics.** A single soft haptic on the headline line would deepen E1/E5 considerably; no sound anywhere is also defensible. Preference?
3. **Once-ever moments need memory.** E6, R4, first-match extra line require a small `seen_moments` store (server-side, per account) so reinstalls don't repeat them. Implementation detail, flagged now so it isn't a surprise later.
4. **The Guardian's side.** R4 proposes a Wali-facing moment too. Wali surfaces have had less design love; say if you want that included in round one or parked.

---

## 6. What exists already (upgrade, not invent)

`match_notification_screen.dart` (E1), `profile_ready_screen.dart` (E6), `onboarding/transition_screen.dart` (the timed-reveal pattern to generalise), the takeover/extension language (the visual grammar these moments should inherit). The mock accompanying this document plays E1–E6 plus R2 and R5 with real pacing.

---

## 7. Build status (2026-08-13, DR-ZYRA-148)

Engine: `lib/widgets/zyra_moment.dart` — the grammar enforced in one place (pacing, tap-through, glow/closure accents, the beat widget). Wired and live: E1 (match_notification_screen rewritten), E2 (before the flow opens), E3 (family_stage→conversation — **absorbs R3**: one transition, one moment, families credited inside E3's lines, per the no-stacking rule), E4 (all three End paths; deliberately NOT on the takeover's end-and-begin, where the new beginning is the story), E5 + R7 (timeline confirm, confirming side), E6 (profile_ready handshake), R1 (reveal completion, mark form — the live score ring is a later refinement), R2 ×3 (one shared design fed by the canonical map), R5 (replaces the stock AlertDialog), Salam + Guardian Gate beats, in place.

Pending (OA-ZYRA-205): R4 first-Guardian-linked (both audiences), R6 restart-accepted, the proposer-side milestone moments, the `seen_moments` store + first-match extra line, haptics decision.
