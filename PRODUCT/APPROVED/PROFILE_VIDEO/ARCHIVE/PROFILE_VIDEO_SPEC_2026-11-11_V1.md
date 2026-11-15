---
id: DOC-ZYRA-0446
type: SPEC
status: SUPERSEDED
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 29 - one silent profile video for Seeker One
links: [AD-AIOS-115]
owner: ZYRA chat
---

> **SUPERSEDED 11 Nov 2026 by `RECORD/PROFILE_VIDEO_SPEC_CURRENT_VERSION_V2.md`. Reference only.**

# PROFILE VIDEO — SPEC — V1 (LOCKED 11 NOV 2026)

**Founder, 11 Nov 21:56 (iPhone, Photos page):** "Lets add possibility if 1 no sound video (not for seeker basic)" → clickable answers **Up to 10 seconds** · **As one of the photo pages** · **Everyone who can see the profile** · **Yes, checked first, sound removed** (all Recommended) → prototype V186 → **"LOCK it (Recommended)"**. Reference: prototype copy `PRODUCT/APPROVED/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V187.html` (Profile → Manage photos; Profiles → Amira / Sara last photo page). No masters (charter rule 13).

| Item | Rule |
|---|---|
| Who can add | **Seeker One only**: one video space. Seeker Basic sees the space locked (dashed gold border, lock, "Video", "Comes with Seeker One", "See Seeker One ›" → Seeker One page). If a member drops to Basic, the video is hidden from others (kept, shown again on return to One) |
| Video | One video, **up to 10 seconds**, **no sound**: the server removes the sound track on upload (never only muted in the app). Longer clips are trimmed in the picker to 10 s before upload |
| Photos page | Header "Photos"; line "4 photo spaces available · 1 video space" (Basic: no video part); 2-column grid of ivory floating tiles filling the height (no dead space): main photo (gold border + gold check), photo spaces (+), **video space last**. States: **Add a video** (gold ring play icon, "Up to 10 seconds · no sound") → **Being checked** (dimmed still, ivory pill "Being checked", "Only you can see it for now") → **Live** (plays muted on a loop, badge "🔇 10 s", × remove → confirm sheet LOCK 28: "Remove your video?" · "It disappears from your profile at once. You can add a new one at any time." · Remove video / Keep video). Rejected after checking: back to Add with a short reason line |
| On a profile | The video is **the last photo page** of the Profiles card (and Preview, Journey Bio): one extra page dot; plays **muted, looping, automatically** while that page is open; badge top-right "🔇 Video · no sound" (white on a dark translucent pill). Reduce Motion / Low Power: still frame + play button, plays on tap |
| Who sees it | **Everyone who can see the profile** (Seeker Basic viewers too) — only after it is approved |
| Checking | Every video is checked (same rules as photos) before anyone else can see it |
| Upgrade table | Seeker One table row "Profile video · — · 1 silent video" (LOCK 25 V3), shown only once this ships (honest-table rule) |
| Server (Fable, OA-ZYRA-317) | Storage, sound removal, 10 s limit, checking queue, approved / rejected state, hiding on downgrade. The app part must not ship before this exists |

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-11-11 | V1 | First version |
