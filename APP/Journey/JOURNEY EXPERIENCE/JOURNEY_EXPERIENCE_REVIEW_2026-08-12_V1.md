# ZYRA — The Journey as an Experience
## A product and UX review of the Active Journey, end to end

**Version:** V1 — for Founder review. Nothing in here is built or scheduled; every recommendation is yours to accept, change, or refuse.
**Date:** 2026-08-12
**Requested by:** Founder — "review the Active Journey from a pure product and UX perspective… challenge everything… I'm deliberately leaving the solution open."
**Ground rules honoured:** the architecture, stages, progression and logic are untouched. Every proposal below runs on the existing eight stages, the existing checkpoints, the existing both-parties mechanics, and the Timeline that already exists. This is a redesign of *how it feels*, not *how it works*.
**Method:** I walked the entire built experience as a user would meet it — every stage view, every waiting state, every dialog, every line of copy — and read it against your own June philosophy ("ZYRA does not build a platform where people chat. ZYRA builds a guided marriage journey") and the memory test you set: *would a couple remember the experience years later, or remember completing forms inside an app?*

---

## 1 · The verdict

**The skeleton is right. The soul is specified. Neither is on screen yet.**

Three things became clear walking it end to end:

**First — your diagnosis is accurate, and it is worth being precise about why.** The Journey today is eight meanings rendered through one grammar: a centred heading, a line of grey subtext, a filled button. Compatibility Reveal, Salam Exchange, Guardian Gate, three chapters of discovery, the meeting of two families, and the opening of a door the couple spent weeks earning — all of them are *the same room with different labels*. The user's felt experience is exactly what you wrote: Continue, Continue, Continue. The stages differ in what they store; they barely differ in what they *are*.

**Second — and this is the important one — most of what is missing was already designed. By you. In June.** The Journey Stages spec calls the Reveal "one of the first meaningful moments two people experience together — it should feel like an event, not just another information screen." It specifies a held transitional moment ("You both chose to reveal… Revealing your compatibility…"), a count-up, categories arriving one by one. It specifies a between-chapter progress overview "because people love seeing progress — it makes the journey feel like something being built." It specifies topic chips so people "feel prepared before they answer." None of this exists in the build. What was built is the *mechanics* of those specs — the flags, the gates, the both-parties checks, all correct — with the *atmosphere* left for later. Later is now. So this review is not asking ZYRA to become something new. It is asking the build to finish becoming what you already wrote down.

**Third — ZYRA already owns the answer to your memory test, and the Journey never uses it.** You built a permanent Timeline this month: real calendar dates, milestones written by the database itself, Meeting and Nikah attested by both people. That *is* the memory artifact — a couple's story, kept. And the Journey never once points at it. Not when the first Salam is exchanged, not when a chapter completes, not when the door opens. The book is being written and nobody tells the couple it exists. Connecting these two systems — the Journey as the *writing* of the story the Timeline *keeps* — is the single highest-value idea in this document, and it costs almost nothing, because both halves are already built.

---

## 2 · The memory test, applied honestly to what is built

What each stage would leave in memory today:

| Stage | What actually happens today | What survives in memory |
|---|---|---|
| Starting the Journey | A confirmation dialog about slots and Guardians reading the conversation | "I confirmed a dialog" |
| Compatibility Reveal | Tap Reveal → (poll) → the number is *suddenly there* with five category rows | The number, maybe. Not the moment |
| Salam Exchange | A button: "Send Salam". When both flags are true, the screen **auto-advances instantly** | Nothing — see below |
| Guardian Gate | "To begin your journey, you need to link a Guardian" + a spinner while waiting | "The app made me do admin" |
| Faith & Values | Eight stacked text boxes, "Submit Answers", spinner, then all sixteen answers in one scroll with rating chips, then "Ready to continue?" beside an **End Journey button of equal size** | "We filled in forms" — the literal fear in your brief |
| Building a Life | Identical grammar, different questions | Blurs into the previous |
| Navigating Life | Identical grammar, different questions | Blurs into the previous |
| Family Review (48h) | The one genuinely designed wait: "Both families have this stage to review… continues automatically in 47h 12m" | This one, honestly, is close |
| Family Compatibility | Four text boxes, "Submit", waiting spinner, then — mid-read — auto-advance | "Then suddenly we were somewhere else" |
| Open Conversation | A real threshold screen (new, 2026-08-11), decent words, a door | The door — the newest screen is the closest to the standard |

