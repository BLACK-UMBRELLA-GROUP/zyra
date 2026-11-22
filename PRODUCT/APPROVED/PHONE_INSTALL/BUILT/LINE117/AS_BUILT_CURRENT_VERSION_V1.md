---
id: ASBUILT-ZYRA-LINE117
type: HANDOVER
status: CURRENT
feature: PHONE DELIVERY
purpose: Exact signed Founder PROFILE build installed on the paired iPhone, with deferred phone acceptance
links: [DOC-ZYRA-0514, DOC-ZYRA-0448, OA-ZYRA-317, DR-ZYRA-352, ASBUILT-ZYRA-LINE117-WIRELESS]
owner: Codex
---

# Founder iPhone delivery — line 117

Line 117 is BUILT on 22 Nov 2026 under DOC-ZYRA-0514’s install-and-open rule and the Founder’s explicit instruction to defer testing. The paired USB iPhone received signed ZYRA Founder PROFILE 1.0.0 (5), app source 9651731289d583ae660669fccba70aa0ed2252f7. Exactly one protected installation and launch succeeded. CoreDevice verified the installed bundle/version and running executable. The Founder confirmed “ZYRA opens normally.”

The Founder then selected “I’ll test later.” All DOC-ZYRA-0514 step 5(a–d) phone checks are deferred and are not recorded as passes. DEFERRED_PHONE_CHECKS_2026-11-22.json tracks them under OA-ZYRA-317 for later Founder-operated testing. This includes Q158’s fixed code-rotation flow and the real-member safe-failure check. Q157’s accepted widget fallback passed separately at 430×932 and 375×667. The new local signup surface still does not expose that exact legacy found-and-sent rehearsal. A non-Founder member session is required for step 5(d).

The build includes all committed app changes through queue line 124, including profile video, shared code links, the Profile/colour/still-page fixes, Q158 rotation, archive/introduction cards, name limits, sign-up/setup, Guardian Seekers, Developer panel and the walkthrough. It retains the Founder preview boundaries and current server rollout state. Live: no.

## Build and delivery route

SOURCE/tooling/verified_host_profile.mjs pins the exact native host, source seal, native inputs, profile, entitlements and receipt. SOURCE/tooling/verified_phone_delivery.mjs enforces the selected device and records install, launch and post-verification separately. USB was selected by the Founder’s 22 Nov “GO wired”, superseding the earlier wireless choice for this delivery.

Exactly one full native PROFILE build used the approved DOC-ZYRA-0448 route. Flutter ran inside no_git.sb with cached packages. All eight Swift revisions and locks stayed fixed, with no fetch detected. The temporary Xcode preference was unset → YES → unset, including verified restoration. The same valid development profile and signing certificate were used. The signed Associated Domains entitlement is exactly applinks:zyraconnect.app.

Initial wired preflights encountered an idle tunnel. A live lock-state query followed immediately by the strict protected check passed. On the dispatcher’s instruction, a temporary read-only lock-state poll kept that exact provisioned phone’s tunnel active during the final artifact rehash and delivery. The poll stopped immediately after each operation.

The separate exact-build GO was “GO — install this build.” The delivery required the same sole provisioned paired USB iPhone, connected tunnel and live unlocked state. Artifact and receipt checks ran before installation and launch and after delivery. There was one installation attempt and no retry.

## Evidence and checks

The protected host remains at SOURCE/build/ios/line117-native-2026-11-22/products/Runner.app. It has 179 files and artifact SHA256 44f47f43b66a840b6c95d4eb89e98e43f325818c652d9fe23d05e178d9fcec5d. Its source seal and BUILD.json stay beside the host. The successful build receipt SHA256 is acfe159fa7f0a2b86051a258144c63e29b9eee415ead60963ac0f347a87b0358.

The exact protected install receipt is under products/PHONE/attempt-1/DELIVERY.json. Sanitized tracked records are NATIVE_BUILD_2026-11-22.json and INSTALL_2026-11-22.json in this folder. Both capture attempts showed another app instead of ZYRA; those images were moved to the single Mac delete folder and excluded from evidence. The visual confirmation is the Founder’s own report.

Flutter 3.44.2 analyzer was clean. All 168 focused profile-video/code tests and 99 route tests passed. Native-inspect, strict signing/profile/certificate/entitlements/engine checks and independent measured-pin review passed. Hosted full CI45010620612 and the pin/readiness source CI45011874498 passed. Phone checks a–d remain deferred.

## Continuation

Resume the tracked phone action when the Founder requests it. Preserve the successful one-install receipt and exact artifact. A new installation is a separate delivery decision. Keep the link grammar and existing messages. Use current Founder local sample controls for preview testing and an existing real-member session for step 5(d). The server rollout and a found card opened from a live link remain under OA-ZYRA-317.
