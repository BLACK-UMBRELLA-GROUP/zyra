// Notification feed (#16) — opened from the Bell icon
// (widgets/notification_bell.dart). Shared by both Seeker and Wali
// accounts; the underlying `notifications` table doesn't distinguish
// role, just whichever profile the event was for.
//
// Deep-linking a tapped notification to its Journey/match (Seeker's
// journey_flow_screen vs Wali's wali_journey_detail_screen are
// different screens with different data shapes) is out of scope for
// this pass — tapping a row marks it read only. Follow-up if wanted.

import 'package:flutter/material.dart';
import '../../services/zyra_notification_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<ZyraNotification> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ZyraNotificationService.fetchRecent();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await ZyraNotificationService.markAllRead();
    await _load();
  }

  Future<void> _tap(ZyraNotification n) async {
    if (!n.isRead) {
      await ZyraNotificationService.markRead(n.id);
      await _load();
    }
  }

  // 2026-07-26: check_circle_outline replaces favorite_border (Founder:
  // app-wide heart-icon removal) — outline variant matches this
  // switch's other three entries.
  static IconData _iconFor(String type) => switch (type) {
        'new_match' => Icons.check_circle_outline,
        'new_message' => Icons.forum_outlined,
        'wali_request' => Icons.shield_outlined,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Notifications', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read', style: ZyraText.subtext(size: 12.5, color: Colors.white70)),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
            child: _loading
              ? const ZyraLoading()
              : _items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: ZyraEmptyState(
                        icon: Icons.notifications_none,
                        message: "You're all caught up — nothing here yet.",
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final n = _items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _tap(n),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: n.isRead ? ZyraColors.iconButtonBg : ZyraColors.accentBg,
                                  border: Border.all(
                                    color: n.isRead ? ZyraColors.iconButtonBorder : ZyraColors.accentBorder,
                                    width: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(_iconFor(n.type), color: Colors.white70, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(n.title, style: ZyraText.body(size: 14, color: Colors.white)),
                                          if (n.body != null && n.body!.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(n.body!, style: ZyraText.subtext(size: 12)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_timeAgo(n.createdAt), style: ZyraText.subtext(size: 11)),
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
      ),
    );
  }
}
