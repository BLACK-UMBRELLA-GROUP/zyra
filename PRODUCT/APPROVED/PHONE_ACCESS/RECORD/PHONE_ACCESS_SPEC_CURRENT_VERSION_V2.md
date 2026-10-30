---
id: TBC (Fable assigns)
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 12 - Phone access page
links: [DOC-ZYRA-0287]
owner: ZYRA chat
---

# PHONE ACCESS — SPEC — V2 (LOCKED 30 OCT 2026)

Masters (430 × 932 @3x): `../MASTERS/settings__phone_access_row.png` (unchanged), `phone_access__normal.png` (**V2**, prototype V87 — new Location wording). Colours: build in today's colours; LOCK 14 (queue line 39) recolours afterwards.

**V2 changes (after Codex preflight 30 Oct, LOCK12-PREFLIGHT-01/02):** no ZYRA explain sheets on this page; one Location wording.

| Item | Rule |
|---|---|
| Where | Settings → PRIVACY, third row after Pause My Profile and Hidden Profiles: **Phone access** with a NEW tag until first opened (Seeker and Guardian) |
| Page | Title "Phone access"; "What ZYRA can use on this phone."; one glass card of rows: icon, name, why, and a status pill (gold when allowed) |
| Rows | **Location** — "Distance in Filters. Only your approximate area is used — never shown to anyone." · **Notifications** — "Requests, Journey and Guardian updates." · **Photos** — "Choosing your profile photos. ZYRA only sees the ones you pick." · **Camera** — "Scanning ZYRA Codes, taking photos and the identity check." · **Face ID** — "Opening ZYRA when App lock is on." |
| Status | Read from the phone each time the page opens: Location "While using" / "Off"; Notifications "Allowed" / "Off"; Photos "Selected photos" / "All photos" / "Off"; Camera "Allowed" / "Off" / "Ask first"; Face ID "On" / "Off" (follows App lock) |
| Tap a row | **Not yet asked → the iPhone prompt straight away (no ZYRA explain sheet — the row is the explanation).** Asked before → opens iPhone Settings → ZYRA. Applies to all five rows (Face ID: the iPhone Face ID prompt) |
| Footer | "Your phone decides these. Tap one to change it in your phone's Settings. ZYRA asks for each one only when you first need it." |
| Never ask for | Contacts, microphone, tracking (App Tracking Transparency), "Always" location |
| Purpose strings (`Info.plist`, exact) | `NSLocationWhenInUseUsageDescription` — **unchanged** (LOCK 11, already built): "Your approximate area is used to measure distance in Filters. It is never shown to anyone." · `NSCameraUsageDescription` — "Scanning ZYRA Codes, taking photos and the identity check." · `NSPhotoLibraryUsageDescription` — "Choosing your profile photos. ZYRA only sees the ones you pick." · `NSFaceIDUsageDescription` — "Opening ZYRA when App lock is on." · `NSPhotoLibraryAddUsageDescription` — **unchanged** (not part of this page) · Notifications — no iOS purpose text |
