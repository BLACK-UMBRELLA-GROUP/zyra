// Whole-card presentation only: photograph, identity, markers and outline are
// one current child. Navigation, photo paging and member authority are external.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_card_metrics.dart';
import 'package:zyra/widgets/zyra_browse_next_photo_motion.dart';

const _boundary = ValueKey('next-motion-paint');
const _subject = ValueKey('next-motion-subject');
const _firstColor = Color(0xffd42c41);
const _nextColor = Color(0xff1f5bdd);
const _thirdColor = Color(0xff2caa62);
const _gold = Color(0xffffcc66);
const _size = Size(200, 320);
final _choices = ZyraBrowseNextMotion.values
    .where((style) => style != ZyraBrowseNextMotion.current)
    .toList();

Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _transform => _key('browse_next_motion_transform');
Finder get _clip => _key('browse_next_motion_clip');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Card-motion fixtures must remain offline.');
  }
}

class _Member extends StatefulWidget {
  const _Member({
    required this.id,
    required this.color,
    required this.lifecycle,
    this.onTap,
  });

  final String id;
  final Color color;
  final List<String> lifecycle;
  final VoidCallback? onTap;

  @override
  State<_Member> createState() => _MemberState();
}

class _MemberState extends State<_Member> {
  @override
  void initState() {
    super.initState();
    widget.lifecycle.add('mount:${widget.id}');
  }

  @override
  void dispose() {
    widget.lifecycle.add('dispose:${widget.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Member ${widget.id}',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: ClipRRect(
        key: ValueKey('member_round_${widget.id}'),
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              key: ValueKey('member_photo_${widget.id}'),
              color: widget.color,
            ),
            Positioned(
              left: 14,
              top: 130,
              child: SizedBox(
                key: ValueKey('member_markers_${widget.id}'),
                width: 6,
                height: 22,
                child: Column(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 20,
              child: Text(widget.id, key: ValueKey('member_name_${widget.id}')),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  key: ValueKey('member_frame_${widget.id}'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      ZyraCardMetrics.cardRadius,
                    ),
                    border: Border.all(color: _gold, width: 5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _app({
  required List<String> lifecycle,
  String id = 'first',
  int epoch = 0,
  ZyraBrowseNextMotion style = ZyraBrowseNextMotion.current,
  Color color = _firstColor,
  Size size = _size,
  bool quiet = false,
  bool accessible = false,
  VoidCallback? onTap,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(disableAnimations: quiet, accessibleNavigation: accessible),
    child: child!,
  ),
  home: Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            key: const ValueKey('fixed-header'),
            width: size.width,
            height: 40,
            child: const Text('Browse'),
          ),
          RepaintBoundary(
            key: _boundary,
            child: SizedBox.fromSize(
              size: size,
              child: ZyraBrowseNextPhotoMotion(
                key: _subject,
                profileId: id,
                epoch: epoch,
                style: style,
                child: _Member(
                  id: id,
                  color: color,
                  lifecycle: lifecycle,
                  onTap: onTap,
                ),
              ),
            ),
          ),
          SizedBox(
            key: const ValueKey('fixed-footer'),
            width: size.width,
            height: 40,
            child: const Text('Request a Journey'),
          ),
        ],
      ),
    ),
  ),
);

List<double> _matrix(WidgetTester tester) =>
    tester.widget<Transform>(_transform).transform.storage.toList();

void _identity(WidgetTester tester) {
  final matrix = _matrix(tester);
  for (var index = 0; index < matrix.length; index++) {
    expect(matrix[index], closeTo(index % 5 == 0 ? 1 : 0, .000001));
  }
}

int _duration(ZyraBrowseNextMotion style) => switch (style) {
  ZyraBrowseNextMotion.current => 0,
  ZyraBrowseNextMotion.cardGlide => 680,
  ZyraBrowseNextMotion.cardRise ||
  ZyraBrowseNextMotion.fanTurn ||
  ZyraBrowseNextMotion.cardDeal => 720,
  ZyraBrowseNextMotion.springPop => 850,
  ZyraBrowseNextMotion.cardRock => 900,
  ZyraBrowseNextMotion.hingeTurn || ZyraBrowseNextMotion.forwardFlip => 800,
  ZyraBrowseNextMotion.arcEntrance => 880,
  ZyraBrowseNextMotion.elasticCard => 760,
};

double _between(double start, double end, double t) =>
    start + (end - start) * Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));

