---
id: DOC-ZYRA-GSEEKERS-ASBUILT-V1
type: HANDOVER
status: CURRENT
feature: GUARDIAN SEEKERS PAGE
purpose: As-built LOCK 35 Founder-preview Seekers swipe cards, queue line 122
links: [DOC-ZYRA-GSEEKERS-V1, AD-AIOS-115, AD-AIOS-147, OA-ZYRA-317]
owner: Codex
---
# Guardian Seekers — as built

Built on 19 Nov 2026 from the LOCK 35 V1 spec, LOCK record, build brief of
18 Nov and Q168's ten V275 masters. The Founder-preview Guardian Seekers tab
now shows Adam, Yusuf and Invite as full-height cards. Dots settle with the
shared swipe track. The header offers Circle and Invite. Detail rows reuse
Seeker details; an available Current Journey selects the existing Journeys tab.
The Circle row opens that Seeker's Circle; Guardian Basic remains read only.

## Live files and boundaries
- `SOURCE/lib/dev/zyra_one_journey_guardian_seekers.dart`: presentation and local
  card index, shared title/monogram/card tokens/dots/swipe/haptic helpers; a
  short or enlarged-text card scrolls inside its fixed frame.
- `SOURCE/lib/dev/zyra_one_journey_guardian_tabs.dart`: replaces the old stacked
  roster with the pager. Existing details and remaining Guardian tabs stay here.
- `SOURCE/lib/dev/zyra_one_journey_concept_shell.dart`: caller-owned permitted
  Journey projection, selected Seeker and guarded navigation. Adam's permitted
  data remains independent while the neighbouring card is visible; Yusuf's
  sample has no Journey. Every settled selection revokes previous callbacks.
  Invite retains the last real Seeker identity and never becomes a third Seeker.
- `SOURCE/test/visual/lock35_guardian_seekers_test.dart`: twelve tests of actual
  offline shell navigation, swipe/dots, Circle roles, empty/Invite, callback
  revocation, phone geometry, 2x text, Reduce Motion and shared errors; captures.
- Updated existing visual tests: `lock24_tab_spacing_test.dart`,
  `zyra_visual_regression_test.dart`, `line104_own_photo_test.dart`,
  `lock8_guardian_tabs_capture_test.dart` in `SOURCE/test/visual/`. Their old
  stacked-card/photo assumptions are replaced; access and identity checks remain.
- `README.md` describes the new visible behaviour. The planned screen inventory
  and MAP are regenerated. No old roster widget file remains to retire.

## Data, entry and limits
Only the existing admitted Founder shell reaches this sample presentation.
The ordinary member roster, server, sign-in, payment and permission authority
are unchanged. The shell checkpoint persists real Seeker choice (0 or 1), not
Invite. The existing loading spinner, Invite your Seeker destination, Journeys
page and full-screen error components remain the shared states named in Q168.
No developer control or production route is added. No migrations.

This is local sample behaviour, not a server integration (OA-ZYRA-317). The
existing Invite destination retains its existing comparison message and sends
no real invitation. Written refusal: no live authority or new Invite flow is
added by this UI brief. Native iPhone installation and device observation are
PENDING: Founder away; this task is explicitly not a phone-delivery request.
No compiled apps, source copies or one-off scripts are evidence.

## Verification and authority
All ten masters were reopened and verified as 1290x2796 pixels, with the
role, Journey, Invite, empty, Circle and error coverage recorded in Q168.
Ten actual built PNGs are under `BUILT/LINE122_BUILD/`; comparison pairs put
masters beside the build. Shared app font/icons/title/navigation/card tokens
remain authoritative where the HTML reference raster differs from Flutter.
`LINE122_CHECKS.json` records exact tests and results; `BUILD.json` identifies
source commit, Flutter version, mode and timestamp. Logs are ignored under
`SOURCE/build/line122/`. Initial focus: 12 passed; expanded focus: 268 passed,
2 test timing failures; corrected focus: 14 passed. Final gate: 7,341 visible tests passed, 124 skipped, zero failures (466.876 s).
Final analysis: no issues (5.7 s); twelve post-lint focus tests pass.
Hosted line 118 CI passed; this line's hosted CI is PENDING after push.
Independent review found one callback-generation gap across Invite; corrected
with transition tests. Review of the correction: PASS. All ten final captures were reviewed against
the masters. They are not pixel-identical: the unchanged Circle uses a shorter
message fixture and the unchanged Journeys destination uses the test silhouette;
Flutter's existing shared title, nav, icon and shadow metrics remain in use.

Product authority: `RECORD/GUARDIAN_SEEKERS_SPEC_CURRENT_VERSION_V1.md` and
`RECORD/LOCK_RECORD.md`; build contract: `BRIEFS/BUILD_BRIEF_2026-11-18_V1.md`;
this handover records implementation. Q168 answered the former picture gap.
Next: Fable/ZYRA Claude compare the recorded built pictures in their normal
review; live connection remains with OA-ZYRA-317 and device delivery with its
own Founder-present line.
