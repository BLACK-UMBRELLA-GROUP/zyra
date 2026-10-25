---
id: DOC-ZYRA-0117
type: PLAN
status: CURRENT
feature: BUSINESS: ZYRA MARKETING SYSTEM
purpose: Zyra Marketing System — Script Summary: ZYRA MARKETING SYSTEM — SCRIPT SUMMARY
links: []
owner: ZYRA chat
---

# ZYRA MARKETING SYSTEM — SCRIPT SUMMARY

## PROJECT LOCATION

- **Major Folder:** 04_BUSINESS/
- **Purpose:** Define the implementation contract for the local marketing command centre.
- **Owns:** Local content records, approval states, brand checks, publishing exports and performance learning.
- **References:** `ZYRA_MARKETING_SYSTEM_CURRENT_VERSION_V4.md`, Brand Messaging and governed product truth.
- **Referenced By:** Approved publishing operations and future controlled integrations.

## SCRIPT SUMMARY

### Current implementation

The canonical dashboard is mounted in AIOS at `http://127.0.0.1:7700/marketing/` by `BLACK UMBRELLA GROUP/AIOS/marketing_bridge.py`. `SYSTEM/tools/zyra_marketing_center.py` remains the workflow engine and loopback-only fallback. The interface is in `SYSTEM/tools/zyra_marketing_web/`; atomic runtime state is in `SYSTEM/RESOURCES/MARKETING_COMMAND_CENTER/state.json`. Cross-process file locking protects that single state store. There is no social, model, advertising or payment API.

The eight operating roles, nine-platform non-secret account register, master-idea families, linked platform variants, 1–3-idea calendar, content pipeline, research memory, collection-only inspiration inbox, Founder approval, community classification and analytics memory are usable. Exact repeat URLs are marked; no video is fetched or analysed during collection. Three sample content ideas are `DRAFT`; none is approved or public. The existing website remains unchanged.

### Command-centre record

Each content item must carry:

- stable ID, creation/update timestamps and owner;
- pillar, campaign, target platform and content format;
- source evidence and current-product references;
- hook, script/copy, media/thumbnail and destination link;
- risk class and required reviewer route;
- brand/product/compliance findings;
- exact-preview hash or equivalent immutable approval identity;
- exact destination account, scheduled local time, media reference and optional
  media SHA-256 fingerprint;
- Founder approval/rejection record;
- schedule/publication result and platform identifier;
- performance observations and next learning.

### State machine

`DRAFT → BRAND_REVIEWED → COMPLIANCE_REVIEWED_IF_REQUIRED → FOUNDER_REVIEW → APPROVED → MANUALLY_PUBLISHED → MEASURED`

`REJECTED` and `CORRECTION_REQUIRED` are explicit reroute states. Any material public-field edit clears checks and approval and returns the item to `DRAFT`. Published and measured records are immutable.

### Non-negotiable controls

- Publishing is impossible without exact Founder approval.
- Spend requires a separate explicit budget approval.
- Credentials and recovery data never enter source files or content records.
- The account register rejects password, token, recovery-code and API-key fields.
- Live social connections, automated publishing and automated public replies
  remain fail-closed and have no route in the engine.
- Safety reports, complaints, religious questions and sensitive matrimonial situations are human-only.
- Private member data is prohibited as marketing input.
- Manual approved publishing precedes API scheduling.
- Platform integrations must be reversible, observable and scoped to the minimum permission required.
- Inspiration collection persists links only; analysis begins solely after the Founder ends collection.

### Verification

Eleven command-centre safety/workflow tests pass, including approval invalidation, compliance routing, manual publication gating, human-only escalation, collection-only duplicate capture, secret rejection, disabled live connections, master-idea variants, the three-idea daily cap and schedule/media/account approval binding. Four AIOS bridge tests pass. Python compilation passes for the engine and bridge. The existing website remains unchanged.
