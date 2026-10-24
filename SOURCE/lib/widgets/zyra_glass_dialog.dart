// ZYRA's shared centred dialog. The historical Glass API names stay stable
// so all existing notices and confirmations use the same current chrome.
// Founder full-app consistency review, 2026-10-03: opaque plum like the
// approved sheets/toasts, a quiet gold edge, and scroll-safe large text.
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
// Historical 2026-08 glass values (superseded by the current opaque chrome):
//   barrier   black 55%
//   inset     36pt horizontal
//   radius    24
//   blur      sigma 30
//   fill      white 14%
//   border    white 22%, 1px

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// The shared modal card itself, without the `showDialog` call.
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
    return AnimatedPadding(
      padding: MediaQuery.viewInsetsOf(context),
      duration: const Duration(milliseconds: 160),
      child: SafeArea(
        child: Center(
          // OUTSIDE the clip. The old blur/frame nesting trap remains avoided.
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: DecoratedBox(
                  key: const ValueKey('zyra_modal_surface'),
                  decoration: BoxDecoration(
                    color: ZyraColors.modalSheetSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: ZyraColors.journeyGold.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: child,
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

/// Shared opaque chrome. The caller supplies the contents, so a dialog with
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

  /// Destructive choices keep the same modal chrome, but use the app's
  /// restrained destructive colour for the committed action.
  bool destructivePrimary = false,
  TextAlign bodyTextAlign = TextAlign.center,
  Key? primaryKey,
  Key? secondaryKey,

  /// Optional line between body and buttons — used by the Unlock+ prompt to
  /// show both credit balances without turning the dialog into a shop.
  Widget? detail,
}) {
  return showZyraGlassDialog<bool>(
    context: context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: ZyraColors.foreground, size: 30),
        const SizedBox(height: 14),
        Text(
          title,
          style: ZyraText.heading(size: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(body, style: ZyraText.subtext(), textAlign: bodyTextAlign),
        if (detail != null) ...[const SizedBox(height: 14), detail],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: primaryKey,
            style: destructivePrimary
                ? FilledButton.styleFrom(
                    backgroundColor: ZyraColors.destructive,
                    foregroundColor: ZyraColors.onPrimaryAction,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              primaryLabel,
              textAlign: TextAlign.center,
              style: ZyraText.button(
                color: destructivePrimary
                    ? ZyraColors.onPrimaryAction
                    : ZyraColors.foreground,
              ),
            ),
          ),
        ),
        TextButton(
          key: secondaryKey,
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(secondaryLabel, style: ZyraText.subtext()),
        ),
      ],
    ),
  );
}

/// The one-action counterpart to [showZyraGlassChoice]. Information and
/// blocked-state messages use the same opaque plum chrome as confirmations,
/// instead of falling back to an unrelated platform dialog.
Future<void> showZyraGlassNotice({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String body,
  String buttonLabel = 'OK',
  TextAlign bodyTextAlign = TextAlign.center,
}) {
  return showZyraGlassDialog<void>(
    context: context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: ZyraColors.foreground, size: 30),
        const SizedBox(height: 14),
        Text(
          title,
          style: ZyraText.heading(size: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(body, style: ZyraText.subtext(), textAlign: bodyTextAlign),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              buttonLabel,
              textAlign: TextAlign.center,
              style: ZyraText.button(),
            ),
          ),
        ),
      ],
    ),
  );
}
