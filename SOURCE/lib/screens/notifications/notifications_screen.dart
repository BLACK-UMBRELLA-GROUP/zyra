// Notification feed (#16) — opened from the Bell icon
// (widgets/notification_bell.dart). Shared by both Seeker and Wali
// accounts; the underlying `notifications` table doesn't distinguish
// role, just whichever profile the event was for.
//
// Deep-linking a tapped notification to its Journey/match (Seeker's
// journey_flow_screen vs Wali's wali_journey_detail_screen are
// different screens with different data shapes) is out of scope for
// this pass — tapping a row marks it read only. Now tracked properly as
// OA-ZYRA-216 (the Founder's "Go" button), deliberately NOT built in the
// same pass as this one: its routing table has to be checked against
// OA-ZYRA-161's safety rules first, because a destination is a tell in
// exactly the way wording is.
//
// Navigation now gold-tints the artwork from confirmed unread state.
// Neither opening this screen nor entering any destination marks rows read.
// Explicit row/selection actions acknowledge only their captured exact IDs.
//
// SELECTION MODE added the same day (Founder: Select All + Mark All as
// Read, both disabled and visibly non-pressable when there is nothing
// to act on). The disabled state is drawn rather than hidden on
// purpose: a control that vanishes when it has no work teaches nobody
// it exists, and the Founder asked for "unavailable", not "absent".

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Supabase;
import '../../dev/zyra_app_gold_preview.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_notification_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';

typedef ZyraNotificationsLoader = Future<List<ZyraNotification>?> Function();

class NotificationsScreen extends StatefulWidget {
  /// True when living as the nav bar's fifth tab (DR-ZYRA-149) rather
  /// than a pushed route: hides the AppBar back arrow (popping here
  /// would pop HomeShell itself) and pads the list clear of the
  /// floating nav pill.
  final bool isTab;
  final ZyraNotificationsLoader? loadNotifications;

