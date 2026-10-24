# ZYRA — Product Observability Build Contract

**Version:** V1  
**Status:** CURRENT_VERSION — Phase 2 local/staged slice and AIOS report surface built; production gates remain  
**Date:** 2026-09-18  
**Authority:** DR-ZYRA-239; ZYRA_PRODUCT_OBSERVABILITY  
**Implementation action:** OA-ZYRA-256  
**Reliability action:** OA-ZYRA-297

## 1. Phase 1 — local foundation and staged server boundary

Build:

1. one Dart service whose public API accepts enums only;
2. a maximum of 200 current-process events, never persisted locally;
3. a compile-time remote gate that defaults to false;
4. initial page-open evidence for both role shells and ZYRA Code entry;
5. a Founder-only view showing collection state and session counts;
6. one staged private Supabase table and authenticated write RPC;
7. static tests pinning the client/server taxonomy and security grants.

The RPC is `SECURITY DEFINER`, uses an empty search path, derives
authentication from `auth.uid()`, accepts only fixed scalar fields, exposes no
read route and grants execution only to authenticated/service_role. Raw table
access is private and denied to public, anon and authenticated.

## 2. Phase 1 acceptance

- telemetry-focused tests pass;
- Flutter analyzer is clean;
- default build proves remote collection is false;
- migration remains unapplied;
- no Privacy & Data claim is changed to imply live analytics;
- no approved visual baseline is regenerated;
- pre/post hashes and full-suite truth are filed.

## 3. Phase 2 — local reliability and production-readiness controls

Built under the Founder's instruction to continue:

- bounded, current-process technical fingerprints for startup, framework and
  platform failures, with no raw exception, stack, route or member data;
- truthful health counts in the Founder Health & Usage view;
- started/completed/failed evidence on both ZYRA Code request funnels;
- a staged 30-day raw-event pruning function;
- a staged service-role-only aggregate summary;
- transaction-scoped caller serialization and a 5,000-events-per-minute
  identifier-free project circuit breaker.

These additions remain local or staged. No provider, migration, collection
flag or schedule was activated.

### Phase 2B — core action coverage

Built under the Founder's instruction to continue:

- Membership screen opens, separated by Seeker/Guardian surface;
- Support screen opens, self-service answer completion and email-launch
  started/completed/failed outcomes;
- Identity Check opens, provider starts, terminal completion and fixed failure
  outcomes;
- Guardian detail opens plus consent, report, Make Main and removal outcomes.

No query, question, email address, identity result reason, Guardian identity,
relationship or free-text error is accepted by the event API.

### Phase 2C — action-level evidence

Built under the Founder's instruction to continue:

- one additional closed action enum, independent of visible button copy;
- action values for page views, ZYRA Code check/request, known-person
  Consider, Support answer/email, identity provider and Guardian consent,
  report, Make Main and removal actions;
- zero-inclusive feature and action counts in the Founder session view;
- matching `action_key` constraints, write validation and aggregate grouping
  in the still-staged migration.

No arbitrary string, control label, person value or action payload is accepted.
Production collection remains compile-time off and the migration remains
unapplied.

## 4. Production promotion gates (held)

Before apply or collection enablement:

- independent SQL/security review;
- retention, deletion, access and abuse-control implementation;
- solicitor/privacy review and final member disclosure/objection design;
- isolated PostgreSQL replay and direct-call matrix;
- exact migration SHA-256 Founder apply GO;
- post-apply verification;
- a separate release build with the compile gate enabled;
- rollback proof.

## 5. Phase 3 — remote reliability and Founder operations (held)

Evaluate Apple diagnostics plus a scrubbed EU-region crash provider. Add
service-health inputs and a short Founder report through the existing daily
operation only after a separate scheduler activation GO. No new duplicate
schedule is created. Automated agents may classify and prepare tested patches
but cannot deploy or self-approve.

### Phase 2D — AIOS ZYRA Health & Usage surface

Built under the Founder's instruction to start with AIOS:

- one Founder-only page inside the existing AIOS portal, not a new portal;
- 24-hour, 7-day and 30-day aggregate views plus a plain Founder report;
- complete zero-inclusive feature/action taxonomies;
- fixed reliability, service-health and build/release summaries;
- one read-only AIOS aggregate API;
- one file bridge contract whose unknown or identity-bearing fields fail
  closed; and
- truthful collection-off behaviour while the production gates remain held.

The AIOS process does not connect to Supabase, hold service-role credentials,
read raw events or expose member-level activity. A later ingestion bridge,
its credential custody, schedule and activation each remain separately gated.

## 6. Stop conditions

Stop on personal-data payload expansion, unknown taxonomy values, public/raw
table access, caller-identity persistence, security-definer drift, a failed
isolated replay, unapproved cost, changed privacy requirements, or any request
to enable production collection without the named gates.
