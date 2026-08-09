// App entry gate — OA-102 session persistence. supabase_flutter itself
// persists the session locally between app restarts; this widget is
// what actually acts on that at cold start: skip Welcome/sign-in
// entirely if a session is already there, otherwise show Welcome as
// before. Without this, a signed-in user would be asked to sign in
// again every time they reopened the app, which defeats the point of
// session persistence existing at all.

import 'package:flutter/material.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_session_router.dart';
import '../widgets/zyra_loading.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  /// Whether to play the full splash before handing over.
  ///
  /// TRUE at cold start — main.dart's `home:`. That is the launch the
  /// splash exists for.
  ///
  /// FALSE when re-entering the gate from inside an already-running app.
  /// Today that is Developer Access switching test accounts. Founder,
  /// 2026-08-08: "on dev button I pick user, I see the splash screen, I
  /// don't want that."
  ///
  /// ── WHY A FLAG AND NOT A DIFFERENT ROUTE. The 2026-08-07 change that
  /// sent Developer Access through AuthGate did TWO things, and only one of
  /// them was wrong. The splash was wrong. The other — deleting
  /// `preset.isWali ? WaliHomeShell : HomeShell` so routing is decided
  /// once, by ZyraSessionRouter, from the profile row rather than a
  /// hand-set flag in the dev screen — was right and must survive. So the
  /// dev screen still goes through the gate; it just does not ask for the
  /// performance.
  final bool playSplash;

  const AuthGate({super.key, this.playSplash = true});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Widget> _resolved = _resolve();

  /// When [AuthGate.playSplash], the splash ALWAYS plays in full —
  /// Founder, 2026-08-07: "every time I open the app I want to start with
  /// the splash screen."
  ///
  /// So there are two conditions to move on, not one: the animation must
  /// have finished AND the session must have resolved. Whichever is slower
  /// decides.
  ///
  /// On a fast launch the animation is the limit and the app waits for it —
  /// that is the deliberate cost of having one. On a slow network the fetch
  /// is the limit and the splash simply holds on its final frame, which is
  /// why that frame is composed to be calm to sit on rather than to be the
  /// end of a movement.
  ///
  /// Initialised TRUE when the splash is skipped, so the only remaining
  /// condition is the session resolving.
  late bool _animationDone = !widget.playSplash;

  Future<Widget> _resolve() async {
    if (!ZyraAuth.isSignedIn) return const WelcomeScreen();
    return ZyraSessionRouter.resolveHome();
  }

  /// How long brand purple takes to resolve into the member's own colour.
  ///
  /// Matches the 260ms cross-fade main.dart uses when the gendered
  /// background changes, so the app only ever has one speed for "the
  /// background colour is changing".
  static const _handoff = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolved,
      builder: (context, snapshot) {
        // SPLASH, NOT A SPINNER — 2026-08-07. This branch was a bare
        // CircularProgressIndicator on a gradient: real waiting, presented
        // as a loading indicator.
        //
        // Note the condition is no longer just `!snapshot.hasData`. The
        // splash outlives the fetch when the fetch is quick, because it now
        // always plays through — see _animationDone.
        //
        // ── THE HANDOFF IS THIS WIDGET'S JOB — 2026-08-08.
        //
        // The splash is BRAND PURPLE for its whole four seconds and is not
        // gender-matched (DR-ZYRA-094 lists Splash Screen under GLOBAL
        // BRAND). main.dart's layer underneath IS gender-matched, so
        // swapping the splash out in one frame cuts straight from purple to
        // the member's colour — which is the "second of purple before it
        // goes pink" the Founder reported on 2026-08-07.
        //
        // That was previously "fixed" by tinting the splash itself, i.e. by
        // making it the wrong colour for four seconds to avoid being the
        // wrong colour for one frame. Reversed 2026-08-08 on Founder
        // instruction. The cut is softened here instead, where the two
        // colours actually meet.
        //
        // AnimatedSwitcher cross-fades the two. Brand purple RESOLVES INTO
        // the member's colour instead of being replaced by it.
        //
        // Stacking is the DEFAULT layoutBuilder's, deliberately not
        // overridden: previous children first, current last, so the
        // incoming screen paints ON TOP of the outgoing splash and fades
        // up over it. That is the right way round here. Whatever shows
        // through mid-fade is main.dart's gendered layer — the destination
        // colour — so the blend only ever moves toward where it is going.
        return AnimatedSwitcher(
          duration: _handoff,
          // Fade only. A slide or scale would read as navigation; this is
          // one screen becoming another, not a push.
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: (!snapshot.hasData || !_animationDone)
              // WAITING. Two different things depending on why.
              //
              // Cold start: the splash, which is a statement and owns a
              // fixed 3s. Re-entry (Developer Access): ZyraLoading, which
              // is forgettable and lasts exactly as long as the profile
              // read — usually a few hundred milliseconds, often invisible.
              ? (widget.playSplash
                  ? SplashScreen(
                      // Keyed so AnimatedSwitcher treats splash and home as
                      // different children. Without a key it compares by
                      // runtime type alone, and the resolved screen's type
                      // varies by route, which would make the transition
                      // fire inconsistently.
                      key: const ValueKey('splash'),
                      // setState only on the first fire. The controller
                      // emits `completed` once, but a rebuild mid-animation
                      // would recreate the widget and re-run it — guarding
                      // here keeps the flag monotonic either way.
                      onFinished: () {
                        if (mounted && !_animationDone) {
                          setState(() => _animationDone = true);
                        }
                      },
                    )
                  : const ZyraLoading.fullScreen(key: ValueKey('loading')))
              : KeyedSubtree(
                  key: const ValueKey('resolved'),
                  child: snapshot.data!,
                ),
        );
      },
    );
  }
}
