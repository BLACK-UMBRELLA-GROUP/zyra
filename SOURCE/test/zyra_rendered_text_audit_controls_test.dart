// OA-ZYRA-371: independent controls for the rendered-text auditor, using real
// bundled Poppins. These exercise measurement; they do not approve app screens.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_monogram_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/dev/zyra_one_journey_location_sheet.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_draft_compatibility_score_designs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_rendered_text_contrast.dart';
import 'visual/baseline_capture_support.dart';
import 'visual/lock22_v4_settings_edit_profile_test.dart' as settings;

const _font = 'ZYRAIndependentAuditPoppins';
const _boundaryKey = ValueKey('independent-text-audit-boundary');

class _ReadbackPaintObserver extends SingleChildRenderObjectWidget {
  const _ReadbackPaintObserver({required this.onPaint, required super.child});
  final VoidCallback onPaint;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReadbackPaintObserver(onPaint);
}

class _RenderReadbackPaintObserver extends RenderProxyBox {
  _RenderReadbackPaintObserver(this.onPaint);
  final VoidCallback onPaint;
  @override
  void paint(PaintingContext context, Offset offset) {
    onPaint();
    super.paint(context, offset);
  }
}

class _DirectPaintBackdrop extends SingleChildRenderObjectWidget {
  const _DirectPaintBackdrop({
    required super.key,
    required super.child,
    this.persistent = false,
  });
  final bool persistent;
  @override
  RenderObject createRenderObject(BuildContext context) => persistent
      ? _RenderPersistentPaintBackdrop()
      : _RenderDirectPaintBackdrop();
}

class _RenderDirectPaintBackdrop extends RenderProxyBox {
  Color color = Colors.white;
  void changeColor(Color value) {
    color = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.drawRect(offset & size, Paint()..color = color);
    super.paint(context, offset);
  }
}

class _RenderPersistentPaintBackdrop extends _RenderDirectPaintBackdrop {
  @override
  bool get debugNeedsPaint => true;
  @override
  void changeColor(Color value) {
    // The flag is already dirty: no new dirty transition or widget callback
    // announces this mutation. A visible persistent flag must force the
    // original-raster check when probe cleanup repaints the actual scene.
    color = value;
  }
}

class _DeferredAuditImageStream extends ImageStreamCompleter {
  void deliver(ImageInfo info) => setImage(info);
  void fail() => reportError(
    context: ErrorDescription('independent first-frame failure control'),
    exception: StateError('first image frame failed'),
    silent: true,
  );
}

class _TrackedDeferredAuditImageStream extends _DeferredAuditImageStream {
  final _listeners = <ImageStreamListener>{};
  final _readinessListeners = <ImageStreamListener>{};
  VoidCallback? onFirstReadinessListener;
  int readinessAdds = 0;
  int readinessRemoves = 0;

  int get listenerCount => _listeners.length;
  int get readinessListenerCount => _readinessListeners.length;

  @override
  void addListener(ImageStreamListener listener) {
    // The cached Image already owns one listener. Readiness temporarily adds
    // another to the same stream; only that addition releases this control.
    final readiness = _listeners.isNotEmpty;
    _listeners.add(listener);
    if (readiness) {
      _readinessListeners.add(listener);
      readinessAdds++;
    }
    super.addListener(listener);
    if (readiness && readinessAdds == 1) {
      onFirstReadinessListener?.call();
    }
  }

  @override
  void removeListener(ImageStreamListener listener) {
    if (_readinessListeners.remove(listener)) readinessRemoves++;
    _listeners.remove(listener);
    super.removeListener(listener);
  }
}

class _DeferredAuditImage extends ImageProvider<_DeferredAuditImage> {
  const _DeferredAuditImage(this.stream);
  final ImageStreamCompleter stream;
  @override
  Future<_DeferredAuditImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream target,
    _DeferredAuditImage key,
    ImageErrorListener handleError,
  ) => target.setCompleter(stream);
}

// Unlike a standalone page, this public widget gives its descendants the
// isolated BuildScope used by the real shell's back-swipe LayoutBuilder.
Widget _isolatedScope(Widget child) =>
    LayoutBuilder(builder: (context, constraints) => child);

Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 220);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 220),
          textScaler: TextScaler.noScaling,
        ),
        child: RepaintBoundary(
          key: _boundaryKey,
          child: ColoredBox(
            color: Colors.white,
            child: SizedBox.expand(
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Widget _label(
  String value, {
  Color color = Colors.black,
  double size = 14,
  FontWeight weight = FontWeight.w400,
  List<Shadow>? shadows,
}) => Text(
  value,
  style: TextStyle(
    fontFamily: _font,
    fontSize: size,
    fontWeight: weight,
    color: color,
    shadows: shadows,
  ),
);

Future<ZyraRenderedTextAudit> _audit(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  final paragraphs = find
      .descendant(of: find.byKey(_boundaryKey), matching: find.byType(RichText))
      .evaluate()
      .map((element) => element.renderObject! as RenderParagraph)
      .toList();
  final original = {
    for (final paragraph in paragraphs) paragraph: paragraph.text,
  };
  final shadows = debugDisableShadows;
  final result = await auditZyraRenderedText(tester, boundary);
  expect(
    debugDisableShadows,
    shadows,
    reason: 'Restore the caller shadow mode',
  );
  for (final entry in original.entries) {
    expect(
      identical(entry.key.text, entry.value),
      isTrue,
      reason: 'Every original span must be restored after paint probes',
    );
  }
  return result;
}

List<Map<String, Object?>> _contrastFailures(ZyraRenderedTextAudit result) =>
    result.failures
        .where((failure) => failure['contrast_pass'] == false)
        .toList();

Future<void> _modalHome(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(360, 220),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      builder: (context, child) =>
          RepaintBoundary(key: _boundaryKey, child: child!),
      home: Scaffold(backgroundColor: Colors.white, body: home),
    ),
  );
  await tester.pumpAndSettle();
}

class _LeftHalfClip extends CustomClipper<Rect> {
  const _LeftHalfClip();
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width / 2, size.height);
  @override
  bool shouldReclip(_LeftHalfClip oldClipper) => false;
}

class _FooterEdgePainter extends CustomPainter {
  const _FooterEdgePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00ffffff), Color(0xf0ffffff)],
    ).createShader(Offset.zero & size);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height + 64),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_FooterEdgePainter oldDelegate) => false;
}

class _AuditRectClip extends CustomClipper<Rect> {
  const _AuditRectClip(this.inset);
  final double inset;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(inset, 0, size.width - inset, size.height);
  @override
  bool shouldReclip(_AuditRectClip old) => inset != old.inset;
}

class _AuditRRectClip extends CustomClipper<RRect> {
  const _AuditRRectClip(this.radius);
  final double radius;
  @override
  RRect getClip(Size size) =>
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
  @override
  bool shouldReclip(_AuditRRectClip old) => radius != old.radius;
}

class _AuditPathClip extends CustomClipper<Path> {
  const _AuditPathClip();
  @override
  Path getClip(Size size) => Path()..addRect(Offset.zero & size);
  @override
  bool shouldReclip(_AuditPathClip old) => false;
}

class _SelfPaintingZeroOpacity extends LeafRenderObjectWidget {
  const _SelfPaintingZeroOpacity();
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSelfPaintingZeroOpacity();
}

class _RenderSelfPaintingZeroOpacity extends RenderOpacity {
  _RenderSelfPaintingZeroOpacity() : super(opacity: 0);
  @override
  bool get debugNeedsPaint => true;
  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.drawRect(offset & size, Paint()..color = Colors.red);
  }
}