  const NotificationsScreen({
    super.key,
    this.isTab = false,
    this.loadNotifications,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<ZyraNotification> _items = [];
  late final String? _ownerUserId;
  late final int _ownerGeneration;
  late final (bool, String?) _openingSdk;
  late final ZyraNotificationsLoader? _openingLoader;
  late final int _openingPreviewSession;
  String? _initialAccessToken;
  StreamSubscription<AuthState>? _authSubscription;
  int _loadRevision = 0;
  bool _revoked = false;
  bool _acknowledging = false;
  String? _ackError;

  bool get _currentAccount =>
      mounted &&
      !_revoked &&
      !ZyraInternalPreviewClient.isActive &&
      ZyraInternalPreviewClient.previewSession == _openingPreviewSession &&
      identical(widget.loadNotifications, _openingLoader) &&
      _readSdkOwner() == _openingSdk &&
      (!_openingSdk.$1 || _openingSdk.$2 == _ownerUserId) &&
      !ZyraAccountState.isSigningOut &&
      ZyraAccountState.userId == _ownerUserId &&
      ZyraAccountState.generation == _ownerGeneration;

  (bool, String?) _readSdkOwner() {
    try {
      return (true, ZyraAuth.currentUser?.id);
    } catch (_) {
      return (false, null);
    }
  }

  void _watchAuthLifetime() {
    if (!_openingSdk.$1) return;
    try {
      _initialAccessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      _authSubscription = ZyraAuth.authStateChanges.listen((state) {
        if (!mounted || _revoked) return;
        // Inspect the event's owner as well as the SDK getter: queued
        // A→B→A must not revive A's old rows or read/mutation callbacks.
        final replacedLifetime =
            _readSdkOwner() != _openingSdk ||
            state.session?.user.id != _openingSdk.$2 ||
            state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.signedOut ||
            state.event == AuthChangeEvent.passwordRecovery ||
            (state.event == AuthChangeEvent.initialSession &&
                state.session?.accessToken != _initialAccessToken);
        _accountChanged(force: replacedLifetime);
      }, onError: (Object _, StackTrace _) => _accountChanged(force: true));
    } catch (_) {
      // An SDK present at admission must remain inspectable. Never turn a
      // failed subscription into the SDK-free injected fixture allowance.
      _withdrawOldAccount(force: true);
    }
  }

  bool _withdrawOldAccount({bool force = false}) {
    if (_revoked || (!force && _currentAccount)) return false;
    _revoked = true;
    ++_loadRevision;
    _authSubscription?.cancel().ignore();
    _items = [];
    _selected.clear();
    _selecting = false;
    _loading = false;
    _loadFailed = true;
    return true;
  }

  void _accountChanged({bool force = false}) {
    if (!mounted || !_withdrawOldAccount(force: force)) return;
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

  bool get _canAct {
    if (!mounted) return false;
    if (!_currentAccount) {
      _accountChanged();
      return false;
    }
    return ModalRoute.of(context)?.isCurrent == true;
  }

  /// BUG-05 (2026-08-14 audit, OA-ZYRA-225 — fixed 2026-08-15): true
  /// when the LAST fetch failed. Failure used to render as the empty
  /// state — "All caught up" — which is misleading exactly when the
  /// person needs to retry. A failed refresh with rows already on
  /// screen keeps showing them (stale beats blank); a failed first
  /// load shows an honest error with a retry.
  bool _loadFailed = false;

  /// Selection mode, and what is selected. Ids rather than objects so a
  /// refresh mid-selection cannot leave a stale row selected.
  bool _selecting = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _ownerUserId = ZyraAccountState.userId;
    _ownerGeneration = ZyraAccountState.generation;
    _openingSdk = _readSdkOwner();
    _openingLoader = widget.loadNotifications;
    _openingPreviewSession = ZyraInternalPreviewClient.previewSession;
    AppState.instance.addListener(_accountChanged);
    _watchAuthLifetime();
    _load();
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different delegate is not permission to repurpose the old route's
    // rows or callbacks. The new source needs a distinct admitted owner.
    if (!identical(widget.loadNotifications, _openingLoader)) {
      _withdrawOldAccount(force: true);
    }
  }

  Future<void> _load() async {
    if (!_currentAccount) return;
    final revision = ++_loadRevision;
    final loader = _openingLoader ?? ZyraNotificationService.fetchRecent;
    List<ZyraNotification>? items;
    try {
      items = await loader();
    } catch (_) {
      items = null;
    }
    if (mounted && revision == _loadRevision && _currentAccount) {
      setState(() {
        if (items == null) {
          // Fetch FAILED — keep whatever we already had. See [_loadFailed].
          _loadFailed = true;
        } else {
          _loadFailed = false;
          _items = items;
          // Drop anything that no longer exists — see [_selected].
          _selected.removeWhere((id) => !items!.any((n) => n.id == id));
        }
        _loading = false;
      });
    }
  }

  void _retry() {
    if (!_canAct) return;
    setState(() => _loading = true);
    _load();
  }

  Future<void> _acknowledge(
    Set<String> capturedIds, {
    required int capturedRevision,
    bool closeSelection = false,
  }) async {
    if (_acknowledging ||
        !_canAct ||
        capturedRevision != _loadRevision ||
        capturedIds.isEmpty ||
        (closeSelection &&
            (capturedIds.length != _selected.length ||
                !capturedIds.containsAll(_selected))) ||
        !capturedIds.every((id) => _items.any((n) => n.id == id))) {
      return;
    }
    setState(() {
      _acknowledging = true;
      _ackError = null;
    });
    final result = await ZyraNotificationService.acknowledgeIds(capturedIds);
    if (!mounted || !_currentAccount) return;
    setState(() => _acknowledging = false);
    if (!_canAct || capturedRevision != _loadRevision) return;
    if (!result.isConfirmed || !result.confirmedIds.containsAll(capturedIds)) {
      setState(
        () =>
            _ackError = "Couldn't mark these notifications as read. Try again.",
      );
      return;
    }
    // Publish only server-confirmed IDs. New arrivals are outside this set.
    final readAt = DateTime.now();
    setState(() {
      _items = [
        for (final n in _items)
          if (!capturedIds.contains(n.id) || n.isRead)
            n
          else
            ZyraNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              relatedMatchId: n.relatedMatchId,
              createdAt: n.createdAt,
              readAt: readAt,
            ),
      ];
      if (closeSelection) {
        _selected.removeAll(capturedIds);
        if (_selected.isEmpty) _selecting = false;
      }
    });
    await _load();
  }

  void _toggleSelecting() {
    if (_acknowledging || !_canAct) return;
    setState(() {
      _selecting = !_selecting;
      // Leaving selection mode drops the selection with it. Keeping it
      // would mean a hidden set of chosen rows waiting to surprise
      // whoever presses Select next.
      if (!_selecting) _selected.clear();
    });
  }

  void _toggleOne(ZyraNotification n) {
    if (_acknowledging || !_canAct) return;
    setState(() {
      if (!_selected.add(n.id)) _selected.remove(n.id);
    });
  }

  void _beginSelecting(ZyraNotification n) {
    if (_acknowledging || !_canAct) return;
    setState(() {
      _selecting = true;
      _selected.add(n.id);
    });
  }

  /// Select all / Deselect all on one control — it flips once everything
  /// is chosen, so the button is never a no-op you have to notice.
  void _selectAll() {
    if (_acknowledging || !_canAct) return;
    setState(() {
      if (_selected.length == _items.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_items.map((n) => n.id));
      }
    });
  }