void _appearance(
  WidgetTester tester,
  ZyraBrowseNextMotion style,
  int elapsed, {
  Size size = _size,
}) {
  final t = elapsed / _duration(style);
  final eased = Curves.easeInOutCubic.transform(t);
  final r = 1 - eased;
  final matrix = _matrix(tester);
  const tolerance = .0001;
  final dx = matrix[12];
  final dy = matrix[13];
  final angleZ = math.atan2(matrix[1], matrix[0]);
  switch (style) {
    case ZyraBrowseNextMotion.cardGlide:
      expect(dx, closeTo(size.width * .12 * r, tolerance));
      expect(dy, closeTo(0, tolerance));
      expect(angleZ, closeTo(0, tolerance));
      if (elapsed == 100) {
        expect(dx, greaterThan(size.width * .10));
      }
    case ZyraBrowseNextMotion.cardRise:
      expect(dy, closeTo(size.height * .10 * r, tolerance));
      expect(dx, closeTo(0, tolerance));
      expect(angleZ, closeTo(0, tolerance));
      if (elapsed == 100) {
        expect(dy, greaterThan(size.height * .08));
      }
    case ZyraBrowseNextMotion.springPop:
      final scale = t < .32
          ? _between(.64, .96, t / .32)
          : t < .54
          ? _between(.96, .87, (t - .32) / .22)
          : _between(.87, 1, (t - .54) / .46);
      expect(matrix[0], closeTo(scale, tolerance));
      expect(matrix[5], closeTo(scale, tolerance));
      expect(dx, closeTo(0, tolerance));
      expect(dy, closeTo(0, tolerance));
    case ZyraBrowseNextMotion.cardRock:
      expect(
        angleZ,
        closeTo(.105 * math.cos(3 * math.pi * t) * (1 - t), tolerance),
      );
      expect(dx, closeTo(0, tolerance));
      expect(dy, closeTo(0, tolerance));
    case ZyraBrowseNextMotion.fanTurn:
      expect(angleZ, closeTo(-.20 * r, tolerance));
      expect(dx, closeTo(0, tolerance));
      expect(dy, closeTo(size.height * .04 * r, tolerance));
      if (elapsed == 100) {
        expect(angleZ, lessThan(-.17));
      }
    case ZyraBrowseNextMotion.hingeTurn:
      final angle = .72 * r;
      final scale = .88 + .12 * eased;
      expect(matrix[10], closeTo(math.cos(angle), tolerance));
      expect(matrix[2], closeTo(-math.sin(angle) * scale, tolerance));
      expect(
        matrix[3],
        closeTo(
          -.85 / math.max(size.width, size.height) * math.sin(angle) * scale,
          tolerance,
        ),
      );
      expect(dx, closeTo(-size.width * .04 * r, tolerance));
      expect(dy, closeTo(0, tolerance));
      if (elapsed == 100) {
        expect(matrix[2].abs(), greaterThan(.5));
      }
    case ZyraBrowseNextMotion.cardDeal:
      expect(dx, closeTo(size.width * .09 * r, tolerance));
      expect(dy, closeTo(-size.height * .10 * r, tolerance));
      expect(angleZ, closeTo(.13 * r, tolerance));
    case ZyraBrowseNextMotion.forwardFlip:
      final angle = -.60 * r;
      final scale = .88 + .12 * eased;
      expect(matrix[10], closeTo(math.cos(angle), tolerance));
      expect(matrix[6], closeTo(math.sin(angle) * scale, tolerance));
      expect(
        matrix[7],
        closeTo(
          .85 / math.max(size.width, size.height) * math.sin(angle) * scale,
          tolerance,
        ),
      );
      expect(dx, closeTo(0, tolerance));
      expect(dy, closeTo(size.height * .025 * r, tolerance));
      if (elapsed == 100) {
        expect(matrix[6].abs(), greaterThan(.4));
      }
    case ZyraBrowseNextMotion.arcEntrance:
      expect(
        dx,
        closeTo(
          -size.width * .10 * (1 - t) * math.cos(1.5 * math.pi * t),
          tolerance,
        ),
      );
      expect(
        dy,
        closeTo(
          size.height * .05 * (1 - t) * math.sin(1.5 * math.pi * t),
          tolerance,
        ),
      );
      expect(angleZ, closeTo(.045 * r * math.sin(2 * math.pi * t), tolerance));
    case ZyraBrowseNextMotion.elasticCard:
      final sx = .72 + .28 * eased;
      final sy = .95 - .09 * math.sin(math.pi * t) + .05 * eased;
      expect(matrix[0] / matrix[5], closeTo(sx / sy, tolerance));
      expect(dx, closeTo(0, tolerance));
      expect(dy, closeTo(0, tolerance));
      if (elapsed == 100) {
        expect(matrix[0] / matrix[5], lessThan(.85));
      }
    case ZyraBrowseNextMotion.current:
      _identity(tester);
  }
}

