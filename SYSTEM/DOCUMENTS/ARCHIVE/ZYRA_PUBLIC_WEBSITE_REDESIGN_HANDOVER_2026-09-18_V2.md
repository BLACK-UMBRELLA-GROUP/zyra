# CODEX HANDOVER — ZYRA PUBLIC WEBSITE REDESIGN

**Version:** V2
**Date:** 2026-09-18
**Status:** CODEX INTERNALLY VERIFIED — Founder review and publication pending
**Owner:** Codex; Founder alone accepts and authorises publication
**Supersedes:** ZYRA_PUBLIC_WEBSITE_REDESIGN_HANDOVER_2026-09-18_V1.md (ARCHIVE; byte-preserved)
**Authority:** Founder’s complete-redesign brief and same-day cinematic/purple/gold revision; AD-AIOS-109
**Outstanding action:** OA-ZYRA-260

## 1. Outcome and boundaries

The existing Astro site now follows the Founder's revised direction: the app's
purple background, gold accents, white ZYRA wordmark, and a scroll-driven story
extending beyond the four-screen Experience section. Twelve chapters contain the
full product story; ten can pin on a sufficiently tall desktop. Experience keeps
its own four-screen progression; the FAQ deliberately remains normal flow so
opening answers never traps or clips their content.

Local review: `http://127.0.0.1:4321/` while the preview process runs.
**Not deployed; Founder acceptance pending.** No git, DNS, cloud/account settings,
app source, migration, production data, billing or Apple upload changes. No
outside-review participant was enlisted. Subagent checks are internal Codex QA.

V1 remains the historical record of the complete first redesign, product audit,
four app-screen captures and original deployment-source audit. Its light visual
treatment and first-round metrics are superseded by this report. The original
public Draft 3.1 site is not claimed to have been changed by either local round.

## 2. Brand and assets

- Background: current app gradient `#684D78` → `#241A2C`.
- Gold accents: `#E8C98A`; white headings and Syne wordmark.
- Poppins body text and Syne wordmark remain locally hosted with OFL notices.
- Gold lines, restrained glass surfaces and soft rings replace light pastel panels.
- The social preview is re-rendered at 1200×630 in the same palette.

Source references: `SOURCE/lib/theme/zyra_colors.dart` (gradient lines 42–48,
current default 602–605; gold line 203) and `SOURCE/lib/theme/zyra_text.dart`
(wordmark 328–341). This is a web treatment based on current tokens; app colours
and controls were not changed. The web gold CTA follows this Founder direction.

The four existing current-app WebPs are byte-preserved: Connections, Guardian-side
Journey detail, Seeker Guardian management and My ZYRA. They use synthetic fixtures,
not member data or production sessions. They remain labelled development previews.
Original harness, source hashes and PNGs are in the V1 evidence `app-captures/`.
No AI-generated screenshots or approved app visual baselines were created/replaced.

## 3. Scroll choreography

| Chapter | Scroll behaviour |
|---|---|
| 01 — A clearer path | Phone rotates and approaches; supporting notes drift; headline and orbit respond |
| 02 — Intention | Three principles settle into place with a current-beat accent |
| 03 — The experience | Existing sticky phone changes through four real app screens |
| 04 — Compatibility | Separate rings converge; conceptual points settle, with no invented score |
| 05 — Your people | Seeker and Guardian panels turn towards a shared composition |
| 06 — The Journey | Gold path draws across the stages; current stage is highlighted |
| 07 — My ZYRA | Phone straightens; Now and future Insights receive successive emphasis |
| 08 — Memberships | Cards settle into place; prices are never animated or obscured |
| 09 — On the horizon | Availability rows highlight in sequence |
| 10 — Trust | Principles settle and highlight |
| 11 — Good questions | Normal-flow accessible FAQ; no outer pin |
| 12 — Your next chapter | White ZYRA wordmark settles within expanding gold orbits |

