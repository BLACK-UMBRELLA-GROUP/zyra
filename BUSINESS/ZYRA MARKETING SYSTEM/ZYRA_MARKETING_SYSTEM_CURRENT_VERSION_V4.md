---
id: DOC-ZYRA-0119
type: PLAN
status: CURRENT
feature: BUSINESS: ZYRA MARKETING SYSTEM
purpose: Zyra Marketing System — ZYRA MARKETING SYSTEM CURRENT VERSION V4
links: []
owner: ZYRA chat
---

# ZYRA MARKETING SYSTEM

**Version:** V4  
**Status:** CURRENT_VERSION — social control register, campaign variants and calendar implemented inside AIOS; no external connection or publishing authorised  
**Date:** 2026-10-04  
**Owner:** Founder (approval) · Codex (main operator and marketing lead) · ChatGPT (bounded support only)  
**Authority:** Founder instruction, 2026-09-25; AD-AIOS-111; OA-AIOS-379; OA-AIOS-389; OA-ZYRA-301

## PROJECT LOCATION

- **Major Folder:** 04_BUSINESS/
- **Purpose:** Govern ZYRA's AI-assisted marketing preparation, approval, manual publishing and learning loop.
- **Owns:** Marketing research, inspiration intake, strategy, content production, brand review, approval flow, publishing workflow, community-response drafting and marketing analytics.
- **References:** ZYRA Brand Messaging, Competitor Research, Website, Launch Guide, Product Specification, Pricing and current implementation handovers.
- **Referenced By:** AIOS, public website, marketing-channel operations, campaign landing pages and future scheduling/analytics integrations.

## 1. Governing principle

**AI prepares and learns; the Founder retains control of what represents ZYRA publicly.**

No post, reply, advert, campaign, spend or material public edit is approved merely because Codex or another agent prepared or checked it. Public content requires the Founder's exact approval of the final visible artefact. Any material edit after approval invalidates that approval and returns the item to draft.

## 2. Operating model

| Role | Responsibility |
|---|---|
| Founder | Sole approval of public content, campaigns, sensitive replies and budgets. |
| Codex | Main operator and marketing lead: research synthesis, strategy, content, product truth, brand accuracy, channel administration, security coordination, compliance records, spending controls and governed records. |
| ChatGPT | Bounded support for research, drafting, analysis or review when engaged by the Founder or Codex; never an approver or mandatory gate. |

Codex does not handle secret values, accept external terms or self-approve spend or public content. The Founder performs human-only credential, recovery, identity and payment steps and retains final control of every public output.

## 3. Channel scope

- TikTok — reach, short-form education, Founder/building story and product demonstrations.
- Instagram — short-form video, carousels, visual education, trust content and repurposed concepts.
- Facebook — parents, Guardians, families, longer explanations and community-relevant updates.
- Threads — conversational education and product discussion adapted from approved master ideas.
- YouTube — Shorts reused from approved vertical video and later longer explanations.
- X — concise updates and questions where the channel has a defined purpose.
- Pinterest — durable educational/visual material where it proves useful.
- Reddit — community-specific discussion only where community rules permit it.
- Snapchat — reserved/experimental until a staffed purpose is approved.
- Website — destination for approved channel activity; website changes remain a separate explicit workstream.

No channel, advertising or payment API is connected to the command centre.

## 4. AI-assisted team

1. **Research Agent** — public-source signals, competitor activity, audience questions and opportunities with evidence.
2. **Strategy Agent** — pillars, hooks, keywords, platform fit and priorities.
3. **Content Studio** — scripts, captions, carousels, thumbnails and platform variants.
4. **ZYRA Brand Guardian** — dating-app language, unsupported claims, privacy overreach and current-product accuracy.
5. **Approval Centre** — exact public artefact, destination, risk and spend for Founder approval.
6. **Publishing System** — approved manual publishing packs only; it cannot post.
7. **Community Manager** — ordinary draft replies; sensitive categories are human-only.
8. **Analytics & Memory** — outcomes and lessons after publication.

These are controlled workflow roles, not eight autonomous public actors. Codex operates the workflow. None can publish or spend independently.

## 5. Inspiration collection mode

The Founder may send saved videos one by one. During collection:

- each URL is retained in arrival order;
- an identical URL is marked as a repeat without deleting either record;
- no video is researched, copied, analysed, implemented or turned into content;
- the intake remains `COLLECT_ONLY` until the Founder explicitly ends collection;
- later review will consolidate repeats, separate useful principles from unsuitable copying, and put any proposed implementation through the normal approval route.

