// ZYRA app shell — entry point.
// Replaces the stock Flutter counter template (resuming ZYRA build,
// 2026-07-18, OA-AIOS-289). Routes: Welcome -> Sign Up/Sign In ->
// Role Selection -> Onboarding -> Transition -> Home (Browse/Matches/Profile).

import 'dart:async' show unawaited;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/zyra_app_variant.dart';
import 'config/zyra_native_identity_policy.dart';
import 'config/zyra_internal_founder_policy.dart';
import 'dev/zyra_dev_control_system.dart' show ZyraDevControlsRouteObserver;
import 'dev/zyra_global_dev_overlay.dart';
import 'dev/zyra_app_gold_preview.dart';
import 'models/zyra_error_state.dart';
import 'screens/auth_gate.dart';
import 'services/zyra_app_lock.dart';
import 'services/zyra_account_state.dart';
import 'services/zyra_internal_preview_client.dart';
import 'services/zyra_image_cache.dart';
import 'services/zyra_local_prefs.dart';
import 'services/zyra_promotion_engine.dart';
import 'services/zyra_reliability_monitor.dart';
import 'services/zyra_release_diagnostics.dart';
import 'state/app_state.dart';
import 'screens/welcome_screen.dart';
import 'theme/zyra_colors.dart';
import 'theme/zyra_app_gold_style.dart';
import 'theme/zyra_interaction_style.dart';
import 'theme/zyra_text.dart';
import 'widgets/zyra_app_lock_gate.dart';
import 'widgets/zyra_full_screen_error.dart';
import 'widgets/zyra_loading.dart';
import 'widgets/zyra_keyboard_dismiss_scope.dart';

/// Global navigator access for controls that sit above the whole app rather
/// than inside any one screen — today that is DevScenarioPanel's Home
/// button (dev_scenario_panel.dart, _goHome), which clears the entire stack
/// without having a BuildContext inside it. (DevNavOverlay, the original
/// holder of this key, was deleted 2026-08-12 — see the note at `builder:`.)
final GlobalKey<NavigatorState> zyraNavigatorKey = GlobalKey<NavigatorState>();
final NavigatorObserver zyraKeyboardDismissNavigatorObserver =
    ZyraKeyboardDismissNavigatorObserver();
final zyraDevControlsRouteObserver = ZyraDevControlsRouteObserver();

void main() async {
  installZyraReleaseDiagnostics();
  WidgetsFlutterBinding.ensureInitialized();
  _installReliabilityHooks();

  // Verify the sole supported artifact identity before any backend connection.
  await _verifyNativeIdentity();

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

  // Open local storage, but do not paint a cached member identity before
  // the restored Auth principal is known. Legacy/unowned caches are not
  // evidence that the next person signing in owns those values.
  await ZyraLocalPrefs.init();
  // OA-101/102: only initialize once lib/config/supabase_config.dart has
  // real project values — until then every screen keeps using the mock
  // in-memory AppState exactly as it did before Supabase existed, so the
  // app is never broken by an unconfigured backend.
  if (_nativeIdentityAccepted && SupabaseConfig.isConfigured) {
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
        httpClient: ZyraInternalPreviewClient.create(),
        // The public application key identifies this project. Supabase Auth
        // still restores and refreshes the member's own session separately.
        publishableKey: SupabaseConfig.publishableKey,
      ).timeout(const Duration(seconds: 10));
      _supabaseReady = true;
    } catch (e, stack) {
      _startupError = e;
      ZyraReliabilityMonitor.instance.record(
        area: ZyraReliabilityArea.startup,
        fingerprint: ZyraReliabilityFingerprint.backendStartup,
      );
      // Deliberately logged, not swallowed (the codebase's 64 silent
      // `catch (_)` blocks are exactly why launch failures have been
      // invisible until now — see the engineering audit, ES-08).
      debugPrint(
        'ZYRA: Supabase.initialize failed — starting in offline mode.\n$e\n$stack',
      );
    }
  }

  // Account ownership is resolved before the first Flutter frame and before
  // any profile/preview can load. A failed initialization gets neutral state,
  // never whichever person's presentation happened to remain on this phone.
  await _restoreAccountPresentation();

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

void _installReliabilityHooks() {
  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    ZyraReliabilityMonitor.instance.record(
      area: ZyraReliabilityArea.interface,
      fingerprint: ZyraReliabilityFingerprint.flutterFramework,
    );
    if (!kReleaseMode) {
      (previousFlutterHandler ?? FlutterError.presentError)(details);
    }
  };

  final previousPlatformHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    ZyraReliabilityMonitor.instance.record(
      area: ZyraReliabilityArea.platform,
      fingerprint: ZyraReliabilityFingerprint.unhandledPlatform,
    );
    // Returning false asks the platform to dump the raw exception/stack.
    // The fixed-category incident above is the release-safe evidence.
    if (kReleaseMode) return true;
    return previousPlatformHandler?.call(error, stack) ?? false;
  };
}

