# ZYRA — Legal Document Research & Clause Coverage Matrix

**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-08-01
**Author:** Claude (Opus), Implementation Lead
**Purpose:** Research foundation for ZYRA's Privacy Policy, Terms of Service, Cookie Policy and Community Guidelines.

---

## ⚠️ READ THIS FIRST

**Nothing in this document, and nothing drafted from it, is legal advice.**

I am not a lawyer. Neither is Fable, nor ChatGPT. What this research enables is a
*well-informed draft* that saves a solicitor several hours of billable discovery
work — it does not replace the solicitor.

ZYRA's specific risk profile makes this non-negotiable:

| Factor | Why it raises the stakes |
|---|---|
| **Religious belief + ethnicity are collected** | Article 9 UK GDPR special-category data. Requires an Article 9 condition, not just a lawful basis. |
| **~174-question values instrument** | One of the most detailed personal-belief datasets any consumer app holds. |
| **Guardian/guardian model** | ZYRA processes data about a **third party** (the Guardian) and shares a Seeker's Journey progress with them. No competitor has this. Genuinely novel processing. |
| **Marriage/dating classification** | Attracts CMA consumer-protection scrutiny on auto-renewal and pricing. |
| **Vulnerable users** | Young women, some in controlling households. Elevated duty of care. |
| **UK company, likely UK+global users** | UK GDPR, plus adequacy/SCC questions the moment anyone abroad signs up. |

**Recommendation: budget for a solicitor with data-protection and consumer-tech
experience before public launch.** A draft reviewed is cheap; a policy litigated
is not.

---

## 1. Research Method and Coverage

| Source | Retrieved | Value |
|---|---|---|
| **Tinder Privacy Policy** (policies.tinder.com) | ✅ Full | Best-in-class structure. 12 sections, lawful basis tabulated per purpose, specific retention periods. The model to follow for *shape*. |
| **Muzz Terms of Service** (muzz.com/us/en/terms) | ✅ Full | **Most important source.** MUZZ LTD is registered in England and Wales (co. no. 09376746). Same jurisdiction, same category, same regulator. |
| **Muzz Privacy Policy** | ◐ Partial | Retrieved but oversized; opening sections reviewed. Muzz Ltd named as controller. |
| **inshAllah — Terms + Privacy** | ✅ Full (via Chrome) | **The most directly comparable data model.** CAJIS FRANCE, French law. Collects the same special-category fields ZYRA does — and gets the lawful basis wrong. See §2A. |
| **Salams** | ❌ Genuinely offline | Site is displaying a scheduled-maintenance page, not a rendering failure. Nothing to read. Retry later. |

**Honest limitation:** Salams could not be assessed — their site is down. Three of
four retrieved, including the two most relevant (Muzz for UK legal precedent,
inshAllah for the closest data model).

**On copying:** competitor legal text is copyrighted and written for *their*
business model. Nothing below is lifted. This is a map of *what clauses exist and
why*, so ZYRA's documents can be original and actually describe ZYRA.

---

## 2. What Muzz's Terms Tell Us (UK precedent)

Muzz's Terms run to 33 clauses plus a separate US annex. The structure worth
learning from:

**Consumer-law compliance, done visibly.** Clause 1.3 opens by *drawing attention*
to the clauses a UK consumer most needs to notice — auto-renewal, cooling-off,
community rules, termination rights, liability. That is not decoration; it is how
you make onerous terms enforceable under UK consumer law. **ZYRA should copy this
pattern.**

**14-day cooling-off** (cl. 10), with the standard carve-outs: digital content
once used, services once completed. Required by the Consumer Contracts Regulations.

**Auto-renewal disclosed prominently** (cl. 9.5–9.6), including advance notice of
renewal and price. The CMA has been active here.

**Eligibility bar beyond age** (cl. 7.1.3): no one ever convicted of a hate crime,
terrorism, or a violent or sexual offence. Notable — and given ZYRA's audience,
worth adopting.

**Liability cap** (cl. 24.4): greater of 12 months' fees or £100, with the
mandatory carve-outs for death/personal injury and fraud.

**Two disclaimers ZYRA needs even more than Muzz does** (cl. 24.6):
> *"We do not run or enforce criminal background checks."*
> *"All age, selfie and identity verification processes are conducted on a best
> efforts basis and [we] cannot guarantee their accuracy."*

ZYRA's verification is **not built at all**. Shipping without an equivalent
disclaimer, while the FAQ discusses verification, would be indefensible.

**The Chaperone clause (cl. 11.8)** — the only competitor precedent for anything
like a Guardian. It is thin: the user appoints one, supplies an email, the chaperone
receives *weekly transcripts*, and it can be switched off at any time.

---

## 2A. inshAllah — The Closest Data Model, and a Compliance Gap to Avoid

CAJIS FRANCE, Paris, French law. Both documents dated **06/04/2020 — six years
stale**, with a broken internal cross-reference (Art. 4.1 points to "Article 7"
for paid services; Article 7 is actually account deletion). A useful reminder
that a legal document nobody maintains is a liability, not an asset.

