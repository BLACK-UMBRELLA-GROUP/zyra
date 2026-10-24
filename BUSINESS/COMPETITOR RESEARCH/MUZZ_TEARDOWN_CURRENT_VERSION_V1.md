# MUZZ — Founder-Level Product Teardown & ZYRA Strategic Response

**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-08-01
**Reviewer:** Claude (independent product review)
**Requested by:** Founder (Shakeel)
**Subject:** Muzz iOS **v8.87.0 (build 560)**, reviewed live on device via iPhone Mirroring, free ("Basic") account, UK market
**Nature of this document:** Product, UX, behavioural, commercial and safety review. Nothing here has been implemented. Recommendations that should become permanent ZYRA rules are separated into §5 (Decision Records) rather than assumed.

---

## 0. Method, Coverage and Honest Limits

### 0.1 What I actually saw

Live, on device, this session: the **Marriage** discovery deck and profile card, the full-screen **photo viewer**, the complete **Filters** taxonomy (free and Gold), the **Menu**/monetisation dashboard, the entire **Settings** tree, the **Muzz Gold paywall** with all 12 features and all three price points, the **Safety & Advice** Resources Centre, the **Chat** tab and its empty state, the **Explore** tab, and the **Jamaa** social feed.

### 0.2 What I could not see — stated plainly

- **Onboarding and registration.** The account is already registered. Unreviewed.
- **Chat interior.** The account has 0 active conversations, so there was no live thread to inspect. The chat *shell* and its rules I did see.
- **Paid surfaces.** Free account, so Gold-only features were reviewed as paywalls, not as products.
- **Events, My history, and the "Friends"/Social mode.** Not opened this pass.
- **Profile creation and editing.** Not opened this pass.

### 0.3 The measurement limit — this matters for your Performance section

**I cannot measure Muzz's performance, battery or network behaviour, and I am not going to pretend otherwise.** In the ZYRA audit I read the source, ran queries against the live database, and could tell you exactly what was wrong and why. Here I am looking at a competitor's compiled binary through a mirroring session. Every claim in the Performance sections below is *observational inference* from render behaviour and interaction latency, explicitly labelled as such. Anything stronger would be fabrication dressed as analysis, which is worse than silence.

One consequence worth stating: mirroring adds its own latency, so I have deliberately **not** drawn conclusions about frame rate, animation smoothness, or scroll performance. Those would be artefacts of the transport, not the app.

### 0.4 A finding that emerged from the method itself

**Muzz blocks other members' photos and names from screen capture.** Throughout the session, every piece of UI chrome — text, buttons, tags, nav, editorial images in the Safety Centre — rendered perfectly, while member photos rendered as blank white or black and member names rendered as `•••`. The user's *own* name and avatar rendered normally.

That is not a bug or a network failure. It is a deliberate anti-screenshot protection applied specifically to user-generated content about other people. It is the single best trust-and-safety decision in the app, it directly prevents the "screenshot her photo and share it in the group chat" harm that is endemic in this category, and **ZYRA has nothing equivalent.** See §3.1 and DR proposal 1.

### 0.5 Privacy handling

You authorised unrestricted capture. I have still kept third parties out of this document — names, employers, precise locations and photos of the women whose profiles appeared are not recorded here. They are not your data to publish into a business document, the analysis does not need them, and a review that says "profile cards expose street-level location" is worth exactly as much as one that names a street. Nothing identifying was written to disk.

---

## 1. Screen-by-Screen Review

Each screen is assessed against your framework. To keep this readable I have merged dimensions where a screen had nothing distinct to say about one.

---

### 1.1 Marriage — The Discovery Deck

**Product.** This page exists to make you make a decision about a stranger as quickly as possible. It achieves that with total efficiency, which is precisely the problem: it is optimised for *decision throughput*, not *decision quality*. The card shows a full-bleed photo occupying ~70% of the screen, then name, age, verification tick, distance to street-level precision, and five identity tags (nationality, occupation, practising level, ethnicity, heritage). Everything above the fold is a snap-judgement input.

*Confusing:* a persistent gold banner reading "Check if you match their filters" sits under the action row. It is unclear whether this is informational, a nag, or a purchase. It overlaps the tab bar area and looks like an ad. *Unnecessary:* the "Sort" pill is prominent in the top bar but sorting is a Gold feature — so the primary top-bar control is, for most users, a paywall trigger dressed as a utility. *Simplification:* the three-button action row (pass / super-like / like) plus swipe gestures plus tap-to-open-photos plus tap-to-expand-profile is four interaction models on one card.

**UX/UI.** Clean, confident, modern. Generous type hierarchy on the name, good use of dark translucent pills for tags against photo. The bottom action row uses three different colours (black, purple, pink) with no shared visual logic — the purple centre button's meaning is not inferable. White space is good. **Accessibility is a concern**: tag text is small and set in white/grey on photographic backgrounds with no guaranteed contrast — legibility depends entirely on what the photo happens to look like behind it.

**Behaviour.** The emotion is *appetite*. Full-bleed faces, quick binary choices, immediate next card. This is a slot machine with a variable-reward schedule, and it is the single most engagement-optimised surface in the app. It does not encourage intentional marriage; it encourages volume. The daily like limit exists not to promote deliberation but to create a purchasable scarcity — we know this because you can buy your way past it.

**Performance (observational).** The card chrome rendered instantly while photos did not render at all under capture protection, so I cannot assess image loading. Tag pills, badges and nav were immediate.

**Business.** This is the funnel mouth. Revenue comes from exhausting the daily like allowance (13 remaining on this account), then offering Gold. Every element that could be a limit *is* a limit: likes per day, sort order, filters, visibility. The upsells here are **moderately tasteful** — no interstitials, no full-screen takeovers mid-swipe.

**Trust & safety.** **Street-level distance ("2 miles away, Canary Wharf") displayed by default on every card is the most serious safety problem I found in the app.** Combined with a photo, first name, and occupation, this is enough to physically locate a woman. Distance should be banded (e.g. "under 5 miles"), and precision should be a setting the *displayed* user controls, not the viewer.

**Engineering.** Cheap to build; a solved pattern. No visible technical debt.

