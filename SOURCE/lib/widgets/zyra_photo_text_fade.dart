// LOCK14 V9 / Q190: the photo and overlay layout stay with their presenters.
// The dark fade follows the actual first text line, including Larger Text.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

enum ZyraPhotoFadeTone {
  seeker(Color(0xFF0A0410), .90, .28),
  guardian(Color(0xFF140E0A), .88, .34);

  const ZyraPhotoFadeTone(this.ink, this.bottomAlpha, this.minimumDarkFraction);
  final Color ink;
  final double bottomAlpha, minimumDarkFraction;
}

@immutable
class ZyraPhotoFadeGeometry {
  const ZyraPhotoFadeGeometry({
    required this.firstTextTop,
    required this.darkTop,
    required this.clearTop,
  });
  final double? firstTextTop;
  final double darkTop, clearTop;
}

/// A normal expanding Stack, with its fade painted immediately after the
/// first (photo) child. No extra layout, frame delay, shadow or text styling.
class ZyraPhotoTextFade extends StatelessWidget {
  const ZyraPhotoTextFade({
    super.key,
    required this.children,
    this.tone = ZyraPhotoFadeTone.seeker,
  });
  final List<Widget> children;
  final ZyraPhotoFadeTone tone;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (_) {
          // The scroll viewport has its own repaint boundary. Repaint the fade
      // as well when its text moves, without rebuilding or relaying out the card.
          final render = context.findRenderObject();
          if (render is RenderZyraPhotoTextFade && render.attached) {
            render.markNeedsPaint();
          }
          return false;
        },
        child: _PhotoTextFadeRender(tone: tone, children: children),
      );
}

class _PhotoTextFadeRender extends MultiChildRenderObjectWidget {
  const _PhotoTextFadeRender({required this.tone, required super.children});
  final ZyraPhotoFadeTone tone;

  @override
  RenderZyraPhotoTextFade createRenderObject(BuildContext context) =>
      RenderZyraPhotoTextFade(tone, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderZyraPhotoTextFade renderObject,
  ) {
    renderObject
      ..tone = tone
      ..textDirection = Directionality.of(context);
  }
}

class RenderZyraPhotoTextFade extends RenderStack {
  RenderZyraPhotoTextFade(this._tone, {required TextDirection textDirection})
    : super(fit: StackFit.expand, textDirection: textDirection);

  ZyraPhotoFadeTone _tone;
  set tone(ZyraPhotoFadeTone value) {
    if (value == _tone) return;
    _tone = value;
    markNeedsPaint();
  }

  ZyraPhotoFadeGeometry get fadeGeometry {
    double? firstTextTop;
    void visit(RenderObject object) {
      if (object is RenderOffstage && object.offstage) return;
      if (object is RenderOpacity && object.opacity == 0) return;
      if (object is RenderAnimatedOpacity && object.opacity.value == 0) return;
      if (object is RenderParagraph) {
        final text = object.text.toPlainText();
        final family = object.text.style?.fontFamily?.toLowerCase() ?? '';
        if (text.trim().isNotEmpty &&
            !family.endsWith('materialicons') &&
            !family.endsWith('cupertinoicons')) {
          final transform = object.getTransformTo(this);
          for (final box in object.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          )) {
            final rect = MatrixUtils.transformRect(transform, box.toRect());
            if (rect.isFinite) {
              firstTextTop = math.min(firstTextTop ?? rect.top, rect.top);
            }
          }
        }
      }
      object.visitChildren((child) {
        if (identical(child.parent, object) && !object.paintsChild(child)) {
          return;
        }
        visit(child);
      });
    }

    // The first child is the image/placeholder, never an overlay label.
    var child = firstChild == null
        ? null
        : (firstChild!.parentData! as StackParentData).nextSibling;
    while (child != null) {
      visit(child);
      child = (child.parentData! as StackParentData).nextSibling;
    }
    final prototypeTop = size.height * (1 - _tone.minimumDarkFraction);
    final darkTop = math
        .min(prototypeTop, (firstTextTop ?? size.height) - 8)
        .clamp(0.0, size.height)
        .toDouble();
    return ZyraPhotoFadeGeometry(
      firstTextTop: firstTextTop,
      darkTop: darkTop,
      // Q190's explicit thirty-percent transition takes precedence over the
      // Seeker prototype CSS's seventy-percent total scrim height.
      clearTop: darkTop - size.height * .30,
    );
  }

  @override
  void paintStack(PaintingContext context, Offset offset) {
    final geometry = fadeGeometry;
    var child = firstChild;
    var photo = true;
    while (child != null) {
      final data = child.parentData! as StackParentData;
      context.paintChild(child, offset + data.offset);
      if (photo && size.height > 0) {
        photo = false;
        final darkStop =
            (geometry.darkTop - geometry.clearTop) /
            (size.height - geometry.clearTop);
        context.canvas.drawRect(
          offset & size,
          Paint()
            ..shader = ui.Gradient.linear(
              offset + Offset(0, geometry.clearTop),
              offset + Offset(0, size.height),
              [
                _tone.ink.withValues(alpha: 0),
                _tone.ink.withValues(alpha: .76),
                _tone.ink.withValues(alpha: _tone.bottomAlpha),
              ],
              [0, darkStop, 1],
            ),
        );
      }
      child = data.nextSibling;
    }
  }
}
