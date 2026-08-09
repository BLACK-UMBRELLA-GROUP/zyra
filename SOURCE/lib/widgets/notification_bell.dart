// Bell icon (#16) — per APP/Navigation/SEEKER NAVIGATION/Summary.md's
// ratified rule: "Notifications use the Bell Icon. Bell Icon is
// positioned top-right. Notifications are not a navigation tab." Used
// identically in both HomeShell (Seeker) and WaliHomeShell (Guardian) —
// the notifications table/service work the same for either role.
//
// CHANGED 2026-07-26 (Founder, Browse review: "when pressed I don't
// want a new page I want a card to open or expand in the same screen
// which can be closed by clicking anywhere else on page but there") —
// previously pushed NotificationsScreen as a full route; became an
// anchored card (widgets/anchored_card_overlay.dart) instead.
//
// CHANGED BACK 2026-07-27 (Founder: "the bell icon is still showing the
// underline and ur sayign its probably apple so u might have to
// rediegn it... lets replace the placeholder with it taking to its own
// dedicated page with a back button"). Full grep of SOURCE/lib for any
// TextDecoration/underline near this card found nothing — the anchored
// card's own copy wasn't setting it, so redesigning the presentation is
// the practical response rather than continuing to chase an OS-level
// cause. Reverted to what the header comment above already said used to
// exist: NotificationsScreen as a real pushed route, Flutter's own
// AppBar back button included for free. The anchored _NotificationCard
// this file used to define is gone — fully superseded, not kept as
// dead code.
import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/notifications/notifications_screen.dart';
import '../services/zyra_notification_service.dart';
import '../theme/zyra_colors.dart';
import 'glass_icon_button.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final count = await ZyraNotificationService.fetchUnreadCount();
    if (mounted) setState(() => _unread = count);
  }

  Future<void> _open() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    // Unread count may have changed while the page was open (rows get
    // marked read on tap there) — refresh on return rather than relying
    // on the next 20s poll tick.
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassIconButton(
          icon: Icons.notifications_outlined,
          onTap: _open,
        ),
        if (_unread > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(color: ZyraColors.rosePink, shape: BoxShape.circle),
              child: Text(
                _unread > 9 ? '9+' : '$_unread',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
