import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';

const _labels = [
  'Current',
  'Footsteps',
  'Shared path',
  'Together',
  'Linked',
  'Lasting',
  'Growing',
  'Milestone',
  'Two paths',
  'With intention',
  'Couple',
];

class _OpticallyFittedOriginalArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    // Independent reference: the original arrow's stroked bounds are
    // 16.8 × 17.8 around (12, 12). Retain its exact path after the newly
    // requested 21-unit optical fit, with the original visible line weight.
    const fit = 21 / 17.8;
    canvas.translate(12, 12);
    canvas.scale(fit);
    canvas.translate(-12, -12);
    final paint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 / fit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(4.5, 20)
        ..cubicTo(4.5, 15, 12, 16, 12, 10.5)
        ..moveTo(19.5, 20)
        ..cubicTo(19.5, 15, 12, 16, 12, 10.5)
        ..moveTo(12, 10.5)
        ..lineTo(12, 4)
        ..moveTo(8.5, 7.5)
        ..lineTo(12, 4)
        ..lineTo(15.5, 7.5),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _OpticallyFittedOriginalArrowPainter oldDelegate,
  ) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    AppState.instance.resetForAccountChange();
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  test(
    'Couple is the canonical default; historical paint paths remain intact',
    () {
      expect(ZyraJourneyIconDesign.values.map((value) => value.label), _labels);
      expect(ZyraJourneyIconPainter.viewBoxSize, 24);
      expect(ZyraJourneyIconPainter.strokeWidth, 1.8);
      const defaultPainter = ZyraJourneyIconPainter(color: Colors.amber);
      expect(defaultPainter.design, ZyraJourneyIconDesign.couple);
      expect(defaultPainter.shouldRepaint(defaultPainter), isFalse);
      expect(
        defaultPainter.shouldRepaint(
          const ZyraJourneyIconPainter(color: Colors.white),
        ),
        isTrue,
      );
      for (final design in ZyraJourneyIconDesign.values) {
        expect(
          defaultPainter.shouldRepaint(
            ZyraJourneyIconPainter(color: Colors.amber, design: design),
          ),
          design == ZyraJourneyIconDesign.couple ? isFalse : isTrue,
        );
      }
    },
  );

  for (final change in [
    'ordinary startup',
    'preview startup',
    'developer ABA',
    'account fixture reset',
    'account reset',
  ]) {
    testWidgets(
      'Couple stays canonical after $change without member mutation',
      (tester) async {
        if (change == 'preview startup') {
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
        }
        final app = AppState.instance;
        final journeys = List.of(app.activeJourneys);
        final saved = List.of(app.saved);
        final photos = List.of(app.photos);
        var changes = 0;
        void changed() => changes++;
        app.addListener(changed);
        addTearDown(() => app.removeListener(changed));
        await tester.pumpWidget(
          const MaterialApp(
            home: Row(
              children: [
                ZyraJourneyIcon(
                  key: ValueKey('small-glyph'),
                  color: Colors.amber,
                ),
                ZyraJourneyIcon(
                  key: ValueKey('large-glyph'),
                  color: Colors.white54,
                  size: 26,
                ),
              ],
            ),
          ),
        );
        final before = {
          for (final key in ['small-glyph', 'large-glyph'])
            key: tester.getRect(find.byKey(ValueKey(key))),
        };
        List<ZyraJourneyIconPainter> painters() => tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((widget) => widget.painter)
            .whereType<ZyraJourneyIconPainter>()
            .toList();
        expect(painters().map((painter) => painter.design), [
          ZyraJourneyIconDesign.couple,
          ZyraJourneyIconDesign.couple,
        ]);
        expect(changes, 0);
        if (change == 'developer ABA') {
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
        } else if (change == 'account fixture reset') {
          ZyraAccountState.resetForTesting();
        } else if (change == 'account reset') {
          AppState.instance.resetForAccountChange();
        }
        await tester.pump();
        expect(painters().map((painter) => painter.design), [
          ZyraJourneyIconDesign.couple,
          ZyraJourneyIconDesign.couple,
        ]);
        expect(painters().map((painter) => painter.color), [
          Colors.amber,
          Colors.white54,
        ]);
        for (final key in before.keys) {
          expect(tester.getRect(find.byKey(ValueKey(key))), before[key]);
        }
        expect(app.activeJourneys, journeys);
        expect(app.saved, saved);
        expect(app.photos, photos);
        if (change != 'account reset') expect(changes, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'eleven historical paint-only references retain distinct unclipped shapes and fitted arrow geometry',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final design in ZyraJourneyIconDesign.values)
                  RepaintBoundary(
                    key: ValueKey('preview-${design.name}'),
                    child: ZyraJourneyIcon(
                      color: Colors.amber,
                      size: 48,
                      design: design,
                    ),
                  ),
                RepaintBoundary(
                  key: const ValueKey('original-current-reference'),
                  child: SizedBox.square(
                    dimension: 48,
                    child: CustomPaint(
                      painter: _OpticallyFittedOriginalArrowPainter(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fingerprints = <String>{};
      String? currentPixels;
      for (final design in ZyraJourneyIconDesign.values) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(ValueKey('preview-${design.name}')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            final data = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final bytes = data!.buffer.asUint8List();
            final fingerprint = base64Encode(bytes);
            fingerprints.add(fingerprint);
            if (design == ZyraJourneyIconDesign.current) {
              currentPixels = fingerprint;
            }
            var painted = 0;
            for (var y = 0; y < image.height; y++) {
              for (var x = 0; x < image.width; x++) {
                if (bytes[(y * image.width + x) * 4 + 3] == 0) continue;
                painted++;
                expect(
                  x,
                  inInclusiveRange(1, image.width - 2),
                  reason: '${design.label} must not crop at its viewBox edge.',
                );
                expect(
                  y,
                  inInclusiveRange(1, image.height - 2),
                  reason: '${design.label} must not crop at its viewBox edge.',
                );
              }
            }
            expect(painted, greaterThan(20));
          } finally {
            image.dispose();
          }
        });
      }
      expect(fingerprints, hasLength(11));
      final reference = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('original-current-reference')),
      );
      await tester.runAsync(() async {
        final image = await reference.toImage(pixelRatio: 1);
        try {
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(base64Encode(data!.buffer.asUint8List()), currentPixels);
        } finally {
          image.dispose();
        }
      });
      expect(tester.takeException(), isNull);
    },
  );
}