The dashboard's **Inspiration inbox** is the durable record for this intake.

## 6. Content pillars

1. Why ZYRA is different from dating apps.
2. Guardian and family involvement.
3. Serious, marriage-first introductions.
4. Safety, trust and privacy.
5. Compatibility and intentional matching.
6. Advice for Seekers.
7. Advice for Guardians and parents.
8. Founder story and building ZYRA.
9. Product demonstrations.
10. Pre-launch progress and testing.

Content must not expose test-member information, imply public availability, present planned features as live, offer religious rulings or promise a marriage outcome.

## 7. Approval and risk rules

| Class | Route |
|---|---|
| Routine | Brand/product check → Founder exact-preview approval → manual publication |
| Sensitive | Brand/product check → recorded compliance review → Founder exact-preview approval → manual publication |
| Human-only response | Do not auto-reply; route safety, complaint, religious, sensitive matrimonial, press and regulator items to a human |
| Spend-bearing | Brand/product check → compliance review → separate Founder budget approval → Founder content approval |

Approval applies to the exact copy, platform, format, link and budget. Editing any public field clears the existing checks and approval.

## 8. Marketing memory boundaries

- Use public sources, approved ZYRA documents, approved public content and platform performance data.
- Never use private member messages, compatibility answers, identity evidence, safety reports or precise member location as marketing input.
- Do not create fake testimonials, couples, comments, scale claims or performance data.
- Record observation separately from interpretation and future experiments.
- Retain only the inbound-message content needed for an operational purpose.

## 9. AIOS command centre

The canonical Founder entry point is:

`http://127.0.0.1:7700/marketing/`

AIOS mounts the governed ZYRA workflow through `BLACK UMBRELLA GROUP/AIOS/marketing_bridge.py`. The underlying engine and interface remain:

- `SYSTEM/tools/zyra_marketing_center.py`
- `SYSTEM/tools/zyra_marketing_web/`
- `SYSTEM/RESOURCES/MARKETING_COMMAND_CENTER/state.json`

The standalone loopback server remains a fallback developer route, not a second state store. Cross-process locking protects the shared state if the fallback is used while AIOS is present.

## 10. Implemented controls

- Eight-role command view.
- Nine-platform non-secret account register covering ownership, public identity,
  business status, MFA, passkey, recovery, delegated-access and integration status.
- Secret-field rejection: passwords, tokens, recovery codes and API keys cannot
  be entered into the account register.
- Master ideas with linked platform variants, allowing one concept to become
  platform-specific executions without being counted as separate daily ideas.
- Europe/London calendar with a maximum of three distinct master ideas per day;
  additional variants of the same idea remain allowed.
- Content pipeline and exact-preview approval identity.
- Exact approval now includes the destination account, master idea, schedule,
  media reference and optional media SHA-256 fingerprint as well as public copy.
- Deterministic ZYRA brand/product claim checks.
- Separate compliance and spend gates.
- Manual publishing-pack export and publication record.
- Research memory and collection-only inspiration inbox.
- Exact-URL repeat marking without deletion.
- Human-only escalation for sensitive community categories.
- Analytics and learning records after publication.
- Founder-scope enforcement through AIOS; no public or customer-scoped write route.
- A fail-closed connection policy: live connections, automated publishing and
  automated community replies are disabled in state and have no API route.
- Five-second idle-client timeout so speculative browser connections cannot freeze the serial AIOS service.

## 11. Verification and current boundary

- Eleven command-centre workflow/safety tests pass.
- Four AIOS bridge tests pass.
- Python compilation passes for the command-centre engine and AIOS bridge.
- The tests cover secret rejection, disabled live connections, account/campaign
  bridge routes, the three-idea calendar limit, variant reuse, and approval
  fingerprints that change when account, media or schedule changes.
- Existing AIOS UI-consistency dashboard tests remain green.
- Live AIOS probes returned HTTP 200 for the command page, JavaScript and state API.
- The dashboard loaded visually with eight roles, three unapproved content drafts and an empty collection-only inspiration inbox.

No content has been approved, published or sent. No social account, model API,
scheduling API, publishing API, advertising API, credential or payment mechanism
is connected. Account rows are operating records, not authenticated sessions.

## 12. Next gate

Reconcile the real account handles, public URLs, login identities and non-secret
security status in the new register. Before any OAuth or scheduler connection is
implemented, separately approve and verify request-level AIOS authentication,
CSRF protection and encrypted external secret storage. Only then connect one
platform/provider at a time. Public activity still requires the Founder's exact
approval of the final account, copy, media, destination, schedule and spend.
