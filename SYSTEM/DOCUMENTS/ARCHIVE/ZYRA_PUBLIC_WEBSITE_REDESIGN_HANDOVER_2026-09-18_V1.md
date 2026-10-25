# CODEX HANDOVER — ZYRA PUBLIC WEBSITE REDESIGN

**Version:** V1
**Date:** 2026-09-18
**Status:** CODEX INTERNALLY VERIFIED — Founder review and publication pending
**Owner:** Codex; Founder alone accepts and authorises publication
**Authority:** Founder’s complete website-redesign implementation brief, 2026-09-18; AD-AIOS-109
**Outstanding actions:** OA-ZYRA-260; incidental existing app defect recorded under OA-ZYRA-297

## 1. Outcome and boundary

The complete public homepage has been redesigned and implemented in the existing
Astro website, not as a disconnected concept. It has thirteen product-story sections,
four fresh current-app screens, a sticky desktop story, a deliberately simpler mobile
story, local typography, accessible navigation, honest availability labels and public
metadata. The local preview is `http://127.0.0.1:4321` while the preview process runs.

**Nothing has been deployed.** No git, DNS, Cloudflare settings, account changes,
app source edits, database changes, migration, Apple upload, email send or billing
changes were performed. Founder review remains outstanding. Codex verification is
not Founder acceptance and is not described as independent external approval.

The new brief expressly permits replacing the old structure and copy. The historical
Draft 3.1 dark-design and verbatim-copy restrictions do not constrain this local
candidate; all non-conflicting privacy, truthful-state and publication controls remain.

## 2. Existing website audited / stack / routes

The starting site was an Astro static project with a bespoke scroll engine, the
Midnight Plum Draft 3.1 homepage, a privacy page, local favicon, a waitlist component
and a Cloudflare Pages Function. Its README still described the historical
Fable→Codex handover. The prior UI used fabricated phone panels rather than current
app screenshots. The waitlist function returned 501: there was no working collection
service to present as a signup form.

Existing documented deployment is the Founder-controlled `zyra-site` GitHub
repository → Cloudflare Pages, `npm run build`, output `dist`. Domain
`zyraconnect.app`, plus its existing www redirect, was not changed. This is a source
audit of the delivery arrangement, not a claim of a fresh production deployment test.

Implemented with Astro 5.18.2, vanilla TypeScript and CSS. No React, animation
framework, remote font, analytics library or autoplay video is shipped. Build/test
runtime: Node 24.19.0, pnpm 11.19.0. The dependency lock is retained. Install scripts
for esbuild/sharp are explicitly disabled; offline frozen-lock installation and build
pass with their installed platform packages.

Preserved routes: `/`, `/privacy`, `/api/waitlist`. Preserved legacy anchors:
`#how`, `#values`, `#journey`, `#waitlist`. The unchanged waitlist handler returns
its honest 501 response; the unused original component is retained, not displayed.
The final CTA uses the documented `hello@zyraconnect.app` mail route. It does not
claim to subscribe anyone, send mail automatically, reserve a place or grant testing access.

## 3. Information architecture and copy

| Section | Implemented purpose |
|---|---|
| Hero | Muslim marriage context; “A clearer path to marriage”; Explore ZYRA CTA; private-testing status |
| Why ZYRA | Marriage intention, understanding, family support; concise editorial pillars |
| How it works | Four scroll steps: begin thoughtfully, give connection direction, bring trusted support, find the next step |
| Compatibility Unlock | Overall alignment and private answers; conceptual shared/different perspectives, not an invented score |
| Seekers | Define the role; individual profile, discovery, choices, Journeys and Guardian support |
| Guardians | Define the role; authorised participation, own account, support for multiple Seekers |
| Journey | Discover → understand → involve → decide; respectful endings, not failure |
| My ZYRA | Now summary/routing; future evidence-backed Insights clearly separated |
| Memberships | Three requested planned memberships, allocation explanation, trial note, purchases not open |
| Coming soon | Core in private testing; Insights/reflections coming; billing/identity checks before public launch |
| Trust | Separate accounts, role-aware visibility, two-sided code linking; no access purchased through membership |
| FAQ | Eleven concise role, permission, compatibility, family, free-plan and availability answers |
| Final CTA | Ask about early access by email; no public download or invented launch date |

