---
id: DOC-ZYRA-0514
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex task - one fresh signed iPhone build from the newest ZYRA commit after line 109, verified and installed on the Founder's iPhone on his GO
links: [DR-ZYRA-352, OA-ZYRA-317, OA-AIOS-420, DOC-ZYRA-0448]
owner: Fable
---

# BRIEF — FINAL SIGNED BUILD AND iPHONE INSTALL — 14 NOV 2026

**Needs: Founder present - at the Mac to click Allow on signing and device prompts, iPhone plugged in and unlocked** (charters rule 15, Q162). Never start this line in the 01:00 run; build and install on Shakeel's daytime GO only.

**Founder-named task.** Founder 14 Nov: "I WANT IT TO BE LATEST UPDATE ON CODEX CLAUDE AND MY PHONE TODFAY", then
(clickable, QUESTIONS 153) **"One final build after 109 (Recommended)"**: the line 84 host (12fcf8f) is not installed;
one fresh build from the newest commit carries lines 84, 109, 113-115 and every fix together.

**When:** after line 109 is BUILT and committed, with nothing uncommitted in `SOURCE/lib`, `SOURCE/test`, `SOURCE/ios`
(every line before it committed). If another line is mid-edit, wait for it to commit; do not stash, reset or check out.

| Step | Detail |
|---|---|
| 1 | Note the commit (`git status` clean for the paths above). Run the analyzer and the focused tests of lines 84 and 109 |
| 2 | Build exactly as line 84's successful attempt (DOC-ZYRA-0448 step 0 (iii), (iii-d), (iii-e)): Flutter prepared inside `no_git.sb`; temporary `IDEPackageSupportDisableManifestSandbox` = YES, restored straight after (also on failure), both values recorded; cached pinned Swift packages only, `Package.resolved` byte-identical; `-allowProvisioningUpdates` allowed for the development profile only (line 109 adds `applinks:zyraconnect.app`; Founder approved 14 Nov). **One** Xcode attempt; if it fails, stop and ask |
| 3 | Strict checks unchanged: signature, profile, entitlements (now including `applinks:zyraconnect.app`), certificate, sole paired device, unlocked device. Refresh the route pins with the reason |
| 4 | Tell Shakeel in one line: version/build, commit, what is new (profile video, code links, Profile on one screen, one card colour, still pages). **Wait for his GO**, then install and open on his iPhone |
| 5 | **Phone checks (Fable 14 Nov, Q154 order; corrected for Q155):** the live server does not have `zyra_resolve_code_link` until the clean server is applied. The strict link parser stays as locked (LOCK 9 V4 §0b) - no demo exception, no fixture that lets sample codes through a link, and the Founder demo still never produces a working link (DOC-ZYRA-0512 step 6). Four checks: (a) **Link delivery:** from Notes open `https://zyraconnect.app/c/#<code>` with a made-up code in the locked five-group format that is not a real member code (record which one). ZYRA must open (not Safari) and land on the code lookup; in the Founder preview the result is today's not-found message (spec §0b: unknown codes). This proves the Universal Link and the `#` part reach the app. (b) **Bad link:** open the same URL with a DEMO/DRAFT sample code, and one with a broken code → "This isn't a ZYRA Code." (this is correct, sample codes are outside the link format). (c) **Found card in the preview:** type a DEMO/DRAFT sample code into the Their code boxes and tap Check code - Guardian sample as a Seeker, Seeker sample - found card, Send request → sent state, nothing sent (spec §0b); your own code → the personal-code page's existing message for that case (today's not-found message; spec §0b row 7 "today's message for that case" - no new wording, Q156). (d) **Safe failure:** as a real member, a well-formed link against today's server shows the step 7 page with today's message, no crash. The found card **from a link** is checked only after the live apply (OA-ZYRA-317). Record each result. Task note under 4 KB; mark BUILT after the install opens |

Not in this line: live server changes, App Store or TestFlight upload, new features.
