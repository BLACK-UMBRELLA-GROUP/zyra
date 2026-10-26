---
id: DOC-ZYRA-0177
type: SPEC
status: DRAFT
feature: GUARDIAN NETWORK
purpose: Guardian visibility of Seeker Browse activity — privacy proposal
links: []
owner: ZYRA chat
---

# Guardian visibility of Seeker Browse activity — privacy proposal

**Status:** DRAFT — Founder review item (Decision 6, 2026-08-28). Nothing is built; the staged dev chips remain dev-only; no RLS path exists or is designed until the Founder rules on this document.
**Author:** Fable, 2026-08-28
**Register:** OA-ZYRA-265 trail (Dashboard content contract); underlying gap raised with DR-ZYRA-171's hub build
**Question:** should a Guardian see a ward's Browse activity (Saved / Considering / Declined) — and if so, what is the minimum honest disclosure?

Answers to the Founder's eight questions, with a recommendation. Grounding fact: today saves/likes/passes are owner-only tables by deliberate design; the Guardian Dashboard's activity chips are staged developer counts and say so.

**1 · Why would a Guardian legitimately need each item?**
Saved: weak legitimacy — private shortlisting, contemplation stage; a Guardian acting on it intrudes on discernment before the Seeker has decided anything. Considering (an outgoing expression of interest): moderate-to-strong — it is the step that consumes entitlement and can become a Journey the Guardian will later be part of; a Main Guardian learning of it only at match time can feel ambushed, and early awareness matches the guidance role. Declined: essentially none — knowing whom a ward rejected serves oversight of taste, not guidance of process; it is the surveillance end of the spectrum.

**2 · Would the Seeker know this activity is visible?**
Non-negotiable if anything ships: visibility must be DECLARED to the Seeker in plain sight (in the Guardian-link flow and on the Browse surface itself), never discovered. The trust model's own words — guidance, not surveillance — fail if the Seeker learns from a family conversation that their browsing was being watched.

**3 · Does visibility alter Seeker autonomy?**
Yes, materially — this is the strongest argument for restraint. A watched Browse changes browsing: Seekers (young women above all, per the legal research's vulnerable-user note) may save less, consider more conservatively, or perform choices for the observer. In controlling households, activity visibility becomes a pressure instrument. Whatever ships must be something a Seeker can comfortably know is visible.

**4 · Is Saved different from Considered?**
Categorically. Saved is private contemplation (no counterpart, no consequence, reversible in thought). Considered is an outward act with consequences (entitlement consumed, a counterpart contacted, a potential Journey). The privacy line sits exactly between them.

**5 · Is Declined useful to a Guardian at all?**
No. It cannot guide anything the Guardian is for, invites relitigating the ward's choices, and its only "use" is oversight. Recommend permanently out, at any disclosure level.

**6 · Counts only, or individual profiles?**
Counts only, if anything. Individual profiles would let a Guardian pre-screen and pressure specific choices before the Seeker acts — autonomy inversion. A count ("2 people under consideration") tells the family the process is alive without handing over the choices themselves. Note honestly: even counts leak at small numbers (a count of 1 plus a later match identifies the person retroactively); mitigation is coarse wording ("actively considering" vs numerals) — a design decision if this proceeds.

**7 · Main vs Additional Guardian?**
If anything ships, Main only. The product already reserves action (reviews, Gate) to Main; Additional Guardians receiving behavioural signals widens the audience of a sensitive channel for no role reason. DR-ZYRA-168 (Additional visibility parity) concerns Journey rows, not Browse behaviour — keep those separate.

**8 · Minimum useful disclosure?**
**Recommendation — Option B of three:**
- **A · Nothing (status quo).** Fully defensible; the Dashboard stays honest by simply not claiming this data. Zero risk, zero build.
- **B · RECOMMENDED: declared, Main-only, Considering-count-only.** One coarse signal ("actively considering someone" / "considering 2 people"), visible to the Main Guardian only, declared to the Seeker in the link flow and on Browse, server-side via one narrow RPC (no table opened), OFF for existing links until the Seeker re-consents. Saved and Declined: never. This matches the moment family involvement genuinely begins (outward interest) and nothing before it.
- **C · Counts for Saved+Considering.** Not recommended — Saved is contemplation; watching it chills discernment (Q3).

**If the Founder chooses B, the build gate list:** Seeker-facing declaration copy (Founder-approved), consent/re-consent rule for existing links, one SECURITY-DEFINER count RPC (Main-scoped; no RLS opening of owner tables), small-count wording rule, and a line in the privacy policy's Guardian section. A migration is involved → separate Founder authorisation at build time, as always.

**Also worth stating:** solving G4 is not required for the Guardian home to feel alive — Journey stages, reviews, Gate, milestones and GN activity are all legitimate movement. Option A remains a fully honest product.

*Draft for decision. No access is assumed; nothing changes until the Founder rules.*