Copy was shortened and rewritten into public language. No OA/DR terms, technical
permission names, internal architecture or sensitive commercial positioning are in
the public text. There are no success guarantees, invented scientific claims or
universal Family saving percentages. “Process, never behavioural surveillance” is
preserved explicitly in the family/privacy explanation.

## 4. Commercial conflict — publication hold

The review candidate implements the explicit prices in this brief:

| Plan | Review candidate |
|---|---|
| ZYRA One | £39.99/month; one Seeker allocation + one Guardian allocation |
| Additional Guardian | £19.99/month; coverage for another person |
| ZYRA Family | £99.99/month; up to five unique people; flexible roles; one bill, separate accounts |
| Trial / Free | Planned 14-day trial; no permanent consumer Free/Basic plan in this candidate |

**This is not the current app commercial model.**
`BUSINESS/ZYRA PRICING/ARCHIVE/ZYRA_PRICING_2026-09-24_V5.md` lines 15–19 instead
specifies One Seeker £29.99/month, Seeker Basic £9.99 one-time, One Guardian
£19.99/month and Guardian Basic £9.99 one-time; Family is unchanged by that ruling.
Lines 63–64 limit the planned trial to One Seeker and do not authorise a Guardian trial.
The corresponding paid-membership handover V4 also describes the separate-role model.

The Founder’s new brief governs this website candidate, not an inferred app billing
migration. The conflict was flagged during implementation and is retained in
OA-ZYRA-260. Before publication, the Founder must settle which model should be
offered publicly, its exact trial scope and how app entitlements will agree. No app
prices, store products, checkout or entitlement records were changed.

Compatibility Unlock public prices and category labels are deliberately omitted:
the current source supports an overall-score explanation, while detailed category
results/names are not ready for an unqualified public claim. The visual is expressly
conceptual, with no synthetic numeric compatibility result. Confirm public Unlock
price and scope under OA-ZYRA-260 before adding a price claim; omission is safe now.

## 5. Product truth and availability

- **Private testing:** discovery, overall compatibility, structured Journeys,
  Guardianship and My ZYRA Now. No public download or public TestFlight button.
- **Coming soon:** evidence-backed Insights and voluntary reflections; no promise
  that private messages are analysed or relationship outcomes inferred.
- **Before public launch:** memberships/billing and identity checks. No active
  biometric provider, verified-every-member or production-IDV claim.
- **Guardians:** authorised Journey conversations may be visible. The copy does
  not falsely promise that all messages are hidden from Guardians. Private
  compatibility answers and unrelated Journeys remain outside that claim.
- **Main/Additional:** Main leads designated family decisions; money does not
  grant authority. Preview-only separate View/Chat controls are not advertised as
  an already-live server feature.
- **ZYRA Codes:** start a request, not automatic linking, Journey access or a
  public people directory.
- Expanded Family management, conversation-preparation promises and unruled
  future features were not promoted merely to fill the roadmap.

## 6. Visual assets and provenance

Current Poppins body typography and Syne wordmark were confirmed in app source,
rather than assuming an older Jost document was current. The exact app font bytes
are self-hosted; Poppins and Syne OFL notices accompany them. Syne licence source:
`https://raw.githubusercontent.com/google/fonts/main/ofl/syne/OFL.txt`.

Four images were freshly rendered from current Flutter production widgets at
390×844 logical / 780×1688 pixel resolution, using synthetic fixtures and injected
data loaders. No real member data, session, production account, signed-in capture or
cloud read was used. The dummy test endpoint cannot be a production destination.

