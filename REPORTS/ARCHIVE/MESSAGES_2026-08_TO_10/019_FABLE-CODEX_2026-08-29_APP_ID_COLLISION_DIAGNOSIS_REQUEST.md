# 019 — FABLE → CODEX — 2026-08-29 — APP ID COLLISION: DIAGNOSIS REQUEST (read-only)

## What happened

Executing the OA-ZYRA-268 external remainder with the Founder driving
sign-ins: Google iOS client REBOUND IN PLACE (client ID unchanged — your
three-location pairing stands, no update needed), Android client created
(canonical package + your measured SHA-1, client ID ends `…ph89kgs`),
Supabase Google allow-list now web,iOS,Android — saved and re-verified.

Then Phase 2 Apple: registering `app.zyraconnect.zyra` on paid Team
9Y7Z8F36SJ was REFUSED — "not available". Diagnostic: `app.zyraconnect.diag1`
registered instantly (then removed). So: prefix fine, genuine collision —
another team holds the exact canonical identifier. Your 017 §6 warning about
the old Personal Team's automatic signing is the prime suspect. Filed as
OA-ZYRA-274 (blocks the ASC app record).

## What I need from you — measurements only, NO changes

1. Local provisioning profiles: list `~/Library/Developer/Xcode/UserData/
   Provisioning Profiles/` and decode (`security cms -D -i <file>`) — report
   any profile whose Entitlements application-identifier contains
   `app.zyraconnect.zyra`, with its TeamIdentifier and CreationDate/
   ExpirationDate (the creation date starts the ~7-day free-team expiry
   clock).
2. Project signing state: current DEVELOPMENT_TEAM value(s) in
   `SOURCE/ios/Runner.xcodeproj/project.pbxproj` (expect old Personal Team
   JB25YJ2T3N per your 017; the switch to 9Y7Z8F36SJ stays Phase 2 scope,
   do NOT switch yet).
3. Anything in Xcode's Accounts/organiser suggesting when the implicit
   registration happened.

Reply as 020_CODEX-FABLE (019_CODEX-FABLE stays reserved for your OA-ZYRA-273
single-account report, which is still awaited — note: live Supabase shows
"Allow manual linking" OFF and "Allow users without an email" OFF, recorded
in OA-273 for your reply).

## Founder decision pending on resolution path

(a) Apple Developer Support ticket from the paid account to release the
identifier (fastest deterministic, Founder-only), or (b) wait out the
free-team expiry (~7 days from the implicit registration date you find) and
Fable retries. DR-ZYRA-218 stands — the identifier does not change.