/// Whether Supabase.initialize() actually completed. `SupabaseConfig
/// .isConfigured` only says the URL/key are filled in — it does NOT mean
/// the client exists. Anything that touches `Supabase.instance` must gate
/// on THIS, because Supabase.instance throws when initialize() was skipped
/// or failed.
bool _supabaseReady = false;
Object? _startupError;
bool _nativeIdentityAccepted = true;
bool get supabaseReady => _supabaseReady;

Future<void> _restoreAccountPresentation() async {
  // Auth recovery can replace a session before the widget-level listener is
  // mounted. Check the actual principal as well as our local generation.
  while (true) {
    final owner = supabaseReady ? supabase.auth.currentUser?.id : null;
    await ZyraAccountState.synchronize(owner);
    final generation = ZyraAccountState.generation;
    bool stillCurrent() =>
        ZyraAccountState.userId == owner &&
        ZyraAccountState.generation == generation &&
        (supabaseReady ? supabase.auth.currentUser?.id : null) == owner;
    await ZyraImageCache.init();
    if (!stillCurrent()) continue;
    ZyraColors.restoreCurrentAppPalette();
    // Member font choices are retired: ordinary app text stays Poppins.
    // Discard any account-bound legacy choice instead of reviving it later.
    ZyraText.restoreAppFont(null);
    if (ZyraLocalPrefs.cachedAppFontName != null) {
      await ZyraLocalPrefs.setCachedAppFontName(null);
    }
    ZyraInteractionStyle.restoreHapticLevel(
      ZyraLocalPrefs.cachedHapticLevelName,
    );
    ZyraAppGoldStyle.instance.restoreCurrent();
    ZyraColors.restoreAppSurfaceStyle(ZyraLocalPrefs.cachedAppSurfaceStyleName);
    await ZyraPromotionEngine.instance.initialize();
    if (!stillCurrent()) continue;
    AppState.instance.gender = ZyraLocalPrefs.cachedGender;
    AppState.instance.name = ZyraLocalPrefs.cachedFirstName;
    // Restore the matching owner's lock before mounting protected content.
    ZyraAppLock.instance.hydrate();
    return;
  }
}

