import 'package:flutter/material.dart';

/// LOCK17: the shared unread count for an existing conversation icon button.
class ZyraConversationUnreadBadge extends StatelessWidget {
  const ZyraConversationUnreadBadge({
    super.key,
    required this.child,
    required this.unreadCount,
    this.backgroundColor,
    this.muted = false,
  });

  final Widget child;
  final int unreadCount;
  final Color? backgroundColor;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (unreadCount <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -3,
          right: -3,
          child: IgnorePointer(
            child: ZyraConversationUnreadCount(
              count: unreadCount,
              backgroundColor: backgroundColor,
              muted: muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// The shared count can also sit inline, such as before a Circle row chevron.
class ZyraConversationUnreadCount extends StatelessWidget {
  const ZyraConversationUnreadCount({
    super.key,
    required this.count,
    this.backgroundColor,
    this.muted = false,
  });

  final int count;
  final Color? backgroundColor;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Semantics(
      label: zyraConversationUnreadLabel(count),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: muted ? const Color(0xFFD9D0C2) : const Color(0xFFC08A3A),
            borderRadius: BorderRadius.circular(8),
            // Paint the page ring outside the locked 16 pt shape.
            boxShadow: [
              BoxShadow(
                color:
                    backgroundColor ??
                    Theme.of(context).scaffoldBackgroundColor,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
              maxHeight: 16,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                widthFactor: 1,
                child: Text(
                  count >= 10 ? '9+' : '$count',
                  style: TextStyle(
                    color: muted
                        ? const Color(0xFF5C5048)
                        : const Color(0xFF2B2420),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1,
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

String zyraConversationUnreadLabel(int count) =>
    '$count unread ${count == 1 ? 'message' : 'messages'}';
