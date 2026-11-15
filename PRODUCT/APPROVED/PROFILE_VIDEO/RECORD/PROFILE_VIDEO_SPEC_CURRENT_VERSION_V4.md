---
id: DOC-ZYRA-0446
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 29 - one silent profile video for Seeker One
links: [AD-AIOS-115]
owner: ZYRA chat
---

# PROFILE VIDEO — SPEC — V4 (LOCKED 11 NOV 2026, CHOOSE 10 SECONDS 12 NOV, JOURNEY BIO GALLERY 12 NOV)

**Founder, 11 Nov 21:56 (iPhone, Photos page):** "Lets add possibility if 1 no sound video (not for seeker basic)" → clickable answers **Up to 10 seconds** · **As one of the photo pages** · **Everyone who can see the profile** · **Yes, checked first, sound removed** (all Recommended) → prototype V186 → **"LOCK it (Recommended)"**. Reference: prototype copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V194.html` (Profile → Manage photos; Profiles → Amira / Sara last photo page). No masters (charter rule 13).

| Item | Rule |
|---|---|
| Who can add | **Seeker One only**: one video space. Seeker Basic sees the space locked (dashed gold border, lock, "Video", "Comes with Seeker One", "See Seeker One ›" → Seeker One page). If a member drops to Basic, the video is hidden from others (kept, shown again on return to One) |
| Video | One video, **up to 10 seconds**, **no sound**: the app saves the clip **with no sound track** (trimmed to 10 s) before upload, and the **server checks every upload and refuses** any file with a sound track or over 10 s (never only muted in the app). Founder 11 Nov: "App strips, server refuses (Recommended)" |
| **Choose 10 seconds (V3)** | Founder 12 Nov: "They choose which 10 seconds (Recommended)". A clip **10 s or shorter** skips this screen. A longer clip opens **Choose 10 seconds**: back header; line "Slide the gold frame to pick your best 10 seconds. It plays without sound."; large preview (rounded 22, plays the chosen 10 s muted on a loop, badge "🔇 No sound"); time row "0:06 – 0:16" left, "Video 0:32" right; filmstrip (56 high, 10 frames) with a **gold frame exactly 10 s wide** (3 pt `#C08A3A`, radius 10) that the member drags along the clip (or taps where it should start); outside the frame is veiled ivory (55 %); starts on the first 10 s. Gold **Use these 10 seconds** → the app exports that segment with **no sound track** → upload → "Being checked". **Choose another video** → library again. States: **Preparing your video…** (spinner) · **Ready** · **This video couldn't be opened** (gold-ring muted icon, "Try another video, or save it to your phone first.", gold Choose another video). Reduce Motion: preview shows a still frame. VoiceOver: the frame is adjustable ("Start 0:06, 10 seconds") |
| **Journey Bio gallery (V4)** | Codex (line 84): Journey Bio has a portrait and no pager. Founder 12 Nov clickable **"B · 'Photos & video' button"** (prototype V193 → V194, screen list "Journey Bio · photos & video"). Under the name and its gold underline, a small ivory floating button **"Photos & video ›"** (34 high, 12.5 pt) — label **"Photos ›"** when the person has no approved video. It opens the **shared full-screen gallery**: dark background, page dots at the top (gold active), the person's approved photos in order and the **approved video as the last page** (muted loop, badge "🔇 Video · no sound"), tap right = next / left = previous, swipe as LOCK 26, × closes back to the Bio. The portrait itself stays as today (no badge, not a button). Same gallery from Ended Journey Bio while the archive is readable. Reduce Motion: video shows a still + tap to play |
| Photos page | Header "Photos"; line "4 photo spaces available · 1 video space" (Basic: no video part); 2-column grid of ivory floating tiles filling the height (no dead space): main photo (gold border + gold check), photo spaces (+), **video space last**. States: **Add a video** (gold ring play icon, "Up to 10 seconds · no sound") → **Being checked** (dimmed still, ivory pill "Being checked", "Only you can see it for now") → **Live** (plays muted on a loop, badge "🔇 10 s", × remove → confirm sheet LOCK 28: "Remove your video?" · "It disappears from your profile at once. You can add a new one at any time." · Remove video / Keep video). Rejected after checking: back to Add with a short reason line |
| On a profile | The video is **the last photo page** of the Profiles card (and Preview, Journey Bio): one extra page dot; plays **muted, looping, automatically** while that page is open; badge top-right "🔇 Video · no sound" (white on a dark translucent pill). Reduce Motion / Low Power: still frame + play button, plays on tap |
| Who sees it | **Everyone who can see the profile** (Seeker Basic viewers too) — only after it is approved |
| Checking | Every video is checked (same rules as photos) before anyone else can see it |
| Upgrade table | Seeker One table row "Profile video · — · 1 silent video" (LOCK 25 V3), shown only once this ships (honest-table rule) |
| Server (Fable, OA-ZYRA-317) | Storage, sound-track refusal, 10 s limit, checking queue, approved / rejected state, hiding on downgrade - server brief DOC-ZYRA-0445, queue line 85. The app part must not ship before this exists |

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-11-11 | V1 | First version |
| 2026-11-12 | V4 | Journey Bio gallery entry: "Photos & video ›" button under the name; video last page (Founder "B"). V3 archived |
| 2026-11-12 | V3 | Choose 10 seconds screen (Founder "They choose which 10 seconds"). Sound rule unchanged: app exports without a sound track, server refuses any file with sound or over 10 s. V2 archived |
| 2026-11-11 | V2 | Sound: app saves without a sound track, server refuses any file with sound or over 10 s (Founder clickable "App strips, server refuses (Recommended)"); server brief DOC-ZYRA-0445 |
