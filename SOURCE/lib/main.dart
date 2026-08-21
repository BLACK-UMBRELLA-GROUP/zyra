// ZYRA app shell — entry point.
// Replaces the stock Flutter counter template (resuming ZYRA build,
// 2026-07-18, OA-AIOS-289). Routes: Welcome -> Sign Up/Sign In ->
// Role Selection -> Onboarding -> Transition -> Home (Browse/Matches/Profile).

import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'models/zyra_error_state.dart';
import 'screens/auth_gate.dart';
import 'services/zyra_app_lock.dart';
import 'services/zyra_image_cache.dart';
import 'services/zyra_local_prefs.dart';
import 'state/app_state.dart';
import 'screens/welcome_screen.dart';
import 'theme/zyra_colors.dart';
import 'theme/zyra_text.dart';
import 'widgets/zyra_app_lock_gate.dart';
import 'widgets/zyra_full_screen_error.dart';
import 'widgets/zyra_loading.dart';

/// Global navigator access for controls that sit above the whole app rather
/// than inside any one screen — today that is DevScenarioPanel's Home
/// button (dev_scenario_panel.dart, _goHome), which clears the entire stack
/// without having a BuildContext inside it. (DevNavOverlay, the original
/// holder of this key, was deleted 2026-08-12 — see the note at `builder:`.)
final GlobalKey<NavigatorState> zyraNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // PORTRAIT ONLY — DR-ZYRA-188 (Founder: "lock to portrait"). Every
  // screen is portrait-composed — the full-bleed Browse photos, the
  // swipe thresholds, the Journey veil and ribbon — and rotating them
  // into an undesigned landscape reads as a bug. The category agrees:
  // matrimonial/dating apps ship portrait-locked. If an iPad build
  // ever exists, landscape becomes ITS decision, not a free rotate.
  // unawaited: the lock applies asynchronously; nothing after this
  // depends on it, and holding the splash for it buys nothing.
  unawaited(
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  );

  // FIRST, and before Supabase — local disk, single-digit milliseconds.
  // This is what lets frame one paint the right gradient (Founder: "I
  // don't want to see that quick colour change at all"). Deliberately
  // ahead of Supabase.initialize, which can take up to its 10s timeout;
  // the whole point is not to wait on the network to know a colour.
  await ZyraLocalPrefs.init();
  AppState.instance.gender = ZyraLocalPrefs.cachedGender;
  // Same first-frame contract as the gender (DR-ZYRA-169 Phase 2): the
  // Profile tab greets by name immediately instead of "Your Profile"
  // until hydration lands. hydrateFrom() overwrites with the server's
  // answer moments later — cache paints, server decides.
  AppState.instance.name = ZyraLocalPrefs.cachedFirstName;
  // Image-cache schema check (DR-ZYRA-169 Phase 1) — deliberately NOT
  // awaited: a wipe after an app update can take a beat, and frame one
  // must never wait on cache housekeeping.
  unawaited(ZyraImageCache.init());
  // Same reasoning, same frame. If the app lock is on, the lock screen has
  // to be the FIRST thing painted — reading this any later would show the
  // app for a moment first, which is precisely what it exists to prevent.
  ZyraAppLock.instance.hydrate();
  // OA-101/102: only initialize once lib/config/supabase_config.dart has
  // real project values — until then every screen keeps using the mock
  // in-memory AppState exactly as it did before Supabase existed, so the
  // app is never broken by an unconfigured backend.
  if (SupabaseConfig.isConfigured) {
    // HARDENED 2026-08-01 — this was a bare `await` with no try/catch, and
    // it is the ONLY blocking call before runApp(). If it threw for any
    // reason (no network on a cold launch, DNS failure, a stored session
    // that can't be refreshed, a platform-channel/storage error), main()
    // threw with it, runApp() was never reached, and the app died on the
    // splash screen — i.e. "the app won't open", with no visible error.
    //
    // Failing to reach Supabase is a DEGRADED state, not a fatal one. The
    // whole app already tolerates it: AuthGate falls back to Welcome, and
    // every service guards on ZyraAuth.currentUser being null. So catch,
    // record it, and start anyway.
    //
    // The timeout matters as much as the catch — initialize() attempts
    // session recovery over the network, and a hang holds the splash
    // screen forever, which the user experiences identically to a crash.
    //
    // KNOWN, ACCEPTED BEHAVIOUR (raised by Fable on review, 2026-08-01):
    // .timeout() does NOT cancel the underlying call. If initialize()
    // eventually completes at, say, second 11, the Supabase client will
    // exist but `supabaseReady` stays false, so that session runs in
    // offline mode until the app is relaunched. That is the correct
    // trade — a slow-but-alive backend degrading to Welcome is strictly
    // better than an indefinite splash — but it is deliberate, not an
    // oversight, so don't "fix" it by removing the timeout.
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // `publishableKey` is the successor, but switching is an auth-boot
        // behaviour change (new sb_publishable_ key format), not a rename.
        // Migrate deliberately with a device test, not as lint cleanup.
        // Tracked for Opus.
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      ).timeout(const Duration(seconds: 10));
      _supabaseReady = true;
    } catch (e, stack) {
      _startupError = e;
      // Deliberately logged, not swallowed (the codebase's 64 silent
      // `catch (_)` blocks are exactly why launch failures have been
      // invisible until now — see the engineering audit, ES-08).
      debugPrint(
        'ZYRA: Supabase.initialize failed — starting in offline mode.\n$e\n$stack',
      );
    }
  }

  // A broken widget must never become Flutter's red diagnostics screen for
  // a member. Debug/profile builds keep the diagnostics because hiding them
  // would make device testing weaker; release gets the approved calm page.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) {
      final reference = zyraErrorReference(details.exception);
      debugPrint(
        'ZYRA page build failed [$reference]\n'
        '${details.exception}\n${details.stack}',
      );
      return ZyraFullScreenError(
        kind: ZyraErrorKind.page,
        referenceCode: reference,
        onPrimary: () => _restartAfterFatalError(playSplash: false),
        onSecondary: () => _restartAfterFatalError(playSplash: true),
      );
    };
  }
  runApp(const ZyraApp());
}

