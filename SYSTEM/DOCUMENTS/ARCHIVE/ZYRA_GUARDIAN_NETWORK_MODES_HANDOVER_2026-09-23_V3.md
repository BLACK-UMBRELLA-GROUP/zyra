> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Superseded by `ZYRA_GUARDIAN_NETWORK_MODES_HANDOVER_CURRENT_VERSION_V4.md`. The supersession DATE is not recorded in
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
- Owns: Guardian Network mode navigation, header-level Seeker selection, and request-action presentation.
- References: Guardian Network request stages, linked Seekers, Guardian relationship authority, and current ZYRA action styling.
- Referenced By: Guardian Network discovery and request-management surfaces.

## APPROVED SUMMARY

Guardian Network has three horizontally swipeable modes: `Browser`, `Sent requests`, and `Received`. The active Seeker is displayed in the main page header: `Network` on the left and the selected Seeker name with a dropdown chevron on the right.

The separate Seeker context row is retired. Selecting the name in the header opens the same linked-Seeker dropdown and updates all three Network modes.

A family can appear in Browser only while its relationship stage is untouched. Sent and received families appear only in their relevant request area. Received-request connection uses the current restrained gold-accent action treatment.

## SCRIPT SUMMARY

- The segmented mode control represents Browser, sent requests, and received requests; its fill follows the horizontal page swipe.
- The header-level Seeker control writes the shared `GNContext` through the existing dropdown.
- The page title and selected Seeker share one vertically aligned title row.
- `GNContext.servedFamily` returns only `GNStage.none` families.
- `GNStage.sent` families render in `Sent requests`; `GNStage.incoming` families render in `Received`.
- Sending a request removes the family from Browser immediately and advances Browser to the next untouched family.
- Received-request connection uses `GNActionPill.goldAccent`, not the legacy primary lavender fill.
- No database, RLS, membership, compatibility, or production-service changes were made.

## FLOW BLUEPRINT

`Network header` → selected Seeker name → linked-Seeker dropdown → all modes update

`Network` → swipe/tap `Browser` | `Sent requests` | `Received`

`Browser` → `Send request` → family removed from Browser → family appears in `Sent requests`

## VERIFICATION

- Guardian Network Flutter tests: 14 passed.
- Flutter analyser: no issues found.
- iOS profile build: succeeded.
- Wireless installation completed on device `00008130-001A2C1E26F8001C`.
- Automatic relaunch was blocked because the iPhone was locked; the installed app remains available for manual opening.
- Bundle: `app.zyraconnect.zyra`.
- App binary SHA-256: `366faf3392cde0593ae087ca5d55d5d5e2ade9d5665b04436ac458d16b347406`.

## APPROVED TO-DO LIST

- Founder visual review of the header-level Seeker selector.
