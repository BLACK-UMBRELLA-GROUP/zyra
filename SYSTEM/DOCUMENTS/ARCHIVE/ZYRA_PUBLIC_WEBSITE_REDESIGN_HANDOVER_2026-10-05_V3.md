# CODEX HANDOVER — ZYRA PUBLIC WEBSITE

**Version:** V3
**Date:** 2026-09-18
**Status:** CODEX INTERNALLY VERIFIED — Founder review and publication pending
**Owner:** Codex; Founder alone accepts and authorises publication
**Supersedes:** ZYRA_PUBLIC_WEBSITE_REDESIGN_HANDOVER_2026-09-18_V2.md (ARCHIVE; byte-preserved)
**Authority:** Founder’s website redesign, cinematic revision and Seeker/Guardian pricing-correction instruction, 2026-09-18; AD-AIOS-109
**Outstanding action:** OA-ZYRA-260

## 1. Result and scope

The existing Astro website now has a top-level **Seeker / Guardian** switch,
role-specific messaging and **Basic versus One** feature comparisons, plus the
current configurable **ZYRA Family** calculator. Purple/gold styling, white ZYRA,
current-app preview images and the native-scroll story remain.

Local review: `http://127.0.0.1:4321/`. **Not published.** This work changes SITE
and its records only. No app-source edit, phone install, TestFlight upload, git,
database, auth, account, billing, DNS or cloud change. No payment or trial starts.
Internal Codex checks are not Founder acceptance or external approval.

The other app task's saved reconciliation report explicitly leaves SITE untouched.
Its app catalogue/Family correction was inspected on disk and reused, not overwritten.
A coordination message to that task was blocked by the tool before transmission;
the saved handover provided the required evidence without external messaging.
No concurrent app or phone build was started here.

## 2. Current commercial source and resolved discrepancy

Authoritative source:
`BUSINESS/ZYRA PRICING/ARCHIVE/ZYRA_PRICING_2026-09-24_V5.md`, including the same-day
§1.1 Family reconciliation; implementation source
`SOURCE/lib/data/zyra_membership_catalog.dart`. The user's explicit correction
replaces the superseded website brief's combined/fixed-price model.

| Current product | Website and app catalogue |
|---|---|
| ZYRA One — Seeker | £29.99/month |
| Seeker Basic | £9.99 one-time |
| ZYRA One — Guardian | £19.99/month |
| Guardian Basic | £9.99 one-time |
| ZYRA Family | Independently configured One memberships; no fixed price |
| Compatibility Unlock | Separate optional £1.99 each / £7.99 for five |
| Unlock Plus | Separate optional £2.99 each / £9.99 for five |

Removed from active website copy: combined One £39.99, Additional Guardian as a
payment product, fixed Family £99.99, five-person maximum and the generalised trial.
**The prior pricing contradiction is resolved.** Publication still requires Founder
visual/copy acceptance and exact publication GO; resolving copy is not activating billing.

Only **Seeker One** has a planned 14-day trial, after verification. Basic fees do
not start a trial. There is no approved Guardian trial or established Family trial.
The page visibly states purchases and trial/paid-access activation are not available.

## 3. Website role focus

Seeker is the initial enhanced view. The top pill buttons change:

- hero headline, explanatory copy and app preview (Connections versus Guardian Journey);
- four Experience walkthrough titles and paragraphs;
- compatibility explanation, without implying Guardian access to private answers;
- the order/emphasis of the two explanatory role panels;
- the visible role's Basic/One cards and comparison table.

Both role descriptions remain available, so the family context is not hidden.
The change is presentation only: no account role, permission, plan, cookie, local
storage or analytics event is created. A polite status announces the selected view.
Buttons expose aria-pressed; hidden comparison controls leave the tab/accessibility
trees. No-JS displays both comparisons and hides nonfunctional role buttons.

The scroll engine remeasures after a role or calculator layout change. All copy
stays readable; the expanded Memberships section deliberately uses normal flow.
Nine other chapters can pin when their content fits. Experience keeps its own
four-screen sequence; FAQ remains normal flow. At small/short sizes, reduced motion
or no JS, content uses a complete readable fallback. Read-without-motion is retained.
No wheel/touch interception, forced snapping or autoplay is introduced.

## 4. Comparison truth

Tables use real headings, row/column headers, ✓ / × with text equivalents, and
numbers where a binary tick would misrepresent a limit. One is visually emphasised
with gold without describing Basic as free or removing essential safety rights.

Seeker Basic / One limits:

| Feature | Basic | One |
|---|---:|---:|
| Active Journeys | 1 | 3 |
| Potential Journeys | 25 | No plan limit |
| Paused Journeys | 5 | 10 |
| Recent ended Journeys displayed | 1 | 5 |
| Saves | 10 | 50 |
| Active Considers | 50 | No plan limit |
| Considers per day | 5 | No plan limit |
| Profile swipes | 25 / four-hour window | No plan limit |
| My ZYRA Now / essential safety | Included | Included |
| Insights | Not included | Coming soon |
| Ad-free experience | Not included | Included in planned model |

The Basic advert cadence is explicitly a preview, not a claim of live ad delivery.
Ended-list limits never imply history deletion. No “unlimited Saves/Journeys” claim.
Numeric values are checked against the app's Journey limits, Basic policy and paid
Save cap. The same catalogue supplies website cards and Family quotes.

Guardian Basic can retain accepted links, view permitted information and use consent,
reporting/blocking and essential safety controls. One adds eligibility for permitted
conversation entry, planned commenting and future Guardian Network. The present
conversation renderer is **read-only; sending is not available**. No unqualified
“chat freely” claim. Additional-Guardian View/Chat controls are described as planned;
accepted-link, Seeker permission and Main authority rules remain explicit. Payment
never creates a link, promotes someone to Main or bypasses privacy.

