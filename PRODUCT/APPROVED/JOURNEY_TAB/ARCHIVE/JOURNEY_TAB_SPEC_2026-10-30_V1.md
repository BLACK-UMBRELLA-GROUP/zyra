---
id: TBC (Fable assigns)
type: SPEC
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 13 - Seeker Journey tab (swipe cards, one per Journey place)
links: [DOC-ZYRA-0283, DR-ZYRA-277, AD-AIOS-115]
owner: ZYRA chat
---

# JOURNEY TAB — SPEC — V1 (LOCKED 30 OCT 2026)

Masters (430 × 932 @3x, prototype V73) in `../MASTERS/`: j01 `one__no_journey`, j02 `one__journey_sara`, j03 `one__journey_aisha`,
j04 `one__free_place`, j05 `one__three_journeys_maryam`, j06 `basic__no_journey`, j07 `basic__journey_sara`.
Replaces today's Journey tab (three "Awaiting a Journey" boxes / Journey list cards). The pages it opens (the Journey page and the
Journey options page) are **not** changed.

| Item | Rule |
|---|---|
| Header | Title "Journey". Gold **•••** top-right (same as Profiles) **only while the card shown is a Journey** → opens today's Journey options page for that Journey (View Profile, Timeline, Journey Bio, Compatibility score, Guardians, Report, End Journey) |
| Dots | Under the title, one dot per **place**: Seeker One 3, Seeker Basic 1. Current = long gold pill (as Profiles) |
| Journey card | Fills all the space between the dots and the bottom pill (**no dead space**). Radius 22, gold border at 60%. The other person's **main photo** full-bleed; dark fade on the lower 70%; on it, bottom-left: gold stage line "Stage 4 of 8 · Faith & Values" (12.5), **first name** 30 light, "27 · Birmingham" 15, an **8-segment progress bar** (gold up to the current stage, 4 high, 3 apart), and the **next-step line** (12, muted) |
| Next-step line | Family Review open → "Family Review · N hours left"; this member's move → "Your turn: <action>" (Salam Exchange: send Salam · Compatibility reveal: choose to reveal · Guardian gate: add your Main Guardian · question stages: answer <stage name> · Family stage: answer Family Compatibility · Conversation: open the conversation); otherwise "Waiting for <first name>" |
| Order | Journeys first (most recent activity first), then free places |
| Free place card | Same size, dashed border, centred: dashed gold circle with +, "Free place", "When you and someone both agree, your Journey starts here.", gold-outline **Browse profiles** (→ Profiles tab) |
| Moving | Swipe left / right on the card, or the arrows in the bottom pill. No loop; ‹ disabled on the first card, › on the last |
| Bottom pill | The Profiles request pill (LOCK 7): **‹ · Continue Journey · ›**; on a free place the middle reads **Browse profiles** (gold). Continue Journey → today's Journey page at its current stage |
| No Journey (j01, j06) | Centred in the space: Journey icon (the tab's two-person icon) in a 64 gold ring, "No Journey yet" (22 light), "You have 3 places. Send a Journey request from Profiles to begin." (Basic: "You have 1 place."), gold **Browse profiles** (52). No dots, no pill |
| **Seeker Basic** (j06, j07) | One place (one dot). Under the card / empty state: dashed upsell card — lock icon, "More Journeys come with Seeker One", "Up to 3 at once.", gold "See Seeker One ›" → Plans. The Journey card shrinks to leave room for it |
| Never | No hearts anywhere; no counts of other members; no distances |
| Accessibility | Card announced "Journey with Sara, stage 4 of 8, Faith & Values, Family Review 41 hours left, 1 of 3"; arrows are the swipe equivalents; Larger Text wraps the text block upward, never clips |
| Data | Preview: the existing sample Journeys and their stages (Sara / Aisha / Maryam in the masters are samples). Server: Journeys, stages, Family Review timers as built (DOC-ZYRA-0329 for the gaps) |