**ZYRA comparison.** ZYRA's Browse is structurally the same swipe deck with a three-way traffic-light decision (Consider / Save / Pass) instead of a binary. ZYRA's decision language is better — "Consider" is a meaningfully different mental act from "Like". Current physical travel follows the positive/rightward convention: finger left-to-right = Consider, finger right-to-left = Pass, and downward = Save. The gesture remains undiscoverable before first use. **ZYRA should copy:** Muzz's early gesture discoverability, not its binary language. **ZYRA should avoid:** street-level distance. **Third solution:** see §1.9.

---

### 1.2 Profile Photo Viewer

**Product.** Tapping the card opens a full-screen pager (1/2, dot indicators, close, report flag). Sensible. The **report flag placed directly in the photo viewer** is excellent — reporting is available at the exact moment a user sees something wrong, rather than buried three levels into a profile menu.

**UX/UI.** Minimal and correct. Dot indicators plus an "n/N" counter is redundant — two affordances for one piece of information.

**Trust & safety.** Report-in-context is the right pattern. **ZYRA should copy this directly** — ZYRA's Browse currently has no reporting affordance visible in the photo view at all.

---

### 1.3 Filters — The Most Revealing Screen in the App

This screen tells you more about Muzz's actual priorities than any other.

**Free filters:** Age, Location, **Sect** (with real granularity — Sunni, Hanafi, Hanbali and others), **Ethnicity**.

**Gold-only ("Advanced") filters**, approximately 23 of them:
- *Profile & Activity:* Completed Bio, **ID and age verified**, Recently active, Gold member, Just joined, Blurred photos
- *About them:* Nationality, Height, Marital status, Children, Grew up in, Languages, Education, Profession, Interests, Personality
- *Future plans:* Marriage plans, Relocation plans, Family plans
- *Faith & Practice:* **Religious practice, Islamic dress, Diet, Alcohol**

**The finding.** The free tier gives you *sect and ethnicity*. The paid tier gives you *religious practice, Islamic dress, diet and alcohol*.

In other words: **Muzz gives away tribal and sectarian filtering, and charges for actual religiosity.** For a product whose entire premise is helping Muslims marry compatibly in their deen, this is backwards. The free experience nudges users toward matching on ethnic and sectarian identity, which is the axis most likely to entrench biradari, caste and colourism dynamics, while the axis the product exists to serve sits behind £34.99/month.

I do not think this was malicious. I think practising-level filters convert better because they are what people most want, so they went into the paid tier — a revenue decision, not a values decision. But it *is* the values decision now, because it is what the product does.

**"ID and age verified" being a paid filter is worse.** The ability to restrict your matches to identity- and age-verified humans is a safety control. Charging for it means the free tier — which is where the young, the price-sensitive, and the vulnerable live — is the tier most exposed to catfishing and to adults misrepresenting their age. **Safety filters must never be a premium SKU.** This is the clearest single thing ZYRA should refuse to copy.

**Filters worth stealing outright:** Marriage plans, Relocation plans, Family plans, Grew up in, Blurred photos. "Grew up in" is subtle and excellent — it captures cultural formation independently of nationality or ethnicity, which is often what people actually mean when they say they want someone "from a similar background".

---

### 1.4 Menu — The Monetisation Dashboard

**Product.** Nominally a profile/account hub. Functionally, a shop. Above the fold: your name, then **four separate monetisation vectors**:

1. **Basic plan** → "Upgrade now"
2. **13 Likes** → "Get 3x more likes with Gold" → "Get more"
3. **1 Compliment** → "Get more"
4. **0 Profile Boosts** → "Get more"
5. **£8.07/week** → "Learn more"

That is three consumable currencies plus a subscription, each with its own brand colour (pink, purple, teal, gold), on one screen. **This is free-to-play mobile game economics — Candy Crush's lives-and-boosters model — applied to marriage.**

*Confusing:* three currencies with no explanation of how they relate. *Unnecessary:* the "0 Profile Boosts" card. Showing a zero balance exists solely to create a gap for the user to want to fill. *Simplification:* one currency, or none.

**UX/UI.** Well laid out, clear hierarchy. **One real bug:** the £8.07 card at the bottom is clipped by the tab bar and the screen does not scroll far enough to fully clear it. The "Learn more" button sits partly under the tab bar. A missing bottom safe-area inset in a build-560 app — small, but it is the kind of thing that suggests this screen has had cards added to it over time without the container being revisited.

**Behaviour.** The emotion is *deficiency*. Every number on this screen is a number you do not have enough of. This is not a profile page; it is a fuel gauge running low.

**Business.** Extremely well constructed for revenue. Multiple price points, multiple commitment levels, consumables for users who will not subscribe. **Intrusiveness: high but not deceptive.** Nothing here is hidden or tricked; it is simply relentless.

**ZYRA comparison.** ZYRA has one paid tier (ZYRA One) and no consumable currencies. **ZYRA is already better here and should stay that way.** The moment ZYRA sells Likes, Boosts or Compliments it becomes a game with a marriage skin. Note that ZYRA has already built a sponsored-card slot into Browse (DR-ZYRA-109) — that is the thin end of exactly this wedge and deserves a deliberate second look.

---

### 1.5 Muzz Gold Paywall

**Pricing.** 1 week £22.99 · 1 month £34.99 (£8.07/wk, "Most popular", pre-selected, "Save 65%") · 3 months £80.99 (£6.23/wk, "Best value", "Save 73%").

**The weekly price is a decoy.** £22.99/week (≈£99/month) exists to make £34.99/month look like a 65% saving. Nobody is meant to buy it. The "savings" percentages are computed against this decoy, not against any real list price. This is standard SaaS anchoring, it is legal, and it is mildly dishonest.

**£34.99/month is at the very top of the consumer dating market** — roughly 2-3× Tinder Plus and above Hinge. Muzz can charge it because the alternative for a practising Muslim is a mainstream app that does not serve them. That is a moat built on underserved-ness, and it is exactly the moat ZYRA is attacking.

**The 12 features, and what they admit:**

