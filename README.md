# ZYRA

ZYRA is a matrimonial app for a faith community where the family is part of finding a spouse. It brings profiles, preferences, requests and guardian participation into one place so members can consider a match with their family involved.

The app is intended for adult members of that community and their guardians. It is being developed before launch; the current Founder preview uses made-up sample profiles while the server rules and real member journeys are completed.

## Status

Pre-launch, built solo since June 2026. Version 1.0.0 (build 5) runs on the Founder's iPhone for internal testing. The redesigned interface is a Founder preview over the existing app. Server and checkout integration are still pending. The website is [zyraconnect.app](https://zyraconnect.app).

The app has no developer rail, Home/Preview/Actions panel, comparison picker, role/plan/wallet selector, reset or onboarding skip shortcut. The protected Founder entry starts with sample Adam on Seeker One. Member settings and controls drawn in current LOCK masters remain, including the Profile Switch flow and the locked local request Demo actions.

Add a Guardian and Add a Seeker open on My code, with a QR, copy and
share. Their code and the Profiles Scan page use the same camera and five
code boxes. Sharing sends the raw code. A request still needs the other
person to accept it.

See [ROADMAP.md](ROADMAP.md) for the next work, including bringing the full test suite back to green. The baseline and final interface milestone stays open until queues 44, 73 and 75 are built and the full suite passes.

When the app or a screen cannot open, ZYRA shows one error page with help for
that failure. Connection and route errors can retry every 15 seconds while the
page is open. On the release framework fallback, Try again restarts the app
when pressed. Contact support opens Help & Support with the error reference.

Browse gives one haptic tick for an accepted photo action, including the
accessible Next page control.