class _UnknownAuditDecoration extends BoxDecoration {
  const _UnknownAuditDecoration();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await loader.load();
  });

  // Actual framework Clip delegates are recreated after an actual readback event.
  // Equal resolved shapes and Clip.none pass; changed shapes fail even where white
  // text/background pixels make the original scene visually identical.
  for (final kind in [
    'equal Rect',
    'equal RRect',
    'Clip.none Rect',
    'Clip.none Path',
    'changed Rect',
    'changed RRect',
    'unknown active Path',
  ]) {
    testWidgets('resolved clip guard: $kind', (tester) async {
      final generation = ValueNotifier<int>(0);
      final realZone = (await tester.runAsync(() async => Zone.current))!;
      const key = ValueKey('resolved-clip-probe-label');
      var active = false, scheduled = false, fired = false;
      late InlineSpan original;
      try {
        await _mount(
          tester,
          _ReadbackPaintObserver(
            onPaint: () {
              if (!active || scheduled) return;
              final paragraph = tester.renderObject<RenderParagraph>(
                find.byKey(key),
              );
              if (identical(paragraph.text, original)) return;
              scheduled = true;
              realZone.run(
                () => Timer.run(() {
                  fired = active;
                  generation.value++;
                }),
              );
            },
            child: ValueListenableBuilder<int>(
              valueListenable: generation,
              builder: (context, value, child) {
                final rich = RichText(
                  key: key,
                  text: const TextSpan(
                    text: 'Shape guard',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                );
                original = rich.text;
                final content = Center(child: rich);
                if (kind.contains('Path')) {
                  return ClipPath(
                    clipBehavior: kind.startsWith('Clip.none')
                        ? Clip.none
                        : Clip.hardEdge,
                    clipper: _AuditPathClip(),
                    child: content,
                  );
                }
                if (kind.contains('RRect')) {
                  return ClipRRect(
                    clipper: _AuditRRectClip(
                      kind.startsWith('changed') && value > 0 ? 40 : 4,
                    ),
                    child: content,
                  );
                }
                return ClipRect(
                  clipBehavior: kind.startsWith('Clip.none')
                      ? Clip.none
                      : Clip.hardEdge,
                  clipper: _AuditRectClip(
                    kind.startsWith('changed') && value > 0 ? 8 : 0,
                  ),
                  child: content,
                );
              },
            ),
          ),
        );
        active = true;
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_boundaryKey),
        );
        final result = await auditZyraRenderedText(tester, boundary);
        active = false;
        expect(fired, isTrue);
        expect(tester.takeException(), isNull);
        final errors = result.failures.where(
          (row) => row.containsKey('coverage_error'),
        );
        if (kind.startsWith('changed') || kind == 'unknown active Path') {
          expect(errors, isNotEmpty);
          expect(result.cacheHit, isFalse);
        } else {
          expect(errors, isEmpty);
          expect(result.runs, greaterThan(0));
        }
        // White-on-white deliberately gives contrast failures; this control is
        // only about semantic clip equivalence vs actual shape changes.
      } finally {
        active = false;
        await tester.pumpWidget(const SizedBox.shrink());
        generation.dispose();
      }
    });
  }

  for (final animated in [false, true]) {
    testWidgets(
      'exact zero-alpha excludes the entire opacity object: animated=$animated',
      (tester) async {
        final opacity = ValueNotifier<double>(animated ? .001 : 0);
        try {
          await _mount(
            tester,
            Column(
              children: [
                _label('Visible strict label'),
                ValueListenableBuilder<double>(
                  valueListenable: opacity,
                  builder: (context, value, child) {
                    final label = _label(
                      'Hidden then revealed weak text',
                      color: const Color(0xffaaaaaa),
                    );
                    return animated
                        ? AnimatedOpacity(
                            opacity: value,
                            duration: Duration.zero,
                            child: label,
                          )
                        : Opacity(opacity: value, child: label);
                  },
                ),
              ],
            ),
          );
          var result = await _audit(tester);
          expect(result.failures, isEmpty);
          expect(result.runs, greaterThan(0));
          opacity.value = 1;
          await tester.pumpAndSettle();
          result = await _audit(tester);
          expect(_contrastFailures(result), isNotEmpty);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          opacity.dispose();
        }
      },
    );
  }

  testWidgets('unknown zero-opacity subclass self-paint stays conservative', (
    tester,
  ) async {
    await _mount(
      tester,
      Stack(
        children: [
          Center(child: _label('Visible ordinary text')),
          const Positioned(
            left: 0,
            top: 0,
            width: 30,
            height: 30,
            child: _SelfPaintingZeroOpacity(),
          ),
        ],
      ),
    );
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage();
      try {
        return await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      } finally {
        image.dispose();
      }
    });
    expect(
      bytes!.buffer.asUint8List().take(4),
      [244, 67, 54, 255],
      reason: 'This unknown opacity subclass actually paints its own content',
    );
    final result = await _audit(tester);
    expect(result.cacheHit, isFalse);
    expect(
      result.failures.single['coverage_error'].toString(),
      contains('persistently dirty'),
    );
    expect(tester.takeException(), isNull);
  });

  for (final kind in [
    'hidden avatar',
    'hidden delete',
    'weak label',
    'visible avatar',
    'visible delete',
  ]) {
    testWidgets('actual Chip slot admission: $kind', (tester) async {
      await _modalHome(
        tester,
        Material(
          child: Center(
            child: RawChip(
              label: _label(
                'Chip label',
                color: kind == 'weak label'
                    ? const Color(0xffaaaaaa)
                    : Colors.black,
              ),
              avatar: kind == 'visible avatar'
                  ? _label('A', color: const Color(0xffaaaaaa))
                  : null,
              deleteIcon: kind.endsWith('delete')
                  ? _label('X', color: const Color(0xffaaaaaa))
                  : null,
              onDeleted: kind == 'visible delete' ? () {} : null,
              showCheckmark: true,
              selected: false,
              onSelected: (_) {},
              backgroundColor: Colors.white,
            ),
          ),
        ),
      );
      final result = await _audit(tester);
      expect(
        result.failures.where((row) => row.containsKey('coverage_error')),
        isEmpty,
      );
      if (kind.startsWith('hidden')) {
        expect(result.failures, isEmpty);
        expect(result.runs, greaterThan(0));
      } else {
        expect(_contrastFailures(result), isNotEmpty);
      }
      expect(tester.takeException(), isNull);
    });
  }

  // ACTUAL PUBLIC PHONE PAGE: do not replace its ListenableBuilder/ListView with
  // a synthetic notifier. A held native status response is completed only after
  // an actual paint probe is installed. Its callback can mark the real outer
  // ListenableBuilder dirty while an inner lazy SliverList owns build scope.
  for (final changed in [false, true]) {
    testWidgets(
      'actual phone native response during raster readback: changed=$changed',
      (tester) async {
        ZyraAccountState.resetForTesting();
        final phoneFont = FontLoader('Poppins');
        for (final weight in [
          'ExtraLight',
          'Light',
          'Regular',
          'Medium',
          'Bold',
        ]) {
          phoneFont.addFont(
            rootBundle.load('assets/fonts/Poppins-$weight.ttf'),
          );
        }
        await phoneFont.load();
        final realZone = (await tester.runAsync(() async => Zone.current))!;
        final response = realZone.run(() => Completer<Object?>());
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(zyraPhoneAccessChannel, (
          call,
        ) async {
          if (call.method == 'status') return response.future;
          if (call.method == 'cancel') return null;
          throw StateError('Unexpected native method ${call.method}');
        });
        var active = false, scheduled = false, firedDuringProbe = false;
        late RenderParagraph observed;
        late InlineSpan original;
        final previousPaintObserver = debugOnProfilePaint;
        void observePhonePaint(RenderObject object) {
          previousPaintObserver?.call(object);
          if (!active ||
              scheduled ||
              !identical(object, observed) ||
              identical(observed.text, original)) {
            return;
          }
          scheduled = true;
          realZone.run(
            () => Timer.run(() {
              firedDuringProbe = active && !identical(observed.text, original);
              response.complete(
                changed
                    ? <String, String>{'location': 'allowed'}
                    : <String, String>{},
              );
            }),
          );
        }

        try {
          await _modalHome(
            tester,
            _isolatedScope(
              ZyraPhoneAccessPage(canAct: () => true, onBack: () {}),
            ),
            size: const Size(375, 667),
          );
          expect(find.byType(ListenableBuilder), findsWidgets);
          expect(find.byType(SliverList), findsOneWidget);
          final scroll = tester.state<ScrollableState>(
            find.byType(Scrollable).first,
          );
          expect(scroll.position.maxScrollExtent, greaterThan(30));
          scroll.position.jumpTo(30);
          await tester.pump();
          observed = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byKey(const ValueKey('phone_access_status_location')),
              matching: find.byType(RichText),
            ),
          );
          original = observed.text;
          debugOnProfilePaint = observePhonePaint;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(_boundaryKey),
          );
          active = true;
          final result = await auditZyraRenderedText(tester, boundary);
          active = false;
          expect(scheduled, isTrue);
          expect(firedDuringProbe, isTrue);
          final presentation = tester.widget<ZyraPhoneAccessPresentation>(
            find.byType(ZyraPhoneAccessPresentation),
          );
          expect(
            presentation.controller.label(ZyraPhonePermission.location),
            changed ? 'While using' : 'Ask first',
            reason:
                'The actual native response continuation must complete, not just its Timer',
          );
          expect(
            tester.takeException(),
            isNull,
            reason:
                'The actual SliverList/native continuation must not violate build scope',
          );
          if (changed) {
            expect(
              result.failures.any((row) => row.containsKey('coverage_error')),
              isTrue,
            );
            expect(result.cacheHit, isFalse);
          } else {
            expect(
              result.failures.where((row) => row.containsKey('coverage_error')),
              isEmpty,
            );
            expect(result.runs, greaterThan(0));
          }
        } finally {
          active = false;
          debugOnProfilePaint = previousPaintObserver;
          if (!response.isCompleted) response.complete(<String, String>{});
          await tester.pumpWidget(const SizedBox.shrink());
          messenger.setMockMethodCallHandler(zyraPhoneAccessChannel, null);
          ZyraAccountState.resetForTesting();
        }
      },
    );
  }

  for (final kind in [
    'equal rectangle',
    'equal rounded rectangle',
    'equal circle',
    'changed radius',
    'rectangle to circle',
    'circle to rectangle',
    'unknown decoration',
  ]) {
    testWidgets('actual SDK BoxDecoration clip: $kind', (tester) async {
      final generation = ValueNotifier<int>(0);
      final realZone = (await tester.runAsync(() async => Zone.current))!;
      const key = ValueKey('decoration-clip-label');
      var active = false, scheduled = false, fired = false;
      late InlineSpan actual;
      try {
        await _mount(
          tester,
          _ReadbackPaintObserver(
            onPaint: () {
              if (!active || scheduled) return;
              final paragraph = tester.renderObject<RenderParagraph>(
                find.byKey(key),
              );
              if (identical(paragraph.text, actual)) return;
              scheduled = true;
              realZone.run(
                () => Timer.run(() {
                  fired = active;
                  generation.value++;
                }),
              );
            },
            child: ValueListenableBuilder<int>(
              valueListenable: generation,
              builder: (context, value, _) {
                final circle =
                    kind == 'equal circle' ||
                    (kind == 'rectangle to circle' && value > 0) ||
                    (kind == 'circle to rectangle' && value == 0);
                final rounded =
                    kind == 'equal rounded rectangle' ||
                    kind == 'changed radius';
                actual = const TextSpan(
                  text: 'White original shape',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: _font,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                );
                return Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: kind == 'unknown decoration'
                      ? _UnknownAuditDecoration()
                      : BoxDecoration(
                          color: Colors.white,
                          shape: circle ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: rounded
                              ? BorderRadius.circular(
                                  kind == 'changed radius' && value > 0
                                      ? 30
                                      : 4,
                                )
                              : null,
                        ),
                  child: Center(
                    child: RichText(key: key, text: actual),
                  ),
                );
              },
            ),
          ),
        );
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_boundaryKey),
        );
        final before = await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            return await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          } finally {
            image.dispose();
          }
        });
        active = true;
        final result = await auditZyraRenderedText(tester, boundary);
        active = false;
        expect(fired, isTrue);
        final after = await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            return await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          } finally {
            image.dispose();
          }
        });
        expect(
          after!.buffer.asUint8List(),
          orderedEquals(before!.buffer.asUint8List()),
          reason:
              'The uniform original bitmap cannot substitute for clip-shape identity',
        );
        final errors = result.failures.where(
          (row) => row.containsKey('coverage_error'),
        );
        if (kind.startsWith('equal')) {
          expect(errors, isEmpty);
          expect(result.runs, greaterThan(0));
        } else {
          expect(errors, isNotEmpty);
          expect(result.cacheHit, isFalse);
        }
        expect(tester.takeException(), isNull);
      } finally {
        active = false;
        await tester.pumpWidget(const SizedBox.shrink());
        generation.dispose();
      }
    });
  }

  for (final change in [
    'same scene',
    'warm same scene',
    'changed text',
    'changed foreground',
    'changed alignment',
    'changed backdrop',
    'changed backdrop without observer',
    'direct backdrop',
    'cold cleanup',
    'warm cleanup',
  ]) {
    testWidgets('actual mid-readback notification: $change', (tester) async {
      final value = ValueNotifier<int>(0);
      final bindingSchedule = tester.binding.buildOwner!.onBuildScheduled;
      final recognizers = <TapGestureRecognizer>[];
      final key = ValueKey('mid-readback-$change');
      final realZone = await tester.runAsync(() async => Zone.current);
      late TextSpan latestSpan;
      late TapGestureRecognizer latestRecognizer;
      var active = false, scheduled = false, firedDuringProbe = false;
      var taps = -1;
      final warm = change.startsWith('warm');
      final changed =
          change.startsWith('changed') || change.endsWith('cleanup');
      final cleanup = change.endsWith('cleanup');
      final direct = change == 'direct backdrop';
      void observePaint() {
        if (!active || scheduled) return;
        final paragraph = tester.renderObject<RenderParagraph>(find.byKey(key));
        final span = paragraph.text as TextSpan;
        if (identical(span, latestSpan)) return;
        if ((cleanup || change == 'warm same scene') &&
            (span.style?.foreground?.color != Colors.white ||
                span.style?.background?.imageFilter != null)) {
          return;
        }
        scheduled = true;
        realZone!.run(
          () => Timer.run(() {
            firedDuringProbe = active && !identical(paragraph.text, latestSpan);
            if (direct) {
              tester
                  .renderObject<_RenderDirectPaintBackdrop>(
                    find.byKey(const ValueKey('direct-paint-backdrop')),
                  )
                  .changeColor(const Color(0xff222222));
            } else if (change == 'changed backdrop without observer') {
              final owner = tester.binding.buildOwner!;
              final callback = owner.onBuildScheduled;
              try {
                // Exercise independent scope detection when this observation
                // is unavailable. The real LayoutBuilder still schedules its
                // deferred public frame callback and owns the dirty Element.
                owner.onBuildScheduled = bindingSchedule;
                value.value++;
              } finally {
                owner.onBuildScheduled = callback;
              }
            } else {
              value.value++;
            }
          }),
        );
      }

      try {
        await _mount(
          tester,
          _ReadbackPaintObserver(
            onPaint: observePaint,
            child: _isolatedScope(
              ValueListenableBuilder<int>(
                valueListenable: value,
                builder: (context, generation, child) {
                  latestRecognizer = TapGestureRecognizer()
                    ..onTap = () => taps = generation;
                  recognizers.add(latestRecognizer);
                  latestSpan = TextSpan(
                    text: change == 'changed text' && generation > 0
                        ? 'Changed text during readback'
                        : 'Readback control $change',
                    recognizer: latestRecognizer,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: change == 'changed alignment'
                          ? Colors.white
                          : change == 'changed foreground' && generation > 0
                          ? const Color(0xffaaaaaa)
                          : Colors.black,
                    ),
                  );
                  final rich = RichText(
                    key: key,
                    text: latestSpan,
                    textAlign: change == 'changed alignment' && generation > 0
                        ? TextAlign.right
                        : TextAlign.left,
                  );
                  final label = Center(
                    child: change == 'changed alignment'
                        ? SizedBox(width: 300, child: rich)
                        : rich,
                  );
                  if (direct) {
                    return _DirectPaintBackdrop(
                      key: const ValueKey('direct-paint-backdrop'),
                      child: label,
                    );
                  }
                  return ColoredBox(
                    color:
                        generation > 0 &&
                            (change.startsWith('changed backdrop') || cleanup)
                        ? const Color(0xff222222)
                        : Colors.white,
                    child: label,
                  );
                },
              ),
            ),
          ),
        );
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_boundaryKey),
        );
        if (warm) {
          final baseline = await auditZyraRenderedText(tester, boundary);
          expect(baseline.failures, isEmpty);
          expect(baseline.cacheHit, isFalse);
        }
        final originalRecognizer = latestRecognizer;
        final scheduledCallback = tester.binding.buildOwner!.onBuildScheduled;
        active = true;
        final result = await auditZyraRenderedText(tester, boundary);
        active = false;
        expect(
          tester.binding.buildOwner!.onBuildScheduled,
          same(scheduledCallback),
        );
        expect(scheduled, isTrue);
        expect(
          firedDuringProbe,
          isTrue,
          reason: 'The notifier must run during a real probe readback',
        );
        expect(value.value, direct ? 0 : 1);
        expect(identical(latestRecognizer, originalRecognizer), direct);
        final actual = tester
            .renderObject<RenderParagraph>(find.byKey(key))
            .text;
        expect(
          identical(actual, latestSpan),
          isTrue,
          reason: 'Cleanup preserves the latest actual span, not its old copy',
        );
        expect((actual as TextSpan).recognizer, same(latestRecognizer));
        latestRecognizer.onTap!();
        expect(taps, direct ? 0 : 1);
        expect(tester.takeException(), isNull);
        if (changed || direct) {
          expect(result.cacheHit, isFalse);
          expect(
            result.failures.any((row) => row.containsKey('coverage_error')),
            isTrue,
          );
          if (direct || change.startsWith('changed backdrop')) {
            expect(
              result.failures.single['coverage_error'].toString(),
              contains('same_pixels=false'),
            );
          }
        } else {
          expect(result.failures, isEmpty);
          expect(result.runs, greaterThan(0));
          expect(result.cacheHit, warm);
          expect(
            result.rasterImages,
            greaterThan(4),
            reason: 'Actual source work requires an original-raster check',
          );
        }
        if (cleanup) {
          // A failed late readback may not create a new cache entry. A valid
          // earlier entry remains usable after the real scene is restored.
          value.value = 0;
          await tester.pump();
          final restored = await auditZyraRenderedText(tester, boundary);
          expect(restored.failures, isEmpty);
          expect(restored.cacheHit, warm);
        }
      } finally {
        active = false;
        await tester.pumpWidget(const SizedBox.shrink());
        value.dispose();
        for (final recognizer in recognizers) {
          recognizer.dispose();
        }
      }
    });
  }

  testWidgets(
    'visible persistently dirty paint cannot receive scene or cache credit',
    (tester) async {
      const key = ValueKey('ambiguous-persistent-backdrop');
      await _mount(
        tester,
        _DirectPaintBackdrop(
          key: key,
          persistent: true,
          child: Center(child: _label('Ambiguous painted background')),
        ),
      );
      final backdrop = tester.renderObject<_RenderPersistentPaintBackdrop>(
        find.byKey(key),
      );
      expect(backdrop.debugNeedsPaint, isTrue);
      // No new dirty mark or widget callback distinguishes this mutation from
      // the existing flag. Rejecting this unknown scene also closes a mutation
      // during any final readback: it can never get a cache/contrast pass.
      backdrop.changeColor(const Color(0xff222222));
      final result = await _audit(tester);
      expect(result.cacheHit, isFalse);
      expect(
        result.failures.single['coverage_error'].toString(),
        contains('persistently dirty'),
      );
      expect(result.runs, 0);
    },
  );

  testWidgets(
    'sliver paint admission retains admitted overflow and audits revealed cache text',
    (tester) async {
      await _mount(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: 80,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.none,
              scrollCacheExtent: const ScrollCacheExtent.pixels(500),
              itemCount: 6,
              itemBuilder: (context, index) => SizedBox(
                height: 30,
                child: index == 0
                    ? Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 40,
                            child: _label(
                              'Admitted overflow',
                              color: const Color(0xffaaaaaa),
                            ),
                          ),
                        ],
                      )
                    : _label(
                        index == 4
                            ? 'Cached then revealed'
                            : 'Visible row $index',
                        color: index == 4
                            ? const Color(0xffaaaaaa)
                            : Colors.black,
                      ),
              ),
            ),
          ),
        ),
      );
      final first = await _audit(tester);
      expect(
        first.failures.where((row) => row.containsKey('coverage_error')),
        isEmpty,
      );
      final firstLabels = _contrastFailures(first).map((row) => row['text']);
      expect(firstLabels, contains('Admitted overflow'));
      expect(firstLabels, isNot(contains('Cached then revealed')));
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .jumpTo(100);
      await tester.pump();
      final revealed = await _audit(tester);
      expect(
        revealed.failures.where((row) => row.containsKey('coverage_error')),
        isEmpty,
      );
      expect(
        _contrastFailures(revealed).map((row) => row['text']),
        contains('Cached then revealed'),
      );
    },
  );

  testWidgets(
    'OverlayPortal onstage text retains conservative paint traversal',
    (tester) async {
      final controller = OverlayPortalController();
      await _modalHome(
        tester,
        Material(
          color: Colors.white,
          child: OverlayPortal(
            controller: controller,
            overlayChildBuilder: (context) => Positioned(
              top: 70,
              left: 10,
              child: _label(
                'Portal low contrast',
                color: const Color(0xffaaaaaa),
              ),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: _label('Portal owner'),
            ),
          ),
        ),
      );
      controller.show();
      await tester.pumpAndSettle();
      final shown = await _audit(tester);
      expect(
        _contrastFailures(shown).map((row) => row['text']),
        contains('Portal low contrast'),
      );
      expect(
        shown.failures.where((row) => row.containsKey('coverage_error')),
        isEmpty,
      );
      controller.hide();
      await tester.pumpAndSettle();
      final hidden = await _audit(tester);
      expect(hidden.failures, isEmpty);
      expect(hidden.runs, 1);
    },
  );

  for (final sheet in [false, true]) {
    testWidgets(
      'Q192 actual ${sheet ? 'sheet' : 'dialog'} keeps foreground strict and exempts only its backdrop',
      (tester) async {
        late BuildContext launcher;
        await _modalHome(
          tester,
          Builder(
            builder: (context) {
              launcher = context;
              return Align(
                alignment: Alignment.topLeft,
                child: _label(
                  'Low contrast backdrop',
                  color: const Color(0xffaaaaaa),
                ),
              );
            },
          ),
        );
        final before = await _audit(tester);
        expect(
          _contrastFailures(
            before,
          ).any((f) => f['text'] == 'Low contrast backdrop'),
          isTrue,
          reason: before.toJson().toString(),
        );
        Widget foreground(BuildContext context) => ColoredBox(
          color: Colors.white,
          child: SizedBox(
            height: 90,
            child: Column(
              children: [
                _label('Foreground bad', color: Colors.white),
                _label('Foreground good'),
                Opacity(opacity: .5, child: _label('Foreground faded')),
              ],
            ),
          ),
        );
        if (sheet) {
          showModalBottomSheet<void>(
            context: launcher,
            barrierColor: Colors.black38,
            builder: foreground,
          );
        } else {
          showDialog<void>(
            context: launcher,
            barrierColor: Colors.white.withValues(alpha: .7),
            builder: (context) => Dialog(
              backgroundColor: Colors.white,
              child: foreground(context),
            ),
          );
        }
        await tester.pumpAndSettle();
        final open = await _audit(tester);
        expect(open.modalExemptPixels, greaterThan(0));
        expect(open.runs, greaterThanOrEqualTo(3));
        expect(
          open.failures.any((f) => f['text'] == 'Low contrast backdrop'),
          isFalse,
        );
        expect(
          _contrastFailures(open).any((f) => f['text'] == 'Foreground bad'),
          isTrue,
        );
        expect(
          open.failures.any((f) => f['text'] == 'Foreground good'),
          isFalse,
        );
        expect(
          open.failures.any(
            (f) =>
                f['text'] == 'Foreground faded' && f['opacity_pass'] == false,
          ),
          isTrue,
        );
        Navigator.of(tester.element(find.text('Foreground good'))).pop();
        await tester.pumpAndSettle();
        final closed = await _audit(tester);
        expect(closed.modalExemptPixels, 0);
        expect(
          _contrastFailures(
            closed,
          ).any((f) => f['text'] == 'Low contrast backdrop'),
          isTrue,
        );
      },
    );
  }

  testWidgets('Q192 a transparent dialog barrier grants no dim exemption', (
    tester,
  ) async {
    late BuildContext launcher;
    await _modalHome(
      tester,
      Builder(
        builder: (context) {
          launcher = context;
          return Align(
            alignment: Alignment.topLeft,
            child: _label('Undimmed backdrop', color: const Color(0xffaaaaaa)),
          );
        },
      ),
    );
    showDialog<void>(
      context: launcher,
      barrierColor: Colors.transparent,
      builder: (_) => Dialog(child: _label('Good dialog')),
    );
    await tester.pumpAndSettle();
    final result = await _audit(tester);
    expect(result.modalExemptPixels, 0);
    expect(
      _contrastFailures(result).any((f) => f['text'] == 'Undimmed backdrop'),
      isTrue,
    );
  });

  testWidgets(
    'Q192 actual inline location barrier exempts its earlier sibling only',
    (tester) async {
      final oldStubs = ZyraText.useTestFontStubs;
      final oldFont = ZyraText.testReadingFontFamily;
      ZyraText.useTestFontStubs = true;
      ZyraText.testReadingFontFamily = _font;
      addTearDown(() {
        ZyraText.useTestFontStubs = oldStubs;
        ZyraText.testReadingFontFamily = oldFont;
      });
      await _modalHome(
        tester,
        Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: _label('Inline backdrop', color: const Color(0xffaaaaaa)),
            ),
            Positioned.fill(
              child: ZyraOneJourneyLocationSheet(
                explain: true,
                town: 'London',
                currentArea: false,
                canAct: () => true,
                onHome: () {},
                onCurrent: () {},
                onContinue: () {},
                onClose: () {},
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: _label('Inline foreground bad', color: Colors.white),
            ),
          ],
        ),
        size: const Size(430, 932),
      );
      final result = await _audit(tester);
      expect(result.modalExemptPixels, greaterThan(0));
      expect(
        result.failures.any((f) => f['text'] == 'Inline backdrop'),
        isFalse,
      );
      expect(
        _contrastFailures(
          result,
        ).any((f) => f['text'] == 'Inline foreground bad'),
        isTrue,
      );
    },
  );

  testWidgets(
    'Q191 one overflow-visible word cannot pass as a fitted single line',
    (tester) async {
      await _mount(
        tester,
        Center(
          child: SizedBox(
            width: 40,
            child: Text(
              'Birmingham',
              softWrap: false,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
      final result = await _audit(tester);
      expect(
        result.failures.any(
          (f) =>
              f['text'] == 'Birmingham' &&
              f['word_overflows_available_width'] == true,
        ),
        isTrue,
      );
    },
  );

  for (final rounded in [false, true]) {
    testWidgets(
      'Q192 ${rounded ? 'rounded' : 'rectangular'} barrier clipping does not exempt exposed text',
      (tester) async {
        final barrier = ModalBarrier(
          color: Colors.black.withValues(alpha: .7),
          onDismiss: () {},
        );
        await _modalHome(
          tester,
          Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 10,
                top: 95,
                child: _label('Behind dim', color: const Color(0xffaaaaaa)),
              ),
              Positioned(
                left: 225,
                top: 8,
                child: _label('Exposed corner', color: const Color(0xffaaaaaa)),
              ),
              Positioned.fill(
                child: rounded
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: barrier,
                      )
                    : ClipRect(clipper: const _LeftHalfClip(), child: barrier),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: ColoredBox(
                  color: Colors.white,
                  child: _label('Foreground clipped bad', color: Colors.white),
                ),
              ),
            ],
          ),
        );
        final result = await _audit(tester);
        expect(result.modalExemptPixels, greaterThan(0));
        expect(
          result.failures.any((failure) => failure['text'] == 'Behind dim'),
          isFalse,
        );
        expect(
          _contrastFailures(
            result,
          ).any((failure) => failure['text'] == 'Exposed corner'),
          isTrue,
        );
        expect(
          _contrastFailures(
            result,
          ).any((failure) => failure['text'] == 'Foreground clipped bad'),
          isTrue,
        );
      },
    );
  }

  testWidgets(
    'Q191 fractional letter-spacing bearings preserve an exact fitted advance',
    (tester) async {
      const style = TextStyle(
        fontFamily: _font,
        fontSize: 32,
        fontWeight: FontWeight.w300,
        letterSpacing: .25,
        color: Colors.black,
      );
      final painter = TextPainter(
        text: const TextSpan(text: 'Sara', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final advance = painter.width;
      painter.dispose();
      await _mount(
        tester,
        Center(
          child: SizedBox(
            width: advance,
            child: const Text(
              'Sara',
              softWrap: false,
              overflow: TextOverflow.visible,
              style: style,
            ),
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 4),
      );
      expect(
        boxes.single.left,
        closeTo(.125, .001),
        reason: 'The fixture must contain the actual fractional paint bearing',
      );
      final result = await _audit(tester);
      expect(result.runs, 1);
      expect(
        result.failures,
        isEmpty,
        reason: 'A positive bearing does not increase the fitted advance',
      );
    },
  );

  for (final backdrop in [
    (Colors.white, Colors.black, 'black text over white parent'),
    (Colors.black, Colors.white, 'white text over black parent'),
  ]) {
    testWidgets('transparent capture boundary: ${backdrop.$3}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 220);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 220),
              textScaler: TextScaler.noScaling,
            ),
            // The real opaque surface deliberately lives OUTSIDE the capture
            // boundary. A raw image of the boundary alone omits this backdrop.
            child: ColoredBox(
              color: backdrop.$1,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: SizedBox.expand(
                  child: Center(
                    child: _label(
                      'External backdrop contrast',
                      color: backdrop.$2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_boundaryKey),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(
            bytes!.getUint8(3),
            0,
            reason: 'Fixture must actually omit the outside opaque backdrop',
          );
        } finally {
          image.dispose();
        }
      });
      final result = await _audit(tester);
      expect(
        _contrastFailures(result),
        isEmpty,
        reason:
            'Premultiplied transparent RGB must never become a false '
            'opaque-black/white contrast failure',
      );
      final coverageErrors = result.failures.where(
        (failure) => failure['coverage_error'] != null,
      );
      if (coverageErrors.isEmpty) {
        expect(
          result.runs,
          1,
          reason: 'A known21:1 parent backdrop must produce visible text proof',
        );
        expect(result.paintedPixels, greaterThan(0));
        expect(result.failures, isEmpty);
      }
    });
  }

  testWidgets(
    'later painted translucent white veil lowers actual ink contrast',
    (tester) async {
      await _mount(
        tester,
        Stack(
          children: [
            Positioned(
              left: 24,
              top: 70,
              child: _label('Visible under the veil'),
            ),
            Positioned.fill(
              child: ColoredBox(color: Colors.white.withValues(alpha: .7)),
            ),
          ],
        ),
      );
      final result = await _audit(tester);
      expect(result.paintedPixels, greaterThan(0));
      expect(_contrastFailures(result), isNotEmpty);
      expect(_contrastFailures(result).first['contrast'], lessThan(2.2));
    },
  );

  testWidgets('occluded thin text cannot borrow another node visible glyphs', (
    tester,
  ) async {
    await _mount(
      tester,
      Stack(
        children: [
          Positioned(
            left: 24,
            top: 70,
            child: _label('Hidden overlap', weight: FontWeight.w200),
          ),
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
          Positioned(left: 24, top: 70, child: _label('Visible overlap')),
        ],
      ),
    );
    final result = await _audit(tester);
    expect(result.runs, 1);
    expect(result.paintedPixels, greaterThan(0));
    expect(result.failures, isEmpty);
  });

  testWidgets('a separately painted node shadow stays in the real background', (
    tester,
  ) async {
    await _mount(
      tester,
      Stack(
        children: [
          Positioned(
            left: 0,
            top: -70,
            child: _label(
              'MMMM',
              size: 160,
              shadows: const [
                Shadow(color: Color(0xFFAAAAAA), offset: Offset(0, 120)),
              ],
            ),
          ),
          Positioned(
            left: 30,
            top: 140,
            child: _label(
              'Actual shadow background',
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
    final result = await _audit(tester);
    final failures = _contrastFailures(result)
        .where((failure) => failure['text'] == 'Actual shadow background')
        .toList();
    expect(failures, isNotEmpty);
    expect(failures.first['contrast'], lessThan(3));
    expect((failures.first['sample']! as Map)['background'], '#ffaaaaaa');
  });

  testWidgets(
    'mixed RichText ink, backgrounds, ligatures and graphemes isolate',
    (tester) async {
      const bad = 'g\u0308j';
      await _mount(
        tester,
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'office affine ',
                  style: TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: 'fi e\u0301 ',
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                  ),
                ),
                TextSpan(
                  text: bad,
                  style: TextStyle(color: Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ),
        ),
      );
      final result = await _audit(tester);
      expect(result.runs, 3);
      expect(_contrastFailures(result).map((failure) => failure['text']), [
        bad,
      ]);
      expect(result.failures.length, 1);
    },
  );

  testWidgets('word-break gate spans separate colored RichText runs', (
    tester,
  ) async {
    await _mount(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 42,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'unbreak',
                  style: TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: 'able',
                  style: TextStyle(color: Color(0xFF111111)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final result = await _audit(tester);
    expect(
      result.failures
          .where((failure) => failure['word_split_without_hyphen'] == true)
          .map((failure) => failure['text']),
      ['unbreakable'],
    );
  });

  testWidgets(
    'explicit visible syllable hyphen is accepted by word-break gate',
    (tester) async {
      await _mount(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 80, child: Text('Intro-\nductions')),
        ),
      );
      final result = await _audit(tester);
      expect(result.runs, 1);
      expect(result.failures, isEmpty);
    },
  );

  testWidgets('original foreground shader fails closed as unsupported', (
    tester,
  ) async {
    await _mount(
      tester,
      Text(
        'Original shader',
        style: TextStyle(
          foreground: Paint()
            ..shader = ui.Gradient.linear(Offset.zero, const Offset(200, 0), [
              Colors.black.withValues(alpha: .1),
              Colors.black.withValues(alpha: .1),
            ]),
        ),
      ),
    );
    final result = await _audit(tester);
    expect(
      result.failures.where((failure) => failure['coverage_error'] != null),
      isNotEmpty,
    );
  });

  testWidgets('ancestor ColorFiltered fails closed as unsupported', (
    tester,
  ) async {
    await _mount(
      tester,
      ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white.withValues(alpha: .8),
          BlendMode.srcATop,
        ),
        child: _label('Filtered reading text'),
      ),
    );
    final result = await _audit(tester);
    expect(
      result.failures.where((failure) => failure['coverage_error'] != null),
      isNotEmpty,
    );
  });

  testWidgets('colorizing srcIn mask fails closed before glyph visibility', (
    tester,
  ) async {
    await _mount(
      tester,
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: [Colors.purple, Colors.purple],
        ).createShader(rect),
        child: Center(child: _label('Colorized reading text')),
      ),
    );
    final result = await _audit(tester);
    expect(
      result.failures.where((failure) => failure['coverage_error'] != null),
      isNotEmpty,
    );
  });

  for (final paintCase in ['stroke', 'multiply']) {
    testWidgets('original foreground $paintCase paint fails closed', (
      tester,
    ) async {
      final paint = Paint()..color = Colors.black;
      if (paintCase == 'stroke') {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
      } else {
        paint.blendMode = BlendMode.multiply;
      }
      await _mount(
        tester,
        Center(
          child: Text('Original paint', style: TextStyle(foreground: paint)),
        ),
      );
      final result = await _audit(tester);
      expect(
        result.failures.where((failure) => failure['coverage_error'] != null),
        isNotEmpty,
      );
    });
  }

  testWidgets('opaque gold circle edge does not dilute remaining visible ink', (
    tester,
  ) async {
    await _mount(
      tester,
      Stack(
        children: [
          Positioned(
            left: 24,
            top: 70,
            child: _label('Readable around gold circle'),
          ),
          const Positioned(
            left: 83.25,
            top: 67.75,
            width: 39.5,
            height: 39.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFA9792E),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
    final result = await _audit(tester);
    expect(result.runs, 1);
    expect(result.paintedPixels, greaterThan(0));
    expect(result.occlusionFringePixels, greaterThan(0));
    expect(result.failures, isEmpty);
  });

  for (final alpha in [.05, 1 / 255]) {
    testWidgets('uniform faint dstIn mask $alpha remains contrast tested', (
      tester,
    ) async {
      await _mount(
        tester,
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            colors: [
              Colors.white.withValues(alpha: alpha),
              Colors.white.withValues(alpha: alpha),
            ],
          ).createShader(rect),
          child: Center(child: _label('Faint reading text')),
        ),
      );
      final result = await _audit(tester);
      expect(result.runs, 1);
      expect(result.paintedPixels, greaterThan(0));
      expect(result.occlusionFringePixels, 0);
      expect(_contrastFailures(result), hasLength(1));
    });
  }

  testWidgets('generic faint shader edge is not an opaque-geometry exemption', (
    tester,
  ) async {
    await _mount(
      tester,
      ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          colors: [Colors.white.withValues(alpha: .05), Colors.transparent],
        ).createShader(rect),
        child: Center(child: _label('Faint shader edge')),
      ),
    );
    final result = await _audit(tester);
    expect(result.paintedPixels, greaterThan(0));
    expect(result.occlusionFringePixels, 0);
    expect(_contrastFailures(result), hasLength(1));
  });

  testWidgets(
    'cache distinguishes black text on black from black-covered text',
    (tester) async {
      Widget scene(bool covered) => ColoredBox(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 70,
              child: _label('Cache adversarial text'),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: covered ? 1 : 0),
              ),
            ),
          ],
        ),
      );
      await _mount(tester, scene(false));
      final visible = await _audit(tester);
      expect(visible.runs, 1);
      expect(_contrastFailures(visible), hasLength(1));
      expect(_contrastFailures(visible).single['contrast'], 1);

      await _mount(tester, scene(true));
      final covered = await _audit(tester);
      expect(
        covered.cacheHit,
        isFalse,
        reason:
            'Identical original black pixels have different visibility probes',
      );
      expect(covered.runs, 0);
      expect(covered.paintedPixels, 0);
      expect(covered.failures, isEmpty);
      final repeated = await _audit(tester);
      expect(repeated.cacheHit, isTrue);
      expect(repeated.runs, 0);
      expect(repeated.failures, isEmpty);
    },
  );

  testWidgets('split-span combining mark receives its own visible ink audit', (
    tester,
  ) async {
    await _mount(
      tester,
      const Center(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'e',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: '\u0301',
                style: TextStyle(color: Color(0xFFAAAAAA)),
              ),
              TextSpan(
                text: ' ffi',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
    final result = await _audit(tester);
    expect(result.runs, 3);
    expect(_contrastFailures(result).map((failure) => failure['text']), [
      '\u0301',
    ]);
  });

  testWidgets(
    'Poppins 12.5 summary on pale card retains nominal secondary ink',
    (tester) async {
      await _mount(
        tester,
        const ColoredBox(
          color: Color(0xFFF4EFE5),
          child: Center(
            child: Text(
              '76% Aligned · Discuss 16% · Opposed 8%',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6E6257),
              ),
            ),
          ),
        ),
      );
      final result = await _audit(tester);
      expect(result.runs, 1);
      expect(result.paintedPixels, greaterThan(0));
      expect(result.failures, isEmpty);
    },
  );

  for (final pair in [
    (const Color(0xFF737874), 4.498958743458361, false),
    (const Color(0xFF71796F), 4.5000349651688705, true),
  ]) {
    testWidgets('strict 4.5 boundary ${pair.$2}', (tester) async {
      final ratio = 1.05 / (pair.$1.computeLuminance() + .05);
      expect(ratio, closeTo(pair.$2, 1e-12));
      await _mount(
        tester,
        Center(child: _label('Strict boundary', color: pair.$1)),
      );
      final result = await _audit(tester);
      expect(result.paintedPixels, greaterThan(0));
      expect(_contrastFailures(result).isEmpty, pair.$3);
      if (pair.$3) expect(result.failures, isEmpty);
    });
  }

  for (final boundary in [
    (24.0, FontWeight.w400, const Color(0xFF949494), true),
    (23.99, FontWeight.w400, const Color(0xFF949494), false),
    (23.99, FontWeight.w700, const Color(0xFF949494), false),
    (19.0, FontWeight.w700, const Color(0xFF949494), false),
    (24.0, FontWeight.w400, const Color(0xFF959595), false),
  ]) {
    testWidgets(
      '24pt boundary ${boundary.$1} w${boundary.$2.value} ${boundary.$3}',
      (tester) async {
        await _mount(
          tester,
          Center(
            child: _label(
              'Large text boundary',
              size: boundary.$1,
              weight: boundary.$2,
              color: boundary.$3,
            ),
          ),
        );
        final result = await _audit(tester);
        expect(result.paintedPixels, greaterThan(0));
        expect(_contrastFailures(result).isEmpty, boundary.$4);
        if (boundary.$4) {
          expect(result.failures, isEmpty);
        } else {
          expect(
            _contrastFailures(result).single['required_contrast'],
            boundary.$1 < 24 ? 4.5 : 3.0,
          );
        }
      },
    );
  }

  testWidgets(
    'ONE artwork in an actual monogram child stays ordinary small text',
    (tester) async {
      await _mount(
        tester,
        Center(
          child: ZyraGoldRingMonogram(
            name: 'Adam',
            size: 80,
            fontSize: 34,
            child: _label('ONE', color: const Color(0xFF949494)),
          ),
        ),
      );
      final result = await _audit(tester);
      expect(result.initials, 0);
      expect(_contrastFailures(result), hasLength(1));
      expect(_contrastFailures(result).single['required_contrast'], 4.5);
    },
  );

  testWidgets('provider G at 15pt is ordinary small text', (tester) async {
    await _mount(
      tester,
      Center(child: _label('G', size: 15, color: const Color(0xFF949494))),
    );
    final result = await _audit(tester);
    expect(result.initials, 0);
    expect(_contrastFailures(result), hasLength(1));
    expect(_contrastFailures(result).single['required_contrast'], 4.5);
  });

  testWidgets(
    'actual person initial uses 3 to 1 on its controlled gold background',
    (tester) async {
      final oldStubs = ZyraText.useTestFontStubs;
      final oldFamily = ZyraText.testReadingFontFamily;
      ZyraText.useTestFontStubs = true;
      ZyraText.testReadingFontFamily = _font;
      addTearDown(() {
        ZyraText.useTestFontStubs = oldStubs;
        ZyraText.testReadingFontFamily = oldFamily;
      });
      await _mount(
        tester,
        const Center(
          child: ColoredBox(
            color: Color(0xFFE6CB96),
            child: SizedBox(
              width: 120,
              height: 120,
              child: Center(
                child: ZyraGoldRingMonogram(
                  name: 'Adam',
                  size: 80,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
      final result = await _audit(tester);
      expect(result.runs, 1);
      expect(result.initials, 1);
      expect(result.paintedPixels, greaterThan(0));
      expect(result.failures, isEmpty);
    },
  );

  for (final size in [8.0, 10.0, 12.0, 14.0]) {
    for (final weight in [
      FontWeight.w200,
      FontWeight.w300,
      FontWeight.w400,
      FontWeight.w500,
    ]) {
      testWidgets(
        'Poppins ${size.toInt()} w${weight.value} narrow and descender glyphs',
        (tester) async {
          await _mount(
            tester,
            Center(
              child: _label(
                'iljtf gypq e\u0301 ffi',
                size: size,
                weight: weight,
              ),
            ),
          );
          final result = await _audit(tester);
          expect(result.runs, 1);
          expect(result.paintedPixels, greaterThan(0));
          expect(
            _contrastFailures(result),
            isEmpty,
            reason: 'Antialiasing must not dilute the nominal black ink',
          );
          if (weight.value < 400) {
            expect(result.failures, hasLength(1));
            expect(result.failures.single['weight_pass'], false);
          } else {
            expect(result.failures, isEmpty);
          }
        },
      );
    }
  }

  for (final clipped in [false, true]) {
    testWidgets(
      'actual footer fade band respects clipping=$clipped and foreground',
      (tester) async {
        final footer = CustomPaint(
          key: const ValueKey('compatibility-editor-scroll-edge-fade'),
          painter: const _FooterEdgePainter(),
          child: SizedBox(
            width: 360,
            height: 50,
            child: Align(
              alignment: Alignment.topRight,
              child: _label('Foreground bad', color: Colors.white),
            ),
          ),
        );
        await _mount(
          tester,
          Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 220,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 30,
                          child: _label(
                            'Outside band bad',
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          top: 160,
                          left: 4,
                          child: _label('Faded scrolling'),
                        ),
                        Positioned(
                          top: 160,
                          left: 210,
                          child: _label('Exposed bad', color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 130,
                left: 0,
                child: clipped
                    ? ClipRect(clipper: const _LeftHalfClip(), child: footer)
                    : footer,
              ),
            ],
          ),
        );
        final result = await _audit(tester);
        final failed = _contrastFailures(result).map((f) => f['text']).toSet();
        expect(result.exemptPixels, greaterThan(0));
        expect(failed, contains('Outside band bad'));
        expect(failed, isNot(contains('Faded scrolling')));
        expect(failed.contains('Exposed bad'), clipped);
        if (!clipped) expect(failed, contains('Foreground bad'));
      },
    );
  }

  testWidgets(
    'known footer fade does not exempt unrelated non-scrolling text',
    (tester) async {
      await _mount(
        tester,
        Stack(
          children: [
            Positioned(top: 185, child: _label('Static faded text')),
            Positioned(
              top: 130,
              left: 0,
              child: CustomPaint(
                key: const ValueKey('compatibility-editor-scroll-edge-fade'),
                painter: const _FooterEdgePainter(),
                child: const SizedBox(width: 360, height: 50),
              ),
            ),
          ],
        ),
      );
      final result = await _audit(tester);
      expect(result.exemptPixels, 0);
      expect(_contrastFailures(result).single['text'], 'Static faded text');
    },
  );

  group('audit harness restoration', () {
    Future<void> reflow(BaselineHarness h, String state) async {
      for (final size in [const Size(430, 932), const Size(375, 667)]) {
        for (final scale in [1.0, 1.3]) {
          final viewport = BaselineAuditViewport(size, scale);
          await h.withAuditViewport(viewport, () async {
            expect(h.auditViewportMismatch(viewport), isNull);
            final scrolls = h.tester
                .stateList<ScrollableState>(find.byType(Scrollable))
                .toList();
            for (final scroll in scrolls) {
              if (scroll.mounted && scroll.position.axis == Axis.vertical) {
                scroll.position.jumpTo(scroll.position.maxScrollExtent);
                await h.tester.pump();
                await h.tester.pump();
              }
            }
          });
        }
      }
    }

    setUpAll(() {
      baselineTextAuditOnly = true;
      baselineTextAudit = reflow;
    });
    tearDownAll(() {
      baselineTextAudit = null;
      baselineTextAuditOnly = false;
    });
    // Reuse the real Settings route and every row-action assertion. These
    // controls used to lose the lazy-list anchor after the first audit.
    settings.main();

    testWidgets('unkeyed responsive scrolls restore their exact child slots', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final callback = baselineTextAudit;
      baselineTextAudit = null;
      try {
        final h = BaselineHarness(tester, group: 'unkeyed-scroll-control');
        await h.mountPresentation(
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: false,
            tab: 0,
            pages: const [],
            model: ViewRequestDraftModel(capacity: 3).snapshot(),
          ),
          child: Scaffold(
            body: LayoutBuilder(
              builder: (context, bounds) {
                final columns = Column(
                  children: [
                    for (var index = 0; index < 2; index++)
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            height: 1600,
                            child: Column(
                              children: [
                                const SizedBox(height: 600),
                                Text(
                                  'Anchor $index',
                                  key: ValueKey('unkeyed-anchor-$index'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
                return bounds.maxWidth < 400
                    ? Center(child: columns)
                    : Padding(padding: EdgeInsets.zero, child: columns);
              },
            ),
          ),
        );
        final originals = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .toList();
        expect(originals, hasLength(2));
        originals[0].position.jumpTo(220);
        originals[1].position.jumpTo(440);
        await tester.pump();
        final anchorRects = [
          for (var index = 0; index < 2; index++)
            tester.getRect(find.byKey(ValueKey('unkeyed-anchor-$index'))),
        ];
        for (final size in [const Size(430, 932), const Size(375, 667)]) {
          for (final scale in [1.0, 1.3]) {
            await h.withAuditViewport(
              BaselineAuditViewport(size, scale),
              () async {
                for (final state in tester.stateList<ScrollableState>(
                  find.byType(Scrollable),
                )) {
                  state.position.jumpTo(state.position.maxScrollExtent);
                }
                await tester.pump();
              },
            );
            final restored = tester
                .stateList<ScrollableState>(find.byType(Scrollable))
                .toList();
            expect(restored.map((state) => state.position.pixels), [220, 440]);
            for (var index = 0; index < 2; index++) {
              expect(
                tester.getRect(find.byKey(ValueKey('unkeyed-anchor-$index'))),
                anchorRects[index],
              );
            }
          }
        }
        final restored = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .toList();
        expect(restored[0], isNot(same(originals[0])));
        expect(restored[1], isNot(same(originals[1])));
      } finally {
        baselineTextAudit = callback;
      }
    });

    testWidgets(
      'real compatibility reader restores real page without sentinel',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final callback = baselineTextAudit;
        baselineTextAudit = null;
        try {
          final h = BaselineHarness(tester, group: 'real-score-page-control');
          await h.mountPresentation(
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: ViewRequestDraftModel(capacity: 3).snapshot(),
              tab: 0,
              pages: const [],
            ),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  height: 400,
                  child: ZyraCompatibilityScoreReader(
                    personName: 'Sara',
                    overallScore: 73,
                  ),
                ),
              ),
            ),
          );
          final pages = find.byKey(
            const ValueKey('draft_compatibility_score_pages'),
          );
          final controller = tester.widget<PageView>(pages).controller!;
          controller.jumpToPage(0);
          await tester.pump();
          expect(
            controller.page!.round(),
            2,
            reason: 'Real loop recentering makes sentinel zero unrestorable',
          );
          controller.jumpToPage(1);
          await tester.pump();
          final originalOffset = controller.offset;
          for (final size in [const Size(430, 932), const Size(375, 667)]) {
            for (final scale in [1.0, 1.3]) {
              await h.withAuditViewport(
                BaselineAuditViewport(size, scale),
                () async {
                  tester.widget<PageView>(pages).controller!.jumpToPage(2);
                  await tester.pump();
                },
              );
              final restored = tester.widget<PageView>(pages).controller!;
              expect(restored.page!.round(), 1);
              expect(restored.offset, originalOffset);
            }
          }
        } finally {
          baselineTextAudit = callback;
        }
      },
    );

    for (final change in ['type', 'key', 'cardinality']) {
      testWidgets('unkeyed restoration rejects a changed $change path', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final callback = baselineTextAudit;
        baselineTextAudit = null;
        try {
          var changed = false;
          late StateSetter update;
          final h = BaselineHarness(tester, group: 'unkeyed-$change-negative');
          await h.mountPresentation(
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              tab: 0,
              pages: const [],
              model: ViewRequestDraftModel(capacity: 3).snapshot(),
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return LayoutBuilder(
                  builder: (context, bounds) {
                    final column = Column(
                      children: [
                        if (changed && change == 'cardinality')
                          const SizedBox(height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            child: const SizedBox(height: 1600),
                          ),
                        ),
                      ],
                    );
                    if (bounds.maxWidth < 400 ||
                        (changed && change == 'type')) {
                      return Center(child: column);
                    }
                    return Padding(
                      key: change == 'key'
                          ? ValueKey(changed ? 'changed' : 'original')
                          : null,
                      padding: EdgeInsets.zero,
                      child: column,
                    );
                  },
                );
              },
            ),
          );
          Object? failure;
          try {
            await h.withAuditViewport(
              const BaselineAuditViewport(Size(375, 667), 1.3),
              () async => update(() => changed = true),
            );
          } catch (error) {
            failure = error;
          }
          expect(failure, isA<TestFailure>());
        } finally {
          baselineTextAudit = callback;
        }
      });
    }

    for (final change in [
      'preserve',
      'editable',
      'filled',
      'app-controller',
      'app-key',
      'hint',
      'focused',
    ]) {
      testWidgets('empty read-only display restoration: $change', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final callback = baselineTextAudit;
        baselineTextAudit = null;
        final controllers = [TextEditingController(), TextEditingController()];
        try {
          var changed = false;
          late StateSetter update;
          final h = BaselineHarness(tester, group: 'readonly-$change-control');
          await h.mountPresentation(
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: ViewRequestDraftModel(capacity: 3).snapshot(),
              tab: 0,
              pages: const [],
            ),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return LayoutBuilder(
                    builder: (context, bounds) {
                      final field = TextField(
                        key: ValueKey(
                          changed && change == 'app-key'
                              ? 'changed-readonly-display'
                              : 'readonly-display',
                        ),
                        controller: change == 'app-controller'
                            ? controllers[changed ? 1 : 0]
                            : null,
                        readOnly: change != 'editable',
                        autofocus: change == 'focused',
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: changed && change == 'hint'
                              ? 'Changed display'
                              : 'In your own words…',
                        ),
                      );
                      return bounds.maxWidth < 400
                          ? Center(child: field)
                          : Padding(padding: EdgeInsets.zero, child: field);
                    },
                  );
                },
              ),
            ),
          );
          final original = tester.widget<EditableText>(
            find.byType(EditableText),
          );
          if (change == 'filled') {
            original.controller.value = const TextEditingValue(
              text: 'Retained display',
              selection: TextSelection.collapsed(offset: 16),
            );
            await tester.pump();
          }
          if (change == 'focused') expect(original.focusNode.hasFocus, isTrue);
          Object? failure;
          try {
            await h.withAuditViewport(
              const BaselineAuditViewport(Size(375, 667), 1.3),
              () async {
                update(() => changed = true);
                await tester.pump();
              },
            );
          } catch (error) {
            failure = error;
          }
          if (change == 'preserve') {
            expect(failure, isNull);
            final restored = tester.widget<EditableText>(
              find.byType(EditableText),
            );
            expect(restored.controller, isNot(same(original.controller)));
            expect(restored.controller.value, TextEditingValue.empty);
          } else {
            expect(failure, isA<TestFailure>());
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          for (final controller in controllers) {
            controller.dispose();
          }
          baselineTextAudit = callback;
        }
      });
    }

    for (final change in ['preserve', 'outer-controller', 'app-key']) {
      testWidgets('nested scroll chrome keeps ownership: $change', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final callback = baselineTextAudit;
        baselineTextAudit = null;
        final controllers = [
          ScrollController(),
          ScrollController(),
          ScrollController(),
        ];
        final appKeys = [GlobalKey(), GlobalKey()];
        try {
          var changed = false;
          late StateSetter update;
          final h = BaselineHarness(
            tester,
            group: 'scroll-chrome-$change-control',
          );
          await h.mountPresentation(
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: ViewRequestDraftModel(capacity: 3).snapshot(),
              tab: 0,
              pages: const [],
            ),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return LayoutBuilder(
                    builder: (context, bounds) {
                      final swapped = changed && change == 'outer-controller';
                      final content = Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              controller: controllers[swapped ? 1 : 0],
                              child: SizedBox(
                                height: 1600,
                                child: Column(
                                  children: [
                                    Semantics(
                                      child: IgnorePointer(
                                        key: change == 'app-key'
                                            ? appKeys[changed ? 1 : 0]
                                            : null,
                                        child: SizedBox(
                                          height: 200,
                                          child: SingleChildScrollView(
                                            controller: controllers[2],
                                            child: const SizedBox(height: 900),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: controllers[swapped ? 0 : 1],
                              child: const SizedBox(height: 1600),
                            ),
                          ),
                        ],
                      );
                      return bounds.maxWidth < 400
                          ? Center(child: content)
                          : Padding(padding: EdgeInsets.zero, child: content);
                    },
                  );
                },
              ),
            ),
          );
          final originals = tester
              .stateList<ScrollableState>(find.byType(Scrollable))
              .toList();
          expect(originals, hasLength(3));
          for (var index = 0; index < 3; index++) {
            originals[index].position.jumpTo(20.0 * (index + 1));
          }
          await tester.pump();
          Object? failure;
          try {
            await h.withAuditViewport(
              const BaselineAuditViewport(Size(375, 667), 1.3),
              () async {
                update(() => changed = true);
                await tester.pump();
                for (final state in tester.stateList<ScrollableState>(
                  find.byType(Scrollable),
                )) {
                  state.position.jumpTo(state.position.maxScrollExtent);
                }
              },
            );
          } catch (error) {
            failure = error;
          }
          if (change == 'preserve') {
            expect(failure, isNull);
            expect(
              tester
                  .stateList<ScrollableState>(find.byType(Scrollable))
                  .map((state) => state.position.pixels),
              [20, 40, 60],
            );
            expect(
              tester
                  .stateList<ScrollableState>(find.byType(Scrollable))
                  .toList()[1],
              isNot(same(originals[1])),
              reason: 'The nested scroll must actually remount',
            );
          } else {
            expect(failure, isA<TestFailure>());
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          for (final controller in controllers) {
            controller.dispose();
          }
          baselineTextAudit = callback;
        }
      });
    }

    for (final change in [
      'preserve',
      'controller',
      'explicit-focus',
      'focused-generated',
    ]) {
      testWidgets('editable restoration identity: $change', (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final callback = baselineTextAudit;
        baselineTextAudit = null;
        final controllers = [
          TextEditingController(text: 'First long input ' * 20),
          TextEditingController(text: 'Second long input ' * 20),
        ];
        final focuses = [FocusNode(), FocusNode(), FocusNode()];
        try {
          var changed = false;
          late StateSetter update;
          final h = BaselineHarness(tester, group: 'editable-$change-control');
          await h.mountPresentation(
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: ViewRequestDraftModel(capacity: 3).snapshot(),
              tab: 0,
              pages: const [],
            ),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return LayoutBuilder(
                    builder: (context, bounds) {
                      final inputs = Column(
                        children: [
                          TextField(
                            key: const ValueKey('identity-input-0'),
                            controller:
                                controllers[changed && change == 'controller'
                                    ? 1
                                    : 0],
                            focusNode: change == 'focused-generated'
                                ? null
                                : focuses[changed && change == 'explicit-focus'
                                      ? 2
                                      : 0],
                          ),
                          TextField(
                            key: const ValueKey('identity-input-1'),
                            controller: controllers[1],
                            focusNode: focuses[1],
                          ),
                        ],
                      );
                      return bounds.maxWidth < 400
                          ? Center(child: inputs)
                          : Padding(padding: EdgeInsets.zero, child: inputs);
                    },
                  );
                },
              ),
            ),
          );
          if (change == 'focused-generated') {
            await tester.tap(find.byKey(const ValueKey('identity-input-0')));
            await tester.pump();
            expect(
              tester
                  .widgetList<EditableText>(find.byType(EditableText))
                  .first
                  .focusNode
                  .hasFocus,
              isTrue,
            );
          }
          final scrolls = tester
              .stateList<ScrollableState>(find.byType(Scrollable))
              .toList();
          expect(scrolls, hasLength(2));
          scrolls[0].position.jumpTo(5);
          scrolls[1].position.jumpTo(10);
          await tester.pump();
          Object? failure;
          try {
            await h.withAuditViewport(
              const BaselineAuditViewport(Size(375, 667), 1.3),
              () async {
                update(() => changed = true);
                await tester.pump();
                for (final state in tester.stateList<ScrollableState>(
                  find.byType(Scrollable),
                )) {
                  state.position.jumpTo(state.position.maxScrollExtent);
                }
              },
            );
          } catch (error) {
            failure = error;
          }
          if (change == 'preserve') {
            expect(failure, isNull);
            expect(
              tester
                  .stateList<ScrollableState>(find.byType(Scrollable))
                  .map((state) => state.position.pixels),
              [5, 10],
            );
          } else {
            expect(failure, isA<TestFailure>());
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          for (final controller in controllers) {
            controller.dispose();
          }
          for (final focus in focuses) {
            focus.dispose();
          }
          baselineTextAudit = callback;
        }
      });
    }

    for (final ready in [true, false]) {
      testWidgets(
        'initial raster audit requires presentation readiness=$ready',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final callback = baselineTextAudit;
          var prepared = false;
          var audits = 0;
          late StateSetter publish;
          baselineTextAudit = (h, state) async {
            expect(prepared, isTrue);
            expect(
              find.byKey(const ValueKey(('ready-scene', true))),
              findsOneWidget,
            );
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
            );
            final result = await auditZyraRenderedText(tester, boundary);
            expect(result.runs, greaterThan(0));
            expect(result.failures, isEmpty);
            audits++;
          };
          try {
            final h = BaselineHarness(
              tester,
              group: 'initial-readiness-$ready',
            );
            Object? failure;
            try {
              await h.mountPresentation(
                checkpoint: ZyraPreviewNavigationCheckpoint(
                  guardian: false,
                  model: ViewRequestDraftModel(capacity: 3).snapshot(),
                  tab: 0,
                  pages: const [],
                ),
                waitForPresentation: () async {
                  expect(
                    audits,
                    0,
                    reason: 'Never audit the unprepared app key',
                  );
                  expect(
                    find.byKey(const ValueKey(('ready-scene', false))),
                    findsOneWidget,
                  );
                  var signal = false;
                  await tester.runAsync(() async {
                    signal = ready;
                  });
                  for (var attempt = 0; attempt < 3 && !signal; attempt++) {
                    await tester.pump();
                  }
                  expect(
                    signal,
                    isTrue,
                    reason: 'Bounded public readiness precondition',
                  );
                  publish(() => prepared = signal);
                  await tester.pump();
                },
                child: StatefulBuilder(
                  builder: (context, setState) {
                    publish = setState;
                    return ColoredBox(
                      key: ValueKey(('ready-scene', prepared)),
                      color: Colors.white,
                      child: Center(
                        child: _label(
                          prepared ? 'Prepared scene' : 'Preparing',
                        ),
                      ),
                    );
                  },
                ),
              );
            } catch (error) {
              failure = error;
            }
            if (ready) {
              expect(failure, isNull);
              expect(
                audits,
                1,
                reason: 'The post-ready initial audit is unconditional',
              );
            } else {
              expect(failure, isA<TestFailure>());
              expect(
                audits,
                0,
                reason: 'Failed readiness cannot create passing evidence',
              );
            }
          } finally {
            baselineTextAudit = callback;
          }
        },
      );
    }

    testWidgets('cold image first frame covers the actual closed action tray', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final callback = baselineTextAudit;
      final stream = _DeferredAuditImageStream();
      final provider = _DeferredAuditImage(stream);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(Colors.white, BlendMode.src);
      final picture = recorder.endRecording();
      final image = await tester.runAsync(() => picture.toImage(1, 1));
      picture.dispose();
      var audits = 0;
      baselineTextAudit = (h, state) async {
        expect(
          tester.widget<RawImage>(find.byType(RawImage)).image,
          isNull,
          reason: 'This control starts before the real first image frame',
        );
        await tester.runAsync(() async {
          Timer.run(() => stream.deliver(ImageInfo(image: image!)));
        });
        await h.prepareRasterFrame();
        expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
        );
        final result = await auditZyraRenderedText(tester, boundary);
        expect(result.failures, isEmpty);
        expect(
          result.runs,
          1,
          reason: 'Only the foreground title paints; covered tray earns no run',
        );
        audits++;
      };
      try {
        await BaselineHarness(
          tester,
          group: 'cold-image-first-frame',
        ).mountPresentation(
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: false,
            model: ViewRequestDraftModel(capacity: 1).snapshot(),
            tab: 4,
            pages: const ['manage_photos'],
          ),
          child: Material(
            color: Colors.white,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(child: _label('Closed tray')),
                Image(image: provider, fit: BoxFit.cover),
                Positioned(top: 80, child: _label('Photos')),
              ],
            ),
          ),
        );
        expect(audits, 1);
      } finally {
        baselineTextAudit = callback;
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('failed image first frame cannot become passing raster proof', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final callback = baselineTextAudit;
      final stream = _DeferredAuditImageStream();
      var audits = 0;
      baselineTextAudit = (h, state) async {
        await tester.runAsync(() async => Timer.run(stream.fail));
        await h.prepareRasterFrame();
        audits++;
      };
      try {
        Object? failure;
        try {
          await BaselineHarness(
            tester,
            group: 'failed-image-first-frame',
          ).mountPresentation(
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: ViewRequestDraftModel(capacity: 1).snapshot(),
              tab: 4,
              pages: const ['manage_photos'],
            ),
            child: Material(
              child: Image(
                image: _DeferredAuditImage(stream),
                errorBuilder: (context, error, stack) =>
                    const SizedBox.expand(),
              ),
            ),
          );
        } catch (error) {
          failure = error;
        }
        expect(failure, isA<StateError>());
        expect(audits, 0);
      } finally {
        baselineTextAudit = callback;
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    for (final scenario in [
      (
        mode: 'ready',
        name: 'mounted cached PageView image settles before audit capture',
      ),
      (
        mode: 'error',
        name: 'cached image first-frame error rejects before any raster proof',
      ),
      (
        mode: 'bounded',
        name:
            'cached image readiness stays four-pass bounded and disposes listeners',
      ),
    ]) {
      testWidgets(scenario.name, (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final callback = baselineTextAudit;
        baselineTextAudit = null;
        final stream = _TrackedDeferredAuditImageStream();
        final controller = PageController();
        ui.Image? image;
        var delivered = false;
        var completedAudits = 0;
        var preparations = 0;
        try {
          if (scenario.mode != 'error') {
            final recorder = ui.PictureRecorder();
            Canvas(recorder).drawColor(Colors.white, BlendMode.src);
            final picture = recorder.endRecording();
            image = await tester.runAsync(() => picture.toImage(1, 1));
            picture.dispose();
          }
          stream.onFirstReadinessListener = () {
            Timer.run(() {
              if (scenario.mode == 'error') {
                stream.fail();
              } else {
                delivered = true;
                stream.deliver(ImageInfo(image: image!));
              }
            });
          };
          final h = BaselineHarness(tester, group: 'cached-image-readiness');
          await h.mountPresentation(
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: ViewRequestDraftModel(capacity: 1).snapshot(),
              tab: 4,
              pages: const ['manage_photos'],
            ),
            child: Material(
              color: Colors.white,
              child: PageView(
                controller: controller,
                allowImplicitScrolling: true,
                children: [
                  Center(child: _label('Visible cached-image page')),
                  Image(
                    image: _DeferredAuditImage(stream),
                    fit: BoxFit.cover,
                    frameBuilder: scenario.mode == 'bounded'
                        ? (context, child, frame, synchronous) =>
                              const SizedBox.expand()
                        : null,
                    errorBuilder: (context, error, stack) =>
                        const SizedBox.expand(),
                  ),
                ],
              ),
            ),
          );
          final allImages = find.byType(Image, skipOffstage: false);
          final allRawImages = find.byType(RawImage, skipOffstage: false);
          expect(find.byType(Image), findsNothing);
          expect(allImages, findsOneWidget);
          expect(stream.listenerCount, 1);
          expect(stream.readinessAdds, 0);
          if (scenario.mode == 'bounded') {
            expect(allRawImages, findsNothing);
          } else {
            expect(tester.widget<RawImage>(allRawImages).image, isNull);
          }
          final hiddenElement = allImages.evaluate().single;
          final hiddenRenderObject = hiddenElement.renderObject;
          final scrollPixels = controller.position.pixels;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
          );
          Object? failure;
          ZyraRenderedTextAudit? result;
          try {
            result = await auditZyraRenderedText(
              tester,
              boundary,
              prepareBeforeCapture: () async {
                preparations++;
                await h.prepareRasterFrame();
                expect(tester.widget<RawImage>(allRawImages).image, isNotNull);
              },
            );
            completedAudits++;
          } catch (error) {
            failure = error;
          }
          expect(preparations, 1);
          if (scenario.mode == 'ready') {
            expect(failure, isNull);
            expect(completedAudits, 1);
            expect(result!.failures, isEmpty);
            expect(result.runs, 1);
            expect(stream.readinessAdds, 1);
          } else {
            expect(completedAudits, 0);
            if (scenario.mode == 'error') {
              expect(failure, isA<StateError>());
              expect(stream.readinessAdds, 1);
            } else {
              expect(failure, isA<TestFailure>());
              expect(failure.toString(), contains('four passes'));
              expect(stream.readinessAdds, 4);
            }
          }
          expect(stream.readinessListenerCount, 0);
          expect(stream.readinessRemoves, stream.readinessAdds);
          expect(identical(allImages.evaluate().single, hiddenElement), isTrue);
          if (scenario.mode == 'ready') {
            expect(
              identical(hiddenElement.renderObject, hiddenRenderObject),
              isTrue,
            );
          }
          expect(controller.position.pixels, scrollPixels);
          expect(find.byType(Image), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          baselineTextAudit = callback;
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
          if (!delivered) image?.dispose();
          expect(stream.listenerCount, 0);
        }
      });
    }

    testWidgets(
      'actual nested native notifier during once-only readiness settles before capture',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final callback = baselineTextAudit;
        baselineTextAudit = null;
        ZyraAccountState.resetForTesting();
        final realZone = (await tester.runAsync(() async => Zone.current))!;
        final response = realZone.run(() => Completer<Object?>());
        final notified = realZone.run(() => Completer<void>());
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(zyraPhoneAccessChannel, (
          call,
        ) async {
          if (call.method == 'status') return response.future;
          if (call.method == 'cancel') return null;
          throw StateError('Unexpected native method ${call.method}');
        });
        ZyraPhoneAccessController? controller;
        var preparing = false;
        var arrivedDuringReadiness = false;
        var preparations = 0;
        var verifications = 0;
        void nativeNotification() {
          arrivedDuringReadiness = preparing;
          if (!notified.isCompleted) notified.complete();
        }

        try {
          final h = BaselineHarness(
            tester,
            group: 'native-readiness-handoff',
            logicalSize: const Size(375, 667),
          );
          await h.mountPresentation(
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: ViewRequestDraftModel(capacity: 1).snapshot(),
              tab: 4,
              pages: const ['phone_access'],
            ),
            child: _isolatedScope(
              ZyraPhoneAccessPage(canAct: () => true, onBack: () {}),
            ),
          );
          controller = tester
              .widget<ZyraPhoneAccessPresentation>(
                find.byType(ZyraPhoneAccessPresentation),
              )
              .controller;
          controller.addListener(nativeNotification);
          expect(controller.label(ZyraPhonePermission.location), 'Ask first');
          expect(find.text('While using'), findsNothing);
          final scheduledCallback = tester.binding.buildOwner!.onBuildScheduled;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
          );
          final result = await auditZyraRenderedText(
            tester,
            boundary,
            prepareBeforeCapture: () async {
              preparations++;
              await h.prepareRasterFrame();
              preparing = true;
              try {
                await tester.runAsync(() async {
                  Timer.run(
                    () => response.complete(<String, String>{
                      'location': 'allowed',
                    }),
                  );
                  await notified.future.timeout(const Duration(seconds: 2));
                });
                expect(arrivedDuringReadiness, isTrue);
                expect(
                  controller!.label(ZyraPhonePermission.location),
                  'While using',
                );
                expect(
                  find.text('While using'),
                  findsNothing,
                  reason: 'The actual nested builder is still pending',
                );
              } finally {
                preparing = false;
              }
            },
            verifyBeforeCapture: () {
              verifications++;
              expect(find.text('While using'), findsOneWidget);
            },
          );
          expect(preparations, 1);
          expect(verifications, 1);
          expect(arrivedDuringReadiness, isTrue);
          expect(result.failures, isEmpty);
          expect(result.runs, greaterThan(0));
          expect(
            tester.binding.buildOwner!.onBuildScheduled,
            same(scheduledCallback),
          );
          expect(tester.takeException(), isNull);
        } finally {
          preparing = false;
          controller?.removeListener(nativeNotification);
          if (!response.isCompleted) response.complete(<String, String>{});
          baselineTextAudit = callback;
          await tester.pumpWidget(const SizedBox.shrink());
          messenger.setMockMethodCallHandler(zyraPhoneAccessChannel, null);
          ZyraAccountState.resetForTesting();
        }
      },
    );

    testWidgets(
      'layout-mounted unresolved image rejects before capture without readiness retry',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final callback = baselineTextAudit;
        baselineTextAudit = null;
        final stream = _TrackedDeferredAuditImageStream();
        const layoutKey = ValueKey('image-readiness-handoff-layout');
        var introduceImage = false;
        var layouts = 0;
        var preparations = 0;
        var verifications = 0;
        try {
          final h = BaselineHarness(tester, group: 'image-layout-handoff');
          await h.mountPresentation(
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: ViewRequestDraftModel(capacity: 1).snapshot(),
              tab: 4,
              pages: const ['manage_photos'],
            ),
            child: Material(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _label('Layout image guard'),
                  Center(
                    child: SizedBox(
                      key: layoutKey,
                      width: 120,
                      height: 80,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          layouts++;
                          return introduceImage
                              ? Image(image: _DeferredAuditImage(stream))
                              : const SizedBox.expand();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          expect(find.byType(Image, skipOffstage: false), findsNothing);
          final initialLayouts = layouts;
          final scheduledCallback = tester.binding.buildOwner!.onBuildScheduled;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
          );
          final result = await auditZyraRenderedText(
            tester,
            boundary,
            prepareBeforeCapture: () async {
              preparations++;
              await h.prepareRasterFrame();
              introduceImage = true;
              // Change only render constraints: there is no dirty Element to
              // build yet. Final flushLayout runs this LayoutBuilder.
              tester
                  .renderObject<RenderConstrainedBox>(find.byKey(layoutKey))
                  .additionalConstraints = const BoxConstraints.tightFor(
                width: 121,
                height: 80,
              );
              expect(layouts, initialLayouts);
              expect(find.byType(Image, skipOffstage: false), findsNothing);
            },
            verifyBeforeCapture: () => verifications++,
          );
          expect(layouts, initialLayouts + 1);
          expect(find.byType(Image, skipOffstage: false), findsOneWidget);
          expect(
            tester
                .widget<RawImage>(find.byType(RawImage, skipOffstage: false))
                .image,
            isNull,
          );
          expect(preparations, 1);
          expect(verifications, 0);
          expect(result.rasterImages, 0);
          expect(result.runs, 0);
          expect(result.cacheHit, isFalse);
          expect(
            result.failures.single['coverage_error'],
            contains('mounted image lost first-frame readiness'),
          );
          expect(stream.readinessAdds, 0);
          expect(stream.readinessListenerCount, 0);
          expect(
            tester.binding.buildOwner!.onBuildScheduled,
            same(scheduledCallback),
          );
          expect(tester.takeException(), isNull);
        } finally {
          baselineTextAudit = callback;
          await tester.pumpWidget(const SizedBox.shrink());
          expect(stream.listenerCount, 0);
        }
      },
    );

    testWidgets('pending async notifier builds before sliver raster layout', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final callback = baselineTextAudit;
      final status = ValueNotifier<String>('Pending');
      var audits = 0;
      baselineTextAudit = (h, state) async {
        expect(status.value, 'Pending');
        await tester.runAsync(() async {
          Timer.run(() => status.value = 'Ready');
        });
        await h.prepareRasterFrame();
        expect(status.value, 'Ready');
        for (final viewport in [
          const BaselineAuditViewport(Size(430, 932), 1),
          const BaselineAuditViewport(Size(375, 667), 1),
          const BaselineAuditViewport(Size(430, 932), 1.3),
          const BaselineAuditViewport(Size(375, 667), 1.3),
        ]) {
          await h.withAuditViewport(viewport, () async {
            final scroll = tester.state<ScrollableState>(
              find.byType(Scrollable),
            );
            scroll.position.jumpTo(scroll.position.maxScrollExtent);
            await tester.pump();
            await h.prepareRasterFrame();
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
            );
            final result = await auditZyraRenderedText(tester, boundary);
            expect(result.failures, isEmpty);
            expect(result.runs, greaterThan(0));
            expect(tester.takeException(), isNull);
          });
        }
        audits++;
      };
      try {
        await BaselineHarness(
          tester,
          group: 'async-sliver-notifier',
        ).mountPresentation(
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: false,
            model: ViewRequestDraftModel(capacity: 1).snapshot(),
            tab: 4,
            pages: const ['phone_access'],
          ),
          child: Material(
            color: Colors.white,
            child: ListenableBuilder(
              listenable: status,
              builder: (context, child) => ListView.builder(
                itemCount: 40,
                itemBuilder: (context, index) => SizedBox(
                  height: 70,
                  child: _label('${status.value} permission $index'),
                ),
              ),
            ),
          ),
        );
        expect(audits, 1);
      } finally {
        baselineTextAudit = callback;
        await tester.pumpWidget(const SizedBox.shrink());
        status.dispose();
      }
    });

    testWidgets('a nested forced scaler cannot claim a canonical tuple', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final callback = baselineTextAudit;
      baselineTextAudit = null;
      try {
        final h = BaselineHarness(tester, group: 'canonical-negative-control');
        await h.mount();
        final shell = tester.widget<ZyraOneJourneyConceptShell>(
          find.byType(ZyraOneJourneyConceptShell),
        );
        final checkpoint = h.latest;
        await h.mountPresentation(
          checkpoint: checkpoint,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: shell,
            ),
          ),
        );
        const viewport = BaselineAuditViewport(Size(375, 667), 1.3);
        await h.withAuditViewport(viewport, () async {
          expect(
            h.auditViewportMismatch(viewport),
            contains('differs from assigned 375x667@1.3'),
          );
        });
      } finally {
        baselineTextAudit = callback;
      }
    });
  });
}
