> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Superseded by `ZYRA_GUARDIAN_NETWORK_MODES_HANDOVER_CURRENT_VERSION_V2.md`. The supersession DATE is not recorded in
> these documents and cannot be recovered from the filesystem — all versions
> share one mtime — so none is stated here rather than an inferred one.
> The current version is `ZYRA_GUARDIAN_NETWORK_MODES_HANDOVER_CURRENT_VERSION_V4.md`, in this folder.
> This file keeps its `CURRENT_VERSION` filename deliberately. Renaming it
> would break references held in the registers and in sealed mailbox messages,
> which are never edited after filing. Recorded under **OA-AIOS-384**.
> Banner added by Fable 2026-09-23 under AD-AIOS-110. **The body below is
> unchanged** and remains the truthful record of what was current at the time.

---

# FEATURE NAME

Guardian Network Modes

## PROJECT LOCATION

- Major Folder: `02_NAVIGATION/`
- Purpose: Separate untouched Network discovery from sent and received Guardian requests.
- Owns: Guardian Network mode navigation and Seeker-context selection on the Network page.
- References: Guardian Network request stages, linked Seekers, Guardian relationship authority, and Dashboard connection context.
- Referenced By: Guardian Network discovery and request-management surfaces.

## APPROVED SUMMARY

Guardian Network has three horizontally swipeable modes: `Browser`, `Sent requests`, and `Received`. The selected Seeker is controlled by a compact dropdown beneath the modes on the right.

A family can appear in Browser only while its relationship stage is untouched. As soon as either family sends a request, that family leaves Browser and appears only in the relevant request area. The previous Browser merge card stating that a family had already requested connection is retired.

## SCRIPT SUMMARY

- The Network top segmented control now represents Browser, sent requests, and received requests.
- Its selected fill follows the horizontal mode-page swipe.
- Sent and received counts can surface as existing unseen dots on their segments.
- The linked-Seeker slider was replaced on this page by a right-aligned dropdown; selection still writes the shared `GNContext`, preserving Dashboard context.
- `GNContext.servedFamily` now returns only `GNStage.none` families.
- `GNStage.sent` families render in `Sent requests`; `GNStage.incoming` families render in `Received`.
- Sending a request removes the family from Browser immediately and advances Browser to the next untouched family.
- Existing request withdrawal, incoming connect, incoming decline, analytics, limits, and Main Guardian authority remain unchanged.
- No database, RLS, membership, compatibility, or production-service changes were made.

## FLOW BLUEPRINT

`Network` → swipe/tap `Browser` | `Sent requests` | `Received`

`Seeker dropdown` → choose linked Seeker → all three modes update to that Seeker

`Browser` → `Send request` → family removed from Browser → family appears in `Sent requests`

`External incoming request` → never appears in Browser → appears in `Received`

## VERIFICATION

- Related Flutter tests: 63 passed.
- Flutter analyser: no issues found.
- iOS profile build: succeeded.
- Wireless installation and launch completed on device `00008130-001A2C1E26F8001C`.
- Bundle: `app.zyraconnect.zyra`.
- App binary SHA-256: `526c07903b6f48dc1d1333f968dd4de40fe1c5cf7938a7ed58d1d931eef9b2cc`.

## APPROVED TO-DO LIST

- Founder visual review of mode labels, swipe behaviour, request lists, and Seeker dropdown placement.
