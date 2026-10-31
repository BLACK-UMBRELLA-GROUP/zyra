import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Supabase;
import '../../dev/zyra_app_gold_preview.dart';

import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_hidden_profile_store.dart';
import '../../services/zyra_personal_hide_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_glass_dialog.dart';

class HiddenProfilesScreen extends StatefulWidget {
  final Future<List<String>?> Function()? loadServerIds;
  final Future<bool> Function(String)? unhideServerProfile;

  const HiddenProfilesScreen({
    super.key,
    this.loadServerIds,
    this.unhideServerProfile,
  });

  @override
  State<HiddenProfilesScreen> createState() => _HiddenProfilesScreenState();
}

class _HiddenProfilesScreenState extends State<HiddenProfilesScreen> {
  bool _loading = true;
  bool _unavailable = false;
  int _loadRequest = 0;
  List<ZyraHiddenProfileRecord> _hidden = [];
  final Set<String> _working = {};
  late final String? _owner;
  late final int _generation;
  String? _initialAccessToken;
  bool _revoked = false;
  StreamSubscription<AuthState>? _authSubscription;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _owner = _ownerId();
    _generation = ZyraAccountState.generation;
    AppState.instance.addListener(_accountChanged);
    try {
      _initialAccessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      _authSubscription = ZyraAuth.authStateChanges.listen((state) {
        if (!mounted || _revoked) return;
        // Deny from the event itself: a queued A→B→A must not disappear
        // merely because the SDK getter has already returned to A. A new
        // same-ID sign-in is also a new lifetime; healthy token refresh is
        // not. This never grants or replaces the opening owner.
        final replacedLifetime =
            state.session?.user.id != _owner ||
            state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.signedOut ||
            state.event == AuthChangeEvent.passwordRecovery ||
            (state.event == AuthChangeEvent.initialSession &&
                state.session?.accessToken != _initialAccessToken);
        _accountChanged(force: replacedLifetime);
      }, onError: (Object _, StackTrace _) => _accountChanged(force: true));
    } catch (_) {
      // Injected local fixtures need no initialized Auth client. They still
      // retain the opening generation and cannot adopt a replacement owner.
    }
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _accountChanged();
  }

  @override
  void dispose() {
    _revoked = true;
    AppState.instance.removeListener(_accountChanged);
    _authSubscription?.cancel().ignore();
    super.dispose();
  }

  String? _ownerId() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      // Pre-auth developer previews and widget tests have no client yet.
      return null;
    }
  }

  bool _sameOwner(String? owner, int generation) =>
      ZyraAccountState.generation == generation &&
      !ZyraAccountState.isSigningOut &&
      _ownerId() == owner;

  bool get _current => !_revoked && _sameOwner(_owner, _generation);

  bool get _canAct => mounted && _current && (_route?.isCurrent ?? false);

  void _accountChanged({bool force = false}) {
    if (!mounted || _revoked || (!force && _current)) return;
    _revoked = true;
    _loadRequest++;
    _hidden = [];
    _working.clear();
    _loading = false;
    _unavailable = true;
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

  bool _currentLoad(int request, String? owner, int generation) =>
      mounted &&
      _current &&
      _loadRequest == request &&
      _sameOwner(owner, generation);

  void _showUnavailable(int request) {
    if (!mounted || _loadRequest != request) return;
    setState(() {
      _hidden = [];
      _working.clear();
      _unavailable = true;
      _loading = false;
    });
  }

  Future<void> _load() async {
    if (!_current) {
      _accountChanged();
      return;
    }
    final request = ++_loadRequest;
    final owner = _owner;
    final generation = _generation;
    setState(() {
      _hidden = [];
      _unavailable = false;
      _loading = true;
    });
    try {
      // Retire legacy real identity summaries even if the new server API is
      // unavailable. These records never supply a real personal-hide row.
      final cached = await ZyraHiddenProfileStore.records();
      if (!_currentLoad(request, owner, generation)) {
        _showUnavailable(request);
        return;
      }
      final serverIds =
          await (widget.loadServerIds?.call() ??
              ZyraPersonalHideService.hiddenIdsOrNull());
      if (!_currentLoad(request, owner, generation) || serverIds == null) {
        _showUnavailable(request);
        return;
      }

      final ids = <String>{};
      for (final id in serverIds) {
        if (!ZyraPersonalHideService.isProfileId(id) ||
            !ids.add(id.toLowerCase())) {
          _showUnavailable(request);
          return;
        }
      }
      if (!_currentLoad(request, owner, generation)) {
        _showUnavailable(request);
        return;
      }
      final records = <ZyraHiddenProfileRecord>[
        for (final id in ids) ZyraHiddenProfileRecord.fallback(id),
        // Non-UUID profiles are developer previews and never reach Supabase.
        for (final record in cached)
          if (record.isDemo) record,
      ];
      setState(() {
        _hidden = records;
        _loading = false;
      });
    } catch (_) {
      _showUnavailable(request);
    }
  }

  Future<void> _unhide(ZyraHiddenProfileRecord profile) async {
    if (!_current) {
      _accountChanged();
      return;
    }
    if (!_canAct ||
        _working.contains(profile.id) ||
        !_hidden.any((record) => record.id == profile.id)) {
      return;
    }
    final owner = _owner;
    final generation = _generation;
    setState(() => _working.add(profile.id));
    var ok = profile.isDemo;
    if (!profile.isDemo) {
      try {
        ok =
            await (widget.unhideServerProfile?.call(profile.id) ??
                ZyraPersonalHideService.unhide(profile.id));
      } catch (_) {
        ok = false;
      }
    }
    if (!mounted) return;
    if (!_current || !_sameOwner(owner, generation)) {
      _accountChanged();
      return;
    }
    if (!_canAct) {
      // A dispatched write can already have committed. On route cover,
      // withdraw the stale display and require a real reload on return.
      _showUnavailable(_loadRequest);
      return;
    }
    if (ok) await ZyraHiddenProfileStore.forget(profile.id);
    if (!mounted) return;
    if (!_current || !_sameOwner(owner, generation)) {
      _accountChanged();
      return;
    }
    if (!_canAct) {
      _showUnavailable(_loadRequest);
      return;
    }
    setState(() {
      _working.remove(profile.id);
      if (ok) _hidden.removeWhere((record) => record.id == profile.id);
    });
    if (ok) {
      AppState.instance.refreshBrowseDeck();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("That didn't go through. Please try again."),
      ),
    );
  }

  Future<void> _confirmUnhide(ZyraHiddenProfileRecord profile) async {
    if (!_current) {
      _accountChanged();
      return;
    }
    if (!_canAct ||
        _working.contains(profile.id) ||
        !_hidden.any((record) => record.id == profile.id)) {
      return;
    }
    final owner = _owner;
    final generation = _generation;
    final confirmed = await showZyraGlassChoice(
      context: context,
      icon: Icons.visibility_outlined,
      title: profile.isDemo
          ? 'Unhide ${profile.firstName}?'
          : 'Unhide profile?',
      body:
          'This profile may appear for you in Profiles again. '
          'This does not change blocks or bring back an ended Journey.',
      primaryLabel: 'Unhide',
      secondaryLabel: 'Cancel',
    );
    if (!mounted) return;
    if (!_current || !_sameOwner(owner, generation)) {
      _accountChanged();
      return;
    }
    if (confirmed == true && _canAct) await _unhide(profile);
  }

  @override
  Widget build(BuildContext context) {
    if (!_current) _accountChanged();
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Hidden Profiles', style: ZyraText.heading(size: 17)),
        iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
      ),
      body: Container(
        decoration: ZyraAppGoldDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: _loading
            ? const ZyraLoading()
            : _unavailable || !_current
            ? ListView(
                padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 40),
                children: [
                  ZyraEmptyState(
                    icon: Icons.refresh_outlined,
                    title: 'Hidden profiles unavailable',
                    message: _revoked
                        ? 'Your account changed. Return to Settings and open Hidden Profiles again.'
                        : 'We could not confirm your hidden profiles right now.',
                    ctaLabel: 'Try again',
                    onCta: _canAct ? _load : null,
                  ),
                ],
              )
            : _hidden.isEmpty
            ? Padding(
                padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 40),
                child: LayoutBuilder(
                  key: const ValueKey('hidden_profiles_empty_viewport'),
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const ZyraEmptyState(
                        key: ValueKey('hidden_profiles_confirmed_empty'),
                        icon: Icons.visibility_off_outlined,
                        title: 'No hidden profiles',
                        message:
                            'Profiles you hide will appear here, where you can '
                            'unhide them at any time.',
                      ),
                    ),
                  ),
                ),
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 40),
                children: [
                  Text(
                    'These profiles are hidden from your view. '
                    "Hiding does not block them. Hiding someone you're in a Journey with ends that Journey.",
                    style: ZyraText.subtext(size: 12.5),
                  ),
                  const SizedBox(height: 16),
                  for (final profile in _hidden)
                    _HiddenProfileRow(
                      profile: profile,
                      busy: _working.contains(profile.id),
                      onUnhide: () => _confirmUnhide(profile),
                    ),
                ],
              ),
      ),
    );
  }
}

