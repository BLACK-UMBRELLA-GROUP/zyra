---
id: DOC-ZYRA-0339
type: DECISION
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: LOCK record for LOCK 14 - ZYRA app colours (Ivory, gold, warm neutrals; matching icon and splash; no member colour choice)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# LOCK RECORD — APP COLOURS

| Date | Founder's words | What it locks |
|---|---|---|
| 2026-10-30 14:24 | "now give some colour options for backgroudn of app i dunno is purple is the one anymore but i could be wrong. most apps use white but lets see some options" | Six backgrounds in the prototype (V77) |
| 2026-10-30 14:33 | "let say we choose ivory - is out secndry accents still plunm and gold cos im still seeing some purple" | "Ivory · no purple" variant (V78) |
| 2026-10-30 ~14:40 | "how does it change the app icon and splash screen then" → icon/splash picture | — |
| 2026-10-30 ~14:45 | Clickable: background **"Ivory · no purple"**; icon and splash **"Match the app"**; member colour choice **"Ivory only (Recommended)"** | **LOCK** of `RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V1.md` and the 13 `MASTERS/` (prototype V79). Replaces Midnight Plum (DR-ZYRA-276 colour; Floating Glass style kept) |
| 2026-10-30 18:06–18:15 | Comment on the tab bar: **"lets see how this looks with it loking similiar to background so it looks floating if that makes sensw"** (V80) · **"do it for everything thats white and seperated in colour if that makes sense"** (V81) · **"is it for all pages check caarefullt cos look atgaurdian page for exampel i see this dark shadow line that i dont like look for example at the edge fo active i can see a line"** → clipped shadow edges fixed and every page checked (V82) → **"LOCK it (Recommended)"** | **LOCK V2**: floating look; `RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V2.md`, c01–c10 re-rendered (V82). V1 in `ARCHIVE/` |
| 2026-10-30 (evening) | Comment on the Filters link: **"make sure this button leads me to the page im seeing on actual app so we can edit that"** → Green / Yellow / Red pages in the prototype (V86); dot colours on Ivory missing from the table → clickable **"Muted green + red (Recommended)"** → **"LOCK it (Recommended)"** | **LOCK V3**: traffic-light dot colours added to the colour table; `RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V3.md`, new master `MASTERS/c14_traffic_light_dots.png`. V2 in `ARCHIVE/` |
| 2026-10-31 ~06:50 | Founder relayed Fable: "Ivory gold buttons fail contrast (3.97 vs 4.5). Show me options and I'll LOCK one." → five options in the prototype (V92–V94) → clickable **"1 · Brighter gold (Recommended)"** | **LOCK V4**: gold fills with text `#C08A3A` + `#2B2420` (5.0 : 1); `RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V4.md`; c08 and c14 re-rendered (V3 spec and pictures in `ARCHIVE/`) |
| 2026-10-31 ~07:15 | Small gold text measured 3.1–3.6 : 1 → side-by-side pictures + prototype switch (V96) → clickable **"Deeper gold (Recommended)"** | **LOCK V5**: small gold text `#845F24`; accent `#A9792E` stays for icons, lines, outlines and large text; `RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V5.md`; c01, c02, c05–c10 re-rendered (V4 spec and pictures in `ARCHIVE/`) |
| 2026-10-31 ~15:35 | Line 42 build shows the ‹ · label · › bottom pill gold-filled on the Journey tab and Filters; masters show it ivory → clickable **"Light, as the masters (Recommended)"** | Confirms the LOCK 14 V5 masters: the bottom pill is ivory on every page, never gold-filled. Fix is queue line 71 |

Pictures showing sample photos moved to the private group folder 9 Nov 2026 (OA-AIOS-430); recaptured with placeholders when ZYRA restarts.
| 2026-11-10 ~15:15 | Codex QUESTIONS row 21 (line 73): small danger text `#B84A42` measures 4.14 : 1 (< 4.5) → prototype switch "Small red text (Q21)" (V143) → clickable **"Deeper red #AC453E (Recommended)"** | **LOCK V6**: small danger text `#AC453E` (4.6 : 1); `#B84A42` stays for icons, outlines, dots and large text. Spec `APP_COLOURS_SPEC_CURRENT_VERSION_V6.md`; built by queue line 75 step 7 |
| 2026-11-11 13:37 | Founder: "becaus eof our cream colour on the iphone the actual phones top bar- time-wifi-battery isnt clearly visable. is that our issue that cant be changed and suggest a solution" | **No new LOCK — build fix under LOCK 14 V6**: the shell still asked iOS for white status-bar content (left from Plum). Dark status-bar content on every Ivory screen; light only over photos / the dark photo fade. Queue line 77 step 5 |
| 2026-11-11 21:48–21:52 | Settings screenshot: "Remove this darker colour everywhere it is in app" → prototype V185 → **"LOCK it app-wide (Recommended)"** | **APP COLOURS V8**: no surface darker than the background; ivory floating fill everywhere; dark tints only for dividers, dim layer, handles, tracks, inactive dots. Queue line 83 |
