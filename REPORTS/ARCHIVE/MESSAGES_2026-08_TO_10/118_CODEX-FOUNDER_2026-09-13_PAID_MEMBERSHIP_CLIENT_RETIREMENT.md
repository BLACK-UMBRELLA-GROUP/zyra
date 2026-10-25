# 118 — Paid membership: client retirement and remaining activation gates

**TO:** Founder
**FROM:** Codex — operating/build seat, AD-AIOS-109
**Date:** 2026-09-13
**Status:** CLIENT RETIREMENT IMPLEMENTED; overall paid-only request NOT COMPLETE / NOT LIVE
**Owning actions:** OA-ZYRA-253; OA-ZYRA-266; OA-ZYRA-175/176; OA-ZYRA-286

- Removed the visible free-plan comparison, adverts, upgrade nudges and fake
  purchase success. Membership now describes One and Additional Guardian only.
- Preserved true originals outside the app for rollback.
- Real trial/billing/transfer/dual-context activation is not implemented and
  cannot be inferred from the new page. No upload or live change happened.

## 1. Scope and authority

The Founder directly requested the removal and two-product model. The prior
discussion proposed fourteen-day trial then mandatory paid One. Implemented
the clear reversible client surface; recorded the server/payment/context gaps
before building beyond them. No outside reviewer was commissioned. Internal
agents audited bounded independent slices; none approved the work.

Product authority: ZYRA_PRICING V3, with V2 byte-preserved under its dated
archive name. ZYRA_PRODUCT_SPEC has a scoped supersession notice. As-built:
ZYRA_PAID_MEMBERSHIP_HANDOVER V1. The old price £399.90/year remains a derived,
unconfirmed term; it is not sold. Launch discounts were not silently cancelled
or automatically stacked with the trial.

## 2. Exact source evidence

Base: `SYSTEM/RESOURCES/TEMPORARY/ZYRA_PAID_ONLY_ROLLBACK_2026-09-13/prestate.ycqtLs/`

| Artifact | SHA-256 / meaning |
|---|---|
| `source-before.tar.gz` | `f169927d78b494b766ecd8bfc1aace27a1e5a37c2e7b7848ef1d5e3f03638f3a` — true pre-edit source/test text, pubspec/run/README |
| `governance-before.tar.gz` | `c3e8a18ea71c002678270d24d8b03c08f1ae0119ac285ea19fbdff8c3613bdd9` — true pre-edit pricing/spec/index |
| `source-ledger.json` | `80ceb0106381eeb98501e03494e553ae4605ff46402eb5a99073ad40f915f61d` — 35 changed files, every pre/post hash and size |
| `forward.patch` / `reverse.patch` | Scoped diffs against retained originals; both dry-run checks completed without applying changes |
| `membership-candidates-v1/` | Four new unapproved render candidates outside the app; old candidate PNGs restored byte-exact |

The ledger is the full exact file list. It contains 25 library files and ten
tests. There are four new files: catalogue plus three focused test files.
No service other than the promotion engine changed. Signup/IDV/auth/router,
unlock/disclosure/Guardian services, AppState, pubspec, native setup and run.sh
are preserved. Existing legacy plan identifiers and limits remain compatible;
they are not a free-product offer. Root/source archives deliberately exclude
PNG assets because none of the approved pixels were edited.

## 3. Measurements

| Gate | Result |
|---|---|
| Membership / compatibility / account-context tests | 12/12 pass, including 320/390 width and 200% text; no purchase or trial mutation |
| Commercial retirement / notification tests | 15/15 pass |
| Both dashboards / refusal / intelligence tests | 40/40 pass |
| Guardian Network / developer controls | 38/38 pass |
| Final extra Guardian developer-control cleanup | 29/29 pass; targeted analyzer clean |
| First complete Flutter suite | 999 passed, 1 compile-gated skip, 60 golden comparison failures |
| Visual failure comparison with report 117 | All 60 names and all 60 actual image SHA-256 values identical; no new failure |
| Final full analyzer | Clean, 5.1 seconds; exit 0 |
| Explicit IDV-enforcement regression | 21/21 pass with `ZYRA_IDV_ENFORCE_EXISTING_ACCOUNTS=true`; exit 0 |
| iOS simulator compilation | Unsigned Debug compile PASS, Xcode 23.1 seconds; no install/upload |
| New Membership candidate capture | Four variants PASS; approved and candidate manifests unchanged |
| Final full suite after last control cleanup | 999 passed, 1 compile-gated skip, the same 60 golden comparison failures; 67 seconds; exit 1 |

The full suite is **not green**. Its existing golden failures remain visible,
not fixed by overwriting accepted images. The runtime approved manifest stays
`4667f42228d76dcb0893c247ea5c95c2f9556f485fc3fb8af3ece76974b5e03e`.
Final logs and image comparison are retained beside the ledger.

After the final run, all sixty failing variant names and all sixty actual PNG
hashes again matched report 117's retained evidence exactly. No approved image
was replaced. Forward and reverse dry-run logs cover all thirty-five files
without a failed or rejected hunk. `completion-receipt.json` beside the ledger
records the final document/artifact hashes and rechecks every source post-hash.

The guarded index completed: 655 documents (97 current, 85 archived, 473
ungoverned), with exactly one current pricing document, V3. The new handover and
this report are indexed. Index SHA-256:
`ee18910ffd313f1e2217c07c4ecad6e6d225e3578b8636b682a61ef540bf6780`.
The existing generator is unchanged; the wrapper excludes private-prefixed
trees, symlinks and cross-device traversal before reading.

Construction failures are disclosed in the handover: transient footer syntax
error, a real large-text overflow repaired with wrapping chips, then a lazy-list
test-scroll assumption corrected. Final passing checks follow those repairs.

## 4. Why activation remains held

- Existing server permits Basic participation and ignores expiry in several
  entitlement/cap paths. Removing labels is not paid-only enforcement.
- No receipt-backed purchase or one-time trial engine exists. Never replace
  that with a local One flag or an onboarding timestamp.
- Existing Guardian entitlement boolean can be funded by an Additional link;
  it cannot safely prove the required Main-specific access allocation. A new
  contextual resolver/allocation ledger is required, with server validation.
- Single-role profiles and invite rules do not yet support both contexts.
  OA-ZYRA-175's former-Guardian matching rule and OA-ZYRA-176's exclusion loss
  on account deletion remain relevant safety blockers.
- Founder confirmation of compatibility inclusion and exact transfer mechanics
  is still required. No identity/profile/history ownership transfer is inferred.
- IDV provider enablement and a new Apple build remain separately gated.

No migration was authored/applied, no live Supabase state changed, no Apple
account/product/upload changed, no keys were read and no git operation ran.
The current TestFlight build therefore remains unchanged.

## 5. Continuation and closure

Founder reviews client candidates; answer the compatibility inclusion question;
then prepare the precise billing/access/dual-context build contract, resolve
existing exclusion questions, implement and verify under the applicable gates.
Only after exact live activation GO and post-verification is paid-only access
real. Device delivery also requires the next approved build.

No new action identifier is created because existing OA-ZYRA-253 owns this
pricing/payment change; named IDV/safety/delivery actions retain their scope.
No OA is closed. Full master-register/downstream-doc reconciliation remains
owed under OA-ZYRA-253 rather than silently claiming those large records were
rewritten. The generated index is regenerated after filing these documents.

The overall user request is not marked complete merely because this report
exists. Founder acceptance and live activation remain distinct.