| Feature | What it really is |
|---|---|
| Like 3× more profiles a day | Removal of an artificial cap |
| **See who likes you** | Sale of information the user has already earned |
| 5 additional chat slots | Removal of an artificial cap |
| Free daily Compliment credit | Consumable drip |
| 2 free weekly Profile Boosts | Consumable drip |
| Discover Sorting | Feature |
| Change your mind (undo pass/block) | Removal of a consequence |
| **Rematch** | Sale of the ability to re-approach someone who unmatched you |
| **Double your daily profile visits** | **Removal of a visibility penalty** |
| Advanced filters | Feature (but see §1.3) |
| Invisible mode | Feature |
| VIP Badge | Status good |

**"Double your daily profile visits" is the most revealing line in the entire application.** Read it carefully: *"Be seen more than twice as much as soon as you become a Gold member."* This is an explicit admission that free users' visibility is deliberately throttled. It is not a feature being added; it is a penalty being lifted. Six of the twelve "features" are of this shape.

**"Rematch — Been unmatched? Request to Rematch for a second chance" is a safeguarding problem.** Unmatching is how a woman exits an interaction she does not want. Selling a man the ability to re-request contact monetises the reversal of someone else's boundary. Whatever the consent mechanics on the receiving end — and I could not test them from a free account — the *product decision to sell this at all* is wrong. **ZYRA must never build this.**

**"See who likes you" deserves a first-principles look.** Someone liking you is a fact about *you*. Muzz collects that fact, hides it from you, and sells it back at £34.99/month. It is the highest-converting mechanic in the history of dating apps and it exists for exactly that reason. From first principles it is indefensible. It survives because it works.

---

### 1.6 Settings — Where Muzz Is Genuinely Excellent

This is the part of the app I would most want ZYRA to learn from, and I want to be unambiguous about that.

- **Date of birth: locked, "Can only be updated once."** ZYRA's live database currently grants `authenticated` UPDATE on `profiles.date_of_birth` with no minimum-age constraint (see the engineering audit, finding C4). **Muzz has solved a problem ZYRA has open right now.**
- **Passcode** — "require a passcode every time you open the Muzz app."
- **Custom app icon, including a "Discreet" plain-black icon.**
- **Block my phone contacts** — "Block people from your contact list on your phone, so they can't see you on Muzz."
- **Who can see my marriage profile** — invisible to people you haven't liked, or hidden entirely.
- **Profile sharing link** — off by default, and *"Hidden photos stay hidden"* when shared.
- **Manage account** — "Start again with your marriage search, **take a break**, or delete your marriage profile."

Those first three together constitute a coherent, unstated threat model: **someone else may pick up this phone.** A brother, a parent, a spouse, a colleague. For Muslim women in particular — and for anyone in a controlling household — that is the correct threat model, and almost no mainstream dating app takes it seriously. Muzz does, quietly, in Settings, without marketing it.

"Block my phone contacts" is the best single feature in the app. The fear of being seen on a marriage app by your cousin, your student, or your imam is the number one reason practising Muslims avoid these platforms. Muzz addresses it directly.

**"Take a break" as a first-class account state**, alongside restart and delete, is a genuine healthy-behaviour affordance — the app gives you a supported way to stop using it.

**ZYRA has none of: passcode lock, discreet icon, contact blocking, screenshot protection, or DOB immutability.** This is the highest-value section of this document.

---

### 1.7 Chaperone — Muzz's Guardian, and Why ZYRA's Is Both Better and Riskier

Buried in App Settings, between Passcode and Privacy:

> **Chaperone** — "For your peace of mind you can add a chaperone or guardian to automatically receive copies of your chats."

That is the entirety of Muzz's guardian model: an **optional, user-initiated CC of your messages to a third party.** No account for the Guardian. No app. No approval gate. No visibility into the journey. No blocking power.

**ZYRA's Guardian architecture is dramatically more ambitious** — a first-class account type, its own shell, Journey visibility, a Guardian Gate that blocks progression, and a 48-hour Family Review Period on stage transitions.

**ZYRA's model is more faithful to actual Islamic practice.** Muzz's chaperone is a surveillance feed; ZYRA's Guardian is a participant. For the seeker who wants their family genuinely involved, ZYRA is not slightly better, it is a different category.

**But Muzz's model has one property ZYRA's does not, and it is not an accident: it cannot block the user.** Muzz's chaperone requires nothing of the chaperone. He does not need to download an app, create an account, understand the product, or ever respond. If he ignores every message, the seeker's experience is unaffected.

ZYRA's Guardian Gate creates a **hard external dependency on a third party's engagement.** If a woman's father will not install the app, is not technical, is abroad, is unwell, or simply does not reply within 48 hours, her Journey stops. Muzz looked at that trade and chose zero friction. ZYRA has chosen high fidelity. Both are defensible; only one has been stress-tested against real families.

**This is the most important strategic question in ZYRA's product**, and it deserves its own Decision Record. My view: keep the Guardian Gate — it is the differentiator — but build an explicit, dignified **Guardian-unavailable path** (grace periods, a nominated alternate, an auto-continue default after a stated window with the Guardian notified rather than blocking). A product that stops a woman's marriage search because her uncle did not open a push notification has misidentified who it serves.

---

### 1.8 Chat — Scarcity Rendered as Furniture

**"Active conversations (0/5)"** — *"Your matches are added to your conversations when you've both sent each other a message. You can only talk to 5 people at a time."* Below it: five empty slots, each a dashed circle reading "Select a match to start a conversation."

**Product.** The mutual-message requirement before a conversation "activates" is a genuinely good mechanic — it filters one-sided openers and means a conversation slot is only consumed by real reciprocity. Steal this.

**The five empty slots are the most sophisticated piece of persuasion design in the app.** An empty state has been converted into permanent, furniture-level advertising for the paid tier. Every free user, every time they open Chat, sees five holes they have not filled and a counter that reads 0/5. It is elegant and it is relentless.

**Behaviour, and the point that matters most for ZYRA.** A five-conversation cap looks philosophically identical to ZYRA's One-Active-Journey rule. It is not. **The difference is that Muzz sells the way around it.** A limit you can buy your way out of is not a value; it is a lever. ZYRA's One-Active-Journey rule is only a principle for exactly as long as it cannot be purchased.

> **If ZYRA ever sells additional Active Journeys, ZYRA becomes Muzz with better typography.** This should be written down as a constitutional constraint, not left as an assumption.

