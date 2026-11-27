// LOCK14 V4 floating surfaces. Presentation only; no sizing or action authority.
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';

class ZyraFloatingSurface extends StatelessWidget {
  const ZyraFloatingSurface({
    super.key,
    required this.child,
    this.radius = 22,
    this.gold = false,
    this.tabBar = false,
    this.circle = false,
  });
  final Widget child;
  final double radius;
  final bool gold, tabBar, circle;

  static const standardShadows = ZyraColors.cardShadows;
  static const tabShadows = [
    BoxShadow(
      color: Color(0x293E2E1E),
      blurRadius: 23.38,
      offset: Offset(0, 12),
    ),
    BoxShadow(color: Color(0x143E2E1E), blurRadius: 6.06, offset: Offset(0, 3)),
  ];
  static const goldShadows = [
    BoxShadow(
      color: Color(0x40A9792E),
      blurRadius: 14.72,
      offset: Offset(0, 8),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_FloatingOwner>() != null) {
      return child;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
        boxShadow: tabBar
            ? tabShadows
            : gold
            ? goldShadows
            : standardShadows,
      ),
      child: _FloatingOwner(child: child),
    );
  }
}

class _FloatingOwner extends InheritedWidget {
  const _FloatingOwner({required super.child});
  @override
  bool updateShouldNotify(_FloatingOwner oldWidget) => false;
}

// Expand the scroll viewport, then put its child back at the original position.
// Shadows get 24px side clearance without moving locked content.
class ZyraShadowScrollView extends SingleChildScrollView {
  const ZyraShadowScrollView({
    super.key,
    super.child,
    super.padding,
    super.controller,
    super.physics,
    super.primary,
    super.reverse,
    super.scrollDirection,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.dragStartBehavior,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (!box.hasBoundedHeight || !box.hasBoundedWidth) {
        return SingleChildScrollView(
          padding: padding,
          controller: controller,
          physics: physics,
          primary: primary,
          reverse: reverse,
          scrollDirection: scrollDirection,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: Clip.none,
          dragStartBehavior: dragStartBehavior,
          child: child,
        );
      }
      final dx = box.hasBoundedWidth ? 24.0 : 0.0;
      const dy = 0.0;
      final inset = (padding ?? EdgeInsets.zero).resolve(
        Directionality.of(context),
      );
      return OverflowBox(
        alignment: Alignment.center,
        minWidth: box.hasBoundedWidth ? box.maxWidth + dx * 2 : null,
        maxWidth: box.hasBoundedWidth ? box.maxWidth + dx * 2 : null,
        minHeight: box.hasBoundedHeight ? box.maxHeight + dy * 2 : null,
        maxHeight: box.hasBoundedHeight ? box.maxHeight + dy * 2 : null,
        child: SingleChildScrollView(
          padding: inset + EdgeInsets.symmetric(horizontal: dx, vertical: dy),
          controller: controller,
          physics: physics,
          primary: primary,
          reverse: reverse,
          scrollDirection: scrollDirection,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          dragStartBehavior: dragStartBehavior,
          child: child,
        ),
      );
    },
  );
}
