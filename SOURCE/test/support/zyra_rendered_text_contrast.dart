// OA-ZYRA-371 / LOCK14 V9: original text metrics, nominal ink and actual
// painted backgrounds. Probe colours establish visibility, never policy ink.
import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_first_tour_overlay.dart';
import 'package:zyra/dev/zyra_one_journey_monogram_presentation.dart';
import 'package:zyra/widgets/zyra_fade_edges.dart';

class ZyraRenderedTextAudit {
  ZyraRenderedTextAudit();
  ZyraRenderedTextAudit.cached(ZyraRenderedTextAudit source) {
    failures.addAll(source.failures);
    diagnosticSamples.addAll(source.diagnosticSamples);
    diagnosticRuns.addAll(source.diagnosticRuns);
    items.addAll(source.items);
    runs = source.runs;
    paintedPixels = source.paintedPixels;
    exemptPixels = source.exemptPixels;
    modalExemptPixels = source.modalExemptPixels;
    initials = source.initials;
    occlusionFringePixels = source.occlusionFringePixels;
    cacheHit = true;
  }
  final failures = <Map<String, Object?>>[];
  final diagnosticSamples = <Map<String, Object?>>[];
  final diagnosticRuns = <Map<String, Object?>>[];
  final items = <Map<String, Object?>>[];
  int runs = 0,
      paintedPixels = 0,
      exemptPixels = 0,
      modalExemptPixels = 0,
      initials = 0,
      occlusionFringePixels = 0;
  bool cacheHit = false;
  int rasterImages = 0;
  Map<String, Object?> toJson() => {
    'runs': runs,
    'painted_pixels': paintedPixels,
    'exempt_pixels': exemptPixels,
    'modal_backdrop_exempt_pixels': modalExemptPixels,
    'initials': initials,
    'geometric_occlusion_aa_pixels': occlusionFringePixels,
    'raster_pixel_ratio': 1,
    'cache_hit': cacheHit,
    'raster_images': rasterImages,
    'real_shadows': true,
    'failures': failures,
    if (diagnosticSamples.isNotEmpty) 'diagnostic_samples': diagnosticSamples,
    if (diagnosticRuns.isNotEmpty) 'diagnostic_runs': diagnosticRuns,
  };
}

// Exact probe equality, including metrics and exemptions, can reuse analysis.
// We never deduplicate on a route name or an ordinary screenshot: a different
// hidden background or paint response must produce a different cache key.
final _auditedPaintResponses = <String, ZyraRenderedTextAudit>{};
var _rasterImages = 0;
const _solidPatchExpansion = 4.0;

class _Run {
  _Run(this.start, this.text, this.style);
  final int start;
  final String text;
  final TextStyle style;
}

List<_Run> _runs(InlineSpan root) {
  final result = <_Run>[];
  var offset = 0;
  void visit(InlineSpan span, TextStyle inherited) {
    if (span is TextSpan) {
      final style = inherited.merge(span.style);
      if (span.text case final text?) {
        result.add(_Run(offset, text, style));
        offset += text.length;
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        visit(child, style);
      }
    } else {
      offset += span.toPlainText().length;
    }
  }

  visit(root, const TextStyle());
  return result;
}

Color _ink(TextStyle style) =>
    style.foreground?.color ?? style.color ?? Colors.black;