**Two judgment errors on this screen.** A **"Do you like Muzz? 👍👎"** rating prompt fired on a screen showing zero matches and zero conversations — asking for an App Store review from a user who has received nothing. And the banner **"Love's knocking but your notifications are off ❤️"** — romantic-urgency framing to recover a notification permission the user deliberately declined.

---

### 1.9 Explore — Monetising Regret

Three tabs (For you / Events / My history). The "For you" tab contains:

- **"Likes in your filters (0)"** — empty, immediately followed by a **Boost purchase card**.
- **"Likes just outside your filters (1)"** — a blurred profile teaser with **"See who likes you 👑"** over it.
- Banner: **"Every missed notification is a missed chance."**

**"Likes just outside your filters" is the cleverest and most cynical mechanic in the app.** It shows you people who liked you but whom *your own filters* excluded. It manufactures doubt about your own stated preferences and converts it into either widened filters (more inventory) or a Gold purchase. It monetises regret.

**The teaser I was shown was timestamped "Last year."** A like more than twelve months old is being displayed as live bait for a £34.99/month subscription. The person is overwhelmingly likely to be inactive or married. **Presenting year-old inventory as a current opportunity crosses from persuasion into misleading**, and in a UK consumer-protection context it is the kind of thing the CMA has taken an interest in.

**"Every missed notification is a missed chance"** is loss-framed FOMO applied to a marriage search. Compare with the honest version: *"Turn on notifications so you don't miss a reply."*

---

### 1.10 Jamaa — A Social Feed Inside a Marriage App

A full X/Twitter-style public feed, sub-branded "Jamaa by Muzz": For you / New / Following tabs, posts with handles, likes, threaded replies, a Create Post FAB, and a **gamified onboarding — "Like 5 posts to get started. The more you like, the better your feed gets"** with a five-node progress track.

There is also a banner promoting **downloading Jamaa as a separate app.**

**Product.** This is not a marriage feature. It is a retention hedge. A marriage app has a structural business problem: **success means the customer leaves.** A social feed solves that problem for the company, not for the user. The gamified feed-training onboarding is a recommendation-engine engagement loop lifted wholesale from social media.

**Trust & safety — this is the largest liability in the app.** The content on screen during review included a public thread on cousin marriage and genetic risk, with hundreds of replies, including amateur genetics presented as fact and at least one reply opening with "Disgusting." A public, apparently lightly-moderated forum, attached to a marriage app, used by young Muslim women, covering religion, sect, ethnicity, family practice and health, is a moderation and legal exposure of a completely different order to the matching product. Under the UK **Online Safety Act**, user-to-user services carry duties that a pure 1:1 matching service largely does not. Muzz has voluntarily taken on a regulated surface.

**ZYRA should not build this, at all, in any form.** Not a feed, not a forum, not comments, not a community tab. It contradicts the entire premise of a deliberate, private, family-involved process, and it imports a regulatory burden ZYRA has no reason to carry.

---

### 1.11 Safety & Advice

Four cards: Profile Quality Guidelines ("See how to create a **halal** profile"), Behaviour Guidelines, Safety Guidelines, Safety Resources ("Mental health, physical safety and more").

Well built, well written, appropriately prominent (a top-level chip on the Menu, not buried). Applying religious framing to profile *quality* — "a halal profile" — is a nice piece of category-appropriate language. Including **mental health** resources signals a duty-of-care posture that most dating apps avoid because acknowledging harm invites liability.

**ZYRA should copy the structure of this wholesale.** ZYRA has `SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V3.md` as a document but no equivalent in-product surface.

---

## 2. Top 50 Things Muzz Does Well

1. Screenshot/screen-capture protection on member photos and names.
2. Editorial imagery still renders while member photos do not — protection is scoped correctly, not blanket.
3. "Block my phone contacts" — the single best culturally-specific feature in the category.
4. Discreet, unbranded app icon option.
5. App-level passcode lock.
6. Date of birth locked after one change.
7. Age and identity verification exists as a concept with a visible badge.
8. "Take a break" as a first-class account state, distinct from delete.
9. Three distinct account exits (restart / pause / delete) rather than one destructive option.
10. Report flag placed inside the photo viewer, at the moment of harm.
11. Safety Resources include mental health, not just physical safety.
12. "Halal profile" framing — religious language applied to product quality.
13. Sect granularity (Hanafi, Hanbali, etc.) shows real domain understanding.
14. Sect filtering is free, not paywalled.
15. Ethnicity filtering is free.
16. "Grew up in" as a filter — captures cultural formation better than nationality.
17. "Marriage plans" as an explicit, filterable intent field.
18. "Family plans" as a filterable field.
19. "Relocation plans" — surfaces a common late-stage dealbreaker early.
20. Marital status and children as first-class fields, not buried in bio.
21. Blurred-photo support for users who want modesty.
22. A filter *for* blurred photos, so preference is mutual.
23. Mutual-message requirement before a conversation activates.
24. Conversation slots visualised concretely rather than described in text.
25. Invisible mode / granular profile visibility control.
26. Profile sharing link off by default.
27. "Hidden photos stay hidden" when a profile link is shared — thoughtful edge case.
28. Chaperone/guardian requires nothing of the chaperone — zero adoption friction.
29. Chaperone is optional, so it never blocks the user.
30. "Block social chat requests from women" — granular, gendered contact control.
31. "Profiles I've blocked" is a visible, manageable list.
32. Verification badge displayed inline on the profile card.
33. "Active today" freshness indicator.
34. Identity tags as compact pills — high information density, low cognitive load.
35. Conventional swipe directions (right = positive) — no learning cost.
36. Full-bleed photo card — confident, modern, category-appropriate.
37. Clear top-level tab architecture with legible labels.
38. Multiple price points and commitment lengths.
39. Consumables for users who will never subscribe — captures non-subscriber revenue.
40. Paywall shows 3 features first, expandable to 12 — progressive disclosure.
41. No mid-swipe interstitial ads or full-screen takeovers.
42. Restore Purchases is present and easy to find.
43. Language selection in-app.
44. Notification settings honour the user's decline (nagging, but not overridden).
45. Separate Marriage and Friends chat inboxes — intent separation.
46. Distinct "Marriage" mode selector at the top of Menu.
47. Empty states explain the underlying rule rather than just saying "nothing here."
48. Filters screen has a "Clear all" — easy escape from over-filtering.
49. Version maturity (build 560) evident in polish and edge-case handling.
50. The product clearly knows its user is watched — and designs for it.

