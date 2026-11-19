# BUILD BRIEF — FIRST-TIME WALKTHROUGH (LOCK 36 V1) — 19 NOV 2026
Spec: `PRODUCT/APPROVED/FIRST_TOUR/RECORD/FIRST_TOUR_SPEC_CURRENT_VERSION_V1.md`. Masters: `FIRST_TOUR/MASTERS/` (37). Prototype V289 (Founder's private copy, layout **First-time tour**). Exception to AD-AIOS-149 approved by the Founder 19 Nov ("Lock and queue now"). Build after line 121 (sign-up) is in place — it is.

**Needs: none** (charters rule 15; added by Fable 19 Nov). Every check runs in the Founder preview and simulator; the iPhone check is done at the next phone install on Shakeel's daytime GO (line 117), never by a device install in the 01:00 run.

## Scope (planned app / Founder preview, Seeker and Guardian)
1. One overlay widget for the whole walkthrough: shade with cut-outs (lit item + current tab icon), 2 pt gold edge, ivory note with pointer, touch-point gesture loop, welcome and end cards — exactly per spec §1.
2. Step lists per spec §2 (Seeker, 18) and §3 (Guardian, 14). Each step switches to its tab, finds its item by a stable key on the existing widget; if missing, light the tab icon.
3. Trigger once after first sign-up entry (spec §1 "When"); remember it on the device with the app's existing local storage per account. No server change in this line.
4. Settings → SUPPORT → first row **Replay the walkthrough** (NEW tag) starts it.
5. No skip; tap anywhere / Next; left 20 % = back; no timer. Reduce Motion: no loop, still touch point. VoiceOver reads title then line; Next is a button.
6. During the walkthrough the member's real pages are shown; nothing is tapped through to the real controls.

## Checks
- iPhone: new Seeker and new Guardian see it once after sign-up; it does not show again after restart; Replay works from Settings.
- Each master matches on 430 × 932. Placement per spec §1 "Placement" (QUESTIONS 175): the note never covers the lit item or the current tab icon; tall items are lit at their top part only; the opaque note may sit over shaded unlit page content. No step stuck on a missing item.
- Tests for trigger-once, replay, back/next, missing-item fallback; no new failures.
