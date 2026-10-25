# ZYRA MARKETING SYSTEM

**Version:** V2  
**Status:** CURRENT_VERSION — local Marketing Command Centre implemented; no external publishing authorised  
**Date:** 2026-09-25  
**Owner:** Founder (approval) · Codex (marketing lead, strategy, content, product accuracy, account administration, security coordination, compliance records and spending controls) · ChatGPT (bounded support only)  
**Authority:** Founder instruction, 2026-09-25; AD-AIOS-111; OA-AIOS-379; OA-AIOS-389; OA-AIOS-390; OA-ZYRA-301

## PROJECT LOCATION

- **Major Folder:** 04_BUSINESS/
- **Purpose:** Govern ZYRA's AI-assisted marketing preparation, approval, manual publishing and learning loop.
- **Owns:** Marketing research, strategy, content production, brand review, approval flow, publishing workflow, community-response drafting and marketing analytics.
- **References:** ZYRA Brand Messaging, Competitor Research, Website, Launch Guide, Product Specification, Pricing and current implementation handovers.
- **Referenced By:** Public website, marketing-channel operations, campaign landing pages and future scheduling/analytics integrations.

## 1. Governing principle

**AI prepares and learns; the Founder retains control of what represents ZYRA publicly.**

No post, reply, advert, campaign, spend or material public edit is approved merely because an agent produced or checked it. Public content requires the Founder's exact approval of the final visible artefact. Any material edit after approval invalidates that approval and returns the item to draft.

## 2. Operating split

| Role | Responsibility |
|---|---|
| Founder | Final approval of public content, campaigns, sensitive replies and budgets. |
| Codex | Main operator and marketing lead; research synthesis, strategy, content, product truth, brand accuracy, channel-account administration, security coordination, compliance, spending controls and governed records. Website work occurs only under a separate explicit instruction. |
| ChatGPT | Bounded support for research, drafting, analysis or review when engaged by the Founder or Codex; never an approver or mandatory gate. |

Codex does not handle secret values, accept external terms or approve spend.
The Founder performs human-only credential, recovery, identity and payment
steps and approves all public output and budgets. ChatGPT has no standing
account or publishing authority.

## 3. Initial channel scope

- TikTok — reach, short-form education, Founder/building story and product demonstrations.
- Instagram — short-form video, carousels, visual education, trust content and repurposed TikTok concepts.
- Facebook — parents, Guardians, families, longer explanations and community-relevant updates.
- Website — the destination for approved channel activity; unchanged by this implementation.

No channel API or social-account credential is connected to the command centre.

## 4. Team

1. **Research Agent** — records public-source signals, competitor activity, audience questions and opportunities with evidence.
2. **Strategy Agent** — chooses pillars, hooks, keywords, platform fit and priorities.
3. **Content Studio** — prepares scripts, captions, carousels, thumbnails and platform variants.
4. **ZYRA Brand Guardian** — rejects dating-app language, unsupported claims, privacy overreach and wording inconsistent with the current product.
5. **Approval Centre** — presents the exact public artefact, destination, risk and spend for Founder approval.
6. **Publishing System** — exports only approved manual publishing packs. It cannot post to social accounts.
7. **Community Manager** — classifies inbound items and prepares ordinary draft replies; sensitive categories are human-only.
8. **Analytics & Memory** — records outcomes and lessons after publication.

## 5. Content pillars

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

Content uses current ZYRA terminology and implementation truth. It must not expose test-member information, imply public availability, present planned features as live, offer religious rulings or promise a marriage outcome.

## 6. Approval and risk rules

| Class | Route |
|---|---|
| Routine | Brand/product check → Founder exact-preview approval → manual publication |
| Sensitive | Brand/product check → recorded compliance review → Founder exact-preview approval → manual publication |
| Human-only response | Do not auto-reply; route safety, complaint, religious, sensitive matrimonial, press and regulator items to a human |
| Spend-bearing | Brand/product check → compliance review → separate Founder budget approval → Founder content approval |

Approval applies to the exact copy, platform, format, link and budget. Editing any public field clears the existing checks and approval.

## 7. Marketing memory boundaries

- Use public sources, approved ZYRA documents, approved public content and platform performance data.
- Never use private member messages, compatibility answers, identity evidence, safety reports or precise member location as marketing input.
- Do not create fake testimonials, couples, comments, scale claims or performance data.
- Record observation separately from interpretation and future experiments.
- Retain the minimum inbound-message content needed for an operational purpose.

## 8. Implemented command centre

The local-only command centre is implemented at:

`SYSTEM/tools/zyra_marketing_center.py`

It is opened through:

`SYSTEM/tools/run_zyra_marketing_center.sh`

Runtime state is stored atomically at:

`SYSTEM/RESOURCES/MARKETING_COMMAND_CENTER/state.json`

The interface contains the eight-role team, content pipeline, research memory, Founder approval centre, community classification and analytics memory. Three content ideas exist as unapproved drafts. No live account, model API, scheduling API, publishing API or payment mechanism is connected.

## 9. Verification

- Seven command-centre workflow and safety tests pass.
- Desktop and 390 px layouts were visually checked.
- The temporary website changes created under the rejected interpretation were removed.
- The original website builds as two routes and its full local suite passes: 99 site checks, 247 audience checks, 77 scroll-settle checks, 24 scroll-settle unit checks and zero reported accessibility violations.

## 10. Next gate

The Founder reviews the command centre and the three draft ideas. No review action is public approval. After explicit direction, Codex can conduct current public-source research and build the first content batch. Live scheduling, analytics or account connections remain separate controlled changes.