/// Whether Supabase.initialize() actually completed. `SupabaseConfig
/// .isConfigured` only says the URL/key are filled in — it does NOT mean
/// the client exists. Anything that touches `Supabase.instance` must gate
/// on THIS, because Supabase.instance throws when initialize() was skipped
/// or failed.
bool _supabaseReady = false;
Object? _startupError;
bool get supabaseReady => _supabaseReady;

/// Convenience accessor used once real auth/data calls are wired in
/// (post-OA-102) — `SupabaseConfig.isConfigured` must be checked before
/// use, since `Supabase.instance` throws if initialize() was skipped.
SupabaseClient get supabase => Supabase.instance.client;

class ZyraApp extends StatelessWidget {
  const ZyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZYRA',
      debugShowCheckedModeBanner: false,
      // ADDED 2026-08-07 (Founder, asked four times: "the lines at top and
      // bottom… I need it to be seamless").
      //
      // Measuring the screenshot's pixels settled it: the still image has NO
      // hard edge anywhere — the gradient runs smooth top to bottom. So the
      // line only exists WHILE SCROLLING, which is why removing the refresh
      // indicator, the Material 3 app-bar tint and the duplicate gradient
      // each fixed something real and none of them fixed this.
      //
      // It is the overscroll indicator. Flutter paints it on its own opaque
      // surface at whichever edge you push against — top when you pull down,
      // bottom when you pull up — and over a gradient that reads as a hard
      // rule appearing and vanishing. A still frame captures it only if the
      // shutter happens to fall mid-gesture.
      //
      // Set HERE rather than per screen. It was fixed on the Guardian detail
      // page alone last time, which is why it kept appearing everywhere else.
      // One behaviour, every scrollable, including screens not yet written.
      scrollBehavior: const _ZyraScrollBehavior(),
      navigatorKey: zyraNavigatorKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        // ADDED 2026-08-06 (Founder: "when I scroll down then back up it
        // creates that pink line at top, remove that so it's all seamless").
        //
        // Material 3 tints an AppBar with `surfaceTint` the moment content
        // scrolls underneath it. Fourteen screens here set
        // `extendBodyBehindAppBar: true` over a gradient, so that tint
        // lands as a hard-edged pale strip across the top — and only after
        // scrolling, which is what makes it read as a glitch rather than as
        // a background.
        //
        // Fixed once here rather than on each screen: every one of those
        // fourteen has the same problem, and the next screen built this way
        // would have inherited it too.
        //
        // BOTH are required. Zeroing the elevation alone leaves the tint
        // colour applied, and setting the colour alone leaves the shadow.
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
        ),
        // 2026-07-25, DR-ZYRA-101 audit item 1 (Founder decision:
        // "switch to gradient"): scaffoldBackgroundColor only accepts a
        // solid Color, so it can't hold DR-ZYRA-094's gradient directly
        // — the gradient default is now applied one level up, in
        // `builder:` below, wrapping every screen. This Color is kept
        // only as the Scaffold-internal fallback for the rare instant
        // before that wrapper paints.
        //
        // 2026-08-01: now follows the CACHED gender too. It was hardcoded
        // to Royal Purple, which matched the neutral gradient's top stop
        // and mismatched the female one — a second, smaller flash hiding
        // behind the first.
        // TRANSPARENT — 2026-08-13 (DR-ZYRA-165, closing OA-ZYRA-212).
        //
        // This read the gender ONCE, when ZyraApp.build ran, from the
        // value main() had just loaded out of the disk cache — the
        // PREVIOUS session's gender. ZyraApp is a StatelessWidget, so
        // nothing rebuilt the ThemeData afterwards. The live gradient in
        // `builder:` below tracks gender through a ListenableBuilder;
        // this did not. After any sign-in or Developer Access switch the
        // two disagreed for the rest of the process.
        //
        // THAT IS THE MALE-SEEKER ASYMMETRY THE FOUNDER REPORTED. Launch
        // with a female account cached, switch to a male one, and every
        // gap where a Scaffold shows through paints Rose Pink behind
        // Royal Blue chrome. Test female-on-female and it is pink on
        // pink — invisible. The bug was never male-specific; it was
        // switch-specific, and the female baseline is where it hides.
        //
        // Transparent rather than "rebuild the theme on change", which
        // is the other half of OA-ZYRA-212's target. The `builder:`
        // wrapper below paints the live gender gradient behind EVERY
        // route, so there is a correct colour there already and a second
        // copy of it in the theme can only ever be a copy that goes
        // stale. This removes the class of bug rather than keeping two
        // values in step.
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
        // ADDED 2026-08-11 (Founder, screenshot review: "some buttons are
        // one colour and some are another… now the continue journey button
        // is blue. so why are some blue and some transparent. I want a
        // clean UI"; Frost UI brief).
        //
        // No ColorScheme was ever set, so every colour role fell back to
        // Material 3's STOCK dark baseline — which is where the "blue"
        // came from: FilledButtons painted the stock primary #D0BCFF
        // periwinkle (with, at most call sites, a hardcoded white label at
        // ~2:1 contrast on it), and chips/menus painted the stock
        // near-black surface, which is why the phase-reveal rating chips
        // and the Journey 3-dot menu sat on the gradient like black holes.
        // None of those colours were ZYRA decisions; they were defaults.
        //
        // Set HERE once, same reasoning as appBarTheme/snackBarTheme
        // above: every current and future button inherits it, instead of
        // each call site restating (and mis-stating) the brand.
        //
        //   primary/onPrimary    Pastel Grey Lavender with Luxury Dark
        //                        Purple text (5.8:1 — see zyra_colors.dart
        //                        for why never white-on-lavender)
        //   surface              Luxury Dark Purple — the ratified sheet/
        //                        dialog base (zyra_colors.dart 2026-08-01
        //                        block), so anything Material paints on
        //                        "surface" lands in the brand family
        //                        rather than stock near-black
        //   error                the End Journey coral, tokenised
        colorScheme: ColorScheme.dark(
          primary: ZyraColors.primaryAction,
          onPrimary: ZyraColors.onPrimaryAction,
          secondary: ZyraColors.primaryAction,
          onSecondary: ZyraColors.onPrimaryAction,
          surface: ZyraColors.luxuryDarkPurple,
          error: ZyraColors.destructive,
          onError: ZyraColors.luxuryDarkPurple,
        ),
        // With colorScheme.primary now lavender, unstyled TextButtons and
        // OutlinedButtons would tint their labels lavender too. Their
        // labels have always read as white in this app (ZyraText.button's
        // old hardcoded default), so pin that at the theme level — call
        // sites passing explicit colours (End Journey coral, subtext
        // greys) are unaffected.
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
        ),
        // ADDED 2026-08-01 (Founder: "it shows a white tab at bottom
        // again doesn't match app system"). No snackBarTheme was ever
        // set, so all 14 SnackBars in the app fell back to Material's
        // default — a light surface with dark text, dropped onto a dark
        // purple app. Setting it here fixes every one of them at once
        // rather than per call site, and any future SnackBar inherits it.
        snackBarTheme: SnackBarThemeData(
          backgroundColor: ZyraColors.toastSurface,
          contentTextStyle: ZyraText.body(size: 13.5, color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          elevation: 0,
        ),
        // Edge-swipe-to-go-back on iOS (Founder request, 2026-07-19): no
        // custom pageTransitionsTheme needed here — Flutter's own default
        // already maps TargetPlatform.iOS to a Cupertino-style page
        // transition with the standard left-edge swipe-back gesture
        // built in. (An earlier attempt to make this explicit via a
        // custom PageTransitionsTheme hit a real build-time error on
        // this project's Flutter SDK — CupertinoPageTransitionsBuilder
        // wasn't resolving — so removed rather than fight a toolchain
        // issue for behaviour that was already correct by default.)
        // Only works on screens reached via a normal push — screens
        // reached via pushReplacement/pushAndRemoveUntil (onboarding
        // steps, the post-sign-in transition) are intentionally
        // forward-only and won't have this gesture, matching how iOS
        // itself behaves in similar forward-only flows.
      ),
      // DevNavOverlay DELETED 2026-08-12 (dev-panel redesign, drift pass).
      // It began 2026-07-19 as floating Back/Home buttons wrapped here via
      // `builder:`; the buttons moved into DevScenarioPanel on 2026-08-03
      // and the wrapper had passed its child through untouched ever since —
      // kept only as "the natural place for the next always-on debug
      // affordance", which five weeks did not produce. If one is ever
      // needed, wrap it here exactly as the old file did.
      // 2026-07-25, DR-ZYRA-101 audit item 1: app-wide gradient default,
      // wrapping every screen below the ThemeData Color fallback above.
      // Neutral brandGradient, not gender-matched — this layer is
      // reached before auth/gender is known (Welcome, Role Selection)
      // as well as after, so it must stay the same regardless of who's
      // signed in (a gendered default here would risk showing a stale
      // colour after sign-out, same reasoning as ZyraColors.
      // genderGradient()'s doc comment). Individual profile-context
      // screens already layer their own gender-matched gradient on top
      // via their own Container/Scaffold body, so this is genuinely
      // just the base layer, not a competing source of truth.
      // 2026-08-01: gender-matched from the cache when there is one.
      //
      // The note above says a gendered default here "would risk showing a
      // stale colour after sign-out". That risk is real and is handled at
      // the source instead — ZyraLocalPrefs.clear() runs on sign-out, so
      // after signing out the cache is empty and genderGradient(null)
      // returns exactly the neutral gradient this used to hardcode.
      // Nothing is stale because nothing is kept.
      // ListenableBuilder + AnimatedContainer — 2026-08-05 (Fable),
      // completing the local-cache fix above.
      //
      // Two gaps remained. (1) ZyraApp is a StatelessWidget, so this layer
      // read AppState.gender exactly once and never again: on a FIRST-ever
      // sign-in, where nothing is cached to disk yet, the background stayed
      // neutral until some unrelated rebuild happened to repaint it.
      // Listening fixes that. (2) When it does change — first sign-in, or
      // switching accounts in Developer Access — a hard swap is the visible
      // "flash" being complained about, so the change is now a 260ms
      // cross-fade. BoxDecoration lerps gradients natively.
      //
      // 2026-08-07 — ZyraAppLockGate is the OUTERMOST wrapper here, above
      // even the gradient. Two reasons, both deliberate:
      //
      //   1. Nothing beneath it is built while the app is locked, so there
      //      is no half-painted screen behind the lock and nothing to leak
      //      through a transparent edge.
      //   2. The gradient below is GENDER-MATCHED, and the lock screen is
      //      seen by whoever is holding the phone. Painting pink or blue
      //      behind a lock would disclose whose account it is before anyone
      //      authenticated — a small thing that defeats a real part of the
      //      point.
      builder: (context, child) => ZyraAppLockGate(
        child: ListenableBuilder(
          listenable: AppState.instance,
          builder: (context, _) => AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: ZyraColors.genderGradient(AppState.instance.gender),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      // AuthGate calls into Supabase.instance, which throws if
      // initialize() was skipped — only safe to use once configured.
      //
      // 2026-08-01: gate on `supabaseReady`, not `isConfigured`. Those are
      // not the same thing — isConfigured only means the URL and key are
      // present in the config file, which was still true when initialize()
      // had just failed. AuthGate would then call Supabase.instance and
      // throw inside build(), turning a recoverable backend outage into a
      // dead app. The startup gate now presents the approved retryable
      // connection/service page and keeps Welcome as its safe exit.
      home: const _ZyraStartupGate(),
    );
  }
}

