# ZYRA pricing reconciliation — 2026-09-18

Status: **CODEX INTERNALLY VERIFIED — source updated; not device installed,
published, billed or Founder visually accepted.**

## 1. Authority and finding

Current Founder request: check all pricing, retain Seeker One £29.99, include
both Basic products, replace fixed Family pricing with the previously agreed
configurable model and update the app. This side-conversation work is bounded
to that request; the parent website redesign has not been resumed or edited.

Read-only recovery in `ZYRA APP BUILD`
(`01a08777-d732-7c00-a6a5-ca18e7f479c6`) found:

- `01a0b408-16cc-79f3-bdd9-edda178383ad`: Founder requires independent counts,
  maximum 10/10, with savings capped at 40% at 5/5 and flat thereafter.
- `01a0b40b-ce65-7fa2-824b-f0057acf37c0`: Founder permits 0/0 but no Continue,
  also 1/0 at the individual price. The displayed calculator was revised to
  0–10 independent counters, no discount at one/two, 5% increments thereafter.
- `01a0b40f-02ee-7251-97f9-d17cd55ed160`: Founder asks to keep that idea while
  reviewing economics; the 0–10, 0%/5%-steps/40%-cap model is reiterated.
- The subsequent Basic decision leaves monthly One prices intact and assigns
  £9.99 one-time to each Basic role.

The current direct instruction resolves implementation authority. No new
commercial formula was invented. V5's “Family unchanged” was an incomplete
record; the fixed £99.99 five-person Family model is historical. Standalone
app prices were already correct. Family was absent from the Membership screen.

## 2. Implemented behaviour and boundaries

Four standalone plans remain: Seeker One £29.99/month; Guardian One
£19.99/month; Seeker Basic £9.99 once; Guardian Basic £9.99 once.

Existing Membership route now includes Build your ZYRA Family. Each One-role
counter is independently 0–10. At zero/zero it asks for a selection, with no
buy/Continue action. At nonzero selections it shows full individual monthly
total, percentage and pound saving, then the discounted monthly total.

The pure quote model uses integer pence and the same One price constants as
standalone membership cards. Discount is 0% at one/two, then 5% per additional
membership, capped at 40%. Round the discounted total once, half up, and derive
saving by subtraction. All 121 role combinations are valid; counts outside
0–10 throw. Basic one-time fees are not monthly Family memberships.

Help now explains the formula instead of saying “Family unchanged”. Pricing
V5 and the existing Paid Membership handover are reconciled in place, with
true pre-files retained below. No plan enum, entitlement, role, permission,
trial, quota, analytics event, server data or billing state changes. No live
Family product, invitation/allocation, proration, receipt processing or trial
is implied. Checkout is still unavailable for every product.

## 3. Measured verification

- `dart format` on the five Dart files: completed.
- `flutter test --no-pub test/paid_only_membership_catalog_test.dart test/family_membership_pricing_test.dart`:
  **16/16 PASS**. Includes four standalone prices, existing permission/navigation
  guards, all 121 Family combinations, invalid boundaries, totals/savings
  reconciliation, role-only choices, independent UI counters, 0/10 disabled
  controls, 40% ceiling, Help explanation, no entitlement mutation and no
  purchase/backend writer in the Family card.
- Widget tests include widths **320 and 390**, text scales **1 and 2**:
  no Flutter layout exceptions. The existing Membership tests also traverse
  the extended page to compatibility purchases and safety terms.
- `flutter analyze --no-pub`: **PASS — No issues found!** (8.0 seconds).
- Full repository test suite and golden comparison: not run for this bounded
  pricing change. No approved pixels regenerated.
- Phone build/install, TestFlight, public website deploy: **not performed**.
- Database/schema/RPC/store/auth changes, git and sub-agent operations: **none**.

## 4. SHA-256 ledger and true pre-state

Paths are relative to the ZYRA root. `pre/` contains exact copies captured before
the first edit, first in the current task workspace and then byte-preserved in
this evidence folder. New files had no prior content; no reconstructed audit
anchors. Existing unrelated edits were preserved; only bounded pricing hunks
were changed.

| File | Pre SHA-256 | Post SHA-256 |
|---|---|---|
| SOURCE/lib/data/zyra_membership_catalog.dart | 0f231d06976852617d04f95e4962bcace7a5c91478657495984cbfc235806e7d | de575748662cd1d408637dd594b473119dad03cb2811a054b82331d53c1fba29 |
| SOURCE/lib/data/help_content.dart | d9813077f61bed0fa1e94281c59c7c6a47168e1ba2cd6e1b047b006f3fce8c79 | 9d3e748a3630f26e4358921d8490687709a718b8032eb80945a7761e3c41dc85 |
| SOURCE/lib/screens/subscription/upgrade_screen.dart | dbc596b99a2d2da7bc1c187d8833c49be29f3d6760a3c4a35cd9d1aa243b1ef0 | 5742d75c67318d84d5d5eac0bdeaf31e87cf61c4f47a0b7367076edbd8a529b6 |
| SOURCE/lib/widgets/zyra_family_pricing_card.dart | NEW | 422b341ddb9f4420ea9da9730e4683831ead3eb251f44ec47026dbd462031697 |
| SOURCE/test/family_membership_pricing_test.dart | NEW | d4aa0f55b9eff75ebffecb12057b8cb173fe0f261aceff53c397ee50a25b0c69 |
| BUSINESS/ZYRA PRICING/ZYRA_PRICING_CURRENT_VERSION_V5.md | 06d1df51993a3b950a64a8c71cea22c3848506f955e76df1fb1e70ebf2ff877e | 196dfa0eead09ebe5b31b66afd8067bfb1f60aac1b820cce2f4db5296ed172d4 |
| SYSTEM/DOCUMENTS/ZYRA_PAID_MEMBERSHIP_HANDOVER_CURRENT_VERSION_V4.md | 86189afd8c12fcdc19318c2707a33553cddf944200a55d9f80ba00fceefbea46 | 9e3b389ee48785e1e30bf767c3c1c4497fd0f5ec2c445746f3e1db2be8a16d7b |

## 5. Remaining work and handoff

- **Website discrepancy:** at this check, `SITE/src/pages/index.astro` lines
  129–131 still show old combined One £39.99, an Additional Guardian payment
  tier and fixed Family £99.99/five places, omitting both Basic products.
  Those blocks must use Pricing V5 §1/§1.1 before publication. The parent task
  is actively editing that file for its redesign; this side task did not
  overwrite it or contact its agents. No separate OA is raised for that
  in-flight correction because the current pricing request and website task
  already own it. This report is the exact handoff, not a claim it is fixed.
- **Delivery/acceptance:** app source is ready for the next coordinated local
  build/install. No concurrent phone build was started. Founder inspection
  and any TestFlight release remain separate from these source tests.
- **Commercial activation:** OA-ZYRA-253 remains open for store billing,
  receipts, Family member allocation and server entitlements; OA-ZYRA-293
  remains open for Basic authoritative quotas and live advertising. No new
  duplicate actions or closures, no assumed activation and no billing policy
  changes here.
- Existing unrelated Help and historical document issues are not swept by
  this bounded correction. Only pricing statements were amended.
