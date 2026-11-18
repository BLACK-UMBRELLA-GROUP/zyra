# FIX BRIEF — ONE SHEET SIZE FOR ••• MENUS AND THEIR CONFIRMS — 18 NOV 2026

Founder, 18 Nov 18:16 (iPhone, Guardian page): "clicking the 3 dots gives me optoin make as maing guridan or remove … the text seems small and comparing it to when i actually press for exmapel make as main guridan another pop up exactly from bottom sppears but this time its differnt size inc size text … i need those unifed" → clarified: "i dont mind 3 dots but waht i mean if i click it and if i choose a option a new sheet shows but text and box is alrger so its not unified".

A fix (AD-AIOS-149): flow and wording unchanged. The ••• menu still opens a sheet; choosing an option still opens the confirm sheet (LOCK 28). Only sizes change.

## Problem (from code)
- The Guardian ••• menu sheet (`lib/dev/zyra_one_journey_guardian_cards.dart`, menu around lines 360–420, actions from `zyraGuardianCardManageActions`) uses its own container (padding 18/11, 4 pt handle, 12 pt body text).
- The confirm sheet (`lib/widgets/zyra_confirm_sheet.dart`, `ZyraIvorySheet`) is wider/taller with 24 / 21 pt headings, 56 pt buttons and its own padding.
So the second sheet looks larger than the first.

## Change (app-wide, every ••• menu that leads to a confirm)
1. The ••• menu sheet uses the **same container as the confirm sheet**: `ZyraIvorySheet` (same side margins, corner radius, handle, top padding and `bottomPadding`, same fill from line 114).
2. Its top line (e.g. "Hassan · Guardian") uses the confirm sheet's small top line style.
3. Each option is a **56 pt row** using the **same text style and size as the confirm sheet's buttons**; a destructive option (Remove …) uses the confirm sheet's red.
4. Cancel uses the confirm sheet's secondary button style.
5. Apply to the Guardian ••• menu and every other ••• or long-press menu sheet in the Founder preview and the member app that opens a LOCK 28 confirm (list each in the as-built record).

## Checks
- Open ••• then Make Main Guardian on the iPhone: the two sheets have the same width, corners, handle and text sizes; only the content changes.
- Text in the menu is no smaller than the confirm's button text.
- No wording, order or flow change. Tests and goldens updated; no new failures.