class _HiddenProfileRow extends StatelessWidget {
  final ZyraHiddenProfileRecord profile;
  final bool busy;
  final VoidCallback onUnhide;

  const _HiddenProfileRow({
    required this.profile,
    required this.busy,
    required this.onUnhide,
  });

  @override
  Widget build(BuildContext context) {
    final localFixture =
        profile.isDemo && !ZyraPersonalHideService.isProfileId(profile.id);
    final detail = profile.age > 0
        ? '${profile.age} · ${profile.city}'
        : profile.city;
    final initial = profile.firstName.isEmpty
        ? '?'
        : profile.firstName.characters.first.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ZyraColors.iconButtonBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ZyraColors.surfaceEmphasisFill,
                border: Border.all(color: ZyraColors.surfaceEmphasisBorder),
              ),
              child: localFixture
                  ? Text(initial, style: ZyraText.heading(size: 17))
                  : Icon(Icons.person_outline, color: ZyraColors.ink(0.70)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localFixture ? profile.displayName : 'Hidden profile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZyraText.body(size: 14, color: Colors.white),
                  ),
                  if (localFixture) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZyraText.subtext(size: 11.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: busy ? null : onUnhide,
              child: Text(
                busy ? 'Unhiding…' : 'Unhide',
                style: ZyraText.button(
                  size: 12.5,
                  color: ZyraColors.foreground.withValues(
                    alpha: busy ? 0.4 : 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
