// Notification preferences.
//
// REBUILT 2026-08-06. The previous version's own header said the toggles
// were "honest" about being local-only: they wrote to AppState and nowhere
// else, so every choice was lost on restart.
//
// That was tolerable for three product notifications. It stopped being
// tolerable when the Founder's Settings brief added Marketing Emails and
// Product Updates, because those are not preferences — under UK GDPR and
// PECR they are records of CONSENT. A consent switch that forgets means the
// consent was never recorded, a withdrawal is never honoured, and neither
// can be evidenced.
//
// Now backed by `notification_preferences`, which is append-only: every
// change is a new row and nothing is ever updated or deleted, so opting in,
// withdrawing and opting in again all survive. A single mutable row could
// only prove the most recent one.
//
// Defaults come from the server, not from here — marketing and product
// updates default OFF, because a pre-ticked consent box is not consent.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../dev/zyra_app_gold_preview.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_notification_prefs_service.dart';
import '../../services/zyra_promotion_engine.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final ZyraPromotionRole role;
  final Future<Map<ZyraNotifyCategory, bool>?> Function()? loadPreferences;
  final Future<bool> Function(ZyraNotifyCategory, bool)? savePreference;

  const NotificationSettingsScreen({
    super.key,
    this.role = ZyraPromotionRole.seeker,
    this.loadPreferences,
    this.savePreference,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  Map<ZyraNotifyCategory, bool>? _values;
  bool _loading = true;
  String? _error;
  int _loadRequest = 0;
  final Set<ZyraNotifyCategory> _saving = {};
  // Display invalidation is not cancellation of a dispatched write. Keep
  // its category owned until transport settles, even after an unknown ACK
  // invalidates the optimistic map and advances the display epoch.
  final Set<ZyraNotifyCategory> _pendingWrites = {};
  late final String? _owner;
  late final int _generation;
  bool _revoked = false;
  StreamSubscription? _authSubscription;

  String? _ownerId() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      return null; // Local preview or widget test without a client.
    }
  }

  bool get _current =>
      !_revoked &&
      !ZyraAccountState.isSigningOut &&
      ZyraAccountState.generation == _generation &&
      _ownerId() == _owner;

  bool get _canWrite =>
      mounted &&
      _current &&
      (_owner != null || widget.savePreference != null) &&
      ModalRoute.of(context)?.isCurrent == true;

  @override
  void initState() {
    super.initState();
    _owner = _ownerId();
    _generation = ZyraAccountState.generation;
    AppState.instance.addListener(_accountChanged);
    try {
      _authSubscription = ZyraAuth.authStateChanges.listen(
        (_) => _accountChanged(),
        onError: (Object _, StackTrace _) => _accountChanged(force: true),
      );
    } catch (_) {
      // Injected local read/write fixtures need no initialized Auth client.
    }
    _load();
  }

  void _accountChanged({bool force = false}) {
    if (!mounted || _revoked || (!force && _current)) return;
    _revoked = true;
    _loadRequest++;
    _values = null;
    _saving.clear();
    _loading = false;
    _error = "We couldn't load your preferences.";
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
    AppState.instance.removeListener(_accountChanged);
    _authSubscription?.cancel().ignore();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_current) {
      _accountChanged();
      return;
    }
    if (_pendingWrites.isNotEmpty) return;
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _values = null;
      _saving.clear();
      _error = null;
    });
    Map<ZyraNotifyCategory, bool>? v;
    try {
      v =
          await (widget.loadPreferences?.call() ??
              ZyraNotificationPrefsService.fetch());
    } catch (_) {
      v = null;
    }
    // The RPC is expected to include every category, including consent
    // defaults. A partial response is not permission to invent an off value.
    if (v != null &&
        ZyraNotifyCategory.values.any(
          (category) => !v!.containsKey(category),
        )) {
      v = null;
    }
    if (!mounted) return;
    if (!_current) {
      _accountChanged();
      return;
    }
    if (request != _loadRequest) return;
    setState(() {
      _values = v == null ? null : Map.of(v);
      _loading = false;
      _error = v == null ? "We couldn't load your preferences." : null;
    });
  }

  /// An unacknowledged write may have committed. Withdraw the optimistic
  /// display until an authoritative reload rather than inventing a rollback.
  Future<void> _set(ZyraNotifyCategory c, bool v) async {
    if (!_current) {
      _accountChanged();
      return;
    }
    if (!_canWrite ||
        _loading ||
        _pendingWrites.contains(c) ||
        _values?[c] == null) {
      return;
    }
    final loadRequest = _loadRequest;
    setState(() {
      _values![c] = v;
      _saving.add(c);
      _pendingWrites.add(c);
      _error = null;
    });

    var ok = false;
    try {
      ok =
          await (widget.savePreference?.call(c, v) ??
              ZyraNotificationPrefsService.set(c, v));
    } catch (_) {
      ok = false;
    }
    _pendingWrites.remove(c);
    if (!mounted) return;
    if (!_current) {
      _accountChanged();
      return;
    }
    if (loadRequest != _loadRequest) {
      // This ACK cannot publish into a newer display epoch. Its settlement
      // can, however, make an authoritative Reload safe once all flights end.
      setState(() {});
      return;
    }
    setState(() {
      _saving.remove(c);
      if (!ok) {
        _loadRequest++;
        _values = null;
        _saving.clear();
        _error =
            "We couldn't confirm this change. Reload your preferences before trying again.";
      }
    });
    if (ok) {
      ZyraPromotionEngine.instance.recordPreferenceChanged(
        role: widget.role,
        categoryCode: c.code,
        marketing: c.isConsent,
        enabled: v,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const product = [
      ZyraNotifyCategory.matchesJourneys,
      ZyraNotifyCategory.guardianActivity,
      ZyraNotifyCategory.introductions,
    ];
    const consent = [
      ZyraNotifyCategory.productUpdates,
      ZyraNotifyCategory.marketingEmails,
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Notifications', style: ZyraText.heading(size: 17)),
        iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
      ),
      body: Container(
        decoration: ZyraAppGoldDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: SafeArea(
          child: _loading
              ? const ZyraLoading()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
                  children: [
                    if (_error != null) ...[
                      ZyraErrorBanner(
                        message: _error!,
                        onRetry:
                            _values == null &&
                                _current &&
                                _pendingWrites.isEmpty
                            ? _load
                            : null,
                        onDismiss: _values == null
                            ? null
                            : () => setState(() => _error = null),
                      ),
                      SizedBox(height: 18),
                    ],

                    if (_values != null) ...[
                      const _DeviceNotificationStatus(),
                      SizedBox(height: 28),

                      Text(
                        'SERVICE NOTIFICATIONS',
                        style: ZyraText.chapterLabel(
                          color: ZyraColors.ink(0.54),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.role == ZyraPromotionRole.seeker
                            ? 'Matches, Journeys and Guardian activity that need your attention.'
                            : 'Seeker links, Journey activity and introductions that need your attention.',
                        style: ZyraText.subtext(
                          size: 11.5,
                          color: ZyraColors.ink(0.38),
                        ),
                      ),
                      SizedBox(height: 12),
                      ...product.map(_row),

                      SizedBox(height: 28),
                      // Separated, and labelled as consent rather than as
                      // preference. They are a different kind of decision and
                      // presenting them identically would obscure that.
                      Text(
                        'MARKETING',
                        style: ZyraText.chapterLabel(
                          color: ZyraColors.ink(0.54),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Off unless you turn them on. You can withdraw at any '
                        'time, and we keep a record of both.',
                        style: ZyraText.subtext(
                          size: 11.5,
                          color: ZyraColors.ink(0.38),
                        ),
                      ),
                      SizedBox(height: 12),
                      ...consent.map(_row),

                      SizedBox(height: 28),
                      Text(
                        'ACCOUNT & SAFETY',
                        style: ZyraText.chapterLabel(
                          color: ZyraColors.ink(0.54),
                        ),
                      ),
                      SizedBox(height: 10),
                      const _EssentialNotificationRow(),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _row(ZyraNotifyCategory c) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: _ToggleRow(
      label: c.label,
      subtitle: c.hint,
      value: _values![c]!,
      busy: _saving.contains(c) || !_canWrite,
      onChanged: (v) => _set(c, v),
    ),
  );
}

class _DeviceNotificationStatus extends StatelessWidget {
  const _DeviceNotificationStatus();

  @override
  Widget build(BuildContext context) {
    final state = ZyraPromotionEngine.instance.permissionState;
    final enabled = state == ZyraNotificationPermissionState.enabled;
    final unavailable = state == ZyraNotificationPermissionState.unavailable;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZyraColors.foreground.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZyraColors.ink(0.12), width: 0.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            enabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: enabled ? ZyraColors.unlockDot : ZyraColors.ink(0.38),
            size: 20,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Device notifications',
                        style: ZyraText.body(size: 14, color: Colors.white),
                      ),
                    ),
                    Text(
                      enabled
                          ? 'On'
                          : unavailable
                          ? 'Not connected'
                          : 'Off',
                      style: ZyraText.subtext(
                        size: 11,
                        color: enabled
                            ? ZyraColors.unlockDot
                            : ZyraColors.ink(0.38),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  unavailable
                      ? 'Device alerts are not connected yet. Updates in My ZYRA still work.'
                      : enabled
                      ? 'ZYRA can alert you outside the app. Category choices below still decide what you receive.'
                      : 'Device alerts are off. Updates in My ZYRA still work.',
                  style: ZyraText.subtext(
                    size: 11.5,
                    color: ZyraColors.ink(0.54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EssentialNotificationRow extends StatelessWidget {
  const _EssentialNotificationRow();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: ZyraColors.foreground.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ZyraColors.ink(0.10), width: 0.5),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, size: 18, color: ZyraColors.ink(0.54)),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Essential account notices',
                style: ZyraText.body(size: 13.5, color: Colors.white),
              ),
              SizedBox(height: 3),
              Text(
                'Security, account and safety notices have no marketing switch. ZYRA keeps an in-app route even if device alerts are off.',
                style: ZyraText.subtext(
                  size: 11.5,
                  color: ZyraColors.ink(0.54),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ZyraText.body(size: 15, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: ZyraText.subtext(
                    size: 11.5,
                    color: ZyraColors.ink(0.38),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          // Disabled while in flight. A switch you can flip again before the
          // first write lands is how a consent log ends up with events in an
          // order nobody intended.
          Switch(
            value: value,
            onChanged: busy ? null : onChanged,
            activeThumbColor: ZyraColors.accentBorder,
          ),
        ],
      ),
    );
  }
}
