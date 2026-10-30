// Shared current Profiles presentation. No account, permission or navigation authority.
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_invitation_label.dart';
import 'zyra_press_feedback.dart';

class ZyraProfilesDetailsContent extends StatelessWidget {
  const ZyraProfilesDetailsContent({
    super.key,
    this.surfaceKey,
    this.scrollKey,
    required this.children,
  });
  final Key? surfaceKey, scrollKey;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: surfaceKey,
    decoration: BoxDecoration(color: ZyraColors.surfaceFill),
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: scrollKey,
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ),
      ),
    ),
  );
}

TextStyle zyraProfilesActionStyle({Color? color}) => ZyraText.button(
  size: 14,
  color: color,
).copyWith(fontWeight: FontWeight.w400, height: 1.25, letterSpacing: .1);

Widget zyraProfilesPill({
  required Key key,
  required String label,
  required VoidCallback? onTap,
  String? semanticLabel,
  IconData? icon,
  double iconSize = 20,
  bool primary = false,
  bool previewEnabledAppearance = false,
  bool? invitationSent,
  double minimumHeight = 48,
}) => Semantics(
  button: true,
  enabled: onTap != null,
  label:
      semanticLabel ??
      (invitationSent == true ? '$label. Tap to cancel invitation' : label),
  onTap: onTap,
  excludeSemantics: true,
  child: ZyraPressFeedback(
    enabled: primary && onTap != null,
    child: Material(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: primary
                ? ZyraColors.journeyGold.withValues(
                    alpha: invitationSent == true ? .85 : .55,
                  )
                : ZyraColors.surfaceBorder,
          ),
        ),
        child: InkWell(
          key: key,
          onTap: onTap,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 48, minHeight: minimumHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: icon == null ? 10 : 8,
                vertical: 8,
              ),
              child: Center(
                child: icon == null
                    ? invitationSent != null
                          ? ZyraInvitationLabel(
                              label: label,
                              sent: invitationSent,
                              style: zyraProfilesActionStyle(
                                color: ZyraColors.ink(
                                  onTap == null && !previewEnabledAppearance
                                      ? .34
                                      : .90,
                                ),
                              ),
                            )
                          : Text(
                              label,
                              textAlign: TextAlign.center,
                              style: primary
                                  ? zyraProfilesActionStyle(
                                      color: ZyraColors.ink(
                                        onTap == null &&
                                                !previewEnabledAppearance
                                            ? .34
                                            : .90,
                                      ),
                                    )
                                  : ZyraText.button(
                                      size: 12.5,
                                      color: ZyraColors.ink(
                                        onTap == null &&
                                                !previewEnabledAppearance
                                            ? .34
                                            : .90,
                                      ),
                                    ),
                            )
                    : Icon(
                        icon,
                        size: iconSize,
                        color: onTap == null && !previewEnabledAppearance
                            ? ZyraColors.ink(.34)
                            : ZyraColors.journeyGold,
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

class ZyraProfilesBottomRow extends StatelessWidget {
  const ZyraProfilesBottomRow({
    super.key,
    required this.previous,
    required this.action,
    required this.next,
  });
  final Widget previous, action, next;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 50, child: previous),
      const SizedBox(width: 8),
      Expanded(child: action),
      const SizedBox(width: 8),
      SizedBox(width: 72, child: next),
    ],
  );
}