---

## 3. Top 50 Things ZYRA Already Does Better

Stated honestly: several of these are *design intent* rather than shipped, working code. The engineering audit of 2026-07-26 found real gaps. I have marked those **[intent]**.

1. Guardian is a first-class account type, not a mailing-list CC.
2. Guardian has their own app shell and experience.
3. Guardian Gate blocks Journey progression — real participation, not passive observation.
4. Family Review Period (48h) makes the family a genuine participant in pacing.
5. Journey is a structured process with named stages, not an unbounded chat.
6. Pre-Journey Ritual creates deliberate commitment before conversation opens.
7. One Active Journey at a time as a stated principle. **[intent — not concurrency-safe today]**
8. Compatibility is computed from a ~174-question values instrument, not filter overlap.
9. Traffic-light preferences (green/amber/red) capture nuance a boolean filter cannot.
10. Hard Requirements as an explicit, separate concept from preferences.
11. Compatibility percentage deliberately withheld until Active Journey — resists gamification.
12. Compatibility score never exposed to the client at all.
13. Three-way decision (Consider / Save / Pass) rather than binary like/pass.
14. "Consider" is a better mental act than "Like" for marriage.
15. Decline is never recorded and never notified — no rejection accounting.
16. Saves are private and never revealed to the saved person.
17. No "see who likes you" paywall.
18. No consumable currencies of any kind.
19. No Boosts.
20. No Compliments/super-likes as a purchasable.
21. No paid undo of a decision.
22. No Rematch — an unmatch stays an unmatch.
23. No VIP/status badges creating a visible class system.
24. No social feed, forum or comment surface.
25. No separate "Friends"/social mode diluting marriage intent.
26. Single subscription tier — no pricing maze.
27. Journey Suspension ("Pause") as a designed, first-class state.
28. 24-hour cooling period after ending a Journey — enforced deliberation.
29. Restart requires going through the full process again — no cheap re-entry.
30. Milestone timeline (match → conversation → family stage → meeting → nikah) orients toward the actual goal.
31. "Nikah" exists as a modelled milestone — the product knows what success is.
32. Journey stages named in the domain's own language.
33. Server-side write boundaries on matches, subscriptions and conversations.
34. RLS enabled on all 24 tables.
35. Private photo storage bucket with signed URLs.
36. Row-level own-data-only policy on the values questionnaire.
37. Compatibility scoring runs server-side so raw answers never leave the database.
38. Sect, ethnicity *and* religious practice are all part of the free model. **[intent]**
39. No paywall on any safety-relevant capability.
40. Explicit error/empty-state standard with defined categories.
41. Documented image-handling standard including EXIF/GPS stripping. **[intent — unbuilt]**
42. Documented moderation pipeline with human review queue. **[intent — unbuilt]**
43. "Minimum 3 photos + moderation approval + ID verification before profile is live." **[intent — unbuilt]**
44. Decision Records cited inline in source code — traceable product reasoning.
45. Terminology standard enforcing consistent product language.
46. Advertising standard that explicitly forbids ambiguity between a match and an ad.
47. Subscription transparency standard as a governing document.
48. Global platform principles document constraining future features.
49. Safeguarding explicitly prioritised over monetisation in the Guardian design.
50. A written philosophy that a feature can be rejected against — Muzz has no visible equivalent.

---

## 4. Top 50 Opportunities for ZYRA to Lead

**Safety and trust (highest leverage — this is where the category is weakest)**
1. Screenshot/screen-record protection on all member photos and names.
2. Discreet app icon.
3. App-level passcode / Face ID lock.
4. Contact-list blocking ("never show me to anyone in my phonebook").
5. Banded distance ("under 5 miles") — never street-level.
6. Let the *displayed* user set their own location precision.
7. Free ID and age verification for everyone — never a paid filter.
8. Verification as a requirement for progression, not a badge.
9. Photo EXIF/GPS stripping enforced server-side (currently unbuilt).
10. Mandatory photo moderation before a profile goes live (currently unbuilt).
11. Report-in-context on every photo and message.
12. A published, plain-English safety centre in-product.
13. Mental-health resources surfaced with the same weight as physical safety.
14. Guaranteed finality of blocking and unmatching — never purchasable.
15. Cooling-off on repeated contact attempts.
16. Household-safety mode: rapid hide/exit gesture.

**The Guardian system — ZYRA's actual moat**
17. Guardian-unavailable path with grace periods and auto-continue.
18. Nominated alternate Guardian.
19. Guardian onboarding that works for a non-technical 60-year-old.
20. Guardian-side digest by SMS/email for guardians who will not install an app.
21. Guardian reputation/response-time visibility so seekers can pick an engaged guardian.
22. Explicit Guardian code of conduct — guardians can be abusive too.
23. A route for a seeker to escalate or replace an obstructive Guardian.
24. Guardian-to-Guardian introduction as a formal, structured stage.

**Compatibility — where ZYRA can be genuinely differentiated**
25. Publish the compatibility methodology; make it inspectable.
26. Show *why* two people are compatible, not a number.
27. Surface incompatibilities honestly and early.
28. Let both parties see which Hard Requirements they each set.
29. Deal-breaker-first matching: filter on the four or five things that actually end marriages.
30. Values drift check partway through a Journey.
31. Family-expectations compatibility as a distinct axis from personal compatibility.

**Process and intent**
32. Make One Active Journey constitutionally unpurchasable and say so publicly.
33. Publish an outcomes metric — Journeys reaching nikah — and be judged on it.
34. Ship a "we think you should take a break" prompt when usage looks compulsive.
35. Graduation: an explicit, celebrated way to leave the app.
36. No daily limits framed as scarcity; limits framed and priced as principle.
37. Time-boxed Journeys with a natural decision point.
38. Structured question sets that surface real information, not small talk.
39. Post-Journey reflection to improve the next one.

