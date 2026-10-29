---
id: OA-ZYRA-316-BASELINE-2026-10-29
type: INDEX
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Generated capture artifact for DOC-ZYRA-0301; every available planned-app page and local preview state
links: [DOC-ZYRA-0301, DOC-ZYRA-0278, DOC-ZYRA-0286, OA-ZYRA-316]
owner: Codex (capture only)
---

# Founder preview baseline — 29 Oct 2026

Built from: not a design task (capture), `PRODUCT/APPROVED/BASELINE/CAPTURE_BRIEF_2026-10-29.md`.
These pictures are review inputs, not a LOCK record. App source commit: `d08b2d17884dd44b4c22676a61175ef8c0619871`.

Route (c): Flutter visual-test render at **430 × 932 logical, DPR 3; 1290 × 2796 PNG**. The native build driver is held
following its SwiftPM nested-sandbox refusal. No native build, install or bypass was attempted. The paired phone is now
available, but that does not clear the held build route. The iOS status bar is absent; its safe area is preserved.
Actual app headers and tabs remain where the shell shows them; leaf pages naturally omit the tab bar. Long pages use
the full phone viewport, with separately indexed scroll/chapter states. No stitching or cropping.

The harness reads the production `ZyraApp` theme and scroll behavior without mounting startup, authentication or lock
wrappers. It uses the iOS test target, real bundled Poppins/Syne and decoded offline sample portraits. The system San
Francisco font is loaded in memory only for missing glyph fallback (the verified check symbol); no font asset was copied.
The environment receipt records its hash. No member data, backend transport or app source was changed.

All picture states below are current local preview states. A normal, empty, loading, error or held state with no separate
reachable local control is **not in preview** for that page; none was invented. Native camera, photo picker and keyboard
surfaces are outside this headless preview. Retired Saved/Paused destinations and unavailable role/page pairs are recorded
below. Notifications remains in the generated inventory but has no current opener; see the coverage notes.

## Pictures

Paths are relative to this `SCREENSHOTS/` folder. Each row is one PNG; role, area, inventory page ID, state and actual
checkpoint/taps/control path are retained. Source areas follow DOC-ZYRA-0278 §3.

