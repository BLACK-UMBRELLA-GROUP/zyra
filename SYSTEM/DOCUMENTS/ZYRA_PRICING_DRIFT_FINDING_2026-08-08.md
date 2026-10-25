---
id: DOC-ZYRA-0246
type: SPEC
status: CURRENT
feature: PRICING AND MEMBERSHIP
purpose: ZYRA — Pricing drift on the upgrade screen
links: []
owner: ZYRA chat
---

# ZYRA — Pricing drift on the upgrade screen

**Status:** FINDING — for your decision. No prices changed.
**Date:** 2026-08-08
**Severity:** Launch blocker (pre-revenue, so no money has been lost)
**Found by:** the `DANGLING DOC REF` check, on its first real run

---

## 1. What the screen shows versus what the spec approves

`upgrade_screen.dart` renders an à-la-carte table transcribed from
`ZYRA_PRODUCT_SPEC` **V3**. The spec is now at **V5**. Every row has moved —
both products were renamed and all four prices raised.

| Screen shows (V3) | Approved spec (V5) | Change |
|---|---|---|
| Unlock Profile · 1 profile · **£0.99** | Compatibility Unlock · 1 profile · **£1.99** | +£1.00 |
| Unlock Profile · 5 profiles · **£2.99** | Compatibility Unlock · 5 profiles · **£7.99** | +£5.00 |
| Unlock Profile Plus · 1 profile · **£1.99** | Compatibility Unlock Plus · 1 profile · **£2.99** | +£1.00 |
| Unlock Profile Plus · 5 profiles · **£4.99** | Compatibility Unlock Plus · 5 profiles · **£9.99** | +£5.00 |

**ZYRA One is unaffected** — £34.99/month and £349.90/year are identical in
V3 and V5, and those are the figures the main upgrade card uses.

One related rename also went unpropagated: the Guardian add-on at £9.99/month
is **Extended Guardian** in V3 and **Guardian+** in V5. I have not searched
for other places that string appears.

---

## 2. Why nobody caught it

The file header said, in full confidence:

> transcribed verbatim from `ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md` §4-8
> (Status: Approved) — nothing on this screen is invented

Every word was true when written. Then the spec went to V4 and V5, and the
archive rule renamed the cited file out of existence. **The claim stayed
confident and became unverifiable at the same moment.** A reviewer wanting to
check the numbers had nothing to open.

This is the concrete cost of the reference class, and it is worse than the
proposal argued. I described the harm as *"a developer finds nothing and
cannot tell whether the document was renamed or deleted"* — inconvenience.
The actual harm is that a stale transcription keeps asserting it is verbatim
long after it stopped being so.

---

## 3. This also corrects my audit

The check found a reference my hand audit missed, in the very file that
turned out to matter:

| | Audited by hand | Measured by the check |
|---|---|---|
| Dangling documents | 5 | **6** |
| Dangling sites | 13 | **14** |
| `BROWSE_UX_SPEC` V1 / V3 | 1 / 2 sites | **2 / 1 sites** (transposed) |

`ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md` was invisible to my audit because
the comment wraps mid-filename and my regex discarded both halves as
fragments. Estimating by eye undercounted again, and in the same direction as
every previous estimate.

**Baseline unchanged at 5 documents / 13 sites** — the sixth was fixed rather
than baselined, per your decision.

---

## 4. Decision needed

The screen has no payment processing, so nothing is being charged. But it
under-quotes the approved spec, and it is visible in the running build.

| Option | Effect |
|---|---|
| **A · Update the screen to V5** | Screen matches approved pricing. Renames `Unlock Profile` -> `Compatibility Unlock` in UI strings too — worth checking whether that name appears elsewhere. |
| **B · Confirm V3 pricing was intentional** | If the V5 rise is not yet decided commercially, the spec is ahead of the product and the spec is what needs correcting. |
| **C · Leave until the payments work** | Defensible while pre-revenue, but the screen keeps asserting figures that contradict the approved spec. |

I have not touched the numbers. The file now carries a `⚠ STALE` header
naming the discrepancy so it cannot be read as verbatim again.

**Recommendation: A**, but only after you confirm V5's prices are the
commercial decision and not a drafting artefact — I can verify what a
document says, not which number you meant.

---

## 5. Outstanding action

Logged as **OA-ZYRA-166** in `OUTSTANDING_ACTIONS_V2.md` on your instruction.
Register metadata advanced: TOTAL REGISTERED 166 -> 167, NEXT IDENTIFIER
OA-ZYRA-166 -> OA-ZYRA-167.

> **OA-ZYRA-166** — Upgrade screen à-la-carte pricing and product names
> reflect ZYRA_PRODUCT_SPEC V3; current approved version is V5. Four prices
> and two product names to reconcile. Blocked on Founder confirmation that
> V5 pricing is the commercial decision.

**Correction:** I first told you the next free ID was 167. It was 166. I had
grepped for `OA-ZYRA-\d{3}` and taken the highest match — but the highest
match was the register's own `NEXT IDENTIFIER: OA-ZYRA-166` line, which names
an ID precisely because it has *not* been used. I read a reservation as a
record.

Same shape as the audit undercount earlier in this document: a regex match
counted without checking what it had matched. Twice in one day, which by the
invariants document's own rule ("once is an error, twice is a class") is worth
naming — **a grep tells you a string is present, not what it means.** Both
times the fix was to look at the matching line.

---

## 6. Register housekeeping — flagged, not fixed

Two things noticed while writing the entry. Neither touched, since the
register is governed and neither is in scope here.

| Observation | Note |
|---|---|
| `OUTSTANDING_ACTIONS_V2.md` | Does not follow §2's `DOCUMENT_NAME_CURRENT_VERSION_VN.md`. The archived `OUTSTANDING_ACTIONS_2026-06-20_V1.md` does. Would be swept up by Option A. |
| Stray `# Register Metadata` heading at line 6928 | A duplicate of the real block at the end, sitting mid-register above OA-ZYRA-139. No duplicated action entries — 44 unique headings, no repeats. Cosmetic. |