**Product and UX**
40. Conventional swipe directions, or remove swiping entirely.
41. First-run coach mark for any non-standard gesture.
42. Full accessibility baseline — the audit found effectively zero semantic labelling.
43. Text scaling support (299 hardcoded font sizes today).
44. Distinguish "no results", "network error" and "permission denied" in every empty state.
45. Offline tolerance with honest messaging.
46. Pull-to-refresh everywhere.
47. "Grew up in", marriage plans, family plans and relocation plans as free fields.
48. Blurred-photo support with mutual preference matching.

**Commercial**
49. Price on outcome, not on removal of penalties — a single honest subscription that adds capability rather than lifting throttles.
50. Never throttle free users' visibility, and say publicly that you don't.

---

## 5. What Contradicts ZYRA's Philosophy — Never Copy

| # | Muzz pattern | Why it is incompatible with ZYRA |
|---|---|---|
| 1 | **Paid "See who likes you"** | Sells the user a fact about themselves that the platform is withholding. |
| 2 | **Throttling free users' visibility** | "Double your daily profile visits" is a penalty sold as a feature. |
| 3 | **Paid ID/age-verified filter** | Safety is not a SKU. This is the single worst decision in the app. |
| 4 | **Paywalled religious-practice filters** | Charges for the exact axis the product exists to serve. |
| 5 | **Rematch** | Monetises the reversal of someone else's boundary. |
| 6 | **Paid undo of pass/block** | A block should be final. |
| 7 | **Consumable currencies (Likes/Boosts/Compliments)** | Free-to-play game economics applied to marriage. |
| 8 | **Purchasable conversation slots** | Turns a stated value into a revenue lever. |
| 9 | **A social feed inside a marriage app** | Retention hedge against the core product succeeding. |
| 10 | **Gamified feed training ("Like 5 posts")** | Engagement loop with no relationship to marriage. |
| 11 | **"Likes just outside your filters"** | Manufactures regret and sells the cure. |
| 12 | **Surfacing year-old likes as live opportunities** | Misleading, and a consumer-protection risk. |
| 13 | **Street-level distance by default** | Physical safety risk to women. |
| 14 | **"Every missed notification is a missed chance"** | Loss-framed FOMO in a marriage context. |
| 15 | **"Love's knocking but your notifications are off"** | Emotional manipulation to recover a declined permission. |
| 16 | **Rating prompt on an empty state** | Asks for advocacy before delivering value. |
| 17 | **Decoy weekly price** | Anchoring the user against a price nobody should buy. |
| 18 | **"Find your wife faster"** | Speed is the wrong promise; ZYRA's promise is rightness. |
| 19 | **VIP badges** | Visible paid class system inside a marriage market. |
| 20 | **"Gold member" as a filter** | Lets money buy assortative access to money. |
| 21 | **A parallel social/friends mode** | Dilutes intent; reintroduces the ambiguity ZYRA removes. |
| 22 | **Zero-balance counters ("0 Boosts")** | Manufactured deficiency. |

---

## 6. Proposed New ZYRA Decision Records

Per your instruction, these are proposals for ratification, not implementations.

| Ref | Proposed Decision | Rationale |
|---|---|---|
| **DR-A** | **Screen-capture protection on all member photos and names.** | Muzz's best safety decision; ZYRA has nothing. Prevents non-consensual sharing of women's photos. |
| **DR-B** | **The One Active Journey rule is constitutionally unpurchasable.** No SKU, bundle or promotion may ever increase it. | Muzz's 5-chat cap proves that a limit you can buy is a lever, not a value. |
| **DR-C** | **No safety-relevant capability may sit behind a paywall.** Verification, blocking, reporting, filtering for verified users, and privacy controls are free forever. | Directly inverts Muzz's worst decision. |
| **DR-D** | **Distance is always banded, never precise**, and precision is controlled by the displayed user. | Street-level distance on a woman's profile is a physical safety risk. |
| **DR-E** | **Date of birth is immutable after profile creation** without support intervention; a minimum-age constraint is enforced in the database. | Muzz has solved this; ZYRA's audit found DOB freely editable via the API. |
| **DR-F** | **ZYRA will not build a social feed, forum, or public comment surface.** | Retention hedge, philosophical contradiction, and an Online Safety Act burden. |
| **DR-G** | **Guardian-unavailable path.** Defined grace periods, nominated alternate, and a stated auto-continue default. | Removes ZYRA's single largest product risk: a hard dependency on a third party's engagement. |
| **DR-H** | **Household-safety feature set:** discreet app icon, passcode lock, contact-list blocking. | Muzz's implicit threat model — "someone else may pick up this phone" — is correct for this market. |
| **DR-I** | **No consumable currencies, ever.** One subscription. | Prevents drift into free-to-play economics. |
| **DR-J** | **Free-tier visibility is never throttled**, and ZYRA will state this publicly. | Turns Muzz's worst mechanic into ZYRA's marketing. |
| **DR-K** | **Blocks and unmatches are permanent and unpurchasable.** | Kills the Rematch pattern before it can be proposed. |
| **DR-L** | **Report-in-context** on every photo, profile and message. | Cheap, proven, currently absent from ZYRA. |
| **DR-M** | **"Take a break" as a first-class account state.** | Healthy-behaviour affordance; ZYRA has Journey suspension but no account-level pause. |
| **DR-N** | **Publish an outcomes metric.** | The strongest available differentiator against an engagement-optimised incumbent. |
| **DR-O** | **Reconsider the Browse sponsored-card slot (DR-ZYRA-109).** | It is the first step onto exactly the path this document argues against. |

---

## 7. Inconsistencies and Duplication Inside Muzz

