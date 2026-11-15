---
id: DOC-ZYRA-0419
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 21 - Profile tab (Seeker and Guardian) in the Monogram layout with grouped floating cards
links: [AD-AIOS-115]
owner: ZYRA chat
---

# PROFILE TAB — SPEC — V1 (LOCKED 31 OCT 2026)

## 1. Purpose and scope
The **Profile tab** for Seekers and Guardians uses the **Monogram** layout, the same visual language as the Guardian card (LOCK 19): the person centred at the top, then grouped floating cards.
Prototype: V112. Masters: `../MASTERS/p01–p06` (1290 × 2796, Ivory, @3x).
**In scope:** Seeker Profile tab (One and Basic) and Guardian Profile tab (One and Basic).
**Not in scope:** the pages these rows open. They stay as they are today.

## 2. Header (centred)
| Item | Seeker | Guardian | Master |
|---|---|---|---|
| Avatar | Own photo, 104 × 104, gold ring (today's `pav` ring) | Monogram: 104 circle, 1 pt gold ring, initial 50 pt weight 200 in gold | p01, p04 |
| Name | 28 pt light | same | p01 |
| Line | Small caps, gold, letter-spacing 1.2: "SEEKER ONE · SEEKER" / "SEEKER BASIC · SEEKER" | "GUARDIAN ONE · GUARDIAN" / "GUARDIAN BASIC · GUARDIAN" | p01, p03, p06 |
| Pills | **Preview** · **Edit** · **⇄ Switch** | **⇄ Switch** | p01, p04 |

## 3. Cards (top to bottom)
Each card is a floating rounded card (radius 20, ivory glass, soft shadow). Rows have a gold icon, a title, an optional muted sub-line and a chevron, with thin dividers between rows.

### Seeker
| Card | Rows | Opens (existing) |
|---|---|---|
| 1 | Manage photos | Manage photos |
| 2 Membership | **Seeker One** · "Manage membership" (Basic: **Seeker Basic** · "See Seeker One") · **Compatibility Unlocks** · "<n> left · 3 more each month" (Basic: "<n> left") · **Profiles & Family places** · "Who your membership covers" | Membership (Basic → Seeker One page) · Unlocks store · Your subscriptions (renamed) |
| 3 Guardians & safety | What Guardians can do · Safety & advice · Invite someone to ZYRA | LOCK 3 page · Safety · Invite |
| 4 | **Settings** · "Account, privacy, notifications" · **Appearance & haptics** · **Sign out** in red `#B84A42`, last, no chevron | Settings · Personalisation · existing sign out |

### Guardian
| Card | Rows | Opens (existing) |
|---|---|---|
| 1 | **Your Seekers** · "Adam · you're his Father and Main Guardian" (relationship + role per linked Seeker; with several: "Adam, Yusuf") | Seekers tab |
| 2 Membership | **Guardian One** · "Manage membership" (Basic: **Guardian Basic** · "See Guardian One") · **Profiles & Family places** | Guardian membership · Your subscriptions |
| 3 | Safety & advice · Invite someone to ZYRA | existing |
| 4 | Settings · Appearance & haptics · Sign out (red) | existing |

## 4. Removed from today's tab
| Today | Why |
|---|---|
| "About me" rows (Age / Gender / Location; Guardian: Relationship / Linked Seekers count) | They repeat Edit profile. The Guardian's relationship moves into "Your Seekers" |
| Section labels MEMBERSHIP / COMPATIBILITY / YOUR PROFILE / SAFETY & SHARING / PERSONALISATION | Cards group the rows instead |
| "Preview my profile" / "Edit profile" rows | Now pills in the header |
| "Your subscriptions" label | Renamed **Profiles & Family places** (same page) |

## 5. Rules
- No member counts.
- The page scrolls; the tab bar floats as today.
- Larger Text: rows grow taller; pills wrap to a second line, never clip.

## 6. Version history
| Date | Version | Change |
|---|---|---|
| 2026-10-31 | V1 | Founder: "does this whole page need improvment…" → 5 designs → "LOCK Monogram (Recommended)" |
