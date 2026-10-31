import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';

/// LOCK16 V2 presentation only. The shell owns the exact person and attempt.
class ZyraDraftJourneyBlockHideSheet extends StatelessWidget {
  const ZyraDraftJourneyBlockHideSheet({
    super.key,
    required this.firstName,
    required this.hide,
    required this.onKeep,
    required this.onConfirm,
  });

  final String firstName;
  final bool hide;
  final VoidCallback onKeep, onConfirm;

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.modalSheetSurface,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('journey_person_safety_scroll'),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ZyraColors.ink(.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${hide ? 'Hide' : 'Block'} $firstName and end your Journey?',
              style: ZyraText.heading(size: 22).copyWith(height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              "You're in a Journey with $firstName. ${hide ? 'Hiding' : 'Blocking'} ends it first.",
              style: ZyraText.subtext(size: 12.5).copyWith(height: 1.35),
            ),
            const SizedBox(height: 14),
            ZyraFloatingSurface(
              radius: 22,
              circle: false,
              gold: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ZyraColors.surfaceEmphasisFill,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    _row(
                      Icons.forum_outlined,
                      'Your Journey ends',
                      "It ends for both of you and can't be reopened. Your Timeline stays.",
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(
                        height: 1,
                        color: ZyraColors.surfaceBorder,
                      ),
                    ),
                    _row(
                      hide
                          ? Icons.visibility_off_outlined
                          : Icons.verified_user_outlined,
                      '$firstName is ${hide ? 'hidden' : 'blocked'}',
                      hide
                          ? "$firstName won't appear in Profiles again. You can undo this in Settings → Hidden Profiles."
                          : "$firstName can't see you, send you a request or message you again. $firstName isn't told you blocked them.",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _button(
              context,
              'journey_person_safety_keep',
              'Keep this Journey',
              onKeep,
            ),
            const SizedBox(height: 12),
            _button(
              context,
              'journey_person_safety_confirm',
              'End Journey and ${hide ? 'hide' : 'block'}',
              onConfirm,
              destructive: true,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _row(IconData icon, String title, String detail) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Icon(icon, size: 18, color: ZyraColors.journeyGold),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ZyraText.body(size: 14).copyWith(height: 1.4)),
            const SizedBox(height: 3),
            Text(
              detail,
              style: ZyraText.subtext(size: 12).copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _button(
    BuildContext context,
    String id,
    String label,
    VoidCallback action, {
    bool destructive = false,
  }) => ZyraFloatingSurface(
    radius: 999,
    circle: false,
    gold: false,
    child: OutlinedButton(
      key: ValueKey(id),
      onPressed: ZyraTapFeedback.onTap(context, action),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        backgroundColor: ZyraColors.surfaceEmphasisFill,
        foregroundColor: destructive
            ? const Color(0xFFB84A42)
            : ZyraColors.foreground,
        side: BorderSide(
          color: destructive
              ? ZyraColors.destructiveBorder
              : ZyraColors.surfaceBorder,
        ),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: ZyraText.button(
          size: 14,
          color: destructive ? const Color(0xFFB84A42) : ZyraColors.foreground,
        ),
      ),
    ),
  );
}
