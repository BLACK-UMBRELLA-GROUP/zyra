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
import '../theme/zyra_colors.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Widget> _resolved = _resolve();

  Future<Widget> _resolve() async {
    if (!ZyraAuth.isSignedIn) return const WelcomeScreen();
    return ZyraSessionRouter.resolveHome();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolved,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // 2026-07-25, DR-ZYRA-101 audit item 1 (Founder decision:
          // "switch to gradient"): neutral brandGradient, not gender-
          // matched — at this exact moment we're still resolving
          // whether there's a session at all, so gender may not be
          // loaded into AppState yet. Same reasoning as main.dart's
          // app-wide default. Spinner stays white (2026-07-19,
          // DR-ZYRA-090) for contrast against either the old flat
          // Royal Purple or this gradient's lighter top stop.
          return DecoratedBox(
            decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
            child: const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
