---
id: DOC-ZYRA-0278
type: SPEC
status: SUPERSEDED
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 1 - every ZYRA screen in plain words: what it is for, who sees it, how you reach it, what it leads to, and its states. Read this first to rebuild or change any screen
links: [OA-ZYRA-309, DOC-ZYRA-0279]
owner: Fable
---

> **READ FIRST (25 Oct 2026, DR-ZYRA-274).** This part describes the **old member app**, which is being replaced. The planned
> ZYRA is the Founder preview (the latest Codex design), where Pause, Save and restart are retired. This part will be redone from
> the planned app. Until then, use it only to understand what members' code does today.

# ZYRA BLUEPRINT — PART 1 — SCREEN MAP — V1 (DRAFT)

Status: **DRAFT for Shakeel's review.** Written 25 Oct 2026 from the code in `SOURCE/lib` (the code wins where
documents disagree, OA-ZYRA-309). Each screen's line comes from the code's own description of it; links come from
the generated inventory DOC-ZYRA-0279, which also lists every button and what it does. Re-generate that inventory
with `SYSTEM/tools/blueprint/generate_screen_map.py` after any screen change.

## How the app starts

| Step | Screen | What decides the next screen |
|---|---|---|
| 1 | Startup gate (`main.dart`) → `AuthGate` | Plays `SplashScreen` once; no saved session → `WelcomeScreen` (Google / Apple sign-in, email recovery) |
| 2 | `ZyraSessionRouter` (not a screen — the decision maker) | No profile yet → sign-up: `RoleSelectionScreen` (Seeker or Guardian path), then onboarding. Unfinished sign-up → resumes it. Identity check not passed → `InitialIdentityCheckScreen` |
| 3 | Paid-only gate | When paid-only is switched on and the member has not paid → `MembershipRequiredScreen` |
| 4 | The member's home | Guardian → `WaliHomeShell`; Seeker → `HomeShell` (opens on the My ZYRA tab while onboarding is unfinished) |

## The two homes (bottom navigation)

| Home | Tabs, left to right |
|---|---|
| **Seeker** — `HomeShell` | Profiles (`BrowseScreen`) · Connections (`ConnectionsScreen`) · My ZYRA (`SeekerDashboardScreen`) · Guardian (`SeekerWaliTab`) · Profile (`ProfileScreen`) |
| **Guardian** — `WaliHomeShell` | Dashboard (`WaliDashboardScreen`) · Network (`WaliNetworkScreen`) · Seekers (`WaliSeekersScreen`) · Profile (`WaliProfileScreen`) |

## Every screen (88)

Who sees it comes from the screen's folder. "States" means the code has a loading, empty or error view — not that each one was checked on a phone.

### top level — Everyone

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `AuthGate` | App entry gate — OA-102 session persistence. supabase_flutter itself persists the session locally between app restarts; this widget is what actually acts on that at cold start: skip Welcome/sign-in entirely if a s | DeveloperAccessScreen, ProfileReadyScreen, dev_scenario_panel_v2, main, wali_dev_scenario_panel, zyra_developer_route_gate, zyra_global_dev_overlay | SplashScreen, WelcomeScreen | loading, error |
| `SplashScreen` | Splash — the branded opening.  : Founder selected Quiet Horizon as the main splash. | AuthGate, dev_splash_directions, dev_splash_lab | — | — |
| `WelcomeScreen` | Welcome Screen — entry point to ZYRA. Spec: APP/Authentication/Script/Script_V1.md §WELCOME SCREEN. | AuthGate, InitialIdentityCheckScreen, ProfileScreen, WaliProfileScreen, dev_signup_process, main, zyra_onboarding_account_exit | EmailRecoveryScreen, RoleSelectionScreen, TesterAccessScreen | loading, error |

### auth — Everyone (signed out)

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `EmailRecoveryScreen` | *(no description in the code)* | WelcomeScreen | — | loading, error |
| `RoleSelectionScreen` | First-use path selection.  Founder direction, | WelcomeScreen, dev_signup_process, zyra_session_router | GuardianOnboardingOverviewScreen, OnboardingFlow | error |
| `TesterAccessScreen` | Private TestFlight entry for invited external testers. This never appears in ordinary builds and does not create an account or bypass real auth. | WelcomeScreen | — | error |

