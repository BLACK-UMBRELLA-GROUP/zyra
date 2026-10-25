---
id: DOC-ZYRA-0197
type: HANDOVER
status: CURRENT
feature: GUARDIAN NETWORK
purpose: CODEX HANDOVER — ZYRA PUBLIC WEBSITE
links: []
owner: ZYRA chat
---

# CODEX HANDOVER — ZYRA PUBLIC WEBSITE

**Version:** V4
**Date:** 2026-10-07
**Status:** CURRENT_VERSION — LOCAL ROUTE, SITEMAP AND FAMILY FOCUS CORRECTIONS INTERNALLY CHECKED WITH QUALIFICATIONS; NOT PUBLISHED; Founder acceptance pending
**Owner:** Codex under AD-AIOS-111; Founder alone accepts and authorises publication
**Supersedes:** ZYRA_PUBLIC_WEBSITE_REDESIGN_HANDOVER_2026-10-05_V3.md (ARCHIVE; byte-preserved)
**Authority:** Founder October5 website correction instruction; fresh October6 execution correction verified in ZYRA FINAL REALEASE, human message 01a1110e-070c-7d60-9fbb-b167ca5cc41f. Fresh continuation human message 01a1135c-272b-7160-91be-e9a70d131307 authorises remaining work that does not need the Founder. October7 restart human message 01a115fa-d868-7000-8887-7438092859c9 renews clearly scoped reversible local work while away. Details and local-only boundaries in §8, §10 and §11.
**Outstanding actions:** OA-AIOS-390; OA-AIOS-392 REC-006/007/008/009/011; product gates OA-ZYRA-253 and OA-ZYRA-293 remain separate

## 1. Result and boundary

A local Astro correction candidate restores current ordinary Basic/One pricing,
adds real support, pre-launch terms-status and deletion-assistance pages, and a
top-level 404 page. Footer and privacy links reach the correct pages rather than
silently substituting the homepage. Existing purple/gold design, local fonts,
synthetic app previews and cinematic progressive enhancement are preserved.

No public deployment, DNS/provider setting, app edit/install, store configuration,
backend/data change, public/third-party message, signup, payment, trial or identity check was executed.
No git ran; no credential folder was accessed. Internal checks are not Founder
acceptance, compliance certification or permission to publish.

## 2. Source versus live facts

Read-only checks on October 5 at approximately 12:39–12:40 BST found:
live homepage Basic prices £9.99 once; local pre-edit source omitted Basic.
Live /terms, /support and /delete-account and a deliberately unknown route all
returned HTTP 200 homepage content with root title/canonical. Live GET /api/waitlist
also returned homepage content; no live POST was made. The live Family 2+2 estimate
was £89.96/month, a 10% / £10 saving.

These live observations were not closed by local edits. Publication and fresh
public routing/content/provider checks remain necessary. Absence of a top-level
404 is consistent with the documented Cloudflare Pages SPA fallback; actual
post-deployment routing is not established by Astro preview.

## 3. Commercial correction

Source of truth: BUSINESS/ZYRA PRICING/ZYRA_PRICING_CURRENT_VERSION_V6.md and
read-only app catalogue/policy/limit parity. Current ordinary UK reference prices:

- Seeker Basic and Guardian Basic: each £4.99 once per role, joining/verification
  fee, no monthly subscription. Basic is not a free tier.
- Seeker One: £29.99/month; one planned 14-day trial per verified person for life,
  after identity verification AND payment authorisation.
- Guardian One: £19.99/month, no trial. Family has no ordinary trial.
- Compatibility Unlock £1.99 / £7.99 five; Plus £2.99 / £9.99 five; purchases closed.
- Protected Seeker/Family first-month offers are NOT public offers and are absent.

The comparison restores Basic Active 1, Potential 10, Paused 1, Saves 5,
Active Considers 25, daily Considers 5, linked Guardians 1 and swipes 25/4h.
One has Active 3, Paused 10, Saves 50, linked Guardians 10, latest five Paused
return eligibility, latest five Ended-return eligibility (planned new attempt),
and latest ten declined revisits. Other unlimited limits remain qualified by
normal safety/consent/capacity rules. Expiry does not grant unfunded Basic;
stored history and accepted links are not deleted by quota changes.