bool _iconStyle(TextStyle style) {
  final family = style.fontFamily?.toLowerCase() ?? '';
  return family.endsWith('materialicons') || family.endsWith('cupertinoicons');
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
double _contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

InlineSpan _probe(InlineSpan root, int mode, {int? targetStart}) {
  var offset = 0;
  InlineSpan visit(InlineSpan span, TextStyle inherited) {
    if (span is! TextSpan) {
      offset += span.toPlainText().length;
      return span;
    }
    final style = inherited.merge(span.style);
    final start = offset;
    offset += span.text?.length ?? 0;
    final selected = targetStart == null || start == targetStart;
    final ink = _ink(style);
    final solidInk = mode == 3
        ? Colors.black
        : mode == 4
        ? Colors.white
        : ink.withValues(alpha: 1);
    final foreground = mode < 0
        ? (Paint()
            ..color = Colors.white
            ..shader = ui.Gradient.linear(
              Offset.zero,
              const Offset(1, 0),
              const [Colors.transparent, Colors.transparent],
            ))
        : mode >= 2
        ? (Paint()..color = solidInk)
        : (Paint()
            ..color = Color.from(
              alpha: ink.a,
              red: mode.toDouble(),
              green: mode.toDouble(),
              blue: mode.toDouble(),
            ));
    // An opaque nominal-ink patch retains the real glyph metrics. Dilation
    // covers descenders/AA fringes outside the original line rectangle without
    // introducing stroked-glyph tessellation seams.
    // Later-painted barriers, group alpha and masks still composite normally.
    final replacement = selected
        ? style.copyWith(
            foreground: foreground,
            // Decorations must follow the selected probe too. Retaining an
            // underlined link's original ink in its hidden glyph pass makes
            // that underline its own background and occluding foreground.
            decorationColor: mode < 0
                ? Colors.transparent
                : mode >= 2
                ? solidInk
                : Color.from(
                    alpha: ink.a,
                    red: mode.toDouble(),
                    green: mode.toDouble(),
                    blue: mode.toDouble(),
                  ),
            background: mode >= 2
                ? (Paint()
                    ..color = solidInk
                    ..imageFilter = ui.ImageFilter.dilate(
                      radiusX: _solidPatchExpansion,
                      radiusY: _solidPatchExpansion,
                    ))
                : style.background ??
                      (Paint()
                        ..color = style.backgroundColor ?? Colors.transparent),
            shadows: mode >= 2 ? const [] : style.shadows,
          )
        : style.copyWith(
            foreground: style.foreground ?? (Paint()..color = ink),
            background:
                style.background ??
                (Paint()..color = style.backgroundColor ?? Colors.transparent),
          );
    return TextSpan(
      text: span.text,
      style: replacement,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
      spellOut: span.spellOut,
      children: [
        for (final child in span.children ?? const <InlineSpan>[])
          visit(child, style),
      ],
    );
  }

  return visit(root, const TextStyle());
}

class _Mask {
  _Mask(this.object, this.top, this.bottom);
  final RenderShaderMask object;
  final double top, bottom;
  bool get edge => top > 0 || bottom > 0;
}

class _ModalDim {
  _ModalDim(this.order, this.rect, this.clips);
  final int order;
  final Rect rect;
  final List<({Matrix4 inverse, Object shape})> clips;
  bool contains(Offset point) =>
      rect.contains(point) &&
      clips.every((clip) {
        final local = MatrixUtils.transformPoint(clip.inverse, point);
        return switch (clip.shape) {
          Rect shape => shape.contains(local),
          RRect shape => shape.contains(local),
          Path shape => shape.contains(local),
          _ => false,
        };
      });
  @override
  String toString() =>
      '$order/$rect/${clips.map((clip) => '${clip.inverse}/${clip.shape}')}';
}

class _Node {
  _Node(
    this.object,
    this.original,
    this.opacity,
    this.masks,
    this.initial,
    this.coach,
    this.path,
    this.paintOrder,
  );
  final RenderBox object;
  final InlineSpan original;
  final double opacity;
  final List<_Mask> masks;
  final bool initial, coach;
  final List<String> path;
  final int paintOrder;
  late InlineSpan actual = original;
  InlineSpan? ownedProbe;
  InlineSpan? get current => switch (object) {
    RenderParagraph paragraph => paragraph.text,
    RenderEditable editable => editable.text,
    _ => null,
  };
  List<Object?> get layoutInputs => switch (object) {
    RenderParagraph paragraph => [
      paragraph.textAlign,
      paragraph.textDirection,
      paragraph.softWrap,
      paragraph.overflow,
      paragraph.maxLines,
      paragraph.locale,
      paragraph.strutStyle?.toString(),
      paragraph.textWidthBasis,
      paragraph.textHeightBehavior?.toString(),
    ],
    RenderEditable editable => [
      editable.textAlign,
      editable.textDirection,
      editable.locale,
      editable.strutStyle?.toString(),
      editable.textWidthBasis,
      editable.textHeightBehavior?.toString(),
      editable.maxLines,
      editable.minLines,
      editable.expands,
      editable.forceLine,
      editable.obscureText,
      editable.obscuringCharacter,
      editable.selection,
      editable.offset.hasPixels,
      if (editable.offset.hasPixels) editable.offset.pixels,
    ],
    _ => const [],
  };
  void replace(InlineSpan text) {
    if (!object.attached) return;
    ownedProbe = text;
    _write(text);
  }

  void _write(InlineSpan text) {
    switch (object) {
      case RenderParagraph paragraph:
        paragraph.text = text;
      case RenderEditable editable:
        editable.text = text;
    }
    object.markNeedsPaint();
  }

  void restoreOwned() {
    if (!object.attached) {
      ownedProbe = null;
      return;
    }
    final text = current;
    if (ownedProbe != null && identical(text, ownedProbe)) {
      _write(actual);
    } else if (text != null) {
      // A widget rebuild owns its new span, including its recognizer. Even
      // same-text updates must not be overwritten by a stale captured span.
      actual = text;
    }
    ownedProbe = null;
  }

  List<ui.TextBox> boxes(int start, int end) {
    final selection = TextSelection(baseOffset: start, extentOffset: end);
    return switch (object) {
      RenderParagraph paragraph => paragraph.getBoxesForSelection(selection),
      RenderEditable editable => editable.getBoxesForSelection(selection),
      _ => const [],
    };
  }

  double scale(double size) => switch (object) {
    RenderParagraph paragraph => paragraph.textScaler.scale(size),
    RenderEditable editable => editable.textScaler.scale(size),
    _ => size,
  };
}

class _ChangedProbeScene implements Exception {
  const _ChangedProbeScene(this.reason);
  final String reason;
}

class _SceneIdentity {
  const _SceneIdentity(this.value);
  final Object? value;
  @override
  bool operator ==(Object other) =>
      other is _SceneIdentity && identical(value, other.value);
  @override
  int get hashCode => identityHashCode(value);
  @override
  String toString() => '${value.runtimeType}#${identityHashCode(value)}';
}

bool _sameSceneValue(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameSceneValue(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

String _sceneDifference(Object? a, Object? b, [String path = 'scene']) {
  if (a is List && b is List) {
    if (a.length != b.length) return '$path.length: ${a.length} -> ${b.length}';
    for (var i = 0; i < a.length; i++) {
      if (!_sameSceneValue(a[i], b[i])) {
        return _sceneDifference(a[i], b[i], '$path[$i]');
      }
    }
  }
  return '$path: $a -> $b';
}

Object _pathClipSignature(RenderClipPath object) {
  final clipper = object.clipper;
  // Pinned container.dart:478-496 delegates this exact SDK clipper to the
  // decoration. Exact BoxDecoration has only the three shapes below
  // (box_decoration.dart:223-237); unknown decorations/Paths stay identity-strict.
  if (clipper.runtimeType.toString() == '_DecorationClipper') {
    try {
      final dynamic sdkClipper = clipper;
      final Object? source = sdkClipper.decoration;
      final Object? direction = sdkClipper.textDirection;
      if (source.runtimeType == BoxDecoration && direction is TextDirection) {
        final decoration = source! as BoxDecoration;
        final rect = Offset.zero & object.size;
        return [
          'SDK BoxDecoration clip',
          decoration.shape,
          direction,
          switch (decoration.shape) {
            BoxShape.circle => Rect.fromCircle(
              center: rect.center,
              radius: rect.shortestSide / 2,
            ),
            BoxShape.rectangle =>
              decoration.borderRadius == null
                  ? rect
                  : decoration.borderRadius!.resolve(direction).toRRect(rect),
          },
        ];
      }
    } catch (_) {
      // A future pinned-SDK shape cannot silently become a known clip.
    }
  }
  return _SceneIdentity(clipper);
}

bool _paintsNothingAtZeroAlpha(RenderObject object) => switch (object) {
  RenderOpacity() when object.runtimeType == RenderOpacity =>
    Color.getAlphaFromOpacity(object.opacity) == 0,
  RenderAnimatedOpacity() when object.runtimeType == RenderAnimatedOpacity =>
    Color.getAlphaFromOpacity(object.opacity.value) == 0,
  _ => false,
};

bool _chipSubmitsChild(RenderObject object, RenderObject child) {
  if (object.runtimeType.toString() != '_RenderChip') return true;
  // Pinned Flutter 3.44.2 chip.dart: _paintAvatar / deleteIconShowing.
  // Unknown SDK implementations stay conservative; the label is never skipped.
  try {
    final dynamic chip = object;
    if (identical(child, chip.avatar) &&
        chip.theme.showAvatar == false &&
        chip.avatarDrawerAnimation.isDismissed == true) {
      return false;
    }
    if (identical(child, chip.deleteIcon) && chip.deleteIconShowing == false) {
      return false;
    }
  } catch (_) {
    return true; // Unknown pinned-slot introspection never proves invisibility.
  }
  return true;
}

void _visitPaintedChildren(RenderObject object, RenderObjectVisitor visitor) {
  if (_paintsNothingAtZeroAlpha(object)) return;
  if (object is RenderTransform &&
      object.child != null &&
      object.filterQuality == null) {
    // RenderTransform.paint returns without painting its child for this exact
    // singular-matrix case (e.g. Scaffold's collapsed empty FAB transform).
    final transform = Matrix4.identity();
    object.applyPaintTransform(object.child!, transform);
    final determinant = transform.determinant();
    if (MatrixUtils.getAsTranslation(transform) == null &&
        (determinant == 0 || !determinant.isFinite)) {
      return;
    }
  }
  void child(RenderObject child) {
    // Theater also exposes OverlayPortal children whose actual parent is a
    // different render object. paintsChild requires a real parent/child pair;
    // foreign-parent children stay conservative instead of being discarded.
    if (identical(child.parent, object) &&
        (!object.paintsChild(child) || !_chipSubmitsChild(object, child))) {
      return;
    }
    if (identical(child.parent, object) &&
        child is RenderSliver &&
        child.geometry?.visible == false &&
        (object.runtimeType == RenderViewport ||
            object.runtimeType == RenderShrinkWrappingViewport ||
            object.runtimeType == RenderSliverPadding ||
            (object is RenderSliverEdgeInsetsPadding &&
                object.runtimeType.toString() ==
                    '_RenderSliverFractionalPadding'))) {
      return; // Exact viewport/padding paint admission, including all overflow.
    }
    if (object.runtimeType == RenderSliverToBoxAdapter &&
        (object as RenderSliverToBoxAdapter).geometry?.visible == false) {
      return;
    }
    if (object is RenderSliverMultiBoxAdaptor &&
        const <Type>{
          RenderSliverList,
          RenderSliverGrid,
          RenderSliverFixedExtentList,
          RenderSliverFillViewport,
        }.contains(object.runtimeType) &&
        child is RenderBox &&
        child.hasSize &&
        child.parentData is SliverMultiBoxAdaptorParentData) {
      final offset =
          (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset;
      if (offset != null) {
        // Exact pinned base paint admission, not an approximate paintBounds
        // test: a rejected child is never painted, including its overflow.
        // Unknown subclasses/offsets remain conservative.
        final delta = offset - object.constraints.scrollOffset;
        final extent = switch (object) {
          RenderSliverFixedExtentList() => object.itemExtent,
          RenderSliverFillViewport() => object.itemExtent,
          _ =>
            object.constraints.axis == Axis.horizontal
                ? child.size.width
                : child.size.height,
        };
        if (!(delta < object.constraints.remainingPaintExtent &&
            delta + extent > 0)) {
          return;
        }
      }
    }
    visitor(child);
  }

  if (object.runtimeType.toString() == '_RenderTheater') {
    object.visitChildrenForSemantics(child);
  } else {
    object.visitChildren(child);
  }
}

/// A readback yields to real asynchronous work. Build that work with original
/// spans installed before a render-only probe, matching WidgetsBinding's
/// build-before-layout ordering. The captured visual scene stays immutable;
/// each node separately retains the latest actual interaction-bearing span.
void _verifyMountedImageFrames(WidgetTester tester) {
  for (final element in find.byType(Image, skipOffstage: false).evaluate()) {
    final raw = find.descendant(
      of: find.byElementPredicate(
        (candidate) => identical(candidate, element),
        skipOffstage: false,
      ),
      matching: find.byType(RawImage, skipOffstage: false),
      skipOffstage: false,
    );
    if (raw.evaluate().isEmpty ||
        tester
            .widgetList<RawImage>(raw)
            .every((image) => image.image == null)) {
      throw const _ChangedProbeScene(
        'A mounted image lost first-frame readiness during source preparation',
      );
    }
  }
}

class _ProbeScene {
  _ProbeScene(this.tester, this.boundary) {
    final owner = tester.binding.buildOwner!;
    previousBuildScheduled = owner.onBuildScheduled;
    buildScheduled = () {
      sourceBuildScheduled = true;
      previousBuildScheduled?.call();
    };
    owner.onBuildScheduled = buildScheduled;
  }
  final WidgetTester tester;
  final RenderRepaintBoundary boundary;
  late final VoidCallback? previousBuildScheduled;
  late final VoidCallback buildScheduled;
  bool sourceBuildScheduled = false;
  bool failed = false;
  List<_Node> nodes = [];
  Map<RenderObject, Element> elements = {};
  List<Object?>? capturedSignature;
  String? originalHash;
  final cacheWrites = <String, ZyraRenderedTextAudit>{};
  Set<RenderObject> dirtyAtLastRender = {};

  List<RenderObject> objects() {
    final result = <RenderObject>[];
    void visit(RenderObject object) {
      result.add(object);
      object.visitChildren(visit);
    }

    if (boundary.attached) visit(boundary);
    return result;
  }

  Set<RenderObject> paintedObjects() {
    final result = <RenderObject>{};
    void visit(RenderObject object) {
      if (object is RenderOffstage && object.offstage) return;
      if (_paintsNothingAtZeroAlpha(object)) return;
      result.add(object);
      _visitPaintedChildren(object, visit);
    }

    if (boundary.attached) visit(boundary);
    return result;
  }

  bool get newSourceWorkPending =>
      sourceBuildScheduled ||
      objects().any(
        (object) =>
            (object.debugNeedsLayout || object.debugNeedsPaint) &&
            !dirtyAtLastRender.contains(object),
      ) ||
      nodes.any(
        (node) =>
            node.ownedProbe != null &&
            !identical(node.current, node.ownedProbe),
      );

  bool get sourceWorkPending {
    if (newSourceWorkPending) return true;
    final painted = paintedObjects();
    return dirtyAtLastRender.any(painted.contains);
  }

  List<Element> relevantDirtyNestedScopes() {
    final rootScope = tester.binding.rootElement?.buildScope;
    // This is a build/layout predicate, not paint visibility. Even an
    // unpainted active sibling can share a Sliver's isolated BuildScope.
    return [
      for (final element in tester.allElements)
        if (element.debugIsActive &&
            element.dirty &&
            !identical(element.buildScope, rootScope))
          element,
    ];
  }

  List<Object?> signature([Set<RenderObject>? knownPainted]) {
    if (!boundary.attached) {
      throw const _ChangedProbeScene(
        'The original paint boundary was detached',
      );
    }
    final painted = knownPainted ?? paintedObjects();
    final renderObjects = objects();
    final objectSet = renderObjects.toSet();
    final transforms = <RenderObject, Matrix4>{boundary: Matrix4.identity()};
    Matrix4 transformFor(RenderObject object) => transforms.putIfAbsent(
      object,
      () {
        final parent = object.parent;
        if (parent == null || !objectSet.contains(parent)) {
          // OverlayPortal can expose children through a foreign paint parent.
          return object.getTransformTo(boundary);
        }
        final matrix = Matrix4.copy(transformFor(parent));
        parent.applyPaintTransform(object, matrix); // Same SDK operation order.
        return matrix;
      },
    );
    return [
      for (final object in renderObjects)
        [
          _SceneIdentity(object),
          painted.contains(object),
          if (object is RenderBox && object.hasSize) ...[
            object.size,
            object.constraints,
            transformFor(object).storage.toList(growable: false),
          ],
          if (object is RenderSliver) ...[
            object.geometry?.scrollExtent,
            object.geometry?.paintExtent,
            object.geometry?.maxPaintExtent,
            object.geometry?.layoutExtent,
            object.geometry?.paintOrigin,
            object.geometry?.hitTestExtent,
            object.geometry?.visible,
            object.geometry?.hasVisualOverflow,
            object.geometry?.cacheExtent,
            object.geometry?.scrollOffsetCorrection,
          ],
          if (object is RenderOpacity) object.opacity,
          if (object is RenderAnimatedOpacity) object.opacity.value,
          if (object is RenderShaderMask) ...[
            object.blendMode,
            _SceneIdentity(object.shaderCallback),
          ],
          if (object is RenderClipRect) ...[
            object.clipBehavior,
            if (object.clipBehavior != Clip.none)
              object.clipper?.getClip(object.size) ??
                  (Offset.zero & object.size),
          ],
          if (object is RenderClipRRect) ...[
            object.clipBehavior,
            if (object.clipBehavior != Clip.none)
              object.clipper?.getClip(object.size) ??
                  object.borderRadius
                      .resolve(object.textDirection)
                      .toRRect(Offset.zero & object.size),
          ],
          if (object is RenderClipPath) ...[
            object.clipBehavior,
            if (object.clipBehavior != Clip.none) _pathClipSignature(object),
          ],
        ],
      for (final node in nodes) ...[
        [
          _SceneIdentity(node.object),
          node.object.attached,
          if (node.current != null)
            [
              for (final run in _runs(node.current!))
                [run.start, run.text, run.style.getTextStyle().toString()],
            ],
          node.object is RenderParagraph
              ? (node.object as RenderParagraph).textScaler.toString()
              : (node.object as RenderEditable).textScaler.toString(),
          // Source layout inputs are immutable and exact. Selection boxes can
          // change by a native float-cache ULP after a paint-only span update
          // even when these inputs and the actual render geometry are equal.
          node.layoutInputs,
        ],
      ],
      _ownerGraph(),
      for (final state in tester.stateList<ScrollableState>(
        find.byType(Scrollable),
      ))
        [
          _SceneIdentity(state),
          _SceneIdentity(state.position),
          state.position.axisDirection,
          if (state.position.hasContentDimensions) ...[
            state.position.pixels,
            state.position.minScrollExtent,
            state.position.maxScrollExtent,
            state.position.viewportDimension,
          ],
        ],
    ];
  }

  List<Object?> _ownerGraph() {
    final owners = <Object?>[];
    final visited = <Element>{};
    for (final node in nodes) {
      Element? current = elements[node.object];
      if (!node.object.attached || current?.mounted != true) {
        throw const _ChangedProbeScene(
          'An original paragraph owner was detached',
        );
      }
      owners.add([_SceneIdentity(node.object), _SceneIdentity(current)]);
      while (current != null && visited.add(current)) {
        Element? parent;
        current.visitAncestorElements((ancestor) {
          parent = ancestor;
          return false;
        });
        owners.add([
          _SceneIdentity(current),
          current.widget.runtimeType,
          current.widget.key,
          _SceneIdentity(parent),
        ]);
        current = parent;
      }
    }
    // Do not create inherited-widget dependencies while observing a scene.
    // Navigator ownership is already exact in this retained ancestor chain
    // and the complete render-object tree (including ModalScope/Overlay).
    return owners;
  }

  void capture(List<_Node> value, Map<RenderObject, Element> sourceElements) {
    nodes = value;
    elements = sourceElements;
    capturedSignature = signature();
    noteRendered();
  }

  void noteRendered() {
    // Retained unpainted Navigator transforms can remain dirty after a full
    // flush. New dirty work is distinct from those unchanged baseline flags.
    // Visible persistent dirtiness still requires an original-raster check.
    dirtyAtLastRender = {
      for (final object in objects())
        if (object.debugNeedsLayout || object.debugNeedsPaint) object,
    };
  }

  void _restoreAndBuildRoot() {
    for (final node in nodes) {
      node.restoreOwned();
    }
    final owner = tester.binding.buildOwner!;
    final root = tester.binding.rootElement;
    if (root != null) owner.buildScope(root);
  }

  void _renderOriginal() {
    final owner = tester.binding.buildOwner!;
    _paint(tester);
    noteRendered();
    owner.finalizeTree();
    final error = tester.takeException();
    expect(
      error,
      isNull,
      reason: 'Probe frame must not swallow Flutter errors',
    );
    sourceBuildScheduled = false;
    for (final node in nodes) {
      if (node.object.attached && node.current != null) {
        node.actual = node.current!;
      }
    }
  }

  Future<bool> prepare({
    bool validate = true,
    Future<void> Function()? prepareBeforeCapture,
    VoidCallback? verifyBeforeCapture,
    VoidCallback? renderAction,
  }) async {
    var sourceWork = sourceWorkPending;
    _restoreAndBuildRoot();
    // A root build can itself dirty an isolated descendant scope. Inspect
    // after that build, before any manual layout can enter a narrower Sliver.
    if (relevantDirtyNestedScopes().isNotEmpty) {
      sourceWork = true;
      // Exactly one zero-duration public frame runs LayoutBuilder's deferred
      // transient callback. Actual spans, never probes, are installed here.
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'The public source frame must preserve Flutter errors',
      );
      _restoreAndBuildRoot();
      if (relevantDirtyNestedScopes().isNotEmpty) {
        failed = true;
        throw const _ChangedProbeScene(
          'A nested source build scope remained unstable after one public frame',
        );
      }
    }
    if (prepareBeforeCapture != null) {
      // Wait once after initial source-frame settlement. A notifier may arrive
      // during this await, so prepare its real source before the final check.
      await prepareBeforeCapture();
      sourceWork = true;
      _restoreAndBuildRoot();
      if (relevantDirtyNestedScopes().isNotEmpty) {
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason:
              'The post-readiness source frame must preserve Flutter errors',
        );
        _restoreAndBuildRoot();
        if (relevantDirtyNestedScopes().isNotEmpty) {
          failed = true;
          throw const _ChangedProbeScene(
            'Source work remained unstable after post-readiness preparation',
          );
        }
      }
    }
    _renderOriginal();
    if (prepareBeforeCapture != null) {
      // Layout can mount another lazy image. Check after final layout/paint
      // and finalization, without a second wait or any raster capture.
      _verifyMountedImageFrames(tester);
      verifyBeforeCapture?.call();
    }
    if (failed) {
      renderAction?.call();
      return sourceWork;
    }
    final painted = paintedObjects();
    final ambiguous = dirtyAtLastRender.where(painted.contains).toList();
    if (ambiguous.isNotEmpty) {
      failed = true;
      final ancestry = <String>[];
      for (
        RenderObject? current = ambiguous.first;
        current != null && ancestry.length < 24;
        current = current.parent
      ) {
        ancestry.add(
          '${current.runtimeType}'
          '${current is RenderOpacity ? ':${current.opacity}' : ''}'
          '${current is RenderAnimatedOpacity ? ':${current.opacity.value}' : ''}',
        );
      }
      throw _ChangedProbeScene(
        'Visible paint remained persistently dirty after rendering; no stable scene proof: ${ambiguous.take(8).map((object) => object.runtimeType)}; ${ancestry.join(' <- ')}',
      );
    }
    if (!validate || capturedSignature == null) {
      renderAction?.call();
      return sourceWork;
    }
    final currentSignature = signature(painted);
    if (!_sameSceneValue(currentSignature, capturedSignature)) {
      failed = true;
      throw _ChangedProbeScene(
        'Original text, owner, geometry or effect changed during pixel readback; ${_sceneDifference(capturedSignature, currentSignature)}',
      );
    }
    if (sourceWork && originalHash != null) {
      final actual = await _pixels(tester, boundary);
      if (newSourceWorkPending ||
          relevantDirtyNestedScopes().isNotEmpty ||
          sha256.convert(actual).toString() != originalHash) {
        failed = true;
        throw _ChangedProbeScene(
          'Original painted scene changed or remained unstable during pixel readback; '
          'build=$sourceBuildScheduled; dirty='
          '${objects().where((object) => object.debugNeedsLayout || object.debugNeedsPaint).take(8).map((object) => object.runtimeType)}; '
          'same_pixels=${sha256.convert(actual).toString() == originalHash}',
        );
      }
    }
    // Apply and render in this same synchronous continuation, after the last
    // readback await and stability check. Awaiting prepare in the caller then
    // rendering would reopen a native-notifier/build-scope window.
    renderAction?.call();
    return sourceWork;
  }

  void close() {
    final owner = tester.binding.buildOwner!;
    if (identical(owner.onBuildScheduled, buildScheduled)) {
      owner.onBuildScheduled = previousBuildScheduled;
    }
  }
}

void _paint(WidgetTester tester) {
  final owner = tester.binding.rootPipelineOwner;
  owner.flushLayout();
  owner.flushCompositingBits();
  owner.flushPaint();
  expect(
    tester.takeException(),
    isNull,
    reason: 'Every original/probe render must preserve Flutter errors',
  );
}

void _repaint(RenderObject object) {
  object.markNeedsPaint();
  object.visitChildren(_repaint);
}

Future<Uint8List> _pixels(
  WidgetTester tester,
  RenderRepaintBoundary boundary,
) async {
  Uint8List? result;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      result = Uint8List.fromList(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
  _rasterImages++;
  return result!;
}

Future<List<Uint8List>> _pictures(
  WidgetTester tester,
  RenderRepaintBoundary boundary,
  List<_Node> nodes, {
  required _ProbeScene scene,
  int? targetStart,
  List<int> modes = const [-1, 0, 1, 2, 3, 4],
}) async {
  final pictures = <Uint8List>[];
  try {
    for (final mode in modes) {
      await scene.prepare(
        renderAction: () {
          for (final node in nodes) {
            node.replace(_probe(node.actual, mode, targetStart: targetStart));
          }
          _paint(tester);
          scene.noteRendered();
        },
      );
      pictures.add(await _pixels(tester, boundary));
    }
  } finally {
    await scene.prepare();
  }
  return pictures;
}

/// Reads only LOCKed exemptions. Q192 requires an actual painted modal dim
/// above the text; neither a route flag nor BlockSemantics alone exempts it.
Future<ZyraRenderedTextAudit> auditZyraRenderedText(
  WidgetTester tester,
  RenderRepaintBoundary boundary, {
  List<Offset> diagnosticPoints = const [],
  bool collectRunDiagnostics = false,
  bool collectItems = false,
  Future<void> Function()? prepareBeforeCapture,
  VoidCallback? verifyBeforeCapture,
}) async {
  final previousShadows = debugDisableShadows;
  final previousImages = _rasterImages;
  final scene = _ProbeScene(tester, boundary);
  ZyraRenderedTextAudit? result;
  debugDisableShadows = false;
  try {
    await scene.prepare(
      validate: false,
      prepareBeforeCapture: prepareBeforeCapture,
      verifyBeforeCapture: verifyBeforeCapture,
      renderAction: () {
        _repaint(boundary);
        _paint(tester);
        scene.noteRendered();
      },
    );
    result = await _audit(
      tester,
      boundary,
      diagnosticPoints,
      collectRunDiagnostics,
      collectItems,
      scene,
    );
  } on _ChangedProbeScene catch (error) {
    scene.failed = true;
    result = ZyraRenderedTextAudit()
      ..failures.add({'coverage_error': error.reason});
  } finally {
    try {
      await scene.prepare();
    } on _ChangedProbeScene catch (error) {
      scene.failed = true;
      result = ZyraRenderedTextAudit()
        ..failures.add({'coverage_error': error.reason});
    } finally {
      try {
        final lateWork = scene.newSourceWorkPending;
        debugDisableShadows = previousShadows;
        if (boundary.attached) {
          final cleanupSourceWork = await scene.prepare(
            validate: false,
            renderAction: () {
              _repaint(boundary);
              _paint(tester);
              scene.noteRendered();
            },
          );
          if (!scene.failed &&
              scene.capturedSignature != null &&
              (lateWork ||
                  cleanupSourceWork ||
                  scene.newSourceWorkPending ||
                  scene.relevantDirtyNestedScopes().isNotEmpty ||
                  !_sameSceneValue(
                    scene.signature(),
                    scene.capturedSignature,
                  ))) {
            scene.failed = true;
            result = ZyraRenderedTextAudit()
              ..failures.add({
                'coverage_error':
                    'Source work arrived during final probe cleanup',
              });
          }
        }
      } on _ChangedProbeScene catch (error) {
        scene.failed = true;
        result = ZyraRenderedTextAudit()
          ..failures.add({'coverage_error': error.reason});
      } finally {
        scene.close();
      }
    }
  }
  if (!scene.failed) _auditedPaintResponses.addAll(scene.cacheWrites);
  result!.rasterImages = _rasterImages - previousImages;
  return result;
}

Future<ZyraRenderedTextAudit> _audit(
  WidgetTester tester,
  RenderRepaintBoundary boundary,
  List<Offset> diagnosticPoints,
  bool collectRunDiagnostics,
  bool collectItems,
  _ProbeScene scene,
) async {
  final result = ZyraRenderedTextAudit();
  final elements = <RenderObject, Element>{};
  final modalBarrierRoots = <RenderObject, ModalBarrier>{};
  for (final element in tester.allElements) {
    if (element is RenderObjectElement) {
      elements[element.renderObject] = element;
    }
    final widget = element.widget;
    if (widget is ModalBarrier &&
        widget.color != null &&
        (widget.color!.toARGB32() >> 24) > 0) {
      final object = element.findRenderObject();
      if (object != null) modalBarrierRoots[object] = widget;
    }
  }
  final masks = <RenderShaderMask, _Mask>{};
  _Mask maskFor(RenderShaderMask object) => masks.putIfAbsent(object, () {
    final element = elements[object];
    if (element?.widget.key ==
        const ValueKey('guardian-seeker-page-bottom-fade')) {
      return _Mask(object, 0, 26);
    }
    ZyraFadeEdges? fade;
    // Only the ShaderMask directly produced by this wrapper is an edge fade.
    // A different nested mask does not inherit that exemption.
    element?.visitAncestorElements((ancestor) {
      if (ancestor.widget is ShaderMask) return false;
      if (ancestor.widget is ZyraFadeEdges) {
        fade = ancestor.widget as ZyraFadeEdges;
        return false;
      }
      return true;
    });
    return _Mask(object, fade?.top ?? 0, fade?.bottom ?? 0);
  });
  final nodes = <_Node>[];
  final modalDims = <_ModalDim>[];
  final footerFades = <({RenderObject owner, _ModalDim region})>[];
  var paintOrder = 0;
  void visit(RenderObject object, double opacity, List<_Mask> effects) {
    if (object is RenderOffstage && object.offstage) return;
    if (object is RenderOpacity) opacity *= object.opacity;
    if (object is RenderAnimatedOpacity) opacity *= object.opacity.value;
    if (opacity == 0) return;
    final order = paintOrder++;
    final footerFade =
        object is RenderCustomPaint &&
        elements[object]?.widget.key ==
            const ValueKey('compatibility-editor-scroll-edge-fade');
    if ((modalBarrierRoots.containsKey(object) || footerFade) &&
        object is RenderBox &&
        object.hasSize) {
      final clips = <({Matrix4 inverse, Object shape})>[];
      var unsupportedClip = false;
      for (
        RenderObject? ancestor = object;
        ancestor != null && ancestor != boundary;
        ancestor = ancestor.parent
      ) {
        if (ancestor is! RenderBox || !ancestor.hasSize) continue;
        Object? shape;
        if (ancestor is RenderClipRect && ancestor.clipBehavior != Clip.none) {
          shape =
              ancestor.clipper?.getClip(ancestor.size) ??
              (Offset.zero & ancestor.size);
        } else if (ancestor is RenderClipRRect &&
            ancestor.clipBehavior != Clip.none) {
          shape =
              ancestor.clipper?.getClip(ancestor.size) ??
              ancestor.borderRadius
                  .resolve(ancestor.textDirection)
                  .toRRect(Offset.zero & ancestor.size);
        } else if (ancestor is RenderClipOval &&
            ancestor.clipBehavior != Clip.none) {
          shape = Path()
            ..addOval(
              ancestor.clipper?.getClip(ancestor.size) ??
                  (Offset.zero & ancestor.size),
            );
        } else if (ancestor is RenderClipPath &&
            ancestor.clipBehavior != Clip.none) {
          shape =
              ancestor.clipper?.getClip(ancestor.size) ??
              (Path()..addRect(Offset.zero & ancestor.size));
        } else if (ancestor is RenderAbstractViewport) {
          shape = Offset.zero & ancestor.size;
        } else if ((ancestor is RenderPhysicalModel &&
                ancestor.clipBehavior != Clip.none) ||
            (ancestor is RenderPhysicalShape &&
                ancestor.clipBehavior != Clip.none)) {
          unsupportedClip = true;
        }
        if (shape != null) {
          clips.add((
            inverse: Matrix4.inverted(ancestor.getTransformTo(boundary)),
            shape: shape,
          ));
        }
      }
      if (unsupportedClip) {
        result.failures.add({
          'coverage_error':
              'Unsupported physical clipping around a dim/fade; no exemption granted',
        });
      } else {
        final region = _ModalDim(
          order,
          MatrixUtils.transformRect(
            object.getTransformTo(boundary),
            Rect.fromLTWH(
              0,
              0,
              object.size.width,
              object.size.height + (footerFade ? 64 : 0),
            ),
          ),
          clips,
        );
        if (footerFade) {
          // _EditorScaffold stacks its scrolling content before _BottomSave.
          // The actual painter extends exactly 64pt below its footer box.
          // Keep its foreground descendants and unrelated scrolling strict.
          RenderObject? owner = object.parent;
          while (owner != null && owner is! RenderStack && owner != boundary) {
            owner = owner.parent;
          }
          if (owner is RenderStack) {
            footerFades.add((owner: owner, region: region));
          } else {
            result.failures.add({
              'coverage_error': 'Known editor footer fade has no owning Stack',
            });
          }
        } else {
          modalDims.add(region);
        }
      }
    }
    if (object is RenderShaderMask) effects = [...effects, maskFor(object)];
    if (object is RenderParagraph || object is RenderEditable) {
      final box = object as RenderBox;
      if (box.hasSize) {
        final span = object is RenderParagraph
            ? object.text
            : (object as RenderEditable).text;
        if (span != null && span.toPlainText().trim().isNotEmpty) {
          var icon = false, avatar = false, artwork = false, coach = false;
          final path = <String>[];
          elements[object]?.visitAncestorElements((element) {
            final name = element.widget.runtimeType.toString();
            path.add(name);
            icon |= element.widget is Icon;
            avatar |=
                name.contains('Avatar') ||
                name.contains('Monogram') ||
                name == '_Monogram';
            if (element.widget case ZyraGoldRingMonogram(:final child)) {
              artwork |= child != null;
            }
            final key = element.widget.key;
            if (key is ValueKey) {
              avatar |=
                  key.value.toString().contains('avatar') ||
                  key.value.toString().contains('monogram');
            }
            coach |= element.widget is ZyraFirstTourOverlay;
            return true;
          });
          final plain = span.toPlainText().trim();
          if (!icon) {
            nodes.add(
              _Node(
                box,
                span,
                opacity,
                effects,
                avatar &&
                    !artwork &&
                    RegExp(r'^\p{L}{1,2}$', unicode: true).hasMatch(plain),
                coach,
                path,
                order,
              ),
            );
          }
        }
      }
    }
    _visitPaintedChildren(object, (child) => visit(child, opacity, effects));
  }

  visit(boundary, 1, const []);
  scene.capture(nodes, elements);
  if (nodes.isEmpty) return result;

  final tour = tester
      .widgetList<ZyraFirstTourOverlay>(find.byType(ZyraFirstTourOverlay))
      .firstOrNull;
  final holes = <RRect>[];
  if (tour != null) {
    Rect? rect(String key) {
      final finder = find.byKey(ValueKey(key));
      if (finder.evaluate().isEmpty) return null;
      final box = tester.renderObject<RenderBox>(finder);
      return MatrixUtils.transformRect(
        box.getTransformTo(boundary),
        Offset.zero & box.size,
      );
    }

    final target = rect('first_tour_target'), tab = rect('first_tour_tab');
    if (target != null) {
      holes.add(
        RRect.fromRectAndRadius(
          target,
          Radius.circular(target == tab ? target.shortestSide / 2 : 22),
        ),
      );
      if (tab != null && target != tab) {
        holes.add(
          RRect.fromRectAndRadius(tab, Radius.circular(tab.shortestSide / 2)),
        );
      }
    }
  }
  String? exemption(_Node node, Offset point) {
    if (modalDims.any(
      (dim) => dim.order > node.paintOrder && dim.contains(point),
    )) {
      return 'ordinary_modal_dim_backdrop';
    }
    if (tour != null &&
        !node.coach &&
        !holes.any((hole) => hole.contains(point))) {
      return 'walkthrough_dim_backdrop';
    }
    if (node.path.contains('Scrollable')) {
      for (final fade in footerFades) {
        if (fade.region.order <= node.paintOrder ||
            !fade.region.contains(point)) {
          continue;
        }
        for (
          RenderObject? parent = node.object.parent;
          parent != null && parent != boundary;
          parent = parent.parent
        ) {
          if (identical(parent, fade.owner)) return 'scroll_edge_fade_band';
        }
      }
    }
    for (final mask in node.masks) {
      if (!mask.edge) continue;
      final local = MatrixUtils.transformPoint(
        Matrix4.inverted(mask.object.getTransformTo(boundary)),
        point,
      );
      final height = mask.object.size.height;
      if ((mask.top > 0 && local.dy < math.min(mask.top, height / 2)) ||
          (mask.bottom > 0 &&
              local.dy >= height - math.min(mask.bottom, height / 2))) {
        return 'scroll_edge_fade_band';
      }
    }
    return null;
  }

  final bounds = <_Node, Rect>{};
  final effectBounds = <_Node, Rect>{};
  for (final node in nodes) {
    Rect? bound;
    final transform = node.object.getTransformTo(boundary);
    for (final box in node.boxes(0, node.original.toPlainText().length)) {
      final r = MatrixUtils.transformRect(transform, box.toRect());
      bound = bound == null ? r : bound.expandToInclude(r);
    }
    bounds[node] = bound ?? Rect.zero;
    var effect = bounds[node]!.inflate(_solidPatchExpansion + 1);
    for (final run in _runs(node.original)) {
      for (final shadow in run.style.shadows ?? const <Shadow>[]) {
        effect = effect.expandToInclude(
          bounds[node]!.shift(shadow.offset).inflate(shadow.blurRadius * 3 + 2),
        );
      }
    }
    effectBounds[node] = effect;
  }
  final originalPixels = await _pixels(tester, boundary);
  scene.originalHash = sha256.convert(originalPixels).toString();
  final prefix = await _pictures(
    tester,
    boundary,
    nodes,
    scene: scene,
    modes: const [-1, 0, 1],
  );
  final responseKey = sha256.convert([
    ...sha256.convert(originalPixels).bytes,
    for (final pixels in prefix) ...sha256.convert(pixels).bytes,
    ...sha256
        .convert(
          utf8.encode(
            [
              '${boundary.size}|$holes|${tour != null}|$modalDims|${footerFades.map((fade) => '${fade.owner}/${fade.region}')}|$diagnosticPoints|$collectRunDiagnostics|$collectItems|',
              for (final node in nodes)
                '${_runs(node.original).map((run) => '${run.start}/${run.text}/${run.style}/${run.style.foreground?.shader != null}/${run.style.foreground?.colorFilter != null}/${run.style.foreground?.blendMode}/${run.style.foreground?.style}/${run.style.foreground?.maskFilter}/${run.style.foreground?.imageFilter}')}|${node.boxes(0, node.original.toPlainText().length).map((box) => box.toRect())}|${node.object.getTransformTo(boundary)}|${node.opacity}|${node.initial}|${node.coach}|${node.paintOrder}|${node.path}|${node.masks.map((m) => '${m.object.blendMode}/${m.top}/${m.bottom}')}',
            ].join(),
          ),
        )
        .bytes,
  ]).toString();
  if (_auditedPaintResponses[responseKey] case final previous?) {
    return ZyraRenderedTextAudit.cached(previous);
  }
  final global = [
    ...prefix,
    ...await _pictures(
      tester,
      boundary,
      nodes,
      scene: scene,
      modes: const [2, 3, 4],
    ),
  ];
  final width = boundary.size.width.ceil(),
      height = boundary.size.height.ceil();
  for (final node in nodes) {
    final overlap = nodes.any(
      (other) =>
          !identical(node, other) &&
          bounds[node]!.overlaps(effectBounds[other]!),
    );
    final nodePictures = overlap
        ? await _pictures(tester, boundary, [node], scene: scene)
        : global;
    final transform = node.object.getTransformTo(boundary);
    final visible = <Offset>[];
    final runs = _runs(node.original);
    final separateLeaves = runs.where((run) => run.text.isNotEmpty).length > 1;
    for (final run in runs) {
      if (run.text.trim().isEmpty || _iconStyle(run.style)) continue;
      final pictures = separateLeaves
          ? await _pictures(
              tester,
              boundary,
              [node],
              scene: scene,
              targetStart: run.start,
            )
          : nodePictures;
      final background = pictures[0],
          black = pictures[1],
          white = pictures[2],
          solid = pictures[3];
      final solidBlack = pictures[4], solidWhite = pictures[5];
      int transmission(int x, int y) {
        final index = (y * width + x) * 4;
        return math.max(
          (solidWhite[index] - solidBlack[index]).abs(),
          math.max(
            (solidWhite[index + 1] - solidBlack[index + 1]).abs(),
            (solidWhite[index + 2] - solidBlack[index + 2]).abs(),
          ),
        );
      }

      bool opaqueOcclusionEdge(int x, int y) {
        // Full-patch probes establish transmission without glyph AA. Only
        // the single raster-pixel edge beside independently opaque paint is
        // geometric occlusion. Faint uniform paint and generic shader fades
        // are never removed by a visibility threshold.
        if (node.masks.any((mask) => !mask.edge)) return false;
        if (transmission(x, y) >= 255) return false;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx, ny = y + dy;
            if ((dx == 0 && dy == 0) ||
                nx < 0 ||
                ny < 0 ||
                nx >= width ||
                ny >= height) {
              continue;
            }
            if (transmission(nx, ny) == 0) return true;
          }
        }
        return false;
      }

      final ink = _ink(run.style);
      final previousNamedInk = switch (ink.toARGB32()) {
        0xff4f443a => const Color(0xff6e6257),
        0xff5c4319 => const Color(0xff845f24),
        _ => null,
      };
      var previousNamedWorst = double.infinity;
      Map<String, Object?>? previousNamedSample;
      var unsupported =
          node.masks.any((mask) => mask.object.blendMode != BlendMode.dstIn) ||
          run.style.foreground?.shader != null ||
          run.style.foreground?.colorFilter != null ||
          (run.style.foreground != null &&
              (run.style.foreground!.blendMode != BlendMode.srcOver ||
                  run.style.foreground!.style != PaintingStyle.fill ||
                  run.style.foreground!.maskFilter != null ||
                  run.style.foreground!.imageFilter != null));
      elements[node.object]?.visitAncestorElements((element) {
        unsupported |= element.widget is ColorFiltered;
        return true;
      });
      var worst = double.infinity;
      var pixels = 0;
      var potentialUnexemptPixels = false;
      Map<String, Object?>? nonOpaqueSample;
      Map<String, Object?>? sample;
      // Partial ligatures and combining-mark leaves may have no independent
      // selection box. The isolated leaf-only mask locates its actual paint
      // inside the original paragraph line boxes, without borrowing another
      // leaf's glyph or changing UTF16 boundaries.
      final boxes = separateLeaves
          ? node.boxes(0, node.original.toPlainText().length)
          : node.boxes(run.start, run.start + run.text.length);
      for (final box in boxes) {
        final rect = MatrixUtils.transformRect(
          transform,
          box.toRect(),
        ).intersect(Offset.zero & boundary.size);
        for (
          var y = math.max(0, rect.top.floor());
          y < math.min(height, rect.bottom.ceil());
          y++
        ) {
          for (
            var x = math.max(0, rect.left.floor());
            x < math.min(width, rect.right.ceil());
            x++
          ) {
            final p = (y * width + x) * 4;
            final point = Offset(x + .5, y + .5);
            final reason = exemption(node, point);
            potentialUnexemptPixels |= reason == null;
            if (white[p] == black[p] &&
                white[p + 1] == black[p + 1] &&
                white[p + 2] == black[p + 2]) {
              continue;
            }
            if (reason != null) {
              result.exemptPixels++;
              if (reason == 'ordinary_modal_dim_backdrop') {
                result.modalExemptPixels++;
              }
              continue;
            }
            if (opaqueOcclusionEdge(x, y)) {
              result.occlusionFringePixels++;
              continue;
            }
            if (background[p + 3] != 255 || solid[p + 3] != 255) {
              nonOpaqueSample ??= {
                'x': x,
                'y': y,
                'background_alpha': background[p + 3],
                'original_alpha': originalPixels[p + 3],
                'solid_alpha': solid[p + 3],
                'premultiplied_background_rgb': [
                  background[p],
                  background[p + 1],
                  background[p + 2],
                ],
              };
              continue;
            }
            final bg = Color.fromARGB(
              255,
              background[p],
              background[p + 1],
              background[p + 2],
            );
            // Alpha interpolation is AFTER the whole real paint pipeline.
            // This keeps later translucent siblings, masks and shadows in the
            // nominal foreground instead of repainting source ink above them.
            int channel(int c) =>
                (solid[p + c] * ink.a + background[p + c] * (1 - ink.a))
                    .round();
            final foreground = Color.fromARGB(
              255,
              channel(0),
              channel(1),
              channel(2),
            );
            if (diagnosticPoints.any(
              (point) => point.dx.floor() == x && point.dy.floor() == y,
            )) {
              result.diagnosticSamples.add({
                'text': run.text,
                'x': x,
                'y': y,
                'background': _hex(bg),
                'nominal_ink': _hex(foreground),
                'source_ink': _hex(ink),
                'background_alpha': background[p + 3],
                'original_alpha': originalPixels[p + 3],
                'solid_alpha': solid[p + 3],
                'opaque_patch_transmission': transmission(x, y),
                'original_glyph_delta': math.max(
                  (white[p] - black[p]).abs(),
                  math.max(
                    (white[p + 1] - black[p + 1]).abs(),
                    (white[p + 2] - black[p + 2]).abs(),
                  ),
                ),
              });
            }
            final ratio = _contrast(foreground, bg);
            if (collectRunDiagnostics && previousNamedInk != null) {
              int oldChannel(int channel, double value) =>
                  (solidBlack[p + channel] +
                          (solidWhite[p + channel] - solidBlack[p + channel]) *
                              value)
                      .round()
                      .clamp(0, 255);
              final oldForeground = Color.fromARGB(
                255,
                oldChannel(0, previousNamedInk.r),
                oldChannel(1, previousNamedInk.g),
                oldChannel(2, previousNamedInk.b),
              );
              final oldRatio = _contrast(oldForeground, bg);
              if (oldRatio < previousNamedWorst) {
                previousNamedWorst = oldRatio;
                previousNamedSample = {
                  'x': x,
                  'y': y,
                  'background': _hex(bg),
                  'nominal_ink': _hex(oldForeground),
                  'background_alpha': background[p + 3],
                  'original_alpha': originalPixels[p + 3],
                  'opaque_patch_transmission': transmission(x, y),
                };
              }
            }
            pixels++;
            visible.add(point);
            result.paintedPixels++;
            if (ratio < worst) {
              worst = ratio;
              sample = {
                'x': x,
                'y': y,
                'background': _hex(bg),
                'nominal_ink': _hex(foreground),
                'background_alpha': background[p + 3],
                'original_alpha': originalPixels[p + 3],
                'solid_alpha': solid[p + 3],
                'original_glyph_delta': math.max(
                  (white[p] - black[p]).abs(),
                  math.max(
                    (white[p + 1] - black[p + 1]).abs(),
                    (white[p + 2] - black[p + 2]).abs(),
                  ),
                ),
                'opaque_patch_transmission': transmission(x, y),
              };
            }
          }
        }
      }
      if (unsupported && potentialUnexemptPixels) {
        result.failures.add({
          'text': run.text,
          'coverage_error':
              'Unsupported original foreground paint, ShaderMask blend mode or ancestor ColorFiltered',
        });
      }
      if (nonOpaqueSample != null) {
        result.failures.add({
          'text': run.text,
          'coverage_error':
              'Nonopaque capture background requires the actual external backdrop; premultiplied RGB is not policy RGB',
          'sample': nonOpaqueSample,
        });
      }
      if (pixels == 0) continue;
      if (collectRunDiagnostics) {
        result.diagnosticRuns.add({
          'text': run.text,
          'source_ink': _hex(ink),
          'contrast': worst,
          'sample': sample,
          if (previousNamedInk != null)
            'previous_named_ink': _hex(previousNamedInk),
          if (previousNamedInk != null)
            'previous_named_contrast': previousNamedWorst,
          if (previousNamedInk != null)
            'previous_named_sample': previousNamedSample,
        });
      }
      result.runs++;
      if (node.initial) result.initials++;
      final size = run.style.fontSize ?? 14;
      final renderedSize =
          node.scale(size) *
          math.sqrt(
            transform.entry(1, 0) * transform.entry(1, 0) +
                transform.entry(1, 1) * transform.entry(1, 1),
          );
      final weight = (run.style.fontWeight ?? FontWeight.w400).value;
      final required = node.initial || renderedSize >= 24 ? 3.0 : 4.5;
      final weightPass = (size >= 16 && renderedSize >= 16) || weight >= 400;
      if (collectItems) {
        result.items.add({
          'text': run.text,
          'ink': sample?['nominal_ink'],
          'real_background': sample?['background'],
          'ratio': worst,
          'required_ratio': required,
          'pass':
              worst >= required &&
              weightPass &&
              node.opacity == 1 &&
              !(unsupported && potentialUnexemptPixels) &&
              nonOpaqueSample == null,
        });
      }
      if (worst < required || !weightPass || node.opacity < 1) {
        result.failures.add({
          'text': run.text,
          'font_size': size,
          'rendered_size': renderedSize,
          'weight': weight,
          'source_ink': _hex(ink),
          'parent_opacity': node.opacity,
          'initials': node.initial,
          'contrast': worst,
          'required_contrast': required,
          'contrast_pass': worst >= required,
          'weight_pass': weightPass,
          'opacity_pass': node.opacity == 1,
          'sample': sample,
          'widget_path': node.path.take(12).toList(),
        });
      }
    }
    // Words are checked in the original paragraph, across span boundaries.
    // Explicit hyphens/soft hyphens separate syllables; automatic breaks
    // inside an unhyphenated word must never be disguised by tiny glyphs.
    final plain = node.original.toPlainText();
    for (final word in RegExp(
      r"[\p{L}\p{M}]+(?:['’][\p{L}\p{M}]+)*",
      unicode: true,
    ).allMatches(plain)) {
      final localWordBoxes = node.boxes(word.start, word.end);
      if (node.object is RenderParagraph &&
          localWordBoxes.any((box) {
            final local = box.toRect();
            final painted = MatrixUtils.transformRect(transform, local);
            // Selection-box positions include fractional ink/spacing overhang.
            // Compare advance width, allowing only float32 coordinate roundoff.
            return visible.any(painted.contains) &&
                local.width > node.object.size.width + 0.0001;
          })) {
        result.failures.add({
          'text': word.group(0),
          'word_overflows_available_width': true,
          'paragraph': plain,
          'available_width': node.object.size.width,
          'word_boxes': localWordBoxes
              .map((box) => [box.left, box.top, box.right, box.bottom])
              .toList(),
          'widget_path': node.path.take(12).toList(),
        });
      }
      final boxes = node
          .boxes(word.start, word.end)
          .map((box) => MatrixUtils.transformRect(transform, box.toRect()))
          .where((box) => visible.any(box.contains))
          .toList();
      if (boxes.length < 2) continue;
      final lines = <Rect>[];
      for (final box in boxes) {
        if (!lines.any(
          (line) =>
              (line.center.dy - box.center.dy).abs() <
              math.min(line.height, box.height) * .55,
        )) {
          lines.add(box);
        }
      }
      if (lines.length > 1) {
        result.failures.add({
          'text': word.group(0),
          'word_split_without_hyphen': true,
          'paragraph': plain,
          'lines': lines
              .map((r) => [r.left, r.top, r.right, r.bottom])
              .toList(),
          'widget_path': node.path.take(12).toList(),
        });
      }
    }
  }
  scene.cacheWrites[responseKey] = result;
  return result;
}
