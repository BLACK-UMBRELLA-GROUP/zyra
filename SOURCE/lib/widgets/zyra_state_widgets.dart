// Shared error / empty / disabled-state widgets — implements APP/UX
// Writing/ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1.md (DR-ZYRA-080).
// Every screen should use these rather than one-off Text() error strings,
// so the warm tone and visual treatment stay consistent app-wide.

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
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        message!,
        style: ZyraText.subtext(size: 12, color: ZyraColors.rosePink),
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

  const ZyraErrorBanner({super.key, required this.message, this.onRetry, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: ZyraColors.rosePink.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: ZyraText.body(size: 13))),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text('Try again', style: ZyraText.body(size: 13).copyWith(fontWeight: FontWeight.w500)),
                ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.white70, size: 16),
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
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const ZyraEmptyState({
    super.key,
    required this.icon,
    required this.message,
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
            Icon(icon, color: Colors.white.withValues(alpha: 0.35), size: 30),
            const SizedBox(height: 14),
            Text(message, style: ZyraText.subtext(size: 13.5), textAlign: TextAlign.center),
            if (ctaLabel != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onCta,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: ZyraColors.accentBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ZyraColors.accentBorder, width: 1),
                  ),
                  child: Text(ctaLabel!, style: ZyraText.body(size: 13).copyWith(fontWeight: FontWeight.w500)),
                ),
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
      message: "Something didn't quite work. Please try again — and if it keeps happening, let us know.",
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
        style: ZyraText.subtext(size: 12, color: Colors.white.withValues(alpha: 0.55)),
        textAlign: TextAlign.center,
      ),
    );
  }
}
