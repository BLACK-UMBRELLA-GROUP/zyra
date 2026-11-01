# ZYRA

ZYRA is a Muslim matrimonial app for people seeking marriage. It brings profiles, preferences, requests and guardian participation into one place so members can consider a match with their family involved.

The app is intended for adult Muslim members and their guardians. It is being developed before launch; the current Founder preview uses made-up sample profiles while the server rules and real member journeys are completed.

## Status

Pre-launch, built solo since June 2026. Version 1.0.0 (build 5) runs on the Founder's iPhone for internal testing; the redesigned interface is a Founder preview over the existing app, and server integration, pricing and purchases are not yet connected to it. The website is [zyraconnect.app](https://zyraconnect.app).

See [ROADMAP.md](ROADMAP.md) for the next work, including bringing the full test suite back to green.

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

## Repository layout

- `SOURCE/`: Flutter app, native platform projects, tests and Supabase migrations.
- `PRODUCT/`: approved designs, specifications, lock records and the build queue.
- `REPORTS/`: project reports and review records.
- `SYSTEM/`: decisions, open actions, standards and development guidance.

## How work is done

The Founder designs with an AI design assistant and locks each design (pictures at real phone size, a spec with numbers, a lock record in his words). An AI coding assistant then builds only from those locked files: every change is a line in `PRODUCT/APPROVED/BUILD_QUEUE.md` pointing at its brief, and each build ends with checks and an as-built record showing the built screen beside the master. Sample profiles and pictures are made up (free stock photos), never real members.

## Licence

The source is licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE) for the copyright notice. The ZYRA name, logo and domain are not licensed under that source licence.