Future<void> _verifyNativeIdentity() async {
  _nativeIdentityAccepted =
      ZyraAppVariantPolicy.current == ZyraAppVariant.production;
  if (!_nativeIdentityAccepted ||
      kIsWeb ||
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  _nativeIdentityAccepted = false;
  try {
    final info = await PackageInfo.fromPlatform();
    _nativeIdentityAccepted = ZyraNativeIdentityPolicy.matches(
      variant: ZyraAppVariantPolicy.current,
      bundleId: info.packageName,
      displayName: info.appName,
    );
  } catch (error, stack) {
    ZyraReliabilityMonitor.instance.record(
      area: ZyraReliabilityArea.startup,
      fingerprint: ZyraReliabilityFingerprint.nativeIdentity,
    );
    debugPrint(
      'ZYRA: native app identity could not be verified.\n$error\n$stack',
    );
  }

  if (!_nativeIdentityAccepted) {
    debugPrint(
      'ZYRA: native app identity and compiled flavor do not match; '
      'backend initialization is blocked.',
    );
  }
}

/// Convenience accessor used once real auth/data calls are wired in
/// (post-OA-102) — `SupabaseConfig.isConfigured` must be checked before
/// use, since `Supabase.instance` throws if initialize() was skipped.
SupabaseClient get supabase => Supabase.instance.client;

class ZyraApp extends StatelessWidget {
  const ZyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Developer Style compares reading faces, backgrounds, accents and shared
    // navigation treatments live. Rebuilding MaterialApp refreshes every
    // mounted route immediately; navigator state is retained, the Syne
    // wordmark stays locked, and every comparison resets to the current
    // Midnight Plum + Poppins + Floating Glass defaults on relaunch. The
    // separate App Surface selection is restored before runApp and therefore
    // persists across relaunches until the signed-in user resets or signs out.
    return ListenableBuilder(
      listenable: Listenable.merge([
        ZyraText.appFontSelection,
        ZyraColors.devPaletteSelection,
        ZyraColors.appSurfaceStyleSelection,
        ZyraInteractionStyle.navStyleSelection,
      ]),
      builder: (context, _) => MaterialApp(
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
        navigatorObservers: [
          zyraKeyboardDismissNavigatorObserver,
          if (ZyraInternalFounderPolicy.enabled) zyraDevControlsRouteObserver,
        ],
        theme: ThemeData(
          brightness: ZyraColors.isLightPalette
              ? Brightness.light
              : Brightness.dark,
          textTheme: ZyraText.textTheme(
            ZyraColors.isLightPalette
                ? ThemeData.light().textTheme
                : ThemeData.dark().textTheme,
          ),
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
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            foregroundColor: ZyraColors.foreground,
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
          colorScheme: ColorScheme.fromSeed(
            brightness: ZyraColors.isLightPalette
                ? Brightness.light
                : Brightness.dark,
            seedColor: ZyraColors.royalPurple,
            primary: ZyraColors.actionFill,
            onPrimary: ZyraColors.onAction,
            secondary: ZyraColors.actionFill,
            onSecondary: ZyraColors.onAction,
            surface: ZyraColors.isLightPalette
                ? const Color(0xFFFDFBFD)
                : ZyraColors.luxuryDarkPurple,
            onSurface: ZyraColors.foreground,
            error: ZyraColors.destructive,
            onError: ZyraColors.luxuryDarkPurple,
          ),
          bottomSheetTheme: BottomSheetThemeData(
            backgroundColor: ZyraColors.modalSheetSurface,
            modalBackgroundColor: ZyraColors.modalSheetSurface,
            surfaceTintColor: Colors.transparent,
          ),
          // APP-WIDE PRIMARY ACTION MODERNISATION — Founder, 2026-08-29.
          //
          // Raw FilledButtons were still inheriting the earlier solid
          // lavender Material treatment on otherwise modern glass screens.
          // Keep ordinary actions neutral and glass-led; premium actions use
          // ZyraGoldActionPill instead, so gold never leaks into Continue,
          // Save, consent or safety decisions. Call-site semantic colours
          // (for example destructive red) continue to override the fill while
          // inheriting this shared geometry and minimum target size.
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              foregroundColor: ZyraColors.foreground,
              backgroundColor: ZyraColors.surfaceEmphasisFill,
              disabledForegroundColor: ZyraColors.ink(0.38),
              disabledBackgroundColor: ZyraColors.surfaceFill,
              side: BorderSide(
                color: ZyraColors.surfaceEmphasisBorder,
                width: 1,
              ),
              shape: const StadiumBorder(),
            ),
          ),
          // With colorScheme.primary now lavender, unstyled TextButtons and
          // OutlinedButtons would tint their labels lavender too. Their
          // labels have always read as white in this app (ZyraText.button's
          // old hardcoded default), so pin that at the theme level — call
          // sites passing explicit colours (End Journey coral, subtext
          // greys) are unaffected.
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: ZyraColors.foreground),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: ZyraColors.foreground,
            ),
          ),
          iconTheme: IconThemeData(color: ZyraColors.foreground),
          dividerColor: ZyraColors.isLightPalette
              ? const Color(0x243D2A4A)
              : const Color(0x24FFFFFF),
          // ADDED 2026-08-01 (Founder: "it shows a white tab at bottom
          // again doesn't match app system"). No snackBarTheme was ever
          // set, so all 14 SnackBars in the app fell back to Material's
          // default — a light surface with dark text, dropped onto a dark
          // purple app. Setting it here fixes every one of them at once
          // rather than per call site, and any future SnackBar inherits it.
          snackBarTheme: SnackBarThemeData(
            backgroundColor: ZyraColors.toastSurface,
            contentTextStyle: ZyraText.body(
              size: 13.5,
              color: ZyraColors.foreground,
            ),
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
        builder: (context, child) => ZyraKeyboardDismissScope(
          child: ZyraAppLockGate(
            child: ZyraAppGoldPreviewHost(
              child: ListenableBuilder(
                listenable: AppState.instance,
                builder: (context, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  decoration: ZyraAppGoldDecoration(
                    gradient: ZyraColors.genderGradient(
                      AppState.instance.gender,
                    ),
                  ),
                  child: ZyraGlobalDevOverlayHost(
                    navigatorKey: zyraNavigatorKey,
                    routeObserver: ZyraInternalFounderPolicy.enabled
                        ? zyraDevControlsRouteObserver
                        : null,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
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
      ),
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
    if (_retrying || !_nativeIdentityAccepted || !SupabaseConfig.isConfigured) {
      return;
    }
    setState(() {
      _retrying = true;
      _showWelcome = false;
    });
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        httpClient: ZyraInternalPreviewClient.create(),
        publishableKey: SupabaseConfig.publishableKey,
      ).timeout(const Duration(seconds: 10));
      _supabaseReady = true;
      await _restoreAccountPresentation();
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
    if (!_nativeIdentityAccepted) {
      return const _NativeIdentityBlocked();
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

/// An unsupported flavor or native identity is a terminal artifact defect.
class _NativeIdentityBlocked extends StatelessWidget {
  const _NativeIdentityBlocked();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 34,
                  color: ZyraColors.foreground,
                ),
                const SizedBox(height: 18),
                Text(
                  'This ZYRA build is locked',
                  textAlign: TextAlign.center,
                  style: ZyraText.heading(size: 25),
                ),
                const SizedBox(height: 10),
                Text(
                  'Its installed app identity does not match its approved '
                  'environment. No connection was attempted.',
                  textAlign: TextAlign.center,
                  style: ZyraText.body(size: 14, color: ZyraColors.ink(0.72)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
