// Welcome Screen — entry point to ZYRA.
// Spec: APP/Authentication/Script/Script_V1.md §WELCOME SCREEN.
//
// Rework (2026-07-18, Founder instruction): Google + Apple sign-in as the
// normal entry methods — no ZYRA password and no open email sign-up.
// Founder decision 2026-08-20 adds passwordless recovery for an email that
// was verified from inside an existing Apple/Google account. It is recovery,
// not sign-up: shouldCreateUser=false prevents duplicate profiles.
// Sign-up and sign-in collapse into the same action with OAuth (a
// first-time Google/Apple sign-in has no `profiles` row yet, so
// ZyraSessionRouter routes it to Role Selection exactly like resuming
// an interrupted onboarding), so the old "Begin Your Journey" / "I
// Already Have An Account" fork — and the SignUpScreen/SignInScreen/
// EmailAuthScreen chain behind it — no longer has a reason to exist.
// Every button still performs a real navigation/auth action, per this
// screen's own governing rule.

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../dev/dev_onboarding_gold_design.dart';
import '../models/zyra_error_state.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_session_router.dart';
import '../services/zyra_developer_access.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_state_widgets.dart';
import 'auth/email_recovery_screen.dart';
import 'auth/role_selection_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final Future<ZyraAuthResult> Function()? googleSignIn;
  final Future<ZyraAuthResult> Function()? appleSignIn;

  /// Protected local signup rehearsal. Requested previews never fall back
  /// to OAuth if developer authority is absent or revoked.
  final bool devPreview;

  /// Optional local-study introduction after the simulated provider action.
  /// Never read by ordinary OAuth/account entry.
  final WidgetBuilder? devIntroductionBuilder;

  /// Optional protected route for the simulated provider-to-intro handoff.
  /// Ordinary authentication never reads this route factory.
  final PageRoute<void> Function(WidgetBuilder)? devIntroductionRouteBuilder;

  final ZyraOnboardingGoldDesign onboardingGoldDesign;
  final ZyraOnboardingGoldMotion onboardingGoldMotion;
  final Listenable? onboardingPageEntries;

  const WelcomeScreen({
    super.key,
    this.googleSignIn,
    this.appleSignIn,
    this.devPreview = false,
    this.devIntroductionBuilder,
    this.devIntroductionRouteBuilder,
    this.onboardingGoldDesign = ZyraOnboardingGoldDesign.diagonalDust,
    this.onboardingGoldMotion = ZyraOnboardingGoldMotion.liveDrift,
    this.onboardingPageEntries,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  _WelcomeProvider? _loadingProvider;
  String? _error;

  bool get _loading => _loadingProvider != null;

  Future<void> _continueWithGoogle() => _continueWith(
    _WelcomeProvider.google,
    widget.googleSignIn ?? ZyraAuth.signInWithGoogle,
  );
  Future<void> _continueWithApple() => _continueWith(
    _WelcomeProvider.apple,
    widget.appleSignIn ?? ZyraAuth.signInWithApple,
  );

  Future<void> _continueWith(
    _WelcomeProvider provider,
    Future<ZyraAuthResult> Function() signIn,
  ) async {
    if (_loading) return;
    if (widget.devPreview) {
      if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
      // Show the normal first-use path without replacing the authenticated
      // operator, invoking a provider, or resolving their real member home.
      final builder =
          widget.devIntroductionBuilder ??
          (_) => const RoleSelectionScreen(devPreview: true);
      Navigator.of(context).pushReplacement(
        widget.devIntroductionRouteBuilder?.call(builder) ??
            MaterialPageRoute<void>(allowSnapshotting: false, builder: builder),
      );
      return;
    }
    setState(() {
      _loadingProvider = provider;
      _error = null;
    });
    try {
      final result = await signIn();
      if (!mounted) return;

      switch (result.outcome) {
        case ZyraAuthOutcome.cancelled:
          setState(() => _loadingProvider = null);
          return;
        case ZyraAuthOutcome.error:
          setState(() {
            _loadingProvider = null;
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
    } catch (error) {
      // Protected routing can refuse admission even after OAuth succeeds.
      // Stay on Welcome, release every control and never show raw details.
      if (!mounted) return;
      setState(() {
        _loadingProvider = null;
        _error = zyraErrorKindFor(error).content.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ZyraDeveloperAccess.authorizationChanges,
    builder: (context, _) {
      if (widget.devPreview && !ZyraDeveloperAccess.canUseDeveloperTools) {
        return Scaffold(
          key: const ValueKey('welcome_preview_denied'),
          backgroundColor: ZyraColors.modalSheetSurface,
          body: const SizedBox.expand(),
        );
      }
      return _buildWelcome(context);
    },
  );

  Widget _buildWelcome(BuildContext context) {
    // Keep the platform-native provider first and larger: Apple leads on
    // iOS, while Google leads on Android. Both retain the approved white
    // treatment; size and order communicate the platform priority.
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final googleButton = _OAuthButton(
      key: const ValueKey('welcome_google'),
      iconAsset: 'assets/auth/google_g_logo.png',
      label: 'Continue with Google',
      loadingLabel: 'Connecting with Google…',
      brand: _OAuthButtonBrand.google,
      emphasized: !isIOS,
      fitLabel: widget.devPreview,
      loading: _loadingProvider == _WelcomeProvider.google,
      onTap: _loading ? null : _continueWithGoogle,
    );
    final appleButton = _OAuthButton(
      key: const ValueKey('welcome_apple'),
      icon: Icons.apple,
      label: 'Continue with Apple',
      loadingLabel: 'Connecting with Apple…',
      brand: _OAuthButtonBrand.apple,
      emphasized: isIOS,
      fitLabel: widget.devPreview,
      loading: _loadingProvider == _WelcomeProvider.apple,
      onTap: _loading ? null : _continueWithApple,
    );
    final orderedButtons = isIOS
        ? [appleButton, googleButton]
        : [googleButton, appleButton];
    final orderedProviders = isIOS
        ? const [_WelcomeProvider.apple, _WelcomeProvider.google]
        : const [_WelcomeProvider.google, _WelcomeProvider.apple];

    Widget providerSlot({
      required _WelcomeProvider provider,
      required Widget button,
      required double height,
    }) {
      final visible = _loadingProvider == null || _loadingProvider == provider;
      return SizedBox(height: height, child: visible ? button : null);
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.devPreview)
              ZyraOnboardingGoldBackdrop(
                design: widget.onboardingGoldDesign,
                motion: widget.onboardingGoldMotion,
                pageEntries: widget.onboardingPageEntries,
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    // OA-ZYRA-122 §2: tightened from flex 3/4 — the welcome
                    // screen felt too open with excessive empty vertical
                    // space; logo/slogan/buttons now sit closer together.
                    const Spacer(flex: 2),
                    // 52 -> 80. The Founder approved the card labelled "64" in
                    // the size comparison; that widget was mislabelled and the
                    // card was drawing at roughly 80pt. See splash_screen.dart
                    // for the arithmetic.
                    //
                    // The pairing still holds: splash 74 arriving, Welcome 80
                    // settling, so the mark GROWS into place across the
                    // handoff rather than shrinking away.
                    //
                    // NOT RESPONSIVE. 80pt is close to edge-to-edge on a 390pt
                    // phone and there is no scaling for narrower devices — an
                    // iPhone SE will be tight. Flagged rather than solved,
                    // because a responsive wordmark is its own decision.
                    if (widget.devPreview)
                      // The local rehearsal has a persistent Close header. Keep
                      // its wordmark single-line at compact/enlarged-text sizes;
                      // ordinary Welcome retains its approved 80pt presentation.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'ZYRA',
                          maxLines: 1,
                          style: ZyraText.wordmark(
                            size: 80,
                            color: ZyraColors.splashWordmark,
                          ),
                        ),
                      )
                    else
                      Text(
                        'ZYRA',
                        style: ZyraText.wordmark(
                          size: 80,
                          color: ZyraColors.splashWordmark,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      // Approved tagline — BUSINESS/BRAND MESSAGING/Summary.md
                      'Connecting Through Trust',
                      // Was a bare subtext() — i.e. 12.5, the default body
                      // subtext size, which is what you get when nobody
                      // decides. Shared with the splash since 2026-08-09 so
                      // the tagline cannot be two sizes again.
                      style: ZyraText.subtext(
                        size: ZyraText.taglineSize(context),
                        color: ZyraColors.splashTagline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(flex: 2),
                    if (_error != null) ...[
                      ZyraErrorBanner(
                        message: _error!,
                        onDismiss: () => setState(() => _error = null),
                      ),
                      const SizedBox(height: 14),
                    ],
                    providerSlot(
                      provider: orderedProviders[0],
                      button: orderedButtons[0],
                      height: 54,
                    ),
                    const SizedBox(height: 14),
                    providerSlot(
                      provider: orderedProviders[1],
                      button: orderedButtons[1],
                      height: 46,
                    ),
                    const SizedBox(height: 12),
                    if (!widget.devPreview)
                      TextButton(
                        key: const ValueKey('welcome_recovery_email'),
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EmailRecoveryScreen(),
                                ),
                              ),
                        child: Text(
                          'Use recovery email',
                          style: ZyraText.subtext(size: 12.5),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _WelcomeProvider { google, apple }

enum _OAuthButtonBrand { apple, google }

class _OAuthButton extends StatelessWidget {
  final IconData? icon;
  final String? iconAsset;
  final String label;
  final String loadingLabel;
  final _OAuthButtonBrand brand;
  final bool emphasized;
  final bool loading;
  final bool fitLabel;
  final VoidCallback? onTap;

  const _OAuthButton({
    super.key,
    this.icon,
    this.iconAsset,
    required this.label,
    required this.loadingLabel,
    required this.brand,
    required this.emphasized,
    required this.loading,
    this.fitLabel = false,
    this.onTap,
  }) : assert(icon != null || iconAsset != null);

  Widget _buttonLabel(String value, Color color) {
    final text = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: ZyraText.button(size: emphasized ? 15 : 13.5, color: color),
    );
    // Keep the complete provider label visible in compact enlarged-text local
    // studies. Ordinary OAuth retains its approved layout and text scaling.
    return fitLabel ? FittedBox(fit: BoxFit.scaleDown, child: text) : text;
  }

  @override
  Widget build(BuildContext context) {
    final isGoogle = brand == _OAuthButtonBrand.google;
    const textColor = Color(0xFF1F1F1F);
    final dimmed = onTap == null && !loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: dimmed ? 0.42 : 1,
      child: SizedBox(
        width: double.infinity,
        height: emphasized ? 54 : 46,
        child: DecoratedBox(
          key: ValueKey(
            isGoogle
                ? 'welcome_google_white_surface'
                : 'welcome_apple_white_surface',
          ),
          decoration: BoxDecoration(
            // Google's standard-colour G must not be recoloured or placed
            // directly on ZYRA purple. Its approved light treatment uses a
            // white surface and grey border. Apple's approved white style
            // uses a white surface with a black mark and text.
            color: Colors.white,
            border: Border.all(
              color: isGoogle ? const Color(0xFF747775) : Colors.white,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: onTap,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: loading
                      ? Padding(
                          key: const ValueKey('oauth_connecting'),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: emphasized ? 18 : 16,
                                height: emphasized ? 18 : 16,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: Color(0xFF5F6368),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: _buttonLabel(loadingLabel, textColor),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          key: const ValueKey('oauth_idle'),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (iconAsset != null)
                                Image.asset(
                                  iconAsset!,
                                  key: const ValueKey(
                                    'welcome_google_brand_logo',
                                  ),
                                  width: emphasized ? 20 : 18,
                                  height: emphasized ? 20 : 18,
                                  filterQuality: FilterQuality.high,
                                  excludeFromSemantics: true,
                                )
                              else
                                Icon(
                                  icon,
                                  color: textColor,
                                  size: emphasized ? 20 : 17,
                                ),
                              const SizedBox(width: 10),
                              Flexible(child: _buttonLabel(label, textColor)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
