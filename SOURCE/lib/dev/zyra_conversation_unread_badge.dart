import 'package:flutter/material.dart';

/// LOCK17: the shared unread count for an existing conversation icon button.
class ZyraConversationUnreadBadge extends StatelessWidget {
  const ZyraConversationUnreadBadge({
    super.key,
    required this.child,
    required this.unreadCount,
    this.backgroundColor,
  });

  final Widget child;
  final int unreadCount;
  final Color? backgroundColor;

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
            child: Semantics(
              label:
                  '$unreadCount unread '
                  '${unreadCount == 1 ? 'message' : 'messages'}',
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFC08A3A),
                    borderRadius: BorderRadius.circular(8),
                    // The locked gold shape is 16 pt high. Paint its page
                    // ring outside, so the ring never consumes that height.
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
                          unreadCount >= 10 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Color(0xFF2B2420),
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
            ),
          ),
        ),
      ],
    );
  }
}
