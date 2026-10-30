---
id: ASBUILT-ZYRA-QUEUE40
type: HANDOVER
status: CURRENT
feature: PHONE ACCESS
purpose: LOCK12 V2 Phone access implementation, boundaries, evidence and remaining native proof
links: [AD-AIOS-115, OA-ZYRA-286, OA-ZYRA-317, OA-ZYRA-323]
owner: Codex
---

# Phone access — queue 40, LOCK12 V2

Queue 40 builds the Founder preview's Phone access page from `PRODUCT/APPROVED/PHONE_ACCESS/BRIEFS/BUILD_BRIEF_2026-10-30_V2.md`, `RECORD/LOCK_RECORD.md`, `RECORD/PHONE_ACCESS_SPEC_CURRENT_VERSION_V2.md` and both current `MASTERS/` images. This replaces the withdrawn failed preflight at queue 27; its evidence remains untouched. The source/render manifest and BUILD.json in `REPORTS/EVIDENCE/LOCK12_PHONE_ACCESS_V2_2026-10-30/` identify the tested source and two real renders. Independent verification and Founder acceptance remain separate.

## Current behaviour and entry

Founder Settings → PRIVACY now has Phone access after the existing Privacy rows, with NEW until first opened. Seeker keeps Pause My Profile / Hidden Profiles; Guardian keeps Pause My Profile / Guardian privacy. The receipt persists locally as `zyra_phone_access_seen_v1`; it establishes no account authority. A failed receipt read leaves NEW visible. Public member/sign-in routes and the OA-ZYRA-286 Founder gate are unchanged.

The page shows the five locked rows, exact reasons and footer, a single glass card and status pills. Opening performs metadata reads only. Every tap re-reads status: not determined requests the native permission immediately; previously determined opens iPhone Settings → ZYRA. There is no extra ZYRA explanation sheet. Unknown/unsupported status fails closed as Ask first (Face ID remains On/Off from actual App lock) and performs no unsupported request. Returning from Settings refreshes metadata.

## Live files and ownership

- `SOURCE/lib/dev/zyra_one_journey_account_presentation.dart`: Settings row and bright journeyGold NEW tag; additive seen field/action.
- `SOURCE/lib/dev/zyra_one_journey_concept_shell.dart`: admitted route, local education receipt and callbacks bound to route, role, UI revision, developer-controls epoch and navigation stamp.
- `SOURCE/lib/dev/zyra_one_journey_phone_access.dart`: page/presentation and controller. Controller owns metadata and one pending action; it observes lifecycle and the real `ZyraAppLock.instance`. No sample switch changes permission or App lock.
- `SOURCE/ios/Runner/AppDelegate.swift`: retained stock MethodChannel adapter for authorization metadata, explicit permission requests, Settings and cancellation. Registered with the implicit Flutter engine; no dependency or project-file change.
- `SOURCE/ios/Runner/Info.plist`: only Camera, Photos and Face ID purpose strings changed to the exact LOCK12 V2 text.
- `SOURCE/lib/services/zyra_app_lock.dart`: records a prompt-attempt receipt through the channel; preserves existing authentication policy, single-flight and generation checks, including a check after the new asynchronous receipt boundary.
- `SOURCE/test/zyra_phone_access_lock12_test.dart` and `SOURCE/test/visual/lock12_phone_access_capture_test.dart`: mocked permission/lifetime and actual-shell render/contract checks.

## Native boundary, data and lifecycle

The adapter uses UNUserNotificationCenter settings/authorization, PHPhotoLibrary readWrite authorization, AVCaptureDevice video authorization, CLLocationManager authorization only and LAContext. Metadata reads never request a permission, start a camera/capture session, fetch images, acquire a location fix or register a remote push token. No Contacts, microphone, tracking or Always request/key was added. Settings uses UIApplication.openSettingsURLString. The existing LOCK11 rough-location class is byte-identical to the starting index, including reduced accuracy, native rounding and cancellation; its trimmed class SHA256 is `bbc915e5752cf84b85952418935c0b2b5f9a63c4575e1727894936d370866ca6`. Location purpose and PhotoLibraryAdd text are unchanged. No coordinate crosses the new channel. Existing Location revocation and background clearing remain active.

Dart rejects stale replies across account ID/generation, sign-out, admission, route and developer-control changes. Temporary inactive state preserves an OS permission prompt; background cancels pending work and clears cached grants. Resume re-reads permission metadata without requesting it. Repeated taps are single-flight. The newest controller owns channel cancellation, so disposing an obsolete page cannot cancel its replacement's request. Native UUID checks prevent late completions affecting a new operation; background invalidates LAContext and releases a pending authorization result. Some system permission dialogs cannot be programmatically dismissed; their late replies are ignored. No result enables App lock or grants product access.

Apple exposes no separate Face ID authorization-status API. Native uses a device-local prompt-attempt receipt (`zyra_face_id_prompt_attempted_v1`) to distinguish subsequent taps, augmented by the actual App lock state; capability is never the On/Off pill. Existing App lock authentication records attempts as well. Historical permission use before this receipt existed cannot be perfectly reconstructed: an already-granted but currently disabled App lock may perform one authentication attempt on the first Phone access tap, then route to Settings thereafter. Written scope refusal: no private TCC inspection or invented consent state. This native edge and all actual prompt/Settings behaviour remain OA-ZYRA-323 device-proof work. Face ID taps here never toggle App lock.

## Validation, comparison and limits

Primary alone ran SDK commands through the pinned `node tooling/no_git_driver.mjs` wrapper. Final analyser is clean. Seven suites passed 95 distinct cases: 38 permission-controller/presentation cases, 14 App lock lifecycle, five actual-shell/capture/Info.plist cases, 30 LOCK11 controller/visual cases, one compiled-app boundary and seven existing Settings lifetime cases. The final bright-gold badge adjustment was recaptured with the five-case actual-shell suite and eight public/settings checks (13 pass, overlapping the 95). Source/plist checks and parent read-only native review are separate from execution. The first grouped regression exposed a test scope issue: its LOCK11 suffix scan included the newly appended adapter. Moving the adapter before the unchanged final Location class restored the intended privacy contract; final 87-case grouped run passed. No whole-suite claim.

Both 1290×2796 renders and two master-beside-build sheets are in `PRODUCT/APPROVED/PHONE_ACCESS/BUILT/`. Capture uses actual shell routes and bundled fonts; permission metadata is mocked to match the master, App lock is actually Off. Small-phone 320pt and 200% text remains scrollable without overflow. Current Settings header alignment is retained; font/glyph/line-break metrics, existing Settings cards and the prototype rounded frame differ. No pixel-parity claim. Exact bright gold is #E8C98A on new badges/icons/allowed pills. No native prompt or Settings screenshot was fabricated.

No dependency, backend, migration, signing, production data, upload, publication, native build/install or old-member/sign-in retirement. OA-ZYRA-317 owns member integration; OA-ZYRA-323 owns native compilation/device proof; Fable owns protected blueprint/inventory and existing document-size maintenance. No PRODUCT/BLUEPRINT edit or queue 39/35 work. Parent verifies this row, task note, source/render SHA256 manifest and commits, then archives this chat.
