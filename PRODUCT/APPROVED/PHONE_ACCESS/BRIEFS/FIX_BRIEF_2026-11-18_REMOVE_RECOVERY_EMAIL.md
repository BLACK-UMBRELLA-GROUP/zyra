# FIX BRIEF — REMOVE RECOVERY EMAIL FROM THE APP — 18 NOV 2026

Founder, 18 Nov 19:25 (prototype comment on the Welcome page): "lets remove recovery email text and whatever it was from app - we will talk security further down line". Also stated 18 Nov 19:22: accounts are created only with Apple or Google; on iPhone Apple is on top, on Android Google is on top.

A removal (fix only, AD-AIOS-149). Server tables and functions are NOT changed by this line (server work belongs to Fable's briefs).

## Change
1. Welcome screen (`lib/screens/welcome_screen.dart`): remove the "Use recovery email" link and its route to `EmailRecoveryScreen`. Welcome shows only Continue with Apple and Continue with Google; Apple first on iOS, Google first on Android.
2. Sign-in & security (`lib/screens/settings/sign_in_security_screen.dart`): remove the recovery email row and the Add / Verify recovery email setup steps.
3. Privacy & data (`lib/screens/settings/privacy_and_data_screen.dart`, around line 99): remove the sentence about a recovery email.
4. Remove `lib/screens/auth/email_recovery_screen.dart` and any now-unused recovery-email client code and its tests (move nothing to the server; leave server functions in place). List every file removed in the as-built record.
5. No other sign-in change. No new wording.

## Checks
- Welcome on iPhone: Apple, then Google; nothing else below.
- Settings show no recovery email anywhere; search the app for "recovery email" returns nothing in member-facing text.
- Tests updated; no new failures.

## Note for later (Founder: "we will talk security further down line")
Without a recovery email, a member who loses their Apple or Google sign-in has no in-app way back. Fable to keep this as an open security question for the Founder.
