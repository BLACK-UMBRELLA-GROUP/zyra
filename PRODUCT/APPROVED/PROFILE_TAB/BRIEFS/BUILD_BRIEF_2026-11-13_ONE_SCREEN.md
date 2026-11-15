# BUILD BRIEF — PROFILE ON ONE SCREEN (PROFILE_TAB V5) — 13 NOV 2026

Spec: `PRODUCT/APPROVED/PROFILE_TAB/RECORD/PROFILE_TAB_SPEC_CURRENT_VERSION_V5.md` §8. Prototype: `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V229.html` (Profile tab, Seeker and Guardian; V228 archived 14 Nov).
Masters (copy exactly): `PRODUCT/APPROVED/PROFILE_TAB/MASTERS/p11_seeker_one__one_screen.png`, `p12_seeker_basic__one_screen.png`, `p13_guardian_one__one_screen.png`, `p14_guardian_basic__one_screen.png`, `p15_seeker_one__small_phone_top.png`, `p15_seeker_one__small_phone_end.png`, `p16_guardian_one__small_phone_top.png`, `p16_guardian_one__small_phone_end.png` (spec §8 lists the measurements). Header buttons Preview · Edit · Switch are all 34 pt high (44 pt tap area).

## Build
1. Seeker and Guardian Profile tabs: header in a row (84 pt photo or monogram on the left; name, plan line, buttons on the right) per §8.
2. Rows become one line. Remove the description lines; show only the short right-hand values listed in §8.
3. Lay the groups out to fill the space between the header and the nav bar: rows share the spare height evenly (minimum 44 pt each), 12 pt between groups, last group 16 pt above the nav bar (LOCK 24). No scrolling and no bounce when it fits (LOCK 26 V4, line 113).
4. If it cannot fit at the minimum row height, scroll, with bottom padding so Sign out stops above the nav bar.
5. Use the shared card surface from line 114.

## Checks
- On the Founder's iPhone: the whole Profile, Sign out included, is visible above the nav bar; dragging does not move it; no empty band above the nav bar.
- iPhone SE size: scrolls and Sign out stops above the nav bar.
- Long names end with "…" on one line.
- Tests and goldens updated; no new failures.
