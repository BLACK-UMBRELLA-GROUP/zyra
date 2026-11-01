---
id: DOC-ZYRA-0372
type: SPEC
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 12 - Phone access page
links: [DOC-ZYRA-0287]
owner: ZYRA chat
---

# PHONE ACCESS — SPEC — V1 (LOCKED 30 OCT 2026)

Masters (430 × 932 @3x): `../MASTERS/settings__phone_access_row.png`, `phone_access__normal.png`.

| Item | Rule |
|---|---|
| Where | Settings → PRIVACY, third row after Pause My Profile and Hidden Profiles: **Phone access** with a NEW tag until first opened (Seeker and Guardian) |
| Page | Title "Phone access"; "What ZYRA can use on this phone."; one glass card of rows: icon, name, why, and a status pill (gold when allowed) |
| Rows | **Location** — "Distance in Filters. Only your town is used — never shown to anyone." · **Notifications** — "Requests, Journey and Guardian updates." · **Photos** — "Choosing your profile photos. ZYRA only sees the ones you pick." · **Camera** — "Scanning ZYRA Codes, taking photos and the identity check." · **Face ID** — "Opening ZYRA when App lock is on." |
| Status | Read from the phone each time the page opens: Location "While using" / "Off"; Notifications "Allowed" / "Off"; Photos "Selected photos" / "All photos" / "Off"; Camera "Allowed" / "Off" / "Ask first"; Face ID "On" / "Off" (follows App lock) |
| Tap a row | Not yet asked → ZYRA's explain sheet then the iPhone prompt; asked before → opens iPhone Settings → ZYRA |
| Footer | "Your phone decides these. Tap one to change it in your phone's Settings. ZYRA asks for each one only when you first need it." |
| Never ask for | Contacts, microphone, tracking (App Tracking Transparency), "Always" location |
| Purpose strings | Each permission's iOS text matches the "why" above |
