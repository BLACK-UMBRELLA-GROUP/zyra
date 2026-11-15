---
id: DOC-ZYRA-0450
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 28 - one confirm sheet for every "Are you sure?" in the app
links: [AD-AIOS-115]
owner: ZYRA chat
---

# APP CONFIRM — SPEC — V1 (LOCKED 11 NOV 2026)

**Founder, 11 Nov (iPhone, Guardian → Omar → Cancel invitation):** "This design isnt nice make it different pleade" + "And the buttons dont even work" → prototype V184 (A bottom sheet / B small centred card) → clickable **"A · Bottom sheet, like the ••• menu (Recommended)"** + **"Yes, every confirm (Recommended)"**. Reference: prototype copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V194.html` (Guardian → Omar → Cancel invitation; Guardian ••• → Remove / Remove as Main Guardian; Profiles ••• → Hide). No masters (charter rule 13).

| Item | Rule |
|---|---|
| What | **Every** "Are you sure?" in the app (cancel invitation, remove a Guardian, remove as Main Guardian, hide a profile, end a Journey, block, decline, sign out of a device, and any future one) uses this one sheet. No centred dialogs, no full-height dialogs |
| Layout | Bottom sheet that **hugs its content** (never taller than needed, no empty space): fill `#F7F2EA`, top corners 26, shadow up (0 −10 30, 18 %), dim layer behind (`rgba(30,22,16,.38)`, tap = keep). Grab handle 40 × 4. Gold-ring monogram 56 (the person's initial; a matching icon when there is no person). Title 21 light, centred, as a question naming the person ("Cancel Omar’s invitation?"). One or two short lines, 12.5 muted, saying what happens and what stays possible |
| Buttons | Full-width **danger row** (thin divider above, 52 high, text `#AC453E`, the action words, e.g. "Cancel invitation", "Remove Hassan", "Hide profile") then a full-width **ivory pill** to keep (52, fill `#FBF7F0`, thin border, soft shadow, muted text: "Keep invitation", "Keep Hassan", "Keep profile") |
| Must work | Both buttons and the dim layer **must do their job**: the action runs and the sheet closes (toast confirms, the item disappears / changes at once); keep closes and changes nothing. Tested on every confirm |
| Accessibility | VoiceOver reads the title first; the danger button says what it does; Escape / swipe down = keep; Reduce Motion: no slide |
| Words today | Cancel invitation: "Cancel Omar’s invitation?" · "Omar won’t be able to accept it. You can invite him again at any time." · Remove: "Remove Hassan?" · "Hassan loses all access to your Journeys and the Guardian Circle. You can invite Hassan again later." · Main: "Remove Hassan as Main Guardian?" · "Without a Main Guardian no Journey can move on. You can choose a new Main Guardian at any time." · Hide: "Hide Sara?" · "Sara won’t appear in your Profiles again. You can show her again from Settings → Hidden Profiles." Other confirms keep today's meaning in this layout |

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-11-11 | V1 | First version |
