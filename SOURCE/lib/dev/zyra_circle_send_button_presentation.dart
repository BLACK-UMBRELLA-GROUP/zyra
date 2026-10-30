import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';

/// Fixed gold-outline presentation; sending remains caller-owned.
class ZyraCircleSendButton extends StatelessWidget {
  const ZyraCircleSendButton({
    super.key,
    required this.busy,
    this.onSend,
    this.privateGuardian = false,
  });

  final bool busy;
  final bool privateGuardian;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && onSend != null;
    final gold = ZyraColors.journeyGold;
    final radius = BorderRadius.circular(999);
    return Semantics(
      key: const ValueKey('circle_send_button'),
      button: true,
      enabled: enabled,
      label: busy ? 'Sending message' : 'Send message',
      onTap: ZyraTapFeedback.onTap(context, enabled ? onSend : null),
      excludeSemantics: true,
      child: Tooltip(
        message: 'Send message',
        child: SizedBox(
          width: privateGuardian ? 38 : 52,
          height: privateGuardian ? 38 : 52,
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: privateGuardian ? ZyraColors.surfaceFill : null,
                border: Border.all(
                  color: privateGuardian
                      ? ZyraColors.surfaceBorder
                      : gold.withValues(alpha: enabled ? .8 : .35),
                  width: 1,
                ),
              ),
              child: InkWell(
                key: const ValueKey('circle_send_action'),
                borderRadius: radius,
                onTap: ZyraTapFeedback.onTap(context, enabled ? onSend : null),
                excludeFromSemantics: true,
                child: Center(
                  child: busy
                      ? SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: gold,
                          ),
                        )
                      : ExcludeSemantics(
                          child: Icon(
                            privateGuardian
                                ? Icons.send_rounded
                                : Icons.arrow_upward_rounded,
                            size: privateGuardian ? 20 : 23,
                            color: gold.withValues(alpha: enabled ? 1 : .55),
                          ),
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
