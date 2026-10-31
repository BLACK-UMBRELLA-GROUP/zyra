---
id: DOC-ZYRA-0337
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 14 - app colours Ivory (planned app, icon, launch, splash)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — APP COLOURS (IVORY) — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build **after** queue lines 29–32, 37, 38, 26 and 40 (40 replaces 27)
(their layouts land first, in Plum) and **before** lines 43 (My ZYRA) and 44 (developer toggles). Queue line **42** replaces line 39, which stopped in preflight on the gold-button contrast (3.97 : 1); spec V4 fixes it.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V5**: floating look + traffic-light dot colours + gold fill `#C08A3A` for gold buttons, pills and badges with text + small gold text `#845F24`) and the 14 `../MASTERS/` pictures |
| 2 | Theme: make the colour table the app's colour tokens (`theme/zyra_colors.dart` and the shared widgets/styles), so every planned-app screen takes the new colours from one place. Replace hard-coded Plum/lilac/white-text values in the planned app with those tokens. Add the floating-look shadow as one shared surface style and use it on every floating surface the spec lists; make scroll areas leave room so shadows never end in a hard line. No layout, size or wording changes |
| 3 | Default and only background = Ivory. Remove the Background picker from Profile → Appearance & haptics; ignore saved palette preferences without deleting member data. Keep haptics and the Gold accents switch |
| 4 | Text on photos stays white on the dark fade (Profiles photo pages, Journey cards) |
| 5 | Icon: regenerate `ios/Runner/Assets.xcassets/AppIcon.appiconset` (all sizes) and `assets/icon/icon.png` + `android_adaptive_foreground.png` from today's icon source, changing only colours to the spec (c11 is a colour reference). Launch: `LaunchBackground` `#FBF7F0`, `splash_logo.png`/`LaunchImage` in `#A9792E` (c13). App splash per c12 |
| 6 | Tests: golden/screenshot checks of the ten c01–c10 states and c14 (a partner-preference question with one green, one gold and one red answer) match the masters; `positiveGreen`/`negativeRed`/traffic-light gold use the V3 values; every gold fill that carries text uses `#C08A3A` with `#2B2420` text (contrast ≥ 4.5 : 1); every gold text below large size uses `#845F24` (≥ 4.5 : 1 on every Ivory background); no purple/lilac colour value left in the planned app (search for the old hex values in the table); contrast check on body and secondary text; no clipped shadow edges on any page; Larger Text and Increase Contrast. Analyser clean |
| 7 | Render c01–c10, c14, the splash and the launch screen into `APP_COLOURS/BUILT/` (430 × 932 @3x) and the 1024 icon, plus master-beside-build pictures |
| 8 | Task note (include which old colour values were replaced, and files moved to `~/_to_delete/`), commit within core rule 2, mark the queue line BUILT or FAILED |