| Role | Area | Page ID | State | Reached through | PNG path |
|---|---|---|---|---|---|
| Guardian | guardians | controls | circle_contextCards | Actual hold-to-open controls, selected existing Circle interior | [PNG](guardian/guardians/controls__circle_contextCards.png) |
| Guardian | guardians | controls | circle_current | Actual hold-to-open controls, selected existing Circle interior | [PNG](guardian/guardians/controls__circle_current.png) |
| Guardian | guardians | controls | circle_journeyRail | Actual hold-to-open controls, selected existing Circle interior | [PNG](guardian/guardians/controls__circle_journeyRail.png) |
| Guardian | guardians | controls | circle_portraitTiles | Actual hold-to-open controls, selected existing Circle interior | [PNG](guardian/guardians/controls__circle_portraitTiles.png) |
| Guardian | guardians | controls | circle_quietList | Actual hold-to-open controls, selected existing Circle interior | [PNG](guardian/guardians/controls__circle_quietList.png) |
| Guardian | guardians | controls | circle_segmentedCards | Actual hold-to-open controls, selected existing Circle interior | [PNG](guardian/guardians/controls__circle_segmentedCards.png) |
| Guardian | guardians | controls | root_0 | Actual Guardian root 0 admitted hold; contextual controls visible. | [PNG](guardian/guardians/controls__root_0.png) |
| Guardian | guardians | controls | root_1 | Actual Guardian root 1 admitted hold; contextual controls visible. | [PNG](guardian/guardians/controls__root_1.png) |
| Guardian | guardians | controls | root_2 | Actual Guardian root 2 admitted hold; contextual controls visible. | [PNG](guardian/guardians/controls__root_2.png) |
| Guardian | guardians | guardian | active_journey | Actual embedded Seeker workspace > Open current Journey. | [PNG](guardian/guardians/guardian__active_journey.png) |
| Guardian | guardians | guardian_circle | bubble_contextCards | Actual controls choice 5 · Context cards, then X | [PNG](guardian/guardians/guardian_circle__bubble_contextCards.png) |
| Guardian | guardians | guardian_circle | bubble_current | Actual controls choice Current, then X | [PNG](guardian/guardians/guardian_circle__bubble_current.png) |
| Guardian | guardians | guardian_circle | bubble_journeyRail | Actual controls choice 3 · Journey rail, then X | [PNG](guardian/guardians/guardian_circle__bubble_journeyRail.png) |
| Guardian | guardians | guardian_circle | bubble_portraitTiles | Actual controls choice 2 · Initial tiles, then X | [PNG](guardian/guardians/guardian_circle__bubble_portraitTiles.png) |
| Guardian | guardians | guardian_circle | bubble_quietList | Actual controls choice 1 · Quiet list, then X | [PNG](guardian/guardians/guardian_circle__bubble_quietList.png) |
| Guardian | guardians | guardian_circle | bubble_segmentedCards | Actual controls choice 4 · Segmented cards, then X | [PNG](guardian/guardians/guardian_circle__bubble_segmentedCards.png) |
| Guardian | guardians | guardian_circle | normal | Actual allowed Guardian Circle checkpoint with local sample transcript | [PNG](guardian/guardians/guardian_circle__normal.png) |
| Guardian | guardians | guardian_linked_profile | normal | Actual Guardian My ZYRA family card > View profile. | [PNG](guardian/guardians/guardian_linked_profile__normal.png) |
| Guardian | guardians | guardian_network_profile | normal | Actual Guardian Network > View profile. | [PNG](guardian/guardians/guardian_network_profile__normal.png) |
| Guardian | guardians | held_action | invite_seeker | Actual unlinked Guardian Network > Invite your Seeker; held local explanation. | [PNG](guardian/guardians/held_action__invite_seeker.png) |
| Guardian | guardians | network_request | confirmation | Actual Guardian Network > Speak to Guardian; no request sent. | [PNG](guardian/guardians/network_request__confirmation.png) |
| Guardian | guardians | tab_my_zyra | basic_insights_locked | Safe local checkpoint matching the actual Guardian Basic plan control. | [PNG](guardian/guardians/tab_my_zyra__basic_insights_locked.png) |
| Guardian | guardians | tab_my_zyra | no_current_journey | Fresh local Guardian preview with linked Seeker and no Active Journey. | [PNG](guardian/guardians/tab_my_zyra__no_current_journey.png) |
| Guardian | guardians | tab_my_zyra | normal | Guardian root tab 0 with one supported local Active Journey. | [PNG](guardian/guardians/tab_my_zyra__normal.png) |
| Guardian | guardians | tab_my_zyra | unlinked_empty | Safe local checkpoint after supported Guardian unlink; Guardian root 0. | [PNG](guardian/guardians/tab_my_zyra__unlinked_empty.png) |
| Guardian | guardians | tab_network | additional_guardian_held | Safe local checkpoint after supported Main change; Hassan is Additional. | [PNG](guardian/guardians/tab_network__additional_guardian_held.png) |
| Guardian | guardians | tab_network | normal | Guardian root tab 1 with one supported local Active Journey. | [PNG](guardian/guardians/tab_network__normal.png) |
| Guardian | guardians | tab_network | received_empty | Actual Guardian Network Received tab; no received fixture exists. | [PNG](guardian/guardians/tab_network__received_empty.png) |
| Guardian | guardians | tab_network | sent_populated | Actual local Speak confirmation > Sent tab. | [PNG](guardian/guardians/tab_network__sent_populated.png) |
| Guardian | guardians | tab_network | unlinked_empty | Safe local checkpoint after supported Guardian unlink; Guardian root 1. | [PNG](guardian/guardians/tab_network__unlinked_empty.png) |
| Guardian | guardians | tab_seekers | normal | Guardian root tab 2 with one supported local Active Journey. | [PNG](guardian/guardians/tab_seekers__normal.png) |
| Guardian | guardians | tab_seekers | unlinked_empty | Safe local checkpoint after supported Guardian unlink; Guardian root 2. | [PNG](guardian/guardians/tab_seekers__unlinked_empty.png) |
| Guardian | profile_membership_settings | account_action | cancel_membership_held | Actual Current Membership > Cancel membership; held explanation only. | [PNG](guardian/profile_membership_settings/account_action__cancel_membership_held.png) |
| Guardian | profile_membership_settings | account_action | invite_held | Profile > Invite someone to ZYRA; actual held local action. | [PNG](guardian/profile_membership_settings/account_action__invite_held.png) |
| Guardian | profile_membership_settings | account_action | overview_advanced | Safe local Settings parent chain; advanced overview. | [PNG](guardian/profile_membership_settings/account_action__overview_advanced.png) |
| Guardian | profile_membership_settings | account_action | overview_appLock | Safe local Settings parent chain; appLock overview. | [PNG](guardian/profile_membership_settings/account_action__overview_appLock.png) |
| Guardian | profile_membership_settings | account_action | overview_feedback | Safe local Settings parent chain; feedback overview. | [PNG](guardian/profile_membership_settings/account_action__overview_feedback.png) |
| Guardian | profile_membership_settings | account_action | overview_guardianPrivacy | Safe local Settings parent chain; guardianPrivacy overview. | [PNG](guardian/profile_membership_settings/account_action__overview_guardianPrivacy.png) |
| Guardian | profile_membership_settings | account_action | overview_notificationSettings | Safe local Settings parent chain; notificationSettings overview. | [PNG](guardian/profile_membership_settings/account_action__overview_notificationSettings.png) |
| Guardian | profile_membership_settings | account_action | overview_privacyData | Safe local Settings parent chain; privacyData overview. | [PNG](guardian/profile_membership_settings/account_action__overview_privacyData.png) |
| Guardian | profile_membership_settings | account_action | overview_signInSecurity | Safe local Settings parent chain; signInSecurity overview. | [PNG](guardian/profile_membership_settings/account_action__overview_signInSecurity.png) |
| Guardian | profile_membership_settings | account_action | overview_visibility | Safe local Settings parent chain; visibility overview. | [PNG](guardian/profile_membership_settings/account_action__overview_visibility.png) |
| Guardian | profile_membership_settings | compatibility_store | normal | Restored safe local Profile checkpoint to compatibility_store; unchanged shell. | [PNG](guardian/profile_membership_settings/compatibility_store__normal.png) |
| Guardian | profile_membership_settings | controls | profile | Actual admitted three-second hold on Profile; controls intentionally visible. | [PNG](guardian/profile_membership_settings/controls__profile.png) |
| Guardian | profile_membership_settings | help_support | normal | Restored safe local Profile checkpoint to help_support; unchanged shell. | [PNG](guardian/profile_membership_settings/help_support__normal.png) |
| Guardian | profile_membership_settings | help_support | search_empty | Actual local Help search field > unmatched query; no answer invented. | [PNG](guardian/profile_membership_settings/help_support__search_empty.png) |
| Guardian | profile_membership_settings | help_support | search_matches | Actual local Help search field > sign in. | [PNG](guardian/profile_membership_settings/help_support__search_matches.png) |
| Guardian | profile_membership_settings | membership | basic_history_neverPaid | Actual Membership controls > neverPaid > Basic role pager. | [PNG](guardian/profile_membership_settings/membership__basic_history_neverPaid.png) |
| Guardian | profile_membership_settings | membership | basic_history_unknown | Actual Membership controls > unknown > Basic role pager. | [PNG](guardian/profile_membership_settings/membership__basic_history_unknown.png) |
| Guardian | profile_membership_settings | membership | basic_paid_before | Membership role pager > Basic; unchanged previously-paid example. | [PNG](guardian/profile_membership_settings/membership__basic_paid_before.png) |
| Guardian | profile_membership_settings | membership | section_current | Profile > Membership > actual current section control. | [PNG](guardian/profile_membership_settings/membership__section_current.png) |
| Guardian | profile_membership_settings | membership | section_family | Profile > Membership > actual family section control. | [PNG](guardian/profile_membership_settings/membership__section_family.png) |
| Guardian | profile_membership_settings | membership | section_guardian | Profile > Membership > actual guardian section control. | [PNG](guardian/profile_membership_settings/membership__section_guardian.png) |
| Guardian | profile_membership_settings | membership | section_guardian_basic | Actual guardian membership pager > second Basic card. | [PNG](guardian/profile_membership_settings/membership__section_guardian_basic.png) |
| Guardian | profile_membership_settings | membership | section_seeker | Profile > Membership > actual seeker section control. | [PNG](guardian/profile_membership_settings/membership__section_seeker.png) |
| Guardian | profile_membership_settings | membership | section_seeker_basic | Actual seeker membership pager > second Basic card. | [PNG](guardian/profile_membership_settings/membership__section_seeker_basic.png) |
| Guardian | profile_membership_settings | membership | section_unlocks | Profile > Membership > actual unlocks section control. | [PNG](guardian/profile_membership_settings/membership__section_unlocks.png) |
| Guardian | profile_membership_settings | membership_review | basic_paid_before | Actual Basic selection > Review selection; no store or payment. | [PNG](guardian/profile_membership_settings/membership_review__basic_paid_before.png) |
| Guardian | profile_membership_settings | personalisation | background_choices | Actual Personalisation > Background choice sheet; nothing selected. | [PNG](guardian/profile_membership_settings/personalisation__background_choices.png) |
| Guardian | profile_membership_settings | personalisation | haptic_choices | Actual Personalisation > Haptic feel choice sheet; nothing selected. | [PNG](guardian/profile_membership_settings/personalisation__haptic_choices.png) |
| Guardian | profile_membership_settings | personalisation | normal | Restored safe local Profile checkpoint to personalisation; unchanged shell. | [PNG](guardian/profile_membership_settings/personalisation__normal.png) |
| Guardian | profile_membership_settings | safety | no_subject | Profile > Safety & advice; actual local action, no person selected. | [PNG](guardian/profile_membership_settings/safety__no_subject.png) |
| Guardian | profile_membership_settings | settings | normal | Restored safe local Profile checkpoint to settings; unchanged shell. | [PNG](guardian/profile_membership_settings/settings__normal.png) |
| Guardian | profile_membership_settings | settings_detail | appLock | Safe local Settings > appLock > appLock chain. | [PNG](guardian/profile_membership_settings/settings_detail__appLock.png) |
| Guardian | profile_membership_settings | settings_detail | deleteAccount | Safe local Settings > advanced > deleteAccount chain. | [PNG](guardian/profile_membership_settings/settings_detail__deleteAccount.png) |
| Guardian | profile_membership_settings | settings_detail | discovery | Safe local Settings > visibility > discovery chain. | [PNG](guardian/profile_membership_settings/settings_detail__discovery.png) |
| Guardian | profile_membership_settings | settings_detail | feedback | Safe local Settings > feedback > feedback chain. | [PNG](guardian/profile_membership_settings/settings_detail__feedback.png) |
| Guardian | profile_membership_settings | settings_detail | notifications | Safe local Settings > notificationSettings > notifications chain. | [PNG](guardian/profile_membership_settings/settings_detail__notifications.png) |
| Guardian | profile_membership_settings | settings_detail | privacyPolicy | Safe local Settings > privacyData > privacyPolicy chain. | [PNG](guardian/profile_membership_settings/settings_detail__privacyPolicy.png) |
| Guardian | profile_membership_settings | settings_detail | recovery | Safe local Settings > signInSecurity > recovery chain. | [PNG](guardian/profile_membership_settings/settings_detail__recovery.png) |
| Guardian | profile_membership_settings | settings_detail | resetProfile | Safe local Settings > advanced > resetProfile chain. | [PNG](guardian/profile_membership_settings/settings_detail__resetProfile.png) |
| Guardian | profile_membership_settings | settings_detail | terms | Safe local Settings > privacyData > terms chain. | [PNG](guardian/profile_membership_settings/settings_detail__terms.png) |
| Guardian | profile_membership_settings | subscriptions | normal | Profile > Your subscriptions; unchanged local wallet. | [PNG](guardian/profile_membership_settings/subscriptions__normal.png) |
| Guardian | profile_membership_settings | switch_account_setup | normal | Actual switch wallet > Set up other profile; local setup overview. | [PNG](guardian/profile_membership_settings/switch_account_setup__normal.png) |
| Guardian | profile_membership_settings | switch_account_signup | coverage_assignedFamily | Actual Profile controls > other role assignedFamily > Switch. | [PNG](guardian/profile_membership_settings/switch_account_signup__coverage_assignedFamily.png) |
| Guardian | profile_membership_settings | switch_account_signup | coverage_basic | Actual Profile controls > other role basic > Switch. | [PNG](guardian/profile_membership_settings/switch_account_signup__coverage_basic.png) |
| Guardian | profile_membership_settings | switch_account_signup | coverage_individualOne | Actual Profile controls > other role individualOne > Switch. | [PNG](guardian/profile_membership_settings/switch_account_signup__coverage_individualOne.png) |
| Guardian | profile_membership_settings | switch_account_signup | coverage_none | Actual Profile controls > other role none > Switch. | [PNG](guardian/profile_membership_settings/switch_account_signup__coverage_none.png) |
| Guardian | profile_membership_settings | switch_account_signup | coverage_unavailable | Actual Profile controls > other role unavailable > Switch. | [PNG](guardian/profile_membership_settings/switch_account_signup__coverage_unavailable.png) |
| Guardian | profile_membership_settings | switch_account_signup | needs_signup | Actual Profile controls > Needs sign-up with existing coverage > Switch. | [PNG](guardian/profile_membership_settings/switch_account_signup__needs_signup.png) |
| Guardian | profile_membership_settings | tab_profile | normal | Guardian root tab 3 with one supported local Active Journey. | [PNG](guardian/profile_membership_settings/tab_profile__normal.png) |
| Seeker | browse_and_requests | compatibility | locked_zero_unlocks | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/browse_and_requests/compatibility__locked_zero_unlocks.png) |
| Seeker | browse_and_requests | controls | browse_detailsFirst | Actual controls Profile cards choice | [PNG](seeker/browse_and_requests/controls__browse_detailsFirst.png) |
| Seeker | browse_and_requests | controls | browse_originalPhotos | Actual controls Profile cards choice | [PNG](seeker/browse_and_requests/controls__browse_originalPhotos.png) |
| Seeker | browse_and_requests | controls | next_arcEntrance | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_arcEntrance.png) |
| Seeker | browse_and_requests | controls | next_cardDeal | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_cardDeal.png) |
| Seeker | browse_and_requests | controls | next_cardGlide | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_cardGlide.png) |
| Seeker | browse_and_requests | controls | next_cardRise | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_cardRise.png) |
| Seeker | browse_and_requests | controls | next_cardRock | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_cardRock.png) |
| Seeker | browse_and_requests | controls | next_current | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_current.png) |
| Seeker | browse_and_requests | controls | next_elasticCard | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_elasticCard.png) |
| Seeker | browse_and_requests | controls | next_fanTurn | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_fanTurn.png) |
| Seeker | browse_and_requests | controls | next_forwardFlip | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_forwardFlip.png) |
| Seeker | browse_and_requests | controls | next_hingeTurn | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_hingeTurn.png) |
| Seeker | browse_and_requests | controls | next_springPop | Actual existing Next animation choice | [PNG](seeker/browse_and_requests/controls__next_springPop.png) |
| Seeker | browse_and_requests | filters | age_range | Actual Age filter expansion | [PNG](seeker/browse_and_requests/filters__age_range.png) |
| Seeker | browse_and_requests | filters | normal | Profiles → actual options → Filters | [PNG](seeker/browse_and_requests/filters__normal.png) |
| Seeker | browse_and_requests | introductions | empty | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/browse_and_requests/introductions__empty.png) |
| Seeker | browse_and_requests | profile | normal | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/browse_and_requests/profile__normal.png) |
| Seeker | browse_and_requests | profiles_tab | gallery_detailsFirst | Actual controls Profile cards choice then X | [PNG](seeker/browse_and_requests/profiles_tab__gallery_detailsFirst.png) |
| Seeker | browse_and_requests | profiles_tab | gallery_originalPhotos | Actual controls Profile cards choice then X | [PNG](seeker/browse_and_requests/profiles_tab__gallery_originalPhotos.png) |
| Seeker | browse_and_requests | profiles_tab | next_arcEntrance | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_arcEntrance.png) |
| Seeker | browse_and_requests | profiles_tab | next_cardDeal | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_cardDeal.png) |
| Seeker | browse_and_requests | profiles_tab | next_cardGlide | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_cardGlide.png) |
| Seeker | browse_and_requests | profiles_tab | next_cardRise | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_cardRise.png) |
| Seeker | browse_and_requests | profiles_tab | next_cardRock | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_cardRock.png) |
| Seeker | browse_and_requests | profiles_tab | next_current | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_current.png) |
| Seeker | browse_and_requests | profiles_tab | next_elasticCard | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_elasticCard.png) |
| Seeker | browse_and_requests | profiles_tab | next_fanTurn | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_fanTurn.png) |
| Seeker | browse_and_requests | profiles_tab | next_forwardFlip | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_forwardFlip.png) |
| Seeker | browse_and_requests | profiles_tab | next_hingeTurn | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_hingeTurn.png) |
| Seeker | browse_and_requests | profiles_tab | next_springPop | Actual Next animation selection; resting page unchanged | [PNG](seeker/browse_and_requests/profiles_tab__next_springPop.png) |
| Seeker | browse_and_requests | profiles_tab | normal | Fresh local Founder-preview Seeker tab 0 | [PNG](seeker/browse_and_requests/profiles_tab__normal.png) |
| Seeker | browse_and_requests | request_capacity | full | Real received request → Accept while three sample places occupied | [PNG](seeker/browse_and_requests/request_capacity__full.png) |
| Seeker | browse_and_requests | requests | received | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/browse_and_requests/requests__received.png) |
| Seeker | browse_and_requests | requests | received_empty | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/browse_and_requests/requests__received_empty.png) |
| Seeker | browse_and_requests | requests | sent | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/browse_and_requests/requests__sent.png) |
| Seeker | browse_and_requests | requests | sent_empty | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/browse_and_requests/requests__sent_empty.png) |
| Seeker | browse_and_requests | scan | manual_empty | Profiles → actual options → Scan; default manual entry | [PNG](seeker/browse_and_requests/scan__manual_empty.png) |
| Seeker | ended_journeys | ended | empty | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/ended_journeys/ended__empty.png) |
| Seeker | ended_journeys | ended | normal | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/ended_journeys/ended__normal.png) |
| Seeker | ended_journeys | ended | undated_archive | Existing Add Ended history sample fixture | [PNG](seeker/ended_journeys/ended__undated_archive.png) |
| Seeker | ended_journeys | ended_bio | locked | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/ended_journeys/ended_bio__locked.png) |
| Seeker | ended_journeys | ended_bio | shared_archive | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/ended_journeys/ended_bio__shared_archive.png) |
| Seeker | ended_journeys | ended_compatibility | locked | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/ended_journeys/ended_compatibility__locked.png) |
| Seeker | ended_journeys | ended_compatibility | shared_archive | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/ended_journeys/ended_compatibility__shared_archive.png) |
| Seeker | ended_journeys | ended_guardians | locked | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/ended_journeys/ended_guardians__locked.png) |
| Seeker | ended_journeys | ended_guardians | shared_archive | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/ended_journeys/ended_guardians__shared_archive.png) |
| Seeker | ended_journeys | ended_restart | not_available | Ended card → actual Request restart | [PNG](seeker/ended_journeys/ended_restart__not_available.png) |
| Seeker | ended_journeys | past_journeys | empty | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/ended_journeys/past_journeys__empty.png) |
| Seeker | ended_journeys | past_journeys | normal | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/ended_journeys/past_journeys__normal.png) |
| Seeker | guardians | controls | circle_contextCards | Actual hold-to-open controls, selected existing Circle interior | [PNG](seeker/guardians/controls__circle_contextCards.png) |
| Seeker | guardians | controls | circle_current | Actual hold-to-open controls, selected existing Circle interior | [PNG](seeker/guardians/controls__circle_current.png) |
| Seeker | guardians | controls | circle_journeyRail | Actual hold-to-open controls, selected existing Circle interior | [PNG](seeker/guardians/controls__circle_journeyRail.png) |
| Seeker | guardians | controls | circle_portraitTiles | Actual hold-to-open controls, selected existing Circle interior | [PNG](seeker/guardians/controls__circle_portraitTiles.png) |
| Seeker | guardians | controls | circle_quietList | Actual hold-to-open controls, selected existing Circle interior | [PNG](seeker/guardians/controls__circle_quietList.png) |
| Seeker | guardians | controls | circle_segmentedCards | Actual hold-to-open controls, selected existing Circle interior | [PNG](seeker/guardians/controls__circle_segmentedCards.png) |
| Seeker | guardians | guardian_circle | bubble_contextCards | Actual controls choice 5 · Context cards, then X | [PNG](seeker/guardians/guardian_circle__bubble_contextCards.png) |
| Seeker | guardians | guardian_circle | bubble_current | Actual controls choice Current, then X | [PNG](seeker/guardians/guardian_circle__bubble_current.png) |
| Seeker | guardians | guardian_circle | bubble_journeyRail | Actual controls choice 3 · Journey rail, then X | [PNG](seeker/guardians/guardian_circle__bubble_journeyRail.png) |
| Seeker | guardians | guardian_circle | bubble_portraitTiles | Actual controls choice 2 · Initial tiles, then X | [PNG](seeker/guardians/guardian_circle__bubble_portraitTiles.png) |
| Seeker | guardians | guardian_circle | bubble_quietList | Actual controls choice 1 · Quiet list, then X | [PNG](seeker/guardians/guardian_circle__bubble_quietList.png) |
| Seeker | guardians | guardian_circle | bubble_segmentedCards | Actual controls choice 4 · Segmented cards, then X | [PNG](seeker/guardians/guardian_circle__bubble_segmentedCards.png) |
| Seeker | guardians | guardian_circle | normal | Actual allowed Guardian Circle checkpoint with local sample transcript | [PNG](seeker/guardians/guardian_circle__normal.png) |
| Seeker | guardians | guardian_invite | normal | Guardian tab → actual Add Guardian | [PNG](seeker/guardians/guardian_invite__normal.png) |
| Seeker | guardians | guardian_tab | normal | Fresh local Founder-preview Seeker tab 3 | [PNG](seeker/guardians/guardian_tab__normal.png) |
| Seeker | journey | bio | shared | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/bio__shared.png) |
| Seeker | journey | bio_locked | locked | Actual current Journey options → bio | [PNG](seeker/journey/bio_locked__locked.png) |
| Seeker | journey | guardian_access_agreement | paid_additional_consent | Both sample people ready → actual Begin Journey | [PNG](seeker/journey/guardian_access_agreement__paid_additional_consent.png) |
| Seeker | journey | journey | bio_both_ready | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__bio_both_ready.png) |
| Seeker | journey | journey | bio_both_shared | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__bio_both_shared.png) |
| Seeker | journey | journey | bio_self_ready | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__bio_self_ready.png) |
| Seeker | journey | journey | bio_self_shared | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__bio_self_shared.png) |
| Seeker | journey | journey | bio_unshared | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__bio_unshared.png) |
| Seeker | journey | journey | both_ready | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__both_ready.png) |
| Seeker | journey | journey | options_expanded | Journey card options tapped | [PNG](seeker/journey/journey__options_expanded.png) |
| Seeker | journey | journey | own_main_missing | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__own_main_missing.png) |
| Seeker | journey | journey | own_main_missing_content | Existing Journey vertical pager to current chapter content | [PNG](seeker/journey/journey__own_main_missing_content.png) |
| Seeker | journey | journey | peer_main_missing | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__peer_main_missing.png) |
| Seeker | journey | journey | peer_main_missing_content | Existing Journey vertical pager to current chapter content | [PNG](seeker/journey/journey__peer_main_missing_content.png) |
| Seeker | journey | journey | preparing | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__preparing.png) |
| Seeker | journey | journey | self_ready | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__self_ready.png) |
| Seeker | journey | journey | stage_compatibility_reveal | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__stage_compatibility_reveal.png) |
| Seeker | journey | journey | stage_compatibility_reveal_content | Existing Journey vertical pager to current chapter content | [PNG](seeker/journey/journey__stage_compatibility_reveal_content.png) |
| Seeker | journey | journey | stage_conversation | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__stage_conversation.png) |
| Seeker | journey | journey | stage_conversation_content | Existing Journey vertical pager to current chapter content | [PNG](seeker/journey/journey__stage_conversation_content.png) |
| Seeker | journey | journey | stage_family_stage | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__stage_family_stage.png) |
| Seeker | journey | journey | stage_family_stage_content | Existing Journey vertical pager to current chapter content | [PNG](seeker/journey/journey__stage_family_stage_content.png) |
| Seeker | journey | journey | stage_phase_1 | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__stage_phase_1.png) |
| Seeker | journey | journey | stage_phase_1_content | Existing Journey vertical pager to current chapter content | [PNG](seeker/journey/journey__stage_phase_1_content.png) |
| Seeker | journey | journey | stage_phase_2 | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__stage_phase_2.png) |
| Seeker | journey | journey | stage_phase_2_content | Existing Journey vertical pager to current chapter content | [PNG](seeker/journey/journey__stage_phase_2_content.png) |
| Seeker | journey | journey | stage_phase_3 | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__stage_phase_3.png) |
| Seeker | journey | journey | stage_phase_3_content | Existing Journey vertical pager to current chapter content | [PNG](seeker/journey/journey__stage_phase_3_content.png) |
| Seeker | journey | journey | stage_salam_exchange | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__stage_salam_exchange.png) |
| Seeker | journey | journey | stage_salam_exchange_content | Existing Journey vertical pager to current chapter content | [PNG](seeker/journey/journey__stage_salam_exchange_content.png) |
| Seeker | journey | journey | stage_wali_gate | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey__stage_wali_gate.png) |
| Seeker | journey | journey | stage_wali_gate_content | Existing Journey vertical pager to current chapter content | [PNG](seeker/journey/journey__stage_wali_gate_content.png) |
| Seeker | journey | journey_action | end_confirmation | Actual current Journey options → end | [PNG](seeker/journey/journey_action__end_confirmation.png) |
| Seeker | journey | journey_compatibility | revealed_result_pending | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey_compatibility__revealed_result_pending.png) |
| Seeker | journey | journey_compatibility_locked | locked | Actual current Journey options → compatibility | [PNG](seeker/journey/journey_compatibility_locked__locked.png) |
| Seeker | journey | journey_guardians | active | Public sample-model checkpoint; role/page eligibility checked by unchanged shell | [PNG](seeker/journey/journey_guardians__active.png) |
| Seeker | journey | journey_guardians | locked | Actual current Journey options → guardians | [PNG](seeker/journey/journey_guardians__locked.png) |
| Seeker | journey | journey_tab | active_1 | Public seedJourneys(1), same local preview preset | [PNG](seeker/journey/journey_tab__active_1.png) |
| Seeker | journey | journey_tab | active_2 | Public seedJourneys(2), same local preview preset | [PNG](seeker/journey/journey_tab__active_2.png) |
| Seeker | journey | journey_tab | active_3 | Public seedJourneys(3), same local preview preset | [PNG](seeker/journey/journey_tab__active_3.png) |
| Seeker | journey | journey_tab | empty_1_places | Public empty local model, membership matching capacity | [PNG](seeker/journey/journey_tab__empty_1_places.png) |
| Seeker | journey | journey_tab | empty_3_places | Public empty local model, membership matching capacity | [PNG](seeker/journey/journey_tab__empty_3_places.png) |
| Seeker | journey | journey_tab | normal | Fresh local Founder-preview Seeker tab 1 | [PNG](seeker/journey/journey_tab__normal.png) |
| Seeker | journey | timeline | event-compatibility_revealed | Sara Timeline → hold developer controls → Individual event: Compatibility revealed → close controls | [PNG](seeker/journey/timeline__event-compatibility_revealed.png) |
| Seeker | journey | timeline | event-conversation_started | Sara Timeline → hold developer controls → Individual event: Open Conversation began → close controls | [PNG](seeker/journey/timeline__event-conversation_started.png) |
| Seeker | journey | timeline | event-family_stage | Sara Timeline → hold developer controls → Individual event: Families introduced → close controls | [PNG](seeker/journey/timeline__event-family_stage.png) |
| Seeker | journey | timeline | event-guardian_linked | Sara Timeline → hold developer controls → Individual event: Guardians linked → close controls | [PNG](seeker/journey/timeline__event-guardian_linked.png) |
| Seeker | journey | timeline | event-journey_ended | Sara Timeline → hold developer controls → Individual event: Journey ended → close controls | [PNG](seeker/journey/timeline__event-journey_ended.png) |
| Seeker | journey | timeline | event-journey_restarted | Sara Timeline → hold developer controls → Individual event: Journey began again → close controls | [PNG](seeker/journey/timeline__event-journey_restarted.png) |
| Seeker | journey | timeline | event-journey_started | Sara Timeline → hold developer controls → Individual event: Journey began → close controls | [PNG](seeker/journey/timeline__event-journey_started.png) |
| Seeker | journey | timeline | event-liked | Sara Timeline → hold developer controls → Individual event: You liked each other → close controls | [PNG](seeker/journey/timeline__event-liked.png) |
| Seeker | journey | timeline | event-match_created | Sara Timeline → hold developer controls → Individual event: Match → close controls | [PNG](seeker/journey/timeline__event-match_created.png) |
| Seeker | journey | timeline | event-meeting | Sara Timeline → hold developer controls → Individual event: Meeting → close controls | [PNG](seeker/journey/timeline__event-meeting.png) |
| Seeker | journey | timeline | event-nikah | Sara Timeline → hold developer controls → Individual event: Nikah → close controls | [PNG](seeker/journey/timeline__event-nikah.png) |
| Seeker | journey | timeline | event-phase_1_complete | Sara Timeline → hold developer controls → Individual event: Finished Faith & Values → close controls | [PNG](seeker/journey/timeline__event-phase_1_complete.png) |
| Seeker | journey | timeline | event-phase_2_complete | Sara Timeline → hold developer controls → Individual event: Finished Building a Life → close controls | [PNG](seeker/journey/timeline__event-phase_2_complete.png) |
| Seeker | journey | timeline | event-phase_3_complete | Sara Timeline → hold developer controls → Individual event: Finished Navigating Life → close controls | [PNG](seeker/journey/timeline__event-phase_3_complete.png) |
| Seeker | journey | timeline | event-salam_exchanged | Sara Timeline → hold developer controls → Individual event: Salam exchanged → close controls | [PNG](seeker/journey/timeline__event-salam_exchanged.png) |
| Seeker | journey | timeline | scenario-allEvents | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: All events → close controls | [PNG](seeker/journey/timeline__scenario-allEvents.png) |
| Seeker | journey | timeline | scenario-answersLocked | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Answers private → close controls | [PNG](seeker/journey/timeline__scenario-answersLocked.png) |
| Seeker | journey | timeline | scenario-answersRevealed | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Answers revealed → close controls | [PNG](seeker/journey/timeline__scenario-answersRevealed.png) |
| Seeker | journey | timeline | scenario-current | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Current Journey → close controls | [PNG](seeker/journey/timeline__scenario-current.png) |
| Seeker | journey | timeline | scenario-empty | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Empty → close controls | [PNG](seeker/journey/timeline__scenario-empty.png) |
| Seeker | journey | timeline | scenario-event | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: One event → close controls | [PNG](seeker/journey/timeline__scenario-event.png) |
| Seeker | journey | timeline | scenario-loading | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Loading → close controls | [PNG](seeker/journey/timeline__scenario-loading.png) |
| Seeker | journey | timeline | scenario-meetingConfirmed | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Meeting · recorded → close controls | [PNG](seeker/journey/timeline__scenario-meetingConfirmed.png) |
| Seeker | journey | timeline | scenario-meetingConfirming | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Meeting · confirming → close controls | [PNG](seeker/journey/timeline__scenario-meetingConfirming.png) |
| Seeker | journey | timeline | scenario-meetingToConfirm | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Meeting · confirm → close controls | [PNG](seeker/journey/timeline__scenario-meetingToConfirm.png) |
| Seeker | journey | timeline | scenario-meetingWaiting | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Meeting · waiting → close controls | [PNG](seeker/journey/timeline__scenario-meetingWaiting.png) |
| Seeker | journey | timeline | scenario-nikahConfirmed | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Nikah · recorded → close controls | [PNG](seeker/journey/timeline__scenario-nikahConfirmed.png) |
| Seeker | journey | timeline | scenario-nikahConfirming | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Nikah · confirming → close controls | [PNG](seeker/journey/timeline__scenario-nikahConfirming.png) |
| Seeker | journey | timeline | scenario-nikahToConfirm | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Nikah · confirm → close controls | [PNG](seeker/journey/timeline__scenario-nikahToConfirm.png) |
| Seeker | journey | timeline | scenario-nikahWaiting | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Nikah · waiting → close controls | [PNG](seeker/journey/timeline__scenario-nikahWaiting.png) |
| Seeker | journey | timeline | scenario-stage | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Journey position → close controls | [PNG](seeker/journey/timeline__scenario-stage.png) |
| Seeker | journey | timeline | scenario-unavailable | Founder preview: seeded three Active Journeys → Requests → Sara Timeline → hold developer controls → Timeline examples: Unavailable → close controls | [PNG](seeker/journey/timeline__scenario-unavailable.png) |
| Seeker | journey | timeline | stage-compatibility_reveal | Sara Timeline → hold developer controls → Stage and road ahead: Compatibility Reveal → close controls → scroll to the current-stage marker | [PNG](seeker/journey/timeline__stage-compatibility_reveal.png) |
| Seeker | journey | timeline | stage-conversation | Sara Timeline → hold developer controls → Stage and road ahead: Open Conversation → close controls → scroll to the current-stage marker | [PNG](seeker/journey/timeline__stage-conversation.png) |
| Seeker | journey | timeline | stage-family_stage | Sara Timeline → hold developer controls → Stage and road ahead: Family Compatibility → close controls → scroll to the current-stage marker | [PNG](seeker/journey/timeline__stage-family_stage.png) |
| Seeker | journey | timeline | stage-phase_1 | Sara Timeline → hold developer controls → Stage and road ahead: Faith & Values → close controls → scroll to the current-stage marker | [PNG](seeker/journey/timeline__stage-phase_1.png) |
| Seeker | journey | timeline | stage-phase_2 | Sara Timeline → hold developer controls → Stage and road ahead: Building a Life → close controls → scroll to the current-stage marker | [PNG](seeker/journey/timeline__stage-phase_2.png) |
| Seeker | journey | timeline | stage-phase_3 | Sara Timeline → hold developer controls → Stage and road ahead: Navigating Life → close controls → scroll to the current-stage marker | [PNG](seeker/journey/timeline__stage-phase_3.png) |
| Seeker | journey | timeline | stage-salam_exchange | Sara Timeline → hold developer controls → Stage and road ahead: Salam Exchange → close controls → scroll to the current-stage marker | [PNG](seeker/journey/timeline__stage-salam_exchange.png) |
| Seeker | journey | timeline | stage-wali_gate | Sara Timeline → hold developer controls → Stage and road ahead: Guardian Gate → close controls → scroll to the current-stage marker | [PNG](seeker/journey/timeline__stage-wali_gate.png) |
| Seeker | profile_membership_settings | account_action | cancel_membership_held | Actual Current Membership > Cancel membership; held explanation only. | [PNG](seeker/profile_membership_settings/account_action__cancel_membership_held.png) |
| Seeker | profile_membership_settings | account_action | hidden_profile_restore_confirmation | Actual Hidden Profiles > Unhide confirmation; not submitted. | [PNG](seeker/profile_membership_settings/account_action__hidden_profile_restore_confirmation.png) |
| Seeker | profile_membership_settings | account_action | hidden_profiles_populated | Safe local checkpoint containing the supported fictional Hide transition. | [PNG](seeker/profile_membership_settings/account_action__hidden_profiles_populated.png) |
| Seeker | profile_membership_settings | account_action | invite_held | Profile > Invite someone to ZYRA; actual held local action. | [PNG](seeker/profile_membership_settings/account_action__invite_held.png) |
| Seeker | profile_membership_settings | account_action | overview_advanced | Safe local Settings parent chain; advanced overview. | [PNG](seeker/profile_membership_settings/account_action__overview_advanced.png) |
| Seeker | profile_membership_settings | account_action | overview_appLock | Safe local Settings parent chain; appLock overview. | [PNG](seeker/profile_membership_settings/account_action__overview_appLock.png) |
| Seeker | profile_membership_settings | account_action | overview_feedback | Safe local Settings parent chain; feedback overview. | [PNG](seeker/profile_membership_settings/account_action__overview_feedback.png) |
| Seeker | profile_membership_settings | account_action | overview_hiddenProfiles | Safe local Settings parent chain; hiddenProfiles overview. | [PNG](seeker/profile_membership_settings/account_action__overview_hiddenProfiles.png) |
| Seeker | profile_membership_settings | account_action | overview_notificationSettings | Safe local Settings parent chain; notificationSettings overview. | [PNG](seeker/profile_membership_settings/account_action__overview_notificationSettings.png) |
| Seeker | profile_membership_settings | account_action | overview_privacyData | Safe local Settings parent chain; privacyData overview. | [PNG](seeker/profile_membership_settings/account_action__overview_privacyData.png) |
| Seeker | profile_membership_settings | account_action | overview_signInSecurity | Safe local Settings parent chain; signInSecurity overview. | [PNG](seeker/profile_membership_settings/account_action__overview_signInSecurity.png) |
| Seeker | profile_membership_settings | account_action | overview_visibility | Safe local Settings parent chain; visibility overview. | [PNG](seeker/profile_membership_settings/account_action__overview_visibility.png) |
| Seeker | profile_membership_settings | activity_preview_detail | guardianUpdate | Actual activity item from selected checklist example | [PNG](seeker/profile_membership_settings/activity_preview_detail__guardianUpdate.png) |
| Seeker | profile_membership_settings | activity_preview_detail | introductionReceived | Actual activity item from selected checklist example | [PNG](seeker/profile_membership_settings/activity_preview_detail__introductionReceived.png) |
| Seeker | profile_membership_settings | activity_preview_detail | journeyEnded | Actual activity item from selected checklist example | [PNG](seeker/profile_membership_settings/activity_preview_detail__journeyEnded.png) |
| Seeker | profile_membership_settings | activity_preview_detail | journeyReady | Actual activity item from selected checklist example | [PNG](seeker/profile_membership_settings/activity_preview_detail__journeyReady.png) |
| Seeker | profile_membership_settings | activity_preview_detail | requestAccepted | Actual activity item from selected checklist example | [PNG](seeker/profile_membership_settings/activity_preview_detail__requestAccepted.png) |
| Seeker | profile_membership_settings | activity_preview_detail | requestDeclined | Actual activity item from selected checklist example | [PNG](seeker/profile_membership_settings/activity_preview_detail__requestDeclined.png) |
| Seeker | profile_membership_settings | compatibility_store | normal | Restored safe local Profile checkpoint to compatibility_store; unchanged shell. | [PNG](seeker/profile_membership_settings/compatibility_store__normal.png) |
| Seeker | profile_membership_settings | controls | profile | Actual admitted three-second hold on Profile; controls intentionally visible. | [PNG](seeker/profile_membership_settings/controls__profile.png) |
| Seeker | profile_membership_settings | edit_profile | normal | Actual Seeker Profile action opens the retained local edit_profile. | [PNG](seeker/profile_membership_settings/edit_profile__normal.png) |
| Seeker | profile_membership_settings | help_support | normal | Restored safe local Profile checkpoint to help_support; unchanged shell. | [PNG](seeker/profile_membership_settings/help_support__normal.png) |
| Seeker | profile_membership_settings | help_support | search_empty | Actual local Help search field > unmatched query; no answer invented. | [PNG](seeker/profile_membership_settings/help_support__search_empty.png) |
| Seeker | profile_membership_settings | help_support | search_matches | Actual local Help search field > sign in. | [PNG](seeker/profile_membership_settings/help_support__search_matches.png) |
| Seeker | profile_membership_settings | manage_photos | normal | Actual Seeker Profile action opens the retained local manage_photos. | [PNG](seeker/profile_membership_settings/manage_photos__normal.png) |
| Seeker | profile_membership_settings | membership | basic_history_neverPaid | Actual Membership controls > neverPaid > Basic role pager. | [PNG](seeker/profile_membership_settings/membership__basic_history_neverPaid.png) |
| Seeker | profile_membership_settings | membership | basic_history_unknown | Actual Membership controls > unknown > Basic role pager. | [PNG](seeker/profile_membership_settings/membership__basic_history_unknown.png) |
| Seeker | profile_membership_settings | membership | basic_paid_before | Membership role pager > Basic; unchanged previously-paid example. | [PNG](seeker/profile_membership_settings/membership__basic_paid_before.png) |
| Seeker | profile_membership_settings | membership | section_current | Profile > Membership > actual current section control. | [PNG](seeker/profile_membership_settings/membership__section_current.png) |
| Seeker | profile_membership_settings | membership | section_family | Profile > Membership > actual family section control. | [PNG](seeker/profile_membership_settings/membership__section_family.png) |
| Seeker | profile_membership_settings | membership | section_guardian | Profile > Membership > actual guardian section control. | [PNG](seeker/profile_membership_settings/membership__section_guardian.png) |
| Seeker | profile_membership_settings | membership | section_guardian_basic | Actual guardian membership pager > second Basic card. | [PNG](seeker/profile_membership_settings/membership__section_guardian_basic.png) |
| Seeker | profile_membership_settings | membership | section_seeker | Profile > Membership > actual seeker section control. | [PNG](seeker/profile_membership_settings/membership__section_seeker.png) |
| Seeker | profile_membership_settings | membership | section_seeker_basic | Actual seeker membership pager > second Basic card. | [PNG](seeker/profile_membership_settings/membership__section_seeker_basic.png) |
| Seeker | profile_membership_settings | membership | section_unlocks | Profile > Membership > actual unlocks section control. | [PNG](seeker/profile_membership_settings/membership__section_unlocks.png) |
| Seeker | profile_membership_settings | membership_review | basic_paid_before | Actual Basic selection > Review selection; no store or payment. | [PNG](seeker/profile_membership_settings/membership_review__basic_paid_before.png) |
| Seeker | profile_membership_settings | my_zyra_tab | activity_circleMessage | Actual My ZYRA controls → Activity checklist → circleMessage | [PNG](seeker/profile_membership_settings/my_zyra_tab__activity_circleMessage.png) |
| Seeker | profile_membership_settings | my_zyra_tab | activity_guardianUpdate | Actual My ZYRA controls → Activity checklist → guardianUpdate | [PNG](seeker/profile_membership_settings/my_zyra_tab__activity_guardianUpdate.png) |
| Seeker | profile_membership_settings | my_zyra_tab | activity_introductionReceived | Actual My ZYRA controls → Activity checklist → introductionReceived | [PNG](seeker/profile_membership_settings/my_zyra_tab__activity_introductionReceived.png) |
| Seeker | profile_membership_settings | my_zyra_tab | activity_journeyEnded | Actual My ZYRA controls → Activity checklist → journeyEnded | [PNG](seeker/profile_membership_settings/my_zyra_tab__activity_journeyEnded.png) |
| Seeker | profile_membership_settings | my_zyra_tab | activity_journeyReady | Actual My ZYRA controls → Activity checklist → journeyReady | [PNG](seeker/profile_membership_settings/my_zyra_tab__activity_journeyReady.png) |
| Seeker | profile_membership_settings | my_zyra_tab | activity_quiet | Actual My ZYRA controls → Activity checklist → quiet | [PNG](seeker/profile_membership_settings/my_zyra_tab__activity_quiet.png) |
| Seeker | profile_membership_settings | my_zyra_tab | activity_requestAccepted | Actual My ZYRA controls → Activity checklist → requestAccepted | [PNG](seeker/profile_membership_settings/my_zyra_tab__activity_requestAccepted.png) |
| Seeker | profile_membership_settings | my_zyra_tab | activity_requestDeclined | Actual My ZYRA controls → Activity checklist → requestDeclined | [PNG](seeker/profile_membership_settings/my_zyra_tab__activity_requestDeclined.png) |
| Seeker | profile_membership_settings | my_zyra_tab | activity_requestReceived | Actual My ZYRA controls → Activity checklist → requestReceived | [PNG](seeker/profile_membership_settings/my_zyra_tab__activity_requestReceived.png) |
| Seeker | profile_membership_settings | my_zyra_tab | activity_severalRequests | Actual My ZYRA controls → Activity checklist → severalRequests | [PNG](seeker/profile_membership_settings/my_zyra_tab__activity_severalRequests.png) |
| Seeker | profile_membership_settings | my_zyra_tab | normal | Fresh local Founder-preview Seeker tab 2 | [PNG](seeker/profile_membership_settings/my_zyra_tab__normal.png) |
| Seeker | profile_membership_settings | own_profile_preview | normal | Actual Seeker Profile action opens the retained local own_profile_preview. | [PNG](seeker/profile_membership_settings/own_profile_preview__normal.png) |
| Seeker | profile_membership_settings | personalisation | background_choices | Actual Personalisation > Background choice sheet; nothing selected. | [PNG](seeker/profile_membership_settings/personalisation__background_choices.png) |
| Seeker | profile_membership_settings | personalisation | haptic_choices | Actual Personalisation > Haptic feel choice sheet; nothing selected. | [PNG](seeker/profile_membership_settings/personalisation__haptic_choices.png) |
| Seeker | profile_membership_settings | personalisation | normal | Restored safe local Profile checkpoint to personalisation; unchanged shell. | [PNG](seeker/profile_membership_settings/personalisation__normal.png) |
| Seeker | profile_membership_settings | profile_tab | normal | Fresh local Founder-preview Seeker tab 4 | [PNG](seeker/profile_membership_settings/profile_tab__normal.png) |
| Seeker | profile_membership_settings | safety | no_subject | Profile > Safety & advice; actual local action, no person selected. | [PNG](seeker/profile_membership_settings/safety__no_subject.png) |
| Seeker | profile_membership_settings | settings | normal | Restored safe local Profile checkpoint to settings; unchanged shell. | [PNG](seeker/profile_membership_settings/settings__normal.png) |
| Seeker | profile_membership_settings | settings_detail | appLock | Safe local Settings > appLock > appLock chain. | [PNG](seeker/profile_membership_settings/settings_detail__appLock.png) |
| Seeker | profile_membership_settings | settings_detail | deleteAccount | Safe local Settings > advanced > deleteAccount chain. | [PNG](seeker/profile_membership_settings/settings_detail__deleteAccount.png) |
| Seeker | profile_membership_settings | settings_detail | discovery | Safe local Settings > visibility > discovery chain. | [PNG](seeker/profile_membership_settings/settings_detail__discovery.png) |
| Seeker | profile_membership_settings | settings_detail | feedback | Safe local Settings > feedback > feedback chain. | [PNG](seeker/profile_membership_settings/settings_detail__feedback.png) |
| Seeker | profile_membership_settings | settings_detail | hiddenProfiles | Safe local Settings > hiddenProfiles > hiddenProfiles chain. | [PNG](seeker/profile_membership_settings/settings_detail__hiddenProfiles.png) |
| Seeker | profile_membership_settings | settings_detail | notifications | Safe local Settings > notificationSettings > notifications chain. | [PNG](seeker/profile_membership_settings/settings_detail__notifications.png) |
| Seeker | profile_membership_settings | settings_detail | privacyPolicy | Safe local Settings > privacyData > privacyPolicy chain. | [PNG](seeker/profile_membership_settings/settings_detail__privacyPolicy.png) |
| Seeker | profile_membership_settings | settings_detail | recovery | Safe local Settings > signInSecurity > recovery chain. | [PNG](seeker/profile_membership_settings/settings_detail__recovery.png) |
| Seeker | profile_membership_settings | settings_detail | resetProfile | Safe local Settings > advanced > resetProfile chain. | [PNG](seeker/profile_membership_settings/settings_detail__resetProfile.png) |
| Seeker | profile_membership_settings | settings_detail | terms | Safe local Settings > privacyData > terms chain. | [PNG](seeker/profile_membership_settings/settings_detail__terms.png) |
| Seeker | profile_membership_settings | subscriptions | normal | Profile > Your subscriptions; unchanged local wallet. | [PNG](seeker/profile_membership_settings/subscriptions__normal.png) |
| Seeker | profile_membership_settings | switch_account_setup | normal | Actual switch wallet > Set up other profile; local setup overview. | [PNG](seeker/profile_membership_settings/switch_account_setup__normal.png) |
| Seeker | profile_membership_settings | switch_account_signup | coverage_assignedFamily | Actual Profile controls > other role assignedFamily > Switch. | [PNG](seeker/profile_membership_settings/switch_account_signup__coverage_assignedFamily.png) |
| Seeker | profile_membership_settings | switch_account_signup | coverage_basic | Actual Profile controls > other role basic > Switch. | [PNG](seeker/profile_membership_settings/switch_account_signup__coverage_basic.png) |
| Seeker | profile_membership_settings | switch_account_signup | coverage_individualOne | Actual Profile controls > other role individualOne > Switch. | [PNG](seeker/profile_membership_settings/switch_account_signup__coverage_individualOne.png) |
| Seeker | profile_membership_settings | switch_account_signup | coverage_none | Actual Profile controls > other role none > Switch. | [PNG](seeker/profile_membership_settings/switch_account_signup__coverage_none.png) |
| Seeker | profile_membership_settings | switch_account_signup | coverage_unavailable | Actual Profile controls > other role unavailable > Switch. | [PNG](seeker/profile_membership_settings/switch_account_signup__coverage_unavailable.png) |
| Seeker | profile_membership_settings | switch_account_signup | needs_signup | Actual Profile controls > Needs sign-up with existing coverage > Switch. | [PNG](seeker/profile_membership_settings/switch_account_signup__needs_signup.png) |

