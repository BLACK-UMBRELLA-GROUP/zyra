# ZYRA — Data Protection Impact Assessment: Identity Verification & Photo Moderation (DRAFT)

**Version:** V1
**Status:** DRAFT — for Founder review and signature (DR-ZYRA-220 in-house path). NOT legal advice; ⚖️ marks judgments a solicitor would normally confirm. Engineering facts are verified against the built system (030/031); legal gaps are stated as gaps, not filled with assumptions.
**Date:** 2026-08-29
**Author:** Fable (drafter) · **Signatory:** Founder (controller)
**Register:** OA-ZYRA-266 · DR-ZYRA-219/220/221 · Codex 027/030

---

## 1 · Why a DPIA

Biometric face-match to identify a unique person = special-category data
(UK GDPR Art 9); large-scale special-category processing and innovative
biometric technology are ICO DPIA triggers. This DPIA covers: (a) identity
verification at onboarding; (b) same-population duplicate-face detection;
(c) automated photo-safety screening.

## 2 · Processing description (as built and planned)

Member consents in-app (versioned consent record) → provider capture on
device → document + selfie + biometric template processed and STORED BY
PROVIDER ONLY → signed webhook returns a coarse outcome → ZYRA stores:
provider code, opaque session reference, coarse result, yes/no duplicate
flag, hashed event reference, consent version/timestamps. Structurally
impossible to store more: the applied schema has no columns for images,
templates, scores, PII, duplicate hits or raw payloads (verified live
2026-08-29). Duplicate flag → human review in provider console → final
outcome by the same webhook. Photos: Vision SafeSearch verdict + likelihood
buckets stored; raw analysis discarded; borderline → human review queue.

Parties: ZYRA (controller) · Sumsub (verification processor; also
independent controller for its own limited purposes — ⚖️ contract review
defines the split) · Google Cloud (photo-screening processor) · Supabase
(EU-hosted platform processor).

## 3 · Lawful bases (⚖️ the central legal judgments)

- Art 6: contract necessity (verification is a membership condition) and/or
  legitimate interests (member safety, fraud prevention) — ⚖️ final
  selection.
- Art 9 (biometrics): **explicit consent** via the in-app screen
  (idv_sumsub_biometric_v1_2026-08-29). KNOWN TENSION, recorded not
  hidden: DR-ZYRA-221 makes verification a condition of membership, so
  consent has no in-app alternative; the member's alternative is not
  joining. ⚖️ Freely-given analysis is the single biggest legal question
  in this file. Mitigations: full prior information, refusal honestly
  handled (no account, no penalty beyond non-membership), withdrawal path,
  deletion of unstarted attempts.
- Art 22: no solely-automated significant decision — duplicate flags and
  final refusals route through human review; contest path via support.

## 4 · Necessity & proportionality

Purpose: every match is between verified, unique, real people — core to a
marriage product's safety promise. Less-intrusive options considered:
selfie-only badges (weaker against impersonation), verification only at
matching (rejected by Founder ruling DR-ZYRA-221), no duplicate check
(defeats the one-person rule). Minimisation is structural (schema),
organisational (review in provider console, ZYRA never ingests evidence)
and contractual (⚖️ pending: retention, region, no model-training,
no cross-client matching).

## 5 · Risks and mitigations

| # | Risk | L×S | Mitigations (built/planned) | Residual |
|---|---|---|---|---|
| 1 | False face-match rejects a genuine member | M×M | Retry states; human review; support/appeal; no auto-ban | Low |
| 2 | Demographic bias in face-match performance | M×M | Provider certified algorithms ⚖️ request provider bias documentation in quote pack; human review on failure; monitor rates post-launch | Med-Low |
| 3 | False duplicate flag harms an innocent member | M×M | Review-only rule (never auto-ban); neutral copy; no disclosure of the other account; override path | Low |
| 4 | Provider breach exposes documents/biometrics | L×H | Data lives with the specialist provider only; ZYRA holds nothing exploitable; DPA security terms ⚖️; breach-response duties in contract ⚖️ | Med-Low |
| 5 | ZYRA breach | L×M | Nothing sensitive at rest (opaque refs + coarse results); private schema; RLS; service-role-only writes (all live-verified) | Low |
| 6 | Function/RLS bypass by modified client | M×M | Server-authoritative predicates; 030 §6 activation audit is a RECORDED RELEASE BLOCKER before enforcement switches on | Low after audit |
| 7 | Consent not freely given (condition of membership) | ⚖️ | Recorded openly here + DR-ZYRA-221; full prior information; refusal without hidden detriment | ⚖️ accepted risk (DR-ZYRA-220) |
| 8 | Minor attempts verification | M×H | 18+ App Store rating; DOB in onboarding; provider document age extraction refuses minors ⚖️ confirm provider under-18 handling in contract | Med until confirmed |
| 9 | Photo screening wrongly rejects/holds normal photos | M×L | Conservative thresholds; hold-not-reject for uncertainty; human review; member picks another photo; no account sanction from the signal alone | Low |
| 10 | Verification cost abuse (repeat attempts) | M×L | Session reuse; rate/attempt limits (Phase B); billing terms in quote ⚖️ | Low |
| 11 | Data subject rights involving provider-held data | M×M | Coordinated route via support → provider APIs; deletion removes face from comparison population; ⚖️ SLA in contract | Med until contract |
| 12 | Guardian population widens biometric scope | M×M | Recorded in DR-ZYRA-221 with held-open exemption flag; same protections apply | Founder decision |

## 6 · Rights, review and appeal

Access/erasure/objection handled via support with provider coordination;
manual-review outcomes communicated neutrally; contest path documented
before launch (release requirement); reviewer authorisation limited to the
Founder/authorised persons in the provider console; override events return
by webhook and are audit-trailed by hash ledger.

## 7 · Open items before this DPIA can be signed as complete

1. Sumsub contract pack: region, retention, deletion SLA, sub-processors,
   security terms, bias documentation, under-18 handling, no-training +
   no-cross-client clauses (OA-ZYRA-266 conditions 1-5). 
2. Founder threshold ruling for photo screening (table delivered).
3. 030 §6 activation audit completed before enforcement.
4. ⚖️ items: consent freely-given analysis; Art 6 basis selection;
   consent-evidence retention period; ICO prior-consultation question if
   residual risk is judged high — all Founder-accepted in-house per
   DR-ZYRA-220 unless that ruling changes.

**Sign-off:** Founder signature + date pending review of this draft.
