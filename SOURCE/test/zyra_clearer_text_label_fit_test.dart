import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_focus_dashboard.dart';

import 'visual/baseline_capture_support.dart';

const _report = String.fromEnvironment('ZYRA_LINE126_FIT_REPORT');
final _rows = <Map<String, Object?>>[];
final _normalHeights = <String, double>{};

String _words(String text) =>
    text.replaceAll('-\n', '').replaceAll(RegExp(r'\s+'), ' ').trim();

Future<void> _mount(
  WidgetTester tester, {
  required Widget child,
  double width = 430,
  double scale = 1,
  bool guardian = false,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await BaselineHarness(
    tester,
    group: 'line126_fit',
    logicalSize: Size(width, width == 375 ? 667 : 932),
    devicePixelRatio: 1,
    textScale: scale,
    safePadding: width == 375
        ? const EdgeInsets.only(top: 20)
        : const EdgeInsets.only(top: 59, bottom: 34),
    reduceMotion: true,
  ).mountPresentation(
    child: Scaffold(body: child),
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: guardian,
      model: ViewRequestDraftModel(capacity: 3).snapshot(),
      tab: 2,
      pages: const [],
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null, useSystemSymbolFont: false));
  tearDownAll(() async {
    await baselineTearDown();
    if (_report.isNotEmpty) {
      final output = File(_report);
      output.parent.createSync(recursive: true);
      output.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'scope': 'Real production frame and bundled Poppins; Q180/Q183 fit',
          'rows': _rows,
        }),
      );
    }
  });

  for (final guardian in [false, true]) {
    for (final basic in [false, true]) {
      final role =
          '${guardian ? 'guardian' : 'seeker'}_${basic ? 'basic' : 'one'}';
      for (final width in [430.0, 375.0]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets('$role labels fit at $width pt and $scale', (
            tester,
          ) async {
            final labels = [
              'Journey\nrequests',
              if (guardian) 'Connect with\nGuardian' else 'Introductions',
              if (guardian) 'Introductions' else 'Ended\nJourneys',
              'Notifications',
            ];
            final tiles = [
              for (var index = 0; index < labels.length; index++)
                ZyraFocusTile(
                  id: 'fit-$index',
                  label: labels[index],
                  status: guardian && basic && (index == 1 || index == 2)
                      ? 'Guardian One'
                      : 'Nothing new',
                  icon: Icons.mail_outline,
                  locked: guardian && basic && (index == 1 || index == 2),
                  onTap: () {},
                ),
            ];
            await _mount(
              tester,
              width: width,
              scale: scale,
              guardian: guardian,
              child: ZyraFocusDashboard(
                items: const [],
                chips: const [],
                tiles: tiles,
              ),
            );
            final tileRects = [
              for (var index = 0; index < labels.length; index++)
                tester.getRect(find.byKey(ValueKey('fit-$index'))),
            ];
            expect(
              tileRects.map((rect) => rect.width),
              everyElement((width - 76) / 4),
            );
            for (final rect in tileRects) {
              expect(rect.height, closeTo(tileRects.first.height, .001));
            }
            if (width == 430 && scale == 1) {
              _normalHeights[role] = tileRects.first.height;
            }
            for (var index = 0; index < labels.length; index++) {
              final finder = find.byKey(
                ValueKey('focus-tile-label-fit-$index'),
              );
              final widget = tester.widget<Text>(finder);
              final element = tester.element(finder);
              final render = tester.renderObject<RenderParagraph>(
                find.descendant(of: finder, matching: find.byType(RichText)),
              );
              final style = DefaultTextStyle.of(
                element,
              ).style.merge(widget.style);
              final scaler = MediaQuery.textScalerOf(element);
              expect(style.fontWeight, FontWeight.w400);
              expect(style.letterSpacing, 0);
              expect(style.fontSize, inInclusiveRange(10, 11.5));
              expect(widget.textScaler, isNull);
              expect(scaler.scale(11.5), closeTo(11.5 * scale, .0001));
              if (scale > 1) expect(style.fontSize, 11.5);
              expect(_words(widget.data!), _words(labels[index]));
              expect(widget.semanticsLabel, labels[index]);
              expect(widget.maxLines, isNull);
              expect(widget.overflow, TextOverflow.visible);
              final displayLines = widget.data!.split('\n');
              if (width == 375 && scale == 1.3) {
                if (labels[index] == 'Introductions') {
                  expect(widget.data, 'Intro-\nductions');
                }
                if (labels[index] == 'Notifications') {
                  expect(widget.data, 'Notifi-\ncations');
                }
              }
              for (final line in displayLines) {
                final painter = TextPainter(
                  text: TextSpan(text: line, style: style),
                  textDirection: Directionality.of(element),
                  textScaler: scaler,
                )..layout();
                expect(
                  painter.width,
                  lessThanOrEqualTo(render.constraints.maxWidth + .01),
                  reason: '$role $width/$scale: $line',
                );
                painter.dispose();
              }
              if (width == 430 && scale == 1) {
                expect(style.fontSize, 11.5);
                expect(widget.data, labels[index]);
                expect(tileRects[index].width, 88.5);
              }
              if (guardian && width == 375 && scale == 1.3 && index == 1) {
                expect(widget.data, 'Connect\nwith\nGuar-\ndian');
                expect(displayLines.length, 4);
                expect(
                  tileRects[index].height,
                  greaterThan(_normalHeights[role]!),
                );
              }
              _rows.add({
                'role': role,
                'viewport_width': width,
                'text_scale': scale,
                'label': labels[index],
                'display': widget.data,
                'font_family': style.fontFamily,
                'font_size': style.fontSize,
                'weight': style.fontWeight!.value,
                'letter_spacing': style.letterSpacing,
                'scaled_down': style.fontSize! < 11.5,
                'hyphenated': widget.data!.contains('-\n'),
                'line_count': displayLines.length,
                'available_label_width': render.constraints.maxWidth,
                'tile_width': tileRects[index].width,
                'tile_height': tileRects[index].height,
                'row_grew':
                    tileRects[index].height >
                    (_normalHeights[role] ?? tileRects[index].height),
              });
            }
          });
        }
      }
    }
  }

  testWidgets(
    'inactive Salam and disabled round-action text is outside artwork fades',
    (tester) async {
      await _mount(
        tester,
        child: const ZyraConceptJourneyThresholdBody(
          firstName: 'Sara',
          mine: false,
          theirs: false,
          headline: 'A beginning',
          body: 'Send Salam to begin.',
          salam: true,
          actionLabel: 'Send Salam',
        ),
      );
      for (final label in ['Not sent', 'Awaiting Salam', 'Send Salam']) {
        final finder = find.text(label);
        final text = tester.widget<Text>(finder);
        expect(text.style!.color, ZyraColors.secondaryText);
        expect(text.style!.fontWeight!.value, greaterThanOrEqualTo(400));
        expect(
          find.ancestor(
            of: finder,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Opacity && widget.opacity < 1 ||
                  widget is AnimatedOpacity && widget.opacity < 1,
            ),
          ),
          findsNothing,
        );
      }
      expect(
        find.byWidgetPredicate(
          (widget) => widget is AnimatedOpacity && widget.opacity == .38,
        ),
        findsNWidgets(2),
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Opacity && widget.opacity == .45,
        ),
        findsOneWidget,
      );
    },
  );
}
