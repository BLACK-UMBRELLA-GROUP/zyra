ZYRA — ACCOUNT TYPE UX REVIEW
=============================
Status:  CURRENT_VERSION
Version: V1
Date:    2026-07-26
Owner:   Implementation Lead (Claude)
Actions: OA-ZYRA-124 (Account Types & UX Review)
Related: DR-ZYRA-107 (Guardian Account UX Parity Fixes), DR-ZYRA-106
         ("Extended Guardian" → "Guardian+" rename), DR-ZYRA-094 (gender-
         gradient parity)

How to read this document
--------------------------
OA-ZYRA-124 asked for each of 8 account-type/gender variants to be
reviewed against 10 criteria (Navigation, Available tabs, Feature
access, Upgrade prompts, User journey, Permissions, UI consistency,
Empty states, Settings, Profile behaviour), to confirm every account
type "feels complete and intentional."

The 8 variants collapse to 4 functionally distinct experiences —
Seeker Basic, Seeker One, Guardian Basic, Guardian+ — because Male/Female
differ only in ZyraColors.genderGradient() and copy such as "Guardian" vs
"Waliyyah" where used; no navigation, permission, or feature-access
code branches on gender anywhere in the client. That itself is a
finding (see Section 1, row "UI consistency").

Section 2 lists every gap found, each tagged with the Feature Review
Process decision (Build / Modify Existing / Delay / Reject) and
reasoning, per this project's standing review discipline. Four gaps
were fixed directly during this pass (DR-ZYRA-107); the rest are
listed as Delay or Reject with reasoning, not silently dropped.

Section 1 — The 10 criteria across 4 account types
----------------------------------------------------

| Criterion | Seeker Basic | Seeker One | Guardian Basic | Guardian+ |
|---|---|---|---|---|
| Navigation | Bottom floating pill nav, 5 tabs | Same as Basic | Bottom floating pill nav, 5 tabs — different tab set, see below | Same as Guardian Basic |
| Available tabs | Browse · Connections · Dashboard · Guardian · Profile | Same | Dashboard · Network · Seekers · Notifications · Profile | Same, but Network tab is unlocked instead of showing an upsell |
| Feature access | Full Browse/swipe, Connections, Guardian-link flow | Same, plus Pause Journey (journey_flow_screen.dart, gated `plan == ZyraPlan.one`) | Dashboard + Seekers list + Family Stage answering; Network tab shows a locked upsell | Same, plus real Network (Discover/Requests tabs, currently both empty — no real Network data model yet) |
| Upgrade prompts | Profile plan badge (tappable → UpgradeScreen), "ZYRA Basic" label | Profile plan badge shows "ZYRA One", no upgrade prompt (already top tier) | Profile plan badge (now tappable → Network tab, DR-ZYRA-107), Network tab's own locked-state CTA ("Get Guardian+ — £9.99/month") | Profile plan badge shows "Guardian+", no upgrade prompt (already top tier) |
| User journey | Onboarding → Dashboard → Browse/Connections/Guardian as relevant → Journey stages | Same, plus can Pause an Active Journey | Onboarding → Dashboard → Seekers list → Family Stage approvals when a linked Seeker reaches that stage | Same, plus can browse the Guardian Network once real data exists |
| Permissions | Standard Seeker RLS — own profile only, own matches | Same | wali_links-scoped read access to a linked Seeker's Family Stage data only (RLS via `is_active` wali_links row); cannot Browse, cannot see match candidates | Same permission model as Guardian Basic — Guardian+ is an entitlement gate on the Network tab, not a wider permission grant |
| UI consistency | Full theming (glass cards, gender gradient, ZyraText/ZyraColors tokens) throughout | Same | Same tokens, but historically lagged Seeker screens on gender-gradient parity (DR-ZYRA-094, fixed 2026-07-25) and Dev Access parity (DR-ZYRA-107, fixed 2026-07-26) | Same as Guardian Basic |
| Empty states | ZyraEmptyState used consistently (Connections, Guardian tab, Search) | Same | ZyraEmptyState used (Seekers list, Network Discover/Requests) | Same |
| Settings | Notifications, Privacy, Manage Subscription, Help & Support, Sign Out, Delete Account — all wired | Same | Same 6 rows now present and wired (DR-ZYRA-107 fixed 3 of the 6 that were dead or missing); Notifications/Privacy use Guardian-appropriate copy, not the Seeker's | Same as Guardian Basic |
| Profile behaviour | Rich profile: photos, bio, prompts, compatibility data shown to other Seekers in Browse | Same, plus any One-tier-gated profile features (none currently implemented beyond Browse/Journey) | Minimal — "Guardian accounts carry identity only" per GUARDIAN ARCHITECTURE: name, relationship, linked-Seeker count only, no Browse-visible profile at all (by design, not a gap) | Same as Guardian Basic |

