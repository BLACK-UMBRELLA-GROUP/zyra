// Shared current Profiles presentation. No account, permission or navigation authority.
import 'zyra_tap_feedback.dart';
import 'dart:math' as math;

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
}) => Builder(
  builder: (context) => Semantics(
    button: true,
    enabled: onTap != null,
    label:
        semanticLabel ??
        (invitationSent == true ? '$label. Tap to cancel invitation' : label),
    onTap: ZyraTapFeedback.onTap(context, onTap),
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
            onTap: ZyraTapFeedback.onTap(context, onTap),
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(999),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 48,
                minHeight: minimumHeight,
              ),
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

/// LOCK 7 presentation only. Owners retain all request and navigation authority.
class ZyraProfilesRequestRow extends StatelessWidget {
  const ZyraProfilesRequestRow({
    super.key,
    required this.actionKey,
    required this.label,
    required this.labels,
    required this.sent,
    required this.onPrevious,
    required this.onRequest,
    required this.onNext,
    this.semanticLabel,
  });

  final Key actionKey;
  final String label;
  final List<String> labels;
  final String? semanticLabel;
  final bool sent;
  final VoidCallback? onPrevious, onRequest, onNext;

  static const arrowWidth = 68.0;

  static double heightFor(
    BuildContext context,
    double width,
    List<String> labels,
  ) {
    var height = 56.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: zyraProfilesActionStyle()),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: math.max(1, width - 2 * arrowWidth));
      height = math.max(height, painter.height + 18);
      painter.dispose();
    }
    return height;
  }

  Widget _button({
    required Key key,
    required String label,
    required VoidCallback? onTap,
    required Widget child,
    bool primary = false,
  }) => Builder(
    builder: (context) => Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: ZyraTapFeedback.onTap(context, onTap),
      excludeSemantics: true,
      child: ZyraPressFeedback(
        enabled: primary && onTap != null,
        child: InkWell(
          key: key,
          onTap: ZyraTapFeedback.onTap(context, onTap),
          excludeFromSemantics: true,
          child: Center(child: child),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: heightFor(context, constraints.maxWidth, labels),
      child: Material(
        key: const ValueKey('concept_request_row_surface'),
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: Container(
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: ZyraColors.journeyGold.withValues(alpha: sent ? 1 : .6),
            ),
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: arrowWidth,
                    child: _button(
                      key: const ValueKey('concept_previous_profile'),
                      label: 'Previous profile · no decision',
                      onTap: onPrevious,
                      child: Icon(
                        Icons.chevron_left,
                        size: 24,
                        color: onPrevious == null
                            ? ZyraColors.ink(.28)
                            : ZyraColors.journeyGold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _button(
                      key: actionKey,
                      label: semanticLabel ?? label,
                      onTap: onRequest,
                      primary: true,
                      child: ZyraInvitationLabel(
                        label: label,
                        sent: sent,
                        style: zyraProfilesActionStyle(
                          color: ZyraColors.ink(onRequest == null ? .34 : .90),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: arrowWidth,
                    child: _button(
                      key: const ValueKey('concept_next_profile'),
                      label: 'Next profile · no decision',
                      onTap: onNext,
                      child: Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: onNext == null
                            ? ZyraColors.ink(.28)
                            : ZyraColors.journeyGold,
                      ),
                    ),
                  ),
                ],
              ),
              for (final left in [true, false])
                Positioned(
                  left: left ? arrowWidth : null,
                  right: left ? null : arrowWidth,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SizedBox(
                      width: 1,
                      height: 28,
                      child: ColoredBox(color: ZyraColors.surfaceBorder),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
