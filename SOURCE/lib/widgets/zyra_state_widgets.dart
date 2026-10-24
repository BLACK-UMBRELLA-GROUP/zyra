// Shared error / empty / disabled-state widgets — implements APP/UX
// Writing/ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1.md (DR-ZYRA-080).
// Every screen should use these rather than one-off Text() error strings,
// so the warm tone and visual treatment stay consistent app-wide.
//
// 2026-08-23 (Founder, GN Draft 3.2, from phone screenshots): ZyraAddCircle
// added at the end of this file — the Guardians page's large "+" blank-page
// invitation, extracted so every empty Wali surface (Dashboard, Network,
// Seekers) renders the identical pattern instead of a mid-screen paragraph
// with a pill button. Visuals copied 1:1 from seeker_wali_tab.dart's
// _AddGuardianButton(large: true) + its label line.

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

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
                    onPressed: onRetry,
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
                  onTap: onDismiss,
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

/// Full empty-state layout (Category 3) — "nothing here yet", not an
/// error. Centred icon + one line of copy + optional single CTA.
class ZyraEmptyState extends StatelessWidget {
  final IconData icon;

  /// Optional shared artwork for a destination with a canonical custom icon.
  /// All existing Material-icon empty states retain their original treatment.
  final Widget? iconWidget;

  /// Optional heading above the message (2026-08-13). Null on every
  /// existing empty state — those stay exactly as they were, one line
  /// under the icon. Supplied only where the empty state names the
  /// thing that is empty before saying what will fill it.
  final String? title;

  /// Empty omits the paragraph and its gap, retaining an optional heading.
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const ZyraEmptyState({
    super.key,
    required this.icon,
    this.iconWidget,
    required this.message,
    this.title,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ?? Icon(icon, color: ZyraColors.ink(0.35), size: 30),
            SizedBox(height: 14),
            if (title != null)
              Text(
                title!,
                style: ZyraText.heading(size: 15),
                textAlign: TextAlign.center,
              ),
            if (message.isNotEmpty) ...[
              if (title != null) SizedBox(height: 6),
              Text(
                message,
                style: ZyraText.subtext(size: 13.5),
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null) ...[
              SizedBox(height: 16),
              FilledButton(
                // Shared primary geometry, focus/semantics and disabled
                // state, rather than a small purple gesture-only bubble.
                onPressed: onCta,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(ctaLabel!, style: ZyraText.button(size: 13)),
              ),
            ],
          ],
        ),
      ),
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

/// The large "+" invitation for a blank page — one circle, one short
/// line, centred in the usable page. EXTRACTED 2026-08-23 (GN Draft 3.2) from
/// seeker_wali_tab.dart's private _AddGuardianButton so the Wali side's
/// empty surfaces (Dashboard, Network, Seekers) match the Guardians
/// page exactly (Founder: "it should copy picture 1").
///
/// Layout contract at every empty-state call site (Founder follow-up,
/// 2026-08-23): page title remains at the top; this control sits dead-centre
/// in the remaining usable page, above the floating navigation clearance.
class ZyraAddCircle extends StatelessWidget {
  final VoidCallback onTap;
  final String? label;
  const ZyraAddCircle({super.key, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: ZyraColors.frostFill,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ZyraColors.frostBorder, width: 1),
              ),
              child: Icon(Icons.add, size: 34, color: ZyraColors.foreground),
            ),
          ),
        ),
        if (label != null && label!.isNotEmpty) ...[
          SizedBox(height: 14),
          Text(
            label!,
            style: ZyraText.body(size: 15, color: ZyraColors.ink(0.75)),
          ),
        ],
      ],
    );
  }
}
