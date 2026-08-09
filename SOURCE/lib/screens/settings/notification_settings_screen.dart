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

import 'package:flutter/material.dart';
import '../../services/zyra_notification_prefs_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  Map<ZyraNotifyCategory, bool>? _values;
  bool _loading = true;
  String? _error;
  final Set<ZyraNotifyCategory> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await ZyraNotificationPrefsService.fetch();
    if (!mounted) return;
    setState(() {
      _values = v;
      _loading = false;
      _error = v == null ? "We couldn't load your preferences." : null;
    });
  }

  /// Optimistic, but ONLY until the write comes back.
  ///
  /// If the save fails the switch goes back and the user is told. Leaving a
  /// consent switch showing "on" for a consent that was never recorded is
  /// the one outcome worse than the switch appearing not to work.
  Future<void> _set(ZyraNotifyCategory c, bool v) async {
    final previous = _values![c]!;
    setState(() {
      _values![c] = v;
      _saving.add(c);
      _error = null;
    });

    final ok = await ZyraNotificationPrefsService.set(c, v);
    if (!mounted) return;
    setState(() {
      _saving.remove(c);
      if (!ok) {
        _values![c] = previous;
        _error = c.isConsent
            ? "We couldn't record that. Your preference is unchanged — "
                'please try again.'
            : "That didn't save. Please try again.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = ZyraNotifyCategory.values.where((c) => !c.isConsent);
    final consent = ZyraNotifyCategory.values.where((c) => c.isConsent);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Notifications', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: _loading
              ? const ZyraLoading()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
                  children: [
                    if (_error != null) ...[
                      ZyraErrorBanner(
                        message: _error!,
                        onRetry: _values == null ? _load : null,
                        onDismiss: () => setState(() => _error = null),
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (_values != null) ...[
                      Text('ABOUT YOUR JOURNEY',
                          style: ZyraText.chapterLabel(color: Colors.white54)),
                      const SizedBox(height: 4),
                      Text(
                        'Things happening on your account.',
                        style: ZyraText.subtext(size: 11.5, color: Colors.white38),
                      ),
                      const SizedBox(height: 12),
                      ...product.map(_row),

                      const SizedBox(height: 28),
                      // Separated, and labelled as consent rather than as
                      // preference. They are a different kind of decision and
                      // presenting them identically would obscure that.
                      Text('EMAILS FROM ZYRA',
                          style: ZyraText.chapterLabel(color: Colors.white54)),
                      const SizedBox(height: 4),
                      Text(
                        'Off unless you turn them on. You can withdraw at any '
                        'time, and we keep a record of both.',
                        style: ZyraText.subtext(size: 11.5, color: Colors.white38),
                      ),
                      const SizedBox(height: 12),
                      ...consent.map(_row),
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
          busy: _saving.contains(c),
          onChanged: (v) => _set(c, v),
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
                Text(label, style: ZyraText.body(size: 15, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: ZyraText.subtext(size: 11.5, color: Colors.white38)),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
