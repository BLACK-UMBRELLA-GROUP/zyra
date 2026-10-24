# 136 — CODEX → FOUNDER — Personal-Code Surfaces Fill Screen

**Date:** 2026-09-17  
**Programme:** OA-ZYRA-286 / OA-ZYRA-289

The default Add Guardian/Add Seeker page now fills the available height using
the UI surfaces themselves: a large feature code card, taller sharing buttons,
and two expanded Scan/Enter actions. Internal gaps remain compact. QR,
requests, errors and short screens retain the scroll-safe layout.

- focused tests: 16/16 PASS;
- analyzer: PASS;
- signed profile build/install/launch: PASS;
- inventory: one `app.zyraconnect.zyra`, 1.0.0 (2);
- Supabase, migrations, TestFlight, App Store and git: untouched.

| File | Pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/wali/zyra_code_screen.dart` | `4ae5ef2d7f76cda1f147647c9f9f04a88f42f4dbf7c1bdab4975cb14d20011d6` | `bd88108d1d4add714c4a58fc5b59049c2cdaa279709af0c9d3e350388297e2be` |

Built executable SHA-256:
`f7d49a33a2bec0d70cc63cfb140dc763b74bfe072195d6969edd55f6f2a4d63a`.

Governance pre-hashes captured at edit time:

- Outstanding Actions: `f617d661d1ceab6ad651ec298a1cfd2e989a2b7ab1c0ee2d90a72b24d4b363d5`
- personal-code handover: `17ba64b97132bc737068d71ca416e037c86be4357072d0c3e3afde6079eabd4e`
- documentation index: `db1ffaf9b29e9ea86f11195df035821f83da83b42c0738e4087915e320fa6e90`
