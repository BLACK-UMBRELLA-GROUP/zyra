# ZYRA External Tester Access — Current Handover V1

## Status

Implemented in the app source and verified with Flutter analysis, iOS profile
build, and wireless installation on the connected iPhone.

## Purpose

Provide an invited external TestFlight tester with a safe way to open the main
Seeker and Guardian preview experiences without creating an account or being
stuck at the normal OAuth sign-up gate.

## User flow

1. Tester installs the invited TestFlight build.
2. On the Welcome screen they choose **Private tester access**.
3. They enter the private tester code.
4. They choose Seeker, Seeker Basic, Guardian, or Guardian Basic.
5. The existing local preview shell opens, including the current navigation,
   network, guardian, profile, and dashboard experiences.
6. Sign Out clears the tester latch and returns to the normal Welcome screen.

## Safety boundary

- The entry is compiled only when `ZYRA_EXTERNAL_TESTER_ACCESS=true`.
- The code is compiled into that private build and defaults to `ZYRA-TEST-01`
  unless `ZYRA_EXTERNAL_TESTER_CODE` is supplied.
- The tester session is local preview state; it does not create a Supabase
  user, grant Founder authority, or bypass production RLS.
- Founder Developer Access remains protected by the existing refreshed,
  server-controlled Founder proof.
- Public builds retain the normal Apple/Google sign-up flow and do not show
  the tester entry.

## TestFlight release configuration

Build the private cohort archive with:

```text
flutter build ipa --flavor production \
  --dart-define=ZYRA_EXTERNAL_TESTER_ACCESS=true \
  --dart-define=ZYRA_EXTERNAL_TESTER_CODE=ZYRA-TEST-01
```

The app build number is now `1.0.0+3`. Upload this as a new build under the
existing ZYRA App Store Connect record and add the external tester to the
appropriate TestFlight group. Do not publish this compile configuration as a
public App Store build.

## Files

- `lib/config/zyra_external_tester_policy.dart`
- `lib/screens/auth/tester_access_screen.dart`
- `lib/screens/welcome_screen.dart`
- `lib/services/zyra_developer_access.dart`
- `lib/dev/zyra_dev_local_preview.dart`
- `lib/services/zyra_internal_preview_client.dart`
- `lib/services/zyra_auth.dart`
