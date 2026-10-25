# CODEX → FOUNDER — ZYRA BUILD 5 EXTERNAL BETA REVIEW SUBMITTED

Date: 2026-09-24
Authority: explicit Founder artifact-bound upload approval, followed by
action-time confirmation to transmit dedicated review access information and
submit build 5 for external Beta App Review.

## Outcome

The exact signed ZYRA Connect IPA for version `1.0.0`, build `5`, bundle
`app.zyraconnect.zyra`, Apple ID `6810741513`, SHA-256
`da89aff38201eee83bb0f3685b09a6c1350b9853e34bee831c99e9a44940fca0`
was uploaded exactly once. Apple's upload command returned exit 0 with
`PROCESSING`. Fresh App Store Connect evidence then showed upload `Complete`
and build 5 `Ready to Submit`.

The first hidden-password prompt did not accept a credential and did not start
an Apple upload. After the Founder explicitly asked to retry, a fresh one-use
prompt handled the app-specific password through hidden stdin. No credential
was placed in chat, command arguments, environment variables, Keychain, log or
evidence file. The user's clipboard was restored after the later browser form
handoff; the short-lived local credential bridge was stopped and contained no
credential in its URL.

## Review correction

App Store Connect Test Information was corrected from the rejected single-code
instruction to the build-5 two-field **Review & tester access** flow. Sign-in
required was enabled. The dedicated local-review username/password, corrected
access steps, review notes, company contact email and the Founder-entered phone
number were saved. No production member credential, Founder credential or live
member data was supplied. Apple showed zero required-field errors after save.

Build 5 was added to the existing external group `1ST GROUP`. Automatic tester
notification remains enabled. The build was submitted for Beta App Review and
fresh Apple UI showed:

- group: `External Group · 1 Tester · 2 Builds`;
- build `1.0.0 (5)`: `Waiting for Review`, expiring in 90 days;
- historical build 4: retained and still `Rejected`;
- existing tester: retained; no tester was added, removed or edited.

No public link was created. No old build was deleted. No reply was posted to
the historical rejection thread. The corrected build and complete review access
information are the active submission.

## Remaining boundary

Apple approval is not yet claimed. Tester installation, update and real-device
acceptance are not yet claimed. Monitor for approval, rejection or information
request. Any reviewer reply requires a fresh action-time Founder confirmation.
External testers must not upload real photos until the separately governed
photo metadata/size change ships.
