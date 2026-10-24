# 002 · FABLE → CODEX · 2026-08-25 · Website — full update and design handover to you

**Register:** OA-ZYRA-260
**Founder instruction (2026-08-25):** Codex is to **give his own design and take over the design of the website**. This message is the update and handover that instruction asked me to send you.

---

## 1 · What is live right now

`zyraconnect.app` is serving **DRAFT 3.1 — "Daylight interactive · Midnight Plum"** (Founder pushed commit `a5b1e37`, 2026-08-25; I verified the deployed stylesheet and page live after each push). It is a scroll-driven single page: pinned full-viewport scenes whose content changes as the user scrolls, on the app's Midnight Plum gradient with glass cards.

## 2 · Design history — what the Founder asked for at each step

| Draft | Founder direction (his intent, faithfully) | Outcome |
|---|---|---|
| 1 | Original site | Dark purple/gold. **Approved 2026-08-20.** In git history. |
| 2 | "Make my website design look like **Daylight**" (daylightcomputer.com, found via Mobbin; I captured the language via Chrome) | Warm-paper static interpretation: editorial serif + italic gold, floating cards, marigold CTAs. **Rejected — too static.** |
| 3 | "I wanted it to feel **interactive where user scrolls and pages change** — I don't want a static website… mock/stock images are OK for layout" | Scroll-driven rebuild. Deployed 2026-08-25. |
| 3.1 | "Update the background to match the app's current **Midnight Plum** theme — `linear-gradient(180deg,#684D78 0%,#241A2C 100%)` — apply consistently, verify text/cards/buttons/glass stay readable" | Full dark conversion. **Live now.** |

So the Founder's standing taste signals for your design: **Daylight-style editorial quality, genuinely scroll-interactive ("pages change as you scroll"), skinned in the app's Midnight Plum with gold**, calm and premium. He iterates by looking at deployed builds on his devices and reacts fast.

## 3 · What Draft 3.1 actually contains (as-built)

- **Scenes** (each a tall scroll track with a sticky 100svh stage): hero with load-time word cascade that lifts away on scroll → "how" section as a 3-card deck that deals itself → 8-stage journey: pinned CSS-drawn phone whose mock app screens change per stage, stage rail with filling gold line, big serif stage name + 01/08 counter → manifesto with scroll-scrubbed word-by-word reveal → rising final CTA → footer.
- **Engine:** hand-rolled vanilla JS in `Base.astro` (`is:inline`), no libraries/CDNs. Writes scene progress to a `--p` CSS custom property; stepped scenes fire discrete state changes. rAF-throttled; culling with a full first pass.
- **Progressive enhancement:** all machinery lives under `html.js`; with no JS or `prefers-reduced-motion` the page is a normal static document. Please preserve this property (or consciously replace it) in your design.
- **Phone mock screens are CSS placeholders** — Founder-approved as mocks; intended to be replaced with real app screenshots later.
- **Theme:** tokens in `global.css` — plum gradient fixed per-viewport, cream ink, glass (`backdrop-filter`) nav/brandchip/waitlist/deck cards, gold `#e9a83c`/`#d3922b` accents, Source Serif 4 + Inter (Google Fonts).
- **Readability verification:** I rendered the built page headless (Chromium/Playwright) at desktop 1440×900 and mobile 390×844 across ~11 scroll positions per width and visually checked every scene after each design pass. Recommend you keep some form of this; it composes naturally with your visual-gate discipline if you choose to extend it to SITE (not currently wired — SOURCE-only today).

## 4 · Stack and pipeline

- Astro ^5 static site in `ZYRA/SITE/` — its own git repo → GitHub `ZYRA-APP-LAB/zyra-site` → **Cloudflare Pages auto-deploys on push to main**. Build `npm run build`, output `dist/`.
- **Agents never run git** (standing law). The Founder deploys from his Terminal; give him one-line commands. Local preview: `npm run dev`.
- Files: `src/pages/index.astro` (all copy + scene markup) · `src/pages/privacy.astro` · `src/layouts/Base.astro` (head, fonts, theme-color `#684d78`, the scroll engine) · `src/components/Nav.astro` (floating brandchip + nav card) · `src/components/WaitlistForm.astro` · `src/styles/global.css` (**the whole design language**) · `functions/api/waitlist.js` (**returns 501 — D1 waitlist backend not built yet**; the form degrades to a `hello@zyraconnect.app` mailto message; this backend round stays with me unless the Founder says otherwise) · `README.md` (**design-of-record — keep it current**).

## 5 · Constraints that bind whatever you design

1. **Copy is Founder-approved verbatim** — hero h1/sub, band lines, the three "how" cards, the eight stage names, jnote, manifesto quote + attribution, "Be first / Your journey begins soon.", footer. Reuse exactly; changes need Founder approval.
2. Privacy page must stay reachable (waitlist promise) and its "no advertising trackers, no marketing cookies" statement binds any analytics you add.
3. Keep a no-JS/reduced-motion fallback that still reads as a complete page.
4. Waitlist form posts to `/api/waitlist` — don't break the degradation path while the backend is 501.
5. README design-of-record updated with your design; Drafts 1–3.1 stay in git history as the archive.
6. Founder approves designs on his devices — plan for a preview he can open (I've been sending single-file renders with CSS inlined from `dist/`; technique yours if useful).

## 6 · The ask (Founder instruction)

1. **Produce your own website design** — concept + rationale, in the direction signals of §2, and present it to the Founder for approval.
2. **Take over website design ownership** from me on his approval of your concept (or immediately for iteration work if he says so). I remain on ops: DNS/Cloudflare estate, the D1 waitlist backend round, and documentation.
3. File your handovers per `IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V1.md` as usual; OA-ZYRA-260 tracks this transfer.

Reply here (`## REPLY`) or file 003 with your design direction and anything you need from me — happy to hand over the Playwright sweep script, the preview-inlining snippet, or anything else.

— Fable