Two findings in this table deserve to be pulled out, because they are the sharpest of the whole review:

**The Salam — the first thing two people ever say to each other — is never witnessed.** The code advances the moment both flags are true: `if (mine && theirs) continue()`. There is no screen state in which a person *sees* that the other's Salam arrived. No moment where the exchange is complete and held. The single most human beat in the early Journey — *she said Salam back* — is structurally unwitnessable. It isn't under-designed; it is skipped. And returning a greeting is not app furniture in this faith — it is an obligation with weight. The app treats it as two booleans meeting.

**The chapter checkpoint puts "End Journey" at equal visual weight beside "Continue" — at the exact moment a couple has just finished something together.** They have both answered, both read, both rated. The screen's response to this small achievement is a fifty-fifty choice between carrying on and ending it all. Ending must always be *available* (your rule, and the right one — the quiet Pause · End footer already exists on other stages for exactly this). But at the moment of completion, parity between "continue" and "end" reads as "we are neutral on whether this was worth anything."

---

## 3 · Why it feels like a wizard — six structural causes

Symptoms are screens; causes are patterns. Fix the six patterns and every screen improves at once.

**3.1 · One grammar for eight meanings.** Every stage renders as heading + subtext + button, centred. Identity is carried by *nouns only*. A threshold (Reveal), a ritual (Salam), an administrative gate (Guardian), a fortnight of shared writing (the chapters), a family summit (Family Stage) and an arrival (Conversation) are different *kinds* of moment, and the screen grammar should know it. The stage model already does — `ZyraStageKind.threshold / sustained / destination` exists in the code and *nothing visual reads it*.

