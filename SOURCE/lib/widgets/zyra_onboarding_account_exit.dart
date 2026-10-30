import 'zyra_tap_feedback.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart' show supabase;
import '../screens/welcome_screen.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_auth.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_glass_dialog.dart';

/// A safe escape from first-time setup when the wrong account was used.
///
/// This deliberately calls [ZyraAuth.signOut] rather than Supabase directly,
/// so the account-scoped signup draft and the rest of ZYRA's local account
/// state are cleared before the session is released.
class ZyraOnboardingAccountExit extends StatefulWidget {
  final String expectedUserId;

  const ZyraOnboardingAccountExit({super.key, required this.expectedUserId});

  @override
  State<ZyraOnboardingAccountExit> createState() =>
      _ZyraOnboardingAccountExitState();
}

class _ZyraOnboardingAccountExitState extends State<ZyraOnboardingAccountExit> {
  bool _busy = false;
  String? _error;
  late final String _owner;
  late int _ownerGeneration;
  int? _dispatchGeneration;
  late final String? _initialToken;
  bool _firstAuthEvent = true;
  StreamSubscription<AuthState>? _authSubscription;
  bool _superseded = false;

  @override
  void initState() {
    super.initState();
    _owner = widget.expectedUserId;
    _ownerGeneration = ZyraAccountState.generation;
    String? initialToken;
    try {
      initialToken = supabase.auth.currentSession?.accessToken;
    } catch (_) {
      // A read-only local render may have no initialized Auth client.
    }
    _initialToken = initialToken;
    try {
      _authSubscription = ZyraAuth.authStateChanges.listen(
        _authChanged,
        onError: (Object _, StackTrace _) => _revoke(),
      );
    } catch (_) {
      // No client means no Auth events; the principal entry guard still denies.
    }
  }

  @override
  void didUpdateWidget(covariant ZyraOnboardingAccountExit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expectedUserId != _owner) _revoke();
  }

  void _authChanged(AuthState state) {
    if (!mounted || _superseded) return;
    final first = _firstAuthEvent;
    _firstAuthEvent = false;
    final session = state.session;
    final ownExit =
        _dispatchGeneration != null &&
        ZyraAccountState.userId == null &&
        ZyraAccountState.generation == _dispatchGeneration! + 1;
    if (session == null) {
      if (!ownExit) _revoke();
      return;
    }
    if (session.user.id != _owner ||
        state.event == AuthChangeEvent.passwordRecovery ||
        (state.event == AuthChangeEvent.signedIn &&
            !(first && session.accessToken == _initialToken)) ||
        (state.event == AuthChangeEvent.initialSession &&
            session.accessToken != _initialToken) ||
        (!ownExit && ZyraAccountState.generation != _ownerGeneration)) {
      _revoke();
    }
  }

  void _revoke() {
    if (!mounted || _superseded) return;
    setState(() {
      _superseded = true;
      _busy = false;
      _error = 'Your account changed. Close and reopen ZYRA.';
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel().ignore();
    super.dispose();
  }

  bool _guardPrincipal() {
    if (!mounted) return false;
    if (!_superseded &&
        !ZyraAccountState.isSigningOut &&
        ZyraAuth.currentUser?.id == _owner &&
        ZyraAccountState.generation == _ownerGeneration) {
      return true;
    }
    _superseded = true;
    if (mounted) {
      setState(() {
        _busy = false;
        _error = 'Your account changed. Close and reopen ZYRA.';
      });
    }
    return false;
  }

  Future<void> _confirmAndLeave() async {
    if (_busy ||
        !_guardPrincipal() ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final confirmed = await showZyraGlassChoice(
        context: context,
        icon: Icons.switch_account_outlined,
        title: 'Use a different account?',
        body:
            'This will clear setup saved on this device and return to sign in. '
            'Your account will not be deleted.',
        primaryLabel: 'Switch account',
        secondaryLabel: 'Cancel',
        primaryKey: const ValueKey('onboarding_account_exit_confirm'),
        secondaryKey: const ValueKey('onboarding_account_exit_cancel'),
      );
      if (confirmed != true ||
          !mounted ||
          !_guardPrincipal() ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }

      _dispatchGeneration = _ownerGeneration;
      await ZyraAuth.signOut(
        expectedUserId: _owner,
        expectedGeneration: _ownerGeneration,
      );
      if (!mounted) return;
      if (!_canShowWelcome) {
        setState(() {
          _error =
              'Your account changed while signing out. Close and reopen ZYRA.';
        });
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } catch (error) {
      debugPrint(
        'ZYRA: onboarding account switch failed (${error.runtimeType}).',
      );
      if (!mounted) return;
      // Only this completed, failed logout may advance its retry epoch.
      // A replacement or unrelated epoch change can never refresh old intent.
      if (!_superseded &&
          _dispatchGeneration != null &&
          !ZyraAccountState.isSigningOut &&
          ZyraAuth.currentUser?.id == _owner &&
          ZyraAccountState.userId == null &&
          ZyraAccountState.generation == _dispatchGeneration! + 1) {
        _ownerGeneration = ZyraAccountState.generation;
      }
      // GoTrue can clear the device session before a best-effort server
      // logout request reports a network error. The security postcondition,
      // not the exception alone, decides whether it is safe to show Welcome.
      if (_canShowWelcome) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      } else if (!_superseded) {
        setState(() {
          _error = "We couldn't sign you out. Please try again.";
        });
      }
    } finally {
      _dispatchGeneration = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _canShowWelcome =>
      mounted &&
      !_superseded &&
      ModalRoute.of(context)?.isCurrent == true &&
      !ZyraAccountState.isSigningOut &&
      ZyraAuth.currentUser == null &&
      ZyraAccountState.userId == null &&
      _dispatchGeneration != null &&
      ZyraAccountState.generation == _dispatchGeneration! + 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          key: const ValueKey('onboarding_account_exit'),
          onPressed: ZyraTapFeedback.onTap(
            context,
            _busy || _superseded ? null : _confirmAndLeave,
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          ),
          child: _busy
              ? Text(
                  'Signing out…',
                  style: ZyraText.subtext(
                    size: 11.5,
                    color: ZyraColors.ink(0.54),
                  ),
                )
              : Text(
                  'Use a different account',
                  style: ZyraText.subtext(
                    size: 11.5,
                    color: ZyraColors.ink(0.70),
                  ),
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: ZyraText.subtext(size: 10.5),
            ),
          ),
      ],
    );
  }
}
