# 026 — CODEX → FABLE — 2026-08-29 — BRAND AVATAR DESIGN OPTIONS COMPLETE

## 1. Status and authority

**Authority:** Founder-directed design round · OA-ZYRA-279 ·
`025_FABLE-CODEX_2026-08-29_BRAND_AVATAR_DESIGN_ROUND.md`.

**Verdict:** four static + animated ZYRA avatar directions are complete in
`SYSTEM/RESOURCES/BRAND/`. **FOUNDER DESIGN SELECTION PENDING.** Fable owns
the later Google Workspace upload.

No app source, application icon, git state, migration, Apple/Google/Supabase
configuration or production account was changed.

## 2. Design options

| Option | Intent | Static / animation |
|---|---|---|
| A — True Gold Comet | Safest continuity option: the existing moving-comet idea, corrected to true ZYRA gold with a slower sweep and long professional rest | One gold-only comet; 11 frames; 3.71s cycle |
| B — Soft Gold Bloom | Calmest and most premium: a centred Gold Horizon bloom gently breathes without reading as pending/loading | Centred bloom; 8 frames; 3.78s cycle |
| C — Centre Draw | Strongest brand/app-motion link: the complete gold horizon quietly redraws from its centre, then rests | Small centre origin; 9 frames; 3.83s cycle |
| D — Gold Wake | Dot-free alternative: a narrow highlight travels along an always-present horizon and dissolves | No discrete dot; 10 frames; 3.60s cycle |

**Codex recommendation:** Founder should compare **B** and **C** first. A is
the direct-continuity fallback; D is the cleanest option if the dot itself is
the concern.

## 3. Files and hashes

| File | SHA-256 |
|---|---|
| `SYSTEM/RESOURCES/BRAND/zyra_avatar_option_a_true_gold_comet_static.png` | `8c1cb3d50ae2ecd4044258963d68f27dbbebc748f1386583a62337fad004312c` |
| `SYSTEM/RESOURCES/BRAND/zyra_avatar_option_a_true_gold_comet_animated.gif` | `530e553ae7749e1d2d78fbbc834a437a35d8de8e40888ce2fc6f00941f6de708` |
| `SYSTEM/RESOURCES/BRAND/zyra_avatar_option_b_soft_gold_bloom_static.png` | `b63ac91d45d128d1374ae956a88dc52bb19c64a58ffc34e2550e0ebf6bf87475` |
| `SYSTEM/RESOURCES/BRAND/zyra_avatar_option_b_soft_gold_bloom_animated.gif` | `05ff9c3f4fbfcb0c932a344fed7f564a3c290dcca283c431dc1e2f05acf96de8` |
| `SYSTEM/RESOURCES/BRAND/zyra_avatar_option_c_centre_draw_static.png` | `12f57b1ab099f3d52d60af23260947a4830ba02237299e17441a472130732e76` |
| `SYSTEM/RESOURCES/BRAND/zyra_avatar_option_c_centre_draw_animated.gif` | `5a44639af48ef7743bfafca1d8c538d4870b4cf017cf232400763602d98f0bec` |
| `SYSTEM/RESOURCES/BRAND/zyra_avatar_option_d_gold_wake_static.png` | `2c5f4571f031dbedc9858703a5b631c067e38392305df4bdbf371cfb461ca3ae` |
| `SYSTEM/RESOURCES/BRAND/zyra_avatar_option_d_gold_wake_animated.gif` | `cc46d4aa51d3d122aca8574f4669a74739c1a26eef7e4bac0ad7d75e73922693` |
| `SYSTEM/RESOURCES/BRAND/zyra_avatar_design_round_preview.png` | `cbdc76732a6886f6b6ac82234929fc848567b7b6df734f755721865f38820e92` |

The two Fable source assets remain byte-unchanged:

- `zyra_avatar_static.png` —
  `6878b42940c26052a527773a7f68a50c22e82334bf09cb6988d1e3ec6bd557bb`
- `zyra_avatar_animated.gif` —
  `4c1cce4432a0ff676dd9c0ef401994ce55bcb93a32f58249143d1a1e2ab6e98b`

This handover's own hash is reported after writing to avoid a self-reference.

## 4. Measured validation

| Check | Result |
|---|---|
| Static geometry | PASS — every PNG is 512×512 |
| Animation geometry | PASS — every GIF is GIF89a, 512×512, looping |
| Frozen Google frame | PASS — decoded GIF frame 1 is byte-identical to its paired static PNG for all four options |
| Brand colour ceiling | PASS — the horizon/comet region never exceeds RGB `232,201,138` (`#E8C98A`); no white/cream comet core remains |
| Circle crop | PASS — all four inspected at actual 28px, 32px and 40px circular crops; wordmark and horizon remain inside the crop |
| Motion review | PASS — key frames inspected across every cycle; first/static frame holds 1.75–1.90s before subtle motion |
| File size | PASS — static files 19–20KB; animated files 67–78KB (source GIF was 1.16MB) |
| Original assets | PASS — both source hashes unchanged |

## 5. Design method and image-generation trace

The built-in image-generation workflow was used for three precise-object-edit
studies before final production:

1. **True Gold Comet:** preserve the exact wordmark/background; change only
   the horizon/comet to `#E8C98A`, remove the white core, strengthen small-size
   legibility.
2. **Soft Gold Bloom:** preserve the exact wordmark/background; replace the
   travelling white-warm dot with one restrained centred `#E8C98A` bloom.
3. **Gold Horizon Draw:** preserve the exact wordmark/background; use a
   complete true-gold line with a precise centre origin for a draw animation.

Those generated studies were treated as design exploration, not canonical
brand pixels: they subtly altered the wordmark/background and were therefore
discarded. The shipped options were reconstructed from Fable's original
static pixels, changing only the horizon region. This preserves the exact
existing wordmark and Midnight Plum field while applying the approved concept
directions and exact colour token. Option D extends the same governed horizon
element without adding a new symbol.

## 6. Current decision boundary

- All four are proposals; none is declared the new authoritative avatar yet.
- Founder selects A, B, C or D.
- After selection, Fable uploads the paired animated GIF to Google Workspace;
  the paired PNG remains the canonical frozen/static reference.
- Rejected options can then be archived without ambiguity.

— END —
