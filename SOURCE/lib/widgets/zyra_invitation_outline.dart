import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';

/// Decorative feedback only. The caller keeps ownership of invitation actions.
class ZyraInvitationOutline extends StatefulWidget {
  const ZyraInvitationOutline({
    super.key,
    required this.sent,
    required this.borderRadius,
  });

  final bool sent;
  final BorderRadius borderRadius;

  @override
  State<ZyraInvitationOutline> createState() => _ZyraInvitationOutlineState();
}

class _ZyraInvitationOutlineState extends State<ZyraInvitationOutline>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    value: widget.sent ? 1 : 0,
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool _mediaQuiet = false;
  bool get _quiet =>
      _mediaQuiet ||
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .reduceMotion;
  bool _visible = false;

  bool get _canAnimate =>
      !_quiet &&
      _visible &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mediaQuiet =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _reconcileVisibility();
  }

  @override
  void didUpdateWidget(ZyraInvitationOutline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sent == oldWidget.sent) return;
    if (!_canAnimate) {
      _ring.value = widget.sent ? 1 : 0;
    } else if (widget.sent) {
      _ring.animateTo(
        1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _ring.animateBack(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
    _updateGlow();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _reconcileVisibility();
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(_reconcileVisibility);
  }

  void _reconcileVisibility() {
    if (!_canAnimate) _ring.value = widget.sent ? 1 : 0;
    _updateGlow();
  }

  void _updateGlow() {
    final shouldBreathe = widget.sent && _canAnimate;
    if (shouldBreathe == _glow.isAnimating) return;
    if (shouldBreathe) {
      _glow.repeat(reverse: true);
    } else {
      _glow.reset();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ring.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ring,
            builder: (context, child) => DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                border: Border.all(
                  color: ZyraColors.journeyGold.withValues(alpha: _ring.value),
                  width: 1.5,
                ),
              ),
              child: child,
            ),
            child: _quiet
                ? null
                : CustomPaint(
                    key: const ValueKey('invitation-inner-glow'),
                    painter: _InvitationInnerGlow(
                      borderRadius: widget.borderRadius,
                      glow: _glow,
                      ring: _ring,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _InvitationInnerGlow extends CustomPainter {
  _InvitationInnerGlow({
    required this.borderRadius,
    required this.glow,
    required this.ring,
  }) : super(repaint: glow);

  final BorderRadius borderRadius;
  final Animation<double> glow;
  final Animation<double> ring;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = .5 * Curves.easeInOut.transform(glow.value) * ring.value;
    if (opacity == 0 || size.shortestSide <= 6) return;
    final edge = borderRadius.toRRect(Offset.zero & size);
    final sigma = ui.Shadow.convertRadiusToSigma(26);
    canvas
      ..save()
      ..clipRRect(edge)
      ..drawDRRect(
        edge.inflate(4 * sigma),
        edge.deflate(3),
        Paint()
          ..color = const Color(0xFFE8C98A).withValues(alpha: opacity)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, sigma),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_InvitationInnerGlow oldDelegate) =>
      borderRadius != oldDelegate.borderRadius ||
      glow != oldDelegate.glow ||
      ring != oldDelegate.ring;
}
