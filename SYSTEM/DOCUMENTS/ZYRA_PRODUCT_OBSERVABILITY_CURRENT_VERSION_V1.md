# ZYRA — Product Observability

**Version:** V1  
**Status:** CURRENT_VERSION — Founder-approved Phase 2 local/staged build plus live-local AIOS Founder reporting; production collection held  
**Date:** 2026-09-18  
**Owner:** Founder  
**Implementation:** Codex  
**Authority:** DR-ZYRA-239; OA-ZYRA-256; OA-ZYRA-297

## 1. Purpose

ZYRA needs to know which product areas are used, where people encounter
failure and whether releases are healthy without turning a private marriage
service into a surveillance product. This document governs that balance.

## 2. Product evidence model

Every measured feature uses one small funnel:

`shown → opened → started → completed | failed`

This distinguishes a feature people never see from one they see but do not
open, and from one that fails after use. Raw tap totals alone are not a
product decision.

The first allowlisted feature keys are Browse, Connections, My ZYRA,
Guardian, Journey, Profile, ZYRA Code, Membership, Identity Check and
Support. The surface keys are Seeker, Guardian and Entry. Adding a new key is
a governed taxonomy change, not an arbitrary client string.

Phase 2C adds a separate fixed action dimension so a report can distinguish
page views from ZYRA Code checks/requests, known-person Consider actions,
Support answer/email actions, identity-provider actions and Guardian history
consent/report/Make Main/removal actions. An action is an enum, never button
copy or an arbitrary string. The Founder session view lists every governed
feature and action, including zero-use entries, so least-used evidence is not
silently omitted.

## 3. Permanent privacy boundary

Product events must never contain:

- names, emails, phone numbers or ZYRA Codes;
- user, profile, Guardian, Match, attempt or Journey identifiers;
- messages, search terms, profile answers, compatibility or religious data;
- safety, moderation or identity-document data;
- precise location, device or advertising identifiers;
- screenshots, session replay, arbitrary JSON or free text.

The first-party raw event table contains only fixed event, feature, surface,
platform, app-version/build and server timestamp fields. It does not persist
the authenticated caller. Product evidence must not become an individual
activity history.

## 4. Truth and control

- Normal builds keep remote collection OFF unless explicitly compiled with
  `ZYRA_PRODUCT_TELEMETRY_ENABLED=true`.
- A migration on disk is not a live system. The staged migration requires a
  separate exact Founder apply GO after security and privacy review.
- Applying the migration alone still does not turn collection on.
- Telemetry failure never blocks or changes a member action.
- The Founder health view states whether collection is off, local only or
  remotely accepted. It must not imply a crash provider or service-health
  integration exists before one does.

## 5. Retention and production gate

The staged migration now enforces a fixed 30-day raw-event deletion function,
a 5,000-events-per-minute project circuit breaker and a service-role-only
aggregate summary. None is live because the migration remains unapplied. Up
to 13 months for non-identifying aggregate trends remains a policy proposal,
not a live store or job. Before remote collection is enabled, ZYRA must
approve:

1. final privacy wording and an easy objection/opt-out route where required;
2. lawful basis and solicitor/privacy review;
3. independent verification of the staged retention/deletion and access
   controls;
4. independent verification of the staged abuse controls and an isolated
   direct-call matrix;
5. aggregate reports that cannot be used to reconstruct a member history;
6. store disclosures and a verified production rollback.

## 6. Reliability and crash evidence

Product events do not replace diagnostics. Phase 2 adds a bounded in-memory
technical monitor for backend-startup, native-identity, Flutter-framework and
unhandled-platform categories. It never accepts exception text, stack traces,
routes or arbitrary fields and sends nothing remotely. Apple crash
diagnostics and a strictly scrubbed error provider may be added later under
OA-ZYRA-297. They must exclude user content, screenshots, replay, email, IP
retention and arbitrary request bodies. Agents may detect, triage and prepare
fixes, but may never apply a migration, deploy, release or alter production
automatically.

## 7. Current truth

Phase 2 exists in the app as the Phase 1 typed event channel plus completed /
failed evidence for known-person and Guardian-link ZYRA Code funnels, a
bounded local reliability monitor and an expanded Founder-only session health
view. Phase 2B adds role-aware Membership and Support opens, Support
self-service/email outcomes, Identity Check outcomes, and Guardian detail,
consent, report, Main-role and removal actions. These all reuse the same fixed
feature/event/action/surface enums; no search query, help question, identity
reason, Guardian identity or arbitrary action payload is recorded. Phase 2C
makes that fixed action dimension explicit in both the client event and staged
server row, and shows zero-inclusive feature/action counts to the Founder. The first-party migration
stages retention, aggregate and abuse controls but remains unapplied. No
production analytics provider, remote crash reporter, live event table or
AIOS scheduler has been activated.

## 8. AIOS Founder reporting

AIOS now has one dedicated, Founder-only **ZYRA Health & Usage** space at
`/zyra-health`, with a matching read-only aggregate endpoint at
`/api/zyra-health`. It is part of the existing AIOS portal; no second portal
or public origin was created. The space provides:

- 24-hour, 7-day and 30-day report windows;
- zero-inclusive governed feature and action totals;
- shown/opened/started/completed/failed totals and success rate;
- release/build mix, fixed reliability categories and service-health states;
- a short plain-language Founder report; and
- an explicit collection state and privacy contract.

The bridge accepts only the already-aggregated fixed taxonomy. Unknown fields,
identity-bearing keys, negative counts, unreconciled totals and malformed
service/build data fail closed. It does not connect to Supabase or handle a
service-role credential. The future approved ingestion job may atomically
write only `AIOS/WORKSPACE_DATA/zyra_observability.json` after calling the
service-role aggregate RPC.

Current truth: the page and API are live on the local AIOS service, but they
show **Collection off** and zero metrics because the migration is still
unapplied and production collection is still disabled. The page is available
only to the full Founder scope; customer-scoped ZYRA portal sessions are
denied and do not receive the navigation item. No scheduler, provider, cloud
configuration or production data source was activated in this phase.
