// ZYRA app shell — entry point.
// Replaces the stock Flutter counter template (resuming ZYRA build,
// 2026-07-18, OA-AIOS-289). Routes: Welcome -> Sign Up/Sign In ->
// Role Selection -> Onboarding -> Transition -> Home (Browse/Matches/Profile).

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth_gate.dart';
import 'screens/welcome_screen.dart';
import 'theme/zyra_colors.dart';
import 'widgets/dev_nav_overlay.dart';

/// Global navigator access for DevNavOverlay's Back/Home buttons — lets
/// them pop routes without needing a BuildContext from wherever they're
/// drawn (they sit above the whole app, not inside any one screen).
final GlobalKey<NavigatorState> zyraNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // OA-101/102: only initialize once lib/config/supabase_config.dart has
  // real project values — until then every screen keeps using the mock
  // in-memory AppState exactly as it did before Supabase existed, so the
  // app is never broken by an unconfigured backend.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
  runApp(const ZyraApp());
}

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
      navigatorKey: zyraNavigatorKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        // 2026-07-25, DR-ZYRA-101 audit item 1 (Founder decision:
        // "switch to gradient"): scaffoldBackgroundColor only accepts a
        // solid Color, so it can't hold DR-ZYRA-094's gradient directly
        // — the gradient default is now applied one level up, in
        // `builder:` below, wrapping every screen. This Color is kept
        // only as the Scaffold-internal fallback for the rare instant
        // before that wrapper paints; it matches the gradient's top
        // stop (Royal Purple) so there's no visible seam.
        scaffoldBackgroundColor: ZyraColors.royalPurple,
        useMaterial3: true,
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
      // Founder testing aid (2026-07-19) — floating Back/Home buttons,
      // debug-only (see dev_nav_overlay.dart). Wrapping here via
      // `builder:` means it sits above every screen regardless of the
      // navigation stack depth, without needing to touch any individual
      // screen.
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
      builder: (context, child) => Container(
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: DevNavOverlay(
          navigatorKey: zyraNavigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      // AuthGate calls into Supabase.instance, which throws if
      // initialize() was skipped — only safe to use once configured.
      home: SupabaseConfig.isConfigured ? const AuthGate() : const WelcomeScreen(),
    );
  }
}