In the Founder preview, a sideways drag brings the neighbouring card into view
on Profiles, Guardian, Journey, Filters and My ZYRA’s Needs you section. The
selection updates when the cards settle. Each Guardian card shows details and
Journey access together. The three-dot menu opens Main Guardian and removal
actions. In the Founder preview, Guardian Circle opens on Main, shows unread
counts by chat, and puts unread Past chats first. Opening a chat clears its
count. The Circle menu offers separate controls for one chat and the whole
Circle. Past Journey topics stay open for members who can write.
Seeker avatars use the first profile photo or the Profile silhouette in
Profile, Circle and Journey. The same photo appears in the profile Preview
and the Guardian's linked Seeker views. Guardians use monograms.
In the ordinary Seeker Guardian tab and Founder preview, the round plus on the
full-height Add card opens Add a Guardian. The ordinary tab shows the card when
there are no linked Guardians and after the last Guardian when there is room.
The Seeker Basic card counts active links, shows the Basic place when its status
is known, shows remaining Guardian One places, and links to the Seeker One
comparison.
Help & Support lists Past Journey summaries in the Guardians FAQ.
The client checks a maximum of 10 active links including Main.
For a Seeker Basic roster, at most one Guardian can be on Guardian Basic.
Live link responses need verified Guardian plans before the client can admit
a second link for Seeker Basic. Profile details show the gold ring and announce
Seeker One when the displayed profile's plan is verified as One. A verified
Seeker Basic profile uses a plain circle. Profiles with an unavailable plan
keep the existing ring. The Profiles details card shows the first photo
above the name and the public age, location, nationality and ethnicity tiles.
Request a Journey appears below the tiles on the details page. Seeker Basic
shows the Seeker One comparison prompt on a backward profile swipe.
Profiles, Guardian, Journey, Filters and My ZYRA let cards slide to the screen
edges with their shadows visible throughout the swipe.
A card settles from the point where the finger lifts, with shorter travel
for a fast flick. Reduce Motion switches pages instantly. Scrolling uses
iPhone-style bounce, with fixed cards following their layout rules.
In the Founder preview, Seeker Basic filters by age and location. The
Nationality and Ethnicity cards link to the Seeker One comparison.
The Founder preview's Compatibility reader has two pages, Overall and
Every area. Seeker One and Guardian One see twelve areas with synthetic
bands in admitted preview results. In a mutually revealed Journey,
Seeker Basic can use a local Unlock to open the areas for that person.
A Guardian with View can open the reader after both Seekers reveal.
Guardian Basic sees the area names with locks and a Guardian One comparison.
A shared Past summary with View on that attempt keeps its read-only row.
Live Compatibility areas show locks or `Not enough answers` pending
approved result wiring.
The Guardian Basic invitation example shows what happens when a Seeker’s
free Guardian place is taken, keeping the current holder private.
Basic profiles and explicit upgrade prompts open the Seeker One or Guardian
One comparison. Current One members keep their membership controls.
The comparison shows only supported differences and explains that checkout
is unavailable in this build.
The full tab bar stays visible on My ZYRA quick access pages, including the
read-only Journey requests opened from Guardian Notifications. A sideways swipe
on My ZYRA changes the Needs you item. New activity badges reflect arrivals.
The My ZYRA Preferences chip and Edit profile open the same Partner preferences
page. Amber is labelled Open to this. The Founder preview includes a
sample Quick check for saved amber choices, including setup lights and the
counterpart’s preference questions. A deliberate tap clears a pending check.
When the server asks for reconfirmation before showing a Compatibility result,
the Seeker can check their saved amber choices in one place and return
to the result with their existing Unlock.
New Compatibility results use the three sect choices shown in the Seeker’s
set-up. A missing sect light appears as Not set in Partner preferences and can
be set with a deliberate tap. Saved results and Unlocks are kept.
In the Founder preview, Guardian invitations and code link requests expire
after 14 days. A Seeker who is still unready sees a Needs you reminder at
48 hours. A Journey that is still waiting for readiness at 72 hours moves
to Past as Not taken up. Under My ZYRA → Journey requests → Past, repeat
requests share one card per person and direction. Open a card to see the
latest five requests and use Show all to see the rest. In sample data the
sender waits 7 days after Not taken up, 14 days after five in a row and
30 days from the tenth onward. Beginning a Journey clears the streak.
The profile button shows the same date during the wait. Live ask-again
dates await SERVER 1.
Ended Journeys have no fixed reading deadline. A Seeker can remove their own
archived Journey, and a block from either side hides it until unblock. A
preview restart can be requested after 24 hours and stays open for 30 days.
When a sample member deletes their account, their active and ended Journeys,
Timelines, Circle discussions, requests, Past items and Introductions disappear
from the other Seeker's preview. My ZYRA shows one anonymous Needs you item
with Open Journey, and the Journey place is free. The Guardian One comparison
uses Continue until a verified store offer is available. Live account deletion
and push delivery await their server rollout.

An open inactivity notice in the Founder preview's sample data clears on
return. My ZYRA shows Welcome back once, with a link to Ended Journeys. The
item goes away when opened or when the Seeker leaves My ZYRA. Member
availability awaits the inactivity server rollout.

Haptics starts on Light for members who have never saved a level.

## Built with

- Flutter and Dart. The current checked toolchain is Flutter 3.44.2; `SOURCE/pubspec.yaml` requires Dart `^3.12.2`.
- Supabase for the backend. `supabase_flutter` is locked to 2.16.0 in `SOURCE/pubspec.lock` (declared constraint `^2.8.0`).
- Native iOS and Android projects under `SOURCE/`.

## Run locally

Install Flutter 3.44 and the platform tools first. Backend and OAuth configuration is local and not committed: copy `SOURCE/lib/config/supabase_config.dart.example` to `supabase_config.dart` and `oauth_config.dart.example` to `oauth_config.dart`, then fill in your own Supabase project's public URL and publishable key and your own OAuth client IDs.

From the repository root, resolve dependencies:

```sh
cd SOURCE
flutter pub get
```

For the Founder-operated iPhone route, export the intended device identifier and approved Founder account UUID in your shell. [.env.example](.env.example) lists the variable names with placeholders only. `run.sh` reads exported shell variables; it does not automatically load an env file. Keep actual values in a private local environment. Replace the example values before use:

