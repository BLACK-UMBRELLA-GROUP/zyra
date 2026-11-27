import 'dart:async';

// LOCK 28: the shared confirmation for a pending member action.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_text.dart';
import 'zyra_tap_feedback.dart';

Future<bool?> showZyraConfirm({
  required BuildContext context,
  required String title,
  required String body,
  required String primaryLabel,
  required String secondaryLabel,
  IconData icon = Icons.info_outline,
  String? personName,
  bool goldPrimary = false,
  Key? sheetKey,
  Key? primaryKey,
  Key? secondaryKey,
  bool Function()? canConfirm,
  Listenable? visibilityListenable,
  bool Function()? isVisible,
  Future<String?> Function()? onCommit,
  String? busyLabel,
  void Function(ModalRoute<bool> route)? onOpening,
  VoidCallback? onConfirmedPop,
  ZyraHapticLevel Function()? hapticLevel,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final origin = ModalRoute.of(context);
  final feedback = context.getInheritedWidgetOfExactType<ZyraTapFeedback>();
  late final ModalBottomSheetRoute<bool> route;
  var chosen = false;
  final state = ValueNotifier<({bool busy, String? error})>((
    busy: false,
    error: null,
  ));
  bool routeCurrent() => route.isCurrent && route.navigator == navigator;

  Future<void> choose(bool confirm) async {
    // Closing an exact, current route is safe even after the subject expires
    // or the source loses its authority to commit the action.
    if (chosen || !routeCurrent()) return;
    chosen = true;
    final accepted =
        confirm &&
        context.mounted &&
        (origin?.isActive ?? true) &&
        (isVisible?.call() ?? true) &&
        (canConfirm?.call() ?? true);
    if (confirm && !accepted) {
      navigator.pop(false);
      return;
    }
    ZyraInteractionStyle.performSelectionTap(() {
      if (accepted && onCommit != null) {
        state.value = (busy: true, error: null);
      } else {
        navigator.pop(accepted);
        if (accepted) onConfirmedPop?.call();
      }
    }, level: hapticLevel?.call() ?? feedback?.level());
    if (!accepted || onCommit == null) return;

    final error = await onCommit();
    if (!route.isActive) return;
    if (error != null) {
      chosen = false;
      state.value = (busy: false, error: error);
      return;
    }
    if (routeCurrent()) {
      navigator.pop(true);
      onConfirmedPop?.call();
    } else {
      navigator.removeRoute(route, true);
    }
  }

  route = ModalBottomSheetRoute<bool>(
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    enableDrag: onCommit == null,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierLabel: secondaryLabel,
    modalBarrierColor: const Color(0x611E1610),
    sheetAnimationStyle:
        MediaQuery.disableAnimationsOf(context) ||
            MediaQuery.accessibleNavigationOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) {
      final sheet = ValueListenableBuilder(
        valueListenable: state,
        builder: (context, status, _) => PopScope(
          canPop: !status.busy,
          child: ZyraConfirmSheet(
            surfaceKey: sheetKey,
            title: title,
            body: body,
            primaryLabel: status.busy
                ? busyLabel ?? primaryLabel
                : primaryLabel,
            secondaryLabel: secondaryLabel,
            error: status.error,
            icon: icon,
            personName: personName,
            goldPrimary: goldPrimary,
            primaryKey: primaryKey,
            secondaryKey: secondaryKey,
            onConfirm: status.busy ? null : () => unawaited(choose(true)),
            onKeep: status.busy ? null : () => unawaited(choose(false)),
            swipeToKeep: onCommit != null,
          ),
        ),
      );
      final visibility = visibilityListenable;
      return visibility == null
          ? sheet
          : ListenableBuilder(
              listenable: visibility,
              child: sheet,
              builder: (context, child) =>
                  isVisible?.call() == false ? const SizedBox.shrink() : child!,
            );
    },
  );
  onOpening?.call(route);
  final pending = navigator.push(route);
  unawaited(route.completed.whenComplete(state.dispose));
  return pending;
}

class ZyraConfirmSheet extends StatelessWidget {
  const ZyraConfirmSheet({
    super.key,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.icon,
    required this.onConfirm,
    required this.onKeep,
    this.error,
    this.swipeToKeep = false,
    this.surfaceKey,
    this.personName,
    this.goldPrimary = false,
    this.primaryKey,
    this.secondaryKey,
  });

  final String title, body, primaryLabel, secondaryLabel;
  final IconData icon;
  final String? personName, error;
  final bool swipeToKeep, goldPrimary;
  final Key? surfaceKey, primaryKey, secondaryKey;
  final VoidCallback? onConfirm, onKeep;

