// Shared error / empty / disabled-state widgets — implements APP/UX
// Writing/ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1.md (DR-ZYRA-080).
// Every screen should use these rather than one-off Text() error strings,
// so the warm tone and visual treatment stay consistent app-wide.
// LOCK22 V3 now supplies the shared empty layout, including legacy invitations.

import 'zyra_tap_feedback.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../dev/zyra_one_journey_monogram_presentation.dart';

/// Inline field-level validation message (Category 1 of the standard).
/// Sits directly under a form field — no icon, no modal, low emphasis.
class ZyraFieldError extends StatelessWidget {
  final String? message;
  const ZyraFieldError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        message!,
        style: ZyraText.subtext(size: 12, color: ZyraColors.destructive),
      ),
    );
  }
}

/// Soft glass banner for simulated backend / auth / network errors
/// (Category 2) and send-failure style errors. Dismissible, non-blocking,
/// appears near the action that triggered it rather than as a takeover.
class ZyraErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ZyraErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: ZyraColors.destructive.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ZyraColors.ink(0.22), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: ZyraColors.foreground, size: 18),
              SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Text(message, style: ZyraText.body(size: 13)),
              ),
              if (onRetry != null)
                Flexible(
                  flex: 2,
                  child: TextButton(
                    onPressed: ZyraTapFeedback.onTap(context, onRetry),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Try again',
                      style: ZyraText.body(
                        size: 13,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: ZyraTapFeedback.onTap(context, onDismiss),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: ZyraColors.ink(0.70),
                      size: 16,
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

/// LOCK22 V3 / LOCK8 V8 shared Monogram empty-state layout.
class ZyraEmptyState extends StatelessWidget {
  final IconData icon;

  /// Optional shared artwork for a destination with a canonical custom icon.
  final Widget? iconWidget;

  /// Existing headings remain optional; the layout never invents copy.
  final String? title;

  /// Empty omits the paragraph and its gap, retaining an optional heading.
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final Key? titleKey;
  final Key? ctaKey;
  final bool Function()? canAct;

  const ZyraEmptyState({
    super.key,
    required this.icon,
    this.iconWidget,
    required this.message,
    this.title,
    this.ctaLabel,
    this.onCta,
    this.titleKey,
    this.ctaKey,
    this.canAct,
  });

  Widget _heading(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = ZyraText.heading(
        size: 21,
      ).copyWith(fontWeight: FontWeight.w300, height: 1.2);
      final scaler = MediaQuery.textScalerOf(context);
      var widest = 0.0;
      for (final word in title!.split(RegExp(r'\s+'))) {
        final painter = TextPainter(
          text: TextSpan(
            text: word,
            style: DefaultTextStyle.of(context).style.merge(style),
          ),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        if (painter.width > widest) widest = painter.width;
        painter.dispose();
      }
      return Text(
        title!,
        key: titleKey,
        style: style,
        textAlign: TextAlign.center,
        textScaler: widest > constraints.maxWidth
            ? TextScaler.linear(
                scaler.scale(21) / 21 * constraints.maxWidth / widest * .995,
              )
            : scaler,
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZyraGoldRingMonogram(
              name: '',
              size: 96,
              fontSize: 34,
              ringColor: const Color(0xFFA9792E).withValues(alpha: .65),
              child: IconTheme(
                data: IconThemeData(color: ZyraColors.journeyGold, size: 34),
                child:
                    iconWidget ??
                    Icon(icon, size: 34, color: ZyraColors.journeyGold),
              ),
            ),
            const SizedBox(height: 20),
            if (title != null) _heading(context),
            if (message.isNotEmpty) ...[
              if (title != null) const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 270),
                child: Text(
                  message,
                  style: ZyraText.subtext(size: 12.5).copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (ctaLabel != null) ...[
              const SizedBox(height: 22),
              OutlinedButton(
                key: ctaKey,
                onPressed: ZyraTapFeedback.onTap(
                  context,
                  onCta,
                  canAct: canAct,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  side: BorderSide(
                    color: ZyraColors.journeyGold.withValues(alpha: .65),
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  ctaLabel!,
                  style: ZyraText.button(
                    size: 12.5,
                    color: ZyraColors.journeyGold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: content,
              ),
            )
          : content,
    );
  }
}

/// Fallback for anything not anticipated (Category 5) — never a raw
/// exception or blank screen.
class ZyraUnknownErrorState extends StatelessWidget {
  final VoidCallback? onRetry;
  const ZyraUnknownErrorState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ZyraEmptyState(
      icon: Icons.refresh,
      message:
          "Something didn't quite work. Please try again — and if it keeps happening, let us know.",
      ctaLabel: onRetry != null ? 'Try again' : null,
      onCta: onRetry,
    );
  }
}

/// Small "why is this disabled" hint (Category 4) — used under a
/// disabled Continue button so the user knows what's blocking them
/// rather than silently greying out.
class ZyraDisabledHint extends StatelessWidget {
  final String message;
  const ZyraDisabledHint(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        message,
        style: ZyraText.subtext(size: 12, color: ZyraColors.ink(0.55)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Compatibility API for existing blank-page invitations. The existing tap
/// remains on the same control; its artwork/copy use the one shared layout.
class ZyraAddCircle extends StatelessWidget {
  final VoidCallback onTap;
  final String? label;
  const ZyraAddCircle({super.key, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: InkWell(
      borderRadius: BorderRadius.circular(48),
      onTap: ZyraTapFeedback.onTap(context, onTap),
      child: ZyraEmptyState(icon: Icons.add_outlined, message: label ?? ''),
    ),
  );
}