### The important finding

inshAllah's **mandatory** registration fields include:

- Country of origin
- **Religious current** (madhab / sect)
- **Level of practice**
- Declared location
- **Marriage horizon**

That is almost exactly ZYRA's data model. But their stated lawful bases are only:
*contract execution*, *legitimate interest*, and *legal obligation*.

**Religious belief is Article 9 special-category data. "Performance of a
contract" is not a valid Article 9 condition.** Their policy collects mandatory
religious data without ever naming an Article 9 condition for it. Whether that
would survive CNIL scrutiny is not my call — but it is a gap, and it is the exact
trap ZYRA is walking toward.

Tinder, by contrast, handles it correctly: sensitive data is routed through
**consent**, with the policy saying so explicitly.

**What this means for ZYRA — the hardest design constraint in the whole project:**

Article 9(2)(a) requires *explicit consent* for religious data. Consent must be
freely given, which normally means the service must work without it. But ZYRA's
entire compatibility engine is built on ~174 values questions covering religious
practice.

Three possible routes, all needing a solicitor's view:

1. **Explicit consent, genuinely optional** — the values instrument becomes
   skippable, and compatibility ordering simply doesn't apply to those who skip.
   Cleanest legally, weakest for the product.
2. **Explicit consent as a condition of a distinct optional feature** — matching
   on values is framed as a separable service the user opts into.
3. **Art. 9(2)(d)** (not-for-profit religious body) — almost certainly does not
   apply to a commercial platform, but worth a lawyer ruling out rather than us
   assuming.

**My view:** route 2 is most likely workable and should be the question put to the
solicitor first. This needs deciding before launch, not after — it shapes
onboarding.

### Two things inshAllah does that ZYRA should copy

**No device geolocation, ever.** They collect only a *declared* city and say so
proudly: *"Unlike most market players, and for the sake of confidentiality,
Inshallah does not at any time collect the position of the Member's device."*

This directly answers the Muzz teardown's most serious safety finding — Muzz shows
street-level distance ("2 miles away, Canary Wharf") on every card. ZYRA currently
uses a `location_text` field, i.e. already declared-only. **That is the right
design and should be stated as a commitment in the privacy policy**, not left as
an implementation detail.

**Clear retention numbers.** One year after deletion for legal requisition; auto-
delete after three years of inactivity. Specific and defensible.

---

## 3. The Guardian Problem — Where No Precedent Exists

**This is the section a solicitor most needs to see.** ZYRA's Guardian model is
materially different from Muzz's Chaperone, and every difference increases legal
complexity.

| | Muzz Chaperone | ZYRA Guardian |
|---|---|---|
| Account | None — just an email address | Full account, own login, own app experience |
| Data received | Weekly chat transcripts | Journey stage, progress, family-stage answers |
| Power | None — passive observer | **Can block progression** (Guardian Gate, Family Review Period) |
| Consent | Seeker switches on/off freely | Structural to the product |
| Data subject? | Barely — an email address | **Yes. A full data subject in their own right.** |

**The questions this raises, which the drafts must answer:**

1. **Who is the controller of the Guardian's data?** ZYRA is. So the Guardian needs their
   own privacy notice, their own rights, their own retention schedule.
2. **What is the lawful basis for sharing a Seeker's Journey data with her Guardian?**
   Consent is the obvious answer — but consent must be *freely given*, and a Guardian
   Gate that blocks progression makes it arguably conditional. This is the single
   hardest question in the whole document set.
3. **Can a Seeker withdraw that consent?** UK GDPR says consent must be as easy to
   withdraw as to give. If withdrawing halts her Journey, is it really free?
4. **What if the Guardian is coercive?** ZYRA has built a mechanism that gives one
   person visibility and veto over another's marriage process. That is defensible
   religiously and correct for the market — but it needs an explicit escalation
   route, and the Terms need to say the relationship can be ended.
5. **Data minimisation.** The Guardian should receive the least data that makes the
   role work. ZYRA's design already says "guidance, not surveillance" and does not
   share private messages — that is the right instinct and should be stated as a
   *commitment* in the privacy notice, not just a product behaviour.

**My view:** the Guardian architecture is ZYRA's biggest differentiator *and* its
biggest legal exposure. It should be the first thing raised with a solicitor, not
a footnote.

---

## 4. Clause Coverage Matrix

### 4.1 Privacy Policy