Guardian paid conversation, compatibility answering, Network and Circle sending
are explicitly planned eligibility, not publicly available. Membership never
grants relationship authority. Guardian/privacy copy now distinguishes intended
permission boundaries from verified public release behavior.

Family retains 0–10 each paid role; 0+0 invalid; 5 percentage points per place
above two, capped at 40%; integer-pence half-up rounding. The owner occupies a
paid place, dual role uses two, and unused paid places remain charged. Formula
estimates may round upward to supported store prices. No allocation/checkout.

## 4. Routes and contact behavior

Built static pages: home, privacy, support, terms status, deletion assistance, 404.
Distinct titles, canonical links and H1s; footer links resolve. Support/status/
deletion/404 carry noindex. Sitemap now contains home and privacy only; Support
was removed to preserve its existing noindex scope (October6 correction, §10).

Terms is a truthful status notice, NOT an operative member agreement. Deletion
assistance distinguishes website enquiry data from app accounts, warns against
emailing sensitive material, and does NOT pretend deletion is automated or complete.
A contact-only page is not sufficient to prove app-deletion/store compliance.

The unused WaitlistForm is now an email link, without form/fetch/collection.
Cloudflare GET and POST /api/waitlist handlers both refuse with 501 JSON/no-store
and never read/store the request body. Unit-tested handlers are not live routing;
Astro preview does not execute Cloudflare Functions. The managed waitlist remains
closed; email enquiries neither reserve a place nor enrol somebody.

Website privacy text scopes the no-marketing-pixel/analytics statement to this
website's own code; it does not certify provider-injected behavior. Full operator,
retention, website/app privacy and member terms are NOT completed by this change.

## 5. Fresh internal verification — October 5 only

- Astro 5.18.2 production build: PASS, six pages, no dependency added.
- Pure catalogue/app parity and all 121 Family combinations: PASS.
- Scroll selector unit cases: 24 PASS.
- Built route/closed-handler assertions: 55 PASS.
- HTTP preview: five intended routes 200 with distinct content; unknown route 404.
- Computer-use browser QA: 320x700, 390x844, 844x390 and 1440x900 tested;
  role switching, comparisons, no document horizontal overflow at tested sizes;
  mobile menu open/close, short-landscape scroll container and Escape dismissal;
  footer support/terms/deletion/privacy destinations; visible not-found page.
- Family UI zero state, 2+2 £89.96 / 10% / £10, 10+10 £299.88 / 40%,
  maximum add buttons disabled, role change preserves selection, keyboard Enter
  on decrement updates the quote. No payment or account state is affected.
- Browser error/warning logs inspected: none observed during this bounded session.
- Desktop support and membership screenshots saved in the evidence directory.

The first route test expected /404 rather than the generated /404/ canonical;
the test expectation was corrected and all 55 assertions reran. A browser test
attempted keyboard input on a correctly disabled max-count button; verification
was retargeted to an enabled decrement and passed. Neither is concealed as an
uninterrupted first-pass test run.

Browser scripts were updated but NOT executed here. Historical 101/83 pass counts,
WebKit, no-JS browser, reduced-motion browser, automated axe/Lighthouse and physical
device results are NOT fresh verification. No cybersecurity/WCAG certification.

## 6. Evidence and recoverability

Evidence directory:
SYSTEM/RESOURCES/REVIEWS/WEBSITE_CORRECTIONS_2026-10-05.Qc9ZtL/

- True pre-edit site archive, including preceding dist:
  pre-site.tar.gz SHA-256
  68ec0cf0eefcb35413dd6f2f76a7b4be248de3b02b1f1ec6e7c22d7cfc55dd6b
- Exact local source + dist + Functions candidate:
  candidate-site.tar.gz SHA-256
  4d01ee7efe4d5620adaa0ede6422a25a961a8a7c4d8e885be86bc214dd983226
- file-ledger.json: true archive-derived pre hashes and current source/dist hashes.
- REPORT.md: scope, fresh verification, route checks, blockers and OA trace.
- backup/: original handover/index; former README retained as historical.
- Archived V3 is byte-identical to pre-edit current:
  ff8db998f68211effadf19f3bbeeb88e2b267c804ef92c817997cfc4be4ba587

For recovery, extract into a new scratch location, compare exact affected files
and any subsequent user changes, and restore only the approved scope. No repository
reset or blind archive extraction over the worktree. The live release is unchanged;
this local archive is NOT a production rollback instruction.

## 7. Founder dependencies and next action