### browse — Seeker

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `BrowseScreen` | Browse — BROWSE_UX_SPEC_CURRENT_VERSION_V3.md + PROFILE DECISION SYSTEM/Summary.md. Current terminology (DR-ZYRA-099, : 🔴 Pass (was: Decline — no record, no notification), 🟡 Save (private bookmark), 🟢 C | HomeShell | MatchNotificationScreen, ProfileUnlockScreen | loading, empty, error |
| `FindByZyraCodeScreen` | Deliberate known-person discovery from Browse.  A permanent ZYRA Code only locates an eligible Seeker. | HomeShell | — | error |
| `MatchNotificationScreen` | Match Notification — E1, THE moment (DR-ZYRA-147/148, .  Was a single fade-in per MATCH_UX_SPEC's "warm, calm, human" — right instinct, functional execution, and the Founder named it the single biggest | BrowseScreen | — | — |

### chat — Seeker and Guardian

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `ChatScreen` | Conversation screen for an Active Journey — per MATCH_UX_SPEC: "Conversation belongs to Active Journey only."  Unavailable conversations fail closed. Local sample messages are confined to the explicitly authorised | JourneyFlowScreen | JourneyTimelineScreen | loading, empty, error |

### connections — Seeker

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `ConnectionsScreen` | Connections tab — per APP/Navigation/SEEKER NAVIGATION/Summary.md's CONNECTIONS section: "Relationship Journey = Save → Consider → Match → Conversation → Family Stage." Matches is NOT a conversation inbox (MATCH_U | HomeShell | JourneyFlowScreen, JourneyTimelineScreen, ProfileUnlockScreen, SeekerProfileScreen | loading, empty, error |

### home — Seeker

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `HomeShell` | Home shell — bottom navigation across Browse / Connections / Dashboard / Guardian / Profile.  : NOTIFICATIONS BECAME THE FI | ProfileReadyScreen, SeekerPostIdentityChoiceScreen, seeker_setup_navigation, zyra_dev_local_preview, zyra_session_router | BrowseScreen, ConnectionsScreen, EditProfileScreen, FindByZyraCodeScreen, HelpSupportScreen, ProfileScreen, SeekerDashboardScreen, SeekerOnboardingOverviewScreen, SeekerWaliTab, UpgradeScreen | — |
| `SeekerDashboardScreen` | Seeker Dashboard — one resolver, one production renderer.  Developer scenarios use the same Quiet renderer and governed resolution as production. | HomeShell | — | loading, error |

### journey — Seeker

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `JourneyFlowScreen` | Pre-Journey Ritual host screen — APP/Journey/PRE-JOURNEY RITUAL/ Summary.md. Routes an Active Journey through its real stages (matches.journey_stage): Salam Exchange -> Compatibility Reveal -> Wali Gate -> Phase 1 | ConnectionsScreen, ZyraGuardianCirclesInboxScreen, dev_scenario_panel_v2 | ChatScreen, InitialIdentityCheckScreen, JourneyTimelineScreen, LinkWaliScreen | loading, empty, error |
| `JourneyMapScreen` | The Journey Map — where we are, on which road.  , decision D1 of JOURNEY_EXPERIENCE_REVIEW_. | **nothing found** | JourneyTimelineScreen | — |

### matches — Seeker

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `JourneyTimelineScreen` | Journey Timeline — per ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md's timelines/timeline_milestones tables ("Journey timeline per match" / "Events recorded on the timeline"). Reads real milestones for the signed-in | ChatScreen, ConnectionsScreen, JourneyFlowScreen, JourneyMapScreen, PastJourneysScreen | ProfileUnlockScreen | loading, empty, error |

### notifications — Everyone signed in

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `NotificationsScreen` | Notification feed (#16) — opened from the Bell icon (widgets/notification_bell.dart). Shared by both Seeker and Wali accounts; the underlying `notifications` table doesn't distinguish role, just whichever profile | **nothing found** | — | loading, empty, error |

### onboarding — New member

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `GuardianOnboardingOverviewScreen` | *(no description in the code)* | ProfileScreen, RoleSelectionScreen, SeekerPostIdentityChoiceScreen | — | loading, empty, error |
| `SeekerOnboardingOverviewScreen` | A calm orientation screen before a long onboarding path begins.  Founder-approved direction, | HomeShell, ProfileReadyScreen, SeekerPostIdentityChoiceScreen, WaliProfileScreen | — | loading, empty, error |
| `SeekerPostIdentityChoiceScreen` | The explicit Seeker handoff after the short account essentials and the mandatory identity check. The account may open before the longer profile journey is finished; neither action publishes an incomplete profile. | OnboardingFlow | BioOnboardingFlow, Chapter2Flow, GuardianOnboardingOverviewScreen, HomeShell, OnboardingStageIntroScreen, ProfileReadyScreen, SeekerOnboardingOverviewScreen, ValuesPreferencesFlow, WaliOnboardingFlow | loading, empty, error |
| `Article9ConsentScreen` | Explicit consent for special-category data — Founder approved | Chapter2Flow | — | error |
| `BioOnboardingFlow` | Optional, Journey-only Bio chapter.  The structured facts are intentionally entered here rather than copied silently from private compatibility answers. | Chapter2Flow, SeekerPostIdentityChoiceScreen | OnboardingStageIntroScreen, ValuesPreferencesFlow | loading, error |
| `CategorySummaryScreen` | Combined compatibility category summary. Every card keeps the Seeker's own answer visible; scored questions can expand to show the traffic lights set immediately after that answer. | ValuesPreferencesFlow | — | empty |
| `Chapter2Flow` | Chapter 2 — Your Profile. 8 topics per Questions Section 2 Profile Information.md: Photos, Location, Sect, Revert Status, Country of Birth, Nationality, Ethnicity, Languages Spoken. | SeekerPostIdentityChoiceScreen | Article9ConsentScreen, BioOnboardingFlow, OnboardingStageIntroScreen, TrafficLightQuestionScreen | loading, empty, error |
| `CompatibilityCategoryIntroScreen` | A quiet boundary between compatibility subjects.  The screen says where the Seeker is, gives one brief description and keeps the question count separate. | ValuesPreferencesFlow | — | — |
| `GenericSelectQuestionScreen` | Generic single/multi-select question screen — renders any OnboardingQuestion (used for the ~104 Chapter 3 "About You" questions, and reused for Chapter 2's "About You" half of each topic). Keeps one well-tested re | CompatibilityEditorScreen, ValuesPreferencesFlow | — | — |
| `IdentityVerificationPrivacyScreen` | Temporary Phase A destination. It links to the truthful current summary while making clear that the full app policy is not yet published. | InitialIdentityCheckScreen | — | loading, error |
| `InitialIdentityCheckScreen` | Mandatory identity-verification step — DR-ZYRA-220/221, OA-ZYRA-266.  Phase A owns the exact consent surface, coarse-state presentation and the fail-closed navigation boundary. | JourneyFlowScreen, OnboardingFlow, ProfileReadyScreen, WaliOnboardingFlow, zyra_session_router | IdentityVerificationPrivacyScreen, PrivacyAndDataScreen, WelcomeScreen | loading, error |
| `OnboardingFlow` | Account essentials: names, gender, date of birth and first Seeker photo. Spec: APP/Onboarding/SEEKER ONBOARDING QUESTIONS/Onboarding Rules & UX.md. | RoleSelectionScreen, zyra_session_router | AccountEssentialsIntroScreen, InitialIdentityCheckScreen, SeekerPostIdentityChoiceScreen, SignupMembershipChoiceScreen | empty, error |
| `AccountEssentialsIntroScreen` | Short account setup is not one of the four optional profile sections. It comes before identity verification and the explicit now/later choice. | OnboardingFlow | OnboardingStageIntroScreen | empty |
| `OnboardingStageIntroScreen` | *(no description in the code)* | AccountEssentialsIntroScreen, BioOnboardingFlow, Chapter2Flow, SeekerPostIdentityChoiceScreen, ValuesPreferencesFlow, dev_onboarding_lab | — | empty |
| `ProfileReadyScreen` | Final Seeker review: server-confirmed setup and an explicit publication action. Visiting this page never manufactures completion or verification. | SeekerPostIdentityChoiceScreen, ValuesPreferencesFlow | AuthGate, EditProfileScreen, HomeShell, InitialIdentityCheckScreen, MyProfilePreviewScreen, SeekerOnboardingOverviewScreen | loading, error |
| `SignupMembershipChoiceScreen` | The account flow owns saving and navigation. Choosing a card never grants membership, begins a trial, charges a fee or marks identity as verified. | OnboardingFlow, WaliOnboardingFlow | — | — |
| `TrafficLightQuestionScreen` | Generic per-option preference screen. Every possible answer receives its own explicit Prefer this / No preference / Not for me choice. | Chapter2Flow, CompatibilityEditorScreen, ValuesPreferencesFlow | — | — |
| `TransitionScreen` | Shared Guardian support/consent handoff. The selected onboarding style keeps the reading area scrollable and its continuation consistently reachable. | WaliOnboardingFlow | — | — |
| `ValuesPreferencesFlow` | Compatibility onboarding — two calm, separate modes over the existing Chapter 3/4 storage contract.  Part 1 asks every private "About You" question, grouped into the 11 Founder-approved sections. | BioOnboardingFlow, SeekerPostIdentityChoiceScreen | CategorySummaryScreen, CompatibilityCategoryIntroScreen, GenericSelectQuestionScreen, OnboardingStageIntroScreen, ProfileReadyScreen, TrafficLightQuestionScreen | loading, empty, error |

### profile — Seeker

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `AvatarAdjustScreen` | *(no description in the code)* | EditPhotosScreen | — | error |
| `CompatibilityEditorScreen` | *(no description in the code)* | EditProfileScreen | GenericSelectQuestionScreen, TrafficLightQuestionScreen | loading, empty, error |
| `EditPhotosScreen` | *(no description in the code)* | ProfileScreen | AvatarAdjustScreen, PhotoCropReviewScreen | loading, empty, error |
| `EditProfileScreen` | Edit Profile — everything that changes what is ON your profile. | HomeShell, ProfileReadyScreen, ProfileScreen | CompatibilityEditorScreen, HelpSupportScreen | loading, error |
| `MyProfilePreviewScreen` | Read-only owner preview using the current bounded Portrait Browse card. It never joins the feed or exposes a decision/action against oneself. | ProfileReadyScreen, ProfileScreen | — | empty, error |
| `PastJourneyArchiveUnavailableScreen` | Truthful read-only destination until an archive row can identify the exact authorised attempt. This deliberately has no reader, retry or mutation action: an unavailable historical attempt is not a current one. | PastJourneysScreen | — | loading, empty, error |
| `PastJourneysScreen` | The profile-owned archive for Paused and Ended Journey records.  Connections remains the live working surface. | ProfileScreen | JourneyTimelineScreen, PastJourneyArchiveUnavailableScreen | loading, empty, error |
| `PhotoCropReviewScreen` | ZYRA-owned crop queue for a batch selected from the native photo picker. Nothing leaves this screen until every photo is approved. | EditPhotosScreen, zyra_photo_batch_flow | — | loading, error |
| `ProfileScreen` | Profile tab — APP/Profiles/Script/Script_V1.md: no white content containers, info sits directly on the page background, white section headings, membership status replaces the generic "Member" label. Includes the P | HomeShell | CompatibilityUnlockStoreScreen, EditPhotosScreen, EditProfileScreen, GuardianOnboardingOverviewScreen, HelpSupportScreen, MyProfilePreviewScreen, PastJourneysScreen, PersonalisationScreen, SettingsScreen, UpgradeScreen, WaliHomeShell, WelcomeScreen | empty, error |
| `SeekerProfileScreen` | FULL PROFILE — read-only, for someone you are already in a Journey with.  Founder, | ConnectionsScreen, GNSheetShell, WaliDashboardScreen, ZyraGuardianCirclesInboxScreen | — | empty, error |

### settings — Everyone signed in

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `AccountAdvancedScreen` | Reset/Delete are explanation destinations only. Their written destructive contracts remain unapproved, and the client service methods also refuse. | MembershipRequiredScreen, SettingsScreen | HelpSupportScreen | error |
| `AppLockScreen` | App Lock settings.   One toggle, and deliberately one toggle — the feature is a single decision, and a screen of options would make a simple thing look like a security product it is not. | SettingsScreen | — | loading |
| `FeedbackScreen` | Send feedback.     SEPARATE FROM HELP & SUPPORT, deliberately. | SettingsScreen | — | loading, error |
| `HelpSupportScreen` | Help & Support — rebuilt .  WAS: four lines of text and an email address, | AccountAdvancedScreen, EditProfileScreen, HomeShell, LegalDocumentScreen, MembershipRequiredScreen, ProfileScreen, SettingsScreen, WaliProfileScreen | SafetyCaseStatusScreen | error |
| `HiddenProfilesScreen` | *(no description in the code)* | SettingsScreen | — | loading, empty, error |
| `LegalDocumentScreen` | Honest document availability, not invented legal text or acceptance. The public website notice covers the website only, not the member app. | PrivacyAndDataScreen, UpgradeScreen | HelpSupportScreen | — |
| `NotificationSettingsScreen` | Notification preferences.   The previous version's own header said the toggles were "honest" about being local-only: they wrote to AppState and nowhere else, so every choice was lost on restart. | SettingsScreen, WaliNotificationSettingsScreen | — | loading, empty, error |
| `PersonalisationScreen` | Member choices retain the existing preference coordinators. The explicit preview constructor publishes caller-owned presentation intentions only. | ProfileScreen, WaliProfileScreen | — | error |
| `PrivacyAndDataScreen` | Current | InitialIdentityCheckScreen, MembershipRequiredScreen, SettingsScreen | LegalDocumentScreen | — |
| `PrivacySettingsScreen` | Account-level pause consumes only the versioned owner-only server contract. The old discovery is_active switch is not global account privacy. | SettingsScreen | — | loading, error |
| `SafetyCaseStatusScreen` | *(no description in the code)* | HelpSupportScreen, MembershipRequiredScreen | — | loading, empty, error |
| `SettingsScreen` | Settings — the account control centre.   Settings was previously a SECTION inside profile_screen.dart: a label and seven flat rows, below the profile card and a list of Connections counts. | ProfileScreen, WaliProfileScreen, dev_settings_design | AccountAdvancedScreen, AppLockScreen, FeedbackScreen, HelpSupportScreen, HiddenProfilesScreen, NotificationSettingsScreen, PrivacyAndDataScreen, PrivacySettingsScreen, SignInSecurityScreen, UpgradeScreen | error |
| `RecoveryEmailSetupScreen` | *(no description in the code)* | SignInSecurityScreen | — | loading, error |
| `SignInSecurityScreen` | *(no description in the code)* | SettingsScreen | RecoveryEmailSetupScreen | loading, error |

### subscription — Seeker

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `MembershipRequiredScreen` | Paid-only boundary shown after identity/account routing but before any product shell is built. It deliberately keeps only the controls a locked member must retain: restore/resubscribe, billing, safety/support, data and d | zyra_session_router | AccountAdvancedScreen, HelpSupportScreen, PrivacyAndDataScreen, SafetyCaseStatusScreen, UpgradeScreen | — |
| `ProfileUnlockScreen` | Compatibility Unlock — ONE page, two sections. : one Compatibility Unlock includes the former full-detail target. | BrowseScreen, ConnectionsScreen, JourneyTimelineScreen | — | loading, error |
| `CompatibilityUnlockStoreScreen` | The one purchase destination for Compatibility Unlock credits. Membership remains discoverable separately and never acts as an indirect scroll-to route for these one-off purchases. | ProfileScreen, UpgradeScreen | — | error |
| `UpgradeScreen` | The historical route name remains compatible with callers. This page is the truthful membership control centre: it shows current access, explains available plans, and hands store-owned changes to the App Store / P | HomeShell, MembershipRequiredScreen, ProfileScreen, SettingsScreen, WaliDashboardScreen, WaliNetworkScreen, WaliProfileScreen, zyra_guardian_capacity_notice, zyra_locked_feature_upgrade, zyra_membership_history_lock | CompatibilityUnlockStoreScreen, LegalDocumentScreen | error |

### wali — Guardian

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `AcceptGuardianInviteScreen` | Accepting a Guardian invitation you RECEIVED.     A full page rather than a sheet, deliberately: | zyra_guardian_invitation_dashboard | — | empty |
| `AcceptWaliInviteScreen` | Shared invite-code entry screen — reachable from LinkWaliScreen on both sides (a Seeker linking a Wali, or a Wali linking a Seeker). Previews who sent the code before committing (via preview_wali_ invite), then co | ZyraCodeScreen | — | error |
| `ZyraGuardianCircleScreen` | *(no description in the code)* | SeekerWaliTab, WaliSeekersScreen, ZyraGuardianCirclesInboxScreen, zyra_one_journey_concept_shell | — | loading, empty, error |
| `ZyraGuardianCirclesInboxScreen` | *(no description in the code)* | **nothing found** | JourneyFlowScreen, SeekerProfileScreen, WaliJourneyDetailScreen, ZyraGuardianCircleScreen | loading, empty, error |
| `GuardianDetailScreen` | One Guardian, in full. Reached by tapping their card on the Guardian tab. | **nothing found** | — | loading, empty, error |
| `LinkGuardianScreen` | Seeker entry point for permanent ZYRA Codes. | SeekerWaliTab, zyra_one_journey_concept_shell | ZyraCodeScreen | — |
| `LinkWaliScreen` | Compatibility route used by older profile and Journey entry points. Every route now lands on the same permanent-code/request surface. | JourneyFlowScreen | ZyraCodeScreen | — |
| `SeekerGuardianPage` | Canonical Seeker Guardian page selected by the Founder.  Horizontal [PageView] movement is the sole Guardian-to-Guardian navigation. | SeekerWaliTab, zyra_one_journey_concept_shell | — | loading, empty, error |
| `SeekerWaliTab` | Seeker-side canonical owner for Guardian relationship management.  The Founder-approved production experience is the vertical, Main-first Guardian page. | HomeShell | LinkGuardianScreen, SeekerGuardianPage, ZyraGuardianCircleScreen | loading |
| `WaliDashboardScreen` | Guardian Dashboard — one person-first family-support home.  Each linked Seeker owns one swipeable page. | WaliHomeShell | SeekerProfileScreen, UpgradeScreen, WaliJourneyDetailScreen | loading, empty, error |
| `GNSheetShell` | Guardian Network — SHARED LIBRARY (GN DRAFT 3, .  Founder directive, | WaliNetworkScreen | SeekerProfileScreen | empty |
| `WaliHomeShell` | Guardian home shell — one stable navigation structure for every membership. Guardian Basic sees paid destinations in place with a lock; entitlement changes access and content, never the shape of the app. | ProfileScreen, ZyraCodeScreen, zyra_dev_local_preview, zyra_session_router | WaliDashboardScreen, WaliNetworkScreen, WaliProfileScreen, WaliSeekersScreen | — |
| `WaliInviteSeekerScreen` | Guardian entry point for their permanent code and Seeker requests. | WaliNetworkScreen, WaliOnboardingFlow, WaliSeekersScreen | ZyraCodeScreen | — |
| `WaliJourneyDetailScreen` | Guardian-facing Journey detail. Guardian Free can view the linked Seeker's Journey and Timeline only. | WaliDashboardScreen, WaliSeekerWorkspaceScreen, ZyraGuardianCirclesInboxScreen | — | loading, empty, error |
| `WaliNetworkScreen` | GN DRAFT 3.1 — D14-RATIFIED interaction model . Built to ZYRA_GN_BUILD_CONTRACT_CURRENT_VERSION_V1.md (Rules 1-44, as amended for Draft 3 — see wali_gn_shared.dart's header). | WaliHomeShell | GNSheetShell, UpgradeScreen, WaliInviteSeekerScreen | loading, empty, error |
| `WaliNotificationSettingsScreen` | Guardian notification settings use the same persisted five-category service and the same honest device-permission state as Seeker settings. Copy adapts by role; storage codes and consent semantics do not fork. | **nothing found** | NotificationSettingsScreen | — |
| `WaliOnboardingFlow` | Wali Onboarding — v1 draft. WALI_ARCHITECTURE_CURRENT_VERSION_V5.md is a fully approved, detailed architecture (account model, capability grants, three entry paths, screen flow diagram, navigation), but the actual | SeekerPostIdentityChoiceScreen, zyra_session_router | InitialIdentityCheckScreen, SignupMembershipChoiceScreen, TransitionScreen, WaliInviteSeekerScreen | empty, error |
| `WaliProfileScreen` | Guardian Profile follows the same ownership rule as Seeker Profile: identity and role-specific information live here; account controls live in Settings. Guardian remains intentionally smaller because it has no Bro | WaliHomeShell | HelpSupportScreen, PersonalisationScreen, SeekerOnboardingOverviewScreen, SettingsScreen, UpgradeScreen, WelcomeScreen | error |
| `WaliSeekerWorkspaceScreen` | *(no description in the code)* | WaliSeekersScreen | WaliJourneyDetailScreen | loading, empty, error |
| `WaliSeekersScreen` | Guardian-side Seeker Workspace roster — DR-ZYRA-224 F4 / 051 Phase 2.  Server truth is split by role before rich Journey context is assembled. | WaliHomeShell | WaliInviteSeekerScreen, WaliSeekerWorkspaceScreen, ZyraGuardianCircleScreen | loading, empty, error |
| `ZyraCodeScreen` | One role-neutral surface for the Founder-approved permanent ZYRA Code.  The code is only a discovery handle. | LinkGuardianScreen, LinkWaliScreen, WaliInviteSeekerScreen | AcceptWaliInviteScreen, WaliHomeShell | loading, empty, error |

### dev — Developer only

| Screen | What it is for | Reached from | Leads to | States |
|---|---|---|---|---|
| `DeveloperAccessScreen` | Founder | dev_scenario_panel_v2, wali_dev_scenario_panel, zyra_dev_home, zyra_global_dev_overlay | AuthGate, ZyraHealthUsageScreen | loading |
| `ModerationReviewQueueScreen` | Internal Phase A moderation review queue preview.  Local state only. | **nothing found** | — | empty |
| `ZyraHealthUsageScreen` | Founder-only truth view for the first observability slice.  It reports what exists now. | DeveloperAccessScreen | — | — |

## Found while mapping

**6 screens that nothing in the app opens** (no other code creates them): `JourneyMapScreen`, `NotificationsScreen`, `ZyraGuardianCirclesInboxScreen`, `GuardianDetailScreen`, `WaliNotificationSettingsScreen`, `ModerationReviewQueueScreen`. They may be leftovers from redesigns. Raised as OA-ZYRA-311 for Shakeel to decide keep or retire after the build freeze — nothing is changed now.

## Limits of this part

- Read from the code, not by running the app. Navigation built at run time, and buttons whose labels come from data, can be missed; the generated inventory marks those as icon / inline actions.
- Buttons inside shared widgets (`lib/widgets/`) are listed under the widget, not every screen that uses it.
- Part 2 (rules and behaviour per feature), part 3 (data), part 4 (outside services), part 5 (look and feel), part 6 (build and release) and part 7 (trace) follow.

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-25 | V1 | First draft from the code (OA-ZYRA-309) |