void _restartAfterFatalError({required bool playSplash}) {
  final navigator = zyraNavigatorKey.currentState;
  if (navigator == null) return;
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => supabaseReady
          ? AuthGate(playSplash: playSplash)
          : const _ZyraStartupGate(),
    ),
    (route) => false,
  );
}

/// Owns the only retryable failure that occurs before normal routing exists.
/// No navigation or Journey state is cleared: once Supabase is available,
/// AuthGate reads the same persisted session and resumes normally.
class _ZyraStartupGate extends StatefulWidget {
  const _ZyraStartupGate();

  @override
  State<_ZyraStartupGate> createState() => _ZyraStartupGateState();
}

class _ZyraStartupGateState extends State<_ZyraStartupGate> {
  bool _retrying = false;
  bool _showWelcome = false;

  Future<void> _retry() async {
    if (_retrying || !SupabaseConfig.isConfigured) return;
    setState(() {
      _retrying = true;
      _showWelcome = false;
    });
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      ).timeout(const Duration(seconds: 10));
      _supabaseReady = true;
      _startupError = null;
    } catch (error, stack) {
      _startupError = error;
      debugPrint('ZYRA startup retry failed.\n$error\n$stack');
    }
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_retrying) {
      return const ZyraLoading.fullScreen(label: 'Trying again…');
    }
    if (supabaseReady) return const AuthGate();
    final error = _startupError;
    if (!_showWelcome && SupabaseConfig.isConfigured && error != null) {
      return ZyraFullScreenError(
        kind: zyraErrorKindFor(error),
        referenceCode: zyraErrorReference(error),
        onPrimary: _retry,
        onSecondary: () => setState(() => _showWelcome = true),
      );
    }
    return const WelcomeScreen();
  }
}

/// No overscroll indicator, anywhere.
///
/// Bouncing physics on every platform, so the page still gives when pulled —
/// the give is the feedback, and the painted glow was only ever a second,
/// uglier way of saying the same thing.
class _ZyraScrollBehavior extends MaterialScrollBehavior {
  const _ZyraScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
