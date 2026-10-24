// Reset/Delete are explanation destinations only. Their written destructive
// contracts remain unapproved, and the client service methods also refuse.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

import '../../dev/zyra_app_gold_preview.dart';
import '../../main.dart' show supabase;
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import 'help_support_screen.dart';

class _AccountControlLifetime extends ChangeNotifier {
  _AccountControlLifetime({String? expectedOwner, int? expectedGeneration})
    : owner = expectedOwner ?? _currentId(),
      generation = expectedGeneration ?? ZyraAccountState.generation,
      previewSession = ZyraInternalPreviewClient.previewSession,
      openingToken = _currentToken() {
    AppState.instance.addListener(_check);
    ZyraInternalPreviewClient.changes.addListener(_check);
    try {
      _subscription = ZyraAuth.authStateChanges.listen(
        _authChanged,
        onError: (Object _, StackTrace _) => _check(force: true),
      );
    } catch (_) {
      // No SDK means no originating owner and no active control.
    }
  }

  final String? owner;
  final int generation;
  final int previewSession;
  final String? openingToken;
  StreamSubscription? _subscription;
  bool _alive = true;
  bool _revoked = false;

  static String? _currentId() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  static String? _currentToken() {
    try {
      return supabase.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  bool get current =>
      _alive &&
      !_revoked &&
      owner != null &&
      !ZyraAccountState.isSigningOut &&
      ZyraAccountState.generation == generation &&
      !ZyraInternalPreviewClient.isActive &&
      ZyraInternalPreviewClient.previewSession == previewSession &&
      _currentId() == owner;

  void _authChanged(AuthState state) {
    _check(
      force:
          state.session?.user.id != owner ||
          state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.signedOut ||
          state.event == AuthChangeEvent.passwordRecovery ||
          (state.event == AuthChangeEvent.initialSession &&
              state.session?.accessToken != openingToken),
    );
  }

  void _check({bool force = false}) {
    if (!_alive || _revoked || (!force && current)) return;
    _revoked = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _alive = false;
    AppState.instance.removeListener(_check);
    ZyraInternalPreviewClient.changes.removeListener(_check);
    _subscription?.cancel().ignore();
    super.dispose();
  }
}

class AccountAdvancedScreen extends StatefulWidget {
  const AccountAdvancedScreen({super.key, this.guardian = false});
  final bool guardian;

  @override
  State<AccountAdvancedScreen> createState() => _AccountAdvancedScreenState();
}

class _AccountAdvancedScreenState extends State<AccountAdvancedScreen> {
  late final _AccountControlLifetime _lifetime;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _lifetime = _AccountControlLifetime();
  }

  @override
  void dispose() {
    _lifetime.dispose();
    super.dispose();
  }

  bool get _canAct =>
      mounted && _lifetime.current && ModalRoute.of(context)?.isCurrent == true;

  Future<void> _openExplanation({required bool reset}) async {
    if (!_canAct || _opening) return;
    setState(() => _opening = true);
    final owner = _lifetime.owner!;
    final generation = _lifetime.generation;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _lifetime.current
              ? _AccountControlInformationScreen(
                  reset: reset,
                  guardian: widget.guardian,
                  owner: owner,
                  generation: generation,
                )
              : const SizedBox.shrink(),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _lifetime,
    builder: (context, _) => Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Advanced', style: ZyraText.heading(size: 17)),
        iconTheme: IconThemeData(color: ZyraColors.foreground),
      ),
      body: Container(
        decoration: ZyraAppGoldDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
            children: [
              Text(
                'Understand your options.',
                style: ZyraText.heading(size: 25),
              ),
              const SizedBox(height: 12),
              Text(
                'These pages explain account controls. Reset and deletion are not available from this version.',
                style: ZyraText.subtext(size: 13),
              ),
              const SizedBox(height: 24),
              _AccountInformationRow(
                label: 'Reset profile',
                hint: 'Read about starting your profile setup again.',
                icon: Icons.restart_alt_rounded,
                onTap: _opening || !_lifetime.current
                    ? null
                    : () => _openExplanation(reset: true),
              ),
              const SizedBox(height: 14),
              _AccountInformationRow(
                label: 'Delete account',
                hint: 'Read about permanent account closure and support.',
                icon: Icons.delete_outline_rounded,
                onTap: _opening || !_lifetime.current
                    ? null
                    : () => _openExplanation(reset: false),
              ),
              if (!_lifetime.current) ...[
                const SizedBox(height: 20),
                Text(
                  'Account controls unavailable. Reopen Settings from your current account.',
                  style: ZyraText.subtext(size: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _AccountControlInformationScreen extends StatefulWidget {
  const _AccountControlInformationScreen({
    required this.reset,
    required this.guardian,
    required this.owner,
    required this.generation,
  });
  final bool reset;
  final bool guardian;
  final String owner;
  final int generation;

  @override
  State<_AccountControlInformationScreen> createState() =>
      _AccountControlInformationScreenState();
}

class _AccountControlInformationScreenState
    extends State<_AccountControlInformationScreen> {
  late final _AccountControlLifetime _lifetime;

  @override
  void initState() {
    super.initState();
    _lifetime = _AccountControlLifetime(
      expectedOwner: widget.owner,
      expectedGeneration: widget.generation,
    );
  }

  @override
  void dispose() {
    _lifetime.dispose();
    super.dispose();
  }

  bool get _canAct =>
      mounted && _lifetime.current && ModalRoute.of(context)?.isCurrent == true;

  void _back() {
    if (_canAct) Navigator.of(context).pop();
  }

  void _support() {
    if (!_canAct) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _lifetime.current
            ? const HelpSupportScreen()
            : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _lifetime,
    builder: (context, _) {
      final title = widget.reset ? 'Reset Profile' : 'Delete Account';
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            key: const ValueKey('account-control-info-back'),
            tooltip: 'Back',
            onPressed: _lifetime.current ? _back : null,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(title, style: ZyraText.heading(size: 17)),
        ),
        body: Container(
          decoration: ZyraAppGoldDecoration(
            gradient: ZyraColors.genderGradient(AppState.instance.gender),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              children: [
                Icon(
                  widget.reset
                      ? Icons.restart_alt_rounded
                      : Icons.manage_accounts_outlined,
                  size: 38,
                  color: ZyraColors.journeyGold,
                ),
                const SizedBox(height: 20),
                Text(
                  !_lifetime.current
                      ? 'Account controls unavailable'
                      : widget.reset
                      ? 'A fresh start needs a clear plan.'
                      : 'Account closure needs care.',
                  style: ZyraText.heading(size: 26),
                ),
                const SizedBox(height: 18),
                Text(
                  !_lifetime.current
                      ? 'Reopen Settings from your current account.'
                      : widget.reset
                      ? widget.guardian
                            ? 'A Guardian profile reset is not available. This page does not change your account, Seeker links, Circle or membership.'
                            : 'Reset Profile is not available yet. This page does not clear answers, photos, history, Guardian links or paid entitlements, and it does not restart setup.'
                      : 'Delete Account is not available from this version. This page does not delete your account or photos, end relationships, sign you out or submit a deletion request.',
                  style: ZyraText.body(size: 14),
                ),
                const SizedBox(height: 20),
                if (_lifetime.current) ...[
                  Text(
                    widget.reset
                        ? widget.guardian
                              ? 'Use supported profile edits for changes. Any future reset needs its own clearly described Guardian-specific behavior.'
                              : 'You can continue making supported changes through Edit profile and Manage photos. The final reset details will be provided before this feature becomes available.'
                        : widget.guardian
                        ? 'Closing a Guardian account affects its Seeker links and responsibilities. Contact support for help with your account and data.'
                        : 'Account closure affects shared Journeys, Guardian links and account data. Contact support for help with your account and data.',
                    style: ZyraText.subtext(size: 13),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Opening this page does not change or cancel store subscription billing.',
                    style: ZyraText.subtext(size: 13),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const ValueKey('account-control-info-support'),
                    onPressed: _support,
                    icon: const Icon(Icons.support_agent_outlined),
                    label: const Text('Help & support'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _AccountInformationRow extends StatelessWidget {
  const _AccountInformationRow({
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.surfaceFill,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: ZyraColors.journeyGold, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ZyraText.body(size: 15)),
                  const SizedBox(height: 5),
                  Text(hint, style: ZyraText.subtext(size: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: ZyraColors.foregroundMuted,
            ),
          ],
        ),
      ),
    ),
  );
}
