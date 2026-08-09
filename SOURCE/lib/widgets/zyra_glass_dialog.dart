// ZYRA's centred glass dialog — the one modal shape the app uses.
//
// EXTRACTED 2026-08-04. The exact same fourteen lines of chrome appeared in
// browse_screen twice (daily limit, save/consider cap) and was about to be
// typed a fourth time for the Unlock+ prompt. Every copy carried the same
// values, and every copy would have had to be found and edited the next
// time one of them changed.
//
// ==================== THE TRAP THIS FILE REMEMBERS ====================
//
// Founder, 2026-08-01: "the transparency is ok but look at the edges, it
// looks like two extra transparent frames sticking out."
//
// That was real, and it was a NESTING mistake rather than a colour one.
// `margin` sat on the Container INSIDE the ClipRRect, so the clip and the
// blur described a rectangle 36pt wider on each side than the bordered
// card. The outer rectangle still got blurred and still got rounded
// corners — it just had no tint or border — so it read as a second,
// ghostly frame around the real one.
//
// The fix, preserved here permanently: PADDING GOES OUTSIDE THE ClipRRect.
// Blur, clip and border then all describe exactly the same rectangle.
// Anyone tempted to add `margin:` to the Container below should read this
// paragraph first.
// ======================================================================
//
// Values are the ratified ones, unchanged from the modals this replaces:
//   barrier   black 55%
//   inset     36pt horizontal
//   radius    24
//   blur      sigma 30
//   fill      white 14%
//   border    white 22%, 1px

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/zyra_text.dart';

/// The glass card itself, without the `showDialog` call.
///
/// Exposed separately because browse_screen's two modals already call
/// `showDialog` with their own barrier and their own `dialogContext`
/// closures. Wrapping just the chrome lets them share the look without
/// rewriting either of them into a different shape — which is how a
/// refactor turns into a regression.
class ZyraGlassCard extends StatelessWidget {
  final Widget child;
  const ZyraGlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      // OUTSIDE the ClipRRect. See the trap at the top of this file.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
              ),
              child: Material(type: MaterialType.transparency, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chrome only. The caller supplies the contents, so a dialog with
/// conditional icons or two-branch copy keeps its own logic rather than
/// being forced through a parameter list that cannot express it.
Future<T?> showZyraGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) => ZyraGlassCard(child: builder(dialogContext)),
  );
}

/// The common shape: icon, title, body, one primary action, one quiet
/// decline. Returns true for the primary, false for the decline, null if
/// dismissed by tapping outside.
Future<bool?> showZyraGlassChoice({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String body,
  required String primaryLabel,
  required String secondaryLabel,

  /// Optional line between body and buttons — used by the Unlock+ prompt to
  /// show both credit balances without turning the dialog into a shop.
  Widget? detail,
}) {
  return showZyraGlassDialog<bool>(
    context: context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 14),
        Text(title, style: ZyraText.heading(size: 18), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(body, style: ZyraText.subtext(), textAlign: TextAlign.center),
        if (detail != null) ...[
          const SizedBox(height: 14),
          detail,
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(primaryLabel, textAlign: TextAlign.center),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(secondaryLabel, style: ZyraText.subtext()),
        ),
      ],
    ),
  );
}
