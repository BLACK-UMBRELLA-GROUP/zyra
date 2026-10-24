# 134 — CODEX → FOUNDER — Personal-Code Full-Height Layout Installed

**Date:** 2026-09-17  
**Programme:** OA-ZYRA-286 / OA-ZYRA-289

## Outcome

The shared Add Guardian/Add Seeker page now fills the available viewport with
three balanced zones: the code/share area, the divider, and Scan/Enter. The
code card, Copy/QR/Share row and Scan/Enter targets are taller. QR expansion,
requests, errors and small screens remain scroll-safe.

This is UI-only. Demo codes remain local Founder-preview fixtures and real
members remain on the existing live IDV-gated service.

## Verification

- focused tests: 16/16 PASS;
- focused analyzer: PASS, no issues;
- signed profile build: PASS, 35.1 MB;
- install inventory: one ZYRA, `app.zyraconnect.zyra`, 1.0.0 (2);
- device launch: PASS;
- Supabase, migrations, TestFlight, App Store and git: untouched.

## True pre-state

| File | Pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/wali/zyra_code_screen.dart` | `7d24899f3516d399e463d2c60ccd2993bcd3de3da78f2fe291a6a4cbba334a5f` | `c885c6520ca2484cdd52aabc4710d10e9ac97f34e31f50561b1faaec7dcae3b3` |

Built executable SHA-256:
`d5fd2d4384ab41d045721c03b59de0e6ffb57749e0168f03a039e79aa76a66c9`.

Governance-document pre-hashes were captured at edit time:

- Outstanding Actions: `9cd01076675531a6171862fb7ceb7fd55f6174ad5d0dfc522d4c26a7dce2a5ee`
- personal-code handover: `b303432fd43fb3569042c1d3fc14218e651a07490316fc4ca7d9453827e9febc`
- documentation index: `8c60f837905a85519f4ffec1e2b32b1a2c10490d45302daa241577309e89a028`
