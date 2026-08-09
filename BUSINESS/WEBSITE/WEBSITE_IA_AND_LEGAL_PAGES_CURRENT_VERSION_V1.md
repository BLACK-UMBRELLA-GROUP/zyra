# ZYRA — Website Information Architecture & Legal Pages Blueprint

**Version:** V1
**Status:** CURRENT_VERSION — PROPOSED, awaiting Founder review
**Date:** 2026-08-01
**Author:** Fable, UX & Product Experience Lead
**Commissioned by:** Founder, via ChatGPT brief (footer/legal pages research) — companion to Opus's `ZYRA_LEGAL_RESEARCH` clause coverage matrix
**Purpose:** Defines every page ZYRA's website should have, why, in what order, and gives Opus a per-page specification to draft from. This is the *what and why*; Opus drafts the *words*; the Founder approves; a solicitor reviews the legal four before launch.

**Not legal advice.** Same caveat as Opus's research, same reasoning.

---

## 1. What the leaders actually do — pattern synthesis

Rather than page-by-page tourism through fifteen footers, the useful finding is that footers cluster into four archetypes, and ZYRA needs a deliberate blend of two of them:

**The dating-app pattern (Muzz, Hinge, Bumble, Tinder).** Legal four + Safety Centre + Success Stories + app-store badges. Muzz's safety cluster is genuinely good — a Safety Center hub with Guidelines and Behavior sub-pages, plus UK-specific helplines (Samaritans, Women's Aid, Muslim Counsellor, Muslim Women's Help). Hinge/Bumble lead with "designed to be deleted"-style mission framing. Tinder's legal pages are the structural gold standard (Opus's matrix confirms this from full retrieval). What they all share: safety content is *marketing* for a dating app — it converts anxious users, it doesn't just satisfy regulators.

**The fintech trust pattern (Monzo, Revolut, Stripe).** The insight worth stealing: fintechs treat trust pages as product surface — named regulators, complaint routes, "how we protect your money" in plain English, service status. Users under stress find operational honesty, not marketing. ZYRA's equivalent stress moment is a worried parent or a woman assessing whether the app is safe to be seen on.

**The minimalist pattern (Linear, Notion).** Small teams, small footers: product, pricing, about, legal, contact, done. The lesson is negative space — a footer full of empty-shelf links (blog with 2 posts, careers with no jobs, press with no coverage) signals "small company pretending", which is worse than a short footer signalling "focused company".

**The platform pattern (Apple, Google, Microsoft, LinkedIn, OpenAI, Airbnb).** Mostly irrelevant scale, but three items transfer: accessibility statements as first-class pages, AI transparency pages (OpenAI/LinkedIn), and Airbnb's community-standards-as-narrative (rules explained through values, not legalese).

**ZYRA's blend: dating-app safety cluster + fintech operational honesty, at minimalist size.**

---

## 2. Recommended architecture — three tiers

### Tier 1 — must exist at public launch (blocking)

| Page | Why |
|---|---|
| Home | Conversion. The one page most visitors ever see |
| How ZYRA Works | The Journey model is unfamiliar; unexplained = uninstalled |
| For Guardians & Families | **Novel, no competitor equivalent.** See §4.1 |
| Safety | The audience's #1 question, and a legal-duty surface (OSA) |
| Privacy Policy | Legal. Opus's matrix §4.1 |
| Terms of Service | Legal. Opus's matrix §4.2 |
| Community Guidelines | Public face of `SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V3` |
| Help Centre | Web mirror of the in-app FAQ (post-review version, same source of truth once it moves to Supabase) |
| Contact | One honest page: support email, expected response time |
| Account Deletion | Apple/Google *require* a reachable web deletion path; also GDPR hygiene |
| Accessibility Statement | Cheap, differentiating, and honest about the roadmap |
| Cookie banner + policy | Only if the site ships analytics — otherwise a one-line "no cookies" statement, which is itself a trust win |

### Tier 2 — within weeks of launch (trust deepeners)

| Page | Why |
|---|---|
| How ZYRA Decides Who You See | Algorithm transparency in plain English. See §4.2 |
| What ZYRA Will Never Do | The commitments page. See §4.3 |
| Subscription & Refunds | Pricing, auto-renewal, 14-day cooling-off, how to cancel — CMA-sensitive per Opus §2, deserves a plain-English page not just a Terms clause |
| Report & Appeals | What happens after a report; how to appeal a removal. **Blocked on the moderation queue existing** — must not ship before the process it describes |
| About | Founder story, why ZYRA exists. Short. Honest about being new |

### Tier 3 — earned, not built on faith

Success Stories (needs real couples — fake or borrowed stories would be fatal in this community), Blog/Guides (only with a real cadence), Press (only with real coverage), Careers (only with real roles). **Recommendation: none of these at launch.** An empty shelf is worse than no shelf.

### Explicitly recommended against

- **A religious-rulings page.** ZYRA should describe its *approach* (marriage-first, family-present, Islamically-grounded) and define terms it uses (Guardian, Nikah, Mahram) in a glossary — but must not issue or imply fatwas, endorse a madhhab, or arbitrate fiqh. That is scholars' terrain; a commercial platform placing itself there invites a legitimacy fight it cannot win. If scholarly endorsement is ever secured, name the scholars and let *them* speak.
- **US-style arbitration clauses** (per Opus §4.2 — UK launch).
- **Live chat / ticket portal** — there is no team behind it. The Contact page says email, honestly.

---

## 3. Footer layout (for the site build)

```
ZYRA
Connecting Through Trust

Product            Safety & Trust        Company          Legal
How ZYRA Works     Safety                About            Privacy Policy
For Guardians &        Community Guidelines  Contact          Terms of Service
  Families         How ZYRA Decides     Help Centre       Cookie statement
Pricing              Who You See                          Accessibility
                   What ZYRA Will
                     Never Do
                   Account Deletion

[App Store badge]  [Play badge]     © ZYRA / [Company Ltd], England & Wales · [co. no.]
```

Four columns, ~16 links, no social icons until the accounts exist. Company line is blocked on incorporation (Opus §6).

---

## 4. The pages nobody else has — ZYRA's trust differentiators

### 4.1 For Guardians & Families

The single highest-value page on the site and the reason someone chooses ZYRA over Muzz. Audience is *not* the Seeker — it's her father, or the cautious parents of a son. Content: what a Guardian is on ZYRA (drawing on `WALI_ARCHITECTURE_CURRENT_VERSION_V6` — male guardian, full account, real role); what the Guardian sees and *cannot* see ("guidance, not surveillance" — private conversations are never shared, stated as a commitment); how linking works; what the Family Review Period is; a section written directly to parents whose child asked them to join. Tone: the UX Writing standard applied to a 55-year-old reader — warm, unhurried, zero app-jargon. This page converts the real decision-maker in many households.

### 4.2 How ZYRA Decides Who You See

Plain-English algorithm transparency, doing double duty as the Art. 22-adjacent disclosure Opus's matrix flags (automated ordering + Hard Requirement exclusion must be disclosed somewhere users can find). Content: you answer values questions; ZYRA orders Browse by alignment; anything you marked non-negotiable filters both directions; no score is shown while browsing and why; what ZYRA does *not* use (no engagement-maximising ranking, no pay-for-visibility — verify against pricing doc before drafting: profile unlocks must be honestly described). This page turns a legal obligation into a brand asset — nobody in the category explains their matching honestly.

### 4.3 What ZYRA Will Never Do

The fintech-style commitments page, harvesting promises already made in governed docs and the FAQ review: never sell additional Active Journeys · never show your distance or precise location (declared city only — per the inshAllah precedent Opus found, stated proudly) · never charge for safety features · never share private conversations with anyone, including a Guardian · never run engagement-bait notifications. **Every line requires explicit Founder sign-off — these are quotable forever.** Only include commitments the product actually keeps today; each one becomes a testable claim.

### 4.4 Glossary (small, folded into How ZYRA Works or standalone)

Guardian, Mahram, Nikah, Salam, Journey — one calm sentence each, written for second- and third-generation British Muslims and for non-Muslim family members who get shown the app. Improves comprehension and SEO simultaneously without becoming a religious-authority page.

---

## 5. Per-page specification for Opus

Format: purpose → key messages → outline → constraints. Tone for all: `APP/UX Writing/Summary.md` applied to web copy — people before software, no dating-app tropes, no gamification language. Honesty rule from the FAQ review binds everywhere: **describe the product that exists, not the one intended.**

**Home.** Purpose: convert the cautious. Messages: marriage-first not swipe-culture; one Journey at a time; families included by design; British Muslim, built here. Outline: hero + tagline ("Connecting Through Trust"), three-step How It Works strip, Guardian/family section, safety strip, download CTAs. Constraint: no user-count or success claims (there are none yet); no screenshots of features that don't exist.

**How ZYRA Works.** Purpose: teach the Journey model pre-download. Outline: Browse → Consider → Match (Potential Journey) → Active Journey stages → family involvement → what happens when a Journey ends (cooling period). Constraint: use the app's real vocabulary (Consider/Save/Pass) and nothing aspirational.

**For Guardians & Families.** Per §4.1. Dependencies: WALI_ARCHITECTURE V6 is the source of truth; nothing beyond it.

**Safety.** Purpose: operational honesty for the worried. Outline: blocking (instant, private, mutual invisibility — real), reporting (**wording gated on the FAQ-review caveat**: no implied moderation team until the queue exists), photo privacy (private storage, expiring links — real), declared-location-only commitment, UK helplines list (mirror Muzz's including Muslim-specific lines — verify each number at draft time), guidance for meeting safely with family present. Constraint: the verification disclaimer belongs here in plain English as well as in the Terms (Opus §2: nothing is built — say "verification is coming; here's what to do meanwhile" rather than implying checks exist).

**Community Guidelines.** Purpose: public, warm rendering of `SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V3`. Airbnb-style values-first structure: what ZYRA expects (respect, honesty about intentions, marriage-seriousness), what's never tolerated, what happens when rules are broken ("we may" language per Opus's moderation-rights note). Constraint: must match actual enforcement capability.

**Help Centre.** Purpose: the in-app FAQ, on the web, same source of truth. Dependency: ships *after* the FAQ review fixes land — the four fiction answers must not be published to the open web.

**Privacy Policy / Terms / Cookies.** Opus's clause matrix is the specification — this document adds only the UX requirements: a plain-English summary box at the top of each (Muzz's cl. 1.3 attention-drawing pattern, rendered in ZYRA's voice); the Guardian privacy notice as its own clearly-navigable section, not buried; retention numbers stated specifically (inshAllah's one-year/three-year pattern as the shape, Founder to decide values — blocker per Opus §6); the Art. 9 consent route decided *before* drafting (Opus's route 2 question to the solicitor). Blocked on: incorporation details, retention decisions, Art. 9 route, live support email.

**Contact.** One page: support email, "a real person reads this", expected response window (Founder to commit honestly — 48h?), no fake form. Blocked on confirming `support@zyra.app` mailbox actually exists (flagged in both Opus §6 and the FAQ review).

**Account Deletion.** Purpose: store compliance + trust. Outline: what deletion removes (mirror the real `delete_own_account()` cascade — accurate today), how to do it in-app, what's retained and for how long (blocked on retention decisions). Constraint: must match the FAQ's corrected deletion path.

**Accessibility Statement.** Purpose: honesty as differentiation. Outline: commitment, current state (in progress — semantic labelling and text scaling on the roadmap per the audit's findings), how to report barriers, timeline. Constraint: do not claim WCAG conformance that doesn't exist; "we're building toward it, here's where we are" is the only honest version and still ahead of the category.

**Subscription & Refunds (Tier 2).** Plain-English: what's free (safety, always), what One adds, prices, renewal, cancellation paths (Apple/Google flows), 14-day cooling-off with the digital-content carve-out. Source: pricing doc + Opus §2. CMA-sensitive — solicitor reviews this page too.

**Report & Appeals (Tier 2).** Blocked on moderation queue. Spec exists so it's drafted the week the queue ships, not scrambled after.

**About (Tier 2).** Founder story, short. Honesty is the asset: new company, why it exists, what it refuses to become. No stock-photo team page.

---

## 6. Founder decisions required

1. Every line of "What ZYRA Will Never Do" (§4.3) — each is a permanent public commitment.
2. Retention numbers (blocks Privacy Policy + Account Deletion + Help Centre deletion answer).
3. Art. 9 consent route — solicitor question one (Opus §2A route 2 recommended for the ask).
4. Support email + response-time commitment.
5. Incorporation details (blocks footer company line, Terms, Privacy).
6. Whether the site ships analytics at all (determines cookie banner vs. proud "no cookies" line).
7. Tier 3 confirmation: agree to launch *without* Success Stories/Blog/Press/Careers.

## 7. Sequencing with Opus

Opus drafts in this order: (1) the two legal-blocked documents *in skeleton* with decision-placeholders so the solicitor brief is ready the day blockers clear; (2) full drafts of everything unblocked: How ZYRA Works, For Guardians & Families, Safety, Community Guidelines, Contact, Accessibility, Account Deletion, Home; (3) Tier 2 pages behind their gates. Each draft returns through me for experience review, then Founder approval, per the working structure.

---

*Sources: live checks of [Muzz Safety Center](https://muzz.com/us/en/safety/), [Safety Guidelines](https://muzz.com/us/en/safety/guidelines/), [Behavior Guidelines](https://muzz.com/us/en/safety/behavior/); Opus's `ZYRA_LEGAL_RESEARCH` V1 (Tinder/Muzz/inshAllah full retrievals); `MUZZ_TEARDOWN_CURRENT_VERSION_V1.md`; footer-pattern references: [NN/g on footers](https://www.nngroup.com/articles/footers/), [Eleken footer UX patterns](https://www.eleken.co/blog-posts/footer-ux).*

*End of Document*
