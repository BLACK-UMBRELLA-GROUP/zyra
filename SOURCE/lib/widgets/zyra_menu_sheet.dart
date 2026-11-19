import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_confirm_sheet.dart';

/// Action menus that lead to a LOCK 28 confirm share its surface and metrics.
/// Callers keep ownership of selection, dismissal, permissions and feedback.
class ZyraMenuSheet extends StatelessWidget {
  const ZyraMenuSheet({super.key, this.surfaceKey, required this.children});

  final Key? surfaceKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (MediaQuery.sizeOf(context).height * .90 - keyboard).clamp(
            0.0,
            double.infinity,
          ),
        ),
        child: DecoratedBox(
          decoration: ZyraIvorySheet.decoration,
          child: ZyraIvorySheet(
            surfaceKey: surfaceKey,
            child: SafeArea(
              top: false,
              minimum: ZyraIvorySheet.bottomPadding,
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (constraints.maxHeight >= 30)
                      const ZyraIvorySheetHandle(bottomSpacing: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        primary: false,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ZyraMenuHeader extends StatelessWidget {
  const ZyraMenuHeader({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: ZyraText.body(size: 12.5, color: ZyraColors.secondaryText),
  );
}

class ZyraMenuOption extends StatelessWidget {
  const ZyraMenuOption({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.leading,
    this.trailing,
    this.subtitle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final Widget? leading, trailing, subtitle;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? ZyraColors.dangerText
        : ZyraColors.secondaryText;
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: ZyraText.body(size: 15, color: color),
    );
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: leading != null || subtitle != null ? 0 : 12,
          vertical: leading != null || subtitle != null ? 0 : 8,
        ),
        foregroundColor: color,
      ),
      onPressed: onPressed,
      child: leading == null && trailing == null && subtitle == null
          ? text
          : Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      text,
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
    );
  }
}

class ZyraMenuCancel extends StatelessWidget {
  const ZyraMenuCancel({
    super.key,
    required this.onPressed,
    this.label = 'Cancel',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(999)),
      boxShadow: ZyraColors.cardShadows,
    ),
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: ZyraColors.surfaceBorder),
        shape: const StadiumBorder(),
        backgroundColor: ZyraColors.cardSurface,
        foregroundColor: ZyraColors.secondaryText,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: ZyraText.body(size: 15, color: ZyraColors.secondaryText),
      ),
    ),
  );
}