1. **"Marriage" and "Friends" modes** create two products with different norms in one app — and a "Block social chat requests from women" setting exists to manage the collision.
2. **Discovery is split across Marriage and Explore** with overlapping purposes and no clear rule for which belongs where.
3. **Three separate consumable currencies** with no explained relationship.
4. **Jamaa is simultaneously an in-app tab and a separate app being promoted for download** — cannibalising its own surface.
5. **Boosts appear as a Menu card, an Explore card, and a Gold benefit** — three entry points, one product.
6. **"Sort" is a prominent free-looking top-bar control that is actually a Gold feature.**
7. **Photo viewer shows both dot indicators and an "n/N" counter** — redundant.
8. **Two notification-enable banners with different copy** on Chat and Explore.
9. **The Gold sticky CTA overlaps the feature list** it is asking you to read.
10. **The Menu's bottom card is clipped by the tab bar** and cannot be scrolled clear.
11. **"Advanced filters" is both a Gold benefit and an in-context upsell** in the Filters screen — duplicated sell.
12. **Verification is a badge, a paid filter, and a trust signal**, with no single coherent story about what it means.

---

## 8. Patterns Worth Adapting

1. Report flag inside the photo viewer.
2. Visualising a rule as furniture (the five slots) — powerful, and usable for good: show ZYRA's *one* Journey slot as a single, deliberate, honoured space.
3. Mutual-message requirement before a conversation opens.
4. Empty states that teach the rule rather than apologising.
5. Compact identity pills for high-density, low-effort scanning.
6. "Active today" freshness signal — but only if honest.
7. Progressive disclosure on the paywall (3 → 12).
8. Safety Centre as a top-level chip, not a settings sub-page.
9. Three-way account exit (restart / break / delete).
10. Settings copy that explains *why* ("For additional privacy…") rather than just naming the toggle.
11. "Grew up in" as a cultural-formation field.
12. Blurred photos plus a matching preference filter.
13. Sect granularity as a signal of genuine domain respect.
14. Sub-branding a distinct surface — if ZYRA ever ships one, though §5.9 argues it should not.

---

## 9. Premium Features That Should Inspire Better ZYRA Equivalents

| Muzz | Problem it exploits | Better ZYRA equivalent |
|---|---|---|
| See who likes you | Curiosity about mutual interest | Show incoming interest to everyone, free. Charge for nothing that is a fact about the user. |
| Advanced filters | Precision matching | All filters free; charge instead for **depth** — extended values instrument, richer compatibility reporting. |
| Boosts | Visibility anxiety | Never throttle. If visibility is ever varied, vary it by *profile completeness and good conduct*, not payment. |
| Compliments | Standing out | A single, free, high-intent opener that must reference something specific from her profile. |
| Rematch | Regret | Nothing. This should not exist. |
| Change your mind | Regret | A short free undo window (seconds, not purchasable). Blocks remain permanent. |
| Invisible mode | Privacy | Free. Privacy is not a premium good. |
| VIP badge | Status | Replace with earned, non-purchasable signals: verified, Guardian-linked, values instrument completed. |
| 5 extra chat slots | Focus vs. optionality | Never. One Active Journey is the product. |
| Discover Sorting | Control | Free. |

**The pattern:** almost every Muzz premium feature monetises an anxiety the product itself created. **ZYRA's premium tier should monetise capability the product genuinely adds** — deeper compatibility work, richer family involvement, better guidance — not the removal of self-inflicted friction.

---

## 10. Legal, Safeguarding and Moderation Lessons

1. **Online Safety Act.** Jamaa makes Muzz a user-to-user service with duties ZYRA can avoid entirely by never building a feed. This is a genuine regulatory saving.
2. **Special-category data.** Religious belief and ethnicity are Article 9 UK GDPR data. Both platforms hold it. ZYRA holds *more* of it (a 174-question values instrument). Explicit consent, a retention schedule, and export/erasure must be real, not documentary.
3. **Age assurance.** Muzz locks DOB and offers age verification. ZYRA currently allows arbitrary DOB edits via the API and has no minimum-age constraint. This is the most urgent safeguarding gap ZYRA has.
4. **Location precision.** Street-level distance is a physical-safety risk. Band it.
5. **Consumer protection.** Decoy pricing and year-old likes presented as live opportunities are the kind of practice the CMA scrutinises. ZYRA should hold a "no dark patterns" standard as a competitive claim.
6. **Boundary finality.** Selling re-contact after an unmatch is a safeguarding failure regardless of consent mechanics. Never build it.
7. **Moderation cost is not optional.** ZYRA's image standard specifies a full AI + human moderation pipeline. None of it is built. Launching a photo-based marriage platform with zero moderation is the single largest launch risk in the project.
8. **Duty of care.** Muzz's mental-health resources are a good model. Marriage search involves rejection; the platform should acknowledge that.
9. **Guardian abuse.** ZYRA's Guardian holds real power over a woman's Journey. That power can be misused. A Guardian code of conduct and an escalation route are required before launch, not after.
10. **Data minimisation.** ZYRA's compatibility system could work on hashed/derived values rather than storing raw answers indefinitely. Worth exploring before the dataset grows.

---

## 11. Forget That Muzz Is Successful

You asked me to challenge every decision from first principles and to say where something exists only because of history, legacy or growth hacking. This is the most valuable section, so I have been blunt.

### 11.1 The swipe deck would not survive a 2026 whiteboard

Swiping exists because Tinder proved in 2012 that it manufactures the *feeling* of a liquid marketplace, and because it is the cheapest possible way to collect preference data. It is optimised for rapid photo-based judgement.

Marriage selection is the single worst possible application of that mechanic. The traits that predict a successful marriage — values alignment, conflict style, family expectations, financial attitudes, religious practice — are **all invisible in a photograph.** Muzz has a swipe deck because in 2015 that was what an app was, and because every subsequent quarter had a growth target that swiping served.

**If Muzz were founded in 2026, with LLMs available, they would not build a swipe deck.** They would build structured mutual disclosure with progressive revelation, and photos would arrive late, not first. ZYRA has half-built this — the values instrument, the Journey ritual — and then put a swipe deck in front of it. **ZYRA's Browse is legacy inherited from a competitor's 2012 constraint. It deserves to be challenged, not refined.**

### 11.2 "See who likes you" is a tax on information asymmetry

The platform knows something about you and hides it from you so it can sell it back. Nothing about that requires a product decision — it requires a *withholding* decision. It exists because it is the highest-converting mechanic ever found in this category.

Founded today with any intent to be trusted, you would show it free and charge for something you actually add.

### 11.3 Six of twelve Gold features are penalty removal