## Inventory and role coverage

Every one of the 49 inventory IDs is accounted for both roles; nine root tabs are included separately. “Not applicable”
means that destination belongs to the other role. “Retired” and “unreachable” have no substituted picture.

| Role | Page or tab | Status | Reason |
|---|---|---|---|
| Guardian | account_action | captured | 10 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | account_action | captured | 12 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | activity_preview_detail | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | activity_preview_detail | captured | 6 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | bio | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | bio | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | bio_locked | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | bio_locked | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | compatibility | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | compatibility | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | compatibility_store | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | compatibility_store | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | controls | captured | 10 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | controls | captured | 20 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | edit_profile | not_applicable | Guardian Profile does not expose the Seeker profile/editor/photo action; no current Guardian opener. |
| Seeker | edit_profile | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | ended | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | ended | captured | 3 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | ended_bio | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | ended_bio | captured | 2 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | ended_compatibility | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | ended_compatibility | captured | 2 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | ended_guardians | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | ended_guardians | captured | 2 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | ended_restart | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | ended_restart | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | filters | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | filters | captured | 2 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | guardian | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | guardian | not_applicable | Current navigation exposes this family-support destination only in the Guardian role; no Seeker opener. |
| Guardian | guardian_access_agreement | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | guardian_access_agreement | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | guardian_circle | captured | 7 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | guardian_circle | captured | 7 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | guardian_invite | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | guardian_invite | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | guardian_linked_profile | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | guardian_linked_profile | not_applicable | Current navigation exposes this family-support destination only in the Guardian role; no Seeker opener. |
| Guardian | guardian_network_profile | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | guardian_network_profile | not_applicable | Current navigation exposes this family-support destination only in the Guardian role; no Seeker opener. |
| Seeker | guardian_tab | captured | Actual unchanged root navigation and full viewport, including its own tab bar. |
| Guardian | held_action | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | held_action | not_applicable | Current navigation exposes this family-support destination only in the Guardian role; no Seeker opener. |
| Guardian | help_support | captured | 3 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | help_support | captured | 3 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | introductions | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | introductions | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | journey | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | journey | captured | 29 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | journey_action | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | journey_action | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | journey_compatibility | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | journey_compatibility | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | journey_compatibility_locked | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | journey_compatibility_locked | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | journey_guardians | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | journey_guardians | captured | 2 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | journey_tab | captured | Actual unchanged root navigation and full viewport, including its own tab bar. |
| Guardian | manage_photos | not_applicable | Guardian Profile does not expose the Seeker profile/editor/photo action; no current Guardian opener. |
| Seeker | manage_photos | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | membership | captured | 10 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | membership | captured | 10 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | membership_review | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | membership_review | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | my_zyra_tab | captured | Actual unchanged root navigation and full viewport, including its own tab bar. |
| Guardian | network_request | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | network_request | not_applicable | Current navigation exposes this family-support destination only in the Guardian role; no Seeker opener. |
| Guardian | notifications | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | notifications | not_in_preview | A legacy dashboard switch case can name notifications, but current dashboard updates are empty, activity examples contain no notifications destination, supportiveCardsFromResolution filters notifications targets, and checkpoint restoration does not admit the page. No current UI opener; deliberately not forced. |
| Guardian | own_profile_preview | not_applicable | Guardian Profile does not expose the Seeker profile/editor/photo action; no current Guardian opener. |
| Seeker | own_profile_preview | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | past_journeys | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | past_journeys | captured | 2 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | paused | retired_not_in_preview | Retired feature: explicit unavailable destination with no current opener; no fabricated navigation or state. |
| Seeker | paused | retired_not_in_preview | Retired feature: explicit unavailable destination with no current opener; no fabricated navigation or state. |
| Guardian | personalisation | captured | 3 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | personalisation | captured | 3 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | profile | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | profile | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | profile_tab | captured | Actual unchanged root navigation and full viewport, including its own tab bar. |
| Seeker | profiles_tab | captured | Actual unchanged root navigation and full viewport, including its own tab bar. |
| Guardian | request_capacity | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | request_capacity | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | requests | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | requests | captured | 4 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | safety | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | safety | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | saved | retired_not_in_preview | Retired feature: explicit unavailable destination with no current opener; no fabricated navigation or state. |
| Seeker | saved | retired_not_in_preview | Retired feature: explicit unavailable destination with no current opener; no fabricated navigation or state. |
| Guardian | scan | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | scan | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | settings | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | settings | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | settings_detail | captured | 9 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | settings_detail | captured | 10 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | subscriptions | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | subscriptions | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | switch_account_setup | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | switch_account_setup | captured | 1 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | switch_account_signup | captured | 6 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Seeker | switch_account_signup | captured | 6 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
| Guardian | tab_my_zyra | captured | Actual unchanged root navigation and full viewport, including its own tab bar. |
| Guardian | tab_network | captured | Actual unchanged root navigation and full viewport, including its own tab bar. |
| Guardian | tab_profile | captured | Actual unchanged root navigation and full viewport, including its own tab bar. |
| Guardian | tab_seekers | captured | Actual unchanged root navigation and full viewport, including its own tab bar. |
| Guardian | timeline | not_applicable | This Browse/request/Journey/archive/activity destination belongs to the Seeker flow; no current Guardian opener. |
| Seeker | timeline | captured | 40 current full-shell local preview capture(s); native-device status bar absent in authorized Flutter-test fallback. |
