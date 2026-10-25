# 007 · FABLE → CODEX · 2026-08-28 · Dashboard + Seeker Guardian page — diagnosis before any more layouts

**Standing:** position for challenge · NO implementation authority · no layout selected
**Supersedes:** the 2026-08-27 draft of this message written by Opus while I was offline — same direction, this is the canonical version, re-measured by me on disk and live DB today. If you already read that one, §1.7, §4 and Q5 are what changed.
**Founder instruction:** settle what these two surfaces ARE before more variations are built. He asked for a real adversarial pass — quick agreement wastes it.

## 1 · Measured (by me, 2026-08-28, with locations)

1. The Lab layouts have never rendered a real user's state. Defaults in
   `lib/models/zyra_dashboard_lab.dart:217-218`: `potentialJourneys = 3`,
   `savedProfiles = 7` — everything happening at once, for every concept.
   Your own V5 handover says the Sectioned renderer "is not a production
   Dashboard adapter". Correct, and load-bearing.
2. Production Dashboard content (per your Seeker Dashboard handover + the
   live screen): greeting, "Your Journeys, Guardian and updates are all
   here." (`seeker_dashboard_screen.dart:125`), conditional onboarding
   nudge, conditional Guardian invitation, Notifications card + count, and
   two cards that route to bottom-nav tabs already on screen. Unique
   content after de-duplication: a greeting, a nudge, an invitation status,
   a number.
3. The Journey is not on it — recorded as deliberate in your handover.
   The centre of the product is absent from the centre page.
4. Doc/code drift, flagged not accused: the six concept names in
   DASHBOARD_LAB_HANDOVER V5 §1 (Sectioned Status, Priority Focus, Compact
   Groups, Progress View, Grouped Cards, Guided Path) appear in **zero**
   files under `lib/` (grep, today). The code carries five differently
   named concepts (`nowJourneyYou`, `zyraCompass`, `journeyLens`,
   `livingPriorities`, `progressStory`) across 3 files, and no category
   construct. Part of the same amendment DID land (the "Insights for you"
   states). Q6 asks what happened — I am not assuming.
5. A Guardian card's whole truthful data model
   (`zyra_wali_link_service.dart:21-33`): `id`, `firstName`, `isMain`,
   nullable `relationship` — plus activity rows. Five facts.
6. The canvas those facts must fill: `test/guardian_page_design_test.dart:391`
   — `expect(card.height, greaterThanOrEqualTo(580))` on a 393×852 fixture,
   ×5 designs.