```sh
export ZYRA_DEVICE_ID='YOUR_APPLE_DEVICE_IDENTIFIER'
export ZYRA_INTERNAL_FOUNDER_UUID='YOUR_APPROVED_FOUNDER_ACCOUNT_UUID'
./run.sh
```

The default is PROFILE mode, which supports reopening the installed app after unplugging. `./run.sh dev` (or `debug`) starts DEBUG mode and requires the cable to remain connected. Both routes retain the existing opt-in for the exact authenticated Founder account; setting a variable does not grant another account access. `./run.sh release` uses production RELEASE mode with no Founder opt-in and needs only `ZYRA_DEVICE_ID`. Missing required variables stop the script before Flutter runs. The separate Test target is retired.

Widget and capture tests select other sample roles, plans and states from code. The shell uses `ZyraOneJourneyShellFixture` through `SOURCE/test/support/zyra_hidden_dev_controls_driver.dart`; onboarding fixtures and immutable scenario catalogs also live under `SOURCE/test/support/`. These helpers provide values and call guarded source callbacks. They add no runtime picker or navigation door. Ordinary member navigation, saved Personalisation choices and account ownership checks remain with the app.

The signed-in Founder can open **Developer** from a page heading in the
ordinary Seeker app. A fresh session with the existing Founder claim enables
local sample data on that account. See [the Flutter source guide](SOURCE/README.md)
for the offline test commands.

Confirmations share a compact bottom sheet. Profile Preview uses the Profiles card with the member’s own public details and photos. Its request button shows an explanation.

Profile photo review uses the reference Profiles card shape and shows which part of the crop stays visible on the smaller reference screen. Photos fill the full rectangular photo areas in Profiles, Profile Preview, Journey Bio, Guardian views and Manage Photos. The review source is bounded at 3000 px on its longest edge and the saved JPEG at 1440 px. Photo preparation errors show recovery advice and a support reference.

The app requests signed links for private profile photos with a one-hour lifetime.

Use the protected local driver with the installed pinned SDK for checks, without resolving dependencies again:

```sh
cd SOURCE
node tooling/no_git_driver.mjs check
node tooling/no_git_driver.mjs flutter analyze --no-pub
node tooling/no_git_driver.mjs flutter test --no-pub --reporter json
```

The protected iPhone delivery route uses `SOURCE/tooling/verified_host_profile.mjs` with the exact reviewed `HOST_PROFILE_PLAN.json`. Run `inspect` to check the pinned native host and `build` to produce the PROFILE candidate. Delivery requires the Founder’s GO, a paired and unlocked iPhone connected by USB, and the observed SHA-256 of the successful build receipt. The `phone-check` command checks device readiness, and `deliver` verifies the candidate, installation and launch.

Profile video is available in the offline test fixture for Photos, Profiles,
Profile Preview and Journey Bio. The iOS exporter needs a freshly verified native host
before the protected delivery route can package it.

## Repository layout

- `SOURCE/`: Flutter app, native platform projects, tests and Supabase migrations.
- `PRODUCT/`: approved designs, specifications, lock records and the build queue.
- `REPORTS/`: project reports and review records.
- `SYSTEM/`: decisions, open actions, standards and development guidance.

## How work is done

The Founder designs with an AI design assistant and locks each design (pictures at real phone size, a spec with numbers, a lock record in his words). An AI coding assistant then builds only from those locked files: every change is a line in `PRODUCT/APPROVED/BUILD_QUEUE.md` pointing at its brief, and each build ends with checks and an as-built record showing the built screen beside the master. Sample profiles are fictional. The sample profile pictures are simple placeholder images made for this project; they show no real people. Earlier versions in the Git history used photos whose source was not recorded. The placeholders use this repository’s existing Apache-2.0 licence; see `LICENSE`.

## Licence

The source is licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE) for the copyright notice. The ZYRA name, logo and domain are not licensed under that source licence.
