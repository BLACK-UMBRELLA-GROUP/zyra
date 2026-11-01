# ZYRA

ZYRA is a Muslim matrimonial app for people seeking marriage. It brings profiles, preferences, requests and guardian participation into one place so members can consider a match with their family involved.

The app is intended for adult Muslim members and their guardians. It is being developed before launch; the current Founder preview uses made-up sample profiles while the server rules and real member journeys are completed.

## Status

Pre-launch. Version 1.0.0 (build 5) is installed on the Founder's iPhone for internal PROFILE testing. The new interface is a Founder preview; ordinary members still see the existing app. Server integration, pricing and purchases are not connected to the preview. No TestFlight upload is part of this repository preparation. The website is [zyraconnect.app](https://zyraconnect.app).

See [ROADMAP.md](ROADMAP.md) for the next work. The existing full test baseline has failures and is not a passing release check.

## Built with

- Flutter and Dart. The current checked toolchain is Flutter 3.44.2; `SOURCE/pubspec.yaml` requires Dart `^3.12.2`.
- Supabase for the backend. `supabase_flutter` is locked to 2.16.0 in `SOURCE/pubspec.lock` (declared constraint `^2.8.0`).
- Native iOS and Android projects under `SOURCE/`.

## Run locally

Install the required Flutter toolchain and platform tools first. Backend and OAuth configuration is local: supply the existing ignored files `SOURCE/lib/config/supabase_config.dart` and `SOURCE/lib/config/oauth_config.dart` through your own approved development setup. This repository does not supply private configuration.

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

These are human-operated device commands. AI implementation sessions follow the repository's process-execution rules rather than invoking the legacy script.

## Repository layout

- `SOURCE/`: Flutter app, native platform projects, tests and Supabase migrations.
- `PRODUCT/`: approved designs, specifications, lock records and the build queue.
- `REPORTS/`: project reports and review records; private legal drafts have moved to the private group repository.
- `SYSTEM/`: decisions, open actions, standards and development guidance.

## How work is done

The Founder approves and locks design documents before implementation. AI coding assistants build from those locked files. Every change goes through `PRODUCT/APPROVED/BUILD_QUEUE.md`, with checks and an as-built handover recorded before completion.

## Licence

The source is licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE) for the copyright notice. The ZYRA name, logo and domain are not licensed under that source licence.