The header provides current chapter and a “Read without motion” switch, replacing
the header CTA while visible; the real final email CTA remains available. Read mode
removes both outer pins and Experience animation, retaining the current chapter.
“Play scroll story” re-enables it. No preference is silently saved to an account.

Scrolling is native: no wheel/touch interception, forced snap, smooth-scroll
library, autoplay video or synthetic production scroll timer. JavaScript consumes
cached geometry in requestAnimationFrame; it updates progress variables, current
beats, accessible screen states and the chapter label.

## 4. Responsive and accessible behaviour

Desktop enhancement requires at least 900×640 CSS pixels and no reduced-motion
preference. Each chapter pins only when the complete section fits below the header;
it falls back to ordinary flow otherwise. At 1440×1000 and the checked 1440/1920/
1024×900 viewports, ten chapters fit; Experience and FAQ use their own normal flow.
At the actual 1280×720 in-app review viewport, seven chapters pin plus Experience's
existing sequence; the taller people, memberships and closing sections flow normally.
At 1024×640, three outer chapters fit. This is an intentional fit/readability limit,
not a claim that every chapter is pinned at every desktop size.

Mobile, tablet, short viewports, reduced motion and no JavaScript preserve the full
story and inline app images. All copy, prices and actions remain in the document.
Inactive Experience illustrations are inert/aria-hidden only during enhanced mode.
In-page links and keyboard focus settle within their destination scene. Native
details/summary, semantic headings, skip link and keyboard mobile menu are retained.

Automated checks are not complete WCAG certification. Physical iPhone Safari,
Android, VoiceOver and Founder motion/visual acceptance remain review checks.
Playwright WebKit is not described as a real iPhone Safari test.

## 5. Product truth and publication HOLD — unchanged

The revised appearance does not add functionality or change prices/authority.

- Core app is in private testing. No public download, public TestFlight or promised launch date.
- Insights and reflections are coming soon, not claimed as available.
- Billing and identity checks are not open publicly. No verified-every-member claim.
- Compatibility visual is conceptual; private answers stay private. No invented
  category results, scientific guarantees or unruled Unlock prices.
- Guardians see only role/permission-authorised information and conversations.
  A membership does not purchase unrestricted access. Codes start requests, not
  automatic linking or a people directory.
- Final contact is genuine email to `hello@zyraconnect.app`, not a functional waitlist.
  The retained `/api/waitlist` function still returns honest 501; no fake form is displayed.
- `/`, `/privacy`, legacy anchors, robots, sitemap, favicon and public metadata survive.
  No analytics, external fonts or third-party browser requests are introduced.

**Commercial publication conflict remains OA-ZYRA-260.** The website brief requests
One £39.99/month (Seeker + Guardian), Additional Guardian £19.99/month, Family
£99.99/month (five unique people), a planned 14-day trial and no permanent Basic
plan. Current `BUSINESS/ZYRA PRICING/ARCHIVE/ZYRA_PRICING_2026-09-24_V5.md` instead
rules One Seeker £29.99, Seeker Basic £9.99 one-time, One Guardian £19.99 and Guardian
Basic £9.99 one-time; Family unchanged and trial limited to One Seeker. The website
candidate implements its explicit brief, but cannot be published until the Founder
reconciles the public offer, app entitlements and exact trial scope. This visual
revision is not a commercial ruling or billing migration.

Existing delivery remains the documented Founder-controlled GitHub `zyra-site` →
Cloudflare Pages arrangement (`npm run build`, `dist`, Pages Functions). It was not
modified or tested through a production deployment. Before publishing, confirm
runtime/package manager, routing, security headers, exact artifact and rollback;
Founder alone performs git and gives publication GO.

## 6. Verification

Final cinematic build: PASS, two static pages; TypeScript check PASS.
Production JavaScript: **8.95KB raw / 3.11KB gzip**, no animation dependencies.
Complete browser suite: **104 checks passed**, **41 screenshots**, Chrome and
Playwright WebKit 26.5.
Four automated WCAG A/AA contexts (desktop, mobile, privacy, reduced motion) each
reported zero violations. No uncaught exceptions or third-party browser requests.
Checks include each pinned chapter at 20%/80% scroll, sticky viewport position,
motion mode switching, Experience controls, five responsive widths, 200% browser
zoom-equivalent reflow, short laptop/menu handling, no-JS and unchanged 501 response.

