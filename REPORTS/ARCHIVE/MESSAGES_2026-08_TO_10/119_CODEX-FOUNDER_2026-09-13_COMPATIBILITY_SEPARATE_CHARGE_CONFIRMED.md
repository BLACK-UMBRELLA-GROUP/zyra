# 119 — Compatibility purchases remain separately charged

**TO:** Founder
**FROM:** Codex, AD-AIOS-109
**Date:** 2026-09-13
**Authority:** Founder reply “Seperate charge” to the question whether all
Compatibility Unlock/Plus reports should be included without credits or extra cost.
**Status:** Local presentation/record correction verified; checkout NOT LIVE
**Owning action:** OA-ZYRA-253, still open

## 1. Decision and scope

ZYRA One and Additional Guardian remain the two membership subscriptions.
Compatibility Unlock and Unlock Plus are separate optional purchases, not extra
subscription tiers. No unlimited inclusion is granted. Prices remain unchanged:

| Purchase | Single | Five-pack |
|---|---:|---:|
| Compatibility Unlock | £1.99 | £7.99 |
| Unlock Plus | £2.99 | £9.99 |

Source: preserved pricing V2 and Profile Unlocks Summary; current pricing V3 now
records this clarification. It supersedes V3's initial removal of the separate
sales model. It does not restore a permanent free tier, adverts or upgrade nags.

Existing credits, permanent disclosure rights, Journey-revealed Overall access,
and the Plus no-new-spend guard remain unchanged. The old three-included-Plus-
credit rule (DR-ZYRA-119) is not silently revoked: permitting separate purchases
does not unambiguously cancel a prior allowance. Any prospective change to that
allowance needs explicit supersession when actual billing is scoped. No credit
grant, expiry change, mock purchase, payment or recurring allowance ran here.

## 2. Implemented and verified

- Catalogue holds shared separate-charge, unchanged price and unavailable-copy
  constants; still exactly two membership enum values and checkout false.
- Membership adds a neutral compatibility-purchase information section.
- Help cost/inclusions answers use the same shared copy.
- The catalogue/widget test pins the prices, shared Help copy, 320/390 widths at
  100%/200% text, no layout exceptions and no membership/purchase mutation.
- Current pricing and as-built handover reconciled; report 118, its receipts,
  previous rollback files and approved images remain untouched.

Command scope: `flutter test` for `paid_only_membership_catalog_test.dart`,
`membership_presentation_retirement_test.dart`, `paid_only_promotions_test.dart`,
`zyra_promotion_engine_test.dart`, `zyra_bottom_promotion_test.dart`:
**26/26 pass, exit 0**. Full `flutter analyze`: **no issues, 7.3s, exit 0**.

Full suite, iOS compilation and visual capture were not repeated for this
copy-only amendment; report 118's measurements are historical, not claimed as
fresh verification. Its four unapproved Membership candidates predate this new
information section. No approved pixels or candidate manifest were changed.
New capture/device inspection remains part of OA-ZYRA-253's delivery work.

## 3. True pre-state and exact files

Evidence: `SYSTEM/RESOURCES/TEMPORARY/ZYRA_PAID_ONLY_ROLLBACK_2026-09-13/separate-charge.8P7OYJ/`.

`before.tar.gz` was captured before editing. SHA-256:
`97b31866eb2a7bcf9e5285559fb57e5b170866865297cbf189df1b214ab783a9`.

`completion-receipt.json` records pre/post SHA-256 and bytes for these exact
files, plus this new report and test/analyzer evidence:

1. SOURCE/lib/data/zyra_membership_catalog.dart
2. SOURCE/lib/data/help_content.dart
3. SOURCE/lib/screens/subscription/upgrade_screen.dart
4. SOURCE/test/paid_only_membership_catalog_test.dart
5. BUSINESS/ZYRA PRICING/ARCHIVE/ZYRA_PRICING_2026-09-18_V3.md
6. SYSTEM/DOCUMENTS/ARCHIVE/ZYRA_PAID_MEMBERSHIP_HANDOVER_2026-09-18_V1.md
7. SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md
8. SYSTEM/RESOURCES/MESSAGES/119_CODEX-FOUNDER_2026-09-13_COMPATIBILITY_SEPARATE_CHARGE_CONFIRMED.md (new)

Codex is the sole source/document writer except for the named bounded internal
index writer. The index uses the unchanged generator with private/symlink/
cross-device traversal guards. The source and governing documents were read;
no live database verification was needed or performed for presentation constants.

Rollback: verify the new post-hashes, then recover only the named originals
from this archive; do not overwrite later unrelated edits. Report 118's old
post-hashes are now historical anchors for these changed files, not live pins.

## 4. Remaining work

Actual purchases, trial, paid-only enforcement, contextual Guardian allocation,
transfer mechanics and dual-role safety remain unbuilt/held as documented in
the current paid-membership handover. No database, account, Apple product,
upload or git action occurred. Internal checks are not Founder acceptance.

No new OA is raised because OA-ZYRA-253 already owns this clarification and
billing work; no OA is closed. The master register was not edited: the large
register/downstream reconciliation owed in 118 remains owed, rather than
claiming this local handover amendment updated that register. This report and
the current handover record the decision durably for continuation.
