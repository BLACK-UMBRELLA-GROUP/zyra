# 142 — CODEX → FOUNDER

**Date:** 2026-09-18  
**Subject:** OA-ZYRA-294 optional Main Guardian client installed; enforcement staged  
**State:** CLIENT BUILT · DEVICE INSTALLED · MIGRATION STAGED ONLY  
**Production / Git / TestFlight / App Store:** untouched

## 1. Founder ruling implemented

- Main action now says **Remove as Main Guardian** and demotes without
  unlinking.
- Make Main Guardian, Remove as Main Guardian and Remove Guardian all replace
  the original pill in place with equal **Cancel** and **Confirm** pills.
- No dialog, expanding warning or automatic replacement remains.
- A linked family with no Main produces **Choose a Main Guardian** in My ZYRA
  Now and routes to Guardian.
- Active Journey content fails closed while either Seeker lacks a Main;
  Pause and End remain available.

## 2. Client delivery

The signed Founder profile build was built, installed as the sole
`app.zyraconnect.zyra` app on the Founder iPhone and launched successfully.
Version remains `1.0.0 (2)`. No TestFlight upload occurred.

Focused verification: **160/160 PASS**. `flutter analyze`: **PASS**, no issues.
The legacy visual baseline run remains red because approved pixels preserve
superseded screens; no approved baseline was regenerated in this round.

## 3. Staged server boundary

Migration:

`20260918140508_oa294_main_guardian_optional_journey_hold.sql`

SHA-256:

`67683db6045e42e2ae691321b8a35676913c69433392276a07551138dbc8004b`

It contains caller-bound demotion/removal RPCs, a two-side boolean Journey
gate, explicit ACLs, empty search paths and trigger enforcement for current
ordinary Journey writes. Message writes resolve through the authoritative
conversation → attempt → match chain; potential/ended records are excluded;
resumption is held while Pause and End remain possible.

**It has not been applied.** Next gates are isolated PostgreSQL 17 replay,
direct-call/write-surface verification, security review and a separate exact
file/hash Founder apply GO.

## 4. True pre/post hashes

| File | Pre SHA-256 | Post SHA-256 |
|---|---|---|
| `lib/screens/wali/seeker_guardian_designs.dart` | `1b206c945e139da93ee99b70cf6f3ce4c002407938bfaf29b7ac47c847087f13` | `6939b6faee03775d7b13da556e079195a3d1a66980fb9aa60a0b6849a65a106d` |
| `lib/screens/wali/seeker_wali_tab.dart` | `2614e126d254deb3d4ec78eea04a8794ddfec779096097f0a44bb2c9fb648676` | `33265daaf86e8c770072de4906d18c162917ab3384320e80a5a3d40e08a763c4` |
| `lib/services/zyra_wali_link_service.dart` | `15e808fd6b6825440ee8190030074152ad581a7294c16319e3d50502967a6841` | `997cfa861d2f82220f598c600a8fe2183ce196bd87d5804cc44e211dcab26174` |
| `lib/services/zyra_dashboard_adapter.dart` | `555f6c8992444ed48551f98472cd5ca8189d41c70cca09f5caa56e803d769559` | `7e75ddea0ca5e23e7b7a0802f704c4aa2e2a93c18aaf4cfddc4d04794caa96a1` |
| `lib/models/zyra_supportive_dashboard.dart` | `457fc9feda6cd26d8927cf76ab891ad7978be69b214ff5aaab290d5777f5941a` | `2b4adaf457d7e0c8e3189952412e291129a17425b1715d24b0817bbce64d53d7` |
| `lib/screens/journey/journey_flow_screen.dart` | `230fbcf96cff9f3dbb9a34a18fec6c7db3407ea291cf5e0fb208c80474f78f57` | `181878fcae4b30c0ca8bd2102646f399ceb577011a76a51dd7d3849fa596b11d` |
| `lib/screens/connections/connections_screen.dart` | `ccd3dc97e4b8435a8c78ee4edb2eb49802fca0a4a0efe443f0d5d8a2d8d047af` | `93097c12bcc84c0f9fe5110ca54cb16db527feb6ba3bcdf4605d72481fac5b13` |
| `lib/screens/home/home_shell.dart` | `f40ec668aa8f417101526ae27099544ce57fb169cc4a15491df7f473966358d1` | `88193bef6a78ae89cda845f0ee724add23b03a125aa4a4bd327d13193b75fa97` |
| staged migration | new | `67683db6045e42e2ae691321b8a35676913c69433392276a07551138dbc8004b` |

The quiet Insights locked-state copy was also corrected to remove a stale
commercial teaser; its post hash is
`29fb1cb77188a99015deca2afbe3a203fa9f7f2950358911357f7cbd4bc00f3f`.