Sources audited: Pricing V5; Paid Membership Handover V4; app
`zyra_membership_catalog.dart`, `zyra_entitlements.dart`, `zyra_seeker_basic_policy.dart`,
Browse limits, UpgradeScreen features, Wali Journey read-only renderer and Guardian
Network unavailable states. No production database access was needed.

## 5. Family calculator

- Independent integer counts **0–10 Seeker One** and **0–10 Guardian One**, maximum 20.
- Gross pence = `seekers × 2999 + guardians × 1999`.
- Discount = `min(40, max(0, (memberships − 2) × 5))` percent.
- Final pence = `floor((gross × (100 − discount) + 50) / 100)`; saving is gross minus final.
- One/two have no discount; three 5%, four 10%, ten through twenty 40%.
- 1+1 £49.98; 2+1 £75.97; 2+2 £89.96; 5+5 £149.94; 10+10 £299.88 monthly.
- Zero/zero displays “—” and an honest selection prompt, not a free offer.
- Basic one-time products are excluded. One role may be zero; no forced pairing.
- Local arithmetic only: no checkout, Continue, account writer, allocation, receipt
  or trial activation. No-JS controls are disabled, with formula and example retained.

## 6. Verification

- Astro production build: PASS, two pages. No dependency added.
- Strict TypeScript/checked-JavaScript validation of all three client controllers
  and the pricing model: PASS.
- Pure pricing suite: **all 121 Family combinations** against an independent BigInt
  half-up oracle, exact app constant/range/formula/limit parity, invalid inputs,
  zero-state and penny reconciliation. No exact half-penny ties occur in this
  catalogue; the test does not claim otherwise.
- Full site browser suite: **101/101 PASS**, Chrome and Playwright WebKit, 40 screenshots.
  V2 had 104: four assertions for the now-unpinned Memberships scene were replaced
  by one explicit normal-flow assertion; this is an intentional layout change.
- Added role/calculator suite: **83/83 PASS**, 14 screenshots; five widths 320–1440,
  role-specific copy/visibility/prices, header hit targets, calculator zero/max,
  no-JS fallback, no external requests or uncaught runtime exceptions.
- Six automated WCAG A/AA contexts (original four plus Guardian desktop/mobile):
  **zero violations**. These are bounded audits, not WCAG certification.
- Additional internal calculator browser probe: 242 combinations across 390/1440px,
  exact totals/savings and no overflow. No account or cloud state touched.
- The first site run exposed the taller mobile header clipping the short-landscape
  menu. The menu height and anchor clearance now use measured header height;
  the complete suites were rerun and passed.
- Client scripts total about 13.0KB raw / 4.9KB gzip. Earlier V2 Lighthouse lab
  scores are historical; no fresh Lighthouse claim is made for this larger comparison.

Physical Safari/Android/screen-reader review and Founder acceptance remain practical
checks. WebKit automation is not represented as an installed iPhone test.

## 7. Preserved behaviour and delivery boundaries

Purple `#684D78`→`#241A2C`, gold `#E8C98A`, white Syne wordmark and local Poppins
remain. Existing four WebP screenshots, fonts/licences and social image are unchanged.
They use synthetic current-app fixtures; source provenance stays in first-round evidence.
No approved app pixels were regenerated.

Public availability remains private-testing only. No public download or launch date.
Insights, billing/identity verification and other unavailable capabilities are labelled.
`/privacy`, metadata, original anchors, sitemap, robots and favicon remain; the
unused waitlist function stays byte-identical and truthfully returns 501. Email CTA
uses the documented hello@zyraconnect.app route; no email was sent.

Existing documented deployment is Founder-controlled GitHub → Cloudflare Pages,
`npm run build`, `dist` and Pages Functions. No production configuration was changed
or deployment performed. Before publication: Founder copy/visual acceptance, runtime/
routing/security checks, exact artifact/rollback and explicit GO; only Founder runs git.

The app pricing correction is already recorded in
`SYSTEM/RESOURCES/PRICING_RECONCILIATION_2026-09-18/REPORT.md` (16 tests/full analyzer
reported by that task). This report does not relabel those as a new phone installation.
Billing remains OA-ZYRA-253, Basic quotas/adverts OA-ZYRA-293, split Guardian authority
OA-ZYRA-296. No duplicate actions or closures.

## 8. Evidence and rollback

Evidence:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/zyra-website-pricing.y22ARw/`.

`site-before.tar.gz` was captured before edits, SHA-256:
`cd7c1cd8286ed3154d45fe4909a4dd944a805a205bf7aba52b39e3f7b32ec6fb`.
`pre-records/` holds true pre-edit report/register/index copies; `file-ledger.json`
and `.md` hold complete source/record pre/post hashes. No reconstructed audit anchors.
`review/` holds verification JSON and desktop/mobile screenshots.

V2 is archived byte-preserved as
`ARCHIVE/ZYRA_PUBLIC_WEBSITE_REDESIGN_HANDOVER_2026-09-18_V2.md`, SHA-256
`c857a3e4c4cdd7026b42c36a318bc7ddae1bac2953e8043b3ee7a60c52811387`.
V1 and both earlier evidence rounds are retained. Extract the source archive into a
new scratch directory to compare; restore only affected files after checking for
subsequent user edits. Do not reset the repository. No public rollback is needed.

Founder next review: use the top Seeker/Guardian switch, inspect each comparison,
and try Family counts. Nothing in this report self-approves the design or publication.
