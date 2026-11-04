// App entry gate — OA-102 session persistence. supabase_flutter itself
// persists the session locally between app restarts; this widget is
// what actually acts on that at cold start: skip Welcome/sign-in
// entirely if a session is already there, otherwise show Welcome as
// before. Without this, a signed-in user would be asked to sign in
// again every time they reopened the app, which defeats the point of
// session persistence existing at all.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Session, Supabase;
import '../dev/zyra_dev_local_preview.dart';
import '../dev/zyra_founder_launch_screen.dart';
import '../models/zyra_error_state.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_app_lock.dart';
import '../services/zyra_developer_access.dart';
import '../services/zyra_session_router.dart';
import '../widgets/zyra_full_screen_error.dart';
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

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  late Future<Widget> _resolved;
  bool _didRetry = false;
  bool _exiting = false;
  bool _authRecoveryPending = false;
  String? _routeOwner;
  int _routeGeneration = 0;
  int _request = 0;
  StreamSubscription? _authSubscription;
  Session? _routeSession;
  final Set<String> _loggedErrorReferences = {};
  final Completer<void> _splashFinished = Completer<void>();
  ZyraLocalPreviewPreparation? _preparation;
  bool _destinationPrepared = false;
  bool _splashRetainable = true;
  bool _startupCommitted = false;
  // Presentation history only, never proof or permission. The same AuthGate
  // can remain mounted and resolve a later SDK session after its cold arrival.
  bool _destinationPainted = false;
  // Leaving before the first destination paints still ends the launch artwork.
  // This latch never supplies destination paint, preparation or access proof.
  bool _coldArrivalInterrupted = false;
  bool _startupWasForeground = false;
  bool _startupSuspended = false;

  /// When [AuthGate.playSplash], the splash ALWAYS plays in full —
  /// Founder, 2026-08-07: "every time I open the app I want to start with
  /// the splash screen."
  ///
  /// So there are two conditions to move on, not one: the animation must
  /// have finished AND the session must have resolved. Whichever is slower
  /// decides.
  ///
  /// On a fast launch the animation is the limit. Real routing and the second
  /// protected Founder preparation happen beneath it. Genuinely pending work
  /// after the full splash uses an unbranded quiet canvas, never another
  /// wordmark animation or an artificial minimum waiting interval.
  ///
  /// Initialised TRUE when the splash is skipped, so the only remaining
  /// condition is the session resolving.
  late bool _animationDone = !widget.playSplash;

  @override
  void initState() {
    super.initState();
    if (_animationDone) _splashFinished.complete();
    WidgetsBinding.instance.addObserver(this);
    ZyraAppLock.instance.addListener(_foregroundChanged);
    _resolved = _resolve()..ignore();
    _authSubscription = ZyraAuth.authStateChanges.listen(
      _refreshForSessionChange,
      onError: (Object error, StackTrace stack) {
        if (!mounted || _exiting) return;
        _discardPreparation();
        _request++;
        _routeOwner = ZyraAuth.currentUser?.id;
        ZyraAccountState.synchronize(_routeOwner);
        _routeGeneration = ZyraAccountState.generation;
        setState(() {
          _authRecoveryPending = true;
          // Attach an error handler immediately; FutureBuilder subscribes on
          // the next frame and still renders the existing recovery design.
          _resolved = Future<Widget>.error(error)..ignore();
        });
      },
    );
  }

  @override
  void dispose() {
    _request++;
    _discardPreparation();
    if (!_splashFinished.isCompleted) _splashFinished.complete();
    WidgetsBinding.instance.removeObserver(this);
    ZyraAppLock.instance.removeListener(_foregroundChanged);
    _authSubscription?.cancel().ignore();
    super.dispose();
  }

  void _refreshForSessionChange(AuthState state) {
    if (!mounted || _exiting) return;
    final sameLifetime =
        _routeOwner == ZyraAuth.currentUser?.id &&
        _routeGeneration == ZyraAccountState.generation &&
        !ZyraAccountState.isSigningOut;
    final actualSession = Supabase.instance.client.auth.currentSession;
    final authenticEvent = identical(state.session, actualSession);
    final recoveredSession =
        authenticEvent &&
        (state.event == AuthChangeEvent.tokenRefreshed ||
            state.event == AuthChangeEvent.signedIn) &&
        state.session != null &&
        state.session!.user.id == _routeOwner;
    final replacedLifetime =
        authenticEvent &&
        !identical(actualSession, _routeSession) &&
        (state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.initialSession ||
            state.event == AuthChangeEvent.passwordRecovery ||
            state.event == AuthChangeEvent.signedOut);
    if (authenticEvent &&
        sameLifetime &&
        state.event == AuthChangeEvent.tokenRefreshed) {
      _routeSession = actualSession;
    }
    if (sameLifetime &&
        !replacedLifetime &&
        !(_authRecoveryPending && recoveredSession)) {
      return;
    }
    setState(() {
      // Consume recovery before resolving: the resolver refreshes Auth using
      // its existing protected policy and may emit another token event.
      // Duplicate healthy events must not recursively restart that request.
      // A changed owner instead gets the normal new-lifetime route below.
      _authRecoveryPending = false;
      _discardPreparation();
      _request++;
      _resolved = _resolve()..ignore();
    });
  }

  Future<Widget> _resolve() async {
    _routeOwner = ZyraAuth.currentUser?.id;
    _routeSession = Supabase.instance.client.auth.currentSession;
    ZyraAccountState.synchronize(_routeOwner);
    _routeGeneration = ZyraAccountState.generation;
    final owner = _routeOwner;
    final generation = _routeGeneration;
    final request = _request;
    _startupCommitted = false;
    _destinationPrepared = false;
    if (!ZyraAuth.isSignedIn) return const WelcomeScreen();
    final destination = await ZyraSessionRouter.resolveHome();
    if (!mounted || !_callbackCurrent(owner, generation, request)) {
      throw StateError('Startup lifetime changed.');
    }
    if (destination is! ZyraFounderLaunchScreen) {
      _destinationPrepared = true;
      await _splashFinished.future;
      final published = await _commitOnForegroundFrame<Widget>(
        () {
          _startupCommitted = true;
          return destination;
        },
        current: () =>
            _callbackCurrent(owner, generation, request) && _foreground,
      );
      if (published == null) {
        throw StateError('Startup lifetime changed.');
      }
      return published;
    }
    // The router's freshly authorized Founder placeholder used to mount only
    // after splash, then start a second refresh while showing Golden thread.
    // Run that same protected work now, while the existing splash is playing.
    final preparation = await ZyraDevLocalPreview.prepare(
      current: () =>
          _callbackCurrent(owner, generation, request) && _foreground,
      route: ModalRoute.of(context),
      onCreated: (preparation) => _preparation = preparation,
      isWali: false,
    );
    if (!_callbackCurrent(owner, generation, request) || preparation == null) {
      preparation?.dispose();
      throw const ZyraPreviewAuthorizationException();
    }
    _preparation = preparation;
    _destinationPrepared = true;
    // This is primitive preparation, not a hidden destination widget. It may
    // be consumed only after the unchanged splash, with a final post-frame
    // foreground check. Waiting presentation never supplies access proof.
    await Future.any([_splashFinished.future, preparation.withdrawn]);
    if (!preparation.isReady) {
      preparation.dispose();
      throw const ZyraPreviewAuthorizationException();
    }
    final presentation = await _commitOnForegroundFrame(
      () {
        final presentation = preparation.commit();
        if (presentation != null) _startupCommitted = true;
        return presentation;
      },
      current: () => preparation.isReady,
      withdrawn: preparation.withdrawn,
    );
    if (presentation == null ||
        !_callbackCurrent(owner, generation, request) ||
        !_foreground) {
      throw const ZyraPreviewAuthorizationException();
    }
    _preparation = null;
    _startupCommitted = true;
    return presentation.buildDestination();
  }

  bool get _foreground =>
      mounted &&
      ZyraLocalPreviewPreparation.foreground &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  bool get _coldArrival =>
      widget.playSplash && !_destinationPainted && !_coldArrivalInterrupted;

  void _discardPreparation() {
    _preparation?.dispose();
    _preparation = null;
    _destinationPrepared = false;
  }

  Future<T?> _commitOnForegroundFrame<T>(
    T? Function() commit, {
    required bool Function() current,
    Future<void>? withdrawn,
  }) async {
    if (!mounted || !current()) return null;
    final frame = Completer<void>();
    T? result;
    Object? failure;
    StackTrace? failureStack;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && current()) {
        try {
          result = commit();
        } catch (error, stack) {
          failure = error;
          failureStack = stack;
        }
      }
      frame.complete();
    });
    WidgetsBinding.instance.scheduleFrame();
    // Access still commits only on an actual eligible foreground frame.
    // Withdrawal may end this await, but cannot make the callback current.
    await Future.any([frame.future, ?withdrawn]);
    if (failure != null) {
      Error.throwWithStackTrace(failure!, failureStack!);
    }
    return result;
  }

  void _foregroundChanged() {
    if (!mounted) return;
    final foreground = _foreground;
    if (foreground) _startupWasForeground = true;
    final interruptedColdArrival =
        !foreground && _startupWasForeground && _coldArrival;
    if (interruptedColdArrival) {
      _coldArrivalInterrupted = true;
      _animationDone = true;
      if (!_splashFinished.isCompleted) _splashFinished.complete();
    }
    if (_startupCommitted) {
      // A committed destination may still be at zero opacity and not have
      // reported a paint. Retire the outgoing launch artwork even then,
      // without restarting or granting any routing/preparation work.
      if (interruptedColdArrival) setState(() {});
      return;
    }
    if (!foreground) {
      if (_startupSuspended) return;
      _startupSuspended = true;
      _request++;
      _discardPreparation();
      return;
    }
    if (!_startupSuspended) return;
    setState(() {
      _startupSuspended = false;
      _request++;
      _resolved = _resolve()..ignore();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ModalRoute subscribes to current-route changes. A covering route is a
    // terminal interruption, even if it is popped before preparation returns.
    _foregroundChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foregroundChanged();
  }

  bool _callbackCurrent(String? owner, int generation, int request) =>
      mounted &&
      !_exiting &&
      request == _request &&
      !ZyraAccountState.isSigningOut &&
      ZyraAuth.currentUser?.id == owner &&
      ZyraAccountState.generation == generation;

  void _retry(String? owner, int generation, int request) {
    if (!_callbackCurrent(owner, generation, request)) return;
    setState(() {
      _discardPreparation();
      _request++;
      _authRecoveryPending = false;
      _didRetry = true;
      _resolved = _resolve()..ignore();
    });
  }

  void _returnToWelcome(String? owner, int generation, int request) {
    if (!_callbackCurrent(owner, generation, request)) return;
    _request++;
    _showWelcome();
  }

  void _showWelcome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _signInAgain(String? owner, int generation, int request) async {
    if (!_callbackCurrent(owner, generation, request)) return;
    _exiting = true;
    final previewBlocked = ZyraDeveloperAccess.blocksMemberRouting;
    try {
      await ZyraAuth.signOut(expectedUserId: owner);
    } catch (error) {
      // An expired server session can make remote sign-out fail. The member
      // still needs a usable exit instead of being trapped on this page.
      debugPrint(
        'ZYRA expired-session sign-out failed (${error.runtimeType}).',
      );
      // A failed preview sign-out retains its denial latch and recovery page.
      // Do not imply that another account can now use live member data.
      if (previewBlocked && mounted) {
        setState(() {
          _request++;
          _resolved = _resolve()..ignore();
        });
        return;
      }
    } finally {
      _exiting = false;
    }
    // Sign-out deliberately invalidates this owner's generation once. Any
    // replacement/re-login is a different lifetime and owns its own routing.
    if (!mounted ||
        request != _request ||
        ZyraAccountState.isSigningOut ||
        ZyraAuth.currentUser != null ||
        ZyraAccountState.userId != null ||
        ZyraAccountState.generation != generation + 1) {
      if (mounted && request == _request) {
        setState(() {
          _request++;
          _resolved = _resolve()..ignore();
        });
      }
      return;
    }
    _request++;
    _showWelcome();
  }

  Widget _errorScreen(Object error) {
    final owner = _routeOwner;
    final generation = _routeGeneration;
    final request = _request;
    final kind = zyraErrorKindFor(error);
    final reference = zyraErrorReference(error);
    if (_loggedErrorReferences.add(reference)) {
      debugPrint('ZYRA route failed [$reference] (${error.runtimeType}).');
    }
    return ZyraFullScreenError(
      key: ValueKey('route_error_${kind.name}'),
      kind: kind,
      referenceCode: reference,
      onPrimary: kind == ZyraErrorKind.sessionExpired
          ? () => _signInAgain(owner, generation, request)
          : () => _retry(owner, generation, request),
      onSecondary:
          kind == ZyraErrorKind.sessionExpired ||
              kind == ZyraErrorKind.previewAccess
          ? () => _signInAgain(owner, generation, request)
          : () => _returnToWelcome(owner, generation, request),
    );
  }

  /// How long brand purple takes to resolve into the member's own colour.
  ///
  /// Matches the 260ms cross-fade main.dart uses when the gendered
  /// background changes, so the app only ever has one speed for "the
  /// background colour is changing".
  static const _handoff = Duration(milliseconds: 260);

  Widget _loading() {
    final request = _request;
    _splashRetainable = false;
    return ZyraQuietLoading(key: ValueKey('loading_$request'));
  }

  Widget _destination(Widget child) {
    final owner = _routeOwner;
    final generation = _routeGeneration;
    final request = _request;
    return KeyedSubtree(
      key: const ValueKey('resolved'),
      child: _ZyraDestinationPaint(
        onPainted: () {
          if (!_startupCommitted ||
              !_foreground ||
              !_callbackCurrent(owner, generation, request)) {
            return false;
          }
          _destinationPainted = true;
          return true;
        },
        child: child,
      ),
    );
  }

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
          // An interrupted first arrival must not retain an outgoing branded
          // loader/splash under the resumed quiet wait. Once the destination
          // has painted, this key stays stable and preserves its live subtree.
          key: ValueKey(_coldArrivalInterrupted),
          duration: _handoff,
          // Once a wait begins, retire old entries rather than retaining
          // branded artwork behind a transparent destination or zero-length
          // quiet transition. Current entry keys/state are unchanged.
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.center,
            children: [if (_splashRetainable) ...previous, ?current],
          ),
          // A cold arrival that never needed a wait still crossfades.
          transitionBuilder: (child, animation) =>
              child is ZyraQuietLoading || !_splashRetainable
              // A quiet wait can finish before its switcher controller moves
              // past zero. Fading its destination would then expose an older
              // outgoing splash after that quiet entry is removed. Once a
              // wait starts, hand over opaquely; a fast cold arrival that
              // never waited keeps the established splash crossfade.
              ? child
              : FadeTransition(opacity: animation, child: child),
          child: !_animationDone
              ? SplashScreen(
                  key: const ValueKey('splash'),
                  onFinished: () {
                    if (mounted && !_animationDone) {
                      setState(() => _animationDone = true);
                      if (!_splashFinished.isCompleted) {
                        _splashFinished.complete();
                      }
                    }
                  },
                )
              : !_callbackCurrent(_routeOwner, _routeGeneration, _request)
              ? _loading()
              : snapshot.connectionState != ConnectionState.done
              ? _coldArrival &&
                        !_didRetry &&
                        _destinationPrepared &&
                        _splashRetainable
                    ? SplashScreen(
                        key: const ValueKey('splash'),
                        onFinished: () {},
                      )
                    : _loading()
              : snapshot.hasError
              ? _errorScreen(snapshot.error!)
              : snapshot.hasData
              ? _destination(snapshot.data!)
              : _loading(),
        );
      },
    );
  }
}

/// A paint-only marker. It changes subsequent waiting artwork, not the
/// resolver's ownership, routing, authorization or fresh-proof requirements.
class _ZyraDestinationPaint extends SingleChildRenderObjectWidget {
  const _ZyraDestinationPaint({required this.onPainted, required super.child});
  final bool Function() onPainted;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ZyraDestinationPaintRender(onPainted);

  @override
  void updateRenderObject(
    BuildContext context,
    _ZyraDestinationPaintRender renderObject,
  ) => renderObject.report = onPainted;
}

class _ZyraDestinationPaintRender extends RenderProxyBox {
  _ZyraDestinationPaintRender(this.report);
  bool Function() report;
  bool _reported = false;
  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (_reported) return;
    final paintedReport = report;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only this actually painted callback may mark its exact request.
      // Offstage children never paint; outgoing/replaced owners cannot mark
      // the new callback merely because their post-frame work ran later.
      if (attached && identical(paintedReport, report)) {
        _reported = paintedReport();
      }
    });
  }
}