  Future<void> _tap(ZyraNotification n) async {
    if (_acknowledging || !_canAct || !_items.any((row) => identical(row, n))) {
      return;
    }
    if (_selecting) {
      _toggleOne(n);
      return;
    }
    if (!n.isRead) {
      await _acknowledge({n.id}, capturedRevision: _loadRevision);
    }
  }

  @override
  void dispose() {
    _revoked = true;
    ++_loadRevision;
    AppState.instance.removeListener(_accountChanged);
    _authSubscription?.cancel().ignore();
    super.dispose();
  }

  // 2026-07-26: check_circle_outline replaces favorite_border (Founder:
  // app-wide heart-icon removal) — outline variant matches this
  // switch's other three entries.
  static IconData _iconFor(String type) => switch (type) {
    'new_match' => Icons.check_circle_outline,
    'new_message' => Icons.forum_outlined,
    'wali_request' => Icons.shield_outlined,
    'wali_invite_received' => Icons.mark_email_unread_outlined,
    'wali_invite_declined' => Icons.person_off_outlined,
    'wali_invite_expiring' => Icons.hourglass_top_rounded,
    'wali_invite_expired' => Icons.event_busy_outlined,
    'wali_invite_revoked' => Icons.link_off_outlined,
    _ => Icons.notifications_outlined,
  };

