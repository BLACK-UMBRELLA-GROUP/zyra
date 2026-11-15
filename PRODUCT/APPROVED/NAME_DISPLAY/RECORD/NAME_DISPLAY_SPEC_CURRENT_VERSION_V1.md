---
id: DOC-ZYRA-0493
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 33 - how member names show everywhere so long or multi-part names keep the layout clean, and the sign-up length limits
links: [AD-AIOS-115]
owner: ZYRA chat
---

# NAME DISPLAY — SPEC — V1 (LOCKED 12 NOV 2026)

Founder 12 Nov 17:22: "what if they have middle name and or long name how will it effect layout and how can we ensure its kept
clean". Reference: prototype V214 (private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V226.html`)
— strip **Name test (sample data) → Long names** on Profiles, Journey, Journey requests, Ended Journeys, Introductions.

## 1. Display rules (everywhere — universal)
| Place | Rule |
|---|---|
| **List cards** — Journey requests (Received, Sent, Past incl. grouped), Ended Journeys, Introductions (Received, Past), Guardian "Introductions you’ve made", and any other list card using the request card | First name + surname on **one line**, same font size, ending in **"…"** when it does not fit. Every card keeps the same height. The name column takes the space left of the chevron |
| **Profile page (big name)** — Profiles card details page, own Preview, profile view | First name on **one line**: shrinks to fit down to **75 %** of its size, then "…". Surname up to **2 lines**, then "…". Age · city stays one line with "…" (unchanged) |
| Short mentions in sentences (toasts, "You can ask <first name> again…", confirm sheets) | First name only, as today |
| Full name | Always available in full on the person's profile page (and to screen readers as the full label) |
Names are shown exactly as typed: no automatic cutting of "middle" words (compound names such as "Abdul Malik" must stay whole).

## 2. Sign-up and edit limits
| Field | Limit (was 60) |
|---|---|
| First name | **30** characters |
| Surname | **40** characters |
The field counter shows when 5 characters are left. Existing members with longer names keep them; the display rules above keep their cards clean. Server check: QUESTIONS 135 (Fable).

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-11-12 | V1 | LOCKed by the Founder (`LOCK_RECORD.md`, LOCK 33) |