Like limits, chat slots, visibility throttling, sorting, filters, undo. **Muzz's paid tier is substantially "stop hurting me" rather than "give me more."** This is legacy free-to-play design that arrived via mobile gaming and colonised dating apps around 2016-2018.

A 2026 product built for trust would price on added capability and never on self-inflicted friction — because users increasingly recognise the pattern, and because the marginal cost of *not* throttling is zero.

### 11.4 Jamaa exists because the business model conflicts with the user's goal

A marriage app succeeds when its user leaves. That is an unusual and uncomfortable business. Rather than solve it — by charging appropriately for a successful outcome, or accepting high churn as a sign of quality — Muzz bolted on a social feed so users have a reason to stay after the marriage product has served or failed them.

**This is a business-model problem wearing a feature costume.** ZYRA has the same underlying problem and must answer it honestly: *what does ZYRA want a successfully married user to do?* The right answer is "leave, and tell people" — which means the pricing model has to work with high, fast churn. Get that right and you never need a feed.

### 11.5 The dual Marriage/Friends mode is TAM expansion, not product design

A marriage app that also does friendship reintroduces exactly the ambiguity — *is this person serious?* — that the marriage app existed to remove. This is a growth decision that damaged the core promise. It is the clearest example in the app of something that would not exist if drawn fresh today.

### 11.6 Free ethnicity, paid religiosity is an accident that became a value

I do not believe anyone decided "we should encourage ethnic matching and charge for deen." Practising-level filters convert better, so they went behind the paywall. But the free product is the product most people experience, and the free product optimises for biradari. **A 2026 founding team that had thought about this for ten minutes would invert it.**

### 11.7 What I would actually build instead

If I were building this category from scratch in 2026, knowing what we now know:

1. **No swipe deck.** A small number of deeply-considered introductions per week, with a written reason for each. Scarcity as genuine curation, not as a purchasable cap.
2. **Structured mutual disclosure before photos.** Values, then conversation, then faces. Photos unlock on mutual progression. This is roughly what ZYRA's Journey already does — the mistake is putting Browse in front of it.
3. **LLM-assisted compatibility that explains itself in prose**, not a percentage. "You both said X; you differ on Y; here is the question you should ask each other." A number invites gamification; a paragraph invites reflection.
4. **The guardian as a designed participant with graceful degradation** — ZYRA's architecture, plus Muzz's zero-friction fallback.
5. **Verification mandatory and free**, as a condition of participation rather than a badge.
6. **Priced on outcome, honestly:** a single subscription, no consumables, no throttling, and a public commitment that nothing safety-related is ever paid.
7. **No feed, no forum, no social mode.** Accept the churn.
8. **An explicit graduation ritual.** Celebrate leaving. Make the exit the most beautiful screen in the app — it is the best marketing a marriage product can have.
9. **Household-safety as a first-class design constraint**, not a settings sub-page.
10. **Publish the outcomes.** The first Muslim marriage platform to publish verified nikah rates and let itself be judged on them takes the category, because every competitor is optimised for retention and cannot follow.

---

## 12. Final Founder Report

> **"If Muzz launched today as a startup, knowing everything we now know in 2026, what would you build differently?"**

Muzz is a **very well-executed 2016 product** that has been polished for a decade. Build 560 shows it: the edge cases are handled, the safety settings are thoughtful, the cultural understanding is real and hard-won. The team clearly knows this user. "Block my phone contacts" is not a feature you invent in a workshop — it comes from listening to someone explain why they deleted the app.

But its **architecture of incentives is inherited from a different industry.** Underneath the Islamic framing, the mechanics are Tinder's discovery loop, Candy Crush's currency economics, and Twitter's engagement feed. Those three systems are each optimised for one thing — time in app — and marriage is the one consumer category where time in app is a *failure* signal.

**The single sentence version:** Muzz sells you the removal of obstacles it created, in a product designed to keep you rather than to finish with you.

If it launched today, I believe the team would keep the safety architecture, the cultural depth, the verification, and the filter taxonomy — and would not build the swipe deck, the three currencies, the visibility throttle, the paid "see who likes you", the social feed, or the friends mode. Not because those are unprofitable, but because a 2026 user recognises them, and because the category's next winner will win on **trust**, not on liquidity. Muzz already has the liquidity. It is spending the trust to monetise it.

**What this means for ZYRA.**

ZYRA's philosophy is right, and it is genuinely differentiated — the Guardian system in particular is a real moat that Muzz has not attempted. But three things need to be true for that to matter:

1. **The engineering has to actually work.** The 2026-07-26 audit found that no real user can currently appear in Browse, that a "fixed" data-protection issue is still open, and that developer credentials ship in release builds. Philosophy does not survive contact with a broken discovery loop.
2. **ZYRA must ship the safety features Muzz already has.** Screenshot protection, contact blocking, a passcode, a discreet icon, immutable DOB. These are table stakes in this market and ZYRA currently has none of them.
3. **ZYRA must write down what it will never sell** — before the first revenue pressure arrives, not after. Every mechanic in §5 was, at some point, a reasonable-sounding suggestion in a growth meeting at a company that also started with good intentions.

The opportunity is real. The incumbent is beatable, not because it is bad, but because it is optimised for the wrong outcome and is too big to change. **ZYRA's advantage is that it can still choose.**

---

## 13. Version History

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-01 | Initial teardown — Muzz iOS v8.87.0 (560), free tier, UK. Screen-by-screen review, 50/50/50 lists, 15 proposed Decision Records, first-principles challenge. |

---

## 14. Governing References

- `ZYRA_ENGINEERING_AUDIT_CURRENT_VERSION_V1.md` — findings C1–C4 referenced throughout
- `COMPETITOR_REVIEW_MUSLIM_MARRIAGE_PLATFORMS_CURRENT_VERSION_V1.md`
- `WALI_ARCHITECTURE_CURRENT_VERSION_V6.md` — §1.7 relates directly
- `IMAGE_HANDLING_CURRENT_VERSION_V2.md` — §10.7 relates directly
- `GLOBAL_PLATFORM_PRINCIPLES_CURRENT_VERSION_V1.md`
- `ADVERTISING_STANDARD_CURRENT_VERSION_V1.md` — §5.22 and DR-O relate directly
- `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` — DR-A to DR-O proposed for entry