Section 2 — Gaps found, with Build/Modify/Delay/Reject decisions
-------------------------------------------------------------------

**Fixed this pass (DR-ZYRA-107) — Modify Existing:**

1. WaliHomeShell had no Dev Access shortcut (Seeker's HomeShell did).
   Checked for duplicate functionality: none — this was a pure
   omission, not an intentional restriction. Decision: Modify
   Existing. Done.
2. WaliProfileScreen's plan badge was not tappable (Seeker's is).
   Decision: Modify Existing. Done — now routes to the Network tab,
   the real Guardian+ purchase surface, not a copy of UpgradeScreen
   (which would write to the wrong entitlement field — see DR-107's
   "Alternatives considered").
3. WaliProfileScreen had no "Manage Subscription" row at all.
   Decision: Modify Existing (add the row). Done.
4. WaliProfileScreen's "Notifications" and "Privacy" rows had no
   onTap — dead taps, which fails ERROR_AND_EMPTY_STATE_STANDARD's
   "never feel like a bug" rule. Decision: Modify Existing. Done —
   new WaliNotificationSettingsScreen (Guardian-appropriate copy, reuses
   AppState's existing notification-preference fields) and an honest
   "Privacy" explanation dialog (a Guardian has no Browse visibility
   toggle to offer, so a real dialog beats a fake toggle).

**Found, not fixed this pass — with reasoning:**

5. Guardian Network's Discover/Requests tabs are permanently empty — no
   real "other Guardians with Guardian+" data model exists yet (comment in
   wali_network_screen.dart confirms this is known). Checked for
   overlap: this depends on a real Guardian Network/Family Introduction
   data model that doesn't exist anywhere in the schema yet — this is
   new-feature-sized work, not a UX polish item. Decision: Delay.
   Reasoning: building a real Network requires its own schema design
   (introduction requests, mutual visibility rules, likely its own
   RLS policy) — out of scope for a UX parity pass; tracked here so
   it isn't lost, but not spun into its own OA/DR without Founder
   sign-off on scope.
6. wali_network_screen.dart's internal identifiers (`_hasExtended`,
   `_purchaseExtendedWali`) still read "Extended" post-rename — the
   DR-ZYRA-106 sweep targeted the literal phrase "Extended Guardian" and
   its exact-match identifiers; these two names are abbreviated/
   partial matches the mechanical pass didn't catch. User-facing
   strings in this file are already correct ("Get Guardian+", "Guardian
   One capabilities"). Decision: Delay — cosmetic, internal-only,
   zero user-facing impact; safe to fold into the next time this file
   is touched for an unrelated reason, rather than opening a one-line
   diff purely for internal naming.
7. Seeker One's only currently-gated feature is Pause Journey
   (journey_flow_screen.dart). Checked for duplicate functionality/
   overlap: this matches ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5.md's
   description of what ZYRA One actually includes — it is not a gap,
   it's the correct current scope; flagging only because OA-124 asked
   specifically about "Upgrade prompts" and "Feature access" per
   tier, and a reviewer unfamiliar with the spec could otherwise
   mistake "few gated features" for "incomplete gating." Decision:
   Reject (no action needed) — noted for completeness only.
8. Guardian Basic vs Guardian+ profile behaviour is identical apart from
   Network-tab access — by design, per GUARDIAN ARCHITECTURE ("Guardian
   accounts carry identity only"). Checked against existing docs:
   confirmed intentional, not an oversight. Decision: Reject (no
   action needed).

What this pass did not review
------------------------------
Journey-stage screens (Family Stage, Meeting Stage, etc.) were not
re-audited criterion-by-criterion here — they were covered by earlier
passes (#15 Guardian-side Family Stage answering UI, #17 cooling period).
This document is scoped to the 4 home-shell-level screens (HomeShell/
WaliHomeShell, ProfileScreen/WaliProfileScreen, and their directly
reachable settings screens) since that's where OA-124's "Settings"
and "Profile behaviour" criteria live, and where the concrete parity
gaps were found.

Next step
---------
OA-ZYRA-124 can be marked resolved against this document and
DR-ZYRA-107. Item 5 above (real Guardian Network data model) is
substantial enough to warrant its own future task if the Founder
wants it prioritised — not assumed here.
