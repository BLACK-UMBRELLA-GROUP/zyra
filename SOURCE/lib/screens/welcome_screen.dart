// Welcome Screen — entry point to ZYRA.
// Spec: APP/Authentication/Script/Script_V1.md §WELCOME SCREEN.
//
// Rework (2026-07-18, Founder instruction): Google + Apple sign-in
// ONLY — no password, no email login, no phone login, no magic link.
// Sign-up and sign-in collapse into the same action with OAuth (a
// first-time Google/Apple sign-in has no `profiles` row yet, so
// ZyraSessionRouter routes it to Role Selection exactly like resuming
// an interrupted onboarding), so the old "Begin Your Journey" / "I
// Already Have An Account" fork — and the SignUpScreen/SignInScreen/
// EmailAuthScreen chain behind it — no longer has a reason to exist.
// Every button still performs a real navigation/auth action, per this
// screen's own governing rule.

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_session_router.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_state_widgets.dart';
import 'dev/developer_access_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _continueWithGoogle() => _continueWith(ZyraAuth.signInWithGoogle);
  Future<void> _continueWithApple() => _continueWith(ZyraAuth.signInWithApple);

  Future<void> _continueWith(Future<ZyraAuthResult> Function() signIn) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await signIn();
    if (!mounted) return;

    switch (result.outcome) {
      case ZyraAuthOutcome.cancelled:
        setState(() => _loading = false);
        return;
      case ZyraAuthOutcome.error:
        setState(() {
          _loading = false;
          _error = result.errorMessage;
        });
        return;
      case ZyraAuthOutcome.success:
        final home = await ZyraSessionRouter.resolveHome();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => home),
          (route) => false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // OA-ZYRA-122 §3: platform-native sign-in priority — the button
    // matching the user's own device is primary (larger, filled) and
    // leads; the other provider is secondary (smaller, outline) and
    // follows. defaultTargetPlatform rather than dart:io Platform, since
    // it's the Flutter-idiomatic way to branch UI on platform and works
    // the same whether or not the app ever runs on web.
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final googleButton = _OAuthButton(
      icon: Icons.g_mobiledata,
      label: 'Continue with Google',
      primary: !isIOS,
      loading: _loading,
      onTap: _loading ? null : _continueWithGoogle,
    );
    final appleButton = _OAuthButton(
      icon: Icons.apple,
      label: 'Continue with Apple',
      primary: isIOS,
      loading: _loading,
      onTap: _loading ? null : _continueWithApple,
    );
    final orderedButtons = isIOS ? [appleButton, googleButton] : [googleButton, appleButton];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                // OA-ZYRA-122 §2: tightened from flex 3/4 — the welcome
                // screen felt too open with excessive empty vertical
                // space; logo/slogan/buttons now sit closer together.
                const Spacer(flex: 2),
                Text('ZYRA', style: ZyraText.wordmark(size: 52)),
                const SizedBox(height: 8),
                Text(
                  // Approved tagline — BUSINESS/BRAND MESSAGING/Summary.md
                  'Connecting Through Trust',
                  style: ZyraText.subtext(),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                if (_error != null) ...[
                  ZyraErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
                  const SizedBox(height: 14),
                ],
                orderedButtons[0],
                const SizedBox(height: 14),
                orderedButtons[1],
                const SizedBox(height: 22),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DeveloperAccessScreen()),
                  ),
                  child: Text('Developer Access', style: ZyraText.subtext(size: 11, color: Colors.white38)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  // OA-ZYRA-122 §3: renamed from `filled` — this is now driven by
  // platform-native priority (which provider matches the user's device),
  // not a fixed per-provider style. Primary = larger + filled + full
  // opacity; secondary = smaller + outline + slightly dimmer.
  final bool primary;
  final bool loading;
  final VoidCallback? onTap;

  const _OAuthButton({required this.icon, required this.label, required this.primary, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = primary ? Colors.white : Colors.white.withOpacity(0.85);
    return SizedBox(
      width: double.infinity,
      height: primary ? 54 : 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: primary ? ZyraColors.accentBg : Colors.transparent,
          border: Border.all(color: primary ? ZyraColors.accentBorder : Colors.white24, width: 1),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onTap,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: primary ? 20 : 17,
                      height: primary ? 20 : 17,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: textColor, size: primary ? 20 : 17),
                        const SizedBox(width: 10),
                        Text(label, style: ZyraText.button(size: primary ? 15 : 13.5, color: textColor)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
