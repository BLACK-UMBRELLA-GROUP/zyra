// Account-level pause consumes only the versioned owner-only server contract.
// The old discovery is_active switch is not global account privacy.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

import '../../dev/zyra_app_gold_preview.dart';
import '../../main.dart' show supabase;
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_profile_pause_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late final String? _owner;
  late final int _generation;
  late final int _previewSession;
  late final String? _openingToken;
  late final ZyraProfilePauseService _service;
  StreamSubscription? _authSubscription;
  ModalRoute<dynamic>? _route;
  bool _routeCurrent = false;
  bool _revoked = false;
  bool _started = false;
  bool _loading = true;
  bool _saving = false;
  int _request = 0;
  int _routeEpoch = 0;
  ZyraProfilePauseState _state = ZyraProfilePauseState.unavailable;

  String? _ownerId() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  bool get _current =>
      !_revoked &&
      _owner != null &&
      !ZyraAccountState.isSigningOut &&
      ZyraAccountState.generation == _generation &&
      !ZyraInternalPreviewClient.isActive &&
      ZyraInternalPreviewClient.previewSession == _previewSession &&
      _ownerId() == _owner;

  bool get _canAct =>
      mounted && _current && _routeCurrent && _route?.isCurrent == true;

  @override
  void initState() {
    super.initState();
    _owner = _ownerId();
    _generation = ZyraAccountState.generation;
    _previewSession = ZyraInternalPreviewClient.previewSession;
    try {
      _openingToken = supabase.auth.currentSession?.accessToken;
    } catch (_) {
      _openingToken = null;
    }
    _service = ZyraProfilePauseService(
      expectedUserId: _owner,
      expectedGeneration: _generation,
      canAct: () => _canAct,
    );
    AppState.instance.addListener(_accountChanged);
    ZyraInternalPreviewClient.changes.addListener(_accountChanged);
    try {
      _authSubscription = ZyraAuth.authStateChanges.listen(
        _authChanged,
        onError: (Object _, StackTrace _) => _accountChanged(force: true),
      );
    } catch (_) {
      // A missing SDK never creates a local confirmed privacy state.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final current = route?.isCurrent ?? false;
    final changed = !identical(route, _route) || current != _routeCurrent;
    if (changed) {
      _route = route;
      _routeCurrent = current;
      _routeEpoch++;
      _request++;
      _service.invalidatePending();
      _state = ZyraProfilePauseState.unavailable;
      _saving = false;
      _loading = false;
    }
    if (!_started || (changed && current)) {
      _started = true;
      if (_canAct) {
        unawaited(_load());
      } else {
        _loading = false;
      }
    }
  }

  void _accountChanged({bool force = false}) {
    if (!mounted || _revoked || (!force && _current)) return;
    _revoked = true;
    _clearConfirmation();
  }

  void _authChanged(AuthState state) {
    if (!mounted || _revoked) return;
    if (state.session?.user.id != _owner ||
        state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.signedOut ||
        state.event == AuthChangeEvent.passwordRecovery ||
        (state.event == AuthChangeEvent.initialSession &&
            state.session?.accessToken != _openingToken)) {
      _accountChanged(force: true);
    } else if (state.event == AuthChangeEvent.tokenRefreshed) {
      // A refreshed login lifetime may retry, but never reuse the old
      // visible confirmation or its retained action callback.
      _clearConfirmation();
    } else {
      _accountChanged();
    }
  }

  void _clearConfirmation() {
    _request++;
    _routeEpoch++;
    _service.invalidatePending();
    _state = ZyraProfilePauseState.unavailable;
    _saving = false;
    _loading = false;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {});
    } else {
      binding.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      binding.ensureVisualUpdate();
    }
  }

  @override
  void dispose() {
    _revoked = true;
    _request++;
    _routeEpoch++;
    _service.dispose();
    AppState.instance.removeListener(_accountChanged);
    ZyraInternalPreviewClient.changes.removeListener(_accountChanged);
    _authSubscription?.cancel().ignore();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_canAct || _saving) return;
    final request = ++_request;
    final epoch = _routeEpoch;
    setState(() {
      _loading = true;
      _state = ZyraProfilePauseState.unavailable;
    });
    final state = await _service.load();
    if (!mounted || request != _request || epoch != _routeEpoch) return;
    if (!_current) {
      _accountChanged();
      return;
    }
    if (!_canAct) return;
    setState(() {
      _state = state.ownerId == _owner
          ? state
          : ZyraProfilePauseState.unavailable;
      _loading = false;
    });
  }

  Future<void> _setPaused(bool value, int revision, int epoch) async {
    if (!_canAct ||
        _loading ||
        _saving ||
        epoch != _routeEpoch ||
        !_state.available ||
        _state.revision != revision) {
      return;
    }
    final request = ++_request;
    setState(() => _saving = true);
    final state = await _service.setPaused(value, expectedRevision: revision);
    if (!mounted || request != _request || epoch != _routeEpoch) return;
    if (!_current) {
      _accountChanged();
      return;
    }
    if (!_canAct) return;
    setState(() {
      _state = state.ownerId == _owner
          ? state
          : ZyraProfilePauseState.unavailable;
      _saving = false;
    });
    if (!_state.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "We couldn't confirm your profile pause status. Please try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final epoch = _routeEpoch;
    final revision = _state.revision;
    final paused = _state.paused == true;
    final ready = _state.available && _canAct && !_loading && !_saving;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Pause My Profile', style: ZyraText.heading(size: 17)),
        iconTheme: IconThemeData(color: ZyraColors.foreground),
      ),
      body: Container(
        decoration: ZyraAppGoldDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              Text(
                'Take a break. Keep what matters.',
                style: ZyraText.heading(size: 25),
              ),
              const SizedBox(height: 12),
              Text(
                'One account-level pause, without deleting your account or signing you out.',
                style: ZyraText.subtext(size: 14),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ZyraColors.surfaceFill,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: ZyraColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _loading
                          ? 'Checking pause status…'
                          : !_state.available
                          ? 'Pause status unavailable'
                          : paused
                          ? 'Profile paused'
                          : 'Profile active',
                      key: const ValueKey('profile-pause-status'),
                      style: ZyraText.heading(size: 19),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _loading
                          ? 'Waiting for your account’s confirmed status.'
                          : !_state.available
                          ? 'Your pause status could not be confirmed. Pause and unpause stay unavailable until the account service can confirm them.'
                          : paused
                          ? 'Your profile is paused. You can still manage your account and use permitted features.'
                          : 'Your account is not paused. Your existing profile, relationship and safety permissions still apply.',
                      style: ZyraText.subtext(size: 13),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const ValueKey('profile-pause-action'),
                      onPressed: ready
                          ? () => _setPaused(!paused, revision!, epoch)
                          : null,
                      icon: Icon(
                        paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      ),
                      label: Text(
                        _saving
                            ? 'Confirming…'
                            : paused
                            ? 'Unpause My Profile'
                            : 'Pause My Profile',
                        style: ZyraText.button(size: 13),
                      ),
                    ),
                    if (!_loading && !_state.available) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        key: const ValueKey('profile-pause-retry'),
                        onPressed: _canAct && !_saving
                            ? () {
                                if (epoch == _routeEpoch) _load();
                              }
                            : null,
                        child: const Text('Try again'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _explanation(
                'While paused',
                'Other members cannot open your profile or start new activity involving your account. Existing shared entries use a neutral unavailable state, without revealing whether the reason is pause, a block or another restriction.',
              ),
              _explanation(
                'Your account stays yours',
                'Your profile information, Guardian links, Journeys, history and paid entitlements stay intact. Pause does not end or delete a Journey.',
              ),
              _explanation(
                'Unpause when you are ready',
                'Unpausing does not remove blocks, restore removed Guardians, lift safety restrictions or automatically resume a separately paused Journey.',
              ),
              _explanation(
                'Membership billing',
                'Pausing does not cancel Apple or Google subscription billing. Manage billing through your store subscription settings.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _explanation(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ZyraText.body(size: 15)),
        const SizedBox(height: 6),
        Text(body, style: ZyraText.subtext(size: 13)),
      ],
    ),
  );
}