  static String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    // A rebuild may precede the account-reset notification. Withdraw loaded
    // rows synchronously as well; an old route never adopts the next owner.
    _withdrawOldAccount();
    final capturedRevision = _loadRevision;
    final shownUnreadIds = Set<String>.unmodifiable(
      _items.where((n) => !n.isRead).map((n) => n.id),
    );
    final selectedIds = Set<String>.unmodifiable(_selected);
    final hasUnread = _items.any((n) => !n.isRead);
    return Scaffold(
      // FIXED 2026-07-27 (Founder, screenshot: "the purple at top doesn't
      // suit so I'd rather the pink/purple takes whole screen"). Without
      // extendBodyBehindAppBar, the body (which carries the gender
      // gradient) starts below the AppBar, so the transparent AppBar's
      // row + status bar just showed the Scaffold's own flat background
      // colour through — a solid purple strip cutting off the gradient.
      // Now the gradient Container fills the entire screen behind the
      // AppBar, and the scrollable content below gets manual top padding
      // (status bar + toolbar height) instead of relying on SafeArea's
      // top inset, which alone only accounts for the status bar.
      extendBodyBehindAppBar: true,
      // AS A TAB (DR-ZYRA-150, Founder: "make notifications one be same
      // as connections and guardian one"): no AppBar at all — the title
      // renders in the body, top-LEFT at heading size, exactly the
      // header language Connections and Guardian speak. The pushed form
      // (the Wali side's Bell still pushes this screen) keeps its
      // AppBar and back arrow.
      appBar: widget.isTab
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('Notifications', style: ZyraText.heading(size: 17)),
              iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
              // The Mark-all action left this row on 2026-08-13
              // (DR-ZYRA-154): both forms of this screen now draw one
              // action strip in the body, so the pushed version and the
              // tab version cannot drift into offering different
              // controls.
            ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: ZyraAppGoldDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: SafeArea(
          top: widget.isTab,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The Connections/Guardian header, spoken here too — same
              // padding, same heading size, title top-left. Mark all
              // read keeps its seat on the row's right.
              if (widget.isTab)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: ZyraText.heading(size: 26),
                        ),
                      ),
                      if (_selecting)
                        Text(
                          '${_selected.length} selected',
                          style: ZyraText.subtext(
                            size: 12.5,
                            color: ZyraColors.ink(0.70),
                          ),
                        ),
                    ],
                  ),
                ),
              // THE ACTION STRIP — drawn in BOTH forms, and drawn even
              // when every control in it is dead. The Founder asked for
              // "unavailable/non-pressable", not absent: a button that
              // disappears when it has no work never teaches anyone it
              // is there, and this screen's whole job is to be the place
              // notifications are managed.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  widget.isTab
                      ? 4
                      : MediaQuery.of(context).padding.top + kToolbarHeight,
                  20,
                  8,
                ),
                // Selection has three controls. Let complete controls wrap
                // on compact screens and with larger accessibility text.
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!_selecting) ...[
                      _StripAction(
                        label: 'Select',
                        icon: Icons.checklist_rtl,
                        // Nothing to select is the disabled case the
                        // Founder named. Not "no unread" — you can
                        // legitimately want to select rows you have
                        // already read.
                        enabled: _items.isNotEmpty && !_acknowledging,
                        onTap: _toggleSelecting,
                      ),
                      _StripAction(
                        label: 'Mark all read',
                        icon: Icons.done_all,
                        enabled: hasUnread && !_acknowledging,
                        onTap: () => _acknowledge(
                          shownUnreadIds,
                          capturedRevision: capturedRevision,
                        ),
                      ),
                    ] else ...[
                      _StripAction(
                        label: _selected.length == _items.length
                            ? 'Deselect all'
                            : 'Select all',
                        icon: Icons.select_all,
                        enabled: _items.isNotEmpty && !_acknowledging,
                        onTap: _selectAll,
                      ),
                      _StripAction(
                        label: 'Mark read',
                        icon: Icons.done_all,
                        enabled: _selected.isNotEmpty && !_acknowledging,
                        onTap: () => _acknowledge(
                          selectedIds,
                          capturedRevision: capturedRevision,
                          closeSelection: true,
                        ),
                      ),
                      _StripAction(
                        label: 'Cancel',
                        icon: Icons.close,
                        enabled: !_acknowledging,
                        onTap: _toggleSelecting,
                      ),
                    ],
                  ],
                ),
              ),
              if (_ackError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(_ackError!, style: ZyraText.subtext(size: 13)),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: _loading
                      ? const ZyraLoading()
                      // BUG-05: a failed FIRST load is an error, not an empty
                      // feed — "All caught up" only ever describes a successful
                      // read. With rows already on screen, a failed refresh
                      // falls through and keeps showing them.
                      : _loadFailed && _items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ZyraEmptyState(
                            icon: Icons.cloud_off_outlined,
                            title: "Couldn't load notifications",
                            message: 'Check your connection.',
                            ctaLabel: 'Try again',
                            onCta: _retry,
                          ),
                        )
                      : _items.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: ZyraEmptyState(
                            icon: Icons.notifications_none,
                            // 2026-08-13 (ChatGPT review): the state, then
                            // the fact. Same icon, same layout.
                            title: 'All caught up',
                            message: 'No new notifications.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final n = _items[i];
                            final picked = _selected.contains(n.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _tap(n),
                                  // Long-press opens selection mode with
                                  // this row already chosen — the gesture
                                  // people try first, and it saves a trip to
                                  // the strip to select one thing.
                                  onLongPress: _selecting
                                      ? null
                                      : () => _beginSelecting(n),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: n.isRead
                                          ? ZyraColors.iconButtonBg
                                          : ZyraColors.accentBg,
                                      border: Border.all(
                                        // A picked row outlines white rather
                                        // than changing fill: unread already
                                        // owns the fill, and one row cannot
                                        // say two things with one colour.
                                        color: picked
                                            ? ZyraColors.foreground.withValues(
                                                alpha: 0.7,
                                              )
                                            : n.isRead
                                            ? ZyraColors.iconButtonBorder
                                            : ZyraColors.accentBorder,
                                        width: picked ? 1.2 : 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          _selecting
                                              ? (picked
                                                    ? Icons.check_circle
                                                    : Icons
                                                          .radio_button_unchecked)
                                              : _iconFor(n.type),
                                          color: ZyraColors.ink(0.70),
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                n.title,
                                                style: ZyraText.body(
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              if (n.body != null &&
                                                  n.body!.isNotEmpty) ...[
                                                SizedBox(height: 3),
                                                Text(
                                                  n.body!,
                                                  style: ZyraText.subtext(
                                                    size: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          _timeAgo(n.createdAt),
                                          style: ZyraText.subtext(size: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One control in the Notifications action strip.
///
/// DISABLED IS DRAWN, NOT HIDDEN (Founder, 2026-08-13: "buttons should
/// appear unavailable/non-pressable"). Dimmed to 0.32, and with a null
/// onTap rather than a guard inside the callback — a disabled control
/// that still ripples under a press has told the person it worked.
class _StripAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StripAction({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ZyraColors.foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ZyraColors.foreground.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: ZyraText.button(size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Semantics(
        enabled: false,
        label: '$label, unavailable',
        child: Opacity(opacity: 0.32, child: content),
      );
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