| Clause | Tinder | Muzz | ZYRA needs | Notes for ZYRA |
|---|---|---|---|---|
| Controller identity + address | ✅ | ✅ | ✅ | Company must be registered first |
| UK GDPR representative | ✅ | n/a | Only if incorporating outside UK | Muzz is UK — likely n/a |
| DPO / contact route | ✅ | ✅ | ✅ | Not mandatory at ZYRA's scale, but a named contact is |
| Data categories collected | ✅ table | ✅ | ✅ | **Add: values instrument, Guardian link, Journey data** |
| **Special-category data** | ✅ consent | ✅ | ✅ **critical** | Religion + ethnicity. Needs an Art. 9 condition, likely explicit consent |
| Lawful basis per purpose | ✅ table | ✅ | ✅ | Tinder's table format is the ICO-preferred pattern — copy the *format* |
| Automated decision-making | ✅ (FAQ link) | — | ✅ | **Compatibility scoring orders who you see.** Must be disclosed |
| Sharing — other members | ✅ | ✅ | ✅ | Plus: what the Guardian sees |
| Sharing — processors | ✅ | ✅ | ✅ | Supabase (AWS eu-west-1), Google/Apple auth |
| International transfers | ✅ | ✅ | ✅ | Supabase eu-west-1 = Ireland. Adequacy applies |
| Retention periods | ✅ specific | ✅ | ✅ | **Be specific.** Vague retention is a common ICO finding |
| Data subject rights | ✅ | ✅ | ✅ | Access, rectify, erase, restrict, object, portability, withdraw |
| Right to complain to ICO | ✅ | ✅ | ✅ | Must name the ICO |
| Children's privacy | ✅ 18+ | ✅ 18+ | ✅ | **ZYRA has no enforced minimum age in the database** — see audit C4 |
| Security measures | ✅ | ✅ | ✅ | Don't overclaim. RLS + private storage + signed URLs is true |
| Policy changes | ✅ | ✅ | ✅ | |
| **Guardian-specific notice** | — | — | ✅ **novel** | No precedent. Must be written from scratch |

### 4.2 Terms of Service

| Clause | Muzz | ZYRA needs | Notes |
|---|---|---|---|
| Attention-drawing preamble | ✅ | ✅ | Enforceability of onerous terms |
| Company details, VAT | ✅ | ✅ | Blocked on incorporation |
| Eligibility: 18+ | ✅ | ✅ | |
| Eligibility: no relevant convictions | ✅ | ✅ recommended | |
| Account creation rules | ✅ | ✅ | ZYRA is Apple/Google only — simpler |
| Purchases, pricing, VAT | ✅ | ✅ | £34.99 / £9.99 per pricing doc |
| **Auto-renewal** | ✅ | ✅ **critical** | CMA-sensitive |
| **14-day cooling-off** | ✅ | ✅ **critical** | Consumer Contracts Regulations |
| User content licence | ✅ | ✅ | |
| **Chaperone / Guardian** | ✅ thin | ✅ **must be far fuller** | See §3 |
| Community rules | ✅ extensive | ✅ | Should reference ZYRA's own Safety standard |
| Reporting mechanism | ✅ | ✅ | **Must not overstate — no moderation queue exists** |
| Moderation rights | ✅ | ✅ | "We may, not must" |
| IP ownership | ✅ | ✅ | |
| App store terms (Apple) | ✅ | ✅ | Apple requires specific wording |
| Suspension / termination | ✅ | ✅ | |
| Account closure consequences | ✅ | ✅ | ZYRA's `delete_own_account()` genuinely cascades |
| **Verification disclaimer** | ✅ | ✅ **critical** | ZYRA has *no* verification built |
| **No background checks** | ✅ | ✅ **critical** | |
| Liability cap + carve-outs | ✅ | ✅ | |
| Governing law | ✅ English | ✅ | |
| Dispute resolution | ✅ | ✅ | Avoid US-style arbitration unless US launch |

### 4.3 Also required

- **Cookie Policy** — if the marketing site uses analytics. Consent banner needed.
- **Community Guidelines** — ZYRA already has `SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V3.md`; needs a public-facing version.
- **Online Safety Act assessment** — ZYRA is user-to-user (messaging). Duties apply even without a feed. Worth a solicitor's view on scope.

---

## 5. Where ZYRA's Documents Must Differ From Every Competitor

1. **The Guardian.** No precedent exists. §3.
2. **The values instrument.** ~174 questions covering religious practice, family
   expectations and lifestyle. Far beyond a normal dating profile.
3. **Automated ordering.** `score_candidates()` decides who a user sees, and
   excludes people outright on Hard Requirements. That is automated processing
   with a real effect and must be disclosed.
4. **One Active Journey.** A contractual service limit, not just a feature.
5. **Honesty about what isn't built.** Verification, photo moderation and the
   report queue do not exist. The Terms must not imply otherwise — the FAQ made
   exactly this mistake and it was caught in review.

---

## 6. Blockers Before Drafting Can Complete

| Blocker | Needed from Founder |
|---|---|
| **Company not confirmed** | Registered name, number, registered office, VAT status |
| **Support/legal email** | `support@zyra.app` exists in docs — is it live? |
| **DPO / privacy contact** | Named person or role |
| **Launch territories** | UK only, or wider? Changes transfers, and whether US terms are needed |
| **Age floor** | 18, presumably — but the database currently enforces none |
| **Retention decisions** | How long after deletion? Muzz archives at 2 years |
| **Solicitor engaged?** | Yes/no changes how the drafts are written |

---

## 7. Version History

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-01 | Initial research. Tinder privacy + Muzz terms retrieved in full; Salams and inshAllah unreachable. Coverage matrix and Guardian gap analysis. |
