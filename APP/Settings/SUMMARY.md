# Settings

**Status:** Partially built
**Updated:** 2026-08-20 (DR-ZYRA-209/210; OA-ZYRA-244/245)

------------------------------------------------------------
WHERE IT LIVES
------------------------------------------------------------

There is no standalone Settings tab or top-level Settings screen.
Settings is a section within the Profile tab (SOURCE/lib/screens/
profile/profile_screen.dart) and its Guardian equivalent (screens/guardian/
wali_profile_screen.dart), listing:

  • Notifications  → SOURCE/lib/screens/settings/notification_settings_screen.dart
  • Privacy         → SOURCE/lib/screens/settings/privacy_settings_screen.dart
  • Sign-in & security → SOURCE/lib/screens/settings/sign_in_security_screen.dart
  • Manage Subscription → existing UpgradeScreen
  • Help & Support  → SOURCE/lib/screens/settings/help_support_screen.dart (#22)
  • Sign Out        → built, functional
  • Delete Account  → real, built 2026-07-26 (#22) — see below

------------------------------------------------------------
HELP & SUPPORT — REAL SCOPE (#22)
------------------------------------------------------------

No in-app ticketing/chat system exists. The screen surfaces the real,
documented support address (BUSINESS/ZYRA LAUNCH GUIDE/Summary.md:
support@zyra.app) as selectable text, plus category rows mirroring
onboarding_scaffold.dart's existing (previously unwired) help-sheet
categories. Deliberately did not add a url_launcher-style dependency
for a mailto: link mid-session — an unverified new package addition
carries real risk with no way to build/test it in this environment.

------------------------------------------------------------
DELETE ACCOUNT — REAL SCOPE (#22)
------------------------------------------------------------

Real, hard deletion — `delete_own_account()` (SECURITY DEFINER,
20260726170000_delete_own_account.sql), verified end-to-end against a
scratch test account (not real seed data): deletes the auth.users row,
which cascades through profiles.id REFERENCES auth.users(id) ON DELETE
CASCADE and from there through every table referencing profiles(id) —
matches, conversations, messages, timelines, wali_links, wali_invites,
saves, likes, subscriptions, profile_photos, notifications,
onboarding_answers, journey_* tables. Also removes the user's actual
photo files from the `profile-photos` Storage bucket (client-side
Storage API call first, then a server-side path-prefix cleanup as a
second attempt — direct SQL DELETE on storage.objects is blocked by
Supabase's own protect_delete trigger unless explicitly bypassed,
which the function does via a scoped `storage.allow_delete_query`
setting).

Disclosed to the user in the confirmation dialog: deleting a Seeker's
account also deletes the OTHER party's copy of any shared Match/
conversation history (both sides of a match reference profiles(id) ON
DELETE CASCADE) — an unavoidable consequence of a real hard delete,
not withheld from the user.

Available to both Seeker and Guardian accounts (profile_screen.dart and
wali_profile_screen.dart both wire the same ZyraAuth.deleteAccount()).

"Link a Guardian" was removed from this list 2026-07-26 — Guardian linking is
now its own bottom-nav tab (see APP/Navigation/SEEKER NAVIGATION/
Summary.md), so a duplicate entry here would have been a second path
to the same flow.

------------------------------------------------------------
SIGN-IN & SECURITY — APPROVED MODEL
------------------------------------------------------------

The public app keeps Apple and Google as its two normal sign-in choices.
Settings shows each connected provider and allows an authenticated member to
link the missing provider to the same Supabase user id. A separately verified
recovery email provides six-digit one-time-code recovery with no ZYRA
password and cannot create an account.

Provider identity, recovery email and contact/notification email are labelled
separately. Matching email text never causes an automatic account merge.

The Founder's Google Workspace account uses the same Google button as every
other member. Developer Access depends on an exact-account, protected
server-issued role and is available only after authentication in non-release
builds. The Workspace domain alone never grants access; ordinary Google users
route normally; release builds expose no developer route.

The current pre-auth Developer Access entry and embedded shared test password
are technical debt. Their protected server-mediated replacement is tracked by
OA-ZYRA-245. Live Google/Apple/manual-linking/email-template configuration is
also required before the relevant controls are production-ready. No database
migration is authorised by this decision.

------------------------------------------------------------
NOTIFICATIONS SCREEN — REAL SCOPE
------------------------------------------------------------

There is no push notification system in this build — no delivery
mechanism, no backend table, and no Bell icon anywhere yet either,
despite SEEKER NAVIGATION's own ratified rule assuming one exists.
The screen says this plainly rather than implying working
notifications, and captures three preference toggles (New Matches,
New Messages, Guardian Requests) in AppState — saved for this session,
not yet wired to any real delivery mechanism.

------------------------------------------------------------
PRIVACY SCREEN — REAL SCOPE
------------------------------------------------------------

One genuinely-wired control: "Visible in Browse", toggling
`profiles.is_active` (the same column Browse's own discovery query
filters on, and that profiles_select RLS checks for row visibility).
Turning it off actually removes the Seeker from Browse for everyone
else — not cosmetic. No other privacy controls (blocking, photo
visibility rules, etc.) exist yet; the screen says so.

------------------------------------------------------------
NOT BUILT
------------------------------------------------------------

  • Data export (deletion is built; a downloadable copy of one's own
    data before/instead of deleting is not)
  • Any privacy control beyond Browse visibility
  • In-app ticketing/chat for Help & Support (email only)
  • Live OAuth/manual-linking/recovery-email configuration and proof
    (OA-ZYRA-244)
  • Protected Google Workspace Founder/developer authorisation and the
    server-mediated seeded-persona switch (OA-ZYRA-245)