Stop for confirmed actual legal operator/controller and public contact details;
approved website/app privacy and member terms, retention/deletion policy and a
verified account-deletion process; remaining app authorisation/privacy and commerce
release gates; review of contact-only versus approved managed waitlist; provider/
tracking assessment and exact publication GO.

Do not mark OA-AIOS-390/392 or website readiness complete on this internal candidate.
No new commercial or legal decision is inferred. Only the Founder accepts.
A publication request must identify the exact artifact, live destination, provider
routing, rollback and independent post-verification; it must not open signup,
waitlist storage, purchases or IDV by implication.

Technical references checked for this candidate:
[Cloudflare Pages routing](https://developers.cloudflare.com/pages/configuration/serving-pages/)
and [Apple account deletion guidance](https://developer.apple.com/support/offering-account-deletion-in-your-app/).
The deletion page's store-billing warning is supported by the latter; neither
reference makes the current product compliant.

## 8. October6 mechanical native-focus repair — local only

The original320×700 immediate nativeTab failure was reproduced in earlier
evidence and fixed locally by exactly one source-line replacement in
SITE/src/styles/global.css: root scroll-behavior:smooth → auto; padding96px
unchanged. No header/layout/focus-interception/content/price change. Ordinary
native focus and unpinned anchors are now instant; explicit scripted cinematic
and story smooth calls remain byte-unchanged. Authorised internal release-chat
coordination occurred; no public publication or collection was enabled.

Fresh execution authority: human message01a1110e-070c-7d60-9fbb-b167ca5cc41f,
turn01a110fb-bd68-7980-a294-64d45848a5cd, in ZYRA FINAL REALEASE. Codex's earlier
October5 approval was not reused as fresh October6 GO. Internal checks remain
distinct from Founder acceptance and exact public publication authority.

Fresh evidence:
SYSTEM/RESOURCES/REVIEWS/WEBSITE_FOCUS_FIX_2026-10-06.lhnNym/

- Exact320×700 immediate AddSeeker rect375.578125–419.578125,44×44;
  gold3px outline/3px offset fully clears actual header130.25. First captured
  rendered state, settled and later stable observations have identical geometry.
  Literal first requestAnimationFrame sampling was NOT available; do not equate
  the later screenshot with an instantaneous frame.
- Native backward/rapid Tabs,390×844, mobile menu/Escape, skip link,
  fragments/history, Family2+2£89.96/10%/£10 and role persistence checked.
  Explicit desktop pinned-anchor/story smooth movement observed. Native
  wheel→Tab remained stable, but no active settle frame was caught cancelling.
- Existing844×390 nominal-outline edge remains: top129.71875 vs header130.25
  (0.53125px overlap), with button visible at135.71875–179.71875. Isolated exact
  pre-dist reproduced identical nearest-focus geometry after Guardian settled.
  Fast baseline animation timing differs; this is not identical timed-sequence
  proof or broad all-orientations full-outline PASS. Root instructed to retain
  the verified320px fix and record the existing edge separately under REC006.
- Six-page Astro build, all121 Family/parity checks with a separately bound
  seven-file dependency receipt,24 scroll units,55 route/closed-handler checks,
  28 selected browser assertions and14 artifact checks passed.71 scoped files
  bound; only source CSS changed,45 other non-dist files unchanged; six built
  HTML stylesheet references and one compiled shared CSS replacement changed,
  with18 other built files including3 JS bundles unchanged.
- Fresh reduced-motion media browser, WebKit, physical device/no-JS and live
  provider behavior were NOT established. Console warnings/errors absent only
  in the bounded inspected session. No accessibility/security certification.
- A separate post-resize390×844 Family sample retained AddSeeker focus
  offscreen at5300.3125–5344.3125 before the next native Tab revealed AddGuardian.
  It is NOT among the28 selected passing assertions. Resize-only focus retention
  and its baseline status were not established; keep a distinct REC006 coverage/
  follow-up item. The fix is for new native focus movement, not every resize-only
  focus state. The raw baseline list also retains one invalid binding observation:
  26 entries comprise25 correctly bound observations plus that failure record.

New candidate source+dist archive SHA-256:
ac703405eafe5592884795948a4aa62c9ec845bf5c2381c0fc189c1787eb2c1f.
Current CSS SHA-256:
5eca0393cc5e4cab267a25a28d3a8347f200b8cbe48104b4ced62e2a37c230b4.
True preceding dist archive SHA-256:
56fd3c430209bda106df22cff0603b723cbf27816f1456926f311a6ed13ad4bf.

REPORT.md, raw observations, source/build receipts, pre/post ledger, failure
records, baseline/current screenshots, cleanup receipt and OUTPUT_MANIFEST
retain the exact bounds. True pre-edit V4 copy is backup/website-handover-V4.md
(SHA-256763abba7baf3ae14b86094f64d461fd17aed3889695e097e154d336afe931214).
Original Oct5 and Oct6 FAIL/PASS evidence directories remain immutable. Initial
helper URL decoding/sequencing fault, conservative PAX rejection and baseline
observer misbinding were corrected and preserved, not concealed as first-pass
success. No blind whole-tree rollback was used.

Shared OA registers remain ADMIN's sole-write scope. Factual reconciliation
draft sent to root/ADMIN; this chat did not write them or accept its own work.
Narrow defect is locally verified; qualified edge/coverage and all established
legal/privacy/product/publication gates remain separate and open/held.

## 9. October6 Family focus retention after resize

The separate resize defect described in §8 is now repaired in the local candidate.
Fresh exact current and matching predecessor observations first established that
the preceding auto-CSS candidate and its captured baseline both retained Add
Seeker focus offscreen after 844×390 changed to 390×844. The read-only evidence is
SYSTEM/RESOURCES/REVIEWS/WEBSITE_RESIZE_CHARACTERIZATION_2026-10-06.eRlbDv/.
The full historical backward-then-forward baseline key sequence was not captured;
the matching baseline predecessor and resize failure were. Earlier records remain
historical evidence rather than being rewritten as a pass.

This packet changes only SITE/src/scripts/story.ts as production source. It caches
a fully visible keyboard-focused Family step button before reflow, preserves that
predecessor through coalesced resize events and consumes one request after the
existing final geometry measurement. It scrolls instantly by the minimum clamped
amount needed for the actual header and full nominal outline. User navigation,
focus loss, hidden/removed/disabled controls, page lifecycle and motion/desktop
transitions cancel the request. Unrelated layout events cannot create one.
Impossible viewport/document geometry is not retried or claimed as guaranteed
clearance. Cinematic reading-location and scripted motion remain separate.

Fresh evidence is in
SYSTEM/RESOURCES/REVIEWS/WEBSITE_RESIZE_FIX_2026-10-06.2fT90j/.
Final source SHA-256:
79d32f50f3ca7852d4cd5ed2c2c58e6f48d1b166232c7bbbed70f3def3fab0d5.
The retained CSS SHA-256 remains
5eca0393cc5e4cab267a25a28d3a8347f200b8cbe48104b4ced62e2a37c230b4.
No 96px padding, header, layout, price, content, other script, dependency or app
source changed. Build output changes are six HTML script references and one
compiled story bundle replacement; 18 other built files remain unchanged.

- Exact native keyboard predecessor: Add Seeker at220.71875–264.71875,
  scroll9175, zero selections, 844×390. First API observation after rotation:
  793.3125–837.3125, scroll13682, 390×844; full outline787.3125–843.3125
  clears header130.25 and viewport844. After-state and later samples are stable.
- Two Enter activations produce exactly two Seeker places without further scroll.
  Guardian add reverse rotation, enabled Guardian/Seeker decrements, 320×700,
  role persistence, intentional scroll-away exclusion and menu/Escape checked.
  Disabled Guardian decrement blurs to BODY; later viewport document-clamping is
  not attributed to this guard or claimed as zero total scrolling.
- Final six-page Astro build, 121 Family selections and app parity, 24 scroll
  units and 55 route/closed-handler checks pass; 11 execution dependencies are
  hash-bound before/after. Browser evidence has 21 observations and 26 selected
  assertions passing, not a claim that every raw observation is visible.
- Entire actual production source bundled unchanged in a mocked DOM/fake RAF:
  original 38 PASS and 15 expected missing-retention FAIL; final55 PASS,
  including both resize/media ordering races. These are offline tests, not
  real-browser RAF, membership activation or physical-device proof.

First candidate failed because a desktop-to-mobile media update cleared the
resize completion flag; that attempt and source are preserved. The final change
keeps the queued completion while invalidating the focus request. A second trial
used the wrong footer target and focused a privacy link; it is explicitly excluded.
Two empty serialization artifacts caused by a reassigned REPL capture array are
also invalid evidence; browser-validated-observations.json recovers the intact
original observation ledger. Screenshot filenames from failed/invalid attempts
are not pass evidence. verified-family-focus-390x844.jpg is the verified sample.

True preceding local candidate archive SHA-256:
ae162954174fb95d37ca18ecbaa278413005b123f3f0aaf4d25d643f9d65edd6.
New local source/dist archive SHA-256:
7d40d03b71bdfa7fad98ca592f450bf8f60b8e3d3d444ecf0845145362a23ac4.
Rollback is limited to restoring backup/story.ts after checking subsequent edits,
then rebuilding; preserve the current auto-CSS repair and all unrelated files.

At the §9 checkpoint the existing 0.53125px landscape nominal-outline edge was
separate and remained qualified under REC006; §10 records its later local fix.
No literal first browser RAF, fresh reduced-motion media,
WebKit, no-JS, physical device or live provider verification is implied. No public
publication, account/security/provider, collection, commercial or shared-register
write occurred. Same fresh Founder authority and local-only boundary as §8;
internal evidence is not Founder acceptance or release readiness. ADMIN remains
the sole shared OA writer. Existing legal/privacy/product/publication gates stand.

## 10. Family outline clearance and sitemap correction

Fresh October6 continuation is verified against the Founder message
01a1135c-272b-7160-91be-e9a70d131307 in ZYRA FINAL REALEASE. This finite packet
uses the existing reversible-local authority; it does not authorise publication,
shared-register edits or decisions held for the Founder. Evidence is preserved in
SYSTEM/RESOURCES/REVIEWS/WEBSITE_ACCESSIBILITY_PASS_2026-10-06.dNsRj7/.

Three SITE files changed: src/scripts/story.ts, public/sitemap.xml and
scripts/verify-routes.mjs, plus their normal built artifacts. Design, CSS, copy,
prices, Family counts, permissions and cinematic policy are unchanged. New
keyboard Family focus can move the document only when its border box is already
visible and its nominal outline is clipped. The existing eligibility and
unchanged-viewport guards apply. The shared minimum integer instant-scroll
calculation also preserves the preceding resize behavior. No refocusing,
unsolicited activation or general offscreen reveal was added.

Actual isolated pre-state and candidate sequences at844×390 match through
Seeker → Guardian → availability → Guardian. The final backward Tab to Seeker
previously left outline top129.71875 under header130.25. The candidate scrolls
one integer pixel,9260→9259, giving outline top130.71875 and preserving zero
counts. Both real390×844↔844×390 rotation directions retain the complete outline;
Enter/Space add once and Remove Enter subtracts once. These are observations
after tool actions, not literal first browser RAF measurements.

Test-first receipts preserve62 PASS/3 expected FAIL on the captured source and
65 PASS/0 FAIL on the candidate in the same simulated DOM/media/RAF harness.
Final six-page build,121 Family selections with app parity,24 scroll units and
61 route/closed-handler/indexing checks pass. Browser validation has25 selected
assertions passing. Support sitemap removal resolves the preserved failing
indexing assertion without changing robots scopes. Native footer checks reach
the actual support, privacy, terms-status and deletion-assistance pages with no
forms; planned/not-open language and existing legal gates remain intact.

Real cinematic scroll movement while the settling flag was active was observed
before resizing in both directions. First returned post-resize observations have
cleared flags and unchanged Family counts. This is not first-frame cancellation
or later stability proof. Safari loaded the candidate and the stored targeted
receipt confirms a Seeker increment; precise Family keyboard/outline verification
did not complete because native window control became unavailable. Fresh real
reduced-motion media, no-JS browser, literal RAF and physical-device checks remain
unverified. No runtime or dependency was installed or upgraded.

Invalid or superseded attempts remain identified in browser-assertions-final.json:
wrong tab-closure binding, resize requests that affected the other tab, a landscape
image misnamed as portrait and Safari FAQ focus mistaken for Family coverage.
Only the validated replacements support the claims above. Two read-only helper
reviews support the narrow code/indexing change and evidence exclusions; these
are internal review, not an independent physical-device run or Founder acceptance.

Current story.ts SHA-256:
b9857e5f31b1d01413b92972042910a7b0c61b8f33a0881c38f98ad61d99d63a.
The packet retains the true preceding source/dist archive, original source and
handover, complete diff, final archive and hash manifest. Roll back only these
three new SITE deltas after checking subsequent edits, then rebuild. Keep the
previous auto-CSS and resize corrections. OA-AIOS-390/392 REC006 remain open;
ADMIN alone writes the shared OA register. No live/provider/account/security,
collection, app, store, spend, shared-register or publication action occurred.

## 11. October7 local evidence and deployment holds

Direct human restart authority was verified in ZYRA FINAL REALEASE, turn
01a115fa-d7cb-70c0-817e-cddf4563af9a, message
01a115fa-d868-7000-8887-7438092859c9. The Founder is away. No native app or
foreground browser was launched, and no device/login/physical action was assumed.

Evidence is in SYSTEM/RESOURCES/REVIEWS/WEBSITE_READINESS_2026-10-07.6Vu03l/.
All71 scoped SITE files, including the25 built files, still match the preceding
sealed candidate. No SITE source, test, dependency, price, copy or build output
changed. The prior build/pricing/route checks were not rerun or described as fresh.
The current source/dist archive SHA-256 is
db001bb3b9801ac0af9af743e6958f311f294721cca3d0b39b8c69036ebc8f9d.
The true pre-update handover is handover-before.md, SHA-256
b1c9ecb1bf06cd1cc241717fd9f6d814d6a0205a6c72e7b3fb0f37228da36c23.

An isolated loopback server served hash-matched built files. One mode applied
script-src 'none' to otherwise identical HTML. In the actual IAB browser, the
four story-step containers and headings remain present and not CSS-hidden,
all four Family controls remain disabled,
the native experience fragment and FAQ disclosure work, and the390px viewport
has no document horizontal overflow. This measures a real script-blocked failure
path, NOT a JavaScript-disabled browser setting or execution of noscript content.
Full body-text/onscreen visibility and successful image loading were not
established by the saved style receipt. The cause of incomplete initial images
was not established. No collection or form was introduced.

A separate evidence-only observer module was added only to the isolated test
response after the original modules. It neither replaces native RAF/scroll/focus
nor changes production bundles, but adds DOM publishing, layout reads and RAF
workload: it is not zero-impact instrumentation. Both active-settle resize directions have changing
pre-resize positions; the first recorded observer RAF retains the settling flag,
the second clears it, and frames2–60 remain stable for approximately967ms with
zero selections. Both Family rotation directions likewise retain offscreen focus
on the first observed RAF, clear the full nominal outline on the second, and
preserve focus/counts through frame60. These are real instrumented callback
samples, not a guarantee of synchronous cancellation, first-paint/compositor
clearance or uninstrumented timing. The deferred geometry behavior remains a
REC006 qualification; no new settled regression or source repair was established.

Twenty-two fresh pure selector threshold/immutability cases pass, with four
before/after source identity checks. The observation validator has24 passing
evidence-consistency assertions. Neither count promotes the early-frame caveat
to accessibility acceptance. Real reduced-motion preference, browser no-JS,
qualified Safari Family keyboard/outline/rotation, physical-device and live
provider coverage remain held. No runtime download or dependency update occurred.

An initial FAQ locator mismatch was resolved against the actual summary element.
The real footer Memberships link also correctly left the instrumented path;
those Family observations were not used as first-frame evidence. The corrected
instrumented predecessor and complete frame receipts are separately preserved.
The unrelated1000×700 resize followed by intentional navigation is excluded from
stability assertions. Duplicated Family event receipts are not independent runs.
Two overstrong initial validator labels were corrected without changing criteria;
the prior receipt is retained and observation-checks-final.json is authoritative.
No invalid capture was relabelled as a pass.

REPORT.md and DEPLOYMENT_CHECKLIST.md bind the current local candidate and retain
operator/controller, public contacts, privacy/provider assessment, operative
terms, support/deletion handling, contact-only versus waitlist, exact publication
GO and post-deployment routing holds. Existing owning OAs remain open; ADMIN
alone reconciles the shared registers. The packet has a candidate ledger,
recoverable handover, archive and seal. Rollback for this round is documentary
only, after checking subsequent edits; no SITE rollback is needed. Owned hidden
tab and temporary viewport were cleaned up, and only the owned loopback server
was stopped. Internal verification is not Founder acceptance or release approval.
