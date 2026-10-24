> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Superseded by `ZYRA_GUARDIAN_NETWORK_MODES_HANDOVER_CURRENT_VERSION_V3.md`. The supersession DATE is not recorded in
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
- Owns: Guardian Network mode navigation, Seeker-context selection, and request-action presentation on the Network page.
- References: Guardian Network request stages, linked Seekers, Guardian relationship authority, and current ZYRA action styling.
- Referenced By: Guardian Network discovery and request-management surfaces.

## APPROVED SUMMARY

Guardian Network has three horizontally swipeable modes: `Browser`, `Sent requests`, and `Received`. A family can appear in Browser only while its relationship stage is untouched. Sent and received families appear only in their relevant request area.

The selected Seeker now appears as an integrated full-width context row beneath the mode control. `SEEKER` sits quietly on the left; the selected name and dropdown chevron sit on the right. The previous floating name pill is retired.

The received-request action `Connect with this family` uses ZYRA's current restrained gold-accent treatment. The legacy lavender filled action is retired from this surface.

## SCRIPT SUMMARY

- The segmented mode control represents Browser, sent requests, and received requests; its fill follows the horizontal page swipe.
- The linked-Seeker selector writes the shared `GNContext` through a dropdown integrated into a quiet context row.
- `GNContext.servedFamily` returns only `GNStage.none` families.
- `GNStage.sent` families render in `Sent requests`; `GNStage.incoming` families render in `Received`.
- Sending a request removes the family from Browser immediately and advances Browser to the next untouched family.
- Received-request connection uses `GNActionPill.goldAccent`, not the legacy primary lavender fill.
- Existing request withdrawal, incoming connect, incoming decline, analytics, limits, and Main Guardian authority remain unchanged.
- No database, RLS, membership, compatibility, or production-service changes were made.

## FLOW BLUEPRINT

`Network` → swipe/tap `Browser` | `Sent requests` | `Received`

`SEEKER context row` → dropdown → choose linked Seeker → all three modes update

`Browser` → `Send request` → family removed from Browser → family appears in `Sent requests`

`Received` → `Connect with this family` in current gold-accent style

## VERIFICATION

- Guardian Network Flutter tests: 14 passed.
- Flutter analyser: no issues found.
- iOS profile build: succeeded.
- Wireless installation and launch completed on device `00008130-001A2C1E26F8001C`.
- Bundle: `app.zyraconnect.zyra`.
- App binary SHA-256: `6dc65681870422a485a29f41382a84ef2c64083202d669716181fcb3735280a5`.

## APPROVED TO-DO LIST

- Founder visual review of the integrated Seeker context row and gold connection action.