A separate navigation check caught an intermittent initial anchor-scroll stop
while lazy images loaded. Fixed: geometry refresh no longer removes/re-adds every
pin or restores a scroll position when top/travel/pin geometry did not change.
The final suite adds three fresh-context header-anchor regressions and passes
all 104 checks. The initial 101-check pass did not cover this regression; it is
not used to claim the original engine was defect-free.

Final `story.ts` SHA-256:
`03667e572f2b35f20c734b72354d06857364844cf05707e9d99cba766bd22bb2`.
The intermediate script is preserved as `story-before-anchor-fix.ts`; it is not
substituted for the true pre-round source archive.

Additional internal runtime probes passed: header/HUD non-overlap (minimum observed
115px horizontal gap at the measured desktop sizes), keyboard focus to a Trust link,
direct fragment load, native Back between chapter links, mode switching while reading
Memberships, dynamic reduced motion/mobile resize, and Experience selection. No
runtime exceptions. These are bounded developer probes, not external sign-off.

Fresh Lighthouse 13.4.1 **local simulated Chrome lab**, not production field data:

| Metric | Mobile | Desktop |
|---|---:|---:|
| Performance | 90 | 100 |
| Accessibility / Best practices / SEO | 100 / 100 / 100 | 100 / 100 / 100 |
| LCP | 3.3s | 0.7s |
| CLS | 0.014 | 0.012 |
| TBT | 0ms | 0ms |

No Lighthouse run warnings. The lab runs preceded the bounded navigation fix;
the full browser suite was rerun afterwards. Remaining advisory opportunities: responsive screenshot
sizing (~58KiB), font delivery and ~30ms initial geometry measurement. There is no
real-user INP dataset and no claim that mobile LCP meets 2.5s. Production performance
is not inferred from these local results.

## 7. Evidence, hashes and rollback

Current evidence root:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/zyra-cinematic-round.iJblUL/`.

- `site-before.tar.gz`: true pre-edit source snapshot, excludes `.git`, dependencies and generated outputs.
- `governance-prestate/`: true register, index and V1 handover before this round's edits.
- `file-ledger.json` / `file-ledger.md`: complete source and record pre/post hashes.
- `review/`: browser/accessibility evidence, screenshots, local Lighthouse reports and movie recording.
- `generate-social.cjs`, `record-review.cjs`, `visual-check.cjs`: bounded local evidence generators.

Pre-edit archive SHA-256:
`45f9a2133996512a23b31bb3cdd68b6d5d0692b967c932f0c2190a79eb739744`.

V1 report was archived byte-for-byte as
`ARCHIVE/ZYRA_PUBLIC_WEBSITE_REDESIGN_HANDOVER_2026-09-18_V1.md`, SHA-256
`9a96f4417520ed1fbf876b430793d8ceebd9fe3c9382e5fea27d060eca602bc1`.

Previous evidence `zyra-website-redesign.ecE5kb/` remains intact, including the
original pre-redesign site archive, full app-capture provenance and first-round QA.
No reconstructed files are used as pre-state audit anchors.

Rollback: extract the archive into a new scratch folder, compare hashes against
subsequent edits and restore only the affected files while preserving new candidates.
Do not reset the repository or overwrite unrelated work. Public rollback is not
required because nothing was deployed. The OA remains awaiting Founder review.

## 8. Founder handoff

Review the local desktop scroll pacing and purple/gold direction. The read-without-
motion option and narrow-screen flow are intentional accessibility alternatives.
This report does not close OA-ZYRA-260 or approve publication. Existing incidental
app defect OA-ZYRA-297 from the V1 capture audit is unchanged and not duplicated.
