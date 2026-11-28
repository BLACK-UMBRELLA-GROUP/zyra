import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// LOCK14 V9 correction 4b: keep the live brand name whole at Larger Text.
///
/// Normal [Text] still resolves the font, inherited style, accessibility
/// overrides and semantics. Only a wordmark wider than its actual layout
/// constraint gets a smaller scaler; fitting text keeps the original scaler.
class ZyraWordmark extends Text {
  const ZyraWordmark({
    String text = 'ZYRA',
    super.key,
    super.style,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.textScaler,
    super.strutStyle,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
    super.semanticsLabel,
    super.semanticsIdentifier,
    int? maxLines = 1,
  }) : assert(text == 'ZYRA' || text == 'Z Y R A'),
       super(
         text,
         softWrap: false,
         overflow: TextOverflow.visible,
         maxLines: maxLines,
       );

  @override
  Widget build(BuildContext context) => _WordmarkWidthCap(
    scaler: textScaler ?? MediaQuery.textScalerOf(context),
    child: super.build(context),
  );
}

/// The existing splash animation draws the four letters separately. Their
/// individual styles, opacity and offsets stay owned by that animation; this
/// wrapper only caps their combined measured width and gives the name one
/// accessible label.
class ZyraWordmarkGroup extends StatelessWidget {
  const ZyraWordmarkGroup({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ZYRA',
    excludeSemantics: true,
    child: _WordmarkWidthCap(
      scaler: MediaQuery.textScalerOf(context),
      group: true,
      child: child,
    ),
  );
}

class _WordmarkWidthCap extends SingleChildRenderObjectWidget {
  const _WordmarkWidthCap({
    required this.scaler,
    this.group = false,
    required super.child,
  });
  final TextScaler scaler;
  final bool group;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWordmarkWidthCap(scaler, group);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWordmarkWidthCap renderObject,
  ) => renderObject.scaler = scaler;
}

class _RenderWordmarkWidthCap extends RenderProxyBox {
  _RenderWordmarkWidthCap(this._scaler, this.group);
  TextScaler _scaler;
  final bool group;

  set scaler(TextScaler value) {
    if (_scaler == value) return;
    _scaler = value;
    markNeedsLayout();
  }

  List<RenderParagraph> get _paragraphs {
    final result = <RenderParagraph>[];
    void visit(RenderObject object) {
      if (object is RenderParagraph) {
        result.add(object);
      } else {
        object.visitChildren(visit);
      }
    }

    visit(child!);
    assert(group || result.length == 1, 'A wordmark contains one paragraph.');
    assert(result.isNotEmpty);
    return result;
  }

  RenderParagraph get _paragraph => _paragraphs.single;

  TextPainter _painter(RenderParagraph paragraph, TextScaler scaler) =>
      TextPainter(
        text: paragraph.text,
        textAlign: paragraph.textAlign,
        textDirection: paragraph.textDirection,
        textScaler: scaler,
        maxLines: paragraph.maxLines,
        locale: paragraph.locale,
        strutStyle: paragraph.strutStyle,
        textWidthBasis: paragraph.textWidthBasis,
        textHeightBehavior: paragraph.textHeightBehavior,
      );

  TextScaler _fitScaler(List<RenderParagraph> paragraphs, double width) {
    if (!width.isFinite) return _scaler;
    final painters = [for (final p in paragraphs) _painter(p, _scaler)];
    double measured(TextScaler scaler) {
      var total = 0.0;
      for (final painter in painters) {
        painter.textScaler = scaler;
        painter.layout();
        total += painter.maxIntrinsicWidth;
      }
      return total;
    }

    try {
      if (measured(_scaler) <= width) return _scaler;
      // Letter spacing is part of the measured paragraph and is not scaled by
      // Flutter's TextScaler. Measure each candidate rather than divide widths.
      var lower = 0.0;
      var upper = 1.0;
      for (var step = 0; step < 48; step++) {
        final fraction = (lower + upper) / 2;
        if (measured(_WordmarkScaler(_scaler, fraction)) <= width) {
          lower = fraction;
        } else {
          upper = fraction;
        }
      }
      return _WordmarkScaler(_scaler, lower);
    } finally {
      for (final painter in painters) {
        painter.dispose();
      }
    }
  }

  TextPainter _layoutPainter(BoxConstraints constraints) {
    final paragraph = _paragraph;
    return _painter(paragraph, _fitScaler([paragraph], constraints.maxWidth))
      ..layout(minWidth: constraints.minWidth);
  }

  @override
  void performLayout() {
    final paragraphs = _paragraphs;
    final fitted = _fitScaler(paragraphs, constraints.maxWidth);
    invokeLayoutCallback<BoxConstraints>((constraints) {
      for (final paragraph in paragraphs) {
        paragraph.textScaler = fitted;
      }
    });
    super.performLayout();
  }

  // Welcome uses IntrinsicHeight. These independent painters do not change
  // the live paragraph during intrinsic/dry layout or leave a stale cap after
  // an unbounded layout. Fitting sizes retain the normal paragraph metrics.
  @override
  double computeMinIntrinsicWidth(double height) {
    if (group) return _groupSize(double.infinity).width;
    final painter = _painter(_paragraph, _scaler)..layout();
    try {
      return painter.minIntrinsicWidth;
    } finally {
      painter.dispose();
    }
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (group) return _groupSize(double.infinity).width;
    final painter = _painter(_paragraph, _scaler)..layout();
    try {
      return painter.maxIntrinsicWidth;
    } finally {
      painter.dispose();
    }
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (group) return _groupSize(width).height;
    final painter = _layoutPainter(BoxConstraints(maxWidth: width));
    try {
      return painter.height;
    } finally {
      painter.dispose();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (group) return constraints.constrain(_groupSize(constraints.maxWidth));
    final painter = _layoutPainter(constraints);
    try {
      return constraints.constrain(painter.size);
    } finally {
      painter.dispose();
    }
  }

  @override
  double computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    if (group) {
      final paragraphs = _paragraphs;
      final fitted = _fitScaler(paragraphs, constraints.maxWidth);
      final height = _groupSize(constraints.maxWidth).height;
      double? result;
      for (final paragraph in paragraphs) {
        final painter = _painter(paragraph, fitted)..layout();
        try {
          final value =
              (height - painter.height) / 2 +
              painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
          if (result == null || value < result) result = value;
        } finally {
          painter.dispose();
        }
      }
      return result!;
    }
    final painter = _layoutPainter(constraints);
    try {
      return painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    } finally {
      painter.dispose();
    }
  }

  Size _groupSize(double width) {
    final paragraphs = _paragraphs;
    final fitted = _fitScaler(paragraphs, width);
    var totalWidth = 0.0;
    var height = 0.0;
    for (final paragraph in paragraphs) {
      final painter = _painter(paragraph, fitted)..layout();
      try {
        totalWidth += painter.width;
        if (painter.height > height) height = painter.height;
      } finally {
        painter.dispose();
      }
    }
    return Size(totalWidth, height);
  }
}

class _WordmarkScaler extends TextScaler {
  const _WordmarkScaler(this.inherited, this.fraction);
  final TextScaler inherited;
  final double fraction;

  @override
  double scale(double fontSize) => inherited.scale(fontSize) * fraction;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is _WordmarkScaler &&
      other.inherited == inherited &&
      other.fraction == fraction;

  @override
  int get hashCode => Object.hash(inherited, fraction);
}