**3.2 · Transitions are state swaps.** Progress happens when a 3-second poll notices the server moved, and the widget under your eyes is replaced. Twice the app advances *automatically mid-read* (Salam; Family Stage's "Both sides have answered — continuing to Conversation" which replaces itself before it can be read). Nothing is ever closed, sealed, or acknowledged — the Journey has *achievements in the data* (checkpoints, milestones with real dates) *and no achievement moments on screen*. An earned transition needs three beats: what just finished · what it means · what comes next. Currently there are zero beats.

**3.3 · Waiting is rendered as absence.** Five of the eight stages have waiting states, and in wall-clock terms *waiting is most of the Journey* — waiting for her reveal, his Salam, her Guardian, his answers, her Continue, the families' 48 hours. Nearly every one is a spinner plus "Waiting for {name}". A spinner is the system's symbol for *its own* incomplete work; borrowed for human waiting it says "the other person is a loading error." The one designed wait — Family Review — proves the app already knows better: it names what is happening, why it is legitimate, and when it resolves.

**3.4 · Progress has no geography.** There is no map, no path, no sense of position — the only indicator of where you are is the stage title itself. The spec's between-chapter overview (✓ Faith & Values · → Building a Life · ○ Navigating Life) was never built. Because the user can never see the road, every stage feels like the same distance from the end, which is the definitional feeling of a wizard: *pages, not places*.

**3.5 · The voice is administrative at the personal moments.** "Submit Answers." "Submit." "Faith & Values — Revealed." "Ready to continue?" "Your answer…" This is the language of forms, sitting directly on the most intimate content in the product — questions about faith, children, hardship, health. The strange thing is that the *right* voice already exists in this codebase, in the places written with care: "Nothing has been lost." · "Pause = hold, not rejection." · "The result is bought, the relationship is not." · "There is more distance here than most pairs begin with. That is information, not a verdict." The voice isn't missing. It is unevenly applied — strongest at the edges (pausing, ending, refusing) and weakest at the centre (the daily work of the Journey).

**3.6 · The story is being written and nobody says so.** The database writes `liked`, `match_created`, every stage advance, `journey_ended` — dated, permanent, both-party. Meeting and Nikah can now be proposed and confirmed by both people. This is a *wedding-album-grade* record accumulating silently. The Journey never mentions it. The couple cannot feel they are writing something because the app never shows them the ink.

---

## 4 · The redesign — one continuous experience

### 4.0 · The organizing idea: ZYRA as witness and scribe

Every proposal below follows one thought, so the whole Journey feels like one designed thing rather than ten fixes:

> **The couple is writing a story. ZYRA is the witness who keeps it.**
> The app does not move people through stages; it watches two people do meaningful things — choose, greet, answer, involve their families — and it *records each one, names it, and keeps it*. Ceremony in ZYRA is never confetti. It is the quiet weight of: **"This is now part of your story. 14 August 2026."**

This is native to what you have built: the philosophy says the goal is Nikah, not engagement; the Timeline is already permanent; the language of chapters already runs through the product. A witness is calm. A witness never rushes you. A witness never celebrates *at* you. And a witness makes moments matter simply by writing them down — which is precisely the register between "flat workflow" and "romanticised drama" you asked for.

Three recurring moves, applied to every stage:

| Move | What it is | Answers your question |
|---|---|---|
| **The Threshold** | Each stage opens with a cover, once: its name, its guiding question, why it matters, what will be shared and with whom | "How does each stage begin? Should every chapter have an introduction? Should the app explain why this stage matters?" |
| **The Presence** | Inside the stage, the screen behaves like that stage's *kind* — a threshold holds still, a chapter feels like writing, a wait feels tended | "Should the app guide rather than instruct?" |
| **The Seal** | Each stage closes with a held moment both people see: what was completed, its date, its line written to the Timeline — then one breath of anticipation for what is next | "How does each stage end? Completion moment? Reflection? Sense of achievement? Anticipation?" |

### 4.1 · Stage by stage

**Starting the Journey — from slot management to intention.**
The current dialog leads with mechanics: "This starts your Active Journey. It will use your Journey slot…" Slots are the *panel's* vocabulary. Keep every fact (one Journey at a time; Guardians can read the conversation — that honesty is a strength, keep it word for word), but lead with what the tap *means*: starting a Journey with one person, to the exclusion of everyone else, with families present. One-Journey-at-a-time is your seriousness principle — let the copy carry it as *meaning* ("ZYRA asks you to walk with one person at a time") rather than as a quota. The moment they confirm is the first Timeline entry they should ever be shown: *"Your Journey with Aisha began — 12 August 2026. The first line of your story."*

**Compatibility Reveal — build the held breath you specified in June.**
The mechanics are excellent (mutual consent to see; Plus sees early but cannot advance — "the result is bought, the relationship is not" is one of the best decisions in the product). What is missing is your own STATE 2: both have chosen, and the screen *pauses* — "You both chose to reveal." — before the number counts up and the categories arrive one by one. Once, ever; never re-animated on later visits. The insight line beneath it should complete the moment by giving the number *direction* (the intelligence layer already speaks this way on ZYRA One). The seal: *"You revealed together — 12 August. You chose to continue — 13 August."* Two dates, because in this product the choosing matters more than the score.

**Salam Exchange — from two booleans to an exchange.**
The most important small redesign in this document. Make it sequential and witnessed: when her Salam arrives, he *sees it arrive* — "Aisha has sent you her Salam" — and his action is `Return her Salam`, which is a different act than initiating. When both exist, **hold**: the completed exchange on screen, unhurried — "You began with Salam. 13 August 2026." — and only then a Continue that the couple presses, not a poll that whisks them away. This costs one screen state and removes one auto-advance, and it converts the emptiest stage into the first memory. (Whether the Salam should carry the *words* — the greeting text itself displayed, or a short optional first line — is a Founder decision, D2 below; the redesign works either way.)

**Guardian Gate — from compliance to arrival.**
Current copy: "To begin your journey, you need to link a Guardian" — the voice of a form that wants a field filled. What this stage *is*: the moment the Journey stops being private, by design, forever — the thing that makes ZYRA ZYRA. Say that: *"This is where your families join you. From here, nothing in this Journey happens without a Guardian beside each of you."* The waiting state ("Waiting for Aisha to link theirs") is one of the few waits with a genuinely useful pastime: introduce **your** Guardian's role — what they will see, when they can act — so the wait teaches the model. Seal: *"Both families are present — 15 August."*

**The three chapters — where the wizard feeling is actually made, and where it is unmade.**
This is the heart of the Journey and the heaviest concentration of form-feel. Four changes:

1. **Chapter covers** (the spec's phase intro, built at last): the chapter name, its guiding question — "Are we fundamentally compatible?" is *already written and already good* — the topic chips with tap-to-expand ("Core Values — honesty, priorities, decision making"), the privacy covenant ("Your answers are shared with Aisha and your Guardians. Your ratings are never shown to anyone."), and one line of *why this chapter exists*. Shown once on first entry; a compact header afterwards.
2. **One question at a time.** Today all eight questions stack in one scroll over one Submit — the physical form factor of a survey, and the single strongest source of the feeling you named. Presented one per screen (progress as a quiet "3 of 8"), each question becomes a *sitting*: read it, think, write, move on. Same data, same submission, entirely different texture. Draft answers persist; nothing is sent until the final review-and-share step, which keeps the current safety of one submission.
3. **Name the envelope.** The reveal mechanic is genuinely beautiful — both write in private; neither sees anything until both have finished — and the current copy narrates it as a queue ("Aisha will see your answers once they share theirs"). Say what it actually is: *"Your answers are sealed until Aisha finishes hers. You open them together."* The wait for her answers then has a shape: not "waiting for data," but a sealed envelope on the table. Waiting content: re-read *your own* answers (editable until both submit? — D8), preview the topics still ahead, and — on One — what the intelligence layer noticed so far.
4. **The reading, then the seal.** When both have shared, the opening of answers deserves its own beat — "Aisha's answers have arrived. Read them slowly; there is no clock on this stage." — before the interleaved read-and-rate view (whose rating chips are already humane and correctly private). Then the checkpoint, reframed: not "Ready to continue?" with End at equal billing, but **the seal** — *"Close this chapter together? Your answers stay on your Timeline; Building a Life is next."* Continue is the primary act; Pause · End remain in the quiet stage footer where they already live on every other screen (D6). When both have chosen: the held completion — *"Faith & Values — completed together, 19 August 2026"* — with the next chapter's guiding question as one line of anticipation, and *no automatic advance*: the next chapter starts when someone walks into it. That pause between chapters IS the reflection space (your question 5) — designed rest, not dead air.

**Family Review (48h) — nearly right already; finish the reframe.**
"Both families have this stage to review… your Journey continues automatically in 47h 12m" is honest and calm — the best waiting state in the app. Two refinements: name it as *purposeful* time rather than a timer ("This pause is deliberate — it is your families' time. Unless a Guardian raises a concern, you continue together on Thursday."), and give the couple something worth doing in it: revisit the sealed chapter, read their Timeline so far, see what the next chapter will ask. A 48-hour wait with a full Timeline to reread is a *feature*; the same wait against a spinner is a punishment.

**Family Compatibility — two families, not four text boxes.**
The stage where the parents' generation enters, rendered with the same grammar as everything else. The cover should honour it: *"Your families meet your Journey here. Aisha's Guardian will ask you their questions; yours will ask theirs. Answer as if they were sitting across from you — they are."* The Guardian-side questions are already well-written and already real (both sides must answer — the 2026-07-26 fix made the Guardian's role genuine; the experience should say so). Kill the mid-read auto-advance: when both sides complete, **hold the seal** — *"Both families have spoken with you both. 26 August 2026."* This is plausibly the single most reassuring sentence the app will ever show a parent-conscious user; it currently flashes past in under a second.

**Open Conversation — the arrival, earned and said so.**
The newest screen and the closest to the bar; the philosophy line is already in it ("the structure lifts, it does not end"). Complete it with the earned-summary — the recap that makes the arrival *weigh* something: *"Forty-six answers shared. Three chapters sealed. Both families present. You have earned this conversation."* — each line pulled from real data, followed by the Timeline itself, then the door. This is your question about achievement answered at the largest scale: the achievement is not a badge, it is *the accurate list of what they actually did*.

**Paused · Ended — already in the right voice.**
"Nothing has been lost." and "Your Timeline with Aisha is preserved as historical record" are the standard the rest of the app should rise to. One addition each: Paused offers the Timeline ("what you built together is safe — you can read it any time"); Ended, in time, deserves a gentler final page — the story, closed, kept — but that touches sensitive ground and is not urgent.

### 4.2 · The Journey Map — yes, and here is its precise job

Your question "should there be a Journey Map?" — **yes**, because it is the direct cure for cause 3.4 (no geography), and it must be *one screen with one job*: **where we are, on which road.**

- The eight stages as a **path** (a road with places on it — not a numbered stepper, not a progress bar, no percentages ever).
- Behind: sealed places, with their dates — pulled from the Timeline, because those milestones already exist with real timestamps.
- Here: the current stage, its guiding question, and — when waiting — *who the Journey is waiting on*, said plainly.
- Ahead: **names and guiding questions only.** No content spoilers; anticipation comes from knowing the shape of the road, not its contents. The final place is always visible from the first day: *Open Conversation — where this road leads.* The destination being visible from the start is what makes every stage feel like progress toward something rather than another page.
- Entry points: the Journey app bar (a small path glyph), and a slim current-position strip on the Connections Active card.
- **Map vs Timeline, one line:** the Map is the road; the Timeline is the story. Forward vs backward. Two screens, two jobs, no merging.

### 4.3 · Waiting, as doctrine

Every waiting state in the Journey follows one rule — a wait must offer three things:

1. **What is true** — who or what the Journey is waiting on, in honest words (this exists today).
2. **Why it is right** — the wait as meaning, not delay: the envelope stays sealed; the families have their time; a Salam deserves an unhurried reply.
3. **Something worthy of the time** — reread their answers or your own; read the Timeline; preview the road ahead; on One, what ZYRA noticed. Never a spinner as the hero of a screen about a human being.

And one prohibition: **the app never nags the other party.** No "remind Aisha" buttons, no guilt copy. A Journey where both people move only when both choose is the product's spine; pressure mechanics would snap it.

### 4.4 · The voice — principles and concrete rewrites

Principles: the witness's register — calm, plural where the pair acts together ("You both…"), verbs of record (*kept, sealed, written, part of your story*), dates spoken in full ("14 August 2026" — the Timeline's own format), no exclamation marks anywhere in the Journey, honesty kept blunt where it protects people (the Guardian-visibility line, the pause caps, "that is information, not a verdict"). English throughout, Islamic terms used naturally and never decoratively.

| Today | Proposed |
|---|---|
| "Send your Salam to Aisha to begin your journey." | "Every Journey in ZYRA begins the same way — with Salam." |
| *(unwitnessable)* | "Aisha has sent you her Salam." → **Return her Salam** |
| "To begin your journey, you need to link a Guardian." | "This is where your families join you. Link your Guardian to continue." |
| "Submit Answers" | "Share my answers" *(on the final review step: "Seal my answers")* |
| "Aisha will see your answers once they share theirs." | "Your answers are sealed until Aisha finishes hers. You open them together." |
| "Waiting for Aisha's answers" + spinner | "Aisha is still writing." *(+ reread / preview / Timeline)* |
| "Faith & Values — Revealed" | "Your answers, opened together" |
| "Ready to continue?" *(Continue ∥ End Journey, equal width)* | "Close this chapter together?" *(Continue primary; Pause · End stay in the stage footer)* |
| "Both sides have answered — continuing to Conversation." *(auto-advance)* | "Both families have spoken with you both. — 26 August 2026" *(held; Continue when ready)* |
| "This starts your Active Journey. It will use your Journey slot…" | "A Journey is one person at a time, with your families present. Everything else waits." |

### 4.5 · Pacing

The danger is not speed — the both-parties mechanic already prevents solo rushing — it is **blur**: three chapters completed in one long evening feel like one long form regardless of grammar. The redesign paces by *invitation, never by lock*: chapters do not auto-advance; seals invite rest ("Building a Life is ready when you both are — there is no clock on this road"); the Family Review already contributes 48 designed hours per gated transition. **No artificial cooldowns** — a couple who genuinely wants a full evening together in the app should have it; the app's job is to make stopping-points feel natural, not to enforce them. (D10 if you ever want a soft "one chapter a day" suggestion; I recommend against anything harder.)

---

## 5 · Anti-patterns — what this redesign must refuse

Each of these would be *easier to build* than what is proposed, and each would spend the product's dignity:

- **Gamification** — badges, streaks, XP, completion percentages, confetti. A Journey scored in points is a Journey whose milestones stop being about the couple. (Philosophy §5: engagement is not the goal.)
- **Manufactured urgency** — "Aisha is waiting!", countdown pressure outside the honest Family Review window, re-engagement nudges written as the other person's feelings. Guilt is not intention.
- **Romantic theatrics** — destiny copy, "written in the stars", hearts raining. Wrong register for the product's users *and* wrong theologically: the app is a witness, not an oracle; qadr is not ZYRA's to narrate.
- **Ceremony inflation** — if every tap gets a held moment, no moment holds. Seals are for stages and true milestones only; the count of ceremonial beats in the whole Journey should stay under a dozen.
- **Sentiment that overwrites honesty** — the warm version of a screen must never delete the plain fact (who can read what, what a pause means, what ending costs). The current build's honesty is its best inheritance; the redesign decorates none of it away.

## 6 · What already meets the bar

For fairness and for pattern-reuse: the mutual-consent mechanics everywhere (reveal, continue, checkpoints — "every checkpoint is a shared decision" is *built and true*); the Family Review waiting state; the Paused and Ended copy; DR-135's bought-number-not-bought-stage restraint; the intelligence layer's tone ("information, not a verdict"); the Open Conversation threshold existing at all (a door, not a trapdoor); the guiding questions; the question sets themselves — genuinely good questions, humanely ordered, health and hardship handled with dignity; and the Timeline + attestation system, which is the memory artifact this entire review keeps pointing at.

## 7 · The memory test, re-run

The couple who marries through the redesigned Journey remembers: the evening they both chose to reveal and watched the number arrive; that their story began with Salam, and the app treated the returning of it as something worth holding; the week they wrote to each other one question at a time, sealed until both finished; reading his answer about the hardest year of his life; closing Faith & Values together and seeing *completed together, 19 August 2026*; the two days their families took, which felt like respect rather than delay; the sentence *both families have spoken with you both*; and arriving at a door with their whole road listed behind them — then walking through it. And at the Nikah, one of them opens the Timeline and reads the dates aloud.

None of that requires a new table, a new stage, or a changed rule. It is the same architecture, finally *felt*.

## 8 · Decisions for the Founder

| # | Decision | My recommendation |
|---|---|---|
| D1 | Build the Journey Map (path screen + Connections strip)? | Yes — it is the cure for "pages, not places" |
| D2 | Salam redesign: witnessed sequential exchange; and should it carry words (shown greeting / optional first line) or remain wordless? | Build the witnessed exchange now; keep it wordless in v1 (the words question touches messaging-before-conversation policy) |
| D3 | Chapters: one question at a time with draft persistence? | Yes — the single biggest de-wizarding change |
| D4 | Seals: both-parties held completion moments with Timeline dates, no auto-advance anywhere? | Yes — remove both auto-advances (Salam, Family Stage) |
| D5 | Religious content (du'a at Journey start, ayah at Nikah milestone, bismillah placements)? | Reserve the spaces in the designs; add content only with your selection and scholarly review — not mine to write |
| D6 | Demote End Journey out of the checkpoint row into the standard stage footer? | Yes — availability unchanged, parity removed |
| D7 | Chapter covers: full cover on first entry, compact header after? | Yes |
| D8 | While the envelope is sealed, may a Seeker edit their own answers until both have submitted? | Yes — it rewards reflection; lock only at mutual submission |
| D9 | Does "chapter / story / sealed" become user-facing vocabulary, or design-internal only? | User-facing, sparingly — the Timeline already made "story" true |
| D10 | Any soft pacing suggestion ("one chapter a day")? | No — invitation-shaped rest only; never locks |

**Sequencing, if accepted (experience-only, no schema):** Wave 1 — voice pass + kill both auto-advances + checkpoint reweighting + seal moments (copy and view-layer only). Wave 2 — chapter covers, one-question-at-a-time, envelope framing, waiting-state offerings. Wave 3 — Journey Map, Reveal STATE 2 moment, Open Conversation earned-summary, Timeline threading throughout. Each wave ships whole on the existing model.

---

*ZYRA — Journey Experience Review — V1, 2026-08-12. For Founder decision; nothing herein is scheduled. Companion documents: JOURNEY PHILOSOPHY/Summary.md (the standard), PRE-JOURNEY RITUAL/Summary.md (the June experience spec this review asks the build to finish), SEEKER TO SEEKER TIMELINE (the memory artifact).*

---

## AS APPLIED — 2026-08-12 (DR-ZYRA-139)

The Founder re-issued the brief the same day with "make any changes and let
me update it in terminal" — the decisions were taken as recommended and
**Waves 1–3 are built**, entirely on the existing architecture:

| Decision | Outcome |
|---|---|
| D1 Journey Map | ✅ Built — `journey_map_screen.dart`, reached from the Journey app bar |
| D2 Witnessed Salam (wordless) | ✅ Built — auto-advance removed; the exchange holds |
| D3 One question at a time | ✅ Built — cover → sequential → review-and-seal ("Seal my answers", gated on completeness) |
| D4 Seals, no auto-advances | ✅ Built — Salam and Family Stage both hold; Family Review opens with the sealed chapter |
| D5 Religious content | ⏸ Deferred as recommended — spaces exist, content is the Founder's call with scholarly review |
| D6 End out of the checkpoint row | ✅ Built — quiet stage footer everywhere |
| D7 Chapter covers | ✅ Built — full cover on first entry, compact header once writing has begun |
| D8 Edit while sealed | ⏸ Deferred — `submitPhaseAnswer` is insert-only server-side; needs upsert semantics first |
| D9 Chapter/story vocabulary | ✅ Adopted, sparingly, in the new copy |
| D10 No pacing locks | ✅ Honoured — invitation-shaped rest only |

Also applied: the Reveal transitional moment (June spec STATE 2 — held line,
count-up, once per match), the envelope named in every chapter waiting
state, the earned arrival + Timeline link at Open Conversation, the
start-Journey dialog leading with meaning, and the Family Review reframed
as the families' time with the Timeline offered. The Connections
current-position strip remains open (map v2). Voice pass per §4.4's table.*