// Independent homogeneous projection of the centred child. This catches fit,
// multiplication-order and perspective regressions, not only widget presence.
Offset _project(List<double> matrix, Size size, Offset point) {
  final x = point.dx - size.width / 2;
  final y = point.dy - size.height / 2;
  final w = matrix[3] * x + matrix[7] * y + matrix[15];
  expect(w, greaterThan(0));
  final projected = Offset(
    (matrix[0] * x + matrix[4] * y + matrix[12]) / w + size.width / 2,
    (matrix[1] * x + matrix[5] * y + matrix[13]) / w + size.height / 2,
  );
  expect(projected.dx.isFinite && projected.dy.isFinite, isTrue);
  return projected;
}

void _contained(WidgetTester tester, Size size) {
  final matrix = _matrix(tester);
  for (final corner in [
    Offset.zero,
    Offset(size.width, 0),
    Offset(size.width, size.height),
    Offset(0, size.height),
  ]) {
    final projected = _project(matrix, size, corner);
    expect(projected.dx, inInclusiveRange(-.001, size.width + .001));
    expect(projected.dy, inInclusiveRange(-.001, size.height + .001));
  }
  expect(tester.getRect(_clip).size, size);
}

void _wholeCard(WidgetTester tester, String id) {
  expect(find.byType(_Member), findsOneWidget);
  expect(
    find.descendant(of: find.byKey(_subject), matching: find.byType(Transform)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: find.byKey(_subject), matching: find.byType(ClipRect)),
    findsOneWidget,
  );
  // This is the original moving card's own rounded boundary, not a stationary
  // photo-only mask. All four parts belong to the very same transform owner.
  expect(
    find.descendant(of: find.byKey(_subject), matching: find.byType(ClipRRect)),
    findsOneWidget,
  );
  for (final part in ['photo', 'name', 'markers', 'frame']) {
    expect(
      find.ancestor(of: _key('member_${part}_$id'), matching: _transform),
      findsOneWidget,
    );
  }
  for (final type in [
    Opacity,
    FadeTransition,
    AnimatedSwitcher,
    ImageFiltered,
  ]) {
    expect(
      find.descendant(of: find.byKey(_subject), matching: find.byType(type)),
      findsNothing,
    );
  }
  expect(tester.widget<Transform>(_transform).transformHitTests, isFalse);
}