  Widget _dragToKeep(Widget child, VoidCallback? keep) {
    if (keep == null) return child;
    var distance = 0.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onVerticalDragStart: (_) => distance = 0,
      onVerticalDragUpdate: (details) => distance += details.primaryDelta ?? 0,
      onVerticalDragEnd: (details) {
        if (distance >= 48 || (details.primaryVelocity ?? 0) > 700) keep();
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = personName?.trim() ?? '';
    final viewport = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = (viewport.height * .90 - keyboard).clamp(
      0.0,
      double.infinity,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: ZyraIvorySheet.decoration,
          child: _dragToKeep(
            ZyraIvorySheet(
              surfaceKey: surfaceKey ?? const ValueKey('zyra-confirm-sheet'),
              child: SafeArea(
                top: false,
                minimum: ZyraIvorySheet.bottomPadding,
                child: LayoutBuilder(
                  builder: (context, constraints) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The fixed handle must win the dismiss gesture even
                      // when Larger Text makes the body vertically scrollable.
                      if (constraints.maxHeight >= 30)
                        _dragToKeep(
                          const ZyraIvorySheetHandle(
                            handleKey: ValueKey('zyra-confirm-handle'),
                            bottomSpacing: 16,
                          ),
                          onKeep,
                        ),
                      Flexible(
                        child: SingleChildScrollView(
                          primary: false,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ExcludeSemantics(
                                child: Center(
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ZyraColors.journeyGold
                                            .withValues(alpha: .70),
                                      ),
                                    ),
                                    child: name.isEmpty
                                        ? Icon(
                                            icon,
                                            color: ZyraColors.journeyGold,
                                          )
                                        : Text(
                                            name.characters.first.toUpperCase(),
                                            textScaler: TextScaler.noScaling,
                                            style: ZyraText.heading(
                                              size: 24,
                                              color: ZyraColors.journeyGold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Semantics(
                                header: true,
                                sortKey: const OrdinalSortKey(0),
                                child: Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: ZyraText.heading(
                                    size: 21,
                                  ).copyWith(fontWeight: FontWeight.w300),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 290,
                                  ),
                                  child: Text(
                                    body,
                                    textAlign: TextAlign.center,
                                    style: ZyraText.body(
                                      size: 12.5,
                                      color: ZyraColors.secondaryText,
                                    ),
                                  ),
                                ),
                              ),
                              if (error case final message?) ...[
                                const SizedBox(height: 10),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    message,
                                    textAlign: TextAlign.center,
                                    style: ZyraText.body(
                                      size: 12.5,
                                      color: ZyraColors.dangerText,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: ZyraColors.divider,
                              ),
                              TextButton(
                                key: primaryKey,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  foregroundColor: ZyraColors.dangerText,
                                  backgroundColor: goldPrimary
                                      ? ZyraColors.goldTextFill
                                      : null,
                                  shape: goldPrimary
                                      ? const RoundedRectangleBorder()
                                      : null,
                                ),
                                onPressed: onConfirm,
                                child: Text(
                                  primaryLabel,
                                  textAlign: TextAlign.center,
                                  style: ZyraText.body(
                                    size: 15,
                                    color: goldPrimary
                                        ? ZyraColors.espresso
                                        : ZyraColors.dangerText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DecoratedBox(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(999),
                                  ),
                                  boxShadow: ZyraColors.cardShadows,
                                ),
                                child: OutlinedButton(
                                  key: secondaryKey,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    side: BorderSide(
                                      color: ZyraColors.surfaceBorder,
                                    ),
                                    shape: const StadiumBorder(),
                                    backgroundColor: ZyraColors.cardSurface,
                                    foregroundColor: ZyraColors.secondaryText,
                                  ),
                                  onPressed: onKeep,
                                  child: Text(
                                    secondaryLabel,
                                    textAlign: TextAlign.center,
                                    style: ZyraText.body(
                                      size: 15,
                                      color: ZyraColors.secondaryText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            swipeToKeep ? onKeep : null,
          ),
        ),
      ),
    );
  }
}

/// The LOCK 28 ivory surface shared by the confirmation and Developer sheets.
class ZyraIvorySheet extends StatelessWidget {
  const ZyraIvorySheet({super.key, this.surfaceKey, required this.child});

  final Key? surfaceKey;
  final Widget child;

  static const bottomPadding = EdgeInsets.only(bottom: 26);
  static const corners = BorderRadius.vertical(top: Radius.circular(26));

  static const decoration = BoxDecoration(
    borderRadius: corners,
    boxShadow: [
      BoxShadow(
        color: Color(0x2E3E2E1E),
        blurRadius: 30,
        offset: Offset(0, -10),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Material(
    key: surfaceKey,
    color: ZyraColors.confirmSheetSurface,
    borderRadius: corners,
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class ZyraIvorySheetHandle extends StatelessWidget {
  const ZyraIvorySheetHandle({
    super.key,
    this.handleKey,
    this.bottomSpacing = 12,
  });

  final Key? handleKey;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 10, bottom: bottomSpacing),
    child: Center(
      child: Container(
        key: handleKey,
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: ZyraColors.ink(.18),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}