| Asset | Actual source / representation |
|---|---|
| connections.webp | ConnectionsScreen; two Potential Journeys, one Paused, Active empty |
| journey.webp | Guardian-side WaliJourneyDetailScreen; synthetic Maryam/Adam, stage/timeline and one fixture message |
| guardian.webp | Current SeekerGuardianPage; synthetic Main Guardian Ibrahim |
| my-zyra.webp | Current ZyraQuietDashboard; composite allNow development fixture, not one live account |

Images are labelled development previews/sample data; the Journey view is labelled
Guardian-side in alt text and the inline caption. PNG originals, exact capture
harness, source hashes, WebP hashes and exceptions encountered are retained in
`app-captures/notes.md` in the evidence directory. The final capture test passed:
one test, four outputs, no Flutter error/overflow. No approved visual baseline was
regenerated or touched. The retained static wordmark asset is not claimed as the
current app icon. Social artwork is code-rendered from these brand fonts, 1200×630.

## 7. Motion, responsive behaviour and accessibility

Desktop motion activates only at a sufficiently wide/tall viewport and without a
reduced-motion preference. Native scrolling drives a sticky phone, four changing
screens, a quiet progress line and text/reveal transitions. requestAnimationFrame
and IntersectionObserver avoid per-frame layout polling. No wheel/touch interception,
forced scroll snapping or scroll hijacking. The phone scales down on short laptops.

Mobile/tablet and reduced-motion users get the complete sequence as inline content.
No information depends on motion. JavaScript-disabled pages retain the full story
and a working navigation fallback. Viewport and reduced-motion changes reset hidden
states; inactive enhanced screens are inert/aria-hidden. Numbered controls expose
the same visible numbers in their accessible names. FAQ uses native details/summary.

Verified: skip link, keyboard menu, Escape returning focus, short-landscape menu
scrolling, story controls/current state, meaningful image text, semantic headings,
contrast, no horizontal overflow at 320/390/768/1024/1920 CSS pixels, short laptop
phone/caption clearance, no-JS, reduced-motion and 200% browser-zoom-equivalent
reflow from 1280 to 640 CSS pixels. CSS root zoom was not treated as browser zoom:
it does not recalculate media queries. Main public copy is at least 14px; labels and
captions are separately compact. The site has one light-led treatment with a dark
plum Journey section, not two incomplete light/dark themes.

Automation is not a complete WCAG certification. Physical iPhone Safari, Android,
VoiceOver and Founder visual acceptance remain practical review checks; Playwright
WebKit is explicitly not represented as a physical Safari device test.

## 8. Verification and measured performance

The final relevant browser suite passed **54/54 checks**, across Chrome and
Playwright WebKit 26.5, and produced **31 review screenshots**. Four automated
WCAG A/AA audit contexts (desktop, mobile, privacy, reduced motion) report zero
violations. No uncaught browser exceptions or third-party browser requests occurred.
The unchanged waitlist function was exercised directly and still returned 501.
Production Cloudflare routing was not exercised by Astro’s local preview.

Build: PASS; two static pages. Production JavaScript: **3.75KB raw / 1.41KB gzip**.
Offline frozen-lock dependency verification: PASS. The first dependency install
reported unapproved optional build scripts; explicit disabled policy plus a repeat
offline install resolved that without executing them. Earlier QA findings—contrast,
short-laptop overlap, narrow-screen ring overflow, short menu clipping and mobile
heading whitespace—were corrected, then the browser suite rerun.

| Lighthouse 13.4.1 local lab run | Mobile | Desktop |
|---|---:|---:|
| Performance | 90 | 100 |
| Accessibility | 100 | 100 |
| Best practices | 100 | 100 |
| SEO | 100 | 100 |
| LCP | 3.3s | 0.7s |
| CLS | 0.005 | 0.001 |
| Total blocking time | 0ms | 0ms |

These are local simulated-throttle Chrome results, not production field measurements
or a claim of mobile LCP under 2.5s. Mobile image downsizing could save approximately
58KiB; the small render-blocking stylesheet is the largest remaining lab opportunity.
There is no real-user INP dataset before public launch. Native controls, minimal JS,
zero measured TBT and direct interaction tests give bounded lab evidence, not an
invented live responsiveness metric. Final browser checks followed a whitespace-only
mobile heading correction after the Lighthouse runs; functionality/assets are unchanged.