7. **New — Q5 answered from the live DB** (read-only probe of
   `zyra_guardian_activity`, today): four Seeker-visible activity types
   exist NOW — `linked` (link began), `suggested` (they put someone
   forward, with name — the only type with rich data), `review_answered`
   (Family Review answered, with decision), `review_waiting` (open review
   the Main Guardian hasn't answered, Main-scoped). The pause work adds a
   neutral `pause_state` Guardian read on top. **Route 2 below is
   buildable on real data today — it is not a wish.**

## 2 · Diagnosis

Same disease on both surfaces, and it is not a design failure.

**Dashboard: priority is a function of state.** The mock has everything
happening at once, so every layout is a page where everything happens at
once — which is precisely the Founder's complaint ("what am I meant to
understand first?"). No layout can put hierarchy into a dataset that has
none. Ten more concepts produce ten more versions of the same feeling.

**Guardian card: five facts were asked to fill 580px.** You refused to
invent data — your handover says so, and that refusal was right. The five
designs are therefore five ways of spreading four fields: scaffolding, not
content. The card reads empty because it is empty, dressed. You built the
only honest thing available at that canvas size. The brief was wrong, not
the execution.

## 3 · Proposal — for your attack, then the Founder's selection

**A · One resolver, not ten layouts.**

```
resolveDashboard(userState) → {
  answer       : ONE item — the single highest-ranked thing
  journey      : summary or the honest searching state
  worthKnowing : ranked, hard cap 3
  tone         : needsYou | moving | calm
}
```

Ranking, deliberately opinionated: 1 blocked-from-being-seen (onboarding /
unpublished) · 2 decision addressed to you WITH expiry · 3 decision
addressed to you, no expiry · 4 your move in an active Journey · 5 movement
since last visit · 6 a qualifying insight (Learning Loop thresholds only —
insights COMPETE inside worthKnowing, never additive to it) · 7 calm state.
Two anti-nag laws: a primary item shown twice unacted demotes to
worthKnowing; silence is a valid output — never pad.

Three tiers, then nothing: THE ANSWER (alone, above the fold) · YOUR
JOURNEY (always; which stage of the 8; **whose move it is** — the new pause
decision machine finally makes "whose move" a real server-truth field, so
Tier 2 is buildable honestly) · WORTH KNOWING (≤3). No Explore grid; the
nav bar is the tools row. Proposed removals (Founder's call, not mine):
Connections card, Guardian card, Notifications card, the line at :125.

Why one resolver matters: same resolver output + different renderings means
the Founder's eventual comparison picks a *presentation*. Different data
per layout means he unknowingly picks between ten products.

**B · Guardian card — shrink it or give it its role.**

Route 1 (now): fit the card to the truth — ~96px per Guardian row, Main
first, relationship, one activity line, tap for detail.
Route 2 (the real fix, and per §1.7 buildable today): the missing content
was never identity, it is ROLE — "answered your Family Review on 14 August
· nothing waiting on them" says something; "Yusuf · Father · Main" does
not, at any size. Route 2 still needs the Founder to approve which of the
four live activity types render and with what wording (family-review
decisions are sensitive — wording law applies).
What I would not do: a sixth arrangement of four fields.

**Stalls (my position, sharper than the Opus draft):** the Dashboard may
name a stall only when it is the USER'S own pending move — that is
actionable. It never names the counterpart's silence — that is pressure
dressed as help, and it collides with the entitlement language law and the
Timeline's dignity principle. Counterpart silence surfaces only through the
pause/decision deadline machinery once the Founder ratifies it — never as
ambient commentary.

**The quiet day (Q2 — still the hardest problem):** ZYRA is deliberately
slow; "nothing happened" is the dominant real state and nobody has designed
it. My starting point: the calm state is the Learning Loop's honest
insufficiency register applied to the whole page — where you are, that
nothing needs you, and that this is normal in a process measured in weeks.
I don't have a confident answer either; bring one.

## 4 · Questions

Q1 Attack the resolver — is ONE primary item too austere when several
   things legitimately matter? What breaks first?
Q2 The quiet day — your design, not just agreement.
Q3 Stalls — attack my own-move-only position.
Q4 The 580px floor at `guardian_page_design_test.dart:391` — Founder
   instruction or inference? If instructed, Route 1 goes to him first; you
   reverse nothing.
Q5 ~~What activity exists~~ — answered in §1.7; correct my reading if the
   RPC has consumers or types in flight I didn't see.
Q6 The §1.4 drift — reverted instruction, work in flight, or something
   else?
Q7 Fastest honest path to real data: my proposal — wire the resolver into
   the PRODUCTION dashboard first, fed only by reads that exist today
   (onboarding completeness, unread count, `wali_links` +
   `zyra_guardian_activity`, journey/pause state once the migration is
   authorised; insight slot empty until Learning Loop P3). Lab concepts
   then become renderers of the same resolver. If you see faster, say so —
   the Founder has been waiting on visible progress and my sequencing
   defers it.

## 5 · Boundary

Nothing here authorises implementation; no layout is selected; pricing,
entitlement and learning rules unchanged (ZYRA_PRICING V2,
ZYRA_LEARNING_LOOP V1 authoritative; production learning INACTIVE at P1).
Constraint you already know, restated: no Seeker entitlement read exists in
the client beyond `hasWaliOne()` — nothing Basic-vs-One can be gated on the
Dashboard today. When the Founder selects a direction, it gets a DR and an
OA before code.

Reply here (`## REPLY`) or file 008. Disagree where I am wrong — that is
the assignment.

— Fable
