---
id: DOC-ZYRA-GSEEKERS-V1
type: SPEC
status: CURRENT
feature: GUARDIAN SEEKERS PAGE
purpose: Spec for LOCK 35 - Guardian's Seekers tab as full-height swipe cards like the Seeker's Guardian page
owner: ZYRA chat
---
# GUARDIAN SEEKERS PAGE — SPEC — V1 (LOCKED 18 NOV 2026)
Founder 18 Nov: "redesign this page - take inspiration from seeker one guardian page"; "whers chat icon on this page like seeker one" → prototype V242/V244 → "Yes, lock and queue both (Recommended)" (exception to AD-AIOS-149).

| Item | Rule |
|---|---|
| Header | Title "Seekers"; round chat button (opens Guardian Circle) then round + (Invite your Seeker), same as the Seeker's Guardian page header. |
| Dots | Page dots under the header, one per Seeker plus one for the Invite card; follow the swipe. |
| Seeker card | Full height (shared card surface, line 114). 76 pt monogram circle; name 30 pt light; caps line "YOU ARE HIS MAIN GUARDIAN" / "ADDITIONAL GUARDIAN"; rows Relationship · Membership · Linked; section label CURRENT JOURNEY with one row ("With <name>" + stage; tap opens the Journeys tab on that Seeker's Journey) or "No current Journey" (tap opens that Seeker's details); bottom row "<Name>'s Guardian Circle ›". |
| Invite card | Last card: 104 pt circle with +, "Invite a Seeker", "You can support up to 10 Seekers". |
| Swipe | LOCK 26 V3 shared swipe. |
| Plans | Guardian Basic sees the same page; Circle opens read only (locked Guardian plan table). |
## Masters (QUESTIONS 168, 18 Nov)
Rendered 430 × 932 @3x from prototype V275, folder `GUARDIAN_SEEKERS/MASTERS/`:
| File | Covers |
|---|---|
| gs01 | Guardian One — Adam, Main Guardian, current Journey |
| gs02 | Yusuf — Additional Guardian, No current Journey |
| gs03 | Invite card |
| gs04 | Guardian Basic — Adam (same page) |
| gs05 | Empty: no Seekers yet — only the Invite card, one dot |
| gs06 | Guardian Circle (chat button / Circle row), Guardian One |
| gs07 | Guardian Circle read only, Guardian Basic |
| gs08 | Current Journey row → Journeys tab on Adam's Journey |
| gs91, gs92 | Error states: offline, server — existing app error page (unchanged shared state) |
Unchanged shared states: + / Invite card open today's **Invite your Seeker** page; loading uses the existing loading spinner; the Journeys tab is today's page.
## Version history
| V1 | 2026-11-18 | First version (LOCK 35), prototype V244 → V271 |
| V1 | 2026-11-18 | Correction after Codex preflight (QUESTIONS 168): masters (10) and what the Current Journey row opens. No design change |
