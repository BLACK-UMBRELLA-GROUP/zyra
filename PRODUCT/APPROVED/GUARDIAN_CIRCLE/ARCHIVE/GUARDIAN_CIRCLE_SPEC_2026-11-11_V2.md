---
id: DOC-ZYRA-0391
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 20 - Guardian Circle as Topics (All, one tab per Journey, Past), Seeker and Guardian sides; Guardian Basic reads; past topics open 30 days then read only
links: [AD-AIOS-115, DR-ZYRA-233, DR-ZYRA-248, DR-ZYRA-268]
owner: ZYRA chat
---

# GUARDIAN CIRCLE — SPEC — V2 (LOCKED 31 OCT 2026)

## 1. Purpose and scope
The Guardian Circle (the family's discussion) becomes **Topics**: one transcript you can view as **All**, **one tab per current Journey**, and **Past**. Same layout for the Seeker and for Guardians.
Prototype: V110. Masters: `../MASTERS/gc01–gc14` (1290 × 2796, Ivory, @3x).

**In scope:** Seeker Circle page (Seeker One and Basic); Guardian Circle page (Guardian One and Guardian Basic); the ••• sheet.
**Not in scope:** Journey chat; Connect private chat; the Guardian tab (LOCK 19); any server rule, guard or retention change (§8).

## 2. Page layout
| Part | Rule | Master |
|---|---|---|
| Header | Title **Guardian Circle**; right: round **•••** only. **No member count, no permanent notice row** | gc01 |
| Tabs | Pill tabs under the title, scroll sideways if needed: **All** · one tab per current Journey (the other person's first name) · **Past**. Selected = gold border, light gold fill, gold text | gc01 |
| Transcript | Day separators ("11 SEP", "YESTERDAY", "TODAY"); **UNREAD MESSAGES** separator in gold before the first unread; opens scrolled to the newest message | gc01 |
| Bubbles | Others left with sender line ("Hassan · Father · Main Guardian" / "Adam · Seeker"); own right with gold border; "✓✓ Seen by everyone" in gold under your newest read message | gc01, gc09 |
| Journey tag | A message tied to a Journey shows a small gold outline chip **About <first name>** above the text | gc01 |
| Composer | "Message your Circle" field + gold round send button | gc01 |
| Bubble clears | Opening the Circle clears the LOCK 17 gold bubble on the Guardian tab's Circle button | — |
| All tab | Shows **every** message in time order (tagged and untagged) — the one place to catch up; the only place to talk when there is no Journey (V2, Founder "Keep, rename All") | gc01 |
| All, empty (new family) | Centred gold-ring chat icon, **Talk about your search**, "Who to request, introductions, and what matters to your family. Each Journey gets its own tab when it begins." Composer stays. No Journey tabs; no Past tab until a Journey has ended | gc14 |

## 3. Journey tab
| Item | Rule | Master |
|---|---|---|
| Head card | Photo 64 × 64, first name, "Stage n of 8 · <stage>", outline gold **View Journey** → that Journey | gc03 |
| Transcript | Only messages tied to this Journey; empty day separators are hidden | gc03 |
| Sending | A message sent from a Journey tab is tied to that Journey (shows the About chip). Sent from All = not tied | gc03 |
| Empty | "No messages about <name> yet. Start the discussion below." | gc07 |
| Guardians | See tabs only for Journeys they have View access to (LOCK 19 access side) | gc09 |

## 4. Past
Founder 31 Oct: **"30 days, then read-only"**.

| Item | Seeker | Guardian | Master |
|---|---|---|---|
| Who sees Past | Once at least one Journey has ended | Only when the Seeker shares **Past Journey summaries** with that Guardian (DR-ZYRA-233; LOCK 3 V2 §3b). Sharing off = no Past tab | gc04, gc09, gc10 |
| List row | Photo 52, first name, "Journey ended <date>" | **No photo** (chat-icon tile), "**Adam & Zainab**", "**2 Oct – 24 Oct 2026**" (LOCK 3 V2 §3b format; nothing else shown) | gc04, gc10 |
| Right side | Gold "Open · n days left" or muted "Read only" | same | gc04 |
| Foot note | "You can talk about a Journey for 30 days after it ends. Then it becomes read only. Guardians see these only if you share past Journey summaries with them." | First sentence only | gc04, gc10 |
| Topic page | Head card (as list row) + outline **All past** button; status line: gold "Open until <date> · n days left" or muted "Closed <date> · read only" | same | gc05, gc06, gc11 |
| Open | Composer works; messages tied to that past Journey | same | gc05 |
| Closed | Composer replaced by: "This discussion closed 30 days after the Journey ended. You can still read it." | same | gc06, gc11 |
| Timing | Open from the Journey's end until end date + 30 days; then read only until the existing message retention removes it (DR-ZYRA-248) | same | — |

## 5. ••• sheet
| Item | Rule | Master |
|---|---|---|
| IN THE CIRCLE | Gold small caps, then one row per member: monogram 34, name ("You" for yourself), role (Main Guardian in gold), right "Writes" or "Reads only" | gc02, gc12 |
| Guardian Basic row | Seeker's view: "Reads only ›" — tap opens the LOCK 19 Guardian Basic chat sheet (ZYRA Family routes) | gc02 |
| Rows | **Mute the Circle** / "Unmute the Circle" (right "Muted"); **Report a message** (existing press-and-hold report); **Manage your Guardians** → Guardian tab (Seeker only) | gc02, gc12 |
| Button | Gold **Done** | gc02 |
| Seeker Basic | Members: You and Hassan only | gc08 |

## 6. Guardian Basic in the Circle
Founder 31 Oct: **"Read only"**. A Guardian Basic **is in the Circle and reads everything** the Circle shows them (same tabs and Past rule), but cannot write.

| Item | Rule | Master |
|---|---|---|
| Composer | Replaced by: lock icon + "You're reading only. Chat comes with Guardian One." + outline gold **See Guardian One** → Guardian membership page | gc13 |
| Seeker side | No permanent notice. Shown only in ••• as "Reads only" | gc02 |

## 7. Rules this changes (for Fable to log)
| Today | New | Founder |
|---|---|---|
| DR-ZYRA-248: every Circle member needs their own paid role (One) | Guardian Basic is a **read-only** Circle member | "Read only (Recommended)", 31 Oct |
| DR-ZYRA-268: Guardian Basic can view, cannot chat | Unchanged for writing; viewing now includes reading the Circle | same |
| (none) | Past Journey topics open for 30 days after the Journey ends, then read only | "30 days, then read-only (Recommended)", 31 Oct |

## 8. Build stage in this line
Founder preview, **local preview**: the read-only Guardian Basic view and the 30-day close use preview data; **no server guard, admission rule or retention change**. The server part (Basic read access, closing past topics) is separate SERVER work after Fable logs §7. **Preview writing rule (clarified 1 Nov, Codex question 6, as masters gc02/gc08/gc13 show):** the Seeker writes on Seeker One or Seeker Basic; a Guardian One writes; a Guardian Basic reads only and never stops others writing. Founder-preview check only.

## 9. Version history
| Date | Version | Change |
|---|---|---|
| 2026-10-31 | V1 | Founder: "LOCK Topics (Recommended)"; "30 days, then read-only"; "Read only" for Guardian Basic; "i dont think we need a permenat notificaton here" |
| 2026-10-31 | V2 | Founder comment on the Everyone tab → clickable "Keep, rename \"All\" (Recommended)": tab renamed **All**; new-family empty state (gc14); Past tab only once a Journey has ended; all masters re-rendered (V1 in `ARCHIVE/MASTERS_V1/`) |
