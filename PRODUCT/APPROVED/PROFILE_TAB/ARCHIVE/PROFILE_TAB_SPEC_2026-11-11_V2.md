---
id: DOC-ZYRA-0419
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 21 - Profile tab (Seeker and Guardian) in the Monogram layout with grouped floating cards
links: [AD-AIOS-115]
owner: ZYRA chat
---

# PROFILE TAB — SPEC — V2 (LOCKED 31 OCT 2026, SETTINGS 11 NOV)

**V2 (11 Nov, prototype V151–V152; Founder: "completely remove the apperence and haptic setting with everything inside - no options for app trext-background-gold accests but move hapttips into settings and when clciks its a slider"):** Appearance & haptics row and page removed for Seeker and Guardian; haptics move into Settings as a slider (§5). V1 is in `../ARCHIVE/PROFILE_TAB_SPEC_2026-11-11_V1.md`.

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
| 4 | **Settings** · "Account, privacy, notifications, haptics" · **Sign out** in red (small danger text `#AC453E`, LOCK 14 V6), last, no chevron | Settings · existing sign out |

### Guardian
| Card | Rows | Opens (existing) |
|---|---|---|
| 1 | **Your Seekers** · "Adam · you're his Father and Main Guardian" (relationship + role per linked Seeker; with several: "Adam, Yusuf") | Seekers tab |
| 2 Membership | **Guardian One** · "Manage membership" (Basic: **Guardian Basic** · "See Guardian One") · **Profiles & Family places** | Guardian membership · Your subscriptions |
| 3 | Safety & advice · Invite someone to ZYRA | existing |
| 4 | Settings · "Account, privacy, notifications, haptics" · Sign out (red) | Settings (Guardian) · existing |

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

## 5. Settings → Haptics (V2)
| Item | Rule |
|---|---|
| Removed | The **Appearance & haptics** row (Seeker and Guardian) and its whole page (Personalisation): no text options, no background choice, no **gold accents** switch. Gold accents stay off for everyone; a saved gold or palette preference is ignored (no member data deleted) |
| Where | Settings, section **NOTIFICATIONS & HAPTICS** (was NOTIFICATIONS): **Notifications & emails** · **Haptics**. Same Settings page for Seeker and Guardian (Guardian summary: Membership Guardian One / Basic · Seekers <n> · Signed in with) |
| Haptics row | Title **Haptics**, value on the right = the current level (e.g. "Light"), chevron. Tap → the row expands in place (chevron points down) and shows the slider; tap again to close |
| Slider | Five stops, labels under it: **Off · Subtle · Light · Medium · Strong**. Gold track to the thumb, light track after; ivory round thumb 26 pt with a thin gold ring; the selected label in small gold `#845F24` weight 500. Snaps to stops; dragging updates the value at once; on release the phone gives one tap at the new level (none for Off). VoiceOver: "Haptic strength, <level>", adjustable |
| Starting level | **Light** for a new member (ZYRA chat assumption; the Founder did not answer, 11 Nov). An existing member's saved level is kept |
| Prototype | V152 (Profile → Settings → Haptics) |