Future<void> _currentPixels(
  WidgetTester tester,
  Color color, {
  Size size = _size,
}) async {
  final matrix = _matrix(tester);
  final samples = <(Offset, Color)>[
    (Offset(size.width * .25, size.height * .25), color),
    (Offset(size.width * .75, size.height * .35), color),
    (Offset(size.width * .65, size.height * .60), color),
    (Offset(2.5, size.height / 2), _gold),
    (Offset(size.width - 2.5, size.height / 2), _gold),
  ];
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return [
        for (final sample in samples)
          () {
            final point = _project(matrix, size, sample.$1);
            final x = point.dx.floor().clamp(0, image.width - 1).toInt();
            final y = point.dy.floor().clamp(0, image.height - 1).toInt();
            return [
              for (var channel = 0; channel < 4; channel++)
                bytes!.getUint8((y * image.width + x) * 4 + channel),
            ];
          }(),
      ];
    } finally {
      image.dispose();
    }
  });
  for (var index = 0; index < samples.length; index++) {
    final argb = samples[index].$2.toARGB32();
    final expected = [
      (argb >> 16) & 255,
      (argb >> 8) & 255,
      argb & 255,
      (argb >> 24) & 255,
    ];
    for (var channel = 0; channel < 4; channel++) {
      expect(
        pixels![index][channel],
        closeTo(expected[channel], 3),
        reason: 'Projected current photo/outline is painted, not old/blank.',
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late int haptics;
  setUp(() {
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    haptics = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics++;
          }
          return null;
        });
  });
  tearDown(() {
    HttpOverrides.global = previousNetwork;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    expect(network.attempts, 0);
    expect(haptics, 0);
  });

  test(
    'Current plus ten replacement whole-card choices, not the old effects',
    () {
      expect(ZyraBrowseNextMotion.values, hasLength(11));
      expect(_choices, hasLength(10));
      expect(ZyraBrowseNextMotion.current.label, 'Current');
      expect(
        _choices.map((style) => style.name),
        orderedEquals([
          'cardGlide',
          'cardRise',
          'springPop',
          'cardRock',
          'fanTurn',
          'hingeTurn',
          'cardDeal',
          'forwardFlip',
          'arcEntrance',
          'elasticCard',
        ]),
      );
      expect(
        ZyraBrowseNextMotion.values.map((style) => style.label).toSet(),
        hasLength(11),
      );
      for (var index = 0; index < _choices.length; index++) {
        expect(_choices[index].label, startsWith('${index + 1} · '));
      }
    },
  );

  for (final style in _choices) {
    testWidgets(
      '${style.name}: current whole card moves and settles inside fixed bounds',
      (tester) async {
        final lifecycle = <String>[];
        await tester.pumpWidget(_app(lifecycle: lifecycle, style: style));
        await tester.pump();
        _identity(tester);
        expect(lifecycle, ['mount:first']);
        final rect = tester.getRect(_clip);
        final header = tester.getRect(_key('fixed-header'));
        final footer = tester.getRect(_key('fixed-footer'));
        await tester.pumpWidget(
          _app(
            lifecycle: lifecycle,
            style: style,
            id: 'next',
            epoch: 1,
            color: _nextColor,
          ),
        );
        await tester.pump();
        _wholeCard(tester, 'next');
        expect(find.text('first'), findsNothing);
        expect(find.text('next'), findsOneWidget);
        expect(
          lifecycle.where((event) => event == 'dispose:first'),
          hasLength(1),
        );
        for (final elapsed in [0, 100, 200]) {
          if (elapsed != 0) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          _appearance(tester, style, elapsed);
          _contained(tester, _size);
          expect(tester.getRect(_clip), rect);
          expect(tester.getRect(_key('fixed-header')), header);
          expect(tester.getRect(_key('fixed-footer')), footer);
          await _currentPixels(tester, _nextColor);
        }
        await tester.pump(Duration(milliseconds: _duration(style) - 201));
        _contained(tester, _size);
        await tester.pump(const Duration(milliseconds: 1));
        _identity(tester);
        _wholeCard(tester, 'next');
        expect(tester.getRect(_clip), rect);
        expect(lifecycle.where((event) => event == 'mount:next'), hasLength(1));
        await _currentPixels(tester, _nextColor);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Projected corners stay inside the reserved card area across sizes and phases',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final lifecycle = <String>[];
      for (final size in [
        const Size(200, 320),
        const Size(335, 610),
        const Size(430, 750),
      ]) {
        for (final style in _choices) {
          await tester.pumpWidget(
            _app(lifecycle: lifecycle, style: style, size: size),
          );
          _identity(tester);
          await tester.pumpWidget(
            _app(
              lifecycle: lifecycle,
              style: style,
              size: size,
              id: 'next',
              epoch: 1,
              color: _nextColor,
            ),
          );
          await tester.pump();
          var previous = 0;
          final duration = _duration(style);
          for (final elapsed in [
            0,
            80,
            180,
            duration ~/ 2,
            duration * 3 ~/ 4,
            duration - 1,
            duration,
          ]) {
            if (elapsed > previous) {
              await tester.pump(Duration(milliseconds: elapsed - previous));
            }
            _contained(tester, size);
            previous = elapsed;
          }
          _identity(tester);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets(
    'All ten card choices have pairwise distinct defining mid-motion signatures',
    (tester) async {
      final lifecycle = <String>[];
      final signatures = <ZyraBrowseNextMotion, List<double>>{};
      for (final style in _choices) {
        await tester.pumpWidget(_app(lifecycle: lifecycle, style: style));
        _identity(tester);
        await tester.pumpWidget(
          _app(
            lifecycle: lifecycle,
            style: style,
            id: 'next',
            epoch: 1,
            color: _nextColor,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        _appearance(tester, style, 200);
        signatures[style] = _matrix(tester);
      }
      for (var first = 0; first < _choices.length; first++) {
        for (var second = first + 1; second < _choices.length; second++) {
          final left = signatures[_choices[first]]!;
          final right = signatures[_choices[second]]!;
          var difference = 0.0;
          for (var index = 0; index < left.length; index++) {
            difference = math.max(
              difference,
              (left[index] - right[index]).abs(),
            );
          }
          expect(
            difference,
            greaterThan(.015),
            reason:
                '${_choices[first].name} and ${_choices[second].name} must not look like one common effect.',
          );
        }
      }
      await tester.pumpAndSettle();
      _identity(tester);
    },
  );

  testWidgets('Spring pop visibly grows, recoils and reaches full card size', (
    tester,
  ) async {
    final lifecycle = <String>[];
    const style = ZyraBrowseNextMotion.springPop;
    await tester.pumpWidget(_app(lifecycle: lifecycle, style: style));
    await tester.pumpWidget(
      _app(
        lifecycle: lifecycle,
        style: style,
        id: 'next',
        epoch: 1,
        color: _nextColor,
      ),
    );
    await tester.pump();
    expect(_matrix(tester)[0], closeTo(.64, .0001));
    await tester.pump(const Duration(milliseconds: 272));
    expect(_matrix(tester)[0], closeTo(.96, .0001));
    await tester.pump(const Duration(milliseconds: 187));
    expect(_matrix(tester)[0], closeTo(.87, .0001));
    await tester.pump(const Duration(milliseconds: 391));
    _identity(tester);
  });

  testWidgets(
    'Rocking card changes direction twice without moving its layout',
    (tester) async {
      final lifecycle = <String>[];
      const style = ZyraBrowseNextMotion.cardRock;
      await tester.pumpWidget(_app(lifecycle: lifecycle, style: style));
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: style,
          id: 'next',
          epoch: 1,
          color: _nextColor,
        ),
      );
      await tester.pump();
      expect(
        math.atan2(_matrix(tester)[1], _matrix(tester)[0]),
        closeTo(.105, .0001),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        math.atan2(_matrix(tester)[1], _matrix(tester)[0]),
        closeTo(-.070, .0001),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        math.atan2(_matrix(tester)[1], _matrix(tester)[0]),
        closeTo(.035, .0001),
      );
      await tester.pump(const Duration(milliseconds: 300));
      _identity(tester);
    },
  );

  testWidgets('Default Current has no entrance, filter or extra motion clip', (
    tester,
  ) async {
    final lifecycle = <String>[];
    await tester.pumpWidget(_app(lifecycle: lifecycle));
    _identity(tester);
    await tester.pumpWidget(
      _app(lifecycle: lifecycle, id: 'next', epoch: 1, color: _nextColor),
    );
    await tester.pump(const Duration(milliseconds: 1000));
    _identity(tester);
    _wholeCard(tester, 'next');
    await _currentPixels(tester, _nextColor);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Only changed member plus increasing positive Next epoch animates',
    (tester) async {
      final lifecycle = <String>[];
      const style = ZyraBrowseNextMotion.cardGlide;
      await tester.pumpWidget(_app(lifecycle: lifecycle, style: style));
      await tester.pumpWidget(
        _app(lifecycle: lifecycle, style: style, id: 'next', color: _nextColor),
      );
      _identity(tester);
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: style,
          id: 'next',
          epoch: 1,
          color: _nextColor,
        ),
      );
      _identity(tester);
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: style,
          id: 'third',
          epoch: -1,
          color: _thirdColor,
        ),
      );
      _identity(tester);
      await tester.pumpWidget(
        _app(lifecycle: lifecycle, style: style, id: 'first', epoch: 0),
      );
      _identity(tester);
      await tester.pump(const Duration(milliseconds: 1000));
      _identity(tester);
    },
  );

  testWidgets(
    'Choice change neither replays Next nor remounts the unchanged card',
    (tester) async {
      final lifecycle = <String>[];
      await tester.pumpWidget(
        _app(lifecycle: lifecycle, style: ZyraBrowseNextMotion.cardGlide),
      );
      final original = tester.state(find.byType(_Member));
      await tester.pumpWidget(
        _app(lifecycle: lifecycle, style: ZyraBrowseNextMotion.forwardFlip),
      );
      _identity(tester);
      expect(tester.state(find.byType(_Member)), same(original));
      expect(lifecycle, ['mount:first']);
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: ZyraBrowseNextMotion.fanTurn,
          id: 'next',
          epoch: 1,
          color: _nextColor,
        ),
      );
      _identity(tester);
      await tester.pump(const Duration(milliseconds: 1000));
      _identity(tester);
    },
  );

  testWidgets(
    'Choice, Back and revoked tokens cancel the active pose immediately',
    (tester) async {
      final lifecycle = <String>[];
      await tester.pumpWidget(
        _app(lifecycle: lifecycle, style: ZyraBrowseNextMotion.cardRise),
      );
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: ZyraBrowseNextMotion.cardRise,
          id: 'next',
          epoch: 1,
          color: _nextColor,
        ),
      );
      await tester.pump();
      expect(_matrix(tester)[13], greaterThan(0));
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: ZyraBrowseNextMotion.hingeTurn,
          id: 'next',
          epoch: 1,
          color: _nextColor,
        ),
      );
      _identity(tester);
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: ZyraBrowseNextMotion.hingeTurn,
          id: 'third',
          epoch: 2,
          color: _thirdColor,
        ),
      );
      await tester.pump();
      expect(_matrix(tester)[2].abs(), greaterThan(.5));
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: ZyraBrowseNextMotion.hingeTurn,
          id: 'first',
          epoch: 2,
        ),
      );
      _identity(tester);
      await tester.pump(const Duration(milliseconds: 1000));
      _identity(tester);
      expect(find.text('third'), findsNothing);
    },
  );

  for (final accessible in [false, true]) {
    testWidgets(
      '${accessible ? 'Accessible navigation' : 'Reduced motion'} cancels mid-card entrance',
      (tester) async {
        final lifecycle = <String>[];
        Widget fixture(String id, int epoch, {bool quiet = false}) => _app(
          lifecycle: lifecycle,
          style: ZyraBrowseNextMotion.forwardFlip,
          id: id,
          epoch: epoch,
          color: _nextColor,
          quiet: quiet && !accessible,
          accessible: quiet && accessible,
        );
        await tester.pumpWidget(fixture('first', 0, quiet: true));
        await tester.pumpWidget(fixture('next', 1, quiet: true));
        _identity(tester);
        await tester.pumpWidget(fixture('next', 1));
        _identity(tester);
        await tester.pumpWidget(fixture('third', 2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 180));
        expect(_matrix(tester)[6].abs(), greaterThan(.3));
        await tester.pumpWidget(fixture('third', 2, quiet: true));
        _identity(tester);
        await tester.pump(const Duration(milliseconds: 1000));
        _identity(tester);
        await tester.pumpWidget(fixture('third', 2));
        _identity(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Rapid Next resets the pose and retains no old member', (
    tester,
  ) async {
    final lifecycle = <String>[];
    const style = ZyraBrowseNextMotion.cardDeal;
    await tester.pumpWidget(_app(lifecycle: lifecycle, style: style));
    await tester.pumpWidget(
      _app(
        lifecycle: lifecycle,
        style: style,
        id: 'next',
        epoch: 1,
        color: _nextColor,
      ),
    );
    await tester.pump();
    final start = _matrix(tester);
    await tester.pump(const Duration(milliseconds: 180));
    await tester.pumpWidget(
      _app(
        lifecycle: lifecycle,
        style: style,
        id: 'third',
        epoch: 2,
        color: _thirdColor,
      ),
    );
    await tester.pump();
    expect(_matrix(tester), orderedEquals(start));
    expect(find.text('first'), findsNothing);
    expect(find.text('next'), findsNothing);
    _wholeCard(tester, 'third');
    expect(lifecycle.where((event) => event == 'dispose:next'), hasLength(1));
    await _currentPixels(tester, _thirdColor);
    await tester.pumpWidget(
      _app(
        lifecycle: lifecycle,
        style: style,
        id: 'third',
        epoch: 1,
        color: _thirdColor,
      ),
    );
    _identity(tester);
    await tester.pump(const Duration(milliseconds: 1000));
    _identity(tester);
  });

  testWidgets(
    'Child-only rebuild preserves state and the current animation clock',
    (tester) async {
      final lifecycle = <String>[];
      const style = ZyraBrowseNextMotion.springPop;
      await tester.pumpWidget(_app(lifecycle: lifecycle, style: style));
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: style,
          id: 'next',
          epoch: 1,
          color: _nextColor,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      final state = tester.state(find.byType(_Member));
      final before = _matrix(tester);
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: style,
          id: 'next',
          epoch: 1,
          color: _thirdColor,
        ),
      );
      expect(tester.state(find.byType(_Member)), same(state));
      expect(_matrix(tester), orderedEquals(before));
      await _currentPixels(tester, _thirdColor);
      await tester.pump(const Duration(milliseconds: 1000));
      _identity(tester);
      expect(lifecycle.where((event) => event == 'mount:next'), hasLength(1));
    },
  );

  testWidgets(
    'Stationary hit target and semantics belong only to the current card',
    (tester) async {
      final lifecycle = <String>[];
      final semantics = tester.ensureSemantics();
      try {
        var taps = 0;
        const style = ZyraBrowseNextMotion.cardGlide;
        await tester.pumpWidget(_app(lifecycle: lifecycle, style: style));
        await tester.pumpWidget(
          _app(
            lifecycle: lifecycle,
            style: style,
            id: 'next',
            epoch: 1,
            color: _nextColor,
            onTap: () => taps++,
          ),
        );
        await tester.pump();
        expect(
          find.bySemanticsLabel(RegExp(r'^Member next(?:\nnext)?$')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'^Member first(?:\nfirst)?$')),
          findsNothing,
        );
        await tester.tapAt(
          tester.getRect(_clip).centerLeft + const Offset(1, 0),
        );
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Disposal during whole-card entrance leaves no ticker or delayed update',
    (tester) async {
      final lifecycle = <String>[];
      const style = ZyraBrowseNextMotion.cardRock;
      await tester.pumpWidget(_app(lifecycle: lifecycle, style: style));
      await tester.pumpWidget(
        _app(
          lifecycle: lifecycle,
          style: style,
          id: 'next',
          epoch: 1,
          color: _nextColor,
        ),
      );
      await tester.pump();
      expect(_matrix(tester)[1].abs(), greaterThan(.05));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1000));
      expect(lifecycle.where((event) => event == 'dispose:next'), hasLength(1));
      expect(find.byType(ZyraBrowseNextPhotoMotion), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
