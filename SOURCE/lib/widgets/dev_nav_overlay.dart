// Pass-through wrapper — renders its child unmodified. (HISTORY: this
// began as a temporary testing aid with floating Back/Home buttons,
// debug-only behind `!kReleaseMode`; the buttons and the guard moved to
// DevScenarioPanel — see the notes further down. The wrapper stays only
// so MaterialApp's `builder:` wiring in main.dart needs no churn.)
// Retitled 2026-08-12: the old header described the buttons this file no
// longer contains, contradicting the code 50 lines below it.
//
// Sits on top of the whole app via MaterialApp's `builder:` (see
// main.dart), using a global navigatorKey rather than a local
// BuildContext, so it works identically no matter how deep the current
// screen is in the navigation stack.
//
// 2026-07-19 fix: reported as "visible but not functional." Root cause —
// several ZYRA flows (onboarding chapters especially) don't push real
// Navigator routes per step; they track a step index inside one
// StatefulWidget's own State. A plain Navigator.pop() has nothing to do
// in those screens, so it looked "broken" when it was actually a no-op
// by design. Fixed by making Home a hard reset (pushAndRemoveUntil a
// fresh WelcomeScreen), which wipes the whole widget tree — including
// any internal step state — regardless of how the current screen was
// reached. Back remains a soft pop, which is a legitimate no-op on a
// screen with nothing above it in the route stack (e.g. right after
// opening the app) — not a bug, just nothing to go back to yet.

// 2026-07-19 fix 2 (Fable): gate changed kDebugMode -> !kReleaseMode so
// the overlay also appears in PROFILE builds. Reason: the recurring
// "crashes after unplugging the phone / won't relaunch from the icon"
// problem was not an app bug at all — `flutter run` installs a DEBUG
// build, and iOS kills JIT (debug) apps the moment no debugger is
// attached, and refuses to cold-launch them from the icon. Untethered
// device testing must therefore use `flutter run --profile` (or
// --release), which is AOT-compiled and runs standalone. Profile mode
// keeps this overlay available during that testing; release builds
// (the only thing real users ever get) still never show it.
//
// Back also now explains itself when there is genuinely nothing to go
// back to, instead of silently doing nothing — "silent no-op" and
// "broken" are indistinguishable to a person testing on a phone.
//
// SIMPLIFIED 2026-07-26 (Founder, reviewing the Browse page: "the back
// button is not needed cos I don't use it, so for dev let's just keep
// the home button"): Back removed. Home alone is enough to get unstuck
// (hard reset to WelcomeScreen, which has its own way back into
// whatever the tester needs) and was already doing most of the real
// work — Back's own no-op case above came up often enough to need its
// own explanatory snackbar, which is itself a sign it wasn't pulling
// its weight as a second control.
//
// MOVED 2026-07-26 (Founder: "move the bell icon to right underneath
// the 3 dots... meaning u might have to move the home button on
// left"). HomeShell's Bell + Help/Report column now occupies top-right
// more fully than before, so this button moved from right to left to
// stay clear of it.

// `kReleaseMode` is no longer imported — it appears only in the history
// above now. The release guard moved to DevScenarioPanel along with the
// button that needed it; this wrapper renders nothing of its own, so it
// has nothing to guard.
import 'package:flutter/material.dart';

class DevNavOverlay extends StatelessWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const DevNavOverlay({super.key, required this.child, required this.navigatorKey});

  // _goBack removed 2026-08-01 (Fable, analyzer cleanup): the Back button
  // itself was removed 2026-07-26 per the SIMPLIFIED note above, which
  // left this method orphaned — flutter analyze flagged it unused.
  // EMPTIED 2026-08-03 (Founder: "put the home button in the toggle tab
  // at top"). The floating Home circle moved into DevScenarioPanel —
  // _goHome and _DevButton went with it.
  //
  // It was pinned to the top-left of every screen at a fixed offset, which
  // put it directly on top of each page's title. That is visible in every
  // screenshot taken this week: the dark circle covering "Connections".
  //
  // This wrapper is kept rather than deleted because main.dart's
  // `builder:` composes it around every route, and it is the natural place
  // for the next always-on debug affordance. It currently passes its child
  // straight through and costs one widget in the tree.
  //
  // `navigatorKey` is likewise kept: removing it would change the
  // constructor and touch main.dart for no behavioural gain, and whatever
  // replaces the Home button will want it.
  @override
  Widget build(BuildContext context) => child;
}