## 9. SEO, privacy and metadata

Page-specific title/description/canonical, Open Graph, Twitter large image, favicon,
en-GB language, WebSite structured data, robots and sitemap are implemented. All
public metadata uses `https://zyraconnect.app`, never localhost/internal locations.
No Product/Offer availability schema falsely marks a purchase as available.

The retained privacy route now explains actual website/contact behaviour rather
than nonexistent waitlist collection: no analytics, trackers or third-party fonts;
email enquiry handling; ordinary hosting technical requests; sample app imagery.
It is a website notice, not an invented complete app/IDV privacy contract. Existing
Cloudflare production security/cookie settings should be rechecked at publication.

## 10. Files, evidence and rollback

Source root: `/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SITE`.
Changed existing files: README, package.json, astro.config.mjs, homepage, privacy
page, Base layout, Nav component and global CSS. Added: Footer/Phone components,
story.ts, verification script, dependency lock/policy, self-hosted fonts/licences,
four WebP screens, retained brand asset, social image, robots and sitemap.
Original favicon, WaitlistForm and waitlist function are byte-preserved. Generated
dependencies, .astro and dist are not authoritative source.

Canonical evidence directory:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/zyra-website-redesign.ecE5kb/`.

- `founder-brief.txt`: preserved exact implementation brief.
- `site-before.tar.gz`: true pre-edit archive; no reconstructed pre-state.
- `governance-prestate/`: register/index copies taken before their first edit.
- `file-ledger.json` / `file-ledger.md`: true pre/post SHA-256 and new-file states.
- `app-captures/`: screenshot origins, current source hashes and capture harness.
- `review/index.html`: review gallery linking desktop/mobile/full-page/stills.
- `review/zyra-scroll-review.webm`: short local scroll recording.
- `review/{verification,accessibility}.json`: final browser evidence.
- `review/lighthouse-{mobile,desktop}.report.{html,json}`: lab reports.

Pre-edit archive SHA-256:
`fadf92ac38e843a1ce2bacebc6ff28f1b558f1b3f56533a000616b3d6be2085f`.
The archive excludes .git, dependencies and generated build output. Extract into a
new scratch directory first. Verify hashes and compare against subsequent user edits;
restore only affected originals, preserving new candidate files separately. Do not
use git reset or overwrite the whole user worktree. No public rollback is required
because there was no public deployment.

## 11. Limitations, follow-up and Founder review

1. **OA-ZYRA-260:** review the visual direction, scroll pacing and mobile story.
   Decide whether the website’s requested commercial model replaces the current
   app model; reconcile exact allocations/trial/purchase terms before publication.
2. **OA-ZYRA-260:** review public wording and actual available contact route.
   A working automated waitlist would be a separate bounded backend change;
   the existing 501 endpoint was deliberately not disguised as a working service.
3. **OA-ZYRA-260:** do physical-device/screen-reader acceptance and verify the
   existing Pages runtime/routing/security behaviour before an explicit publish GO.
   This is not authority to change deployment settings or perform Founder git.
4. **OA-ZYRA-297, incidental app finding:** the current synthetic Active Journey
   card reads `SeekerProfile.photoUrl` → `photos.first` with an empty photos list,
   producing StateError at seeker_profile.dart:79 / connections_screen.dart:4562.
   The exact reproduction is in app-captures/notes.md. It is recorded for the
   existing reliability work, not silently fixed or hidden during website capture.

No separate action is raised for speculative further motion, additional sections or
unapproved marketing claims: they are not necessary to fulfil this implementation.
There is no newly created schedule, autonomous repair/deploy agent or duplicate OA.

**Recommended Founder review:** open the local preview, scroll it once on desktop,
review the mobile screenshots, then give design/copy feedback. The public site stays
unchanged until the commercial conflict and publication gate are resolved.
